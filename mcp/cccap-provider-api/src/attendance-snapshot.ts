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
  const riskRows = [
    pendingDays > 0
      ? `| Pending parent confirmations | ${pendingDays} day(s) for ${pendingChildren} child(ren) | Review and complete the pending confirmations |`
      : "| Pending parent confirmations | No pending parent confirmations | None |",
    approachingChildren > 0
      ? `| Children approaching county monthly absence limits | ${approachingFinding} | Review absence details before the next absence is recorded |`
      : "| Children approaching county monthly absence limits | No children currently approaching county monthly absence limits | None |",
    crossedChildren > 0
      ? `| Children crossed county absence limits | ${crossedChildren} child(ren) of ${crossedCounties} counties; ${crossedDays} day(s) over the limit | Review the affected absence records and county follow-up |`
      : "| Children crossed county absence limits | No children have crossed county monthly absence limits | None |",
  ];
  const nextActions = [];
  if (pendingDays > 0) {
    nextActions.push("Review pending parent confirmations in the provider system");
  }
  if (approachingChildren > 0 || crossedChildren > 0) {
    nextActions.push("Review the affected children, county limits, and absence dates");
  }
  if (nextActions.length === 0) {
    nextActions.push("Review today's attendance records for missing or incomplete check-ins");
  }
  const isToday = (scope.dateFilter ?? "TODAY") === "TODAY";
  const snapshotHeading = "Today's snapshot";
  const snapshotRows = [
    "| Today | Count |",
    "| --- | ---: |",
    `| Children scheduled | ${today.scheduled_children} |`,
    `| Children checked in | ${today.checked_in_children} |`,
  ];
  const riskHeading = isToday
    ? "**Payment-readiness risks**"
    : `**Payment-readiness risks (${attendancePeriodLabel(scope)})**`;
  return {
    ...snapshot,
    providerMessage: [
      `Greetings for the day, ${snapshot.providerDisplayName}. Here's where things stand at ${snapshot.facilityName}.`,
      "",
      snapshotHeading,
      ...snapshotRows,
      "",
      riskHeading,
      "| Area | Finding | Suggested next step |",
      "| --- | --- | --- |",
      ...riskRows,
      "",
      "**Next views**",
      ...nextActions.map((action, index) => `${index + 1}. ${action}`),
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

  const [ratePlanData, scheduleData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules({ ...scope, ...(authNames ? { authNames } : {}) }),
  ]);
  const ratePlans = requireArray(
    requireRecord(ratePlanData, "County rate plans").countyRatePlans,
    "County rate plans",
  );
  const schedules = requireArray(
    requireRecord(scheduleData, "Schedules").schedules,
    "Schedules",
  );
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
        .map((value) => asRecord(value)?.authorization_name ?? asRecord(value)?.CI_Authorization_Id__c)
        .filter((value): value is string => typeof value === "string" && value.length > 0),
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
  const authorizationData = authorizationIds.length > 0
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

  const [ratePlanData, scheduleData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules(scope),
  ]);
  const rawSchedules = requireArray(
    requireRecord(scheduleData, "Schedules").schedules,
    "Schedules",
  );
  const authorizationIds = [...new Set(rawSchedules
    .map((value) => asRecord(value)?.authorization_id)
    .filter((value): value is string => typeof value === "string" && value.length > 0))];
  const authorizationNames = [...new Set(rawSchedules
    .map((value) => asRecord(value)?.authorization_name ?? asRecord(value)?.CI_Authorization_Id__c)
    .filter((value): value is string => typeof value === "string" && value.length > 0))];
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

