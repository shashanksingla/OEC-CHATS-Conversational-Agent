import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { CccapClient, type DateScope } from "./client.js";
import { normalizePaymentSourceBundle } from "./payment-canonical-adapter.js";
import { normalizeProviderContext } from "./provider-context.js";
import { assertPaymentEnginePayload } from "./payment-schema.js";
import { buildSituationEnvelope } from "./situation-envelope.js";
import { computePayoutDate } from "./payout-date.js";

const execFileAsync = promisify(execFile);
const paymentEvaluatorPath = fileURLToPath(new URL(
  "../../../skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py",
  import.meta.url,
));
type RecordValue = Record<string, unknown>;

const PAYMENT_EVALUATOR_TIMEOUT_MS = 30_000;
const PAYMENT_EVALUATOR_MAX_BUFFER_BYTES = 10_000_000;

async function runPaymentEvaluator(inputPath: string): Promise<{ stdout: string }> {
  try {
    return await execFileAsync("uv", ["run", paymentEvaluatorPath, inputPath], {
      windowsHide: true,
      timeout: PAYMENT_EVALUATOR_TIMEOUT_MS,
      maxBuffer: PAYMENT_EVALUATOR_MAX_BUFFER_BYTES,
      killSignal: "SIGKILL",
    });
  } catch (error) {
    const nodeError = error as NodeJS.ErrnoException & { killed?: boolean; signal?: string };
    if (nodeError.code === "ENOENT") {
      throw new Error("Payment engine is unavailable: the uv/python runtime could not be started.");
    }
    if (nodeError.killed || nodeError.signal === "SIGKILL" || nodeError.signal === "SIGTERM") {
      throw new Error(`Payment engine is unavailable: evaluation exceeded ${PAYMENT_EVALUATOR_TIMEOUT_MS}ms and was terminated.`);
    }
    throw error;
  }
}

type HighestImpactChild = { name: string; rankedByDollars: boolean } | undefined;

function rankByImpactField(impacts: Record<string, unknown>[], field: "amount_at_risk" | "total_amount"): readonly [string, number] | undefined {
  return impacts
    .map((impact) => [impact.child_name as string, Number(impact[field]) || 0] as const)
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .at(0);
}

function highestImpactChildName(impacts: unknown[], days: unknown[]): HighestImpactChild {
  const rows = impacts
    .map((value) => record(value, "Child payment impact"))
    .filter((impact) => typeof impact.child_name === "string");
  const byAmountAtRisk = rankByImpactField(rows, "amount_at_risk");
  if (byAmountAtRisk && byAmountAtRisk[1] > 0) return { name: byAmountAtRisk[0], rankedByDollars: true };
  // amount_at_risk is 0 for every child (no conditional/limit-exceeded days) -
  // fall back to total dollar exposure across ALL rate-matched days before
  // ever falling back to a non-dollar signal, so "highest impact" still
  // reflects money whenever any verified dollar figure exists.
  const byTotalAmount = rankByImpactField(rows, "total_amount");
  if (byTotalAmount && byTotalAmount[1] > 0) return { name: byTotalAmount[0], rankedByDollars: true };
  // No verified dollar amount exists for any child (e.g. no fiscal rate
  // matched yet) - only a scheduled-hours proxy is available. Callers must
  // label this explicitly as an hours-based fallback, never present it as a
  // dollar-ranked "highest impact" result.
  const fallback = new Map<string, number>();
  for (const value of days) {
    const day = record(value, "Attendance day");
    if (typeof day.child_name !== "string") continue;
    fallback.set(day.child_name, (fallback.get(day.child_name) ?? 0) + (Number(day.unit_hours) || 0));
  }
  const topByHours = [...fallback.entries()]
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .at(0)?.[0];
  return topByHours ? { name: topByHours, rankedByDollars: false } : undefined;
}

