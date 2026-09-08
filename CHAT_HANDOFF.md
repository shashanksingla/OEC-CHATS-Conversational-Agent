# Provider Assist Comprehensive Handoff

**Prepared:** 2026-09-05

Read this document before continuing work in a new chat. It records the product decisions, implementation chronology, false starts, operating constraints, current state, verification evidence, and remaining work.

## Product Contract

Provider Assist is a read-only, authenticated CCCAP assistant for child-care providers. It should tell a provider what matters first: attendance risks, parent confirmations, absence-limit exposure, then payment timing or forecasts when source data supports them.

It must:

- Use only the authenticated provider's authorized data.
- Never request or accept a provider ID from the chat model.
- Explain facts conversationally, use tables for comparable details, and offer one or two evidence-based next actions.
- Remain read-only: no record updates, submissions, confirmations, or parent contact.
- Fail professionally: never replace failed data with an `Unavailable` dashboard, stale values, placeholder counts, or invented payment conclusions.
- Keep deterministic joins, classifications, dates, policies, counters, and money calculations out of the LLM.

## Final Architecture

| Layer | Responsibility | Must not do |
| --- | --- | --- |
| Copilot agent | Interpret provider language, route each turn, explain a verified result | Calculate, join records, choose provider identity, write data |
| Specialized skills | Conversation template, intent routing, attendance, payment readiness, data quality | Become source-of-truth business calculators |
| MCP adapter | Salesforce CLI transport, identity resolution, scope injection, validation, normalization, safe tool output | Trust model-supplied IDs or provide unrestricted API access |
| Apex REST | Authoritative, read-only retrieval and secondary scope guard | Interpret conversational intent |
| Python | Deterministic attendance and payment evaluation | Fetch Salesforce data or make conversational decisions |

```text
Provider request -> intent routing -> narrow read-only MCP tool -> authorized API data
                 -> MCP normalization -> deterministic Python -> provider-safe response
```

## Agent and Skill Layout

| File | Purpose |
| --- | --- |
| `.github/agents/carepay-advisor.agent.md` | Selectable VS Code agent, MCP-only tool allowlist, one greeting-entry instruction. |
| `skills/agent-child-care-payment-advisor/SKILL.md` | Main CarePay persona, common guardrails, skill routing, numeric follow-up behavior. |
| `skills/carepay-conversation-templates/SKILL.md` | Authenticated-provider templates, tables, next actions, read-only boundaries, professional failure behavior. |
| `skills/carepay-intent-routing/SKILL.md` | Per-turn classification: follow-up, refinement, new supported request, ambiguity, digression, or out-of-scope request. |
| `skills/carepay-attendance-readiness/SKILL.md` | Attendance, confirmation, absence-limit, exception, and child-detail behavior. |
| `skills/carepay-payment-readiness/SKILL.md` | Payout-date behavior and strict block on unsupported live monetary claims. |
| `skills/carepay-data-quality/SKILL.md` | Missing, stale, malformed, conflicting, or inaccessible data handling. |
| `carepay-agent-file-usage.md` | Agent/MCP file hierarchy reference. Includes MCP but intentionally excludes Salesforce project-repository inventory. |

`references/` is for client/project contracts and rules, not prompt fragments:

- `api-response-contract.json`: MCP/API response capability and gap contract.
- `schema-mapping.json`: source-of-truth Salesforce and external-source object fields/relationships.
- `integration-contract.md`: integration semantics and known source boundaries.
- `attendance-transaction-rules.md`: versioned transaction attendance rule interpretation.
- `rule-governance.md`: policy approval and provenance requirements.
- `setup-guide.md`: setup and production gating.

Earlier files named `conversation-experience.md`, `intent-resolver.md`, `payment-analysis.md`, `data-integrity.md`, `prompt-quality-canon.md`, and `agent-schema-contract.json` were removed or renamed because they caused prompt drift. Their useful content was moved into specialized skills or the project-named API contract. Do not recreate those old behavior reference files.

## MCP and Authentication

The custom stdio MCP server is `mcp/cccap-provider-api`; VS Code registers it as `cccapprovider` in `.vscode/mcp.json` and launches `dist/index.js` from the `CHATS_SIT` working directory with `SF_TARGET_ORG=CHATS_SIT`.

Why custom MCP exists:

