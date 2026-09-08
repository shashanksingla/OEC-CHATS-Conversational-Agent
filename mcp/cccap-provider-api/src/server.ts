import { McpServer } from "@modelcontextprotocol/server";

import {
  getAttendanceDataAnalysis,
  getAttendanceRiskAnalysis,
  getAttendanceRiskSnapshot,
  getCurrentMonthAttendanceSnapshot,
  getPaymentAnalysis,
} from "./attendance-snapshot.js";
import { CccapClient } from "./client.js";
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
  schedulesSchema,
  servicePeriodSchema,
} from "./schemas.js";

const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: true,
};

type ToolResult = {
  content: [{ type: "text"; text: string }];
  structuredContent?: Record<string, unknown>;
  isError?: boolean;
};

const MAX_DISPLAY_CHILDREN = 10;

function result(data: unknown): ToolResult {
  const structuredContent =
    data && typeof data === "object" && !Array.isArray(data)
      ? (data as Record<string, unknown>)
      : undefined;
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data) }],
    ...(structuredContent ? { structuredContent } : {}),
  };
}

export function formatCountyPolicyResult(data: unknown): ToolResult {
  const response = recordValue(data);
  const plans = response && Array.isArray(response.countyRatePlans)
    ? response.countyRatePlans.map(recordValue).filter(
      (plan): plan is Record<string, unknown> => Boolean(plan),
    )
    : [];
  if (plans.length === 0) {
    return {
      content: [{
        type: "text" as const,
        text: "No verified county rate-plan limits were returned for the authorized provider scope.",
      }],
      structuredContent: {
        capability: "county-policy",
        providerMessage: "No verified county rate-plan limits were returned for the authorized provider scope.",
        resultStatus: "NO_POLICY_DATA",
      },
    };
  }
  const policyResponse = response as Record<string, unknown>;
  const tierColumns = [1, 2, 3, 4, 5].map((tier) => `Tier ${tier}`);
  const lines = [
    "**County absence limits**",
    "",
    `| County | Effective from | ${tierColumns.join(" | ")} |`,
    `| --- | --- | ${tierColumns.map(() => "---:").join(" | ")} |`,
    ...plans.map((plan) =>
      `| ${tableValue(plan.countyName)} | ${tableValue(plan.effectiveBeginDate)} | ${[1, 2, 3, 4, 5]
        .map((tier) => tableValue(plan[`absenceDaysTier${tier}`]))
        .join(" | ")} |`,
    ),
    "",
    "These are the verified absence-day limits returned for the authorized provider counties. The applicable tier depends on the provider or authorization policy tier.",
  ];
  const providerMessage = lines.join("\n");
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "county-policy",
      providerMessage,
      resultStatus: "COMPLETED",
      policyCount: plans.length,
      scope: policyResponse.scope,
      sourceRetrievedAt: policyResponse.sourceRetrievedAt,
    },
  };
}

function snapshotResult(data: unknown): ToolResult {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return result(data);
  }
  const snapshot = data as Record<string, unknown>;
  const providerMessage = snapshot.providerMessage;
  if (typeof providerMessage !== "string" || providerMessage.length === 0) {
    return result(data);
  }
  const risk = recordValue(snapshot.attendanceRisk);
  const children = risk && Array.isArray(risk.children)
    ? risk.children
        .map(recordValue)
        .filter((child): child is Record<string, unknown> => Boolean(child))
    : [];
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "attendance-risk-snapshot",
      providerMessage,
      scope: snapshot.scope,
      sourceRetrievedAt: snapshot.sourceRetrievedAt,
      actionIntents: risk ? actionMetadata(snapshot.scope, risk, children) : [],
    },
  };
}

