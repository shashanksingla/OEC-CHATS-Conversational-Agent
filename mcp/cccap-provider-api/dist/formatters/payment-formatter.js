import { actionControls, countyPaymentSummary, estimatedMoney, plainMoney, humanizeAttendanceType, numericValue, recordValue, renderActionSections, renderCountyComposition, result, shortDateLabel, tableValue, DISCLAIMER_AT_RISK, DISCLAIMER_EXPECTED, DISCLAIMER_FORECASTED, DISCLAIMER_GLOBAL } from './shared.js';
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
function atRiskDisclaimer(confirmByDate) {
    if (typeof confirmByDate === 'string' && confirmByDate.trim()) {
        return DISCLAIMER_AT_RISK.replace('{deadline}', tableValue(confirmByDate));
    }
    return DISCLAIMER_AT_RISK.replace(' before {deadline}', ' before the confirmation deadline');
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
    const view = paymentResult.paymentView === "NEXT_PAYOUT"
        ? detailPage ? "Next payout detail" : "Next payout summary"
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
    const statusLabel = status === "DUPLICATE_GUARD"
        ? "Already paid or requested"
        : status === "CONDITIONAL"
            ? "Conditional"
            : status === "EXPECTED"
                ? "Expected"
                : "Blocked";
    const periodBeginLabel = servicePeriod ? shortDateLabel(servicePeriod.serviceBeginDate ?? servicePeriod.start_date) : undefined;
    const periodEndLabel = servicePeriod ? shortDateLabel(servicePeriod.serviceEndDate ?? servicePeriod.end_date) : undefined;
    const periodYear = servicePeriod ? String(servicePeriod.serviceEndDate ?? servicePeriod.end_date ?? "").slice(0, 4) : undefined;
    const periodHeaderLabel = periodBeginLabel && periodEndLabel
        ? `${paymentResult.paymentView === "CUSTOM_RANGE" ? "Custom period" : "Payout period"}: ${periodBeginLabel}-${periodEndLabel}${periodYear ? `, ${periodYear}` : ""}`
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
            if (value !== undefined)
                lines.push(`| ${label} | ${tableValue(value)} |`);
        }
    }
    if (status === "BLOCKED") {
        lines.push(`| Missing source areas | ${missingInputs.length > 0 ? missingInputs.join(", ") : "Required source data is unavailable"} |`, "", "No payment amount is shown because the approved source data is incomplete.");
    }
    else {
        for (const [label, key] of [
            ["Estimated total", "amount"],
            ["Gross amount", "gross_amount"],
            ["Excluded days", "excluded_days"],
            ["Excluded authorizations", "excluded_authorizations"],
            ["Existing payment status", "existing_status"],
        ]) {
            if (payment[key] !== undefined && key === "amount") {
                lines.push(`| ${label} | ${estimatedMoney(payment[key])} |`);
            }
            else if (payment[key] !== undefined && key === "gross_amount") {
                lines.push(`| ${label} | ${plainMoney(payment[key])} |`);
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
            lines.push("", "Expected - past the  confirmation window; likely payable.", "Forecasted - within the confirmation window or a future date; may change.", "At risk - excluded or flagged; may reduce or exclude payment.");
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
        if (summary.length > 0 && !summaryView && detailPage) {
            const countySummary = countyPaymentSummary(summary);
            lines.push("", "County payment totals:", "The table below shows children served, care hours, and calculated payment by county.", "| County | Children served | Care hours | Expected amount ($) | At-risk amount ($) |", "| --- | ---: | ---: | ---: | ---: |", ...countySummary.map((row) => `| ${tableValue(row.county_name)} | ${tableValue(row.children_served)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} |`));
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
        if (overview && detailPage) {
            lines.push("", "Payment differences:", "| Paid days | Review items | Excluded days | Amount at risk | Vacant-slot amount |", "| ---: | ---: | ---: | ---: | ---: |", `| ${tableValue(overview.paid_days)} | ${tableValue(overview.review_items)} | ${tableValue(overview.excluded_days)} | ${plainMoney(overview.amount_at_risk)} | ${plainMoney(payment.vacant_slot_fee)} |`);
        }
        if (categories.length > 0 && detailPage) {
            lines.push("", "Payment by category:", "| Category | Days | Hours | Expected amount | At-risk amount | Excluded days |", "| --- | ---: | ---: | ---: | ---: | ---: |", ...categories.map((row) => `| ${tableValue(row.label)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (countyRollup.length > 0 && detailPage) {
            lines.push("", "County detail:", "| County | Days | Hours | Expected amount | At-risk amount | Excluded days |", "| --- | ---: | ---: | ---: | ---: | ---: |", ...countyRollup.map((row) => `| ${tableValue(row.label)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (countyComposition.length > 0 && !detailPage) {
            lines.push(...renderCountyComposition(countyComposition));
        }
        if (childRollup.length > 0 && detailPage) {
            lines.push("", "Child detail:", "| Child | Days | Hours | Expected amount | At-risk amount | Excluded days |", "| --- | ---: | ---: | ---: | ---: | ---: |", ...childRollup.map((row) => `| ${tableValue(row.label)} | ${tableValue(row.days)} | ${tableValue(row.hours)} | ${plainMoney(row.amount)} | ${plainMoney(row.conditional_amount)} | ${tableValue(row.excluded_days)} |`));
        }
        if (vacantSlots.length > 0) {
            // guaranteed_amount from the payment engine is not yet surfaced in this formatter; a later workstream will wire it in.
            lines.push("", "Vacant slots (separate from child payments):", "| County | Service date | Classification | Amount |", "| --- | --- | --- | ---: |", ...vacantSlots.map((row) => `| ${tableValue(row.county_name)} | ${tableValue(row.service_date)} | ${tableValue(row.classification)} | ${plainMoney(row.amount)} |`));
        }
        if (nextActions.length > 0) {
            lines.push("", "Payment next actions:", ...nextActions.slice(0, 3).map((row) => `- ${tableValue(row.label)}: ${tableValue(row.reason)} (${plainMoney(row.amount_at_risk)} at risk)`));
        }
        if (paymentResult.highestImpactRankedByDollars === false && !detailPage) {
            lines.push("", "A verified dollar amount at risk isn't available for this scope yet, so the drill-down below shows the child with the most scheduled hours instead of the highest dollar impact.");
        }
        if (attendance.length > 0) {
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
            const detailHeaders = forecastBasisRows
                ? ["Child", "County", "Service date", "Attendance type", "Basis", "Care hours", "Status", "Payment"]
                : ["Child", "County", "Service date", "Attendance type", "Care hours", "Status", "Payment"];
            const detailRows = attendance.map((day) => {
                const basis = day.attendance_basis === "ACTUAL"
                    ? "Actual (checked in)"
                    : day.attendance_basis === "SCHEDULED"
                        ? "Scheduled (projected)"
                        : "";
                const statusLabel = day.payment_type === "GUARANTEED"
                    ? "Guaranteed"
                    : day.conditional === true ? "Pending confirmation" : "Confirmed";
                return forecastBasisRows
                    ? [tableValue(day.child_name), tableValue(day.county_name ?? "Unavailable from the current source"), tableValue(day.service_date), humanizeAttendanceType(day.classification), basis, tableValue(day.unit_hours), statusLabel, day.payment_excluded === true ? "Excluded" : "Included"]
                    : [tableValue(day.child_name), tableValue(day.county_name ?? "Unavailable from the current source"), tableValue(day.service_date), humanizeAttendanceType(day.classification), tableValue(day.unit_hours), statusLabel, day.payment_excluded === true ? "Excluded" : "Included"];
            });
            const numericDetailColumns = forecastBasisRows ? [5] : [4];
            lines.push("", "Detail by child and service date:", ...(pageLabel ? [pageLabel] : []), ...renderNumericTable(detailHeaders, detailRows, numericDetailColumns));
        }
        else if (detailPagination && Number(detailPagination.totalRows) > 0) {
            lines.push("", `Detail available: ${tableValue(detailPagination.totalRows)} child/date rows. Request a detail page to inspect them.`);
        }
    }
    const actionIntents = paymentActionMetadata(paymentResult, payment, detailPagination, status, Boolean(detailPage));
    const providerMessage = `${renderActionSections(lines.join("\n"), actionIntents)}\n\n${DISCLAIMER_GLOBAL}`;
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
export function formatServicePeriodLedgerResult(data) {
    const value = recordValue(data);
    if (!value)
        return result(data);
    const labels = { IN_PROGRESS: "In progress", PENDING_CONFIRMATION: "Pending confirmation", EXPECTED_AWAITING_PAYOUT: "Expected, awaiting payout", PAID: "Paid" };
    const dateLabel = (date) => {
        const short = shortDateLabel(date);
        const year = typeof date === "string" ? date.slice(0, 4) : "";
        return short ? (year ? `${short}, ${year}` : short) : "Unavailable from the current source";
    };
    const entry = recordValue(value.entry);
    const periods = Array.isArray(value.periods) ? value.periods.map(recordValue).filter((row) => Boolean(row)) : undefined;
    const lines = [];
    if (periods) {
        const upcoming = periods.filter((period) => period.periodStatus !== "PAID").sort((a, b) => String(a.payoutDate ?? "").localeCompare(String(b.payoutDate ?? "")))[0];
        lines.push(upcoming ? `Showing ${periods.length} service periods. The soonest upcoming payout is an estimated ${estimatedMoney(upcoming.netAmount)} net on ${dateLabel(upcoming.payoutDate)}.` : `Showing ${periods.length} service periods. No upcoming unpaid payout is currently identified from verified data.`, "", "| Service period | Payout date | Status | Net amount | Guaranteed amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", ...periods.map((period) => {
            const begin = dateLabel(period.serviceBeginDate), end = dateLabel(period.serviceEndDate);
            const servicePeriod = begin !== "Unavailable from the current source" && end !== "Unavailable from the current source" ? `${begin}-${end}` : "Unavailable from the current source";
            return `| ${tableValue(servicePeriod)} | ${tableValue(dateLabel(period.payoutDate))} | ${tableValue(labels[String(period.periodStatus)] ?? "Unavailable from the current source")} | ${plainMoney(period.netAmount)} | ${plainMoney(period.guaranteedAmount)} | ${plainMoney(period.amountAtRisk)} |`;
        }));
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
    const actionIntents = [{ actionId: "review-service-period-payout-ledger", capability: "payment-analysis", label: "Review payment details for a service period", reason: "Inspect the source-backed payment calculation behind a payout period.", priority: "medium", section: "next-actions", source: "current-result" }];
    const providerMessage = `${renderActionSections(lines.join("\n"), actionIntents)}\n\n${DISCLAIMER_GLOBAL}`;
    return { content: [{ type: "text", text: providerMessage }], structuredContent: { capability: "service-period-payout-ledger", periods: periods ?? [], ...(entry ? { entry } : {}), ...(value.daysUntilPayout !== undefined ? { daysUntilPayout: value.daysUntilPayout } : {}), sourceRetrievedAt: value.sourceRetrievedAt, actionIntents, actionControls: actionControls(actionIntents), responseSections: ["summary", "ledger", "next-actions"] } };
}
