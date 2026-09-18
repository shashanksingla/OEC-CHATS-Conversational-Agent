// Consolidated payment formatter: merges payment-summary-renderer.ts (2026-09-15 consolidation).
import { actionControls, countyPaymentSummary, estimatedMoney, plainMoney, humanizeAttendanceType, numericValue, recordValue, renderActionSections, result, shortDateLabel, tableValue, type ToolResult, DISCLAIMER_AT_RISK, DISCLAIMER_EXPECTED, DISCLAIMER_FORECASTED, DISCLAIMER_GLOBAL, DISCLAIMER_GUARANTEED, PAYMENT_AMOUNT_LEGEND } from '../shared/formatters/shared.js';
import { actionViewMetadata, isNoOpAction, isRecentlyRenderedAction, viewState, type ProviderViewState } from '../shared/formatters/shared.js';
import type { RankedNextAction } from '../shared/situation-envelope.js';

// See attendance-formatter.ts's matching RANKED_ACTION_REASONS for the full rationale.
const PAYMENT_RANKED_ACTION_REASONS: Record<string, string> = {
  "review-absence-limit-risk": "Absence-limit exposure may reduce reimbursable payment.",
  "review-approaching-absence-limit": "Approaching the county absence limit may soon reduce reimbursable payment.",
  "review-pending-parent-confirmations": "Unconfirmed attendance may keep payment conditional.",
  "review-incomplete-attendance": "A check-in or check-out is missing and may affect attendance verification.",
  "retry-payment-analysis": "The payment result is blocked until required source data is available.",
  "review-conditional-payment": "Unresolved attendance issues may add to or reduce this payment.",
  "review-excluded-payment-days": "Some days are excluded from payment pending a data or rate resolution.",
};

// Centralizes response assembly so all payout paths share one contract.
function finalizePayoutResponse(input: {
  capability: "payment-analysis" | "service-period-payout-ledger";
  lines: string[];
  // Raw, pre-view-metadata action intents - kept distinct from the
  // view-aware actions used for rendering/actionControls, matching the
  // pre-existing contract where structuredContent.actionIntents is always
  // the raw list.
  actions: Record<string, unknown>[];
  currentView: ProviderViewState;
  disclaimers: string[];
  responseSections: string[];
  extraStructured?: Record<string, unknown>;
  // Multi-hop loop guard input - see the matching comment on isRecentlyRenderedAction in view-state.ts.
  recentActionSignatures?: unknown;
}): ToolResult {
  const recentSignatures = Array.isArray(input.recentActionSignatures) ? new Set(input.recentActionSignatures as string[]) : undefined;
  const viewAwareActions = input.actions
    .map((action) => actionViewMetadata(action, input.currentView))
    .filter((action) => !isNoOpAction(action, input.currentView) && !isRecentlyRenderedAction(action, recentSignatures));
  const providerMessage = `${renderActionSections(input.lines.join("\n"), viewAwareActions)}\n\n${DISCLAIMER_GLOBAL}`;
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: input.capability,
      providerMessage,
      viewState: input.currentView,
      actionIntents: input.actions,
      actionControls: actionControls(viewAwareActions),
      paymentDisclaimers: [...new Set(input.disclaimers)],
      responseSections: input.responseSections,
      ...input.extraStructured,
    },
  };
}

function atRiskDisclaimer(confirmByDate: unknown): string {
  if (typeof confirmByDate === 'string' && confirmByDate.trim()) {
    return DISCLAIMER_AT_RISK.replace('{deadline}', shortDateLabel(confirmByDate) ?? tableValue(confirmByDate));
  }
  return DISCLAIMER_AT_RISK.replace(' before {deadline}', ' before the confirmation deadline');
}

function paymentDisclaimers(
  payment: Record<string, unknown>,
  paymentResult: Record<string, unknown>,
  attendance: Record<string, unknown>[],
  settled = false,
): string[] {
  const disclaimers = [DISCLAIMER_GLOBAL];
  if (!settled && Number(payment.base_amount ?? payment.expected_amount) > 0) disclaimers.push(DISCLAIMER_EXPECTED);
  if (!settled && Number(payment.scheduled_forecast_amount ?? payment.forecasted_amount) > 0) disclaimers.push(DISCLAIMER_FORECASTED);
  if (!settled && Number(payment.at_risk_amount ?? payment.amount_at_risk) > 0) {
    disclaimers.push(atRiskDisclaimer(
      attendance.find((day) => typeof day.confirm_by_date === "string")?.confirm_by_date
        ?? payment.confirm_by_date
        ?? paymentResult.confirm_by_date,
    ));
  }
  if (Number(payment.guaranteed_amount) > 0) disclaimers.push(DISCLAIMER_GUARANTEED);
  return [...new Set(disclaimers)];
}

/**
 * Plain-language reason for an excluded day, folded into the Attendance
 * type cell in brackets (e.g. "Absence (paid) [absence limit exceeded]")
 * now that the separate Status/Payment columns have been removed.
 */
// Keeps high-risk detail visible while capping the preview at five rows.
const MAX_DETAIL_ROWS = 5;
function detailRowPriority(day: Record<string, unknown>): number {
  const flags = Array.isArray(day.flags) ? day.flags.filter((flag): flag is string => typeof flag === 'string') : [];
  let score = 0;
  if (flags.includes('ABSENCE_LIMIT_EXCEEDED')) score += 4;
  if (flags.includes('PARENT_CONFIRMATION_UNAVAILABLE')) score += 4;
  // Missing transactions and unapproved confirmations are distinct past-window risks.
  if (flags.includes('MISSING_ATTENDANCE_TRANSACTION')) score += 4;
  if (day.classification === 'ABSENCE') score += 1;
  if (day.payment_excluded === true) score += 1;
  return score;
}

// Preserves breadth across children when selecting the detail preview.
function topRankedRowsByChild(days: Record<string, unknown>[]): Record<string, unknown>[] {
  const byChild = new Map<string, { rows: Record<string, unknown>[]; maxPriority: number; totalPriority: number }>();
  for (const day of days) {
    const key = typeof day.child_name === 'string' && day.child_name ? day.child_name : 'UNKNOWN';
    const entry = byChild.get(key) ?? { rows: [], maxPriority: 0, totalPriority: 0 };
    entry.rows.push(day);
    const priority = detailRowPriority(day);
    entry.maxPriority = Math.max(entry.maxPriority, priority);
    entry.totalPriority += priority;
    byChild.set(key, entry);
  }
  // A single-child scope shows that child's highest-priority rows instead of one row.
  if (byChild.size === 1) {
    const entry = byChild.values().next().value;
    if (entry) {
      return [...entry.rows]
        .sort((left, right) => detailRowPriority(right) - detailRowPriority(left))
        .slice(0, MAX_DETAIL_ROWS);
    }
  }
  return [...byChild.values()]
    .sort((left, right) => right.maxPriority - left.maxPriority || right.totalPriority - left.totalPriority)
    .slice(0, MAX_DETAIL_ROWS)
    .map((entry) => [...entry.rows].sort((left, right) => detailRowPriority(right) - detailRowPriority(left))[0])
    .filter((row): row is Record<string, unknown> => Boolean(row));
}

/**
 * Plain-language reason for an excluded day, folded into the Attendance
 * type cell in brackets (e.g. "Absence (paid) [absence limit exceeded]")
 * now that the separate Status/Payment columns have been removed.
 */
function exclusionReason(day: Record<string, unknown>): string {
  const flags = Array.isArray(day.flags) ? day.flags.filter((flag): flag is string => typeof flag === 'string') : [];
  if (flags.includes('ABSENCE_LIMIT_EXCEEDED')) return 'absence limit exceeded';
  if (flags.includes('DROP_IN_LIMIT_EXCEEDED')) return 'drop-in limit exceeded';
  if (flags.includes('FISCAL_RATE_UNAVAILABLE')) return 'rate unavailable';
  if (flags.includes('PARENT_CONFIRMATION_UNAVAILABLE')) return 'confirmation unavailable';
  if (flags.includes('MISSING_ATTENDANCE_TRANSACTION')) return 'check-in/check-out not recorded';
  if (flags.includes('HOLIDAY_ALREADY_PAID') || flags.includes('HOLIDAY_ALREADY_PAID_ON_PAIRED_DATE')) return 'already paid';
  if (flags.includes('PAID_HOLIDAY_NOT_ALLOWED')) return 'holiday not allowed by county plan';
  if (flags.includes('DROP_IN_NOT_ALLOWED')) return 'drop-in not allowed by county plan';
  if (flags.includes('DROP_IN_LIMIT_UNAVAILABLE') || flags.includes('ABSENCE_LIMIT_UNAVAILABLE')) return 'limit unavailable from current source';
  if (flags.includes('AGE_BAND_UNAVAILABLE')) return 'age band unavailable';
  if (flags.includes('ABSENCE_APPROVAL_UNAVAILABLE')) return 'approval status unavailable';
  return 'excluded';
}

function amountWithHours(value: unknown, hours: unknown, estimated = false): string {
  const amount = estimated ? estimatedMoney(value) : plainMoney(value);
  const numericHours = Number(hours);
  return Number.isFinite(numericHours) && numericHours > 0
    ? `${amount} (${numericHours.toFixed(2)}H)`
    : amount;
}

function categoryHoursForAmount(rows: Record<string, unknown>[], field: string): number | undefined {
  const values = rows
    .filter((row) => Number(row[field]) > 0 && Number(row.hours) > 0)
    .map((row) => Number(row.hours));
  return values.length > 0 ? values.reduce((sum, value) => sum + value, 0) : undefined;
}


