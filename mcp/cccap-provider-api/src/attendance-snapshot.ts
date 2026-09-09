import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { CccapClient, type DateScope } from "./client.js";
import {
  authorizationKey,
  isSalesforceId,
  normalizeAttendanceRiskSchedules,
} from "./attendance-canonical-adapter.js";
import { normalizeProviderContext } from "./provider-context.js";
import { normalizeScheduleAttendance } from "./schedule-normalizer.js";
export { normalizePaymentStatus } from "./payment-schema.js";
export { getPaymentAnalysis } from "./payment-orchestration.js";
const execFileAsync = promisify(execFile);
const evaluatorPath = fileURLToPath(
  new URL(
    "../../../skills/agent-child-care-payment-advisor/scripts/evaluate_attendance_risks.py",
    import.meta.url,
  ),
);

type RecordValue = Record<string, unknown>;

function asRecord(value: unknown): RecordValue | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as RecordValue)
    : undefined;
}

function calendarDates(initialization: RecordValue, holidayData: RecordValue): {
  closureDates: string[];
  holidayDates: string[];
} {
  const closureDates = (Array.isArray(initialization.providerClosures)
    ? initialization.providerClosures
    : Array.isArray(initialization.provider_closures) ? initialization.provider_closures : [])
    .flatMap((value) => {
      const closure = asRecord(value);
      const active = closure?.IND_ACTIVE__c;
      if (active === false || active === 0 || active === "0" || active === "false") return [];
      const date = closure?.DTE_BEGIN_CLOSURE__c ?? closure?.closure_date;
      return typeof date === "string" && date.length > 0 ? [date] : [];
    });
  const holidays = Array.isArray(holidayData.holidayList) ? holidayData.holidayList : [];
  const holidayDates = holidays.flatMap((value) => {
    const holiday = asRecord(value);
    return [holiday?.DTE_HOL__c, holiday?.DTE_OBSERVED_HOL__c]
      .filter((date): date is string => typeof date === "string" && date.length > 0);
  });
  return {
    closureDates: [...new Set(closureDates)],
    holidayDates: [...new Set(holidayDates)],
  };
}

function providerLicenseStatus(initialization: RecordValue): string | undefined {
  const providers = Array.isArray(initialization.providers) ? initialization.providers : [];
  const provider = asRecord(providers[0]);
  const value = provider?.CDE_TYPE_PROVR__c ?? provider?.provider_type;
  return typeof value === "string" && value.length > 0 ? value.trim().toUpperCase() : undefined;
}

function getHolidayData(client: CccapClient, scope: DateScope): Promise<unknown> {
  return typeof client.getHolidayList === "function"
    ? client.getHolidayList(scope)
    : Promise.resolve({ holidayList: [] });
}

export {
  addAuthorizationNamesToSchedules,
  addCanonicalCountyIdToSchedules,
  addDefaultCountyToSchedules,
  addNestedCountyIdToSchedules,
  addProviderQualityTierToSchedules,
  authorizationKey,
  isSalesforceId,
} from "./attendance-canonical-adapter.js";
export { normalizeScheduleAttendance } from "./schedule-normalizer.js";

export function livePaymentReadiness(): RecordValue {
  return {
    status: "BLOCKED",
    ruleVersion: "provider-risk-payment-v1",
    sourceReadiness: "BLOCKED_MISSING_REQUIRED_INPUTS",
    missingInputs: [
      "fiscal_rates",
      "attendance_transactions",
      "parent_confirmations",
      "absence_approvals",
      "existing_sub_payments",
      "slot_contracts",
      "parent_fees",
      "holiday_payment_eligibility",
      "rate_unit_mapping",
      "art_fee_history",
      "care_not_offered_status",
    ],
  };
}

