# Provider Assist — 360° Redesign Handoff

**Audience**: the agent builder implementing this directly against the codebase described in `PROVIDER_ASSIST_SYSTEM_ARCHITECTURE.md`.

**Status**: This document **supersedes** `Improvement to be done/childcare-agent-improvement-spec.md` — every idea from that spec is carried forward here, re-scoped against the real files, module boundaries, and governance rules (`skills/ARCHITECTURE.md`) of the actual system. Do not implement from the old spec directly; its table/tier designs are correct, but the concrete file/field mappings below are authoritative.

**Constraint carried through every workstream**: system stays **strictly read-only**. No workstream below introduces a write-capable tool. `readOnlyHint: true` remains correct on every tool, including new ones.

---

## 0. Decisions locked before this doc was written

| Decision | Outcome |
|---|---|
| Write capability | Stay strictly read-only. No exceptions. |
| Next-action ranking | Move to a **hybrid dollar + deadline-urgency** weighted formula (Workstream 2), replacing fixed priority bands. |
| contextRef/actionRef persistence | Stay in-memory, process-local. No persistence layer added. Restart-invalidation remains a known, accepted tradeoff. |
| "Confirmed" terminology | Retire only from **payment-dollar labels** (→ `Expected`/`Guaranteed`/`At Risk`/`Forecasted`). Keep `Confirmed` as the attendance-transaction status (`PARENT_APPROVED` → `CONFIRMED`) — that's a true completed fact, not a money prediction. |
| Payout calendar (weekly ledger / monthly rollup / holiday waterfall) | **Full build, in scope now** (Workstream 3). This is new engineering, not a wording change — treat it as such in planning/estimation. |
| "True comparison" capability | Build **period-over-period** first (this cycle vs. last). County-vs-county deepening is a later pass. |

Defaults added by this review (flag if you want any changed):
- Add an automated eval assertion closing the "highest-impact label doesn't match its own table's max" bug class (Workstream 5) — this class of bug is exactly what triggered this whole review and currently has zero automated coverage.
- Add a canonical vocabulary/synonym governance doc, same pattern as the existing `action-labels.md` registry, to end the `amount_at_risk`/`at_risk_amount`/`conditional_amount`/`potential_impact` fragmentation flagged in Section 11 of the architecture doc (Workstream 1).
- Extend deadline surfacing from the attendance engine to the payment engine (Workstream 6) — required for the Workstream 3 payout countdown to have real data to render.

### Already implemented — do not rebuild, only preserve

