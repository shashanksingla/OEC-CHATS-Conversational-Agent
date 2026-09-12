# Provider View Catalog

This is the canonical provider-facing table catalog. Each response owns one active view and one primary table. A drill-down replaces its parent table and preserves the verified provider, period, child, authorization, county, filters, freshness, and rule scope.

## Locking and permission rules (applies to every view)

These three rules are shared by every view below; they are stated once here instead of being repeated per view.

**Locked scope dimensions (frozen on drill-down):** provider identity, the resolved service period or date range, and any child/authorization/county filter already applied when the drill-down was opened. A follow-up action may narrow these further (add a named child, request the next detail page) but must never widen, replace, or drop them. Only `detailPage`/`detailPageSize` may be added on top of a stored `contextRef`/`actionRef` reference; anything else is scope-widening and is rejected (see `conversation-context.ts`).

**Allowed follow-up transitions:** each view's own "Follow-ups" line below names the only views it may transition to. A transition is either (a) a listed follow-up view, (b) a return to the immediate parent view, or (c) a natural-language narrowing of the same view's existing rows (a named child, county, authorization, or page). No view may jump directly to an unlisted view.

**Categorically unavailable actions (always "no", stated once, not per-view):** `confirm`, `submit`, `edit`, `approve`, `update`, or any other record-mutating action never appears as an action label or offered next step in ANY view, regardless of what the underlying data shows. Parent confirmation happens in the parent portal; payment submission/approval happens in the county system; this agent is read-only end to end. If a provider asks for one of these, decline plainly and name where the real action happens — never a silent no-op.

## Attendance views

