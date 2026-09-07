import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import { CccapClient, type DateScope } from "./client.js";

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

function transactionType(recordType: unknown): number | undefined {
  if (recordType === "Check-In") return 1;
  if (recordType === "Check-Out") return 2;
  return undefined;
}

function nestedCountyName(schedule: RecordValue): string | undefined {
  const authorization = asRecord(schedule.Authorization__r);
  const county = asRecord(authorization?.County__r);
  const countyName = county?.County_Name__c;
  return typeof countyName === "string" && countyName ? countyName : undefined;
}

export function addDefaultCountyToSchedules(
  schedules: unknown[],
  defaultCountyId?: string,
): unknown[] {
  if (!defaultCountyId) return schedules;
  return schedules.map((value) => {
    const schedule = asRecord(value);
    if (!schedule) return value;
    const sourceCounty =
      schedule.countyId ??
      schedule.County__c ??
      schedule.CDE_COUNTY__c ??
      nestedCountyName(schedule);
    return typeof sourceCounty === "string" && sourceCounty
      ? schedule
      : { ...schedule, countyId: defaultCountyId };
  });
}

export function normalizeScheduleAttendance(
  schedules: unknown[],
  defaultCountyId?: string,
): {
  schedules: RecordValue[];
  transactions: RecordValue[];
} {
  const transactions: RecordValue[] = [];
  const normalizedSchedules: RecordValue[] = [];
  for (const value of schedules) {
    const schedule = asRecord(value);
    if (!schedule) continue;
    const scheduleId = schedule.Id ?? schedule.Schedule__c;
    const workDate = schedule.CI_Authorization_Date__c ?? schedule.work_date;
    const rawAttendance = asRecord(schedule.Attendance__r);
    const records = rawAttendance?.records;
    const linkedRecords = Array.isArray(records) ? records : [];
    const scheduleTransactions = linkedRecords
      .map(asRecord)
      .filter((record): record is RecordValue => Boolean(record))
      .map((record) => ({
        transaction_id: record.Id,
        schedule_id: record.Schedule__c ?? scheduleId,
        work_date: typeof workDate === "string" ? workDate : undefined,
        transaction_time: record.CI_Transaction_Time__c,
        attended_hours:
          record.Record_Type_Name__c === "Check-Out" ? schedule.Hours__c : undefined,
        type: transactionType(record.Record_Type_Name__c),
        result: 1,
        status: record.Status__c,
        sub_type: record.Sub_Type__c,
        is_historical: false,
        entered_by: record.Creation_Source__c === "Provider" ? "PROVIDER" : record.Creation_Source__c,
      }));
    transactions.push(...scheduleTransactions);
    const timestamps = scheduleTransactions
      .map((transaction) => transaction.transaction_time)
      .filter((timestamp): timestamp is string => typeof timestamp === "string")
      .sort();
    normalizedSchedules.push({
      schedule_id: scheduleId,
      child_name: schedule.Contact_Name__c,
      county_id: schedule.County__c ?? schedule.county_id ?? defaultCountyId,
      county_name: nestedCountyName(schedule),
      quality_tier: schedule.CI_Authorization_Rate_Type__c,
      work_date: workDate,
      schedule_type: schedule.Type__c ?? schedule.schedule_type,
      is_deleted: false,
      denial_reason: undefined,
      auth_status: schedule.Type__c === "CCCAP_AUTHORIZED" ? "APPROVED" : undefined,
      auth_begin_date: undefined,
      auth_end_date: undefined,
      ci_authorization_hours: schedule.CI_Authorization_Hours__c,
      raw_hours: schedule.Hours__c,
      check_in_count: schedule.Check_In_Count__c,
      check_out_count: schedule.Check_Out_Count__c,
      attended_flag: scheduleTransactions.length > 0,
      actual_start_ts: timestamps[0],
      actual_end_ts: timestamps[timestamps.length - 1],
    });
  }
  return { schedules: normalizedSchedules, transactions };
}

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

