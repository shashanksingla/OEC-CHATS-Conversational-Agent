import { randomBytes } from "node:crypto";

export type ContinuationPlan = {
  tool: "cccap_analyze_attendance_risk" | "cccap_analyze_payment";
  input: Record<string, unknown>;
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
};

type SessionActionRecord = ContinuationAction & {
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
    const actionMap = new Map(actionRefs.map((actionRef, index) => [actionRef, actions[index]! ]));
    const bytes = Buffer.byteLength(JSON.stringify({ capability, ruleVersion, actions, result }), "utf8");
    const now = this.now();
    const providerActions = this.sessionActions.get(providerKey) ?? new Map<string, SessionActionRecord>();
    for (const [index, action] of actionMetadata.entries()) {
      const plan = actions[index];
      if (!plan || typeof action.actionId !== "string") continue;
      providerActions.set(action.actionId, {
        actionId: action.actionId,
        metadata: action,
        plan,
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
      .filter((action) => !currentIds.has(action.actionId))
      .map((action) => {
        action.lastUsed = this.now();
        return action;
      });
  }

  resolve(providerKey: string, contextRef: string | undefined, actionRef: string | undefined, capability: string, ruleVersion?: string): ResolvedContinuation | undefined {
    if (!contextRef || !actionRef) return undefined;
    const context = this.contexts.get(contextRef);
    if (!context || context.providerKey !== providerKey || context.capability !== capability || context.expiresAt <= this.now() || (ruleVersion && context.ruleVersion && context.ruleVersion !== ruleVersion)) {
      this.contexts.delete(contextRef);
      return undefined;
    }
    const plan = context.actions.get(actionRef);
    if (!plan) return undefined;
    context.lastUsed = this.now();
    return {
      ...plan,
      ...(context.result !== undefined ? { result: context.result } : {}),
      ...(context.resultTool ? { resultTool: context.resultTool } : {}),
    };
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
    }
  }

  private totalBytes(): number {
    return [...this.contexts.values()].reduce((total, context) => total + context.bytes, 0);
  }

  private reference(): string {
    return randomBytes(24).toString("base64url");
  }
}