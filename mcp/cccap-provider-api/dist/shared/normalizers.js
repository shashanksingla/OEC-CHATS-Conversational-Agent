// Merged: provider-scope.ts + schedule-normalizer.ts + read-model-adapters.ts.
// All three are raw-Salesforce-shape -> canonical-shape normalization, called from the same
// consumers (payment-engine.ts, attendance.ts, server.ts). read-model-adapters.ts already
// imported schedule-normalizer.ts internally; provider-scope.ts had zero deps.
function record(value, label) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new Error(`${label} is unavailable`);
    }
    return value;
}
// ===== begin provider-scope.ts =====
export function normalizeQualityTier(providerQualityRating, _providerType) {
    if (providerQualityRating === "Level 1")
        return 1;
    if (providerQualityRating === "Level 2")
        return 2;
    if (providerQualityRating === "Level 3")
        return 3;
    if (providerQualityRating === "Level 4")
        return 4;
    if (providerQualityRating === "Level 5")
        return 5;
    throw new Error("provider quality tier is unavailable or unsupported");
}
export function normalizeProviderContext(value) {
    const initialization = record(value, "Provider context");
    const providers = initialization.providers;
    if (!Array.isArray(providers) || providers.length === 0) {
        throw new Error("Provider facility is unavailable");
    }
    const provider = record(providers[0], "Provider facility");
    const agreements = initialization.fiscalAgreements;
    if (!Array.isArray(agreements)) {
        throw new Error("Provider county agreements are unavailable");
    }
    const countyIds = [...new Set(agreements
            .map((value) => record(value, "Provider county agreement").CDE_COUNTY__c)
            .filter((value) => typeof value === "string" && value.length > 0))];
    if (countyIds.length === 0) {
        throw new Error("Provider county agreements are unavailable");
    }
    const countyIdByName = {};
    for (const value of agreements) {
        const agreement = record(value, "Provider county agreement");
        const countyId = agreement.CDE_COUNTY__c;
        const county = agreement.CDE_COUNTY__r;
        const countyName = county && typeof county === "object" && !Array.isArray(county)
            ? county.Name
            : undefined;
        if (typeof countyId === "string" && countyId && typeof countyName === "string" && countyName) {
            countyIdByName[countyName] = countyId;
        }
    }
    return {
        facilityName: typeof provider.NAM_FACILITY__c === "string" ? provider.NAM_FACILITY__c : undefined,
        qualityTier: normalizeQualityTier(provider.TXT_CHATS_RATING__c, provider.CDE_TYPE_PROVR__c),
        countyIds,
        countyIdByName,
    };
}
// ===== end provider-scope.ts =====
// ===== begin schedule-normalizer.ts =====
function asRecord(value) {
    return value && typeof value === "object" && !Array.isArray(value)
        ? value
        : undefined;
}
function transactionType(recordType, sourceType) {
    if (typeof sourceType === "number" && Number.isFinite(sourceType))
        return sourceType;
    if (typeof sourceType === "string" && /^\d+$/.test(sourceType))
        return Number(sourceType);
    if (recordType === "Check-In")
        return 1;
    if (recordType === "Check-Out")
        return 2;
    return undefined;
}
function confirmationStatus(value) {
    if (typeof value !== "string")
        return undefined;
    const normalized = value.trim().toUpperCase();
    return normalized || undefined;
}
function directParentConfirmation(value) {
    const normalized = confirmationStatus(value);
    if (!normalized)
        return undefined;
    if (["CONFIRMED", "APPROVED", "PARENT_APPROVED", "COMPLETE"].includes(normalized))
        return "CONFIRMED";
    if (["PENDING", "PARENT_PENDING", "UNCONFIRMED"].includes(normalized))
        return "PENDING";
    if (["REJECTED", "PARENT_REJECTED", "DENIED"].includes(normalized))
        return "REJECTED";
    return undefined;
}
function booleanValue(value) {
    if (typeof value === "boolean")
        return value;
    if (typeof value === "string")
        return value.trim().toLowerCase() === "true";
    return Boolean(value);
}
function authorizationStatus(value) {
    const normalized = String(value ?? "").trim().toUpperCase();
    if (normalized === "2" || normalized === "AUTHORIZED")
        return "APPROVED";
    if (normalized === "4" || normalized === "TERMINATED")
        return "TERMINATED";
    return undefined;
}
function nestedCountyName(schedule) {
    const authorization = asRecord(schedule.Authorization__r);
    const county = asRecord(authorization?.County__r);
    const countyName = county?.County_Name__c;
    return typeof countyName === "string" && countyName ? countyName : undefined;
}
export function normalizeScheduleAttendance(schedules, defaultCountyId, providerQualityTier, authorizationData) {
    const transactions = [];
    const normalizedSchedules = [];
    const authorizationLimits = new Map();
    const authorizationResponse = asRecord(authorizationData);
    const authorizationRows = Array.isArray(authorizationResponse?.authorizations)
        ? authorizationResponse.authorizations
        : Array.isArray(authorizationResponse?.normalizedAuthorizations)
            ? authorizationResponse.normalizedAuthorizations
            : [];
    for (const value of authorizationRows) {
        const authorization = asRecord(value);
        const id = authorization?.Id ?? authorization?.IDN_EXTNL__c;
        const limit = authorization?.Number_of_Drop_in_Days__c;
        if ((typeof id === "string" || typeof id === "number") && typeof limit === "number" && limit >= 0) {
            authorizationLimits.set(String(id), limit);
        }
    }
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
            transaction_id: record.CI_Transaction_ID__c ?? record.Id,
            reporting_authorization_id: record.Reporting_Authorization_Id__c,
            schedule_id: record.Schedule__c ?? scheduleId,
            authorization_id: record.Reporting_Authorization_Id__c ?? schedule.CI_Authorization_Id__c,
            client_id: record.CI_Client_Id__c,
            work_date: record.CI_Attendance_Date__c ?? record.CI_Begin_Date__c ?? workDate,
            begin_date: record.CI_Begin_Date__c,
            end_date: record.CI_End_Date__c,
            transaction_time: record.CI_Transaction_Time__c,
            attended_hours: record.CI_Attendance_Hours__c,
            type: transactionType(record.Record_Type_Name__c, record.CI_Transaction_Type__c),
            result: record.CI_Transaction_Result__c,
            status: confirmationStatus(record.Status__c),
            sub_type: record.Sub_Type__c,
            denial_reason: record.Denial_Status__c,
            is_historical: booleanValue(record.Previous_Transaction__c),
            provider_id: record.CI_Provider_ID__c,
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
        const scheduleParentConfirmation = directParentConfirmation(schedule.parent_confirmation
            ?? schedule.parentConfirmation
            ?? schedule.Parent_Confirmation__c
            ?? schedule.Parent_Confirmation_Status__c
            ?? schedule.parent_confirmation_status);
        if (scheduleParentConfirmation) {
            parentStatuses.add(scheduleParentConfirmation === "CONFIRMED"
                ? "PARENT_APPROVED"
                : `PARENT_${scheduleParentConfirmation}`);
        }
        const authorization = asRecord(schedule.Authorization__r);
        const authorizationReference = schedule.CI_Authorization_Id__c
            ?? schedule.Authorization__c
            ?? schedule.IDN_AUTH__c
            ?? schedule.Authorization_Id__c
            ?? authorization?.Id;
        const authorizationRecord = authorizationRows.find((value) => {
            const wrapper = asRecord(value);
            const candidate = asRecord(wrapper?.authorization) ?? wrapper;
            const candidateReferences = [candidate?.Id, candidate?.IDN_EXTNL__c, candidate?.Name]
                .filter((reference) => (typeof reference === "string" && reference.length > 0) || typeof reference === "number")
                .map(String);
            const scheduleReferences = [authorizationReference, schedule.CI_Authorization_Id__c]
                .filter((reference) => (typeof reference === "string" && reference.length > 0) || typeof reference === "number")
                .map(String);
            return scheduleReferences.some((reference) => candidateReferences.includes(reference));
        });
        const authorizationWrapper = authorizationRecord ? asRecord(authorizationRecord) : undefined;
        const matchedAuthorization = asRecord(authorizationWrapper?.authorization) ?? authorizationWrapper;
        const authorizationId = matchedAuthorization?.Id ?? authorizationReference;
        const authorizationStatusValue = matchedAuthorization && (matchedAuthorization.Authorization_Status__c
            ?? matchedAuthorization.authorization_status
            ?? matchedAuthorization.expr0);
        const normalizedSchedule = {
            schedule_id: scheduleId,
            authorization_id: authorizationId,
            authorization_name: matchedAuthorization?.Name ??
                authorization?.Name ??
                schedule.authorization_name ??
                schedule.Authorization_Name__c,
            child_name: schedule.Contact_Name__c,
            county_id: schedule.County__c
                ?? schedule.county_id
                ?? matchedAuthorization?.CDE_COUNTY__c
                ?? defaultCountyId,
            county_name: nestedCountyName(schedule),
            authorization_drop_in_limit: authorizationLimits.get(String(schedule.Authorization__c ??
                schedule.IDN_AUTH__c ??
                schedule.Authorization_Id__c ??
                authorization?.Id ?? "")),
            quality_tier: providerQualityTier,
            rate_type_code: schedule.CI_Authorization_Rate_Type__c,
            work_date: workDate,
            // Type__c describes authorization status; Schedule_Type__c describes the care unit.
            authorization_type: schedule.Type__c ?? schedule.authorization_type,
            schedule_type: schedule.Schedule_Type__c ?? schedule.schedule_type,
            is_deleted: false,
            denial_reason: undefined,
            auth_status: authorizationStatus(authorizationStatusValue),
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
            normalizedSchedule.absence_parent_approved = booleanValue(schedule.absence_parent_approved
                ?? schedule.absenceParentApproved
                ?? schedule.Absence_Parent_Approved__c);
        }
        else if (parentStatuses.has("PARENT_APPROVED")) {
            normalizedSchedule.parent_confirmation = "CONFIRMED";
            normalizedSchedule.absence_parent_approved = true;
        }
        else if (parentStatuses.has("PARENT_REJECTED")) {
            normalizedSchedule.parent_confirmation = "REJECTED";
            normalizedSchedule.absence_parent_approved = false;
        }
        normalizedSchedules.push(normalizedSchedule);
    }
    return { schedules: normalizedSchedules, transactions };
}
// ===== end schedule-normalizer.ts =====
// ===== begin read-model-adapters.ts =====
function records(value, label) {
    if (value === undefined || value === null)
        return [];
    if (!Array.isArray(value))
        throw new Error(`${label} is unavailable`);
    return value.map((item, index) => record(item, `${label}[${index}]`));
}
function relationshipRecords(value) {
    if (!value || typeof value !== "object" || Array.isArray(value))
        return [];
    const related = value.records;
    return Array.isArray(related) ? related : [];
}
function optionalString(value) {
    return typeof value === "string" && value.length > 0 ? value : undefined;
}
function date(value, label) {
    const result = optionalString(value);
    if (!result)
        throw new Error(`${label} is unavailable`);
    return result;
}
export function normalizeProviderInitialization(value) {
    const source = record(value, "Provider initialization");
    const providers = records(source.providers, "Provider facilities").map((provider) => ({
        id: optionalString(provider.Id),
        external_name: optionalString(provider.Name),
        facility_name: optionalString(provider.NAM_FACILITY__c),
        quality_rating: optionalString(provider.TXT_CHATS_RATING__c),
        provider_type: optionalString(provider.CDE_TYPE_PROVR__c),
    }));
    const fiscalAgreements = records(source.fiscalAgreements, "Fiscal agreements").map((agreement) => ({
        county_id: optionalString(agreement.CDE_COUNTY__c),
        county_name: optionalString((agreement.CDE_COUNTY__r && typeof agreement.CDE_COUNTY__r === "object" && !Array.isArray(agreement.CDE_COUNTY__r))
            ? agreement.CDE_COUNTY__r.Name
            : undefined),
        rate_schedules: records(relationshipRecords(agreement.Rate_Schedules__r), "Rate schedules")
            .map((schedule) => ({
            id: optionalString(schedule.Id),
            external_id: optionalString(schedule.IDN_EXTNL__c),
            rate_type_code: optionalString(schedule.CDE_RATE_TYPE__c),
            effective_start: optionalString(schedule.DTE_BEGIN_EFFV__c),
            effective_end: optionalString(schedule.DTE_END_EFFV__c),
        })),
    }));
    return { providers, fiscal_agreements: fiscalAgreements };
}
export function normalizeCases(value) {
    const source = record(value, "Cases");
    return {
        cases: records(source.cases, "Cases").map((item) => ({
            id: optionalString(item.Id),
            name: optionalString(item.Name),
            county_id: optionalString(item.CDE_COUNTY__c),
            external_id: optionalString(item.IDN_EXTNL__c),
            children: records(relationshipRecords(item.CaseIndividuals__r), "Case individuals")
                .map((child) => ({
                id: optionalString(child.Id),
                client_id: optionalString(child.IDN_CLNT__c),
                name: optionalString(child.Name),
                effective_start: optionalString(child.DTE_BEGIN_EFFV__c),
                effective_end: optionalString(child.DTE_END_EFFV__c),
                status: optionalString(child.Status__c),
            })),
        })),
    };
}
export function normalizeAuthorizations(value) {
    const source = record(value, "Authorizations");
    return {
        authorizations: records(source.authorizations, "Authorizations").map((item) => ({
            id: optionalString(item.Id),
            external_id: optionalString(item.IDN_EXTNL__c),
            name: optionalString(item.Name),
            county_id: optionalString(item.CDE_COUNTY__c),
            case_id: optionalString(item.IDN_CASE__c),
            status: optionalString(item.Status__c),
            effective_start: optionalString(item.DTE_BEGIN_EFFV_AUTH__c),
            effective_end: optionalString(item.DTE_END_EFFV_AUTH__c),
        })),
        slot_contracts: records(source.slotContracts, "Slot contracts").map((item) => ({
            id: optionalString(item.Id),
            authorization_id: optionalString(item.IDN_AUTH__c),
            rate_type_code: optionalString(item.CDE_RATE_TYPE__c),
            care_unit_code: optionalString(item.CDE_CARE_UNIT__c),
            care_level: optionalString(item.CDE_CARE_LEVEL__c),
            effective_start: optionalString(item.DTE_BEGIN_SLOT__c),
            effective_end: optionalString(item.DTE_END_SLOT__c),
            occupied: item.IDN_AUTH__c !== null && item.IDN_AUTH__c !== undefined,
        })),
    };
}
export function normalizeSchedules(value) {
    const source = record(value, "Schedules");
    const normalized = normalizeScheduleAttendance(records(source.schedules, "Schedules"));
    return {
        schedules: normalized.schedules,
        transactions: normalized.transactions,
    };
}
export function normalizeFiscalRates(value) {
    const source = record(value, "Fiscal rates");
    const normalized = record(source.normalizedFiscalRates, "Normalized fiscal rates");
    return {
        fiscal_rates: records(normalized.fiscalRates, "Fiscal rates"),
        fee_schedules: records(normalized.fiscalRateFees, "Fiscal rate fees"),
        mapping_status: normalized.canonicalMappingStatus,
        unresolved_mappings: normalized.unresolvedMappings ?? [],
    };
}
export function normalizeCountyPlans(value) {
    const source = record(value, "County plans");
    return {
        county_plans: records(source.countyRatePlans, "County plans").map((item) => ({
            county_id: optionalString(item.countyId),
            county_name: optionalString(item.countyName),
            effective_start: optionalString(item.effectiveBeginDate),
            absence_days_by_tier: Object.fromEntries([1, 2, 3, 4, 5].map((tier) => [
                String(tier), item[`absenceDaysTier${tier}`],
            ])),
            allow_paid_holidays: item["allowPaidHolidays?"],
            allow_drop_in_days: item.allowDropInDays,
            max_drop_in_days_per_month: item.maxDropInDaysPerMonth,
        })),
    };
}
export function normalizeServicePeriods(value) {
    const source = record(value, "Service periods");
    return {
        service_periods: records(source.servicePeriods, "Service periods").map((item) => ({
            id: optionalString(item.servicePeriodId),
            start: date(item.serviceBeginDate, "Service period start"),
            end: date(item.serviceEndDate, "Service period end"),
            payment_date: optionalString(item.paymentDate),
            release_date: optionalString(item.releaseDate),
        })),
    };
}
export function normalizeHolidays(value) {
    const source = record(value, "Holidays");
    return {
        holidays: records(source.holidayList, "Holiday list").map((item) => ({
            code: optionalString(item.CDE_HOL__c),
            date: optionalString(item.DTE_HOL__c),
            observed_date: optionalString(item.DTE_OBSERVED_HOL__c),
        })),
    };
}
export function normalizePaymentHistory(value) {
    const source = record(value, "Payment history");
    return {
        sub_payments: records(source.subPayments, "Sub-payments").map((item) => ({
            id: optionalString(item.idn_pmt_sub__c),
            authorization_id: optionalString(item.idn_auth__c),
            service_period_id: optionalString(item.idn_period_serv__c),
            status: optionalString(item.cde_status_pmt_sub__c),
            amount: item.amt_pmt_sub__c,
        })),
    };
}
// ===== end read-model-adapters.ts =====
