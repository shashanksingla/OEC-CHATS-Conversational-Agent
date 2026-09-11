import { DISCLAIMER_GLOBAL, estimatedMoney, renderActionSections, shortDateLabel, tableValue } from "./shared.js";
export function formatPeriodComparisonResult(data) {
    const value = data;
    if (!value || typeof value !== "object" || !value.periodOne || !value.periodTwo)
        return { content: [{ type: "text", text: JSON.stringify(data) }] };
    const delta = Number(value.netDeltaAmount) || 0;
    const notable = Array.isArray(value.flaggedDeltas) ? value.flaggedDeltas : [];
    const lead = notable.length > 0
        ? `You're expected to receive ${estimatedMoney(Math.abs(delta))} ${delta >= 0 ? "more" : "less"} this period than last, mainly due to ${tableValue(notable[0].label)}.`
        : "The two periods are within the normal range of variation.";
    const one = value.periodOne;
    const two = value.periodTwo;
    const oneLabel = `${shortDateLabel(one.serviceBeginDate) ?? tableValue(one.serviceBeginDate)}-${shortDateLabel(one.serviceEndDate) ?? tableValue(one.serviceEndDate)}`;
    const twoLabel = `${shortDateLabel(two.serviceBeginDate) ?? tableValue(two.serviceBeginDate)}-${shortDateLabel(two.serviceEndDate) ?? tableValue(two.serviceEndDate)}`;
    const lines = [lead, `Comparing: ${oneLabel} vs ${twoLabel}.`];
    if (notable.length > 0) {
        lines.push("", "**Notable changes**", ...notable.slice(0, 3).map((row) => `- ${tableValue(row.label)}: ${estimatedMoney(Math.abs(Number(row.deltaAmount)))} ${Number(row.deltaAmount) >= 0 ? "higher" : "lower"} (${row.deltaPct ?? "no baseline"}).`));
    }
    const renderTable = (title, rows) => {
        if (!rows.length)
            return;
        lines.push("", title, `| Category | ${oneLabel} Expected amount | ${twoLabel} Expected amount | Delta | Delta % |`, "| --- | ---: | ---: | ---: | ---: |", ...rows.map((raw) => { const row = raw; return `| ${tableValue(row.label)} | ${estimatedMoney(row.periodOneAmount)} | ${estimatedMoney(row.periodTwoAmount)} | ${estimatedMoney(row.deltaAmount)} | ${row.deltaPct === null ? "—" : `${row.deltaPct}%`} |`; }));
    };
    renderTable("Payment by category:", Array.isArray(value.byCategory) ? value.byCategory : []);
    renderTable("County detail:", Array.isArray(value.byCounty) ? value.byCounty : []);
    const message = renderActionSections(`${lines.join("\n")}\n\nExpected amount is the payable estimate; At-risk amount is not included where no baseline is available.\n\n${DISCLAIMER_GLOBAL}`, []);
    return { content: [{ type: "text", text: message }], structuredContent: { capability: "payment-comparison", periodOne: one, periodTwo: two, netDeltaAmount: value.netDeltaAmount, flaggedDeltas: notable, sourceRetrievedAt: value.sourceRetrievedAt } };
}
