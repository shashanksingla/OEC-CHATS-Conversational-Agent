# Provider View Catalog

This is the canonical provider-facing table catalog. Each response owns one active view and one primary table. A drill-down replaces its parent table and preserves the verified provider, period, child, authorization, county, filters, freshness, and rule scope.

## Attendance views

### `ATTENDANCE_RISK_SUMMARY` / `attendance-risk`
- Default starting view for greetings and attendance-risk requests.
- Shown proactively before payment composition.
- Columns: child, county, risk issue, affected days, deadline or confirmation state, and payment implication when verified.
- Follow-ups: date detail, county rollup, or a payment view only when requested or explicitly selected.

### `ATTENDANCE_DATE_DETAIL` / `attendance-date-detail`
- Child/date drill-down for absence limits, pending confirmations, incomplete attendance, or highest-impact attendance review.
- Columns: child, authorization display name when safe, county, service date, attendance type, attended hours, scheduled hours, and the relevant risk or payment status.
- Replaces the attendance summary; do not repeat the parent summary table in the same response.

### `ATTENDANCE_COUNTY_ROLLUP` / `attendance-county-rollup`
- Attendance-only county comparison requested from an attendance view.
- Columns: county, children, risk children, and the risk-specific measure such as pending confirmations, absence days, or incomplete days.
- Do not mix payment amounts into this table.

## Payment views

Payment views are request-driven. They must not appear in the initial attendance view unless the provider asks for payment information or selects a payment action.

### `NEXT_UPCOMING_PAYOUT` / `payout-summary`
- Shows only the next unpaid or upcoming payout identified from verified service-period data.
- Columns: service period, payout date, status, expected or calculated amount, and at-risk amount when verified.

### `PAYOUT_LEDGER` / `payout-ledger`
- Shows multiple verified service periods when the provider asks for a payout history or ledger.
- Columns: service period, payout date, status, expected or calculated amount, and at-risk amount when verified.
- The next action opens the nearest unpaid or upcoming period as the single-period payout view.

### `PAYMENT_CATEGORY_ROLLUP` / `payment-category-rollup`
- Payment composition requested for the active service period or date range.
- Columns: category, children or contracts represented, care hours or units, expected amount, at-risk amount, and potential amount where applicable.
- Categories remain distinct; do not merge expected, at-risk, conditional, vacant-slot, or excluded-day amounts.

### `PAYMENT_COUNTY_ROLLUP` / `payment-county-rollup`
- County payment comparison requested from a payment view.
- Columns: county, children served, care hours, expected amount, and at-risk amount.
- County names are display values only; never expose county IDs.

### `VACANT_SLOT_ROLLUP` / `vacant-slot-rollup`
- Vacant-slot payment detail requested from a payment view.
- Columns: county or safe contract label, eligible days, rate basis when verified, and potential amount.
- Keep vacant-slot amounts separate from child payment totals.

### `SUB_PAYMENT_SUMMARY` / `sub-payment-summary`
- Summary of sub-payment records requested for a service period.
- Columns: safe payment label, service period, status, expected or settled amount, and relevant dates.
- Do not expose payment IDs or raw source identifiers.

### `SUB_PAYMENT_DETAIL` / `sub-payment-detail`
- Child/service-date detail opened from a payment summary or excluded-day review.
- Columns: child, safe authorization display name, county, service date, attendance type, hours, expected amount, at-risk amount, and exclusion reason when applicable.
- Replaces the parent payment table and preserves its locked filters.

### `CURRENT_SERVICE_PERIOD_FORECAST` / `forecast-date-detail`
- Current service-period forecast requested by the provider.
- Columns: child, county, service date, attendance type, forecast basis, attended or scheduled hours, expected amount, and at-risk amount when verified.
- Label projected values as potential or forecasted; never present them as settled payment.

## Navigation rules

- Every active view carries its `viewId`, `tableId`, table title, one-sentence table description, locked scope, source freshness, and rule version when available.
- Actions carry the source view, target view, and locked view state. A return action targets the parent view; a detail action never silently widens scope.
- If a source cannot support a table, omit that table and explain what is unavailable. Attendance findings remain available when payment history is unavailable.
- Natural-language requests and action controls use the same guarded transitions.
