---
name: carepay-attendance-readiness
description: Specialized CarePay skill for provider attendance readiness, parent confirmations, absence-limit risk, attendance exceptions, and child drill-downs.
---

# CarePay Attendance Readiness

Use with `carepay-conversation-templates` when CarePay Advisor needs a facility snapshot, parent-confirmation review, attendance exceptions, absence-limit risk, or child-level attendance detail.

The outcome is a provider-readable attendance-risk answer grounded in `cccapprovider/*` data and `skills/agent-child-care-payment-advisor/scripts/evaluate_attendance_risks.py`. Python owns all grouping, counting, date comparison, risk categorization, and absence-limit logic.

Load these project contracts only when needed for the requested answer:

- `{project-root}/skills/agent-child-care-payment-advisor/references/integration-contract.md`
- `{project-root}/skills/agent-child-care-payment-advisor/references/api-response-contract.json`
- `{project-root}/skills/agent-child-care-payment-advisor/references/schema-mapping.json`

For a greeting, the entrypoint already calls `cccap_get_current_month_risk_snapshot`; do not call it again. Return its successful plain-text snapshot verbatim. For a later facility pulse request, call `cccap_get_attendance_risk_snapshot` with the requested date scope and return its successful plain-text snapshot verbatim. Do not build a fallback snapshot.

For action `Review pending parent confirmations in the provider system`, and for any request for child details, use `cccap_analyze_attendance_risk` with the narrowest date and child scope. Reuse the immediately preceding verified result when its capability, scope, freshness, and returned child rows already answer the action; do not repeat an identical call. Its successful plain-text result includes one row per affected child with `Child name`, `Household name`, `County`, `Authorization name`, `Service dates`, `Note`, and `Potential impact`; return it verbatim. Do not call `cccap_get_cases` when the analysis result contains child rows, and do not ask the provider for a child name before displaying those returned rows. Add absence-limit columns only when the provider asked about limits. Notes cite the exact returned count, date, or status that triggered the row. Potential impact distinguishes conditional payment, possible exclusion, review required, or unavailable impact.

Offer only grounded follow-ups: authorization detail uses returned authorization names with `cccap_get_authorizations`; county-limit detail uses returned counties with `cccap_get_county_rate_plans`; payout detail uses `cccap_get_service_periods` with `paymentAfter: "TODAY"` and `limitOne: true`. If an authorization name or county is unavailable, do not offer that corresponding filtered drill-down.

The first snapshot's payment-readiness table always has exactly three rows: `Pending parent confirmations`, `Children approaching county monthly absence limits`, and `Children crossed county absence limits`. Every answer ends with one or two next actions tied to the returned finding or source limitation.

If a tool, Salesforce request, external service, Python analysis, normalization step, or source field fails, stop the affected response. Do not show partial tables, placeholder counts, fallback dashboards, stale data, or raw technical details.