function requireRecord(value: unknown, label: string): RecordValue {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} is unavailable`);
  }
  return value as RecordValue;
}

function requireArray(value: unknown, label: string): unknown[] {
  if (!Array.isArray(value)) {
    throw new Error(`${label} is unavailable`);
  }
  return value;
}

function attendancePeriodLabel(scope: DateScope): string {
  if (scope.dateFilter === "LAST_MONTH") return "Last-month";
  if (scope.dateFilter === "THIS_MONTH") return "Current-month";
  if (scope.dateFilter === "DATE_RANGE") return "Date-range";
  if (scope.dateFilter === "LAST_N_MONTHS" || scope.dateFilter === "LAST_N_DAYS") {
    return "Historical";
  }
  return "Today";
}

export async function getAttendanceRiskSnapshot(
  client: CccapClient,
  providerDisplayName: string,
  scope: DateScope,
  asOfDate: string,
): Promise<unknown> {
  const snapshot = await getAttendanceRiskAnalysis(
    client,
    providerDisplayName,
    scope,
    asOfDate,
  );
  const risk = requireRecord(snapshot.attendanceRisk, "Attendance risk evaluation");
  const today = requireRecord(risk.today, "Today's attendance snapshot");
  const categories = requireRecord(risk.risk_categories, "Attendance risk categories");
  const pending = requireRecord(
    categories.pending_parent_confirmations,
    "Pending parent confirmations",
  );
  const approaching = requireRecord(
    categories.approaching_absence_limits,
    "Approaching absence limits",
  );
  const crossed = requireRecord(
    categories.crossed_absence_limits,
    "Crossed absence limits",
  );
  const numberValue = (value: unknown): number =>
    typeof value === "number" ? value : 0;
  const pendingDays = numberValue(pending.days);
  const pendingChildren = numberValue(pending.children);
  const approachingChildren = numberValue(approaching.children);
  const approachingCounties = numberValue(approaching.counties);
  const approachingDays = approaching.minimum_days_until_exceeded;
  const approachingFinding =
    typeof approachingDays === "number"
      ? `${approachingChildren} child(ren) of ${approachingCounties} counties; within ${approachingDays} day(s) of exceeding the limit`
      : `${approachingChildren} child(ren) of ${approachingCounties} counties; limit timing unavailable from the current source`;
  const crossedChildren = numberValue(crossed.children);
  const crossedCounties = numberValue(crossed.counties);
  const crossedDays = numberValue(crossed.maximum_days_over_limit);
  const pendingAction = "Review pending parent confirmations in the provider system";
  const absenceAction = "Review affected children and absence dates";
  const riskRows = [
    pendingDays > 0
      ? `| Pending parent confirmations | ${pendingDays} day(s) for ${pendingChildren} child(ren) may keep payment conditional | ${pendingAction} |`
      : "| Pending parent confirmations | No pending parent confirmations | None |",
    approachingChildren > 0
      ? `| Children approaching county monthly absence limits | ${approachingFinding}; payment may be affected by the next absence | ${absenceAction} |`
      : "| Children approaching county monthly absence limits | No children currently approaching county monthly absence limits | None |",
    crossedChildren > 0
      ? `| Children crossed county absence limits | ${crossedChildren} child(ren) of ${crossedCounties} counties; ${crossedDays} day(s) over the limit may be excluded from payment | ${absenceAction} |`
      : "| Children crossed county absence limits | No children have crossed county monthly absence limits | None |",
  ];
  const nextActions = [];
  if (pendingDays > 0) nextActions.push(pendingAction);
  if (approachingChildren > 0 || crossedChildren > 0) nextActions.push(absenceAction);
  if (nextActions.length === 0) {
    nextActions.push("No urgent attendance actions identified");
  }
  const hasAttentionItems = pendingDays > 0 || approachingChildren > 0 || crossedChildren > 0;
  const attentionLine = hasAttentionItems
    ? "The following verified items require your attention. Details and recommended reviews are provided below."
    : "No attendance or payment items require your attention today.";
  const isToday = (scope.dateFilter ?? "TODAY") === "TODAY";
  const snapshotHeading = "Today's snapshot";
  const riskHeading = isToday
    ? "**Attendance and payment issues**"
    : `**Attendance and payment issues (${attendancePeriodLabel(scope)})**`;
  return {
    ...snapshot,
    providerMessage: [
      `Greetings for the day, ${snapshot.providerDisplayName}. Here's where things stand at ${snapshot.facilityName}.`,
      "",
      snapshotHeading,
      "| Today | Count |",
      "| --- | ---: |",
      `| Children scheduled | ${today.scheduled_children} |`,
      `| Children checked in | ${today.checked_in_children} |`,
      "",
      attentionLine,
      "",
      riskHeading,
      "The findings below are the verified issues for this period; the action in the last column explains the most useful read-only review.",
      "| Area | Verified finding | Why it matters / next review |",
      "| --- | --- | --- |",
      ...riskRows,
      "",
      "**Next actions**",
      ...nextActions.map((action) => `- ${action}`),
      "",
      "**Available options**",
      "- Review the next payout summary",
    ].join("\n"),
  };
}

