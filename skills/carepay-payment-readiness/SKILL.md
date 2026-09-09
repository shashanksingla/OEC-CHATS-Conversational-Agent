---
name: carepay-payment-readiness
description: Specialized CarePay skill for payout timing, next-payout detail, current-week forecasting, and honest handling of unsupported what-if requests.
---

# CarePay Payment Readiness

Use with `carepay-conversation-templates` when Provider Assist needs next payout, payout detail, a current-week forecast, a payment explanation, or an honest response to an unsupported what-if request. The conversation-template skill owns response shape and failure handling; this skill owns payment meaning and routing details.

Follow `{project-root}/skills/ARCHITECTURE.md`. This module owns payment meaning and follow-up selection only. Source field mapping belongs to MCP normalizers; money, dates, status, and forecast rules belong to the deterministic evaluator.

The outcome is a provider-readable payment answer grounded in authorized live data and deterministic Python output. Never calculate money, compare dates, join records, or apply policy in model reasoning.

Load these project contracts before presenting any payment status or amount:

- `{project-root}/skills/agent-child-care-payment-advisor/references/integration-contract.md`
- `{project-root}/skills/agent-child-care-payment-advisor/references/api-response-contract.json`
- `{project-root}/skills/agent-child-care-payment-advisor/references/rule-governance.md`

For next-payout detail, use `cccap_analyze_payment` with `view: "NEXT_PAYOUT"`. The tool selects the next service period whose payment has not run, then returns the service dates, processing date, release date, payment status, and any deterministic amount. Present payment amounts only when the result is complete and source-ready; otherwise show the service-period dates and the named missing source areas without inventing an amount.

For a current-week forecast, use `cccap_analyze_payment` with `view: "CURRENT_WEEK_FORECAST"`. The deterministic engine treats dates through today as actuals and future scheduled dates as `SCHEDULED_FORECAST` conditional rows. Explain expected amount, conditional amount at risk, and the child/county/date classifications from the returned table. Never present future scheduled hours as attended actuals.

When live payment calculation is blocked, say which calculation cannot be completed and name the missing approved source area in provider language, such as fiscal rates, parent confirmations, payment status, or transaction-level attendance. Offer one or two next actions, usually reviewing attendance readiness or checking data quality.

What-if scenarios remain unsupported because they require an explicit input-change schema and adapter. Do not invent scenario changes or call ordinary historical payment analysis a scenario; offer next-payout detail or the current-week forecast instead.

Use the shared conversation-template failure policy for failed or incomplete retrieval, normalization, evaluation, or policy data. Do not add a payment-specific fallback format here.