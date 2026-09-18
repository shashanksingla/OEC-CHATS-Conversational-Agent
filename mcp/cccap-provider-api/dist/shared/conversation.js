// Merged: conversation-state.ts (dialogue-state.ts + conversation-context.ts) +
// conversation-logger.ts. All are "conversation layer" infra, always instantiated together
// in server.ts. DialogueStateStore = turn-classification/glossary flag (in-memory, TTL
// 15min/100 entries). ConversationContextStore = action-token issuance/resolution, result
// cache, scope-granularity classification, multi-hop loop-guard signatures (disk-persisted).
// ConversationLogger = per-turn telemetry/audit log (file-based, redacted).
// ConversationSessionStore = greeting-shown + already-surfaced-action tracking, scoped to
// the CONVERSATION (the MCP server process lifetime), not to a rolling TTL - deliberately
// separate from DialogueStateStore, which resets on a 15-minute idle window for a different
// purpose (scope/capability freshness diffing). A session boundary here means "this MCP
// server process started", which happens once per conversation per the current architecture
// (index.ts spins up one server per session) - no eviction logic is needed or wanted.
import { randomBytes } from "node:crypto";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import * as fs from "node:fs";
import * as path from "node:path";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
// Keeps bounded, process-local capability/scope/freshness state for reliable turn classification.
export class DialogueStateStore {
    states = new Map();
    now;
    ttlMs;
    maxEntries;
    constructor(options = {}) {
        this.now = options.now ?? Date.now;
        this.ttlMs = options.ttlMs ?? 15 * 60 * 1000;
        this.maxEntries = options.maxEntries ?? 100;
    }
    hasGlossary(providerKey) {
        this.evict();
        return this.states.get(providerKey)?.glossaryShown === true;
    }
    getLastScope(providerKey) {
        this.evict();
        const record = this.states.get(providerKey);
        if (!record || record.expiresAt <= this.now())
            return undefined;
        return record.lastScope;
    }
    markGlossary(providerKey) {
        this.evict();
        const now = this.now();
        const existing = this.states.get(providerKey);
        this.states.set(providerKey, {
            lastCapability: existing?.lastCapability ?? "",
            lastScope: existing?.lastScope,
            lastFreshnessAt: existing?.lastFreshnessAt ?? "",
            expiresAt: existing?.expiresAt ?? now + this.ttlMs,
            glossaryShown: true,
        });
    }
    recordAndDiff(providerKey, capability, scope, freshnessAt) {
        this.evict();
        const now = this.now();
        const previous = this.states.get(providerKey);
        const stillFresh = previous !== undefined && previous.expiresAt > now;
        const scopeChanged = !stillFresh || !this.scopeEquals(previous.lastScope, scope);
        const capabilityChanged = !stillFresh || previous.lastCapability !== capability;
        const diff = {
            scopeChanged,
            capabilityChanged,
            ...(stillFresh ? { sinceLastTurn: previous.lastFreshnessAt } : {}),
        };
        this.states.set(providerKey, {
            lastCapability: capability,
            lastScope: scope,
            lastFreshnessAt: freshnessAt,
            expiresAt: now + this.ttlMs,
            ...(stillFresh && previous.glossaryShown !== undefined ? { glossaryShown: previous.glossaryShown } : {}),
        });
        return diff;
    }
    scopeEquals(left, right) {
        try {
            return JSON.stringify(left) === JSON.stringify(right);
        }
        catch {
            return false;
        }
    }
    evict() {
        const now = this.now();
        for (const [providerKey, record] of this.states) {
            if (record.expiresAt <= now)
                this.states.delete(providerKey);
        }
        while (this.states.size > this.maxEntries) {
            const oldest = [...this.states.entries()].sort((left, right) => left[1].expiresAt - right[1].expiresAt)[0];
            if (!oldest)
                return;
            this.states.delete(oldest[0]);
        }
    }
}
const DEFAULT_PERSIST_PATH = join(tmpdir(), "cccap-continuation-store.json");
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
    lastSnapshotScope = new Map();
    recentStates = new Map();
    static RECENT_STATE_LIMIT = 3;
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
    createActionToken(providerKey, tool, input, ruleVersion) {
        this.evictActions();
        const token = randomBytes(16).toString("base64url");
        const now = this.now();
        this.actions.set(token, { providerKey, tool, input, ...(ruleVersion ? { ruleVersion } : {}), expiresAt: now + this.ttlMs, lastUsed: now });
        this.saveToDisk();
        return token;
    }
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
    setLastSnapshotScope(providerKey, scope) {
        this.lastSnapshotScope.set(providerKey, scope);
    }
    getLastSnapshotScope(providerKey) {
        return this.lastSnapshotScope.get(providerKey);
    }
    recordRenderedState(providerKey, tool, input) {
        const signature = stableJson({ tool, input });
        const history = this.recentStates.get(providerKey) ?? [];
        history.push(signature);
        if (history.length > ConversationContextStore.RECENT_STATE_LIMIT)
            history.shift();
        this.recentStates.set(providerKey, history);
    }
    recentActionSignatures(providerKey) {
        return new Set(this.recentStates.get(providerKey) ?? []);
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
            // Persistence is optional; an empty store is a valid starting state.
        }
    }
    saveToDisk() {
        try {
            mkdirSync(dirname(this.persistPath), { recursive: true });
            writeFileSync(this.persistPath, JSON.stringify({ actions: Object.fromEntries(this.actions) }), "utf8");
        }
        catch {
            // Keep in-memory continuation working when disk persistence fails.
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
export const ADDITIVE_REFINEMENT_KEYS = new Set(["detailPage", "detailPageSize"]);
export function additiveRefinementsOnly(input) {
    return Object.fromEntries(Object.entries(input).filter(([key]) => ADDITIVE_REFINEMENT_KEYS.has(key)));
}
// ===== end conversation-context.ts =====
// ===== begin conversation-logger.ts =====
const SALESFORCE_ID_PATTERN = /[a-zA-Z0-9]{15,18}/g;
const DEFAULT_LOG_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "..", ".logs");
export class ConversationLogger {
    logDir;
    sessionId = "";
    turn = 0;
    constructor(logDir) {
        this.logDir = logDir ?? process.env.CCCAP_CONVERSATION_LOG_DIR ?? DEFAULT_LOG_DIR;
    }
    startSession(providerKey) {
        this.sessionId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
        this.turn = 0;
        const now = new Date();
        const started = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")}`;
        this.append(`## Conversation session ${this.sessionId} - ${this.redact(providerKey)} - started ${started}\n\n`);
    }
    // Records an authorization/schedule rate-type mismatch - county matched but no
    // candidate fiscal schedule had the requested rate type. This is the specific root
    // cause behind "rate not yet available for these dates". Includes the candidate
    // schedule IDs that were considered (and their actual rate types) so the mismatch
    // can be tracked back to the exact Rate_Schedule__c record. Not tied to conversation
    // turns; appended directly to the current session's log file.
    logFiscalScheduleMismatch(entry) {
        const detail = this.truncate(JSON.stringify(this.redactObject(entry)));
        this.append(`> [fiscal-schedule-mismatch] ${detail}\n`);
    }
    // Records a per-day fiscal-rate join miss surfaced by provider_risk_payment_engine.py's
    // fiscal_rate_gaps (the schedule matched, but no fiscal rate row had the exact
    // paid_tier/rate_type_code/age_group_code the day requested). Distinct from
    // logFiscalScheduleMismatch above, which fires earlier at schedule selection; this fires
    // at the rate-row join itself, so it's the more precise signal for "rate not yet available
    // for these dates" when the schedule match succeeded but the row-level join still failed.
    logFiscalRateGap(entry) {
        const detail = this.truncate(JSON.stringify(this.redactObject(entry)));
        this.append(`> [fiscal-rate-gap] ${detail}\n`);
    }
    logToolCall(entry) {
        const input = JSON.stringify(this.redactObject(entry.input));
        const response = entry.providerResponseText === undefined
            ? "(no provider text)"
            : this.truncate(this.redact(entry.providerResponseText));
        const error = entry.error
            ? `Error: ${this.redact(entry.error.code)} - ${this.redact(entry.error.message)}\n${entry.error.diagnostic ? `Diagnostic: ${this.redact(entry.error.diagnostic)}\n` : ""}`
            : "";
        const providerSaidLine = entry.providerUtterance
            ? `Provider said: "${this.redact(entry.providerUtterance)}"\n\n`
            : "";
        const content = `### Turn ${this.turn} - ${this.redact(entry.tool)} - ${entry.status} (${entry.durationMs}ms)\n\n${providerSaidLine}Input: \`${input}\`\n\nResponse:\n${response}\n\n${error}---\n\n`;
        this.append(content);
    }
    append(content) {
        fs.mkdirSync(this.logDir, { recursive: true });
        const now = new Date();
        const date = `${String(now.getDate()).padStart(2, "0")}_${String(now.getMonth() + 1).padStart(2, "0")}_${String(now.getFullYear()).slice(-2)}`;
        const filePath = path.join(this.logDir, `Assist_log_${date}_${this.sessionId || "no-session"}.md`);
        fs.appendFileSync(filePath, content, "utf8");
    }
    redact(value) {
        return value.replace(SALESFORCE_ID_PATTERN, "[redacted-id]");
    }
    redactObject(value, key) {
        if (typeof value === "string") {
            return key === "actionToken" ? "[redacted-token]" : this.redact(value);
        }
        if (Array.isArray(value)) {
            return value.map((item) => this.redactObject(item));
        }
        if (value && typeof value === "object") {
            return Object.fromEntries(Object.entries(value).map(([entryKey, entryValue]) => [
                entryKey,
                this.redactObject(entryValue, entryKey),
            ]));
        }
        return value;
    }
    truncate(value) {
        return value.length > 4000 ? `${value.slice(0, 4000)}\n[...truncated]` : value;
    }
}
// Tracks two session-scoped (not TTL-scoped) concerns per provider, both intentionally
// living for the lifetime of the MCP server process rather than a rolling idle window:
// 1. Whether a greeting has already been attached to a response this conversation.
// 2. Which recommended-action IDs have already been surfaced this conversation, so a
//    resolved-but-still-flagged item isn't repeated on every turn - it only reappears if
//    the provider explicitly asks about that topic again (a different code path: a direct,
//    scoped request, not the passive "Recommended actions" list this store gates).
export class ConversationSessionStore {
    greetedProviders = new Set();
    surfacedActionsByProvider = new Map();
    hasGreeted(providerKey) {
        return this.greetedProviders.has(providerKey);
    }
    markGreeted(providerKey) {
        this.greetedProviders.add(providerKey);
    }
    hasSurfacedAction(providerKey, actionId) {
        return this.surfacedActionsByProvider.get(providerKey)?.has(actionId) ?? false;
    }
    markActionSurfaced(providerKey, actionId) {
        const surfaced = this.surfacedActionsByProvider.get(providerKey) ?? new Set();
        surfaced.add(actionId);
        this.surfacedActionsByProvider.set(providerKey, surfaced);
    }
}
export const conversationSessionStore = new ConversationSessionStore();
export const conversationLogger = new ConversationLogger();
// ===== end conversation-logger.ts =====
