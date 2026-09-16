import { randomBytes } from "node:crypto";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
const DEFAULT_PERSIST_PATH = join(tmpdir(), "cccap-continuation-store.json");
// Classifies a date scope by breadth, so a freeform follow-up request can be
// checked against the scope the provider's risk figures actually came from,
// instead of silently inheriting whatever narrower scope the conversation
// has since drifted to (e.g. a month-wide risk snapshot followed by a 7-day
// payout drill-down, then a freeform "review absence risk" ask that never
// restates a date range). MONTH covers the standing risk-snapshot filters;
// PERIOD covers an explicit bounded range (a service period or custom
// range); anything else (TODAY, an unset scope) is OTHER and never
// participates in the mismatch check - only a genuine MONTH-vs-PERIOD
// disagreement is "materially ambiguous" enough to ask about.
export function scopeGranularity(scope) {
    if (!scope)
        return "OTHER";
    if (scope.dateFilter === "THIS_MONTH" || scope.dateFilter === "LAST_MONTH" || scope.dateFilter === "LAST_N_MONTHS")
        return "MONTH";
    if (scope.dateFilter === "DATE_RANGE" && typeof scope.dateFrom === "string" && typeof scope.dateTo === "string")
        return "PERIOD";
    return "OTHER";
}
export class ConversationContextStore {
    actions = new Map();
    cache = new Map();
    // Best-effort, in-memory only, per-provider record of the scope the most
    // recent MONTH-wide risk snapshot ran against - used solely for the
    // scope-clarification check above. Never a correctness dependency: losing
    // it (restart, eviction) just means one fewer opportunity to ask the
    // clarifying question, never a wrong or missing analysis result.
    lastSnapshotScope = new Map();
    now;
    ttlMs;
    maxEntries;
    maxBytes;
    persistPath;
    constructor(options = {}) {
        this.now = options.now ?? Date.now;
        this.ttlMs = options.ttlMs ?? 15 * 60 * 1000;
        this.maxEntries = options.maxEntries ?? 100;
        this.maxBytes = options.maxBytes ?? 10_000_000;
        this.persistPath = options.persistPath ?? process.env.CCCAP_CONTINUATION_STORE_PATH ?? DEFAULT_PERSIST_PATH;
        this.loadFromDisk();
    }
    /**
     * Issues a short, opaque action reference and persists it. This is the
     * only thing the client ever sees or has to reproduce - never the actual
     * scope/filters.
     */
    createActionToken(providerKey, tool, input, ruleVersion) {
        this.evictActions();
        const token = randomBytes(16).toString("base64url");
        const now = this.now();
        this.actions.set(token, { providerKey, tool, input, ...(ruleVersion ? { ruleVersion } : {}), expiresAt: now + this.ttlMs, lastUsed: now });
        this.saveToDisk();
        return token;
    }
    /**
     * Resolves a short action reference back to its stored scope/filters.
     * Binds to the requesting provider and the expected tool, and extends
     * the entry's TTL on a hit (sliding window, same as the original store).
     */
    resolveActionToken(token, providerKey, tool) {
        if (!token)
            return undefined;
        this.evictActions();
        const action = this.actions.get(token);
        if (!action || action.providerKey !== providerKey || action.tool !== tool || action.expiresAt <= this.now())
            return undefined;
        const resolvedAt = this.now();
        action.lastUsed = resolvedAt;
        action.expiresAt = resolvedAt + this.ttlMs;
        this.saveToDisk();
        return { input: action.input, ...(action.ruleVersion ? { ruleVersion: action.ruleVersion } : {}) };
    }
    /**
     * Caches a full raw result for best-effort reuse by a later "return to
     * the unscoped view" request - keyed on the stable date-scope portion of
     * a request via `cacheKeyFor`, not on any reference. In-memory only:
     * losing it (restart, eviction) never errors, it just means the next
     * request re-runs the full deterministic, read-only evaluation.
     */
    cacheResult(key, providerKey, capability, result, resultTool, ruleVersion, graph) {
        this.evictCache();
        const bytes = Buffer.byteLength(JSON.stringify({ providerKey, capability, result, ruleVersion }), "utf8");
        if (bytes > this.maxBytes)
            return;
        const now = this.now();
        this.cache.set(key, {
            providerKey,
            capability,
            result,
            resultTool,
            ...(ruleVersion ? { ruleVersion } : {}),
            ...(graph ? { graph } : {}),
            expiresAt: now + this.ttlMs,
            lastUsed: now,
            bytes,
        });
        this.evictCache();
    }
    getCachedResult(key, providerKey) {
        this.evictCache();
        const record = this.cache.get(key);
        if (!record || record.providerKey !== providerKey || record.expiresAt <= this.now())
            return undefined;
        const resolvedAt = this.now();
        record.lastUsed = resolvedAt;
        record.expiresAt = resolvedAt + this.ttlMs;
        return {
            result: record.result,
            resultTool: record.resultTool,
            ...(record.ruleVersion ? { ruleVersion: record.ruleVersion } : {}),
            ...(record.graph ? { graph: record.graph } : {}),
        };
    }
    /** Records the scope a MONTH-granularity risk snapshot just ran against, for the scope-clarification check in server.ts. Best-effort/in-memory only - see the field comment above. */
    setLastSnapshotScope(providerKey, scope) {
        this.lastSnapshotScope.set(providerKey, scope);
    }
    /** Returns the last MONTH-granularity snapshot scope recorded for this provider, or undefined if none ran yet this process lifetime. */
    getLastSnapshotScope(providerKey) {
        return this.lastSnapshotScope.get(providerKey);
    }
    loadFromDisk() {
        try {
            const raw = readFileSync(this.persistPath, "utf8");
            const parsed = JSON.parse(raw);
            if (parsed.actions) {
                const now = this.now();
                for (const [token, action] of Object.entries(parsed.actions)) {
                    if (action && typeof action === "object" && action.expiresAt > now)
                        this.actions.set(token, action);
                }
            }
        }
        catch {
            // No existing store yet, or it's unreadable/corrupt - start fresh.
            // Persistence is a durability optimization, not a correctness
            // requirement: a fresh, empty store is always a valid starting state.
        }
    }
    saveToDisk() {
        try {
            mkdirSync(dirname(this.persistPath), { recursive: true });
            writeFileSync(this.persistPath, JSON.stringify({ actions: Object.fromEntries(this.actions) }), "utf8");
        }
        catch {
            // Fail soft - action resolution still works for the rest of this
            // process's lifetime via the in-memory Map even if disk persistence
            // fails (read-only filesystem, permissions, out of disk space, etc.).
        }
    }
    evictActions() {
        const now = this.now();
        for (const [token, action] of this.actions) {
            if (action.expiresAt <= now)
                this.actions.delete(token);
        }
        while (this.actions.size > this.maxEntries) {
            const oldest = [...this.actions.entries()].sort((left, right) => left[1].lastUsed - right[1].lastUsed)[0];
            if (!oldest)
                return;
            this.actions.delete(oldest[0]);
        }
    }
    evictCache() {
        const now = this.now();
        for (const [key, record] of this.cache) {
            if (record.expiresAt <= now)
                this.cache.delete(key);
        }
        while (this.cache.size > this.maxEntries || this.totalCacheBytes() > this.maxBytes) {
            const oldest = [...this.cache.entries()].sort((left, right) => left[1].lastUsed - right[1].lastUsed)[0];
            if (!oldest)
                return;
            this.cache.delete(oldest[0]);
        }
    }
    totalCacheBytes() {
        return [...this.cache.values()].reduce((total, record) => total + record.bytes, 0);
    }
}
export function stableJson(value) {
    if (Array.isArray(value))
        return `[${value.map(stableJson).join(",")}]`;
    if (value && typeof value === "object") {
        return `{${Object.entries(value)
            .sort(([left], [right]) => left.localeCompare(right))
            .map(([key, entry]) => `${JSON.stringify(key)}:${stableJson(entry)}`)
            .join(",")}}`;
    }
    return JSON.stringify(value) ?? "null";
}
/**
 * Cache key covers only the DATE-SCOPE portion of a request - the part
 * that determines whether "return to the unscoped view" can reuse an
 * already-fetched full result without a Salesforce re-fetch. childNames/
 * riskFocus/countyNames/detailPage/grouping/filters are deliberately
 * excluded: those are exactly the fields a narrowing follow-up changes,
 * and this cache is keyed on what stays the SAME across such a narrowing.
 */
export function cacheKeyFor(providerKey, tool, scope) {
    return stableJson({
        providerKey,
        tool,
        dateFilter: scope.dateFilter,
        dateFrom: scope.dateFrom,
        dateTo: scope.dateTo,
        view: scope.view,
    });
}
// Same additive-narrowing rule the store has always enforced: every key
// already present in the resolved action's input must keep its exact
// value; a caller may only ADD detailPage/detailPageSize on top. Anything
// else is scope-widening and is rejected.
const ADDITIVE_REFINEMENT_KEYS = new Set(["detailPage", "detailPageSize"]);
const TRANSPORT_ONLY_KEYS = new Set(["actionId", "actionToken", "refresh"]);
export function isCompatibleWithStoredInput(requestedInput, storedInput) {
    for (const [key, value] of Object.entries(requestedInput)) {
        if (TRANSPORT_ONLY_KEYS.has(key))
            continue;
        if (key in storedInput) {
            if (stableJson(value) !== stableJson(storedInput[key]))
                return false;
        }
        else if (!ADDITIVE_REFINEMENT_KEYS.has(key)) {
            return false;
        }
    }
    return true;
}
