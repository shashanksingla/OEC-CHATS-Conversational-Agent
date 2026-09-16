---
title: 'Fix authorization schedule join for fiscal-rate mapping'
type: 'bugfix'
created: '2026-09-14'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Forecast attendance rows can lose their fiscal-rate mapping even when the live schedule contains the authorization reference, Denver county, rate type `1`, and authorized hours that map to `FULL_TIME`.

**Approach:** Normalize schedule authorization references at the schedule-to-authorization join so Salesforce ID, external authorization ID, and name references resolve to the same canonical authorization ID used by fiscal-rate rows and attendance days.

</frozen-after-approval>

## Implementation Notes

Investigated `schedule-normalizer.ts`, `payment-orchestration.ts`, `payment-canonical-adapter.ts`, `payment-payload-adapter.ts`, and the Python payment engine. Paid absence derives `FULL_TIME` directly from authorized hours; the requested fix is limited to authorization identity normalization and must preserve that behavior.

Changed `authorization-fiscal-schedule-matcher.ts` to return `FiscalScheduleCandidate.externalId`, matching the identifier stored in normalized fiscal-rate `fiscalScheduleId` values. Updated the focused matcher expectations. The focused/full runtime test suite and production typecheck pass. Test typecheck remains blocked by two unrelated pre-existing `action possibly undefined` diagnostics in `test/server.test.ts`.
