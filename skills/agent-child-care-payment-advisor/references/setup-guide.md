# Provider Assist Setup Guide

Provider Assist is a stateless, read-only child care provider payment-risk agent. It retrieves authorized live data through MCP, delegates every deterministic join and calculation to Python, and presents attendance risks before payout detail.

## Current Build

- Provider-facing persona and six routed experiences are defined in `SKILL.md`.
- Reusable LLM behavior is split into specialized skill files: `carepay-conversation-templates`, `carepay-attendance-readiness`, `carepay-payment-readiness`, and `carepay-data-quality`.
- `scripts/calculate_payout.py` validates legacy normalized fixture cases and calculates fixture totals; its output is explicitly `production_ready: false`.
- The Denver baseline covers absence limits, daily rates, parent copay, confirmation status, expected payout, amount at risk, and excluded amount.
- Unit, baseline-quality, and trigger cases are included.
- No operational record can be changed.

## Production Setup

1. Register read-only MCP tools for `getAuthData`, `getProviderData`, `getCountyData`, `getHolidayList`, `getSchedules`, and `getServicePeriods`. MCP must derive provider/facility identity from the authenticated Salesforce session.
2. Complete response schemas and map the relationship from provider to fiscal agreement, county/rate plan, child authorization, schedule, check-in/out transactions, service period, parent confirmation, and payment.
3. Build the hybrid normalizer that emits one payment case per child, county agreement, and service period. Keep authorization/basic joins server-side and calculation-specific joins in tested Python.
4. Extract Colorado calculation rules from `{project-root}/State Docs/8 CCR 1403-1.pdf` and `{project-root}/State Docs/CCCAP Provider Handbook English.pdf` into versioned structured rule data with citations and effective dates.
5. Require business and compliance approval for each rule version, then add fixtures for every county-plan and effective-date boundary.
6. Add payment-calendar logic only after the business-day anchor, holiday source, EFT timing, and adjustment semantics are approved.
7. Embed the agent in Salesforce after validating the same MCP and calculator contracts in VS Code GitHub Copilot Chat.

## Release Gates

- Verify provider isolation and least-privilege access with negative authorization tests.
- Verify missing or stale data blocks calculations instead of producing estimates.
- Run `uv run scripts/tests/test_calculate_payout.py` from the agent directory.
- Run the BMad path and script scanners against the agent directory.
- Run baseline and trigger evals once a non-interactive VS Code Copilot adapter is configured.
- Complete privacy, security, accessibility, audit-log, and business/compliance reviews before production use.

## Known Gaps

Existing API request schemas are not a complete calculation contract. Attendance validity, confirmation response fields, rate/copay adjustments, payment history/status, source timestamps, payment-window anchors, and final relationship keys remain production blockers.