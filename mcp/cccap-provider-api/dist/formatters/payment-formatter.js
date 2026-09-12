import { actionControls, countyPaymentSummary, estimatedMoney, plainMoney, humanizeAttendanceType, numericValue, recordValue, renderActionSections, renderCountyComposition, result, shortDateLabel, tableValue, DISCLAIMER_AT_RISK, DISCLAIMER_EXPECTED, DISCLAIMER_FORECASTED, DISCLAIMER_GLOBAL, DISCLAIMER_GUARANTEED } from './shared.js';
import { actionViewMetadata, viewState } from '../view-state.js';
/** Render a markdown table while omitting numeric columns that carry no information in this view. */
function renderNumericTable(headers, rows, numericColumns) {
    const keep = headers.map((_, index) => !numericColumns.includes(index) || rows.some((row) => {
        const value = (row[index] ?? '').trim();
        return value !== '' && value !== '—' && value !== '$0.00' && value !== '0' && value !== 'Unavailable from the current source';
    }));
    const filtered = (row) => row.filter((_, index) => keep[index]);
    const separator = headers.map((header, index) => numericColumns.includes(index) ? '---:' : '---');
    return [
        `| ${headers.filter((_, index) => keep[index]).join(' | ')} |`,
        `| ${separator.filter((_, index) => keep[index]).join(' | ')} |`,
        ...rows.map((row) => `| ${filtered(row).join(' | ')} |`),
    ];
}
function renderCategoryTable(rows) {
    const definitions = [
        { header: "Category", value: (row) => tableValue(row.label), numeric: false },
        { header: "Children/contracts", value: (row) => tableValue(row.children_served ?? row.children ?? row.contracts), numeric: true },
        { header: "Days", value: (row) => tableValue(row.days), numeric: true },
        { header: "Care hours", value: (row) => tableValue(row.hours), numeric: true },
        { header: "Expected amount", value: (row) => plainMoney(row.amount), numeric: true },
        { header: "At-risk amount", value: (row) => plainMoney(row.conditional_amount), numeric: true },
        { header: "Excluded days", value: (row) => tableValue(row.excluded_days), numeric: true },
    ];
    const renderedRows = rows.map((row) => definitions.map((definition) => definition.value(row)));
    const numericColumns = definitions.flatMap((definition, index) => definition.numeric ? [index] : []);
    return renderNumericTable(definitions.map((definition) => definition.header), renderedRows, numericColumns);
}
function atRiskDisclaimer(confirmByDate) {
    if (typeof confirmByDate === 'string' && confirmByDate.trim()) {
        return DISCLAIMER_AT_RISK.replace('{deadline}', shortDateLabel(confirmByDate) ?? tableValue(confirmByDate));
    }
    return DISCLAIMER_AT_RISK.replace(' before {deadline}', ' before the confirmation deadline');
}
function paymentDisclaimers(payment, paymentResult, attendance) {
    const disclaimers = [DISCLAIMER_GLOBAL];
    if (Number(payment.expected_amount) > 0)
        disclaimers.push(DISCLAIMER_EXPECTED);
    if (Number(payment.forecasted_amount) > 0)
        disclaimers.push(DISCLAIMER_FORECASTED);
    if (Number(payment.at_risk_amount ?? payment.amount_at_risk) > 0) {
        disclaimers.push(atRiskDisclaimer(attendance.find((day) => typeof day.confirm_by_date === "string")?.confirm_by_date
            ?? payment.confirm_by_date
            ?? paymentResult.confirm_by_date));
    }
    if (Number(payment.guaranteed_amount) > 0)
        disclaimers.push(DISCLAIMER_GUARANTEED);
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
function detailRowPriority(day) {
    const flags = Array.isArray(day.flags) ? day.flags.filter((flag) => typeof flag === 'string') : [];
    let score = 0;
    if (flags.includes('ABSENCE_LIMIT_EXCEEDED'))
        score += 4;
    if (flags.includes('PARENT_CONFIRMATION_UNAVAILABLE'))
        score += 4;
    // MISSING_ATTENDANCE_TRANSACTION = no check-in/check-out was ever logged
    // for a past-window scheduled day (INCOMPLETE_ATTENDANCE_RECORD) - distinct
    // from PARENT_CONFIRMATION_UNAVAILABLE (a transaction exists but wasn't
    // approved in time). Both are "unconfirmed past the window" concerns.
    if (flags.includes('MISSING_ATTENDANCE_TRANSACTION'))
        score += 4;
    if (day.classification === 'ABSENCE')
        score += 1;
    if (day.payment_excluded === true)
        score += 1;
    return score;
}
// Picks up to MAX_DETAIL_ROWS distinct children rather than up to
// MAX_DETAIL_ROWS individual rows - a single child's tied absence-limit
// days would otherwise crowd out every other affected child from the
// top-5 view. Each selected child contributes only their single
// highest-priority row (ties broken by most total absence/unconfirmed days
// for that child), so the table surfaces breadth across children first.
function topRankedRowsByChild(days) {
    const byChild = new Map();
    for (const day of days) {
        const key = typeof day.child_name === 'string' && day.child_name ? day.child_name : 'UNKNOWN';
        const entry = byChild.get(key) ?? { rows: [], maxPriority: 0, totalPriority: 0 };
        entry.rows.push(day);
        const priority = detailRowPriority(day);
        entry.maxPriority = Math.max(entry.maxPriority, priority);
        entry.totalPriority += priority;
        byChild.set(key, entry);
    }
    return [...byChild.values()]
        .sort((left, right) => right.maxPriority - left.maxPriority || right.totalPriority - left.totalPriority)
        .slice(0, MAX_DETAIL_ROWS)
        .map((entry) => [...entry.rows].sort((left, right) => detailRowPriority(right) - detailRowPriority(left))[0])
        .filter((row) => Boolean(row));
}
/**
 * Plain-language reason for an excluded day, folded into the Attendance
 * type cell in brackets (e.g. "Absence (paid) [absence limit exceeded]")
 * now that the separate Status/Payment columns have been removed.
 */
function exclusionReason(day) {
    const flags = Array.isArray(day.flags) ? day.flags.filter((flag) => typeof flag === 'string') : [];
    if (flags.includes('ABSENCE_LIMIT_EXCEEDED'))
        return 'absence limit exceeded';
    if (flags.includes('DROP_IN_LIMIT_EXCEEDED'))
        return 'drop-in limit exceeded';
    if (flags.includes('FISCAL_RATE_UNAVAILABLE'))
        return 'rate unavailable';
    if (flags.includes('PARENT_CONFIRMATION_UNAVAILABLE'))
        return 'confirmation unavailable';
    if (flags.includes('MISSING_ATTENDANCE_TRANSACTION'))
        return 'check-in/check-out not recorded';
    if (flags.includes('HOLIDAY_ALREADY_PAID') || flags.includes('HOLIDAY_ALREADY_PAID_ON_PAIRED_DATE'))
        return 'already paid';
    if (flags.includes('PAID_HOLIDAY_NOT_ALLOWED'))
        return 'holiday not allowed by county plan';
    if (flags.includes('DROP_IN_NOT_ALLOWED'))
        return 'drop-in not allowed by county plan';
    if (flags.includes('DROP_IN_LIMIT_UNAVAILABLE') || flags.includes('ABSENCE_LIMIT_UNAVAILABLE'))
        return 'limit unavailable from current source';
    if (flags.includes('AGE_BAND_UNAVAILABLE'))
        return 'age band unavailable';
    if (flags.includes('ABSENCE_APPROVAL_UNAVAILABLE'))
        return 'approval status unavailable';
    return 'excluded';
}
export function paymentActionMetadata(paymentResult, payment, detailPagination, status, detailPage) {
    const filterInput = recordValue(paymentResult.filters) ?? {};
    const highestImpactChildName = typeof paymentResult.highestImpactChildName === "string"
        ? paymentResult.highestImpactChildName
        : undefined;
    const highestImpactRankedByDollars = paymentResult.highestImpactRankedByDollars;
    const paymentInput = (overrides) => Object.assign({ view: paymentResult.paymentView ?? "NEXT_PAYOUT" }, filterInput, overrides);
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
            label: "Open next payment detail page",
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
export function paymentSummaryView(value) {
    return recordValue(value);
}
export function compactPaymentSummaryView(value) {
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
export function summaryRows(value, key) {
    const summary = paymentSummaryView(value);
    return summary && Array.isArray(summary[key])
        ? summary[key].map(recordValue).filter((row) => Boolean(row))
        : [];
}
export function formatPaymentResult(data) {
    const paymentResult = recordValue(data);
    const payment = paymentResult && recordValue(paymentResult.payment);
    if (!paymentResult || !payment)
        return result(data);
    const status = typeof payment.status === "string" ? payment.status.toUpperCase() : "BLOCKED";
    const detailPagination = recordValue(paymentResult.detailPagination);
    const detailPage = detailPagination && Number(detailPagination.page) > 0;
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
    const attendanceContainer = recordValue(paymentResult.attendance);
    const attendanceDays = attendanceContainer?.["days"];
    const excludedOnly = recordValue(paymentResult.filters)?.excludedOnly === true;
    const attendance = Array.isArray(attendanceDays)
        ? attendanceDays
            .map(recordValue)
            .filter((row) => Boolean(row))
            .filter((row) => row.classification !== "NO_CARE")
            .filter((row) => !excludedOnly || row.payment_excluded === true)
        : [];
    const missingInputs = Array.isArray(payment.missing_inputs)
        ? payment.missing_inputs.filter((value) => typeof value === "string")
        : [];
    const summaryView = paymentSummaryView(payment.summary_view);
    const disclaimers = paymentDisclaimers(payment, paymentResult, attendance);
    const statusLabel = status === "DUPLICATE_GUARD"
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
        `${view}: ${statusLabel}.`,
        ...(periodHeaderLabel ? [periodHeaderLabel] : []),
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
            const isDateField = label === "Services from" || label === "Services through" || label === "Payment processing date" || label === "Payment release date";
            if (value !== undefined)
                lines.push(`| ${label} | ${isDateField ? (shortDateLabel(value) ?? tableValue(value)) : tableValue(value)} |`);
        }
    }
    if (status === "BLOCKED") {
        lines.push(`| Missing source areas | ${missingInputs.length > 0 ? missingInputs.join(", ") : "Required source data is unavailable"} |`, "", "No payment amount is shown because the approved source data is incomplete.");
    }
    else {
        for (const [label, key] of [
            ["Estimated total", "amount"],
            ["Payout date", "payout_date"],
            ["Excluded authorizations", "excluded_authorizations"],
            ["Existing payment status", "existing_status"],
        ]) {
            if (payment[key] !== undefined && key === "amount") {
                lines.push(`| ${label} | ${estimatedMoney(payment[key])} |`);
            }
            else if (payment[key] !== undefined && key === "payout_date") {
                lines.push(`| ${label} | ${shortDateLabel(payment[key]) ?? tableValue(payment[key])} |`);
            }
            else if (payment[key] !== undefined) {
                lines.push(`| ${label} | ${String(payment[key])} |`);
            }
        }
        const netAmountNumeric = typeof payment.amount === "number" ? payment.amount : Number(payment.amount);
        const amountAtRiskNumeric = typeof payment.amount_at_risk === "number" ? payment.amount_at_risk : Number(payment.amount_at_risk);
        if (netAmountNumeric === 0 && Number.isFinite(amountAtRiskNumeric) && amountAtRiskNumeric > 0) {
            lines.push("", `This shows ${plainMoney(0)} net because the payable amount is still conditional, not denied - an estimated ${plainMoney(amountAtRiskNumeric)} remains possible once the pending confirmations below are completed. This is an estimate and will change as confirmations are completed.`, atRiskDisclaimer(attendance.find((day) => typeof day.confirm_by_date === "string")?.confirm_by_date ?? payment.confirm_by_date ?? paymentResult.confirm_by_date));
        }
        // Expected/Forecasted/At-risk breakdown replaces the single "Amount at
        // risk" row above. "Confirmed" is deliberately never used as a label -
        // it would imply the parent affirmatively acted, when Expected here
        // means only that the confirmation window elapsed.
        const singleChildFilter = Array.isArray(recordValue(paymentResult.filters)?.childNames)
            ? (recordValue(paymentResult.filters)?.childNames).length === 1
            : false;
        const hasAmountBreakdown = payment.expected_amount !== undefined
            || payment.forecasted_amount !== undefined
            || payment.at_risk_amount !== undefined;
        if (hasAmountBreakdown && detailPage) {
            lines.push("", "Expected - past the confirmation window; likely payable.", "Forecasted - within the confirmation window or a future date; may change.", "At risk - excluded or flagged; may reduce or exclude payment.");
            const expectedAmount = Number(payment.expected_amount) || 0;
            const forecastedAmount = Number(payment.forecasted_amount) || 0;
            const breakdownDisclaimers = [
                expectedAmount > 0 ? DISCLAIMER_EXPECTED : undefined,
                forecastedAmount > 0 ? DISCLAIMER_FORECASTED : undefined,
            ].filter((disclaimer) => Boolean(disclaimer));
            if (breakdownDisclaimers.length > 0)
                lines.push(breakdownDisclaimers.join(" "));
            if (!excludedOnly) {
                lines.push("", "| Category | Amount |", "| --- | ---: |", `| Expected | ${plainMoney(payment.expected_amount)} |`, `| Forecasted | ${plainMoney(payment.forecasted_amount)} |`);
            }
            lines.push("", "| At-risk reason | Amount |", "| --- | ---: |", `| Excluded or flagged | ${plainMoney(payment.at_risk_amount)} |`);
        }
        const summary = Array.isArray(payment.summary) ? payment.summary.map(recordValue).filter((row) => Boolean(row)) : [];
        if (summary.length > 0 && !summaryView && activeTableId === "payment-county-rollup") {
            const countySummary = countyPaymentSummary(summary);
            lines.push("", "County payment totals:", "> This compares children served, care hours, and calculated payment by county for the selected payment scope.", "| County | Children served | Care hours | Expected amount ($) | At-risk amount ($) |", "| --- | ---: | ---: | ---: | ---: |", ...countySummary.map((row) => `| ${tableValue(row.county_name)} | ${tableValue(row.children_served)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} |`));
        }
        const overview = summaryView && recordValue(summaryView.overview);
        // An excluded-only request or a single-child drill-down already narrows
        // the detail table to exactly the rows the provider asked about; the
        // category/county/child rollups restate the same totals and are the
        // main contributor to an oversized response for these cases, so they
        // are omitted here rather than rendered and then discarded by the client.
        const suppressRollups = excludedOnly || singleChildFilter;
        const categories = suppressRollups ? [] : summaryRows(summaryView, "categories");
        const countyRollup = suppressRollups ? [] : summaryRows(summaryView, "counties");
        const countyComposition = suppressRollups ? [] : summaryRows(summaryView, "county_composition");
        const childRollup = suppressRollups ? [] : summaryRows(summaryView, "children");
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
        if (categories.length > 0 && activeTableId === "payment-category-rollup") {
            lines.push("", "Payment by category:", "> This separates only the payment measures available for the requested category view; omitted columns were not populated for this scope.", ...renderCategoryTable(categories));
        }
        // County detail (the flat Days/Hours/Expected/At-risk/Excluded rollup)
        // has been merged into County payment composition below - it now
        // renders unconditionally instead of only for a summary (!detailPage)
        // view, so the county breakdown no longer reshapes entirely between a
        // payout summary and a payout detail response.
        if (countyComposition.length > 0 && (activeTableId === "payment-county-rollup" || (activeTableId === "payment-category-rollup" && categories.length === 0))) {
            lines.push(...renderCountyComposition(countyComposition));
        }
        if (childRollup.length > 0 && activeTableId === "payment-category-rollup") {
            // A child name alone does not uniquely identify a child - joining
            // every authorization number the rollup's days came from (there can
            // be more than one per child) disambiguates duplicate names.
            const authorizationCell = (row) => {
                const names = Array.isArray(row.authorization_names)
                    ? row.authorization_names.filter((name) => typeof name === "string" && name.length > 0)
                    : [];
                return names.length > 0 ? names.join(", ") : "Unavailable from the current source";
            };
            lines.push("", "Child detail:", "> This shows the payment measures behind the selected child scope; amounts remain estimates or at risk where labeled.", "| Child | Authorization | Days | Care hours | Expected amount | At-risk amount | Excluded days |", "| --- | --- | ---: | ---: | ---: | ---: | ---: |", ...childRollup.map((row) => `| ${tableValue(row.label)} | ${authorizationCell(row)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (vacantSlots.length > 0 && activeTableId === "vacant-slot-rollup") {
            // Rollup by county (Total days | Total amount) instead of one row per
            // slot-day - a provider gets the facility-level total at a glance;
            // the full day-by-day breakdown is available through the drill-down
            // action below rather than dumped inline every time.
            const vacantSlotsByCounty = new Map();
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
            lines.push("", "Payment next actions:", ...nextActions.slice(0, 3).map((row) => `- ${tableValue(row.label)}: ${tableValue(row.reason)} (${tableValue(row.days)} day(s), ${plainMoney(row.amount_at_risk)} at risk)`));
        }
        if (numericValue(payment.total_amount_incorrectly_at_risk) > 0) {
            lines.push("", `Holiday-classification mismatch affecting ${plainMoney(payment.total_amount_incorrectly_at_risk)} - see detail table below.`);
        }
        if (paymentResult.highestImpactRankedByDollars === false && !detailPage) {
            lines.push("", "A verified dollar amount at risk isn't available for this scope yet, so the drill-down below shows the child with the most scheduled hours instead of the highest dollar impact.");
        }
        if (attendance.length > 0 && activeTableId === "payment-category-rollup") {
            // Summary view: the orchestration now includes a small preview (a
            // few rows, not a full page) instead of an empty attendance.days -
            // render a compact preview table plus the total-row count, rather
            // than either the full ranked detail table (reserved for a real
            // detailPage request) or the old bare "Detail available: N rows"
            // text-only hint.
            const previewRows = attendance.map((day) => {
                const serviceDateLabel = shortDateLabel(day.service_date) ?? tableValue(day.service_date);
                const baseTypeLabel = day.payment_excluded === true
                    ? humanizeAttendanceType(day.classification).replace(/\s*\(paid\)/i, "")
                    : humanizeAttendanceType(day.classification);
                const attendanceTypeCell = day.payment_excluded === true
                    ? `${baseTypeLabel} [${exclusionReason(day)}]`
                    : baseTypeLabel;
                return `| ${tableValue(day.child_name)} | ${tableValue(day.county_name ?? "Unavailable from the current source")} | ${serviceDateLabel} | ${attendanceTypeCell} |`;
            });
            lines.push("", `Detail preview (${attendance.length} of ${tableValue(detailPagination?.totalRows)} child/date rows):`, "| Child | County | Service date | Attendance type |", "| --- | --- | --- | --- |", ...previewRows, "", "Request a detail page to inspect the remaining rows.");
        }
        else if (attendance.length > 0) {
            const forecastBasisRows = paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
                && attendance.some((day) => day.attendance_basis === "ACTUAL" || day.attendance_basis === "SCHEDULED");
            // actual_hours_total/scheduled_hours_total arrive as decimal-formatted
            // strings from the Python engine (e.g. "5.00"), not numbers - numericValue()
            // requires typeof "number" and would always read these as 0.
            const actualHoursTotal = Number(attendanceContainer?.actual_hours_total) || 0;
            const scheduledHoursTotal = Number(attendanceContainer?.scheduled_hours_total) || 0;
            if (forecastBasisRows && actualHoursTotal > 0 && scheduledHoursTotal > 0) {
                lines.push("", `Actual (checked in): ${tableValue(attendanceContainer?.actual_hours_total)} hours. Scheduled (projected): ${tableValue(attendanceContainer?.scheduled_hours_total)} hours.`);
            }
            const pageLabel = detailPagination
                ? `Showing detail rows ${((Number(detailPagination.page) - 1) * Number(detailPagination.pageSize)) + 1}-${Math.min(Number(detailPagination.page) * Number(detailPagination.pageSize), Number(detailPagination.totalRows))} of ${tableValue(detailPagination.totalRows)} (page ${tableValue(detailPagination.page)}; page size ${tableValue(detailPagination.pageSize)}).`
                : "";
            // Rank by risk and spread across distinct children - a single child's
            // tied absence-limit days must not crowd out every other affected
            // child, so at most MAX_DETAIL_ROWS children are shown, each
            // contributing their own single highest-priority row. The "Open next
            // payment detail page" action still walks the full paginated set for
            // a provider who wants everything.
            const displayedAttendance = topRankedRowsByChild(attendance);
            const distinctChildCount = new Set(attendance.map((day) => typeof day.child_name === "string" ? day.child_name : "UNKNOWN")).size;
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
    const paymentFilters = recordValue(paymentResult.filters);
    const paymentViewId = activeTableId === "payment-county-rollup"
        ? "PAYMENT_COUNTY_ROLLUP"
        : activeTableId === "vacant-slot-rollup"
            ? "VACANT_SLOT_ROLLUP"
            : paymentResult.paymentView === "NEXT_PAYOUT"
                ? "NEXT_UPCOMING_PAYOUT"
                : paymentResult.paymentView === "CURRENT_WEEK_FORECAST"
                    ? "CURRENT_SERVICE_PERIOD_FORECAST"
                    : detailPage
                        ? "SUB_PAYMENT_DETAIL"
                        : "PAYMENT_CATEGORY_ROLLUP";
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
        ...(detailPage ? { parentViewId: "PAYMENT_CATEGORY_ROLLUP" } : {}),
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
        const parentInput = { ...(paymentFilters ?? {}) };
        delete parentInput.detailPage;
        delete parentInput.detailPageSize;
        actionIntents.push({
            actionId: "return-to-payment-summary",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Return to payment category summary",
            reason: "Go back to the parent payment view without widening the verified provider scope.",
            priority: "medium",
            section: "navigation",
            source: "current-result",
            input: { ...parentInput, viewId: "PAYMENT_CATEGORY_ROLLUP" },
        });
    }
    const viewAwareActionIntents = actionIntents
        .map((action) => actionViewMetadata(action, currentView));
    const providerMessage = `${renderActionSections(lines.join("\n"), viewAwareActionIntents)}\n\n${DISCLAIMER_GLOBAL}`;
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
export function formatServicePeriodLedgerResult(data) {
    const value = recordValue(data);
    if (!value)
        return result(data);
    const labels = { IN_PROGRESS: "In progress", PENDING_CONFIRMATION: "Pending confirmation", EXPECTED_AWAITING_PAYOUT: "Expected, awaiting payout", PAID: "Paid" };
    // shortDateLabel already embeds the 2-digit year (e.g. "31st Aug'26"), so no
    // separate year suffix is appended here.
    const dateLabel = (date) => shortDateLabel(date) ?? "Unavailable from the current source";
    const entry = recordValue(value.entry);
    const periods = Array.isArray(value.periods) ? value.periods.map(recordValue).filter((row) => Boolean(row)) : undefined;
    const multiPeriod = value.periodMode === "MULTI_PERIOD" || (periods?.length ?? 0) > 1;
    const lines = [];
    if (periods) {
        const upcoming = periods.filter((period) => period.periodStatus !== "PAID").sort((a, b) => String(a.payoutDate ?? "").localeCompare(String(b.payoutDate ?? "")))[0];
        const renderPeriodRow = (period) => {
            const begin = dateLabel(period.serviceBeginDate), end = dateLabel(period.serviceEndDate);
            const servicePeriod = begin !== "Unavailable from the current source" && end !== "Unavailable from the current source" ? `${begin}-${end}` : "Unavailable from the current source";
            return `| ${tableValue(servicePeriod)} | ${tableValue(dateLabel(period.payoutDate))} | ${tableValue(labels[String(period.periodStatus)] ?? "Unavailable from the current source")} | ${plainMoney(period.netAmount)} | ${plainMoney(period.guaranteedAmount)} | ${plainMoney(period.amountAtRisk)} |`;
        };
        if (multiPeriod) {
            lines.push(`Showing ${periods.length} service periods from the verified payout ledger. The soonest upcoming payout is estimated at ~ ${estimatedMoney(upcoming?.netAmount)} net.`);
            lines.push("", "> This ledger compares multiple service periods; select the next upcoming payout for a single-period view.", "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", ...periods.map(renderPeriodRow));
        }
        else if (upcoming) {
            lines.push(`Showing the next upcoming service period only: an estimated ${estimatedMoney(upcoming.netAmount)} net on ${dateLabel(upcoming.payoutDate)}.`, "", "> This shows only the next unpaid or upcoming payout identified from verified service-period data.", "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", renderPeriodRow(upcoming));
        }
        else {
            lines.push("No upcoming unpaid payout is currently identified from verified data.");
        }
    }
    else if (entry) {
        const days = value.daysUntilPayout;
        const countdown = typeof days === "number" ? `${days} day${days === 1 ? "" : "s"}` : "an undetermined number of days";
        lines.push(`Payout in ${countdown}, on ${dateLabel(entry.payoutDate)}: an estimated ${estimatedMoney(entry.netAmount)} net.`);
        lines.push(Number(entry.amountAtRisk) > 0
            ? atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)
            : DISCLAIMER_EXPECTED);
    }
    else
        lines.push("No upcoming payout is currently identified from verified data.");
    const ledgerDisclaimers = [
        DISCLAIMER_GLOBAL,
        ...(entry && Number(entry.amountAtRisk) > 0
            ? [atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)]
            : entry ? [DISCLAIMER_EXPECTED] : []),
    ];
    const actionIntents = multiPeriod
        ? [
            { actionId: "open-next-upcoming-payout", capability: "payment-analysis", label: "Open next upcoming payout", reason: "Focus on the nearest unpaid or upcoming service period.", priority: "high", section: "next-actions", source: "current-result", input: { viewId: "NEXT_UPCOMING_PAYOUT" } },
        ]
        : [{ actionId: "review-service-period-payout-ledger", capability: "payment-analysis", label: "Review payment details for this service period", reason: "Inspect the source-backed payment calculation behind this payout period.", priority: "medium", section: "next-actions", source: "current-result" }];
    const currentView = viewState({
        viewId: multiPeriod ? "PAYOUT_LEDGER" : "NEXT_UPCOMING_PAYOUT",
        tableId: multiPeriod ? "payout-ledger" : "payout-summary",
        tableTitle: multiPeriod ? "Payout ledger" : "Next upcoming payout",
        tableDescription: multiPeriod ? "This table compares multiple verified service periods and their payout status." : "This table shows only the next unpaid or upcoming payout identified from verified service-period data.",
        ...(value.scope !== undefined ? { scope: value.scope } : {}),
        ...(typeof value.sourceRetrievedAt === "string" ? { sourceRetrievedAt: value.sourceRetrievedAt } : {}),
    });
    const viewAwareActionIntents = actionIntents.map((action) => actionViewMetadata(action, currentView));
    const providerMessage = `${renderActionSections(lines.join("\n"), viewAwareActionIntents)}\n\n${DISCLAIMER_GLOBAL}`;
    return { content: [{ type: "text", text: providerMessage }], structuredContent: { capability: "service-period-payout-ledger", viewState: currentView, periods: periods ?? [], ...(entry ? { entry } : {}), ...(value.daysUntilPayout !== undefined ? { daysUntilPayout: value.daysUntilPayout } : {}), sourceRetrievedAt: value.sourceRetrievedAt, paymentDisclaimers: [...new Set(ledgerDisclaimers)], actionIntents, actionControls: actionControls(viewAwareActionIntents), responseSections: ["summary", "ledger", "next-actions"] } };
}