export function paymentActionMetadata(
  paymentResult: Record<string, unknown>,
  payment: Record<string, unknown>,
  status: string,
  // Cross-capability, dollar/urgency-scored candidates from situation.rankedActions - see the
  // matching comment on attendance-formatter.ts's actionMetadata for the full rationale. This
  // function still owns navigation actions (drill-down/cross-capability links) below.
  rankedActions: RankedNextAction[] = [],
): Record<string, unknown>[] {
  const filterInput = recordValue(paymentResult.filters) ?? {};
  const highestImpactChildName = typeof paymentResult.highestImpactChildName === "string"
    ? paymentResult.highestImpactChildName
    : undefined;
  const highestImpactRankedByDollars = paymentResult.highestImpactRankedByDollars;
  const paymentInput = (overrides: Record<string, unknown>): Record<string, unknown> =>
    Object.assign({ view: paymentResult.paymentView ?? "NEXT_PAYOUT" }, filterInput, overrides);
  if (status === "BLOCKED") {
    return [{
      actionId: "retry-payment-analysis",
      capability: "payment-analysis",
      tool: "cccap_analyze_payment",
      label: "Retry payment review",
      reason: "The payment result is blocked until required source data is available.",
      priority: "high",
      section: "next-actions",
      source: "current-result",
      input: paymentInput({}),
    }];
  }
  const actions: Record<string, unknown>[] = [];
  // Cross-capability, dollar/urgency-scored candidates - replaces the hardcoded risk-driven
  // pushes this function never had explicitly (only the BLOCKED-status retry above), but now
  // also surfaces e.g. an attendance risk found while a sibling result was cached, so a payment
  // response's top action can point at the highest-priority item overall, not just payment's own.
  for (const rankedAction of rankedActions) {
    actions.push({
      actionId: rankedAction.action_id,
      capability: rankedAction.tool === "cccap_analyze_payment_risk" ? "attendance-risk-analysis" : "payment-analysis",
      tool: rankedAction.tool,
      label: rankedAction.label,
      reason: PAYMENT_RANKED_ACTION_REASONS[rankedAction.action_id] ?? "Ranked by payment impact and urgency.",
      priority: rankedAction.priority_score,
      section: "next-actions",
      source: "current-result",
      input: rankedAction.tool === "cccap_analyze_payment" ? paymentInput(rankedAction.input) : rankedAction.input,
    });
  }
  const attendance = recordValue(paymentResult.attendance);
  const returnedRows = Array.isArray(attendance?.days) ? attendance.days.length : 0;
  if (returnedRows > 0) {
    actions.push({
      actionId: highestImpactRankedByDollars === false ? "open-highest-hours-child-detail" : "open-payment-detail",
      capability: "payment-analysis",
      tool: "cccap_analyze_payment",
      label: highestImpactRankedByDollars === false ? "Open highest-scheduled-hours child detail" : "Open highest-impact child payment detail",
      reason: highestImpactRankedByDollars === false
        ? "A verified dollar amount at risk isn't available for this scope yet, so this shows the child with the most scheduled hours instead of the highest dollar impact."
        : "Inspect the child and service-date rows behind this summary.",
      priority: "high",
      section: "drill-down",
      source: "current-result",
      input: paymentInput({
        ...(highestImpactChildName ? { childNames: [highestImpactChildName] } : {}),
      }),
    });
  }
  // Item 4(a): a cross-capability link alongside the payment child-detail
  // action, so a provider following payment's highest-impact child can jump
  // to the same 3-table attendance-risk view (absence/pending/incomplete)
  // for that child, not just its payment amounts. No riskFocus - this always
  // resolves through attendance-formatter.ts's child-scoped-multi-risk view.
  if (highestImpactChildName) {
    const attendanceScopeInput: Record<string, unknown> = { childNames: [highestImpactChildName] };
    const dateFilter = filterInput.dateFilter;
    const dateFrom = filterInput.dateFrom;
    const dateTo = filterInput.dateTo;
    if (typeof dateFilter === "string") attendanceScopeInput.dateFilter = dateFilter;
    if (typeof dateFrom === "string") attendanceScopeInput.dateFrom = dateFrom;
    if (typeof dateTo === "string") attendanceScopeInput.dateTo = dateTo;
    if (!attendanceScopeInput.dateFilter) attendanceScopeInput.dateFilter = "THIS_MONTH";
    actions.push({
      actionId: "open-attendance-risk-for-child",
      capability: "attendance-risk-analysis",
      tool: "cccap_analyze_payment_risk",
      label: "Open attendance-risk detail for this child",
      reason: "See every risk area (absence, pending confirmations, incomplete attendance) for this child, not just the payment figures.",
      priority: "medium",
      section: "drill-down",
      source: "current-result",
      input: attendanceScopeInput,
    });
  }
  if (actions.length === 0) {
    actions.push({
      actionId: "review-payment-summary",
      capability: "payment-analysis",
      label: "Compare payment by county",
      reason: "Compare the estimated payment across the current provider scope.",
      priority: "medium",
      section: "available-views",
      source: "current-result",
      input: paymentInput({}),
    });
  }
  return actions.slice(0, 2);
}

export function paymentSummaryView(value: unknown): Record<string, unknown> | undefined {
  return recordValue(value);
}

export function compactPaymentSummaryView(value: Record<string, unknown> | undefined): Record<string, unknown> | undefined {
  if (!value) return undefined;
  const compact: Record<string, unknown> = {};
  const overview = recordValue(value.overview);
  if (overview) compact.overview = overview;
  for (const key of ["categories", "counties", "children", "vacant_slots", "next_actions"]) {
    const rows = Array.isArray(value[key]) ? value[key] : undefined;
    if (rows && rows.length > 0) compact[`${key}Count`] = rows.length;
  }
  const countyComposition = Array.isArray(value.county_composition)
    ? value.county_composition.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
    : undefined;
  if (countyComposition && countyComposition.length > 0) compact.county_composition = countyComposition;
  return compact;
}

export function summaryRows(value: unknown, key: string): Record<string, unknown>[] {
  const summary = paymentSummaryView(value);
  return summary && Array.isArray(summary[key])
    ? summary[key].map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
    : [];
}
/**
 * Single public entry point for every payout path - NEXT_PAYOUT, LAST_PAYOUT,
 * PAYOUT_LEDGER (multi-period), STATUS, CUSTOM_RANGE, CURRENT_WEEK_FORECAST,
 * and the detail-page drill-down. Dispatches purely on the shape of the raw
 * orchestration result:
 * - `entry` (LedgerPeriodEntry | undefined) or `periods` (array) identifies a
 *   ledger-sourced result from getUpcomingPayoutDetail/getLastPayoutDetail/
 *   getServicePeriodLedger.
 * - `payment` identifies a direct payment-analysis result from
 *   getPaymentAnalysis.
 * Both internal implementations funnel into the same finalizePayoutResponse()
 * for the actual relay/assembly - this dispatcher is the only function any
 * caller needs regardless of which payout path was requested.
 */
export function formatPayoutResult(data: unknown): ToolResult {
  const value = recordValue(data);
  if (value && ("entry" in value || Array.isArray(value.periods))) {
    return formatLedgerResult(data);
  }
  return formatPaymentAnalysisResult(data);
}

