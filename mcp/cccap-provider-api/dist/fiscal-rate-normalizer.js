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
function record(value, label) {
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
