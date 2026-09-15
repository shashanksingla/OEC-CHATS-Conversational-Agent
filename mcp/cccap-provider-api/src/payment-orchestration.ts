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

function datePart(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value.slice(0, 10) : undefined;
}

function dateWithinPeriod(value: unknown, periodStart: string, periodEnd: string): boolean {
  const date = datePart(value);
  return date !== undefined && date >= periodStart && date <= periodEnd;
}

function scheduleReferences(schedule: RecordValue): Set<string> {
  return new Set<string>([
    schedule.Authorization__c,
    schedule.authorization_id,
    schedule.authorization_name,
    schedule.CI_Authorization_Id__c,
    schedule.IDN_AUTH__c,
    schedule.Authorization_Id__c,
  ]
    .filter((value): value is string | number =>
      (typeof value === "string" && value.length > 0) || typeof value === "number",
    )
    .map(String));
}

export function scopeScheduleData(
  scheduleData: unknown,
  serviceBeginDate: string,
  serviceEndDate: string,
): { data: RecordValue; rows: RecordValue[] } {
  const source = record(scheduleData, "Schedules");
  const rows = array(source.schedules, "Schedules")
    .map((value, index) => record(value, `Schedule[${index}]`))
    .filter((schedule) => dateWithinPeriod(
      schedule.CI_Authorization_Date__c ?? schedule.work_date,
      serviceBeginDate,
      serviceEndDate,
    ));
  return { data: { ...source, schedules: rows }, rows };
}

