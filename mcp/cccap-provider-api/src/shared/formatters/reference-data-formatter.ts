// Merged: cases-formatter.ts + authorizations-formatter.ts + county-policy-formatter.ts.
// Small table renderers for the generic reference-data tools (cccap_get_cases,
// cccap_get_authorizations, cccap_get_county_rate_plans) - none owned by attendance or
// payment domain math.
import { recordValue, shortDateLabel, tableValue, type ToolResult } from './shared.js';

// ===== begin cases-formatter.ts =====
/** Renders enrolled cases without exposing raw Salesforce record IDs. */
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
// ===== end cases-formatter.ts =====

// ===== begin authorizations-formatter.ts =====
/** Renders authorizations without exposing raw Salesforce record IDs. */
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
// ===== end authorizations-formatter.ts =====

// ===== begin county-policy-formatter.ts =====
export function formatCountyPolicyResult(data: unknown): ToolResult {
  const response = recordValue(data);
  const plans = response && Array.isArray(response.county_plans)
    ? response.county_plans.map(recordValue).filter(
      (plan): plan is Record<string, unknown> => Boolean(plan),
    )
    : [];
  if (plans.length === 0) {
    return {
      content: [{
        type: "text" as const,
        text: "No verified county rate-plan limits were returned for the authorized provider scope.",
      }],
      structuredContent: {
        capability: "county-policy",
        resultStatus: "NO_POLICY_DATA",
      },
    };
  }
  const policyResponse = response as Record<string, unknown>;
  const tierColumns = [1, 2, 3, 4, 5].map((tier) => `Tier ${tier}`);
  const lines = [
    "**County absence limits**",
    "",
    `| County | Effective from | ${tierColumns.join(" | ")} |`,
    `| --- | --- | ${tierColumns.map(() => "---:").join(" | ")} |`,
    ...plans.map((plan) =>
      `| ${tableValue(plan.county_name)} | ${tableValue(plan.effective_start)} | ${[1, 2, 3, 4, 5]
        .map((tier) => tableValue(recordValue(plan.absence_days_by_tier)?.[String(tier)]))
        .join(" | ")} |`,
    ),
    "",
    "These are the verified absence-day limits returned for the authorized provider counties. The applicable tier depends on the provider or authorization policy tier.",
  ];
  const providerMessage = lines.join("\n");
  return {
    content: [{ type: "text" as const, text: providerMessage }],
    structuredContent: {
      capability: "county-policy",
      resultStatus: "COMPLETED",
      policyCount: plans.length,
      scope: policyResponse.scope,
      sourceRetrievedAt: policyResponse.sourceRetrievedAt,
    },
  };
}
// ===== end county-policy-formatter.ts =====