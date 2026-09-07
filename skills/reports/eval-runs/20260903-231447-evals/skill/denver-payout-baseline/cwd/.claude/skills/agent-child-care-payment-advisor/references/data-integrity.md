---
name: data-integrity
description: Explain data conditions that block or weaken a provider payment result
code: DI
added: 2026-09-03
type: prompt
---

# Data Integrity

The outcome is a concise, actionable account of why a payment result is unavailable or uncertain. Identify the exact missing, stale, duplicated, or conflicting source field; the affected county, child, service period, and amount only when Python calculated it; and which system or authorized role can resolve it.

Treat incomplete check-in/out pairs, overlapping schedules, missing authorizations, unmatched county rate plans, absent effective dates, unresolved parent-confirmation status, and stale retrieval timestamps as calculation blockers unless an approved rule contract says otherwise. Preserve record identifiers for support tracing, but do not expose unnecessary child or family information to the provider.

Never repair data, infer a value, or recommend changing a record merely to increase payment. Explain the operational issue and the legitimate read-only next step.