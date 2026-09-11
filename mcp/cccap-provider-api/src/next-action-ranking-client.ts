import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const execFileAsync = promisify(execFile);
const rankingScriptPath = fileURLToPath(new URL(
  "../../../skills/agent-child-care-payment-advisor/scripts/next_action_ranking.py",
  import.meta.url,
));

const RANKING_TIMEOUT_MS = 15_000;
const RANKING_MAX_BUFFER_BYTES = 5_000_000;

export interface RankedNextAction {
  action_id: string;
  label: string;
  category: string;
  priority_score: number;
  tool: string;
  input: Record<string, unknown>;
}

/**
 * Invokes the deterministic Python next-action ranking module. Ranking is an
 * enhancement layered on top of an already fail-closed evaluator result, not
 * a required input to it: a ranking failure (timeout, missing runtime,
 * malformed output) must never block the underlying attendance/payment
 * response, so this fails OPEN to an empty ranked list rather than throwing.
 */
export async function rankNextActions(
  canonicalFacts: unknown,
  activeCapability: string,
): Promise<RankedNextAction[]> {
  const directory = await mkdtemp(join(tmpdir(), "carepay-ranking-"));
  const inputPath = join(directory, "ranking.json");
  try {
    await writeFile(
      inputPath,
      JSON.stringify({ canonical_facts: canonicalFacts, active_capability: activeCapability }),
      "utf8",
    );
    const { stdout } = await execFileAsync("uv", ["run", rankingScriptPath, inputPath], {
      windowsHide: true,
      timeout: RANKING_TIMEOUT_MS,
      maxBuffer: RANKING_MAX_BUFFER_BYTES,
      killSignal: "SIGKILL",
    });
    const evaluated = JSON.parse(stdout) as { status?: string; result?: { actions?: RankedNextAction[] } };
    if (evaluated.status !== "ok" || !evaluated.result) return [];
    return Array.isArray(evaluated.result.actions) ? evaluated.result.actions : [];
  } catch {
    return [];
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}