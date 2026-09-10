import { randomBytes } from "node:crypto";

export type ContinuationPlan = {
  tool: "cccap_analyze_payment_risk" | "cccap_analyze_payment";
  input: Record<string, unknown>;
  compatibilityKey?: string;
  provenance?: { capability: string; scope?: unknown };
};

export type ResolvedContinuation = ContinuationPlan & {
  result?: unknown;
  resultTool?: ContinuationPlan["tool"];
};

export type ContinuationAction = {
  actionId: string;
  metadata: Record<string, unknown>;
  plan: ContinuationPlan;
};

type ContextRecord = {
  providerKey: string;
  capability: string;
  ruleVersion?: string;
  result?: unknown;
  resultTool?: ContinuationPlan["tool"];
  expiresAt: number;
  actions: Map<string, ContinuationPlan>;
  bytes: number;
  lastUsed: number;
  compatibilityKey: string;
};

type SessionActionRecord = ContinuationAction & {
  contextRef: string;
  expiresAt: number;
  lastUsed: number;
};

export type ConversationContextOptions = {
  now?: () => number;
  ttlMs?: number;
  maxEntries?: number;
  maxBytes?: number;
};

export class ConversationContextStore {
  private readonly contexts = new Map<string, ContextRecord>();
  private readonly sessionActions = new Map<string, Map<string, SessionActionRecord>>();
  private readonly now: () => number;
  private readonly ttlMs: number;
  private readonly maxEntries: number;
  private readonly maxBytes: number;

  constructor(options: ConversationContextOptions = {}) {
    this.now = options.now ?? Date.now;
    this.ttlMs = options.ttlMs ?? 15 * 60 * 1000;
    this.maxEntries = options.maxEntries ?? 100;
    this.maxBytes = options.maxBytes ?? 1_000_000;
  }

  create(
    providerKey: string,
    capability: string,
    actions: ContinuationPlan[],
    result?: unknown,
    resultTool?: ContinuationPlan["tool"],
    ruleVersion?: string,
    actionMetadata: Record<string, unknown>[] = [],
  ): {
    contextRef: string;
    actionRefs: string[];
  } {
    this.evict();
    const contextRef = this.reference();
    const actionRefs = actions.map(() => this.reference());
    const actionMap = new Map(actionRefs.map((actionRef, index) => {
      const action = actions[index]!;
      return [actionRef, {
        ...action,
        compatibilityKey: compatibilityKeyFor(action.tool, ruleVersion, [action]),
      }];
    }));
    const compatibilityKey = compatibilityKeyFor(capability, ruleVersion, actions);
    const bytes = Buffer.byteLength(JSON.stringify({ providerKey, capability, ruleVersion, actions, result, compatibilityKey }), "utf8");
    const now = this.now();
    const providerActions = this.sessionActions.get(providerKey) ?? new Map<string, SessionActionRecord>();
    for (const [index, action] of actionMetadata.entries()) {
      const plan = actions[index];
      if (!plan || typeof action.actionId !== "string") continue;
      providerActions.set(action.actionId, {
        actionId: action.actionId,
        metadata: action,
        plan,
        contextRef,
        expiresAt: now + this.ttlMs,
        lastUsed: now,
      });
    }
    this.sessionActions.set(providerKey, providerActions);
    this.contexts.set(contextRef, {
      providerKey,
      capability,
      ...(resultTool ? { resultTool } : {}),
      ...(result !== undefined ? { result } : {}),
      ...(ruleVersion ? { ruleVersion } : {}),
      expiresAt: now + this.ttlMs,
      actions: actionMap,
      bytes,
      lastUsed: now,
      compatibilityKey,
    });
    this.evict();
    return { contextRef, actionRefs };
  }

  getInheritedActions(providerKey: string, currentActions: Record<string, unknown>[]): ContinuationAction[] {
    this.evict();
    const currentIds = new Set(currentActions.map((action) => action.actionId));
    const actions = this.sessionActions.get(providerKey);
    if (!actions) return [];
    return [...actions.values()]
      .filter((action) => !currentIds.has(action.actionId) && this.contextIsLive(action.contextRef))
      .map((action) => {
        action.lastUsed = this.now();
        return { ...action, plan: publicPlan(action.plan) };
      });
  }

  resolve(providerKey: string, contextRef: string | undefined, actionRef: string | undefined, capability: string, ruleVersion?: string, requestedInput?: Record<string, unknown>): ResolvedContinuation | undefined {
    if (!contextRef || !actionRef) return undefined;
    const context = this.contexts.get(contextRef);
    if (!context || context.providerKey !== providerKey || context.capability !== capability || context.expiresAt <= this.now() || (ruleVersion && context.ruleVersion && context.ruleVersion !== ruleVersion)) {
      this.contexts.delete(contextRef);
      return undefined;
    }
    const plan = context.actions.get(actionRef);
    if (!plan || (requestedInput && !isCompatibleInput(requestedInput, plan.input))) return undefined;
    if (plan.compatibilityKey && plan.compatibilityKey !== compatibilityKeyFor(plan.tool, ruleVersion, [plan])) return undefined;
    context.lastUsed = this.now();
    return {
      ...publicPlan(plan),
      ...(context.result !== undefined ? { result: context.result } : {}),
      ...(context.resultTool ? { resultTool: context.resultTool } : {}),
    };
  }

