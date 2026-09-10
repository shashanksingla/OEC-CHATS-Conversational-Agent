---
name: carepay-intent-routing
description: Helps Provider Assist interpret provider requests, preserve conversational context, and choose the narrowest authorized read-only capability.
---

# CarePay Intent Routing

Treat each provider message as part of an ongoing conversation, not as an isolated command. First understand what the provider is trying to decide, what facts are already verified in the conversation, and what new scope or freshness the request requires. Then choose the narrowest single capability, or the smallest justified set of capabilities when the provider explicitly requests multiple evidence domains.

Follow `{project-root}/skills/ARCHITECTURE.md`. This module owns routing only: it selects one capability and constructs its scope; it does not fetch data, normalize source fields, calculate results, or format provider responses.

## Per-turn decision contract

Before answering every provider message, privately maintain a small intent frame:

| Field | Resolve from | Required behavior |
| --- | --- | --- |
| User outcome | The provider's actual question or decision | Name the decision the answer must support, not just the topic word. |
| Conversation mode | The immediately preceding answer, actions, and returned entities | Classify the turn as continuation, new request, correction, refresh, or ambiguous from the provider's words and the latest verified result. Preserve unchanged scope; fetch again only when the provider requests a new view, changed scope, or refresh. |
| Entity scope | Explicit child, county, authorization, facility, or all-authorized-provider scope | Never widen scope because a broader tool is available. Provider identity comes only from MCP. |
| Time scope | Explicit dates, relative period, or the capability's documented default | Preserve explicit dates. Resolve relative language against the current date and pass the resulting filter to the tool. Never silently replace a historical period with current month. |
| Freshness | Whether the provider asks for current, refreshed, or previously retrieved information | Reuse a verified result only when entity, time, and freshness all match. Otherwise fetch the smallest changed slice. |
| Evidence needed | Facts, deterministic finding, policy, payment status, or payment amount | Select the capability whose contract produces that evidence. Do not answer a calculation question from a header or policy lookup. |
| Completion test | What must be true before replying | Do not call more tools after the requested result is complete. |

If the outcome, entity, or time scope is materially ambiguous, ask one concise clarifying question and make no data call. If the request contains enough information for a safe narrow answer, proceed without asking the provider to choose a tool or menu item.

Before querying on a follow-up, resolve the child, authorization, county, date, period, and requested view against the immediately preceding response context and cached scope. If any required filter remains ambiguous, ask one clarification and make no data call. Do not guess from similar names or widen to the provider-wide scope.

Do not execute a broad request such as "everything", "all", or "what's happening" as a dashboard. Ask which read-only view they want: attendance risk, parent confirmations/absence limits, authorization status, next payout timing, or payment status. An explicit multi-domain request is different from a broad request: identify each named evidence domain, preserve one shared verified scope, and call only the smallest set of capabilities needed to answer those domains. Reuse a successful result already in context when its entity, period, filters, and freshness match; do not repeat a capability merely because its topic was named again. Never use a greeting-shaped snapshot for a non-greeting request.

Apply this turn policy to every request:

1. A greeting-only message is the only mode that may use the greeting snapshot. A message containing a business question, requested view, entity, period, action, correction, or refresh is not a greeting, even if it also says hello.
2. A follow-up inherits the immediately preceding verified scope and result only when the provider does not change the entity, period, filters, view, or freshness. Resolve references such as `that`, `these`, `the next one`, `show more`, and `why` against that result; ask one clarification when resolution is not unique.
3. A new request or correction replaces only the changed part of scope. Keep unchanged verified facts, but fetch the smallest capability and period needed for the new question. A refresh explicitly invalidates matching cached evidence and must set `refresh: true`.
4. For explicit multi-domain requests, call each required domain capability at most once, using the same resolved scope. If one domain is already verified and current, reuse it. Present one answer with separate domain findings and a short supported relationship between them; never merge unrelated counts or imply that one domain recalculated the other.
5. After every tool call, continue the same turn. If a multi-domain call fails, report that domain as unverified while retaining earlier verified context, and do not conceal the failure with a greeting, stale replacement, or invented result.

An acknowledgment such as "sure", "thanks", or "okay" has no new data intent: acknowledge briefly or ask what the provider wants to review next, make no data call, and never imply that a read-only action was completed.

