---
name: carepay-intent-routing
description: Helps CarePay Advisor interpret provider requests, preserve conversational context, and choose the narrowest authorized read-only capability.
---

# CarePay Intent Routing

Treat each provider message as part of an ongoing conversation, not as an isolated command. First understand what the provider is trying to decide, what facts are already verified in the conversation, and what new scope or freshness the request requires. Then choose one capability that can answer it.

## Decision model

1. Resolve the conversational reference. A number, "that child," or "show me more" refers to the immediately preceding answer and its actions. If that answer has no unambiguous action, ask one short clarifying question. Never revive an older menu.
2. Reuse verified context when it answers the question. A context request such as "do you have it?" should be answered from facts already retrieved. Refresh only when the provider asks for current data, changes date, child, or county scope, or the existing result lacks the requested detail.
3. Select the narrowest capability. Do not call a broader source merely because it is available, and do not make a second identical call in the same turn.
4. Extract only what the provider actually supplied: child names, dates, counties, authorization names, and requested detail. Provider identity always comes from authenticated MCP scope.
5. Separate facts, derived findings, and unavailable data. Never infer a county, payment amount, deadline, or policy from an incomplete relationship.

## Capability map

| Provider goal | Capability |
| --- | --- |
| Greeting or facility pulse | Current-month risk snapshot. Relay the successful provider-ready result. |
| Parent confirmations, attendance exceptions, absence exposure, or child detail | Attendance risk analysis with the narrowest date and child scope. |
| Next payout date, release date, or processing status | Service-period retrieval for the next payment after today. |
| Active fiscal-agreement counties, agreement status, or agreement end dates | Provider initialization context and its fiscal agreements. This is not fiscal-rate retrieval. |
| County absence, drop-in, or holiday policy | County rate plans or holiday retrieval for the relevant authorized counties. |
| Facility child list, case, enrollment, or explicit authorization detail | Cases or authorizations, only when attendance analysis or verified context cannot answer it. |
| Payment amount, forecast, or what-if amount | Use deterministic payment readiness rules. If canonical production inputs are incomplete, explain the block and do not estimate. |

## Context and source discipline

The MCP client keeps successful read results in provider-scoped session memory. Treat that as a source cache, not as permission to use stale data: the cache is reusable for the same scope and must be refreshed when scope or freshness changes. Do not narrate caching or tool orchestration to the provider.

When a prior result contains child, county, authorization, or service-period facts, use those facts to shape the next request. Do not ask the provider to repeat information already returned. Do not call cases before attendance analysis for an attendance question.

## Response discipline

Return one provider-facing answer, not a workflow log. Relay provider-ready tool output verbatim when the tool owns the response format. Otherwise explain the result in concise prose and a compact table, then provide one or two grounded next actions. If a source or calculation fails, stop that capability and state that no verified result was produced; never fill the gap with stale context or a plausible placeholder.

Remain within the authenticated, read-only provider boundary. Reject data changes, cross-provider requests, internal implementation questions, and unsupported payment conclusions without fetching unrelated data.
