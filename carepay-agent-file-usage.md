# Provider Assist File Map

The canonical module ownership and build flow are maintained in [skills/ARCHITECTURE.md](skills/ARCHITECTURE.md) and [_bmad-output/planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08/ARCHITECTURE-SPINE.md](_bmad-output/planning-artifacts/architecture/architecture-child-care-agent-final-2026-09-08/ARCHITECTURE-SPINE.md).

## Runtime Roots

- Agent entrypoint: [.github/agents/carepay-advisor.agent.md](.github/agents/carepay-advisor.agent.md)
- Agent skills: [skills](skills)
- MCP source: [mcp/cccap-provider-api/src](mcp/cccap-provider-api/src)
- Deterministic evaluators and tests: [skills/agent-child-care-payment-advisor/scripts](skills/agent-child-care-payment-advisor/scripts)
- Salesforce source boundary: [CHATS_SIT/force-app/main/default/classes/CccapPortalApiV1.cls](CHATS_SIT/force-app/main/default/classes/CccapPortalApiV1.cls)

## Ownership Rule

Use the architecture guide for where a change belongs. Raw source fields belong in canonical adapters and normalizers; capability orchestration consumes canonical data; Python evaluators consume canonical payloads; skills route and explain verified results. Do not add duplicate ownership rules to this map.

Generated MCP `dist/` output is rebuilt from `src/` and is not a source-of-truth module. `CHAT_HANDOFF.md`, `Provider_Assist_Fix_Handoff.md`, and dated files under `_bmad-output/` are historical implementation records, not runtime instructions; when they disagree with the active agent files, source, or tests, they must be refreshed before being treated as authoritative. `CHAT_HANDOFF.md` remains a historical migration record.