// Internal - handles STATUS/CUSTOM_RANGE/CURRENT_WEEK_FORECAST/detail-page
// payment-analysis results. Reached only through formatPayoutResult() above.
function formatPaymentAnalysisResult(data: unknown): ToolResult {
  const paymentResult = recordValue(data);
  const payment = paymentResult && recordValue(paymentResult.payment);
  if (!paymentResult || !payment) return result(data);

  const status = typeof payment.status === "string" ? payment.status.toUpperCase() : "BLOCKED";
  const detailPagination = recordValue(paymentResult.detailPagination);
  const detailPage = detailPagination && Number(detailPagination.page) > 0;
  const paymentFilters = recordValue(paymentResult.filters);
  const requestedTableId = paymentResult.tableId === "payment-county-rollup" || paymentResult.tableId === "vacant-slot-rollup"
    ? paymentResult.tableId
    : undefined;
  const activeTableId = requestedTableId ?? (status === "BLOCKED" && paymentResult.paymentView === "NEXT_PAYOUT"
    ? "payout-summary"
    : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
      ? "forecast-date-detail"
      : detailPage
        ? "sub-payment-detail"
        : "payment-category-rollup");
  const view = paymentResult.paymentView === "NEXT_PAYOUT"
    ? detailPage ? "Upcoming payout detail" : "Upcoming payout summary"
    : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
      ? "Current service-period forecast"
      : "Payment status";
  const servicePeriod = recordValue(paymentResult.servicePeriod);
  // A PAID service period is settled: it must not receive the forward-looking
  // expected/forecasted/at-risk language used by upcoming payment views.
  const isSettled = paymentResult.paymentView === "LAST_PAYOUT"
    || paymentResult.periodStatus === "PAID"
    || payment.periodStatus === "PAID"
    || servicePeriod?.status === "PAID"
    || servicePeriod?.service_period_status === "PAID";
  const attendanceContainer = recordValue(paymentResult.attendance);
  const attendanceDays = attendanceContainer?.["days"];
  const attendance = Array.isArray(attendanceDays)
    ? attendanceDays
        .map(recordValue)
        .filter((row): row is Record<string, unknown> => Boolean(row))
        .filter((row) => row.classification !== "NO_CARE")
    : [];
  const missingInputs = Array.isArray(payment.missing_inputs)
    ? payment.missing_inputs.filter((value): value is string => typeof value === "string")
    : [];
  const summaryView = paymentSummaryView(payment.summary_view);
  const summaryOverview = summaryView ? recordValue(summaryView.overview) : undefined;
  const childrenServed = summaryOverview?.children_served;
  const summaryCategories = summaryRows(summaryView, "categories");
  const scheduledForecastCategory = summaryCategories.find((row) =>
    tableValue(row.label).toLowerCase() === "scheduled forecast",
  );
  const scheduledForecastAmount = scheduledForecastCategory
    ? numericField(scheduledForecastCategory, ["amount"])
    : undefined;
  const scheduledForecastAtRisk = scheduledForecastCategory
    ? numericField(scheduledForecastCategory, ["conditional_amount"])
    : undefined;
  const netPaymentHours = categoryHoursForAmount(summaryCategories, "amount");
  const scheduledForecastHours = categoryHoursForAmount(summaryCategories, "scheduled_forecast");
  const conditionalAtRiskHours = categoryHoursForAmount(summaryCategories, "conditional_amount");
  const baseAmount = numericField(payment, ["base_amount", "amount"]);
  const estimatedTotal = estimatedPaymentTotal(payment, baseAmount, scheduledForecastAmount);
  const engineAmountAtRisk = numericField(payment, ["amount_at_risk", "at_risk_amount"]);
  const hasReconciledAmount = estimatedTotal !== undefined
    && (
      estimatedTotal !== baseAmount
      || payment.vacant_slot_fee !== undefined
      || payment.slot_fee !== undefined
      || scheduledForecastAmount !== undefined
      || engineAmountAtRisk !== undefined
    );
  const attendanceAmountAtRisk = attendanceDerivedAtRisk(attendance);
  const amountAtRiskNumeric = engineAmountAtRisk ?? attendanceAmountAtRisk ?? scheduledForecastAtRisk;
  const displayAmountAtRisk = amountAtRiskNumeric ?? Number.NaN;
  // #9.4 fix: the "~" estimate marker on Net payment/Maximum estimated
  // payout should signal genuine incompleteness (an unavailable/incomplete
  // fiscal rate excluded real days from this total), not appear
  // unconditionally on every response regardless of whether the total is
  // actually exact.
  const hasIncompleteRateData = summaryCategories.some((row) => (Number(row.excluded_days) || 0) > 0);
  const disclaimers = paymentDisclaimers(payment, paymentResult, attendance, isSettled);
  // The Python engine's real duplicate/already-submitted status string is
  // "SUBMITTED" (see provider_risk_payment_engine.py's payment_status
  // assignment) - checking only "DUPLICATE_GUARD" let a genuinely submitted
  // payment fall through to the default "Blocked" label even though the
  // response carries a complete amount/at-risk breakdown, not a block.
  const statusLabel = isSettled
    ? "Paid"
    : status === "DUPLICATE_GUARD" || status === "SUBMITTED"
    ? "Already paid or requested"
    : status === "CONDITIONAL"
      ? "Conditional"
      : status === "EXPECTED"
        ? "Expected"
        : "Blocked";
  const periodBeginLabel = servicePeriod ? shortDateLabel(servicePeriod.serviceBeginDate ?? servicePeriod.start_date) : undefined;
  const periodEndLabel = servicePeriod ? shortDateLabel(servicePeriod.serviceEndDate ?? servicePeriod.end_date) : undefined;
  // shortDateLabel already embeds the 2-digit year (e.g. "31st Aug'26"), so no
  // separate year suffix is appended here - that would duplicate the year.
  const verifiedServicePeriodId = typeof servicePeriod?.servicePeriodId === "string"
    ? servicePeriod.servicePeriodId
    : undefined;
  const periodHeaderLabel = periodBeginLabel && periodEndLabel
    ? `${paymentResult.paymentView === "CUSTOM_RANGE" && !detailPage && (!verifiedServicePeriodId || verifiedServicePeriodId.startsWith("CUSTOM:")) ? "Custom period" : "Service period"}: ${periodBeginLabel}-${periodEndLabel}`
    : undefined;
  const lines = [
    // Bolded: this is the response's "Interpretation" line and mandatory
    // "Scope" line per the conversation-templates contract - previously
    // rendered as plain prose indistinguishable from any other sentence.
    // Status is stated here, not as a separate table row - matching the
    // ledger path's headline-carries-status convention (e.g. "Upcoming
    // payout in 2 days...") so status isn't shown twice.
    `**${view}: ${statusLabel}.**`,
    "",
    // Legend for the status word stated above.
    "> Status: Conditional = some attendance issues remain unresolved for this period. Expected = the confirmation window has elapsed with no unresolved issues. Blocked = payment cannot be estimated from current data. Paid = already released.",
    PAYMENT_AMOUNT_LEGEND,
    "",
    "| Measure | Result |",
    "| --- | --- |",
  ];
  // Row set intentionally matches the ledger path's (NEXT_PAYOUT/LAST_PAYOUT)
  // top summary table exactly - Service period and Payout date first,
  // regardless of status - so the two payout paths present the same shape
  // regardless of which one produced the response, including the BLOCKED
  // case (a blocked result must still say which period it's blocked for).
  // Children served, Excluded authorizations, Existing payment status, and
  // the separate Services from/through/Payment processing/release date/
  // Service-period status rows are no longer shown here: none of those
  // exist in the ledger path's table either, and the information they
  // carried is still available via the county/category tables below (which
  // already break out per-category Scheduled forecast/Vacant slots/
  // Unavailable-days detail) rather than being duplicated at this top level.
  if (periodBeginLabel && periodEndLabel) {
    lines.push(`| ${periodHeaderLabel?.startsWith("Custom period") ? "Custom period" : "Service period"} | ${periodBeginLabel}-${periodEndLabel} |`);
  }
  if (payment.payout_date !== undefined) {
    lines.push(`| Payout date | ${shortDateLabel(payment.payout_date) ?? tableValue(payment.payout_date)} |`);
  } else if (servicePeriod?.paymentReleaseDate !== undefined) {
    lines.push(`| Payout date | ${shortDateLabel(servicePeriod.paymentReleaseDate) ?? tableValue(servicePeriod.paymentReleaseDate)} |`);
  }
  if (status === "BLOCKED") {
    lines.push(
      `| Missing source areas | ${missingInputs.length > 0 ? missingInputs.join(", ") : "Required source data is unavailable"} |`,
      "",
      "No payment amount is shown because the approved source data is incomplete.",
    );
  } else {
    // The "Net payment" figure actually shown in the table below is either
    // the reconciled payableBeforeRisk (when estimatedTotal is available -
    // e.g. scheduled forecast/vacant slots can make this nonzero even when
    // the raw payment.amount net is 0) or the raw payment.amount otherwise.
    // Computed once here, BEFORE the table rows, so the explanatory
    // sentence below can never contradict the actual displayed figure -
    // previously it hardcoded "$0.00 net" and gated on the raw unreconciled
    // payment.amount, so a response with a nonzero reconciled Net payment
    // (e.g. driven entirely by scheduled forecast + vacant slots) still
    // showed a jarring "This shows $0.00 net..." sentence directly under a
    // table row that already read "$6021.50".
    // C1 fix: "Net payment" must be TRUE net - it previously absorbed
    // scheduledForecastAmount via estimatedTotal - atRisk, which silently
    // folded not-yet-earned scheduled care into a "net" figure. That made
    // the top Net payment disagree with the "Payment by category" table's
    // own Net-payment column (which keeps Scheduled forecast separate) and
    // broke the documented legend formula (Maximum estimated payout = net
    // payment + scheduled forecast + conditional at-risk). Net payment now
    // excludes both scheduled forecast and at-risk; Scheduled forecast gets
    // its own row (added only when nonzero) so every visible row sums to
    // Maximum estimated payout, matching the category table exactly.
    const atRiskValue = Number.isFinite(displayAmountAtRisk) ? displayAmountAtRisk : 0;
    const scheduledForecastValue = scheduledForecastAmount ?? 0;
    const trueNetBeforeRisk = estimatedTotal !== undefined
      ? Math.max(0, estimatedTotal - scheduledForecastValue - atRiskValue)
      : undefined;
    const displayedNetPayment = trueNetBeforeRisk !== undefined
      ? (isSettled ? estimatedTotal! : trueNetBeforeRisk)
      : (typeof payment.amount === "number" ? payment.amount : Number(payment.amount));
    if (payment.amount !== undefined && !hasReconciledAmount) {
      lines.push(`| Net payment | ${estimatedMoney(baseAmount ?? payment.amount, hasIncompleteRateData)} |`);
    }
    if (estimatedTotal !== undefined) {
      // Vacant slots remain folded into Net payment (unchanged, matching the
      // ledger path). Scheduled forecast is only surfaced here when nonzero
      // and not settled - NEXT_PAYOUT-style responses (forecast always 0)
      // render with no added row, so this is not a regression for that path.
      lines.push(`| Net payment | ${amountWithHours(displayedNetPayment, netPaymentHours)} |`);
      if (!isSettled && scheduledForecastValue > 0) {
        lines.push(`| Scheduled forecast | ${amountWithHours(scheduledForecastValue, scheduledForecastHours)} |`);
      }
      lines.push(`| Conditional at-risk | ${amountWithHours(isSettled ? 0 : atRiskValue, isSettled ? undefined : conditionalAtRiskHours)} |`);
      // #9.4 fix: "~" now only appears when this total is genuinely
      // incomplete (unavailable/incomplete rate data excluded real days
      // from it) - previously appeared unconditionally on every response.
      const maximumHours = [netPaymentHours, scheduledForecastHours, conditionalAtRiskHours]
        .filter((hours): hours is number => hours !== undefined)
        .reduce((sum, hours) => sum + hours, 0);
      lines.push(`| Maximum estimated payout | ${amountWithHours(estimatedTotal, maximumHours || undefined, hasIncompleteRateData)} |`);
    }
    if (!isSettled && displayedNetPayment === 0 && (atRiskValue > 0 || scheduledForecastValue > 0)) {
      lines.push(
        "",
        `This shows ${plainMoney(0)} net because the payable amount is still conditional or not yet scheduled to occur, not denied - an estimated ${plainMoney(scheduledForecastValue + atRiskValue)} remains possible once scheduled care occurs and the pending confirmations below are completed. This is an estimate and will change as confirmations are completed.`,
        atRiskDisclaimer(attendance.find((day) => typeof day.confirm_by_date === "string")?.confirm_by_date ?? payment.confirm_by_date ?? paymentResult.confirm_by_date),
      );
    }
    // Expected/Forecasted/At-risk breakdown replaces the single "Amount at
    // risk" row above. "Confirmed" is deliberately never used as a label -
    // it would imply the parent affirmatively acted, when Expected here
    // means only that the confirmation window elapsed.
    const singleChildFilter = Array.isArray(recordValue(paymentResult.filters)?.childNames)
      ? (recordValue(paymentResult.filters)?.childNames as unknown[]).length === 1
      : false;
    const hasAmountBreakdown = payment.base_amount !== undefined
      || payment.scheduled_forecast_amount !== undefined
      || payment.amount_at_risk !== undefined
      || payment.expected_amount !== undefined
      || payment.forecasted_amount !== undefined
      || payment.at_risk_amount !== undefined;
    // Expected/Forecasted/At-risk are STATUS-level figures (one number
    // each), folded here as extra rows into the SAME "Payment by category"
    // table below (Table 12) instead of two standalone 1-2 row mini-tables -
    // they reuse that table's existing "Expected amount"/"At-risk amount"
    // columns rather than introducing new columns.
    const breakdownRows: Record<string, unknown>[] = [];
    if (hasAmountBreakdown && detailPage && !isSettled) {
      lines.push(
        "",
        "Net payment - resolved attendance, absence, drop-in, and facility amounts currently included in the estimate.",
        "Scheduled forecast - future authorized schedule days only.",
        "Conditional at-risk - unresolved or excluded amounts that may reduce or increase the final payment.",
      );
      const expectedAmount = Number(payment.base_amount ?? payment.expected_amount) || 0;
      const forecastedAmount = Number(payment.scheduled_forecast_amount ?? payment.forecasted_amount) || 0;
      const breakdownDisclaimers = [
        expectedAmount > 0 ? DISCLAIMER_EXPECTED : undefined,
        forecastedAmount > 0 ? DISCLAIMER_FORECASTED : undefined,
      ].filter((disclaimer): disclaimer is string => Boolean(disclaimer));
      if (breakdownDisclaimers.length > 0) lines.push(breakdownDisclaimers.join(" "));
      breakdownRows.push(
        { label: "Net payment", amount: payment.base_amount ?? payment.expected_amount },
        { label: "Scheduled forecast", amount: payment.scheduled_forecast_amount ?? payment.forecasted_amount },
      );
      breakdownRows.push({ label: "Amount at risk", amount: payment.amount_at_risk ?? payment.at_risk_amount });
    }
    // Table 8 ("County payment totals") retired - County payment
    // composition (rendered further below via renderCountyComposition) is
    // now the only county-level payment table; it already covers this same
    // information with a richer per-category breakdown.
    // An excluded-only request or a single-child drill-down already narrows
    // the detail table to exactly the rows the provider asked about; the
    // category/county/child rollups restate the same totals and are the
    // main contributor to an oversized response for these cases, so they
    // are omitted here rather than rendered and then discarded by the client.
    const suppressRollups = singleChildFilter;
    const categories = suppressRollups ? [] : summaryRows(summaryView, "categories");
    const countyComposition = suppressRollups ? [] : summaryRows(summaryView, "county_composition");
    const childRollup = suppressRollups ? [] : summaryRows(summaryView, "children");
    const vacantSlots = suppressRollups ? [] : summaryRows(summaryView, "vacant_slots");
    const nextActions = summaryRows(summaryView, "next_actions");
    // Folded-in Expected/Forecasted/At-risk breakdown rows (see
    // breakdownRows above) append to whatever category rows already exist,
    // so a detail-page response with a real category breakdown gets both in
    // ONE table instead of the table plus two standalone mini-tables.
    const categoriesWithBreakdown = splitConditionalScheduledForecast(categories);
    // "forecast-date-detail" (CURRENT_PERIOD_FORECAST's activeTableId) is
    // included here alongside the default "payment-category-rollup" -
    // previously this table only ever rendered for STATUS/CUSTOM_RANGE
    // views, so a forecast response showed county composition but never
    // the category breakdown, even though `categories` was already
    // computed and available. Mirrors the same fix already applied to the
    // county-composition condition just below.
    if (activeTableId === "payment-category-rollup" || activeTableId === "forecast-date-detail" || activeTableId === "payout-summary") {
      const categoryRows = [...categoriesWithBreakdown];
      const vacantSlotAmount = vacantSlots.reduce((total, row) => total + (Number(row.amount) || 0), 0);
      const vacantSlotCategoryAmount = payment.vacant_slot_fee ?? (vacantSlots.length > 0 ? vacantSlotAmount : undefined);
      if (vacantSlotCategoryAmount !== undefined
        && !categoryRows.some((row) => ["vacant slots", "vacant-slot amount"].includes(tableValue(row.label).toLowerCase()))) {
        // days: vacantSlots.length - the count of vacant-slot-day records
        // backing vacantSlotCategoryAmount. Previously omitted, so this
        // synthesized row always showed 0 Days in "Payment by category"
        // (normalizedCategoryRows sums Number(row.days), and undefined ->
        // NaN is skipped) even though the amount rendered correctly. No
        // `hours` field is added - vacant slots are a flat facility-level
        // fee per day, not attendance/hour-based (the dedicated "Vacant
        // slots (separate from child payments)" table below also has no
        // Hours column), so Care hours legitimately has no source value here.
        categoryRows.push({ label: "Vacant slots", amount: vacantSlotCategoryAmount, days: vacantSlots.length });
      }
      const categoryRisk = categoryRows.reduce((sum, row) => sum + (numericField(row, ["conditional_amount"]) ?? 0), 0);
      if (Number.isFinite(displayAmountAtRisk) && displayAmountAtRisk > categoryRisk) {
        categoryRows.push({ label: "Amount at risk", conditional_amount: displayAmountAtRisk - categoryRisk });
      }
      if (categoryRows.length === 0) {
        categoryRows.push({ label: "Regular care", amount: payment.base_amount ?? payment.amount });
      }
      if (countyComposition.length > 0) {
        lines.push(...renderCountyCategoryTable(countyComposition, estimatedTotal, childrenServed));
      }
      lines.push(...renderPaymentCategorySection("Payment by category:", categoryRows, estimatedTotal, childrenServed));
    }
    // County detail (the flat Days/Hours/Expected/At-risk/Excluded rollup)
    // has been merged into County payment composition below - it now
    // renders unconditionally instead of only for a summary (!detailPage)
    // view, so the county breakdown no longer reshapes entirely between a
    // payout summary and a payout detail response.
    // "forecast-date-detail" (CURRENT_PERIOD_FORECAST's activeTableId) was
    // missing from this condition, so a forecast summary showed only a
    // single "Estimated total" figure with no county-level breakdown - the
    // composition data (auth/vacant-slot/paid-holiday/drop-in amounts) was
    // already computed and available, just never rendered for this view.
    if (countyComposition.length > 0 && activeTableId === "payment-county-rollup") {
      lines.push(...renderCountyCategoryTable(countyComposition, estimatedTotal, childrenServed));
    }
    if (childRollup.length > 0 && activeTableId === "payment-category-rollup") {
      // A child name alone does not uniquely identify a child - joining
      // every authorization number the rollup's days came from (there can
      // be more than one per child) disambiguates duplicate names.
      const authorizationCell = (row: Record<string, unknown>): string => {
        const names = Array.isArray(row.authorization_names)
          ? row.authorization_names.filter((name): name is string => typeof name === "string" && name.length > 0)
          : [];
        return names.length > 0 ? names.join(", ") : "Unavailable from the current source";
      };
      // Item 4(b): a quick attendance-risk signal per child, derived from
      // this same response's already-fetched attendance day flags, so the
      // payment table carries a signal without requiring the extra hop to
      // open-attendance-risk-for-child. Never fabricates a risk that isn't
      // backed by a verified flag on one of this child's own days.
      const attendanceRiskTag = (childName: unknown): string => {
        const childDays = attendance.filter((day) => day.child_name === childName);
        if (childDays.length === 0) return "Unavailable from the current source";
        const tags = new Set<string>();
        for (const day of childDays) {
          const flags = Array.isArray(day.flags) ? day.flags.filter((flag): flag is string => typeof flag === "string") : [];
          if (flags.includes("ABSENCE_LIMIT_EXCEEDED") || flags.includes("ABSENCE_LIMIT_APPROACHING")) tags.add("Absence");
          if (flags.includes("PARENT_CONFIRMATION_UNAVAILABLE")) tags.add("Pending confirmation");
          if (flags.includes("MISSING_ATTENDANCE_TRANSACTION")) tags.add("Incomplete attendance");
        }
        return tags.size > 0 ? [...tags].join(", ") : "None";
      };
      lines.push("", "Child detail:", "> This shows the payment measures behind the selected child scope; net payment and conditional amounts are kept separate. Attendance risk summarizes this same response's day-level flags - open the attendance-risk detail action below for the complete breakdown.", "| Child | Authorization | Days | Care hours | Net payment | Conditional at-risk | Excluded days | Attendance risk |", "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |", ...childRollup.map((row) => `| ${tableValue(row.label)} | ${authorizationCell(row)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} | ${attendanceRiskTag(row.label)} |`));
    }
    // Vacant-slot contract data is a separate payment scenario that doesn't
    // depend on attendance - it now renders by default alongside the
    // category table for any date/period-scoped summarization (not just the
    // dedicated vacant-slot-rollup drill-down), per the spec's "include a
    // separate table for vacant slot contract counts" requirement. Still
    // excluded from single-child/excluded-only views via suppressRollups
    // (vacant slots are facility-level, not tied to any one child).
    if (vacantSlots.length > 0 && (activeTableId === "vacant-slot-rollup" || activeTableId === "payment-category-rollup")) {
      // Rollup by county (Total days | Total amount) instead of one row per
      // slot-day - a provider gets the facility-level total at a glance;
      // the full day-by-day breakdown is available through the drill-down
      // action below rather than dumped inline every time.
      const vacantSlotsByCounty = new Map<string, { county: string; days: number; amount: number }>();
      for (const row of vacantSlots) {
        const countyName = tableValue(row.county_name);
        const current = vacantSlotsByCounty.get(countyName) ?? { county: countyName, days: 0, amount: 0 };
        current.days += 1;
        current.amount += Number(row.amount) || 0;
        vacantSlotsByCounty.set(countyName, current);
      }
      lines.push("", "Vacant slots (separate from child payments):", "> This is a facility-level vacant-slot amount and is kept separate from child attendance payments.", "| County | Total days | Total amount |", "| --- | ---: | ---: |", ...[...vacantSlotsByCounty.values()].map((row) => `| ${row.county} | ${row.days} | ${plainMoney(row.amount)} |`));
    }
    // The inline "Payment next actions:" block (built from
    // summaryView.next_actions) previously rendered alongside the separate
    // "**Recommended actions**" section (built from paymentActionMetadata()
    // via renderActionSections/finalizePayoutResponse), so a response could
    // show two competing action lists - one prose list of "next actions"
    // and one numbered list of "recommended actions" - for the same result.
    // Per explicit request, only the single obvious drill-down action list
    // (paymentActionMetadata -> "**Recommended actions**") is kept; the
    // duplicate inline list is intentionally not rendered here anymore.
    // nextActions itself is left in place (still consumed by
    // compactPaymentSummaryView/structuredContent) in case a future action
    // needs the raw rows, just not rendered as a second text block.
    void nextActions;
    if (numericValue(payment.total_amount_incorrectly_at_risk) > 0) {
      lines.push(
        "",
        `Holiday-classification mismatch affecting ${plainMoney(payment.total_amount_incorrectly_at_risk)} - see detail table below.`,
      );
    }
    if (paymentResult.highestImpactRankedByDollars === false && !detailPage) {
      lines.push(
        "",
        "A verified dollar amount at risk isn't available for this scope yet, so the drill-down below shows the child with the most scheduled hours instead of the highest dollar impact.",
      );
    }
    if (attendance.length > 0 && detailPage) {
      const forecastBasisRows = paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
        && attendance.some((day) => day.attendance_basis === "ACTUAL" || day.attendance_basis === "SCHEDULED");
      // actual_hours_total/scheduled_hours_total arrive as decimal-formatted
      // strings from the Python engine (e.g. "5.00"), not numbers - numericValue()
      // requires typeof "number" and would always read these as 0.
      const actualHoursTotal = Number(attendanceContainer?.actual_hours_total) || 0;
      const scheduledHoursTotal = Number(attendanceContainer?.scheduled_hours_total) || 0;
      if (forecastBasisRows && actualHoursTotal > 0 && scheduledHoursTotal > 0) {
        lines.push(
          "",
          `Actual (checked in): ${tableValue(attendanceContainer?.actual_hours_total)} hours. Scheduled (projected): ${tableValue(attendanceContainer?.scheduled_hours_total)} hours.`,
        );
      }
      // Rank by risk and spread across distinct children - a single child's
      // tied absence-limit days must not crowd out every other affected
      // child, so at most MAX_DETAIL_ROWS children are shown, each
      // contributing their own single highest-priority row. The "Open next
      // payment detail page" action still walks the full paginated set for
      // a provider who wants everything.
      const displayedAttendance = topRankedRowsByChild(attendance);
      const distinctChildCount = new Set(attendance.map((day) => typeof day.child_name === "string" ? day.child_name : "UNKNOWN")).size;
      // Fetched-vs-shown reconciliation: detailPagination describes the raw
      // page fetched from the source (e.g. rows 1-25 of 153), but the table
      // below only ever renders up to MAX_DETAIL_ROWS ranked rows out of
      // that page. Stating the fetched range alone (the old "Showing detail
      // rows..." wording) previously implied the full page would be listed
      // below it - both figures are now stated together on one line so they
      // reconcile instead of contradicting each other.
      const pageLabel = detailPagination
        ? `Fetched rows ${((Number(detailPagination.page) - 1) * Number(detailPagination.pageSize)) + 1}-${Math.min(Number(detailPagination.page) * Number(detailPagination.pageSize), Number(detailPagination.totalRows))} of ${tableValue(detailPagination.totalRows)} for this page (page ${tableValue(detailPagination.page)}; page size ${tableValue(detailPagination.pageSize)}) - showing the top ${displayedAttendance.length} by risk below.`
        : "";
      const rankedNote = distinctChildCount > displayedAttendance.length
        ? `Top ${displayedAttendance.length} of ${distinctChildCount} affected children, ranked by risk.`
        : "";
      // "Care hours" renamed to "Scheduled hours" - for every classification
      // except Drop-in, unit_hours represents the authorized/scheduled
      // figure (min(auth,actual) for Regular, authorized hours for
      // Absence/Holiday/Enrollment). Drop-in is the one exception: there is
      // no authorization for a drop-in day by definition, so the engine
      // sets unit_hours = attended_hours for those rows - calling that
      // "Scheduled hours" would mislabel an actual-attendance figure as a
      // pre-scheduled one. Drop-in rows omit this column value entirely
      // (rendered as "—") and rely on Attended hours alone.
      const detailHeaders = forecastBasisRows
        ? ["Child", "Authorization", "County", "Service date", "Attendance type", "Basis", "Attended hours", "Scheduled hours"]
        : ["Child", "Authorization", "County", "Service date", "Attendance type", "Attended hours", "Scheduled hours"];
      const detailRows = displayedAttendance.map((day) => {
        const basis = day.attendance_basis === "ACTUAL"
          ? "Actual (checked in)"
          : day.attendance_basis === "SCHEDULED"
            ? "Scheduled (projected)"
            : "";
        // Status/Payment columns are removed (both read as confusing side-by-
        // side yes/no flags); the exclusion reason is folded directly into
        // the Attendance type cell in brackets so exclusion is unambiguous
        // without a separate column. "(paid)" is dropped from the label
        // itself when the day is actually excluded - calling an excluded
        // day "Absence (paid)" is self-contradictory; the bracket already
        // states why it isn't being paid.
        const baseTypeLabel = day.payment_excluded === true
          ? humanizeAttendanceType(day.classification).replace(/\s*\(paid\)/i, "")
          : humanizeAttendanceType(day.classification);
        const attendanceTypeCell = day.payment_excluded === true
          ? `${baseTypeLabel} [${exclusionReason(day)}]`
          : baseTypeLabel;
        const serviceDateLabel = shortDateLabel(day.service_date) ?? tableValue(day.service_date);
        // A child's name alone does not uniquely identify them - the
        // authorization number is the disambiguator when duplicate child
        // names exist, so it is always shown alongside the child column.
        const authorizationCell = tableValue(day.authorization_name ?? day.authorization_id ?? "Unavailable from the current source");
        // Drop-in has no authorization for that day, so unit_hours is set
        // to attended_hours by the engine - there is nothing "scheduled"
        // about it. Omit the value there rather than mislabel it.
        const scheduledHoursCell = day.classification === "DROP_IN" ? "—" : tableValue(day.unit_hours);
        return forecastBasisRows
          ? [tableValue(day.child_name), authorizationCell, tableValue(day.county_name ?? "Unavailable from the current source"), serviceDateLabel, attendanceTypeCell, basis, tableValue(day.attended_hours), scheduledHoursCell]
          : [tableValue(day.child_name), authorizationCell, tableValue(day.county_name ?? "Unavailable from the current source"), serviceDateLabel, attendanceTypeCell, tableValue(day.attended_hours), scheduledHoursCell];
      });
      const numericDetailColumns = forecastBasisRows ? [6, 7] : [5, 6];
      lines.push("", "Detail by child and service date:", ...(pageLabel ? [pageLabel] : []), ...renderNumericTable(detailHeaders, detailRows, numericDetailColumns));
    }
    // The text-only "Detail available: N rows" fallback (for when
    // detailPagination reports rows but attendance.days was empty) is
    // removed: the live orchestration now always populates a small preview
    // whenever totalRows > 0, so attendance.length is never 0 with a
    // nonzero totalRows on the real runtime path. The two branches above
    // (attendance.length > 0 && !detailPage -> preview table; else -> full
    // ranked table) already cover every reachable case.
  }
  const paymentViewId = activeTableId === "payment-county-rollup"
    ? "PAYMENT_COUNTY_ROLLUP" as const
    : activeTableId === "vacant-slot-rollup"
      ? "VACANT_SLOT_ROLLUP" as const
      : paymentResult.paymentView === "NEXT_PAYOUT"
    ? "NEXT_UPCOMING_PAYOUT" as const
    : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
      ? "CURRENT_SERVICE_PERIOD_FORECAST" as const
      : detailPage
        ? "SUB_PAYMENT_DETAIL" as const
        : "PAYMENT_CATEGORY_ROLLUP" as const;
  const currentView = viewState({
    viewId: paymentViewId,
    tableId: activeTableId,
    tableTitle: activeTableId === "payment-county-rollup"
      ? "Payment by county"
      : activeTableId === "vacant-slot-rollup"
        ? "Vacant-slot payments"
        : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
      ? "Current service-period forecast"
      : paymentResult.paymentView === "NEXT_PAYOUT"
        ? "Next upcoming payout"
        : detailPage
          ? "Sub-payment detail"
          : "Payment category summary",
    tableDescription: activeTableId === "payment-county-rollup"
      ? "This table compares children served, care hours, net payment amount, and conditional at-risk amount by county."
      : activeTableId === "vacant-slot-rollup"
        ? "This table keeps facility-level vacant-slot amounts separate from child attendance payments."
        : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
      ? "This table projects scheduled and attended services into the current service-period payment estimate."
      : paymentResult.paymentView === "NEXT_PAYOUT"
        ? "This table shows the next upcoming service-period payout and its current payment status."
        : detailPage
          ? "This table replaces the payment summary with the child and service-date rows behind the selected payment result."
          : "This table groups the requested payment result into decision-ready payment categories.",
    ...(detailPage ? { parentViewId: "PAYMENT_CATEGORY_ROLLUP" as const } : {}),
    scope: paymentResult.scope,
        ...(paymentFilters ? { filters: paymentFilters } : {}),
        ...(typeof paymentResult.sourceRetrievedAt === "string" ? { sourceRetrievedAt: paymentResult.sourceRetrievedAt } : {}),
        ...(typeof paymentResult.rule_version === "string" ? { ruleVersion: paymentResult.rule_version } : {}),
    ...(detailPagination ? {
      page: numericValue(detailPagination.page),
      pageSize: numericValue(detailPagination.pageSize),
      totalRows: numericValue(detailPagination.totalRows),
    } : {}),
  });
  const paymentRankedActions = Array.isArray(recordValue(paymentResult.situation)?.rankedActions) ? recordValue(paymentResult.situation)!.rankedActions as RankedNextAction[] : [];
  const actionIntents = paymentActionMetadata(paymentResult, payment, status, paymentRankedActions);
  if (detailPage) {
    const parentInput = { ...(paymentFilters ?? {}) } as Record<string, unknown>;
    delete parentInput.detailPage;
    delete parentInput.detailPageSize;
    actionIntents.push({
      actionId: "return-to-payment-summary",
      capability: "payment-analysis",
      tool: "cccap_analyze_payment",
      label: "Return to payment category summary",
      reason: "Go back to the parent payment view without widening the verified provider scope.",
      priority: "medium",
      // Item 2: "navigation" was never read by renderActionSections at all
      // (it only collects next-actions/drill-down/available-views), so this
      // action previously never rendered in the text list, only in the raw
      // actionControls. "return" is the dedicated, always-last, uncapped
      // bucket renderActionSections now reads.
      section: "return",
      source: "current-result",
      input: { ...parentInput, viewId: "PAYMENT_CATEGORY_ROLLUP" },
    });
  }
  const providerSummaryRows = summaryView && Array.isArray(summaryView.county_composition)
    ? summaryView.county_composition
    : Array.isArray(payment.summary) ? payment.summary : [];
  const providerSummaryInput = providerSummaryRows
    .map(recordValue)
    .filter((row): row is Record<string, unknown> => Boolean(row))
    .map((row) => {
      if (typeof row.county_name === "string") return row;
      const component = (key: string, field: string): number => {
        const value = recordValue(row[key])?.[field];
        return typeof value === "number" ? value : Number(value ?? 0);
      };
      return {
        county_name: row.county,
        children_served: row.children_served,
        hours: component("care", "hours") + component("absence", "hours") + component("enrollment_absence", "hours") + component("drop_in", "hours") + component("paid_holidays", "hours"),
        amount: component("care", "amount") + component("absence", "amount") + component("enrollment_absence", "amount") + component("drop_in", "amount") + component("paid_holidays", "amount"),
        conditional_amount: row.amount_at_risk,
      };
    });
  const providerSummary = providerSummaryInput.length > 0
    ? countyPaymentSummary(providerSummaryInput).map((row) => ({
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
  return finalizePayoutResponse({
    capability: "payment-analysis",
    lines,
    actions: actionIntents,
    currentView,
    disclaimers,
    responseSections: ["summary", "next-actions", "drill-down", "available-views"],
    recentActionSignatures: paymentResult.recentActionSignatures,
    extraStructured: {
      scope: paymentResult.scope,
      paymentView: paymentResult.paymentView,
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
      filters: paymentResult.filters,
      responseContext: {
        scope: paymentResult.scope,
        sourceRetrievedAt: paymentResult.sourceRetrievedAt,
        paymentView: paymentResult.paymentView,
        filters: paymentResult.filters,
        resultStatus: paymentResult.status,
      },
    },
  });
}

// Internal - handles NEXT_PAYOUT/LAST_PAYOUT/PAYOUT_LEDGER ledger-sourced
// results. Reached only through formatPayoutResult() below.
function formatLedgerResult(data: unknown): ToolResult {
  const value = recordValue(data);
  if (!value) return result(data);
  const labels: Record<string, string> = { NOT_YET_STARTED: "Not yet started", IN_PROGRESS: "In progress", PENDING_CONFIRMATION: "Pending confirmation", EXPECTED_AWAITING_PAYOUT: "Expected, awaiting payout", OVERDUE: "Overdue, needs follow-up", PAID: "Paid" };
  // shortDateLabel already embeds the 2-digit year (e.g. "31st Aug'26"), so no
  // separate year suffix is appended here.
  const dateLabel = (date: unknown): string => shortDateLabel(date) ?? "Unavailable from the current source";
  const entry = recordValue(value.entry);
  const periods = Array.isArray(value.periods) ? value.periods.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row)) : undefined;
  const upcoming = periods?.filter((period) => period.periodStatus !== "PAID").sort((a, b) => String(a.payoutDate ?? "").localeCompare(String(b.payoutDate ?? "")))[0];
  const multiPeriod = value.periodMode === "MULTI_PERIOD" || (periods?.length ?? 0) > 1;
  const lines: string[] = [];
  // Unlike formatPaymentResult (which always synthesizes a "Vacant slots"
  // category row from payment.vacant_slot_fee when the python engine's
  // categories list doesn't include one - vacant slot days are never part
  // of the attendance_days loop that builds `categories`), this ledger
  // path never did that synthesis at all. The result: the "Vacant slots"
  // row in "Payment by category" always rendered as the all-zero fallback
  // template (no matching aggregate found) for NEXT_PAYOUT/LAST_PAYOUT/
  // PAYOUT_LEDGER, even though the period's real vacant-slot fee was
  // available the whole time on countyComposition[].vacant_slots.amount -
  // the exact "correct amount doesn't flow there" gap.
  const ledgerCategoryRows = (period: Record<string, unknown> | undefined): Record<string, unknown>[] => {
    if (!period) return [];
    const rows = Array.isArray(period.categories)
      ? period.categories.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
      : [];
    if (rows.length === 0 && (period.baseAmount !== undefined || period.calculatedAmount !== undefined || period.netAmount !== undefined)) {
      rows.push({ label: "Regular care", amount: period.baseAmount ?? period.calculatedAmount ?? period.netAmount });
    }
    const hasVacantSlotsRow = rows.some((row) => tableValue(row.label).toLowerCase() === "vacant slots");
    if (!hasVacantSlotsRow) {
      const countyComposition = Array.isArray(period.countyComposition)
        ? period.countyComposition.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
        : [];
      // county.vacant_slots already carries both {days, amount} from the
      // Python engine (provider_risk_payment_engine.py's
      // slot_county["vacant_slots"]["days"] += 1) - only amount was summed
      // here previously, so this row's Days column always showed 0 even
      // though the day count was available on the exact same object. No
      // `hours` - vacant slots are a flat per-day facility fee, not
      // hour-based (see the matching comment in formatPaymentAnalysisResult).
      const vacantSlotTotals = countyComposition.reduce((sum: { amount: number; days: number }, county) => {
        const vacantSlots = recordValue(county.vacant_slots);
        return {
          amount: sum.amount + (Number(vacantSlots?.amount) || 0),
          days: sum.days + (Number(vacantSlots?.days) || 0),
        };
      }, { amount: 0, days: 0 });
      if (vacantSlotTotals.amount > 0) rows.push({ label: "Vacant slots", amount: vacantSlotTotals.amount, days: vacantSlotTotals.days });
    }
    return rows;
  };
  if (periods) {
    // A row shows exactly one of Net (released/paid, historical) or
    // Calculated (not yet released, a current estimate) - never both, and
    // never the guaranteed-amount field mislabeled as "Calculated".
    const renderPeriodRow = (period: Record<string, unknown>): string => {
      const begin = dateLabel(period.serviceBeginDate), end = dateLabel(period.serviceEndDate);
      const servicePeriod = begin !== "Unavailable from the current source" && end !== "Unavailable from the current source" ? `${begin}-${end}` : "Unavailable from the current source";
      const maximum = money(period.estimatedTotal ?? period.potentialTotal);
      const risk = money(period.amountAtRisk);
      return `| ${tableValue(servicePeriod)} | ${tableValue(dateLabel(period.payoutDate))} | ${tableValue(labels[String(period.periodStatus)] ?? "Unavailable from the current source")} | ${plainMoney(Math.max(0, maximum - risk))} | ${plainMoney(period.scheduledForecastAmount)} | ${plainMoney(risk)} | ${plainMoney(maximum)} |`;
    };
    // Headline figure uses whichever of Net/Calculated is populated for the
    // soonest period - a released period never reaches here as "upcoming"
    // (getUpcomingPayoutDetail/the ledger's own upcoming filter excludes
    // PAID rows), so this is effectively always Calculated, but the
    // fallback keeps the sentence accurate if that ever changes.
    const upcomingHeadlineAmount = upcoming?.calculatedAmount ?? upcoming?.netAmount;
    // Legend for the Status column's five possible values - added so a
    // provider doesn't have to guess what "Not yet started" vs "Expected,
    // awaiting payout" actually mean relative to each other.
    const statusLegend = "> Status: Not yet started = period hasn't begun · In progress = today falls within this period · Pending confirmation = period ended, within the 9-day confirmation window · Expected, awaiting payout = confirmation window passed, not yet due · Overdue, needs follow-up = payout date has passed with no confirmed payment - review this period directly · Paid = released and settled.";
    if (multiPeriod) {
      lines.push(`**Showing ${periods.length} service periods from the verified payout ledger. The soonest upcoming payout has a maximum estimate of ${estimatedMoney(upcoming?.estimatedTotal ?? upcomingHeadlineAmount)}.**`);
      lines.push("", PAYMENT_AMOUNT_LEGEND, "> This ledger shows net payment, future scheduled forecast, conditional at-risk, and maximum estimated payout for each service period.", statusLegend, "| Service period | Payout date | Status | Net payment | Scheduled forecast | Conditional at-risk | Maximum estimated payout |", "| --- | --- | --- | ---: | ---: | ---: | ---: |", ...periods.map(renderPeriodRow), `| Total |  |  |  |  | ${plainMoney(periods.reduce((sum, period) => sum + Number(period.amountAtRisk || 0), 0))} | ${plainMoney(periods.reduce((sum, period) => sum + Number(period.estimatedTotal ?? period.potentialTotal ?? 0), 0))} |`);
      // "Payment by category" was previously never rendered anywhere in this
      // formatter (only county composition was) - shown here for the
      // soonest upcoming period only (not every row) to avoid cluttering a
      // multi-period table with N separate category breakdowns.
      const upcomingCategories = ledgerCategoryRows(upcoming);
      if (upcomingCategories.length > 0) {
        lines.push(...renderPaymentCategorySection(`Payment by category (soonest upcoming period, ${dateLabel(upcoming?.serviceBeginDate)}-${dateLabel(upcoming?.serviceEndDate)}):`, upcomingCategories, upcoming?.estimatedTotal ?? upcoming?.potentialTotal, upcoming?.childrenServed));
      }
    } else if (upcoming) {
        const upcomingMaximum = money(upcoming.estimatedTotal ?? upcoming.potentialTotal);
        const upcomingRisk = money(upcoming.amountAtRisk);
        lines.push(`**Showing the next upcoming service period only: maximum estimated payout ${estimatedMoney(upcomingMaximum)}, on ${dateLabel(upcoming.payoutDate)}.**`, "", PAYMENT_AMOUNT_LEGEND, "> This shows only the single next unpaid or upcoming payout identified from verified data.", "| Measure | Result |", "| --- | --- |", `| Service period | ${dateLabel(upcoming.serviceBeginDate)}-${dateLabel(upcoming.serviceEndDate)} |`, `| Payout date | ${dateLabel(upcoming.payoutDate)} |`, `| Status | ${tableValue(labels[String(upcoming.periodStatus)] ?? "Unavailable from the current source")} |`, `| Children served | ${tableValue(upcoming.childrenServed)} |`, `| Net payment | ${plainMoney(Math.max(0, upcomingMaximum - upcomingRisk))} |`, `| Scheduled forecast | ${plainMoney(upcoming.scheduledForecastAmount)} |`, `| Conditional at-risk | ${plainMoney(upcomingRisk)} |`, `| Maximum estimated payout | ${plainMoney(upcomingMaximum)} |`);
      const upcomingCategories = ledgerCategoryRows(upcoming);
      if (upcomingCategories.length > 0) {
        if (Array.isArray(upcoming.countyComposition) && upcoming.countyComposition.length > 0) lines.push(...renderCountyCategoryTable(upcoming.countyComposition.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row)), upcoming.estimatedTotal ?? upcoming.potentialTotal, upcoming.childrenServed));
        lines.push(...renderPaymentCategorySection("Payment by category:", upcomingCategories, upcoming.estimatedTotal ?? upcoming.potentialTotal, upcoming.childrenServed));
      }
    } else {
      lines.push("No upcoming unpaid payout is currently identified from verified data.");
    }
  } else if (entry) {
    const days = value.daysUntilPayout;
    const countdown = typeof days === "number" ? `${days} day${days === 1 ? "" : "s"}` : "an undetermined number of days";
    const isLastPayout = entry.periodStatus === "PAID";
    const entryAmount = isLastPayout ? entry.netAmount : entry.calculatedAmount;
    lines.push(isLastPayout
      ? `Your last payout was released on ${dateLabel(entry.payoutDate)}.`
      : `Upcoming payout in ${countdown}, on ${dateLabel(entry.payoutDate)}.`);
    const entryMaximum = money(entry.estimatedTotal ?? entry.potentialTotal ?? entry.calculatedAmount ?? entry.netAmount);
    const entryRisk = isLastPayout ? 0 : money(entry.amountAtRisk);
    lines.push("", PAYMENT_AMOUNT_LEGEND, "", "| Measure | Result |", "| --- | --- |", `| Service period | ${dateLabel(entry.serviceBeginDate)}-${dateLabel(entry.serviceEndDate)} |`, `| Payout date | ${dateLabel(entry.payoutDate)} |`, `| Net payment | ${plainMoney(Math.max(0, entryMaximum - entryRisk))} |`, `| Conditional at-risk | ${plainMoney(entryRisk)} |`, `| Maximum estimated payout | ${plainMoney(entryMaximum)} |`);
    lines.push(!isLastPayout && Number(entry.amountAtRisk) > 0
      ? atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)
      : DISCLAIMER_EXPECTED);
    // County payment composition now shown for a single-entry response too
    // (NEXT_PAYOUT/LAST_PAYOUT), not only for the multi-period ledger or
    // CURRENT_PERIOD_FORECAST - LedgerPeriodEntry.countyComposition threads
    // this through from the same underlying payment analysis.
    const entryCountyComposition = Array.isArray(entry.countyComposition)
      ? entry.countyComposition.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
      : [];
    // County composition is rendered once, immediately before categories.
    // "Payment by category" (Care/Absence/Drop-in/Holiday breakdown) was
    // never rendered anywhere in this formatter before - only county
    // composition was. LedgerPeriodEntry.categories threads this through
    // from the same underlying payment analysis as countyComposition above.
    const entryCategories = ledgerCategoryRows(entry);
    if (entryCategories.length > 0) {
      if (entryCountyComposition.length > 0) lines.push(...renderCountyCategoryTable(entryCountyComposition, entry.estimatedTotal ?? entry.potentialTotal, entry.childrenServed));
      lines.push(...renderPaymentCategorySection("Payment by category:", entryCategories, entry.estimatedTotal ?? entry.potentialTotal, entry.childrenServed));
    }
  } else lines.push("No upcoming payout is currently identified from verified data.");
  const isLastPayoutEntry = Boolean(entry) && !periods && entry?.periodStatus === "PAID";
  const ledgerDisclaimers = [
    DISCLAIMER_GLOBAL,
    ...(entry && !isLastPayoutEntry && Number(entry.amountAtRisk) > 0
      ? [atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)]
      : entry && !isLastPayoutEntry ? [DISCLAIMER_EXPECTED] : []),
  ];
  const ledgerScope = recordValue(value.scope);
  const selectedPeriod = upcoming ?? entry;
  // CUSTOM_RANGE's schema caps a span at 31 days; a service period longer
  // than that would make the drill-down request itself fail validation. Fall
  // back to STATUS only for that rare case, rather than constructing a
  // request the schema is guaranteed to reject.
  const selectedPeriodSpanDays = selectedPeriod?.serviceBeginDate && selectedPeriod?.serviceEndDate
    ? Math.round(
        (Date.parse(`${String(selectedPeriod.serviceEndDate)}T00:00:00Z`) - Date.parse(`${String(selectedPeriod.serviceBeginDate)}T00:00:00Z`))
          / 86400000,
      ) + 1
    : undefined;
  const ledgerInput = selectedPeriod?.serviceBeginDate && selectedPeriod?.serviceEndDate
    ? {
        // CUSTOM_RANGE (FORECAST mode), not STATUS - the ledger's own
        // per-period figure for this exact date range was already computed
        // via CUSTOM_RANGE in getServicePeriodLedger. Routing this drill-down
        // through the stricter STATUS mode instead re-evaluates the same
        // dates under a different, more fail-closed mode and can block on
        // "ambiguous mapping" even though the ledger already showed a
        // complete at-risk breakdown for the identical period - a dead end
        // for a provider following "show me the detail behind this number."
        view: (selectedPeriodSpanDays !== undefined && selectedPeriodSpanDays > 31) ? "STATUS" : "CUSTOM_RANGE",
        dateFilter: "DATE_RANGE",
        dateFrom: String(selectedPeriod.serviceBeginDate),
        dateTo: String(selectedPeriod.serviceEndDate),
      }
    : {
        view: "NEXT_PAYOUT",
        ...(ledgerScope?.dateFilter ? { dateFilter: ledgerScope.dateFilter } : {}),
        ...(ledgerScope?.dateFrom ? { dateFrom: ledgerScope.dateFrom } : {}),
        ...(ledgerScope?.dateTo ? { dateTo: ledgerScope.dateTo } : {}),
      };
  // Multi-period ledger: offer the "next" period first, then up to 2 more
  // individual periods (excluding whichever one is already "next") as their
  // own drill-down entries, each with a dynamic date-range label - a
  // provider can otherwise only reach the "next" period, with no
  // discoverable way to open any other listed row.
  const additionalPeriodActions: Record<string, unknown>[] = multiPeriod && periods
    ? periods
        .filter((period) => period !== upcoming)
        .slice(0, 2)
        .flatMap((period, index) => {
          const begin = dateLabel(period.serviceBeginDate);
          const end = dateLabel(period.serviceEndDate);
          // Skip rather than render a garbled label ("Open Unavailable from
          // the current source-Unavailable from the current source payout")
          // when either boundary date can't be resolved to a display value.
          if (begin === "Unavailable from the current source" || end === "Unavailable from the current source") return [];
          return [{
            actionId: `open-service-period-${index}`,
            capability: "payment-analysis",
            label: `Open ${begin}-${end} payout`,
            reason: "Inspect this specific service period's full payment breakdown.",
            priority: "medium",
            // "drill-down", not "next-actions" - the shared renderActionSections
            // caps the "next-actions" section at MAX_NEXT_ACTIONS (2), which
            // would silently truncate one of these two additional-period
            // entries before this function's own 3-total cap even applies.
            section: "drill-down",
            source: "current-result",
            input: {
              view: "CUSTOM_RANGE",
              dateFilter: "DATE_RANGE",
              dateFrom: String(period.serviceBeginDate),
              dateTo: String(period.serviceEndDate),
            },
          }];
        })
    : [];
  // Item 7: the multi-period ledger renders only the flat period rollup
  // table above (confirmed - renderCountyComposition is never called in the
  // multiPeriod branch); this follow-up action aggregates county-level
  // composition (Care/Absence/Drop-in/Vacant Slot/Paid Holiday amounts)
  // across the FULL requested range as the next step, per the ordering
  // requested: service-period rollup first, county-level composition next.
  // The single-period case above is unchanged - it already shows composition
  // inline via the `entry` branch.
  const rangeBoundaryDates = multiPeriod && periods
    ? periods.reduce<{ begin?: string; end?: string }>((bounds, period) => {
        const begin = typeof period.serviceBeginDate === "string" ? period.serviceBeginDate : undefined;
        const end = typeof period.serviceEndDate === "string" ? period.serviceEndDate : undefined;
        const nextBegin = begin && (!bounds.begin || begin < bounds.begin) ? begin : bounds.begin;
        const nextEnd = end && (!bounds.end || end > bounds.end) ? end : bounds.end;
        return {
          ...(nextBegin ? { begin: nextBegin } : {}),
          ...(nextEnd ? { end: nextEnd } : {}),
        };
      }, {})
    : {};
  const countyCompositionRangeAction = multiPeriod && rangeBoundaryDates.begin && rangeBoundaryDates.end
    ? [{
        actionId: "view-county-composition-for-range",
        capability: "payment-analysis",
        tool: "cccap_analyze_payment",
        label: "View county-level payment composition for this range",
        reason: "Aggregate Care/Absence/Drop-in/Vacant Slot/Paid Holiday amounts by county across every period in this range.",
        priority: "medium",
        section: "drill-down",
        source: "current-result",
        input: {
          view: "CUSTOM_RANGE",
          dateFilter: "DATE_RANGE",
          dateFrom: rangeBoundaryDates.begin,
          dateTo: rangeBoundaryDates.end,
          grouping: "COUNTY",
        },
      }]
    : [];
  // Every action object here MUST carry an explicit `tool` field, same as
  // every sibling action elsewhere in this file (e.g. countyCompositionRangeAction
  // above) - these three were the one place that omitted it. Without `tool`,
  // the calling agent has no declared MCP tool to invoke when the action is
  // used, so the button renders but produces no output when acted on - this
  // was the root cause of "Review payment details for this service period"
  // (and the equivalent multi-period/last-payout actions) silently doing
  // nothing even though the initial NEXT_PAYOUT/LAST_PAYOUT response itself
  // rendered correctly.
  const actionIntents = multiPeriod
    ? [
        { actionId: "open-next-upcoming-payout", capability: "payment-analysis", tool: "cccap_analyze_payment", label: "Open next upcoming payout", reason: "Focus on the nearest unpaid or upcoming service period.", priority: "high", section: "next-actions", source: "current-result", input: ledgerInput },
        ...additionalPeriodActions,
        ...countyCompositionRangeAction,
      ]
    : isLastPayoutEntry
      ? [{ actionId: "open-next-upcoming-payout-from-last", capability: "payment-analysis", tool: "cccap_analyze_payment", label: "View next upcoming payout", reason: "See the next payout still ahead, separate from this released one.", priority: "medium", section: "next-actions", source: "current-result", input: { view: "NEXT_PAYOUT" } }]
      : [{ actionId: "review-service-period-payout-ledger", capability: "payment-analysis", tool: "cccap_analyze_payment", label: "Review payment details for this service period", reason: "Inspect the source-backed payment calculation behind this payout period.", priority: "medium", section: "next-actions", source: "current-result", input: ledgerInput }];
  const currentView = viewState({
    viewId: multiPeriod ? "PAYOUT_LEDGER" : isLastPayoutEntry ? "LAST_PAYOUT" : "NEXT_UPCOMING_PAYOUT",
    tableId: multiPeriod ? "payout-ledger" : isLastPayoutEntry ? "last-payout-summary" : "payout-summary",
    tableTitle: multiPeriod ? "Payout ledger" : isLastPayoutEntry ? "Last payout" : "Next upcoming payout",
    tableDescription: multiPeriod
      ? "This table shows every verified service period in the requested range and its payout status."
      : isLastPayoutEntry
        ? "This shows only the most recently released payout identified from verified service-period data."
        : "This table shows only the next unpaid or upcoming payout identified from verified service-period data.",
    ...(value.scope !== undefined ? { scope: value.scope } : {}),
    ...(typeof value.sourceRetrievedAt === "string" ? { sourceRetrievedAt: value.sourceRetrievedAt } : {}),
  });
  // Keep structuredContent as navigation metadata only. The complete payout
  // tables already live in content[0].text; copying county/category rows here
  // makes the host ingest the same large result twice and can suppress the
  // provider-facing text in the UI.
  const compactLedgerPeriod = (period: Record<string, unknown>): Record<string, unknown> => Object.fromEntries(
    [
      "serviceBeginDate",
      "serviceEndDate",
      "payoutDate",
      "periodStatus",
      "amountAtRisk",
      "estimatedTotal",
      "potentialTotal",
      "childrenServed",
    ]
      .filter((key) => period[key] !== undefined)
      .map((key) => [key, period[key]]),
  );
  const selectedSummaryPeriod = selectedPeriod ? compactLedgerPeriod(selectedPeriod) : undefined;
  return finalizePayoutResponse({
    capability: "service-period-payout-ledger",
    lines,
    actions: actionIntents,
    currentView,
    disclaimers: ledgerDisclaimers,
    responseSections: ["summary", "ledger", "next-actions"],
    recentActionSignatures: value.recentActionSignatures,
    extraStructured: {
      periods: periods?.map(compactLedgerPeriod) ?? [],
      ...(selectedSummaryPeriod ? { selectedPeriod: selectedSummaryPeriod } : {}),
      ...(value.daysUntilPayout !== undefined ? { daysUntilPayout: value.daysUntilPayout } : {}),
      sourceRetrievedAt: value.sourceRetrievedAt,
    },
  });
}