- Generic Salesforce MCP could run SOQL but could not invoke arbitrary `@RestResource` endpoints.
- A direct bearer-token approach failed with HTTP 401 and would have put token handling in Node.
- The final adapter uses `sf api request rest`, JSON via stdin, and the existing Salesforce CLI session. Do not log token/header values.
- On Windows, `sf.cmd` needed Windows-safe process invocation rather than plain `execFile` behavior.

Identity and scope:

1. `sf` resolves authenticated username.
2. MCP resolves that user's Salesforce `User.Id` internally.
3. `cccap_initialize_provider` calls `getProviderData` and captures permitted provider IDs, provider external names, county IDs, and fiscal-rate schedule IDs in MCP process memory.
4. Provider-specific calls inject these values; model input cannot override them.

Read context cache:

- The MCP process is long-lived for the VS Code session. `CccapClient` now caches successful read results in provider-scoped process memory using the action and exact request scope as the key.
- Identical initialization, cases, authorizations, county plans, schedules, fiscal rates, service periods, and holiday reads reuse the cached source payload instead of making another Salesforce request.
- A changed date range, county, authorization, child, or other request field produces a new key and retrieves fresh data. This is a session cache, not durable storage; restarting MCP clears it.
- The model must answer context questions from verified conversation results and must not repeat an identical tool call in one turn. Numbered actions bind only to the immediately preceding response; a response without actions requires clarification.

Critical identifier-routing lesson:

| Endpoint | Provider identifier |
| --- | --- |
| `getCaseData` | Numeric external provider `Name` |
| `getAuthData`, `getSchedules`, `getFiscalRates` | Salesforce provider record `Id` |

Earlier code mistakenly sent a Salesforce provider ID to the numeric case filter. This was corrected. Preserve this split.

MCP SDK lesson: version 2.0.0 tool registration expects raw Zod object shapes in `inputSchema` (for example, `schema.shape`), not a complete Zod object. This was fixed after a typecheck failure.

## Available MCP Tools

Current read-only tool surface includes initialization, source retrieval, snapshot/analysis, and fiscal-rate retrieval. Run `npm run protocol` from `mcp/cccap-provider-api` to verify the exact discovery output.

| Tool | Role |
| --- | --- |
| `cccap_initialize_provider` | Establish authenticated provider scope. |
| `cccap_get_current_month_risk_snapshot` | One-call greeting snapshot. Returns final provider Markdown as primary text. |
| `cccap_analyze_attendance_risk` | Generalized facility or child-scoped attendance analysis. Returns a provider-ready table. |
| `cccap_get_cases` | Explicit case/enrollment requests only. Do not use for attendance details already returned by the analyzer. |
| `cccap_get_authorizations` | Explicit authorization questions; supports `caseIds`. |
| `cccap_get_county_rate_plans` | County absence/drop-in/holiday policy. |
| `cccap_get_schedules` | External DECL schedule source, including nested attendance records. |
| `cccap_get_service_periods` | Current/upcoming payout dates and processing/release timing. |
| `cccap_get_holidays` | Holiday dates. |
| `cccap_get_fiscal_rates` | Scoped raw fiscal schedules, fiscal rate rows, and fee rows. Does not calculate payout. |

Tool error behavior is standardized: server errors return a provider-safe structured error with capability, generic no-result message, and recovery actions. No Salesforce exception text, CLI output, IDs, request payloads, stack traces, or secrets should reach provider chat.

## Conversation Behavior and Lessons

### Per-turn intent resolver

The user explicitly requested a guardrail on **every new prompt**. The resolver skill classifies each message as:

- Direct follow-up or numeric action from the immediately preceding response.
- Refinement of child/date/county/detail scope.
- New supported request.
- Genuine ambiguity needing one concise clarification question.
- Unsupported or digressive request.
- Read-only/safety boundary request.

It selects a narrow capability, extracts only explicit child names/dates/counties, and refreshes when capability, child, county, date, detail level, or freshness needs change. Prior data may explain a follow-up but must not silently become fresh facts.

| Provider language | Correct route |
| --- | --- |
| `Hi` | Greeting snapshot exactly once. |
| Any follow-up selection or reference | Match its meaning to the immediately preceding response's action intents and attached scope, independent of wording or presentation format. For confirmation/attendance detail, use attendance analysis, not cases; if the match is absent or ambiguous, ask one clarification question and make no data call. |
| `Review absence risks` | Attendance analyzer with appropriate date scope. |
| `When is my next payout?` | `cccap_get_service_periods` with `paymentAfter: "TODAY"`, `limitOne: true`. |
| `What will I get paid?` | Explain live amount/forecast is blocked until complete canonical sources are provided. Do not estimate. |
| `Review` after an agent response | Refresh/review relevant provider data, never local files. |

