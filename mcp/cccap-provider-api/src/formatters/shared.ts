export const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: true,
};

export type ToolResult = {
  content: [{ type: "text"; text: string }];
  structuredContent?: Record<string, unknown>;
  isError?: boolean;
};

export const MAX_DISPLAY_CHILDREN = 10;
export const MAX_SUMMARY_ROWS = 7;
// Global disclaimer - use once per full response, as a closing line
export const DISCLAIMER_GLOBAL =
  "⚠️ *Figures reflect the system's current data and are not an official payment notice. " +
  "Actual payments are subject to state and county verification, review, and may differ from these calculated estimates.*";

// Per-status disclaimers - attach directly next to the figure they qualify.
export const DISCLAIMER_EXPECTED =
  "*Expected, based on current system data — may still change if the county issues a correction.*";
export const DISCLAIMER_FORECASTED =
  "*Forecasted from scheduled and partial attendance data — may change as the period completes.*";
export const DISCLAIMER_AT_RISK =
  "*Could be reduced or excluded if unresolved before {deadline}.*";
export const DISCLAIMER_GUARANTEED =
  "*Paid per your county contract regardless of occupancy or attendance.*";

export function result(data: unknown): ToolResult {
  const structuredContent =
    data && typeof data === "object" && !Array.isArray(data)
      ? (data as Record<string, unknown>)
      : undefined;
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data) }],
    ...(structuredContent ? { structuredContent } : {}),
  };
}
export function compactActionControls(actions: Record<string, unknown>[]): Record<string, unknown>[] {
  return actionControls(actions).map((action) => {
    const input = recordValue(action.input);
    return {
      ...action,
      ...(input ? {
        input: Object.fromEntries(
          Object.entries(input).filter(([key]) => key !== "childNames"),
        ),
      } : {}),
    };
  });
}
export function recordValue(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

export function tableValue(value: unknown): string {
  if (typeof value === "string" && value.trim()) {
    const normalized = value.replace(/[\r\n|]/g, " ").trim();
    return isSalesforceRecordId(normalized)
      ? "Unavailable from the current source"
      : normalized;
  }
  if (typeof value === "number") {
    return String(value);
  }
  return "Unavailable from the current source";
}

// Plain-language 'Attendance type' values for the internal classification
// codes the payment evaluator returns, per the carepay-conversation-templates
// column-naming standard (a provider should never see a raw code like
// ABSENCE or ENROLLMENT_ABSENCE in a rendered table).
export const ATTENDANCE_TYPE_LABELS: Record<string, string> = {
  ATTENDED: "Attended",
  ABSENCE: "Absence (paid)",
  ENROLLMENT_ABSENCE: "Enrollment absence",
  HOLIDAY: "Holiday",
  DROP_IN: "Drop-in",
  SCHEDULED_FORECAST: "Scheduled (forecast)",
  CARE_NOT_OFFERED: "Care not offered",
  NO_CARE: "No care scheduled",
  BLOCKED: "Unavailable from the current source",
  PENDING_CONFIRMATION: "Pending parent confirmation",
  INCOMPLETE_ATTENDANCE_RECORD: "Missing check-in/check-out",
  VACANT_SLOT: "Vacant slot",
};

export function humanizeAttendanceType(value: unknown): string {
  if (typeof value !== "string") return "Unavailable from the current source";
  return ATTENDANCE_TYPE_LABELS[value] ?? tableValue(value);
}

// Appends the evaluator's best-effort risk_amount_estimate to a Potential
// impact cell as "At-risk amount" - the same term used in the payout
// summary's At-risk table - so the two surfaces read consistently. Omits
// the figure entirely when no estimate is available, per the no-fabricated-
// dollar-figure rule; never shows "$0" or "Unavailable" in its place.
export function withAtRiskAmount(potentialImpact: unknown, riskAmountEstimate: unknown): string {
  const base = tableValue(potentialImpact);
  const amount = typeof riskAmountEstimate === "number" ? riskAmountEstimate : undefined;
  if (amount === undefined || amount <= 0) return base;
  return base + " At-risk amount: " + estimatedMoney(amount) + ".";
}

function moneyDisplay(value: unknown): string {
  if (typeof value === "number" && !Number.isFinite(value)) return "Unavailable from the current source";
  if (typeof value === "string" && (value.trim() === "" || !Number.isFinite(Number(value)))) {
    return "Unavailable from the current source";
  }
  const numeric = typeof value === "number"
    ? value
    : typeof value === "string"
      ? Number(value)
      : undefined;
  return numeric === undefined ? tableValue(value) : numeric.toFixed(2);
}

/** Estimated headline amount, explicitly marked as an estimate. */
export function estimatedMoney(value: unknown): string {
  const display = moneyDisplay(value);
  return display === "Unavailable from the current source" ? display : `~ $${display}`;
}

/** Plain amount for line items and table cells; the surrounding table explains the context. */
export function plainMoney(value: unknown): string {
  const display = moneyDisplay(value);
  return display === "Unavailable from the current source" ? display : `$${display}`;
}

// Combines an amount with its underlying count into one cell, e.g.
// "$67.00 (56 Days)" or "$34.00 (30 Hours)" - the county composition
// column-consolidation format. Returns the plain amount when there is
// nothing to count (count is 0/undefined), so a genuinely empty category
// still reads as "$0.00" rather than a confusing "(0 Days)". Per-cell
// entries never carry the "~" estimate marker - that is reserved for the
// single facility-wide "Estimated total" headline figure.
export function amountWithUnit(amount: unknown, count: unknown, unit: "Days" | "Hours"): string {
  const money = plainMoney(amount);
  const numericCount = typeof count === "number"
    ? count
    : typeof count === "string" && Number.isFinite(Number(count))
      ? Number(count)
      : undefined;
  if (money === "Unavailable from the current source" || !numericCount) return money;
  return `${money} (${numericCount} ${unit})`;
}

export const PAYMENT_AMOUNT_LEGEND = "> Payment amounts: Net payment is the current estimate excluding unresolved risk. Conditional at-risk is the amount that may be added or lost when attendance issues are resolved. Maximum estimated payout = net payment + scheduled forecast + conditional at-risk. Vacant-slot payments are included once in net payment when applicable.";

export function renderCountyComposition(rows: Record<string, unknown>[], options: { settled?: boolean } = {}): string[] {
  const component = (row: Record<string, unknown>, key: string): Record<string, unknown> =>
    recordValue(row[key]) ?? (key === "attendance_based" || key === "authorized_based"
      ? { amount: row[`${key}_amount`] }
      : {});
  const countyRiskAmount = (row: Record<string, unknown>): unknown => {
    const direct = row.amount_at_risk ?? row.at_risk_amount ?? row.conditional_amount;
    if (direct !== undefined) return direct;
    const components = ["care", "absence", "drop_in", "vacant_slots", "paid_holidays"]
      .map((key) => component(row, key).conditional_amount)
      .filter((value) => value !== undefined && value !== null);
    return components.length > 0
      ? components.reduce((total: number, value) => total + (Number(value) || 0), 0)
      : undefined;
  };
  const headers = [
    "County",
    "Children served",
    "Attendance-based amount",
    "Paid absences",
    "Drop-in amount",
    "Paid Holiday Amount",
    "Vacant Slot Amount",
    "Conditional at-risk",
    options.settled ? "Total amount" : "Maximum estimated payout",
  ];
  const separator = headers.map((header) => header === "County" ? "---" : "---:");
  const sumComponent = (key: string): number => rows.reduce((total, row) => {
    const amount = Number(component(row, key).amount);
    return Number.isFinite(amount) ? total + amount : total;
  }, 0);
  const sumRisk = rows.reduce((total, row) => {
    const amount = Number(countyRiskAmount(row));
    return Number.isFinite(amount) ? total + amount : total;
  }, 0);
  const sumPotential = rows.reduce((total, row) => {
    const amount = Number(row.estimated_total ?? row.potential_total);
    return Number.isFinite(amount) ? total + amount : total;
  }, 0);
  const renderedRows = rows.map((row) => {
    const attendanceBased = component(row, "attendance_based");
    const absence = component(row, "absence");
    const dropIn = component(row, "drop_in");
    const paidHolidays = component(row, "paid_holidays");
    const vacantSlots = component(row, "vacant_slots");
    const values = [
      tableValue(row.county),
      tableValue(row.children_served),
      amountWithUnit(attendanceBased.amount, attendanceBased.days ?? attendanceBased.hours, attendanceBased.days !== undefined ? "Days" : "Hours"),
      amountWithUnit(absence.amount, absence.days, "Days"),
      amountWithUnit(dropIn.amount, dropIn.hours, "Hours"),
      amountWithUnit(paidHolidays.amount, paidHolidays.days ?? paidHolidays.hours, paidHolidays.days !== undefined ? "Days" : "Hours"),
      amountWithUnit(vacantSlots.amount, vacantSlots.days, "Days"),
      plainMoney(countyRiskAmount(row)),
      plainMoney(row.potential_total ?? row.estimated_total),
    ];
    return values
      .map((value) => value === "Unavailable from the current source" ? "N/A" : value)
      .join(" | ");
  });
  const totalValues = [
    "Total",
    "N/A",
    plainMoney(sumComponent("attendance_based")),
    plainMoney(sumComponent("absence")),
    plainMoney(sumComponent("drop_in")),
    plainMoney(sumComponent("paid_holidays")),
    plainMoney(sumComponent("vacant_slots")),
    plainMoney(options.settled ? 0 : sumRisk),
    plainMoney(sumPotential),
  ];
  // A settled/released (Paid) period has definite actual amounts, not
  // potential/conditional ones - the "potential amounts" disambiguation is
  // actively wrong there, not just unnecessary, so it's dropped rather than
  // shown alongside a settled figure.
  return [
    "",
    options.settled ? "**County payment composition**" : "**County payment composition (potential amounts)**",
    ...(options.settled ? [] : []),
    `| ${headers.join(" | ")} |`,
    `| ${separator.join(" | ")} |`,
    ...renderedRows.map((row) => `| ${row} |`),
    `| ${totalValues.join(" | ")} |`,
  ];
}

export function isSalesforceRecordId(value: string): boolean {
  return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
}

function authorizationNames(value: unknown): string {
  if (!Array.isArray(value) || value.length === 0) {
    return "Unavailable from the current source";
  }
  return value.map(tableValue).join(", ");
}

export function numericValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

// Ordinal suffix for a day-of-month number (1st, 2nd, 3rd, 4th... 11th-13th are
// always "th" regardless of the trailing digit).
function ordinalSuffix(day: number): string {
  if (day % 100 >= 11 && day % 100 <= 13) return "th";
  switch (day % 10) {
    case 1: return "st";
    case 2: return "nd";
    case 3: return "rd";
    default: return "th";
  }
}

// Provider-facing date format across the whole agent experience, e.g.
// "31st Aug'26" - day-of-month with ordinal suffix, short month, apostrophe
// plus 2-digit year. Replaces the older "Aug 31" short format everywhere a
// date is rendered so dates read consistently end to end.
export function shortDateLabel(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const datePart = value.trim().match(/^\d{4}-\d{2}-\d{2}/)?.[0];
  if (!datePart) return undefined;
  const parsed = new Date(`${datePart}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return undefined;
  const day = parsed.getUTCDate();
  const month = parsed.toLocaleDateString("en-US", { month: "short", timeZone: "UTC" });
  const year = String(parsed.getUTCFullYear()).slice(-2);
  return `${day}${ordinalSuffix(day)} ${month}'${year}`;
}

// Numeric "Over limit" count, replacing the old prose "exceed the county
// limit" sentence repeated per row - matches the Drill-Down Template's
// 6-column numeric format so the shared explanation lives once above the
// table instead of in every row.
export function overLimitDays(absenceDays: unknown, absenceLimit: unknown): string {
  const days = numericValue(absenceDays);
  const limit = typeof absenceLimit === "number" ? absenceLimit : undefined;
  if (limit === undefined) return "—";
  return String(Math.max(0, days - limit));
}

export function attendanceScopeLabel(scope: unknown): string {
  const dateFilter = recordValue(scope)?.dateFilter;
  if (dateFilter === "LAST_MONTH") return "Last-month";
  if (dateFilter === "THIS_MONTH") return "Current-month";
  if (dateFilter === "DATE_RANGE") return "Date-range";
  if (dateFilter === "TODAY") return "Today";
  return "Attendance-risk";
}

export function hasAbsenceLimitConcern(child: Record<string, unknown>): boolean {
  // Kept in sync with the identical local copy in attendance-formatter.ts -
  // includes UNAVAILABLE/CONFLICT alongside EXCEEDED/APPROACHING so a child
  // whose absence-limit status could not be resolved is still treated as an
  // absence-limit concern needing review, not silently dropped.
  return Array.isArray(child.risk_codes) && child.risk_codes.some((code) =>
    code === "ABSENCE_LIMIT_EXCEEDED"
    || code === "ABSENCE_LIMIT_APPROACHING"
    || code === "ABSENCE_LIMIT_UNAVAILABLE"
    || code === "ABSENCE_LIMIT_CONFLICT",
  );
}
const MAX_NEXT_ACTIONS = 2;

// Single source of truth for action ordering/capping - used identically by
// renderActionSections (the rendered "N." text) and actionControls (the
// structured array the calling agent resolves "position N" against). These
// two previously diverged: renderActionSections capped "next-actions" to
// MAX_NEXT_ACTIONS and reordered into [next-actions, drill-down,
// available-views, return], but actionControls mapped over the raw,
// uncapped, original-declaration-order actions - so whenever a response had
// more than MAX_NEXT_ACTIONS next-actions candidates, the rendered "3." and
// actionControls[2] pointed at two different actions. Routing both through
// this one function makes that divergence structurally impossible.
export function orderedActionList(actions: Record<string, unknown>[]): Record<string, unknown>[] {
  const uniqueActions = [...new Map(actions.map((action) => [String(action.actionId), action])).values()];
  // Cap to the two highest-priority next actions so the response names the
  // one or two things that actually matter instead of listing every
  // candidate action.
  const nextActions = uniqueActions
    .filter((action) => action.section === "next-actions")
    .slice(0, MAX_NEXT_ACTIONS);
  const drillDown = uniqueActions.filter((action) => action.section === "drill-down");
  const availableViews = uniqueActions.filter((action) => action.section === "available-options" || action.section === "available-views");
  // Dedicated "return" bucket: a navigation-back action (return to
  // attendance summary, return to payment summary) must never be dropped by
  // the next-actions cap and must always render LAST, after every other
  // action - it was previously either tagged "next-actions" (and could be
  // capped away by MAX_NEXT_ACTIONS before it rendered) or tagged
  // "navigation" (a section this function never read at all, so it silently
  // never appeared in the text list).
  const returnActions = uniqueActions.filter((action) => action.section === "return");
  // Combined into one simple numbered list - priority next-actions first,
  // then drill-downs, then available views, then return-navigation last -
  // replacing the previous four separate sections (Priority Actions / Drill
  // down / Available views / Next step). A single list is inherently
  // unambiguous to number: the earlier "numbers reserved for exactly one
  // section" rule existed only to prevent two competing numbered surfaces in
  // the same response, which cannot happen once every action lives in one
  // combined list.
  return [...nextActions, ...drillDown, ...availableViews, ...returnActions];
}

// Any action dropped here by orderedActionList's cap is now also absent
// from actionControls, matching renderActionSections's text exactly - an
// action never shown to the provider as a numbered option is no longer
// separately resolvable/selectable either.
export function actionControls(actions: Record<string, unknown>[]): Record<string, unknown>[] {
  return orderedActionList(actions).map((action) => ({
    type: "button",
    actionId: action.actionId,
    label: action.label,
    ...(action.reason ? { reason: action.reason } : {}),
    ...(action.priority ? { priority: action.priority } : {}),
    ...(action.source ? { source: action.source } : {}),
    section: action.section,
    capability: action.capability,
    ...(action.tool ? { tool: action.tool } : {}),
    ...(action.input ? { input: action.input } : {}),
    ...(action.scope ? { scope: action.scope } : {}),
    ...(action.riskFocus ? { riskFocus: action.riskFocus } : {}),
    ...(action.view ? { view: action.view } : {}),
  }));
}

export function renderActionSections(message: string, actions: Record<string, unknown>[]): string {
  const base = message
    .replace(/\n\*\*Priority Actions\*\*[\s\S]*$/, "")
    .replace(/\n\*\*Recommended actions\*\*[\s\S]*$/, "");
  const combined = orderedActionList(actions);
  const lines = [base, "", "**Recommended actions**"];
  lines.push(...(combined.length > 0
    ? combined.map((action, index) => `${index + 1}. ${String(action.label)}`)
    : ["No urgent action identified from the current verified result. Ask about the specific child, county, date, or payment detail you want reviewed next."]));
  return lines.join("\n");
}

// Human-facing label for a riskFocus enum value, for the scope-clarification
// prompt below - kept intentionally small and local rather than importing
// from attendance-formatter.ts, to avoid a circular import between the two
// formatter files.
function riskFocusLabel(riskFocus: string): string {
  if (riskFocus === "ABSENCE_LIMITS") return "absence-limit risk";
  if (riskFocus === "PARENT_CONFIRMATIONS") return "pending parent confirmations";
  if (riskFocus === "INCOMPLETE_ATTENDANCE") return "incomplete attendance records";
  return "this risk area";
}

/**
 * Renders a short clarifying question instead of running an analysis, for
 * the case where a freeform riskFocus request's inherited scope granularity
 * doesn't match the scope the provider's risk figures actually came from
 * (see scopeGranularity in conversation-context.ts) - e.g. the original
 * month-wide snapshot introduced these numbers, but the conversation has
 * since narrowed to one service period via a payout drill-down. Offers
 * exactly the two live options rather than silently picking one.
 */
export function formatScopeClarification(
  riskFocus: string,
  periodScope: { dateFrom: string; dateTo: string },
): ToolResult {
  const focusLabel = riskFocusLabel(riskFocus);
  const periodLabel = `${shortDateLabel(periodScope.dateFrom) ?? periodScope.dateFrom}-${shortDateLabel(periodScope.dateTo) ?? periodScope.dateTo}`;
  const message = [
    `**Which scope do you want for ${focusLabel}?**`,
    "The conversation has since narrowed to a specific service period, but the risk figures you were originally shown came from the current month - these can be different numbers.",
  ].join("\n");
  const actions: Record<string, unknown>[] = [
    {
      actionId: "clarify-scope-month",
      capability: "attendance-risk-analysis",
      tool: "cccap_analyze_payment_risk",
      label: "Use the current month (matches the original snapshot)",
      reason: "Recompute this review against the same month-wide scope the earlier figures came from.",
      priority: "high",
      section: "next-actions",
      source: "current-result",
      input: { dateFilter: "THIS_MONTH", riskFocus },
    },
    {
      actionId: "clarify-scope-period",
      capability: "attendance-risk-analysis",
      tool: "cccap_analyze_payment_risk",
      label: `Use just the current period (${periodLabel})`,
      reason: "Keep the review scoped to the service period currently under discussion.",
      priority: "high",
      section: "next-actions",
      source: "current-result",
      input: { dateFilter: "DATE_RANGE", dateFrom: periodScope.dateFrom, dateTo: periodScope.dateTo, riskFocus },
    },
  ];
  return {
    content: [{ type: "text" as const, text: renderActionSections(message, actions) }],
    structuredContent: {
      capability: "attendance-risk-analysis",
      scopeClarification: true,
      actionIntents: actions,
    },
  };
}

export function countyPaymentSummary(rows: Record<string, unknown>[]): Record<string, unknown>[] {
  const byCounty = new Map<string, Record<string, unknown>>();
  for (const row of rows) {
    const county = typeof row.county_name === "string" && row.county_name.length > 0
      ? row.county_name
      : "Unavailable from the current source";
    const current = byCounty.get(county) ?? {
      county_name: county,
      children_served: 0,
      hours: 0,
      amount: 0,
      conditional_amount: 0,
    };
    current.children_served = Number(current.children_served) + Number(row.children_served ?? 0);
    current.hours = Number(current.hours) + Number(row.hours ?? 0);
    current.amount = Number(current.amount) + Number(row.amount ?? 0);
    current.conditional_amount = Number(current.conditional_amount) + Number(row.conditional_amount ?? 0);
    byCounty.set(county, current);
  }
  return [...byCounty.values()];
}
export function careUnitLabel(value: unknown): string {
  switch (value) {
    case "PART_TIME": return "Part-time care";
    case "FULL_TIME": return "Full-time care";
    case "FULL_TIME_PLUS_PART_TIME": return "Full-time + part-time care";
    case "FULL_TIME_PLUS_FULL_TIME": return "Full-time + full-time care";
    case "NO_PAYMENT": return "No payable care unit";
    default: return tableValue(value);
  }
}