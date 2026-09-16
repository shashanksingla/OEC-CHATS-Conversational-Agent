// Consolidated payment engine: merges payment-schema.ts, payment-payload-adapter.ts, payment-canonical-adapter.ts, authorization-fiscal-schedule-matcher.ts, fiscal-rate-normalizer.ts, and payout-date.ts (2026-09-15 consolidation).
export function normalizePaymentStatus(value) {
    const status = String(value ?? "").trim().toUpperCase();
    if (status === "4" || status === "PAID")
        return "PAID";
    if (["1", "2", "3", "CREATED", "IN_PROGRESS", "CALCULATED", "REQUESTED"].includes(status)) {
        return "REQUESTED";
    }
    return undefined;
}
/**
 * Fails closed before the payload crosses the TypeScript-to-Python process
 * boundary. This is a lightweight structural check (top-level shape only) so
 * an obviously malformed payload is rejected here with a clear message
 * instead of being handed to the subprocess; the Python engine still owns
 * full field-level validation of every record it consumes.
 */
export function assertPaymentEnginePayload(payload) {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
        throw new Error("Payment engine payload must be an object");
    }
    const record = payload;
    if (record.rule_version !== "provider-risk-payment-v3") {
        throw new Error("Payment engine payload rule_version must be provider-risk-payment-v3");
    }
    const requiredArrayFields = [
        "authorizations",
        "attendance_days",
        "county_policies",
        "fiscal_rates",
        "existing_sub_payments",
    ];
    for (const field of requiredArrayFields) {
        if (!Array.isArray(record[field])) {
            throw new Error(`Payment engine payload.${field} must be an array`);
        }
    }
    const servicePeriod = record.service_period;
    if (!servicePeriod
        || typeof servicePeriod !== "object"
        || Array.isArray(servicePeriod)
        || typeof servicePeriod.id !== "string"
        || typeof servicePeriod.start_date !== "string"
        || typeof servicePeriod.end_date !== "string") {
        throw new Error("Payment engine payload.service_period must include id, start_date, and end_date");
    }
}
// ===== end payment-schema.ts =====
// ===== begin payment-payload-adapter.ts =====
import { normalizeQualityTier } from "./provider-policy.js";
function asRecord(value, label) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new Error(`${label} must be an object`);
    }
    return value;
}
function requiredString(value, label) {
    if (typeof value !== "string" || value.length === 0) {
        throw new Error(`${label} is required`);
    }
    return value;
}
function resolveAuthorizationId(value, authorizations, label) {
    const reference = typeof value === "string" && value.length > 0 ? value : undefined;
    if (!reference)
        throw new Error(`${label} is required`);
    if (authorizations.length === 0)
        return reference;
    const authorization = authorizations.find((candidate) => candidate.Name === reference || candidate.IDN_EXTNL__c === reference || candidate.Id === reference);
    return requiredString(authorization?.Id, `${label} Salesforce authorization ID`);
}
function resolveOptionalAuthorizationId(value, authorizations, label) {
    if (value === undefined || value === null || value === "")
        return undefined;
    return resolveAuthorizationId(value, authorizations, label);
}
export function normalizeServicePeriod(value) {
    const period = asRecord(value, "service period");
    // paymentReleaseDate is the real Apex-sourced release date (or its own
    // ISO-week fallback) from ServicePeriodService.cls - undefined only for a
    // synthetic CUSTOM_RANGE period with no matching T_SERV_PERIOD__c record.
    // payout_date stays optional precisely for that case.
    const releaseDate = period.paymentReleaseDate ?? period.payout_date;
    return {
        id: requiredString(period.servicePeriodId ?? period.id, "service period id"),
        start_date: requiredString(period.serviceBeginDate ?? period.start_date, "service period start date"),
        end_date: requiredString(period.serviceEndDate ?? period.end_date, "service period end date"),
        ...(typeof releaseDate === "string" && releaseDate.length > 0 ? { payout_date: releaseDate } : {}),
    };
}
export function normalizeExistingSubPayments(value, authorizations = []) {
    const response = asRecord(value, "payment history response");
    const rows = response.subPayments;
    if (!Array.isArray(rows))
        throw new Error("payment history subPayments must be an array");
    return rows.map((value, index) => {
        const row = asRecord(value, `subPayments[${index}]`);
        const status = normalizePaymentStatus(row.cde_status_pmt_sub__c);
        if (!status)
            throw new Error(`subPayments[${index}].cde_status_pmt_sub__c is unsupported`);
        const sourceAmount = row.amt_pmt_sub__c ?? row.amt_total_pmt_sub__c;
        const amount = typeof sourceAmount === "number" && Number.isFinite(sourceAmount)
            ? sourceAmount
            : typeof sourceAmount === "string" && Number.isFinite(Number(sourceAmount))
                ? Number(sourceAmount)
                : undefined;
        const authorizationId = resolveOptionalAuthorizationId(row.idn_auth__c, authorizations, `subPayments[${index}].idn_auth__c`);
        return {
            service_period_id: requiredString(row.idn_period_serv__c, `subPayments[${index}].idn_period_serv__c`),
            status,
            ...(authorizationId ? { authorization_id: authorizationId } : {}),
            ...(amount !== undefined ? { amount } : {}),
        };
    });
}
function requiredNonNegativeNumber(value, label) {
    if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
        throw new Error(`${label} must be a non-negative number`);
    }
    return value;
}
function requiredBoolean(value, label) {
    if (typeof value !== "boolean")
        throw new Error(`${label} is required`);
    return value;
}
function optionalBoolean(value) {
    return typeof value === "boolean" ? value : undefined;
}
function dateMatches(value, date) {
    return typeof value === "string" && value.slice(0, 10) === date;
}
function sourceDate(value) {
    return typeof value === "string" && value.length > 0 ? value.slice(0, 10) : undefined;
}
function childIsUnder36Months(dateOfBirth, careDate, authorizationId) {
    if (typeof dateOfBirth !== "string" || dateOfBirth.length === 0) {
        throw new Error(`child date of birth is missing for ${authorizationId}`);
    }
    const birthDate = new Date(`${dateOfBirth.slice(0, 10)}T00:00:00Z`);
    const careDateValue = new Date(`${careDate.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(birthDate.getTime()) || Number.isNaN(careDateValue.getTime())) {
        throw new Error(`child date of birth or care date is invalid for ${authorizationId} on ${careDate}`);
    }
    const thirtySixMonthDate = new Date(birthDate);
    thirtySixMonthDate.setUTCFullYear(thirtySixMonthDate.getUTCFullYear() + 3);
    return careDateValue < thirtySixMonthDate;
}
function findAuthorizationForSchedule(schedule, authorizations) {
    const references = [
        schedule.authorization_id,
        schedule.authorization_name,
        schedule.CI_Authorization_Id__c,
    ]
        .filter((reference) => (typeof reference === "string" && reference.length > 0) || typeof reference === "number")
        .map(String);
    return authorizations.find((authorization) => references.some((reference) => authorization.Id === reference
        || authorization.Name === reference
        || authorization.IDN_EXTNL__c === reference));
}
export function deriveAttendanceEnrichment(schedules, authorizationData, holidayData) {
    const response = asRecord(authorizationData, "authorization enrichment");
    const rawAuthorizations = Array.isArray(response.authorizations)
        ? response.authorizations
        : Array.isArray(response.normalizedAuthorizations)
            ? response.normalizedAuthorizations.map((value) => asRecord(value, "normalized authorization").authorization)
            : [];
    const authorizationRecords = rawAuthorizations
        .map((value, index) => asRecord(value, `authorizations[${index}]`));
    const slotContracts = Array.isArray(response.slotContracts) ? response.slotContracts : [];
    const encumbrances = Array.isArray(response.encumbrances) ? response.encumbrances : [];
    const holidays = asRecord(holidayData, "holiday enrichment").holidayList;
    if (!Array.isArray(holidays))
        throw new Error("holiday enrichment holidayList must be an array");
    const result = {};
    schedules.forEach((value, index) => {
        const schedule = asRecord(value, `schedules[${index}]`);
        const authorizationId = requiredString(schedule.authorization_id, `schedules[${index}].authorization_id`);
        const serviceDate = requiredString(schedule.work_date, `schedules[${index}].work_date`);
        const authorization = findAuthorizationForSchedule(schedule, authorizationRecords);
        // A schedule whose authorization reference cannot be matched to any
        // authorization record in this response (e.g. its CI_Authorization_Id__c
        // is absent and its raw Authorization__c lookup does not correspond to
        // any authorization id/name/external-id returned for this scope) cannot
        // have its age band, encumbrance status, or client DOB derived at all -
        // there is nothing here to guess. Previously this fell through to
        // childIsUnder36Months with an undefined client and threw "child date
        // of birth is missing", which was misleading (the DOB is not actually
        // missing from the source - the authorization link for THIS schedule
        // row never resolved) and crashed enrichment for every other schedule
        // in the same call via the enclosing forEach. Skip only this
        // unresolved row; normalizePaymentSourceBundle excludes it from the
        // payload downstream instead of fabricating enrichment for it.
        if (!authorization)
            return;
        const authorizationReferences = new Set([
            authorizationId,
            authorization?.Id,
            authorization?.Name,
            authorization?.IDN_EXTNL__c,
        ].filter((reference) => typeof reference === "string" && reference.length > 0));
        const matchingEncumbrances = encumbrances.filter((candidate) => {
            const row = asRecord(candidate, "authorization encumbrance");
            const references = [row.idn_auth__c, row.idn_encmbr_auth__c]
                .filter((reference) => typeof reference === "string" && reference.length > 0);
            return references.some((reference) => {
                if (authorizationRecords.length === 0)
                    return reference === authorizationId;
                return authorizationReferences.has(reference);
            }) && dateMatches(row.dte_care__c, serviceDate);
        });
        const clientValue = authorization?.IDN_CLIENT__r;
        const client = clientValue && typeof clientValue === "object" && !Array.isArray(clientValue)
            ? asRecord(clientValue, "authorization client")
            : undefined;
        const ageBand = childIsUnder36Months(client?.DTE_DOB__c, serviceDate, authorizationId) ? "ZERO_TO_36_MONTHS" : "OVER_36_MONTHS";
        const encumbranceStatuses = new Set(matchingEncumbrances
            .map((candidate) => normalizeEncumbranceStatus(asRecord(candidate, "authorization encumbrance").cde_status_encmbr__c))
            .filter((status) => status !== undefined));
        if (encumbranceStatuses.size !== 1) {
            throw new Error(`encumbrance status is missing or ambiguous for ${authorizationId} on ${serviceDate}`);
        }
        const matchingSlots = slotContracts.filter((candidate) => {
            const row = asRecord(candidate, "slot contract");
            const begins = row.DTE_BEGIN_SLOT__c;
            const ends = row.DTE_END_SLOT__c;
            return authorizationReferences.has(String(row.IDN_AUTH__c))
                && (!begins || String(begins).slice(0, 10) <= serviceDate)
                && (!ends || String(ends).slice(0, 10) >= serviceDate);
        });
        const occupiedSlotContract = matchingSlots.length > 0;
        const matchingHoliday = holidays.find((candidate) => {
            const holiday = asRecord(candidate, "holiday");
            return dateMatches(holiday.DTE_HOL__c, serviceDate)
                || dateMatches(holiday.DTE_OBSERVED_HOL__c, serviceDate);
        });
        const holiday = matchingHoliday ? asRecord(matchingHoliday, "holiday") : undefined;
        result[authorizationId] = {
            age_band: ageBand,
            slot_contract_present: matchingSlots.length > 0,
            occupied_slot_contract: occupiedSlotContract,
            care_not_offered: encumbranceStatuses.has("CARE_NOT_OFFERED")
                || optionalBoolean(schedule.care_not_offered) === true,
            observed_holiday: Boolean(holiday),
            ...(holiday?.CDE_HOL__c !== undefined ? { holiday_name: String(holiday.CDE_HOL__c) } : {}),
            ...(sourceDate(holiday?.DTE_HOL__c) ? { holiday_date: sourceDate(holiday?.DTE_HOL__c) } : {}),
            ...(sourceDate(holiday?.DTE_OBSERVED_HOL__c)
                ? { observed_holiday_date: sourceDate(holiday?.DTE_OBSERVED_HOL__c) }
                : {}),
        };
    });
    return result;
}
export function normalizeAttendanceDays(schedules, enrichmentByAuthorization, options = {}) {
    return schedules.map((value, index) => {
        const schedule = asRecord(value, `schedules[${index}]`);
        const authorizationId = requiredString(schedule.authorization_id, `schedules[${index}].authorization_id`);
        const enrichment = enrichmentByAuthorization[authorizationId];
        if (!enrichment)
            throw new Error(`attendance enrichment is missing for ${authorizationId}`);
        const serviceDate = requiredString(schedule.work_date, `schedules[${index}].work_date`);
        const isForecast = options.mode === "FORECAST";
        const isFutureForecast = isForecast &&
            typeof options.asOfDate === "string" &&
            serviceDate > options.asOfDate;
        const parentConfirmation = isFutureForecast || (isForecast && schedule.parent_confirmation === undefined)
            ? "PENDING"
            : schedule.parent_confirmation;
        if (parentConfirmation !== "CONFIRMED" && parentConfirmation !== "PENDING") {
            throw new Error(`schedules[${index}].parent_confirmation is required`);
        }
        const ageBand = enrichment.age_band;
        if (ageBand !== "ZERO_TO_36_MONTHS" && ageBand !== "OVER_36_MONTHS") {
            throw new Error(`attendance enrichment age_band is required for ${authorizationId}`);
        }
        return {
            authorization_id: authorizationId,
            service_date: serviceDate,
            authorized_hours: requiredNonNegativeNumber(schedule.ci_authorization_hours, `schedules[${index}].ci_authorization_hours`),
            attended_hours: isFutureForecast
                ? 0
                : typeof schedule.raw_hours === "number"
                    ? requiredNonNegativeNumber(schedule.raw_hours, `schedules[${index}].raw_hours`)
                    : isForecast
                        ? 0
                        : requiredNonNegativeNumber(schedule.raw_hours, `schedules[${index}].raw_hours`),
            parent_confirmation: parentConfirmation,
            absence_parent_approved: typeof schedule.absence_parent_approved === "boolean"
                ? schedule.absence_parent_approved
                : isForecast
                    ? false
                    : requiredBoolean(schedule.absence_parent_approved, `schedules[${index}].absence_parent_approved`),
            age_band: ageBand,
            slot_contract_present: requiredBoolean(enrichment.slot_contract_present ?? enrichment.occupied_slot_contract, `attendance enrichment slot_contract_present for ${authorizationId}`),
            occupied_slot_contract: requiredBoolean(enrichment.occupied_slot_contract, `attendance enrichment occupied_slot_contract for ${authorizationId}`),
            care_not_offered: requiredBoolean(enrichment.care_not_offered, `attendance enrichment care_not_offered for ${authorizationId}`),
            observed_holiday: requiredBoolean(enrichment.observed_holiday, `attendance enrichment observed_holiday for ${authorizationId}`),
            ...(typeof schedule.child_name === "string" ? { child_name: schedule.child_name } : {}),
            ...(typeof schedule.authorization_name === "string"
                ? { authorization_name: schedule.authorization_name }
                : typeof schedule.Authorization_Name__c === "string"
                    ? { authorization_name: schedule.Authorization_Name__c }
                    : {}),
            ...(typeof schedule.county_id === "string" ? { county_id: schedule.county_id } : {}),
            ...(typeof schedule.county_name === "string" ? { county_name: schedule.county_name } : {}),
            attendance_basis: (typeof schedule.check_in_count === "number" && schedule.check_in_count > 0)
                || schedule.attended_flag === true
                ? "ACTUAL"
                : "SCHEDULED",
            ...(isFutureForecast ? { forecast_basis: "SCHEDULED" } : {}),
            ...(typeof enrichment.holiday_name === "string" ? { holiday_name: enrichment.holiday_name } : {}),
            ...(typeof enrichment.holiday_date === "string" ? { holiday_date: enrichment.holiday_date } : {}),
            ...(typeof enrichment.observed_holiday_date === "string"
                ? { observed_holiday_date: enrichment.observed_holiday_date }
                : {}),
            ...(typeof schedule.rate_type_code === "string" && schedule.rate_type_code.length > 0
                ? { rate_type_code: schedule.rate_type_code }
                : {}),
        };
    });
}
function optionalNonNegativeNumber(value, label) {
    if (value === undefined || value === null)
        return undefined;
    return requiredNonNegativeNumber(value, label);
}
function optionalFiniteNumber(value, label) {
    if (value === undefined || value === null)
        return undefined;
    if (typeof value !== "number" || !Number.isFinite(value)) {
        throw new Error(`${label} must be a finite number`);
    }
    return value;
}
// Kept despite the ART/copay removal: this feeds evaluate_attendance's
// history-based absence-limit and drop-in-limit counting (_history_count)
// and paid-holiday-on-paired-date detection (_holiday_paid_on_paired_date)
// in provider_risk_payment_engine.py via payload.get("fee_history") -
// both explicitly kept features, unrelated to the removed ART fee-offset
// calculation that used to also read this same array's activity_paid/
// registration_paid/transportation_paid/slot_paid fields.
export function normalizePaymentFeeHistory(value, authorizations = []) {
    const response = asRecord(value, "payment history response");
    const subPayments = Array.isArray(response.subPayments) ? response.subPayments : [];
    const bySubPayment = new Map();
    subPayments.forEach((item, index) => {
        const row = asRecord(item, `subPayments[${index}]`);
        if (row.idn_pmt_sub__c !== undefined)
            bySubPayment.set(String(row.idn_pmt_sub__c), row);
    });
    const details = [
        ...(Array.isArray(response.paymentDetails) ? response.paymentDetails : []),
        ...(Array.isArray(response.paymentDetailHistory) ? response.paymentDetailHistory : []),
    ];
    return details.map((item, index) => {
        const detail = asRecord(item, `payment detail[${index}]`);
        const subPayment = bySubPayment.get(String(detail.idn_pmt_sub__c));
        const normalized = {
            authorization_id: resolveAuthorizationId(subPayment?.idn_auth__c, authorizations, `payment detail[${index}].authorization_id`),
            service_date: requiredString(detail.dte_care__c, `payment detail[${index}].dte_care__c`),
        };
        if (detail.cde_type_info_addntl__c !== undefined)
            normalized.info_code = detail.cde_type_info_addntl__c;
        if (detail.ind_record_delete_logcl__c !== undefined) {
            normalized.deleted = detail.ind_record_delete_logcl__c === true;
        }
        return normalized;
    });
}
function requiredRecords(value, label) {
    if (!Array.isArray(value) || value.length === 0) {
        throw new Error(`${label} must contain at least one record`);
    }
    return value.map((item, index) => asRecord(item, `${label}[${index}]`));
}
export function buildCanonicalPaymentPayload(input) {
    const authorizationRows = input.authorizationRecords ?? [];
    const authorizationById = new Map(authorizationRows
        .filter((row) => typeof row.Id === "string")
        .map((row) => [row.Id, row]));
    const countyPolicyRows = requiredRecords(input.countyPolicies, "county policies");
    const countyPolicyById = new Map(countyPolicyRows.map((row) => [String(row.countyId ?? row.CDE_COUNTY__c ?? ""), row]));
    return {
        rule_version: "provider-risk-payment-v3",
        as_of_date: requiredString(input.asOfDate, "as-of date"),
        ...(input.mode
            ? { calculation_mode: input.mode === "FORECAST" ? "CURRENT_WEEK_FORECAST" : "STATUS" }
            : {}),
        service_period: normalizeServicePeriod(input.servicePeriod),
        authorizations: requiredRecords(input.authorizations, "authorizations"),
        attendance_days: normalizeAttendanceDays(input.schedules, input.attendanceEnrichmentByAuthorization, {
            ...(input.mode ? { mode: input.mode } : {}),
            ...(input.asOfDate ? { asOfDate: input.asOfDate } : {}),
        }),
        county_policies: countyPolicyRows,
        ...(input.providerClosureDates && input.providerClosureDates.length > 0
            ? { provider_closure_dates: [...new Set(input.providerClosureDates.map((value) => value.slice(0, 10)))] }
            : {}),
        fiscal_rates: requiredRecords(input.fiscalRates, "fiscal rates"),
        existing_sub_payments: normalizeExistingSubPayments(input.paymentHistory, input.authorizationRecords),
        ...(input.feeHistory ? { fee_history: input.feeHistory } : {}),
        ...(input.vacantSlotSchedules ? { vacant_slot_schedules: input.vacantSlotSchedules } : {}),
    };
}
export { normalizeQualityTier } from "./provider-policy.js";
export function normalizeEncumbranceStatus(value) {
    const status = String(value ?? "").trim().toUpperCase();
    const statuses = {
        "1": "PENDING",
        "2": "AUTHORIZED",
        "3": "ATTENDED",
        "4": "PAID",
        "5": "CARE_NOT_OFFERED",
        PENDING: "PENDING",
        AUTHORIZED: "AUTHORIZED",
        ATTENDED: "ATTENDED",
        PAID: "PAID",
        "CARE NOT OFFERED": "CARE_NOT_OFFERED",
        CARE_NOT_OFFERED: "CARE_NOT_OFFERED",
    };
    return statuses[status];
}
export function normalizeFiscalRatesForPayment(normalizedFiscalRates, authorizationMatches, authorizationAgeGroupCodes = {}, 
// An authorization's own schedule rows can each use a DIFFERENT rate
// type across one service period (live-confirmed: one authorization's 7
// days in a week used rate types 31/31/31/1/91/43/37 - overnight,
// regular, out-of-county, evening, weekend all under the same
// authorization). A single rate-type string here would keep only the
// fiscal rate rows for ONE of those rate types and silently exclude
// every day whose rate type differs - the confirmed root cause of the
// recurring "rate unavailable" exclusions. Every rate type list must be
// checked for membership, not equality against one value.
authorizationRateTypeCodes = {}) {
    const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
    return rates.flatMap((rate, index) => {
        const scheduleId = requiredString(rate.fiscalScheduleId, `normalized fiscal rates[${index}].fiscalScheduleId`);
        const authorizationIds = Object.entries(authorizationMatches)
            .filter(([, matchedScheduleId]) => matchedScheduleId === scheduleId)
            .map(([authorizationId]) => authorizationId);
        const paidTier = rate.paidTier;
        if (authorizationIds.length === 0)
            return [];
        if (typeof paidTier !== "string") {
            throw new Error(`fiscal rate ${scheduleId} cannot be joined to a paid tier`);
        }
        return authorizationIds
            .filter((authorizationId) => {
            const rateTypeCodes = authorizationRateTypeCodes[authorizationId];
            const ageGroups = authorizationAgeGroupCodes[authorizationId];
            return (!rateTypeCodes || rateTypeCodes.length === 0 || rateTypeCodes.includes(String(rate.rateTypeCode)))
                && (!ageGroups || rate.ageGroupCode === undefined
                    || ageGroups.includes(String(rate.ageGroupCode)));
        })
            .map((authorizationId) => ({
            authorization_id: authorizationId,
            paid_tier: paidTier,
            ...(rate.rateTypeCode !== undefined && rate.rateTypeCode !== null
                ? { rate_type_code: String(rate.rateTypeCode) }
                : {}),
            amount: Number(rate.fiscalAgreementAmount),
            source_id: rate.sourceId,
        }));
    });
}
export function deriveFiscalAgeGroupCodes(dateOfBirth, careDate) {
    if (typeof dateOfBirth !== "string" || dateOfBirth.length === 0)
        return undefined;
    const birthDate = new Date(`${dateOfBirth.slice(0, 10)}T00:00:00Z`);
    const careDateValue = new Date(`${careDate.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(birthDate.getTime()) || Number.isNaN(careDateValue.getTime()))
        return undefined;
    let months = (careDateValue.getUTCFullYear() - birthDate.getUTCFullYear()) * 12
        + careDateValue.getUTCMonth() - birthDate.getUTCMonth();
    if (careDateValue.getUTCDate() < birthDate.getUTCDate())
        months -= 1;
    if (months < 0)
        return undefined;
    if (months < 6)
        return ["1"];
    if (months < 12)
        return ["2"];
    if (months < 18)
        return ["3"];
    if (months < 24)
        return ["4"];
    if (months < 30)
        return ["5"];
    if (months < 36)
        return ["6"];
    return months < 60 ? ["7"] : ["8"];
}
// ===== end payment-payload-adapter.ts =====
// ===== begin payment-canonical-adapter.ts =====
import { normalizeProviderContext } from "./provider-context.js";
import { normalizeScheduleAttendance } from "./schedule-normalizer.js";
function record(value, label) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new Error(`${label} is unavailable`);
    }
    return value;
}
function array(value, label) {
    if (!Array.isArray(value))
        throw new Error(`${label} is unavailable`);
    return value;
}
function first(value, label) {
    const rows = array(value, label);
    if (rows.length === 0)
        throw new Error(`${label} is unavailable`);
    return record(rows[0], label);
}
function containsRateType(value, requested) {
    return value
        .split(/[,;|\s]+/)
        .map((token) => token.trim())
        .filter((token) => token.length > 0)
        .includes(requested);
}
export function normalizePaymentSourceBundle(sources) {
    const initialization = record(sources.initialization, "Provider context");
    const { qualityTier: providerTier, countyIds, countyIdByName } = normalizeProviderContext(initialization);
    const countyNameById = Object.fromEntries(Object.entries(countyIdByName).map(([countyName, countyId]) => [countyId, countyName]));
    const countyPlanRows = array(record(sources.countyData, "County policies").countyRatePlans, "County policies");
    for (const value of countyPlanRows) {
        const policy = record(value, "County policy");
        const countyId = policy.countyId ?? policy.County__c ?? policy.CDE_COUNTY__c;
        const county = policy.County__r;
        const countyRecord = county && typeof county === "object" && !Array.isArray(county)
            ? county
            : undefined;
        const countyName = policy.countyName ?? policy.County_Name__c ?? countyRecord?.Name ?? countyRecord?.County_Name__c;
        if ((typeof countyId === "string" || typeof countyId === "number") && typeof countyName === "string") {
            countyNameById[String(countyId)] = countyName;
        }
    }
    const servicePeriod = normalizeServicePeriod(sources.servicePeriod);
    const authorizationData = record(sources.authorizationData, "Authorizations");
    const normalizedAuthorizations = array(authorizationData.normalizedAuthorizations, "Normalized authorizations");
    const authorizationRecords = normalizedAuthorizations.map((value, index) => record(record(value, `Normalized authorization[${index}]`).authorization, `Authorization[${index}]`));
    const authorizationMatches = {};
    // An authorization's own schedule rows can use several DIFFERENT rate
    // types across one service period (verified live: 31/31/31/1/91/43/37
    // across one week) - a single string here would only let one of those
    // rate types find its fiscal rate row downstream, silently excluding
    // every day whose rate type isn't the one retained. See client.ts's
    // getAuthorizations for where this list is populated.
    const authorizationRateTypeCodes = {};
    const authorizationAgeGroupCodes = {};
    // An UNRESOLVED fiscalScheduleMatch on one authorization (e.g. a fiscal
    // schedule that genuinely has no county/rate-type/date match in the
    // source data) is a per-authorization data-quality gap, not an invariant
    // violation of the whole request - a hard throw here previously crashed
    // the entire payment computation for every authorization in the period
    // (and, via getServicePeriodLedger's Promise.all, every other period in
    // the same ledger/NEXT_PAYOUT call) over one bad row. Skip the
    // unresolved row and track it, mirroring the vacantSlotMappingGaps
    // silent-drop-risk pattern below, instead of failing the whole request.
    let authorizationMappingGaps = 0;
    const authorizations = normalizedAuthorizations.flatMap((value, index) => {
        const row = record(value, `Normalized authorization[${index}]`);
        const authorization = record(row.authorization, `Authorization[${index}]`);
        const match = record(row.fiscalScheduleMatch, `Fiscal schedule match[${index}]`);
        if (typeof authorization.Id !== "string" ||
            match.status !== "MATCHED" ||
            typeof match.fiscalScheduleId !== "string") {
            authorizationMappingGaps += 1;
            return [];
        }
        authorizationMatches[authorization.Id] = match.fiscalScheduleId;
        if (Array.isArray(row.rateTypeCode) && row.rateTypeCode.every((code) => typeof code === "string") && row.rateTypeCode.length > 0) {
            authorizationRateTypeCodes[authorization.Id] = row.rateTypeCode;
        }
        const client = authorization.IDN_CLIENT__r;
        const ageGroupCodes = client && typeof client === "object" && !Array.isArray(client)
            ? deriveFiscalAgeGroupCodes(client.DTE_DOB__c, servicePeriod.start_date)
            : undefined;
        if (ageGroupCodes)
            authorizationAgeGroupCodes[authorization.Id] = ageGroupCodes;
        return [{
                id: authorization.Id,
                county_id: authorization.CDE_COUNTY__c,
                quality_tier: providerTier,
                drop_in_limit: authorization.Number_of_Drop_in_Days__c,
            }];
    });
    const normalizedSchedules = normalizeScheduleAttendance(array(record(sources.scheduleData, "Schedules").schedules, "Schedules"), countyIds.length === 1 ? countyIds[0] : undefined, providerTier, authorizationData);
    const schedulesWithCountyNames = normalizedSchedules.schedules.map((schedule) => {
        if (schedule.county_name || typeof schedule.county_id !== "string")
            return schedule;
        const countyName = countyNameById[schedule.county_id];
        return countyName ? { ...schedule, county_name: countyName } : schedule;
    });
    const enrichment = deriveAttendanceEnrichment(schedulesWithCountyNames, authorizationData, sources.holidayData);
    // deriveAttendanceEnrichment skips (does not add an entry for) any
    // schedule whose authorization reference could not be matched to a real
    // authorization record - there is no age band, encumbrance status, or
    // client DOB to derive for it. normalizeAttendanceDays requires an
    // enrichment entry for every schedule it receives, so those same
    // unresolved rows must be excluded here too, otherwise they would hit
    // the exact same "enrichment is missing" wall one step later. This is a
    // genuine per-row data-quality gap (an orphaned schedule/authorization
    // link), not a reason to drop every other valid schedule in the period.
    const enrichedSchedules = schedulesWithCountyNames.filter((schedule) => typeof schedule.authorization_id === "string" && schedule.authorization_id in enrichment);
    authorizationMappingGaps += schedulesWithCountyNames.length - enrichedSchedules.length;
    const countyPolicies = countyPlanRows.map((value, index) => {
        const policy = record(value, `County policy[${index}]`);
        const absenceLimit = policy[`absenceDaysTier${providerTier}`];
        if (typeof absenceLimit !== "number") {
            throw new Error(`County policy absenceDaysTier${providerTier} is unavailable`);
        }
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
            activityArtCap: policy.activityArtCap,
            registrationArtCap: policy.registrationArtCap,
            transportationArtCap: policy.transportationArtCap,
        };
    });
    const normalizedFiscal = record(record(sources.fiscalData, "Fiscal rates").normalizedFiscalRates, "Normalized fiscal rates");
    const fiscalRates = normalizeFiscalRatesForPayment(normalizedFiscal.fiscalRates, authorizationMatches, authorizationAgeGroupCodes, authorizationRateTypeCodes);
    const providerClosures = Array.isArray(initialization.providerClosures)
        ? initialization.providerClosures
        : Array.isArray(initialization.provider_closures)
            ? initialization.provider_closures
            : [];
    const providerClosureDates = providerClosures.flatMap((value) => {
        const closure = record(value, "Provider closure");
        const date = closure.DTE_BEGIN_CLOSURE__c ?? closure.closure_date;
        return typeof date === "string" ? [date] : [];
    });
    const vacantSlotData = record(sources.vacantSlotData ?? { vacantSlots: [] }, "Vacant slots");
    const paymentHistory = sources.paymentData;
    let vacantSlotMappingGaps = 0;
    const payload = buildCanonicalPaymentPayload({
        servicePeriod,
        schedules: enrichedSchedules,
        attendanceEnrichmentByAuthorization: enrichment,
        authorizations,
        countyPolicies,
        fiscalRates,
        paymentHistory,
        authorizationRecords,
        providerClosureDates,
        vacantSlotSchedules: (() => {
            const resolved = normalizeVacantSlotSchedules(vacantSlotData.vacantSlots, normalizedFiscal.fiscalRates, countyIds, providerTier, sources.initialization, countyNameById);
            vacantSlotMappingGaps = countEligibleVacantSlots(vacantSlotData.vacantSlots) - resolved.length;
            return resolved;
        })(),
        mode: sources.mode,
        asOfDate: sources.asOfDate,
    });
    return { payload, servicePeriod, vacantSlotMappingGaps, authorizationMappingGaps };
}
// A vacant slot that is genuinely occupied (IDN_AUTH__c set) is correctly
// excluded by normalizeVacantSlotSchedules and is not a mapping gap. Any
// other vacant slot that normalizeVacantSlotSchedules could not price
// (no matching rate schedule) is a silent-drop risk: it contributes $0 to
// the vacant-slot fee instead of surfacing as a data-quality gap. Track that
// count here so callers can report it rather than let it vanish untraced.
function countEligibleVacantSlots(slots) {
    if (!Array.isArray(slots))
        return 0;
    return slots.filter((value) => {
        const slot = value && typeof value === "object" && !Array.isArray(value) ? value : undefined;
        if (!slot)
            return false;
        return slot.IDN_AUTH__c === null || slot.IDN_AUTH__c === undefined;
    }).length;
}
export function normalizeVacantSlotSchedules(slots, normalizedFiscalRates, countyIds, providerQualityTier, initialization, countyNameById = {}) {
    if (!Array.isArray(slots))
        throw new Error("vacantSlots must be an array");
    const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
    const context = record(initialization, "Provider context");
    const agreements = Array.isArray(context.fiscalAgreements) ? context.fiscalAgreements : [];
    const closures = Array.isArray(context.providerClosures) ? context.providerClosures : [];
    const scheduleByCounty = new Map();
    for (const value of agreements) {
        const agreement = record(value, "Provider county agreement");
        const countyId = agreement.CDE_COUNTY__c;
        const schedules = agreement.Rate_Schedules__r;
        const rows = schedules && typeof schedules === "object" && !Array.isArray(schedules)
            ? schedules.records
            : undefined;
        if (typeof countyId !== "string" || !countyIds.includes(countyId) || !Array.isArray(rows))
            continue;
        scheduleByCounty.set(countyId, rows.flatMap((row) => {
            const schedule = record(row, "Rate schedule");
            if (typeof schedule.IDN_EXTNL__c !== "string"
                || typeof schedule.CDE_RATE_TYPE__c !== "string"
                || typeof schedule.DTE_BEGIN_EFFV__c !== "string")
                return [];
            const qualityTier = typeof schedule.TXT_CHATS_RATING__c === "string"
                ? normalizeQualityTier(schedule.TXT_CHATS_RATING__c, undefined)
                : undefined;
            return [{
                    id: schedule.IDN_EXTNL__c,
                    rateTypeCode: schedule.CDE_RATE_TYPE__c,
                    ...(qualityTier !== undefined ? { qualityTier } : {}),
                    beginDate: schedule.DTE_BEGIN_EFFV__c,
                    ...(typeof schedule.DTE_END_EFFV__c === "string" ? { endDate: schedule.DTE_END_EFFV__c } : {}),
                }];
        }));
    }
    return slots.flatMap((value, index) => {
        const slot = record(value, `vacantSlots[${index}]`);
        if (slot.IDN_AUTH__c !== null && slot.IDN_AUTH__c !== undefined)
            return [];
        const countyId = requiredString(slot.CDE_COUNTY__c, `vacantSlots[${index}].CDE_COUNTY__c`);
        const slotStart = requiredString(slot.DTE_BEGIN_SLOT__c, `vacantSlots[${index}].DTE_BEGIN_SLOT__c`);
        const slotEnd = typeof slot.DTE_END_SLOT__c === "string" ? slot.DTE_END_SLOT__c : undefined;
        const scheduleMatches = (scheduleByCounty.get(countyId) ?? []).filter((schedule) => containsRateType(schedule.rateTypeCode, String(slot.CDE_RATE_TYPE__c))
            && schedule.qualityTier === providerQualityTier
            && schedule.beginDate <= (slotEnd ?? slotStart)
            && (schedule.endDate === undefined || schedule.endDate >= slotStart));
        if (scheduleMatches.length === 0)
            return [];
        const firstScheduleMatch = scheduleMatches[0];
        if (!firstScheduleMatch)
            return [];
        const latestBeginDate = scheduleMatches.reduce((latest, schedule) => schedule.beginDate > latest ? schedule.beginDate : latest, firstScheduleMatch.beginDate);
        const effectiveSchedules = scheduleMatches.filter((schedule) => schedule.beginDate === latestBeginDate);
        if (effectiveSchedules.length !== 1)
            return [];
        const selectedSchedule = effectiveSchedules[0];
        if (!selectedSchedule)
            return [];
        const matches = rates.filter((rate) => rate.fiscalScheduleId === selectedSchedule.id
            && rate.rateTypeCode === String(slot.CDE_RATE_TYPE__c)
            && rate.careUnitCode === String(slot.CDE_CARE_UNIT__c)
            && rate.ageGroupCode === String(slot.CDE_CARE_LEVEL__c));
        if (matches.length !== 1 || !matches[0])
            return [];
        const rate = matches[0];
        const closureDates = closures.flatMap((value) => {
            const closure = record(value, "Provider closure");
            return closure.IDN_PROVIDER__c === slot.IDN_PROVIDER__c
                && closure.CDE_COUNTY__c === countyId
                && typeof closure.DTE_BEGIN_CLOSURE__c === "string"
                ? [closure.DTE_BEGIN_CLOSURE__c.slice(0, 10)]
                : [];
        });
        const daysOfMonth = optionalNonNegativeNumber(slot.CNT_DAYS_OF_MONTH__c, `vacantSlots[${index}].CNT_DAYS_OF_MONTH__c`);
        return [{
                slot_contract_id: requiredString(slot.Id, `vacantSlots[${index}].Id`),
                county_id: countyId,
                ...(countyNameById[countyId] ? { county_name: countyNameById[countyId] } : {}),
                fiscal_schedule_id: selectedSchedule.id,
                effective_start: slotStart,
                ...(slot.DTE_END_SLOT__c ? { effective_end: requiredString(slot.DTE_END_SLOT__c, `vacantSlots[${index}].DTE_END_SLOT__c`) } : {}),
                ...(daysOfMonth !== undefined ? { days_of_month: daysOfMonth } : {}),
                ...(typeof slot.CNT_DAYS_OF_WEEK__c === "string" || typeof slot.CNT_DAYS_OF_WEEK__c === "number"
                    ? { days_of_week: slot.CNT_DAYS_OF_WEEK__c }
                    : {}),
                slot_rate_amount: Number(rate.fiscalAgreementAmount),
                ...(closureDates.length > 0 ? { provider_closure_dates: closureDates } : {}),
            }];
    });
}
function containsDate(beginDate, endDate, date) {
    return beginDate <= date && (endDate === undefined || endDate >= date);
}
export function selectFiscalScheduleForAuthorization(authorizationValue, schedules, careDate, 
// A single authorization's schedule can legitimately carry a DIFFERENT
// rate type per day across one service period (e.g. regular weekdays,
// an evening day, a weekend day, an overnight day, all under the SAME
// authorization) - live org data confirmed one authorization's 7 days in
// a week using rate types 31/31/31/1/91/43/37. Accepting only a single
// scheduleRateType here (and its caller previously collapsing all of an
// authorization's rate types down to just one, last-wins) matched a
// schedule that only actually covers ONE of those rate types, then
// silently excluded every other day's rate rows downstream - the
// confirmed root cause of the recurring "rate unavailable" exclusions.
// Accept every rate type the authorization's days actually use and
// match if the candidate schedule serves ANY of them - the schedule
// record itself spans multiple rate types (verified: one externalId's
// rate rows cover rate types 1/31/37/43/91 together), so requiring an
// exact single-value match was never structurally correct.
scheduleRateTypes) {
    const authorization = record(authorizationValue, "authorization");
    const countyId = requiredString(authorization.CDE_COUNTY__c, "authorization.CDE_COUNTY__c");
    const authorizationBegin = requiredString(authorization.DTE_BEGIN_EFFV_AUTH__c, "authorization.DTE_BEGIN_EFFV_AUTH__c");
    const authorizationEnd = typeof authorization.DTE_END_EFFV_AUTH__c === "string"
        ? authorization.DTE_END_EFFV_AUTH__c
        : undefined;
    if (!containsDate(authorizationBegin, authorizationEnd, careDate)) {
        return { status: "UNRESOLVED", reason: "NO_MATCH" };
    }
    const requestedRateTypes = (scheduleRateTypes ?? []).filter((value) => value.length > 0);
    if (requestedRateTypes.length === 0) {
        return { status: "UNRESOLVED", reason: "MISSING_SCHEDULE_RATE_TYPE" };
    }
    // Filtered step-by-step (county -> rate type -> date) instead of one
    // combined filter, so a zero-result step reports exactly which
    // criterion failed - previously all three collapsed into one opaque
    // "NO_MATCH", which told a debugger nothing about whether the county,
    // the rate type, or the date range was the actual problem.
    const countyMatches = schedules.filter((schedule) => schedule.countyId === countyId);
    if (countyMatches.length === 0)
        return { status: "UNRESOLVED", reason: "NO_MATCH_COUNTY" };
    const rateTypeMatches = countyMatches.filter((schedule) => requestedRateTypes.some((rateType) => containsRateType(schedule.rateTypeCode, rateType)));
    if (rateTypeMatches.length === 0)
        return { status: "UNRESOLVED", reason: "NO_MATCH_RATE_TYPE" };
    const matches = rateTypeMatches.filter((schedule) => containsDate(schedule.beginDate, schedule.endDate, careDate));
    if (matches.length === 0)
        return { status: "UNRESOLVED", reason: "NO_MATCH_DATE" };
    const firstMatch = matches[0];
    if (!firstMatch)
        return { status: "UNRESOLVED", reason: "NO_MATCH_DATE" };
    const latestBeginDate = matches.reduce((latest, schedule) => schedule.beginDate > latest ? schedule.beginDate : latest, firstMatch.beginDate);
    const latestMatches = matches.filter((schedule) => schedule.beginDate === latestBeginDate);
    if (latestMatches.length !== 1) {
        return { status: "UNRESOLVED", reason: "AMBIGUOUS_MATCH" };
    }
    const selectedMatch = latestMatches[0];
    if (!selectedMatch)
        return { status: "UNRESOLVED", reason: "NO_MATCH" };
    return { status: "MATCHED", fiscalScheduleId: selectedMatch.externalId };
}
const AGE_GROUP_LABELS = {
    "1": "0-6 Months",
    "2": "06-12 Months",
    "3": "12-18 Months",
    "4": "18-24 Months",
    "5": "24-30 Months",
    "6": "30-36 Months",
    "7": "36 - School Age",
    "8": "School Age",
};
const CARE_UNIT_LABELS = {
    "1": "NP",
    "2": "PT",
    "3": "FT",
    "4": "FTPT",
    "5": "FTFT",
};
const PAID_TIER_BY_CARE_UNIT = {
    "1": "NO_PAYMENT",
    "2": "PART_TIME",
    "3": "FULL_TIME",
    "4": "FULL_TIME_PLUS_PART_TIME",
    "5": "FULL_TIME_PLUS_FULL_TIME",
};
const RATE_TYPE_LABELS = {
    "1": "Regular",
    "13": "Before School",
    "19": "After School",
    "25": "B and A School",
    "31": "Overnight",
    "37": "Weekend",
    "43": "Evening",
    "55": "Disability",
    "91": "Out-of-County",
};
export const R00393_VALUES = {
    "1": 15650,
    ADD: 5500,
};
function money(value, label) {
    if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
        throw new Error(`${label} must be a non-negative number`);
    }
    return value.toFixed(2);
}
function optionalString(value) {
    return typeof value === "string" && value.length > 0 ? value : undefined;
}
function optionalMoney(value, label) {
    if (value === undefined || value === null)
        return undefined;
    return money(value, label);
}
function mappedLabel(value, mappings, label) {
    const code = requiredString(value, label);
    const mapped = mappings[code];
    if (!mapped)
        throw new Error(`${label} has unsupported code ${code}`);
    return mapped;
}
export function normalizeFiscalRateResponse(value) {
    const data = record(value, "fiscal-rate response");
    const rawRates = data.fiscalRates;
    const rawFees = data.fiscalRateFees;
    if (!Array.isArray(rawRates))
        throw new Error("fiscalRates must be an array");
    if (!Array.isArray(rawFees))
        throw new Error("fiscalRateFees must be an array");
    const unresolvedMappings = [];
    const fiscalRates = rawRates.map((value, index) => {
        const row = record(value, `fiscalRates[${index}]`);
        const sourceId = requiredString(row.Id, `fiscalRates[${index}].Id`);
        const fiscalScheduleId = requiredString(row.idn_fiscal_sch__c, `fiscalRates[${index}].idn_fiscal_sch__c`);
        const rateTypeCode = requiredString(row.cde_rate_type__c, `fiscalRates[${index}].cde_rate_type__c`);
        const ageGroupCode = requiredString(row.cde_age_group__c, `fiscalRates[${index}].cde_age_group__c`);
        const careUnitCode = requiredString(row.cde_care_unit__c, `fiscalRates[${index}].cde_care_unit__c`);
        const paidTier = PAID_TIER_BY_CARE_UNIT[careUnitCode];
        if (!paidTier)
            unresolvedMappings.push(`fiscalRates[${index}].cde_care_unit__c=${careUnitCode}`);
        return {
            sourceId,
            fiscalScheduleId,
            rateTypeCode,
            rateTypeLabel: mappedLabel(row.cde_rate_type__c, RATE_TYPE_LABELS, `fiscalRates[${index}].cde_rate_type__c`),
            ageGroupCode,
            ageGroupLabel: mappedLabel(row.cde_age_group__c, AGE_GROUP_LABELS, `fiscalRates[${index}].cde_age_group__c`),
            careUnitCode,
            careUnitLabel: mappedLabel(row.cde_care_unit__c, CARE_UNIT_LABELS, `fiscalRates[${index}].cde_care_unit__c`),
            ...(paidTier ? { paidTier } : {}),
            countyAmount: money(row.amt_cty__c, `fiscalRates[${index}].amt_cty__c`),
            fiscalAgreementAmount: money(row.amt_fa__c, `fiscalRates[${index}].amt_fa__c`),
            providerAmount: money(row.amt_provr__c, `fiscalRates[${index}].amt_provr__c`),
        };
    });
    const fiscalRateFees = rawFees.map((value, index) => {
        const row = record(value, `fiscalRateFees[${index}]`);
        const fee = {
            sourceId: requiredString(row.Id, `fiscalRateFees[${index}].Id`),
            fiscalScheduleId: requiredString(row.IDN_FISCAL_SCH__c, `fiscalRateFees[${index}].IDN_FISCAL_SCH__c`),
        };
        const activityFrequency = optionalString(row.CDE_ACT_FREQ__c);
        const registrationFrequency = optionalString(row.CDE_REG_FREQ__c);
        const transportationFrequency = optionalString(row.CDE_TRANS_FREQ__c);
        const activityMonths = optionalString(row.TXT_ACT_MONTH__c);
        const registrationMonths = optionalString(row.TXT_REG_MONTH__c);
        const transportationMonths = optionalString(row.TXT_TRANS_MONTH__c);
        const activityCountyAmount = optionalMoney(row.AMT_ACT_CTY__c, `fiscalRateFees[${index}].AMT_ACT_CTY__c`);
        const activityFiscalAgreementAmount = optionalMoney(row.AMT_ACT_FA__c, `fiscalRateFees[${index}].AMT_ACT_FA__c`);
        const activityProviderAmount = optionalMoney(row.AMT_ACT_PROVR__c, `fiscalRateFees[${index}].AMT_ACT_PROVR__c`);
        const registrationCountyAmount = optionalMoney(row.AMT_REG_CTY__c, `fiscalRateFees[${index}].AMT_REG_CTY__c`);
        const registrationFiscalAgreementAmount = optionalMoney(row.AMT_REG_FA__c, `fiscalRateFees[${index}].AMT_REG_FA__c`);
        const registrationProviderAmount = optionalMoney(row.AMT_REG_PROVR__c, `fiscalRateFees[${index}].AMT_REG_PROVR__c`);
        const transportationCountyAmount = optionalMoney(row.AMT_TRANS_CTY__c, `fiscalRateFees[${index}].AMT_TRANS_CTY__c`);
        const transportationFiscalAgreementAmount = optionalMoney(row.AMT_TRANS_FA__c, `fiscalRateFees[${index}].AMT_TRANS_FA__c`);
        const transportationProviderAmount = optionalMoney(row.AMT_TRANS_PROVR__c, `fiscalRateFees[${index}].AMT_TRANS_PROVR__c`);
        if (activityFrequency)
            fee.activityFrequency = activityFrequency;
        if (registrationFrequency)
            fee.registrationFrequency = registrationFrequency;
        if (transportationFrequency)
            fee.transportationFrequency = transportationFrequency;
        if (activityMonths)
            fee.activityMonths = activityMonths;
        if (registrationMonths)
            fee.registrationMonths = registrationMonths;
        if (transportationMonths)
            fee.transportationMonths = transportationMonths;
        if (activityCountyAmount !== undefined)
            fee.activityCountyAmount = activityCountyAmount;
        if (activityFiscalAgreementAmount !== undefined) {
            fee.activityFiscalAgreementAmount = activityFiscalAgreementAmount;
        }
        if (activityProviderAmount !== undefined)
            fee.activityProviderAmount = activityProviderAmount;
        if (registrationCountyAmount !== undefined)
            fee.registrationCountyAmount = registrationCountyAmount;
        if (registrationFiscalAgreementAmount !== undefined) {
            fee.registrationFiscalAgreementAmount = registrationFiscalAgreementAmount;
        }
        if (registrationProviderAmount !== undefined)
            fee.registrationProviderAmount = registrationProviderAmount;
        if (transportationCountyAmount !== undefined)
            fee.transportationCountyAmount = transportationCountyAmount;
        if (transportationFiscalAgreementAmount !== undefined) {
            fee.transportationFiscalAgreementAmount = transportationFiscalAgreementAmount;
        }
        if (transportationProviderAmount !== undefined)
            fee.transportationProviderAmount = transportationProviderAmount;
        return fee;
    });
    return {
        fiscalRates,
        fiscalRateFees,
        // Must reflect unresolvedMappings rather than a hardcoded literal: a
        // caller (mapping_status in read-model-adapters.ts) trusts this field to
        // know whether every code was resolved without inspecting the array itself.
        canonicalMappingStatus: unresolvedMappings.length > 0 ? "PARTIAL_CODE_MAPPING" : "COMPLETE_CODE_MAPPING",
        unresolvedMappings,
        r00393Values: { ...R00393_VALUES },
    };
}
// ===== end fiscal-rate-normalizer.ts =====
// ===== begin payout-date.ts =====
/**
 * Payout Date = Service Period End Date (Sunday) + 12 days - always resolves
 * to Friday, the true payment release date (confirmed against real
 * T_SERV_PERIOD__c sample data: DTE_BATCH_FILE_PMT__c/release is one day
 * after DTE_BATCH_PRCS_PMT__c/processing). Mirrors compute_payout_date() in
 * skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py
 * exactly - do not change the +12 offset here without updating that Python
 * function and both test suites in the same change. This formula is now
 * strictly a last-resort fallback - the real Apex-sourced
 * paymentReleaseDate (from ServicePeriodService.cls) is preferred wherever
 * a resolved service-period record is available.
 */
export const PAYOUT_DATE_OFFSET_DAYS = 12;
/**
 * The engine's payment.payout_date is authoritative when available; this
 * utility is for call sites that do not perform a full engine run.
 *
 * @param serviceEndDateIso ISO date string (YYYY-MM-DD) for the service period end date.
 * @returns ISO date string (YYYY-MM-DD) for the computed payout date.
 */
// Engine payment.payout_date is authoritative when available; use this for call sites without a full engine run.
export function computePayoutDate(serviceEndDateIso) {
    const parsed = new Date(`${serviceEndDateIso}T00:00:00Z`);
    parsed.setUTCDate(parsed.getUTCDate() + PAYOUT_DATE_OFFSET_DAYS);
    return parsed.toISOString().slice(0, 10);
}
// ===== end payout-date.ts =====