function recordValue(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function tableValue(value: unknown): string {
  if (typeof value === "string" && value.trim()) {
    return value.replace(/[\r\n|]/g, " ").trim();
  }
  if (typeof value === "number") {
    return String(value);
  }
  return "Unavailable from the current source";
}

function authorizationDates(value: unknown): string {
  if (!Array.isArray(value) || value.length === 0) {
    return "Unavailable from the current source";
  }
  return value.map(tableValue).join(", ");
}

function authorizationNames(value: unknown): string {
  if (!Array.isArray(value) || value.length === 0) {
    return "Unavailable from the current source";
  }
  return value.map(tableValue).join(", ");
}

function numericValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function attendanceScopeLabel(scope: unknown): string {
  const dateFilter = recordValue(scope)?.dateFilter;
  if (dateFilter === "LAST_MONTH") return "Last-month";
  if (dateFilter === "THIS_MONTH") return "Current-month";
  if (dateFilter === "DATE_RANGE") return "Date-range";
  if (dateFilter === "TODAY") return "Today";
  return "Attendance-risk";
}

function hasAbsenceLimitConcern(child: Record<string, unknown>): boolean {
  return Array.isArray(child.risk_codes) && child.risk_codes.some((code) =>
    code === "ABSENCE_LIMIT_EXCEEDED" || code === "ABSENCE_LIMIT_APPROACHING",
  );
}

function actionMetadata(
  scope: unknown,
  risk: Record<string, unknown>,
  children: Record<string, unknown>[],
): Record<string, unknown>[] {
  const childNamesFor = (code: string) => children
    .filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes(code))
    .map((child) => child.child_name)
    .filter((name): name is string => typeof name === "string");
  const actions: Record<string, unknown>[] = [];
  if (numericValue(risk.pending_confirmation_days) > 0) {
    actions.push({
      actionId: "review-pending-parent-confirmations",
      capability: "attendance-risk-analysis",
      label: "Review pending parent confirmations in the provider system",
      scope,
      childNames: childNamesFor("PARENT_CONFIRMATION_PENDING"),
    });
  }
  const absenceChildren = children.filter(hasAbsenceLimitConcern);
  if (absenceChildren.length > 0) {
    actions.push({
      actionId: "review-absence-limit-risk",
      capability: "county-policy",
      tool: "cccap_get_county_rate_plans",
      label: "Review county absence limits for the affected children",
      scope,
      childNames: absenceChildren
        .map((child) => child.child_name)
        .filter((name): name is string => typeof name === "string"),
    });
  }
  return actions;
}

