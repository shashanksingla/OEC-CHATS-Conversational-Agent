---
name: carepay-attendance-readiness
description: Specialized CarePay skill for provider attendance readiness, parent confirmations, absence-limit risk, attendance exceptions, and child drill-downs.
---

# CarePay Attendance Readiness

Use with `carepay-conversation-templates` when Provider Assist needs a facility snapshot, parent-confirmation review, attendance exceptions, absence-limit risk, or child-level attendance detail. The conversation-template skill owns response shape and failure handling; this skill owns attendance meaning and routing details.

Follow `{project-root}/skills/ARCHITECTURE.md`. This module owns attendance meaning and follow-up selection only. Source field mapping belongs to MCP normalizers; counts, dates, classifications, and absence-limit rules belong to the deterministic evaluator.

The outcome is a provider-readable attendance-risk answer grounded in `cccapprovider/*` data and the deterministic attendance evaluators. Python owns all grouping, counting, date comparison, risk categorization, and absence-limit logic. Effective provider closure dates are `Care Not Offered` and are excluded from default child day tables, absence counts, and pending-confirmation counts. County actual and observed holiday dates are classified separately from absences. Detailed attendance uses the full drop-in rules, including actual hours, tier, county and authorization limits, and fail-closed handling when a licensed-only policy lacks provider license status. Parent approval does not replace the five-day basic risk cutoff.

Load these project contracts only when needed for the requested answer:

- `{project-root}/skills/agent-child-care-payment-advisor/references/integration-contract.md`
- `{project-root}/skills/agent-child-care-payment-advisor/references/api-response-contract.json`
- `{project-root}/skills/agent-child-care-payment-advisor/references/schema-mapping.json`

For a greeting, the entrypoint already calls `cccap_get_current_month_risk_snapshot`; do not call it again. Its response includes today's scheduled and checked-in child counts followed by current-month payment-readiness risks. Return its successful plain-text snapshot verbatim. For a later facility pulse request, call `cccap_get_attendance_risk_snapshot` with the requested date scope and return its successful plain-text snapshot verbatim. Do not build a fallback snapshot.

For action `Review pending parent confirmations in the provider system`, use `cccap_analyze_attendance_risk` with `riskFocus: "PARENT_CONFIRMATIONS"`, the narrowest date, and child scope. For absence-limit detail, use `riskFocus: "ABSENCE_LIMITS"`. Reuse the immediately preceding verified result when its capability, scope, freshness, focus, and returned child rows already answer the action; do not repeat an identical call. The successful result's `providerMessage` is authoritative, whether it appears as text content or structured content; relay it verbatim. It includes one row per affected child with `Child name`, `Household name`, `County`, `Authorization name`, `Service dates`, `Note`, and `Potential impact`. Do not classify a result as incomplete merely because structured action metadata omits those rows. Do not call `cccap_get_cases` when the analysis result contains child rows, and do not ask the provider for a child name before displaying those returned rows. Add absence-limit columns only when the provider asked about limits. Notes cite the exact returned count, date, or status that triggered the row. Potential impact distinguishes conditional payment, possible exclusion, review required, or unavailable impact.

Offer only grounded next views, not actions: authorization detail uses returned authorization names with `cccap_get_authorizations`; absence-limit follow-up uses `cccap_analyze_attendance_risk` with `riskFocus: "ABSENCE_LIMITS"` so affected children, verified absence dates, counties, authorizations, absences used, and the applicable limit are shown; an explicit county-policy question uses `cccap_get_county_rate_plans` with `dateFilter: "THIS_MONTH"`; payout timing uses `cccap_get_service_periods` with `paymentAfter: "TODAY"` and `limitOne: true`. If an authorization name or county is unavailable, do not offer that corresponding filtered drill-down. Never route an absence-limit child-detail action through county policy retrieval.

The first snapshot's payment-readiness table always has exactly three rows: `Pending parent confirmations`, `Children approaching county monthly absence limits`, and `Children crossed county absence limits`.

Use the shared conversation-template failure policy for failed or incomplete retrieval, normalization, evaluation, or source data. Do not add a capability-specific fallback format here.