import { rankNextActions, type RankedNextAction } from "./next-action-ranking-client.js";

export const NEXT_ACTION_RANKING_RULE_VERSION = "provider-next-action-ranking-v1";

export interface SituationEnvelope {
  scope: unknown;
  freshnessAt: string;
  activeRiskCount: number;
  topPriorityActionId?: string;
  ruleVersion: string;
  rankedActions: RankedNextAction[];
}

/**
 * Builds the uniform `situation` block shared by attendance and payment
 * composite tool responses. This is the server-computed replacement for
 * asking the conversational model to infer "what matters most right now"
 * from prose: `topPriorityActionId` and `activeRiskCount` come from the
 * deterministic Python ranking module, not from model judgment.
 */
export async function buildSituationEnvelope(
  canonicalFacts: unknown,
  activeCapability: "attendance-risk-analysis" | "payment-analysis",
  scope: unknown,
  freshnessAt: string,
): Promise<SituationEnvelope> {
  const rankedActions = await rankNextActions(canonicalFacts, activeCapability);
  const topAction = rankedActions[0];
  return {
    scope,
    freshnessAt,
    activeRiskCount: rankedActions.length,
    ...(topAction ? { topPriorityActionId: topAction.action_id } : {}),
    ruleVersion: NEXT_ACTION_RANKING_RULE_VERSION,
    rankedActions,
  };
}