// --- Merged from payment-summary-renderer.ts (2026-09-15 consolidation) ---
export function renderNumericTable(headers: string[], rows: string[][], numericColumns: number[]): string[] {
  const keep = headers.map((_, index) => !numericColumns.includes(index) || rows.some((row) => {
    const value = (row[index] ?? '').trim();
    return value !== '' && value !== '—' && value !== '$0.00' && value !== '0'
      && value !== 'Unavailable from the current source' && value !== 'N/A';
  }));
  const filtered = (row: string[]) => row.filter((_, index) => keep[index]);
  const separator = headers.map((_, index) => numericColumns.includes(index) ? '---:' : '---');
  return [
    `| ${headers.filter((_, index) => keep[index]).join(' | ')} |`,
    `| ${separator.filter((_, index) => keep[index]).join(' | ')} |`,
    ...rows.map((row) => `| ${filtered(row).join(' | ')} |`),
  ];
}

function renderFixedTable(headers: string[], rows: string[][]): string[] {
  return [
    `| ${headers.join(' | ')} |`,
    `| ${headers.map((_, index) => index === 0 ? '---' : '---:').join(' | ')} |`,
    ...rows.map((row) => `| ${row.join(' | ')} |`),
  ];
}

export const PAYMENT_CATEGORY_ORDER = [
  "Enrollment absence",
  "Paid absence",
  "Paid holidays",
  "Drop-ins",
  "Regular care",
  "Vacant slots",
] as const;

