import { normalizePaymentStatus } from "./attendance-snapshot.js";
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
export function normalizeServicePeriod(value) {
    const period = asRecord(value, "service period");
    return {
        id: requiredString(period.servicePeriodId ?? period.id, "service period id"),
        start_date: requiredString(period.serviceBeginDate ?? period.start_date, "service period start date"),
        end_date: requiredString(period.serviceEndDate ?? period.end_date, "service period end date"),
    };
}
export function normalizeExistingSubPayments(value) {
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
            authorization_id: requiredString(row.idn_auth__c, `subPayments[${index}].idn_auth__c`),
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
export function deriveAttendanceEnrichment(schedules, authorizationData, holidayData) {
    const response = asRecord(authorizationData, "authorization enrichment");
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
        const matchingEncumbrances = encumbrances.filter((candidate) => {
            const row = asRecord(candidate, "authorization encumbrance");
            return row.idn_auth__c === authorizationId && dateMatches(row.dte_care__c, serviceDate);
        });
        const ageFlags = new Set(matchingEncumbrances
            .map((candidate) => asRecord(candidate, "authorization encumbrance").ind_0_36_months__c)
            .filter((flag) => typeof flag === "boolean"));
        if (ageFlags.size !== 1) {
            throw new Error(`age-band enrichment is ambiguous for ${authorizationId} on ${serviceDate}`);
        }
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
            return row.IDN_AUTH__c === authorizationId
                && (!begins || String(begins).slice(0, 10) <= serviceDate)
                && (!ends || String(ends).slice(0, 10) >= serviceDate);
        });
        const occupiedFlags = new Set(matchingSlots
            .map((candidate) => optionalBoolean(asRecord(candidate, "slot contract").IND_OCCUPIED__c))
            .filter((flag) => flag !== undefined));
        if (occupiedFlags.size !== 1) {
            throw new Error(`slot occupancy enrichment is ambiguous for ${authorizationId} on ${serviceDate}`);
        }
        const matchingHoliday = holidays.find((candidate) => {
            const holiday = asRecord(candidate, "holiday");
            return dateMatches(holiday.DTE_HOL__c, serviceDate)
                || dateMatches(holiday.DTE_OBSERVED_HOL__c, serviceDate);
        });
        const holiday = matchingHoliday ? asRecord(matchingHoliday, "holiday") : undefined;
        result[authorizationId] = {
            age_band: ageFlags.has(true) ? "ZERO_TO_36_MONTHS" : "OVER_36_MONTHS",
            slot_contract_present: matchingSlots.length > 0,
            occupied_slot_contract: occupiedFlags.has(true),
            care_not_offered: encumbranceStatuses.has("CARE_NOT_OFFERED")
                || requiredBoolean(schedule.care_not_offered, `schedules[${index}].care_not_offered`),
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
export function normalizeAttendanceDays(schedules, enrichmentByAuthorization) {
    return schedules.map((value, index) => {
        const schedule = asRecord(value, `schedules[${index}]`);
        const authorizationId = requiredString(schedule.authorization_id, `schedules[${index}].authorization_id`);
        const enrichment = enrichmentByAuthorization[authorizationId];
        if (!enrichment)
            throw new Error(`attendance enrichment is missing for ${authorizationId}`);
        const parentConfirmation = schedule.parent_confirmation;
        if (parentConfirmation !== "CONFIRMED" && parentConfirmation !== "PENDING") {
            throw new Error(`schedules[${index}].parent_confirmation is required`);
        }
        const ageBand = enrichment.age_band;
        if (ageBand !== "ZERO_TO_36_MONTHS" && ageBand !== "OVER_36_MONTHS") {
            throw new Error(`attendance enrichment age_band is required for ${authorizationId}`);
        }
        return {
            authorization_id: authorizationId,
            service_date: requiredString(schedule.work_date, `schedules[${index}].work_date`),
            authorized_hours: requiredNonNegativeNumber(schedule.ci_authorization_hours, `schedules[${index}].ci_authorization_hours`),
            attended_hours: requiredNonNegativeNumber(schedule.raw_hours, `schedules[${index}].raw_hours`),
            parent_confirmation: parentConfirmation,
            absence_parent_approved: requiredBoolean(schedule.absence_parent_approved, `schedules[${index}].absence_parent_approved`),
            age_band: ageBand,
            slot_contract_present: requiredBoolean(enrichment.slot_contract_present ?? enrichment.occupied_slot_contract, `attendance enrichment slot_contract_present for ${authorizationId}`),
            occupied_slot_contract: requiredBoolean(enrichment.occupied_slot_contract, `attendance enrichment occupied_slot_contract for ${authorizationId}`),
            care_not_offered: requiredBoolean(enrichment.care_not_offered, `attendance enrichment care_not_offered for ${authorizationId}`),
            observed_holiday: requiredBoolean(enrichment.observed_holiday, `attendance enrichment observed_holiday for ${authorizationId}`),
            ...(typeof enrichment.holiday_name === "string" ? { holiday_name: enrichment.holiday_name } : {}),
            ...(typeof enrichment.holiday_date === "string" ? { holiday_date: enrichment.holiday_date } : {}),
            ...(typeof enrichment.observed_holiday_date === "string"
                ? { observed_holiday_date: enrichment.observed_holiday_date }
                : {}),
        };
    });
}
export function normalizeAuthorizationCopays(value) {
    if (!Array.isArray(value))
        throw new Error("authorization copays must be an array");
    return value.map((item, index) => {
        const row = asRecord(item, `authorizationCopays[${index}]`);
        const authorizationId = requiredString(row.idn_auth__c, `authorizationCopays[${index}].idn_auth__c`);
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
export function normalizePaymentFeeHistory(value) {
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
            authorization_id: requiredString(subPayment?.idn_auth__c, `payment detail[${index}].authorization_id`),
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
    return slotContracts.map((item, index) => {
        const slot = asRecord(item, `slotContracts[${index}]`);
        const authorizationId = requiredString(slot.IDN_AUTH__c, `slotContracts[${index}].IDN_AUTH__c`);
        const fiscalScheduleId = authorizationMatches[authorizationId];
        if (!fiscalScheduleId)
            throw new Error(`slot contract ${authorizationId} cannot be joined to a fiscal schedule`);
        const rateTypeCode = requiredString(slot.CDE_RATE_TYPE__c, `slotContracts[${index}].CDE_RATE_TYPE__c`);
        const careUnitCode = requiredString(slot.CDE_CARE_UNIT__c, `slotContracts[${index}].CDE_CARE_UNIT__c`);
        const matchingRates = rates.filter((rate) => rate.fiscalScheduleId === fiscalScheduleId
            && rate.rateTypeCode === rateTypeCode
            && rate.careUnitCode === careUnitCode);
        if (matchingRates.length !== 1)
            throw new Error(`slot contract ${authorizationId} has an ambiguous fiscal rate`);
        const rate = matchingRates[0];
        if (!rate)
            throw new Error(`slot contract ${authorizationId} has no fiscal rate`);
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
            slot_rate_amount: Number(rate.providerAmount),
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
                ["activityProviderAmount", "activity_amount"],
                ["registrationProviderAmount", "registration_amount"],
                ["transportationProviderAmount", "transportation_amount"],
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
        return result;
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
        service_period: normalizeServicePeriod(input.servicePeriod),
        authorizations: requiredRecords(input.authorizations, "authorizations"),
        attendance_days: normalizeAttendanceDays(input.schedules, input.attendanceEnrichmentByAuthorization),
        county_policies: requiredRecords(input.countyPolicies, "county policies"),
        fiscal_rates: requiredRecords(input.fiscalRates, "fiscal rates"),
        existing_sub_payments: normalizeExistingSubPayments(input.paymentHistory),
        ...(input.feeSchedules ? { fee_schedules: input.feeSchedules } : {}),
        ...(input.feeHistory ? { fee_history: input.feeHistory } : {}),
    };
}
export function normalizeQualityTier(providerQualityRating, providerType) {
    if (providerType === "EXE")
        return 1;
    if (providerQualityRating === "Level 1")
        return 2;
    if (providerQualityRating === "Level 2")
        return 3;
    if (providerQualityRating === "Level 3")
        return 4;
    if (providerQualityRating === "Level 4")
        return 5;
    if (providerQualityRating === "Level 5")
        return 6;
    throw new Error("provider quality tier is unavailable or unsupported");
}
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
export function normalizeFiscalRatesForPayment(normalizedFiscalRates, authorizationMatches) {
    const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
    return rates.map((rate, index) => {
        const scheduleId = requiredString(rate.fiscalScheduleId, `normalized fiscal rates[${index}].fiscalScheduleId`);
        const authorizationId = Object.entries(authorizationMatches)
            .find(([, matchedScheduleId]) => matchedScheduleId === scheduleId)?.[0];
        const paidTier = rate.paidTier;
        if (!authorizationId || typeof paidTier !== "string") {
            throw new Error(`fiscal rate ${scheduleId} cannot be joined to an authorization and paid tier`);
        }
        return {
            authorization_id: authorizationId,
            paid_tier: paidTier,
            amount: Number(rate.providerAmount),
            source_id: rate.sourceId,
        };
    });
}
