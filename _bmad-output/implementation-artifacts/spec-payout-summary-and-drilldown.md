---
title: 'Provider payout summary and drill-down'
type: 'feature'
created: '2026-09-09'
status: 'done'
baseline_commit: 'd2b630e752810f49e69d71482991383339a4a522'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'C:/Users/shsingla/Downloads/Child Care Agent/Child Care Agent/architecture.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Payout responses currently lead with a long child/date attendance table, making it difficult for a provider to understand total hours, applied rates, children served, and forecast versus actual payout at a glance. Detailed child/date calculations are useful, but they should follow a provider-level summary rather than replace it.

**Approach:** Add a calculated payout summary grouped by county, payment category/tier, applied rate, and attendance basis, including children served, hours, forecast amount, and conditional amount. Keep the existing child/date rows as a drill-down and allow payment analysis to scope that detail by child names or authorization names over the requested period.

## Boundaries & Constraints

**Always:** Use the deterministic evaluator as the single source of amounts; classify future scheduled hours as forecast and past confirmed attendance as actual; keep excluded authorizations visible in summary counts; preserve read-only provider scope and existing fail-closed behavior for malformed or ambiguous source data.

**Never:** Do not recalculate amounts in the formatter, use slot contracts to select authorization fiscal rates, expose raw family data, or silently include excluded authorization rows in payout totals.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|-----------------------------|----------------|
| SUMMARY | Any successful payment view | Provider-facing summary table appears before child/date detail with county, category, rate, basis, children, hours, and amount columns | N/A |
| MIXED_BASIS | Period contains past and future rows | Summary separates actual and scheduled forecast contributions | N/A |
| FILTERED_DRILLDOWN | `childNames` or `authNames` plus date scope | Calculation and detail rows include only the requested population and period | Empty filter result remains a valid zero/empty summary |
| EXCLUDED_RATE | Authorization has no usable fiscal rate | Other authorizations calculate; excluded authorization/day counts and row status are shown | Existing malformed/ambiguous rate blockers remain blocking |

</frozen-after-approval>

## Open Questions

## Code Map

- `mcp/cccap-provider-api/src/payment-orchestration.ts` -- retrieves source data, scopes schedules, builds canonical payload, and invokes the Python evaluator; extend input filters here without changing source ownership.
- `skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py` -- owns attendance classification and payment amounts; add summary aggregation from evaluated rows and preserve exclusion behavior.
- `mcp/cccap-provider-api/src/server.ts` -- owns provider-facing payment formatting and structured output; render summary before detail and expose drill-down metadata.
- `mcp/cccap-provider-api/src/schemas.ts` -- validates payment-analysis inputs; add optional child and authorization filters matching attendance analysis.
- `mcp/cccap-provider-api/test/server.test.ts` -- provider-facing payment formatting and forecast coverage; extend summary and filtered drill-down assertions.
- `skills/agent-child-care-payment-advisor/scripts/tests/test_provider_risk_payment_engine.py` -- evaluator behavior tests; add grouping, basis, exclusion, and mixed-period cases.

## Tasks & Acceptance

**Execution:**
- [x] `skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py` -- aggregate evaluated payable rows into county/category/rate/basis summary rows and return them with payment totals -- keep all arithmetic in the evaluator.
- [x] `mcp/cccap-provider-api/src/schemas.ts` and `mcp/cccap-provider-api/src/payment-orchestration.ts` -- accept optional child/auth filters and apply them before canonical evaluation -- enable scoped drill-down without duplicating source reads.
- [x] `mcp/cccap-provider-api/src/server.ts` -- render the high-level summary first, label forecast versus actual, and retain a clearly marked detail table -- make provider output scannable.
- [x] `skills/agent-child-care-payment-advisor/scripts/tests/test_provider_risk_payment_engine.py` and `mcp/cccap-provider-api/test/server.test.ts` -- cover summary aggregation, mixed basis, filters, and excluded rates -- prevent regressions.

**Acceptance Criteria:**
- Given a successful payout analysis, when the provider reads the response, then a summary table shows county, category/tier, applied rate, actual or scheduled basis, children served, hours, and amount before detail rows.
- Given future scheduled rows and past confirmed rows, when the evaluator aggregates them, then their amounts and hours remain separated by basis.
- Given child or authorization filters, when payment analysis runs for a date scope, then only the selected population contributes to totals and detail.
- Given an authorization without a usable fiscal rate, when other authorizations have valid rates, then valid amounts remain available and excluded counts/rows are visible.
- Given malformed, ambiguous, or missing required canonical inputs, when evaluation runs, then existing blocked behavior remains unchanged.

## Implementation Notes

- Added evaluator-owned summary grouping by county, paid tier, applied rate, and actual/scheduled basis.
- Added optional child and authorization filters to payment analysis; filters resolve against normalized authorization identities and attendance child names before evaluation.
- Provider output now renders the summary before the child/date detail table and marks excluded rows.
- Added regression coverage for mixed-basis summary arithmetic and both drill-down filter types.

## Spec Change Log

## Review Triage Log

## Design Notes

Summary rows should be grouped by `county_id`, `paid_tier`, `rate`, and `basis`; this preserves different authorization rates within one county/category instead of averaging or hiding them. Detail rows remain the audit trail and are filtered by the same population/date scope.

## Verification

**Commands:**
- `python skills/agent-child-care-payment-advisor/scripts/tests/test_provider_risk_payment_engine.py` -- expected: all evaluator tests pass.
- `npm test` -- expected: all MCP tests pass.
- `npm run build` -- expected: TypeScript compilation succeeds.

## Completion Notes

- Multi-period payout responses use the verified service-period ledger with one row per period.
- Ledger actions now resolve to an exact service-period date range and detail view, preventing silent period widening.
- Summary and drill-down behavior is covered by the MCP formatter/server tests and deterministic evaluator tests.
