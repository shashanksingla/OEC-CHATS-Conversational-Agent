---
title: 'Provider conversation context and action references'
type: 'feature'
created: '2026-09-10'
status: 'done'
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
| INITIAL_SNAPSHOT | Greeting/current-month request | Rich Markdown plus opaque action controls carrying only `actionId` | Source/evaluator errors retain existing provider-safe error result |
| CACHED_ACTION | Valid provider-bound `actionId` | Server resolves the private continuation plan and renders requested attendance or payment view without model-supplied child lists | Unknown action IDs are rejected without exposing cache data |
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
- [x] `mcp/cccap-provider-api/src/conversation-context.ts` -- extended the provider-bound store with an immutable normalized compatibility key, inherited-action provenance, and metadata-aware byte accounting.
- [x] `mcp/cccap-provider-api/src/schemas.ts` -- preserved direct attendance/payment inputs while enforcing all-or-none continuation references.
- [x] `mcp/cccap-provider-api/src/client.ts` -- added bounded source-read freshness and explicit cache clearing for refresh.
- [x] `mcp/cccap-provider-api/src/index.ts` and `mcp/cccap-provider-api/src/server.ts` -- resolved continuation plans through compatibility validation, failed closed for invalid references, preserved originating scope, and removed duplicated provider prose from structured output.
- [x] `mcp/cccap-provider-api/src/attendance-snapshot.ts` and `mcp/cccap-provider-api/src/payment-orchestration.ts` -- retained evaluator and direct retrieval ownership.
- [x] `mcp/cccap-provider-api/test/conversation-context.test.ts`, `mcp/cccap-provider-api/test/client.test.ts`, `mcp/cccap-provider-api/test/server.test.ts`, and `mcp/cccap-provider-api/test/protocol.test.ts` -- added hermetic coverage for continuation compatibility, refresh/cache bounds, malformed references, provenance, byte bounds, and text-only envelopes.
- [x] `mcp/cccap-provider-api/README.md` and `.github/agents/carepay-advisor.agent.md` -- existing opaque-reference and text-first routing documentation remains aligned.

**Acceptance Criteria:**
- Given a successful greeting snapshot, when the provider chooses a returned action, then the action input contains only opaque references and the server returns the same scoped attendance/payment view without transmitting cached child rows or child-name arrays.
- Given an existing direct attendance or payment request, when it omits continuation fields, then its current behavior and calculations remain unchanged and a new compatible context is created on success.
- Given a valid context belonging to a different scope, provider, capability, expired entry, or stale rule revision, when it is reused, then the server does not expose stored data and refreshes or returns the shared safe error contract as appropriate.
- Given a provider asks to refresh, when a matching context exists, then the server bypasses it, retrieves current approved sources, and returns a new context reference.
- Given many contexts and large detail datasets, when cache limits are reached, then bounded eviction prevents unbounded memory growth and subsequent expired-reference requests remain provider-safe.
- Given an attendance-to-payment or payment-to-attendance action, when it is resolved from context, then it preserves the originating provider scope and does not require raw identifiers or model-built child filters.
- Given a continuation request with any changed compatibility-key field, when it is reused, then the cached result is not served under the changed projection and the server either executes the stored validated plan afresh or returns the shared safe error contract.
- Given a continuation request with only one reference or an unresolvable reference pair plus direct filters, when it is received, then schema/dispatch rejects it without executing the direct filters.
- Given `refresh: true`, when a continuation is resolved, then both canonical-result reuse and lower-level source-read reuse are bypassed and the returned context reflects a fresh retrieval attempt.
- Given a structured MCP result, when it is relayed, then full provider prose appears only in `content[0].text`; structured metadata contains no `providerMessage`, canonical rows, child lists, raw identifiers, or duplicated prose.

## Implementation Notes

- Existing `ConversationContextStore` is the starting point: retain its opaque references, provider binding, 15-minute TTL, 100-entry cap, 1 MB cap, LRU eviction, and process-local ownership while tightening compatibility and provenance checks.
- The shared continuation boundary must distinguish same-capability cached projections from cross-capability fresh evaluation; the latter carries only an opaque plan and re-enters the target capability's authorization and normalization path.
- Existing formatter-visible Markdown and deterministic evaluator ownership remain stable unless required to remove duplicated provider prose from structured output.

## Spec Change Log

- 2026-09-10: Reconciled the implementation plan with the finalized architecture and current runtime review. Marked incomplete continuation compatibility, refresh, fail-closed, provenance, byte-bound, pagination, and envelope work as actionable tasks.

## Review Triage Log

- `false` -- Blind hunter: refresh only clears the shared `CccapClient` read cache, which covers all lower-level provider reads; no separate cache path remains.
- `patched` -- Blind hunter: continuation byte accounting previously counted action payloads through both context and session records; context storage now counts the canonical plan once and session metadata separately.
- `false` -- Blind hunter: expired session actions are removed by `evict()` on every store operation and lookup path, so `contextIsLive()` does not leave them indefinitely resident.
- `patched` -- Verification-gap reviewer: source-cache TTL, explicit clearing, and entry-bound eviction lacked behavioral tests; client tests now cover expiry, clearing, and the 100-entry bound.
- `false` -- Blind hunter: child-name and county unmatched wording is existing formatter behavior outside this continuation change and is not caused by the reviewed diff.
- `false` -- Blind hunter: removing duplicated `providerMessage` from structured output is an explicit approved contract requirement and is covered by protocol/formatter tests.
- `false` -- Edge-case hunter: payment pagination is carried in the stored action plan and altered direct pagination fields are rejected by compatibility matching; the cited `omitPagination` path is not present.
- `false` -- Edge-case hunter: refresh calls `clearReadCache()` before fresh retrieval, so lower-level cached reads are bypassed for both composite capabilities.
- `false` -- Verification-gap reviewer: its missing-cache-test finding is resolved by the focused client tests added in this review pass.

## Design Notes

Use one private context record per authenticated provider, normalized scope, capability result, and rule version. A stored continuation plan owns the tool target plus validated server-side filters; the public `actionId` resolves to that plan through the provider-bound store. `contextRef` and `actionRef` are private implementation handles, not conversational concepts. The context store is above `CccapClient.readCache`: the latter caches source reads, while the new layer caches canonical provider-safe result models and continuation plans. Initial and drill-down text remains server-rendered from the model; structured content is compact routing metadata only.

## Verification

**Commands:**
- `npm test -- --runInBand` -- expected: all MCP tests pass, including new hermetic context-store cases.
- `npm run typecheck` -- expected: no TypeScript errors.
- `npm run build` -- expected: generated `dist` matches source.
- `npm run protocol` -- expected: attendance/payment tools remain discoverable with additive schemas.