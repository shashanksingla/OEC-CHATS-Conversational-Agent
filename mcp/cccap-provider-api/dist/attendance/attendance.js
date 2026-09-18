// Merged: attendance-engine.ts (canonicalization) + attendance-orchestration.ts (retrieval +
// evaluator invocation). schedule-normalizer.ts stays in shared/ (used by payment-engine.ts and
// read-model-adapters.ts too, so folding it in here would create a circular import:
// attendance.ts -> payment-orchestration.ts -> payment-engine.ts -> attendance.ts).
// ===== begin attendance-engine.ts =====
export { normalizePaymentStatus } from "../payment/payment-engine.js";
export { getPaymentAnalysis } from "../payment/payment-orchestration.js";
export { normalizeScheduleAttendance } from "../shared/normalizers.js";
function asRecord(value) {
    return value && typeof value === "object" && !Array.isArray(value)
        ? value
        : undefined;
}
function nestedCountyName(schedule) {
    const authorization = asRecord(schedule.Authorization__r);
    const county = asRecord(authorization?.County__r);
    const countyName = county?.County_Name__c;
    return typeof countyName === "string" && countyName ? countyName : undefined;
}
// Schedule authorization identifiers may arrive as numbers from the DECL source.
export function authorizationKey(value) {
    if (typeof value === "string" && value)
        return value;
    if (typeof value === "number" && Number.isFinite(value))
        return String(value);
    return undefined;
}
export function isSalesforceId(value) {
    return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
}
export function addDefaultCountyToSchedules(schedules, defaultCountyId) {
    if (!defaultCountyId)
        return schedules;
    return schedules.map((value) => {
        const schedule = asRecord(value);
        if (!schedule)
            return value;
        const sourceCounty = schedule.countyId ?? schedule.County__c ?? schedule.CDE_COUNTY__c;
        return typeof sourceCounty === "string" && sourceCounty
            ? schedule
            : { ...schedule, countyId: defaultCountyId };
    });
}
export function addCanonicalCountyIdToSchedules(schedules) {
    return schedules.map((value) => {
        const schedule = asRecord(value);
        if (!schedule || (typeof schedule.countyId === "string" && schedule.countyId)) {
            return value;
        }
        const countyId = schedule.County__c ?? schedule.CDE_COUNTY__c;
        return typeof countyId === "string" && countyId
            ? { ...schedule, countyId }
            : value;
    });
}
export function addProviderQualityTierToSchedules(schedules, providerQualityTier) {
    return schedules.map((value) => {
        const schedule = asRecord(value);
        return schedule ? { ...schedule, qualityTier: providerQualityTier } : value;
    });
}
export function addAuthorizationNamesToSchedules(schedules, authorizationData) {
    const response = asRecord(authorizationData);
    const authorizations = Array.isArray(response?.authorizations)
        ? response.authorizations
        : [];
    const namesById = new Map();
    for (const value of authorizations) {
        const authorization = asRecord(value);
        const id = authorizationKey(authorization?.Id);
        const externalId = authorizationKey(authorization?.IDN_EXTNL__c);
        const name = authorization?.Name;
        if (id && typeof name === "string" && name)
            namesById.set(id, name);
        if (externalId && typeof name === "string" && name)
            namesById.set(externalId, name);
        if (typeof name === "string" && name)
            namesById.set(name, name);
    }
    return schedules.map((value) => {
        const schedule = asRecord(value);
        if (!schedule)
            return value;
        const existingName = schedule.authorization_name ?? schedule.Authorization_Name__c;
        if (typeof existingName === "string" && existingName)
            return schedule;
        const authorizationId = authorizationKey(schedule.CI_Authorization_Id__c ??
            schedule.Authorization__c ??
            schedule.IDN_AUTH__c ??
            schedule.Authorization_Id__c);
        const name = authorizationId ? namesById.get(authorizationId) : undefined;
        return name ? { ...schedule, authorization_name: name } : schedule;
    });
}
// Joins DECL county identifiers to main-org IDs only through verified county names.
export function addNestedCountyIdToSchedules(schedules, countyIdByName) {
    return schedules.map((value) => {
        const schedule = asRecord(value);
        if (!schedule)
            return value;
        const existingCounty = schedule.countyId ?? schedule.County__c ?? schedule.CDE_COUNTY__c;
        if (typeof existingCounty === "string" && existingCounty)
            return schedule;
        const countyName = nestedCountyName(schedule);
        const countyId = countyName ? countyIdByName[countyName] : undefined;
        return countyId ? { ...schedule, countyId } : schedule;
    });
}
export function normalizeAttendanceRiskSchedules(input) {
    const withAuthorizationNames = addAuthorizationNamesToSchedules(input.schedules, input.authorizationData);
    const withCounties = addNestedCountyIdToSchedules(withAuthorizationNames, input.countyIdByName);
    return addProviderQualityTierToSchedules(addCanonicalCountyIdToSchedules(addDefaultCountyToSchedules(withCounties, input.defaultCountyId)), input.providerQualityTier);
}
export function livePaymentReadiness() {
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
// ===== end attendance-engine.ts =====
// ===== begin attendance-orchestration.ts =====
import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { normalizeProviderContext } from "../shared/normalizers.js";
import { buildSituationEnvelope } from "../shared/situation-envelope.js";
// Rejects sandbox/QA-labeled facility names so the greeting falls back to a generic phrase.
function isLikelyFacilityName(value) {
    if (typeof value !== "string" || !value.trim())
        return false;
    const qaTokenPattern = /\b(regression|sandbox|sb|test|qa|updated|demo)\b/i;
    return !qaTokenPattern.test(value);
}
const execFileAsync = promisify(execFile);
const evaluatorPath = fileURLToPath(new URL("../../../../skills/agent-child-care-payment-advisor/scripts/evaluate_attendance_risks.py", import.meta.url));
const ATTENDANCE_EVALUATOR_TIMEOUT_MS = 30_000;
const ATTENDANCE_EVALUATOR_MAX_BUFFER_BYTES = 10_000_000;
async function runAttendanceEvaluator(scriptPath, inputPath) {
    try {
        return await execFileAsync("uv", ["run", scriptPath, inputPath], {
            windowsHide: true,
            timeout: ATTENDANCE_EVALUATOR_TIMEOUT_MS,
            maxBuffer: ATTENDANCE_EVALUATOR_MAX_BUFFER_BYTES,
            killSignal: "SIGKILL",
        });
    }
    catch (error) {
        const nodeError = error;
        if (nodeError.code === "ENOENT") {
            throw new Error("Attendance engine is unavailable: the uv/python runtime could not be started.");
        }
        if (nodeError.killed || nodeError.signal === "SIGKILL" || nodeError.signal === "SIGTERM") {
            throw new Error(`Attendance engine is unavailable: evaluation exceeded ${ATTENDANCE_EVALUATOR_TIMEOUT_MS}ms and was terminated.`);
        }
        throw error;
    }
}
function calendarDates(initialization, holidayData) {
    const closureDates = (Array.isArray(initialization.providerClosures)
        ? initialization.providerClosures
        : Array.isArray(initialization.provider_closures) ? initialization.provider_closures : [])
        .flatMap((value) => {
        const closure = asRecord(value);
        const active = closure?.IND_ACTIVE__c;
        if (active === false || active === 0 || active === "0" || active === "false")
            return [];
        const date = closure?.DTE_BEGIN_CLOSURE__c ?? closure?.closure_date;
        return typeof date === "string" && date.length > 0 ? [date] : [];
    });
    const holidays = Array.isArray(holidayData.holidayList) ? holidayData.holidayList : [];
    const holidayDates = holidays.flatMap((value) => {
        const holiday = asRecord(value);
        return [holiday?.DTE_HOL__c, holiday?.DTE_OBSERVED_HOL__c]
            .filter((date) => typeof date === "string" && date.length > 0);
    });
    return {
        closureDates: [...new Set(closureDates)],
        holidayDates: [...new Set(holidayDates)],
    };
}
function providerLicenseStatus(initialization) {
    const providers = Array.isArray(initialization.providers) ? initialization.providers : [];
    const provider = asRecord(providers[0]);
    const value = provider?.CDE_TYPE_PROVR__c ?? provider?.provider_type;
    return typeof value === "string" && value.length > 0 ? value.trim().toUpperCase() : undefined;
}
function getHolidayData(client, scope) {
    return typeof client.getHolidayList === "function"
        ? client.getHolidayList(scope)
        : Promise.resolve({ holidayList: [] });
}
function requireRecord(value, label) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new Error(`${label} is unavailable`);
    }
    return value;
}
function requireArray(value, label) {
    if (!Array.isArray(value)) {
        throw new Error(`${label} is unavailable`);
    }
    return value;
}
function attendancePeriodLabel(scope) {
    if (scope.dateFilter === "LAST_MONTH")
        return "Last-month";
    if (scope.dateFilter === "THIS_MONTH")
        return "Current-month";
    if (scope.dateFilter === "DATE_RANGE")
        return "Date-range";
    if (scope.dateFilter === "LAST_N_MONTHS" || scope.dateFilter === "LAST_N_DAYS") {
        return "Historical";
    }
    return "Today";
}
export async function getAttendanceRiskSnapshot(client, providerDisplayName, scope, asOfDate) {
    const snapshot = await getAttendanceRiskAnalysis(client, providerDisplayName, scope, asOfDate);
    const risk = requireRecord(snapshot.attendanceRisk, "Attendance risk evaluation");
    const today = requireRecord(risk.today, "Today's attendance snapshot");
    const categories = requireRecord(risk.risk_categories, "Attendance risk categories");
    const pending = requireRecord(categories.pending_parent_confirmations, "Pending parent confirmations");
    const approaching = requireRecord(categories.approaching_absence_limits, "Approaching absence limits");
    const crossed = requireRecord(categories.crossed_absence_limits, "Crossed absence limits");
    const incomplete = requireRecord(categories.incomplete_attendance, "Incomplete attendance");
    // Reject invalid evaluator counts so failed evaluations cannot appear as zero-risk snapshots.
    const numberValue = (value) => {
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
    const approachingFinding = typeof approachingDays === "number"
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
    // Combine approaching and crossed absence-limit risks because they share the same review action.
    const absenceLimitFinding = crossedChildren > 0 && approachingChildren > 0
        ? `${crossedChildren} child(ren)/${crossedCounties} counties over limit (${crossedDays}d); ${approachingChildren} child(ren)/${approachingCounties} counties approaching`
        : crossedChildren > 0
            ? `${crossedChildren} child(ren)/${crossedCounties} counties; ${crossedDays} day(s) over limit`
            : approachingChildren > 0
                ? approachingFinding
                : "No children near or over county absence limits";
    // Use At-Risk Hours because unresolved exposure is conditional, not a confirmed loss.
    const pendingLossHours = typeof pending.potential_loss_hours === "number" ? pending.potential_loss_hours : undefined;
    const crossedLossHours = typeof crossed.potential_loss_hours === "number" ? crossed.potential_loss_hours : undefined;
    const incompleteLossHours = typeof incomplete.potential_loss_hours === "number" ? incomplete.potential_loss_hours : undefined;
    const lossCell = (hours) => hours !== undefined ? `${hours.toFixed(2)} hour(s)` : "Unavailable from the current source";
    const riskRows = [
        pendingDays > 0
            ? `| Pending parent confirmations | ${pendingDays} day(s) for ${pendingChildren} child(ren) may keep payment conditional | ${lossCell(pendingLossHours)} |`
            : "| Pending parent confirmations | No pending parent confirmations | 0.00 hour(s) |",
        (crossedChildren > 0 || approachingChildren > 0)
            ? `| Children near or over county monthly absence limits | ${absenceLimitFinding} | ${lossCell(crossedLossHours)} |`
            : `| Children near or over county monthly absence limits | ${absenceLimitFinding} | 0.00 hour(s) |`,
        incompleteDays > 0
            ? `| Missing check-ins/check-outs within the confirmation window | ${incompleteDays} day(s) for ${incompleteChildren} child(ren) need a check-in or check-out record | ${lossCell(incompleteLossHours)} |`
            : "| Missing check-ins/check-outs within the confirmation window | No missing check-in or check-out records | 0.00 hour(s) |",
    ];
    const nextActions = [];
    if (pendingDays > 0)
        nextActions.push(pendingAction);
    if (approachingChildren > 0 || crossedChildren > 0)
        nextActions.push(absenceAction);
    if (incompleteDays > 0)
        nextActions.push(incompleteAction);
    if (nextActions.length === 0) {
        nextActions.push("No urgent attendance actions identified");
    }
    const hasAttentionItems = pendingDays > 0 || approachingChildren > 0 || crossedChildren > 0 || incompleteDays > 0;
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
            isLikelyFacilityName(snapshot.facilityName)
                ? `Greetings for the day, ${snapshot.providerDisplayName}. Here's where things stand at ${snapshot.facilityName}.`
                : `Greetings for the day, ${snapshot.providerDisplayName}. Here's where things stand today.`,
            "",
            `**${snapshotHeading}**`,
            "| Metric | Count |",
            "| --- | ---: |",
            `| Children scheduled | ${today.scheduled_children} |`,
            `| Children checked in | ${today.checked_in_children} |`,
            "",
            attentionLine,
            "",
            riskHeading,
            "The findings below are the verified issues for this period",
            "| Risk Area | Verified finding | At-Risk Hours |",
            "| --- | --- | --- |",
            ...riskRows,
            "> For the dollar equivalent of this risk, ask for the current week's service payout.",
            "",
            "**Recommended actions**",
            ...[...nextActions, "Review the next payout summary"].map((action, index) => `${index + 1}. ${action}`),
        ].join("\n"),
    };
}
export async function getCurrentMonthAttendanceSnapshot(client, providerDisplayName, asOfDate) {
    return getAttendanceRiskSnapshot(client, providerDisplayName, { dateFilter: "THIS_MONTH" }, asOfDate);
}
export async function getAttendanceRiskAnalysis(client, providerDisplayName, scope, asOfDate, childNames, authNames, riskFocus, countyNames, detailPage, detailPageSize, siblingPaymentFacts) {
    const initialization = requireRecord(await client.initialize(scope), "Provider context");
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
        typeof client.getFiscalRates === "function" && riskFocus === "ABSENCE_LIMITS"
            ? client.getFiscalRates(scope)
            : Promise.resolve({ normalizedFiscalRates: { fiscalRates: [] } }),
    ]);
    const ratePlans = requireArray(requireRecord(ratePlanData, "County rate plans").countyRatePlans, "County rate plans");
    const rateTypeToDailyAmount = new Map();
    try {
        const fiscalRows = asRecord(asRecord(fiscalData)?.normalizedFiscalRates)?.fiscalRates;
        if (Array.isArray(fiscalRows)) {
            for (const value of fiscalRows) {
                const rate = asRecord(value);
                const rateType = rate?.rateTypeCode ?? rate?.CDE_RATE_TYPE__c;
                const amount = rate?.fiscalAgreementAmount ?? rate?.AMT_FISCAL_AGRMT__c;
                if (typeof rateType === "string" && rateType &&
                    typeof amount === "number" && Number.isFinite(amount) && amount > 0 &&
                    !rateTypeToDailyAmount.has(rateType)) {
                    rateTypeToDailyAmount.set(rateType, amount);
                }
            }
        }
    }
    catch {
        // Fail-soft: an estimate map that could not be built simply stays empty.
    }
    const calendar = calendarDates(initialization, requireRecord(holidayData, "Holiday list"));
    const schedules = requireArray(requireRecord(scheduleData, "Schedules").schedules, "Schedules");
    if (authNames && authNames.length > 0) {
        const returnedAuthorizationNames = new Set(schedules.flatMap((value) => {
            const schedule = asRecord(value);
            const name = authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
            return name ? [name] : [];
        }));
        const unmatchedAuthorizationNames = authNames.filter((name) => !returnedAuthorizationNames.has(name));
        if (unmatchedAuthorizationNames.length > 0) {
            throw new Error("Requested authorization filter did not match the selected provider scope and period.");
        }
    }
    const authorizationIds = [
        ...new Set(schedules
            .map((value) => asRecord(value)?.authorization_id)
            .map(authorizationKey)
            .filter((value) => Boolean(value))),
    ];
    const authorizationNames = [
        ...new Set(schedules
            .map((value) => {
            const schedule = asRecord(value);
            return authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
        })
            .filter((value) => Boolean(value))),
    ];
    const scheduleRateTypesByKey = new Map();
    for (const value of schedules) {
        const schedule = asRecord(value);
        const authorizationId = authorizationKey(schedule?.authorization_name ?? schedule?.CI_Authorization_Id__c);
        const rateType = schedule?.rate_type_code ?? schedule?.CI_Authorization_Rate_Type__c;
        if (!authorizationId || typeof rateType !== "string")
            continue;
        const set = scheduleRateTypesByKey.get(authorizationId) ?? new Set();
        set.add(rateType);
        scheduleRateTypesByKey.set(authorizationId, set);
    }
    const scheduleRateTypes = Object.fromEntries([...scheduleRateTypesByKey.entries()].map(([key, set]) => [key, [...set]]));
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
        if (!schedule)
            return value;
        const rateType = schedule.rate_type_code ?? schedule.CI_Authorization_Rate_Type__c;
        const dailyRateEstimate = typeof rateType === "string" ? rateTypeToDailyAmount.get(rateType) : undefined;
        return dailyRateEstimate === undefined ? schedule : { ...schedule, daily_rate_estimate: dailyRateEstimate };
    });
    const directory = await mkdtemp(join(tmpdir(), "carepay-snapshot-"));
    const inputPath = join(directory, "snapshot.json");
    try {
        await writeFile(inputPath, JSON.stringify({
            as_of_date: asOfDate,
            schedules: scopedSchedules,
            county_rate_plans: ratePlans,
            provider_closure_dates: calendar.closureDates,
            holiday_dates: calendar.holidayDates,
            provider_license_status: providerLicenseStatus(initialization),
            ...(childNames ? { child_names: childNames } : {}),
        }), "utf8");
        const { stdout } = await runAttendanceEvaluator(evaluatorPath, inputPath);
        const evaluated = JSON.parse(stdout);
        if (evaluated.status !== "ok" || !evaluated.result) {
            throw new Error(evaluated.error || "Attendance risk evaluation failed");
        }
        const sourceRetrievedAt = new Date().toISOString();
        const situation = await buildSituationEnvelope(evaluated.result, "attendance-risk-analysis", scope, sourceRetrievedAt, siblingPaymentFacts);
        return {
            providerDisplayName,
            facilityName,
            attendanceRisk: evaluated.result,
            paymentReadiness: livePaymentReadiness(),
            scope,
            riskFocus,
            countyNames,
            detailPage,
            detailPageSize,
            sourceRetrievedAt,
            situation,
        };
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
// ===== end attendance-orchestration.ts =====
