# Provider Assist Skill Architecture

This is the build guide for Provider Assist skills. Keep the conversation layer, capability meaning, source normalization, and deterministic processing separate.

## Request Flow

```text
Provider request
  -> Provider Assist policy
  -> intent routing
  -> one capability skill
  -> one composite MCP tool
  -> authenticated source reads
  -> canonical normalization boundary
  -> deterministic evaluator
  -> provider-safe result
```

The model chooses intent and explains verified output. It does not choose provider identity, join source objects, count days, compare dates, apply policy, or calculate money.

## Skill Ownership

| Module | Owns | Must not own |
| --- | --- | --- |
| `agent-child-care-payment-advisor` | Agent lifecycle, safety boundary, skill loading, final handoff | Domain calculations, source joins, duplicate response templates |
| `carepay-intent-routing` | User outcome, entity/time scope, freshness, narrow tool selection | Data retrieval, calculations, provider-facing formatting |
| `carepay-payment-risk-readiness` | Attendance, parent-confirmation, absence-limit, and payment-risk dollar-exposure meaning and follow-up routing | Common failure wording, source field mapping, payout calculation |
| `carepay-payment-readiness` | Payment status, payout timing, forecast meaning, unsupported scenario handling | Money/date calculations, source joins, common failure wording |
| `carepay-data-quality` | Naming a source gap and selecting a legitimate recovery view | Repairing data, inventing fallback values, recalculating results |
| `carepay-conversation-templates` | Provider-safe response shape, tables, next views, failure envelope | Deciding what the data means or selecting tools |

## MCP Module Ownership

| Layer | Current owner | Contract |
| --- | --- | --- |
| Registration and dispatch | `mcp/cccap-provider-api/src/server.ts` | Validate request dispatch, invoke one capability, return the shared envelope |
| Provider scope and transport | `client.ts`, `sf-cli.ts`, `index.ts` | Resolve authenticated provider context and perform read-only source calls |
| Source normalization | `read-model-adapters.ts`, `provider-context.ts`, `attendance-canonical-adapter.ts`, `payment-canonical-adapter.ts`, `*-normalizer.ts`, `payment-payload-adapter.ts`, `schedule-normalizer.ts`, `provider-policy.ts` | Convert source-shaped records into canonical facts; reject missing or ambiguous relationships |
| Capability orchestration | `attendance-snapshot.ts`, `payment-orchestration.ts` | Request source facts, pass canonical facts from the adapter to the evaluator, attach scope/provenance |
| Deterministic processing | Python evaluator scripts | Apply approved rules to canonical input only; never fetch Salesforce data |
| Provider formatting | Capability formatter in MCP plus conversation-template policy | Present verified results without exposing implementation data |

## Canonical Data Rule

Raw Salesforce or external-source objects may exist only inside transport and source-normalization adapters. Capability orchestration and evaluators must consume named canonical contracts, not raw field names such as `CDE_COUNTY__c`, `Attendance__r`, or `TXT_CHATS_RATING__c`.

A canonical contract must define:

- stable internal identifiers and relationship keys;
- ISO dates and explicit numeric units;
- normalized statuses and classifications;
- source, retrieved-at, effective-date, and rule-version provenance;
- readiness and blocking information when required fields are absent or ambiguous.

When a new source field is needed, update the source mapping contract, add or update the normalizer, add a canonical fixture/test, and only then change capability processing. Do not spread source-field handling into skills, server dispatch, or Python.

## Capability Build Checklist

1. Define the provider decision and the narrowest MCP tool.
2. Define the canonical input and provider-safe output.
3. Map source fields in one adapter boundary.
4. Reject missing, stale, or ambiguous relationships before processing.
5. Pass canonical data to the deterministic evaluator.
6. Format one result and one or two grounded next views.
7. Add a focused normalizer test and an end-to-end capability test.
8. Update the relevant reference contract and this ownership map when boundaries change.

## Change Routing

- New provider intent or follow-up: update `carepay-intent-routing`.
- New attendance/payment meaning: update the corresponding capability skill and evaluator contract.
- New source field or relationship: update `references/schema-mapping.json` and the owning normalizer.
- New response shape or failure behavior: update `carepay-conversation-templates` and the MCP formatter.
- New deterministic rule: update the Python evaluator and `rule-governance.md`.

Do not add the same rule to multiple skills. Link to the owning module instead.
