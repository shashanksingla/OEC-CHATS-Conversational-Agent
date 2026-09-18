_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

# Provider Assist — Complete System Architecture

**Audience**: An architect who cannot read the full codebase and must understand technical, functional, agent-behavior, and hardcoded-detail facts well enough to propose technical, functional, and UX improvements without re-discovering the system from source.

**Scope**: The "CCCAP Provider Assist" chat agent — a read-only child-care-subsidy (CCCAP) payment/attendance advisor exposed inside VS Code (GitHub Copilot Chat custom agent) and backed by a local stdio MCP server that reads a Salesforce org (`CCCAP Portal API v1`) and runs deterministic Python evaluators.

**Working directory of the whole system**: `c:/Users/shsingla/Downloads/Child Care Agent/Child Care Agent` (repo root). Salesforce org project used for auth/dev: `CHATS_SIT/`.

**Consolidation note**: This document merges and supersedes `_bmad-output/planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08/ARCHITECTURE-SPINE.md` (deleted). Section 13 below carries forward that document's Architectural Decision catalog and Consistency Conventions, corrected against current source.

---

## 1. One-paragraph mental model

A provider (day-care director) types a message in VS Code Copilot Chat. The `Provider Assist` custom agent (`.github/agents/carepay-advisor.agent.md`) is a **prompt only** — it has no code of its own. It is instructed (via Markdown "Skill" files) to resolve intent, then call exactly one of 16 MCP tools exposed by a local Node/TypeScript stdio server (`mcp/cccap-provider-api`). That server authenticates via the Salesforce CLI, reads raw Salesforce data through allow-listed Apex REST actions, normalizes it into canonical shapes (stripping all Salesforce field names), hands the canonical JSON to a **deterministic Python script** (spawned as a subprocess) that does all date/money/classification math with zero LLM involvement, and returns a fully-formed provider-facing text string plus a small structured-routing envelope. The LLM's only remaining job is to relay that text (per current policy, verbatim and in full — never paraphrased) and pick the next tool call. No layer in this system ever writes to Salesforce — everything is read-only.

```text
VS Code Copilot Chat (host UI — renders its OWN tool-call telemetry;
                       "Updated todo list" / "Ran X - Completed with input:{}"
                       is host chrome, NOT agent output, and cannot be
                       suppressed from this repo)
        |
        v
.github/agents/carepay-advisor.agent.md   (agent frontmatter + kickstart rules)
        |  loads (by instruction, not by code import)
        v
skills/agent-child-care-payment-advisor/SKILL.md   (agent lifecycle owner)
        |  routes to branch skills
        v
skills/provider-assist-intent-routing/SKILL.md             (intent/scope/tool choice)
skills/provider-assist-payout-readiness/SKILL.md           (payout/forecast meaning)
skills/provider-assist-attendance-risk-readiness/SKILL.md  (attendance/risk meaning)
skills/provider-assist-data-quality/SKILL.md               (missing/blocked data)
skills/provider-assist-conversation-templates/SKILL.md     (response shape/failure envelope)
        |  model calls exactly one MCP tool
        v
mcp/cccap-provider-api/  (local stdio Node/TS MCP server, process: `node dist/index.js`)
  src/server.ts                     <- tool registration + dispatch + safe envelope
  src/formatters/*.ts               <- ALL provider-facing text rendering (per-capability
                                        formatters: payment-formatter.ts, attendance-formatter.ts,
                                        cases-formatter.ts, authorizations-formatter.ts,
                                        county-policy-formatter.ts, comparison-formatter.ts,
                                        shared.ts)
  src/client.ts                     <- authenticated, provider-scoped, cached Salesforce reads
  src/sf-cli.ts                     <- shells out to Salesforce CLI (`sf`) for auth + Apex REST
  src/read-model-adapters.ts, schedule-normalizer.ts, provider-context.ts, provider-policy.ts
                                     <- the ONLY place raw Salesforce field names may appear
  src/attendance-engine.ts, payment-engine.ts, payment-orchestration.ts
                                     <- capability orchestration + canonicalization (fetch ->
                                        normalize -> evaluate)
  src/dialogue-state.ts, src/conversation-context.ts, src/conversation-logger.ts
                                     <- in-memory continuation/dialogue/telemetry state
  src/next-action-ranking-client.ts, src/situation-envelope.ts, src/view-state.ts
                                     <- ranking subprocess client, situation envelope, view-state helpers
        |  writes one JSON payload to a temp file, spawns a subprocess
        v
skills/agent-child-care-payment-advisor/scripts/*.py   (deterministic evaluators,
                                                          invoked via `uv run <script> <tmpfile>`,
                                                          NO Salesforce access, NO LLM)
  provider_risk_payment_engine.py   <- payment math (rule version provider-risk-payment-v3)
  evaluate_attendance_risks.py      <- attendance/absence/confirmation risk math
  analyze_attendance_transactions.py, calculate_payout.py, next_action_ranking.py
        |
        v
Salesforce org (target org alias `CHATS_SIT`, Apex REST class `CccapPortalApiV1`)
```

---

## 2. Repository map (what lives where)

