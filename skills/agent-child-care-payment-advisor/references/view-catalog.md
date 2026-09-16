# Provider View Catalog

This is the canonical provider-facing table catalog. Each response owns one active view and one primary table. A drill-down replaces its parent table and preserves the verified provider, period, child, authorization, county, filters, freshness, and rule scope.

## Locking and permission rules (applies to every view)

These three rules are shared by every view below; they are stated once here instead of being repeated per view.

**Locked scope dimensions (frozen on drill-down):** provider identity, the resolved service period or date range, and any child/authorization/county filter already applied when the drill-down was opened. A follow-up action may narrow these further (add a named child, request the next detail page) but must never widen, replace, or drop them. Only `detailPage`/`detailPageSize` may be added on top of a signed `actionToken` (see `continuation-token.ts`) - the token embeds its own scope/tool/expiry and is verified by signature, not by a server-side lookup, so it survives process restarts; anything beyond the additive keys is scope-widening and is rejected.

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
- Child/date drill-down for absence limits, pending confirmations, incomplete attendance, or highest-impact attendance review — reached only when the request is already scoped to a named child or named county (via the `show-affected-children` action, an explicit child name, or a `countyNames` filter). Never the default rendering for an unscoped riskFocus request. **Exception**: `riskFocus: "PARENT_CONFIRMATIONS"` always renders its own two-table shape (see below) even when unscoped, because pending confirmations is exclusive-by-design.
- **Exclusivity contract**: every table in this view shows only its own `riskFocus`'s columns — a response never surfaces another risk area's counts. Concretely:
  - `riskFocus: "ABSENCE_LIMITS"` — Attendance overview is Scheduled days/Affected children/Absence days/Excluded holidays (no Pending confirmations column). Child rows are Child/Authorization/County/Absences used/County limit. This is the one focus with **real pagination**: the complete affected-child list pages through `detailPage`/`detailPageSize` (default page size 10), reported as "Showing children X-Y of Z (page N; page size S)" with a "next page" action when more remain — not a capped "first N, ask by name" preview.
  - `riskFocus: "PARENT_CONFIRMATIONS"` — always renders exactly two tables, in this order: (1) a county-level table of total pending-confirmation counts (top 4 counties by pending count), then (2) the top 3-4 children by pending-confirmation count (Child/Authorization/County/Pending/Deadline/Days left). No Absence days column anywhere in this focus's tables.
  - `riskFocus: "INCOMPLETE_ATTENDANCE"` — always the day-level "Incomplete attendance detail" shape (Child/Authorization/County/Date/Missing record/Care hours at risk); its overview and county tables use Incomplete days only, never Pending confirmations or Absence days.
  - A named child/child-list request with **no** `riskFocus` renders up to three separate exclusive tables (Absence-limit detail, Pending parent confirmation detail, Incomplete attendance detail) scoped to just those children, one per risk area actually present — never one merged table.
- **County-level context always on**: the county rollup table (severity-sorted, top-4 capped) renders for every riskFocus-scoped response REGARDLESS of how the child list got narrowed — a named child, the full "show affected children" list, or unscoped. This gives a holistic per-county view alongside any child-level detail. Only the facility-wide "Attendance overview" line stays suppressed once scoped to named child(ren) — restating facility totals for one child reads oddly, but the county breakdown remains useful context.
- **Highest-impact detail is always the complete 3-table view**: `open-attendance-detail`'s input explicitly clears `riskFocus`, so it never stays narrowed to whichever single risk area the current response happened to be scoped to — it always resolves to the child-scoped multi-risk view above, showing every risk area present for that one child. This applies whether reached from an attendance response or from a payment response's cross-capability `open-attendance-risk-for-child` action.
- Replaces the attendance summary; do not repeat the parent summary table in the same response.
- Follow-ups: return to `ATTENDANCE_RISK_SUMMARY` only (via `return-to-attendance-summary`, which is `section: "return"` — always rendered last, never capped) — a riskFocus-scoped response never links to a *different* risk area's review; that cross-navigation is offered only from the unscoped `ATTENDANCE_RISK_SUMMARY` itself, and always in the order the summary table lists the risk rows (Pending confirmations -> Absence limits -> Missing check-ins/check-outs). A payment view is offered only when the provider explicitly asks about payment impact.
- Locked on drill-down: the parent summary's date scope, `riskFocus`, and any `childNames`/`countyNames` narrowing already applied — a follow-up may narrow to one more named child, or page forward via `detailPage`/`detailPageSize` (ABSENCE_LIMITS only), but never drop back to the unfiltered facility-wide set without an explicit new request.