export async function getCurrentMonthAttendanceSnapshot(
  client: CccapClient,
  providerDisplayName: string,
  asOfDate: string,
): Promise<unknown> {
  const snapshot = await getAttendanceRiskAnalysis(
    client,
    providerDisplayName,
    { dateFilter: "THIS_MONTH" },
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
    nextActions.push("Review and complete the pending parent confirmations");
  }
  if (approachingChildren > 0 || crossedChildren > 0) {
    nextActions.push("Review the affected children, county limits, and absence dates");
  }
  if (nextActions.length === 0) {
    nextActions.push("Review attendance records for missing or incomplete check-ins");
  }
  nextActions.push("View next payout details");
  return {
    ...snapshot,
    providerMessage: [
      `Greetings for the day, ${snapshot.providerDisplayName}. Here's where things stand at ${snapshot.facilityName}.`,
      "",
      "Today's snapshot",
      "| Today | Count |",
      "| --- | ---: |",
      `| Children scheduled | ${today.scheduled_children} |`,
      `| Children checked in | ${today.checked_in_children} |`,
      "",
      "**Payment-readiness risks**",
      "| Area | Finding | Suggested next step |",
      "| --- | --- | --- |",
      ...riskRows,
      "",
      "**Next actions**",
      ...nextActions.map((action, index) => `${index + 1}. ${action}`),
    ].join("\n"),
  };
}

export async function getAttendanceRiskAnalysis(
  client: CccapClient,
  providerDisplayName: string,
  scope: DateScope,
  asOfDate: string,
  childNames?: string[],
): Promise<{
  providerDisplayName: string;
  facilityName: string;
  attendanceRisk: unknown;
  paymentReadiness: RecordValue;
  scope: DateScope;
}> {
  const initialization = requireRecord(
    await client.initialize(scope),
    "Provider context",
  );
  const providers = requireArray(initialization.providers, "Provider facility");
  const provider = requireRecord(providers[0], "Provider facility");
  const facilityName = provider.NAM_FACILITY__c;
  if (typeof facilityName !== "string" || !facilityName) {
    throw new Error("Provider facility name is unavailable");
  }
  const countyIds = [
    ...new Set(
      requireArray(initialization.fiscalAgreements, "Provider county agreements")
        .map((agreement) => requireRecord(agreement, "Provider county agreement").CDE_COUNTY__c)
        .filter((countyId): countyId is string => typeof countyId === "string"),
    ),
  ];
  if (countyIds.length === 0) {
    throw new Error("Provider county agreements are unavailable");
  }

  const [ratePlanData, scheduleData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules(scope),
  ]);
  const ratePlans = requireArray(
    requireRecord(ratePlanData, "County rate plans").countyRatePlans,
    "County rate plans",
  );
  const schedules = requireArray(
    requireRecord(scheduleData, "Schedules").schedules,
    "Schedules",
  );
  const scopedSchedules = addDefaultCountyToSchedules(
    schedules,
    countyIds.length === 1 ? countyIds[0] : undefined,
  );
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
  const countyIds = [
    ...new Set(
      requireArray(initialization.fiscalAgreements, "Provider county agreements")
        .map((agreement) => requireRecord(agreement, "Provider county agreement").CDE_COUNTY__c)
        .filter((countyId): countyId is string => typeof countyId === "string"),
    ),
  ];
  if (countyIds.length === 0) {
    throw new Error("Provider county agreements are unavailable");
  }

  const [ratePlanData, scheduleData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules(scope),
  ]);
  const rawSchedules = requireArray(
    requireRecord(scheduleData, "Schedules").schedules,
    "Schedules",
  );
  const normalized = normalizeScheduleAttendance(
    rawSchedules,
    countyIds.length === 1 ? countyIds[0] : undefined,
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
    return evaluated.result;
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}