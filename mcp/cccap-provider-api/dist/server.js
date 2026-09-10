import { McpServer } from "@modelcontextprotocol/server";
import { getAttendanceDataAnalysis, getAttendanceRiskAnalysis, getAttendanceRiskSnapshot, getCurrentMonthAttendanceSnapshot, } from "./attendance-snapshot.js";
import { getPaymentAnalysis } from "./payment-orchestration.js";
import { ConversationContextStore } from "./conversation-context.js";
import { DialogueStateStore } from "./dialogue-state.js";
import { normalizeAuthorizations, normalizeCases, normalizeCountyPlans, normalizeFiscalRates, normalizeHolidays, normalizePaymentHistory, normalizeProviderInitialization, normalizeSchedules, normalizeServicePeriods, } from "./read-model-adapters.js";
import { authorizationSchema, attendanceAnalysisSchema, attendanceDataSchema, caseSchema, countySchema, dateScopeSchema, fiscalRatesSchema, paymentHistorySchema, paymentAnalysisSchema, schedulesSchema, servicePeriodSchema, } from "./schemas.js";
const readOnlyAnnotations = {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: true,
};
const MAX_DISPLAY_CHILDREN = 10;
const MAX_SUMMARY_ROWS = 7;
const PAYMENT_DISCLAIMER = "⚠️ *All amounts shown are estimated based on current system data and are subject to change; they do not represent confirmed or final payout amounts.*";
function result(data) {
    const structuredContent = data && typeof data === "object" && !Array.isArray(data)
        ? data
        : undefined;
    return {
        content: [{ type: "text", text: JSON.stringify(data) }],
        ...(structuredContent ? { structuredContent } : {}),
    };
}
export function formatCountyPolicyResult(data) {
    const response = recordValue(data);
    const plans = response && Array.isArray(response.county_plans)
        ? response.county_plans.map(recordValue).filter((plan) => Boolean(plan))
        : [];
    if (plans.length === 0) {
        return {
            content: [{
                    type: "text",
                    text: "No verified county rate-plan limits were returned for the authorized provider scope.",
                }],
            structuredContent: {
                capability: "county-policy",
                resultStatus: "NO_POLICY_DATA",
            },
        };
    }
    const policyResponse = response;
    const tierColumns = [1, 2, 3, 4, 5].map((tier) => `Tier ${tier}`);
    const lines = [
        "**County absence limits**",
        "",
        `| County | Effective from | ${tierColumns.join(" | ")} |`,
        `| --- | --- | ${tierColumns.map(() => "---:").join(" | ")} |`,
        ...plans.map((plan) => `| ${tableValue(plan.county_name)} | ${tableValue(plan.effective_start)} | ${[1, 2, 3, 4, 5]
            .map((tier) => tableValue(recordValue(plan.absence_days_by_tier)?.[String(tier)]))
            .join(" | ")} |`),
        "",
        "These are the verified absence-day limits returned for the authorized provider counties. The applicable tier depends on the provider or authorization policy tier.",
    ];
    const providerMessage = lines.join("\n");
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "county-policy",
            resultStatus: "COMPLETED",
            policyCount: plans.length,
            scope: policyResponse.scope,
            sourceRetrievedAt: policyResponse.sourceRetrievedAt,
        },
    };
}
/**
 * Renders enrolled cases/children as safe provider-facing text. `id` on both
 * the case and each child is a raw Salesforce record ID and is never placed
 * in the rendered table; `name`/`external_id` (masked through `tableValue`
 * as a backstop) are the only identifiers shown.
 */
export function formatCasesResult(data, resolveCountyName = () => undefined) {
    const response = recordValue(data);
    const cases = response && Array.isArray(response.cases)
        ? response.cases.map(recordValue).filter((item) => Boolean(item))
        : [];
    if (cases.length === 0) {
        const providerMessage = "No verified cases were returned for the authorized provider scope.";
        return {
            content: [{ type: "text", text: providerMessage }],
            structuredContent: { capability: "cases", resultStatus: "NO_CASES" },
        };
    }
    const displayName = (record) => {
        const name = tableValue(record.name);
        return name !== "Unavailable from the current source" ? name : tableValue(record.external_id);
    };
    const countyLabel = (record) => tableValue(resolveCountyName(typeof record.county_id === "string" ? record.county_id : undefined));
    const lines = [
        "**Enrolled cases**",
        "",
        "| Case | County | Enrolled children | Effective dates |",
        "| --- | --- | --- | --- |",
        ...cases.map((caseRow) => {
            const children = Array.isArray(caseRow.children)
                ? caseRow.children.map(recordValue).filter((child) => Boolean(child))
                : [];
            const childNames = children.length > 0
                ? children.map(displayName).join(", ")
                : "Unavailable from the current source";
            const dates = children
                .map((child) => [child.effective_start, child.effective_end].filter((value) => typeof value === "string").join(" - "))
                .filter((value) => value.length > 0)
                .join("; ");
            return `| ${displayName(caseRow)} | ${countyLabel(caseRow)} | ${childNames} | ${dates || "Unavailable from the current source"} |`;
        }),
    ];
    const providerMessage = lines.join("\n");
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "cases",
            resultStatus: "COMPLETED",
            caseCount: cases.length,
        },
    };
}
/**
 * Renders authorizations as safe provider-facing text. `id`/`case_id` are
 * raw Salesforce record IDs and are never placed in the rendered table.
 */
