---
name: carepay-payment-readiness
description: Specialized CarePay skill for upcoming payout, weekly forecast, payment explanation, recovery priorities, and payment scenarios.
---

# CarePay Payment Readiness

Use with `carepay-conversation-templates` when CarePay Advisor needs next payout, payout detail, weekly forecast, recovery priorities, why-payment-is-lower explanation, or a what-if payment scenario.

The outcome is a provider-readable payment answer grounded in authorized live data and deterministic Python output. Never calculate money, compare dates, join records, or apply policy in model reasoning.

Load these project contracts before presenting any payment status or amount:

- `{project-root}/skills/agent-child-care-payment-advisor/references/integration-contract.md`
- `{project-root}/skills/agent-child-care-payment-advisor/references/api-response-contract.json`
- `{project-root}/skills/agent-child-care-payment-advisor/references/rule-governance.md`

Use `cccap_get_service_periods` with `paymentAfter: "TODAY"` and `limitOne: true` for the `View next payout details` action and for a direct next-payout request. Present payment amounts only when a deterministic result is marked `production_ready: true`. The current `scripts/calculate_payout.py` contract is `legacy_normalized_fixture` and returns `production_ready: false`, so it cannot support live payout, forecast, or net-payment claims.

When live payment calculation is blocked, say which calculation cannot be completed and name the missing approved source area in provider language, such as fiscal rates, parent confirmations, payment status, or transaction-level attendance. Offer one or two next actions, usually reviewing attendance readiness or checking data quality.

For scenarios, label the answer as a scenario rather than live status, run only the explicit provider-proposed input changes through Python, and compare returned outputs without inventing missing rates or confirmations.

If any retrieval, normalization, Python, or policy step fails, stop the affected response. Do not show partial ledgers, placeholder amounts, fallback tables, stale data, or technical error details.