export function scopeAuthorizationDataToSchedules(
  authorizationData: unknown,
  schedules: RecordValue[],
): RecordValue {
  const source = record(authorizationData, "Authorizations");
  const normalizedAuthorizations = array(
    source.normalizedAuthorizations,
    "Normalized authorizations",
  );
  const scheduleReferencesSet = new Set(schedules.flatMap((schedule) => [...scheduleReferences(schedule)]));
  let scopedAuthorizations = normalizedAuthorizations.filter((value, index) => {
    const row = record(value, `Normalized authorization[${index}]`);
    const authorization = record(row.authorization, `Authorization[${index}]`);
    return [authorization.Id, authorization.Name, authorization.IDN_EXTNL__c]
      .filter((reference): reference is string | number =>
        (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
      )
      .map(String)
      .some((reference) => scheduleReferencesSet.has(reference));
  });
  // Some already-filtered authorization responses omit the external/name
  // fields from the authorization row and expose only one validated record.
  // Keep that single record when the selected period has schedules; never
  // broaden a multi-record response across an unresolved mapping.
  if (scopedAuthorizations.length === 0 && schedules.length > 0) {
    scopedAuthorizations = normalizedAuthorizations.filter((value, index) => {
      const row = record(value, `Normalized authorization[${index}]`);
      const authorization = record(row.authorization, `Authorization[${index}]`);
      const match = row.fiscalScheduleMatch;
      return typeof authorization.Id === "string"
        && record(match, `Fiscal schedule match[${index}]`).status === "MATCHED";
    });
  }
  if (scopedAuthorizations.length === 0 && schedules.length > 0) {
    scopedAuthorizations = normalizedAuthorizations;
  }
  const retainedReferences = new Set(scopedAuthorizations.flatMap((value) => {
    const row = record(value, "Normalized authorization");
    const authorization = record(row.authorization, "Authorization");
    return [authorization.Id, authorization.Name, authorization.IDN_EXTNL__c]
      .filter((reference): reference is string | number =>
        (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
      )
      .map(String);
  }));
  const filterLinkedRows = (value: unknown): unknown => {
    if (!Array.isArray(value) || retainedReferences.size === 0) return value;
    return value.filter((entry) => {
      const row = record(entry, "Authorization-linked row");
      const references = [row.idn_auth__c, row.authorization_id, row.Authorization__c, row.authorizationId]
        .filter((reference): reference is string | number =>
          (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
        )
        .map(String);
      return references.length === 0 || references.some((reference) => retainedReferences.has(reference));
    });
  };
  return {
    ...source,
    normalizedAuthorizations: scopedAuthorizations,
    ...(source.authorizationCopays ? { authorizationCopays: filterLinkedRows(source.authorizationCopays) } : {}),
    ...(source.encumbrances ? { encumbrances: filterLinkedRows(source.encumbrances) } : {}),
    ...(source.slotContracts ? { slotContracts: filterLinkedRows(source.slotContracts) } : {}),
  };
}

export function filterPaymentSchedules(
  schedules: RecordValue[],
  filters: { childNames?: string[]; authNames?: string[] },
): RecordValue[] {
  const childNames = filters.childNames ? new Set(filters.childNames) : undefined;
  const authNames: Set<string> | undefined = filters.authNames ? new Set(filters.authNames.map(String)) : undefined;
  if (!childNames && !authNames) return schedules;
  const hasRequestedAuthReference = authNames && schedules.some((schedule) =>
    [...scheduleReferences(schedule)].some((reference) => authNames.has(reference)),
  );
  return schedules.filter((schedule) => {
    const childName = schedule.child_name ?? schedule.Contact_Name__c ?? schedule.Child_Name__c;
    const childMatches = !childNames || (typeof childName === "string" && childNames.has(childName));
    const references = scheduleReferences(schedule);
    const authMatches = !authNames || !hasRequestedAuthReference || [...references].some((reference) => authNames.has(reference));
    return childMatches && authMatches;
  });
}
// NEXT_PAYOUT/LAST_PAYOUT/PAYOUT_LEDGER never reach getPaymentAnalysis - they
// are intercepted in server.ts and routed to getUpcomingPayoutDetail /
// getLastPayoutDetail / getServicePeriodLedger instead. They remain in this
// union only so PaymentView stays the single source of truth for every
// schema-level view name server.ts can receive.
export type PaymentView = "STATUS" | "NEXT_PAYOUT" | "LAST_PAYOUT" | "PAYOUT_LEDGER" | "CURRENT_WEEK_FORECAST" | "CUSTOM_RANGE";

export async function getPaymentAnalysis(
  client: CccapClient,
  scope: DateScope,
  view: PaymentView = "STATUS",
  asOfDate = new Date().toISOString().slice(0, 10),
  // knownServicePeriodId: when a CUSTOM_RANGE caller already knows the real
  // Salesforce service-period ID for this exact date range (e.g. the ledger,
  // which retrieved it from client.getServicePeriods() before calling here),
  // pass it through so existing-payment/duplicate detection in the Python
  // engine (which matches on service_period.id) can actually find a real
  // record. Optional and backward-compatible: any other CUSTOM_RANGE caller
  // (e.g. comparePaymentPeriods) that doesn't have a real ID keeps getting
  // the synthetic "CUSTOM:{from}:{to}" placeholder exactly as before.
  // knownPaymentReleaseDate: same idea, for the real Apex-sourced payout
  // date (ServicePeriodService.cls's DTE_BATCH_FILE_PMT__c) - lets a
  // CUSTOM_RANGE call (e.g. from getServicePeriodLedger, which already
  // resolved the real service period) thread the true release date through
  // instead of falling back to compute_payout_date()'s formula.
  filters: { childNames?: string[]; authNames?: string[]; countyNames?: string[]; grouping?: "SERVICE_PERIOD" | "COUNTY" | "CHILD" | "CATEGORY"; detailDepth?: "SUMMARY" | "DETAIL"; detailPage?: number; detailPageSize?: number; excludedOnly?: boolean; knownServicePeriodId?: string; knownPaymentReleaseDate?: string } = {},
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
          servicePeriodId: filters.knownServicePeriodId ?? `CUSTOM:${scope.dateFrom}:${scope.dateTo}`,
          serviceBeginDate: scope.dateFrom,
          serviceEndDate: scope.dateTo,
          ...(filters.knownPaymentReleaseDate ? { paymentReleaseDate: filters.knownPaymentReleaseDate } : {}),
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
  // CUSTOM_RANGE and every other non-STATUS view resolved to the same
  // date-range scope (the selected service period's own dates) - collapsed
  // from two identical ternary branches into one.
  const sourceScope: DateScope = view === "STATUS"
    ? scope
    : { dateFilter: "DATE_RANGE", dateFrom: serviceBeginDate, dateTo: serviceEndDate };
  const providerContext = initialization;
  const { countyIds } = normalizeProviderContext(providerContext);
  // When the caller already named specific authorizations (an explicit
  // "show me auth X" / child-narrowed request), pass authNames straight
  // into the schedule fetch so only auth-relevant schedules come back in
  // the first place - narrower and cheaper than fetching every schedule in
  // scope and filtering client-side afterward via filterPaymentSchedules
  // below, and it keeps every later derivation (scheduleRateTypes,
  // scheduleCareDates, authorization lookups) working from an
  // already-scoped row set instead of the full unfiltered one.
  const rawScheduleData = await client.getSchedules({
    ...sourceScope,
    ...(filters.authNames && filters.authNames.length > 0 ? { authNames: filters.authNames } : {}),
  });
  const scopedSchedules = scopeScheduleData(rawScheduleData, serviceBeginDate, serviceEndDate);
  let scheduleRows = filterPaymentSchedules(scopedSchedules.rows, filters);
  let scheduleData = { ...scopedSchedules.data, schedules: scheduleRows };
  // An authorization's schedule can carry a DIFFERENT rate type per day
  // across one service period (live-confirmed: one authorization's 7 days
  // in a week used rate types 31/31/31/1/91/43/37 - overnight, regular,
  // out-of-county, evening, weekend all under the same authorization).
  // Collapsing to one rate type per authorization key (previously via
  // Object.fromEntries, which keeps only the LAST value seen for a
  // duplicate key) matched a fiscal schedule/rate-row selection against
  // only ONE of those rate types and silently dropped every other day's
  // fiscal rate row downstream - the confirmed root cause of the
  // recurring "rate unavailable" exclusions. Every rate type actually
  // used by each authorization's schedule rows must be collected, not
  // just the last one encountered.
  const scheduleRateTypesByKey = new Map<string, Set<string>>();
  for (const value of scheduleRows) {
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
    if (typeof rateType !== "string" && typeof rateType !== "number") continue;
    for (const authorizationKey of authorizationKeys) {
      const key = String(authorizationKey);
      const set = scheduleRateTypesByKey.get(key) ?? new Set<string>();
      set.add(String(rateType));
      scheduleRateTypesByKey.set(key, set);
    }
  }
  const scheduleRateTypes = Object.fromEntries(
    [...scheduleRateTypesByKey.entries()].map(([key, set]) => [key, [...set]]),
  );
  const scheduleCareDates: Record<string, string> = {};
  scheduleRows.forEach((value) => {
    const schedule = record(value, "Schedule");
    const careDate = datePart(schedule.CI_Authorization_Date__c ?? schedule.work_date);
    if (!careDate) return;
    for (const reference of scheduleReferences(schedule)) {
      if (!scheduleCareDates[reference] || careDate < scheduleCareDates[reference]) {
        scheduleCareDates[reference] = careDate;
      }
    }
  });
  const authorizationNames = [...new Set(scheduleRows.flatMap((value) => {
    const schedule = record(value, "Schedule");
    const authorizationName = schedule.authorization_name ?? schedule.CI_Authorization_Id__c;
    return typeof authorizationName === "string" || typeof authorizationName === "number"
      ? [String(authorizationName)]
      : [];
  }))];
  const [rawAuthorizationData, countyData, fiscalData, holidayData, paymentData, vacantSlotData] = await Promise.all([
    client.getAuthorizations({
      ...sourceScope,
      countyIds,
      ...(authorizationNames.length > 0 ? { authNames: authorizationNames } : {}),
      careDate: serviceBeginDate,
      scheduleRateTypes,
      scheduleCareDates,
    }),
    client.getCountyData({ ...sourceScope, countyIds }),
    client.getFiscalRates(sourceScope),
    client.getHolidayList(sourceScope),
    client.getPaymentHistory(sourceScope),
    typeof client.getVacantSlots === "function"
      ? client.getVacantSlots({ ...sourceScope, countyIds })
      : Promise.resolve({ vacantSlots: [] }),
  ]);
  const scopedAuthorizationData = scopeAuthorizationDataToSchedules(rawAuthorizationData, scheduleRows);
  const scopedAuthorizationRows = Array.isArray(scopedAuthorizationData.normalizedAuthorizations)
    ? scopedAuthorizationData.normalizedAuthorizations
    : [];
  const authorizationData: RecordValue = scopedAuthorizationRows.length > 0 || scheduleRows.length === 0
    ? (scheduleRows.length === 0 && (filters.authNames || filters.childNames) ? record(rawAuthorizationData, "Authorizations") : scopedAuthorizationData)
    : record(rawAuthorizationData, "Authorizations");
  const normalizedAuthorizationRows = Array.isArray(authorizationData.normalizedAuthorizations)
    ? authorizationData.normalizedAuthorizations
    : [];
  const verifiedAuthorizationIds = new Set(normalizedAuthorizationRows.flatMap((value) => {
    const row = record(value, "Normalized authorization");
    const authorization = record(row.authorization, "Authorization");
    const clientRecord = authorization.IDN_CLIENT__r;
    const dob = clientRecord && typeof clientRecord === "object" && !Array.isArray(clientRecord)
      ? (clientRecord as RecordValue).DTE_DOB__c
      : undefined;
    const hasDob = typeof dob === "string" && dob.length > 0;
    return hasDob && typeof authorization.Id === "string" ? [authorization.Id] : [];
  }));
  if (verifiedAuthorizationIds.size > 0 && verifiedAuthorizationIds.size < normalizedAuthorizationRows.length) {
    scheduleRows = scheduleRows.filter((schedule) => [...scheduleReferences(schedule)].some((reference) => verifiedAuthorizationIds.has(reference)));
    scheduleData = { ...scheduleData, schedules: scheduleRows };
    authorizationData.normalizedAuthorizations = normalizedAuthorizationRows.filter((value) => {
      const row = record(value, "Normalized authorization");
      const authorization = record(row.authorization, "Authorization");
      return typeof authorization.Id === "string" && verifiedAuthorizationIds.has(authorization.Id);
    });
    for (const key of ["authorizationCopays", "encumbrances", "slotContracts"] as const) {
      const linkedRows = authorizationData[key];
      if (!Array.isArray(linkedRows)) continue;
      authorizationData[key] = linkedRows.filter((value) => {
        const row = record(value, "Authorization-linked row");
        const references = [row.idn_auth__c, row.authorization_id, row.Authorization__c, row.authorizationId]
          .filter((reference): reference is string | number =>
            (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
          )
          .map(String);
        return references.length === 0 || references.some((reference) => verifiedAuthorizationIds.has(reference));
      });
    }
  }
  const { payload, servicePeriod: canonicalServicePeriod, vacantSlotMappingGaps, authorizationMappingGaps } = normalizePaymentSourceBundle({
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
  const authNames: Set<string> | undefined = filters.authNames ? new Set(filters.authNames.map(String)) : undefined;
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
    const requestedAuthNames = authNames;
    const authorizationIdsByName = new Set(
      normalizedAuthorizations.flatMap((value) => {
        const row = record(value, "Normalized authorization");
        const authorization = record(row.authorization, "Authorization");
        const references = [authorization.Id, authorization.Name, authorization.IDN_EXTNL__c]
          .filter((reference): reference is string => typeof reference === "string" && reference.length > 0);
        const authorizationId = typeof authorization.Id === "string" ? authorization.Id : undefined;
        const scheduleMatchesRequestedName = authNames && authorizationId !== undefined && scheduleRows.some((schedule) => {
          const scheduleRefs = scheduleReferences(schedule);
          return scheduleRefs.has(authorizationId) && [...scheduleRefs].some((reference: string) => requestedAuthNames?.has(reference) === true);
        });
        const serverScopedSingleAuthorization = authNames && normalizedAuthorizations.length === 1 && authorizationId !== undefined && !scheduleRows.some((schedule) =>
          [...scheduleReferences(schedule)].some((reference: string) => requestedAuthNames?.has(reference) === true),
        );
        return requestedAuthNames && (references.some((reference) => requestedAuthNames.has(String(reference))) || scheduleMatchesRequestedName || serverScopedSingleAuthorization) && authorizationId !== undefined
          ? [authorizationId]
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
  // Opt-in diagnostic for the known "ledger At-risk figures escalate
  // implausibly across adjacent periods" defect (Fix Handoff Section 4):
  // logs the exact requested date range and the attendance-day count/date
  // span actually reaching the evaluator for THIS call, so a real ledger
  // run (getServicePeriodLedger issuing one CUSTOM_RANGE call per period)
  // can be inspected without guessing. Never enabled unless explicitly set
  // - this must not add overhead or noise to normal request handling.
  if (process.env.CARE_PAY_DEBUG_LEDGER === "1") {
    const debugDays = payload.attendance_days as unknown[];
    const debugDates = debugDays
      .map((day) => (day as Record<string, unknown>).service_date)
      .filter((date): date is string => typeof date === "string")
      .sort();
    console.error(
      `[ledger-debug] view=${view} requestedRange=${sourceScope.dateFrom ?? "n/a"}..${sourceScope.dateTo ?? "n/a"} ` +
      `attendanceDayCount=${debugDays.length} actualDateSpan=${debugDates[0] ?? "n/a"}..${debugDates[debugDates.length - 1] ?? "n/a"}`,
    );
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
    const showDetail = filters.detailDepth === "DETAIL" || filters.detailPage !== undefined || filters.detailPageSize !== undefined;
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
        ...(filters.countyNames ? { countyNames: filters.countyNames } : {}),
        ...(filters.grouping ? { grouping: filters.grouping } : {}),
        ...(filters.detailDepth ? { detailDepth: filters.detailDepth } : {}),
        ...(filters.detailPageSize ? { detailPageSize: filters.detailPageSize } : {}),
        ...(filters.excludedOnly ? { excludedOnly: true } : {}),
      },
      ...(topChild ? { highestImpactChildName: topChild.name, highestImpactRankedByDollars: topChild.rankedByDollars } : {}),
      ...(vacantSlotMappingGaps > 0 ? { vacantSlotMappingGaps } : {}),
      ...(authorizationMappingGaps > 0 ? { authorizationMappingGaps } : {}),
      scope: sourceScope,
      paymentView: view,
      servicePeriod: canonicalServicePeriod,
      sourceRetrievedAt,
      situation: await buildSituationEnvelope(result.payment, "payment-analysis", sourceScope, sourceRetrievedAt),
    };
  } finally { await rm(directory, { recursive: true, force: true }); }
}

// OVERDUE: the confirmation window has closed and the computed payoutDate
// has already passed, but no paid record was found - distinct from
// EXPECTED_AWAITING_PAYOUT (confirmation window closed, payoutDate still
// >= today). Kept as its own status rather than folded into
// EXPECTED_AWAITING_PAYOUT so a provider browsing the ledger can see a
// stuck/overdue period called out, and so Next Payout can exclude it by
// status rather than by an easy-to-miss date comparison alone.
export type LedgerPeriodStatus = "NOT_YET_STARTED" | "IN_PROGRESS" | "PENDING_CONFIRMATION" | "EXPECTED_AWAITING_PAYOUT" | "OVERDUE" | "PAID";
// Net amount is populated ONLY for a released (PAID) period - it is the
// reconciled, historical, already-paid figure. Calculated amount is
// populated ONLY for a period that has not yet been released - it is the
// engine's current best estimate and is expected to change. A period row
// must never carry both a nonzero netAmount and a nonzero calculatedAmount;
// exactly one of the two is meaningful per periodStatus, enforced in the
// mapping below rather than left to the renderer to infer.
// countyComposition carries payment.summary_view.county_composition through
// from the underlying per-period payment analysis, so a single-entry ledger
// response (NEXT_PAYOUT/LAST_PAYOUT) can render the same county-level
// breakdown table already shown for multi-period/forecast views, instead of
// showing only a bare total. categories does the same for the "Payment by
// category" (Care/Absence/Drop-in/Holiday) breakdown, which the ledger
// formatter previously never rendered at all.
export interface LedgerPeriodEntry { servicePeriodId: string; serviceBeginDate: string; serviceEndDate: string; payoutDate: string; periodStatus: LedgerPeriodStatus; netAmount: string | undefined; calculatedAmount: string | undefined; grossAmount: string; guaranteedAmount: string; amountAtRisk: string; countyComposition: unknown[] | undefined; categories: unknown[] | undefined; }
function utcDayDifference(from: string, to: string): number { return Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / 86400000); }
function utcPlusDays(date: string, days: number): string { const d = new Date(`${date}T00:00:00Z`); d.setUTCDate(d.getUTCDate() + days); return d.toISOString().slice(0, 10); }
type PaymentLedgerFilters = { childNames?: string[]; authNames?: string[]; countyNames?: string[] };
export async function getServicePeriodLedger(client: CccapClient, scope: DateScope, asOfDate: string, options: { periodCount?: number; unbounded?: boolean; filters?: PaymentLedgerFilters; isolateFailures?: boolean } = {}): Promise<{ periods: LedgerPeriodEntry[]; sourceRetrievedAt: string }> {
  // Multi-period views (PAYOUT_LEDGER, LAST_PAYOUT's backward search) need
  // more than one candidate and should keep degrading gracefully - one bad
  // period is dropped, the rest still render. A plain "upcoming payment"/
  // NEXT_PAYOUT ask is different: it asks for exactly ONE definite,
  // real-world period (the soonest one whose payout date >= today), never a
  // multi-period fetch, per the explicit product decision that multiple
  // service periods are only ever fetched for a monthly/forecast ask or an
  // explicit multi-period request - so its default here is 1, not 5, and
  // its failures are never silently isolated (see isolateFailures below).
  const count = options.periodCount ?? (options.unbounded ? 1 : 5);
  // isolateFailures (default true, preserving existing PAYOUT_LEDGER/
  // LAST_PAYOUT behavior): a failed period is dropped from the ledger and
  // logged rather than failing the whole multi-period response. Set to
  // false by the strict single-period NEXT_PAYOUT caller below - there is
  // only one candidate, and if it fails, silently dropping it would make
  // getUpcomingPayoutDetail return "no next payout" or (worse) silently
  // substitute a LATER period as if it were "next," which is a real
  // financial-correctness bug, not a display gap. The failure must surface
  // as an explicit, period-scoped error instead.
  const isolateFailures = options.isolateFailures ?? true;
  await client.initialize();
  // unbounded: used exclusively by getUpcomingPayoutDetail (the true "next
  // payout" search). Defaulting the underlying fetch to THIS_MONTH (the
  // non-unbounded branch below) previously excluded a period that began in
  // a PRIOR calendar month even when its real payout date fell on/after
  // today - the period simply never reached the candidate list, so "next
  // payout" silently skipped past the actually-soonest unpaid period. The
  // `paymentAfter: "TODAY"` filter queries DTE_BATCH_FILE_PMT__c > today
  // directly (the real release-date field, confirmed correct - see
  // ServicePeriodService.cls) with no lower bound on service dates at all,
  // ordered ascending by that same field, so this always finds the
  // genuinely soonest still-unpaid period regardless of which month its
  // service dates started in.
  const ledgerScope: DateScope & { paymentAfter?: "TODAY" } = options.unbounded
    ? { paymentAfter: "TODAY" }
    : {
        dateFilter: scope.dateFilter ?? "THIS_MONTH",
        ...(scope.periodCount !== undefined ? { periodCount: scope.periodCount } : {}),
        ...(scope.dateFrom !== undefined ? { dateFrom: scope.dateFrom } : {}),
        ...(scope.dateTo !== undefined ? { dateTo: scope.dateTo } : {}),
      };
  // limitOne must track count, not be hardcoded false: when only one
  // period is actually wanted (count === 1, the strict NEXT_PAYOUT case),
  // the server-side single-record path is what correctly resolves "the"
  // next period - fetching a false-limited list and slicing to 1 client-
  // side was not equivalent and returned the wrong result.
  const response = record(await client.getServicePeriods({ ...ledgerScope, limitOne: count === 1 }), "Service periods");
  // paymentReleaseDate carries the real Apex-sourced payout date
  // (ServicePeriodService.cls's DTE_BATCH_FILE_PMT__c, or its own ISO-week
  // fallback) through to getPaymentAnalysis below, so the ledger's payoutDate
  // reflects the true release date instead of a locally-recomputed guess.
  const selected = array(response.servicePeriods, "Service periods").slice(0, count).map((value) => { const row = record(value, "Service period"); return { servicePeriodId: String(row.servicePeriodId), serviceBeginDate: String(row.serviceBeginDate), serviceEndDate: String(row.serviceEndDate), paymentReleaseDate: typeof row.paymentReleaseDate === "string" ? row.paymentReleaseDate : undefined }; });
  // Pass the REAL service-period ID (already known from client.getServicePeriods()
  // above) through to getPaymentAnalysis, so the Python engine's duplicate/
  // existing-payment lookup (which matches on service_period.id) can actually
  // find a real record for this period instead of never matching the
  // synthetic "CUSTOM:{from}:{to}" ID a bare CUSTOM_RANGE call would otherwise
  // get - this is what makes an early-paid period (paid before its payout
  // date) detectable as PAID in the ledger.
  // Fault isolation: a single period whose source data cannot be evaluated
  // (e.g. a missing child date of birth - a data-quality gap, not something
  // this layer should guess an age band for) must not take down every other
  // period in the same ledger/NEXT_PAYOUT call. Promise.all previously
  // rejected the whole batch on the first such error. Each period's
  // evaluation is now isolated; a failed period is dropped from the ledger
  // (never fabricated) and logged for diagnosis, while every period that
  // did evaluate successfully still renders normally.
  const settledResults = await Promise.all(selected.map(async (period) => {
    try {
      const result = record(await getPaymentAnalysis(client, { dateFilter: "DATE_RANGE", dateFrom: period.serviceBeginDate, dateTo: period.serviceEndDate }, "CUSTOM_RANGE", asOfDate, {
        knownServicePeriodId: period.servicePeriodId,
        ...(period.paymentReleaseDate ? { knownPaymentReleaseDate: period.paymentReleaseDate } : {}),
        ...(options.filters?.childNames ? { childNames: options.filters.childNames } : {}),
        ...(options.filters?.authNames ? { authNames: options.filters.authNames } : {}),
        ...(options.filters?.countyNames ? { countyNames: options.filters.countyNames } : {}),
      }), "Payment evaluation");
      return { period, result, error: undefined };
    } catch (error) {
      const message = `Service period ${period.servicePeriodId} (${period.serviceBeginDate}..${period.serviceEndDate}) could not be evaluated: `
        + (error instanceof Error ? error.message : String(error));
      if (!isolateFailures) {
        // Strict single-period caller (NEXT_PAYOUT): never drop this
        // silently - that would either report "no upcoming payout" when
        // one genuinely exists, or (worse) let a later period be
        // mistaken for "next" once dropped from the candidate list. Let
        // the real, period-scoped error propagate.
        throw new Error(message);
      }
      console.error(`[service-period-ledger] ${message} - excluded from the ledger`);
      return { period, result: undefined, error };
    }
  }));
  const results = settledResults.filter(
    (entry): entry is { period: typeof entry.period; result: RecordValue; error: undefined } => entry.result !== undefined,
  );
  // payoutDate priority: real Apex-sourced release date (period.paymentReleaseDate)
  // -> Python engine's own resolved payout_date (which itself now prefers the
  // same real date when threaded through the canonical payload) -> local
  // formula as absolute last resort (only if neither of the above resolved).
  const periods = results.map(({ period, result }) => { const payment = record(result.payment, "Evaluated payment"); const payoutDate = period.paymentReleaseDate ?? (typeof payment.payout_date === "string" ? payment.payout_date : computePayoutDate(period.serviceEndDate));
    // TEMPORARY, per explicit product decision (2026-09-15): the
    // getPaymentHistory-derived "existing payment already found for this
    // exact period" check (duplicatePaid) is blocked here. It was verified
    // against live org data to be a CORRECT match (a genuine early-paid
    // period, real T_PAYMT__c/sub-payment records) - not a bug - but its
    // real-world side effect (the single-fetched NEXT_PAYOUT candidate
    // reads as "already paid" and the flow reports no upcoming payout even
    // though later periods are genuinely still pending) was judged worse
    // than relying on calculation/date-based settlement alone for now.
    // periodStatus below therefore only ever reaches PAID via isSettled
    // (the payout date itself having passed), never via an actual-payment
    // lookup. Revisit deliberately - do not silently restore.
    const duplicatePaid = false;
    const isSettled = payment.is_settled === true;
    const settledAmount = typeof payment.settled_amount === "string" || typeof payment.settled_amount === "number"
      ? String(payment.settled_amount)
      : undefined;
    // A period whose BEGIN date is still in the future hasn't started yet -
    // distinct from IN_PROGRESS, which previously only checked serviceEndDate
    // and so misclassified every future period (not just the current one) as
    // "in progress."
    // OVERDUE: confirmation window has closed (past the PENDING_CONFIRMATION
    // boundary) AND the computed payoutDate has already passed AND no paid
    // record was found - a stuck/unresolved period, distinct from
    // EXPECTED_AWAITING_PAYOUT (confirmation window closed, payoutDate still
    // >= today, simply not due yet). Checked here (payoutDate is already
    // computed above) rather than left for the renderer to infer.
    const periodStatus: LedgerPeriodStatus = asOfDate < period.serviceBeginDate
      ? "NOT_YET_STARTED"
      : asOfDate < period.serviceEndDate
        ? "IN_PROGRESS"
        : (duplicatePaid || isSettled)
          ? "PAID"
          : asOfDate < utcPlusDays(period.serviceEndDate, 5)
            ? "PENDING_CONFIRMATION"
            : asOfDate > payoutDate
              ? "OVERDUE"
              : "EXPECTED_AWAITING_PAYOUT";
    // Once settled, settledAmount (backed by an actual payment record when
    // one exists, otherwise the same calculated net_total the engine already
    // produced) is the figure to show as Net - falling back to payment.amount
    // only if settledAmount was somehow absent despite is_settled being true.
    const amount = periodStatus === "PAID" && settledAmount !== undefined ? settledAmount : String(payment.amount ?? "0.00");
    const summaryView = payment.summary_view && typeof payment.summary_view === "object" && !Array.isArray(payment.summary_view)
      ? payment.summary_view as Record<string, unknown>
      : undefined;
    const countyComposition = Array.isArray(summaryView?.county_composition) ? summaryView.county_composition : undefined;
    const categories = Array.isArray(summaryView?.categories) ? summaryView.categories : undefined;
    return {
      ...period,
      payoutDate,
      periodStatus,
      countyComposition,
      categories,
      // PAID: the duplicate-guarded amount is the reconciled historical
      // figure - show it as Net, and treat this period as settled (no
      // Calculated/At-risk breakdown, since nothing is still pending).
      // Not yet PAID: the same engine figure is only a current estimate -
      // show it as Calculated, never as Net, so a provider never reads an
      // unreleased period's estimate as if it were an authoritative payout.
      netAmount: periodStatus === "PAID" ? amount : undefined,
      calculatedAmount: periodStatus === "PAID" ? undefined : amount,
      grossAmount: String(payment.gross_amount ?? "0.00"),
      guaranteedAmount: String(payment.guaranteed_amount ?? "0.00"),
      amountAtRisk: periodStatus === "PAID" ? "0.00" : String(payment.amount_at_risk ?? "0.00"),
    };
  });
  return { periods, sourceRetrievedAt: new Date().toISOString() };
}
// Next payout: the single unpaid/upcoming period whose payout (release)
// date is soonest. This is the default view for a plain "upcoming payment"
// request - it must never silently expand to the multi-period ledger.
export async function getUpcomingPayoutDetail(client: CccapClient, scope: DateScope, asOfDate: string, filters?: PaymentLedgerFilters): Promise<{ entry: LedgerPeriodEntry | undefined; daysUntilPayout: number | undefined; sourceRetrievedAt: string }> {
  // unbounded: true - "next payout" must search with no month/date bound at
  // all (see getServicePeriodLedger's comment), never the THIS_MONTH
  // default used by the multi-period ledger view. isolateFailures: false -
  // per product decision, NEXT_PAYOUT fetches and evaluates exactly the one
  // real next service period (periodCount defaults to 1 for unbounded
  // calls); a monthly/forecast ask or an explicit multi-period request is
  // the only case that should ever fetch more than one. If that single
  // period cannot be evaluated, the error must surface naming that period,
  // never fall through to a later period as if it were "next."
  const ledger = await getServicePeriodLedger(client, scope, asOfDate, {
    unbounded: true,
    isolateFailures: false,
    ...(filters ? { filters } : {}),
  });
  // "Next payout" must be the soonest period whose payoutDate is actually
  // >= today - filtering only on periodStatus !== "PAID" (the previous
  // behavior) could return a stuck/OVERDUE period whose payoutDate has
  // already passed, if that happened to be the smallest payoutDate among
  // non-PAID periods. OVERDUE periods are excluded by status here too
  // (not just by the date check) so this stays correct even if payoutDate
  // and periodStatus ever disagree for some other reason.
  const entry = ledger.periods
    .filter((period) => period.periodStatus !== "PAID" && period.periodStatus !== "OVERDUE" && period.payoutDate >= asOfDate)
    .sort((a, b) => a.payoutDate.localeCompare(b.payoutDate))[0];
  return { entry, daysUntilPayout: entry ? utcDayDifference(asOfDate, entry.payoutDate) : undefined, sourceRetrievedAt: ledger.sourceRetrievedAt };
}
// Last payout: the single most recently released (PAID) period. Distinct
// capability from Next Payout; surfaced only on explicit provider request,
// never as a standing greeting/snapshot option, per product decision.
export async function getLastPayoutDetail(client: CccapClient, scope: DateScope, asOfDate: string, filters?: PaymentLedgerFilters): Promise<{ entry: LedgerPeriodEntry | undefined; sourceRetrievedAt: string }> {
  const ledger = await getServicePeriodLedger(client, scope, asOfDate, {
    periodCount: 12,
    ...(filters ? { filters } : {}),
  });
  const entry = ledger.periods
    .filter((period) => period.periodStatus === "PAID")
    .sort((a, b) => b.payoutDate.localeCompare(a.payoutDate))[0];
  return { entry, sourceRetrievedAt: ledger.sourceRetrievedAt };
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