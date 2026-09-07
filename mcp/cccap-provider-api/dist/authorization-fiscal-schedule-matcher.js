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
function containsDate(beginDate, endDate, date) {
    return beginDate <= date && (endDate === undefined || endDate >= date);
}
export function selectFiscalScheduleForAuthorization(authorizationValue, slotContractsValue, schedules, careDate) {
    const authorization = record(authorizationValue, "authorization");
    const authorizationId = requiredString(authorization.Id, "authorization.Id");
    const countyId = requiredString(authorization.CDE_COUNTY__c, "authorization.CDE_COUNTY__c");
    const authorizationBegin = requiredString(authorization.DTE_BEGIN_EFFV_AUTH__c, "authorization.DTE_BEGIN_EFFV_AUTH__c");
    const authorizationEnd = typeof authorization.DTE_END_EFFV_AUTH__c === "string"
        ? authorization.DTE_END_EFFV_AUTH__c
        : undefined;
    if (!containsDate(authorizationBegin, authorizationEnd, careDate)) {
        return { status: "UNRESOLVED", reason: "NO_MATCH" };
    }
    if (!Array.isArray(slotContractsValue)) {
        throw new Error("slotContracts must be an array");
    }
    const slotContracts = slotContractsValue
        .map((value, index) => record(value, `slotContracts[${index}]`))
        .filter((slotContract) => slotContract.IDN_AUTH__c === authorizationId);
    const rateTypes = new Set(slotContracts
        .map((slotContract) => slotContract.CDE_RATE_TYPE__c)
        .filter((value) => typeof value === "string" && value.length > 0));
    if (rateTypes.size !== 1) {
        return { status: "UNRESOLVED", reason: "MISSING_SLOT_CONTRACT_RATE_TYPE" };
    }
    const matches = schedules.filter((schedule) => schedule.countyId === countyId
        && schedule.rateTypeCode === [...rateTypes][0]
        && containsDate(schedule.beginDate, schedule.endDate, careDate));
    if (matches.length === 0)
        return { status: "UNRESOLVED", reason: "NO_MATCH" };
    const firstMatch = matches[0];
    if (!firstMatch)
        return { status: "UNRESOLVED", reason: "NO_MATCH" };
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