  resolveAction(providerKey: string, actionId: string | undefined, tool: ContinuationPlan["tool"], requestedInput?: Record<string, unknown>): ResolvedContinuation | undefined {
    if (!actionId) return undefined;
    this.evict();
    const action = this.sessionActions.get(providerKey)?.get(actionId);
    if (!action || action.plan.tool !== tool || action.expiresAt <= this.now()) return undefined;
    if (requestedInput && !isCompatibleInput(requestedInput, action.plan.input)) return undefined;
    action.lastUsed = this.now();
    return { ...publicPlan(action.plan) };
  }

  private evict(): void {
    const now = this.now();
    for (const [reference, context] of this.contexts) {
      if (context.expiresAt <= now) this.contexts.delete(reference);
    }
    for (const [providerKey, actions] of this.sessionActions) {
      for (const [actionId, action] of actions) {
        if (action.expiresAt <= now) actions.delete(actionId);
      }
      if (actions.size === 0) this.sessionActions.delete(providerKey);
    }
    while (this.contexts.size > this.maxEntries || this.totalBytes() > this.maxBytes) {
      const oldest = [...this.contexts.entries()].sort((left, right) => left[1].lastUsed - right[1].lastUsed)[0];
      if (!oldest) return;
      this.contexts.delete(oldest[0]);
      const actions = this.sessionActions.get(oldest[1].providerKey);
      if (actions) {
        for (const [actionId, action] of actions) {
          if (action.contextRef === oldest[0]) actions.delete(actionId);
        }
        if (actions.size === 0) this.sessionActions.delete(oldest[1].providerKey);
      }
    }
  }

  private totalBytes(): number {
    const contextBytes = [...this.contexts.values()].reduce((total, context) => total + context.bytes, 0);
    const actionBytes = [...this.sessionActions.values()].reduce(
      (total, actions) => total + [...actions.values()].reduce(
        (actionTotal, action) => actionTotal + Buffer.byteLength(JSON.stringify({
          actionId: action.actionId,
          metadata: action.metadata,
          contextRef: action.contextRef,
        }), "utf8"),
        0,
      ),
      0,
    );
    return contextBytes + actionBytes;
  }

  private contextIsLive(contextRef: string): boolean {
    const context = this.contexts.get(contextRef);
    if (!context || context.expiresAt <= this.now()) return false;
    return true;
  }

  private reference(): string {
    return randomBytes(24).toString("base64url");
  }
}

function normalizeInput(input: Record<string, unknown>): string {
  return stableJson(Object.fromEntries(Object.entries(input).filter(([key]) => key !== "contextRef" && key !== "actionRef" && key !== "refresh")));
}

// Pagination-only fields a caller may add on top of a stored action/continuation
// without that being treated as an incompatible/scope-widening request. Any key
// NOT in this set must already be present in the stored plan input with an
// identical value; only these keys may appear as new additions. This is what
// lets a provider narrow detailPage/detailPageSize on an existing action
// reference without the reference being rejected as expired/incompatible.
const ADDITIVE_REFINEMENT_KEYS = new Set(["detailPage", "detailPageSize"]);

// Compatible means: every key already present in the stored plan input keeps
// its exact value (no scope override), and any extra key the caller adds is
// limited to ADDITIVE_REFINEMENT_KEYS. This is deliberately looser than exact
// equality (which rejected a valid actionRef merely because the caller added
// detailPageSize) while still failing closed against a caller trying to widen
// scope by adding an unrelated field.
function isCompatibleInput(requestedInput: Record<string, unknown>, planInput: Record<string, unknown>): boolean {
  const requested = Object.fromEntries(
    Object.entries(requestedInput).filter(([key]) => key !== "contextRef" && key !== "actionRef" && key !== "refresh" && key !== "actionId"),
  );
  for (const [key, value] of Object.entries(requested)) {
    if (key in planInput) {
      if (stableJson(value) !== stableJson(planInput[key])) return false;
    } else if (!ADDITIVE_REFINEMENT_KEYS.has(key)) {
      return false;
    }
  }
  return true;
}

function compatibilityKeyFor(capability: string, ruleVersion: string | undefined, actions: ContinuationPlan[]): string {
  return stableJson({ capability, ruleVersion: ruleVersion ?? null, plans: actions.map((action) => ({ tool: action.tool, input: normalizeInput(action.input), provenance: action.provenance ?? null })) });
}

function stableJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.entries(value as Record<string, unknown>).sort(([left], [right]) => left.localeCompare(right)).map(([key, entry]) => `${JSON.stringify(key)}:${stableJson(entry)}`).join(",")}}`;
  return JSON.stringify(value) ?? "null";
}

function publicPlan(plan: ContinuationPlan): ContinuationPlan {
  const { compatibilityKey: _compatibilityKey, ...visiblePlan } = plan;
  return visiblePlan;
}