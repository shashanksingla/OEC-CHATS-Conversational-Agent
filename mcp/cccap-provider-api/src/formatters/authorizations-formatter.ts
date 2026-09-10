import { recordValue, tableValue, type ToolResult } from './shared.js';

/**
 * Renders authorizations as safe provider-facing text. `id`/`case_id` are
 * raw Salesforce record IDs and are never placed in the rendered table.
 */
export function formatAuthorizationsResult(
  data: unknown,
  resolveCountyName: (countyId: string | undefined) => string | undefined = () => undefined,
): ToolResult {
  const response = recordValue(data);
  const authorizations = response && Array.isArray(response.authorizations)
    ? response.authorizations.map(recordValue).filter((item): item is Record<string, unknown> => Boolean(item))
    : [];
  if (authorizations.length === 0) {
    const providerMessage = "No verified authorizations were returned for the authorized provider scope.";
    return {
      content: [{ type: "text" as const, text: providerMessage }],
      structuredContent: { capability: "authorizations", resultStatus: "NO_AUTHORIZATIONS" },
    };
  }
  const displayName = (record: Record<string, unknown>): string => {
    const name = tableValue(record.name);
    return name !== "Unavailable from the current source" ? name : tableValue(record.external_id);
  };
  const lines = [
    "**Authorizations**",
    "",
    "| Authorization | County | Status | Effective start | Effective end |",
    "| --- | --- | --- | --- | --- |",
    ...authorizations.map((authorization) =>
      `| ${displayName(authorization)} | ${tableValue(resolveCountyName(typeof authorization.county_id === "string" ? authorization.county_id : undefined))} | ${tableValue(authorization.status)} | ${tableValue(authorization.effective_start)} | ${tableValue(authorization.effective_end)} |`,
    ),
  ];
  const providerMessage = lines.join("\n");
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "authorizations",
      resultStatus: "COMPLETED",
      authorizationCount: authorizations.length,
    },
  };
}
