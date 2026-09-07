---
name: payment-analysis
description: Produce traceable provider payment risk, payout, forecast, action, and scenario results
code: PA
added: 2026-09-03
type: script
---

# Payment Analysis

The outcome is a provider-ready answer grounded entirely in authorized live MCP data and the JSON output of `uv run scripts/calculate_payout.py <payment-case.json>`. Load `references/integration-contract.md` before retrieving data. Never fill a missing field from general knowledge, interpret state prose at runtime, or perform arithmetic and date logic yourself.

For a facility snapshot, lead with attendance-related risks ordered by deadline and financial exposure, then show expected payout, conditional amount at risk, amount excluded, affected cases, and source freshness. For payout detail, make every amount traceable to county, child, service period, rate-plan version, and source records. For forecasts, state the as-of date and distinguish confirmed, expected, conditional, disputed, and unavailable outcomes.

Recovery priorities are read-only recommendations that name the deadline, affected amount, and provider-controlled next action without promising recovery. A scenario changes only the inputs the provider explicitly proposes, reruns the script, and compares the returned results; label it as a scenario rather than live status.

If normalization or calculation fails, switch to Data Integrity. Name the missing or conflicting field and the source system responsible; do not produce a partial numeric answer unless the script explicitly returns one.