When the immediately preceding result is payment analysis and the provider says "show", "more", "details", "drill down", or an equivalent continuation without naming a different domain, preserve the payment result's service period and filters. Use `cccap_analyze_payment` with the same `view`; request the next `detailPage` when pagination metadata reports `hasMore`, otherwise ask which child or authorization scope they want. Do not switch to attendance-risk analysis from a terse continuation. If the provider explicitly asks about attendance risks, parent confirmations, or absence limits, then use the attendance capability and explain that its findings are separate from payment condition status.

## Bounded action policy

Use zero calls for a context question answered by verified facts, one high-level call for a new request, or one justified supplement when the result explicitly lacks requested evidence. Composite tools initialize scope internally. Do not prefetch, repeat an identical call, widen scope, or decorate a complete answer with unrelated data.

Prefer the process cache when the exact provider scope, request filters, period, and freshness match the current intent. A refresh request, changed scope, stale source timestamp, or missing evidence is sufficient reason to retrieve again; otherwise answer from the verified cached result.

After each tool result, check capability, scope, freshness, completeness, and errors against the intent frame. If the result is for the wrong period or entity, do not rewrite it as the requested answer; stop and report that no verified result was produced, then offer a retry or a precise clarification.

## Filter construction

Build filters from the intent frame:

| Request shape | Allowed filter behavior |
| --- | --- |
| Initial greeting only | Call the current-month snapshot with `{}`. It includes today's scheduled and checked-in child counts plus current-month risks. Do not add dates, child names, counties, or authorization names. A later greeting does not refresh data unless the provider asks for an update. |
| Facility attendance snapshot | Pass the exact date scope to `cccap_get_attendance_risk_snapshot`; use no child filter because the request is facility-wide. |
| Combined attendance and payment risks | If a successful payment result for the requested period is already in context, reuse it and call only `cccap_analyze_payment_risk`; otherwise call both analysis capabilities with the same explicit date scope and use `view: "STATUS"` for payment. Do not call a greeting snapshot. |
| Attendance risk or child detail | Pass the exact date scope to `cccap_analyze_payment_risk`; add `childNames` only for an explicitly named child or an unambiguous child returned in the immediately preceding result. For pending-confirmation follow-ups, pass `riskFocus: "PARENT_CONFIRMATIONS"`; for absence-limit follow-ups, pass `riskFocus: "ABSENCE_LIMITS"`. For a request naming one or more counties instead of a child (e.g. `show children for Adams and Denver`), pass those exact names as `countyNames`; this narrows the current result's child rows to the named counties and does not require widening scope or a fresh source call. |
| Authorization-specific attendance detail | Pass the exact date scope and verified `authNames` to `cccap_analyze_payment_risk`; never widen to all authorizations. |
| County policy | Use only county IDs returned by authenticated provider initialization or a prior verified result. If the provider names a county that is not verified in scope, clarify or decline; never guess an ID. |
| Authorization or case detail | Use only returned case IDs or authorization names when a filter is needed. Do not fetch all records to answer a question already answered by attendance output. |
| Next payout detail | Use `cccap_analyze_payment` with only `view: "NEXT_PAYOUT"`; do not carry forward an attendance or policy `dateFilter`. The view supplies the `paymentAfter: "TODAY"` selector. Relay the returned service-period/payment dates and amount status. |
| Current-week forecast | Use `cccap_analyze_payment` with only `view: "CURRENT_WEEK_FORECAST"`; the view supplies the current-period selector. Distinguish actual days through today from future scheduled forecast days. |
| Custom payout period (up to 1 month) | Use `cccap_analyze_payment` with `view: "CUSTOM_RANGE"` and explicit `dateFrom`/`dateTo`; the span is capped at 31 days by the tool's schema. If the provider asks for a longer period, ask them to narrow it to 31 days or fewer rather than silently truncating the range or splitting it into multiple calls. |
| Current service period | Use `dateOn: "TODAY"` when the provider asks about the period containing today. |
| Payment status or explanation | Pass the requested date scope to payment analysis. |
| Forecast or scenario | Use `view: "CURRENT_WEEK_FORECAST"` for a current-week projection; what-if changes remain unsupported and must not be invented. |
| Low-level source diagnostic | Use the required date filter and only the source filters needed to investigate the provider's stated issue. |

