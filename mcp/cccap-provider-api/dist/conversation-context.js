import { randomBytes } from "node:crypto";
export class ConversationContextStore {
    contexts = new Map();
    sessionActions = new Map();
    now;
    ttlMs;
    maxEntries;
    maxBytes;
    constructor(options = {}) {
        this.now = options.now ?? Date.now;
        this.ttlMs = options.ttlMs ?? 15 * 60 * 1000;
        this.maxEntries = options.maxEntries ?? 100;
        this.maxBytes = options.maxBytes ?? 1_000_000;
    }
    create(providerKey, capability, actions, result, resultTool, ruleVersion, actionMetadata = [], graph) {
        this.evict();
        const contextRef = this.reference();
        const actionRefs = actions.map(() => this.reference());
        const actionMap = new Map(actionRefs.map((actionRef, index) => {
            const action = actions[index];
            return [actionRef, {
                    ...action,
                    compatibilityKey: compatibilityKeyFor(action.tool, ruleVersion, [action]),
                }];
        }));
        const compatibilityKey = compatibilityKeyFor(capability, ruleVersion, actions);
        const fullBytes = Buffer.byteLength(JSON.stringify({ providerKey, capability, ruleVersion, actions, result, compatibilityKey }), "utf8");
        const storedResult = fullBytes <= this.maxBytes ? result : undefined;
        const bytes = Buffer.byteLength(JSON.stringify({ providerKey, capability, ruleVersion, actions, storedResult, compatibilityKey }), "utf8");
        const now = this.now();
        const providerActions = this.sessionActions.get(providerKey) ?? new Map();
        for (const [index, action] of actionMetadata.entries()) {
            const plan = actions[index];
            if (!plan || typeof action.actionId !== "string")
                continue;
            providerActions.set(action.actionId, {
                actionId: action.actionId,
                metadata: action,
                plan,
                contextRef,
                expiresAt: now + this.ttlMs,
                lastUsed: now,
                state: "OFFERED",
            });
        }
        this.sessionActions.set(providerKey, providerActions);
        this.contexts.set(contextRef, {
            providerKey,
            capability,
            ...(resultTool ? { resultTool } : {}),
            ...(storedResult !== undefined ? { result: storedResult } : {}),
            ...(ruleVersion ? { ruleVersion } : {}),
            expiresAt: now + this.ttlMs,
            actions: actionMap,
            bytes,
            lastUsed: now,
            compatibilityKey,
            ...(graph ? { graph } : {}),
        });
        this.evict();
        return { contextRef, actionRefs };
    }
    getInheritedActions(providerKey, currentActions) {
        this.evict();
        const currentIds = new Set(currentActions.map((action) => action.actionId));
        const actions = this.sessionActions.get(providerKey);
        if (!actions)
            return [];
        return [...actions.values()]
            .filter((action) => !currentIds.has(action.actionId) && this.contextIsLive(action.contextRef))
            .filter((action) => action.state === "OFFERED")
            .map((action) => {
            action.lastUsed = this.now();
            return { ...action, plan: publicPlan(action.plan) };
        });
    }
    resolve(providerKey, contextRef, actionRef, capability, ruleVersion, requestedInput) {
        if (!contextRef || !actionRef)
            return undefined;
        const context = this.contexts.get(contextRef);
        if (!context || context.providerKey !== providerKey || context.capability !== capability || context.expiresAt <= this.now() || (ruleVersion && context.ruleVersion && context.ruleVersion !== ruleVersion)) {
            this.contexts.delete(contextRef);
            return undefined;
        }
        const plan = context.actions.get(actionRef);
        if (!plan || (requestedInput && !isCompatibleInput(requestedInput, plan.input)))
            return undefined;
        if (plan.compatibilityKey && plan.compatibilityKey !== compatibilityKeyFor(plan.tool, ruleVersion, [plan]))
            return undefined;
        context.lastUsed = this.now();
        return {
            ...publicPlan(plan),
            ...(context.result !== undefined ? { result: context.result } : {}),
            ...(context.resultTool ? { resultTool: context.resultTool } : {}),
            ...(context.graph ? { graph: context.graph } : {}),
        };
    }
    resolveAction(providerKey, actionId, tool, requestedInput) {
        if (!actionId)
            return undefined;
        this.evict();
        const action = this.sessionActions.get(providerKey)?.get(actionId);
        if (!action || action.plan.tool !== tool || action.expiresAt <= this.now())
            return undefined;
        if (requestedInput && !isCompatibleInput(requestedInput, action.plan.input))
            return undefined;
        const context = this.contexts.get(action.contextRef);
        if (!context || context.providerKey !== providerKey || context.expiresAt <= this.now()) {
            action.state = "EXPIRED";
            return undefined;
        }
        action.lastUsed = this.now();
        context.lastUsed = this.now();
        action.state = "SELECTED";
        return {
            ...publicPlan(action.plan),
            ...(context.result !== undefined ? { result: context.result } : {}),
            ...(context.resultTool ? { resultTool: context.resultTool } : {}),
            ...(context.graph ? { graph: context.graph } : {}),
        };
    }
    evict() {
        const now = this.now();
        for (const [reference, context] of this.contexts) {
            if (context.expiresAt <= now)
                this.contexts.delete(reference);
        }
        for (const [providerKey, actions] of this.sessionActions) {
            for (const [actionId, action] of actions) {
                if (action.expiresAt <= now)
                    actions.delete(actionId);
            }
            if (actions.size === 0)
                this.sessionActions.delete(providerKey);
        }
        while (this.contexts.size > this.maxEntries || this.totalBytes() > this.maxBytes) {
            const oldest = [...this.contexts.entries()].sort((left, right) => left[1].lastUsed - right[1].lastUsed)[0];
            if (!oldest)
                return;
            this.contexts.delete(oldest[0]);
            const actions = this.sessionActions.get(oldest[1].providerKey);
            if (actions) {
                for (const [actionId, action] of actions) {
                    if (action.contextRef === oldest[0])
                        actions.delete(actionId);
                }
                if (actions.size === 0)
                    this.sessionActions.delete(oldest[1].providerKey);
            }
        }
    }
    totalBytes() {
        const contextBytes = [...this.contexts.values()].reduce((total, context) => total + context.bytes, 0);
        const actionBytes = [...this.sessionActions.values()].reduce((total, actions) => total + [...actions.values()].reduce((actionTotal, action) => actionTotal + Buffer.byteLength(JSON.stringify({
            actionId: action.actionId,
            metadata: action.metadata,
            contextRef: action.contextRef,
        }), "utf8"), 0), 0);
        return contextBytes + actionBytes;
    }
    contextIsLive(contextRef) {
        const context = this.contexts.get(contextRef);
        if (!context || context.expiresAt <= this.now())
            return false;
        return true;
    }
    reference() {
        return randomBytes(24).toString("base64url");
    }
}
function normalizeInput(input) {
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
function isCompatibleInput(requestedInput, planInput) {
    const requested = Object.fromEntries(Object.entries(requestedInput).filter(([key]) => key !== "contextRef" && key !== "actionRef" && key !== "refresh" && key !== "actionId"));
    for (const [key, value] of Object.entries(requested)) {
        if (key in planInput) {
            if (stableJson(value) !== stableJson(planInput[key]))
                return false;
        }
        else if (!ADDITIVE_REFINEMENT_KEYS.has(key)) {
            return false;
        }
    }
    return true;
}
function compatibilityKeyFor(capability, ruleVersion, actions) {
    return stableJson({ capability, ruleVersion: ruleVersion ?? null, plans: actions.map((action) => ({ tool: action.tool, input: normalizeInput(action.input), provenance: action.provenance ?? null })) });
}
function stableJson(value) {
    if (Array.isArray(value))
        return `[${value.map(stableJson).join(",")}]`;
    if (value && typeof value === "object")
        return `{${Object.entries(value).sort(([left], [right]) => left.localeCompare(right)).map(([key, entry]) => `${JSON.stringify(key)}:${stableJson(entry)}`).join(",")}}`;
    return JSON.stringify(value) ?? "null";
}
function publicPlan(plan) {
    const { compatibilityKey: _compatibilityKey, ...visiblePlan } = plan;
    return visiblePlan;
}
