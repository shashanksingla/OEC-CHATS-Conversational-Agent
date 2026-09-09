---
title: 'Provider conversation context and action references'
type: 'feature'
created: '2026-09-10'
status: 'in-review'
baseline_commit: '10f3b516d1daa370075f708b68ce451e137690c1'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'architecture.md'
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** Attendance and payment follow-ups currently pass detailed result data, child-name arrays, and repeated action/view projections through MCP responses. As provider data grows, a successful composite result can exceed the agent handoff budget and produce a false unavailable-result fallback even though the evaluator completed successfully.

**Approach:** Add a provider-scoped, bounded conversation context store inside the MCP server. Composite responses will retain rich provider-facing Markdown while their structured envelopes expose opaque context and action references; follow-up tools will resolve those references server-side against cached canonical results or refresh only when the context is stale or incompatible.

## Boundaries & Constraints

**Always:** Bind each context and action reference to the authenticated provider identity and the owning MCP process; use cryptographically random opaque references; validate scope, capability, expiration, and action ownership before reuse; retain existing direct attendance and payment inputs as supported backward-compatible paths; preserve server-side provider/county authorization; fail closed on unknown, expired, cross-provider, or incompatible references; keep raw Salesforce source data, provider IDs, child data, family data, authorization IDs, tokens, and headers out of provider-facing structured output; keep calculation ownership in the existing deterministic evaluators.

**Never:** Do not serialize cached datasets, child-name lists, pagination rows, raw source records, or duplicated response text into action inputs; do not make the model an owner of cache state; do not add writes, persistent provider data storage, external infrastructure, or a Redis dependency to the local stdio runtime; do not invalidate a context solely because a provider asks a compatible follow-up.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| INITIAL_SNAPSHOT | Greeting/current-month request | Rich Markdown plus compact `contextRef` and action controls with `actionRef` values | Source/evaluator errors retain existing provider-safe error result |
| CACHED_ACTION | Valid provider-bound `contextRef` and `actionRef` | Server resolves stored continuation plan and renders requested attendance or payment view without model-supplied child lists | Invalid action/context pairing is rejected without exposing cache data |
| NEW_INTENT | Direct child, authorization, scope, or payment input | Existing direct tool behavior runs; successful result creates/replaces compatible context | Existing filter validation and fail-closed source errors apply |
| STALE_CONTEXT | Expired context, rule-version change, explicit refresh, or incompatible scope/capability | Server performs the required fresh composite retrieval and returns a new context reference | If refresh fails, return provider-safe no-result/error contract |
| RESOURCE_BOUND | Cache exceeds entry, byte, or TTL limit | Least-recently-used expired/old contexts are evicted; active valid context remains usable | Missing evicted reference is treated as expired and refreshed |

</frozen-after-approval>

## Code Map

- `mcp/cccap-provider-api/src/client.ts` -- retains the lower-level source-read cache; do not expose it to model inputs or replace its provider-scope safeguards.
- `mcp/cccap-provider-api/src/server.ts` -- registers composite attendance/payment tools, creates provider-facing text, and currently generates duplicated action metadata; integrate context/action references here without changing formatter-visible Markdown.
- `mcp/cccap-provider-api/src/schemas.ts` -- validates composite inputs; add optional opaque continuation fields while preserving direct `childNames`, `authNames`, scope, payment view, and pagination inputs.
- `mcp/cccap-provider-api/src/attendance-snapshot.ts` -- owns attendance source retrieval and deterministic evaluator invocation; reuse its results rather than recreating calculations in the context layer.
- `mcp/cccap-provider-api/src/payment-orchestration.ts` -- owns payment source retrieval and deterministic evaluation; reuse its result model for cached continuation rendering.
- `mcp/cccap-provider-api/src/index.ts` -- creates the authenticated client/server process; create exactly one context store per server process here.
- `mcp/cccap-provider-api/test/server.test.ts` and `mcp/cccap-provider-api/test/protocol.test.ts` -- cover provider-safe envelopes and MCP transport; add end-to-end continuation assertions.
- `mcp/cccap-provider-api/test/client.test.ts` -- protects source cache/provider scope; retain its existing guarantees.

