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
