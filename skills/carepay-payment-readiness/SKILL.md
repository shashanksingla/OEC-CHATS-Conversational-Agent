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

## Payout view selection — three distinct capabilities, never interchange them

A plain "upcoming payment" / "what am I getting paid" request with no period named is answered with `view: "NEXT_PAYOUT"` **only** — this always resolves to a single service period (the soonest unpaid/upcoming period by release date). Never call the multi-period ledger for this request shape, and never widen it to a range unless the provider names one.

- **Next payout** (`view: "NEXT_PAYOUT"`) — the default for an unscoped "upcoming payment" question. Single period only: the soonest upcoming/unpaid period by release date. Returns service dates, payout date, status, and a `Calculated amount` (current estimate; the period has not yet been released) plus its at-risk breakdown. Never shows a `Net amount` — a period that has one is, by definition, no longer "upcoming."
- **Last payout** (`view: "LAST_PAYOUT"`) — only on an explicit request about a past/last/most recent payment, or as a grounded follow-up after showing Next Payout. Never offered as a standing greeting/snapshot option. Single period only: the most recently released period. Shows a `Net amount` (the real, reconciled, historical figure) and no at-risk breakdown — it is settled.
- **Payout ledger** (`view: "PAYOUT_LEDGER"`) — only when the provider explicitly names a month or range ("show September's payouts," "show this month," "show all upcoming periods"). Returns every service period in that range; each row shows either a `Net amount` (if released) or a `Calculated amount` (if not), never both, following the same rule as Next Payout / Last Payout.

Present payment amounts only when the result is complete and source-ready; otherwise show the service-period dates and the named missing source areas without inventing an amount.

For a forecast of the service period containing today, use `cccap_analyze_payment` with `view: "CURRENT_PERIOD_FORECAST"` (accepted alias: `CURRENT_WEEK_FORECAST`). This is scoped to whichever service period today falls inside (begin <= today <= end), not a fixed calendar week. The deterministic engine treats dates through today as actuals and future scheduled dates as `SCHEDULED_FORECAST` conditional rows. Explain expected amount, conditional amount at risk, and the child/county/date classifications from the returned table. Never present future scheduled hours as attended actuals. Note when this period is the same period as Next Payout (today can fall inside the next unpaid period) — say so explicitly rather than presenting the same period twice under different labels without comment.

For a payout over a specific or custom date range (not the next scheduled payout, and capped at 31 days), use `cccap_analyze_payment` with `view: "CUSTOM_RANGE"` and the provider's exact `dateFrom`/`dateTo`. This view is independent of any Salesforce service period — it evaluates the arbitrary span the provider asked about rather than selecting the next unpaid period. The tool's schema rejects a span longer than 31 days; if the provider asks for a longer period, ask them to narrow it rather than silently truncating or splitting the request into multiple calls. In provider-facing text, label this span as a custom period or by its exact date range; never call it a service period, pay period, or upcoming payout. Present the result using the same amount-readiness rules as any other payment view: an amount only when the deterministic result is complete and source-ready, otherwise the named missing source areas without inventing a figure.

When live payment calculation is blocked, say which calculation cannot be completed and name the missing approved source area in provider language, such as fiscal rates, parent confirmations, payment status, or transaction-level attendance. Offer one or two next actions, usually reviewing attendance readiness or checking data quality.

What-if scenarios remain unsupported because they require an explicit input-change schema and adapter. Do not invent scenario changes or call ordinary historical payment analysis a scenario; offer next-payout detail or the current-week forecast instead.

Use the shared conversation-template failure policy for failed or incomplete retrieval, normalization, evaluation, or policy data. Do not add a payment-specific fallback format here.