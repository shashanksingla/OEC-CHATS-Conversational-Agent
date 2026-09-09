import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { CccapClient, type DateScope } from "./client.js";
import { normalizePaymentSourceBundle } from "./payment-canonical-adapter.js";
import { normalizeProviderContext } from "./provider-context.js";

const execFileAsync = promisify(execFile);
const paymentEvaluatorPath = fileURLToPath(new URL(
  "../../../skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py",
  import.meta.url,
));
type RecordValue = Record<string, unknown>;

function highestImpactChildName(impacts: unknown[], days: unknown[]): string | undefined {
  const rankedImpacts = impacts
    .map((value) => record(value, "Child payment impact"))
    .filter((impact) => typeof impact.child_name === "string")
    .map((impact) => [impact.child_name as string, Number(impact.amount_at_risk) || 0] as const)
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .at(0);
  if (rankedImpacts && rankedImpacts[1] > 0) return rankedImpacts[0];
  const fallback = new Map<string, number>();
  for (const value of days) {
    const day = record(value, "Attendance day");
    if (typeof day.child_name !== "string") continue;
    fallback.set(day.child_name, (fallback.get(day.child_name) ?? 0) + (Number(day.unit_hours) || 0));
  }
  return [...fallback.entries()]
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .at(0)?.[0];
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
export type PaymentView = "STATUS" | "NEXT_PAYOUT" | "CURRENT_WEEK_FORECAST";

export async function getPaymentAnalysis(
  client: CccapClient,
  scope: DateScope,
  view: PaymentView = "STATUS",
  asOfDate = new Date().toISOString().slice(0, 10),
  filters: { childNames?: string[]; authNames?: string[]; detailPage?: number; detailPageSize?: number } = {},
): Promise<unknown> {
  const initialization = view === "STATUS"
    ? record(await client.initialize(scope), "Provider context")
    : undefined;
  const servicePeriodData = await client.getServicePeriods(
    view === "NEXT_PAYOUT" ? { paymentAfter: "TODAY", limitOne: true } :
      view === "CURRENT_WEEK_FORECAST" ? { dateOn: "TODAY", limitOne: true } :
        { ...scope, limitOne: true, dateFilter: scope.dateFilter },
  );
  const servicePeriod = first(record(servicePeriodData, "Service periods").servicePeriods, "Service period");
  const serviceBeginDate = servicePeriod.serviceBeginDate;
  const serviceEndDate = servicePeriod.serviceEndDate;
  if (typeof serviceBeginDate !== "string" || typeof serviceEndDate !== "string") throw new Error("Service period dates are unavailable");
  const sourceScope: DateScope = view === "STATUS" ? scope : { dateFilter: "DATE_RANGE", dateFrom: serviceBeginDate, dateTo: serviceEndDate };
  const providerContext = initialization ?? record(await client.initialize(sourceScope), "Provider context");
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
  const { payload, servicePeriod: canonicalServicePeriod } = normalizePaymentSourceBundle({
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
  const directory = await mkdtemp(join(tmpdir(), "carepay-payment-"));
  const inputPath = join(directory, "payment.json");
  try {
    await writeFile(inputPath, JSON.stringify(payload), "utf8");
    const { stdout } = await execFileAsync("uv", ["run", paymentEvaluatorPath, inputPath], { windowsHide: true });
    const evaluated = JSON.parse(stdout) as { status?: string; result?: unknown; error?: string };
    if (evaluated.status !== "ok" || !evaluated.result) throw new Error(evaluated.error || "Payment evaluation failed");
    const result = evaluated.result as RecordValue;
    const attendance = record(result.attendance, "Evaluated attendance");
    const allDays = Array.isArray(attendance.days) ? attendance.days : [];
    const displayableDays = allDays.filter((value) => {
      const day = record(value, "Attendance day");
      return day.classification !== "NO_CARE";
    });
    const topChildName = highestImpactChildName(
      Array.isArray(result.child_payment_impacts) ? result.child_payment_impacts : [],
      displayableDays,
    );
    delete result.child_payment_impacts;
    const showDetail = filters.detailPage !== undefined || filters.detailPageSize !== undefined;
    const detailPage = filters.detailPage ?? 1;
    const detailPageSize = filters.detailPageSize ?? 25;
    const detailStart = (detailPage - 1) * detailPageSize;
    const pagedAttendance = {
      ...attendance,
      days: showDetail ? displayableDays.slice(detailStart, detailStart + detailPageSize) : [],
    };
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
      },
      ...(topChildName ? { highestImpactChildName: topChildName } : {}),
      scope: sourceScope,
      paymentView: view,
      servicePeriod: canonicalServicePeriod,
      sourceRetrievedAt: new Date().toISOString(),
    };
  } finally { await rm(directory, { recursive: true, force: true }); }
}
