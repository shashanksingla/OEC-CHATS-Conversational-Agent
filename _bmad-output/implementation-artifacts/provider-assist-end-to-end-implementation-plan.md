# Provider Assist End-to-End Implementation Plan

Status: approved for implementation
Date: 2026-09-12
Scope: payment, payout, attendance, table hierarchy, clarification, smart actions, and conversation continuity

## 1. Non-negotiable boundaries

- Keep the system read-only and provider-scoped. Provider identity comes from MCP initialization, never model input.
- Preserve server-side provider, county, authorization, and relationship validation.
- TypeScript owns schemas, source mapping, normalization, orchestration, continuation resolution, and safe formatting.
- Python owns deterministic attendance classification, thresholds, dates, counts, and money calculations.
- Unknown, missing, conflicting, stale, or ambiguous required data fails closed as blocked or unavailable. Never guess.
- `content[0].text` is the complete provider-facing response. Structured content contains only compact routing state, scope, pagination, and opaque controls.
- Do not expose raw Salesforce IDs, provider IDs, authorization IDs, case IDs, tokens, request bodies, or family data.

## 2. Locked response hierarchy

Every successful data-backed response uses this order, omitting only sections with no grounded content:

1. Interpretation: one plain-language conclusion and why it matters.
2. Scope: visible period/date header and resolved entity filters.
3. Glance strip when both attendance and dollars exist: scheduled/checked-in, pending confirmations, amount at risk.
4. Primary aggregate facts table.
5. Impact explanation from deterministic output.
6. Priority Actions: no more than the most relevant two active actions, numbered from 1 for that response.
7. Drill down: explicit grounded controls only.
8. Available views: optional views, never a replacement for active-risk actions.
9. Context-specific next-step sentence, never a generic repeated menu.

Payment amounts use `~ $` only for the facility-wide headline estimate. Other table amounts are plain values. Use `expected`, `forecasted`, `calculated`, or `at-risk`; never call a dollar amount confirmed or guaranteed.

## 3. Locked table contracts

### 3.1 Next payout and payout ledger

- The stable entry point is a payout ledger, even when it has one row.
- One row per service period, including multi-period payouts.
- Columns: Service period, payout/release date, status, net amount, calculated amount, and at-risk amount.
- The top summary is period-level, not child-level.
- Every row action locks the selected service-period identity and cannot widen to all periods.
- Drill-down from a ledger row opens only that service period's payment summary or detail.
- A single-period result uses the same ledger contract with one row.
- Never show raw service-period IDs.

### 3.2 Payment summary and composition

- Aggregate payment summary appears before any child/date rows.
- Group summary rows by county, payment category/tier, applied rate, and attendance basis.
- Include children served, scheduled/care/attended hours as applicable, expected/calculated amount, conditional amount, and at-risk amount where supported.
- Separate actual confirmed/past contributions from scheduled future forecast contributions.
- County composition includes children served and only nonzero payment categories.
- Vacant-slot amount is facility-level; a single-child view uses drop-in amount instead.
- Excluded authorizations remain visible through counts/status and excluded-day detail but never enter payable totals.
- Empty filter results are valid zero/empty summaries, not errors.
- Detail columns use plain-language attendance types. Include scheduled hours, attended hours, and care hours in per-day detail.
- Authorization is omitted from default payment detail and shown only when explicitly requested, except where an attendance risk table requires it.

### 3.3 Payment detail

- Detail is explicit, never an automatic preview in an aggregate summary.
- Child/date rows include child, county, date, attendance type, scheduled hours, attended hours, care hours, and relevant amount/reason fields.
- Excluded absence rows say `Absence [excluded reason]`, not `Absence (paid)`.
- Omit zero-only numeric columns and redundant one-row tables that merely restate the preceding aggregate.
- Pagination preserves period, child, county, authorization, view, and filters.

### 3.4 Attendance risk summary

- Facility/risk summary is aggregate-first and does not contain child/date previews.
- Risk table uses `Risk Area`, `Verified finding`, and `Potential Loss (Care Hours)` where appropriate.
- Greeting snapshot has exactly three risk rows: pending confirmations, children near/over absence limits, and missing check-ins/check-outs.
- Do not add generic Attendance, Payments, Unavailable, or Required measure unavailable rows.
- Absence-limit summary does not add an `Over limit` column.

### 3.5 Attendance drill-down

- Child-level tables include authorization when the capability requires it.
- Absence-limit detail columns: Child, Authorization, County, Absences used, County limit.
- Parent-confirmation detail uses only issue-relevant numeric columns: pending, outside window, over limit, and estimated risk when available.
- Incomplete attendance detail columns: Child, Authorization, County, Date, Missing record, Care hours at risk.
- `Missing record` explicitly says missing check-in, missing check-out, or both.
- Child-date tables are one row per child-date and never repeat the facility or county rollup below them.
- County absence rollups compare each child's own limit; do not compare a county day sum to one child's limit.

### 3.6 County and category tables

- County payment rows show children served and only requested/capability-supported measures.
- County absence policy shows approved limit or `Multiple`, children over limit, and status.
- Category/rate rows preserve distinct rates and never average incompatible authorization rates.
- Household, authorization display names, and long service-date lists appear only when explicitly requested; compact them when shown.

