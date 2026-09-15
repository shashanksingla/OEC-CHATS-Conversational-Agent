---
title: 'Scope payment forecasts to the selected service period'
type: 'bugfix'
created: '2026-09-15'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** A payment forecast can fail because an authorization returned by a broad date query is not referenced by any schedule in the selected service period. The unrelated authorization is still mapped, and its effective-date mismatch aborts the entire forecast.

**Approach:** Restrict payment inputs to schedules whose work dates are within the selected service period, then retain only authorizations referenced by those schedules before fiscal-schedule canonicalization. Preserve fail-closed behavior for mappings required by retained forecast rows.

</frozen-after-approval>

## Implementation Notes

Changed `mcp/cccap-provider-api/src/payment-orchestration.ts` to discard schedules outside the selected service-period dates, fail closed for undated schedules, and retain only authorization rows referenced by retained schedules before fiscal-schedule canonicalization. Added `mcp/cccap-provider-api/test/payment-period-scope.test.ts` covering the future authorization `963424` failure shape.

Validation passed: 164 tests and TypeScript typecheck. A live MCP retry moved past the original authorization `NO_MATCH` and reached a separate source-data error for a missing child date of birth.

Follow-up hardening: the payout ledger now initializes provider scope before retrieving service periods, covering the direct `NEXT_PAYOUT` path that previously emitted `Initialize provider context before requesting scoped data`. Validation passed again with 165 tests, typecheck, and build.