### Greeting snapshot

The desired first response has two separate concepts:

1. **Today's operational snapshot:** unique scheduled and checked-in children for the as-of date.
2. **Current-month payment-readiness risk:** evaluation through the same as-of date.

The first load must be a single MCP tool. Internally it initializes scope, retrieves current month plans/schedules, builds temporary Python input, runs deterministic evaluation, cleans up, and returns the complete provider-facing Markdown.

The visible table always has exactly these three rows:

1. Pending parent confirmations: days and children.
2. Children approaching county monthly absence limits: children, counties, and days to threshold when known.
3. Children crossed county absence limits: children, counties, and days over limit.

Zero-risk rows stay visible but simple, with `None` as their suggested action. They must not imply review work where no risk exists. Next actions are exactly one or two grounded actions, not a static menu. `View next payout details` is the payment-related action where appropriate.

### Drill-down tables

For affected-child detail, show one row per child with child name, household name, county, authorization name, service dates, precise note, and potential impact. Follow-up actions must map to displayed authorization names, counties, attendance findings, or payout timing. Offer authorization drill-down only when authorization names were returned; offer county-policy drill-down only when county values were returned; otherwise use the relevant attendance review or payout action. Only display fields actually returned. A missing field may say `Unavailable from the current source` in a **successful partial result**, but never turn a failed tool call into a fake dashboard.

### Failure behavior

If any MCP call, Salesforce request, external service, normalization, validation, or Python processing fails:

- Stop the affected response.
- Do not show partial tables, stale counts, placeholder values, or payment conclusions.
- Identify the affected provider capability in plain language.
- State that no result was produced.
- Give one or two recovery actions.
- Keep prior unrelated facts only if explicitly labelled as earlier context.

Repeated runtime issues and fixes:

| Symptom | Root cause / resolution |
| --- | --- |
| Generic greeting, no snapshot | Malformed agent YAML/behavior placement and later stale build; frontmatter restored and behavior moved to body/skill. |
| Terminal/file commands and approvals | First snapshot used agent-created JSON and Python command. Moved composition into MCP. VS Code trust UI cannot be suppressed by prompts. |
| Snapshot only said `Greetings.` | Stale `dist` artifact. Rebuild MCP after TypeScript changes. |
| Snapshot appeared as opaque attachment or `Hi` | JSON plus structured content confused Copilot. Greeting tool now returns provider Markdown as primary plain text only. |
| `Unavailable` dashboard after failed call | Stale agent fallback text told model to create it. Removed it and added universal failure policy. |
| Duplicate greeting calls | Greeting instruction existed in multiple skills. Entrypoint now owns execution; downstream skills display result only. |
| Action `1.` fetched cases then claimed no detail | Analyzer already had child rows but returned bulky JSON. It now returns deterministic provider-ready child table; agent avoids unnecessary cases lookup. |

## Attendance Data and Deterministic Rules

There are two attendance analyzers with distinct maturity:

| Script | Status and responsibility |
| --- | --- |
| `evaluate_attendance_risks.py` | Current snapshot/general analyzer using schedule aggregate fields. Computes today's counts, five-day confirmation window, probable absences, incomplete records, absence-limit categories, and drill-down metadata. |
| `analyze_attendance_transactions.py` | Richer transaction-level analyzer from supplied attendance rules. Applies schedule validity, authorized hours, transaction validity/type, attended hours, drop-in, anomaly, and provider-scoped county rules. |

Important evolution:

- An early evaluator used schedule aggregate counts only.
- User-supplied attendance rules and scenarios drove richer transaction logic with hermetic fixture coverage.
- Direct Apex `getAttendanceAnalysisData` was temporarily added, then removed because `getSchedules` already supplies related transactions.
- Confirmed API relationship: `schedules[*].Attendance__r.records[*]`.
- MCP `attendance-snapshot.ts` normalizes nested transactions to the Python contract. It maps documented aliases, check-in/out record types, parent status, schedule link, timestamps, authorized hours, and service date.
- The normalizer fails closed for incompatible relationship shapes rather than inferring attendance.

External API naming rule: use plain `__c` names such as `Schedule__c`, `CHATS_Case__c`, `Status__c`, `Sub_Type__c`, `CI_Transaction_ID__c`, `CI_Attendance_Date__c`, and `CI_Attendance_Hours__c`. Do not use metadata-wrapper spellings such as `Schedule_c__c` in external API mapping.

