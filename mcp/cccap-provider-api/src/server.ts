import { McpServer } from "@modelcontextprotocol/server";
import * as z from "zod/v4";

import {
  getAttendanceDataAnalysis,
  getAttendanceRiskAnalysis,
  getAttendanceRiskSnapshot,
  getCurrentMonthAttendanceSnapshot,
} from "./attendance-snapshot.js";
import { comparePaymentPeriods, getPaymentAnalysis, getServicePeriodLedger, getUpcomingPayoutDetail } from "./payment-orchestration.js";
import { CccapClient } from "./client.js";
import { ConversationContextStore, type ContinuationPlan } from "./conversation-context.js";
import { DialogueStateStore } from "./dialogue-state.js";
import {
  normalizeAuthorizations,
  normalizeCases,
  normalizeCountyPlans,
  normalizeFiscalRates,
  normalizeHolidays,
  normalizePaymentHistory,
  normalizeProviderInitialization,
  normalizeSchedules,
  normalizeServicePeriods,
} from "./read-model-adapters.js";
import {
  authorizationSchema,
  attendanceAnalysisSchema,
  attendanceDataSchema,
  caseSchema,
  countySchema,
  dateScopeSchema,
  fiscalRatesSchema,
  paymentHistorySchema,
  paymentAnalysisSchema,
  paymentComparisonSchema,
  schedulesSchema,
  servicePeriodSchema,
} from "./schemas.js";
import {
  readOnlyAnnotations,
  recordValue,
  result,
  type ToolResult,
} from './formatters/shared.js';
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