const money = (value: unknown): number => {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : 0;
};

const CATEGORY_LABELS = new Map<string, string>([
  ["enrollment absence", "Enrollment absence"],
  ["absence (enrollment)", "Enrollment absence"],
  ["paid absence", "Paid absence"],
  ["absence", "Paid absence"],
  ["holiday", "Paid holidays"],
  ["paid holiday", "Paid holidays"],
  ["paid holidays", "Paid holidays"],
  ["drop-in", "Drop-ins"],
  ["drop-ins", "Drop-ins"],
  ["regular care", "Regular care"],
  ["care", "Regular care"],
  ["base / estimated payable", "Regular care"],
  ["scheduled forecast", "Regular care"],
  ["amount at risk", "Regular care"],
  ["vacant slots", "Vacant slots"],
]);

export function numericField(row: Record<string, unknown>, keys: string[]): number | undefined {
  for (const key of keys) {
    const value = row[key];
    const numeric = typeof value === "number" ? value : Number(value);
    if (value !== undefined && value !== null && Number.isFinite(numeric)) return numeric;
  }
  return undefined;
}

export function estimatedPaymentTotal(
  payment: Record<string, unknown>,
  baseAmount: number | undefined,
  scheduledForecastAmount: number | undefined,
): number | undefined {
  const direct = numericField(payment, ["potential_total", "estimated_total"]);
  if (direct !== undefined) return direct;
  if (baseAmount === undefined && scheduledForecastAmount === undefined && payment.vacant_slot_fee === undefined && payment.slot_fee === undefined) return undefined;
  return (baseAmount ?? 0) + (scheduledForecastAmount ?? 0) + (numericField(payment, ["vacant_slot_fee", "slot_fee"]) ?? 0) + (numericField(payment, ["amount_at_risk", "at_risk_amount"]) ?? 0);
}

