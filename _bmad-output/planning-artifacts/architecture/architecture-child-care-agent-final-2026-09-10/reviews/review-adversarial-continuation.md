# Adversarial Review: Continuation and Ownership

**Target:** `ARCHITECTURE-SPINE.md` compared with `mcp/cccap-provider-api/src/server.ts`, `src/conversation-context.ts`, and the three implementation specs.

## Verdict

**Not ready to approve.** The implementation follows the broad server-owned continuation direction, but AD-8 and AD-9 are stated more strongly than the runtime enforces. The most serious conflicts are projection/scope compatibility, the unbounded lower-level read cache, and cross-capability action provenance. These can return stale or differently scoped provider results while still appearing successful. Text-only ownership is also not consistently represented by the structured envelope.

## Critical Findings

### C1. Cached attendance continuations can accept a caller-supplied scope projection

**Location:** `ARCHITECTURE-SPINE.md`, AD-8/AD-9; `mcp/cccap-provider-api/src/server.ts`, `cccap_analyze_attendance_risk` dispatch; `src/conversation-context.ts`, `resolve`.

The store resolves only provider, the generic capability label `continuation`, expiry, and optional rule version. After resolution, attendance uses the stored plan only when its tool matches, but constructs the cached result as `{ ...cachedResult, scope: request, riskFocus: request.riskFocus, countyNames: request.countyNames }`. That lets a continuation request add or replace scope/focus fields without a compatibility comparison against the canonical result. AD-9 requires normalized scope, filters, focus/view, projection, and pagination compatibility before reuse.

**Consequence:** A valid opaque action can render cached facts under a caller-selected date/county/focus label, producing a misleading successful view or cross-scope result.

**Required guard:** Store canonical normalized compatibility metadata and compare every requested projection/filter/focus/scope field before serving cached data. On mismatch, bypass the result cache and run the stored validated plan or return the shared fail-closed contract; never overwrite cached scope with request fields.

### C2. Payment detail pagination is not a compatible cache projection

**Location:** `ARCHITECTURE-SPINE.md`, AD-9 and Deferred compatibility-key detail; `spec-provider-conversation-context.md`, CACHED_ACTION/STALE_CONTEXT; `server.ts`, `cccap_analyze_payment` dispatch and `paymentActionMetadata`.

Payment requests with `detailPage` or `detailPageSize` bypass the cached result, but the request is still derived from the stored continuation plan and is evaluated with the requested page. The context record does not store or validate the base filters, result projection, page size, or total-row identity. `next-payment-detail-page` is generated from formatter metadata and can be reused through the provider-wide inherited-action map after later turns.

**Consequence:** A page action can be applied to a changed or incompatible base projection, yielding page numbers/rows that no longer correspond to the original summary. A changed page size or filter is not detected as stale; pagination can silently drift.

**Required guard:** Make pagination part of an immutable continuation compatibility key: normalized scope, filters, view, detail page size, result/rule version, and source freshness. A next-page action must resolve only against that exact base projection, otherwise perform an explicit fresh retrieval and issue a new context.

### C3. The lower-level source cache has no TTL, refresh, or eviction

**Location:** `ARCHITECTURE-SPINE.md`, AD-9 and Cache convention; `mcp/cccap-provider-api/src/client.ts`, `cachedCall`; `spec-provider-conversation-context.md`, client-cache boundary and refresh acceptance.

`cachedCall` stores every `action + JSON.stringify(body)` result indefinitely in `readCache`. `refresh: true` bypasses only the conversation-context result in `server.ts`; it does not invalidate or bypass `CccapClient.readCache`. The architecture calls for cache-first reuse only when freshness/expiry compatibility passes and explicitly describes bounded cache behavior, but the source-read cache has no freshness metadata or bound.

**Consequence:** Explicit refresh can return the same stale Salesforce source data, and long-lived MCP processes can grow without bound. The system can report a fresh continuation timestamp while its underlying source data is not fresh.

**Required guard:** Give source reads explicit TTL/freshness and bounded eviction, or make refresh pass a cache-bypass/invalidation control through the client. Keep source-cache freshness distinct from canonical-result TTL and include it in continuation compatibility.

## High Findings

### H1. Cross-capability actions are not bound to the originating scope/context

**Location:** `ARCHITECTURE-SPINE.md`, AD-8; `server.ts`, `contextualize` and `getInheritedActions`; `conversation-context.ts`, `sessionActions`.