### `ATTENDANCE_COUNTY_ROLLUP` / `attendance-county-rollup`
- Attendance-only county comparison requested from an attendance view.
- Columns: county, children, risk children, and the risk-specific measure such as pending confirmations, absence days, or incomplete days.
- Do not mix payment amounts into this table.
- This standalone "compare all counties" view is uncapped and shows every county. Contrast with the same county table embedded *inside* a `riskFocus`-scoped `ATTENDANCE_DATE_DETAIL` response, which ranks by that focus's severity metric (children over limit, then absence days, for ABSENCE_LIMITS; pending-confirmation days for PARENT_CONFIRMATIONS; incomplete days for INCOMPLETE_ATTENDANCE) and caps to the top 4 counties.
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
- **Service-period rollup first, county composition as the next step**: this table itself never carries a county-level breakdown (that would restate every period's composition inline). Instead, `view-county-composition-for-range` is offered as its own follow-up action, aggregating Care/Absence/Drop-in/Vacant Slot/Paid Holiday amounts by county across the FULL requested range (via `CUSTOM_RANGE` + `grouping: "COUNTY"`) — matching the requested ordering of period rollup first, county detail next. This structure applies only when the ledger is genuinely multi-period; a single-period ledger response already shows composition inline (see `NEXT_UPCOMING_PAYOUT`/`LAST_PAYOUT` above) and needs no separate action.
- Follow-ups: `NEXT_UPCOMING_PAYOUT` for the nearest unpaid/upcoming period as a single-period view, PLUS up to 2 additional individual periods from this same table, each offered as its own drill-down action with a dynamic date-range label (e.g. "Open 14th Sep'26-20th Sep'26 payout"), PLUS `view-county-composition-for-range` — capped at 3 period-level entries even when the table itself lists more periods (the county-composition action is separate from this cap). Selecting a period action opens that exact period's full single-period breakdown (Measure table, Payment by category, County payment composition), not just its ledger row.
- Locked on drill-down: the requested month/range that produced this ledger; a follow-up into one specific period locks to that period's own dates; the county-composition follow-up locks to the full ledger range's earliest begin date through latest end date.

### `PAYMENT_CATEGORY_ROLLUP` / `payment-category-rollup`
- Payment composition requested for the active service period or date range.
- Columns: category, children or contracts represented, care hours or units, expected amount, at-risk amount, and potential amount where applicable.
- Categories remain distinct; do not merge expected, at-risk, conditional, vacant-slot, or excluded-day amounts.
- **Vacant-slot counts render by default** for a date/period-scoped summarization (not just via the dedicated `VACANT_SLOT_ROLLUP` follow-up): a separate by-county Total days/Total amount table appears directly after the category table whenever the response isn't a single-child or excluded-only view. Vacant slots are a contract-level payment scenario independent of any child's attendance, so this table is never merged into the category or child rollups.
- Excluded from a single-child (`childNames` resolving to exactly one child) drill-down and from an excluded-days-only review — vacant-slot amounts aren't tied to any one child's attendance and aren't a "why didn't this day pay" answer.
- The "Child detail:" table carries an additional "Attendance risk" column, a short tag (Absence, Pending confirmation, Incomplete attendance, or None) derived from this same response's own day-level flags — a quick signal without requiring the extra hop. A cross-capability `open-attendance-risk-for-child` action (tool `cccap_analyze_payment_risk`, no `riskFocus`) is offered alongside the payment child-detail action so a provider can open the complete 3-table attendance-risk breakdown for that same child.
- Follow-ups: `PAYMENT_COUNTY_ROLLUP`, `SUB_PAYMENT_DETAIL`, `VACANT_SLOT_ROLLUP` for the full day-by-day vacant-slot breakdown of the same period, or the cross-capability attendance-risk detail above.
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