function sourceIntegrityError(scope: unknown, message: string): ToolResult {
  return {
    isError: true,
    content: [{
      type: "text" as const,
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

export function formatAttendanceRiskResult(data: unknown): ToolResult {
  const analysis = recordValue(data);
  const risk = analysis && recordValue(analysis.attendanceRisk);
  const children = risk && Array.isArray(risk.children) ? risk.children : undefined;
  if (!risk || !children) {
    return result(data);
  }

  const affectedChildren = children
    .map(recordValue)
    .filter((child): child is Record<string, unknown> => Boolean(child))
    .filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.length > 0);
  const pendingDays = numericValue(risk.pending_confirmation_days);
  const pendingChildren = affectedChildren.filter((child) =>
    Array.isArray(child.risk_codes) && child.risk_codes.includes("PARENT_CONFIRMATION_PENDING"),
  ).length;
  const absenceChildren = affectedChildren.filter(hasAbsenceLimitConcern).length;
  const incompleteChildren = affectedChildren.filter((child) =>
    Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD"),
  ).length;
  const probableAbsenceDays = numericValue(risk.probable_absence_days);
  const scopeLabel = attendanceScopeLabel(analysis.scope);
  const childPendingDays = affectedChildren.reduce(
    (total, child) => total + numericValue(child.pending_confirmation_days),
    0,
  );
  const childProbableAbsenceDays = affectedChildren.reduce(
    (total, child) => total + numericValue(child.probable_absence_days),
    0,
  );
  const reportedRiskChildCount = numericValue(risk.risk_child_count);
  if (
    childPendingDays !== pendingDays ||
    childProbableAbsenceDays !== probableAbsenceDays ||
    (reportedRiskChildCount > 0 && reportedRiskChildCount !== affectedChildren.length)
  ) {
    return sourceIntegrityError(
      analysis.scope,
      "Aggregate attendance risk totals do not match the returned child details.",
    );
  }
  const hasAuthorizationNames = affectedChildren.some(
    (child) => Array.isArray(child.authorization_names) && child.authorization_names.length > 0,
  );
  const hasCounties = affectedChildren.some(
    (child) => typeof child.county === "string" && child.county.length > 0,
  );
  const noAttendanceRecords =
    children.length === 0 && numericValue(risk.scheduled_days) === 0;
  const lines = [
    noAttendanceRecords
      ? `${scopeLabel} attendance review returned no attendance records for the requested period.`
      : affectedChildren.length > 0
      ? `${scopeLabel} attendance review found ${affectedChildren.length} child(ren) needing attention.`
      : `${scopeLabel} attendance review found no child-level attendance risks.`,
  ];
  if (pendingDays > 0) {
    lines.push(
      `${pendingDays} pending parent confirmation day(s) affect ${pendingChildren} child(ren).`,
    );
  }
  if (absenceChildren > 0) {
    lines.push(`${absenceChildren} child(ren) have an absence-limit concern${
      probableAbsenceDays > 0 ? ` (${probableAbsenceDays} probable absence day(s))` : ""
    }.`);
  }
  if (incompleteChildren > 0) {
    lines.push(`${incompleteChildren} child(ren) have incomplete attendance records.`);
  }

  if (affectedChildren.length > 0) {
    const displayedChildren = affectedChildren.slice(0, MAX_DISPLAY_CHILDREN);
    lines.push(
      "",
      "| Child name | Household name | County | Authorization name | Service dates | Note | Potential impact |",
      "| --- | --- | --- | --- | --- | --- | --- |",
      ...displayedChildren.map(
        (child) =>
          `| ${tableValue(child.child_name)} | ${tableValue(child.household_name)} | ${tableValue(child.county)} | ${authorizationNames(child.authorization_names)} | ${authorizationDates(child.authorization_dates)} | ${tableValue(child.note)} | ${tableValue(child.potential_impact)} |`,
      ),
    );
    if (affectedChildren.length > displayedChildren.length) {
      lines.push(
        "",
        `Showing the first ${displayedChildren.length} of ${affectedChildren.length} affected children. Ask for the remaining child details by name or group.`,
      );
    }
  }

  const nextActions = [];
  if (pendingDays > 0) {
    nextActions.push("Review pending parent confirmations in the provider system");
    if (hasAuthorizationNames) {
      nextActions.push("Review authorization details for the affected children");
    }
  }
  if (absenceChildren > 0 && hasCounties && nextActions.length < 2) {
    nextActions.push("Review county absence limits for the affected children");
  } else if ((absenceChildren > 0 || incompleteChildren > 0) && nextActions.length < 2) {
    nextActions.push("Review the affected attendance records and county limits");
  }
  if (nextActions.length === 0) {
    nextActions.push("Review attendance records for missing or incomplete check-ins");
  }
  lines.push("", "**Next actions**", ...nextActions.map((action, index) => `${index + 1}. ${action}`));
  const providerMessage = lines.join("\n");
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "attendance-risk-analysis",
      providerMessage,
      scope: analysis.scope,
      sourceRetrievedAt: analysis.sourceRetrievedAt,
      resultStatus: noAttendanceRecords ? "NO_ATTENDANCE_SCHEDULES" : "COMPLETED",
      actionIntents: actionMetadata(analysis.scope, risk, affectedChildren),
      affectedChildNames: affectedChildren
        .map((child) => child.child_name)
        .filter((name): name is string => typeof name === "string"),
    },
  };
}

export function formatPaymentResult(data: unknown): ToolResult {
  const paymentResult = recordValue(data);
  const payment = paymentResult && recordValue(paymentResult.payment);
  if (!paymentResult || !payment) return result(data);

  const status = typeof payment.status === "string" ? payment.status.toUpperCase() : "BLOCKED";
  const view = paymentResult.paymentView === "NEXT_PAYOUT"
    ? "Next payout detail"
    : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
      ? "Current-week forecast"
      : "Payment status";
  const servicePeriod = recordValue(paymentResult.servicePeriod);
  const attendanceContainer = recordValue(paymentResult.attendance);
  const attendanceDays = attendanceContainer?.["days"];
  const attendance = Array.isArray(attendanceDays)
    ? attendanceDays
        .map(recordValue)
        .filter((row): row is Record<string, unknown> => Boolean(row))
    : [];
  const missingInputs = Array.isArray(payment.missing_inputs)
    ? payment.missing_inputs.filter((value): value is string => typeof value === "string")
    : [];
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
    for (const [label, key] of [
      ["Service period", "servicePeriodId"],
      ["Services from", "serviceBeginDate"],
      ["Services through", "serviceEndDate"],
      ["Payment processing date", "paymentProcessingDate"],
      ["Payment release date", "paymentReleaseDate"],
      ["Service-period status", "status"],
    ] as const) {
      if (servicePeriod[key] !== undefined) lines.push(`| ${label} | ${tableValue(servicePeriod[key])} |`);
    }
  }
  if (status === "BLOCKED") {
    lines.push(
      `| Missing source areas | ${missingInputs.length > 0 ? missingInputs.join(", ") : "Required source data is unavailable"} |`,
      "",
      "No payment amount is shown because the approved source data is incomplete.",
    );
  } else {
    for (const [label, key] of [
      ["Net amount", "amount"],
      ["Gross amount", "gross_amount"],
      ["Amount at risk", "amount_at_risk"],
      ["Excluded days", "excluded_days"],
      ["Existing payment status", "existing_status"],
    ] as const) {
      if (payment[key] !== undefined) lines.push(`| ${label} | ${String(payment[key])} |`);
    }
    if (attendance.length > 0) {
      lines.push(
        "",
        "| Child | County | Service date | Basis | Classification | Units | Conditional |",
        "| --- | --- | --- | --- | --- | ---: | --- |",
        ...attendance.map((day) =>
          `| ${tableValue(day.child_name ?? day.authorization_id)} | ${tableValue(day.county_id)} | ${tableValue(day.service_date)} | ${day.forecast_basis === "SCHEDULED" ? "Scheduled forecast" : "Actual"} | ${tableValue(day.classification)} | ${tableValue(day.unit_hours)} | ${day.conditional === true ? "Yes" : "No"} |`,
        ),
      );
    }
  }
  lines.push(
    "",
    "**Next views**",
    status === "BLOCKED"
      ? "1. Review the named source data or retry the payment review."
      : "1. Review the attendance classifications supporting this result.",
  );
  const providerMessage = lines.join("\n");
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "payment-analysis",
      providerMessage,
      scope: paymentResult.scope,
      paymentView: paymentResult.paymentView,
      servicePeriod,
      ruleVersion: paymentResult.rule_version,
      resultStatus: paymentResult.status,
      calculationMode: paymentResult.calculation_mode,
      sourceRetrievedAt: paymentResult.sourceRetrievedAt,
      sourceReadiness: paymentResult.source_readiness,
      status,
    },
  };
}

