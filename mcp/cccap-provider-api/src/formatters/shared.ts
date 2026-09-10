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
  "Only your county portal or remittance advice is authoritative.*";

// Per-status disclaimers - attach directly next to the figure they qualify.
export const DISCLAIMER_EXPECTED =
  "*Expected, based on current system data — may still change if the county issues a correction.*";
export const DISCLAIMER_FORECASTED =
  "*Forecasted from scheduled and partial attendance data — will change as the period completes.*";
export const DISCLAIMER_AT_RISK =
  "*Could be reduced or excluded if unresolved before {deadline}.*";
export const DISCLAIMER_GUARANTEED =
  "*Paid per your county contract regardless of occupancy or attendance.*";

/** @deprecated Use DISCLAIMER_GLOBAL. */
export const PAYMENT_DISCLAIMER = DISCLAIMER_GLOBAL;

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
  const numeric = typeof value === "number"
    ? value
    : typeof value === "string" && value.trim() !== "" && Number.isFinite(Number(value))
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
// "~ $67.00 (56 Days)" or "~ $34.00 (30 Hours)" - the county composition
// column-consolidation format. Returns the plain amount when there is
// nothing to count (count is 0/undefined), so a genuinely empty category
// still reads as "~ $0.00" rather than a confusing "(0 Days)".
export function amountWithUnit(amount: unknown, count: unknown, unit: "Days" | "Hours"): string {
  const money = estimatedMoney(amount);
  const numericCount = typeof count === "number"
    ? count
    : typeof count === "string" && Number.isFinite(Number(count))
      ? Number(count)
      : undefined;
  if (money === "Unavailable from the current source" || !numericCount) return money;
  return `${money} (${numericCount} ${unit})`;
}

export function renderCountyComposition(rows: Record<string, unknown>[]): string[] {
  const component = (row: Record<string, unknown>, key: string): Record<string, unknown> =>
    recordValue(row[key]) ?? {};
  const headers = [
    "County",
    "Care Amount",
    "Absence Amount",
    "Drop-in Amount",
    "Vacant Slot Amount",
    "Paid Holiday Amount",
    "Potential total",
  ];
  const separator = headers.map((header) => header === "County" ? "---" : "---:");
  const renderedRows = rows.map((row) => {
    const care = component(row, "care");
    const absence = component(row, "absence");
    const dropIn = component(row, "drop_in");
    const vacantSlots = component(row, "vacant_slots");
    const paidHolidays = component(row, "paid_holidays");
    return [
      tableValue(row.county),
      amountWithUnit(care.amount, care.hours, "Hours"),
      amountWithUnit(absence.amount, absence.days, "Days"),
      amountWithUnit(dropIn.amount, dropIn.hours, "Hours"),
      amountWithUnit(vacantSlots.amount, vacantSlots.days, "Days"),
      amountWithUnit(paidHolidays.amount, paidHolidays.days, "Days"),
      estimatedMoney(row.potential_total),
    ].join(" | ");
  });
  return [
    "",
    "County payment composition (potential amounts)",
    "Potential amounts include confirmed and conditional amounts; the payable amount remains shown in the summary above.",
    `| ${headers.join(" | ")} |`,
    `| ${separator.join(" | ")} |`,
    ...renderedRows.map((row) => `| ${row} |`),
  ];
}

export function isSalesforceRecordId(value: string): boolean {
  return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
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

export function numericValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

export function shortDateLabel(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const parsed = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return undefined;
  return parsed.toLocaleDateString("en-US", { month: "short", day: "numeric", timeZone: "UTC" });
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
  return Array.isArray(child.risk_codes) && child.risk_codes.some((code) =>
    code === "ABSENCE_LIMIT_EXCEEDED" || code === "ABSENCE_LIMIT_APPROACHING",
  );
}
export function actionControls(actions: Record<string, unknown>[]): Record<string, unknown>[] {
  return actions.map((action) => ({
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
const MAX_NEXT_ACTIONS = 2;

export function renderActionSections(message: string, actions: Record<string, unknown>[]): string {
  const base = message.replace(/\n\*\*Next actions\*\*[\s\S]*$/, "");
  // Cap to the two highest-priority next actions so the response names the
  // one or two things that actually matter instead of listing every
  // candidate action; numbered (not bulleted) to match the drill-down
  // action-list convention and avoid the list reading as an open-ended pile.
  const nextActions = actions
    .filter((action) => action.section === "next-actions")
    .slice(0, MAX_NEXT_ACTIONS);
  const drillDown = actions.filter((action) => action.section === "drill-down");
  const availableViews = actions.filter((action) => action.section === "available-options" || action.section === "available-views");
  const lines = [base, "", "**Next actions**"];
  lines.push(...(nextActions.length > 0
    ? nextActions.map((action, index) => `${index + 1}. ${String(action.label)}`)
    : ["No urgent action identified from the current verified result."]));
  if (drillDown.length > 0) {
    lines.push("", "**Drill down**", ...drillDown.map((action) => `- ${String(action.label)}`));
  }
  if (availableViews.length > 0) {
    lines.push("", "**Available views**", ...availableViews.map((action) => `- ${String(action.label)}`));
  }
  lines.push(
    "",
    "**Next step**",
    "Ask about a specific child, authorization, county, date, or payment impact, or choose one of the reviews above.",
  );
  return lines.join("\n");
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