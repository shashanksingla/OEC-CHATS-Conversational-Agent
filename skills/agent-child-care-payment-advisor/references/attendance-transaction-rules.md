# Attendance Transaction Rules v1

Source: attendance-rules working table provided 2026-09-05 (schedule/transaction validity, attended-hours, drop-in, anomaly, and county-level rules). Business/compliance owner: pending named sign-off; treated as approved for engineering release per current build decision, consistent with the standing practice in `references/rule-governance.md`.

Implementation: `scripts/analyze_attendance_transactions.py`. Tests: `scripts/tests/test_analyze_attendance_transactions.py`.

## Implemented rule groups

- **Schedule Validity** — deleted schedules ignored; only `CCCAP_AUTHORIZED` and `DROP_IN` schedule types processed; schedule date must fall inside the service-period window; invalid denial reason, unapproved auth status, expired auth end date, or future auth begin date force the day to `CARE_NOT_OFFERED` with zero authorized hours.
- **Authorized Hours** — `ci_authorization_hours` is the authorized-hours source of truth; a blank value means the provider was not scheduled that day (excluded, not flagged as an anomaly); the schedule's raw hours field is never used as authorized hours.
- **Transaction Validity** — only `PARENT_APPROVED` or `PENDING_PROVIDER` statuses count; only `result == 1` counts; a transaction must reference the schedule being processed; a transaction denied for no drop-in days remaining does not count and does not consume the drop-in allowance.
- **Transaction Type** — type 1/`CCCAP` = check-in, type 2/`CCCAP` = check-out; type 1 or 3/`DROP_IN` = drop-in check-in, type 2 or 4/`DROP_IN` = drop-in check-out; `CCCAP_NOT_AUTHORIZED` sub-type excluded; system-generated transactions use the same checks; parent-entered transactions are valid only when `PENDING_PROVIDER` or `PARENT_APPROVED`.
- **Attended Hours** — sums valid same-day transaction hours; falls back to the schedule's raw hours field only for an unpaired check-in; caps at 24 hours per day and flags when capped; an attended flag with no surviving valid transactions is a data-quality flag, not an invented value; drop-in days count only drop-in transaction hours.
- **Drop-In Rules** — a day is a drop-in day if the schedule type is `DROP_IN` or any valid transaction sub-type is `DROP_IN`; a schedule already denied for no drop-in days remaining is `NOT_PAID`; attended hours on a drop-in day classify into a tier (`PART_TIME`, `FULL_TIME`, `FULL_TIME_PLUS_PART_TIME`, `FULL_TIME_PLUS_FULL_TIME`) using the same hour boundaries as the existing unit-of-care classification.
- **Anomalies** — unpaired check-in without a raw-hours fallback is flagged; a mismatched check-in/check-out count on the schedule is flagged; a multi-restriction flag is surfaced for manual review without blocking payment; historical/previous-only transactions are excluded from attendance and flagged.
- **County - Absence** — absence days are tracked per child against the effective county/tier absence limit; each day is classified as within limit or over limit; a day one absence away from the limit is flagged proactively.
- **County - Over-Attendance** — attended hours exceeding authorized hours are flagged with the excess amount; more than three over-attendance days in the period flags the child for authorization review.
- **County - Unconfirmed Attendance** — provider-submitted, parent-unconfirmed attendance still counts toward attended hours but is flagged; more than half the child's days in the period being unconfirmed flags the child for supervisor review.
- **County - Drop-In Limits (facility-scoped)** — a per-authorization (this facility's child+county) drop-in day counter is tracked against the effective county drop-in day limit; the day that reaches the limit is flagged as nearly exhausted; days beyond the limit are `NOT_PAID`.
- **County - Summary (facility-scoped)** — per-county and per-child aggregate counts are returned for this provider's own children only.

## Deliberately not implemented

See `UNIMPLEMENTED_RULES` in `scripts/analyze_attendance_transactions.py` for the machine-readable list returned with every result. In summary:

- Overnight schedules spanning midnight are not split across two calendar days (needs confirmed raw timestamp fields).
- Orphan transactions are not matched to a synthetic schedule entry (needs a confirmed matching key).
- Orphan drop-in transaction handling is deferred with the above.
- The 36-month enrollment-absence exception is not encoded: the transcribed rule rows contradict each other on which age band is `Not Payable` versus a still-payable `Enrollment Absence`. This needs business clarification before any age-conditioned payment rule is enabled.
- County-wide drop-in pool exhaustion and county-wide summary totals are not implemented, because a single provider's authorized dataset cannot see other providers' usage in the same county. Only this facility's own children are aggregated.

## Data this module expects

Normalized schedule and transaction objects as documented in the module's own module-level docstring and test fixtures. `mcp/cccap-provider-api` maps `getSchedules.Attendance__r.records` into the transaction contract when those fields are returned. Aggregate `Check_In_Count__c`/`Check_Out_Count__c` values remain an anomaly signal, not a substitute for complete transaction attributes. Missing or incompatible transaction fields remain a per-record data-quality blocker.