export function attendanceDerivedAtRisk(attendance: Record<string, unknown>[]): number | undefined {
  let total = 0;
  let found = false;
  for (const day of attendance) {
    const flags = Array.isArray(day.flags)
      ? day.flags.filter((flag): flag is string => typeof flag === "string")
      : [];
    const conditional = day.conditional === true
      || flags.some((flag) => [
        "PARENT_CONFIRMATION_UNAVAILABLE",
        "PARENT_CONFIRMATION_PENDING",
        "MISSING_ATTENDANCE_TRANSACTION",
        "INCOMPLETE_ATTENDANCE_RECORD",
      ].includes(flag));
    if (!conditional) continue;
    const amount = numericField(day, ["conditional_amount", "amount_at_risk", "risk_amount", "calculated_amount", "potential_amount", "amount"]);
    if (amount !== undefined && amount > 0) {
      total += amount;
      found = true;
    }
  }
  return found ? total : undefined;
}

export function splitConditionalScheduledForecast(rows: Record<string, unknown>[]): Record<string, unknown>[] {
  return rows.flatMap((row) => {
    if (tableValue(row.label).toLowerCase() !== "scheduled forecast") return [row];
    const conditionalAmount = numericField(row, ["conditional_amount"]);
    if (conditionalAmount === undefined || conditionalAmount <= 0) return [row];
    const scheduledAmount = numericField(row, ["amount"]);
    return [
      ...(scheduledAmount !== undefined ? [{ ...row, conditional_amount: undefined }] : []),
      { label: "Amount at risk", conditional_amount: conditionalAmount },
    ];
  });
}

