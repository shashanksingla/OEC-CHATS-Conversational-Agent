import { normalizePaymentStatus, } from "./payment-schema.js";
export { normalizePaymentStatus, } from "./payment-schema.js";
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
export function normalizeServicePeriod(value) {
    const period = asRecord(value, "service period");
    return {
        id: requiredString(period.servicePeriodId ?? period.id, "service period id"),
        start_date: requiredString(period.serviceBeginDate ?? period.start_date, "service period start date"),
        end_date: requiredString(period.serviceEndDate ?? period.end_date, "service period end date"),
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
        return {
            authorization_id: resolveAuthorizationId(row.idn_auth__c, authorizations, `subPayments[${index}].idn_auth__c`),
            service_period_id: requiredString(row.idn_period_serv__c, `subPayments[${index}].idn_period_serv__c`),
            status,
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
            ...(isFutureForecast ? { forecast_basis: "SCHEDULED" } : {}),
            ...(typeof enrichment.holiday_name === "string" ? { holiday_name: enrichment.holiday_name } : {}),
            ...(typeof enrichment.holiday_date === "string" ? { holiday_date: enrichment.holiday_date } : {}),
            ...(typeof enrichment.observed_holiday_date === "string"
                ? { observed_holiday_date: enrichment.observed_holiday_date }
                : {}),
        };
    });
}
export function normalizeAuthorizationCopays(value, authorizations = []) {
    if (!Array.isArray(value))
        throw new Error("authorization copays must be an array");
    return value.map((item, index) => {
        const row = asRecord(item, `authorizationCopays[${index}]`);
        const authorizationId = resolveAuthorizationId(row.idn_auth__c, authorizations, `authorizationCopays[${index}].idn_auth__c`);
        const amount = row.amt_copay_auth__c;
        if (typeof amount !== "number" || !Number.isFinite(amount) || amount < 0) {
            throw new Error(`authorizationCopays[${index}].amt_copay_auth__c must be non-negative`);
        }
        return {
            authorization_id: authorizationId,
            amount,
            effective_start: row.dte_begin_effv__c,
            effective_end: row.dte_end_effv__c,
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
            activity_paid: optionalFiniteNumber(detail.amt_act_paid__c, `payment detail[${index}].amt_act_paid__c`) ?? 0,
            registration_paid: optionalFiniteNumber(detail.amt_reg_paid__c, `payment detail[${index}].amt_reg_paid__c`) ?? 0,
            transportation_paid: optionalFiniteNumber(detail.amt_trans_paid__c, `payment detail[${index}].amt_trans_paid__c`) ?? 0,
            slot_paid: optionalFiniteNumber(detail.amt_slot_paid__c, `payment detail[${index}].amt_slot_paid__c`) ?? 0,
        };
        if (detail.cde_type_info_addntl__c !== undefined)
            normalized.info_code = detail.cde_type_info_addntl__c;
        const expectedHours = optionalNonNegativeNumber(detail.cnt_unit_care_exptd__c, `payment detail[${index}].cnt_unit_care_exptd__c`);
        const actualHours = optionalNonNegativeNumber(detail.cnt_unit_care_actual__c, `payment detail[${index}].cnt_unit_care_actual__c`);
        if (expectedHours !== undefined)
            normalized.expected_hours = expectedHours;
        if (actualHours !== undefined)
            normalized.actual_hours = actualHours;
        if (detail.ind_adjmt__c !== undefined)
            normalized.adjusted = detail.ind_adjmt__c === true;
        if (detail.ind_recovery__c !== undefined)
            normalized.recovery = detail.ind_recovery__c === true;
        if (detail.ind_record_delete_logcl__c !== undefined) {
            normalized.deleted = detail.ind_record_delete_logcl__c === true;
        }
        return normalized;
    });
}
export function normalizePaymentFeeSchedules(normalizedFiscalRates, normalizedFiscalRateFees, slotContracts, authorizationMatches) {
    const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
    const fees = requiredRecords(normalizedFiscalRateFees, "normalized fiscal rate fees");
    if (!Array.isArray(slotContracts))
        throw new Error("slot contracts must be an array");
    return slotContracts
        .filter((item) => {
        const slot = asRecord(item, "slot contract");
        return slot.IDN_AUTH__c !== null && slot.IDN_AUTH__c !== undefined;
    })
        .flatMap((item, index) => {
        const slot = asRecord(item, `slotContracts[${index}]`);
        const authorizationId = requiredString(slot.IDN_AUTH__c, `slotContracts[${index}].IDN_AUTH__c`);
        const fiscalScheduleId = authorizationMatches[authorizationId];
        if (!fiscalScheduleId)
            return [];
        const rateTypeCode = requiredString(slot.CDE_RATE_TYPE__c, `slotContracts[${index}].CDE_RATE_TYPE__c`);
        const careUnitCode = requiredString(slot.CDE_CARE_UNIT__c, `slotContracts[${index}].CDE_CARE_UNIT__c`);
        const careLevelCode = requiredString(slot.CDE_CARE_LEVEL__c, `slotContracts[${index}].CDE_CARE_LEVEL__c`);
        const matchingRates = rates.filter((rate) => rate.fiscalScheduleId === fiscalScheduleId
            && rate.rateTypeCode === rateTypeCode
            && rate.careUnitCode === careUnitCode
            && rate.ageGroupCode === careLevelCode);
        if (matchingRates.length !== 1)
            return [];
        const rate = matchingRates[0];
        if (!rate)
            return [];
        const matchingFees = fees.filter((fee) => fee.fiscalScheduleId === fiscalScheduleId);
        if (matchingFees.length > 1)
            throw new Error(`fiscal schedule ${fiscalScheduleId} has ambiguous fee rows`);
        const fee = matchingFees[0];
        const result = {
            authorization_id: authorizationId,
            fiscal_schedule_id: fiscalScheduleId,
            slot_contract_id: requiredString(slot.Id, `slotContracts[${index}].Id`),
            care_level: requiredString(slot.CDE_CARE_LEVEL__c, `slotContracts[${index}].CDE_CARE_LEVEL__c`),
            effective_start: requiredString(slot.DTE_BEGIN_SLOT__c, `slotContracts[${index}].DTE_BEGIN_SLOT__c`),
            slot_rate_amount: Number(rate.fiscalAgreementAmount),
        };
        const effectiveEnd = slot.DTE_END_SLOT__c;
        if (effectiveEnd !== undefined && effectiveEnd !== null) {
            result.effective_end = requiredString(effectiveEnd, `slotContracts[${index}].DTE_END_SLOT__c`);
        }
        const daysOfMonth = optionalNonNegativeNumber(slot.CNT_DAYS_OF_MONTH__c, `slotContracts[${index}].CNT_DAYS_OF_MONTH__c`);
        const daysOfWeek = slot.CNT_DAYS_OF_WEEK__c;
        if (daysOfMonth !== undefined)
            result.days_of_month = daysOfMonth;
        if (typeof daysOfWeek === "string" && daysOfWeek)
            result.days_of_week = daysOfWeek;
        else if (typeof daysOfWeek === "number" && Number.isFinite(daysOfWeek) && daysOfWeek >= 0)
            result.days_of_week = daysOfWeek;
        if (fee) {
            const amountFields = [
                ["activityFiscalAgreementAmount", "activity_amount"],
                ["registrationFiscalAgreementAmount", "registration_amount"],
                ["transportationFiscalAgreementAmount", "transportation_amount"],
            ];
            amountFields.forEach(([source, target]) => {
                if (fee[source] !== undefined)
                    result[target] = Number(fee[source]);
            });
            const scheduleFields = [
                ["activityFrequency", "activity_frequency"],
                ["activityMonths", "activity_months"],
                ["registrationFrequency", "registration_frequency"],
                ["registrationMonths", "registration_months"],
                ["transportationFrequency", "transportation_frequency"],
                ["transportationMonths", "transportation_months"],
            ];
            scheduleFields.forEach(([source, target]) => {
                if (fee[source] !== undefined)
                    result[target] = fee[source];
            });
        }
        return [result];
    });
}
function requiredRecords(value, label) {
    if (!Array.isArray(value) || value.length === 0) {
        throw new Error(`${label} must contain at least one record`);
    }
    return value.map((item, index) => asRecord(item, `${label}[${index}]`));
}
export function buildCanonicalPaymentPayload(input) {
    return {
        rule_version: "provider-risk-payment-v1",
        ...(input.mode
            ? { calculation_mode: input.mode === "FORECAST" ? "CURRENT_WEEK_FORECAST" : "STATUS" }
            : {}),
        service_period: normalizeServicePeriod(input.servicePeriod),
        authorizations: requiredRecords(input.authorizations, "authorizations"),
        attendance_days: normalizeAttendanceDays(input.schedules, input.attendanceEnrichmentByAuthorization, {
            ...(input.mode ? { mode: input.mode } : {}),
            ...(input.asOfDate ? { asOfDate: input.asOfDate } : {}),
        }),
        county_policies: requiredRecords(input.countyPolicies, "county policies"),
        fiscal_rates: requiredRecords(input.fiscalRates, "fiscal rates"),
        existing_sub_payments: normalizeExistingSubPayments(input.paymentHistory, input.authorizationRecords),
        ...(input.feeSchedules ? { fee_schedules: input.feeSchedules } : {}),
        ...(input.feeHistory ? { fee_history: input.feeHistory } : {}),
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
export function normalizeFiscalRatesForPayment(normalizedFiscalRates, authorizationMatches, authorizationAgeGroupCodes = {}, authorizationRateTypeCodes = {}) {
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
            const rateTypeCode = authorizationRateTypeCodes[authorizationId];
            const ageGroups = authorizationAgeGroupCodes[authorizationId];
            return (!rateTypeCode || rate.rateTypeCode === rateTypeCode)
                && (!ageGroups || rate.ageGroupCode === undefined
                    || ageGroups.includes(String(rate.ageGroupCode)));
        })
            .map((authorizationId) => ({
            authorization_id: authorizationId,
            paid_tier: paidTier,
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
