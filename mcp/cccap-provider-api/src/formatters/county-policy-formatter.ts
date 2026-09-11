import { recordValue, tableValue, type ToolResult } from './shared.js';

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
