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
function containsRateType(scheduleRateTypes, requestedRateType) {
    return scheduleRateTypes
        .split(/[,;|\s]+/)
        .map((value) => value.trim())
        .filter((value) => value.length > 0)
        .includes(requestedRateType);
}
export function selectFiscalScheduleForAuthorization(authorizationValue, schedules, careDate, scheduleRateType) {
    const authorization = record(authorizationValue, "authorization");
    const countyId = requiredString(authorization.CDE_COUNTY__c, "authorization.CDE_COUNTY__c");
    const authorizationBegin = requiredString(authorization.DTE_BEGIN_EFFV_AUTH__c, "authorization.DTE_BEGIN_EFFV_AUTH__c");
    const authorizationEnd = typeof authorization.DTE_END_EFFV_AUTH__c === "string"
        ? authorization.DTE_END_EFFV_AUTH__c
        : undefined;
    if (!containsDate(authorizationBegin, authorizationEnd, careDate)) {
        return { status: "UNRESOLVED", reason: "NO_MATCH" };
    }
    if (!scheduleRateType) {
        return { status: "UNRESOLVED", reason: "MISSING_SCHEDULE_RATE_TYPE" };
    }
    const matches = schedules.filter((schedule) => schedule.countyId === countyId
        && containsRateType(schedule.rateTypeCode, scheduleRateType)
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
    return { status: "MATCHED", fiscalScheduleId: selectedMatch.id };
}
