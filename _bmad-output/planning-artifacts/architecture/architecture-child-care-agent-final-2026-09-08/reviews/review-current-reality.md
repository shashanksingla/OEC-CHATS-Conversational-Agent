# Current-Reality Architecture Review

## Verdict

**Amendment is directionally correct but not ready as an exact description of the current implementation.** AD-8 is substantially accurate. AD-9 overstates the compatibility guarantees implemented by the continuation resolver. AD-10 is contradicted by the current response envelope because `structuredContent.providerMessage` duplicates the provider-facing text for composite results.

The declared versions checked in `mcp/cccap-provider-api/package.json` remain current for this repository: TypeScript `7.0.2`, MCP server SDK `2.0.0`, Zod `4.5.4`, and Node types `26.4.1`.

## Findings

### 1. High: AD-10 does not match the live envelope

**Spine claim:** `structuredContent` contains only compact status, scope, pagination, and opaque action controls, and never duplicated provider prose.

**Repository evidence:** `mcp/cccap-provider-api/src/server.ts` preserves `providerMessage` in `structuredContent` for attendance and payment capabilities inside `contextualize()`. The formatter functions also commonly set `structuredContent.providerMessage` equal to `content[0].text`. Tests in `mcp/cccap-provider-api/test/server.test.ts` explicitly assert this equality.

**Impact:** The rule is currently aspirational, not a current-reality statement. Either remove the “never duplicated provider prose” sentence from AD-10 or change the implementation/spec and tests together. The implementation artifact `spec-provider-conversation-context.md` already describes the intended text-first contract, so the architecture and implementation are out of sync.

### 2. Medium: AD-9 describes compatibility checks that are not centralized or complete

**Spine claim:** A continuation is served only when provider scope, capability, normalized scope, rule version, freshness, requested projection, and pagination are compatible.

**Repository evidence:** `mcp/cccap-provider-api/src/conversation-context.ts` checks provider key, capability, expiry, and optional rule version. It does not store or compare normalized scope, freshness, requested projection, or pagination. `mcp/cccap-provider-api/src/server.ts` adds limited per-tool behavior: `refresh` bypasses cached results, and payment detail-page requests bypass the cached payment result. The attendance continuation path overlays request fields onto the cached result rather than using a general compatibility-key comparison.

**Impact:** The wording promises a stronger invariant than the code enforces. Narrow AD-9 to the implemented checks, or make the compatibility key explicit and enforce it in the context store before treating the rule as adopted.

### 3. Low: AD-8 is accurate with one important scope nuance

The implementation supports opaque random references, provider-bound context records, server-owned continuation plans, capability/tool validation, TTL, entry/byte bounds, and LRU eviction in `mcp/cccap-provider-api/src/conversation-context.ts`. `mcp/cccap-provider-api/src/index.ts` resolves the authenticated provider user outside model input, and `server.ts` injects the store and rewrites action inputs to `contextRef`/`actionRef`.

The architecture should make explicit that a cross-capability action is not served from the originating canonical result: the server preserves the validated plan and performs a new composite evaluation. This behavior matches `spec-provider-conversation-context.md` and does not invalidate AD-8, but it matters when interpreting “cached-result reuse.”

### 4. Medium: AD-7's generated-artifact operational claim remains stale

The spine says `mcp/cccap-provider-api/dist` is disposable and runtime changes occur only in source. The current repository includes generated `dist` output, and `carepay-agent-file-usage.md` documents compiled MCP `dist` output as included. The implementation spec also says the local registration launches the generated entrypoint. This is an operational/documentation inconsistency rather than an AD-8/9/10 defect, but the amended spine should either describe checked-in generated output accurately or establish and enforce a clean-build policy.

## Checks Performed

- MCP test suite: passed according to the execution check; continuation, envelope, and protocol tests are present.
- MCP TypeScript typecheck: passed according to the execution check.
- Architecture spine lint: passed according to the execution check.
- Package-version review: no stale version found in the named MCP package dependencies.

## Recommended Amendments

1. Change AD-10 to state that provider-facing prose is authoritative in `content[0].text`, while acknowledging that the current structured envelope still mirrors `providerMessage` for compatibility.
2. Change AD-9 to enumerate the checks actually enforced today, or implement and test one canonical compatibility key covering scope, freshness, projection, and pagination.
3. Add the cross-capability re-evaluation nuance to AD-8.
4. Reconcile AD-7 with the checked-in `dist` policy and `carepay-agent-file-usage.md`.