The richer transaction analyzer intentionally still lists unimplemented rules requiring unavailable/conflicting information, including cross-provider county-wide aggregates, unresolved overnight splitting, orphan matching, and some 36-month interpretation details. Current policy choice is provider-scoped counters.

## Payment Engine and Rule Decisions

The canonical engine is `scripts/provider_risk_payment_engine.py`, rule version `provider-risk-payment-v1`. It was created to avoid extending a legacy fixture calculator as if it were live production logic.

It currently supports canonical-input evaluation and safe block/duplicate conditions:

- Deterministic date and currency handling.
- Valid service-period bounds.
- Attendance classification and paid tier determination.
- Under-36 effective flag, with date-of-birth fallback logic.
- Over-36 tier based on lower of authorized and attended hours; excess attendance is flagged without raising paid tier.
- Provider-scoped absence/drop-in counters.
- Pending confirmations as conditional amounts only in complete canonical test inputs.
- Observed holiday plus occupied slot contract as `Slot Contract Holiday`.
- Missing confirmation data as blocked, not unpaid or inferred.
- Missing/ambiguous fiscal rates as blocked.
- Existing `REQUESTED` or `PAID` matching as duplicate guard with no amount.
- Out-of-period attendance days and invalid service periods as blocked.

The old `calculate_payout.py` remains a **legacy normalized fixture** calculator and returns:

```json
{
  "source_contract": "legacy_normalized_fixture",
  "production_ready": false
}
```

Do not enable provider-facing payout amounts or forecast amounts through it.

The live MCP attendance result includes `paymentReadiness` with `BLOCKED_MISSING_REQUIRED_INPUTS`. Fiscal rates are no longer missing, but live payout remains blocked until all canonical source mappings exist.

## Source Object and API Understanding

`schema-mapping.json` is the source-of-truth source map. Confirmed main relationships:

```text
Provider
  -> Fiscal Agreement (ID_SERVICE__c)
  -> Rate Schedule (IDN_AGRMT_FISCAL__c / external IDN_EXTNL__c)
  -> Fiscal Rate (external idn_fiscal_sch__c -> schedule external ID)
  -> Fiscal Rate Fee (IDN_FISCAL_SCH__c -> Salesforce rate schedule record)

Provider -> CHATS Case (numeric Provider.Name -> IDN_PROVR__c)
CHATS Case -> Case Individual
Authorization -> CHATS Case, Provider, County, Child
Schedule -> Attendance__r.records
Transaction -> Schedule and CHATS Case external identifiers
```

Other findings:

- `T_SBSD_CASE__c.Id` is authoritative CHATS case identity. Avoid a separate `PaymentCase` identity.
- `CDE_COUNTY__c` lookup/record ID and external county code are distinct.
- Service periods lack an affirmed provider/case lookup.
- Holidays lack a confirmed county lookup; applicability is policy-driven.
- `getAuthData` returns raw SObjects; its `toLabel` status expression needs response-key verification before strict normalization.
- `getSchedules` is a DECL pass-through and remains the attendance source.

## Fiscal-Rate Retrieval

Implemented in Apex and MCP:

1. `getProviderData` returns authorized active fiscal agreement/rate schedule headers, including `IDN_EXTNL__c`.
2. MCP retains only those schedule external IDs after initialization.
3. `cccap_get_fiscal_rates` calls `getFiscalRates` with only captured scope.
4. Apex re-derives active provider agreements and effective schedules, filters requested schedule IDs, then retrieves raw rows from `batchsit_t_fiscal_rate__x` and `T_FISCAL_RAT_FEES__c`.
5. Response keys: `fiscalSchedules`, `fiscalRates`, `fiscalRateFees`.

It is raw retrieval only. It does not resolve a rate or calculate a payout.

Specific Apex lesson: `batchsit_t_fiscal_rate__x` cannot be queried for `Name`. An attempted query caused a compile/validation failure; removal fixed the deployment.

## Chronology