These items from the original improvement spec are confirmed already live in the current system (per the architecture doc's Section 4.1). None of the workstreams below touch them; treat any regression in these as a bug against this handoff, not a feature to re-add:
- Bottom-line-first sentence before any table.
- Mandatory one-line period header (`Payout period: ...` / `Attendance period: ...`).
- Deduplicated shared-legend sentence in drill-down tables (not per-row repeated prose).
- CCCAP jargon glossary, glossed once per session.
- "Needs your attention today" triage list (2–3 items, ranked by dollar impact then urgency) before detail tables.
- Per-figure disclaimer qualifier next to the headline dollar amount (the exact wording is upgraded by Workstream 1.3, but the *placement pattern* already exists and should be reused, not reinvented).

---

## Sequencing (do not build out of order)

```
Workstream 0 (formatter split)  ──┐
                                    ├──> Workstream 3 (payout calendar) ──> Workstream 6 (deadline parity)
Workstream 1 (terminology)  ───────┘
Workstream 2 (ranking)  ─────────────────────────────────────────────────> independent, parallel-safe
Workstream 4 (comparison)  ────────────────────────────────────────────── depends on Workstream 0
Workstream 5 (regression)  ───────────────────────────────────────────────  add incrementally as each workstream lands
Workstream 7 (documentation of unfixable host chrome)  ─── do anytime, no code dependency
```

Workstream 0 must land first — every other workstream adds a new formatter, and `server.ts` is already ~1990 lines owning all rendering for every capability. Adding three new formatters (payout calendar, comparison, updated risk table) into that single file compounds the exact merge-conflict/blast-radius risk Section 11 already flags.

---

## Workstream 0 — Split `server.ts` into per-capability formatters (prerequisite)

**Objective**: extract rendering logic out of the single 1990-line file without changing behavior, so Workstreams 3 and 4 can add formatters safely.

**Tasks**:
1. Create `mcp/cccap-provider-api/src/formatters/` with `payment-formatter.ts`, `attendance-formatter.ts`, `snapshot-formatter.ts`, `cases-formatter.ts`, `authorizations-formatter.ts`, `county-policy-formatter.ts`.
2. Move each named formatter function (`formatPaymentResult`, `formatAttendanceRiskResult`, `formatCasesResult`, `formatAuthorizationsResult`, `formatCountyPolicyResult`, and the snapshot formatter) into its matching file, verbatim, no logic changes.
3. `server.ts` retains only tool registration and imports formatters from `./formatters/*`.
4. Re-run the full `npm test` and `npm run typecheck` suites — this must be a zero-behavior-change refactor. Any diff in rendered output is a bug in the extraction, not an intended improvement (those come in later workstreams).

**Definition of Done**: `server.ts` under ~300 lines (registration only); all existing TS tests pass unchanged; `npm run smoke*` scripts produce byte-identical output to pre-refactor baseline.

---

## Workstream 1 — Terminology & canonical vocabulary

### 1.1 Retire "Confirmed" from payment-dollar labels only

Update `carepay-conversation-templates/SKILL.md`'s column-naming standard:

| Old | New | Scope |
|---|---|---|
| `Confirmed amount` | `Expected amount` | Payment Template, all payout tables |
| `Conditional amount` | `At-risk amount` | Payment Template, all payout tables |
| *(new)* | `Guaranteed amount` | For Vacant Slot / correctly-classified Paid Holiday (Workstream 3) |
| `Confirmed` (attendance transaction status) | **unchanged** | Glossary entry for parent-verification fact — this one stays |

Update the glossary in the architecture doc / skill references to make this distinction explicit, since it's the exact kind of thing a future contributor will get wrong without a written rule: *"'Confirmed' describes a completed parent action. It never describes a dollar amount."*

### 1.2 Canonical vocabulary governance doc

Create `skills/agent-child-care-payment-advisor/references/vocabulary.md`, structured identically to `action-labels.md` (single source of truth, both TS and Python must render from it).

Minimum required entries, resolving the exact fragmentation Section 11 names:

| Internal field(s) found in code | Canonical provider-facing term | Canonical internal field name (target) |
|---|---|---|
| `amount_at_risk`, `at_risk_amount`, `conditional_amount`, `potential_impact` | "At risk" | `at_risk_amount` (pick one, migrate the others) |
| `total_amount` (payment engine) | "Total" / "Expected" depending on classification | unchanged, just document |
| `net`/`gross` (existing payout summary) | Keep, but always paired with the Expected/Guaranteed/At-Risk/Forecasted breakdown beneath it — never shown alone (this was the original $0-vs-$57K bug) | unchanged |

**Task**: audit every Python evaluator output field and every TS formatter's rendered word choice against this table; migrate field names that have no principled reason to differ (bump `rule_version` on any evaluator field-name change, per `rule-governance.md`).

**Definition of Done**: no two files in the repo use two different field names for the same concept without `vocabulary.md` explicitly declaring which is canonical and which is deprecated-but-present-for-migration.

### 1.3 Calibrated disclaimers (drop-in replacement)

Replace any single blanket disclaimer with per-status variants, attached next to the figure they qualify, not only as a closing footnote:

```javascript
// Global disclaimer — use once per full response, as a closing line
export const DISCLAIMER_GLOBAL =
  "⚠️ *Figures reflect the system's current data and are not an official payment notice. " +
  "Only your county portal or remittance advice is authoritative.*";

// Per-status disclaimers — attach directly next to the figure they qualify
export const DISCLAIMER_EXPECTED =
  "*Expected, based on current system data — may still change if the county issues a correction.*";

export const DISCLAIMER_FORECASTED =
  "*Forecasted from scheduled and partial attendance data — will change as the period completes.*";

export const DISCLAIMER_AT_RISK =
  "*Could be reduced or excluded if unresolved before [deadline].*"; // interpolate confirm_by_date (Workstream 6) — never leave this generic

export const DISCLAIMER_GUARANTEED =
  "*Paid per your county contract regardless of occupancy or attendance.*"; // no hedge language — this one should read as certain, not estimated
```

Do not add "may change" hedge language to `DISCLAIMER_GUARANTEED` for stylistic consistency with the others — that would undo the Guaranteed-vs-Attendance-Dependent distinction from Workstream 3.1. Wire these into `carepay-conversation-templates/SKILL.md`'s per-figure disclaimer rule (already established this cycle) so it renders the correct variant based on each figure's classification, rather than one generic string everywhere.

---

## Workstream 2 — Hybrid ranking for `next_action_ranking.py`

### Formula

Replace the fixed priority bands (`_PAYMENT_IMPACT_BASE = 3000`, `_URGENCY_BASE = 2000`, `_SOURCE_RECOVERY_BASE = 1000`) with a continuous, explainable score:

```python
URGENCY_WEIGHT = 5  # tunable — validate against real conversation data before shipping; treat like the other hardcoded constants in Section 7's inventory, document it there too

def rank_score(dollar_amount_at_risk: float, days_remaining: int) -> float:
    days_remaining = max(days_remaining, 1)  # avoid div-by-zero / overweighting same-day items to infinity
    urgency_multiplier = 1 + (URGENCY_WEIGHT / days_remaining)
    return dollar_amount_at_risk * urgency_multiplier
```

This means a $1,000 item due tomorrow (`multiplier ≈ 6`) outranks a $1,000 item due in 10 days (`multiplier = 1.5`), and a genuinely much larger dollar amount still wins even with a distant deadline, since the multiplier only ever scales the base dollar figure rather than replacing it — no fixed band can silently override a 10x dollar difference the way `+80`/`+60` point bonuses currently can.

### Critical wording rule — do not let this reintroduce the original bug class

The payment side's `highestImpactChildName` ranks children by **pure dollars** (unchanged, already fixed this cycle). This workstream's hybrid formula ranks **actions**, a different object, and can legitimately put a smaller, more urgent item first. That's fine — but the rendered text must never claim "highest impact" for an urgency-weighted result. Reserve that exact phrase for the pure-dollar child ranking only. For the hybrid-ranked action list, use "Recommended next action" or equivalent — phrasing that doesn't imply "this is the biggest number," since it might not be.

**Tasks**:
1. Implement `rank_score` in `next_action_ranking.py`, replacing the band constants.
2. Update all 97 existing pytest fixtures that assert on ranking order where band logic previously determined output; add new fixtures specifically testing the dollar-vs-urgency tradeoff (e.g. small-amount-imminent-deadline beating large-amount-distant-deadline, and the reverse).
3. Add a fixture-driven cross-check: given the same underlying risk item, confirm the wording used by `next_action_ranking.py`'s output never contains "highest impact" or "biggest" language — grep-testable in a unit test, not just a style guideline.
4. Update Section 7's hardcoded-value inventory in the architecture doc to list `URGENCY_WEIGHT` alongside the constants it replaces.

**Definition of Done**: all 97+ new tests pass; a manual transcript check confirms no response claims "highest impact" language next to an urgency-weighted (not pure-dollar) result.

---

## Workstream 3 — Payout calendar (full build)

This is the largest workstream. It replaces the flat `STATUS/NEXT_PAYOUT/CURRENT_WEEK_FORECAST/CUSTOM_RANGE` view model with a proper multi-period ledger, per the earlier spec's Tier 1–3 design, now mapped to real files.

### 3.-1. Where the original Tier 1/2/3 table architecture already lives (read this before assuming anything is missing)

The earlier spec's three-tier design (Payout Reconciliation Summary / Category & County Breakdown / Risk & Action Triage) is **not a net-new structure to build** — it already exists in compatible shape inside the real system, and this workstream extends it rather than replacing it:

| Original tier | Already exists as | What this workstream adds |
|---|---|---|
| Tier 1 — Payout Reconciliation Summary | `provider_risk_payment_engine.py`'s net/gross/Expected/Forecasted/At-risk breakdown | Guaranteed bucket (3.1), corrected terminology (Workstream 1) |
| Tier 2 — Category & County Breakdown | Existing category/county/child rollups in the same evaluator | Used/limit pairs split by Guaranteed vs. Attendance-Dependent (3.1) |
| Tier 3 — Risk & Action Triage | `cccap_analyze_payment_risk` + `next_actions` / action-label registry | `HOLIDAY_CLASSIFICATION_MISMATCH` risk code (3.2), hybrid ranking (Workstream 2) |
| Detail drill-down | `child_payment_impacts[]` rows + detail pagination | `confirm_by_date` field (Workstream 6) |

If an implementer reads this doc without the original spec in hand: the tiers are real, they're just fixes-in-place on existing modules rather than a parallel new table system.

### 3.0 Audit first — do not assume `CURRENT_WEEK_FORECAST` already does the right thing

Before building anything, verify against source: does `CURRENT_WEEK_FORECAST` currently blend actual check-ins with scheduled projections (as required below), or is it schedule-only? Its current exact behavior isn't documented in the architecture doc at the level needed to know. This is a required first task, not an assumption either way.

### 3.1 Category classification: Guaranteed vs. Attendance-Dependent

Confirmed already partially true in the existing system: *"Absence/drop-in/attendance-confirmation rules explicitly do NOT apply to vacant slots"* (architecture doc §4.3). Extend this explicitly to Paid Holiday and formalize it as a first-class classification, not an implicit side effect:

| Category | Type | At-risk of exclusion? |
|---|---|---|
| Care Hours | Attendance-dependent | Yes |
| Absence | Attendance-dependent | Yes — only for days correctly resolved as Absence (see waterfall) |
| Drop-in | Attendance-dependent | Yes |
| Vacant Slot | Guaranteed (contracted) | No |
| Paid Holiday | Guaranteed, once correctly classified | No financial risk; classification-order risk exists (see 3.2) |

### 3.2 Zero-attendance-day classification waterfall

Implement in `provider_risk_payment_engine.py`'s per-day classification logic, in this exact order, for any service date where attended hours = 0:
1. Check the holiday calendar (`DTE_OBSERVED_HOL__c` per existing normalizer) — if it matches, classify the day as Paid Holiday (Guaranteed).
2. Else, check for authorized hours on that date — if present, classify as Absence (Attendance-dependent, counts toward absence limit).
3. Else, check Drop-in balance and classify as Drop-in (Attendance-dependent, counts toward drop-in limit).

Add a new risk code to `evaluate_attendance_risks.py`'s risk-code enum: `HOLIDAY_CLASSIFICATION_MISMATCH` — a date matching the holiday calendar that resolved to Absence or Drop-in instead of Paid Holiday (or the reverse). Report its dollar impact as `amount_incorrectly_at_risk`, a new field distinct from genuine attendance-based `at_risk_amount` — this is a data-correction issue, not a provider action item, and must never be summed into the same total as genuine at-risk dollars.

**This requires a `rule_version` bump** (e.g. `provider-risk-payment-v2`) per `rule-governance.md`, since day classification logic is changing.

### 3.3 Payout date formula

`Payout Date = Service Period End Date (Sunday) + 11 days` — always resolves to Thursday. Implement as a single shared utility (one TS function, one Python function, both unit-tested against the same fixture dates) rather than duplicating the offset constant — this is exactly the kind of hardcoded value that belongs in Section 7's inventory table once implemented.

### 3.4 New orchestration capability: multi-period aggregation

`payment-orchestration.ts::getPaymentAnalysis` currently resolves exactly **one** service period per call. The Weekly Ledger, Monthly Rollup, and Upcoming Payout views all require resolving and aggregating **multiple** periods. This is new orchestration, not a parameter tweak:

- **Weekly Service Period Ledger**: new view `SERVICE_PERIOD_LEDGER` — resolves the last N service periods (configurable, default enough to cover the current month plus one prior), computes each period's Payout Date (3.3), and classifies each as `In Progress / Pending Confirmation / Expected, Awaiting Payout / Paid`.
- **Monthly Payout Rollup**: new view `MONTHLY_ROLLUP` — groups **by calendar month of service date**, not by week. A period straddling a month boundary must produce two truncated rows (one per month), each showing only that month's days, with a note referencing the other month's portion. This requires day-level granularity in the aggregation query — the per-day classification already exists inside the payment engine (§4.5 of the architecture doc: "Amount classification per day"), so this is a matter of exposing and grouping that existing day-level data across period boundaries, not inventing new math.
- **Upcoming Payout Detail**: filter the Weekly Ledger to the row whose Payout Date equals the next Thursday from today; lead with a countdown ("Payout in N days") — this requires Workstream 6's deadline field on the payment side.
- **This Week's Forecast**: filter to the period containing today; per-day breakdown must split `Actual (checked in)` vs. `Scheduled (projected)` with separate subtotals and a combined total. Never collapse this into one number without the split visible.

### 3.5 Canonical contract updates (per `skills/ARCHITECTURE.md` checklist)

- New canonical payload fields: `payout_date`, `period_status` (`IN_PROGRESS`/`PENDING_CONFIRMATION`/`EXPECTED_AWAITING_PAYOUT`/`PAID`), `guaranteed_amount`, `amount_incorrectly_at_risk`.
- Update `references/integration-contract.md` and `references/schema-mapping.json` with these fields.
- Update `payment-schema.ts::assertPaymentEnginePayload` to validate the new shape — payloads missing these fields for the new views must fail closed, consistent with existing discipline.
- Add normalizer tests + end-to-end capability tests per the existing checklist; do not skip the reference-contract/ownership-map update step even though it feels like paperwork — this is literally the pattern the architecture doc credits for keeping the system's fail-closed discipline intact.

**Definition of Done**: new `pytest` suite covering the waterfall (all 3 branches + the mismatch case), the payout-date formula (fixture dates across a year boundary and a leap year to catch date-math bugs), and month-straddling truncation (a period split across two calendar months sums to the same total as the un-split period). New TS tests for the new orchestration paths. `rule_version` bumped and documented.

---

## Workstream 4 — Period-over-period comparison (priority: build first, per your decision)

**Objective**: a genuine "this cycle vs. last cycle" comparison, replacing the current re-presentation-of-cached-data behavior.

**Tasks**:
1. New MCP tool `cccap_compare_payment_periods` (or a new `view: COMPARE_PERIODS` on `cccap_analyze_payment` — pick whichever keeps the 14-tool registry more consistent; recommend a new tool since comparison has a genuinely different input shape: two period references, not one).
2. Requires a **fresh fetch of the prior period**, not a re-read of the current period's cache — this is the exact gap named in Section 11 ("no dedicated 'true' comparison capability").
3. New deterministic evaluator (or extend `calculate_payout.py`) computing per-category, per-county deltas between the two periods: `delta_amount`, `delta_pct`, and a flag for deltas exceeding a configurable threshold (surface these first, not buried at the bottom).
4. New formatter (`comparison-formatter.ts`, per Workstream 0's split) rendering: bottom-line delta sentence first ("You're expected to receive $X more/less than last cycle, mainly due to Y"), then the category/county breakdown table with both periods' columns side by side plus a delta column.
5. Reuse Workstream 1's terminology (`Expected`, not `Confirmed`) and Workstream 3's Guaranteed/Attendance-dependent split in the comparison table — a comparison view is exactly the kind of new surface where the old "Confirmed amount" habit could silently creep back in if not explicitly checked.

**Definition of Done**: asking to compare two specific periods returns real numbers from both periods, not a re-run of a single-entity filter (the original "compare payment" bug from the transcript review); eval fixture covering a period-over-period comparison with a known expected delta.

---

## Workstream 5 — Regression safety for the label/data-mismatch bug class

**Objective**: close the gap Section 11 names directly — no automated assertion currently exists that a "highest impact" label's amount is actually the max in its own tables.

**Tasks**:
1. Add a fixture-driven assertion under `skills/agent-child-care-payment-advisor/evals/`: for any response containing a "highest impact" or equivalent superlative label, assert the referenced dollar amount is `>= ` every other comparable amount in that response's own tables.
2. Extend the same assertion pattern to every new superlative-style output introduced by this handoff: the Monthly Rollup's largest-delta category (Workstream 4), the Upcoming Payout countdown's underlying amount (Workstream 3), and the hybrid-ranked action list's wording check from Workstream 2 (never say "highest impact" for an urgency-weighted result).
3. Wire this into the existing eval run process (`skills/reports/eval-runs/`) so it runs automatically alongside the existing "bare" vs. "skill-loaded" comparison, not as a separate manual step.

**Definition of Done**: this class of bug fails CI/eval automatically if reintroduced, rather than requiring another manual transcript review to catch it.

---

## Workstream 6 — Deadline parity between attendance and payment engines

**Objective**: `evaluate_attendance_risks.py` already exposes `next_confirmation_deadline`/`confirmation_days_remaining`; `provider_risk_payment_engine.py` does not expose any per-day or per-authorization deadline. Workstream 3's payout countdown and Holiday Classification Check both need this.

**Tasks**:
1. Add `confirm_by_date` to each day-level record in `provider_risk_payment_engine.py`'s output, using the same 5-day (`CONFIRMATION_WINDOW_DAYS`) window logic already established in `evaluate_attendance_risks.py` — reuse the constant, don't redefine it in a second place.
2. Add `payout_date` (Workstream 3.3) at the period level so the Upcoming Payout view can render "Payout in N days" from real data rather than a placeholder.
3. Update the vocabulary doc (Workstream 1.2) to register `confirm_by_date` and `payout_date` as canonical field names before any formatter consumes them.

**Definition of Done**: a payment-side response can say "this specific day's window closes on [date]" — the exact gap Section 11 names as currently payment-side-only-covers-attendance.

---

## Workstream 7 — Document the unfixable host-chrome constraint (no code change)

**Objective**: prevent a future contributor from re-opening "suppress tool-call telemetry" as a bug ticket against this repo.

**Task**: add a short, prominent note to `carepay-conversation-templates/SKILL.md` and the architecture doc's Section 11: *"Updated todo list" / "Ran [tool] — Completed with input: {...}" is rendered by VS Code Copilot Chat itself, not by this repo's agent text. No prompt or skill change here can suppress it. If this is unacceptable, the fix is a different host surface or a Copilot Chat extension setting — not a change to this codebase.* This is a scope boundary, not a to-do — the only actionable item is making sure the MCP/skill layer itself never adds its *own* redundant echo of tool-call mechanics on top of the host's.

**Definition of Done**: this constraint is written down once, prominently, so it stops being re-discovered per review cycle.

---

## Final note for the agent builder

Every workstream above deliberately follows the existing `skills/ARCHITECTURE.md` capability-build checklist (canonical contract → adapter boundary → fail-closed validation → deterministic evaluator → formatter → tests → reference contract → ownership map). That discipline is why this system is in better shape than most agent codebases reviewed at this depth — the fixes above are gap closures within an already-sound structure, not a rebuild. Preserve the fail-closed and canonical-data rules exactly as they stand; nothing in this handoff should introduce a best-effort guess or a raw Salesforce field name outside the existing adapter boundary.
