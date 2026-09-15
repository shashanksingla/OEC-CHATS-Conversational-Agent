import { actionControls, countyPaymentSummary, estimatedMoney, plainMoney, humanizeAttendanceType, numericValue, recordValue, renderActionSections, renderCountyComposition, result, shortDateLabel, tableValue, type ToolResult, DISCLAIMER_AT_RISK, DISCLAIMER_EXPECTED, DISCLAIMER_FORECASTED, DISCLAIMER_GLOBAL, DISCLAIMER_GUARANTEED } from './shared.js';
import { actionViewMetadata, viewState } from '../view-state.js';

/** Render a markdown table while omitting numeric columns that carry no information in this view. */
function renderNumericTable(headers: string[], rows: string[][], numericColumns: number[]): string[] {
  const keep = headers.map((_, index) => !numericColumns.includes(index) || rows.some((row) => {
    const value = (row[index] ?? '').trim();
    return value !== '' && value !== '—' && value !== '$0.00' && value !== '0' && value !== 'Unavailable from the current source';
  }));
  const filtered = (row: string[]) => row.filter((_, index) => keep[index]);
  const separator = headers.map((header, index) => numericColumns.includes(index) ? '---:' : '---');
  return [
    `| ${headers.filter((_, index) => keep[index]).join(' | ')} |`,
    `| ${separator.filter((_, index) => keep[index]).join(' | ')} |`,
    ...rows.map((row) => `| ${filtered(row).join(' | ')} |`),
  ];
}

