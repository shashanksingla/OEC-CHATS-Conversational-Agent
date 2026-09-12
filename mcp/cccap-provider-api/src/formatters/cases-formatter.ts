import { recordValue, shortDateLabel, tableValue, type ToolResult } from './shared.js';

/**
 * Renders enrolled cases/children as safe provider-facing text. `id` on both
 * the case and each child is a raw Salesforce record ID and is never placed
 * in the rendered table; `name`/`external_id` (masked through `tableValue`
 * as a backstop) are the only identifiers shown.
 */
export function formatCasesResult(
  data: unknown,
  resolveCountyName: (countyId: string | undefined) => string | undefined = () => undefined,
): ToolResult {
  const response = recordValue(data);
  const cases = response && Array.isArray(response.cases)
    ? response.cases.map(recordValue).filter((item): item is Record<string, unknown> => Boolean(item))
    : [];
  if (cases.length === 0) {
    const providerMessage = "No verified cases were returned for the authorized provider scope.";
    return {
      content: [{ type: "text" as const, text: providerMessage }],
      structuredContent: { capability: "cases", resultStatus: "NO_CASES" },
    };
  }
  const displayName = (record: Record<string, unknown>): string => {
    const name = tableValue(record.name);
    return name !== "Unavailable from the current source" ? name : tableValue(record.external_id);
  };
  const countyLabel = (record: Record<string, unknown>): string =>
    tableValue(resolveCountyName(typeof record.county_id === "string" ? record.county_id : undefined));
  const lines = [
    "**Enrolled cases**",
    "",
    "| Case | County | Enrolled children | Effective dates |",
    "| --- | --- | --- | --- |",
    ...cases.map((caseRow) => {
      const children = Array.isArray(caseRow.children)
        ? caseRow.children.map(recordValue).filter((child): child is Record<string, unknown> => Boolean(child))
        : [];
      const childNames = children.length > 0
        ? children.map(displayName).join(", ")
        : "Unavailable from the current source";
      const dates = children
        .map((child) => [child.effective_start, child.effective_end]
          .filter((value): value is string => typeof value === "string")
          .map((value) => shortDateLabel(value) ?? tableValue(value))
          .join(" - "))
        .filter((value) => value.length > 0)
        .join("; ");
      return `| ${displayName(caseRow)} | ${countyLabel(caseRow)} | ${childNames} | ${dates || "Unavailable from the current source"} |`;
    }),
  ];
  const providerMessage = lines.join("\n");
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "cases",
      resultStatus: "COMPLETED",
      caseCount: cases.length,
    },
  };
}