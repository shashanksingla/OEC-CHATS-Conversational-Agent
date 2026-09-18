import { McpServer } from "@modelcontextprotocol/server";
import * as z from "zod/v4";
import { getAttendanceRiskAnalysis, getAttendanceRiskSnapshot, getCurrentMonthAttendanceSnapshot, } from "./attendance/attendance.js";
import { comparePaymentPeriods, getLastPayoutDetail, getPaymentAnalysis, getServicePeriodLedger, getUpcomingPayoutDetail } from "./payment/payment-orchestration.js";
import { ConversationContextStore, additiveRefinementsOnly, cacheKeyFor, scopeGranularity, DialogueStateStore, conversationLogger as defaultConversationLogger } from "./shared/conversation.js";
import { normalizeAuthorizations, normalizeCases, normalizeCountyPlans, normalizeFiscalRates, normalizeHolidays, normalizePaymentHistory, normalizeProviderInitialization, normalizeSchedules, normalizeServicePeriods, } from "./shared/normalizers.js";
import { authorizationSchema, attendanceAnalysisSchema, caseSchema, countySchema, dateScopeSchema, fiscalRatesSchema, paymentHistorySchema, paymentAnalysisSchema, paymentComparisonSchema, schedulesSchema, servicePeriodSchema, } from "./schemas.js";
import { formatScopeClarification, orderedActionList, readOnlyAnnotations, recordValue, result, } from './shared/formatters/shared.js';
import { formatCasesResult, formatAuthorizationsResult, formatCountyPolicyResult } from './shared/formatters/reference-data-formatter.js';
import { formatAttendanceResult } from './attendance/attendance-formatter.js';
import { formatPayoutResult } from './payment/payment-formatter.js';
import { formatPeriodComparisonResult } from './payment/comparison-formatter.js';
// Best-effort lookup of the OTHER capability's last cached result for this provider/scope, so
// action ranking can see both capabilities together without a new fetch. Absence (cache miss,
// wrong tool, or missing field) is not an error - ranking simply falls back to single-capability scoring.
function siblingCanonicalFacts(store, providerKey, siblingTool, scope, factsField) {
    const cached = store.getCachedResult(cacheKeyFor(providerKey, siblingTool, scope), providerKey);
    if (!cached || cached.resultTool !== siblingTool)
        return undefined;
    return recordValue(cached.result)?.[factsField];
}
export { formatAttendanceResult } from './attendance/attendance-formatter.js';
export { formatPayoutResult } from './payment/payment-formatter.js';
export { formatCasesResult, formatAuthorizationsResult, formatCountyPolicyResult } from './shared/formatters/reference-data-formatter.js';
function contextualize(value, store, providerKey, capability, result, resultTool) {
    if (value.isError || !value.structuredContent)
        return value;
    const providerMessage = value.content.find((item) => item.type === "text" && typeof item.text === "string" && item.text.trim().length > 0)?.text;
    const structuredContentBase = providerMessage && typeof value.structuredContent.providerMessage !== "string"
        ? { ...value.structuredContent, providerMessage }
        : value.structuredContent;
    const contextualizedValue = { ...value, structuredContent: structuredContentBase };
    const actions = Array.isArray(structuredContentBase.actionIntents)
        ? structuredContentBase.actionIntents.map(recordValue).filter((action) => Boolean(action))
        : Array.isArray(structuredContentBase.actionControls)
            ? structuredContentBase.actionControls.map(recordValue).filter((action) => Boolean(action))
            : [];
    if (actions.length === 0)
        return contextualizedValue;
    const hasPlanActions = actions.some((action) => {
        const input = recordValue(action.input);
        return Boolean(input) && (action.tool === "cccap_analyze_payment_risk" || action.tool === "cccap_analyze_payment");
    });
    if (!hasPlanActions)
        return contextualizedValue;
    const currentCapability = typeof structuredContentBase.capability === "string"
        ? structuredContentBase.capability
        : undefined;
    const ruleVersion = typeof structuredContentBase.ruleVersion === "string"
        ? structuredContentBase.ruleVersion
        : undefined;
    const viewState = recordValue(structuredContentBase.viewState);
    const situation = recordValue(structuredContentBase.situation);
    const resultRecord = recordValue(result);
    // Cache by stable date scope so returning to an unscoped view can reuse results; misses only trigger deterministic re-evaluation.
    const scopeForCacheKey = recordValue(structuredContentBase.scope) ?? recordValue(viewState?.scope) ?? {};
    const cacheKey = cacheKeyFor(providerKey, resultTool, scopeForCacheKey);
    store.cacheResult(cacheKey, providerKey, capability, result, resultTool, ruleVersion);
    // Continuation validity uses a short opaque, persisted action reference so tokens survive restarts without exposing request data.
    const actionControls = orderedActionList(actions).map((action) => {
        const input = recordValue(action.input);
        if (!input || (action.tool !== "cccap_analyze_payment_risk" && action.tool !== "cccap_analyze_payment"))
            return action;
        const actionToken = store.createActionToken(providerKey, action.tool, input, ruleVersion);
        return {
            type: "button",
            actionId: action.actionId,
            label: action.label,
            ...(action.reason ? { reason: action.reason } : {}),
            ...(action.priority ? { priority: action.priority } : {}),
            section: action.section,
            capability: action.capability,
            tool: action.tool,
            ...(action.sourceViewId ? { sourceViewId: action.sourceViewId } : {}),
            ...(action.targetViewId ? { targetViewId: action.targetViewId } : {}),
            ...(action.lockedView ? { lockedView: action.lockedView } : {}),
            input: { actionId: action.actionId, actionToken },
        };
    });
    const graph = {
        ...(typeof structuredContentBase.intent === "string"
            ? { currentIntent: structuredContentBase.intent }
            : { currentIntent: currentCapability ?? capability }),
        ...(structuredContentBase.scope !== undefined
            ? { scope: structuredContentBase.scope }
            : viewState?.scope !== undefined ? { scope: viewState.scope } : {}),
        ...(resultRecord?.servicePeriod !== undefined ? { selectedServicePeriod: resultRecord.servicePeriod } : {}),
        ...(viewState?.parentViewId !== undefined ? { parentView: viewState.parentViewId } : {}),
        // Keep a bounded current-view pointer for hosts that render navigation from resultGraph.
        ...(Array.isArray(structuredContentBase.responseSections)
            ? { availableEvidence: structuredContentBase.responseSections.filter((section) => typeof section === "string") }
            : {}),
        ...(typeof situation?.severity === "string" ? { severity: situation.severity } : {}),
        ...(typeof structuredContentBase.sourceRetrievedAt === "string"
            ? { sourceRetrievedAt: structuredContentBase.sourceRetrievedAt }
            : {}),
        ...(viewState ? { currentView: viewState } : {}),
        ...(ruleVersion ? { ruleVersion } : {}),
    };
    const isPaymentCapability = currentCapability === "payment-analysis"
        || currentCapability === "service-period-payout-ledger";
    const { actionIntents: _actionIntents, filters: _filters, responseContext: _responseContext, providerMessage: _providerMessage, summary: _summary, summaryView: _summaryView, periods: _periods, selectedPeriod: _selectedPeriod, daysUntilPayout: _daysUntilPayout, paymentDisclaimers: _paymentDisclaimers, responseSections: _responseSections, ...structuredContentWithoutRouting } = structuredContentBase;
    // Preserve providerMessage as the structured-content fallback for every capability, including payment results.
    const structuredContent = isPaymentCapability
        ? {
            ...structuredContentWithoutRouting,
            ...(_providerMessage !== undefined ? { providerMessage: _providerMessage } : {}),
        }
        : {
            ...structuredContentWithoutRouting,
            ...(_summary !== undefined ? { summary: _summary } : {}),
            ...(_summaryView !== undefined ? { summaryView: _summaryView } : {}),
            ...(_providerMessage !== undefined ? { providerMessage: _providerMessage } : {}),
        };
    return {
        ...contextualizedValue,
        structuredContent: {
            ...structuredContent,
            resultGraph: graph,
            actionControls,
        },
    };
}
/** Attach server-computed dialogue-state changes so turn classification does not rely on transcript inference. */
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
function toolError(capability, error) {
    const message = error instanceof Error ? error.message : "";
    // Treat all payout-ledger views like payment analysis so failures retain payment-specific diagnostics.
    const paymentFailure = capability === "payment analysis" || capability === "payment payout ledger";
    const paymentDiagnostic = paymentFailure && message.length > 0
        ? message
            .replace(/[a-zA-Z0-9]{15,18}/g, "[redacted-id]")
            .slice(0, 240)
        : undefined;
    const continuationFailure = message === "Continuation reference is unavailable or expired";
    const filterFailure = message.startsWith("Requested ") && message.includes("filter did not match");
    // Map specific fiscal-schedule-match reasons before the generic mapping error for actionable diagnostics.
    const fiscalMatchSource = !paymentFailure ? undefined
        : message.includes("reason=NO_MATCH_COUNTY")
            ? "no fiscal rate schedule exists for this authorization's county"
            : message.includes("reason=NO_MATCH_RATE_TYPE")
                ? "this authorization's rate type has no matching fiscal schedule in its county"
                : message.includes("reason=NO_MATCH_DATE")
                    ? "no fiscal schedule covers this authorization's service dates for its county/rate type"
                    : message.includes("reason=AMBIGUOUS_MATCH")
                        ? "multiple equally-current fiscal schedules matched for this authorization (ambiguous)"
                        : message.includes("reason=MISSING_SCHEDULE_RATE_TYPE")
                            ? "the schedule's rate type could not be determined"
                            : undefined;
    const paymentSource = fiscalMatchSource
        ? fiscalMatchSource
        : paymentFailure && message.includes("Service period")
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
                                : paymentFailure && (message.includes("subPayments") || message.includes("payment history") || message.includes("Payment history"))
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
    // Use a capability-neutral payment error because requests may target forecasts, status, or custom ranges.
    const userMessage = continuationFailure
        ? "The selected action could not be resumed because its conversation state is unavailable or expired."
        : filterFailure
            ? message
            : paymentFailure && paymentSource
                ? `This payment view could not be verified because ${paymentSource} is incomplete or ambiguous. This is a data-source condition, not a request error.`
                : paymentFailure
                    ? "This payment view could not be verified because one or more approved payment-source mappings were rejected. This is a data-source condition, not a request error."
                    : `The ${capability} could not be completed. No verified result was produced.`;
    const nextSteps = continuationFailure
        ? ["Retry the same selected action once using the current action control", "If it still fails, restate the requested review so a fresh result can be created"]
        : filterFailure
            ? ["Check the child, authorization, and date scope", "Retry with a verified name from the preceding result"]
            : paymentFailure
                ? [
                    paymentSource
                        ? `Review the ${paymentSource} data for the selected service period`
                        : "Review the payment-source mappings for the selected service period",
                    "Retry the next-payout view after the missing or ambiguous data is corrected",
                ]
                : ["Retry the same request once", "Review data quality if the problem continues"];
    const errorCode = continuationFailure
        ? "CONTINUATION_UNAVAILABLE"
        : filterFailure
            ? "REQUEST_SCOPE_NOT_FOUND"
            : paymentFailure
                ? "PAYMENT_DATA_INCOMPLETE"
                : "PROVIDER_DATA_UNAVAILABLE";
    const errorPayload = {
        code: errorCode,
        capability,
        message: userMessage,
        nextSteps,
        ...(paymentDiagnostic ? { diagnostic: paymentDiagnostic } : {}),
    };
    return {
        isError: true,
        content: [
            {
                type: "text",
                text: JSON.stringify({ error: errorPayload }),
            },
        ],
        // Mirror the error payload in structuredContent so clients need not parse content[0].text.
        structuredContent: {
            error: errorPayload,
        },
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
export function createServer(client, providerDisplayName, contextStore = new ConversationContextStore(), providerKey = providerDisplayName, dialogueStore = new DialogueStateStore(), conversationLogger = defaultConversationLogger) {
    const withConversationLogging = (toolName, handler) => async (input) => {
        // Strip debug-only providerUtterance before handlers run so it cannot reach integrations or responses.
        const { providerUtterance, ...handlerInput } = input;
        const startedAt = Date.now();
        const result = await handler(handlerInput);
        const providerResponseText = result.content?.find((item) => item.type === "text")?.text;
        let error;
        if (result.isError) {
            const structuredError = recordValue(recordValue(result.structuredContent)?.error);
            if (structuredError && typeof structuredError.code === "string" && typeof structuredError.message === "string") {
                error = {
                    code: structuredError.code,
                    message: structuredError.message,
                    ...(typeof structuredError.diagnostic === "string" ? { diagnostic: structuredError.diagnostic } : {}),
                };
            }
            else if (typeof providerResponseText === "string") {
                try {
                    const parsed = recordValue(recordValue(JSON.parse(providerResponseText))?.error);
                    if (parsed && typeof parsed.code === "string" && typeof parsed.message === "string") {
                        error = {
                            code: parsed.code,
                            message: parsed.message,
                            ...(typeof parsed.diagnostic === "string" ? { diagnostic: parsed.diagnostic } : {}),
                        };
                    }
                }
                catch {
                }
            }
        }
        conversationLogger.logToolCall({
            tool: toolName,
            // Log sanitized handlerInput; providerUtterance is logged separately and never reintroduced into input.
            input: handlerInput,
            status: result.isError ? "error" : "success",
            durationMs: Date.now() - startedAt,
            ...(typeof providerUtterance === "string" ? { providerUtterance } : {}),
            ...(typeof providerResponseText === "string" ? { providerResponseText } : {}),
            ...(error ? { error } : {}),
        });
        return result;
    };
    conversationLogger.startSession(providerKey);
    const server = new McpServer({
        name: "cccap-provider-api",
        version: "1.0.0",
    });
    server.registerTool("cccap_get_attendance_risk_snapshot", {
        title: "Get CCCAP Attendance Risk Snapshot",
        description: "Get a provider-scoped attendance risk snapshot for the requested date range. Use this for current-month, last-month, or explicit date-range snapshot requests; use cccap_analyze_payment_risk for child-level follow-up details.",
        inputSchema: dateScopeSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_attendance_risk_snapshot", async (input) => execute("attendance-risk snapshot", () => getAttendanceRiskSnapshot(client, providerDisplayName, input, new Date().toISOString().slice(0, 10)), (data) => attachDialogueState(contextualize(formatAttendanceResult(data, true), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined))));
    server.registerTool("cccap_get_current_month_risk_snapshot", {
        title: "Get Current-Month Payment Risk Snapshot",
        description: "Get the authenticated provider's current-month payment-risk snapshot with today's scheduled and checked-in child counts at the top. Use this read-only provider-scoped tool first for a provider greeting.",
        inputSchema: {},
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_current_month_risk_snapshot", async () => execute("current payment-risk snapshot", () => getCurrentMonthAttendanceSnapshot(client, providerDisplayName, new Date().toISOString().slice(0, 10)), (data) => {
        // Record the month-wide snapshot scope so later narrowed risk requests trigger clarification instead of reuse.
        contextStore.setLastSnapshotScope(providerKey, { dateFilter: "THIS_MONTH" });
        return attachDialogueState(contextualize(formatAttendanceResult(data, true), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined);
    })));
    server.registerTool("cccap_analyze_payment_risk", {
        title: "Review Parent Confirmations and Attendance Risk",
        description: "Provider-facing tool for pending parent confirmations, numbered attendance actions after a snapshot, child drill-downs, attendance exceptions, and absence-limit risk. Returns a ready-to-relay response with next actions. The server retrieves only the requested scope and runs the deterministic Python evaluator.",
        inputSchema: attendanceAnalysisSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_analyze_payment_risk", async (input) => {
        const hasContinuation = Boolean(input.actionId || input.actionToken);
        // Resolve the persisted opaque action reference; resolution enforces provider/tool binding and TTL.
        const resolvedAction = contextStore.resolveActionToken(input.actionToken, providerKey, "cccap_analyze_payment_risk");
        if (hasContinuation && !resolvedAction) {
            return toolError("attendance-risk analysis", new Error("Continuation reference is unavailable or expired"));
        }
        // A resolved action token's stored input is authoritative; merge only additive pagination refinements to reject stale echoed fields.
        const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "actionId" && key !== "actionToken" && key !== "refresh"));
        const request = (resolvedAction
            ? { ...resolvedAction.input, ...additiveRefinementsOnly(directContinuationInput) }
            : input);
        // Clarify freeform risk requests that drift from a month snapshot to a narrower period instead of guessing scope.
        if (!hasContinuation && request.riskFocus) {
            const lastSnapshotScope = contextStore.getLastSnapshotScope(providerKey);
            if (lastSnapshotScope && scopeGranularity(lastSnapshotScope) === "MONTH" && scopeGranularity(request) === "PERIOD") {
                // Bias the clarification order toward the scope most recently active in dialogue state.
                const lastActiveScope = dialogueStore.getLastScope(providerKey);
                const biasHint = lastActiveScope && scopeGranularity(lastActiveScope) === "PERIOD" ? "PERIOD" : "MONTH";
                return formatScopeClarification(request.riskFocus, { dateFrom: request.dateFrom, dateTo: request.dateTo }, biasHint);
            }
        }
        if (input.refresh)
            client.clearReadCache();
        const isNarrowedAttendanceContinuation = Boolean(request.childNames?.length ||
            request.authNames?.length ||
            request.countyNames?.length ||
            request.riskFocus);
        // Cache by stable date scope so returning unscoped can reuse results; misses fall through to fresh evaluation.
        const cacheKey = cacheKeyFor(providerKey, "cccap_analyze_payment_risk", request);
        const cached = !input.refresh && !isNarrowedAttendanceContinuation
            ? contextStore.getCachedResult(cacheKey, providerKey)
            : undefined;
        if (cached && cached.resultTool === "cccap_analyze_payment_risk") {
            const cachedResult = recordValue(cached.result);
            if (cachedResult) {
                const continuationResult = { ...cachedResult, scope: request, riskFocus: request.riskFocus, countyNames: request.countyNames, detailPage: request.detailPage, detailPageSize: request.detailPageSize };
                return attachDialogueState(contextualize(formatAttendanceResult(continuationResult, true), contextStore, providerKey, "continuation", continuationResult, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", request, typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined);
            }
        }
        const siblingPaymentFacts = siblingCanonicalFacts(contextStore, providerKey, "cccap_analyze_payment", request, "payment");
        // Recent-state loop guard (multi-hop): record this request's signature BEFORE the response
        // renders, and pass the provider's recent signatures into the formatter so a candidate action
        // that would just recreate a screen shown 1-2 turns ago (not just the current one) is dropped.
        const recentAttendanceSignatures = [...contextStore.recentActionSignatures(providerKey)];
        contextStore.recordRenderedState(providerKey, "cccap_analyze_payment_risk", request);
        return execute("attendance-risk analysis", () => getAttendanceRiskAnalysis(client, providerDisplayName, request, new Date().toISOString().slice(0, 10), request.childNames, request.authNames, request.riskFocus, request.countyNames, request.detailPage, request.detailPageSize), (data) => attachDialogueState(contextualize(formatAttendanceResult({ ...recordValue(data), recentActionSignatures: recentAttendanceSignatures }, true), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
    }));
    server.registerTool("cccap_initialize_provider", {
        title: "Initialize CCCAP Provider",
        description: "Start here. Resolve the configured provider user to one authorized facility, active provider IDs, fiscal agreements, counties, rate schedules, and closures for the requested date scope. The server injects the provider user ID; never ask the model or provider to supply it.",
        inputSchema: dateScopeSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_initialize_provider", async (input) => execute("provider initialization", async () => normalizeProviderInitialization(await client.initialize(input)))));
    server.registerTool("cccap_get_cases", {
        title: "Get CCCAP Cases and Children",
        description: "After initialization, retrieve active cases and related children for the authenticated provider. Omit countyIds for all authorized counties or pass only county IDs returned by initialization.",
        inputSchema: caseSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_cases", async (input) => execute("cases and children retrieval", async () => normalizeCases(await client.getCases(input)), (data) => formatCasesResult(data, (countyId) => client.getCountyName(countyId)))));
    server.registerTool("cccap_get_authorizations", {
        title: "Get CCCAP Authorizations",
        description: "After initialization, retrieve active child authorizations for the authenticated provider. Filter by case IDs, authorized counties, or authorization names only when needed for the provider's question.",
        inputSchema: authorizationSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_authorizations", async (input) => execute("authorizations retrieval", async () => normalizeAuthorizations(await client.getAuthorizations(input)), (data) => formatAuthorizationsResult(data, (countyId) => client.getCountyName(countyId)))));
    server.registerTool("cccap_get_county_rate_plans", {
        title: "Get CCCAP County Rate Plans",
        description: "Retrieve effective county rate plans and provider-facing absence-day limits for the authorized provider counties. For a current policy question, use dateFilter THIS_MONTH when available so this read reuses the current-month snapshot cache. The server initializes provider scope internally when needed.",
        inputSchema: countySchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_county_rate_plans", async (input) => {
        const scope = input.dateFilter || input.dateFrom || input.dateTo
            ? input
            : { ...input, dateFilter: "THIS_MONTH" };
        return execute("county policy retrieval", async () => {
            await client.initialize(scope);
            return normalizeCountyPlans(await client.getCountyData(scope));
        }, formatCountyPolicyResult);
    }));
    server.registerTool("cccap_get_service_periods", {
        title: "Get CCCAP Service Periods",
        description: "Retrieve stored or computed service periods and payment processing/release dates. Use dateOn TODAY for the current service period, paymentAfter TODAY with limitOne for the next payout, or a dateFilter for a range.",
        inputSchema: servicePeriodSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_service_periods", async (input) => execute("service-period retrieval", async () => normalizeServicePeriods(await client.getServicePeriods(input)))));
    server.registerTool("cccap_get_schedules", {
        title: "Get CCCAP Schedules and Attendance",
        description: "After initialization, retrieve schedules and check-in/check-out attendance transactions for the authenticated provider and date range. Use authorization names only to narrow an already authorized provider scope.",
        inputSchema: schedulesSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_schedules", async (input) => execute("schedule and attendance retrieval", async () => normalizeSchedules(await client.getSchedules(input)))));
    server.registerTool("cccap_get_fiscal_rates", {
        title: "Get CCCAP Fiscal Rates",
        description: "After initialization, retrieve fiscal schedules, provider/county/agreement rate rows, and fiscal rate fees for the authenticated provider. The server supplies only rate-schedule IDs returned by provider initialization.",
        inputSchema: fiscalRatesSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_fiscal_rates", async (input) => execute("fiscal-rate retrieval", async () => normalizeFiscalRates(await client.getFiscalRates(input)))));
    server.registerTool("cccap_get_holidays", {
        title: "Get CCCAP Holidays",
        description: "Retrieve holiday and observed-holiday dates, optionally within a date scope. Combine only with an effective county rate plan that allows paid holidays.",
        inputSchema: dateScopeSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_holidays", async (input) => execute("holiday-calendar retrieval", async () => normalizeHolidays(await client.getHolidayList(input)))));
    server.registerTool("cccap_analyze_payment", {
        title: "Analyze CCCAP Payment",
        description: "Retrieve provider-scoped read-only CCCAP inputs and run the deterministic payment engine. Returns expected, conditional, duplicate-guard, or blocked results without performing payment actions.",
        inputSchema: paymentAnalysisSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_analyze_payment", async (input) => {
        const hasContinuation = Boolean(input.actionId || input.actionToken);
        // Resolve the persisted opaque action reference; see the risk-analysis continuation rules above.
        const resolvedAction = contextStore.resolveActionToken(input.actionToken, providerKey, "cccap_analyze_payment");
        if (hasContinuation && !resolvedAction) {
            return toolError("payment analysis", new Error("Continuation reference is unavailable or expired"));
        }
        // A resolved action token's stored input is authoritative; merge only additive pagination refinements.
        const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "actionId" && key !== "actionToken" && key !== "refresh"));
        const resolvedRequest = (resolvedAction
            ? { ...resolvedAction.input, ...additiveRefinementsOnly(directContinuationInput) }
            : input);
        // Normalize the accepted CURRENT_PERIOD_FORECAST alias once so downstream code uses CURRENT_WEEK_FORECAST consistently.
        const normalizedView = resolvedRequest.view === "CURRENT_PERIOD_FORECAST" ? "CURRENT_WEEK_FORECAST" : resolvedRequest.view;
        const request = { ...resolvedRequest, view: normalizedView };
        if (input.refresh)
            client.clearReadCache();
        // Recent-state loop guard (multi-hop) - see the matching comment on the attendance-risk handler above.
        const recentPaymentSignatures = [...contextStore.recentActionSignatures(providerKey)];
        contextStore.recordRenderedState(providerKey, "cccap_analyze_payment", request);
        // All payout views use the ledger formatter, keeping cached continuation and routing behavior consistent.
        const usesLedgerFormatter = request.view === "NEXT_PAYOUT" || request.view === "LAST_PAYOUT" || request.view === "PAYOUT_LEDGER";
        // Reuse stable cached results when available; cache misses trigger fresh evaluation, never an error.
        const cacheKey = cacheKeyFor(providerKey, "cccap_analyze_payment", request);
        const cached = !input.refresh
            ? contextStore.getCachedResult(cacheKey, providerKey)
            : undefined;
        if (cached && cached.resultTool === "cccap_analyze_payment") {
            const cachedResult = recordValue(cached.result);
            if (cachedResult) {
                const continuationResult = { ...cachedResult, filters: request };
                return attachDialogueState(contextualize(formatPayoutResult(continuationResult), contextStore, providerKey, "continuation", continuationResult, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(cachedResult.scope) ?? request, typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined);
            }
        }
        // Keep NEXT_PAYOUT and LAST_PAYOUT single-period; only explicit PAYOUT_LEDGER requests return multiple periods.
        const asOfDateForLedger = new Date().toISOString().slice(0, 10);
        const runNextPayout = () => execute("payment payout ledger", () => getUpcomingPayoutDetail(client, request, asOfDateForLedger, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
        }), (data) => attachDialogueState(contextualize(formatPayoutResult({ ...recordValue(data), recentActionSignatures: recentPaymentSignatures }), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope ?? request, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        const runLastPayout = () => execute("payment payout ledger", () => getLastPayoutDetail(client, request, asOfDateForLedger, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
        }), (data) => attachDialogueState(contextualize(formatPayoutResult({ ...recordValue(data), recentActionSignatures: recentPaymentSignatures }), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope ?? request, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        const runPayoutLedger = () => execute("payment payout ledger", () => getServicePeriodLedger(client, request, asOfDateForLedger, {
            ...(request.periodCount ? { periodCount: request.periodCount } : {}),
            filters: {
                ...(request.childNames ? { childNames: request.childNames } : {}),
                ...(request.authNames ? { authNames: request.authNames } : {}),
                ...(request.countyNames ? { countyNames: request.countyNames } : {}),
            },
        }), (data) => attachDialogueState(contextualize(formatPayoutResult({ ...recordValue(data), recentActionSignatures: recentPaymentSignatures }), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope ?? request, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        if (request.view === "NEXT_PAYOUT") {
            return runNextPayout();
        }
        if (request.view === "LAST_PAYOUT") {
            return runLastPayout();
        }
        if (request.view === "PAYOUT_LEDGER") {
            return runPayoutLedger();
        }
        const siblingAttendanceFacts = siblingCanonicalFacts(contextStore, providerKey, "cccap_analyze_payment_risk", request, "attendanceRisk");
        const runPaymentAnalysis = () => execute("payment analysis", () => getPaymentAnalysis(client, request, request.view, undefined, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
        }, siblingAttendanceFacts), (data) => attachDialogueState(contextualize(formatPayoutResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        const paymentResult = await runPaymentAnalysis();
        if (paymentResult.isError && !hasContinuation && !input.refresh) {
            client.clearReadCache();
            return runPaymentAnalysis();
        }
        return paymentResult;
    }));
    server.registerTool("cccap_compare_payment_periods", {
        title: "Compare CCCAP Payment Periods",
        description: "Read-only genuine period-over-period payment comparison with category and county deltas; distinct from single-period payment analysis.",
        inputSchema: paymentComparisonSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_compare_payment_periods", async (input) => execute("payment comparison", () => comparePaymentPeriods(client, input.periodOne, input.periodTwo, new Date().toISOString().slice(0, 10), input.significantDeltaThresholdPct === undefined ? {} : { significantDeltaThresholdPct: input.significantDeltaThresholdPct }), formatPeriodComparisonResult)));
    server.registerTool("cccap_get_service_period_payout_ledger", {
        title: "Get CCCAP Service-Period Payout Ledger",
        description: "Read-only provider-scoped ledger of recent service periods and payout dates, with an optional soonest upcoming unpaid payout and day countdown.",
        inputSchema: dateScopeSchema.safeExtend({
            periodCount: z.number().int().positive().max(12).optional(),
            upcomingOnly: z.boolean().optional(),
        }).shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_service_period_payout_ledger", async (input) => execute("service-period payout ledger", () => input.upcomingOnly
        ? getUpcomingPayoutDetail(client, input, new Date().toISOString().slice(0, 10))
        : getServicePeriodLedger(client, input, new Date().toISOString().slice(0, 10), input.periodCount === undefined ? {} : { periodCount: input.periodCount }), formatPayoutResult)));
    server.registerTool("cccap_get_payment_history", {
        title: "Get CCCAP Payment History",
        description: "After initialization, retrieve read-only sub-payment history for the authenticated provider and the requested service-period date scope. The server resolves the date scope to overlapping service periods before querying payments, so use this to detect existing paid or requested payments before any future payout calculation.",
        inputSchema: paymentHistorySchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_payment_history", async (input) => execute("payment-history retrieval", async () => normalizePaymentHistory(await client.getPaymentHistory(input)))));
    return server;
}
