export interface ScopeDiff {
  scopeChanged: boolean;
  capabilityChanged: boolean;
  sinceLastTurn?: string;
}

interface DialogueRecord {
  lastCapability: string;
  lastScope: unknown;
  lastFreshnessAt: string;
  expiresAt: number;
}

export interface DialogueStateOptions {
  now?: () => number;
  ttlMs?: number;
  maxEntries?: number;
}

/**
 * Lightweight per-provider dialogue state, sibling to
 * ConversationContextStore. Where that store persists tool-result
 * continuation plans, this store persists only what capability/scope/
 * freshness the provider was looking at last turn, so composite tool
 * responses can hand back a concrete `scopeChanged`/`sinceLastTurn` signal
 * instead of asking the conversational model to infer turn classification
 * (continuation vs. new request vs. correction vs. refresh) from the raw
 * transcript alone. Bounded and TTL-evicted the same way as
 * ConversationContextStore; this is process-local state, not a database.
 */
export class DialogueStateStore {
  private readonly states = new Map<string, DialogueRecord>();
  private readonly now: () => number;
  private readonly ttlMs: number;
  private readonly maxEntries: number;

  constructor(options: DialogueStateOptions = {}) {
    this.now = options.now ?? Date.now;
    this.ttlMs = options.ttlMs ?? 15 * 60 * 1000;
    this.maxEntries = options.maxEntries ?? 100;
  }

  recordAndDiff(providerKey: string, capability: string, scope: unknown, freshnessAt: string): ScopeDiff {
    this.evict();
    const now = this.now();
    const previous = this.states.get(providerKey);
    const stillFresh = previous !== undefined && previous.expiresAt > now;
    const scopeChanged = !stillFresh || !this.scopeEquals(previous.lastScope, scope);
    const capabilityChanged = !stillFresh || previous.lastCapability !== capability;
    const diff: ScopeDiff = {
      scopeChanged,
      capabilityChanged,
      ...(stillFresh ? { sinceLastTurn: previous.lastFreshnessAt } : {}),
    };
    this.states.set(providerKey, {
      lastCapability: capability,
      lastScope: scope,
      lastFreshnessAt: freshnessAt,
      expiresAt: now + this.ttlMs,
    });
    return diff;
  }

  private scopeEquals(left: unknown, right: unknown): boolean {
    try {
      return JSON.stringify(left) === JSON.stringify(right);
    } catch {
      return false;
    }
  }

  private evict(): void {
    const now = this.now();
    for (const [providerKey, record] of this.states) {
      if (record.expiresAt <= now) this.states.delete(providerKey);
    }
    while (this.states.size > this.maxEntries) {
      const oldest = [...this.states.entries()].sort((left, right) => left[1].expiresAt - right[1].expiresAt)[0];
      if (!oldest) return;
      this.states.delete(oldest[0]);
    }
  }
}