function record(value: unknown, label: string): RecordValue {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} is unavailable`);
  return value as RecordValue;
}
function array(value: unknown, label: string): unknown[] {
  if (!Array.isArray(value)) throw new Error(`${label} is unavailable`);
  return value;
}
function first(value: unknown, label: string): RecordValue {
  const rows = array(value, label);
  if (rows.length === 0) throw new Error(`${label} is unavailable`);
  return record(rows[0], label);
}
export type PaymentView = "STATUS" | "NEXT_PAYOUT" | "CURRENT_WEEK_FORECAST" | "CUSTOM_RANGE";

export async function getPaymentAnalysis(
  client: CccapClient,
  scope: DateScope,
  view: PaymentView = "STATUS",
  asOfDate = new Date().toISOString().slice(0, 10),
  filters: { childNames?: string[]; authNames?: string[]; countyNames?: string[]; detailPage?: number; detailPageSize?: number; excludedOnly?: boolean } = {},
): Promise<unknown> {
  const initialization = record(await client.initialize(scope), "Provider context");
  // CUSTOM_RANGE is an arbitrary provider-chosen span (validated to <= 31 days
  // by the request schema) independent of any Salesforce ServicePeriod
  // record, so it never calls getServicePeriods; every other view still
  // selects exactly one authoritative service period as before.
  const servicePeriod = view === "CUSTOM_RANGE"
    ? (() => {
        if (typeof scope.dateFrom !== "string" || typeof scope.dateTo !== "string") {
          throw new Error("dateFrom and dateTo are required for view CUSTOM_RANGE");
        }
        return {
          servicePeriodId: `CUSTOM:${scope.dateFrom}:${scope.dateTo}`,
          serviceBeginDate: scope.dateFrom,
          serviceEndDate: scope.dateTo,
        } as RecordValue;
      })()
    : first(
        record(
          await client.getServicePeriods(
            view === "NEXT_PAYOUT" ? { paymentAfter: "TODAY", limitOne: true } :
              view === "CURRENT_WEEK_FORECAST" ? { dateOn: "TODAY", limitOne: true } :
                { ...scope, limitOne: true, dateFilter: scope.dateFilter },
          ),
          "Service periods",
        ).servicePeriods,
        "Service period",
      );
  const serviceBeginDate = servicePeriod.serviceBeginDate;
  const serviceEndDate = servicePeriod.serviceEndDate;
  if (typeof serviceBeginDate !== "string" || typeof serviceEndDate !== "string") throw new Error("Service period dates are unavailable");
  const sourceScope: DateScope = view === "STATUS"
    ? scope
    : view === "CUSTOM_RANGE"
      ? { dateFilter: "DATE_RANGE", dateFrom: serviceBeginDate, dateTo: serviceEndDate }
      : { dateFilter: "DATE_RANGE", dateFrom: serviceBeginDate, dateTo: serviceEndDate };
  const providerContext = initialization;
  const { countyIds } = normalizeProviderContext(providerContext);
  const scheduleData = await client.getSchedules(sourceScope);
  const scheduleRows = array(record(scheduleData, "Schedules").schedules, "Schedules");
  const scheduleRateTypes = Object.fromEntries(scheduleRows.flatMap((value) => {
    const schedule = record(value, "Schedule");
    const authorizationKeys = [
      schedule.Authorization__c,
      schedule.authorization_id,
      schedule.authorization_name,
      schedule.CI_Authorization_Id__c,
    ].filter((key): key is string | number =>
      (typeof key === "string" && key.length > 0) || typeof key === "number",
    );
    const rateType = schedule.rate_type_code ?? schedule.CI_Authorization_Rate_Type__c;
    return typeof rateType === "string"
      ? authorizationKeys.map((authorizationKey) => [String(authorizationKey), rateType])
      : [];
  }));
  const authorizationNames = [...new Set(scheduleRows.flatMap((value) => {
    const schedule = record(value, "Schedule");
    const authorizationName = schedule.authorization_name ?? schedule.CI_Authorization_Id__c;
    return typeof authorizationName === "string" || typeof authorizationName === "number"
      ? [String(authorizationName)]
      : [];
  }))];
  const [authorizationData, countyData, fiscalData, holidayData, paymentData, vacantSlotData] = await Promise.all([
    client.getAuthorizations({
      ...sourceScope,
      countyIds,
      ...(authorizationNames.length > 0 ? { authNames: authorizationNames } : {}),
      careDate: serviceBeginDate,
      scheduleRateTypes,
    }),
    client.getCountyData({ ...sourceScope, countyIds }),
    client.getFiscalRates(sourceScope),
    client.getHolidayList(sourceScope), client.getPaymentHistory(sourceScope),
    typeof client.getVacantSlots === "function"
      ? client.getVacantSlots({ ...sourceScope, countyIds })
      : Promise.resolve({ vacantSlots: [] }),
  ]);
  const { payload, servicePeriod: canonicalServicePeriod, vacantSlotMappingGaps } = normalizePaymentSourceBundle({
    initialization: providerContext,
    servicePeriod,
    authorizationData,
    countyData,
    scheduleData,
    fiscalData,
    holidayData,
    paymentData,
    vacantSlotData,
    mode: view === "STATUS" ? "STATUS" : "FORECAST",
    asOfDate,
  });
  const childNames = filters.childNames ? new Set(filters.childNames) : undefined;
  const authNames = filters.authNames ? new Set(filters.authNames) : undefined;
  const countyNames = filters.countyNames
    ? new Set(filters.countyNames.map((name) => name.trim().toLowerCase()))
    : undefined;
  if (countyNames && !payload.attendance_days.some((day) => {
    const record = day as unknown as Record<string, unknown>;
    return typeof record.county_name === "string" && countyNames.has(record.county_name.trim().toLowerCase());
  })) {
    throw new Error("Requested county filter did not match the selected provider scope and period.");
  }
  if (countyNames) {
    payload.attendance_days = payload.attendance_days.filter((day) => {
      const record = day as unknown as Record<string, unknown>;
      return typeof record.county_name === "string" && countyNames.has(record.county_name.trim().toLowerCase());
    });
  }
  if (childNames || authNames) {
    const normalizedAuthorizations = array(
      record(authorizationData, "Authorizations").normalizedAuthorizations,
      "Normalized authorizations",
    );
    const authorizationIdsByName = new Set(
      normalizedAuthorizations.flatMap((value) => {
        const row = record(value, "Normalized authorization");
        const authorization = record(row.authorization, "Authorization");
        const references = [authorization.Id, authorization.Name, authorization.IDN_EXTNL__c]
          .filter((reference): reference is string => typeof reference === "string" && reference.length > 0);
        return authNames && references.some((reference) => authNames.has(reference)) && typeof authorization.Id === "string"
          ? [authorization.Id]
          : [];
      }),
    );
    if (authNames && authorizationIdsByName.size === 0) {
      throw new Error("Requested authorization filter did not match the selected provider scope and period.");
    }
    if (childNames && !payload.attendance_days.some((day) => {
      const record = day as unknown as Record<string, unknown>;
      return typeof record.child_name === "string" && childNames.has(record.child_name);
    })) {
      throw new Error("Requested child filter did not match the selected provider scope and period.");
    }
    const selectedAuthorizations = new Set(
      payload.attendance_days
        .filter((day) => {
          const record = day as unknown as Record<string, unknown>;
          return typeof record.authorization_id === "string"
            && (!authNames || authorizationIdsByName.has(record.authorization_id))
            && (!childNames || (typeof record.child_name === "string" && childNames.has(record.child_name)));
        })
        .map((day) => day.authorization_id),
    );
    payload.attendance_days = payload.attendance_days.filter((day) => {
      const record = day as unknown as Record<string, unknown>;
      return typeof record.authorization_id === "string" && selectedAuthorizations.has(record.authorization_id) && (!childNames || (typeof record.child_name === "string" && childNames.has(record.child_name)));
    });
    payload.fiscal_rates = (payload.fiscal_rates as Array<Record<string, unknown>>).filter((rate) => typeof rate.authorization_id === "string" && selectedAuthorizations.has(rate.authorization_id));
    payload.existing_sub_payments = payload.existing_sub_payments.filter((payment) => {
      const record = payment as unknown as Record<string, unknown>;
      return typeof record.authorization_id === "string" && selectedAuthorizations.has(record.authorization_id);
    });
  }
  assertPaymentEnginePayload(payload);
  const directory = await mkdtemp(join(tmpdir(), "carepay-payment-"));
  const inputPath = join(directory, "payment.json");
  try {
    await writeFile(inputPath, JSON.stringify(payload), "utf8");
    const { stdout } = await runPaymentEvaluator(inputPath);
    const evaluated = JSON.parse(stdout) as { status?: string; result?: unknown; error?: string };
    if (evaluated.status !== "ok" || !evaluated.result) throw new Error(evaluated.error || "Payment evaluation failed");
    const result = evaluated.result as RecordValue;
    const attendance = record(result.attendance, "Evaluated attendance");
    const allDays = Array.isArray(attendance.days) ? attendance.days : [];
    const displayableDays = allDays.filter((value) => {
      const day = record(value, "Attendance day");
      if (day.classification === "NO_CARE" || day.classification === "CARE_NOT_OFFERED") return false;
      // Backs the "review excluded payment days" action: narrows to rows the
      // payment engine actually excluded from payment (payment_excluded is
      // tagged by the evaluator for every exclusion path), instead of the
      // full attendance detail the action's label would otherwise mismatch.
      if (filters.excludedOnly) return day.payment_excluded === true;
      return true;
    });
    const topChild = highestImpactChildName(
      Array.isArray(result.child_payment_impacts) ? result.child_payment_impacts : [],
      displayableDays,
    );
    delete result.child_payment_impacts;
    const showDetail = filters.detailPage !== undefined || filters.detailPageSize !== undefined;
    const detailPage = filters.detailPage ?? 1;
    const detailPageSize = filters.detailPageSize ?? 25;
    const detailStart = (detailPage - 1) * detailPageSize;
    // When no detail page was requested, still include a small preview (not
    // the full page) so the summary response can show a few rows inline
    // instead of only a bare "N rows available" text hint - the formatter
    // renders this as a compact preview table, distinct from the full
    // ranked detail table shown once a real detail page is requested.
    const PREVIEW_ROW_COUNT = 3;
    const pagedAttendance = {
      ...attendance,
      days: showDetail
        ? displayableDays.slice(detailStart, detailStart + detailPageSize)
        : displayableDays.slice(0, PREVIEW_ROW_COUNT),
    };
    const sourceRetrievedAt = new Date().toISOString();
    return {
      ...result,
      attendance: pagedAttendance,
      detailPagination: {
        page: showDetail ? detailPage : 0,
        pageSize: showDetail ? detailPageSize : 0,
        totalRows: displayableDays.length,
        hasMore: showDetail ? detailStart + detailPageSize < displayableDays.length : displayableDays.length > 0,
      },
      filters: {
        ...(filters.childNames ? { childNames: filters.childNames } : {}),
        ...(filters.authNames ? { authNames: filters.authNames } : {}),
        ...(filters.detailPageSize ? { detailPageSize: filters.detailPageSize } : {}),
        ...(filters.excludedOnly ? { excludedOnly: true } : {}),
      },
      ...(topChild ? { highestImpactChildName: topChild.name, highestImpactRankedByDollars: topChild.rankedByDollars } : {}),
      ...(vacantSlotMappingGaps > 0 ? { vacantSlotMappingGaps } : {}),
      scope: sourceScope,
      paymentView: view,
      servicePeriod: canonicalServicePeriod,
      sourceRetrievedAt,
      situation: await buildSituationEnvelope(result.payment, "payment-analysis", sourceScope, sourceRetrievedAt),
    };
  } finally { await rm(directory, { recursive: true, force: true }); }
}

export type LedgerPeriodStatus = "IN_PROGRESS" | "PENDING_CONFIRMATION" | "EXPECTED_AWAITING_PAYOUT" | "PAID";
export interface LedgerPeriodEntry { servicePeriodId: string; serviceBeginDate: string; serviceEndDate: string; payoutDate: string; periodStatus: LedgerPeriodStatus; netAmount: string; grossAmount: string; guaranteedAmount: string; amountAtRisk: string; }
function utcDayDifference(from: string, to: string): number { return Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / 86400000); }
function utcPlusDays(date: string, days: number): string { const d = new Date(`${date}T00:00:00Z`); d.setUTCDate(d.getUTCDate() + days); return d.toISOString().slice(0, 10); }
export async function getServicePeriodLedger(client: CccapClient, scope: DateScope, asOfDate: string, options: { periodCount?: number } = {}): Promise<{ periods: LedgerPeriodEntry[]; sourceRetrievedAt: string }> {
  // Five periods is enough to cover the current month plus one prior.
  const count = options.periodCount ?? 5;
  const response = record(await client.getServicePeriods({ ...scope, limitOne: false }), "Service periods");
  const selected = array(response.servicePeriods, "Service periods").slice(0, count).map((value) => { const row = record(value, "Service period"); return { servicePeriodId: String(row.servicePeriodId), serviceBeginDate: String(row.serviceBeginDate), serviceEndDate: String(row.serviceEndDate) }; });
  const results = await Promise.all(selected.map(async (period) => ({ period, result: record(await getPaymentAnalysis(client, { dateFilter: "DATE_RANGE", dateFrom: period.serviceBeginDate, dateTo: period.serviceEndDate }, "CUSTOM_RANGE", asOfDate), "Payment evaluation") })));
  const periods = results.map(({ period, result }) => { const payment = record(result.payment, "Evaluated payment"); const payoutDate = typeof payment.payout_date === "string" ? payment.payout_date : computePayoutDate(period.serviceEndDate); // Fallback is non-fatal for older evaluator output.
    const duplicatePaid = payment.status === "DUPLICATE_GUARD" && (payment.existing_status === "PAID" || payment.existing_status === "4");
    const periodStatus: LedgerPeriodStatus = asOfDate < period.serviceEndDate ? "IN_PROGRESS" : duplicatePaid ? "PAID" : asOfDate < utcPlusDays(period.serviceEndDate, 5) ? "PENDING_CONFIRMATION" : asOfDate < payoutDate ? "EXPECTED_AWAITING_PAYOUT" : "EXPECTED_AWAITING_PAYOUT";
    return { ...period, payoutDate, periodStatus, netAmount: String(payment.amount ?? "0.00"), grossAmount: String(payment.gross_amount ?? "0.00"), guaranteedAmount: String(payment.guaranteed_amount ?? "0.00"), amountAtRisk: String(payment.amount_at_risk ?? "0.00") }; });
  return { periods, sourceRetrievedAt: new Date().toISOString() };
}
export async function getUpcomingPayoutDetail(client: CccapClient, scope: DateScope, asOfDate: string): Promise<{ entry: LedgerPeriodEntry | undefined; daysUntilPayout: number | undefined; sourceRetrievedAt: string }> {
  const ledger = await getServicePeriodLedger(client, scope, asOfDate); const entry = ledger.periods.filter((period) => period.periodStatus !== "PAID" && period.payoutDate >= asOfDate).sort((a, b) => a.payoutDate.localeCompare(b.payoutDate))[0]; return { entry, daysUntilPayout: entry ? utcDayDifference(asOfDate, entry.payoutDate) : undefined, sourceRetrievedAt: ledger.sourceRetrievedAt };
}

export interface PeriodComparisonCategoryDelta { label: string; periodOneAmount: string; periodTwoAmount: string; deltaAmount: string; deltaPct: string | null; }
export interface PeriodComparisonResult {
  periodOne: { servicePeriodId: string; serviceBeginDate: string; serviceEndDate: string; netAmount: string; grossAmount: string };
  periodTwo: { servicePeriodId: string; serviceBeginDate: string; serviceEndDate: string; netAmount: string; grossAmount: string };
  netDeltaAmount: string; netDeltaPct: string | null; byCategory: PeriodComparisonCategoryDelta[]; byCounty: PeriodComparisonCategoryDelta[]; significantDeltaThresholdPct: number; flaggedDeltas: PeriodComparisonCategoryDelta[]; sourceRetrievedAt: string;
}
type ComparisonScope = { dateFrom: string; dateTo: string } | { servicePeriodId: string };
function comparisonNumber(value: unknown): number { const n = typeof value === "number" ? value : Number(value); return Number.isFinite(n) ? n : 0; }
function comparisonRows(value: unknown, key: string): Record<string, unknown>[] { const root = value && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : undefined; const rows = root && Array.isArray(root[key]) ? root[key] : []; return rows.filter((row): row is Record<string, unknown> => Boolean(row) && typeof row === "object" && !Array.isArray(row)); }
function comparisonRollup(result: RecordValue, key: "categories" | "counties"): Record<string, unknown>[] { const payment = record(result.payment, "Evaluated payment"); const view = payment.summary_view && typeof payment.summary_view === "object" && !Array.isArray(payment.summary_view) ? payment.summary_view : undefined; const rows = view ? comparisonRows(view, key) : []; return rows.length > 0 ? rows : (Array.isArray(payment.summary) ? payment.summary.filter((row): row is Record<string, unknown> => Boolean(row) && typeof row === "object" && !Array.isArray(row)) : []); }
function comparisonDeltas(firstResult: RecordValue, secondResult: RecordValue, key: "categories" | "counties"): PeriodComparisonCategoryDelta[] { const firstRows = comparisonRollup(firstResult, key); const secondRows = comparisonRollup(secondResult, key); const map = new Map<string, [number, number]>(); for (const [index, rows] of [[0, firstRows], [1, secondRows]] as const) for (const row of rows) { const label = String(row.label ?? row.county_name ?? "Unavailable from the current source"); const pair = map.get(label) ?? [0, 0]; pair[index] += comparisonNumber(row.amount); map.set(label, pair); } return [...map.entries()].map(([label, [one, two]]) => { const delta = two - one; return { label, periodOneAmount: one.toFixed(2), periodTwoAmount: two.toFixed(2), deltaAmount: delta.toFixed(2), deltaPct: one === 0 ? null : ((delta / one) * 100).toFixed(1) }; }); }
function comparisonPeriod(result: RecordValue): PeriodComparisonResult["periodOne"] { const payment = record(result.payment, "Evaluated payment"); const period = record(result.servicePeriod, "Service period"); return { servicePeriodId: String(period.servicePeriodId ?? period.id ?? ""), serviceBeginDate: String(period.serviceBeginDate ?? period.start_date ?? ""), serviceEndDate: String(period.serviceEndDate ?? period.end_date ?? ""), netAmount: String(payment.amount ?? "0.00"), grossAmount: String(payment.gross_amount ?? "0.00") }; }
export async function comparePaymentPeriods(client: CccapClient, periodOneScope: ComparisonScope, periodTwoScope: ComparisonScope, asOfDate: string, options: { significantDeltaThresholdPct?: number } = {}): Promise<PeriodComparisonResult> {
  const scope = (value: ComparisonScope): DateScope => { if ("servicePeriodId" in value) throw new Error("servicePeriodId comparison scope is not supported; use dateFrom and dateTo"); return { dateFilter: "DATE_RANGE", dateFrom: value.dateFrom, dateTo: value.dateTo }; };
  const [firstResult, secondResult] = await Promise.all([getPaymentAnalysis(client, scope(periodOneScope), "CUSTOM_RANGE", asOfDate, { detailPage: 1 }), getPaymentAnalysis(client, scope(periodTwoScope), "CUSTOM_RANGE", asOfDate, { detailPage: 1 })]);
  const first = record(firstResult, "Payment evaluation"); const second = record(secondResult, "Payment evaluation"); const one = comparisonPeriod(first); const two = comparisonPeriod(second); const netOne = comparisonNumber(one.netAmount); const netTwo = comparisonNumber(two.netAmount); const netDelta = netTwo - netOne; const threshold = options.significantDeltaThresholdPct ?? 15; const byCategory = comparisonDeltas(first, second, "categories"); const byCounty = comparisonDeltas(first, second, "counties"); const flaggedDeltas = [...byCategory, ...byCounty].filter((row) => row.deltaPct !== null && Math.abs(Number(row.deltaPct)) >= threshold).sort((a, b) => Math.abs(Number(b.deltaAmount)) - Math.abs(Number(a.deltaAmount))); return { periodOne: one, periodTwo: two, netDeltaAmount: netDelta.toFixed(2), netDeltaPct: netOne === 0 ? null : ((netDelta / netOne) * 100).toFixed(1), byCategory, byCounty, significantDeltaThresholdPct: threshold, flaggedDeltas, sourceRetrievedAt: new Date().toISOString() };
}