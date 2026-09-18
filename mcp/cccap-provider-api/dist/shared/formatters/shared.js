// Merged: formatters/shared.ts + view-state.ts (view-state.ts is exclusively consumed by
// attendance-formatter.ts and payment-formatter.ts, never by server.ts directly).
export const readOnlyAnnotations = {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: true,
};
export const MAX_DISPLAY_CHILDREN = 10;
export const MAX_SUMMARY_ROWS = 7;
export const DISCLAIMER_GLOBAL = "⚠️ *Figures reflect the system's current data and are not an official payment notice. " +
    "Actual payments are subject to state and county verification, review, and may differ from these calculated estimates.*";
export const DISCLAIMER_EXPECTED = "*Expected, based on current system data — may still change if the county issues a correction.*";
export const DISCLAIMER_FORECASTED = "*Forecasted from scheduled and partial attendance data — may change as the period completes.*";
export const DISCLAIMER_AT_RISK = "*Could be reduced or excluded if unresolved before {deadline}.*";
export const DISCLAIMER_GUARANTEED = "*Paid per your county contract regardless of occupancy or attendance.*";
export function result(data) {
    const structuredContent = data && typeof data === "object" && !Array.isArray(data)
        ? data
        : undefined;
    return {
        content: [{ type: "text", text: JSON.stringify(data) }],
        ...(structuredContent ? { structuredContent } : {}),
    };
}
export function compactActionControls(actions) {
    return actionControls(actions).map((action) => {
        const input = recordValue(action.input);
        return {
            ...action,
            ...(input ? {
                input: Object.fromEntries(Object.entries(input).filter(([key]) => key !== "childNames")),
            } : {}),
        };
    });
}
export function recordValue(value) {
    return value && typeof value === "object" && !Array.isArray(value)
        ? value
        : undefined;
}
export function tableValue(value) {
    if (typeof value === "string" && value.trim()) {
        const normalized = value.replace(/[\r\n|]/g, " ").trim();
        return isSalesforceRecordId(normalized)
            ? "Unavailable from the current source"
            : normalized;
    }
    if (typeof value === "number") {
        return String(value);
    }
    return "Unavailable from the current source";
}
export const ATTENDANCE_TYPE_LABELS = {
    ATTENDED: "Attended",
    ABSENCE: "Absence (paid)",
    ENROLLMENT_ABSENCE: "Enrollment absence",
    HOLIDAY: "Holiday",
    DROP_IN: "Drop-in",
    SCHEDULED_FORECAST: "Scheduled (forecast)",
    CARE_NOT_OFFERED: "Care not offered",
    NO_CARE: "No care scheduled",
    BLOCKED: "Unavailable from the current source",
    PENDING_CONFIRMATION: "Pending parent confirmation",
    INCOMPLETE_ATTENDANCE_RECORD: "Missing check-in/check-out",
    VACANT_SLOT: "Vacant slot",
};
export function humanizeAttendanceType(value) {
    if (typeof value !== "string")
        return "Unavailable from the current source";
    return ATTENDANCE_TYPE_LABELS[value] ?? tableValue(value);
}
function moneyDisplay(value) {
    if (typeof value === "number" && !Number.isFinite(value))
        return "Unavailable from the current source";
    if (typeof value === "string" && (value.trim() === "" || !Number.isFinite(Number(value)))) {
        return "Unavailable from the current source";
    }
    const numeric = typeof value === "number"
        ? value
        : typeof value === "string"
            ? Number(value)
            : undefined;
    return numeric === undefined ? tableValue(value) : numeric.toFixed(2);
}
export function estimatedMoney(value, isUncertain = true) {
    const display = moneyDisplay(value);
    if (display === "Unavailable from the current source")
        return display;
    const withDollarSign = "$" + display;
    return isUncertain ? "~ " + withDollarSign : withDollarSign;
}
export function plainMoney(value) {
    const display = moneyDisplay(value);
    return display === "Unavailable from the current source" ? display : `$${display}`;
}
export const PAYMENT_AMOUNT_LEGEND = [
    "> Net payment: the current estimate excluding unresolved risk.",
    "> Scheduled forecast: the projected amount for future scheduled days that have not yet occurred.",
    "> Conditional at-risk: the amount that may be added or lost when attendance issues are resolved.",
    "> Maximum estimated payout = net payment + scheduled forecast + conditional at-risk.",
    "> Vacant-slot payments are included once in net payment when applicable.",
].join("\n");
export function isSalesforceRecordId(value) {
    return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
}
export function numericValue(value) {
    return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
function ordinalSuffix(day) {
    if (day % 100 >= 11 && day % 100 <= 13)
        return "th";
    switch (day % 10) {
        case 1: return "st";
        case 2: return "nd";
        case 3: return "rd";
        default: return "th";
    }
}
export function shortDateLabel(value) {
    if (typeof value !== "string")
        return undefined;
    const datePart = value.trim().match(/^\d{4}-\d{2}-\d{2}/)?.[0];
    if (!datePart)
        return undefined;
    const parsed = new Date(`${datePart}T00:00:00Z`);
    if (Number.isNaN(parsed.getTime()))
        return undefined;
    const day = parsed.getUTCDate();
    const month = parsed.toLocaleDateString("en-US", { month: "short", timeZone: "UTC" });
    const year = String(parsed.getUTCFullYear()).slice(-2);
    return `${day}${ordinalSuffix(day)} ${month}'${year}`;
}
export function overLimitDays(absenceDays, absenceLimit) {
    const days = numericValue(absenceDays);
    const limit = typeof absenceLimit === "number" ? absenceLimit : undefined;
    if (limit === undefined)
        return "—";
    return String(Math.max(0, days - limit));
}
export function attendanceScopeLabel(scope) {
    const dateFilter = recordValue(scope)?.dateFilter;
    if (dateFilter === "LAST_MONTH")
        return "Last-month";
    if (dateFilter === "THIS_MONTH")
        return "Current-month";
    if (dateFilter === "DATE_RANGE")
        return "Date-range";
    if (dateFilter === "TODAY")
        return "Today";
    return "Attendance-risk";
}
export function hasAbsenceLimitConcern(child) {
    return Array.isArray(child.risk_codes) && child.risk_codes.some((code) => code === "ABSENCE_LIMIT_EXCEEDED"
        || code === "ABSENCE_LIMIT_APPROACHING"
        || code === "ABSENCE_LIMIT_UNAVAILABLE"
        || code === "ABSENCE_LIMIT_CONFLICT");
}
const MAX_NEXT_ACTIONS = 2;
function targetSignature(action) {
    if (typeof action.targetViewId !== "string")
        return undefined;
    const input = action.input && typeof action.input === "object" && !Array.isArray(action.input)
        ? action.input
        : {};
    const scopeKeys = ["childNames", "riskFocus", "countyNames", "authNames", "view"];
    return JSON.stringify([action.targetViewId, ...scopeKeys.map((key) => input[key])]);
}
export function orderedActionList(actions) {
    const uniqueActions = [...new Map(actions.map((action) => [String(action.actionId), action])).values()];
    const seenTargets = new Set();
    const deduplicatedActions = uniqueActions.filter((action) => {
        const signature = targetSignature(action);
        if (signature === undefined)
            return true;
        if (seenTargets.has(signature))
            return false;
        seenTargets.add(signature);
        return true;
    });
    const nextActions = deduplicatedActions
        .filter((action) => action.section === "next-actions")
        .sort((left, right) => (typeof right.priority === "number" ? right.priority : -Infinity) - (typeof left.priority === "number" ? left.priority : -Infinity))
        .slice(0, MAX_NEXT_ACTIONS);
    const drillDown = uniqueActions.filter((action) => action.section === "drill-down");
    const availableViews = uniqueActions.filter((action) => action.section === "available-options" || action.section === "available-views");
    const returnActions = uniqueActions.filter((action) => action.section === "return");
    return [...nextActions, ...drillDown, ...availableViews, ...returnActions];
}
export function actionControls(actions) {
    return orderedActionList(actions).map((action) => ({
        type: "button",
        actionId: action.actionId,
        label: action.label,
        ...(action.reason ? { reason: action.reason } : {}),
        ...(action.priority ? { priority: action.priority } : {}),
        ...(action.source ? { source: action.source } : {}),
        section: action.section,
        capability: action.capability,
        ...(action.tool ? { tool: action.tool } : {}),
        ...(action.input ? { input: action.input } : {}),
        ...(action.scope ? { scope: action.scope } : {}),
        ...(action.riskFocus ? { riskFocus: action.riskFocus } : {}),
        ...(action.view ? { view: action.view } : {}),
    }));
}
export function renderActionSections(message, actions) {
    const base = message
        .replace(/\n\*\*Priority Actions\*\*[\s\S]*$/, "")
        .replace(/\n\*\*Recommended actions\*\*[\s\S]*$/, "");
    const combined = orderedActionList(actions);
    const lines = [base, "", "**Recommended actions**"];
    lines.push(...(combined.length > 0
        ? combined.map((action, index) => `${index + 1}. ${String(action.label)}`)
        : ["No urgent action identified from the current verified result. Ask about the specific child, county, date, or payment detail you want reviewed next."]));
    return lines.join("\n");
}
function riskFocusLabel(riskFocus) {
    if (riskFocus === "ABSENCE_LIMITS")
        return "absence-limit risk";
    if (riskFocus === "PARENT_CONFIRMATIONS")
        return "pending parent confirmations";
    if (riskFocus === "INCOMPLETE_ATTENDANCE")
        return "incomplete attendance records";
    return "this risk area";
}
export function formatScopeClarification(riskFocus, periodScope, biasHint = "MONTH") {
    const focusLabel = riskFocusLabel(riskFocus);
    const periodLabel = `${shortDateLabel(periodScope.dateFrom) ?? periodScope.dateFrom}-${shortDateLabel(periodScope.dateTo) ?? periodScope.dateTo}`;
    const message = [
        `**Which scope do you want for ${focusLabel}?**`,
        biasHint === "PERIOD"
            ? `Did you mean the current service period (${periodLabel}), matching your last question? The risk figures you were originally shown came from the current month - these can be different numbers.`
            : "The conversation has since narrowed to a specific service period, but the risk figures you were originally shown came from the current month - these can be different numbers.",
    ].join("\n");
    const monthAction = {
        actionId: "clarify-scope-month",
        capability: "attendance-risk-analysis",
        tool: "cccap_analyze_payment_risk",
        label: "Use the current month (matches the original snapshot)",
        reason: "Recompute this review against the same month-wide scope the earlier figures came from.",
        priority: "high",
        section: "next-actions",
        source: "current-result",
        input: { dateFilter: "THIS_MONTH", riskFocus },
    };
    const periodAction = {
        actionId: "clarify-scope-period",
        capability: "attendance-risk-analysis",
        tool: "cccap_analyze_payment_risk",
        label: `Use just the current period (${periodLabel})`,
        reason: "Keep the review scoped to the service period currently under discussion.",
        priority: "high",
        section: "next-actions",
        source: "current-result",
        input: { dateFilter: "DATE_RANGE", dateFrom: periodScope.dateFrom, dateTo: periodScope.dateTo, riskFocus },
    };
    const actions = biasHint === "PERIOD" ? [periodAction, monthAction] : [monthAction, periodAction];
    return {
        content: [{ type: "text", text: renderActionSections(message, actions) }],
        structuredContent: {
            capability: "attendance-risk-analysis",
            scopeClarification: true,
            actionIntents: actions,
        },
    };
}
export function countyPaymentSummary(rows) {
    const byCounty = new Map();
    for (const row of rows) {
        const county = typeof row.county_name === "string" && row.county_name.length > 0
            ? row.county_name
            : "Unavailable from the current source";
        const current = byCounty.get(county) ?? {
            county_name: county,
            children_served: 0,
            hours: 0,
            amount: 0,
            conditional_amount: 0,
        };
        current.children_served = Number(current.children_served) + Number(row.children_served ?? 0);
        current.hours = Number(current.hours) + Number(row.hours ?? 0);
        current.amount = Number(current.amount) + Number(row.amount ?? 0);
        current.conditional_amount = Number(current.conditional_amount) + Number(row.conditional_amount ?? 0);
        byCounty.set(county, current);
    }
    return [...byCounty.values()];
}
export function careUnitLabel(value) {
    switch (value) {
        case "PART_TIME": return "Part-time care";
        case "FULL_TIME": return "Full-time care";
        case "FULL_TIME_PLUS_PART_TIME": return "Full-time + part-time care";
        case "FULL_TIME_PLUS_FULL_TIME": return "Full-time + full-time care";
        case "NO_PAYMENT": return "No payable care unit";
        default: return tableValue(value);
    }
}
// Compact large childNames arrays for display while retaining the full server-side continuation input.
function compactScopeForDisplay(scope) {
    if (!scope || typeof scope !== "object" || Array.isArray(scope))
        return scope;
    const record = scope;
    if (!Array.isArray(record.childNames) || record.childNames.length <= 3)
        return scope;
    const { childNames, ...rest } = record;
    return { ...rest, childNamesCount: childNames.length };
}
export function viewState(state) {
    return Object.fromEntries(Object.entries({ ...state, scope: compactScopeForDisplay(state.scope) }).filter(([, value]) => value !== undefined));
}
export function actionViewMetadata(action, currentView) {
    const input = action.input && typeof action.input === "object" && !Array.isArray(action.input)
        ? action.input
        : undefined;
    return {
        ...action,
        sourceViewId: currentView.viewId,
        ...(input?.viewId ? { targetViewId: input.viewId } : { targetViewId: targetViewForAction(action.actionId) }),
        lockedView: currentView,
    };
}
export function isNoOpAction(action, currentView) {
    const input = action.input && typeof action.input === "object" && !Array.isArray(action.input)
        ? action.input
        : undefined;
    const scope = currentView.scope && typeof currentView.scope === "object" && !Array.isArray(currentView.scope)
        ? currentView.scope
        : undefined;
    if (!input || !scope)
        return false;
    const scopeKeys = ["childNames", "riskFocus", "countyNames", "authNames", "detailPage", "detailPageSize", "view"];
    const inputKeys = Object.keys(input).filter((key) => scopeKeys.includes(key));
    if (inputKeys.length === 0)
        return false;
    const scopeMatches = scopeKeys.every((key) => input[key] === undefined || JSON.stringify(input[key]) === JSON.stringify(scope[key]));
    if (!scopeMatches)
        return false;
    if (typeof action.targetViewId === "string" && action.targetViewId !== currentView.viewId)
        return false;
    return true;
}
// Multi-hop loop guard: drops a candidate action whose {tool, input} matches one of the last
// few states already rendered for this provider (recorded via conversation.ts's recordRenderedState).
export function isRecentlyRenderedAction(action, recentSignatures) {
    if (!recentSignatures || recentSignatures.size === 0)
        return false;
    if (typeof action.tool !== "string")
        return false;
    const input = action.input && typeof action.input === "object" && !Array.isArray(action.input)
        ? action.input
        : {};
    return recentSignatures.has(viewStateStableJson({ tool: action.tool, input }));
}
// Local stable-JSON serializer (duplicate-free: this file has no dependency on conversation.ts,
// keeping formatters independent of conversation-state internals).
function viewStateStableJson(value) {
    if (Array.isArray(value))
        return `[${value.map(viewStateStableJson).join(",")}]`;
    if (value && typeof value === "object") {
        return `{${Object.entries(value)
            .sort(([left], [right]) => left.localeCompare(right))
            .map(([key, entry]) => `${JSON.stringify(key)}:${viewStateStableJson(entry)}`)
            .join(",")}}`;
    }
    return JSON.stringify(value) ?? "null";
}
function targetViewForAction(actionId) {
    if (typeof actionId !== "string")
        return undefined;
    if (actionId.startsWith("attendance-view-")) {
        const viewId = actionId.slice("attendance-view-".length);
        if (viewId === "ATTENDANCE_DATE_DETAIL" || viewId === "ATTENDANCE_COUNTY_ROLLUP")
            return viewId;
    }
    if (actionId === "show-affected-children"
        || actionId === "next-attendance-detail-page"
        || actionId === "open-attendance-detail"
        || actionId === "open-attendance-risk-for-child") {
        return "ATTENDANCE_DATE_DETAIL";
    }
    if (actionId.startsWith("open-service-period-") || actionId === "review-service-period-payout-ledger") {
        return "SUB_PAYMENT_DETAIL";
    }
    if (actionId.includes("absence") || actionId.includes("confirmation") || actionId.includes("incomplete")) {
        return "ATTENDANCE_DATE_DETAIL";
    }
    if (actionId.includes("payment-county"))
        return "PAYMENT_COUNTY_ROLLUP";
    if (actionId.includes("vacant-slot"))
        return "VACANT_SLOT_ROLLUP";
    if (actionId.includes("sub-payment"))
        return "SUB_PAYMENT_SUMMARY";
    if (actionId.includes("county"))
        return "ATTENDANCE_COUNTY_ROLLUP";
    if (actionId.includes("payout"))
        return "NEXT_UPCOMING_PAYOUT";
    if (actionId.includes("forecast"))
        return "CURRENT_SERVICE_PERIOD_FORECAST";
    if (actionId.includes("payment-detail"))
        return "SUB_PAYMENT_DETAIL";
    if (actionId.includes("payment-summary"))
        return "PAYMENT_CATEGORY_ROLLUP";
    return undefined;
}
// ===== end view-state.ts =====