export function formatAuthorizationsResult(data, resolveCountyName = () => undefined) {
    const response = recordValue(data);
    const authorizations = response && Array.isArray(response.authorizations)
        ? response.authorizations.map(recordValue).filter((item) => Boolean(item))
        : [];
    if (authorizations.length === 0) {
        const providerMessage = "No verified authorizations were returned for the authorized provider scope.";
        return {
            content: [{ type: "text", text: providerMessage }],
            structuredContent: { capability: "authorizations", resultStatus: "NO_AUTHORIZATIONS" },
        };
    }
    const displayName = (record) => {
        const name = tableValue(record.name);
        return name !== "Unavailable from the current source" ? name : tableValue(record.external_id);
    };
    const lines = [
        "**Authorizations**",
        "",
        "| Authorization | County | Status | Effective start | Effective end |",
        "| --- | --- | --- | --- | --- |",
        ...authorizations.map((authorization) => `| ${displayName(authorization)} | ${tableValue(resolveCountyName(typeof authorization.county_id === "string" ? authorization.county_id : undefined))} | ${tableValue(authorization.status)} | ${tableValue(authorization.effective_start)} | ${tableValue(authorization.effective_end)} |`),
    ];
    const providerMessage = lines.join("\n");
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "authorizations",
            resultStatus: "COMPLETED",
            authorizationCount: authorizations.length,
        },
    };
}
function snapshotResult(data) {
    if (!data || typeof data !== "object" || Array.isArray(data)) {
        return result(data);
    }
    const snapshot = data;
    const providerMessage = snapshot.providerMessage;
    if (typeof providerMessage !== "string" || providerMessage.length === 0) {
        return result(data);
    }
    const risk = recordValue(snapshot.attendanceRisk);
    const children = risk && Array.isArray(risk.children)
        ? risk.children
            .map(recordValue)
            .filter((child) => Boolean(child))
        : [];
    const actionIntents = risk ? actionMetadata(snapshot.scope, risk, children, true) : [];
    const attendanceView = risk
        ? attendanceSummary(risk, children, snapshot.scope, [], [], [])
        : undefined;
    const compactAttendanceView = compactAttendanceSummary(attendanceView);
    const overview = compactAttendanceView && recordValue(compactAttendanceView.overview);
    const snapshotSummary = overview
        ? [
            "",
            "Attendance overview:",
            "| Scheduled days | Affected children | Pending confirmations | Absence days | Incomplete children |",
            "| ---: | ---: | ---: | ---: | ---: |",
            `| ${tableValue(overview.scheduled_days)} | ${tableValue(overview.affected_children)} | ${tableValue(overview.pending_confirmation_days)} | ${tableValue(overview.absence_days)} | ${tableValue(overview.incomplete_children)} |`,
        ].join("\n")
        : "";
    const renderedMessage = renderActionSections(`${providerMessage}${snapshotSummary}`, actionIntents);
    return {
        content: [{ type: "text", text: renderedMessage }],
        structuredContent: {
            capability: "attendance-risk-snapshot",
            scope: snapshot.scope,
            sourceRetrievedAt: snapshot.sourceRetrievedAt,
            responseMode: "SUMMARY",
            responseSections: ["summary", "next-actions", "drill-down", "available-views"],
            providerMessage: renderedMessage,
            actionControls: actionControls(actionIntents),
        },
    };
}
function compactAttendanceSummary(attendanceView) {
    if (!attendanceView)
        return undefined;
    return {
        overview: attendanceView.overview,
        counties: attendanceView.counties,
    };
}
function compactActionControls(actions) {
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
function contextualize(value, store, providerKey, capability, result, resultTool) {
    if (value.isError || !value.structuredContent)
        return value;
    const actions = Array.isArray(value.structuredContent.actionControls)
        ? value.structuredContent.actionControls.map(recordValue).filter((action) => Boolean(action))
        : Array.isArray(value.structuredContent.actionIntents)
            ? value.structuredContent.actionIntents.map(recordValue).filter((action) => Boolean(action))
            : [];
    // Inherited actions let a later turn still reach an older offered action
    // (e.g. "you can still review attendance from here"), but they must not
    // flood every subsequent response: exclude anything from the SAME domain
    // capability as the current result (the current result's own actions
    // already cover that domain) and cap the carryover to one supplementary
    // cross-capability action so the response does not repeat a growing pile
    // of stale buttons turn after turn.
    const currentCapability = typeof value.structuredContent.capability === "string"
        ? value.structuredContent.capability
        : undefined;
    const inheritedActions = store.getInheritedActions(providerKey, actions)
        .map((action) => action.metadata)
        .filter((action) => action.capability !== currentCapability)
        .slice(0, 1);
    const combinedActions = [...actions, ...inheritedActions];
    if (combinedActions.length === 0)
        return value;
    const plans = combinedActions.flatMap((action) => {
        const tool = action.tool;
        const input = recordValue(action.input);
        return (tool === "cccap_analyze_attendance_risk" || tool === "cccap_analyze_payment") && input
            ? [{ tool, input }]
            : [];
    });
    if (plans.length === 0)
        return value;
    const ruleVersion = typeof value.structuredContent.ruleVersion === "string"
        ? value.structuredContent.ruleVersion
        : undefined;
    const planActions = combinedActions.filter((action) => {
        const input = recordValue(action.input);
        return Boolean(input) && (action.tool === "cccap_analyze_attendance_risk" || action.tool === "cccap_analyze_payment");
    });
    const { contextRef, actionRefs } = store.create(providerKey, capability, plans, result, resultTool, ruleVersion, planActions);
    let actionIndex = 0;
    const actionControls = combinedActions.map((action) => {
        const input = recordValue(action.input);
        if (!input || (action.tool !== "cccap_analyze_attendance_risk" && action.tool !== "cccap_analyze_payment"))
            return action;
        const actionRef = actionRefs[actionIndex++];
        return {
            type: "button",
            actionId: action.actionId,
            label: action.label,
            ...(action.reason ? { reason: action.reason } : {}),
            ...(action.priority ? { priority: action.priority } : {}),
            section: action.section,
            capability: action.capability,
            tool: action.tool,
            input: { contextRef, actionRef },
        };
    });
    const { actionIntents: _actionIntents, filters: _filters, responseContext: _responseContext, ...structuredContent } = value.structuredContent;
    return {
        ...value,
        structuredContent: {
            ...structuredContent,
            contextRef,
            actionControls,
        },
    };
}
/**
 * Attaches the dialogue-state diff (scopeChanged/capabilityChanged/
 * sinceLastTurn) to a composite tool's structured content. This gives the
 * conversational model a concrete, server-computed signal for turn
 * classification (continuation vs. new request vs. refresh) instead of
 * asking it to infer that purely from the raw transcript.
 */
function attachDialogueState(value, store, providerKey, capability, scope, freshnessAt) {
    if (value.isError || !value.structuredContent || typeof freshnessAt !== "string")
        return value;
    const diff = store.recordAndDiff(providerKey, capability, scope, freshnessAt);
    return {
        ...value,
        structuredContent: {
            ...value.structuredContent,
            scopeChanged: diff.scopeChanged,
            capabilityChanged: diff.capabilityChanged,
            ...(diff.sinceLastTurn ? { sinceLastTurn: diff.sinceLastTurn } : {}),
        },
    };
}
function recordValue(value) {
    return value && typeof value === "object" && !Array.isArray(value)
        ? value
        : undefined;
}
function tableValue(value) {
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
function estimatedMoney(value) {
    const numeric = typeof value === "number"
        ? value
        : typeof value === "string" && value.trim() !== "" && Number.isFinite(Number(value))
            ? Number(value)
            : undefined;
    const display = numeric === undefined ? tableValue(value) : numeric.toFixed(2);
    return display === "Unavailable from the current source" ? display : `~ $${display}`;
}
function renderCountyComposition(rows) {
    const component = (row, key) => recordValue(row[key]) ?? {};
    const headers = [
        "County",
        "Care hours", "Care amount",
        "Absence hours", "Absence amount",
        "Drop-in hours", "Drop-in amount",
        "Vacant slot days", "Vacant slot amount",
        "Paid holiday hours", "Paid holiday amount",
        "Potential total",
    ];
    const separator = headers.map((header) => header === "County" ? "---" : "---:");
    const renderedRows = rows.map((row) => {
        const care = component(row, "care");
        const absence = component(row, "absence");
        const dropIn = component(row, "drop_in");
        const vacantSlots = component(row, "vacant_slots");
        const paidHolidays = component(row, "paid_holidays");
        return [
            tableValue(row.county),
            tableValue(care.hours), estimatedMoney(care.amount),
            tableValue(absence.hours), estimatedMoney(absence.amount),
            tableValue(dropIn.hours), estimatedMoney(dropIn.amount),
            tableValue(vacantSlots.days), estimatedMoney(vacantSlots.amount),
            tableValue(paidHolidays.hours), estimatedMoney(paidHolidays.amount),
            estimatedMoney(row.potential_total),
        ].join(" | ");
    });
    return [
        "",
        "County payment composition (potential amounts)",
        "Potential amounts include confirmed and conditional amounts; the payable amount remains shown in the summary above.",
        `| ${headers.join(" | ")} |`,
        `| ${separator.join(" | ")} |`,
        ...renderedRows.map((row) => `| ${row} |`),
    ];
}
function isSalesforceRecordId(value) {
    return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
}
function authorizationDates(value) {
    if (!Array.isArray(value) || value.length === 0) {
        return "Unavailable from the current source";
    }
    return value.map(tableValue).join(", ");
}
function authorizationNames(value) {
    if (!Array.isArray(value) || value.length === 0) {
        return "Unavailable from the current source";
    }
    return value.map(tableValue).join(", ");
}
function numericValue(value) {
    return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
function attendanceScopeLabel(scope) {
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
function hasAbsenceLimitConcern(child) {
    return Array.isArray(child.risk_codes) && child.risk_codes.some((code) => code === "ABSENCE_LIMIT_EXCEEDED" || code === "ABSENCE_LIMIT_APPROACHING");
}
function criticalityScore(row) {
    const codes = Array.isArray(row.risk_codes) ? row.risk_codes : [];
    let score = 0;
    if (codes.includes("ABSENCE_LIMIT_EXCEEDED"))
        score += 100;
    if (codes.includes("PARENT_CONFIRMATION_PENDING"))
        score += 80;
    if (codes.includes("INCOMPLETE_ATTENDANCE_RECORD"))
        score += 60;
    score += numericValue(row.absence_days) * 3;
    score += numericValue(row.pending_confirmation_days) * 2;
    return score;
}
function actionMetadata(scope, risk, children, includePaymentAction = false, riskFocus) {
    const childNamesFor = (code) => children
        .filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes(code))
        .map((child) => child.child_name)
        .filter((name) => typeof name === "string");
    const scopeInput = recordValue(scope) ?? {};
    const actions = [];
    const absenceChildren = children.filter(hasAbsenceLimitConcern);
    const absenceChildNames = absenceChildren
        .map((child) => child.child_name)
        .filter((name) => typeof name === "string");
    if (absenceChildren.length > 0 && riskFocus !== "PARENT_CONFIRMATIONS") {
        actions.push({
            actionId: "review-absence-limit-risk",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_attendance_risk",
            label: `Review ${absenceChildren.length} child(ren) near or over the absence limit`,
            reason: "Absence-limit exposure may reduce reimbursable payment.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            riskFocus: "ABSENCE_LIMITS",
            input: Object.assign({ riskFocus: "ABSENCE_LIMITS" }, scopeInput, { childNames: absenceChildNames }),
            scope,
        });
    }
    const pendingChildNames = childNamesFor("PARENT_CONFIRMATION_PENDING");
    const incompleteChildNames = childNamesFor("INCOMPLETE_ATTENDANCE_RECORD");
    if (numericValue(risk.pending_confirmation_days) > 0 && riskFocus !== "ABSENCE_LIMITS") {
        actions.push({
            actionId: "review-pending-parent-confirmations",
            capability: "attendance-risk-analysis",
            label: `Review ${numericValue(risk.pending_confirmation_days)} pending parent confirmation day(s)`,
            reason: "Unconfirmed attendance may keep payment conditional.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            scope,
            tool: "cccap_analyze_attendance_risk",
            input: Object.assign({ riskFocus: "PARENT_CONFIRMATIONS" }, scopeInput, { childNames: pendingChildNames }),
        });
    }
    if (incompleteChildNames.length > 0 && riskFocus !== "ABSENCE_LIMITS") {
        actions.push({
            actionId: "review-incomplete-attendance",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_attendance_risk",
            label: `Review ${incompleteChildNames.length} incomplete attendance record(s)`,
            reason: "A check-in or check-out is missing and may affect attendance verification.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            scope,
            riskFocus: "INCOMPLETE_ATTENDANCE",
            input: Object.assign({ riskFocus: "INCOMPLETE_ATTENDANCE" }, scopeInput, { childNames: incompleteChildNames }),
        });
    }
    if (actions.length === 0 && !includePaymentAction) {
        actions.push({
            actionId: "review-attendance-records",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_attendance_risk",
            label: "Review attendance records for missing or incomplete check-ins",
            reason: "Incomplete records can affect attendance verification and payment.",
            priority: "medium",
            section: "next-actions",
            source: "current-result",
            input: Object.assign({}, scopeInput),
            scope,
        });
    }
    if (children.length > 0 && !includePaymentAction) {
        const highestImpactChild = [...children]
            .sort((left, right) => criticalityScore(right) - criticalityScore(left))[0];
        const highestImpactChildName = typeof highestImpactChild?.child_name === "string"
            ? highestImpactChild.child_name
            : undefined;
        actions.push({
            actionId: "open-attendance-detail",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_attendance_risk",
            label: "Open the highest-impact attendance details",
            reason: "Inspect the affected children, dates, and payment implications behind the summary.",
            priority: "medium",
            section: "drill-down",
            source: "current-result",
            input: Object.assign({}, scopeInput, highestImpactChildName ? { childNames: [highestImpactChildName] } : {}),
            scope,
        });
    }
    if (includePaymentAction) {
        actions.push({
            actionId: "review-next-payout",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Review the next payout summary",
            reason: "Confirm the next service period and estimated payment status.",
            priority: "medium",
            section: "available-options",
            source: "current-result",
            view: "NEXT_PAYOUT",
            input: { view: "NEXT_PAYOUT" },
            scope,
        });
    }
    return actions;
}
function attendanceSummary(risk, children, scope, unmatchedChildNames, excludedClosureDates, excludedHolidayDates) {
    const counties = new Map();
    const childRows = children.map((child) => ({
        child: child.child_name,
        county: child.county,
        pending_confirmation_days: numericValue(child.pending_confirmation_days),
        absence_days: numericValue(child.absence_days),
        absence_limit: child.absence_limit,
        authorization_dates: child.authorization_dates,
        risk_codes: Array.isArray(child.risk_codes) ? child.risk_codes : [],
        note: child.note,
        potential_impact: child.potential_impact,
    }));
    for (const child of children) {
        const key = typeof child.county === "string" && child.county.length > 0 ? child.county : "UNKNOWN";
        const current = counties.get(key) ?? {
            county: typeof child.county === "string" && child.county.length > 0 ? child.county : "Unavailable from the current source",
            children: 0,
            pending_confirmation_days: 0,
            absence_days: 0,
            risk_children: 0,
            absence_limit: undefined,
        };
        current.children = Number(current.children) + 1;
        current.pending_confirmation_days = Number(current.pending_confirmation_days) + numericValue(child.pending_confirmation_days);
        current.absence_days = Number(current.absence_days) + numericValue(child.absence_days);
        if (Array.isArray(child.risk_codes) && child.risk_codes.length > 0) {
            current.risk_children = Number(current.risk_children) + 1;
        }
        // A county's absence-day limit is the same value for every child sharing
        // that county and provider tier, so the first verified value seen is
        // authoritative for the county row; do not overwrite it with a
        // conflicting value from a different child (leave it unresolved instead
        // of silently picking one side of a real data conflict).
        if (typeof child.absence_limit === "number") {
            if (current.absence_limit === undefined) {
                current.absence_limit = child.absence_limit;
            }
            else if (current.absence_limit !== child.absence_limit) {
                current.absence_limit = null;
            }
        }
        counties.set(key, current);
    }
    const scopeInput = recordValue(scope) ?? {};
    const availableViews = [
        {
            viewId: "ATTENDANCE_BY_COUNTY",
            label: "View attendance by county",
            reason: "Compare pending confirmations, absence usage, and affected children across counties.",
            section: "available-views",
            input: scopeInput,
        },
        {
            viewId: "ATTENDANCE_BY_CHILD",
            label: "View attendance by child",
            reason: "Open child-level dates, classifications, and risk explanations.",
            section: "drill-down",
            input: scopeInput,
        },
    ];
    if (numericValue(risk.pending_confirmation_days) > 0) {
        availableViews.unshift({
            viewId: "PARENT_CONFIRMATIONS",
            label: "Review pending parent confirmations",
            reason: "These days may remain conditional until attendance is confirmed.",
            section: "next-actions",
            input: Object.assign({ riskFocus: "PARENT_CONFIRMATIONS" }, scopeInput),
        });
    }
    if (children.some(hasAbsenceLimitConcern)) {
        availableViews.unshift({
            viewId: "ABSENCE_LIMITS",
            label: "Review absence limits",
            reason: "Absence usage may reduce reimbursable payment for affected children.",
            section: "next-actions",
            input: Object.assign({ riskFocus: "ABSENCE_LIMITS" }, scopeInput),
        });
    }
    if (children.some((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD"))) {
        availableViews.unshift({
            viewId: "INCOMPLETE_RECORDS",
            label: "Review incomplete attendance records",
            reason: "Missing check-in or check-out records need verification.",
            section: "next-actions",
            input: scopeInput,
        });
    }
    if (children.some((child) => typeof child.potential_impact === "string" && child.potential_impact.length > 0)) {
        availableViews.push({
            viewId: "PAYMENT_IMPACT",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Review payment impact",
            reason: "Compare attendance risks with the estimated payment result.",
            section: "available-views",
            input: Object.assign({ view: "NEXT_PAYOUT" }, scopeInput),
        });
    }
    return {
        overview: {
            scheduled_days: numericValue(risk.scheduled_days),
            affected_children: children.length,
            pending_confirmation_days: numericValue(risk.pending_confirmation_days),
            absence_days: numericValue(risk.absence_days),
            incomplete_children: children.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD")).length,
            unmatched_children: unmatchedChildNames.length,
            excluded_closure_dates: excludedClosureDates.length,
            excluded_holiday_dates: excludedHolidayDates.length,
        },
        counties: [...counties.values()].sort((left, right) => String(left.county).localeCompare(String(right.county))),
        children: childRows,
        available_views: availableViews.slice(0, 6).map((view) => ({
            actionId: `attendance-view-${String(view.viewId)}`,
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_attendance_risk",
            ...view,
        })),
    };
}
function actionControls(actions) {
    return actions.map((action) => ({
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
function paymentActionMetadata(paymentResult, payment, detailPagination, status, detailPage) {
    const filterInput = recordValue(paymentResult.filters) ?? {};
    const highestImpactChildName = typeof paymentResult.highestImpactChildName === "string"
        ? paymentResult.highestImpactChildName
        : undefined;
    const paymentInput = (overrides) => Object.assign({ view: paymentResult.paymentView ?? "NEXT_PAYOUT" }, filterInput, overrides);
    if (status === "BLOCKED") {
        return [{
                actionId: "retry-payment-analysis",
                capability: "payment-analysis",
                tool: "cccap_analyze_payment",
                label: "Retry the payment review with current provider data",
                reason: "The payment result is blocked until required source data is available.",
                priority: "high",
                section: "next-actions",
                source: "current-result",
                input: paymentInput({}),
            }];
    }
    const actions = [];
    const attendance = recordValue(paymentResult.attendance);
    const returnedRows = Array.isArray(attendance?.days) ? attendance.days.length : 0;
    const totalRows = detailPagination
        ? numericValue(detailPagination.totalRows)
        : returnedRows;
    const hasMore = detailPagination?.hasMore === true;
    if (detailPage && hasMore) {
        actions.push({
            actionId: "next-payment-detail-page",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Open the next child-level payment detail page",
            reason: "Continue reviewing the remaining payment rows in priority order.",
            priority: "medium",
            section: "drill-down",
            source: "current-result",
            input: {
                ...paymentInput({ detailPage: numericValue(detailPagination?.page) + 1 }),
            },
        });
    }
    else if (!detailPage && totalRows > 0) {
        actions.push({
            actionId: "open-payment-detail",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Open the highest-impact child payment details",
            reason: "Inspect the child and service-date rows behind this summary.",
            priority: "high",
            section: "drill-down",
            source: "current-result",
            input: paymentInput({
                detailPage: 1,
                ...(highestImpactChildName ? { childNames: [highestImpactChildName] } : {}),
            }),
        });
    }
    if (numericValue(payment.excluded_days) > 0) {
        actions.push({
            actionId: "review-excluded-payment-days",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Review excluded attendance days and payment impact",
            reason: "Excluded days may explain a lower estimated amount.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            input: paymentInput({ detailPage: 1 }),
        });
    }
    if (actions.length === 0) {
        actions.push({
            actionId: "review-payment-summary",
            capability: "payment-analysis",
            label: "Review the payment summary by county and care unit",
            reason: "Compare the estimated payment across the current provider scope.",
            priority: "medium",
            section: "available-views",
            source: "current-result",
            input: paymentInput({}),
        });
    }
    return actions.slice(0, 2);
}
const MAX_NEXT_ACTIONS = 2;
function renderActionSections(message, actions) {
    const base = message.replace(/\n\*\*Next actions\*\*[\s\S]*$/, "");
    // Cap to the two highest-priority next actions so the response names the
    // one or two things that actually matter instead of listing every
    // candidate action; numbered (not bulleted) to match the drill-down
    // action-list convention and avoid the list reading as an open-ended pile.
    const nextActions = actions
        .filter((action) => action.section === "next-actions")
        .slice(0, MAX_NEXT_ACTIONS);
    const drillDown = actions.filter((action) => action.section === "drill-down");
    const availableViews = actions.filter((action) => action.section === "available-options" || action.section === "available-views");
    const lines = [base, "", "**Next actions**"];
    lines.push(...(nextActions.length > 0
        ? nextActions.map((action, index) => `${index + 1}. ${String(action.label)} (${String(action.reason)})`)
        : ["No urgent action identified from the current verified result."]));
    if (drillDown.length > 0) {
        lines.push("", "**Drill down**", ...drillDown.map((action) => `- ${String(action.label)}`));
    }
    if (availableViews.length > 0) {
        lines.push("", "**Available views**", ...availableViews.map((action) => `- ${String(action.label)}`));
    }
    lines.push("", "**Next step**", "Ask about a specific child, authorization, county, date, or payment impact, or choose one of the reviews above.");
    return lines.join("\n");
}
function countyPaymentSummary(rows) {
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
function paymentSummaryView(value) {
    return recordValue(value);
}
function compactPaymentSummaryView(value) {
    if (!value)
        return undefined;
    const compact = {};
    const overview = recordValue(value.overview);
    if (overview)
        compact.overview = overview;
    for (const key of ["categories", "counties", "children", "vacant_slots", "next_actions"]) {
        const rows = Array.isArray(value[key]) ? value[key] : undefined;
        if (rows && rows.length > 0)
            compact[`${key}Count`] = rows.length;
    }
    const countyComposition = Array.isArray(value.county_composition)
        ? value.county_composition.map(recordValue).filter((row) => Boolean(row))
        : undefined;
    if (countyComposition && countyComposition.length > 0)
        compact.county_composition = countyComposition;
    return compact;
}
function summaryRows(value, key) {
    const summary = paymentSummaryView(value);
    return summary && Array.isArray(summary[key])
        ? summary[key].map(recordValue).filter((row) => Boolean(row))
        : [];
}
function sourceIntegrityError(scope, message) {
    return {
        isError: true,
        content: [{
                type: "text",
                text: JSON.stringify({
                    error: {
                        code: "PROVIDER_DATA_INCONSISTENT",
                        capability: "attendance-risk analysis",
                        scope,
                        message,
                        nextSteps: [
                            "Retry the same request once",
                            "Review data quality if the problem continues",
                        ],
                    },
                }),
            }],
    };
}
export function formatAttendanceRiskResult(data) {
    const analysis = recordValue(data);
    const risk = analysis && recordValue(analysis.attendanceRisk);
    const children = risk && Array.isArray(risk.children) ? risk.children : undefined;
    if (!risk || !children) {
        return result(data);
    }
    const allAffectedChildren = children
        .map(recordValue)
        .filter((child) => Boolean(child))
        .filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.length > 0);
    const riskFocus = analysis?.riskFocus;
    const sourceUnmatchedChildNames = Array.isArray(risk.unmatched_child_names)
        ? risk.unmatched_child_names.filter((name) => typeof name === "string")
        : [];
    const excludedClosureDates = Array.isArray(risk.excluded_closure_dates)
        ? risk.excluded_closure_dates.filter((date) => typeof date === "string")
        : [];
    const excludedHolidayDates = Array.isArray(risk.excluded_holiday_dates)
        ? risk.excluded_holiday_dates.filter((date) => typeof date === "string")
        : [];
    const riskFocusedChildren = riskFocus === "PARENT_CONFIRMATIONS"
        ? allAffectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("PARENT_CONFIRMATION_PENDING"))
        : riskFocus === "ABSENCE_LIMITS"
            ? allAffectedChildren.filter(hasAbsenceLimitConcern)
            : riskFocus === "INCOMPLETE_ATTENDANCE"
                ? allAffectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD"))
                : allAffectedChildren;
    const requestedChildNames = recordValue(analysis?.scope)?.childNames;
    const requestedChildNameList = Array.isArray(requestedChildNames)
        ? requestedChildNames.filter((name) => typeof name === "string" && name.length > 0)
        : [];
    const normalizedRequestedChildren = new Set(requestedChildNameList.map((name) => name.trim().toLowerCase()));
    const requestedCountyNames = Array.isArray(analysis?.countyNames)
        ? analysis.countyNames.filter((name) => typeof name === "string" && name.length > 0)
        : [];
    const normalizedRequestedCounties = new Set(requestedCountyNames.map((name) => name.trim().toLowerCase()));
    // Child and county filters narrow an existing result, including cached
    // continuations, without widening scope or requiring another source read.
    const childScopedChildren = normalizedRequestedChildren.size > 0
        ? riskFocusedChildren.filter((child) => typeof child.child_name === "string" && normalizedRequestedChildren.has(child.child_name.trim().toLowerCase()))
        : riskFocusedChildren;
    const affectedChildren = normalizedRequestedCounties.size > 0
        ? childScopedChildren.filter((child) => typeof child.county === "string" && normalizedRequestedCounties.has(child.county.trim().toLowerCase()))
        : childScopedChildren;
    const unmatchedChildNames = [
        ...sourceUnmatchedChildNames,
        ...requestedChildNameList.filter((name) => !riskFocusedChildren.some((child) => typeof child.child_name === "string" && child.child_name.trim().toLowerCase() === name.trim().toLowerCase())),
    ].filter((name, index, names) => names.indexOf(name) === index);
    const unmatchedCountyNames = normalizedRequestedCounties.size > 0
        ? requestedCountyNames.filter((name) => !childScopedChildren.some((child) => typeof child.county === "string" && child.county.trim().toLowerCase() === name.trim().toLowerCase()))
        : [];
    const pendingDays = riskFocus === "PARENT_CONFIRMATIONS"
        ? affectedChildren.reduce((total, child) => total + numericValue(child.pending_confirmation_days), 0)
        : riskFocus === "ABSENCE_LIMITS" || riskFocus === "INCOMPLETE_ATTENDANCE" ? 0 : numericValue(risk.pending_confirmation_days);
    const pendingChildren = affectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("PARENT_CONFIRMATION_PENDING")).length;
    const absenceChildren = affectedChildren.filter(hasAbsenceLimitConcern).length;
    const incompleteChildren = affectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD")).length;
    const probableAbsenceDays = riskFocus === "ABSENCE_LIMITS"
        ? affectedChildren.reduce((total, child) => total + numericValue(child.absence_days), 0)
        : riskFocus === "PARENT_CONFIRMATIONS" || riskFocus === "INCOMPLETE_ATTENDANCE" ? 0 : numericValue(risk.absence_days);
    const scopeLabel = attendanceScopeLabel(analysis.scope);
    const childPendingDays = affectedChildren.reduce((total, child) => total + numericValue(child.pending_confirmation_days), 0);
    const childProbableAbsenceDays = affectedChildren.reduce((total, child) => total + numericValue(child.absence_days), 0);
    const reportedRiskChildCount = numericValue(risk.risk_child_count);
    // A county filter is a valid narrowing of the same result (like riskFocus),
    // so the affected-children subset is expected to sum to less than the
    // facility-wide aggregate; only run the consistency check against the full,
    // unnarrowed result.
    if (!riskFocus && normalizedRequestedCounties.size === 0 && (childPendingDays !== pendingDays ||
        childProbableAbsenceDays !== probableAbsenceDays ||
        (reportedRiskChildCount > 0 && reportedRiskChildCount !== affectedChildren.length))) {
        return sourceIntegrityError(analysis.scope, "Aggregate attendance risk totals do not match the returned child details.");
    }
    const hasAuthorizationNames = affectedChildren.some((child) => Array.isArray(child.authorization_names) && child.authorization_names.length > 0);
    const hasCounties = affectedChildren.some((child) => typeof child.county === "string" && child.county.length > 0);
    const noAttendanceRecords = children.length === 0 && numericValue(risk.scheduled_days) === 0;
    const attendanceView = attendanceSummary(risk, affectedChildren, analysis.scope, unmatchedChildNames, excludedClosureDates, excludedHolidayDates);
    const lines = [
        noAttendanceRecords
            ? `${scopeLabel} attendance review returned no attendance records for the requested period.`
            : affectedChildren.length > 0
                ? `${scopeLabel} attendance review found ${affectedChildren.length} child(ren) needing attention.`
                : `${scopeLabel} attendance review found no child-level attendance risks.`,
    ];
    if (unmatchedChildNames.length > 0) {
        lines.push(`No attendance records were found for ${unmatchedChildNames.length} requested child(ren) in the selected period.`);
    }
    if (unmatchedCountyNames.length > 0) {
        lines.push(`No affected children were found for the requested county/counties: ${unmatchedCountyNames.join(", ")}.`);
    }
    if (excludedClosureDates.length > 0) {
        lines.push(`Excluded ${excludedClosureDates.length} scheduled closure date(s) from attendance counts: ${excludedClosureDates.join(", ")}.`);
    }
    if (excludedHolidayDates.length > 0) {
        lines.push(`Excluded ${excludedHolidayDates.length} observed holiday date(s) from attendance counts: ${excludedHolidayDates.join(", ")}.`);
    }
    if (riskFocus !== "ABSENCE_LIMITS" && riskFocus !== "INCOMPLETE_ATTENDANCE" && pendingDays > 0) {
        lines.push(`${pendingDays} pending parent confirmation day(s) affect ${pendingChildren} child(ren).`);
    }
    if (riskFocus !== "PARENT_CONFIRMATIONS" && riskFocus !== "INCOMPLETE_ATTENDANCE" && absenceChildren > 0) {
        lines.push(`${absenceChildren} child(ren) have an absence-limit concern${probableAbsenceDays > 0 ? ` (${probableAbsenceDays} absence day(s))` : ""}.`);
    }
    if (!riskFocus && incompleteChildren > 0) {
        lines.push(`${incompleteChildren} child(ren) have incomplete attendance records.`);
    }
    if (affectedChildren.length > 0) {
        const displayedChildren = [...affectedChildren]
            .sort((left, right) => criticalityScore(right) - criticalityScore(left))
            .slice(0, Math.min(MAX_DISPLAY_CHILDREN, MAX_SUMMARY_ROWS));
        if (riskFocus === "ABSENCE_LIMITS") {
            lines.push("", "| Child name | County | Authorization name | Absence dates | Absences used | Applicable limit | Note | Potential impact |", "| --- | --- | --- | --- | ---: | ---: | --- | --- |", ...displayedChildren.map((child) => `| ${tableValue(child.child_name)} | ${tableValue(child.county)} | ${authorizationNames(child.authorization_names)} | ${authorizationDates(child.absence_dates)} | ${tableValue(child.absence_days)} | ${tableValue(child.absence_limit)} | ${tableValue(child.note)} | ${tableValue(child.potential_impact)} |`));
        }
        else {
            lines.push("", "| Child name | Household name | County | Authorization name | Service dates | Note | Potential impact |", "| --- | --- | --- | --- | --- | --- | --- |", ...displayedChildren.map((child) => `| ${tableValue(child.child_name)} | ${tableValue(child.household_name)} | ${tableValue(child.county)} | ${authorizationNames(child.authorization_names)} | ${authorizationDates(child.authorization_dates)} | ${tableValue(child.note)} | ${tableValue(child.potential_impact)} |`));
        }
        if (affectedChildren.length > displayedChildren.length) {
            lines.push("", `Showing the first ${displayedChildren.length} of ${affectedChildren.length} affected children. Ask for the remaining child details by name or group.`);
        }
    }
    const attendanceOverview = recordValue(attendanceView.overview);
    const attendanceCounties = Array.isArray(attendanceView.counties)
        ? attendanceView.counties.map(recordValue).filter((row) => Boolean(row))
        : [];
    const attendanceViews = Array.isArray(attendanceView.available_views)
        ? attendanceView.available_views.map(recordValue).filter((row) => Boolean(row))
        : [];
    if (attendanceOverview) {
        lines.push("", "Attendance overview:", "| Scheduled days | Affected children | Pending confirmations | Absence days | Incomplete children | Excluded closures | Excluded holidays |", "| ---: | ---: | ---: | ---: | ---: | ---: | ---: |", `| ${tableValue(attendanceOverview.scheduled_days)} | ${tableValue(attendanceOverview.affected_children)} | ${tableValue(attendanceOverview.pending_confirmation_days)} | ${tableValue(attendanceOverview.absence_days)} | ${tableValue(attendanceOverview.incomplete_children)} | ${tableValue(attendanceOverview.excluded_closure_dates)} | ${tableValue(attendanceOverview.excluded_holiday_dates)} |`);
    }
    if (attendanceCounties.length > 0) {
        if (riskFocus === "ABSENCE_LIMITS") {
            lines.push("", "Attendance by county:", "| County | Children | Absence days | Applicable limit | Remaining allowance | Status |", "| --- | ---: | ---: | ---: | ---: | --- |", ...attendanceCounties.map((county) => {
                const limit = county.absence_limit;
                const absenceDays = numericValue(county.absence_days);
                const remaining = typeof limit === "number" ? limit - absenceDays : undefined;
                const countyStatus = typeof limit !== "number"
                    ? "Limit unavailable"
                    : absenceDays > limit
                        ? "Over limit"
                        : limit - absenceDays <= 2
                            ? "Approaching limit"
                            : "Within limit";
                return `| ${tableValue(county.county)} | ${tableValue(county.children)} | ${tableValue(absenceDays)} | ${tableValue(limit)} | ${remaining !== undefined ? tableValue(remaining) : "Unavailable from the current source"} | ${countyStatus} |`;
            }));
        }
        else {
            lines.push("", "Attendance by county:", "| County | Children | Risk children | Pending confirmations | Absence days |", "| --- | ---: | ---: | ---: | ---: |", ...attendanceCounties.map((county) => `| ${tableValue(county.county)} | ${tableValue(county.children)} | ${tableValue(county.risk_children)} | ${tableValue(county.pending_confirmation_days)} | ${tableValue(county.absence_days)} |`));
        }
    }
    if (attendanceViews.length > 0) {
        lines.push("", "Recommended attendance views:", ...attendanceViews.slice(0, 4).map((view) => `- ${tableValue(view.label)}: ${tableValue(view.reason)}`));
    }
    const actionIntents = actionMetadata(analysis.scope, risk, affectedChildren, false, typeof riskFocus === "string" ? riskFocus : undefined);
    const providerMessage = renderActionSections(lines.join("\n"), actionIntents);
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "attendance-risk-analysis",
            scope: analysis.scope,
            sourceRetrievedAt: analysis.sourceRetrievedAt,
            resultStatus: noAttendanceRecords ? "NO_ATTENDANCE_SCHEDULES" : "COMPLETED",
            riskFocus,
            actionControls: compactActionControls(actionIntents),
            attendanceSummary: compactAttendanceSummary(attendanceView),
        },
    };
}
export function formatPaymentResult(data) {
    const paymentResult = recordValue(data);
    const payment = paymentResult && recordValue(paymentResult.payment);
    if (!paymentResult || !payment)
        return result(data);
    const status = typeof payment.status === "string" ? payment.status.toUpperCase() : "BLOCKED";
    const detailPagination = recordValue(paymentResult.detailPagination);
    const detailPage = detailPagination && Number(detailPagination.page) > 0;
    const view = paymentResult.paymentView === "NEXT_PAYOUT"
        ? detailPage ? "Next payout detail" : "Next payout summary"
        : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
            ? "Current service-period forecast"
            : "Payment status";
    const servicePeriod = recordValue(paymentResult.servicePeriod);
    const attendanceContainer = recordValue(paymentResult.attendance);
    const attendanceDays = attendanceContainer?.["days"];
    const attendance = Array.isArray(attendanceDays)
        ? attendanceDays
            .map(recordValue)
            .filter((row) => Boolean(row))
            .filter((row) => row.classification !== "NO_CARE")
        : [];
    const missingInputs = Array.isArray(payment.missing_inputs)
        ? payment.missing_inputs.filter((value) => typeof value === "string")
        : [];
    const summaryView = paymentSummaryView(payment.summary_view);
    const statusLabel = status === "DUPLICATE_GUARD"
        ? "Already paid or requested"
        : status === "CONDITIONAL"
            ? "Conditional"
            : status === "EXPECTED"
                ? "Expected"
                : "Blocked";
    const lines = [
        `${view}: ${statusLabel}.`,
        "",
        "| Measure | Result |",
        "| --- | --- |",
        `| Status | ${statusLabel} |`,
    ];
    if (servicePeriod) {
        for (const [label, keys] of [
            ["Services from", ["serviceBeginDate", "start_date"]],
            ["Services through", ["serviceEndDate", "end_date"]],
            ["Payment processing date", ["paymentProcessingDate", "processing_date"]],
            ["Payment release date", ["paymentReleaseDate", "release_date"]],
            ["Service-period status", ["status", "service_period_status"]],
        ]) {
            const value = keys.map((key) => servicePeriod[key]).find((candidate) => candidate !== undefined && candidate !== null);
            if (value !== undefined)
                lines.push(`| ${label} | ${tableValue(value)} |`);
        }
    }
    if (status === "BLOCKED") {
        lines.push(`| Missing source areas | ${missingInputs.length > 0 ? missingInputs.join(", ") : "Required source data is unavailable"} |`, "", "No payment amount is shown because the approved source data is incomplete.");
    }
    else {
        for (const [label, key] of [
            ["Net amount", "amount"],
            ["Gross amount", "gross_amount"],
            ["Amount at risk", "amount_at_risk"],
            ["Excluded days", "excluded_days"],
            ["Excluded authorizations", "excluded_authorizations"],
            ["Existing payment status", "existing_status"],
        ]) {
            if (payment[key] !== undefined && ["amount", "gross_amount", "amount_at_risk"].includes(key)) {
                lines.push(`| ${label} | ${estimatedMoney(payment[key])} |`);
            }
            else if (payment[key] !== undefined) {
                lines.push(`| ${label} | ${String(payment[key])} |`);
            }
        }
        const summary = Array.isArray(payment.summary) ? payment.summary.map(recordValue).filter((row) => Boolean(row)) : [];
        if (summary.length > 0 && !summaryView && detailPage) {
            const countySummary = countyPaymentSummary(summary);
            lines.push("", "County payment totals:", "The table below shows children served, care hours, and calculated payment by county.", "| County | Children served | Care hours | Calculated amount ($) | Conditional amount ($) |", "| --- | ---: | ---: | ---: | ---: |", ...countySummary.map((row) => `| ${tableValue(row.county_name)} | ${tableValue(row.children_served)} | ${tableValue(row.hours)} | ${estimatedMoney(row.amount)} | ${estimatedMoney(row.conditional_amount)} |`));
        }
        const overview = summaryView && recordValue(summaryView.overview);
        const categories = summaryRows(summaryView, "categories");
        const countyRollup = summaryRows(summaryView, "counties");
        const countyComposition = summaryRows(summaryView, "county_composition");
        const childRollup = summaryRows(summaryView, "children");
        const vacantSlots = summaryRows(summaryView, "vacant_slots");
        const nextActions = summaryRows(summaryView, "next_actions");
        if (overview && detailPage) {
            lines.push("", "Payment differences:", "| Paid days | Review items | Excluded days | Amount at risk | Vacant-slot amount |", "| ---: | ---: | ---: | ---: | ---: |", `| ${tableValue(overview.paid_days)} | ${tableValue(overview.review_items)} | ${tableValue(overview.excluded_days)} | ${estimatedMoney(overview.amount_at_risk)} | ${estimatedMoney(payment.vacant_slot_fee)} |`);
        }
        if (categories.length > 0 && detailPage) {
            lines.push("", "Payment by category:", "| Category | Days | Hours | Amount | Conditional | Excluded days |", "| --- | ---: | ---: | ---: | ---: | ---: |", ...categories.map((row) => `| ${tableValue(row.label)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${estimatedMoney(row.amount)} | ${estimatedMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (countyRollup.length > 0 && detailPage) {
            lines.push("", "County detail:", "| County | Days | Hours | Amount | Conditional | Excluded days |", "| --- | ---: | ---: | ---: | ---: | ---: |", ...countyRollup.map((row) => `| ${tableValue(row.label)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${estimatedMoney(row.amount)} | ${estimatedMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (countyComposition.length > 0 && !detailPage) {
            lines.push(...renderCountyComposition(countyComposition));
        }
        if (childRollup.length > 0 && detailPage) {
            lines.push("", "Child detail:", "| Child | Days | Hours | Amount | Conditional | Excluded days |", "| --- | ---: | ---: | ---: | ---: | ---: |", ...childRollup.map((row) => `| ${tableValue(row.label)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${estimatedMoney(row.amount)} | ${estimatedMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (vacantSlots.length > 0) {
            lines.push("", "Vacant slots (separate from child payments):", "| County | Service date | Classification | Amount |", "| --- | --- | --- | ---: |", ...vacantSlots.map((row) => `| ${tableValue(row.county_name)} | ${tableValue(row.service_date)} | ${tableValue(row.classification)} | ${estimatedMoney(row.amount)} |`));
        }
        if (nextActions.length > 0) {
            lines.push("", "Payment next actions:", ...nextActions.slice(0, 3).map((row) => `- ${tableValue(row.label)}: ${tableValue(row.reason)} (${estimatedMoney(row.amount_at_risk)} at risk)`));
        }
        if (attendance.length > 0) {
            const pageLabel = detailPagination
                ? `Showing detail rows ${((Number(detailPagination.page) - 1) * Number(detailPagination.pageSize)) + 1}-${Math.min(Number(detailPagination.page) * Number(detailPagination.pageSize), Number(detailPagination.totalRows))} of ${tableValue(detailPagination.totalRows)} (page ${tableValue(detailPagination.page)}; page size ${tableValue(detailPagination.pageSize)}).`
                : "";
            lines.push("", "Detail by child and service date:", ...(pageLabel ? [pageLabel] : []), "| Child | Authorization | County | Service date | Classification | Care hours | Conditional | Payment |", "| --- | --- | --- | --- | --- | --- | --- | --- |", ...attendance.map((day) => `| ${tableValue(day.child_name)} | ${tableValue(day.authorization_name)} | ${tableValue(day.county_name ?? "Unavailable from the current source")} | ${tableValue(day.service_date)} | ${tableValue(day.classification)} | ${tableValue(day.unit_hours)} | ${day.conditional === true ? "Yes" : "No"} | ${day.payment_excluded === true ? "Excluded" : "Included"} |`));
        }
        else if (detailPagination && Number(detailPagination.totalRows) > 0) {
            lines.push("", `Detail available: ${tableValue(detailPagination.totalRows)} child/date rows. Request a detail page to inspect them.`);
        }
    }
    const actionIntents = paymentActionMetadata(paymentResult, payment, detailPagination, status, Boolean(detailPage));
    const providerMessage = `${renderActionSections(lines.join("\n"), actionIntents)}\n\n${PAYMENT_DISCLAIMER}`;
    const providerSummary = Array.isArray(payment.summary)
        ? countyPaymentSummary(payment.summary.map(recordValue).filter((row) => Boolean(row))).map((row) => ({
            county: row.county_name,
            childrenServed: row.children_served,
            hours: row.hours,
            amount: row.amount,
            conditionalAmount: row.conditional_amount,
        }))
        : [];
    const providerServicePeriod = servicePeriod
        ? Object.fromEntries(Object.entries(servicePeriod).filter(([key]) => [
            "serviceBeginDate",
            "start_date",
            "serviceEndDate",
            "end_date",
            "paymentProcessingDate",
            "processing_date",
            "paymentReleaseDate",
            "release_date",
            "status",
            "service_period_status",
        ].includes(key)))
        : undefined;
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "payment-analysis",
            scope: paymentResult.scope,
            paymentView: paymentResult.paymentView,
            actionIntents,
            actionControls: actionControls(actionIntents),
            servicePeriod: providerServicePeriod,
            ruleVersion: paymentResult.rule_version,
            resultStatus: paymentResult.status,
            calculationMode: paymentResult.calculation_mode,
            sourceRetrievedAt: paymentResult.sourceRetrievedAt,
            sourceReadiness: paymentResult.source_readiness,
            summary: providerSummary,
            summaryView: compactPaymentSummaryView(summaryView),
            detailPagination,
            status,
            providerMessage,
            filters: paymentResult.filters,
            responseSections: ["summary", "next-actions", "drill-down", "available-views"],
            responseContext: {
                scope: paymentResult.scope,
                sourceRetrievedAt: paymentResult.sourceRetrievedAt,
                paymentView: paymentResult.paymentView,
                filters: paymentResult.filters,
                resultStatus: paymentResult.status,
            },
        },
    };
}
function toolError(capability, error) {
    const message = error instanceof Error ? error.message : "";
    const paymentFailure = capability === "payment analysis";
    const paymentDiagnostic = paymentFailure && message.length > 0
        ? message
            .replace(/[a-zA-Z0-9]{15,18}/g, "[redacted-id]")
            .slice(0, 240)
        : undefined;
    const filterFailure = message.startsWith("Requested ") && message.includes("filter did not match");
    const paymentSource = paymentFailure && message.includes("Service period")
        ? "service-period dates"
        : paymentFailure && message.includes("Authorization fiscal schedule mapping")
            ? "authorization-to-fiscal-schedule mapping"
            : paymentFailure && message.includes("County policy")
                ? "county-policy mapping"
                : paymentFailure && (message.includes("attendance") || message.includes("Schedules"))
                    ? "attendance-source mapping"
                    : paymentFailure && message.includes("Payment engine payload")
                        ? "payment-engine input mapping"
                        : paymentFailure && (message.includes("Fiscal") || message.includes("fiscal") || message.includes("rate"))
                            ? "fiscal-rate mapping"
                            : paymentFailure && message.includes("subPayments")
                                ? "existing payment-history rows"
                                : paymentFailure && (message.includes("slot") || message.includes("Slot"))
                                    ? "slot-contract mapping"
                                    : paymentFailure && message.includes("holiday")
                                        ? "holiday-payment mapping"
                                        : paymentFailure && (message.includes("age-band") || message.includes("encumbrance"))
                                            ? "authorization age-band or encumbrance mapping"
                                            : paymentFailure && (message.includes("parent_confirmation") || message.includes("confirmation"))
                                                ? "parent-confirmation attendance mapping"
                                                : undefined;
    const userMessage = filterFailure
        ? message
        : paymentFailure && paymentSource
            ? `The next payout could not be verified because ${paymentSource} is incomplete or ambiguous.`
            : paymentFailure
                ? "The next payout could not be verified because one or more approved payment-source mappings were rejected."
                : `The ${capability} could not be completed. No verified result was produced.`;
    const nextSteps = filterFailure
        ? ["Check the child, authorization, and date scope", "Retry with a verified name from the preceding result"]
        : paymentFailure
            ? [
                paymentSource
                    ? `Review the ${paymentSource} data for the selected service period`
                    : "Review the payment-source mappings for the selected service period",
                "Retry the next-payout view after the missing or ambiguous data is corrected",
            ]
            : ["Retry the same request once", "Review data quality if the problem continues"];
    return {
        isError: true,
        content: [
            {
                type: "text",
                text: JSON.stringify({
                    error: {
                        code: filterFailure ? "REQUEST_SCOPE_NOT_FOUND" : paymentFailure ? "PAYMENT_DATA_INCOMPLETE" : "PROVIDER_DATA_UNAVAILABLE",
                        capability,
                        message: userMessage,
                        nextSteps,
                        ...(paymentDiagnostic ? { diagnostic: paymentDiagnostic } : {}),
                    },
                }),
            },
        ],
    };
}
async function execute(capability, operation, formatResult = result) {
    try {
        return formatResult(await operation());
    }
    catch (error) {
        return toolError(capability, error);
    }
}
export function createServer(client, providerDisplayName, contextStore = new ConversationContextStore(), providerKey = providerDisplayName, dialogueStore = new DialogueStateStore()) {
    const server = new McpServer({
        name: "cccap-provider-api",
        version: "1.0.0",
    });
    server.registerTool("cccap_get_attendance_risk_snapshot", {
        title: "Get CCCAP Attendance Risk Snapshot",
        description: "Get a provider-scoped attendance risk snapshot for the requested date range. Use this for current-month, last-month, or explicit date-range snapshot requests; use cccap_analyze_attendance_risk for child-level follow-up details.",
        inputSchema: dateScopeSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("attendance-risk snapshot", () => getAttendanceRiskSnapshot(client, providerDisplayName, input, new Date().toISOString().slice(0, 10)), (data) => attachDialogueState(contextualize(snapshotResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_attendance_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined)));
    server.registerTool("cccap_get_current_month_risk_snapshot", {
        title: "Get Current-Month Payment Risk Snapshot",
        description: "Get the authenticated provider's current-month payment-risk snapshot with today's scheduled and checked-in child counts at the top. Use this read-only provider-scoped tool first for a provider greeting.",
        inputSchema: {},
        annotations: readOnlyAnnotations,
    }, async () => execute("current payment-risk snapshot", () => getCurrentMonthAttendanceSnapshot(client, providerDisplayName, new Date().toISOString().slice(0, 10)), (data) => attachDialogueState(contextualize(snapshotResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_attendance_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined)));
    server.registerTool("cccap_get_attendance_analysis", {
        title: "Get Attendance Transaction Diagnostics",
        description: "Retrieve low-level authenticated-provider schedule and transaction diagnostics, including data-quality blockers. Do not use for pending parent confirmations, absence risk, child drill-downs, or a numbered action after the provider snapshot; use cccap_analyze_attendance_risk for those provider-facing requests.",
        inputSchema: attendanceDataSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("attendance detail analysis", () => getAttendanceDataAnalysis(client, input)));
    server.registerTool("cccap_analyze_attendance_risk", {
        title: "Review Parent Confirmations and Attendance Risk",
        description: "Provider-facing tool for pending parent confirmations, numbered attendance actions after a snapshot, child drill-downs, attendance exceptions, and absence-limit risk. Returns a ready-to-relay response with next actions. The server retrieves only the requested scope and runs the deterministic Python evaluator.",
        inputSchema: attendanceAnalysisSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => {
        const hasContinuation = Boolean(input.contextRef || input.actionRef);
        const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "contextRef" && key !== "actionRef" && key !== "refresh"));
        const continuation = contextStore.resolve(providerKey, input.contextRef, input.actionRef, "continuation", undefined, Object.keys(directContinuationInput).length > 0 ? directContinuationInput : undefined);
        const request = continuation?.tool === "cccap_analyze_attendance_risk"
            ? continuation.input
            : input;
        if (hasContinuation && (!continuation || continuation.tool !== "cccap_analyze_attendance_risk")) {
            return toolError("attendance-risk analysis", new Error("Continuation reference is unavailable or expired"));
        }
        if (input.refresh)
            client.clearReadCache();
        if (!input.refresh && continuation?.resultTool === "cccap_analyze_attendance_risk" && continuation.result) {
            const cachedResult = recordValue(continuation.result);
            if (cachedResult) {
                const continuationResult = { ...cachedResult, scope: request, riskFocus: request.riskFocus, countyNames: request.countyNames };
                return attachDialogueState(contextualize(formatAttendanceRiskResult(continuationResult), contextStore, providerKey, "continuation", continuationResult, "cccap_analyze_attendance_risk"), dialogueStore, providerKey, "attendance-risk-analysis", request, typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined);
            }
        }
        return execute("attendance-risk analysis", () => getAttendanceRiskAnalysis(client, providerDisplayName, request, new Date().toISOString().slice(0, 10), request.childNames, request.authNames, request.riskFocus, request.countyNames), (data) => attachDialogueState(contextualize(formatAttendanceRiskResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_attendance_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
    });
    server.registerTool("cccap_initialize_provider", {
        title: "Initialize CCCAP Provider",
        description: "Start here. Resolve the configured provider user to one authorized facility, active provider IDs, fiscal agreements, counties, rate schedules, and closures for the requested date scope. The server injects the provider user ID; never ask the model or provider to supply it.",
        inputSchema: dateScopeSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("provider initialization", async () => normalizeProviderInitialization(await client.initialize(input))));
    server.registerTool("cccap_get_cases", {
        title: "Get CCCAP Cases and Children",
        description: "After initialization, retrieve active cases and related children for the authenticated provider. Omit countyIds for all authorized counties or pass only county IDs returned by initialization.",
        inputSchema: caseSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("cases and children retrieval", async () => normalizeCases(await client.getCases(input)), (data) => formatCasesResult(data, (countyId) => client.getCountyName(countyId))));
    server.registerTool("cccap_get_authorizations", {
        title: "Get CCCAP Authorizations",
        description: "After initialization, retrieve active child authorizations for the authenticated provider. Filter by case IDs, authorized counties, or authorization names only when needed for the provider's question.",
        inputSchema: authorizationSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("authorizations retrieval", async () => normalizeAuthorizations(await client.getAuthorizations(input)), (data) => formatAuthorizationsResult(data, (countyId) => client.getCountyName(countyId))));
    server.registerTool("cccap_get_county_rate_plans", {
        title: "Get CCCAP County Rate Plans",
        description: "Retrieve effective county rate plans and provider-facing absence-day limits for the authorized provider counties. For a current policy question, use dateFilter THIS_MONTH when available so this read reuses the current-month snapshot cache. The server initializes provider scope internally when needed.",
        inputSchema: countySchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => {
        const scope = input.dateFilter || input.dateFrom || input.dateTo
            ? input
            : { ...input, dateFilter: "THIS_MONTH" };
        return execute("county policy retrieval", async () => {
            await client.initialize(scope);
            return normalizeCountyPlans(await client.getCountyData(scope));
        }, formatCountyPolicyResult);
    });
    server.registerTool("cccap_get_service_periods", {
        title: "Get CCCAP Service Periods",
        description: "Retrieve stored or computed service periods and payment processing/release dates. Use dateOn TODAY for the current service period, paymentAfter TODAY with limitOne for the next payout, or a dateFilter for a range.",
        inputSchema: servicePeriodSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("service-period retrieval", async () => normalizeServicePeriods(await client.getServicePeriods(input))));
    server.registerTool("cccap_get_schedules", {
        title: "Get CCCAP Schedules and Attendance",
        description: "After initialization, retrieve schedules and check-in/check-out attendance transactions for the authenticated provider and date range. Use authorization names only to narrow an already authorized provider scope.",
        inputSchema: schedulesSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("schedule and attendance retrieval", async () => normalizeSchedules(await client.getSchedules(input))));
    server.registerTool("cccap_get_fiscal_rates", {
        title: "Get CCCAP Fiscal Rates",
        description: "After initialization, retrieve fiscal schedules, provider/county/agreement rate rows, and fiscal rate fees for the authenticated provider. The server supplies only rate-schedule IDs returned by provider initialization.",
        inputSchema: fiscalRatesSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("fiscal-rate retrieval", async () => normalizeFiscalRates(await client.getFiscalRates(input))));
    server.registerTool("cccap_get_holidays", {
        title: "Get CCCAP Holidays",
        description: "Retrieve holiday and observed-holiday dates, optionally within a date scope. Combine only with an effective county rate plan that allows paid holidays.",
        inputSchema: dateScopeSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("holiday-calendar retrieval", async () => normalizeHolidays(await client.getHolidayList(input))));
    server.registerTool("cccap_analyze_payment", {
        title: "Analyze CCCAP Payment",
        description: "Retrieve provider-scoped read-only CCCAP inputs and run the deterministic payment engine. Returns expected, conditional, duplicate-guard, or blocked results without performing payment actions.",
        inputSchema: paymentAnalysisSchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => {
        const hasContinuation = Boolean(input.contextRef || input.actionRef);
        const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "contextRef" && key !== "actionRef" && key !== "refresh"));
        const continuation = contextStore.resolve(providerKey, input.contextRef, input.actionRef, "continuation", undefined, Object.keys(directContinuationInput).length > 0 ? directContinuationInput : undefined);
        const request = continuation?.tool === "cccap_analyze_payment"
            ? continuation.input
            : input;
        if (hasContinuation && (!continuation || continuation.tool !== "cccap_analyze_payment")) {
            return toolError("payment analysis", new Error("Continuation reference is unavailable or expired"));
        }
        if (input.refresh)
            client.clearReadCache();
        const requestsDetailPage = request.detailPage !== undefined || request.detailPageSize !== undefined;
        if (!input.refresh && !requestsDetailPage && continuation?.resultTool === "cccap_analyze_payment" && continuation.result) {
            const cachedResult = recordValue(continuation.result);
            if (cachedResult) {
                const continuationResult = { ...cachedResult, filters: request };
                return attachDialogueState(contextualize(formatPaymentResult(continuationResult), contextStore, providerKey, "continuation", continuationResult, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(cachedResult.scope) ?? request, typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined);
            }
        }
        const runPaymentAnalysis = () => execute("payment analysis", () => getPaymentAnalysis(client, request, request.view, undefined, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
            ...(request.detailPage ? { detailPage: request.detailPage } : {}),
            ...(request.detailPageSize ? { detailPageSize: request.detailPageSize } : {}),
        }), (data) => attachDialogueState(contextualize(formatPaymentResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        const paymentResult = await runPaymentAnalysis();
        if (paymentResult.isError && !hasContinuation && !input.refresh) {
            client.clearReadCache();
            return runPaymentAnalysis();
        }
        return paymentResult;
    });
    server.registerTool("cccap_get_payment_history", {
        title: "Get CCCAP Payment History",
        description: "After initialization, retrieve read-only sub-payment history for the authenticated provider and the requested service-period date scope. The server resolves the date scope to overlapping service periods before querying payments, so use this to detect existing paid or requested payments before any future payout calculation.",
        inputSchema: paymentHistorySchema.shape,
        annotations: readOnlyAnnotations,
    }, async (input) => execute("payment-history retrieval", async () => normalizePaymentHistory(await client.getPaymentHistory(input))));
    return server;
}
function careUnitLabel(value) {
    switch (value) {
        case "PART_TIME": return "Part-time care";
        case "FULL_TIME": return "Full-time care";
        case "FULL_TIME_PLUS_PART_TIME": return "Full-time + part-time care";
        case "FULL_TIME_PLUS_FULL_TIME": return "Full-time + full-time care";
        case "NO_PAYMENT": return "No payable care unit";
        default: return tableValue(value);
    }
}