## 4. Clarification and routing gates

Before every data call, resolve capability, entity, time, filters, requested view, and freshness.

Ask one concise clarification and make no data call when any of these is ambiguous:

- Child identity or multiple matching children.
- Authorization identity or multiple matching authorizations.
- County identity or county outside verified provider scope.
- Service period, date range, relative date, or multiple matching periods.
- Requested grouping or detail depth for a custom payment summary.
- Whether the provider means payment status, attendance risk, policy, payout ledger, or source diagnostic.

Never infer a filter from a similar name, prior unrelated result, row index, or broad tool availability. Explicit widening from child/county/period scope requires provider intent. A broad request such as `everything` asks the provider to choose a supported view instead of creating a dashboard.

Supported custom payment summary inputs are explicit: service period or date range, countyNames, childNames, authNames, grouping (`SERVICE_PERIOD`, `COUNTY`, `CHILD`, `CATEGORY`), and detail depth. Missing grouping when multiple groupings are reasonable requires clarification.

## 5. Result graph and continuation model

Treat each response as a node in a provider-scoped result graph:

- Root result: current intent, capability, normalized scope, selected period/date range, severity, freshness, rule version, top finding, available evidence, and current view.
- Child result: parent context reference, scope delta, target view, selected entity/period, inherited evidence, and new evidence.
- Parent navigation restores the stored parent result; it does not reconstruct filters from prose.
- Narrowing and detail deepening inherit verified state. Widening creates an explicit scope transition and requires provider language.
- Comparison retains both bounded scopes.
- Expired, incompatible, stale, or restarted contexts fail closed.
- A context reference never authorizes a capability other than its stored capability unless a cross-capability action explicitly carries the bounded originating reference and the target validates it.

The stored context tracks shown, selected, completed, superseded, hidden-by-scope, and expired actions. Every action carries source view, target view, locked scope, selected period/entity, provenance, and an opaque reference.

## 6. Smart action engine

Implement action processing as four deterministic stages:

1. Candidate generation from verified findings and available evidence.
2. Eligibility checks for current scope, view, freshness, severity, and required evidence.
3. Scope-aware deduplication and suppression against shown/completed actions and current view.
4. Ranking by payment impact, severity, deadline, and source recovery value, followed by rendering.

Rules:

- Maximum two priority actions in a response.
- Active risk action precedes optional view actions.
- Do not repeat the action just selected.
- Do not offer highest-impact-child from a single-child result.
- Do not offer facility-wide county comparison from a county or child result unless requested.
- Detail pages show only next page and return-to-summary actions.
- Blocked results show retry/source-data actions only.
- Inherited actions are not automatically re-exposed; retain them for navigation and expose again only when explicitly requested and still relevant.
- Final prose is derived from the current result and action state, not a fixed generic sentence.

## 7. Implementation order

1. [x] Fix the remaining protocol assertion based on actual schedule-read behavior, then run the focused protocol test.
2. [x] Add typed result-graph metadata and parent/child continuation transitions in `conversation-context.ts`, `server.ts`, and `view-state.ts`.
3. [ ] Centralize action candidate eligibility, suppression, lifecycle state, ranking, and rendering; shared rendering, deduplication, and selected-action tracking exist, but not one complete engine.
4. [x] Make `NEXT_PAYOUT` use the multi-period ledger entry point while preserving one-row behavior for a single period.
5. [x] Add formal custom payment summary schemas, resolver gates, explicit grouping, and scoped drill-down actions.
6. [x] Add incomplete-attendance child/date rows and missing-record classification.
7. [x] Reconcile fee-history authorization filtering and skill/action-label documentation; historical ART reconciliation remains unsupported without source data.
8. [ ] Rebuild generated MCP output and run live `NEXT_PAYOUT` smoke validation.
9. [x] Run full TypeScript, MCP, Python, architecture lint, and diff checks.

## 8. Acceptance and regression matrix

- Aggregate payment summary precedes detail and contains no child/date preview.
- Multi-period payout has one summary row per service period.
- Ledger-row drill-down cannot widen service-period scope.
- Child/auth/county filters preserve totals and detail scope.
- Ambiguous child, authorization, county, period, grouping, or detail request makes zero data calls.
- Actual and scheduled forecast contributions remain separate.
- Excluded rates remain visible but excluded from payable totals.
- Authorization appears in required attendance child tables.
- Incomplete attendance identifies missing check-in, check-out, or both.
- Selected actions do not reappear in the child result.
- Single-child, county, detail, and blocked results suppress irrelevant actions.
- Parent navigation restores the exact prior verified result.
- Expired, incompatible, or restarted references fail closed.
- Refresh bypasses cache and creates fresh context.
- Provider-safe text contains no raw identifiers or source diagnostics.

## 9. Validation commands

- `npm test`
- `npm run typecheck`
- `npm run build`
- `python -m unittest discover -s skills/agent-child-care-payment-advisor/scripts/tests`
- `uv run ./.agents/skills/bmad-architecture/scripts/lint_spine.py --workspace _bmad-output/planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08`
- `git diff --check`
- Rebuild MCP generated output and run a live `cccap_analyze_payment` `NEXT_PAYOUT` smoke test.
