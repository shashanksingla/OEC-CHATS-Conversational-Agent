import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildCanonicalPaymentPayload, deriveAttendanceEnrichment, normalizeFiscalRatesForPayment, normalizeAuthorizationCopays, normalizePaymentFeeHistory, normalizePaymentFeeSchedules, normalizeQualityTier, } from "./payment-payload-adapter.js";
const execFileAsync = promisify(execFile);
const evaluatorPath = fileURLToPath(new URL("../../../skills/agent-child-care-payment-advisor/scripts/evaluate_attendance_risks.py", import.meta.url));
const paymentEvaluatorPath = fileURLToPath(new URL("../../../skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py", import.meta.url));
function asRecord(value) {
    return value && typeof value === "object" && !Array.isArray(value)
        ? value
        : undefined;
}
function transactionType(recordType) {
    if (recordType === "Check-In")
        return 1;
    if (recordType === "Check-Out")
        return 2;
    return undefined;
}
export function normalizePaymentStatus(value) {
    const status = String(value ?? "").trim().toUpperCase();
    if (status === "4" || status === "PAID")
        return "PAID";
    if (["1", "2", "3", "CREATED", "IN_PROGRESS", "CALCULATED", "REQUESTED"].includes(status)) {
        return "REQUESTED";
    }
    return undefined;
}
function nestedCountyName(schedule) {
    const authorization = asRecord(schedule.Authorization__r);
    const county = asRecord(authorization?.County__r);
    const countyName = county?.County_Name__c;
    return typeof countyName === "string" && countyName ? countyName : undefined;
}
// Schedule authorization identifiers may arrive as numbers from the DECL source.
function authorizationKey(value) {
    if (typeof value === "string" && value)
        return value;
    if (typeof value === "number" && Number.isFinite(value))
        return String(value);
    return undefined;
}
function isSalesforceId(value) {
    return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
}
export function addDefaultCountyToSchedules(schedules, defaultCountyId) {
    if (!defaultCountyId)
        return schedules;
    return schedules.map((value) => {
        const schedule = asRecord(value);
        if (!schedule)
            return value;
        const sourceCounty = schedule.countyId ??
            schedule.County__c ??
            schedule.CDE_COUNTY__c;
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
export function normalizeScheduleAttendance(schedules, defaultCountyId, providerQualityTier) {
    const transactions = [];
    const normalizedSchedules = [];
    for (const value of schedules) {
        const schedule = asRecord(value);
        if (!schedule)
            continue;
        const scheduleId = schedule.Id ?? schedule.Schedule__c;
        const workDate = schedule.CI_Authorization_Date__c ?? schedule.work_date;
        const rawAttendance = asRecord(schedule.Attendance__r);
        const records = rawAttendance?.records;
        const linkedRecords = Array.isArray(records) ? records : [];
        const scheduleTransactions = linkedRecords
            .map(asRecord)
            .filter((record) => Boolean(record))
            .map((record) => ({
            transaction_id: record.Id,
            schedule_id: record.Schedule__c ?? scheduleId,
            authorization_id: schedule.CI_Authorization_Id__c,
            work_date: typeof workDate === "string" ? workDate : undefined,
            transaction_time: record.CI_Transaction_Time__c,
            attended_hours: record.Record_Type_Name__c === "Check-Out" ? schedule.Hours__c : undefined,
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
            .filter((timestamp) => typeof timestamp === "string")
            .sort();
        const parentStatuses = new Set(scheduleTransactions
            .map((transaction) => transaction.status)
            .filter((status) => typeof status === "string"));
        const authorization = asRecord(schedule.Authorization__r);
        const normalizedSchedule = {
            schedule_id: scheduleId,
            authorization_id: schedule.CI_Authorization_Id__c ??
                schedule.Authorization__c ??
                schedule.IDN_AUTH__c ??
                schedule.Authorization_Id__c ??
                authorization?.Id,
            child_name: schedule.Contact_Name__c,
            county_id: schedule.County__c ?? schedule.county_id ?? defaultCountyId,
            county_name: nestedCountyName(schedule),
            quality_tier: providerQualityTier,
            rate_type_code: schedule.CI_Authorization_Rate_Type__c,
            work_date: workDate,
            schedule_type: schedule.Type__c ?? schedule.schedule_type,
            is_deleted: false,
            denial_reason: undefined,
            auth_status: schedule.Type__c === "CCCAP_AUTHORIZED" ? "APPROVED" : undefined,
            auth_begin_date: undefined,
            auth_end_date: undefined,
            ci_authorization_hours: schedule.CI_Authorization_Hours__c,
            raw_hours: schedule.Hours__c,
            care_not_offered: schedule.Care_Not_Offered__c ?? schedule.care_not_offered,
            check_in_count: schedule.Check_In_Count__c,
            check_out_count: schedule.Check_Out_Count__c,
            attended_flag: scheduleTransactions.length > 0,
            actual_start_ts: timestamps[0],
            actual_end_ts: timestamps[timestamps.length - 1],
        };
        if (parentStatuses.has("PARENT_PENDING")) {
            normalizedSchedule.parent_confirmation = "PENDING";
            normalizedSchedule.absence_parent_approved = false;
        }
        else if (parentStatuses.has("PARENT_APPROVED")) {
            normalizedSchedule.parent_confirmation = "CONFIRMED";
            normalizedSchedule.absence_parent_approved = true;
        }
        normalizedSchedules.push(normalizedSchedule);
    }
    return { schedules: normalizedSchedules, transactions };
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
        if (id && typeof name === "string" && name) {
            namesById.set(id, name);
        }
        if (externalId && typeof name === "string" && name) {
            namesById.set(externalId, name);
        }
        if (typeof name === "string" && name) {
            namesById.set(name, name);
        }
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
// The schedule's nested Authorization__r/County__r come from the DECL source org, whose IDs
// do not correspond to the main org's T_COUNTY_RATE__c IDs, so county must be joined by name.
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
export function livePaymentReadiness() {
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
    const numberValue = (value) => typeof value === "number" ? value : 0;
    const pendingDays = numberValue(pending.days);
    const pendingChildren = numberValue(pending.children);
    const approachingChildren = numberValue(approaching.children);
    const approachingCounties = numberValue(approaching.counties);
    const approachingDays = approaching.minimum_days_until_exceeded;
    const approachingFinding = typeof approachingDays === "number"
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
export async function getCurrentMonthAttendanceSnapshot(client, providerDisplayName, asOfDate) {
    return getAttendanceRiskSnapshot(client, providerDisplayName, { dateFilter: "THIS_MONTH" }, asOfDate);
}
export async function getAttendanceRiskAnalysis(client, providerDisplayName, scope, asOfDate, childNames, authNames) {
    const initialization = requireRecord(await client.initialize(scope), "Provider context");
    const providers = requireArray(initialization.providers, "Provider facility");
    const provider = requireRecord(providers[0], "Provider facility");
    const facilityName = provider.NAM_FACILITY__c;
    if (typeof facilityName !== "string" || !facilityName) {
        throw new Error("Provider facility name is unavailable");
    }
    const providerTier = normalizeQualityTier(provider.TXT_CHATS_RATING__c, provider.CDE_TYPE_PROVR__c);
    const fiscalAgreements = requireArray(initialization.fiscalAgreements, "Provider county agreements");
    const countyIds = [
        ...new Set(fiscalAgreements
            .map((agreement) => requireRecord(agreement, "Provider county agreement").CDE_COUNTY__c)
            .filter((countyId) => typeof countyId === "string")),
    ];
    if (countyIds.length === 0) {
        throw new Error("Provider county agreements are unavailable");
    }
    const countyIdByName = {};
    for (const agreement of fiscalAgreements) {
        const record = requireRecord(agreement, "Provider county agreement");
        const id = record.CDE_COUNTY__c;
        const name = asRecord(record.CDE_COUNTY__r)?.Name;
        if (typeof id === "string" && id && typeof name === "string" && name) {
            countyIdByName[name] = id;
        }
    }
    const [ratePlanData, scheduleData] = await Promise.all([
        client.getCountyData({ ...scope, countyIds }),
        client.getSchedules({ ...scope, ...(authNames ? { authNames } : {}) }),
    ]);
    const ratePlans = requireArray(requireRecord(ratePlanData, "County rate plans").countyRatePlans, "County rate plans");
    const schedules = requireArray(requireRecord(scheduleData, "Schedules").schedules, "Schedules");
    const authorizationIds = [
        ...new Set(schedules
            .map((value) => asRecord(value)?.CI_Authorization_Id__c)
            .map(authorizationKey)
            .filter((value) => Boolean(value))),
    ];
    const salesforceAuthorizationIds = authorizationIds.filter(isSalesforceId);
    const authorizationData = authorizationIds.length > 0
        ? await client.getAuthorizations({
            ...scope,
            ...(salesforceAuthorizationIds.length > 0
                ? { authIds: salesforceAuthorizationIds }
                : {}),
        })
        : undefined;
    const schedulesWithAuthorizationNames = addAuthorizationNamesToSchedules(schedules, authorizationData);
    const schedulesWithCounties = addNestedCountyIdToSchedules(schedulesWithAuthorizationNames, countyIdByName);
    const scopedSchedules = addProviderQualityTierToSchedules(addCanonicalCountyIdToSchedules(addDefaultCountyToSchedules(schedulesWithCounties, countyIds.length === 1 ? countyIds[0] : undefined)), providerTier);
    const directory = await mkdtemp(join(tmpdir(), "carepay-snapshot-"));
    const inputPath = join(directory, "snapshot.json");
    try {
        await writeFile(inputPath, JSON.stringify({
            as_of_date: asOfDate,
            schedules: scopedSchedules,
            county_rate_plans: ratePlans,
            ...(childNames ? { child_names: childNames } : {}),
        }), "utf8");
        const { stdout } = await execFileAsync("uv", ["run", evaluatorPath, inputPath], {
            windowsHide: true,
        });
        const evaluated = JSON.parse(stdout);
        if (evaluated.status !== "ok" || !evaluated.result) {
            throw new Error(evaluated.error || "Attendance risk evaluation failed");
        }
        return {
            providerDisplayName,
            facilityName,
            attendanceRisk: evaluated.result,
            paymentReadiness: livePaymentReadiness(),
            scope,
            sourceRetrievedAt: new Date().toISOString(),
        };
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
export async function getAttendanceDataAnalysis(client, scope) {
    const initialization = requireRecord(await client.initialize(scope), "Provider context");
    const provider = firstArrayRecord(initialization.providers, "Provider facility");
    const providerTier = normalizeQualityTier(provider.TXT_CHATS_RATING__c, provider.CDE_TYPE_PROVR__c);
    const countyIds = [
        ...new Set(requireArray(initialization.fiscalAgreements, "Provider county agreements")
            .map((agreement) => requireRecord(agreement, "Provider county agreement").CDE_COUNTY__c)
            .filter((countyId) => typeof countyId === "string")),
    ];
    if (countyIds.length === 0) {
        throw new Error("Provider county agreements are unavailable");
    }
    const [ratePlanData, scheduleData] = await Promise.all([
        client.getCountyData({ ...scope, countyIds }),
        client.getSchedules(scope),
    ]);
    const rawSchedules = requireArray(requireRecord(scheduleData, "Schedules").schedules, "Schedules");
    const normalized = normalizeScheduleAttendance(rawSchedules, countyIds.length === 1 ? countyIds[0] : undefined, providerTier);
    const scheduleDates = normalized.schedules
        .map((schedule) => schedule.work_date)
        .filter((value) => typeof value === "string")
        .sort();
    const servicePeriod = {
        start: scope.dateFrom ?? scheduleDates[0],
        end: scope.dateTo ?? scheduleDates[scheduleDates.length - 1],
    };
    if (!servicePeriod.start || !servicePeriod.end) {
        throw new Error("Schedules do not contain a usable service period");
    }
    const ratePlans = requireArray(requireRecord(ratePlanData, "County rate plans").countyRatePlans, "County rate plans");
    const directory = await mkdtemp(join(tmpdir(), "carepay-attendance-"));
    const inputPath = join(directory, "attendance.json");
    try {
        await writeFile(inputPath, JSON.stringify({
            schedules: normalized.schedules,
            transactions: normalized.transactions,
            county_rate_plans: ratePlans,
            service_period: servicePeriod,
        }), "utf8");
        const analyzerPath = fileURLToPath(new URL("../../../skills/agent-child-care-payment-advisor/scripts/analyze_attendance_transactions.py", import.meta.url));
        const { stdout } = await execFileAsync("uv", ["run", analyzerPath, inputPath], {
            windowsHide: true,
        });
        const evaluated = JSON.parse(stdout);
        if (evaluated.status !== "ok" || !evaluated.result) {
            throw new Error(evaluated.error || "Attendance transaction analysis failed");
        }
        return {
            ...evaluated.result,
            scope,
            sourceRetrievedAt: new Date().toISOString(),
        };
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
function firstArrayRecord(value, label) {
    if (!Array.isArray(value) || value.length === 0)
        throw new Error(`${label} is unavailable`);
    return requireRecord(value[0], label);
}
export async function getPaymentAnalysis(client, scope, view = "STATUS", asOfDate = new Date().toISOString().slice(0, 10)) {
    const initialization = requireRecord(await client.initialize(scope), "Provider context");
    const providers = requireArray(initialization.providers, "Provider facility");
    const provider = firstArrayRecord(providers, "Provider facility");
    const providerTier = normalizeQualityTier(provider.TXT_CHATS_RATING__c, provider.CDE_TYPE_PROVR__c);
    const countyIds = requireArray(initialization.fiscalAgreements, "Provider county agreements")
        .map((value) => requireRecord(value, "Provider county agreement").CDE_COUNTY__c)
        .filter((value) => typeof value === "string");
    if (countyIds.length === 0)
        throw new Error("Provider county agreements are unavailable");
    const servicePeriodData = await client.getServicePeriods(view === "NEXT_PAYOUT"
        ? { paymentAfter: "TODAY", limitOne: true }
        : view === "CURRENT_WEEK_FORECAST"
            ? { dateOn: "TODAY", limitOne: true }
            : { ...scope, limitOne: true, dateFilter: scope.dateFilter });
    const servicePeriod = firstArrayRecord(requireRecord(servicePeriodData, "Service periods").servicePeriods, "Service period");
    const serviceBeginDate = servicePeriod.serviceBeginDate;
    const serviceEndDate = servicePeriod.serviceEndDate;
    if (typeof serviceBeginDate !== "string" || typeof serviceEndDate !== "string") {
        throw new Error("Service period dates are unavailable");
    }
    const sourceScope = view === "STATUS"
        ? scope
        : { dateFilter: "DATE_RANGE", dateFrom: serviceBeginDate, dateTo: serviceEndDate };
    const [authorizationData, countyData, scheduleData, fiscalData, holidayData, paymentData] = await Promise.all([
        client.getAuthorizations({ ...sourceScope, countyIds, careDate: serviceBeginDate }),
        client.getCountyData({ ...sourceScope, countyIds }),
        client.getSchedules(sourceScope),
        client.getFiscalRates(sourceScope),
        client.getHolidayList(sourceScope),
        client.getPaymentHistory(sourceScope),
    ]);
    const authResponse = requireRecord(authorizationData, "Authorizations");
    const normalizedAuthorizations = requireArray(authResponse.normalizedAuthorizations, "Normalized authorizations");
    const authorizationMatches = {};
    const authorizations = normalizedAuthorizations.map((value) => {
        const row = requireRecord(value, "Normalized authorization");
        const authorization = requireRecord(row.authorization, "Authorization");
        const id = typeof authorization.Id === "string" ? authorization.Id : undefined;
        const match = requireRecord(row.fiscalScheduleMatch, "Fiscal schedule match");
        if (!id || match.status !== "MATCHED" || typeof match.fiscalScheduleId !== "string") {
            throw new Error("Authorization fiscal schedule mapping is incomplete");
        }
        authorizationMatches[id] = match.fiscalScheduleId;
        return {
            id,
            county_id: authorization.CDE_COUNTY__c,
            quality_tier: providerTier,
            drop_in_limit: authorization.Number_of_Drop_in_Days__c,
        };
    });
    const rawSchedules = requireArray(requireRecord(scheduleData, "Schedules").schedules, "Schedules");
    const normalized = normalizeScheduleAttendance(rawSchedules, countyIds.length === 1 ? countyIds[0] : undefined, providerTier);
    const enrichment = deriveAttendanceEnrichment(normalized.schedules, authorizationData, holidayData);
    const countyPolicies = requireArray(requireRecord(countyData, "County policies").countyRatePlans, "County policies")
        .map((value) => {
        const policy = requireRecord(value, "County policy");
        const absenceField = `absenceDaysTier${providerTier}`;
        const absenceLimit = policy[absenceField];
        if (typeof absenceLimit !== "number")
            throw new Error(`County policy ${absenceField} is unavailable`);
        return {
            county_id: policy.countyId,
            quality_tier: providerTier,
            absence_limit: absenceLimit,
            allow_paid_holidays: policy["allowPaidHolidays?"],
            county_holiday_list: policy.countyholidayList,
            allow_drop_in_days: policy.allowDropInDays,
            max_drop_in_days_per_month: policy.maxDropInDaysPerMonth,
            drop_in_response: policy.dropInResponse,
            manage_drop_in_at_auth_level: policy.manageDropInAtAuthLevel,
        };
    });
    const fiscalResponse = requireRecord(fiscalData, "Fiscal rates");
    const normalizedFiscal = requireRecord(fiscalResponse.normalizedFiscalRates, "Normalized fiscal rates");
    const fiscalRates = normalizeFiscalRatesForPayment(normalizedFiscal.fiscalRates, authorizationMatches);
    const feeSchedules = normalizePaymentFeeSchedules(normalizedFiscal.fiscalRates, normalizedFiscal.fiscalRateFees, authResponse.slotContracts, authorizationMatches);
    const payload = buildCanonicalPaymentPayload({
        servicePeriod,
        schedules: normalized.schedules,
        attendanceEnrichmentByAuthorization: enrichment,
        authorizations,
        countyPolicies,
        fiscalRates,
        paymentHistory: paymentData,
        feeSchedules,
        feeHistory: normalizePaymentFeeHistory(paymentData),
        mode: view === "CURRENT_WEEK_FORECAST" ? "FORECAST" : "STATUS",
        asOfDate,
    });
    const authorizationCopays = normalizeAuthorizationCopays(authResponse.authorizationCopays);
    payload.authorization_copays = authorizationCopays;
    const directory = await mkdtemp(join(tmpdir(), "carepay-payment-"));
    const inputPath = join(directory, "payment.json");
    try {
        await writeFile(inputPath, JSON.stringify(payload), "utf8");
        const { stdout } = await execFileAsync("uv", ["run", paymentEvaluatorPath, inputPath], { windowsHide: true });
        const evaluated = JSON.parse(stdout);
        if (evaluated.status !== "ok" || !evaluated.result)
            throw new Error(evaluated.error || "Payment evaluation failed");
        return {
            ...evaluated.result,
            scope: sourceScope,
            paymentView: view,
            servicePeriod,
            sourceRetrievedAt: new Date().toISOString(),
        };
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