### `ATTENDANCE_RISK_SUMMARY` / `attendance-risk`
- Default starting view for greetings and attendance-risk requests.
- Shown proactively before payment composition.
- **County-summary-first**: an unscoped riskFocus request (no named child or county) renders ONLY the county-level rollup (see `ATTENDANCE_COUNTY_ROLLUP`'s columns below) plus an interpretation sentence and a `show-affected-children` action — it does NOT render child-level rows by default. The child-level table is drill-down-only (see `ATTENDANCE_DATE_DETAIL`).
- Follow-ups: `ATTENDANCE_DATE_DETAIL` (via the `show-affected-children` action, a named child, or a named county), `ATTENDANCE_COUNTY_ROLLUP`, or a payment view only when requested or explicitly selected.
- Locked on drill-down: the resolved date scope (current-month, last-month, or explicit range) and any `riskFocus` already active.

### `ATTENDANCE_DATE_DETAIL` / `attendance-date-detail`
- Child/date drill-down for absence limits, pending confirmations, incomplete attendance, or highest-impact attendance review — reached only when the request is already scoped to a named child or named county (via the `show-affected-children` action, an explicit child name, or a `countyNames` filter). Never the default rendering for an unscoped riskFocus request.
- Columns: child, authorization display name when safe, county, service date, attendance type, attended hours, scheduled hours, and the relevant risk or payment status. For `riskFocus: "INCOMPLETE_ATTENDANCE"` specifically, this is always the day-level "Incomplete attendance detail" shape (Child/Authorization/County/Date/Missing record/Care hours at risk) — there is no separate child-rollup table for this focus.
- Replaces the attendance summary; do not repeat the parent summary table in the same response.
- Follow-ups: return to `ATTENDANCE_RISK_SUMMARY`, or a payment view when the provider explicitly asks about payment impact.
- Locked on drill-down: the parent summary's date scope, `riskFocus`, and any `childNames`/`countyNames` narrowing already applied — a follow-up may narrow to one more named child but never drop back to the unfiltered facility-wide set without an explicit new request.

### `ATTENDANCE_COUNTY_ROLLUP` / `attendance-county-rollup`
- Attendance-only county comparison requested from an attendance view.
- Columns: county, children, risk children, and the risk-specific measure such as pending confirmations, absence days, or incomplete days.
- Do not mix payment amounts into this table.
- Follow-ups: return to `ATTENDANCE_RISK_SUMMARY`, or `ATTENDANCE_DATE_DETAIL` for a named county's children.
- Locked on drill-down: the parent summary's date scope and `riskFocus`; a named-county narrowing only ever subsets the same already-fetched result, never a fresh source read.

## Payment views

Payment views are request-driven. They must not appear in the initial attendance view unless the provider asks for payment information or selects a payment action.

### `NEXT_UPCOMING_PAYOUT` / `payout-summary`
- Shows the next unpaid or upcoming payout identified from verified service-period data, plus its County payment composition breakdown (Care/Absence/Drop-in/Vacant Slot/Paid Holiday amounts) — not just a bare total.
- Columns: service period, payout date, status, expected or calculated amount, and at-risk amount when verified.
- Follow-ups: `SUB_PAYMENT_DETAIL` for this exact period's detail rows (via `CUSTOM_RANGE`, not `STATUS` — the detail behind an already-computed ledger figure must use the same evaluation mode that produced it), or `LAST_PAYOUT` on an explicit "last payout" ask.
- Locked on drill-down: this exact service period's begin/end dates. A detail request for this period may never widen to the multi-period ledger.

### `LAST_PAYOUT` / `last-payout-summary`
- Shows only the single most recently released (paid) service period, plus its County payment composition breakdown. Never a standing greeting/snapshot option — reachable only via explicit request or a grounded follow-up after Next Payout.
- Columns: service period, payout date, status (always `Paid`), and net amount. No at-risk breakdown — a released period is settled.
- Follow-ups: `NEXT_UPCOMING_PAYOUT` to see the next payout still ahead.
- Locked on drill-down: this exact released period's begin/end dates.

### `PAYOUT_LEDGER` / `payout-ledger`
- Shows multiple verified service periods when the provider explicitly names a month or range — never the default for an unscoped "upcoming payment" ask.
- Columns: service period, payout date, status, net amount (if released) or calculated amount (if not — never both on the same row), and at-risk amount when verified.
- Follow-ups: `NEXT_UPCOMING_PAYOUT` for the nearest unpaid/upcoming period as a single-period view, PLUS up to 2 additional individual periods from this same table, each offered as its own drill-down action with a dynamic date-range label (e.g. "Open 14th Sep'26-20th Sep'26 payout") — capped at 3 total action entries even when the table itself lists more periods. Selecting any of them opens that exact period's full single-period breakdown (Measure table, Payment by category, County payment composition), not just its ledger row.
- Locked on drill-down: the requested month/range that produced this ledger; a follow-up into one specific period locks to that period's own dates.

### `PAYMENT_CATEGORY_ROLLUP` / `payment-category-rollup`
- Payment composition requested for the active service period or date range.
- Columns: category, children or contracts represented, care hours or units, expected amount, at-risk amount, and potential amount where applicable.
- Categories remain distinct; do not merge expected, at-risk, conditional, vacant-slot, or excluded-day amounts.
- Follow-ups: `PAYMENT_COUNTY_ROLLUP`, `SUB_PAYMENT_DETAIL`, or `VACANT_SLOT_ROLLUP` for the same period.
- Locked on drill-down: the active service period/date range and any `childNames`/`authNames`/`countyNames` filter already applied.

### `PAYMENT_COUNTY_ROLLUP` / `payment-county-rollup`
- County payment comparison requested from a payment view.
- Columns: county, children served, care hours, expected amount, and at-risk amount.
- County names are display values only; never expose county IDs.
- Follow-ups: return to `PAYMENT_CATEGORY_ROLLUP`, or `SUB_PAYMENT_DETAIL` for a named county's children.
- Locked on drill-down: the parent payment view's exact period/range; a named-county narrowing only subsets the same already-fetched result.

### `VACANT_SLOT_ROLLUP` / `vacant-slot-rollup`
- Vacant-slot payment detail requested from a payment view.
- Columns: county or safe contract label, eligible days, rate basis when verified, and potential amount.
- Keep vacant-slot amounts separate from child payment totals.
- Follow-ups: return to `PAYMENT_CATEGORY_ROLLUP`.
- Locked on drill-down: the parent payment view's exact period/range.

### `SUB_PAYMENT_SUMMARY` / `sub-payment-summary`
- Summary of sub-payment records requested for a service period.
- Columns: safe payment label, service period, status, expected or settled amount, and relevant dates.
- Do not expose payment IDs or raw source identifiers.
- Follow-ups: `SUB_PAYMENT_DETAIL` for a named record's child/date rows.
- Locked on drill-down: the requested service period.

### `SUB_PAYMENT_DETAIL` / `sub-payment-detail`
- Child/service-date detail opened from a payment summary or excluded-day review.
- Columns: child, safe authorization display name, county, service date, attendance type, hours, expected amount, at-risk amount, and exclusion reason when applicable.
- Replaces the parent payment table and preserves its locked filters.
- Follow-ups: return to the parent payment view (`PAYMENT_CATEGORY_ROLLUP`, `NEXT_UPCOMING_PAYOUT`, or `LAST_PAYOUT`, whichever opened this detail); the next detail page when `hasMore` is true.
- Locked on drill-down: the parent view's exact period/range and any child/authorization/county filter; only `detailPage`/`detailPageSize` may be added.

### `CURRENT_SERVICE_PERIOD_FORECAST` / `forecast-date-detail`
- Current service-period forecast requested by the provider.
- Columns: child, county, service date, attendance type, forecast basis, attended or scheduled hours, expected amount, and at-risk amount when verified.
- Label projected values as potential or forecasted; never present them as settled payment.
- Follow-ups: return to `PAYMENT_CATEGORY_ROLLUP` for the same period once it has concluded.
- Locked on drill-down: the service period containing today at the time this view was opened — a later "refresh" re-resolves which period contains today, it does not silently widen the original period.

## Navigation rules

- Every active view carries its `viewId`, `tableId`, table title, one-sentence table description, locked scope, source freshness, and rule version when available.
- Actions carry the source view, target view, and locked view state. A return action targets the parent view; a detail action never silently widens scope.
- If a source cannot support a table, omit that table and explain what is unavailable. Attendance findings remain available when payment history is unavailable.
- Natural-language requests and action controls use the same guarded transitions.