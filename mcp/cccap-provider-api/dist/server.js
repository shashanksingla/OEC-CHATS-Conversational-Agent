import { McpServer } from "@modelcontextprotocol/server";
import * as z from "zod/v4";
import { getAttendanceDataAnalysis, getAttendanceRiskAnalysis, getAttendanceRiskSnapshot, getCurrentMonthAttendanceSnapshot, } from "./attendance-snapshot.js";
import { comparePaymentPeriods, getLastPayoutDetail, getPaymentAnalysis, getServicePeriodLedger, getUpcomingPayoutDetail } from "./payment-orchestration.js";
import { ConversationContextStore, cacheKeyFor, isCompatibleWithStoredInput, scopeGranularity } from "./conversation-context.js";
import { conversationLogger as defaultConversationLogger } from "./conversation-logger.js";
import { DialogueStateStore } from "./dialogue-state.js";
import { normalizeAuthorizations, normalizeCases, normalizeCountyPlans, normalizeFiscalRates, normalizeHolidays, normalizePaymentHistory, normalizeProviderInitialization, normalizeSchedules, normalizeServicePeriods, } from "./read-model-adapters.js";
import { authorizationSchema, attendanceAnalysisSchema, attendanceDataSchema, caseSchema, countySchema, dateScopeSchema, fiscalRatesSchema, paymentHistorySchema, paymentAnalysisSchema, paymentComparisonSchema, schedulesSchema, servicePeriodSchema, } from "./schemas.js";
import { formatScopeClarification, orderedActionList, readOnlyAnnotations, recordValue, result, } from './formatters/shared.js';
import { formatCasesResult } from './formatters/cases-formatter.js';
import { formatAuthorizationsResult } from './formatters/authorizations-formatter.js';
import { snapshotResult } from './formatters/snapshot-formatter.js';
import { formatAttendanceRiskResult } from './formatters/attendance-formatter.js';
import { formatPaymentResult, formatServicePeriodLedgerResult } from './formatters/payment-formatter.js';
import { formatCountyPolicyResult } from './formatters/county-policy-formatter.js';
import { formatPeriodComparisonResult } from './formatters/comparison-formatter.js';
export { formatAttendanceRiskResult } from './formatters/attendance-formatter.js';
export { formatPaymentResult, formatServicePeriodLedgerResult } from './formatters/payment-formatter.js';
export { formatCasesResult } from './formatters/cases-formatter.js';
export { formatAuthorizationsResult } from './formatters/authorizations-formatter.js';
export { formatCountyPolicyResult } from './formatters/county-policy-formatter.js';
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
        return value;
    const hasPlanActions = actions.some((action) => {
        const input = recordValue(action.input);
        return Boolean(input) && (action.tool === "cccap_analyze_payment_risk" || action.tool === "cccap_analyze_payment");
    });
    if (!hasPlanActions)
        return value;
    const currentCapability = typeof structuredContentBase.capability === "string"
        ? structuredContentBase.capability
        : undefined;
    const ruleVersion = typeof structuredContentBase.ruleVersion === "string"
        ? structuredContentBase.ruleVersion
        : undefined;
    const viewState = recordValue(structuredContentBase.viewState);
    const situation = recordValue(structuredContentBase.situation);
    const resultRecord = recordValue(result);
    // Best-effort result cache: keyed only on the stable date-scope portion
    // (cacheKeyFor), never on a random reference, so a later "return to the
    // unscoped view" can skip a Salesforce re-fetch. Losing this cache
    // (restart, eviction) is never an error - it just costs one extra
    // deterministic re-evaluation on the next request.
    const scopeForCacheKey = recordValue(structuredContentBase.scope) ?? recordValue(viewState?.scope) ?? {};
    const cacheKey = cacheKeyFor(providerKey, resultTool, scopeForCacheKey);
    store.cacheResult(cacheKey, providerKey, capability, result, resultTool, ruleVersion);
    // Continuation VALIDITY is a short, opaque action reference (see
    // conversation-context.ts) persisted to disk so it survives process
    // restarts - the client only ever has to reproduce a ~22-character
    // random string, never a long self-describing blob.
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
        ...(viewState ? { currentView: viewState } : {}),
        ...(Array.isArray(structuredContentBase.responseSections)
            ? { availableEvidence: structuredContentBase.responseSections.filter((section) => typeof section === "string") }
            : {}),
        ...(typeof situation?.severity === "string" ? { severity: situation.severity } : {}),
        ...(typeof structuredContentBase.sourceRetrievedAt === "string"
            ? { sourceRetrievedAt: structuredContentBase.sourceRetrievedAt }
            : {}),
        ...(ruleVersion ? { ruleVersion } : {}),
    };
    const { actionIntents: _actionIntents, filters: _filters, responseContext: _responseContext, ...structuredContent } = structuredContentBase;
    return {
        ...contextualizedValue,
        structuredContent: {
            ...structuredContent,
            resultGraph: graph,
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
function toolError(capability, error) {
    const message = error instanceof Error ? error.message : "";
    // "payment payout ledger" covers NEXT_PAYOUT/LAST_PAYOUT/PAYOUT_LEDGER
    // (getServicePeriodLedger issues the exact same getPaymentAnalysis calls
    // internally as a direct "payment analysis" request) - previously
    // excluded here, so a ledger-view failure fell through to the generic
    // PROVIDER_DATA_UNAVAILABLE fallback below and lost every diagnostic
    // detail a direct payment-analysis call of the same underlying failure
    // would have surfaced.
    const paymentFailure = capability === "payment analysis" || capability === "payment payout ledger";
    const paymentDiagnostic = paymentFailure && message.length > 0
        ? message
            .replace(/[a-zA-Z0-9]{15,18}/g, "[redacted-id]")
            .slice(0, 240)
        : undefined;
    const continuationFailure = message === "Continuation reference is unavailable or expired";
    const filterFailure = message.startsWith("Requested ") && message.includes("filter did not match");
    // Granular fiscal-schedule-match reasons (authorization-fiscal-schedule-
    // matcher.ts) checked BEFORE the generic "Authorization fiscal schedule
    // mapping" substring match below, so a specific reason=NO_MATCH_* etc.
    // gets a specific plain-language description instead of the blanket
    // "authorization-to-fiscal-schedule mapping" - the thrown error message
    // already embeds "reason=<value>" verbatim from payment-canonical-adapter.ts.
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
    // Previously hardcoded "The next payout could not be verified..." even
    // when the actual request was a current-week forecast, status check, or
    // custom-range payout - the message named the wrong view. Uses the
    // generic capability phrase instead so it's accurate for every payment
    // view, and states plainly that this is a source-data condition, not a
    // mistake in what the provider asked for.
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
        // Mirrors the JSON string above into structuredContent so the skill
        // template's literal `error.code`/`error.message`/`error.nextSteps`
        // reads are actually true, instead of requiring the model to parse a
        // JSON string out of content[0].text (see carepay-conversation-
        // templates/SKILL.md's Continuation Failure Template). content[0].text
        // is kept unchanged for any caller still parsing the string form.
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
        // providerUtterance is debug-only metadata (the provider's exact chat
        // message/selection for this turn) - stripped out here, BEFORE the real
        // handler ever runs, so it can never reach Salesforce/Python calls or
        // get echoed back in a response. handlerInput (not input) is what every
        // downstream handler/business-logic call actually receives.
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
                    // Logging must not alter or reject a tool response that has invalid error JSON.
                }
            }
        }
        conversationLogger.logToolCall({
            tool: toolName,
            // handlerInput (not the original input) - providerUtterance was
            // already stripped above and must not reappear here; it's passed
            // separately below as its own field.
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
    }, withConversationLogging("cccap_get_attendance_risk_snapshot", async (input) => execute("attendance-risk snapshot", () => getAttendanceRiskSnapshot(client, providerDisplayName, input, new Date().toISOString().slice(0, 10)), (data) => attachDialogueState(contextualize(snapshotResult(data, true), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined))));
    server.registerTool("cccap_get_current_month_risk_snapshot", {
        title: "Get Current-Month Payment Risk Snapshot",
        description: "Get the authenticated provider's current-month payment-risk snapshot with today's scheduled and checked-in child counts at the top. Use this read-only provider-scoped tool first for a provider greeting.",
        inputSchema: {},
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_current_month_risk_snapshot", async () => execute("current payment-risk snapshot", () => getCurrentMonthAttendanceSnapshot(client, providerDisplayName, new Date().toISOString().slice(0, 10)), (data) => {
        // Records that THIS provider's most recent risk figures came from
        // a MONTH-wide scope, so a later freeform riskFocus request that
        // has since drifted to a narrower PERIOD scope can be caught by
        // the scope-clarification check in cccap_analyze_payment_risk
        // below, instead of silently reusing the narrower scope.
        contextStore.setLastSnapshotScope(providerKey, { dateFilter: "THIS_MONTH" });
        return attachDialogueState(contextualize(snapshotResult(data, true), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined);
    })));
    server.registerTool("cccap_get_attendance_analysis", {
        title: "Get Attendance Transaction Diagnostics",
        description: "Retrieve low-level authenticated-provider schedule and transaction diagnostics, including data-quality blockers. Do not use for pending parent confirmations, absence risk, child drill-downs, or a numbered action after the provider snapshot; use cccap_analyze_payment_risk for those provider-facing requests.",
        inputSchema: attendanceDataSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_attendance_analysis", async (input) => execute("attendance detail analysis", () => getAttendanceDataAnalysis(client, input))));
    server.registerTool("cccap_analyze_payment_risk", {
        title: "Review Parent Confirmations and Attendance Risk",
        description: "Provider-facing tool for pending parent confirmations, numbered attendance actions after a snapshot, child drill-downs, attendance exceptions, and absence-limit risk. Returns a ready-to-relay response with next actions. The server retrieves only the requested scope and runs the deterministic Python evaluator.",
        inputSchema: attendanceAnalysisSchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_analyze_payment_risk", async (input) => {
        const hasContinuation = Boolean(input.actionId || input.actionToken);
        // Short opaque action reference, persisted to disk (conversation-context.ts)
        // so it survives process restarts - resolveActionToken already binds
        // to providerKey/tool and enforces TTL internally.
        const resolvedAction = contextStore.resolveActionToken(input.actionToken, providerKey, "cccap_analyze_payment_risk");
        if (hasContinuation && !resolvedAction) {
            return toolError("attendance-risk analysis", new Error("Continuation reference is unavailable or expired"));
        }
        const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "actionId" && key !== "actionToken" && key !== "refresh"));
        if (resolvedAction && Object.keys(directContinuationInput).length > 0 && !isCompatibleWithStoredInput(directContinuationInput, resolvedAction.input)) {
            return toolError("attendance-risk analysis", new Error("Continuation reference is unavailable or expired"));
        }
        const request = (resolvedAction ? { ...resolvedAction.input, ...directContinuationInput } : input);
        // Scope-clarification backstop: a freeform riskFocus request (no
        // continuation, no explicit dateFilter/dateFrom/dateTo in this raw
        // input) may still carry a dateFrom/dateTo the caller silently
        // reused from an earlier, narrower turn. When the provider's risk
        // figures actually came from a MONTH-wide snapshot earlier this
        // session and the active request has since drifted to a PERIOD-
        // granularity scope, ask which one is meant instead of guessing -
        // never fires when the caller explicitly restated dateFilter in
        // this exact request, when it's a real continuation, or when no
        // month snapshot ran yet this session.
        if (!hasContinuation && request.riskFocus) {
            const lastSnapshotScope = contextStore.getLastSnapshotScope(providerKey);
            if (lastSnapshotScope && scopeGranularity(lastSnapshotScope) === "MONTH" && scopeGranularity(request) === "PERIOD") {
                return formatScopeClarification(request.riskFocus, { dateFrom: request.dateFrom, dateTo: request.dateTo });
            }
        }
        if (input.refresh)
            client.clearReadCache();
        const isNarrowedAttendanceContinuation = Boolean(request.childNames?.length ||
            request.authNames?.length ||
            request.countyNames?.length ||
            request.riskFocus);
        // Best-effort result cache: keyed only on the stable date-scope
        // portion (cacheKeyFor), so a "return to the unscoped view" can reuse
        // an already-fetched full result without a Salesforce re-fetch. A
        // cache miss (restart, eviction) falls straight through to a fresh
        // evaluation below - never an error.
        const cacheKey = cacheKeyFor(providerKey, "cccap_analyze_payment_risk", request);
        const cached = !input.refresh && !isNarrowedAttendanceContinuation
            ? contextStore.getCachedResult(cacheKey, providerKey)
            : undefined;
        if (cached && cached.resultTool === "cccap_analyze_payment_risk") {
            const cachedResult = recordValue(cached.result);
            if (cachedResult) {
                const continuationResult = { ...cachedResult, scope: request, riskFocus: request.riskFocus, countyNames: request.countyNames, detailPage: request.detailPage, detailPageSize: request.detailPageSize };
                return attachDialogueState(contextualize(formatAttendanceRiskResult(continuationResult, true), contextStore, providerKey, "continuation", continuationResult, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", request, typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined);
            }
        }
        return execute("attendance-risk analysis", () => getAttendanceRiskAnalysis(client, providerDisplayName, request, new Date().toISOString().slice(0, 10), request.childNames, request.authNames, request.riskFocus, request.countyNames, request.detailPage, request.detailPageSize), (data) => attachDialogueState(contextualize(formatAttendanceRiskResult(data, true), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"), dialogueStore, providerKey, "attendance-risk-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
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
        // Short opaque action reference, persisted to disk - see the matching
        // comment in cccap_analyze_payment_risk above.
        const resolvedAction = contextStore.resolveActionToken(input.actionToken, providerKey, "cccap_analyze_payment");
        if (hasContinuation && !resolvedAction) {
            return toolError("payment analysis", new Error("Continuation reference is unavailable or expired"));
        }
        const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "actionId" && key !== "actionToken" && key !== "refresh"));
        if (resolvedAction && Object.keys(directContinuationInput).length > 0 && !isCompatibleWithStoredInput(directContinuationInput, resolvedAction.input)) {
            return toolError("payment analysis", new Error("Continuation reference is unavailable or expired"));
        }
        const resolvedRequest = (resolvedAction ? { ...resolvedAction.input, ...directContinuationInput } : input);
        // CURRENT_PERIOD_FORECAST is the current, correctly-named view for
        // "the service period containing today"; CURRENT_WEEK_FORECAST is
        // kept only as an accepted input alias so existing callers do not
        // break. Normalize here, once, so every downstream orchestration and
        // formatter call site keeps using the single existing internal name,
        // and so `request.view`'s type never carries the alias past this point.
        const normalizedView = resolvedRequest.view === "CURRENT_PERIOD_FORECAST" ? "CURRENT_WEEK_FORECAST" : resolvedRequest.view;
        const request = { ...resolvedRequest, view: normalizedView };
        if (input.refresh)
            client.clearReadCache();
        // NEXT_PAYOUT/LAST_PAYOUT/PAYOUT_LEDGER all render through the ledger
        // formatter (single or multi-period), never the payment-summary
        // formatter - keep the cached-continuation branch and the routing
        // below in sync on this.
        const usesLedgerFormatter = request.view === "NEXT_PAYOUT" || request.view === "LAST_PAYOUT" || request.view === "PAYOUT_LEDGER";
        // Best-effort result cache - see the matching comment in
        // cccap_analyze_payment_risk above. A miss falls straight through to
        // a fresh evaluation, never an error.
        const cacheKey = cacheKeyFor(providerKey, "cccap_analyze_payment", request);
        const cached = !input.refresh
            ? contextStore.getCachedResult(cacheKey, providerKey)
            : undefined;
        if (cached && cached.resultTool === "cccap_analyze_payment") {
            const cachedResult = recordValue(cached.result);
            if (cachedResult) {
                const continuationResult = { ...cachedResult, filters: request };
                return attachDialogueState(contextualize(usesLedgerFormatter
                    ? formatServicePeriodLedgerResult(continuationResult)
                    : formatPaymentResult(continuationResult), contextStore, providerKey, "continuation", continuationResult, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(cachedResult.scope) ?? request, typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined);
            }
        }
        // NEXT_PAYOUT resolves to a single upcoming period by default - a
        // plain "upcoming payment" request must never silently expand to the
        // multi-period ledger. PAYOUT_LEDGER is the only view that returns
        // multiple periods, and only when the provider explicitly names a
        // month/range. LAST_PAYOUT resolves to the single most recently
        // released period; it is a distinct capability from NEXT_PAYOUT, not
        // a fallback when no upcoming period exists.
        const asOfDateForLedger = new Date().toISOString().slice(0, 10);
        const runNextPayout = () => execute("payment payout ledger", () => getUpcomingPayoutDetail(client, request, asOfDateForLedger, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
        }), (data) => attachDialogueState(contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope ?? request, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        const runLastPayout = () => execute("payment payout ledger", () => getLastPayoutDetail(client, request, asOfDateForLedger, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
        }), (data) => attachDialogueState(contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope ?? request, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        const runPayoutLedger = () => execute("payment payout ledger", () => getServicePeriodLedger(client, request, asOfDateForLedger, {
            ...(request.periodCount ? { periodCount: request.periodCount } : {}),
            filters: {
                ...(request.childNames ? { childNames: request.childNames } : {}),
                ...(request.authNames ? { authNames: request.authNames } : {}),
                ...(request.countyNames ? { countyNames: request.countyNames } : {}),
            },
        }), (data) => attachDialogueState(contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope ?? request, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
        if (request.view === "NEXT_PAYOUT") {
            return runNextPayout();
        }
        if (request.view === "LAST_PAYOUT") {
            return runLastPayout();
        }
        if (request.view === "PAYOUT_LEDGER") {
            return runPayoutLedger();
        }
        const runPaymentAnalysis = () => execute("payment analysis", () => getPaymentAnalysis(client, request, request.view, undefined, {
            ...(request.childNames ? { childNames: request.childNames } : {}),
            ...(request.authNames ? { authNames: request.authNames } : {}),
            ...(request.countyNames ? { countyNames: request.countyNames } : {}),
        }), (data) => attachDialogueState(contextualize(formatPaymentResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"), dialogueStore, providerKey, "payment-analysis", recordValue(data)?.scope, typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt : undefined));
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
        : getServicePeriodLedger(client, input, new Date().toISOString().slice(0, 10), input.periodCount === undefined ? {} : { periodCount: input.periodCount }), formatServicePeriodLedgerResult)));
    server.registerTool("cccap_get_payment_history", {
        title: "Get CCCAP Payment History",
        description: "After initialization, retrieve read-only sub-payment history for the authenticated provider and the requested service-period date scope. The server resolves the date scope to overlapping service periods before querying payments, so use this to detect existing paid or requested payments before any future payout calculation.",
        inputSchema: paymentHistorySchema.shape,
        annotations: readOnlyAnnotations,
    }, withConversationLogging("cccap_get_payment_history", async (input) => execute("payment-history retrieval", async () => normalizePaymentHistory(await client.getPaymentHistory(input)))));
    return server;
}