function normalizedCategoryRows(rows: Record<string, unknown>[]): Record<string, unknown>[] {
  const aggregate = new Map<string, Record<string, unknown>>();
  for (const row of rows) {
    const sourceLabel = tableValue(row.label).toLowerCase();
    const label = CATEGORY_LABELS.get(sourceLabel);
    if (!label) continue;
    const current = aggregate.get(label) ?? {
      label,
      days: 0,
      hours: 0,
      amount: 0,
      scheduled_forecast: 0,
      conditional_amount: 0,
      excluded_days: 0,
      excluded_reasons: [],
      children_served: 0,
    };
    const targetAmount = sourceLabel === "scheduled forecast" ? "scheduled_forecast" : "amount";
    for (const key of ["days", "hours", "excluded_days"]) {
      const value = Number(row[key]);
      if (Number.isFinite(value)) current[key] = Number(current[key] ?? 0) + value;
    }
    const childrenServed = Number(row.children_served);
    if (Number.isFinite(childrenServed)) current.children_served = Math.max(Number(current.children_served ?? 0), childrenServed);
    for (const key of ["amount", "conditional_amount"]) {
      const value = Number(row[key]);
      const target = sourceLabel === "amount at risk"
        ? "conditional_amount"
        : targetAmount === "amount"
          ? key
          : key === "amount" ? "scheduled_forecast" : key;
      if (Number.isFinite(value)) current[target] = Number(current[target] ?? 0) + value;
    }
    const reasons = Array.isArray(row.excluded_reasons)
      ? row.excluded_reasons.filter((reason): reason is string => typeof reason === "string")
      : typeof row.excluded_reason === "string" ? [row.excluded_reason] : [];
    current.excluded_reasons = [...new Set([...(current.excluded_reasons as string[]), ...reasons])];
    aggregate.set(label, current);
  }
  return PAYMENT_CATEGORY_ORDER.map((label) => aggregate.get(label) ?? {
    label,
    days: 0,
    hours: 0,
    amount: 0,
    scheduled_forecast: 0,
    conditional_amount: 0,
    excluded_days: 0,
    excluded_reasons: [],
    children_served: 0,
  });
}