Cross-capability actions are retained in a provider-wide `sessionActions` map keyed only by `actionId`. `getInheritedActions` returns prior actions after excluding IDs/current capability, and `contextualize` creates a new context from those actions. The action metadata itself contains the original input, including child filters before the structured input is replaced by opaque refs. There is no check that the inherited action's source context is still compatible with the current normalized scope, freshness, or capability transition.

**Consequence:** A later payment or attendance response can expose an executable action from an older scope or stale context. Provider binding alone is insufficient for the AD-8 requirement that the opaque reference resolve a validated scope/filter projection.

**Required guard:** Store origin context identity and compatibility metadata with each session action; inherit only actions whose source context is valid and compatible. Prefer resolving inherited actions directly through their original context rather than copying plans into a new unqualified session entry.

### H2. AD-10 is contradicted by duplicated provider prose in `structuredContent`

**Location:** `ARCHITECTURE-SPINE.md`, AD-10; `server.ts`, `snapshotResult`, `formatAttendanceRiskResult`, `formatPaymentResult`, `contextualize`; `test/protocol.test.ts`.

AD-10 says `content[0].text` is the sole provider-facing response channel and `structuredContent` contains only compact status/scope/pagination/action controls. Runtime structured envelopes deliberately include `providerMessage` equal to the full rendered Markdown for attendance and payment, and tests assert that equality. The context spec says the same: “structured content is compact routing metadata only,” while its acceptance notes say rich Markdown remains exclusively in text.

**Consequence:** Consumers can relay or display duplicate full provider prose, reintroducing the handoff-size and competing-response-source problem AD-10 is meant to prevent. The architecture and tests encode incompatible contracts.

**Required guard:** Remove full `providerMessage` from structured output for attendance/payment and assert its absence; retain only compact status, capability, scope, freshness, pagination, and opaque controls. If a consumer needs a text echo, revise AD-10/specs explicitly and define one owner.

### H3. Fail-closed continuation validation is incomplete for malformed reference pairs

**Location:** `schemas.ts`, attendance/payment schemas; `server.ts`, both composite dispatch branches; `conversation-context.ts`, `resolve`.

The schemas permit `contextRef` and `actionRef` independently. The dispatch branches only return an error for an invalid pair when the request also lacks `dateFilter` (attendance) or lacks both `dateFilter` and `view` (payment). Thus a malformed/expired reference can be silently ignored and a direct request can execute instead. The specs require unknown, expired, cross-provider, and incompatible references to be rejected or handled as explicit stale refresh behavior.

**Consequence:** A failed action click may run a different direct query supplied by the model instead of failing closed, weakening action ownership and making stale UI controls appear to work against a new scope.

**Required guard:** Enforce all-or-none references in schema validation and reject any supplied-but-unresolvable reference unless an explicit, validated refresh path is selected. Do not fall back to direct request inputs when continuation fields are present.

### H4. Attendance and payment continuation compatibility are asymmetric

**Location:** `ARCHITECTURE-SPINE.md`, capability symmetry implied by AD-8/AD-9; `server.ts`, attendance/payment dispatch branches.

Attendance cached reuse always renders the stored canonical result unless `refresh`; payment cached reuse is disabled for any detail pagination request and uses `request` as `filters` on the cached result. Attendance rewrites scope/focus from the request; payment preserves cached result scope for dialogue state but replaces filter metadata. Neither path validates projection compatibility through a shared helper, despite the architecture binding the same continuation rules to both capabilities.

**Consequence:** Equivalent action-control flows have different stale-data and scope semantics, so fixes or tests for one capability do not protect the other. Providers can receive a successful but differently scoped attendance view versus a fresh payment detail view from analogous controls.

**Required guard:** Define one shared continuation compatibility/resolution contract used by both capabilities, with capability-specific projection fields layered on top and symmetric tests for scope, filter, refresh, expiry, pagination, and cross-capability actions.

## Verification Gap

The existing tests cover opaque references, provider binding, TTL, entry eviction, and happy-path action selection. They do not appear to assert: changed scope/focus on a cached attendance action, refresh bypassing the client read cache, page-size/filter incompatibility, stale inherited cross-capability actions, malformed reference pairs with direct inputs, or absence of duplicated provider prose in structured output. The current `npm test`, typecheck, and architecture-spine lint passing therefore does not disprove these conflicts.

**Runtime code was not changed.**