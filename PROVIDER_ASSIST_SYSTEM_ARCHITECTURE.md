_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

# Provider Assist — Complete System Architecture

**Audience**: An architect who cannot read the full codebase and must understand technical, functional, agent-behavior, and hardcoded-detail facts well enough to propose technical, functional, and UX improvements without re-discovering the system from source.

**Scope**: The "CCCAP Provider Assist" chat agent — a read-only child-care-subsidy (CCCAP) payment/attendance advisor exposed inside VS Code (GitHub Copilot Chat custom agent) and backed by a local stdio MCP server that reads a Salesforce org (`CCCAP Portal API v1`) and runs deterministic Python evaluators.

**Working directory of the whole system**: `c:/Users/shsingla/Downloads/Child Care Agent/Child Care Agent` (repo root). Salesforce org project used for auth/dev: `CHATS_SIT/`.

---

## 1. One-paragraph mental model

A provider (day-care director) types a message in VS Code Copilot Chat. The `Provider Assist` custom agent (`.github/agents/carepay-advisor.agent.md`) is a **prompt only** — it has no code of its own. It is instructed (via Markdown "Skill" files) to resolve intent, then call exactly one of 14 MCP tools exposed by a local Node/TypeScript stdio server (`mcp/cccap-provider-api`). That server authenticates via the Salesforce CLI, reads raw Salesforce data through allow-listed Apex REST actions, normalizes it into canonical shapes (stripping all Salesforce field names), hands the canonical JSON to a **deterministic Python script** (spawned as a subprocess) that does all date/money/classification math with zero LLM involvement, and returns a fully-formed provider-facing text string plus a small structured-routing envelope. The LLM's only remaining job is to relay that text (sometimes verbatim, sometimes lightly composed from structured fields) and pick the next tool call. No layer in this system ever writes to Salesforce — everything is read-only.

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
skills/carepay-intent-routing/SKILL.md             (intent/scope/tool choice)
skills/carepay-payment-readiness/SKILL.md          (payout/forecast meaning)
skills/carepay-payment-risk-readiness/SKILL.md     (attendance/risk meaning)
skills/carepay-data-quality/SKILL.md               (missing/blocked data)
skills/carepay-conversation-templates/SKILL.md     (response shape/failure envelope)
        |  model calls exactly one MCP tool
        v
