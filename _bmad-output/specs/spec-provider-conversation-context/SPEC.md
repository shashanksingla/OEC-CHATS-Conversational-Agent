---
id: SPEC-provider-conversation-context
companions:
  - ../../planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08/ARCHITECTURE-SPINE.md
  - runtime-gaps.md
sources:
  - ../../implementation-artifacts/spec-provider-conversation-context.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for provider conversation context and continuation behavior.

# Provider Conversation Context

## Why

Attendance and payment follow-ups need to remain provider-safe and within agent handoff limits as result sets grow. Server-owned continuation projections let the MCP process reuse verified canonical results without asking the model to replay filters, cached rows, child lists, or response prose.

## Capabilities

- **CAP-1**
  - **intent:** Provider-facing attendance and payment results can expose server-owned opaque continuation projections for follow-ups.
  - **success:** Action inputs contain only opaque context and action references, and the server resolves each reference to a validated capability, scope, filters, focus/view, and pagination plan.
- **CAP-2**
  - **intent:** Compatible attendance and payment continuations reuse provider-bound canonical results before new source retrieval.
  - **success:** Reuse occurs only when the immutable compatibility key matches provider scope, capability, normalized scope and filters, focus/view, rule version, freshness policy, projection type, page, and page size; otherwise the result is refreshed or rejected safely.
- **CAP-3**
  - **intent:** Continuation requests support explicit refresh and bounded process-local lifecycle management.
  - **success:** Explicit refresh bypasses canonical-result reuse and returns a new context, while TTL, LRU entry, and byte caps prevent unbounded continuation storage.
- **CAP-4**
  - **intent:** MCP results provide one provider-facing prose channel with compact structured routing metadata.
  - **success:** `content[0].text` is the sole provider-facing response and `structuredContent` contains only compact status, scope, freshness/pagination metadata, and opaque action controls.

## Constraints

- Continuation state is server-owned and process-local; the model cannot supply cached datasets, child lists, raw identifiers, or duplicated response text.
- Compatibility reuse is governed by an immutable normalized key covering authenticated provider scope, capability, normalized date scope and filters, focus/view, rule version, freshness policy, projection type, page, and page size.
- When continuation fields are present, malformed, unknown, expired, provider-mismatched, capability-mismatched, or incompatible references fail closed and never fall back to model-supplied direct filters.
- Cross-capability actions preserve the originating provider and county scope; the target capability performs its own authorization and compatibility validation.
- Continuation storage uses provider-scoped process memory with TTL, LRU entry, and byte caps. It is not durable storage, and process restart clears it.
- Existing direct attendance and payment inputs remain supported. Deterministic calculation ownership stays in the existing evaluators.
- Runtime behavior must preserve server-side provider and county validation and must not expose tokens, headers, provider IDs, child data, family data, or raw Salesforce records.

## Non-goals

- Durable conversation or provider-data storage, external cache infrastructure, Redis, background jobs, writes, notifications, or scenario mutation.
- Moving deterministic calculations into the model, TypeScript continuation store, or Apex source boundary.
- Replacing existing direct attendance or payment request paths with continuation-only inputs.

## Success signal

Hermetic MCP tests demonstrate same-capability cache-first reuse, compatible pagination, explicit refresh, bounded eviction, fail-closed invalid references, cross-capability scope preservation, and compact structured envelopes while provider-facing Markdown remains in `content[0].text`.

## Assumptions

- The existing MCP implementation is the runtime baseline; requirements in the finalized architecture are intended contract rules, while enforcement not demonstrated by current code or tests remains an open question or implementation constraint.

## Open Questions

- Does the runtime implement one immutable normalized compatibility key across both attendance and payment, including normalized scope, filters, focus/view, rule version, freshness, projection, page, and page size?
- Does explicit refresh bypass both the conversation-context result cache and the lower-level source-read cache, or only the former?
- Are malformed or partially supplied continuation references rejected even when direct date, view, or filter inputs are also present?
- Are inherited cross-capability actions bound to a still-valid originating context and compatibility key rather than only the provider and action ID?
- Does the byte bound cover session action metadata as well as canonical context records, and does pagination reuse a compatible cached projection or always trigger fresh retrieval?
