import { normalizeScheduleAttendance } from "./schedule-normalizer.js";
function record(value, label) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new Error(`${label} is unavailable`);
    }
    return value;
}
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