mcp/cccap-provider-api/  (local stdio Node/TS MCP server, process: `node dist/index.js`)
  src/server.ts             <- tool registration + ALL provider-facing text rendering
  src/client.ts              <- authenticated, provider-scoped, cached Salesforce reads
  src/sf-cli.ts              <- shells out to Salesforce CLI (`sf`) for auth + Apex REST
  src/*-canonical-adapter.ts, *-normalizer.ts, read-model-adapters.ts
                             <- the ONLY place raw Salesforce field names may appear
  src/attendance-snapshot.ts, src/payment-orchestration.ts
                             <- capability orchestration (fetch -> normalize -> evaluate)
  src/dialogue-state.ts, src/conversation-context.ts
                             <- in-memory contextRef/actionRef follow-up state
  src/next-action-ranking-client.ts
                             <- spawns next_action_ranking.py
        |  writes one JSON payload to a temp file, spawns a subprocess
        v
skills/agent-child-care-payment-advisor/scripts/*.py   (deterministic evaluators,
                                                          invoked via `uv run <script> <tmpfile>`,
                                                          NO Salesforce access, NO LLM)
  provider_risk_payment_engine.py   <- payment math (rule version provider-risk-payment-v1)
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
| `.github/agents/carepay-advisor.agent.md` | The agent definition GitHub Copilot Chat loads (frontmatter + instructions). This is the ONLY file that defines the agent's identity/tool access; everything below it is prompt content the agent is told to read. |
| `skills/agent-child-care-payment-advisor/` | Agent-lifecycle skill (`SKILL.md`), its Python evaluators (`scripts/*.py`), their tests (`scripts/tests/*.py`), reference contracts (`references/*.md`, `*.json`), eval fixtures (`evals/*.json`), and `customize.toml`. |
| `skills/carepay-intent-routing/SKILL.md` | Owns: user outcome, entity/time scope resolution, freshness, and which MCP tool to call. Must NOT own data retrieval, calculation, or formatting. |
| `skills/carepay-payment-readiness/SKILL.md` | Owns: payout timing, payment status meaning, forecast meaning, unsupported what-if handling. |
| `skills/carepay-payment-risk-readiness/SKILL.md` | Owns: attendance, parent-confirmation, absence-limit, and payment-risk dollar-exposure meaning + follow-up routing. |
| `skills/carepay-data-quality/SKILL.md` | Owns: naming a source gap and selecting a legitimate recovery view (never inventing fallback values). |
| `skills/carepay-conversation-templates/SKILL.md` | Owns: provider-safe response shape, tables, next-actions, failure envelope, greeting/drill-down/payment templates. This is the largest and most frequently touched skill file — it is the presentation contract every response must follow. |
| `skills/ARCHITECTURE.md` | The skill-authoring build guide (module ownership table, canonical-data rule, capability build checklist). Distinct from THIS document — that one is "how to build/extend a skill correctly," this one is "how the whole system actually works end-to-end." |
| `mcp/cccap-provider-api/` | The Node/TypeScript MCP server project. `src/` is hand-written; `dist/` is compiled output (never edit directly). |
| `mcp/cccap-provider-api/src/server.ts` | ~1990 lines. Registers all 14 MCP tools and contains ALL provider-facing text-rendering logic (tables, headlines, next-actions, disclaimers). This is the single largest and most change-heavy file in the system. |
| `mcp/cccap-provider-api/src/client.ts` | `CccapClient` — authenticated, provider-scoped, cached read client wrapping Apex REST calls. |
| `mcp/cccap-provider-api/src/sf-cli.ts` | Shells out to the Salesforce CLI (`sf`) to resolve the authenticated user and to invoke allow-listed Apex REST actions. |
| `mcp/cccap-provider-api/src/index.ts` | Process entry point; starts the MCP stdio server. |
| `mcp/cccap-provider-api/src/*-canonical-adapter.ts`, `*-normalizer.ts`, `read-model-adapters.ts` | The normalization boundary — the ONLY place raw Salesforce field names (e.g. `CDE_COUNTY__c`, `CI_Authorization_Id__c`) may appear. |
| `mcp/cccap-provider-api/src/attendance-snapshot.ts`, `payment-orchestration.ts` | Capability orchestration: fetch scoped source data in parallel, normalize, invoke the matching Python evaluator, attach provenance. |
| `mcp/cccap-provider-api/src/dialogue-state.ts`, `conversation-context.ts` | In-memory, process-local conversation continuation state (`contextRef`/`actionRef` opaque follow-up tokens). |
| `mcp/cccap-provider-api/src/next-action-ranking-client.ts` | Spawns `next_action_ranking.py` as a subprocess. |
| `mcp/cccap-provider-api/src/payment-schema.ts` | Structural validation (`assertPaymentEnginePayload`) enforcing the `provider-risk-payment-v1` canonical payload shape before it is handed to Python. |
| `mcp/cccap-provider-api/scripts/list-tools.mjs`, `provider-conversation-smoke.mjs`, `snapshot-smoke.mjs` | Dev/smoke-test scripts (`npm run protocol`, `npm run smoke*`). |
| `mcp/cccap-provider-api/test/` | TypeScript test files run via `tsx --test test/**/*.test.ts`. |
| `mcp/cccap-provider-api/README.md` | The authoritative module-flow / hardcoded-mapping reference for the MCP layer (payment readiness section documents most status-code mappings verbatim). |
| `CHATS_SIT/` | The actual Salesforce DX project (Apex triggers, manifest, scratch-org config) that the MCP server's target org (`SF_TARGET_ORG=CHATS_SIT`) points at. The custom Apex REST resource `CccapPortalApiV1` referenced by `sf-cli.ts` lives in this org, not in this repo's visible source (deployed metadata, not shown to this review). |
| `chat_experiences_for_review/` | Real transcript exports (e.g. `Sample_4.md`) used to review actual agent behavior against the intended design. |
| `Improvement to be done/childcare-agent-improvement-spec.md` | The standing improvement backlog derived from transcript review (10 numbered issues + a proposed system-prompt rewrite). |
| `.vscode/mcp.json` | Declares the `cccapprovider` MCP server entry VS Code launches. |
| `.vscode/settings.json` | Contains `chat.mcp.autostart: true` and related editor settings. |

---

## 3. End-to-end request flows (concrete traces)

### 3.1 Greeting (`Hi`)
1. Agent kickstart rule fires: call `cccap_get_current_month_risk_snapshot` exactly once with `{}` (never call `cccap_initialize_provider` first — the composite tool does that internally).
2. `attendance-snapshot.ts` initializes provider scope, pulls schedules/holidays/closures for the current month, calls `evaluate_attendance_risks.py`.
3. `server.ts`'s snapshot formatter builds the complete provider-facing text (today's counts + 3-row risk table + Next Actions + `Open next payout summary` available view) and puts it in `content[0].text`; `structuredContent` carries only routing metadata (capability, scope, freshness, responseMode) — it deliberately does NOT repeat the message, per the "Conversation Starter Contract" in the MCP README.
4. Agent relays `content[0].text` verbatim (rule: "a tool call is not an assistant response; always continue with an assistant message").

### 3.2 "next payout" / "upcoming payout"
1. Intent routing maps this directly to `cccap_analyze_payment` with `{ view: "NEXT_PAYOUT" }` — no greeting snapshot, no `cccap_initialize_provider` call (that would duplicate orchestration and risk mismatched scope).
2. `payment-orchestration.ts::getPaymentAnalysis`: resolves exactly one service period (`paymentAfter: "TODAY", limitOne: true`), fetches authorizations/county data/fiscal rates/holidays/payment history/vacant slots in parallel (`Promise.all`), normalizes via `payment-canonical-adapter.ts` into the `provider-risk-payment-v1` payload, validates it with `payment-schema.ts::assertPaymentEnginePayload`, writes it to a temp file, and spawns `uv run provider_risk_payment_engine.py <tmpfile>` with a 30s timeout / 10MB max buffer.
3. The Python engine returns `{status:"ok", result:{...}}`; the orchestration layer computes `highestImpactChildName`/`highestImpactRankedByDollars` (3-tier: `amount_at_risk` -> `total_amount` -> scheduled-hours fallback), attaches `detailPagination`, `filters`, `scope`, `paymentView`, `servicePeriod`, `sourceRetrievedAt`, and a `situation` envelope (`buildSituationEnvelope`, from `situation-envelope.ts`).
4. `server.ts::formatPaymentResult` renders the full text (period header, Measure table, Expected/Forecasted/At-risk breakdown, category/county/child detail tables, county composition, Next Actions/Drill-down/Available-views, `PAYMENT_DISCLAIMER` footer) and returns it as both `content[0].text` and `structuredContent.providerMessage`.
5. Skill rule (`carepay-conversation-templates`): this text has a **strict full-text relay rule** — the model must never shorten it, rebuild a custom summary from `structuredContent.summaryView`, or treat any length as "too large to display."

### 3.3 Drill-down via `actionRef` (e.g. "highest impact child")
1. The previous response's `structuredContent.actionControls` (built by `compactActionControls`) carried a `{ contextRef, actionRef }` pair per action — never raw filters.
2. When the provider selects that action (by number or by typed label match against `action-labels.md`), the agent re-issues the SAME tool with `{ contextRef, actionRef }` instead of reconstructing filters itself.
3. `conversation-context.ts::ConversationContextStore.resolve()`/`resolveAction()` looks up the stored plan, checks it hasn't expired (15-minute TTL) and is compatible with any newly-added input (only `detailPage`/`detailPageSize` may be added on top of a stored reference — anything else is scope-widening and is rejected), and returns the original plan's `input` for `server.ts` to execute for real.
4. If the reference is stale/incompatible/expired, the call fails closed (no silent reconstruction of a similar-looking request).

### 3.4 "compare payment" / "Compare payment by county"
1. **Current design intent (post-fix)**: this must be answered from the county payment composition table ALREADY present in the cached `NEXT_PAYOUT`/`CUSTOM_RANGE` result (`renderCountyComposition` in `server.ts`) — explicitly calling out the highest/lowest-exposure county and the dollar delta — never a new tool call, and never a re-scope to a previously-named child left over from an unrelated turn.
2. All other comparison requests (period-vs-period, child-vs-child) remain **unsupported**: the agent must ask which single period to review and must not claim a comparison was performed.
3. **Historical defect** (documented in `Improvement to be done/childcare-agent-improvement-spec.md`, item 3, and observed in `chat_experiences_for_review/Sample_4.md`): before this fix, "compare payment" caused the model to re-issue `cccap_analyze_payment` with `childNames: ["<previously drilled-down child>"]` — i.e. it silently reused stale conversational context instead of comparing anything. The fix is doc-only (intent-routing + conversation-templates + agent file); there was no dedicated "compare" tool/capability to build against, because the county composition data already exists in the cached result.

### 3.5 "review absence limits" / attendance risk
1. Routed to `cccap_analyze_payment_risk` with the verified period and `riskFocus: "ABSENCE_LIMITS"` (or `"PARENT_CONFIRMATIONS"` / `"INCOMPLETE_ATTENDANCE"`).
2. Same attendance pipeline as the greeting snapshot but with `riskFocus` narrowing which rows/table shape render, plus the full per-child drill-down table (`Child | County | Pending | Outside window | Over limit | Est. risk ($)` — a single shared legend sentence above it, not per-row prose) and, when available, a deadline countdown line (`Earliest confirmation deadline: ... (N day(s) left)`).

---

## 4. Layer-by-layer detail

### 4.1 Agent/prompt layer

**`.github/agents/carepay-advisor.agent.md`** — frontmatter: `name: "Provider Assist"`, `tools: ['cccapprovider/*']`, `user-invocable: true`, `disable-model-invocation: false`. Body rules (all prompt text, not code):
- Must read 3 skills before responding: `agent-child-care-payment-advisor/SKILL.md`, `carepay-conversation-templates/SKILL.md`, `carepay-intent-routing` (skill-name reference, not a literal path).
- Never invent provider/child/authorization/scope/pagination values.
- Greeting (`Hi`) -> call `cccap_get_current_month_risk_snapshot` exactly once with `{}`; a tool call is never itself a response — must always continue with an assistant message.
- Direct "next payout" request -> route straight to `cccap_analyze_payment` with `view: "NEXT_PAYOUT"`, skipping the greeting snapshot and any prerequisite tool.
- Payment responses: strict full-text relay rule (never shorten `content[0].text`/`structuredContent.providerMessage`).
- No "payload too large" concept exists in this interface — never re-call with smaller pagination to "fit."
- One call per turn; only `isError` justifies the Failure Template.
- Absence-limit questions -> `cccap_get_county_rate_plans` with `dateFilter: "THIS_MONTH"`; custom-range payout (not next payout) -> `view: "CUSTOM_RANGE"` capped at 31 days, never called a "service period."
- `review incomplete attendance records` / `review pending parent confirmations` / `review absence limits` -> `cccap_analyze_payment_risk` with `riskFocus` set to `INCOMPLETE_ATTENDANCE` / `PARENT_CONFIRMATIONS` / `ABSENCE_LIMITS` respectively.
- (Added in this session's fix) "compare payment"/"compare payment by county" -> answer from the already-cached county composition table, never a new tool call or a stale child filter; never render "Updated todo list"/"Ran [tool]" host mechanics as if agent-authored.

**Skill files** (`skills/*/SKILL.md`) — pure Markdown instructions loaded by reference from the agent file; there is no runtime "skill engine" in this repo — this is prompt content the LLM is told to read and follow. Ownership boundaries (from `skills/ARCHITECTURE.md`):

| Skill | Owns | Must NOT own |
| --- | --- | --- |
| `agent-child-care-payment-advisor` | Agent lifecycle, safety boundary, skill loading, final handoff | Domain calculations, source joins, duplicate templates |
| `carepay-intent-routing` | User outcome, entity/time scope, freshness, narrow tool selection | Data retrieval, calculations, formatting |
| `carepay-payment-risk-readiness` | Attendance/confirmation/absence-limit/payment-risk dollar-exposure meaning + follow-up routing | Common failure wording, source field mapping, payout calculation |
| `carepay-payment-readiness` | Payment status, payout timing, forecast meaning, unsupported what-if handling | Money/date calculations, source joins, common failure wording |
| `carepay-data-quality` | Naming a source gap, selecting a legitimate recovery view | Repairing data, inventing fallback values, recalculating |
| `carepay-conversation-templates` | Provider-safe response shape, tables, next views, failure envelope | Deciding what data means, selecting tools |

`carepay-conversation-templates/SKILL.md` is the largest and most-edited skill — it defines: the Greeting Snapshot Template, Drill-Down Template (6-column numeric table: `Child | County | Pending | Outside window | Over limit | Est. risk ($)` with ONE shared legend sentence, not per-row prose), Payment Template (strict full-text relay + column-naming standard `Confirmed amount`/`Conditional amount`), Custom Payout Period Template, Failure Template, plus session-wide rules added during this review cycle: bottom-line-first sentence before any table, mandatory one-line period header (`Payout period: Aug 24-30, 2026` / `Attendance period: Sep 1-5, 2026`), a fixed CCCAP jargon glossary (Conditional/Confirmed/Vacant slot/Drop-in/Excluded authorization/Absence (paid)/Enrollment absence — glossed once per session, not re-glossed), a "needs your attention today" triage list (2-3 items, ranked by dollar impact then urgency) before any detail table when a response carries more than one finding, deadline-as-countdown surfacing when `next_confirmation_deadline`/`earliest_confirmation_deadline` are present, and a per-figure estimate qualifier next to the headline dollar amount (not only a closing disclaimer).

`skills/agent-child-care-payment-advisor/references/`: `action-labels.md` (canonical action_id -> label registry, the single source of truth both `server.ts` and `next_action_ranking.py` must render from verbatim), `rule-governance.md` (versioning rules for the Python evaluators — every rule change must produce a new `rule_version` string, e.g. `provider-risk-payment-v1`), `integration-contract.md` (the canonical data contract between MCP orchestration and Python evaluators), `attendance-transaction-rules.md` (attendance classification rules), `schema-mapping.json` (source-field-to-canonical-field mapping table), `setup-guide.md` (local dev setup), `api-response-contract.json` (response shape contract). `customize.toml` holds per-deployment tunables for the skill (e.g. display name / branding-level settings, not business logic).

### 4.2 MCP transport/auth layer

**`client.ts`** — `CccapClient`, constructed with `{ targetOrg, providerUserId, requestApex }`. Public methods: `initialize(scope)`, `getCases`, `getAuthorizations`, `getCountyData`, `getSchedules`, `getFiscalRates`, `getPaymentHistory`, `getServicePeriods`, `getHolidayList`, `getVacantSlots`, `getCountyName`, `clearReadCache`. Holds in-memory provider scope (`providerSalesforceIds`, `providerExternalNames`, `countyIds`, `countyNameById`, `fiscalScheduleIds`, `fiscalSchedules`) established once by `initialize()` and re-used by every subsequent call in the same process lifetime — county filters outside that scope are rejected before Salesforce is ever called. Maintains a process-local read cache: key `${action}:${JSON.stringify(body)}`, **TTL 15 minutes** (`readCacheTtlMs = 15 * 60 * 1000`), **max 100 entries** (`readCacheMaxEntries`), LRU-by-insertion-time eviction. Allowed `dateFilter` values: `TODAY`, `THIS_MONTH`, `LAST_MONTH`, `LAST_N_MONTHS`, `LAST_N_DAYS`, `DATE_RANGE`.

**`sf-cli.ts`** — `resolveAuthenticatedUserId(targetOrg)` runs an `sf` CLI SOQL query (`LIMIT 1`, requires `totalSize === 1`) to resolve the org's authenticated `User.Id`; `requestApexViaSf(targetOrg, action, body)` shells out to invoke one of exactly **10 allow-listed Apex REST actions**: `getProviderData`, `getCaseData`, `getAuthData`, `getCountyData`, `getServicePeriods`, `getSchedules`, `getHolidayList`, `getFiscalRates`, `getPaymentHistory`, `getVacantSlots`. Hardcoded limits: `CLI_TIMEOUT_MS = 60_000` (60s, `SIGKILL` on timeout, exit code `124`), `MAX_CAPTURED_OUTPUT_BYTES = 5_000_000` (5MB stdout/stderr capture cap). Writes the request body to a temp file (`cccap-apex-` prefix, `request.json`) rather than passing it as a CLI arg. Requires both the Apex HTTP status (`200`-`299`) and the CLI/JSON envelope status to be zero/success; any mismatch fails the call. On Windows, reads `process.env.ComSpec` (falls back to `cmd.exe`) purely for spawning the shell — no Salesforce credential is read from environment variables; auth is entirely delegated to the pre-authenticated `sf` CLI session for `SF_TARGET_ORG`.

**`index.ts`** — process entry point; starts the stdio MCP server (`node dist/index.js`), reading `SF_TARGET_ORG` and a display-name override from the environment (see VS Code launch config in Section 7).

### 4.3 Canonical normalization boundary

Files: `attendance-canonical-adapter.ts`, `payment-canonical-adapter.ts`, `payment-payload-adapter.ts`, `read-model-adapters.ts`, `schedule-normalizer.ts`, `fiscal-rate-normalizer.ts`, `authorization-fiscal-schedule-matcher.ts`, `provider-context.ts`, `provider-policy.ts`, `payment-schema.ts`. This is the **only** place raw Salesforce field names may legally appear (per `skills/ARCHITECTURE.md`'s Canonical Data Rule). Verbatim hardcoded mappings documented in `mcp/cccap-provider-api/README.md`:

- Sub-payment status codes: `1` (Created), `2` (In Progress), `3` (Calculated) -> `REQUESTED`; `4` (Paid) -> `PAID`; unknown codes fail closed.
- Attendance transaction `PARENT_APPROVED`/`PARENT_PENDING` -> `parent_confirmation` = `CONFIRMED`/`PENDING`.
- Authoritative authorization join key: `CI_Authorization_Id__c` (schedule and transaction records).
- Age bands derived from `ind_0_36_months__c`; observed holidays from `DTE_OBSERVED_HOL__c`.
- Encumbrance status codes: `1`=Pending, `2`=Authorized, `3`=Attended, `4`=Paid, `5`=Care Not Offered (status `5` supplies the canonical `care_not_offered` value).
- Fiscal-rate age-group codes `1`-`8`, care-unit codes `1`-`5`, canonical rate-type codes `1, 13, 19, 25, 31, 37, 43, 55, 91` all map to fixed Salesforce labels. R00393 lookup: `1 -> 15650`, `ADD -> 5500`.
- Fiscal care-unit-to-payment-tier mapping: `PT -> PART_TIME`, `FT -> FULL_TIME`, `FTPT -> FULL_TIME_PLUS_PART_TIME`, `FTFT -> FULL_TIME_PLUS_FULL_TIME`, `NP -> NO_PAYMENT` (contributes zero base payment).
- Provider quality tiers: `Level 1`-`Level 5` map directly to tiers `1`-`5` from the quality rating alone; provider type is NOT part of this mapping.
- County/authorization fiscal-schedule matching (`authorization-fiscal-schedule-matcher.ts`) is fail-closed: matches by `CI_Authorization_Rate_Type__c` + provider scope + county + authorization dates + requested `careDate`; ties resolved by latest schedule start date; no-match or conflicting results remain unresolved (never guessed).
- Raw vacant slots: active date-overlapping contracts with `IDN_AUTH__c = null`, scoped to authenticated providers' fiscal-agreement counties; rates mapped through fiscal fields; county holidays counted; provider closure dates excluded; `CNT_DAYS_OF_MONTH__c` applied chronologically from the 1st of the month. Absence/drop-in/attendance-confirmation rules explicitly do NOT apply to vacant slots.
- `payment-schema.ts::assertPaymentEnginePayload` structurally enforces the `provider-risk-payment-v1` canonical payload shape before any Python invocation — a payload that fails this check never reaches the evaluator.
- Fail-closed discipline is pervasive: ambiguous joins, malformed amounts, conflicting relationships, or missing required fields always produce a blocked/unresolved result — this codebase never guesses or silently defaults a financial or eligibility fact.

### 4.4 Capability orchestration

**`attendance-snapshot.ts`** — owns retrieval + evaluator invocation for both the greeting snapshot and the attendance-risk drill-down; calls `attendance-canonical-adapter.ts` for schedule/authorization-name/county/quality-tier normalization (which delegates transaction normalization to `schedule-normalizer.ts`).

**`payment-orchestration.ts::getPaymentAnalysis(client, scope, view, asOfDate, filters)`** — the payment capability's single entry point. `view` is one of `STATUS | NEXT_PAYOUT | CURRENT_WEEK_FORECAST | CUSTOM_RANGE`. Steps: resolve exactly one service period (or synthesize a `CUSTOM:<from>:<to>` pseudo-period for `CUSTOM_RANGE`, capped at 31 days by request-schema validation) -> fetch schedules -> derive `scheduleRateTypes`/`authorizationNames` -> fetch authorizations/county data/fiscal rates/holidays/payment history/vacant slots in parallel -> normalize via `payment-canonical-adapter.ts` into `provider-risk-payment-v1` -> apply `childNames`/`authNames`/`countyNames` filters (fail closed if a named filter matches nothing in scope) -> validate via `payment-schema.ts` -> write temp JSON -> spawn `uv run provider_risk_payment_engine.py <tmpfile>` (30s timeout, 10MB max buffer, `SIGKILL` on timeout) -> post-process (`highestImpactChildName`/`highestImpactRankedByDollars` 3-tier ranking, detail pagination default page size 25 capped at 100, `vacantSlotMappingGaps` count) -> attach `situation` envelope via `buildSituationEnvelope` (`situation-envelope.ts`) -> return.

### 4.5 Deterministic Python evaluators

None of these scripts touch Salesforce or the LLM. Each is a pure function over a JSON input file, invoked once per tool call via `execFile("uv", ["run", <script>, <tmpfile>])`. Each is independently unit-tested (`skills/agent-child-care-payment-advisor/scripts/tests/`, 97 tests total, run via `pytest`).

- **`provider_risk_payment_engine.py`** — rule version `provider-risk-payment-v1`. Computes net/gross/conditional amounts, the Expected/Forecasted/At-risk breakdown, category/county/child rollups, vacant-slot amounts, `next_actions`, and (post-fix) `child_payment_impacts[]` rows carrying BOTH `amount_at_risk` (risk-flagged days only: `day["conditional"]` or `DROP_IN_LIMIT_EXCEEDED`/`ABSENCE_LIMIT_EXCEEDED` flags) and `total_amount` (every rate-matched day, unconditionally). Payment statuses: `CONDITIONAL`, `EXPECTED`, `BLOCKED`, `DUPLICATE_GUARD`. Amount classification per day: `AT_RISK` (excluded or limit-exceeded), `FORECASTED` (future or within the 5-day confirmation window), else `EXPECTED`.
- **`evaluate_attendance_risks.py`** — `CONFIRMATION_WINDOW_DAYS = 5` (hardcoded). Per-child risk codes: `ABSENCE_AFTER_CONFIRMATION_WINDOW`, `PARENT_CONFIRMATION_PENDING`, `INCOMPLETE_ATTENDANCE_RECORD`, `ABSENCE_LIMIT_CONFLICT`, `ABSENCE_LIMIT_UNAVAILABLE`, `ABSENCE_LIMIT_EXCEEDED`, `ABSENCE_LIMIT_APPROACHING` (triggered when remaining allowance <= 2 days). Post-fix additions: per-child `next_confirmation_deadline`/`confirmation_days_remaining` (earliest pending-confirmation date + 5 days) and aggregate `earliest_confirmation_deadline`/`earliest_confirmation_days_remaining`. `_category_risk_amount_estimate` deliberately returns `None` (not `$0`) when no affected child has a rate estimate, so the UI never fabricates a dollar figure.
- **`analyze_attendance_transactions.py`, `calculate_payout.py`, `next_action_ranking.py`** — supporting evaluators. `next_action_ranking.py` currently ranks candidate next-actions using FIXED PRIORITY BANDS (`_PAYMENT_IMPACT_BASE = 3000`, `_URGENCY_BASE = 2000`, `_SOURCE_RECOVERY_BASE = 1000`) plus per-candidate score adjustments (e.g. `+80` for `PARENT_CONFIRMATION_PENDING`, `+60` for `INCOMPLETE_ATTENDANCE_RECORD`, `+3` per absence day, `+2` per pending-confirmation day) rather than a pure dollar sort — this is a known architectural inconsistency with the payment side's dollar-based ranking (see Section 9, Considerations).

---

## 5. Full MCP tool registry (14 tools, `server.ts`)

| Tool name | Formatter used | Purpose |
| --- | --- | --- |
| `cccap_get_current_month_risk_snapshot` | snapshot formatter | Greeting-only composite: today's scheduled/checked-in counts + current-month payment-readiness risk table. |
| `cccap_get_attendance_risk_snapshot` | snapshot formatter | Non-greeting attendance snapshot variant. |
| `cccap_analyze_payment_risk` | `formatAttendanceRiskResult` | Attendance/confirmation/absence-limit risk analysis; accepts `riskFocus` (`ABSENCE_LIMITS`/`PARENT_CONFIRMATIONS`/`INCOMPLETE_ATTENDANCE`) and optional `childNames`/`countyNames`. |
| `cccap_analyze_payment` | `formatPaymentResult` | Payment status/payout/forecast/custom-range composite; accepts `view` (`STATUS`/`NEXT_PAYOUT`/`CURRENT_WEEK_FORECAST`/`CUSTOM_RANGE`), `childNames`/`authNames`/`countyNames`/`detailPage`/`detailPageSize`/`excludedOnly`, plus opaque `contextRef`/`actionRef`/`refresh`. |
| `cccap_get_attendance_analysis` | generic `result` (raw JSON passthrough) | Lower-level attendance data. |
| `cccap_initialize_provider` | generic `result` | Explicit provider-context lookup (active fiscal agreements, authorized counties, agreement dates) — only called directly when a composite tool's internal initialization isn't sufficient. |
| `cccap_get_cases` | `formatCasesResult` | Case listing. |
| `cccap_get_authorizations` | `formatAuthorizationsResult` | Authorization listing (includes linked slot-contract/encumbrance/copay rows). |
| `cccap_get_county_rate_plans` | `formatCountyPolicyResult` | County policy/rate-plan/holiday/drop-in-response-code lookup. |
| `cccap_get_service_periods` | generic `result` | Service-period listing. |
| `cccap_get_schedules` | generic `result` | Raw schedule/transaction listing. |
| `cccap_get_fiscal_rates` | generic `result` | Fiscal-rate listing (county/agreement/provider fee tiers). |
| `cccap_get_holidays` | generic `result` | Holiday-list listing. |
| `cccap_get_payment_history` | generic `result` | Sub-payment history listing (requires a date filter; anchored to care period, not release date). |

**Distinct hardcoded `action_id` literals found in `server.ts`**: `review-absence-limit-risk`, `review-pending-parent-confirmations`, `review-incomplete-attendance`, `review-attendance-records`, `open-attendance-detail`, `review-next-payout`, `retry-payment-analysis`, `next-payment-detail-page`, `open-highest-hours-child-detail` (added in this review cycle), `open-payment-detail`, `review-excluded-payment-days`, `review-payment-summary`. Generated (non-literal) action IDs follow the pattern `attendance-view-${viewId}` where `viewId` is one of `ATTENDANCE_BY_COUNTY`, `ATTENDANCE_BY_CHILD`, `PARENT_CONFIRMATIONS`, `ABSENCE_LIMITS`, `INCOMPLETE_RECORDS`, `PAYMENT_IMPACT`.

`MAX_NEXT_ACTIONS = 2` — every response is capped to at most 2 "Next actions" regardless of how many candidates exist. `MAX_DISPLAY_CHILDREN = 10`, `MAX_SUMMARY_ROWS = 7` — drill-down/summary tables never show more than these counts of rows without an explicit follow-up.

---

## 6. Canonical action-label registry (`skills/agent-child-care-payment-advisor/references/action-labels.md`)

Single source of truth for every provider-facing Next Action label, rendered identically by BOTH `server.ts` and `next_action_ranking.py`. Format: `` `[Verb] [2-4 word object] — [qualifier]` `` using an em dash (`—`, U+2014 — not a hyphen), sentence case, no trailing punctuation, no parenthetical reason in the label itself. Fixed verb vocabulary: `Review` (opens a detail/drill-down view of a risk/exception), `Open` (opens a summary/page that is not itself a risk), `Compare` (a by-county or by-child breakdown of the same underlying data), `Retry` (re-runs a blocked/failed capability). `Confirm` is explicitly banned as a verb — the provider/agent can only *review* pending/confirmed/outside-window days; parent confirmation happens in the parent portal, not here.

| `action_id` | Canonical label | Qualifier source |
| --- | --- | --- |
| `review-absence-limit-risk` | `Review absence-limit risk — {N} children` | children over/near limit |
| `review-approaching-absence-limit` | `Review approaching absence limits — {N} children` | children approaching (not yet over) limit |
| `review-pending-parent-confirmations` | `Review pending confirmations — {N} days` | pending confirmation day count |
| `review-incomplete-attendance` | `Review incomplete attendance — {N} records` | incomplete check-in/out record count |
| `review-attendance-records` | `Review attendance records` | generic fallback, no specific risk qualifies |
| `open-attendance-detail` | `Open highest-impact attendance detail` | none |
| `review-next-payout` | `Open next payout summary` | none |
| `retry-payment-analysis` | `Retry payment review` | none |
| `review-conditional-payment` | `Review conditional payment — ~ ${amount}` | conditional amount at risk |
| `review-excluded-payment-days` | `Review excluded payment days` | none |
| `next-payment-detail-page` | `Open next payment detail page` | none |
| `open-payment-detail` | `Open highest-impact child payment detail` | none — used ONLY when a verified dollar ranking exists |
| `open-highest-hours-child-detail` | `Open highest-scheduled-hours child detail` | none — used ONLY when no child has a verified `amount_at_risk`/`total_amount`; the response body must say explicitly that the ranking is by hours, not dollars |
| `review-payment-summary` | `Compare payment by county` | none — resolved from the cached county composition table, not a new tool call |
| `missing-fiscal-rate` | `Review unmatched fiscal rates` | none |
| `review-absence-limit` | `Review absence-limit days` | none |
| `review-drop-in-limit` | `Review drop-in-limit days` | none |
| `confirm-pending-attendance` | `Review pending confirmations` | none |
| `review-holiday-plan` | `Review the county holiday plan` | none |

Rendering rule: the rendered line is exactly `{n}. {canonical label}` — the `reason` field on each action object is internal ranking/telemetry metadata and is NEVER appended to the rendered line. Next Actions numbering restarts at 1 on every response and is scoped to that single turn only (never persisted/reused). A provider selects an action either by number (resolves against the CURRENT turn's list only) or by typing the label text (case-insensitive, leading verb optional; ambiguous partial matches trigger one clarifying question rather than a guess).

---

## 7. Hardcoded values / magic numbers inventory (single consolidated list)

| Value | Where | Meaning |
| --- | --- | --- |
| `15 * 60 * 1000` ms (15 min) | `client.ts::readCacheTtlMs` | Salesforce read cache TTL |
| `100` | `client.ts::readCacheMaxEntries` | Max cached read entries (LRU by insertion time) |
| `100` | `conversation-context.ts::maxEntries` (default option) | Max stored `contextRef` entries |
| `1_000_000` bytes | `conversation-context.ts::maxBytes` (default option) | Max stored conversation-context bytes before eviction |
| `15 * 60 * 1000` ms (15 min) | `conversation-context.ts::ttlMs` (default option) | `contextRef`/`actionRef` follow-up TTL |
| `60_000` ms (60s) | `sf-cli.ts::CLI_TIMEOUT_MS` | Salesforce CLI command timeout (SIGKILL) |
| `5_000_000` bytes (5MB) | `sf-cli.ts::MAX_CAPTURED_OUTPUT_BYTES` | CLI stdout/stderr capture cap |
| `30_000` ms (30s) | `payment-orchestration.ts::PAYMENT_EVALUATOR_TIMEOUT_MS` | Python payment-engine subprocess timeout (SIGKILL) |
| `10_000_000` bytes (10MB) | `payment-orchestration.ts::PAYMENT_EVALUATOR_MAX_BUFFER_BYTES` | Python subprocess stdout buffer cap |
| `25` / `100` | `payment-orchestration.ts` detail pagination | Default `detailPageSize` / hard cap |
| `31` days | request schema for `CUSTOM_RANGE` | Max custom payout range span |
| `2` | `server.ts::MAX_NEXT_ACTIONS` | Max Next Actions shown per response |
| `10` | `server.ts::MAX_DISPLAY_CHILDREN` | Max child rows in a drill-down table before "ask for more" |
| `7` | `server.ts::MAX_SUMMARY_ROWS` | Max rows in a summary table |
| `5` | `evaluate_attendance_risks.py::CONFIRMATION_WINDOW_DAYS` | Days a parent has to confirm attendance before it becomes an "absence day" |
| `<=2` remaining days | `evaluate_attendance_risks.py` | Threshold for `ABSENCE_LIMIT_APPROACHING` risk code |
| `3000` / `2000` / `1000` | `next_action_ranking.py::_PAYMENT_IMPACT_BASE`/`_URGENCY_BASE`/`_SOURCE_RECOVERY_BASE` | Fixed priority-band scoring (not a pure dollar sort — see Section 9) |
| `+80` / `+60` / `+3`/day / `+2`/day | `next_action_ranking.py` scoring adjustments | `PARENT_CONFIRMATION_PENDING`, `INCOMPLETE_ATTENDANCE_RECORD`, per absence day, per pending-confirmation day |
| `10` allow-listed actions | `sf-cli.ts::allowedActions` | The complete allow-list of Apex REST actions this server can ever invoke |
| `provider-risk-payment-v1` | `payment-schema.ts` / `provider_risk_payment_engine.py` | Canonical payload/rule version string — any rule change must bump this |
| `1,13,19,25,31,37,43,55,91` | `fiscal-rate-normalizer.ts` | Canonical rate-type codes |
| `1`-`8` / `1`-`5` | `fiscal-rate-normalizer.ts` | Age-group codes / care-unit codes |
| `1=Pending,2=Authorized,3=Attended,4=Paid,5=Care Not Offered` | canonical adapters | Encumbrance status codes |
| `1,2,3=REQUESTED; 4=PAID` | `payment-canonical-adapter.ts` | Sub-payment status code mapping |
| `Level 1`-`Level 5` -> tier `1`-`5` | canonical adapters | Provider quality-tier mapping |

## 8. Configuration and launch

**`.vscode/mcp.json`** declares the `cccapprovider` server: stdio command `node ${workspaceFolder}/mcp/cccap-provider-api/dist/index.js`, `cwd: ${workspaceFolder}/CHATS_SIT`, env `SF_TARGET_ORG=CHATS_SIT`, `CCCAP_PROVIDER_DISPLAY_NAME=Shashank`. **`.vscode/settings.json`** sets `chat.mcp.autostart: true`.

**`mcp/cccap-provider-api/package.json`** scripts: `build` = `tsc -p tsconfig.json`; `typecheck` = `tsc -p tsconfig.json --noEmit`; `typecheck:test` = `tsc -p tsconfig.test.json`; `test` = `tsx --test test/**/*.test.ts`; `protocol` = `node scripts/list-tools.mjs`; `smoke`/`smoke:conversation`/`smoke:snapshot` = dev smoke scripts; `start` = `node dist/index.js`. Runtime deps: `@modelcontextprotocol/server@2.0.0`, `zod@4.5.4`. Dev deps: `@modelcontextprotocol/client@^2.0.0`, `@types/node@26.4.1`, `tsx@4.23.13`, `typescript@7.0.2`.

**`tsconfig.json`**: target `ES2023`, module/resolution `NodeNext`, `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`, `rootDir: src`, `outDir: dist`.

**`dist/`** is 100% generated (compiled from `src/`) — never hand-edit it; after any `src/` change run `npm run build` then, in VS Code, **MCP: Reset Cached Tools** followed by restarting `cccapprovider` from **MCP: List Servers**, or the running server keeps serving the old compiled code.

**Python subprocess invocation**: every evaluator is run via `uv run <script.py> <input.json>` — `uv` (not bare `python`) must be on `PATH`; if it is missing, `payment-orchestration.ts` raises `"Payment engine is unavailable: the uv/python runtime could not be started."` This is a hard external dependency with no fallback.

---

## 9. Architecture governance rules (from `skills/ARCHITECTURE.md`)

- **Canonical Data Rule**: raw Salesforce/external-source objects may exist ONLY inside transport and source-normalization adapters. Capability orchestration and Python evaluators must consume named canonical contracts, never raw field names.
- A canonical contract must define: stable internal identifiers/relationship keys; ISO dates and explicit numeric units; normalized statuses/classifications; source/retrieved-at/effective-date/rule-version provenance; readiness/blocking information for absent or ambiguous fields.
- **Capability build checklist** (for any new capability): define the provider decision + narrowest MCP tool -> define canonical input/provider-safe output -> map source fields in one adapter boundary -> reject missing/stale/ambiguous relationships before processing -> pass canonical data to the deterministic evaluator -> format one result + 1-2 grounded next views -> add a normalizer test + end-to-end capability test -> update the reference contract and the ownership map.
- **Change routing discipline**: new intent/follow-up -> `carepay-intent-routing`; new attendance/payment meaning -> the owning capability skill + evaluator contract; new source field/relationship -> `references/schema-mapping.json` + the owning normalizer; new response shape/failure behavior -> `carepay-conversation-templates` + the MCP formatter; new deterministic rule -> the Python evaluator + `rule-governance.md`. The same rule must never be duplicated across two skills — link to the owning module instead.

---

## 10. Testing and evaluation

- **Python unit tests**: `skills/agent-child-care-payment-advisor/scripts/tests/*.py` — 97 tests total (`test_analyze_attendance_transactions.py`, `test_calculate_payout.py`, `test_evaluate_attendance_risks.py`, `test_next_action_ranking.py`, `test_provider_risk_payment_engine.py`), run with `pytest` (no `SeeAllData`/Salesforce dependency — pure input-JSON fixtures). All 97 passed as of the last change in this repo's history.
- **TypeScript tests**: `mcp/cccap-provider-api/test/**/*.test.ts`, run via `npm test` (`tsx --test`). `npm run typecheck` / `npm run build` (`tsc`) is the fastest signal that a `server.ts`/orchestration change compiles.
- **Smoke scripts**: `scripts/provider-conversation-smoke.mjs`, `scripts/snapshot-smoke.mjs`, `scripts/list-tools.mjs` (`npm run smoke*`, `npm run protocol`) — exercise the live MCP protocol surface against a real/dev org, not unit-level.
- **Prompt-level evals**: `skills/agent-child-care-payment-advisor/evals/cases.json`, `evals/queries.json`, `evals/files/denver-case.json` — fixture-driven conversational eval cases; historical run artifacts live under `skills/reports/eval-runs/<timestamp>-evals/` (both a "bare" baseline and a "skill"-loaded run per case, with `timing.json`/`execution-summary.json`/`run.json` outputs) — this is how prompt/skill changes were regression-tested against real conversational transcripts before this review cycle.
- **Transcript-based manual review**: `chat_experiences_for_review/*.md` are real exported conversations reviewed by hand against the intended design; `Improvement to be done/childcare-agent-improvement-spec.md` is the resulting backlog. This is currently the PRIMARY mechanism for catching UX-level defects (e.g. the "highest impact child showed $0 at risk" bug) — there is no automated assertion today that a rendered response's "highest impact" label actually matches the largest dollar figure in its own tables.

---

## 11. Considerations for the next architect (known weak points, not yet fixed further than noted)

**Structural**
- `server.ts` (~1990 lines) is a single file owning tool registration AND all provider-facing text rendering for every capability. Every UX-wording change (tables, disclaimers, headers) requires editing this one file, which is both a merge-conflict risk and a "does the LLM/architect actually understand the blast radius of one edit" risk. Splitting per-capability formatters into separate files (payment-formatter.ts, attendance-formatter.ts, snapshot-formatter.ts) would reduce this without changing behavior.
- Two independent "next action" ranking implementations exist with DIFFERENT logic: `payment-orchestration.ts::highestImpactChildName` now ranks strictly by dollars (3-tier, fixed this cycle) but `next_action_ranking.py` still ranks by fixed priority bands (3000/2000/1000) + ad-hoc point additions, not a pure dollar sort. These two "priority" concepts can disagree with each other in the same conversation (one governs which CHILD is drilled into, the other governs which ACTION is listed first) — worth unifying into one ranking contract.
- All conversation continuation state (`dialogue-state.ts`, `conversation-context.ts`) is **process-local, in-memory, non-persistent**: restarting the MCP server (e.g. after any `src/` change + rebuild) invalidates every open `contextRef`/`actionRef` in every active conversation. There is no persistence layer (no DB, no file-backed store) — by design, given the security/telemetry constraints, but worth flagging to an architect evaluating reliability across dev-loop restarts.
- The Python subprocess boundary (`uv run <script> <tmpfile>`) adds real per-call latency (process spawn + interpreter startup) and a hard external dependency on `uv` being on `PATH` with no fallback and no health-check; a warm long-running Python service (or porting the deterministic math to TS) would remove this but was an explicit architectural choice to keep money/date math outside the LLM's TS surface and independently unit-testable.
- `readOnlyAnnotations` (in `server.ts`) hardcodes every tool as `readOnlyHint/idempotentHint: true, destructiveHint: false, openWorldHint: true` — there is currently no write-capable tool anywhere in this server; any future write capability (e.g. actually submitting a parent-confirmation reminder) would need a new trust/consent model, not an extension of the existing tool set.

**Functional/UX** (superset of, and cross-referenced with, `Improvement to be done/childcare-agent-improvement-spec.md`)
- Host-level tool-call telemetry ("Updated todo list", "Ran [tool] — Completed with input: {...}") is rendered by VS Code Copilot Chat itself, NOT by this repo's agent text — no prompt change in this codebase can suppress it; a genuinely different host/surface (or a Copilot Chat extension setting, if one exists) would be needed to fully close this gap. This has been re-confirmed and written down explicitly in `skills/carepay-conversation-templates/SKILL.md` as of the 360-degree redesign handoff (Workstream 7) - treat any future ticket asking to 'suppress tool telemetry' as already answered by that scope-boundary note, not as new engineering work.
- The "compare payment by county" capability is currently defined ENTIRELY as a re-presentation of data already fetched for `NEXT_PAYOUT`/`CUSTOM_RANGE` — there is no dedicated "true" comparison capability (e.g. period N vs period N-1, or a genuinely fresh multi-county fetch); if a provider asks to compare two service periods, the system still has to say "not supported, pick one period."
- `next_action_ranking.py`'s fixed-band scoring (Section 7) has never been validated against real dollar amounts the way the payment-side ranking now is — an architect revisiting "what should be first in the Next Actions list" should treat this as the next likely inconsistency to resolve.
- Deadline/countdown surfacing (this cycle's fix) only covers the `evaluate_attendance_risks.py` pending-confirmation path; `provider_risk_payment_engine.py`'s day-level Expected/Forecasted/At-risk classification does NOT yet expose a per-day or per-authorization deadline, so a payment-side response still cannot say "this specific day's window closes on X" — only the attendance-risk response can.
- No field-level, automated regression check exists asserting "the label rendered says highest-impact and the amount shown for that entity is in fact the maximum across the response's own tables" — this class of bug (label/data mismatch) was caught only by manual transcript review, and would benefit from a lightweight assertion in the eval fixtures under `skills/agent-child-care-payment-advisor/evals/`.
- The greeting snapshot and the payment/attendance drill-downs use different vocabularies for the same underlying concept in places (e.g. `amount_at_risk` at the day level in Python vs. `at_risk_amount` vs. `conditional_amount` vs. `potential_impact` at various points across the pipeline) — the terms are internally consistent within each file but a full end-to-end synonym table would help a future contributor avoid re-introducing an amount-labeling bug like the one fixed this cycle.

---

## 12. Glossary (domain + system terms)

| Term | Meaning |
| --- | --- |
| CCCAP | Colorado Child Care Assistance Program — the subsidy program this whole system reports on. |
| Provider | A day-care/child-care business (the human user of this agent — a director/owner, non-technical). |
| Authorization | A county-approved record entitling a specific child to subsidized care under specific terms/dates/rate type. |
| Service period | A Salesforce-defined date range used to anchor a payout cycle. |
| Conditional (amount) | Approved pending parent confirmation — money that may still be paid but isn't guaranteed yet. |
| Confirmed | The parent has verified the attendance record; money in this state is not further at risk from confirmation. |
| Expected / Forecasted / At-risk | Payment-engine's 3-way day classification: Expected = confirmation window elapsed, not excluded/limit-exceeded (optimistically payable); Forecasted = still within the window or a future scheduled date (may change); At-risk = excluded (unmatched rate/authorization) or limit-exceeded. |
| Vacant slot | A contracted slot the provider held open with no child attending; paid under separate rules from attendance-based care. |
| Drop-in | Unscheduled care provided outside a child's regular authorization. |
| Excluded authorization | An authorization whose rate could not be matched, so its days are left out of the payment total. |
| Absence (paid) / Enrollment absence | A scheduled day the child did not attend but remains eligible for reimbursement, vs. an absence counted against authorized enrollment rather than a specific date. |
| Confirmation window | The 5-day (`CONFIRMATION_WINDOW_DAYS`) period after a service date during which a parent can still confirm attendance before it becomes a counted "absence day." |
| `contextRef` / `actionRef` | Opaque, process-local, TTL-bound tokens the model must pass back (never the raw filters) to safely re-run a previously-offered follow-up action without re-inventing scope. |
| `rule_version` (e.g. `provider-risk-payment-v1`) | A stamped version string on every canonical payload/evaluator result; any change to deterministic business rules must bump this so stale cached results are never silently reinterpreted under new rules. |
| Fail-closed | This codebase's dominant safety posture: any ambiguous, missing, or conflicting relationship produces an explicit "blocked"/"unresolved"/"unavailable" result rather than a best-effort guess — applies to rate matching, county filters, authorization joins, and payment classification alike. |
| Composite (MCP) tool | A single high-level tool (e.g. `cccap_analyze_payment`) that internally performs provider initialization + all required source reads + evaluator invocation, so the model never has to manually orchestrate the lower-level primitive tools for a common request. |

---

*This document was generated by reading the full agent/skill/MCP/Python source tree and prior transcript-review fixes as of the `Redesigned_provider_assist` branch. It reflects the CURRENT implemented state after this session's fixes (dollar-based highest-impact ranking, confirmation deadlines, deduplicated risk tables, cached-result county comparison, bottom-line-first/period-header/jargon-gloss/triage-list presentation rules). Re-verify any specific file/line reference against the live source before making a change — this document is a map, not a substitute for reading the file being edited.*

__________________________GenAI: Generated code ends here______________________________