## Tasks & Acceptance

**Execution:**
- [x] `mcp/cccap-provider-api/src/conversation-context.ts` -- added typed, provider-bound context/action store with opaque random IDs, compatibility checks, TTL, entry/byte caps, LRU eviction, and a testable clock -- continuation state is server-owned and bounded.
- [x] `mcp/cccap-provider-api/src/schemas.ts` -- added optional `contextRef`, `actionRef`, and `refresh` inputs to attendance and payment composite schemas -- direct request shapes remain supported.
- [x] `mcp/cccap-provider-api/src/index.ts` and `mcp/cccap-provider-api/src/server.ts` -- injected one store, registered successful attendance/payment results, resolved same-capability actions from cached results before fresh retrieval, and emit compact action controls using opaque action references -- rich Markdown tables and actions remain provider-facing text.
- [x] `mcp/cccap-provider-api/src/attendance-snapshot.ts` and `mcp/cccap-provider-api/src/payment-orchestration.ts` -- preserved their evaluator and direct retrieval ownership; cached continuation rendering is handled at the server formatter boundary from their canonical composite results.
- [x] `mcp/cccap-provider-api/test/conversation-context.test.ts`, `mcp/cccap-provider-api/test/server.test.ts`, and `mcp/cccap-provider-api/test/protocol.test.ts` -- added hermetic cache, provider binding, expiry, eviction, retained-result, continuation, and compact-envelope coverage -- prevents data leakage and agent-handoff regressions.
- [x] `mcp/cccap-provider-api/README.md` and `.github/agents/carepay-advisor.agent.md` -- documented and directed opaque follow-up references with text-first result relay -- agent routing matches the server contract.

**Acceptance Criteria:**
- Given a successful greeting snapshot, when the provider chooses a returned action, then the action input contains only opaque references and the server returns the same scoped attendance/payment view without transmitting cached child rows or child-name arrays.
- Given an existing direct attendance or payment request, when it omits continuation fields, then its current behavior and calculations remain unchanged and a new compatible context is created on success.
- Given a valid context belonging to a different scope, provider, capability, expired entry, or stale rule revision, when it is reused, then the server does not expose stored data and refreshes or returns the shared safe error contract as appropriate.
- Given a provider asks to refresh, when a matching context exists, then the server bypasses it, retrieves current approved sources, and returns a new context reference.
- Given many contexts and large detail datasets, when cache limits are reached, then bounded eviction prevents unbounded memory growth and subsequent expired-reference requests remain provider-safe.
- Given an attendance-to-payment or payment-to-attendance action, when it is resolved from context, then it preserves the originating provider scope and does not require raw identifiers or model-built child filters.

## Implementation Notes

- Added `ConversationContextStore` above the raw source-read cache. It stores a provider-bound continuation plan and the completed canonical composite result under opaque random references, with a 15-minute TTL, 100-entry cap, 1 MB cap, and least-recently-used eviction.
- Same-capability attendance and payment actions now render from the stored composite result without repeating Salesforce source reads or Python evaluation. Cross-capability actions preserve their server-side scope through the opaque plan, then perform one new composite evaluation and create their own context.
- `refresh: true` resolves the stored plan but bypasses the stored result, so a reference-only refresh correctly uses its original scope/view while retrieving current sources.
- Structured action inputs now contain only `contextRef` and `actionRef`; rich provider-facing tables remain exclusively in `content[0].text`.

## Spec Change Log

## Review Triage Log

## Design Notes

Use one context record per authenticated provider, normalized scope, capability result, and rule version. A stored continuation plan owns tool target plus validated server-side filters; `actionRef` resolves to that plan. The context store is above `CccapClient.readCache`: the latter caches source reads, while the new layer caches canonical provider-safe result models and continuation plans. Initial and drill-down text remains server-rendered from the model; structured content is compact routing metadata only.

## Verification

**Commands:**
- `npm test -- --runInBand` -- expected: all MCP tests pass, including new hermetic context-store cases.
- `npm run typecheck` -- expected: no TypeScript errors.
- `npm run build` -- expected: generated `dist` matches source.
- `npm run protocol` -- expected: attendance/payment tools remain discoverable with additive schemas.