function renderCategoryTable(rows: Record<string, unknown>[]): string[] {
  const definitions = [
    { header: "Category", value: (row: Record<string, unknown>) => tableValue(row.label), numeric: false },
    { header: "Children/contracts", value: (row: Record<string, unknown>) => tableValue(row.children_served ?? row.children ?? row.contracts), numeric: true },
    { header: "Days", value: (row: Record<string, unknown>) => tableValue(row.days), numeric: true },
    { header: "Care hours", value: (row: Record<string, unknown>) => tableValue(row.hours), numeric: true },
    { header: "Expected amount", value: (row: Record<string, unknown>) => plainMoney(row.amount), numeric: true },
    { header: "At-risk amount", value: (row: Record<string, unknown>) => plainMoney(row.conditional_amount), numeric: true },
    { header: "Excluded days", value: (row: Record<string, unknown>) => tableValue(row.excluded_days), numeric: true },
  ];
  const renderedRows = rows.map((row) => definitions.map((definition) => definition.value(row)));
  const numericColumns = definitions.flatMap((definition, index) => definition.numeric ? [index] : []);
  return renderNumericTable(definitions.map((definition) => definition.header), renderedRows, numericColumns);
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
  if (!settled && Number(payment.expected_amount) > 0) disclaimers.push(DISCLAIMER_EXPECTED);
  if (!settled && Number(payment.forecasted_amount) > 0) disclaimers.push(DISCLAIMER_FORECASTED);
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
// Ranks day-level detail rows so the highest-risk rows surface first:
// absence-limit-exceeded days and days unconfirmed past the confirmation
// window outrank routine attended/paid days. Used to cap the "Detail by
// child and service date" table to the top 5 rows instead of dumping every
// returned row, per the standing "show top 5 every time" convention.
const MAX_DETAIL_ROWS = 5;
function detailRowPriority(day: Record<string, unknown>): number {
  const flags = Array.isArray(day.flags) ? day.flags.filter((flag): flag is string => typeof flag === 'string') : [];
  let score = 0;
  if (flags.includes('ABSENCE_LIMIT_EXCEEDED')) score += 4;
  if (flags.includes('PARENT_CONFIRMATION_UNAVAILABLE')) score += 4;
  // MISSING_ATTENDANCE_TRANSACTION = no check-in/check-out was ever logged
  // for a past-window scheduled day (INCOMPLETE_ATTENDANCE_RECORD) - distinct
  // from PARENT_CONFIRMATION_UNAVAILABLE (a transaction exists but wasn't
  // approved in time). Both are "unconfirmed past the window" concerns.
  if (flags.includes('MISSING_ATTENDANCE_TRANSACTION')) score += 4;
  if (day.classification === 'ABSENCE') score += 1;
  if (day.payment_excluded === true) score += 1;
  return score;
}

// Picks up to MAX_DETAIL_ROWS distinct children rather than up to
// MAX_DETAIL_ROWS individual rows - a single child's tied absence-limit
// days would otherwise crowd out every other affected child from the
// top-5 view. Each selected child contributes only their single
// highest-priority row (ties broken by most total absence/unconfirmed days
// for that child), so the table surfaces breadth across children first.
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
  // When the request is already scoped to exactly one child (e.g. a
  // childNames-filtered "highest-impact child" drill-down), the multi-child
  // "one row per child, breadth first" design below makes no sense - it
  // would show only that single child's single highest-priority day even
  // when detailPagination reports many more days for them. Show up to
  // MAX_DETAIL_ROWS of THAT child's own days, ranked by priority, instead.
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


export function paymentActionMetadata(
  paymentResult: Record<string, unknown>,
  payment: Record<string, unknown>,
  detailPagination: Record<string, unknown> | undefined,
  status: string,
  detailPage: boolean,
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
      label: "Open next payment detail page",
      reason: "Continue reviewing the remaining payment rows in priority order.",
      priority: "medium",
      section: "drill-down",
      source: "current-result",
      input: {
        ...paymentInput({ detailPage: numericValue(detailPagination?.page) + 1 }),
      },
    });
  } else if (!detailPage && totalRows > 0) {
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
        detailPage: 1,
        ...(highestImpactChildName ? { childNames: [highestImpactChildName] } : {}),
      }),
    });
  }
  // Item 4(a): a cross-capability link alongside the payment child-detail
  // action, so a provider following payment's highest-impact child can jump
  // to the same 3-table attendance-risk view (absence/pending/incomplete)
  // for that child, not just its payment amounts. No riskFocus - this always
  // resolves through attendance-formatter.ts's child-scoped-multi-risk view.
  if (highestImpactChildName && !detailPage) {
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
  if (numericValue(payment.excluded_days) > 0) {
    actions.push({
      actionId: "review-excluded-payment-days",
      capability: "payment-analysis",
      tool: "cccap_analyze_payment",
      label: "Review excluded payment days",
      reason: "Excluded days may explain a lower estimated amount.",
      priority: "high",
      section: "next-actions",
      source: "current-result",
      input: paymentInput({ detailPage: 1, excludedOnly: true }),
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
export function formatPaymentResult(data: unknown): ToolResult {
  const paymentResult = recordValue(data);
  const payment = paymentResult && recordValue(paymentResult.payment);
  if (!paymentResult || !payment) return result(data);

  const status = typeof payment.status === "string" ? payment.status.toUpperCase() : "BLOCKED";
  const detailPagination = recordValue(paymentResult.detailPagination);
  const detailPage = detailPagination && Number(detailPagination.page) > 0;
  const paymentFilters = recordValue(paymentResult.filters);
  const requestedGrouping = typeof paymentFilters?.grouping === "string" ? paymentFilters.grouping : undefined;
  const requestedTableId = paymentResult.tableId === "payment-county-rollup" || paymentResult.tableId === "vacant-slot-rollup"
    ? paymentResult.tableId
    : undefined;
  const activeTableId = requestedTableId ?? (requestedGrouping === "COUNTY" && !detailPage
    ? "payment-county-rollup"
    : status === "BLOCKED" && paymentResult.paymentView === "NEXT_PAYOUT"
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
  const excludedOnly = recordValue(paymentResult.filters)?.excludedOnly === true;
  const attendance = Array.isArray(attendanceDays)
    ? attendanceDays
        .map(recordValue)
        .filter((row): row is Record<string, unknown> => Boolean(row))
        .filter((row) => row.classification !== "NO_CARE")
        .filter((row) => !excludedOnly || row.payment_excluded === true)
    : [];
  const missingInputs = Array.isArray(payment.missing_inputs)
    ? payment.missing_inputs.filter((value): value is string => typeof value === "string")
    : [];
  const summaryView = paymentSummaryView(payment.summary_view);
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
  const periodHeaderLabel = periodBeginLabel && periodEndLabel
    ? `${paymentResult.paymentView === "CUSTOM_RANGE" ? "Custom period" : "Payout period"}: ${periodBeginLabel}-${periodEndLabel}`
    : undefined;
  const lines = [
    // Bolded: this is the response's "Interpretation" line and mandatory
    // "Scope" line per the conversation-templates contract - previously
    // rendered as plain prose indistinguishable from any other sentence.
    `**${view}: ${statusLabel}.**`,
    ...(periodHeaderLabel ? [`**${periodHeaderLabel}**`] : []),
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
    ] as const) {
      const value = keys.map((key) => servicePeriod[key]).find((candidate) => candidate !== undefined && candidate !== null);
      const isDateField = label === "Services from" || label === "Services through" || label === "Payment processing date" || label === "Payment release date";
      if (value !== undefined) lines.push(`| ${label} | ${isDateField ? (shortDateLabel(value) ?? tableValue(value)) : tableValue(value)} |`);
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
      ["Estimated total", "amount"],
      ["Payout date", "payout_date"],
      ["Excluded authorizations", "excluded_authorizations"],
      ["Existing payment status", "existing_status"],
    ] as const) {
      if (payment[key] !== undefined && key === "amount") {
        lines.push(`| ${label} | ${estimatedMoney(payment[key])} |`);
      } else if (payment[key] !== undefined && key === "payout_date") {
        lines.push(`| ${label} | ${shortDateLabel(payment[key]) ?? tableValue(payment[key])} |`);
      } else if (payment[key] !== undefined) {
        lines.push(`| ${label} | ${String(payment[key])} |`);
      }
    }
    const netAmountNumeric = typeof payment.amount === "number" ? payment.amount : Number(payment.amount);
    const amountAtRiskNumeric = typeof payment.amount_at_risk === "number" ? payment.amount_at_risk : Number(payment.amount_at_risk);
    if (!isSettled && netAmountNumeric === 0 && Number.isFinite(amountAtRiskNumeric) && amountAtRiskNumeric > 0) {
      lines.push(
        "",
        `This shows ${plainMoney(0)} net because the payable amount is still conditional, not denied - an estimated ${plainMoney(amountAtRiskNumeric)} remains possible once the pending confirmations below are completed. This is an estimate and will change as confirmations are completed.`,
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
    const hasAmountBreakdown = payment.expected_amount !== undefined
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
        "Expected - past the confirmation window; likely payable.",
        "Forecasted - within the confirmation window or a future date; may change.",
        "At risk - excluded or flagged; may reduce or exclude payment.",
      );
      const expectedAmount = Number(payment.expected_amount) || 0;
      const forecastedAmount = Number(payment.forecasted_amount) || 0;
      const breakdownDisclaimers = [
        expectedAmount > 0 ? DISCLAIMER_EXPECTED : undefined,
        forecastedAmount > 0 ? DISCLAIMER_FORECASTED : undefined,
      ].filter((disclaimer): disclaimer is string => Boolean(disclaimer));
      if (breakdownDisclaimers.length > 0) lines.push(breakdownDisclaimers.join(" "));
      if (!excludedOnly) {
        breakdownRows.push(
          { label: "Expected", amount: payment.expected_amount },
          { label: "Forecasted", amount: payment.forecasted_amount },
        );
      }
      breakdownRows.push({ label: "Excluded or flagged (at-risk)", conditional_amount: payment.at_risk_amount });
    }
    // Table 8 ("County payment totals") retired - County payment
    // composition (rendered further below via renderCountyComposition) is
    // now the only county-level payment table; it already covers this same
    // information with a richer per-category breakdown.
    const overview = summaryView && recordValue(summaryView.overview);
    // An excluded-only request or a single-child drill-down already narrows
    // the detail table to exactly the rows the provider asked about; the
    // category/county/child rollups restate the same totals and are the
    // main contributor to an oversized response for these cases, so they
    // are omitted here rather than rendered and then discarded by the client.
    const suppressRollups = excludedOnly || singleChildFilter;
    const categories = suppressRollups || (requestedGrouping !== undefined && !["CATEGORY", "SERVICE_PERIOD"].includes(requestedGrouping))
      ? [] : summaryRows(summaryView, "categories");
    const countyRollup = suppressRollups || (requestedGrouping !== undefined && requestedGrouping !== "COUNTY")
      ? [] : summaryRows(summaryView, "counties");
    const countyComposition = suppressRollups || (requestedGrouping !== undefined && requestedGrouping !== "COUNTY")
      ? [] : summaryRows(summaryView, "county_composition");
    const childRollup = suppressRollups || (requestedGrouping !== undefined && requestedGrouping !== "CHILD")
      ? [] : summaryRows(summaryView, "children");
    const vacantSlots = suppressRollups ? [] : summaryRows(summaryView, "vacant_slots");
    const nextActions = summaryRows(summaryView, "next_actions");
    if (overview && activeTableId === "payment-category-rollup") {
      // Vacant-slot amount is a provider/slot-level figure, not tied to any
      // individual child's attendance - showing it in a single-child
      // drill-down is misleading. Show Drop-in amount instead there, since
      // drop-in care is a genuine per-child attendance pattern. An
      // excluded-days-only review is about which days didn't pay, and vacant
      // slots are guaranteed regardless of any child's attendance, so
      // neither vacant-slot nor drop-in amount is relevant there - the
      // column is dropped entirely for that view rather than showing an
      // unrelated figure.
      const rawCategories = summaryRows(summaryView, "categories");
      const dropInCategory = rawCategories.find((row) => tableValue(row.label) === "Drop-in");
      const lastColumn = excludedOnly
        ? undefined
        : singleChildFilter
          ? { label: "Drop-in amount", value: plainMoney(dropInCategory?.amount ?? 0) }
          : { label: "Vacant-slot amount", value: plainMoney(payment.vacant_slot_fee) };
      // "Excluded days" is dropped here too, for consistency with the Measure
      // table: it duplicates the per-row exclusion reasons already shown in
      // the Attendance type brackets in the detail table below, and reads as
      // a resolved-exclusion count that gets conflated with "Amount at risk"
      // (which is a distinct, still-conditional dollar figure).
      // "Review items" renamed to "Flagged categories" - it is a count of
      // distinct issue TYPES flagged (missing rate, absence-limit exceeded,
      // etc.), not a day count, which read as easy to misinterpret next to
      // "Paid days" in the same row.
      const diffHeader = lastColumn
        ? `| Paid days | 🔍 Flagged categories | Amount at risk | ${lastColumn.label} |`
        : "| Paid days | 🔍 Flagged categories | Amount at risk |";
      const diffSeparator = lastColumn ? "| ---: | ---: | ---: | ---: |" : "| ---: | ---: | ---: |";
      const diffRow = lastColumn
        ? `| ${tableValue(overview.paid_days)} | ${tableValue(overview.review_items)} | ${plainMoney(overview.amount_at_risk)} | ${lastColumn.value} |`
        : `| ${tableValue(overview.paid_days)} | ${tableValue(overview.review_items)} | ${plainMoney(overview.amount_at_risk)} |`;
      lines.push("", "Payment differences:", diffHeader, diffSeparator, diffRow);
      if (numericValue(overview.review_items) > 0) {
        lines.push("🔍 Flagged categories = distinct issue types, not days.");
      }
    }
    // Folded-in Expected/Forecasted/At-risk breakdown rows (see
    // breakdownRows above) append to whatever category rows already exist,
    // so a detail-page response with a real category breakdown gets both in
    // ONE table instead of the table plus two standalone mini-tables.
    const categoriesWithBreakdown = [...categories, ...breakdownRows];
    // "forecast-date-detail" (CURRENT_PERIOD_FORECAST's activeTableId) is
    // included here alongside the default "payment-category-rollup" -
    // previously this table only ever rendered for STATUS/CUSTOM_RANGE
    // views, so a forecast response showed county composition but never
    // the category breakdown, even though `categories` was already
    // computed and available. Mirrors the same fix already applied to the
    // county-composition condition just below.
    if (categoriesWithBreakdown.length > 0 && (activeTableId === "payment-category-rollup" || activeTableId === "forecast-date-detail")) {
      lines.push("", "Payment by category:", "> This separates only the payment measures available for the requested category view; omitted columns were not populated for this scope.", ...renderCategoryTable(categoriesWithBreakdown));
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
    if (countyComposition.length > 0 && (activeTableId === "payment-county-rollup" || activeTableId === "forecast-date-detail" || (activeTableId === "payment-category-rollup" && categories.length === 0))) {
      lines.push(...renderCountyComposition(countyComposition, { settled: isSettled }));
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
      lines.push("", "Child detail:", "> This shows the payment measures behind the selected child scope; amounts remain estimates or at risk where labeled. Attendance risk summarizes this same response's day-level flags - open the attendance-risk detail action below for the complete breakdown.", "| Child | Authorization | Days | Care hours | Expected amount | At-risk amount | Excluded days | Attendance risk |", "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |", ...childRollup.map((row) => `| ${tableValue(row.label)} | ${authorizationCell(row)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} | ${attendanceRiskTag(row.label)} |`));
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
    if (nextActions.length > 0) {
      // Keep the action label canonical and put its explanation/metrics in
      // prose; appending reason text to labels creates a competing action UI.
      lines.push(
        "",
        "**Payment next actions:**",
        ...nextActions.slice(0, 3).flatMap((row) => [
          `- ${tableValue(row.label)}`,
          `  ${tableValue(row.reason)}${row.days !== undefined || row.amount_at_risk !== undefined ? ` (${tableValue(row.days)} day(s), ${plainMoney(row.amount_at_risk)} at risk)` : ""}`,
        ]),
      );
    }
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
      ? "This table compares children served, care hours, expected amount, and at-risk amount by county."
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
  const actionIntents = paymentActionMetadata(paymentResult, payment, detailPagination, status, Boolean(detailPage));
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
  const viewAwareActionIntents = actionIntents
    .map((action) => actionViewMetadata(action, currentView));
  const providerMessage = `${renderActionSections(lines.join("\n"), viewAwareActionIntents)}\n\n${DISCLAIMER_GLOBAL}`;
  const providerSummary = Array.isArray(payment.summary)
    ? countyPaymentSummary(payment.summary.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))).map((row) => ({
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
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "payment-analysis",
      viewState: currentView,
      scope: paymentResult.scope,
      paymentView: paymentResult.paymentView,
      actionIntents,
      actionControls: actionControls(viewAwareActionIntents),
      paymentDisclaimers: disclaimers,
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

export function formatServicePeriodLedgerResult(data: unknown): ToolResult {
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
  if (periods) {
    // A row shows exactly one of Net (released/paid, historical) or
    // Calculated (not yet released, a current estimate) - never both, and
    // never the guaranteed-amount field mislabeled as "Calculated".
    const renderPeriodRow = (period: Record<string, unknown>): string => {
      const begin = dateLabel(period.serviceBeginDate), end = dateLabel(period.serviceEndDate);
      const servicePeriod = begin !== "Unavailable from the current source" && end !== "Unavailable from the current source" ? `${begin}-${end}` : "Unavailable from the current source";
      const netCell = period.netAmount !== undefined ? plainMoney(period.netAmount) : "—";
      const calculatedCell = period.calculatedAmount !== undefined ? plainMoney(period.calculatedAmount) : "—";
      return `| ${tableValue(servicePeriod)} | ${tableValue(dateLabel(period.payoutDate))} | ${tableValue(labels[String(period.periodStatus)] ?? "Unavailable from the current source")} | ${netCell} | ${calculatedCell} | ${plainMoney(period.amountAtRisk)} |`;
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
    const statusLegend = "> Status: Not yet started = period hasn't begun · In progress = today falls within this period · Pending confirmation = period ended, within the 5-day confirmation window · Expected, awaiting payout = confirmation window passed, not yet due · Overdue, needs follow-up = payout date has passed with no confirmed payment - review this period directly · Paid = released and settled.";
    if (multiPeriod) {
      lines.push(`**Showing ${periods.length} service periods from the verified payout ledger. The soonest upcoming payout is estimated at ${estimatedMoney(upcomingHeadlineAmount)}.**`);
      lines.push("", "> This ledger shows every service period in the requested range; released periods show a Net amount, unreleased periods show a Calculated (current estimate) amount.", statusLegend, "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", ...periods.map(renderPeriodRow));
      // "Payment by category" was previously never rendered anywhere in this
      // formatter (only county composition was) - shown here for the
      // soonest upcoming period only (not every row) to avoid cluttering a
      // multi-period table with N separate category breakdowns.
      const upcomingCategories = Array.isArray(upcoming?.categories)
        ? upcoming.categories.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
        : [];
      if (upcomingCategories.length > 0) {
        lines.push("", `Payment by category (soonest upcoming period, ${dateLabel(upcoming?.serviceBeginDate)}-${dateLabel(upcoming?.serviceEndDate)}):`, ...renderCategoryTable(upcomingCategories));
      }
    } else if (upcoming) {
      lines.push(`**Showing the next upcoming service period only: an estimated ${estimatedMoney(upcomingHeadlineAmount)} on ${dateLabel(upcoming.payoutDate)}.**`, "", "> This shows only the single next unpaid or upcoming payout identified from verified service-period data.", statusLegend, "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", renderPeriodRow(upcoming));
      const upcomingCategories = Array.isArray(upcoming.categories)
        ? upcoming.categories.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
        : [];
      if (upcomingCategories.length > 0) {
        lines.push("", "Payment by category:", ...renderCategoryTable(upcomingCategories));
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
      ? `Your last payout was released on ${dateLabel(entry.payoutDate)}: ${estimatedMoney(entryAmount)} net.`
      : `Payout in ${countdown}, on ${dateLabel(entry.payoutDate)}: an estimated ${estimatedMoney(entryAmount)}.`);
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
    if (entryCountyComposition.length > 0) {
      // A released (Paid) period is settled - nothing shown here is
      // "potential" anymore, so the composition table drops that
      // disambiguation rather than showing it alongside a settled figure.
      lines.push(...renderCountyComposition(entryCountyComposition, { settled: isLastPayout }));
    }
    // "Payment by category" (Care/Absence/Drop-in/Holiday breakdown) was
    // never rendered anywhere in this formatter before - only county
    // composition was. LedgerPeriodEntry.categories threads this through
    // from the same underlying payment analysis as countyComposition above.
    const entryCategories = Array.isArray(entry.categories)
      ? entry.categories.map(recordValue).filter((row): row is Record<string, unknown> => Boolean(row))
      : [];
    if (entryCategories.length > 0) {
      lines.push("", "Payment by category:", ...renderCategoryTable(entryCategories));
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
        detailDepth: "DETAIL",
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
              detailDepth: "DETAIL",
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
  const actionIntents = multiPeriod
    ? [
        { actionId: "open-next-upcoming-payout", capability: "payment-analysis", label: "Open next upcoming payout", reason: "Focus on the nearest unpaid or upcoming service period.", priority: "high", section: "next-actions", source: "current-result", input: ledgerInput },
        ...additionalPeriodActions,
        ...countyCompositionRangeAction,
      ]
    : isLastPayoutEntry
      ? [{ actionId: "open-next-upcoming-payout-from-last", capability: "payment-analysis", label: "View next upcoming payout", reason: "See the next payout still ahead, separate from this released one.", priority: "medium", section: "next-actions", source: "current-result", input: { view: "NEXT_PAYOUT" } }]
      : [{ actionId: "review-service-period-payout-ledger", capability: "payment-analysis", label: "Review payment details for this service period", reason: "Inspect the source-backed payment calculation behind this payout period.", priority: "medium", section: "next-actions", source: "current-result", input: ledgerInput }];
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
  const viewAwareActionIntents = actionIntents.map((action) => actionViewMetadata(action, currentView));
  const providerMessage = `${renderActionSections(lines.join("\n"), viewAwareActionIntents)}\n\n${DISCLAIMER_GLOBAL}`;
  return { content: [{ type: "text" as const, text: providerMessage }], structuredContent: { capability: "service-period-payout-ledger", providerMessage, viewState: currentView, periods: periods ?? [], ...(entry ? { entry } : {}), ...(value.daysUntilPayout !== undefined ? { daysUntilPayout: value.daysUntilPayout } : {}), sourceRetrievedAt: value.sourceRetrievedAt, paymentDisclaimers: [...new Set(ledgerDisclaimers)], actionIntents, actionControls: actionControls(viewAwareActionIntents), responseSections: ["summary", "ledger", "next-actions"] } };
}