export function renderPaymentCategorySection(
  title: string,
  rows: Record<string, unknown>[],
  estimatedTotal?: unknown,
  childrenServed?: unknown,
): string[] {
  const normalizedRows = normalizedCategoryRows(rows);
  const definitions = [
    { header: "Category", value: (row: Record<string, unknown>) => tableValue(row.label), numeric: false },
    { header: "Children served", value: (row: Record<string, unknown>) => tableValue(row.children_served), numeric: true },
    // #9.5 fix: "Child-days" (was "Days") - the Total row sums this across
    // categories to a figure that can exceed the service period's calendar
    // days (e.g. 42 "days" for a 7-day period with 7 children) because this
    // is child-days, not calendar days; the old header didn't say so.
    { header: "Child-days", value: (row: Record<string, unknown>) => tableValue(row.days), numeric: true },
    { header: "Care hours", value: (row: Record<string, unknown>) => tableValue(row.hours), numeric: true },
    { header: "Net payment", value: (row: Record<string, unknown>) => amountWithHours(row.amount, row.hours), numeric: true },
    { header: "Scheduled forecast", value: (row: Record<string, unknown>) => amountWithHours(row.scheduled_forecast, row.hours), numeric: true },
    { header: "Conditional at-risk", value: (row: Record<string, unknown>) => amountWithHours(row.conditional_amount, row.hours), numeric: true },
    { header: "Unavailable days (reason)", value: (row: Record<string, unknown>) => {
      const days = Number(row.excluded_days) || 0;
      const reasons = Array.isArray(row.excluded_reasons) ? row.excluded_reasons.filter((reason): reason is string => typeof reason === "string") : [];
      return reasons.length > 0 ? `${days} (${reasons.join(", ")})` : String(days);
    }, numeric: true },
    // "Vacant slots" is a normal category row here (no dedicated column,
    // per explicit request) - its amount is summed into "Base / estimated
    // payable" the SAME way every other category row's amount is, so the
    // Total row always equals the sum of the rows displayed above it in
    // THIS table. This total is allowed to differ from the headline's
    // "Base / estimated payable" measure (which deliberately excludes
    // vacant slots as its own separate line) - the two are different
    // things by design; internal within-table consistency is what this
    // table promises, and "Estimated total" (the last column) is still the
    // one figure guaranteed to match the headline everywhere.
    { header: "Maximum estimated payout", value: (row: Record<string, unknown>) => amountWithHours(money(row.amount) + money(row.scheduled_forecast) + money(row.conditional_amount), row.hours), numeric: true },
  ];
  const renderedRows = normalizedRows.map((row) => definitions.map((definition) => definition.value(row)));
  const headers = definitions.map((definition) => definition.header);
  const total = normalizedRows.reduce<{ days: number; hours: number; amount: number; scheduled: number; risk: number; excluded: number }>((sum, row) => ({
    days: sum.days + money(row.days),
    hours: sum.hours + money(row.hours),
    amount: sum.amount + money(row.amount),
    scheduled: sum.scheduled + money(row.scheduled_forecast),
    risk: sum.risk + money(row.conditional_amount),
    excluded: sum.excluded + money(row.excluded_days),
  }), { days: 0, hours: 0, amount: 0, scheduled: 0, risk: 0, excluded: 0 });
  const totalRow = [
    "Total",
    childrenServed !== undefined ? String(Number(childrenServed) || 0) : String(normalizedRows.reduce((sum, row) => sum + money(row.children_served), 0)),
    String(total.days),
    String(total.hours),
    amountWithHours(total.amount, total.hours),
    amountWithHours(total.scheduled, total.hours),
    amountWithHours(total.risk, total.hours),
    String(total.excluded),
    amountWithHours(estimatedTotal !== undefined ? estimatedTotal : total.amount + total.scheduled + total.risk, total.hours),
  ];
  return [
    "",
    title,
    ...renderFixedTable(headers, [...renderedRows, totalRow]),
  ];
}

// #3 fix: County payment composition slimmed to Net payment / Scheduled
// forecast / Conditional at-risk / Maximum estimated payout, matching the
// C1-fixed top Measure table's shape - the 6 per-category dollar columns
// this table previously carried (Enrollment absence, Paid absence, Paid
// holidays, Drop-ins, Regular care, Vacant slots) are already fully covered
// by the separate "Payment by category" table rendered right below this
// one, so duplicating them here forced a provider to cross-reference two
// wide tables for the same underlying numbers.
const COUNTY_CATEGORY_KEYS = ["enrollment_absence", "absence", "paid_holidays", "drop_in", "care", "vacant_slots"] as const;
export function renderCountyCategoryTable(rows: Record<string, unknown>[], estimatedTotal?: unknown, childrenServed?: unknown): string[] {
  const nestedOf = (row: Record<string, unknown>, key: string): Record<string, unknown> =>
    row[key] && typeof row[key] === "object" && !Array.isArray(row[key]) ? row[key] as Record<string, unknown> : {};
  const component = (row: Record<string, unknown>, key: string): number => money(nestedOf(row, key).amount);
  const componentHours = (row: Record<string, unknown>, key: string): number => money(nestedOf(row, key).hours);
  // Scheduled forecast per county is read from each category's own nested
  // `scheduled_forecast` field, when the source provides it (mirrors the
  // category-level split already used by the Measure table/Payment-by-
  // category table). If no row carries this field at all, every county's
  // forecast is 0 and the column is omitted entirely below - matching
  // NEXT_PAYOUT-style responses exactly, so this is not a regression there.
  const scheduledForecastComponent = (row: Record<string, unknown>, key: string): number => money(nestedOf(row, key).scheduled_forecast);
  const countyScheduledForecast = (row: Record<string, unknown>): number =>
    COUNTY_CATEGORY_KEYS.reduce((sum, key) => sum + scheduledForecastComponent(row, key), 0);
  const countyHoursFor = (row: Record<string, unknown>, field: "amount" | "scheduled_forecast" | "conditional_amount"): number | undefined => {
    const hours = COUNTY_CATEGORY_KEYS.reduce((sum, key) => {
      const category = nestedOf(row, key);
      return sum + (Number(category[field]) > 0 ? componentHours(row, key) : 0);
    }, 0);
    return hours > 0 ? hours : undefined;
  };
  const risk = (row: Record<string, unknown>): number => money(row.amount_at_risk ?? row.at_risk_amount ?? row.conditional_amount);
  const total = (row: Record<string, unknown>): number => money(row.potential_total ?? row.total_amount)
    || COUNTY_CATEGORY_KEYS.reduce((sum, key) => sum + component(row, key), 0) + risk(row);
  // True net excludes both scheduled forecast and at-risk, same definition
  // as the C1-fixed top Measure table's "Net payment" row.
  const netPayment = (row: Record<string, unknown>): number => Math.max(0, total(row) - countyScheduledForecast(row) - risk(row));
  const anyForecast = rows.some((row) => countyScheduledForecast(row) > 0);
  const headers = anyForecast
    ? ["County", "Children served", "Net payment", "Scheduled forecast", "Conditional at-risk", "Maximum estimated payout"]
    : ["County", "Children served", "Net payment", "Conditional at-risk", "Maximum estimated payout"];
  const rendered = rows.map((row) => {
    const netHours = countyHoursFor(row, "amount");
    const forecastHours = countyHoursFor(row, "scheduled_forecast");
    const riskHours = countyHoursFor(row, "conditional_amount");
    const cells = [tableValue(row.county), tableValue(row.children_served), amountWithHours(netPayment(row), netHours)];
    if (anyForecast) cells.push(amountWithHours(countyScheduledForecast(row), forecastHours));
    cells.push(amountWithHours(risk(row), riskHours), amountWithHours(total(row), [netHours, forecastHours, riskHours]
      .filter((hours): hours is number => hours !== undefined)
      .reduce((sum, hours) => sum + hours, 0) || undefined));
    return cells;
  });
  const totalChildrenServed = childrenServed !== undefined ? String(Number(childrenServed) || 0) : String(rows.reduce((sum, row) => sum + money(row.children_served), 0));
  const totalNet = rows.reduce((sum, row) => sum + netPayment(row), 0);
  const totalForecast = rows.reduce((sum, row) => sum + countyScheduledForecast(row), 0);
  const totalRisk = rows.reduce((sum, row) => sum + risk(row), 0);
  const totalMax = estimatedTotal !== undefined ? Number(estimatedTotal) : rows.reduce((sum, row) => sum + total(row), 0);
  const totalNetHours = rows.map((row) => countyHoursFor(row, "amount")).filter((hours): hours is number => hours !== undefined).reduce((sum, hours) => sum + hours, 0);
  const totalForecastHours = rows.map((row) => countyHoursFor(row, "scheduled_forecast")).filter((hours): hours is number => hours !== undefined).reduce((sum, hours) => sum + hours, 0);
  const totalRiskHours = rows.map((row) => countyHoursFor(row, "conditional_amount")).filter((hours): hours is number => hours !== undefined).reduce((sum, hours) => sum + hours, 0);
  const totalRow = anyForecast
    ? ["Total", totalChildrenServed, amountWithHours(totalNet, totalNetHours || undefined), amountWithHours(totalForecast, totalForecastHours || undefined), amountWithHours(totalRisk, totalRiskHours || undefined), amountWithHours(totalMax, totalNetHours + totalForecastHours + totalRiskHours || undefined)]
    : ["Total", totalChildrenServed, amountWithHours(totalNet, totalNetHours || undefined), amountWithHours(totalRisk, totalRiskHours || undefined), amountWithHours(totalMax, totalNetHours + totalRiskHours || undefined)];
  return [
    "",
    "County payment composition",
    ...renderFixedTable(headers, [...rendered, totalRow]),
  ];
}