| Path | Contains |
| --- | --- |
| `.github/agents/carepay-advisor.agent.md` | The agent definition GitHub Copilot Chat loads (frontmatter + instructions). This is the ONLY file that defines the agent's identity/tool access; everything below it is prompt content the agent is told to read. Includes an explicit rule that `content[0].text` must be relayed character-for-character (tables, disclaimers, icons, markdown emphasis included), added after live diagnostics proved the backend already renders correctly and reported formatting defects were relay-layer, not backend, issues. |
| `skills/agent-child-care-payment-advisor/` | Agent-lifecycle skill (`SKILL.md`), its Python evaluators (`scripts/*.py`), their tests (`scripts/tests/*.py`), reference contracts (`references/*.md`, `*.json`), eval fixtures (`evals/*.json`), and `customize.toml`. |
| `skills/provider-assist-intent-routing/SKILL.md` | Owns: user outcome, entity/time scope resolution, freshness, and which MCP tool to call. Must NOT own data retrieval, calculation, or formatting. |
| `skills/provider-assist-payout-readiness/SKILL.md` | Owns: payout timing, payment status meaning, forecast meaning, unsupported what-if handling. |
| `skills/provider-assist-attendance-risk-readiness/SKILL.md` | Owns: attendance, parent-confirmation, absence-limit, and payment-risk dollar-exposure meaning + follow-up routing. |
| `skills/provider-assist-data-quality/SKILL.md` | Owns: naming a source gap and selecting a legitimate recovery view (never inventing fallback values). |
| `skills/provider-assist-conversation-templates/SKILL.md` | Owns: provider-safe response shape, tables, next-actions, failure envelope, greeting/drill-down/payment templates. This is the largest and most frequently touched skill file — it is the presentation contract every response must follow. |
| `skills/ARCHITECTURE.md` | The skill-authoring build guide (module ownership table, canonical-data rule, capability build checklist). Distinct from THIS document — that one is "how to build/extend a skill correctly," this one is "how the whole system actually works end-to-end." |
| `mcp/cccap-provider-api/` | The Node/TypeScript MCP server project. `src/` is hand-written; `dist/` is compiled output (never edit directly). |
| `mcp/cccap-provider-api/src/server.ts` | Registers all 16 MCP tools, handles continuation/action-token resolution and dispatch, and builds the shared safe-error envelope. Provider-facing text rendering itself now lives in `src/formatters/*.ts` (see below), not in this file. |
| `mcp/cccap-provider-api/src/formatters/` | Per-capability response rendering: `payment-formatter.ts` (the single `formatPayoutResult` dispatcher covering every payout path — NEXT_PAYOUT, LAST_PAYOUT, PAYOUT_LEDGER, STATUS, CUSTOM_RANGE, CURRENT_WEEK_FORECAST — plus category/county table renderers), `attendance-formatter.ts`, `cases-formatter.ts`, `authorizations-formatter.ts`, `county-policy-formatter.ts`, `comparison-formatter.ts`, and `shared.ts` (disclaimers, table helpers, `ToolResult` type, `PAYMENT_AMOUNT_LEGEND`). |
| `mcp/cccap-provider-api/src/client.ts` | `CccapClient` — authenticated, provider-scoped, cached read client wrapping Apex REST calls. |
| `mcp/cccap-provider-api/src/sf-cli.ts` | Shells out to the Salesforce CLI (`sf`) to resolve the authenticated user and to invoke allow-listed Apex REST actions. |
| `mcp/cccap-provider-api/src/index.ts` | Process entry point; starts the MCP stdio server. |
| `mcp/cccap-provider-api/src/read-model-adapters.ts`, `schedule-normalizer.ts`, `provider-context.ts`, `provider-policy.ts` | The normalization boundary — the ONLY place raw Salesforce field names (e.g. `CDE_COUNTY__c`, `CI_Authorization_Id__c`) may appear. |
| `mcp/cccap-provider-api/src/attendance-engine.ts`, `payment-engine.ts`, `payment-orchestration.ts` | Capability orchestration and canonicalization: fetch scoped source data in parallel, normalize into the canonical payload, invoke the matching Python evaluator, attach provenance. (These three files supersede the previously separate `attendance-canonical-adapter.ts`/`attendance-snapshot.ts`/`payment-canonical-adapter.ts`/`payment-schema.ts`/`payment-payload-adapter.ts`, which were consolidated.) |
| `mcp/cccap-provider-api/src/dialogue-state.ts`, `conversation-context.ts` | In-memory, process-local conversation continuation state (`actionToken`/result-graph follow-up tokens). |
| `mcp/cccap-provider-api/src/conversation-logger.ts` | Per-turn tool-call telemetry (input, status, duration, provider utterance, error) — logging only, never rendered to the provider. |
| `mcp/cccap-provider-api/src/next-action-ranking-client.ts` | Spawns `next_action_ranking.py` as a subprocess. |
| `mcp/cccap-provider-api/src/situation-envelope.ts`, `view-state.ts` | Situation-envelope construction and provider-facing view-state/action-metadata helpers (`viewState`, `actionViewMetadata`) shared by every formatter. |
| `mcp/cccap-provider-api/scripts/` | Dev/smoke-test scripts (`list-tools.mjs`, `provider-conversation-smoke.mjs`, `provider-walkthrough.mjs`, `smoke-test.mjs`, `snapshot-smoke.mjs`). Prior one-off `diagnose-*.mjs` live-diagnostic scripts were removed once their root causes were confirmed fixed — this directory is standing tooling only, not a dumping ground for throwaway investigation scripts. |
| `mcp/cccap-provider-api/test/` | TypeScript test files run via `tsx --test test/**/*.test.ts`. |
| `mcp/cccap-provider-api/README.md` | The authoritative module-flow / hardcoded-mapping reference for the MCP layer (payment readiness section documents most status-code mappings verbatim). |
| `CHATS_SIT/` | The actual Salesforce DX project (Apex triggers, manifest, scratch-org config) that the MCP server's target org (`SF_TARGET_ORG=CHATS_SIT`) points at. The custom Apex REST resource `CccapPortalApiV1` referenced by `sf-cli.ts` lives in this org, not in this repo's visible source (deployed metadata, not shown to this review). |
| `chat_experiences_for_review/` | Real transcript exports used to review actual agent behavior against the intended design. |
| `.vscode/mcp.json` | Declares the `cccapprovider` MCP server entry VS Code launches. |
| `.vscode/settings.json` | Contains `chat.mcp.autostart: true` and related editor settings. |

---

## 3. End-to-end request flows (concrete traces)

