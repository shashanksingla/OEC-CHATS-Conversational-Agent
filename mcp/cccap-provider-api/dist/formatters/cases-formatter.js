import { recordValue, tableValue } from './shared.js';
/**
 * Renders enrolled cases/children as safe provider-facing text. `id` on both
 * the case and each child is a raw Salesforce record ID and is never placed
 * in the rendered table; `name`/`external_id` (masked through `tableValue`
 * as a backstop) are the only identifiers shown.
 */
export function formatCasesResult(data, resolveCountyName = () => undefined) {
    const response = recordValue(data);
    const cases = response && Array.isArray(response.cases)
        ? response.cases.map(recordValue).filter((item) => Boolean(item))
        : [];
    if (cases.length === 0) {
        const providerMessage = "No verified cases were returned for the authorized provider scope.";
        return {
            content: [{ type: "text", text: providerMessage }],
            structuredContent: { capability: "cases", resultStatus: "NO_CASES" },
        };
    }
    const displayName = (record) => {
        const name = tableValue(record.name);
        return name !== "Unavailable from the current source" ? name : tableValue(record.external_id);
    };
    const countyLabel = (record) => tableValue(resolveCountyName(typeof record.county_id === "string" ? record.county_id : undefined));
    const lines = [
        "**Enrolled cases**",
        "",
        "| Case | County | Enrolled children | Effective dates |",
        "| --- | --- | --- | --- |",
        ...cases.map((caseRow) => {
            const children = Array.isArray(caseRow.children)
                ? caseRow.children.map(recordValue).filter((child) => Boolean(child))
                : [];
            const childNames = children.length > 0
                ? children.map(displayName).join(", ")
                : "Unavailable from the current source";
            const dates = children
                .map((child) => [child.effective_start, child.effective_end].filter((value) => typeof value === "string").join(" - "))
                .filter((value) => value.length > 0)
                .join("; ");
            return `| ${displayName(caseRow)} | ${countyLabel(caseRow)} | ${childNames} | ${dates || "Unavailable from the current source"} |`;
        }),
    ];
    const providerMessage = lines.join("\n");
    return {
        content: [{ type: "text", text: providerMessage }],
        structuredContent: {
            capability: "cases",
            resultStatus: "COMPLETED",
            caseCount: cases.length,
        },
    };
}
