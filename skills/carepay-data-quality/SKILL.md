---
name: carepay-data-quality
description: Specialized CarePay skill for source gaps, stale or conflicting data, incomplete mappings, and professional error handling.
---

# CarePay Data Quality

Use with `carepay-conversation-templates` when Provider Assist needs to explain why a provider result is unavailable, uncertain, blocked, stale, conflicting, or missing required source support.

The outcome is a concise, actionable account of the blocking data condition. Identify the affected provider-facing capability, the missing or conflicting source area, and the legitimate read-only next step. Include child, county, service period, or amount only when returned by an authorized source or deterministic Python output.

Load these project contracts when diagnosing a gap:

- `{project-root}/skills/agent-child-care-payment-advisor/references/integration-contract.md`
- `{project-root}/skills/agent-child-care-payment-advisor/references/api-response-contract.json`
- `{project-root}/skills/agent-child-care-payment-advisor/references/schema-mapping.json`

Treat incomplete check-in/out pairs, overlapping schedules, missing authorizations, unmatched county plans, absent effective dates, unresolved parent-confirmation status, missing fiscal rates, unavailable transaction-level fields, and stale retrieval timestamps as blockers unless an approved rule contract says otherwise.

Never repair data, infer a value, recommend changing a record merely to increase payment, or expose raw IDs, request bodies, file paths, stack traces, Salesforce CLI output, or internal exception text. Preserve tracing details for support only when the provider specifically needs a non-sensitive reference.

Every answer ends with one or two recovery actions, such as retrying the same request once, reviewing the named source data, or contacting the appropriate support or county role.