function contextualize(
  value: ToolResult,
  store: ConversationContextStore,
  providerKey: string,
  capability: string,
  result: unknown,
  resultTool: ContinuationPlan["tool"],
): ToolResult {
  if (value.isError || !value.structuredContent) return value;
  const actions = Array.isArray(value.structuredContent.actionControls)
    ? value.structuredContent.actionControls.map(recordValue).filter((action): action is Record<string, unknown> => Boolean(action))
    : Array.isArray(value.structuredContent.actionIntents)
      ? value.structuredContent.actionIntents.map(recordValue).filter((action): action is Record<string, unknown> => Boolean(action))
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
  if (combinedActions.length === 0) return value;
  const plans: ContinuationPlan[] = combinedActions.flatMap((action) => {
    const tool = action.tool;
    const input = recordValue(action.input);
    return (tool === "cccap_analyze_payment_risk" || tool === "cccap_analyze_payment") && input
      ? [{ tool, input }]
      : [];
  });
  if (plans.length === 0) return value;
  const ruleVersion = typeof value.structuredContent.ruleVersion === "string"
    ? value.structuredContent.ruleVersion
    : undefined;
  const planActions = combinedActions.filter((action) => {
    const input = recordValue(action.input);
    return Boolean(input) && (action.tool === "cccap_analyze_payment_risk" || action.tool === "cccap_analyze_payment");
  });
  const { contextRef, actionRefs } = store.create(
    providerKey,
    capability,
    plans,
    result,
    resultTool,
    ruleVersion,
    planActions,
  );
  let actionIndex = 0;
  const actionControls = combinedActions.map((action) => {
    const input = recordValue(action.input);
    if (!input || (action.tool !== "cccap_analyze_payment_risk" && action.tool !== "cccap_analyze_payment")) return action;
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
      input: { actionId: action.actionId, contextRef, actionRef },
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
function attachDialogueState(
  value: ToolResult,
  store: DialogueStateStore,
  providerKey: string,
  capability: string,
  scope: unknown,
  freshnessAt: string | undefined,
): ToolResult {
  if (value.isError || !value.structuredContent || typeof freshnessAt !== "string") return value;
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




function toolError(capability: string, error: unknown): ToolResult {
  const message = error instanceof Error ? error.message : "";
  const paymentFailure = capability === "payment analysis";
  const paymentDiagnostic = paymentFailure && message.length > 0
    ? message
      .replace(/[a-zA-Z0-9]{15,18}/g, "[redacted-id]")
      .slice(0, 240)
    : undefined;
  const continuationFailure = message === "Continuation reference is unavailable or expired";
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
  const userMessage = continuationFailure
    ? "The selected action could not be resumed because its conversation state is unavailable or expired."
    : filterFailure
    ? message
    : paymentFailure && paymentSource
    ? `The next payout could not be verified because ${paymentSource} is incomplete or ambiguous.`
    : paymentFailure
      ? "The next payout could not be verified because one or more approved payment-source mappings were rejected."
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
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: JSON.stringify({
          error: {
            code: continuationFailure
              ? "CONTINUATION_UNAVAILABLE"
              : filterFailure
                ? "REQUEST_SCOPE_NOT_FOUND"
                : paymentFailure
                  ? "PAYMENT_DATA_INCOMPLETE"
                  : "PROVIDER_DATA_UNAVAILABLE",
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

async function execute(
  capability: string,
  operation: () => Promise<unknown>,
  formatResult: (data: unknown) => ToolResult = result,
): Promise<ToolResult> {
  try {
    return formatResult(await operation());
  } catch (error) {
    return toolError(capability, error);
  }
}

export function createServer(
  client: CccapClient,
  providerDisplayName: string,
  contextStore = new ConversationContextStore(),
  providerKey = providerDisplayName,
  dialogueStore = new DialogueStateStore(),
): McpServer {
  const server = new McpServer({
    name: "cccap-provider-api",
    version: "1.0.0",
  });

  server.registerTool(
    "cccap_get_attendance_risk_snapshot",
    {
      title: "Get CCCAP Attendance Risk Snapshot",
      description:
        "Get a provider-scoped attendance risk snapshot for the requested date range. Use this for current-month, last-month, or explicit date-range snapshot requests; use cccap_analyze_payment_risk for child-level follow-up details.",
      inputSchema: dateScopeSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) =>
      execute(
        "attendance-risk snapshot",
        () =>
          getAttendanceRiskSnapshot(
            client,
            providerDisplayName,
            input,
            new Date().toISOString().slice(0, 10),
          ),
        (data) => attachDialogueState(
          contextualize(snapshotResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"),
          dialogueStore,
          providerKey,
          "attendance-risk-analysis",
          recordValue(data)?.scope,
          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
        ),
      ),
  );

  server.registerTool(
    "cccap_get_current_month_risk_snapshot",
    {
      title: "Get Current-Month Payment Risk Snapshot",
      description:
        "Get the authenticated provider's current-month payment-risk snapshot with today's scheduled and checked-in child counts at the top. Use this read-only provider-scoped tool first for a provider greeting.",
      inputSchema: {},
      annotations: readOnlyAnnotations,
    },
    async () =>
      execute(
        "current payment-risk snapshot",
        () =>
          getCurrentMonthAttendanceSnapshot(
            client,
            providerDisplayName,
            new Date().toISOString().slice(0, 10),
          ),
        (data) => attachDialogueState(
          contextualize(snapshotResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"),
          dialogueStore,
          providerKey,
          "attendance-risk-analysis",
          recordValue(data)?.scope,
          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
        ),
      ),
  );

  server.registerTool(
    "cccap_get_attendance_analysis",
    {
      title: "Get Attendance Transaction Diagnostics",
      description:
        "Retrieve low-level authenticated-provider schedule and transaction diagnostics, including data-quality blockers. Do not use for pending parent confirmations, absence risk, child drill-downs, or a numbered action after the provider snapshot; use cccap_analyze_payment_risk for those provider-facing requests.",
      inputSchema: attendanceDataSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) =>
      execute(
        "attendance detail analysis",
        () => getAttendanceDataAnalysis(client, input),
      ),
  );

  server.registerTool(
    "cccap_analyze_payment_risk",
    {
      title: "Review Parent Confirmations and Attendance Risk",
      description:
        "Provider-facing tool for pending parent confirmations, numbered attendance actions after a snapshot, child drill-downs, attendance exceptions, and absence-limit risk. Returns a ready-to-relay response with next actions. The server retrieves only the requested scope and runs the deterministic Python evaluator.",
      inputSchema: attendanceAnalysisSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => {
      const hasContinuation = Boolean(input.actionId || input.contextRef || input.actionRef);
      const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "actionId" && key !== "contextRef" && key !== "actionRef" && key !== "refresh"));
      const continuation = contextStore.resolve(providerKey, input.contextRef, input.actionRef, "continuation", undefined, Object.keys(directContinuationInput).length > 0 ? directContinuationInput : undefined);
      const actionContinuation = contextStore.resolveAction(providerKey, input.actionId, "cccap_analyze_payment_risk", Object.keys(directContinuationInput).length > 0 ? directContinuationInput : undefined);
      const resolvedContinuation = continuation ?? actionContinuation;
      const request = resolvedContinuation?.tool === "cccap_analyze_payment_risk"
        ? resolvedContinuation.input as typeof input
        : input;
      if (hasContinuation && (!resolvedContinuation || resolvedContinuation.tool !== "cccap_analyze_payment_risk")) {
        return toolError("attendance-risk analysis", new Error("Continuation reference is unavailable or expired"));
      }
      if (input.refresh) client.clearReadCache();
      if (!input.refresh && continuation?.resultTool === "cccap_analyze_payment_risk" && continuation.result) {
        const cachedResult = recordValue(continuation.result);
        if (cachedResult) {
          const continuationResult = { ...cachedResult, scope: request, riskFocus: request.riskFocus, countyNames: request.countyNames };
          return attachDialogueState(
            contextualize(
              formatAttendanceRiskResult(continuationResult),
              contextStore,
              providerKey,
              "continuation",
              continuationResult,
              "cccap_analyze_payment_risk",
            ),
            dialogueStore,
            providerKey,
            "attendance-risk-analysis",
            request,
            typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined,
          );
        }
      }
      return execute(
        "attendance-risk analysis",
        () =>
          getAttendanceRiskAnalysis(
            client,
            providerDisplayName,
            request,
            new Date().toISOString().slice(0, 10),
            request.childNames,
            request.authNames,
            request.riskFocus,
            request.countyNames,
          ),
        (data) => attachDialogueState(
          contextualize(formatAttendanceRiskResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment_risk"),
          dialogueStore,
          providerKey,
          "attendance-risk-analysis",
          recordValue(data)?.scope,
          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
        ),
      );
    },
  );

  server.registerTool(
    "cccap_initialize_provider",
    {
      title: "Initialize CCCAP Provider",
      description:
        "Start here. Resolve the configured provider user to one authorized facility, active provider IDs, fiscal agreements, counties, rate schedules, and closures for the requested date scope. The server injects the provider user ID; never ask the model or provider to supply it.",
      inputSchema: dateScopeSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "provider initialization",
      async () => normalizeProviderInitialization(await client.initialize(input)),
    ),
  );

  server.registerTool(
    "cccap_get_cases",
    {
      title: "Get CCCAP Cases and Children",
      description:
        "After initialization, retrieve active cases and related children for the authenticated provider. Omit countyIds for all authorized counties or pass only county IDs returned by initialization.",
      inputSchema: caseSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "cases and children retrieval",
      async () => normalizeCases(await client.getCases(input)),
      (data) => formatCasesResult(data, (countyId) => client.getCountyName(countyId)),
    ),
  );

  server.registerTool(
    "cccap_get_authorizations",
    {
      title: "Get CCCAP Authorizations",
      description:
        "After initialization, retrieve active child authorizations for the authenticated provider. Filter by case IDs, authorized counties, or authorization names only when needed for the provider's question.",
      inputSchema: authorizationSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "authorizations retrieval",
      async () => normalizeAuthorizations(await client.getAuthorizations(input)),
      (data) => formatAuthorizationsResult(data, (countyId) => client.getCountyName(countyId)),
    ),
  );

  server.registerTool(
    "cccap_get_county_rate_plans",
    {
      title: "Get CCCAP County Rate Plans",
      description:
        "Retrieve effective county rate plans and provider-facing absence-day limits for the authorized provider counties. For a current policy question, use dateFilter THIS_MONTH when available so this read reuses the current-month snapshot cache. The server initializes provider scope internally when needed.",
      inputSchema: countySchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => {
      const scope = input.dateFilter || input.dateFrom || input.dateTo
        ? input
        : { ...input, dateFilter: "THIS_MONTH" as const };
      return execute(
        "county policy retrieval",
        async () => {
          await client.initialize(scope);
          return normalizeCountyPlans(await client.getCountyData(scope));
        },
        formatCountyPolicyResult,
      );
    },
  );

  server.registerTool(
    "cccap_get_service_periods",
    {
      title: "Get CCCAP Service Periods",
      description:
        "Retrieve stored or computed service periods and payment processing/release dates. Use dateOn TODAY for the current service period, paymentAfter TODAY with limitOne for the next payout, or a dateFilter for a range.",
      inputSchema: servicePeriodSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "service-period retrieval",
      async () => normalizeServicePeriods(await client.getServicePeriods(input)),
    ),
  );

  server.registerTool(
    "cccap_get_schedules",
    {
      title: "Get CCCAP Schedules and Attendance",
      description:
        "After initialization, retrieve schedules and check-in/check-out attendance transactions for the authenticated provider and date range. Use authorization names only to narrow an already authorized provider scope.",
      inputSchema: schedulesSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "schedule and attendance retrieval",
      async () => normalizeSchedules(await client.getSchedules(input)),
    ),
  );

  server.registerTool(
    "cccap_get_fiscal_rates",
    {
      title: "Get CCCAP Fiscal Rates",
      description:
        "After initialization, retrieve fiscal schedules, provider/county/agreement rate rows, and fiscal rate fees for the authenticated provider. The server supplies only rate-schedule IDs returned by provider initialization.",
      inputSchema: fiscalRatesSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "fiscal-rate retrieval",
      async () => normalizeFiscalRates(await client.getFiscalRates(input)),
    ),
  );

  server.registerTool(
    "cccap_get_holidays",
    {
      title: "Get CCCAP Holidays",
      description:
        "Retrieve holiday and observed-holiday dates, optionally within a date scope. Combine only with an effective county rate plan that allows paid holidays.",
      inputSchema: dateScopeSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "holiday-calendar retrieval",
      async () => normalizeHolidays(await client.getHolidayList(input)),
    ),
  );

  server.registerTool(
    "cccap_analyze_payment",
    {
      title: "Analyze CCCAP Payment",
      description: "Retrieve provider-scoped read-only CCCAP inputs and run the deterministic payment engine. Returns expected, conditional, duplicate-guard, or blocked results without performing payment actions.",
      inputSchema: paymentAnalysisSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => {
      const hasContinuation = Boolean(input.actionId || input.contextRef || input.actionRef);
      const directContinuationInput = Object.fromEntries(Object.entries(input).filter(([key]) => key !== "actionId" && key !== "contextRef" && key !== "actionRef" && key !== "refresh"));
      const continuation = contextStore.resolve(providerKey, input.contextRef, input.actionRef, "continuation", undefined, Object.keys(directContinuationInput).length > 0 ? directContinuationInput : undefined);
      const actionContinuation = contextStore.resolveAction(providerKey, input.actionId, "cccap_analyze_payment", Object.keys(directContinuationInput).length > 0 ? directContinuationInput : undefined);
      const resolvedContinuation = continuation ?? actionContinuation;
      const request = resolvedContinuation?.tool === "cccap_analyze_payment"
        ? resolvedContinuation.input as typeof input
        : input;
      if (hasContinuation && (!resolvedContinuation || resolvedContinuation.tool !== "cccap_analyze_payment")) {
        return toolError("payment analysis", new Error("Continuation reference is unavailable or expired"));
      }
      if (input.refresh) client.clearReadCache();
      const requestsDetailPage = request.detailPage !== undefined || request.detailPageSize !== undefined;
      if (!input.refresh && !requestsDetailPage && continuation?.resultTool === "cccap_analyze_payment" && continuation.result) {
        const cachedResult = recordValue(continuation.result);
        if (cachedResult) {
          const continuationResult = { ...cachedResult, filters: request };
          return attachDialogueState(
            contextualize(
              formatPaymentResult(continuationResult),
              contextStore,
              providerKey,
              "continuation",
              continuationResult,
              "cccap_analyze_payment",
            ),
            dialogueStore,
            providerKey,
            "payment-analysis",
            recordValue(cachedResult.scope) ?? request,
            typeof cachedResult.sourceRetrievedAt === "string" ? cachedResult.sourceRetrievedAt : undefined,
          );
        }
      }
      const runPaymentAnalysis = () => execute(
        "payment analysis",
        () => getPaymentAnalysis(client, request, request.view, undefined, {
          ...(request.childNames ? { childNames: request.childNames } : {}),
          ...(request.authNames ? { authNames: request.authNames } : {}),
          ...(request.countyNames ? { countyNames: request.countyNames } : {}),
          ...(request.detailPage ? { detailPage: request.detailPage } : {}),
          ...(request.detailPageSize ? { detailPageSize: request.detailPageSize } : {}),
          ...(request.excludedOnly ? { excludedOnly: true } : {}),
        }),
        (data) => attachDialogueState(
          contextualize(formatPaymentResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"),
          dialogueStore,
          providerKey,
          "payment-analysis",
          recordValue(data)?.scope,
          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
        ),
      );
      const paymentResult = await runPaymentAnalysis();
      if (paymentResult.isError && !hasContinuation && !input.refresh) {
        client.clearReadCache();
        return runPaymentAnalysis();
      }
      return paymentResult;
    },
  );

  server.registerTool(
    "cccap_compare_payment_periods",
    {
      title: "Compare CCCAP Payment Periods",
      description: "Read-only genuine period-over-period payment comparison with category and county deltas; distinct from single-period payment analysis.",
      inputSchema: paymentComparisonSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "payment comparison",
      () => comparePaymentPeriods(client, input.periodOne, input.periodTwo, new Date().toISOString().slice(0, 10), input.significantDeltaThresholdPct === undefined ? {} : { significantDeltaThresholdPct: input.significantDeltaThresholdPct }),
      formatPeriodComparisonResult,
    ),
  );

  server.registerTool(
    "cccap_get_service_period_payout_ledger",
    {
      title: "Get CCCAP Service-Period Payout Ledger",
      description: "Read-only provider-scoped ledger of recent service periods and payout dates, with an optional soonest upcoming unpaid payout and day countdown.",
      inputSchema: dateScopeSchema.safeExtend({
        periodCount: z.number().int().positive().max(12).optional(),
        upcomingOnly: z.boolean().optional(),
      }).shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "service-period payout ledger",
      () => input.upcomingOnly
        ? getUpcomingPayoutDetail(client, input, new Date().toISOString().slice(0, 10))
        : getServicePeriodLedger(client, input, new Date().toISOString().slice(0, 10), input.periodCount === undefined ? {} : { periodCount: input.periodCount }),
      formatServicePeriodLedgerResult,
    ),
  );

  server.registerTool(
    "cccap_get_payment_history", 
    {
      title: "Get CCCAP Payment History",
      description:
        "After initialization, retrieve read-only sub-payment history for the authenticated provider and the requested service-period date scope. The server resolves the date scope to overlapping service periods before querying payments, so use this to detect existing paid or requested payments before any future payout calculation.",
      inputSchema: paymentHistorySchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute(
      "payment-history retrieval",
      async () => normalizePaymentHistory(await client.getPaymentHistory(input)),
    ),
  );

  return server;
}