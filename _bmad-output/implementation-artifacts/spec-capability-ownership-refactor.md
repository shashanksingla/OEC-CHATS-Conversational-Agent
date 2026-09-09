---
title: 'Capability ownership refactor'
type: 'refactor'
created: '2026-09-08'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'd2b630e752810f49e69d71482991383339a4a522'
context:
  - 'c:/Users/shsingla/Downloads/Child Care Agent/Child Care Agent/_bmad-output/planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08/ARCHITECTURE-SPINE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Capability ownership is documented but not reflected in the MCP source tree. Payment canonical models, normalizers, and orchestration are mixed with attendance orchestration, while the registration server contains capability-specific formatting. This makes changes difficult to locate and increases the chance of duplicate business behavior.

**Approach:** Refactor the MCP adapter into explicit capability boundaries without changing public MCP tool names, request schemas, Apex actions, provider scope rules, evaluator contracts, or provider-facing behavior. Centralize shared response/failure policy in the conversation-template skill and keep domain skills focused on routing semantics.

**Always:** Preserve read-only provider scope, fail-closed validation, endpoint-specific identifier mapping, deterministic Python ownership of calculations, and all existing public tool contracts. Add tests for every moved module and run the existing TypeScript and Python suites.

**Never:** Do not change Salesforce/Apex schemas, activate the legacy payout calculator, accept model-supplied provider identity, alter risk rules, delete source behavior, or hand-edit generated runtime output.

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Existing attendance tool | Existing request and provider scope | Same attendance result and `riskFocus` behavior | Existing safe error contract |
| Existing payment tool | Existing payment view and canonical source payload | Same payment readiness/result status | Existing blocked result contract |
| Invalid source mapping | Missing or ambiguous required relationship | No inferred result | Fail closed at the owning normalizer |
| Clean build | TypeScript source changed | `dist` is rebuilt from source | Build failure blocks release |

</frozen-after-approval>

## Code Map

- `mcp/cccap-provider-api/src/server.ts` -- MCP registration, shared result envelope, and provider-facing formatters; retain dispatch and move only capability-specific ownership where safe.
- `mcp/cccap-provider-api/src/attendance-snapshot.ts` -- attendance composite flows and currently mixed payment orchestration; retain attendance flow and extract payment coordination.
- `mcp/cccap-provider-api/src/payment-payload-adapter.ts` -- canonical payment types and source normalizers; split schema types from normalizer functions without changing exports' behavior.
- `mcp/cccap-provider-api/src/client.ts` -- provider scope, cache, Salesforce/Apex reads; shared infrastructure, no domain-rule relocation.
- `mcp/cccap-provider-api/src/authorization-fiscal-schedule-matcher.ts` and `fiscal-rate-normalizer.ts` -- payment source mapping helpers; remain reusable infrastructure for payment normalization.
- `mcp/cccap-provider-api/test/*.test.ts` -- contract and behavior tests; update imports and add ownership-boundary coverage.
- `skills/*/SKILL.md` -- agent routing and response policy; global failure/response rules belong to conversation templates.
- `mcp/cccap-provider-api/dist/` -- generated output; rebuild from TypeScript and never edit manually.

## Tasks & Acceptance

**Execution:**
- [x] Extract canonical payment interfaces into a dedicated schema module and keep runtime behavior unchanged.
- [x] Extract payment retrieval/normalization/evaluator coordination into a payment orchestration module; keep attendance orchestration attendance-only.
- [x] Update imports, tests, and MCP build output from source.
- [x] Keep `server.ts` as registration/dispatch plus shared result envelope; document capability ownership without changing tool contracts.
- [x] Keep shared response/failure policy in conversation templates and remove duplicated global policy from domain skills.
- [x] Mark generated artifacts as generated and ensure source changes are the only hand-edited runtime changes.

**Acceptance Criteria:**
- Given the existing MCP requests, when the refactored server runs, then all existing tool names, schemas, scope enforcement, result statuses, and provider messages remain compatible.
- Given a payment source mapping change, when a developer searches the MCP source tree, then payment schema, normalization, and orchestration have distinct owners.
- Given an attendance change, when attendance tests run, then attendance behavior remains unchanged and payment modules are not required for attendance-only flows.
- Given source changes, when `npm run typecheck`, `npm test`, and `npm run build` run, then all pass and generated output is produced from `src`.
- Given Python evaluator tests, when the standard-library test runner runs, then all deterministic tests pass.

## Implementation Notes

- Preserve the existing staged `riskFocus` changes and user modifications in the worktree.
- Prefer re-export compatibility during extraction so tests and future callers do not break unnecessarily.
- Do not rename public MCP tools or Salesforce actions in this refactor.
- Extracted shared schedule normalization and provider-tier mapping after dependency review exposed a circular attendance/payment import.
- Generated `dist` was rebuilt from TypeScript; the local MCP registration continues to launch that generated entrypoint.

## Review Triage Log

- **fixed:** Extracted modules lacked direct ownership tests; added `test/ownership-boundaries.test.ts` covering provider policy, payment schema, schedule normalization, and payment orchestration failure propagation.
- **fixed:** `ABSENCE_LIMITS` focus had no direct formatter test; added the branch test in `test/server.test.ts`.
- **fixed:** `PARENT_CONFIRMATIONS` focus suggested a review action even with zero pending days; the action now requires `pendingDays > 0`.
- **fixed:** Payment extraction lacked an old-import compatibility path; `attendance-snapshot.ts` re-exports `getPaymentAnalysis`.
- **false:** Review concern about a missing absence-limit helper was disproved; `hasAbsenceLimitConcern` remains defined and exercised by the formatter tests.
- **false:** Review concern about missing verification evidence was disproved by the final typecheck, 62 MCP tests, build, protocol discovery, and 69 Python tests.
- **false:** Review concern about unvalidated `riskFocus` values is covered by the Zod enum schema; unsupported values cannot reach the formatter.
- **false:** Shared normalizer documentation was updated in the architecture spine and module names now express ownership directly.
- **false:** Re-export compatibility is intentional and documented in implementation notes; direct module tests now cover the canonical owners.
- **false:** Skill guidance already specifies both focus values and their routing; no runtime behavior depends on duplicated prose.

## Verification

**Commands:**
- `Push-Location mcp/cccap-provider-api; npm run typecheck; npm test; npm run build; Pop-Location` -- expected: typecheck, 61+ tests, and build pass.
- `Push-Location skills/agent-child-care-payment-advisor; uv run python -m unittest discover -s scripts/tests -p "test_*.py"; Pop-Location` -- expected: all deterministic tests pass.
