// Consolidated attendance formatter: merges snapshot-formatter.ts (2026-09-15 consolidation).
import { actionControls, compactActionControls, estimatedMoney, recordValue, renderActionSections, result, shortDateLabel, tableValue, MAX_DISPLAY_CHILDREN, MAX_SUMMARY_ROWS } from './shared.js';
import { actionViewMetadata, viewState } from '../view-state.js';
/** Render an attendance table while omitting numeric columns that are zero in every rendered row. */
function renderAttendanceNumericTable(headers, rows, numericColumns) {
    // "Unavailable from the current source" is deliberately NOT in this
    // suppression list - it is meaningful (a value genuinely couldn't be
    // resolved), not a zero-value, and must still render so the provider sees
    // why a figure is missing rather than having the whole column vanish
    // (this previously broke the single-row "unavailable limit" case, where
    // every row's value for that column was the unavailable marker).
    const keep = headers.map((_, index) => !numericColumns.includes(index) || rows.some((row) => {
        const value = (row[index] ?? '').trim();
        return value !== '' && value !== '—' && value !== '0' && value !== '0.00' && value !== '$0.00';
    }));
    const filtered = (row) => row.filter((_, index) => keep[index]);
    return [
        `| ${headers.filter((_, index) => keep[index]).join(' | ')} |`,
        `| ${headers.map((_, index) => numericColumns.includes(index) ? '---:' : '---').filter((_, index) => keep[index]).join(' | ')} |`,
        ...rows.map((row) => `| ${filtered(row).join(' | ')} |`),
    ];
}
export function compactAttendanceSummary(attendanceView) {
    if (!attendanceView)
        return undefined;
    return {
        overview: attendanceView.overview,
        counties: attendanceView.counties,
    };
}
export function sourceIntegrityError(scope, message) {
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
export function formatAttendanceRiskResult(data, includeContinuationMetadata = false) {
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
    const isChildScoped = normalizedRequestedChildren.size > 0;
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
    // Hoisted to function scope (not just inside the child-table block below)
    // since the Attendance overview/county tables further down also need to
    // pick their column shape based on this same focus.
    const isIncompleteAttendanceFocus = riskFocus === "INCOMPLETE_ATTENDANCE";
    // Hoisted alongside isIncompleteAttendanceFocus for the same reason: the
    // Attendance overview/county tables and the child-scoped multi-risk branch
    // further down all need to pick their exclusive shape based on these too.
    const isAbsenceLimitFocus = riskFocus === "ABSENCE_LIMITS";
    const isParentConfirmationsFocus = riskFocus === "PARENT_CONFIRMATIONS";
    // Real pagination for the ABSENCE_LIMITS child-level drill-down - the
    // request's own detailPage/detailPageSize (threaded through via
    // analysis.scope, since `scope` here is the full validated request object,
    // not just a date range) rather than a fixed top-N cap.
    const requestedDetailPage = (() => {
        const value = recordValue(analysis.scope)?.detailPage;
        return typeof value === "number" && Number.isInteger(value) && value > 0 ? value : 1;
    })();
    const requestedDetailPageSize = (() => {
        const value = recordValue(analysis.scope)?.detailPageSize;
        return typeof value === "number" && Number.isInteger(value) && value > 0 ? value : MAX_DISPLAY_CHILDREN;
    })();
    const incompleteDays = affectedChildren.reduce((total, child) => total + numericValue(child.incomplete_attendance_days), 0);
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
    // Hoisted ahead of the isNarrowedToDetail/riskFocus-specific branches
    // below (the PARENT_CONFIRMATIONS county-first branch needs
    // attendanceCounties before the generic overview/county rendering block
    // that used to declare these further down).
    const attendanceOverview = recordValue(attendanceView.overview);
    const attendanceCounties = Array.isArray(attendanceView.counties)
        ? attendanceView.counties.map(recordValue).filter((row) => Boolean(row))
        : [];
    const attendanceViews = Array.isArray(attendanceView.available_views)
        ? attendanceView.available_views.map(recordValue).filter((row) => Boolean(row))
        : [];
    const attendanceScope = recordValue(analysis.scope);
    const attendancePeriodBeginLabel = shortDateLabel(attendanceScope?.dateFrom);
    const attendancePeriodEndLabel = shortDateLabel(attendanceScope?.dateTo);
    // shortDateLabel already embeds the 2-digit year (e.g. "31st Aug'26"), so no
    // separate year suffix is appended here - that would duplicate the year.
    const attendancePeriodHeaderLabel = attendancePeriodBeginLabel && attendancePeriodEndLabel
        ? `Attendance period: ${attendancePeriodBeginLabel}-${attendancePeriodEndLabel}`
        : undefined;
    // Bolded: this is the response's "Interpretation" line per the
    // conversation-templates contract - the single most important sentence in
    // the whole response, previously rendered as plain prose indistinguishable
    // from any other line.
    const interpretationLine = noAttendanceRecords
        ? `${scopeLabel} attendance review returned no attendance records for the requested period.`
        : affectedChildren.length > 0
            ? `${scopeLabel} attendance review found ${affectedChildren.length} child(ren) needing attention.`
            : `${scopeLabel} attendance review found no child-level attendance risks.`;
    const lines = [
        `**${interpretationLine}**`,
        // Bolded: this is the response's mandatory "Scope" line - a visible
        // period header that must never blend into surrounding prose.
        ...(attendancePeriodHeaderLabel ? [`**${attendancePeriodHeaderLabel}**`] : []),
    ];
    if (unmatchedChildNames.length > 0) {
        lines.push(`No attendance records were found for ${unmatchedChildNames.length} requested child(ren) in the selected period.`);
    }
    if (unmatchedCountyNames.length > 0) {
        lines.push(`No affected children were found for the requested county/counties: ${unmatchedCountyNames.join(", ")}.`);
    }
    // Styled as a blockquote legend (matching the "> ..." convention already
    // used for every other explanatory note in this file) instead of a bare
    // sentence indistinguishable from a finding.
    if (excludedClosureDates.length > 0) {
        lines.push(`> Excluded ${excludedClosureDates.length} closure date(s): ${excludedClosureDates.map((date) => shortDateLabel(date) ?? tableValue(date)).join(", ")} (provider closed).`);
    }
    if (excludedHolidayDates.length > 0) {
        lines.push(`> Excluded ${excludedHolidayDates.length} holiday date(s): ${excludedHolidayDates.map((date) => shortDateLabel(date) ?? tableValue(date)).join(", ")} (paid holiday, not an absence).`);
    }
    if (riskFocus !== "ABSENCE_LIMITS" && riskFocus !== "INCOMPLETE_ATTENDANCE" && pendingDays > 0) {
        // Bolded: the confirmation deadline/days-left is the single most
        // time-critical fact in this sentence and was previously buried in
        // plain prose alongside the day/child counts.
        const deadlineSuffix = typeof risk.earliest_confirmation_deadline === "string" && typeof risk.earliest_confirmation_days_remaining === "number"
            ? ` **Earliest confirmation deadline: ${shortDateLabel(risk.earliest_confirmation_deadline) ?? tableValue(risk.earliest_confirmation_deadline)} (${risk.earliest_confirmation_days_remaining} day(s) left).**`
            : "";
        lines.push(`${pendingDays} pending parent confirmation day(s) affect ${pendingChildren} child(ren).${deadlineSuffix}`);
    }
    if (riskFocus !== "PARENT_CONFIRMATIONS" && riskFocus !== "INCOMPLETE_ATTENDANCE" && absenceChildren > 0) {
        // Distinguish children who have actually crossed the county's monthly
        // absence limit (real payment exclusion risk) from those merely
        // approaching it (still within limit, no exclusion yet) - a single
        // "have an absence-limit concern" sentence summed across both groups
        // reads as if every listed absence day is at risk, even when the county
        // table below shows 0 children over limit.
        const crossedCount = affectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("ABSENCE_LIMIT_EXCEEDED")).length;
        const approachingOnlyCount = absenceChildren - crossedCount;
        const daysSuffix = probableAbsenceDays > 0 ? ` (${probableAbsenceDays}d total)` : "";
        if (crossedCount > 0 && approachingOnlyCount > 0) {
            lines.push(`${crossedCount} child(ren) over limit, ${approachingOnlyCount} approaching${daysSuffix}.`);
        }
        else if (crossedCount > 0) {
            lines.push(`${crossedCount} child(ren) over the absence limit${daysSuffix}.`);
        }
        else {
            lines.push(`${approachingOnlyCount} child(ren) approaching the absence limit${daysSuffix} - not excluded yet.`);
        }
    }
    if (!riskFocus && incompleteChildren > 0) {
        // "Incomplete" here = exactly one of check-in/check-out logged; a
        // payment drill-down's "not recorded" reason is stricter (neither
        // logged), so the two counts are not directly comparable.
        lines.push(`${incompleteChildren} child(ren) have incomplete attendance records (one of check-in/check-out missing). See "Review incomplete attendance."`);
    }
    // County-summary-first: the child-level table (and INCOMPLETE_ATTENDANCE's
    // day-level detail table) render only when this request is already scoped
    // to a named child OR a named county (either is an explicit narrowing, not
    // a facility-wide ask) - a fully unscoped riskFocus request shows only the
    // county rollup below plus a "Show affected children" action, instead of
    // always jumping straight to every affected child's row.
    const isNarrowedToDetail = isChildScoped || normalizedRequestedCounties.size > 0;
    // PARENT_CONFIRMATIONS is exclusive-by-design and does not follow the
    // generic county-summary/child-table layout below: whenever it isn't
    // narrowed to a named child, it always renders its own two tables (county
    // pending totals, then top-4 children by pending count) regardless of
    // county narrowing - the spec's exact 2-table shape for this risk area.
    const showGenericAttendanceLayout = !(isParentConfirmationsFocus && !isChildScoped);
    // A named child/child-list with no riskFocus is the "particular child or
    // list of children" scope from the spec - it gets up to 3 separate
    // exclusive tables (absence, pending, incomplete) instead of collapsing
    // into the single generic drillDownColumns shape below.
    const isChildScopedMultiRisk = isChildScoped && !riskFocus;
    // This dedicated block only covers the !isChildScoped case (the
    // unscoped, county-first entry point into PARENT_CONFIRMATIONS). The
    // generic county-table block further below has its OWN PARENT_CONFIRMATIONS
    // branch that covers the isChildScoped case with the identical table shape
    // - without this guard, a child-scoped pending-confirmations request hit
    // BOTH blocks and rendered "Attendance by county (pending confirmations):"
    // twice in the same response.
    if (isParentConfirmationsFocus && !isChildScoped && attendanceCounties.length > 0) {
        const pendingCounties = [...attendanceCounties]
            .sort((left, right) => numericValue(right.pending_confirmation_days) - numericValue(left.pending_confirmation_days))
            .slice(0, 4);
        lines.push("", "Attendance by county (pending confirmations):", "| County | Children | Risk children | Pending confirmations |", "| --- | ---: | ---: | ---: |", ...pendingCounties.map((county) => `| ${tableValue(county.county)} | ${tableValue(county.children)} | ${tableValue(county.risk_children)} | ${tableValue(county.pending_confirmation_days)} |`));
    }
    if (isParentConfirmationsFocus && !isChildScoped && affectedChildren.length > 0) {
        const topPendingChildren = [...affectedChildren]
            .sort((left, right) => numericValue(right.pending_confirmation_days) - numericValue(left.pending_confirmation_days))
            .slice(0, 4);
        lines.push("", "Top children by pending confirmations:", 
        // "Earliest deadline" (header, not bare "Deadline") - a child with
        // Pending > 1 can have several different confirmation deadlines; this
        // is only ever the soonest one. Days left counts down to that date.
        "Days left = time remaining until the earliest deadline shown.", "| Child | Authorization | County | Pending | Earliest deadline | Days left |", "| --- | --- | --- | ---: | --- | ---: |", ...topPendingChildren.map((child) => `| ${tableValue(child.child_name)} | ${authorizationNames(child.authorization_names)} | ${tableValue(child.county)} | ${tableValue(child.pending_confirmation_days)} | ${typeof child.next_confirmation_deadline === "string" ? (shortDateLabel(child.next_confirmation_deadline) ?? tableValue(child.next_confirmation_deadline)) : "Unavailable from the current source"} | ${tableValue(child.confirmation_days_remaining)} |`));
        if (affectedChildren.length > topPendingChildren.length) {
            lines.push("", `Showing the top ${topPendingChildren.length} of ${affectedChildren.length} affected children by pending confirmations. Ask for a specific child by name for their full detail.`);
        }
    }
    if (isChildScopedMultiRisk && affectedChildren.length > 0) {
        const absenceRows = affectedChildren.filter(hasAbsenceLimitConcern);
        const pendingRows = affectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("PARENT_CONFIRMATION_PENDING"));
        const incompleteRows = affectedChildren.filter((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD"));
        // Each risk area present for these specific children renders as its own
        // exclusive table - a category with zero matching children among the
        // requested scope is omitted entirely rather than shown empty.
        if (absenceRows.length > 0) {
            lines.push("", "Absence-limit detail:", "County limit = approved monthly limit.", "| Child | Authorization | County | Absences used | County limit |", "| --- | --- | --- | ---: | ---: |", ...absenceRows.map((child) => `| ${tableValue(child.child_name)} | ${authorizationNames(child.authorization_names)} | ${tableValue(child.county)} | ${tableValue(child.absence_days)} | ${tableValue(child.absence_limit)} |`));
        }
        if (pendingRows.length > 0) {
            lines.push("", "Pending parent confirmation detail:", 
            // "Earliest deadline" (header, not bare "Deadline") - a child with
            // Pending > 1 can have several different confirmation deadlines;
            // this is only ever the soonest one.
            "Days left = time remaining until the earliest deadline shown.", "| Child | Authorization | County | Pending | Earliest deadline | Days left |", "| --- | --- | --- | ---: | --- | ---: |", ...pendingRows.map((child) => `| ${tableValue(child.child_name)} | ${authorizationNames(child.authorization_names)} | ${tableValue(child.county)} | ${tableValue(child.pending_confirmation_days)} | ${typeof child.next_confirmation_deadline === "string" ? (shortDateLabel(child.next_confirmation_deadline) ?? tableValue(child.next_confirmation_deadline)) : "Unavailable from the current source"} | ${tableValue(child.confirmation_days_remaining)} |`));
        }
        if (incompleteRows.length > 0) {
            const incompleteDetailRows = incompleteRows.flatMap((child) => {
                const records = Array.isArray(child.incomplete_attendance_records)
                    ? child.incomplete_attendance_records.map(recordValue).filter((record) => Boolean(record))
                    : [];
                return records.length > 0
                    ? records.map((record) => [tableValue(child.child_name), authorizationNames(child.authorization_names), tableValue(child.county), tableValue(record.date), tableValue(record.missing_record), tableValue(record.care_hours_at_risk)])
                    : [[tableValue(child.child_name), authorizationNames(child.authorization_names), tableValue(child.county), "Unavailable from the current source", "Unavailable from the current source", "Unavailable from the current source"]];
            });
            lines.push("", "Incomplete attendance detail:", "Missing record identifies whether the check-in, check-out, or both records were not returned.", ...renderAttendanceNumericTable(["Child", "Authorization", "County", "Date", "Missing record", "Care hours at risk"], incompleteDetailRows, [5]));
        }
    }
    if (affectedChildren.length > 0 && isNarrowedToDetail && showGenericAttendanceLayout && !isChildScopedMultiRisk) {
        // ABSENCE_LIMITS pages through the complete affected-child list via
        // detailPage/detailPageSize (real pagination) instead of a fixed top-N
        // criticality-ranked preview - every other focus keeps the existing
        // top-N-with-"ask by name" preview behavior.
        const sortedForDisplay = [...affectedChildren].sort((left, right) => criticalityScore(right) - criticalityScore(left));
        const displayedChildren = isAbsenceLimitFocus
            ? sortedForDisplay.slice((requestedDetailPage - 1) * requestedDetailPageSize, (requestedDetailPage - 1) * requestedDetailPageSize + requestedDetailPageSize)
            : isParentConfirmationsFocus
                ? [...affectedChildren]
                    .sort((left, right) => numericValue(right.pending_confirmation_days) - numericValue(left.pending_confirmation_days))
                    .slice(0, 4)
                : sortedForDisplay.slice(0, Math.min(MAX_DISPLAY_CHILDREN, MAX_SUMMARY_ROWS));
        // Column set depends on the risk focus: absence-limit risk is about
        // usage vs. the approved limit (not a "pending confirmation" concept),
        // so it gets its own simplified two-column shape instead of reusing the
        // generic Pending/Outside window/Over limit/Est. risk set.
        // Note: INCOMPLETE_ATTENDANCE never reaches the generic drillDownColumns
        // table below - it always takes the dedicated "Incomplete attendance
        // detail" (day-level) branch a few lines down, so no column-set entry is
        // defined for that focus here (a previous "Scheduled days/Incomplete
        // days" column set existed here but was dead code - unreachable).
        const drillDownColumns = isAbsenceLimitFocus
            ? [
                { label: "Absences used", value: (child) => tableValue(child.absence_days), present: displayedChildren.some((child) => numericValue(child.absence_days) !== 0) },
                { label: "County limit", value: (child) => tableValue(child.absence_limit), present: displayedChildren.some((child) => child.absence_limit !== undefined && child.absence_limit !== null) },
            ]
            : isParentConfirmationsFocus
                ? [
                    // Dedicated shape for this focus too: a provider reviewing
                    // pending parent confirmations wants confirmation-window
                    // information (days pending, deadline), not absence-limit data
                    // (Absences used/Over limit) - those describe a completely
                    // different risk and made this view look near-identical to the
                    // absence-limit drill-down.
                    { label: "Pending", value: (child) => tableValue(child.pending_confirmation_days), present: displayedChildren.some((child) => numericValue(child.pending_confirmation_days) !== 0) },
                    // "Earliest deadline" (not bare "Deadline") - a child with
                    // multiple pending days can have multiple different confirmation
                    // deadlines; this column is only ever the soonest one, and the
                    // header itself now says so instead of relying on a legend line
                    // that's easy to miss when "Pending" shows a count > 1.
                    { label: "Earliest deadline", value: (child) => typeof child.next_confirmation_deadline === "string" ? (shortDateLabel(child.next_confirmation_deadline) ?? tableValue(child.next_confirmation_deadline)) : "Unavailable from the current source", present: displayedChildren.some((child) => typeof child.next_confirmation_deadline === "string") },
                    { label: "Days left", value: (child) => tableValue(child.confirmation_days_remaining), present: displayedChildren.some((child) => typeof child.confirmation_days_remaining === "number") },
                ]
                : [
                    { label: "Pending", value: (child) => tableValue(child.pending_confirmation_days), present: displayedChildren.some((child) => numericValue(child.pending_confirmation_days) !== 0) },
                    // Same underlying field (absence_days) as "Absences used" above -
                    // consolidated onto one label used regardless of riskFocus, instead
                    // of two different names for the identical number.
                    { label: "Absences used", value: (child) => tableValue(child.absence_days), present: displayedChildren.some((child) => numericValue(child.absence_days) !== 0) },
                    { label: "Over limit", value: (child) => overLimitDays(child.absence_days, child.absence_limit), present: displayedChildren.some((child) => numericValue(child.absence_days) > numericValue(child.absence_limit)) },
                    { label: "Est. risk ($)", value: (child) => estimatedMoney(numericValue(child.risk_amount_estimate)), present: displayedChildren.some((child) => numericValue(child.risk_amount_estimate) > 0) },
                ];
        const renderedColumns = drillDownColumns.filter((column) => column.present);
        const extraHeader = renderedColumns.length > 0 ? ` ${renderedColumns.map((column) => column.label).join(" | ")} |` : "";
        const extraSeparator = renderedColumns.length > 0 ? ` ${renderedColumns.map(() => "---:").join(" | ")} |` : "";
        if (isIncompleteAttendanceFocus) {
            const incompleteRows = displayedChildren.flatMap((child) => {
                const records = Array.isArray(child.incomplete_attendance_records)
                    ? child.incomplete_attendance_records.map(recordValue).filter((record) => Boolean(record))
                    : [];
                return records.length > 0
                    ? records.map((record) => [tableValue(child.child_name), authorizationNames(child.authorization_names), tableValue(child.county), tableValue(record.date), tableValue(record.missing_record), tableValue(record.care_hours_at_risk)])
                    : [[tableValue(child.child_name), authorizationNames(child.authorization_names), tableValue(child.county), "Unavailable from the current source", "Unavailable from the current source", "Unavailable from the current source"]];
            });
            lines.push("", "Incomplete attendance detail:", "Missing record identifies whether the check-in, check-out, or both records were not returned.", "", ...renderAttendanceNumericTable(["Child", "Authorization", "County", "Date", "Missing record", "Care hours at risk"], incompleteRows, [5]));
        }
        else {
            lines.push("", isAbsenceLimitFocus
                ? "County limit = approved monthly limit. Over limit = days beyond the limit."
                : isParentConfirmationsFocus
                    ? "Pending = days still awaiting parent confirmation. Deadline/Days left = when the confirmation window closes for this child's earliest pending day."
                    : "Pending = awaiting confirmation. Absences used = past window, unconfirmed. Over limit = beyond county limit.", "", `| Child | Authorization | County |${extraHeader}`, `| --- | --- | --- |${extraSeparator}`, ...displayedChildren.map((child) => {
                const extraCells = renderedColumns.length > 0 ? ` ${renderedColumns.map((column) => column.value(child)).join(" | ")} |` : "";
                return `| ${tableValue(child.child_name)} | ${authorizationNames(child.authorization_names)} | ${tableValue(child.county)} |${extraCells}`;
            }));
        }
        if (isAbsenceLimitFocus) {
            // Real pagination: report the exact row range and page instead of a
            // "showing first N" preview, and let the caller ask for the next page
            // to see the rest of the complete affected-child list.
            const startRow = (requestedDetailPage - 1) * requestedDetailPageSize + 1;
            const endRow = Math.min(requestedDetailPage * requestedDetailPageSize, affectedChildren.length);
            if (affectedChildren.length > 0) {
                lines.push("", `Showing children ${startRow}-${endRow} of ${affectedChildren.length} (page ${requestedDetailPage}; page size ${requestedDetailPageSize}).`);
            }
        }
        else if (affectedChildren.length > displayedChildren.length) {
            lines.push("", `Showing the first ${displayedChildren.length} of ${affectedChildren.length} affected children. Ask for the remaining child details by name or group.`);
        }
    }
    // affectedChildren.length > 0 guard: when a riskFocus review finds zero
    // affected children, every numeric column below is 0 in the (single)
    // overview row - renderAttendanceNumericTable's zero-suppression logic
    // (it hides a numeric column that is 0 in every rendered row) then hides
    // ALL columns at once, producing a headerless, valueless "|  |" table.
    // The interpretation line above already states "found no child-level
    // attendance risks", so the overview table is skipped entirely here
    // rather than rendering that malformed table, matching the project's
    // standing rule of never showing a table/action for a zero-instance risk.
    if (attendanceOverview && !isChildScoped && showGenericAttendanceLayout && affectedChildren.length > 0) {
        // Each riskFocus gets its own exclusive overview shape - a focused
        // drill-down must never surface another risk area's column (Pending
        // confirmations for an absence review, Absence days for a pending-
        // confirmation review, etc.). The combined shape is used only for the
        // genuinely unscoped, all-risk-areas facility overview.
        if (isIncompleteAttendanceFocus) {
            lines.push("", "Attendance overview:", ...renderAttendanceNumericTable(["Scheduled days", "Affected children", "Incomplete days", "Excluded holidays"], [[tableValue(attendanceOverview.scheduled_days), tableValue(attendanceOverview.affected_children), tableValue(incompleteDays), tableValue(attendanceOverview.excluded_holiday_dates)]], [0, 1, 2, 3]));
        }
        else if (isAbsenceLimitFocus) {
            lines.push("", "Attendance overview:", ...renderAttendanceNumericTable(["Scheduled days", "Affected children", "Absence days", "Excluded holidays"], [[tableValue(attendanceOverview.scheduled_days), tableValue(attendanceOverview.affected_children), tableValue(attendanceOverview.absence_days), tableValue(attendanceOverview.excluded_holiday_dates)]], [0, 1, 2, 3]));
        }
        else {
            lines.push("", "Attendance overview:", ...renderAttendanceNumericTable(["Scheduled days", "Affected children", "Pending confirmations", "Absence days", "Excluded holidays"], [[tableValue(attendanceOverview.scheduled_days), tableValue(attendanceOverview.affected_children), tableValue(attendanceOverview.pending_confirmation_days), tableValue(attendanceOverview.absence_days), tableValue(attendanceOverview.excluded_holiday_dates)]], [0, 1, 2, 3, 4]));
        }
        if (numericValue(attendanceOverview.excluded_holiday_dates) > 0) {
            lines.push("Paid separately as a holiday; not counted as an absence.");
        }
    }
    // Item 5's "always on" only applies to an actual riskFocus-scoped response
    // (ABSENCE_LIMITS/INCOMPLETE_ATTENDANCE/PARENT_CONFIRMATIONS, regardless of
    // child scoping) - the isChildScopedMultiRisk case (a named child with NO
    // riskFocus) already renders its own up-to-3 dedicated tables above and
    // must not also show a facility-wide mixed county table alongside them.
    if (attendanceCounties.length > 0 && showGenericAttendanceLayout && !isChildScopedMultiRisk) {
        if (riskFocus === "ABSENCE_LIMITS") {
            // Spec: "top three or four counties with the highest absence counts" -
            // rank by children actually over limit first (real exclusion risk),
            // then by total absence days, and cap to 4 inside this riskFocus
            // drill-down. The standalone ATTENDANCE_COUNTY_ROLLUP view (a
            // "compare all counties" ask, riskFocus not set) is unaffected by this
            // cap and keeps showing every county.
            const topAbsenceCounties = [...attendanceCounties]
                .sort((left, right) => numericValue(right.children_over_limit_count) - numericValue(left.children_over_limit_count)
                || numericValue(right.absence_days) - numericValue(left.absence_days))
                .slice(0, 4);
            lines.push("", "> Status: \"N of M children over limit\" = already exceeded, real payment exclusion risk · \"N of M children approaching limit\" = within limit but close, no exclusion yet · \"Within limit\" = no children over or approaching for this county.", "**Attendance by county (top counties by absence risk):**", ...renderAttendanceNumericTable(["County", "Children", "Risk children", "Absence days", "Monthly absence limit", "Children over limit", "Status"], topAbsenceCounties.map((county) => {
                const childrenOverLimit = numericValue(county.children_over_limit_count);
                const childrenApproaching = numericValue(county.children_approaching_limit_count);
                const totalChildren = numericValue(county.children);
                // "Within limit" previously covered both "genuinely fine" and
                // "approaching but not yet over" counties alike, contradicting the
                // headline sentence above the table (which does distinguish
                // "over limit" from "approaching") - a provider scanning only this
                // column would read a county with many approaching children as
                // needing zero attention.
                // When approved_limit is null (conflicting values) or undefined
                // (never resolved), the Python engine has no limit to compare
                // against, so it can never assign ABSENCE_LIMIT_EXCEEDED/
                // APPROACHING for this county - both counts land at 0 not because
                // the county is verified compliant, but because compliance is
                // unverifiable. Falling through to "Within limit" there asserted a
                // compliance status that was never actually checked, contradicting
                // this same row's "Monthly absence limit: Unavailable from the
                // current source" cell.
                const limitUnresolved = county.approved_limit === null || county.approved_limit === undefined;
                const countyStatus = childrenOverLimit > 0
                    ? `${childrenOverLimit} of ${totalChildren} children over limit`
                    : childrenApproaching > 0
                        ? `${childrenApproaching} of ${totalChildren} children approaching limit`
                        : limitUnresolved
                            ? "Limit unavailable"
                            : "Within limit";
                // "Multiple" means every child in the county actually resolved to a
                // different limit (a real data conflict); undefined/null with no
                // conflict just means no verified limit was available - those are
                // different situations and should not both render as "Multiple".
                const approvedLimit = county.approved_limit === null
                    ? "Multiple"
                    : county.approved_limit !== undefined
                        ? tableValue(county.approved_limit)
                        : "Unavailable from the current source";
                return [tableValue(county.county), tableValue(county.children), tableValue(county.risk_children), tableValue(county.absence_days), approvedLimit, tableValue(childrenOverLimit), countyStatus];
            }), [1, 2, 3, 4, 5]));
        }
        else if (isIncompleteAttendanceFocus) {
            // Dedicated shape: Incomplete days replaces Pending confirmations and
            // Absence days, which don't describe a check-in/check-out gap. Ranked
            // and capped to top 4, same as the ABSENCE_LIMITS branch above.
            const topIncompleteCounties = [...attendanceCounties]
                .sort((left, right) => numericValue(right.incomplete_attendance_days) - numericValue(left.incomplete_attendance_days))
                .slice(0, 4);
            lines.push("", "Attendance by county (top counties by incomplete attendance):", ...renderAttendanceNumericTable(["County", "Children", "Risk children", "Incomplete days"], topIncompleteCounties.map((county) => [tableValue(county.county), tableValue(county.children), tableValue(county.risk_children), tableValue(county.incomplete_attendance_days)]), [1, 2, 3]));
        }
        else if (isParentConfirmationsFocus) {
            // Item 5 follow-through: now that this table always renders regardless
            // of isChildScoped, a PARENT_CONFIRMATIONS + named-child request must
            // still get its own exclusive shape (Pending confirmations only, no
            // Absence days) - matching the dedicated county-first block above,
            // which only covers the !isChildScoped case. Ranked and capped to top
            // 4, same convention as the other two focused branches.
            const topPendingCounties = [...attendanceCounties]
                .sort((left, right) => numericValue(right.pending_confirmation_days) - numericValue(left.pending_confirmation_days))
                .slice(0, 4);
            lines.push("", "Attendance by county (pending confirmations):", ...renderAttendanceNumericTable(["County", "Children", "Risk children", "Pending confirmations"], topPendingCounties.map((county) => [tableValue(county.county), tableValue(county.children), tableValue(county.risk_children), tableValue(county.pending_confirmation_days)]), [1, 2, 3]));
        }
        else {
            lines.push("", "Attendance by county:", ...renderAttendanceNumericTable(["County", "Children", "Risk children", "Pending confirmations", "Absence days"], attendanceCounties.map((county) => [tableValue(county.county), tableValue(county.children), tableValue(county.risk_children), tableValue(county.pending_confirmation_days), tableValue(county.absence_days)]), [1, 2, 3, 4]));
        }
    }
    if (attendanceViews.length > 0 && !riskFocus && !isChildScoped) {
        lines.push("", "Recommended attendance views:", ...attendanceViews.slice(0, 4).map((view) => `- ${tableValue(view.label)}: ${tableValue(view.reason)}`));
    }
    const currentView = viewState({
        viewId: "ATTENDANCE_RISK_SUMMARY",
        tableId: "attendance-risk",
        tableTitle: "Attendance risk summary",
        tableDescription: "This table highlights affected children and the attendance issues most likely to need review.",
        scope: analysis.scope,
        ...(typeof analysis.sourceRetrievedAt === "string" ? { sourceRetrievedAt: analysis.sourceRetrievedAt } : {}),
    });
    const baseActionIntents = actionMetadata(analysis.scope, risk, affectedChildren, false, typeof riskFocus === "string" ? riskFocus : undefined);
    // Real pagination for the ABSENCE_LIMITS child-level drill-down: computed
    // whenever that table actually rendered (isNarrowedToDetail, generic
    // layout, not the child-scoped-multi-risk branch) so the "next page"
    // action and detailPagination metadata only appear alongside the table
    // they describe.
    const absenceDetailPagination = isAbsenceLimitFocus && isNarrowedToDetail && showGenericAttendanceLayout && !isChildScopedMultiRisk
        ? {
            page: requestedDetailPage,
            pageSize: requestedDetailPageSize,
            totalRows: affectedChildren.length,
            hasMore: requestedDetailPage * requestedDetailPageSize < affectedChildren.length,
        }
        : undefined;
    // County-summary-first: when this response did NOT already narrow to a
    // named child, offer an explicit drill-down into the child-level table
    // (and, for INCOMPLETE_ATTENDANCE, the day-level detail table) that the
    // county-summary-only rendering above just suppressed.
    const withDrillDown = !isChildScoped && affectedChildren.length > 0
        ? [
            ...baseActionIntents,
            {
                actionId: "show-affected-children",
                capability: "attendance-risk-analysis",
                tool: "cccap_analyze_payment_risk",
                label: `Show affected children — ${affectedChildren.length}`,
                reason: "Opens the child-level rows behind this county summary.",
                priority: "medium",
                section: "drill-down",
                source: "current-result",
                input: Object.assign({}, recordValue(analysis.scope) ?? {}, typeof riskFocus === "string" ? { riskFocus } : {}, {
                    childNames: affectedChildren
                        .map((child) => child.child_name)
                        .filter((name) => typeof name === "string"),
                }),
                scope: analysis.scope,
            },
        ]
        : baseActionIntents;
    const withPagination = absenceDetailPagination?.hasMore
        ? [
            ...withDrillDown,
            {
                actionId: "next-attendance-detail-page",
                capability: "attendance-risk-analysis",
                tool: "cccap_analyze_payment_risk",
                label: "Open next page of affected children",
                reason: "Continue reviewing the remaining affected children in priority order.",
                priority: "medium",
                section: "drill-down",
                source: "current-result",
                // Only detailPage/detailPageSize are added on top of the exact
                // scope that produced this result, per ADDITIVE_REFINEMENT_KEYS -
                // this is a real next-page request, not a scope-widening one.
                input: Object.assign({}, recordValue(analysis.scope) ?? {}, {
                    detailPage: requestedDetailPage + 1,
                    detailPageSize: requestedDetailPageSize,
                }),
                scope: analysis.scope,
            },
        ]
        : withDrillDown;
    const actionIntents = withPagination.map((action) => actionViewMetadata(action, currentView));
    const providerMessage = renderActionSections(lines.join("\n"), actionIntents);
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "attendance-risk-analysis",
            viewState: currentView,
            scope: analysis.scope,
            sourceRetrievedAt: analysis.sourceRetrievedAt,
            resultStatus: noAttendanceRecords ? "NO_ATTENDANCE_SCHEDULES" : "COMPLETED",
            riskFocus,
            ...(includeContinuationMetadata ? { actionIntents } : {}),
            actionControls: compactActionControls(actionIntents),
            attendanceSummary: compactAttendanceSummary(attendanceView),
            ...(absenceDetailPagination ? { detailPagination: absenceDetailPagination } : {}),
            providerMessage,
        },
    };
}
export function authorizationNames(value) {
    if (!Array.isArray(value) || value.length === 0) {
        return "Unavailable from the current source";
    }
    return value.map(tableValue).join(", ");
}
function numericValue(value) {
    return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
// Numeric "Over limit" count, replacing the old prose "exceed the county
// limit" sentence repeated per row - matches the Drill-Down Template's
// 6-column numeric format so the shared explanation lives once above the
// table instead of in every row.
function overLimitDays(absenceDays, absenceLimit) {
    const days = numericValue(absenceDays);
    const limit = typeof absenceLimit === "number" ? absenceLimit : undefined;
    if (limit === undefined)
        return "—";
    return String(Math.max(0, days - limit));
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
    // Includes UNAVAILABLE/CONFLICT alongside EXCEEDED/APPROACHING - a child
    // whose absence-limit status could not be resolved (no verified limit, or
    // a genuine data conflict across authorizations) is still an absence-limit
    // concern needing review; excluding these two codes let such children
    // silently vanish from every absence-limit view and count.
    return Array.isArray(child.risk_codes) && child.risk_codes.some((code) => code === "ABSENCE_LIMIT_EXCEEDED"
        || code === "ABSENCE_LIMIT_APPROACHING"
        || code === "ABSENCE_LIMIT_UNAVAILABLE"
        || code === "ABSENCE_LIMIT_CONFLICT");
}
function criticalityScore(row) {
    // Prefer the real dollar estimate when available. Otherwise rank by the
    // documented day-count fallback; never synthesize a dollar amount.
    const riskAmount = numericValue(row.risk_amount_estimate);
    if (riskAmount > 0)
        return riskAmount;
    // A child who has actually crossed the county's monthly absence limit is
    // strictly more critical than one merely approaching it, regardless of
    // day-count ties - without this bonus, an "approaching" child with the
    // same day count as several "over limit" children could win the tie by
    // array position alone, opening the wrong child's detail as
    // "highest-impact."
    const riskCodes = Array.isArray(row.risk_codes) ? row.risk_codes : [];
    const exceededBonus = riskCodes.includes("ABSENCE_LIMIT_EXCEEDED") ? 1000 : 0;
    return exceededBonus + numericValue(row.absence_days) + numericValue(row.pending_confirmation_days);
}
export function actionMetadata(scope, risk, children, includePaymentAction = false, riskFocus) {
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
    // Item 3: both guards now read off the same passed-in `children` array
    // (already scoped to this call), not a mix of `children`-derived and raw
    // unfiltered `risk`-object counts - consistent basis across all three
    // risk actions, and a response with zero matching children never offers
    // the corresponding action.
    const pendingChildNames = childNamesFor("PARENT_CONFIRMATION_PENDING");
    const incompleteChildNames = childNamesFor("INCOMPLETE_ATTENDANCE_RECORD");
    // Cross-risk navigation suggestions (jumping to a DIFFERENT risk area's
    // review) only ever render in the fully unscoped, facility-wide response -
    // a response already focused on one risk area (riskFocus is set) must stay
    // exclusive to that risk area and offers only "return to summary" below,
    // never a link into another risk area's counts.
    // Item 1: pushed in the same order the summary table lists these risk rows
    // (Pending confirmations -> Absence limits -> Missing check-ins/check-outs)
    // so the rendered action numbering matches what the provider just read.
    if (pendingChildNames.length > 0 && !riskFocus) {
        actions.push({
            actionId: "review-pending-parent-confirmations",
            capability: "attendance-risk-analysis",
            label: `Review pending confirmations — ${numericValue(risk.pending_confirmation_days)} days`,
            reason: "Unconfirmed attendance may keep payment conditional.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            scope,
            tool: "cccap_analyze_payment_risk",
            // No childNames here - this is an unscoped, facility-wide "switch
            // focus" action, not a narrowing to an already-selected child list.
            // Under the stateless-token design (continuation-token.ts), the
            // action's input must be self-describing (embedded directly in the
            // token, since there is no server-side store to hold it) - baking in
            // a 15-23-name array here made every cross-risk action's token large
            // enough to plausibly overflow the chat client's relay size limit
            // ("unable to retrieve the provider status message"). riskFocus alone
            // is sufficient: the target response re-derives the currently
            // affected children itself, which is also more correct than replaying
            // a list that could go stale between turns.
            input: Object.assign({}, scopeInput, { riskFocus: "PARENT_CONFIRMATIONS" }),
        });
    }
    if (absenceChildren.length > 0 && !riskFocus) {
        actions.push({
            actionId: "review-absence-limit-risk",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_payment_risk",
            label: `Review absence-limit risk — ${absenceChildren.length} children`,
            reason: "Absence-limit exposure may reduce reimbursable payment.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            riskFocus: "ABSENCE_LIMITS",
            // See the matching comment above - no childNames on this unscoped
            // cross-risk action, for the same token-size reason.
            input: Object.assign({}, scopeInput, { riskFocus: "ABSENCE_LIMITS" }),
            scope,
        });
    }
    if (incompleteChildNames.length > 0 && !riskFocus) {
        actions.push({
            actionId: "review-incomplete-attendance",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_payment_risk",
            label: `Review incomplete attendance — ${incompleteChildNames.length} records`,
            reason: "A check-in or check-out is missing and may affect attendance verification.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            scope,
            riskFocus: "INCOMPLETE_ATTENDANCE",
            // See the matching comment above - no childNames on this unscoped
            // cross-risk action, for the same token-size reason.
            input: Object.assign({}, scopeInput, { riskFocus: "INCOMPLETE_ATTENDANCE" }),
        });
    }
    // Item 2: "return" is a dedicated section renderActionSections always
    // renders LAST and never caps - a riskFocus-scoped response never links
    // to a different risk area, so this is the only way back to the
    // unscoped, all-risk-areas summary, and it must never be dropped by the
    // next-actions cap or buried mid-list.
    if (riskFocus) {
        const returnToSummaryInput = { ...scopeInput };
        delete returnToSummaryInput.riskFocus;
        delete returnToSummaryInput.childNames;
        delete returnToSummaryInput.countyNames;
        delete returnToSummaryInput.detailPage;
        delete returnToSummaryInput.detailPageSize;
        actions.push({
            actionId: "return-to-attendance-summary",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_payment_risk",
            label: "Return to attendance risk summary",
            reason: "Go back to the full county-level attendance summary across all risk areas.",
            priority: "medium",
            section: "return",
            source: "current-result",
            input: returnToSummaryInput,
            scope,
        });
    }
    if (actions.length === 0 && !includePaymentAction) {
        actions.push({
            actionId: "review-attendance-records",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_payment_risk",
            label: "Review attendance records",
            reason: "Incomplete records can affect attendance verification and payment.",
            priority: "medium",
            section: "next-actions",
            source: "current-result",
            input: Object.assign({}, scopeInput),
            scope,
        });
    }
    if (children.length > 0 && !includePaymentAction && !Array.isArray(scopeInput.childNames)) {
        const highestImpactChild = [...children]
            .sort((left, right) => criticalityScore(right) - criticalityScore(left))[0];
        const highestImpactChildName = typeof highestImpactChild?.child_name === "string"
            ? highestImpactChild.child_name
            : undefined;
        // Item 4: this must always land on the child-scoped multi-risk view
        // (up to 3 separate exclusive tables: absence/pending/incomplete) for
        // that one child, regardless of which single riskFocus the CURRENT
        // response was already scoped to - riskFocus is explicitly cleared
        // rather than inherited from scopeInput so "highest-impact detail"
        // never stays narrowed to just one risk area.
        const highestImpactDetailInput = Object.assign({}, scopeInput, highestImpactChildName ? { childNames: [highestImpactChildName] } : {});
        delete highestImpactDetailInput.riskFocus;
        actions.push({
            actionId: "open-attendance-detail",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_payment_risk",
            label: "Open highest-impact attendance detail",
            reason: "Inspect every risk area (absence, pending confirmations, incomplete attendance) for this child, not just the current focus.",
            priority: "medium",
            section: "drill-down",
            source: "current-result",
            input: highestImpactDetailInput,
            scope,
        });
    }
    if (includePaymentAction) {
        actions.push({
            actionId: "review-next-payout",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "View upcoming payout summary",
            reason: "Confirm the upcoming service period and estimated payment status.",
            priority: "medium",
            section: "available-options",
            source: "current-result",
            view: "NEXT_PAYOUT",
            input: { view: "NEXT_PAYOUT" },
            scope,
        });
        actions.push({
            actionId: "forecast-current-period-services",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Estimate current week's service payout",
            reason: "Project this service period's actual and scheduled services into an estimated payout.",
            priority: "medium",
            section: "available-options",
            source: "current-result",
            view: "CURRENT_PERIOD_FORECAST",
            input: { view: "CURRENT_PERIOD_FORECAST" },
            scope,
        });
    }
    return actions;
}
export function attendanceSummary(risk, children, scope, unmatchedChildNames, excludedClosureDates, excludedHolidayDates) {
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
            incomplete_attendance_days: 0,
            risk_children: 0,
            children_over_limit_count: 0,
            children_approaching_limit_count: 0,
            approved_limit: undefined,
        };
        current.children = Number(current.children) + 1;
        current.pending_confirmation_days = Number(current.pending_confirmation_days) + numericValue(child.pending_confirmation_days);
        current.absence_days = Number(current.absence_days) + numericValue(child.absence_days);
        current.incomplete_attendance_days = Number(current.incomplete_attendance_days) + numericValue(child.incomplete_attendance_days);
        if (Array.isArray(child.risk_codes) && child.risk_codes.length > 0) {
            current.risk_children = Number(current.risk_children) + 1;
        }
        if (Array.isArray(child.risk_codes) && child.risk_codes.includes("ABSENCE_LIMIT_EXCEEDED")) {
            current.children_over_limit_count = Number(current.children_over_limit_count) + 1;
        }
        // Written alongside children_over_limit_count so the county Status
        // column's "approaching" tier (see the riskFocus===ABSENCE_LIMITS
        // rendering below) has real data instead of always reading 0 - this
        // counter was previously read but never actually populated.
        if (Array.isArray(child.risk_codes) && child.risk_codes.includes("ABSENCE_LIMIT_APPROACHING")) {
            current.children_approaching_limit_count = Number(current.children_approaching_limit_count) + 1;
        }
        // A county's monthly absence limit is resolved per child by matching the
        // provider's quality tier against the county policy (absenceDaysTierN),
        // so it is normally the same value for every child sharing that county
        // and tier; the first verified value seen is authoritative for the
        // county row. Do not overwrite it with a conflicting value from a
        // different child (leave it unresolved instead of silently picking one
        // side of a real data conflict).
        if (typeof child.absence_limit === "number") {
            if (current.approved_limit === undefined) {
                current.approved_limit = child.absence_limit;
            }
            else if (current.approved_limit !== child.absence_limit) {
                current.approved_limit = null;
            }
        }
        counties.set(key, current);
    }
    // The evaluator owns this per-county aggregation over the full (unfiltered)
    // child population, so its children_over_limit_count and approved_limit
    // (tier-resolved monthly absence limit) are authoritative - prefer them
    // over the locally recomputed values, which only reflect whatever subset
    // of children was passed in for this particular risk focus/filter.
    if (Array.isArray(risk.counties)) {
        for (const aggregateValue of risk.counties) {
            const aggregate = recordValue(aggregateValue);
            const county = aggregate?.county;
            if (typeof county !== "string")
                continue;
            const current = counties.get(county);
            if (current) {
                current.children_over_limit_count = numericValue(aggregate?.children_over_limit_count);
                if (typeof aggregate?.approved_limit === "number") {
                    current.approved_limit = aggregate.approved_limit;
                }
            }
        }
    }
    const scopeInput = recordValue(scope) ?? {};
    const availableViews = [
        {
            viewId: "ATTENDANCE_COUNTY_ROLLUP",
            label: "View attendance by county",
            reason: "Compare pending confirmations, absence usage, and affected children across counties.",
            section: "available-views",
            input: scopeInput,
        },
        {
            viewId: "ATTENDANCE_DATE_DETAIL",
            label: "View attendance by child",
            reason: "Open child-level dates, classifications, and risk explanations.",
            section: "drill-down",
            input: scopeInput,
        },
    ];
    // Built in the canonical Pending -> Absence -> Incomplete order via
    // unshift() onto the front of `availableViews` (which already starts
    // with the two fixed "available-views"/"drill-down" entries) - each
    // successive unshift() re-inverts the prior order, so building in this
    // sequence lands the FINAL array in the required order (each new
    // unshift places its entry ahead of the previous risk entry, and the
    // three are pushed in reverse-priority sequence: Incomplete first,
    // then Absence, then Pending last, so Pending ends up frontmost).
    if (children.some((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD"))) {
        availableViews.unshift({
            viewId: "ATTENDANCE_DATE_DETAIL",
            tableId: "attendance-date-detail",
            label: "Review incomplete attendance",
            reason: "Missing check-in or check-out records need verification.",
            section: "next-actions",
            input: Object.assign({ riskFocus: "INCOMPLETE_ATTENDANCE" }, scopeInput),
        });
    }
    if (children.some(hasAbsenceLimitConcern)) {
        availableViews.unshift({
            viewId: "ATTENDANCE_DATE_DETAIL",
            tableId: "attendance-date-detail",
            label: "Review absence limits",
            reason: "Absence usage may reduce reimbursable payment for affected children.",
            section: "next-actions",
            input: Object.assign({ riskFocus: "ABSENCE_LIMITS" }, scopeInput),
        });
    }
    if (numericValue(risk.pending_confirmation_days) > 0) {
        availableViews.unshift({
            viewId: "ATTENDANCE_DATE_DETAIL",
            tableId: "attendance-date-detail",
            label: "Review pending parent confirmations",
            reason: "These days may remain conditional until attendance is confirmed.",
            section: "next-actions",
            input: Object.assign({ riskFocus: "PARENT_CONFIRMATIONS" }, scopeInput),
        });
    }
    if (children.some((child) => typeof child.potential_impact === "string" && child.potential_impact.length > 0)) {
        availableViews.push({
            viewId: "NEXT_UPCOMING_PAYOUT",
            tableId: "payout-summary",
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
            // Scoped to the same (possibly riskFocus-filtered) `children` set as
            // affected_children below, not the unfiltered facility-wide `risk`
            // object - previously this row mixed a scoped affected_children count
            // with unscoped facility-wide scheduled/pending/absence totals, so a
            // 23-child absence-limit review could show the full facility's 70
            // pending-confirmation days as if they belonged to those 23 children.
            scheduled_days: children.reduce((total, child) => total + numericValue(child.scheduled_days), 0),
            affected_children: children.length,
            pending_confirmation_days: children.reduce((total, child) => total + numericValue(child.pending_confirmation_days), 0),
            absence_days: children.reduce((total, child) => total + numericValue(child.absence_days), 0),
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
            tool: "cccap_analyze_payment_risk",
            ...view,
        })),
    };
}
// --- Merged from snapshot-formatter.ts (2026-09-15 consolidation) ---
export function snapshotResult(data, includeContinuationMetadata = false) {
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
    const currentView = viewState({
        viewId: "ATTENDANCE_RISK_SUMMARY",
        tableId: "attendance-risk",
        tableTitle: "Attendance risk summary",
        tableDescription: "This table gives the provider the current attendance risks before any payment detail is opened.",
        scope: snapshot.scope,
        ...(typeof snapshot.sourceRetrievedAt === "string" ? { sourceRetrievedAt: snapshot.sourceRetrievedAt } : {}),
    });
    const actionIntents = risk
        ? actionMetadata(snapshot.scope, risk, children, true).map((action) => actionViewMetadata(action, currentView))
        : [];
    const attendanceView = risk
        ? attendanceSummary(risk, children, snapshot.scope, [], [], [])
        : undefined;
    const compactAttendanceView = compactAttendanceSummary(attendanceView);
    const overview = compactAttendanceView && recordValue(compactAttendanceView.overview);
    const snapshotSummary = overview
        ? [
            "",
            "Attendance overview:",
            `Scheduled days: ${tableValue(overview.scheduled_days)}; affected children: ${tableValue(overview.affected_children)}; pending confirmations: ${tableValue(overview.pending_confirmation_days)}; absence days: ${tableValue(overview.absence_days)}; incomplete children: ${tableValue(overview.incomplete_children)}.`,
        ].join("\n")
        : "";
    const renderedMessage = renderActionSections(`${providerMessage}${snapshotSummary}`, actionIntents);
    return {
        content: [{ type: "text", text: renderedMessage }],
        structuredContent: {
            capability: "attendance-risk-snapshot",
            viewState: currentView,
            scope: snapshot.scope,
            sourceRetrievedAt: snapshot.sourceRetrievedAt,
            responseMode: "SUMMARY",
            responseSections: ["summary", "next-actions", "drill-down", "available-views"],
            providerMessage: renderedMessage,
            ...(includeContinuationMetadata ? { actionIntents } : {}),
            actionControls: actionControls(actionIntents),
        },
    };
}
