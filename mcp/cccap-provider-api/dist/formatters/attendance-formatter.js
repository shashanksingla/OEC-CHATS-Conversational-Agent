import { compactActionControls, estimatedMoney, recordValue, renderActionSections, result, shortDateLabel, tableValue, MAX_DISPLAY_CHILDREN, MAX_SUMMARY_ROWS } from './shared.js';
import { actionViewMetadata, viewState } from '../view-state.js';
function compactAttendanceSummary(attendanceView) {
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
    // Hoisted to function scope (not just inside the child-table block below)
    // since the Attendance overview/county tables further down also need to
    // pick their column shape based on this same focus.
    const isIncompleteAttendanceFocus = riskFocus === "INCOMPLETE_ATTENDANCE";
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
    const attendanceScope = recordValue(analysis.scope);
    const attendancePeriodBeginLabel = shortDateLabel(attendanceScope?.dateFrom);
    const attendancePeriodEndLabel = shortDateLabel(attendanceScope?.dateTo);
    // shortDateLabel already embeds the 2-digit year (e.g. "31st Aug'26"), so no
    // separate year suffix is appended here - that would duplicate the year.
    const attendancePeriodHeaderLabel = attendancePeriodBeginLabel && attendancePeriodEndLabel
        ? `Attendance period: ${attendancePeriodBeginLabel}-${attendancePeriodEndLabel}`
        : undefined;
    const lines = [
        noAttendanceRecords
            ? `${scopeLabel} attendance review returned no attendance records for the requested period.`
            : affectedChildren.length > 0
                ? `${scopeLabel} attendance review found ${affectedChildren.length} child(ren) needing attention.`
                : `${scopeLabel} attendance review found no child-level attendance risks.`,
        ...(attendancePeriodHeaderLabel ? [attendancePeriodHeaderLabel] : []),
    ];
    if (unmatchedChildNames.length > 0) {
        lines.push(`No attendance records were found for ${unmatchedChildNames.length} requested child(ren) in the selected period.`);
    }
    if (unmatchedCountyNames.length > 0) {
        lines.push(`No affected children were found for the requested county/counties: ${unmatchedCountyNames.join(", ")}.`);
    }
    if (excludedClosureDates.length > 0) {
        lines.push(`Excluded ${excludedClosureDates.length} closure date(s): ${excludedClosureDates.map((date) => shortDateLabel(date) ?? tableValue(date)).join(", ")} (provider closed).`);
    }
    if (excludedHolidayDates.length > 0) {
        lines.push(`Excluded ${excludedHolidayDates.length} holiday date(s): ${excludedHolidayDates.map((date) => shortDateLabel(date) ?? tableValue(date)).join(", ")} (paid holiday, not an absence).`);
    }
    if (riskFocus !== "ABSENCE_LIMITS" && riskFocus !== "INCOMPLETE_ATTENDANCE" && pendingDays > 0) {
        const deadlineSuffix = typeof risk.earliest_confirmation_deadline === "string" && typeof risk.earliest_confirmation_days_remaining === "number"
            ? ` Earliest confirmation deadline: ${shortDateLabel(risk.earliest_confirmation_deadline) ?? tableValue(risk.earliest_confirmation_deadline)} (${risk.earliest_confirmation_days_remaining} day(s) left).`
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
    if (affectedChildren.length > 0) {
        const displayedChildren = [...affectedChildren]
            .sort((left, right) => criticalityScore(right) - criticalityScore(left))
            .slice(0, Math.min(MAX_DISPLAY_CHILDREN, MAX_SUMMARY_ROWS));
        // Column set depends on the risk focus: absence-limit risk is about
        // usage vs. the approved limit (not a "pending confirmation" concept),
        // so it gets its own simplified two-column shape instead of reusing the
        // generic Pending/Outside window/Over limit/Est. risk set.
        const isAbsenceLimitFocus = riskFocus === "ABSENCE_LIMITS";
        const isIncompleteAttendanceFocus = riskFocus === "INCOMPLETE_ATTENDANCE";
        const isParentConfirmationsFocus = riskFocus === "PARENT_CONFIRMATIONS";
        const drillDownColumns = isAbsenceLimitFocus
            ? [
                { label: "Absences used", value: (child) => tableValue(child.absence_days), present: displayedChildren.some((child) => numericValue(child.absence_days) !== 0) },
                { label: "County limit", value: (child) => tableValue(child.absence_limit), present: displayedChildren.some((child) => child.absence_limit !== undefined && child.absence_limit !== null) },
                // Added: previously computed but only ever shown in the generic
                // column set below, backwards from where a provider reviewing
                // absence-limit risk specifically would want it - front and center.
                { label: "Over limit", value: (child) => overLimitDays(child.absence_days, child.absence_limit), present: displayedChildren.some((child) => numericValue(child.absence_days) > numericValue(child.absence_limit)) },
            ]
            : isIncompleteAttendanceFocus
                ? [
                    // Dedicated shape for this focus: shows attendance/schedule
                    // information (scheduled vs. incomplete days), not
                    // absence/confirmation data - the generic Pending/Absences-used
                    // columns below describe a different concept entirely and were
                    // being shown here by mistake.
                    { label: "Scheduled days", value: (child) => tableValue(child.scheduled_days), present: displayedChildren.some((child) => numericValue(child.scheduled_days) !== 0) },
                    { label: "Incomplete days", value: (child) => tableValue(child.incomplete_attendance_days), present: displayedChildren.some((child) => numericValue(child.incomplete_attendance_days) !== 0) },
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
                        { label: "Deadline", value: (child) => typeof child.next_confirmation_deadline === "string" ? (shortDateLabel(child.next_confirmation_deadline) ?? tableValue(child.next_confirmation_deadline)) : "Unavailable from the current source", present: displayedChildren.some((child) => typeof child.next_confirmation_deadline === "string") },
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
        lines.push("", isAbsenceLimitFocus
            ? "Absences used = days counted against the monthly limit. County limit = approved monthly limit. Over limit = days beyond the limit."
            : isIncompleteAttendanceFocus
                ? "Scheduled days = total days scheduled this period. Incomplete days = days missing a check-in or check-out."
                : isParentConfirmationsFocus
                    ? "Pending = days still awaiting parent confirmation. Deadline/Days left = when the confirmation window closes for this child's earliest pending day."
                    : "Pending = awaiting confirmation. Absences used = past window, unconfirmed. Over limit = beyond county limit.", "", `| Child | Authorization | County |${extraHeader}`, `| --- | --- | --- |${extraSeparator}`, ...displayedChildren.map((child) => {
            const extraCells = renderedColumns.length > 0 ? ` ${renderedColumns.map((column) => column.value(child)).join(" | ")} |` : "";
            // A child's name alone does not uniquely identify them - the
            // authorization number is the disambiguator when duplicate child
            // names exist, so it is always shown alongside the child column.
            return `| ${tableValue(child.child_name)} | ${authorizationNames(child.authorization_names)} | ${tableValue(child.county)} |${extraCells}`;
        }));
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
        // Incomplete-attendance focus gets its own overview shape (Scheduled
        // days / Affected children / Incomplete days / Excluded holidays) -
        // Pending confirmations and Absence days describe a different concept
        // (parent confirmation, absence-limit usage) and don't belong in a
        // check-in/check-out-gap review.
        if (isIncompleteAttendanceFocus) {
            lines.push("", "Attendance overview:", "| Scheduled days | Affected children | Incomplete days | Excluded holidays |", "| ---: | ---: | ---: | ---: |", `| ${tableValue(attendanceOverview.scheduled_days)} | ${tableValue(attendanceOverview.affected_children)} | ${tableValue(incompleteDays)} | ${tableValue(attendanceOverview.excluded_holiday_dates)} |`);
        }
        else {
            lines.push("", "Attendance overview:", "| Scheduled days | Affected children | Pending confirmations | Absence days | Excluded holidays |", "| ---: | ---: | ---: | ---: | ---: |", `| ${tableValue(attendanceOverview.scheduled_days)} | ${tableValue(attendanceOverview.affected_children)} | ${tableValue(attendanceOverview.pending_confirmation_days)} | ${tableValue(attendanceOverview.absence_days)} | ${tableValue(attendanceOverview.excluded_holiday_dates)} |`);
        }
        if (numericValue(attendanceOverview.excluded_holiday_dates) > 0) {
            lines.push("Excluded holidays = county-recognized paid holidays that fall in this period; they are paid separately as a holiday and are not counted as scheduled care days or absences above.");
        }
    }
    if (attendanceCounties.length > 0) {
        if (riskFocus === "ABSENCE_LIMITS") {
            lines.push("", "> This groups attendance risks by county. It shows where affected children and attendance hours are concentrated; it is not a payment-total table.", "Attendance by county:", "| County | Children | Monthly absence limit | Children over limit | Status |", "| --- | ---: | ---: | ---: | --- |", ...attendanceCounties.map((county) => {
                const childrenOverLimit = numericValue(county.children_over_limit_count);
                const totalChildren = numericValue(county.children);
                const countyStatus = childrenOverLimit > 0
                    ? `${childrenOverLimit} of ${totalChildren} children over limit`
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
                return `| ${tableValue(county.county)} | ${tableValue(county.children)} | ${approvedLimit} | ${tableValue(childrenOverLimit)} | ${countyStatus} |`;
            }));
        }
        else if (isIncompleteAttendanceFocus) {
            // Dedicated shape: Incomplete days replaces Pending confirmations and
            // Absence days, which don't describe a check-in/check-out gap.
            lines.push("", "> This groups attendance risks by county. It shows where affected children and attendance hours are concentrated; it is not a payment-total table.", "Attendance by county:", "| County | Children | Risk children | Incomplete days |", "| --- | ---: | ---: | ---: |", ...attendanceCounties.map((county) => `| ${tableValue(county.county)} | ${tableValue(county.children)} | ${tableValue(county.risk_children)} | ${tableValue(county.incomplete_attendance_days)} |`));
        }
        else {
            lines.push("", "> This groups attendance risks by county. It shows where affected children and attendance hours are concentrated; it is not a payment-total table.", "Attendance by county:", "| County | Children | Risk children | Pending confirmations | Absence days |", "| --- | ---: | ---: | ---: | ---: |", ...attendanceCounties.map((county) => `| ${tableValue(county.county)} | ${tableValue(county.children)} | ${tableValue(county.risk_children)} | ${tableValue(county.pending_confirmation_days)} | ${tableValue(county.absence_days)} |`));
        }
    }
    if (attendanceViews.length > 0) {
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
    const actionIntents = actionMetadata(analysis.scope, risk, affectedChildren, false, typeof riskFocus === "string" ? riskFocus : undefined)
        .map((action) => actionViewMetadata(action, currentView));
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
            actionControls: compactActionControls(actionIntents),
            attendanceSummary: compactAttendanceSummary(attendanceView),
            providerMessage,
        },
    };
}
export function authorizationDates(value) {
    if (!Array.isArray(value) || value.length === 0) {
        return "Unavailable from the current source";
    }
    return value.map(tableValue).join(", ");
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
    return Array.isArray(child.risk_codes) && child.risk_codes.some((code) => code === "ABSENCE_LIMIT_EXCEEDED" || code === "ABSENCE_LIMIT_APPROACHING");
}
function criticalityScore(row) {
    // Prefer the real dollar estimate when available. Otherwise rank by the
    // documented day-count fallback; never synthesize a dollar amount.
    const riskAmount = numericValue(row.risk_amount_estimate);
    if (riskAmount > 0)
        return riskAmount;
    return numericValue(row.absence_days) + numericValue(row.pending_confirmation_days);
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
    if (absenceChildren.length > 0 && riskFocus !== "PARENT_CONFIRMATIONS") {
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
            label: `Review pending confirmations — ${numericValue(risk.pending_confirmation_days)} days`,
            reason: "Unconfirmed attendance may keep payment conditional.",
            priority: "high",
            section: "next-actions",
            source: "current-result",
            scope,
            tool: "cccap_analyze_payment_risk",
            input: Object.assign({ riskFocus: "PARENT_CONFIRMATIONS" }, scopeInput, { childNames: pendingChildNames }),
        });
    }
    if (incompleteChildNames.length > 0 && riskFocus !== "ABSENCE_LIMITS") {
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
            input: Object.assign({ riskFocus: "INCOMPLETE_ATTENDANCE" }, scopeInput, { childNames: incompleteChildNames }),
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
    if (children.length > 0 && !includePaymentAction) {
        const highestImpactChild = [...children]
            .sort((left, right) => criticalityScore(right) - criticalityScore(left))[0];
        const highestImpactChildName = typeof highestImpactChild?.child_name === "string"
            ? highestImpactChild.child_name
            : undefined;
        actions.push({
            actionId: "open-attendance-detail",
            capability: "attendance-risk-analysis",
            tool: "cccap_analyze_payment_risk",
            label: "Open highest-impact attendance detail",
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
            actionId: "forecast-current-week-services",
            capability: "payment-analysis",
            tool: "cccap_analyze_payment",
            label: "Forecast this week's services payout",
            reason: "Project this week's actual and scheduled services into an estimated payout.",
            priority: "medium",
            section: "available-options",
            source: "current-result",
            view: "CURRENT_WEEK_FORECAST",
            input: { view: "CURRENT_WEEK_FORECAST" },
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
    if (children.some((child) => Array.isArray(child.risk_codes) && child.risk_codes.includes("INCOMPLETE_ATTENDANCE_RECORD"))) {
        availableViews.unshift({
            viewId: "ATTENDANCE_DATE_DETAIL",
            tableId: "attendance-date-detail",
            label: "Review incomplete attendance",
            reason: "Missing check-in or check-out records need verification.",
            section: "next-actions",
            input: scopeInput,
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