function toolError(capability: string, error: unknown): ToolResult {
  const message = error instanceof Error ? error.message : "";
  const paymentFailure = capability === "payment analysis";
  const paymentSource = paymentFailure && message.includes("Service period")
    ? "service-period dates"
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
  const userMessage = paymentFailure && paymentSource
    ? `The next payout could not be verified because ${paymentSource} is incomplete or ambiguous.`
    : paymentFailure
      ? "The next payout could not be verified because one or more approved payment-source mappings were rejected."
      : `The ${capability} could not be completed. No verified result was produced.`;
  const nextSteps = paymentFailure
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
            code: paymentFailure ? "PAYMENT_DATA_INCOMPLETE" : "PROVIDER_DATA_UNAVAILABLE",
            capability,
            message: userMessage,
            nextSteps,
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
        "Get a provider-scoped attendance risk snapshot for the requested date range. Use this for current-month, last-month, or explicit date-range snapshot requests; use cccap_analyze_attendance_risk for child-level follow-up details.",
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
        snapshotResult,
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
        snapshotResult,
      ),
  );

  server.registerTool(
    "cccap_get_attendance_analysis",
    {
      title: "Get Attendance Transaction Diagnostics",
      description:
        "Retrieve low-level authenticated-provider schedule and transaction diagnostics, including data-quality blockers. Do not use for pending parent confirmations, absence risk, child drill-downs, or a numbered action after the provider snapshot; use cccap_analyze_attendance_risk for those provider-facing requests.",
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
    "cccap_analyze_attendance_risk",
    {
      title: "Review Parent Confirmations and Attendance Risk",
      description:
        "Provider-facing tool for pending parent confirmations, numbered attendance actions after a snapshot, child drill-downs, attendance exceptions, and absence-limit risk. Returns a ready-to-relay response with next actions. The server retrieves only the requested scope and runs the deterministic Python evaluator.",
      inputSchema: attendanceAnalysisSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) =>
      execute(
        "attendance-risk analysis",
        () =>
          getAttendanceRiskAnalysis(
            client,
            providerDisplayName,
            input,
            new Date().toISOString().slice(0, 10),
            input.childNames,
            input.authNames,
          ),
        formatAttendanceRiskResult,
      ),
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
    async (input) => execute("provider initialization", () => client.initialize(input)),
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
    async (input) => execute("cases and children retrieval", () => client.getCases(input)),
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
    async (input) => execute("authorizations retrieval", () => client.getAuthorizations(input)),
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
          return client.getCountyData(scope);
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
    async (input) => execute("service-period retrieval", () => client.getServicePeriods(input)),
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
    async (input) => execute("schedule and attendance retrieval", () => client.getSchedules(input)),
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
    async (input) => execute("fiscal-rate retrieval", () => client.getFiscalRates(input)),
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
    async (input) => execute("holiday-calendar retrieval", () => client.getHolidayList(input)),
  );

  server.registerTool(
    "cccap_analyze_payment",
    {
      title: "Analyze CCCAP Payment",
      description: "Retrieve provider-scoped read-only CCCAP inputs and run the deterministic payment engine. Returns expected, conditional, duplicate-guard, or blocked results without performing payment actions.",
      inputSchema: paymentAnalysisSchema.shape,
      annotations: readOnlyAnnotations,
    },
    async (input) => execute("payment analysis", () => getPaymentAnalysis(client, input, input.view), formatPaymentResult),
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
    async (input) => execute("payment-history retrieval", () => client.getPaymentHistory(input)),
  );

  return server;
}