1. Product/architecture discovery established read-only authenticated provider assistance and risk-first priority.
2. Initial BMad skill and deterministic Python baseline were created.
3. A GitHub Copilot custom agent was added.
4. Generic Salesforce MCP limitation prompted dedicated custom MCP adapter.
5. Salesforce CLI REST transport replaced direct token handling after 401 and token-safety concerns.
6. Authenticated username-to-`User.Id` resolution removed provider-ID prompt.
7. Provider ID routing was corrected by endpoint.
8. First-load orchestration moved from Copilot terminal/files into one MCP snapshot tool.
9. Snapshot presentation evolved into two data concepts, three fixed risk rows, table-driven output, and dynamic next actions.
10. Agent behavior was cleaned from reference-file sprawl into specialized skills and an intent-routing skill.
11. Attendance drill-down moved into deterministic MCP output so child detail did not depend on LLM JSON interpretation.
12. Salesforce metadata and real API response shape were audited; source map and API contract were cleaned.
13. Legacy payment fixture logic was explicitly marked non-production.
14. User-supplied rules/workbook scenarios informed canonical risk/payment engine and policy choices.
15. Direct temporary Apex attendance normalizer was reverted; MCP normalizes `Attendance__r.records` from `getSchedules`.
16. Fiscal rate retrieval was added, validated, and documented. Live payout remains intentionally blocked.

## Validation and Operations

Latest fiscal work:

- 18 MCP tests passed.
- MCP typecheck and build passed.
- Contract JSON parsed.
- Salesforce validation-only deployment passed after removing `Name` from the external rate query.

Earlier checkpoints included 27 transaction-attendance tests, 48 broader Python tests, protocol discovery, live initialization/case split-ID smoke tests, and BMad path/script scans. Always rerun current checks; counts changed during development.

```powershell
Set-Location "mcp\cccap-provider-api"
npm test
npm run typecheck
npm run build
npm run protocol

Set-Location "..\.."
uv run python skills\agent-child-care-payment-advisor\scripts\tests\test_evaluate_attendance_risks.py
uv run python skills\agent-child-care-payment-advisor\scripts\tests\test_analyze_attendance_transactions.py
uv run python skills\agent-child-care-payment-advisor\scripts\tests\test_provider_risk_payment_engine.py

Set-Location "CHATS_SIT"
sf project deploy start --source-dir force-app\main\default\classes\CccapPortalApiV1.cls --target-org CHATS_SIT --dry-run --wait 10 --json
```

Operational notes:

- Workspace root may not be a Git repository. Do not rely on Git output for validation.
- Salesforce CLI plugin warnings occurred but did not block validation-only deployment.
- Rebuild MCP `dist` after TypeScript edits, then run **MCP: Reset Cached Tools** and restart `cccapprovider` before manual Copilot testing.
- VS Code trust/approval and tool transparency cannot be hidden by prompts. An embedded production chat can abstract it; VS Code cannot.

## Current Open Work

Do not modify working attendance or fiscal retrieval while starting payment work. Recommended order:

1. Inspect real `getFiscalRates` response and save sanitized fixtures.
2. Normalize rate and fee rows into a versioned canonical input, not raw source names in Python.
3. Define rate-resolution precedence: rate type, age group, care unit, rating, effective date, provider/county/fiscal-agreement amounts.
4. Add authorized mappings/fixtures for existing sub-payments, slot contracts, parent fees, ART fees, and complete confirmation/payment history.
5. Confirm service-period anchor, adjustment/reversal semantics, source freshness, and provenance.
6. Feed complete normalized inputs to `provider_risk_payment_engine.py`.
7. Only then add live payout/forecast MCP tool and provider-facing monetary results.

## Non-Negotiable Guardrails

- Keep `mcp/cccap-provider-api` read-only.
- Keep provider/county validation in MCP and Apex.
- Do not log Salesforce tokens, authorization headers, provider user IDs, child data, or raw family data.
- Do not accept model-provided provider IDs, user IDs, county scopes, fiscal agreement IDs, or fiscal schedule IDs.
- Do not reintroduce `getAttendanceAnalysisData`; use `getSchedules` and nested `Attendance__r.records`.
- Do not remove payment readiness/`production_ready` gates merely because fiscal-rate retrieval works.
- Do not recreate stale behavior references outside specialized skills.
- Preserve the difference between a successful partial source field and a failed tool; only the former may label a table cell unavailable.

## Suggested New-Chat Prompt

> Read `CHAT_HANDOFF.md`. Preserve working attendance and fiscal-rate retrieval. Inspect a real sanitized `cccap_get_fiscal_rates` response, create rate/fee normalization fixtures and deterministic rate-resolution tests, and keep all live payout amounts blocked until complete payment inputs, provenance, and duplicate-payment safeguards are available.