### 3.1 Greeting (`Hi`)
1. Agent kickstart rule fires: call `cccap_get_current_month_risk_snapshot` exactly once with `{}` (never call `cccap_initialize_provider` first — the composite tool does that internally).
2. `attendance-engine.ts` initializes provider scope, pulls schedules/holidays/closures for the current month, calls `evaluate_attendance_risks.py`.
3. The snapshot formatter builds the complete provider-facing text (today's counts + risk table + Next Actions + `Open next payout summary` available view) and puts it in `content[0].text`; `structuredContent` carries only routing metadata (capability, scope, freshness, responseMode).
4. Agent relays `content[0].text` verbatim (rule: "a tool call is not an assistant response; always continue with an assistant message").

### 3.2 "next payout" / "upcoming payout"
1. Intent routing maps this directly to `cccap_analyze_payment` with `{ view: "NEXT_PAYOUT" }` — no greeting snapshot, no `cccap_initialize_provider` call.
2. `payment-orchestration.ts::getUpcomingPayoutDetail`/`getServicePeriodLedger`: resolves exactly one service period, fetches authorizations/county data/fiscal rates/holidays/payment history/vacant slots in parallel, normalizes via `payment-engine.ts` into the `provider-risk-payment-v3` canonical payload, writes it to a temp file, and spawns `uv run provider_risk_payment_engine.py <tmpfile>` with a 30s timeout / 10MB max buffer.
3. The Python engine returns `{status:"ok", result:{...}}`; the orchestration layer attaches `highestImpactChildName`/`highestImpactRankedByDollars`, `detailPagination`, `filters`, `scope`, `paymentView`, `servicePeriod`, `sourceRetrievedAt`, and a `situation` envelope.
4. `formatPayoutResult` (in `src/formatters/payment-formatter.ts`) renders the full text — headline, a canonical 5-row measure table (`Service period`, `Payout date`, `Net payment`, `Conditional at-risk`, `Maximum estimated payout` — the same 5 rows and order for every payout path), County payment composition table, Payment by category table, and Recommended actions — into `content[0].text`.
5. Skill rule (`carepay-conversation-templates`, reinforced in the agent file): this text has a **strict full-text relay rule** — the model must never shorten it, re-summarize it, drop tables/disclaimer icon/italics, or treat any length as "too large to display."

### 3.3 Drill-down via signed action token (e.g. "highest impact child")
1. The previous response's `structuredContent.actionControls` carries `{ actionId, actionToken }` per action — never raw filters.
2. When the provider selects that action, the agent calls the declared `tool` with that input object unchanged instead of reconstructing filters itself.
3. `conversation-context.ts::ConversationContextStore` verifies the signed token, checks expiry and compatibility with any newly-added input (only `detailPage`/`detailPageSize` may be added on top of a stored reference), and returns the original plan's input for `server.ts` to execute for real.
4. If the reference is stale/incompatible/expired, the call fails closed.

### 3.4 "compare payment" / "Compare payment by county"
1. **Current design intent**: answered from the county payment composition table already present in the cached `NEXT_PAYOUT`/`CUSTOM_RANGE` result — never a new tool call, never a re-scope to a previously-named child left over from an unrelated turn.
2. All other comparison requests (period-vs-period, child-vs-child) route to the dedicated `cccap_compare_payment_periods` tool (`formatPeriodComparisonResult`), which performs a genuine fresh multi-period fetch and category/county delta comparison — this is a real capability, not only a re-presentation.

### 3.5 "review absence limits" / attendance risk
1. Routed to `cccap_analyze_payment_risk` with the verified period and `riskFocus: "ABSENCE_LIMITS"` (or `"PARENT_CONFIRMATIONS"` / `"INCOMPLETE_ATTENDANCE"`).
2. Same attendance pipeline as the greeting snapshot but with `riskFocus` narrowing which rows/table shape render, plus the full per-child drill-down table and, when available, a deadline countdown line (`Earliest confirmation deadline: ... (N day(s) left)`) — computed as the earliest of each affected child's own earliest pending-confirmation date (`pending_confirmation_dates` sorted ascending per child), then the minimum across children.

---

## 4. Layer-by-layer detail

### 4.1 Agent/prompt layer

**`.github/agents/carepay-advisor.agent.md`** — frontmatter: `name: "Provider Assist"`, `tools: ['cccapprovider/*']`, `user-invocable: true`, `disable-model-invocation: false`. Body rules (all prompt text, not code):
- Must read the referenced skills before responding.
- Never invent provider/child/authorization/scope/pagination values.
- Greeting (`Hi`) -> call `cccap_get_current_month_risk_snapshot` exactly once with `{}`; a tool call is never itself a response.
- Direct "next payout" request -> route straight to `cccap_analyze_payment` with `view: "NEXT_PAYOUT"`.
- `content[0].text` is the authoritative provider-ready response and must be relayed in full and character-for-character — including every markdown table, blank line, emoji/warning icon, and italic/bold marker. The first turn already contains the complete result (headline + both tables + disclaimer + actions); there is no separate "condensed" vs "full" variant to wait for.
- If `content[0].text` is absent, `structuredContent.providerMessage` is the documented fallback, with the same verbatim-relay requirement.
- No "payload too large" concept exists in this interface — never re-call with smaller pagination to "fit," and never claim a successful result is too large to display.
- `review incomplete attendance records` / `review pending parent confirmations` / `review absence limits` -> `cccap_analyze_payment_risk` with the matching `riskFocus`.
- `CURRENT_WEEK_FORECAST` is accepted only as a compatibility alias for `CURRENT_PERIOD_FORECAST`.

**Skill files** (`skills/*/SKILL.md`) — pure Markdown instructions loaded by reference from the agent file; there is no runtime "skill engine" in this repo. Ownership boundaries (from `skills/ARCHITECTURE.md`):

| Skill | Owns | Must NOT own |
| --- | --- | --- |
| `agent-child-care-payment-advisor` | Agent lifecycle, safety boundary, skill loading, final handoff | Domain calculations, source joins, duplicate templates |
| `carepay-intent-routing` | User outcome, entity/time scope, freshness, narrow tool selection | Data retrieval, calculations, formatting |
| `carepay-payment-risk-readiness` | Attendance/confirmation/absence-limit/payment-risk dollar-exposure meaning + follow-up routing | Common failure wording, source field mapping, payout calculation |
| `carepay-payment-readiness` | Payment status, payout timing, forecast meaning, unsupported what-if handling | Money/date calculations, source joins, common failure wording |
| `carepay-data-quality` | Naming a source gap, selecting a legitimate recovery view | Repairing data, inventing fallback values, recalculating |
| `carepay-conversation-templates` | Provider-safe response shape, tables, next views, failure envelope | Deciding what data means, selecting tools |

`skills/agent-child-care-payment-advisor/references/`: `action-labels.md` (canonical action_id -> label registry), `rule-governance.md` (versioning rules for the Python evaluators — every rule change must produce a new `rule_version` string, current: `provider-risk-payment-v3`), `integration-contract.md`, `attendance-transaction-rules.md`, `vocabulary.md` (canonical provider-facing payment terminology, e.g. `Net payment`/`Conditional at-risk`/`Maximum estimated payout`), `schema-mapping.json`, `setup-guide.md`, `api-response-contract.json`. `customize.toml` holds per-deployment tunables.

### 4.2 MCP transport/auth layer

**`client.ts`** — `CccapClient`, constructed with `{ targetOrg, providerUserId, requestApex }`. Public methods: `initialize(scope)`, `getCases`, `getAuthorizations`, `getCountyData`, `getSchedules`, `getFiscalRates`, `getPaymentHistory`, `getServicePeriods`, `getHolidayList`, `getVacantSlots`, `getCountyName`, `clearReadCache`. Holds in-memory provider scope established once by `initialize()` and re-used by every subsequent call in the same process lifetime — county filters outside that scope are rejected before Salesforce is ever called. Maintains a process-local read cache: **TTL 15 minutes**, **max 100 entries**, LRU-by-insertion-time eviction. Allowed `dateFilter` values: `TODAY`, `THIS_MONTH`, `LAST_MONTH`, `LAST_N_MONTHS`, `LAST_N_DAYS`, `DATE_RANGE`.

**`sf-cli.ts`** — `resolveAuthenticatedUserId(targetOrg)` runs an `sf` CLI SOQL query to resolve the org's authenticated `User.Id`; `requestApexViaSf(targetOrg, action, body)` shells out to invoke one of exactly **10 allow-listed Apex REST actions**: `getProviderData`, `getCaseData`, `getAuthData`, `getCountyData`, `getServicePeriods`, `getSchedules`, `getHolidayList`, `getFiscalRates`, `getPaymentHistory`, `getVacantSlots`. Hardcoded limits: `CLI_TIMEOUT_MS = 60_000` (60s, `SIGKILL` on timeout), `MAX_CAPTURED_OUTPUT_BYTES = 5_000_000` (5MB). Writes the request body to a temp file rather than passing it as a CLI arg. Requires both the Apex HTTP status and the CLI/JSON envelope status to be success; any mismatch fails the call. Auth is entirely delegated to the pre-authenticated `sf` CLI session for `SF_TARGET_ORG`.

**`index.ts`** — process entry point; starts the stdio MCP server, reading `SF_TARGET_ORG` and a display-name override from the environment.

### 4.3 Canonical normalization boundary

Files: `read-model-adapters.ts`, `schedule-normalizer.ts`, `provider-context.ts`, `provider-policy.ts`, plus the normalization performed inside `attendance-engine.ts` and `payment-engine.ts`. This is the **only** place raw Salesforce field names may legally appear (per `skills/ARCHITECTURE.md`'s Canonical Data Rule). Verbatim hardcoded mappings documented in `mcp/cccap-provider-api/README.md`:

- Sub-payment status codes: `1` (Created), `2` (In Progress), `3` (Calculated) -> `REQUESTED`; `4` (Paid) -> `PAID`; unknown codes fail closed.
- Attendance transaction `PARENT_APPROVED`/`PARENT_PENDING` -> `parent_confirmation` = `CONFIRMED`/`PENDING`.
- Authoritative authorization join key: `CI_Authorization_Id__c` (schedule and transaction records).
- Age bands derived from `ind_0_36_months__c`; observed holidays from `DTE_OBSERVED_HOL__c`.
- Encumbrance status codes: `1`=Pending, `2`=Authorized, `3`=Attended, `4`=Paid, `5`=Care Not Offered.
- Fiscal-rate age-group codes `1`-`8`, care-unit codes `1`-`5`, canonical rate-type codes `1, 13, 19, 25, 31, 37, 43, 55, 91` all map to fixed Salesforce labels.
- Fiscal care-unit-to-payment-tier mapping: `PT -> PART_TIME`, `FT -> FULL_TIME`, `FTPT -> FULL_TIME_PLUS_PART_TIME`, `FTFT -> FULL_TIME_PLUS_FULL_TIME`, `NP -> NO_PAYMENT`.
- Provider quality tiers: `Level 1`-`Level 5` map directly to tiers `1`-`5` from the quality rating alone.
- County/authorization fiscal-schedule matching is fail-closed: matches by rate type + provider scope + county + authorization dates + requested care date; ties resolved by latest schedule start date; no-match or conflicting results remain unresolved.
- Raw vacant slots: active date-overlapping contracts with no linked authorization, scoped to authenticated providers' fiscal-agreement counties. Each county-composition `vacant_slots` bucket carries both `{days, amount}` — the day count is available at the source and must be read through by any formatter that renders a per-category day count for vacant slots.
- Fail-closed discipline is pervasive: ambiguous joins, malformed amounts, conflicting relationships, or missing required fields always produce a blocked/unresolved result — this codebase never guesses or silently defaults a financial or eligibility fact.

### 4.4 Capability orchestration

**`attendance-engine.ts`** — owns retrieval, canonical normalization, and evaluator invocation for both the greeting snapshot and the attendance-risk drill-down.

**`payment-orchestration.ts`** — five thin entry functions (`getPaymentAnalysis`, `getServicePeriodLedger`, `getUpcomingPayoutDetail`, `getLastPayoutDetail`, `comparePaymentPeriods`), all funneling through the same `payment-engine.ts` canonicalization and the same `provider_risk_payment_engine.py` evaluator — there is no duplicated calculation logic per payout path; the paths differ only in which service period(s) they resolve. Steps: resolve service period(s) -> fetch schedules/authorizations/county data/fiscal rates/holidays/payment history/vacant slots in parallel -> normalize via `payment-engine.ts` into the `provider-risk-payment-v3` canonical payload -> apply `childNames`/`authNames`/`countyNames` filters (fail closed if a named filter matches nothing in scope) -> write temp JSON -> spawn `uv run provider_risk_payment_engine.py <tmpfile>` (30s timeout, 10MB max buffer) -> post-process (`highestImpactChildName` ranking, detail pagination, `vacantSlotMappingGaps` count) -> attach `situation` envelope -> return.

### 4.5 Deterministic Python evaluators

None of these scripts touch Salesforce or the LLM. Each is a pure function over a JSON input file, invoked once per tool call via `uv run`. Each is independently unit-tested (`skills/agent-child-care-payment-advisor/scripts/tests/`, run via `pytest`).

- **`provider_risk_payment_engine.py`** — rule version `provider-risk-payment-v3`. Computes net/gross/conditional amounts, category/county/child rollups, vacant-slot amounts (with per-county `{days, amount}`), `next_actions`, and `child_payment_impacts[]` rows carrying both `amount_at_risk` and `total_amount`. Payment statuses: `CONDITIONAL`, `EXPECTED`, `BLOCKED`, `DUPLICATE_GUARD`. Amount classification per day: `AT_RISK`, `FORECASTED`, else `EXPECTED`.
- **`evaluate_attendance_risks.py`** — `CONFIRMATION_WINDOW_DAYS` (currently 9; verify against source before quoting elsewhere, as this document previously carried an internally-inconsistent value in two places). Per-child risk codes: `ABSENCE_AFTER_CONFIRMATION_WINDOW`, `PARENT_CONFIRMATION_PENDING`, `INCOMPLETE_ATTENDANCE_RECORD`, `ABSENCE_LIMIT_CONFLICT`, `ABSENCE_LIMIT_UNAVAILABLE`, `ABSENCE_LIMIT_EXCEEDED`, `ABSENCE_LIMIT_APPROACHING`. Per-child `next_confirmation_deadline` is the earliest date in that child's own `sorted()` ascending `pending_confirmation_dates` plus the confirmation window; the aggregate `earliest_confirmation_deadline` is the `min()` of every child's own earliest deadline.
- **`analyze_attendance_transactions.py`, `calculate_payout.py`, `next_action_ranking.py`** — supporting evaluators. `next_action_ranking.py` ranks candidate next-actions using fixed priority bands plus per-candidate score adjustments rather than a pure dollar sort — a known architectural inconsistency with the payment side's dollar-based ranking (see Section 11).

---

## 5. Full MCP tool registry (16 tools, `server.ts`)

| Tool name | Formatter used | Purpose |
| --- | --- | --- |
| `cccap_get_current_month_risk_snapshot` | snapshot formatter | Greeting-only composite: today's scheduled/checked-in counts + current-month payment-readiness risk table. |
| `cccap_get_attendance_risk_snapshot` | snapshot formatter | Non-greeting attendance snapshot variant. |
| `cccap_analyze_payment_risk` | `formatAttendanceRiskResult` | Attendance/confirmation/absence-limit risk analysis; accepts `riskFocus` and optional `childNames`/`countyNames`. |
| `cccap_analyze_payment` | `formatPayoutResult` | Payment status/payout/forecast/custom-range composite — the single dispatcher for every payout path (`STATUS`/`NEXT_PAYOUT`/`LAST_PAYOUT`/`PAYOUT_LEDGER`/`CURRENT_PERIOD_FORECAST`/`CURRENT_WEEK_FORECAST` alias/`CUSTOM_RANGE`), scoped filters, pagination, signed `actionToken`, and `refresh`. |
| `cccap_get_attendance_analysis` | generic `result` (raw JSON passthrough) | Lower-level attendance data. |
| `cccap_initialize_provider` | generic `result` | Explicit provider-context lookup — only called directly when a composite tool's internal initialization isn't sufficient. |
| `cccap_get_cases` | `formatCasesResult` | Case listing. |
| `cccap_get_authorizations` | `formatAuthorizationsResult` | Authorization listing. |
| `cccap_get_county_rate_plans` | `formatCountyPolicyResult` | County policy/rate-plan/holiday/drop-in-response-code lookup. |
| `cccap_get_service_periods` | generic `result` | Service-period listing. |
| `cccap_get_schedules` | generic `result` | Raw schedule/transaction listing. |
| `cccap_get_fiscal_rates` | generic `result` | Fiscal-rate listing. |
| `cccap_get_holidays` | generic `result` | Holiday-list listing. |
| `cccap_get_payment_history` | generic `result` | Sub-payment history listing. |
| `cccap_get_service_period_payout_ledger` | `formatPayoutResult` | Explicit multi-period payout ledger or single upcoming-payout lookup — same dispatcher as `cccap_analyze_payment`. |
| `cccap_compare_payment_periods` | `formatPeriodComparisonResult` | Read-only genuine period-over-period payment comparison with category and county deltas. |

`MAX_NEXT_ACTIONS = 2` — every response is capped to at most 2 "Next actions." `MAX_DISPLAY_CHILDREN = 10`, `MAX_SUMMARY_ROWS = 7` — drill-down/summary tables never show more than these counts of rows without an explicit follow-up.

---

## 6. Canonical action-label registry (`skills/agent-child-care-payment-advisor/references/action-labels.md`)

Single source of truth for every provider-facing Next Action label. Fixed verb vocabulary: `Review`, `Open`, `Compare`, `Retry`. `Confirm` is explicitly banned as a verb — parent confirmation happens in the parent portal, not here. Every payment action object must carry an explicit `tool` field (`cccap_analyze_payment`) so the calling agent has a declared MCP tool to invoke when the action is selected — a past defect where several review/follow-up action objects omitted this field caused those buttons to render but silently do nothing.

Rendering rule: the rendered line is exactly `{n}. {canonical label}`. Next Actions numbering restarts at 1 on every response and is scoped to that single turn only. A response must show only one action list ("**Recommended actions**", built from the server-computed action-metadata list) — an earlier defect rendered a second, competing "Payment next actions" prose list alongside it for some payout paths; that duplicate has been removed, and only the single obvious drill-down list renders now.

---

## 7. Hardcoded values / magic numbers inventory (single consolidated list)

| Value | Where | Meaning |
| --- | --- | --- |
| `15 * 60 * 1000` ms (15 min) | `client.ts::readCacheTtlMs` | Salesforce read cache TTL |
| `100` | `client.ts::readCacheMaxEntries` | Max cached read entries (LRU by insertion time) |
| `60_000` ms (60s) | `sf-cli.ts::CLI_TIMEOUT_MS` | Salesforce CLI command timeout (SIGKILL) |
| `5_000_000` bytes (5MB) | `sf-cli.ts::MAX_CAPTURED_OUTPUT_BYTES` | CLI stdout/stderr capture cap |
| `30_000` ms (30s) | `payment-orchestration.ts` | Python payment-engine subprocess timeout (SIGKILL) |
| `10_000_000` bytes (10MB) | `payment-orchestration.ts` | Python subprocess stdout buffer cap |
| `25` / `100` | `payment-orchestration.ts` detail pagination | Default `detailPageSize` / hard cap |
| `31` days | request schema for `CUSTOM_RANGE` | Max custom payout range span |
| `2` | `server.ts::MAX_NEXT_ACTIONS` | Max Next Actions shown per response |
| `10` | `server.ts::MAX_DISPLAY_CHILDREN` | Max child rows in a drill-down table before "ask for more" |
| `7` | `server.ts::MAX_SUMMARY_ROWS` | Max rows in a summary table |
| `3000` / `2000` / `1000` | `next_action_ranking.py` | Fixed priority-band scoring (not a pure dollar sort — see Section 11) |
| `10` allow-listed actions | `sf-cli.ts::allowedActions` | The complete allow-list of Apex REST actions this server can ever invoke |
| `provider-risk-payment-v3` | `payment-engine.ts` / `provider_risk_payment_engine.py` | Canonical payload/rule version string — any rule change must bump this |
| `1,13,19,25,31,37,43,55,91` | payment canonicalization | Canonical rate-type codes |
| `1`-`8` / `1`-`5` | payment canonicalization | Age-group codes / care-unit codes |
| `1=Pending,2=Authorized,3=Attended,4=Paid,5=Care Not Offered` | canonical adapters | Encumbrance status codes |
| `1,2,3=REQUESTED; 4=PAID` | payment canonicalization | Sub-payment status code mapping |
| `Level 1`-`Level 5` -> tier `1`-`5` | canonical adapters | Provider quality-tier mapping |

## 8. Configuration and launch

**`.vscode/mcp.json`** declares the `cccapprovider` server: stdio command `node ${workspaceFolder}/mcp/cccap-provider-api/dist/index.js`, `cwd: ${workspaceFolder}/CHATS_SIT`, env `SF_TARGET_ORG=CHATS_SIT`. **`.vscode/settings.json`** sets `chat.mcp.autostart: true`.

**`mcp/cccap-provider-api/package.json`** scripts: `build` = `tsc -p tsconfig.json`; `test` = `tsx --test test/**/*.test.ts`; `protocol` = `node scripts/list-tools.mjs`; `start` = `node dist/index.js`. Runtime deps: `@modelcontextprotocol/server@2.0.0`, `zod@4.5.4`.

**`tsconfig.json`**: target `ES2023`, module/resolution `NodeNext`, `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`, `rootDir: src`, `outDir: dist`.

**`dist/`** is 100% generated (compiled from `src/`) — never hand-edit it; after any `src/` change run `npm run build` (a full clean rebuild — `Remove-Item -Recurse -Force dist` then `npm run build` — is safest, since `tsc` does not delete orphaned compiled files when source files are removed/renamed) then, in VS Code, **MCP: Reset Cached Tools** followed by restarting `cccapprovider` from **MCP: List Servers**.

**Python subprocess invocation**: every evaluator is run via `uv run <script.py> <input.json>` — `uv` must be on `PATH`; if it is missing, orchestration raises an explicit "Payment engine is unavailable" error. Hard external dependency with no fallback.

---

## 9. Architecture governance rules (from `skills/ARCHITECTURE.md`)

- **Canonical Data Rule**: raw Salesforce/external-source objects may exist ONLY inside transport and source-normalization adapters. Capability orchestration and Python evaluators must consume named canonical contracts, never raw field names.
- A canonical contract must define: stable internal identifiers/relationship keys; ISO dates and explicit numeric units; normalized statuses/classifications; source/retrieved-at/effective-date/rule-version provenance; readiness/blocking information for absent or ambiguous fields.
- **Capability build checklist**: define the provider decision + narrowest MCP tool -> define canonical input/provider-safe output -> map source fields in one adapter boundary -> reject missing/stale/ambiguous relationships before processing -> pass canonical data to the deterministic evaluator -> format one result + 1-2 grounded next views -> add a normalizer test + end-to-end capability test -> update the reference contract and the ownership map.
- **Change routing discipline**: new intent/follow-up -> `provider-assist-intent-routing`; new attendance/payment meaning -> the owning capability skill + evaluator contract; new source field/relationship -> `references/schema-mapping.json` + the owning normalizer; new response shape/failure behavior -> `provider-assist-conversation-templates` + the owning MCP formatter; new deterministic rule -> the Python evaluator + `rule-governance.md`. The same rule must never be duplicated across two skills — link to the owning module instead.

---

## 10. Testing and evaluation

- **Python unit tests**: `skills/agent-child-care-payment-advisor/scripts/tests/*.py`, run with `pytest tests/` **from `skills/agent-child-care-payment-advisor/scripts`** (not from the skill root — the test directory is nested under `scripts/`).
- **TypeScript tests**: `mcp/cccap-provider-api/test/**/*.test.ts`, run via `npm test` (`tsx --test`). `npx tsc -p tsconfig.json --noEmit` is the fastest signal that a `server.ts`/formatter/orchestration change compiles.
- **Smoke scripts**: `scripts/provider-conversation-smoke.mjs`, `scripts/provider-walkthrough.mjs`, `scripts/snapshot-smoke.mjs`, `scripts/smoke-test.mjs`, `scripts/list-tools.mjs` — exercise the live MCP protocol surface against a real/dev org, not unit-level.
- **Prompt-level evals**: `skills/agent-child-care-payment-advisor/evals/` — fixture-driven conversational eval cases; historical run artifacts live under `skills/reports/eval-runs/`.
- **Transcript-based manual review**: `chat_experiences_for_review/*.md` are real exported conversations reviewed by hand against the intended design. This has repeatedly been the mechanism that surfaces UI/relay-layer defects (missing tables, missing disclaimer formatting, contradictory explanatory sentences) that unit tests alone did not catch, because the defect lived in how the calling agent relayed an already-correct backend response, not in the backend itself.
- **Validation discipline established this review cycle**: after any formatter/orchestration change, rebuild `dist` from clean, run the full TS test suite, run the full Python test suite, AND run a live diagnostic against the real org (`SF_TARGET_ORG=CHATS_SIT`) before treating a fix as confirmed — static/unit tests alone were repeatedly insufficient to catch formatting-layer regressions or to disprove a reported UI bug that turned out to be backend-correct.

---

## 11. Considerations for the next architect (known weak points, not yet fixed further than noted)

**Structural**
- Two independent "next action" ranking implementations exist with DIFFERENT logic: `payment-orchestration.ts::highestImpactChildName` ranks strictly by dollars (3-tier) but `next_action_ranking.py` still ranks by fixed priority bands + ad-hoc point additions, not a pure dollar sort. These two "priority" concepts can disagree with each other in the same conversation — worth unifying into one ranking contract.
- All conversation continuation state (`dialogue-state.ts`, `conversation-context.ts`) is **process-local, in-memory, non-persistent**: restarting the MCP server invalidates every open continuation in every active conversation. No persistence layer exists by design.
- The Python subprocess boundary (`uv run <script> <tmpfile>`) adds real per-call latency and a hard external dependency on `uv` being on `PATH` with no fallback and no health-check — an explicit architectural choice to keep money/date math outside the LLM's TS surface and independently unit-testable.
- `readOnlyAnnotations` (in `server.ts`) hardcodes every tool as read-only/idempotent/non-destructive — there is currently no write-capable tool anywhere in this server.

**Functional/UX**
- Host-level tool-call telemetry ("Updated todo list", "Ran [tool] — Completed with input: {...}") is rendered by VS Code Copilot Chat itself, NOT by this repo's agent text — no prompt change in this codebase can suppress it.
- `next_action_ranking.py`'s fixed-band scoring has never been validated against real dollar amounts the way the payment-side ranking now is.
- The greeting snapshot and the payment/attendance drill-downs use different vocabularies for the same underlying concept in places at the Python/internal-field level (e.g. `amount_at_risk` vs `at_risk_amount` vs `conditional_amount` vs `potential_impact`) even though the provider-facing labels were unified this cycle (`Net payment`/`Conditional at-risk`/`Maximum estimated payout` across every payout path) — `skills/agent-child-care-payment-advisor/references/vocabulary.md` is the canonical provider-facing term list; internal field-name consistency across the Python/TS boundary is still a separate, unresolved cleanup.
- The calling/relaying agent has, on multiple confirmed occasions, altered an already-correct `content[0].text` before display (dropping tables on first turn, dropping disclaimer icon/italics, showing a stale contradictory explanatory sentence after a formatter fix). The agent-file rule requiring verbatim relay has been strengthened repeatedly in response; whether a given host/model reliably complies is not something this codebase can enforce at the protocol level, only document and instruct against.
- No field-level, automated regression check exists asserting "the label rendered says highest-impact and the amount shown for that entity is in fact the maximum across the response's own tables," or asserting that the rendered top-summary-table row set is byte-identical across payout paths — both classes of defect were caught only by manual transcript review or live diagnostics in this review cycle, and would benefit from a lightweight assertion in the eval fixtures.

---

## 12. Glossary (domain + system terms)

| Term | Meaning |
| --- | --- |
| CCCAP | Colorado Child Care Assistance Program — the subsidy program this whole system reports on. |
| Provider | A day-care/child-care business (the human user of this agent — a director/owner, non-technical). |
| Authorization | A county-approved record entitling a specific child to subsidized care under specific terms/dates/rate type. |
| Service period | A Salesforce-defined date range used to anchor a payout cycle. |
| Net payment | The provider-facing label (as of this cycle; previously "Payable now") for the current estimate excluding unresolved risk, shown identically across every payout path's top summary table. |
| Conditional at-risk | The amount that may be added or lost once attendance issues/parent confirmations are resolved. |
| Maximum estimated payout | Net payment + scheduled forecast + conditional at-risk, computed once and shown identically across payout paths. |
| Expected / Forecasted / At-risk | Payment-engine's 3-way day classification: Expected = confirmation window elapsed, not excluded/limit-exceeded; Forecasted = still within the window or a future scheduled date; At-risk = excluded or limit-exceeded. |
| Vacant slot | A contracted slot the provider held open with no child attending; paid under separate rules from attendance-based care, tracked per county as `{days, amount}`. |
| Drop-in | Unscheduled care provided outside a child's regular authorization. |
| Excluded authorization | An authorization whose rate could not be matched, so its days are left out of the payment total. |
| Confirmation window | The period (`CONFIRMATION_WINDOW_DAYS`, verify current value against `evaluate_attendance_risks.py`) after a service date during which a parent can still confirm attendance before it becomes a counted "absence day." |
| `actionToken` | An opaque, process-local, TTL-bound token the model must pass back (never the raw filters) to safely re-run a previously-offered follow-up action without re-inventing scope. |
| `rule_version` (currently `provider-risk-payment-v3`) | A stamped version string on every canonical payload/evaluator result; any change to deterministic business rules must bump this so stale cached results are never silently reinterpreted under new rules. |
| Fail-closed | This codebase's dominant safety posture: any ambiguous, missing, or conflicting relationship produces an explicit "blocked"/"unresolved"/"unavailable" result rather than a best-effort guess. |
| Composite (MCP) tool | A single high-level tool (e.g. `cccap_analyze_payment`) that internally performs provider initialization + all required source reads + evaluator invocation. |

---

## 13. Architectural Decisions & Invariants

*Folded in from the retired `_bmad-output/planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08/ARCHITECTURE-SPINE.md`, corrected against current source (the skill referenced there as `carepay-attendance-readiness` does not exist under that name — it is `carepay-payment-risk-readiness`; file references to now-consolidated modules updated to `attendance-engine.ts`/`payment-engine.ts`).*

### AD-1 — One owner per provider capability
Each provider-facing action has one composite MCP capability owner. `server.ts` registers and dispatches; domain modules (`attendance-engine.ts`, `payment-orchestration.ts`) own orchestration, and `src/formatters/*.ts` own result construction.

### AD-2 — Scope is established outside model input
MCP resolves the Salesforce CLI authenticated user at startup, initializes provider scope, injects provider and county constraints, and rejects out-of-scope filters. Production identity derivation inside Apex is deferred; Apex remains a secondary authorization guard.

### AD-3 — Layers have one-way dependencies
Agent -> skills -> MCP -> source/normalizer -> evaluator. Lower layers never call upward layers (prompts never contain business calculations; Python never fetches Salesforce data; Apex never interprets conversation).

### AD-4 — TypeScript prepares facts; Python decides deterministic outcomes
TypeScript owns input validation, source mapping, relationship checks, normalization, orchestration, and safe formatting. Python owns counts, dates, classifications, thresholds, and money calculations. No duplicated arithmetic/date logic/thresholds in prompts or transport handlers.

### AD-5 — Canonical contracts fail closed
Canonical inputs and outputs carry stable identifiers, dates, freshness, provenance, capability, readiness, and error status. Missing or ambiguous required data produces a blocked or unavailable result, never an inferred value.

### AD-6 — Apex is source retrieval, not business orchestration
`CccapPortalApiV1.cls` retrieves authoritative Salesforce records and enforces server-side access checks. It does not parse provider language, choose MCP capabilities, or calculate provider-facing risk or payout conclusions.

### AD-7 — Generated artifacts are disposable
`mcp/cccap-provider-api/dist` is rebuilt from `src`; `skills/reports/eval-runs` is historical output. Runtime changes occur only in source files and are validated before rebuilding. Because `tsc` does not delete orphaned compiled files when source files are removed/renamed, a full clean rebuild (delete `dist`, then `npm run build`) is required after any structural refactor, not an incremental one.

### AD-8 — Continuations are server-owned projections
An opaque action reference resolves inside MCP to a validated capability, normalized scope, filters, focus/view, and pagination projection. The model never owns continuation state or resends cached data.

### AD-9 — Compatible continuations are cache-first
Serve a continuation from the provider-bound canonical result only when an immutable normalized compatibility key matches provider scope, capability, date scope, filters, focus/view, rule version, freshness policy, projection type, page, and page size. Bypass cache for explicit refresh, expiry, incompatible state, or missing projection data.

### AD-10 — Provider response ownership is text-only
`content[0].text` is the sole provider-facing response channel. `structuredContent` contains only compact status, scope, pagination, and opaque action controls; it never carries canonical rows, child lists, raw identifiers, or duplicated provider prose. A confirmed defect (fixed this cycle) had `structuredContent.providerMessage` — the documented fallback for when `content[0].text` is absent — silently stripped for every payment-capability result; this is now preserved.

### AD-11 — Continuation resolution fails closed
When continuation fields are present, an invalid or incompatible reference returns the shared safe error contract and never falls back to model-supplied direct filters.

### AD-12 — Cross-capability actions preserve originating scope
Cross-capability actions carry only opaque references. MCP resolves the originating bounded scope, and the target capability performs its own authorization and compatibility validation before retrieval.

### AD-13 — Continuation storage is bounded and refreshable
Continuation storage uses provider-scoped process memory with TTL, LRU entry, and byte caps. Explicit refresh bypasses canonical-result reuse and creates a new compatible context.

### AD-14 — Conversation state is a provider-scoped result graph
Every continuation projection records its parent context, current intent, normalized scope, selected service period when applicable, current and parent view, available evidence, freshness, rule version, and scope transition. Narrowing and view deepening may inherit verified state; widening requires explicit provider intent; parent navigation restores the stored parent context.

### AD-15 — Action lifecycle and suppression are server-owned
The server generates action candidates, checks eligibility, deduplicates them against the current result graph, ranks them by severity/impact/deadline, and tracks lifecycle state. Previously offered actions are not re-exposed unless explicitly requested and still relevant. A confirmed defect (fixed this cycle) had two independent action lists render for the same payment response (a prose "Payment next actions" list plus the standard "Recommended actions" list); only the single server-computed list renders now.

### Consistency Conventions

| Concern | Convention |
| --- | --- |
| Tool names | `cccap_<verb>_<subject>`; composite tools represent provider goals, not raw Salesforce objects. |
| Provider identifiers | Never accept provider identity from model input. Preserve endpoint-specific keys per capability. |
| Dates and money | ISO dates and explicit decimal/currency handling at the evaluator boundary. |
| Scope | Every composite flow initializes or reuses authenticated provider scope and validates county and related-record relationships. |
| Errors | Provider-safe structured errors include capability, no-result status, and recovery actions; never expose tokens, IDs, raw payloads, stack traces, or CLI output. |
| Cache | Process-memory cache stores provider-bound canonical results and continuation plans; immutable compatibility keys govern reuse, projections are cache-first, and the cache is not durable storage. |
| Source of truth | Runtime source is `.github/agents`, `skills`, `mcp/cccap-provider-api/src`, evaluator scripts, and `CHATS_SIT` Apex. |
| Capability module shape | Each capability exposes one request entrypoint, one canonical input adapter, one evaluator invocation, and one provider-safe result contract. |
| Validation ownership | MCP schemas validate request shape; TypeScript normalizers validate source relationships and canonical evaluator inputs; Python validates deterministic rule inputs. The first failing layer returns the shared blocked/error contract. |
| Response structure | Every payout path (NEXT_PAYOUT, LAST_PAYOUT, PAYOUT_LEDGER, STATUS, CUSTOM_RANGE, CURRENT_WEEK_FORECAST) renders through the one `formatPayoutResult` dispatcher and produces the same 5-row top measure table (`Service period`, `Payout date`, `Net payment`, `Conditional at-risk`, `Maximum estimated payout`) in the same order, so responses are structurally comparable regardless of which path produced them. |

---

*This document reflects the CURRENT implemented state as of this consolidation pass. It reflects the payment-formatter unification (`formatPayoutResult` single dispatcher), the "Net payment" terminology rename, the top-summary-table structural unification across all payout paths, the `providerMessage`/`structuredContent` and duplicate-action-list fixes, the `src/formatters/` split, and the `attendance-engine.ts`/`payment-engine.ts` consolidation. It supersedes and replaces the retired `ARCHITECTURE-SPINE.md`. Re-verify any specific file/line reference against the live source before making a change — this document is a map, not a substitute for reading the file being edited.*

__________________________GenAI: Generated code ends here______________________________