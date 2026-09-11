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
import { buildSituationEnvelope, type SituationEnvelope } from "./situation-envelope.js";
export { normalizePaymentStatus } from "./payment-schema.js";
export { getPaymentAnalysis } from "./payment-orchestration.js";
const execFileAsync = promisify(execFile);
const evaluatorPath = fileURLToPath(
  new URL(
    "../../../skills/agent-child-care-payment-advisor/scripts/evaluate_attendance_risks.py",
    import.meta.url,
  ),
);

const ATTENDANCE_EVALUATOR_TIMEOUT_MS = 30_000;
const ATTENDANCE_EVALUATOR_MAX_BUFFER_BYTES = 10_000_000;

async function runAttendanceEvaluator(scriptPath: string, inputPath: string): Promise<{ stdout: string }> {
  try {
    return await execFileAsync("uv", ["run", scriptPath, inputPath], {
      windowsHide: true,
      timeout: ATTENDANCE_EVALUATOR_TIMEOUT_MS,
      maxBuffer: ATTENDANCE_EVALUATOR_MAX_BUFFER_BYTES,
      killSignal: "SIGKILL",
    });
  } catch (error) {
    const nodeError = error as NodeJS.ErrnoException & { killed?: boolean; signal?: string };
    if (nodeError.code === "ENOENT") {
      throw new Error("Attendance engine is unavailable: the uv/python runtime could not be started.");
    }
    if (nodeError.killed || nodeError.signal === "SIGKILL" || nodeError.signal === "SIGTERM") {
      throw new Error(`Attendance engine is unavailable: evaluation exceeded ${ATTENDANCE_EVALUATOR_TIMEOUT_MS}ms and was terminated.`);
    }
    throw error;
  }
}

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
    ruleVersion: "provider-risk-payment-v3",
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
  const incomplete = requireRecord(
    categories.incomplete_attendance,
    "Incomplete attendance",
  );
  // A non-numeric evaluator count is a data-quality failure, not a zero
  // result; silently coercing it to 0 would present an unaffected snapshot
  // to the provider when the underlying evaluation is actually invalid.
  const numberValue = (value: unknown): number => {
    if (typeof value !== "number" || !Number.isFinite(value)) {
      throw new Error("Attendance risk category count is unavailable or invalid");
    }
    return value;
  };
  const pendingDays = numberValue(pending.days);
  const pendingChildren = numberValue(pending.children);
  const approachingChildren = numberValue(approaching.children);
  const approachingCounties = numberValue(approaching.counties);
  const approachingDays = approaching.minimum_days_until_exceeded;
  const approachingFinding =
    typeof approachingDays === "number"
      ? `${approachingChildren} child(ren), ${approachingCounties} counties; ${approachingDays} day(s) from limit`
      : `${approachingChildren} child(ren), ${approachingCounties} counties; timing unavailable`;
  const crossedChildren = numberValue(crossed.children);
  const crossedCounties = numberValue(crossed.counties);
  const crossedDays = numberValue(crossed.maximum_days_over_limit);
  const incompleteDays = numberValue(incomplete.days);
  const incompleteChildren = numberValue(incomplete.children);
  const pendingAction = "Review pending parent confirmations in the provider system";
  const absenceAction = "Review affected children and absence dates";
  const incompleteAction = "Review incomplete attendance records";
  // Combined per your request: approaching and crossed county absence-limit
  // risk are one row, not two, since both drive the same next review.
  const absenceLimitFinding = crossedChildren > 0 && approachingChildren > 0
    ? `${crossedChildren} child(ren)/${crossedCounties} counties over limit (${crossedDays}d); ${approachingChildren} child(ren)/${approachingCounties} counties approaching`
    : crossedChildren > 0
      ? `${crossedChildren} child(ren)/${crossedCounties} counties; ${crossedDays} day(s) over limit`
      : approachingChildren > 0
        ? approachingFinding
        : "No children near or over county absence limits";
  // Potential Loss (Care Hours) replaces the old prose "why it matters/next
  // review" column with a concrete, comparable number: the scheduled hours
  // behind each row's unresolved days. Pending/missing-check-in rows count
  // every such day's hours (nothing is resolved yet either way); the
  // absence-limit row counts only the hours for absence days actually OVER
  // the county limit (approaching-but-within-limit days carry no loss yet).
  const pendingLossHours = typeof pending.potential_loss_hours === "number" ? pending.potential_loss_hours : undefined;
  const crossedLossHours = typeof crossed.potential_loss_hours === "number" ? crossed.potential_loss_hours : undefined;
  const incompleteLossHours = typeof incomplete.potential_loss_hours === "number" ? incomplete.potential_loss_hours : undefined;
  const lossCell = (hours: number | undefined): string => hours !== undefined ? `${hours.toFixed(2)} hour(s)` : "Unavailable from the current source";
  // The absence-limit row's Verified finding describes BOTH crossed and
  // approaching children when both exist, but its loss-hours figure only
  // ever reflects crossed (over-limit) children - approaching children
  // haven't actually lost anything yet, only crossed ones have. Made
  // explicit here rather than left implicit, since the finding text and
  // the loss figure otherwise appear to describe the same population.
  const absenceLimitLossNote = crossedChildren > 0 && approachingChildren > 0
    ? " (crossed only)"
    : "";
  const riskRows = [
    pendingDays > 0
      ? `| Pending parent confirmations | ${pendingDays} day(s) for ${pendingChildren} child(ren) may keep payment conditional | ${lossCell(pendingLossHours)} |`
      : "| Pending parent confirmations | No pending parent confirmations | 0.00 hour(s) |",
    (crossedChildren > 0 || approachingChildren > 0)
      ? `| Children near or over county monthly absence limits | ${absenceLimitFinding} | ${lossCell(crossedLossHours)}${absenceLimitLossNote} |`
      : `| Children near or over county monthly absence limits | ${absenceLimitFinding} | 0.00 hour(s) |`,
    incompleteDays > 0
      ? `| Missing check-ins/check-outs within the confirmation window | ${incompleteDays} day(s) for ${incompleteChildren} child(ren) need a check-in or check-out record | ${lossCell(incompleteLossHours)} |`
      : "| Missing check-ins/check-outs within the confirmation window | No missing check-in or check-out records | 0.00 hour(s) |",
  ];
  const nextActions = [];
  if (pendingDays > 0) nextActions.push(pendingAction);
  if (approachingChildren > 0 || crossedChildren > 0) nextActions.push(absenceAction);
  if (incompleteDays > 0) nextActions.push(incompleteAction);
  if (nextActions.length === 0) {
    nextActions.push("No urgent attendance actions identified");
  }
  const hasAttentionItems = pendingDays > 0 || approachingChildren > 0 || crossedChildren > 0 || incompleteDays > 0;
  // Bottom-line dollar-impact sentence: sum only the estimators that are
  // actually available (never fabricate a figure for a category with no
  // verified rate estimate).
  const approachingEstimate = typeof approaching.risk_amount_estimate === "number" ? approaching.risk_amount_estimate : undefined;
  const crossedEstimate = typeof crossed.risk_amount_estimate === "number" ? crossed.risk_amount_estimate : undefined;
  const totalEstimate = approachingEstimate !== undefined || crossedEstimate !== undefined
    ? (approachingEstimate ?? 0) + (crossedEstimate ?? 0)
    : undefined;
  const primaryDriver = (crossedChildren + approachingChildren) >= pendingDays && (crossedChildren + approachingChildren) > 0
    ? "absence-limit risk"
    : pendingDays > 0
      ? "pending parent confirmations"
      : "attendance risk";
  // The "no dollar estimate available" case previously explained *why* no
  // estimate could be shown (an internal data-availability detail) instead
  // of telling the provider anything useful - removed entirely per request;
  // the risk table right below already conveys what needs attention.
  const attentionLine = !hasAttentionItems
    ? "No attendance or payment risks require your attention today."
    : totalEstimate !== undefined && totalEstimate > 0
      ? `An estimated ${totalEstimate.toFixed(2)} is at risk this period, mainly due to ${primaryDriver}.`
      : "";
  const isToday = (scope.dateFilter ?? "TODAY") === "TODAY";
  const snapshotHeading = "Today's snapshot";
  const monthLabel = (() => {
    const parsed = new Date(`${asOfDate}T00:00:00Z`);
    return Number.isNaN(parsed.getTime())
      ? attendancePeriodLabel(scope)
      : parsed.toLocaleDateString("en-US", { month: "long", year: "numeric", timeZone: "UTC" });
  })();
  const riskHeading = isToday
    ? "**Attendance and payment issues**"
    : `**Attendance and payment issues (${monthLabel})**`;
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
      "| Risk Area | Verified finding | Potential Loss (Care Hours) |",
      "| --- | --- | --- |",
      ...riskRows,
      "",
      "**Priority Actions**",
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
  riskFocus?: "PARENT_CONFIRMATIONS" | "ABSENCE_LIMITS" | "INCOMPLETE_ATTENDANCE",
  countyNames?: string[],
): Promise<{
  providerDisplayName: string;
  facilityName: string;
  attendanceRisk: unknown;
  paymentReadiness: RecordValue;
  scope: DateScope;
  riskFocus: "PARENT_CONFIRMATIONS" | "ABSENCE_LIMITS" | "INCOMPLETE_ATTENDANCE" | undefined;
  countyNames: string[] | undefined;
  sourceRetrievedAt: string;
  situation: SituationEnvelope;
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

  const [ratePlanData, scheduleData, holidayData, fiscalData] = await Promise.all([
    client.getCountyData({ ...scope, countyIds }),
    client.getSchedules({ ...scope, ...(authNames ? { authNames } : {}) }),
    getHolidayData(client, scope),
    // Fetched independently of the payment capability so payment-risk dollar
    // estimates never depend on a payment call having already run in this
    // session; a match failure below is fail-soft and never blocks the
    // underlying attendance-risk result.
    // Avoid an unnecessary Apex round-trip when the risk-amount estimate is not rendered for this risk focus.
    typeof client.getFiscalRates === "function" && riskFocus === "ABSENCE_LIMITS"
      ? client.getFiscalRates(scope)
      : Promise.resolve({ normalizedFiscalRates: { fiscalRates: [] } }),
  ]);
  const ratePlans = requireArray(
    requireRecord(ratePlanData, "County rate plans").countyRatePlans,
    "County rate plans",
  );
  // Best-effort rate_type_code -> daily amount lookup for payment-risk dollar
  // estimates. This intentionally skips the full fiscal-schedule/authorization/
  // quality-tier matching the payment engine requires for a payable amount
  // (see payment-canonical-adapter.ts): that matching is fail-closed by design
  // for money actually paid, while a risk estimate is explicitly approximate
  // and must never block or throw. Any lookup failure here simply omits the
  // amount rather than surfacing an error.
  const rateTypeToDailyAmount = new Map<string, number>();
  try {
    const fiscalRows = asRecord(asRecord(fiscalData)?.normalizedFiscalRates)?.fiscalRates;
    if (Array.isArray(fiscalRows)) {
      for (const value of fiscalRows) {
        const rate = asRecord(value);
        const rateType = rate?.rateTypeCode ?? rate?.CDE_RATE_TYPE__c;
        const amount = rate?.fiscalAgreementAmount ?? rate?.AMT_FISCAL_AGRMT__c;
        if (
          typeof rateType === "string" && rateType &&
          typeof amount === "number" && Number.isFinite(amount) && amount > 0 &&
          !rateTypeToDailyAmount.has(rateType)
        ) {
          rateTypeToDailyAmount.set(rateType, amount);
        }
      }
    }
  } catch {
    // Fail-soft: an estimate map that could not be built simply stays empty.
  }
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
  }).map((value) => {
    const schedule = asRecord(value);
    if (!schedule) return value;
    const rateType = schedule.rate_type_code ?? schedule.CI_Authorization_Rate_Type__c;
    const dailyRateEstimate = typeof rateType === "string" ? rateTypeToDailyAmount.get(rateType) : undefined;
    return dailyRateEstimate === undefined ? schedule : { ...schedule, daily_rate_estimate: dailyRateEstimate };
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
    const { stdout } = await runAttendanceEvaluator(evaluatorPath, inputPath);
    const evaluated = JSON.parse(stdout) as { status?: string; result?: unknown; error?: string };
    if (evaluated.status !== "ok" || !evaluated.result) {
      throw new Error(evaluated.error || "Attendance risk evaluation failed");
    }
    const sourceRetrievedAt = new Date().toISOString();
    const situation = await buildSituationEnvelope(
      evaluated.result,
      "attendance-risk-analysis",
      scope,
      sourceRetrievedAt,
    );
    return {
      providerDisplayName,
      facilityName,
      attendanceRisk: evaluated.result,
      paymentReadiness: livePaymentReadiness(),
      scope,
      riskFocus,
      countyNames,
      sourceRetrievedAt,
      situation,
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
    const { stdout } = await runAttendanceEvaluator(analyzerPath, inputPath);
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