export async function getCurrentMonthAttendanceSnapshot(
  client: CccapClient,
  providerDisplayName: string,
  asOfDate: string,
): Promise<unknown> {
  return getAttendanceRiskSnapshot(
    client,
    providerDisplayName,
    { dateFilter: "THIS_MONTH" },
    asOfDate,
  );
}


export async function getAttendanceRiskAnalysis(
  client: CccapClient,
  providerDisplayName: string,
  scope: DateScope,
  asOfDate: string,
  childNames?: string[],
  authNames?: string[],
  riskFocus?: "PARENT_CONFIRMATIONS" | "ABSENCE_LIMITS",
): Promise<{
  providerDisplayName: string;
  facilityName: string;
  attendanceRisk: unknown;
  paymentReadiness: RecordValue;
  scope: DateScope;
  riskFocus: "PARENT_CONFIRMATIONS" | "ABSENCE_LIMITS" | undefined;
  sourceRetrievedAt: string;
}> {
  const initialization = requireRecord(
    await client.initialize(scope),
    "Provider context",
  );
  const providers = requireArray(initialization.providers, "Provider facility");
  const providerContext = normalizeProviderContext(initialization);
  const facilityName = providerContext.facilityName;
  if (typeof facilityName !== "string" || !facilityName) {
    throw new Error("Provider facility name is unavailable");
  }
  const { countyIds, countyIdByName, qualityTier: providerTier } = providerContext;

  const [ratePlanData, scheduleData, holidayData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules({ ...scope, ...(authNames ? { authNames } : {}) }),
    getHolidayData(client, scope),
  ]);
  const ratePlans = requireArray(
    requireRecord(ratePlanData, "County rate plans").countyRatePlans,
    "County rate plans",
  );
  const calendar = calendarDates(initialization, requireRecord(holidayData, "Holiday list"));
  const schedules = requireArray(
    requireRecord(scheduleData, "Schedules").schedules,
    "Schedules",
  );
  if (authNames && authNames.length > 0) {
    const returnedAuthorizationNames = new Set(
      schedules.flatMap((value) => {
        const schedule = asRecord(value);
        const name = authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
        return name ? [name] : [];
      }),
    );
    const unmatchedAuthorizationNames = authNames.filter((name) => !returnedAuthorizationNames.has(name));
    if (unmatchedAuthorizationNames.length > 0) {
      throw new Error("Requested authorization filter did not match the selected provider scope and period.");
    }
  }
  const authorizationIds = [
    ...new Set(
      schedules
        .map((value) => asRecord(value)?.authorization_id)
        .map(authorizationKey)
        .filter((value): value is string => Boolean(value)),
    ),
  ];
  const authorizationNames = [
    ...new Set(
      schedules
        .map((value) => {
          const schedule = asRecord(value);
          return authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
        })
        .filter((value): value is string => Boolean(value)),
    ),
  ];
  const scheduleRateTypes = Object.fromEntries(schedules.flatMap((value) => {
    const schedule = asRecord(value);
    const authorizationId = authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
    const rateType = schedule?.rate_type_code ?? schedule?.CI_Authorization_Rate_Type__c;
    return authorizationId && typeof rateType === "string"
      ? [[authorizationId, rateType]]
      : [];
  }));
  const salesforceAuthorizationIds = authorizationIds.filter(isSalesforceId);
  const authorizationData = authorizationIds.length > 0 || authorizationNames.length > 0
    ? await client.getAuthorizations({
        ...scope,
        ...(salesforceAuthorizationIds.length > 0
          ? { authIds: salesforceAuthorizationIds }
          : {}),
        ...(authorizationNames.length > 0 ? { authNames: authorizationNames } : {}),
        scheduleRateTypes,
      })
    : undefined;
  const scopedSchedules = normalizeAttendanceRiskSchedules({
    schedules,
    authorizationData,
    countyIdByName,
    ...(countyIds.length === 1 ? { defaultCountyId: countyIds[0] } : {}),
    providerQualityTier: providerTier,
  });
  const directory = await mkdtemp(join(tmpdir(), "carepay-snapshot-"));
  const inputPath = join(directory, "snapshot.json");
  try {
    await writeFile(
      inputPath,
      JSON.stringify({
        as_of_date: asOfDate,
        schedules: scopedSchedules,
        county_rate_plans: ratePlans,
        provider_closure_dates: calendar.closureDates,
        holiday_dates: calendar.holidayDates,
        provider_license_status: providerLicenseStatus(initialization),
        ...(childNames ? { child_names: childNames } : {}),
      }),
      "utf8",
    );
    const { stdout } = await execFileAsync("uv", ["run", evaluatorPath, inputPath], {
      windowsHide: true,
    });
    const evaluated = JSON.parse(stdout) as { status?: string; result?: unknown; error?: string };
    if (evaluated.status !== "ok" || !evaluated.result) {
      throw new Error(evaluated.error || "Attendance risk evaluation failed");
    }
    return {
      providerDisplayName,
      facilityName,
      attendanceRisk: evaluated.result,
      paymentReadiness: livePaymentReadiness(),
      scope,
      riskFocus,
      sourceRetrievedAt: new Date().toISOString(),
    };
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export async function getAttendanceDataAnalysis(
  client: CccapClient,
  scope: DateScope,
): Promise<unknown> {
  const initialization = requireRecord(
    await client.initialize(scope),
    "Provider context",
  );
  const provider = firstArrayRecord(initialization.providers, "Provider facility");
  const { countyIds, qualityTier: providerTier } = normalizeProviderContext(initialization);

  const [ratePlanData, scheduleData, holidayData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules(scope),
    getHolidayData(client, scope),
  ]);
  const rawSchedules = requireArray(
    requireRecord(scheduleData, "Schedules").schedules,
    "Schedules",
  );
  const authorizationIds = [...new Set(rawSchedules
    .map((value) => authorizationKey(asRecord(value)?.authorization_id))
    .filter((value): value is string => Boolean(value)))];
  const authorizationNames = [...new Set(rawSchedules
    .map((value) => {
      const schedule = asRecord(value);
      return authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
    })
    .filter((value): value is string => Boolean(value)))];
  const authorizationData = authorizationIds.length > 0
    ? await client.getAuthorizations({ ...scope, authIds: authorizationIds, authNames: authorizationNames })
    : authorizationNames.length > 0
      ? await client.getAuthorizations({ ...scope, authNames: authorizationNames })
    : undefined;
  const normalized = normalizeScheduleAttendance(
    rawSchedules,
    countyIds.length === 1 ? countyIds[0] : undefined,
    providerTier,
    authorizationData,
  );
  const scheduleDates = normalized.schedules
    .map((schedule) => schedule.work_date)
    .filter((value): value is string => typeof value === "string")
    .sort();
  const servicePeriod = {
    start: scope.dateFrom ?? scheduleDates[0],
    end: scope.dateTo ?? scheduleDates[scheduleDates.length - 1],
  };
  if (!servicePeriod.start || !servicePeriod.end) {
    throw new Error("Schedules do not contain a usable service period");
  }
  const ratePlans = requireArray(
    requireRecord(ratePlanData, "County rate plans").countyRatePlans,
    "County rate plans",
  );
  const calendar = calendarDates(initialization, requireRecord(holidayData, "Holiday list"));
  const directory = await mkdtemp(join(tmpdir(), "carepay-attendance-"));
  const inputPath = join(directory, "attendance.json");
  try {
    await writeFile(
      inputPath,
      JSON.stringify({
        schedules: normalized.schedules,
        transactions: normalized.transactions,
        county_rate_plans: ratePlans,
        service_period: servicePeriod,
        provider_closure_dates: calendar.closureDates,
        holiday_dates: calendar.holidayDates,
        provider_license_status: providerLicenseStatus(initialization),
      }),
      "utf8",
    );
    const analyzerPath = fileURLToPath(
      new URL(
        "../../../skills/agent-child-care-payment-advisor/scripts/analyze_attendance_transactions.py",
        import.meta.url,
      ),
    );
    const { stdout } = await execFileAsync("uv", ["run", analyzerPath, inputPath], {
      windowsHide: true,
    });
    const evaluated = JSON.parse(stdout) as { status?: string; result?: unknown; error?: string };
    if (evaluated.status !== "ok" || !evaluated.result) {
      throw new Error(evaluated.error || "Attendance transaction analysis failed");
    }
    return {
      ...(evaluated.result as RecordValue),
      scope,
      sourceRetrievedAt: new Date().toISOString(),
    };
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

function firstArrayRecord(value: unknown, label: string): RecordValue {
  if (!Array.isArray(value) || value.length === 0) throw new Error(`${label} is unavailable`);
  return requireRecord(value[0], label);
}

