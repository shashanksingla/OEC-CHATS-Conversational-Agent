// Merged: situation-envelope.ts + next-action-ranking-client.ts.
// situation-envelope.ts's entire original content was a thin wrapper around rankNextActions;
// nothing else imported next-action-ranking-client.ts directly.
import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
// ===== begin next-action-ranking-client.ts =====
const execFileAsync = promisify(execFile);
const rankingScriptPath = fileURLToPath(new URL("../../../../skills/agent-child-care-payment-advisor/scripts/next_action_ranking.py", import.meta.url));
const RANKING_TIMEOUT_MS = 15_000;
const RANKING_MAX_BUFFER_BYTES = 5_000_000;
// Ranking is optional; failures return an empty list without blocking the evaluator result.
// Either or both fact blocks may be provided - when both are present, candidates from both
// capabilities are ranked together so the top action reflects the highest-priority item overall.
export async function rankNextActions(attendanceFacts, paymentFacts) {
    const directory = await mkdtemp(join(tmpdir(), "carepay-ranking-"));
    const inputPath = join(directory, "ranking.json");
    try {
        await writeFile(inputPath, JSON.stringify({ attendance_facts: attendanceFacts, payment_facts: paymentFacts }), "utf8");
        const { stdout } = await execFileAsync("uv", ["run", rankingScriptPath, inputPath], {
            windowsHide: true,
            timeout: RANKING_TIMEOUT_MS,
            maxBuffer: RANKING_MAX_BUFFER_BYTES,
            killSignal: "SIGKILL",
        });
        const evaluated = JSON.parse(stdout);
        if (evaluated.status !== "ok" || !evaluated.result)
            return [];
        return Array.isArray(evaluated.result.actions) ? evaluated.result.actions : [];
    }
    catch {
        return [];
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
// ===== end next-action-ranking-client.ts =====
// ===== begin situation-envelope.ts =====
export const NEXT_ACTION_RANKING_RULE_VERSION = "provider-next-action-ranking-v1";
// Build a deterministic situation block shared by attendance and payment responses.
// `siblingFacts` is the OTHER capability's last-known canonical facts (sourced from the
// per-provider result cache, not a new fetch) - when present, actions are ranked across
// BOTH capabilities together so the top action reflects the highest-priority item overall,
// not just whichever capability happened to be called this turn.
export async function buildSituationEnvelope(canonicalFacts, activeCapability, scope, freshnessAt, siblingFacts) {
    const attendanceFacts = activeCapability === "attendance-risk-analysis" ? canonicalFacts : siblingFacts;
    const paymentFacts = activeCapability === "payment-analysis" ? canonicalFacts : siblingFacts;
    const rankedActions = await rankNextActions(attendanceFacts, paymentFacts);
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
// ===== end situation-envelope.ts =====