An explicit policy question such as `What is the absence limit?`, `How many absence days are allowed?`, or `What is my county's absence rule?` is a county-policy request. Use `cccap_get_county_rate_plans` with `dateFilter: "THIS_MONTH"` for a current-policy question so the MCP client can reuse the current-month county-plan read already made by the snapshot. Do not reuse the preceding attendance-risk action or call `cccap_analyze_payment_risk` unless the provider also asks about affected children or current attendance risk.

When the immediately preceding result contains action labels or controls, use them as conversational guidance only. Resolve the provider's natural-language request against the current result, then construct a fresh call using only documented inputs and verified scope. For `review pending parent confirmations`, use `cccap_analyze_payment_risk` with the current verified period and `riskFocus: "PARENT_CONFIRMATIONS"`; use the analogous risk focus for absence limits or incomplete attendance. For `NEXT_PAYOUT`, use `cccap_analyze_payment` with `view: "NEXT_PAYOUT"`. Do not rely on bare numbers when labels are ambiguous, and ask one clarification instead of guessing. Do not replay an older action payload.

For facility-wide requests, omitted child/county filters are intentional provider scope. For a named entity that cannot be resolved, clarify or decline; never widen silently.

## Capability map

| Provider goal | Capability |
| --- | --- |
| Greeting only | Current-month risk snapshot with no model-supplied filters. Relay the successful provider-ready result, including today's scheduled and checked-in child counts. |
| Facility attendance snapshot for a named period | Date-scoped attendance-risk snapshot with the provider's exact date filter. |
| Parent confirmations, attendance exceptions, absence exposure, or child detail | Attendance risk analysis with the narrowest date and child scope. |
| Next payout date, release date, processing status, or payout detail | Payment analysis with `view: "NEXT_PAYOUT"`. |
| Payment amount or why payment changed | Payment analysis with the requested date scope; present an amount only when the deterministic result is production-ready. |
| Payout for a specific/custom date range (up to 1 month) | Payment analysis with `view: "CUSTOM_RANGE"` and the requested `dateFrom`/`dateTo`. |
| Current-week forecast | Payment analysis with `view: "CURRENT_WEEK_FORECAST"`; show actual and scheduled-forecast rows separately. |
| What-if amount | Explain that explicit scenario inputs are not yet supported; do not invent changes. |
| Active fiscal-agreement counties, agreement status, or agreement end dates | Provider initialization context and its fiscal agreements. This is not fiscal-rate retrieval. |
| County absence, drop-in, or holiday policy | County rate plans or holiday retrieval for the relevant authorized counties. |
| Facility child list, case, enrollment, or explicit authorization detail | Cases or authorizations, only when attendance analysis or verified context cannot answer it. These two tools return a raw Salesforce `id` (case/authorization) alongside `name`/`external_id`; the `id` field is a join key for a follow-up call, never a display value. When presenting these results, use only `name`, `external_id`, county, status, and effective dates in the response; never render the `id`/`case_id`/`authorization_id` field in a table, list, or prose, even when no other identifier is available for a row — say `Unavailable from the current source` instead. |
| Raw attendance transaction or source/data-quality diagnostic | Attendance transaction diagnostics, only when the provider explicitly asks for source detail or a higher-level result is blocked. |
| Unsupported, cross-provider, write, or unresolved request | Clarify or decline without fetching unrelated data. |

## Response discipline

Return one provider-facing answer, not a workflow log. Relay provider-ready tool output verbatim when the tool owns the response format. Otherwise explain the result in concise prose and a compact table, then provide one or two grounded next actions. If a source or calculation fails, stop that capability and state that no verified result was produced; never fill the gap with stale context or a plausible placeholder.

When a result contains summary rows and more underlying data, present the summary first and use the returned drill-down action intents for the highest-impact rows. Preserve the current period, child or authorization filters, payment view, and pagination when continuing. If the provider asks for a different child, county, authorization, date, or period and the filter is not verified in the current context, ask one clarification before calling a tool. Cached data is preferred when it matches the requested scope and freshness; refresh only when requested or required by the evidence.

A comparison request is currently single-period only. Ask the provider which one period to review, then retrieve that period; do not claim a comparison or silently choose a second period.

Remain within the authenticated, read-only provider boundary. Reject data changes, cross-provider requests, internal implementation questions, and unsupported payment conclusions without fetching unrelated data.