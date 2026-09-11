# Runtime Gaps

These are implementation observations reconciled against the finalized architecture. They are not additional behavior claims.

- `ConversationContextStore.resolve` currently checks provider, generic continuation capability, expiry, and optional rule version, but does not compare the full immutable normalized compatibility key required by AD-9.
- Attendance cached rendering overlays request scope, focus, and county fields onto the cached result; the runtime does not yet prove that those fields match the stored projection before reuse.
- Payment detail pagination bypasses canonical-result reuse rather than validating and reusing a compatible cached page projection. Page, page size, base filters, and total-row identity are not represented in the context record.
- `refresh: true` bypasses conversation-context result reuse in the composite handlers, but the lower-level source-read cache has no demonstrated refresh invalidation or bounded freshness policy.
- Schemas allow context and action references independently, and composite handlers can fall back to direct inputs in some cases when a supplied pair is invalid. The fail-closed contract requires rejecting any supplied-but-unresolvable continuation fields.
- Inherited actions are retained in a provider-wide action map keyed by action ID. The runtime does not yet demonstrate binding each inherited action to a live originating context and compatibility key.
- Context byte accounting covers context records but does not demonstrate coverage for session action metadata.
- Current attendance and payment tests assert `structuredContent.providerMessage` for some responses, while the finalized contract requires `content[0].text` to be the sole provider-facing prose channel. This is a contract/test alignment gap, not a license to invent another response channel.
