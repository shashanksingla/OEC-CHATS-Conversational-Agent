# CarePay Agent File Usage

## Purpose

This document is the file-usage map for the Provider Assist agent and its current MCP adapter. It covers agent files plus the MCP files required to expose authenticated, read-only tools. The organization implementation is an external plug-in behind MCP; Salesforce, Apex, and broader project-repository files are outside this map.

## Agent Boundary

```text
.
|-- .github/
|   `-- agents/
|       `-- carepay-advisor.agent.md
`-- skills/
    |-- agent-child-care-payment-advisor/
    |   |-- SKILL.md
    |   |-- customize.toml
    |   |-- evals/
    |   |   |-- cases.json
    |   |   |-- queries.json
    |   |   `-- files/
    |   |       `-- denver-case.json
    |   |-- references/
    |   |   |-- api-response-contract.json
    |   |   |-- attendance-transaction-rules.md
    |   |   |-- integration-contract.md
    |   |   |-- rule-governance.md
    |   |   |-- schema-mapping.json
    |   |   `-- setup-guide.md
    |   `-- scripts/
    |       |-- analyze_attendance_transactions.py
    |       |-- calculate_payout.py
    |       |-- evaluate_attendance_risks.py
    |       `-- tests/
    |           |-- test_analyze_attendance_transactions.py
    |           |-- test_calculate_payout.py
    |           `-- test_evaluate_attendance_risks.py
    |-- mcp/
    |   `-- cccap-provider-api/
    |       |-- README.md
    |       |-- package-lock.json
    |       |-- package.json
    |       |-- tsconfig.json
    |       |-- src/
    |       |   |-- attendance-snapshot.ts
    |       |   |-- client.ts
    |       |   |-- index.ts
    |       |   |-- schemas.ts
    |       |   |-- server.ts
    |       |   `-- sf-cli.ts
    |       |-- test/
    |       |   |-- client.test.ts
    |       |   |-- schemas.test.ts
    |       |   `-- sf-cli.test.ts
    |       `-- scripts/
    |           |-- list-tools.mjs
    |           |-- snapshot-smoke.mjs
    |           `-- smoke-test.mjs
    |-- carepay-conversation-templates/
    |   `-- SKILL.md
    |-- carepay-intent-routing/
    |   `-- SKILL.md
    |-- carepay-attendance-readiness/
    |   `-- SKILL.md
    |-- carepay-payment-readiness/
    |   `-- SKILL.md
    `-- carepay-data-quality/
        `-- SKILL.md
```

Generated `__pycache__` folders, `node_modules`, and archived eval output are omitted because they are not agent runtime files. The compiled MCP `dist` output is included because the local MCP registration runs it.

## File Purpose Table

| File or folder | Ownership | Purpose |
| --- | --- | --- |
| [.github/agents/carepay-advisor.agent.md](.github/agents/carepay-advisor.agent.md) | Agent-owned | Registers Provider Assist, loads the main skills, and defines the allowed tool namespace. |
| [skills/agent-child-care-payment-advisor/SKILL.md](skills/agent-child-care-payment-advisor/SKILL.md) | Agent-owned | Defines persona, routing, shared response policy, failure policy, and capability boundaries. |
| [skills/carepay-conversation-templates/SKILL.md](skills/carepay-conversation-templates/SKILL.md) | Agent-owned | Defines authenticated-provider response templates, drill-down structure, payment responses, failure responses, and next-action rules. |
| [skills/carepay-intent-routing/SKILL.md](skills/carepay-intent-routing/SKILL.md) | Agent-owned | Classifies each provider message, resolves follow-ups, selects bounded data routes, and enforces read-only and digression guardrails. |
| [skills/carepay-attendance-readiness/SKILL.md](skills/carepay-attendance-readiness/SKILL.md) | Agent-owned | Guides attendance snapshots, confirmations, exceptions, absence-limit risk, and child-level detail. |
| [skills/carepay-payment-readiness/SKILL.md](skills/carepay-payment-readiness/SKILL.md) | Agent-owned | Guides payout, forecast, recovery, and scenario responses while blocking unsupported live payment claims. |
| [skills/carepay-data-quality/SKILL.md](skills/carepay-data-quality/SKILL.md) | Agent-owned | Explains failed, incomplete, stale, conflicting, or unmapped data in provider-safe language. |
| [skills/agent-child-care-payment-advisor/customize.toml](skills/agent-child-care-payment-advisor/customize.toml) | Agent-owned | Stores BMad customization metadata for the main skill. |
| [skills/agent-child-care-payment-advisor/evals](skills/agent-child-care-payment-advisor/evals) | Agent-owned | Stores behavior expectations, provider-style prompts, and deterministic evaluation fixtures. |
| [skills/agent-child-care-payment-advisor/scripts](skills/agent-child-care-payment-advisor/scripts) | Agent-owned | Contains deterministic Python for joins, date logic, counts, classifications, and payment calculations. |
| [skills/agent-child-care-payment-advisor/scripts/tests](skills/agent-child-care-payment-advisor/scripts/tests) | Agent-owned | Verifies deterministic attendance and payment behavior with hermetic tests. |
| [skills/agent-child-care-payment-advisor/references/api-response-contract.json](skills/agent-child-care-payment-advisor/references/api-response-contract.json) | Agent-consumed | Defines the tool response shape, normalized keys, derived outputs, known gaps, and production-readiness markers. |
| [skills/agent-child-care-payment-advisor/references/schema-mapping.json](skills/agent-child-care-payment-advisor/references/schema-mapping.json) | Agent-consumed | Maps source concepts and relationships to the normalized data the agent expects. |
| [skills/agent-child-care-payment-advisor/references/integration-contract.md](skills/agent-child-care-payment-advisor/references/integration-contract.md) | Agent-consumed | Defines the read-only trust boundary, required normalized inputs, and integration limitations. |
| [skills/agent-child-care-payment-advisor/references/attendance-transaction-rules.md](skills/agent-child-care-payment-advisor/references/attendance-transaction-rules.md) | Agent-consumed | Documents attendance rules implemented or deferred by the deterministic layer. |
| [skills/agent-child-care-payment-advisor/references/rule-governance.md](skills/agent-child-care-payment-advisor/references/rule-governance.md) | Agent-consumed | Defines how approved policy and rate inputs become deterministic rules. |
| [skills/agent-child-care-payment-advisor/references/setup-guide.md](skills/agent-child-care-payment-advisor/references/setup-guide.md) | Agent-consumed | Records setup, release gates, current limitations, and production-readiness requirements. |
| [mcp/cccap-provider-api/package.json](mcp/cccap-provider-api/package.json) | MCP-owned | Defines the MCP adapter package, build, test, and typecheck commands. |
| [mcp/cccap-provider-api/package-lock.json](mcp/cccap-provider-api/package-lock.json) | MCP-owned | Pins the adapter's dependency tree for reproducible local builds. |
| [mcp/cccap-provider-api/README.md](mcp/cccap-provider-api/README.md) | MCP-owned | Documents adapter setup, commands, tools, and local operation. |
| [mcp/cccap-provider-api/tsconfig.json](mcp/cccap-provider-api/tsconfig.json) | MCP-owned | Configures TypeScript compilation for the adapter. |
| [mcp/cccap-provider-api/src/index.ts](mcp/cccap-provider-api/src/index.ts) | MCP-owned | Starts the adapter, resolves its authenticated provider context, and connects the stdio server. |
| [mcp/cccap-provider-api/src/server.ts](mcp/cccap-provider-api/src/server.ts) | MCP-owned | Registers read-only tools, input schemas, annotations, result wrapping, and sanitized errors. |
| [mcp/cccap-provider-api/src/client.ts](mcp/cccap-provider-api/src/client.ts) | MCP-owned | Calls the external provider API and preserves provider and county scope. |
| [mcp/cccap-provider-api/src/schemas.ts](mcp/cccap-provider-api/src/schemas.ts) | MCP-owned | Validates MCP tool inputs such as dates, ranges, and service-period selectors. |
| [mcp/cccap-provider-api/src/attendance-snapshot.ts](mcp/cccap-provider-api/src/attendance-snapshot.ts) | MCP-owned | Orchestrates provider snapshot retrieval and deterministic attendance evaluation. |
| [mcp/cccap-provider-api/src/sf-cli.ts](mcp/cccap-provider-api/src/sf-cli.ts) | MCP-owned | Bridges adapter requests to the authenticated CLI without exposing tokens or authorization headers. |
| [mcp/cccap-provider-api/test](mcp/cccap-provider-api/test) | MCP-owned | Tests scope enforcement, input validation, request construction, and safe error handling. |
| [mcp/cccap-provider-api/scripts](mcp/cccap-provider-api/scripts) | MCP-owned | Provides protocol, snapshot, and live smoke checks for the adapter. |
| [mcp/cccap-provider-api/dist](mcp/cccap-provider-api/dist) | MCP-generated | Compiled adapter runtime used by the local MCP registration. Rebuild after TypeScript changes. |

## MCP And External Plug-in Boundary

The MCP adapter is included here because it is the current tool boundary used by the agent. It does not own or enumerate the organization implementation. The following remain external dependencies behind MCP:

- The MCP provider API adapter supplies authenticated, read-only provider tools to the agent.
- Salesforce and Apex provide the organization-side data access and authorization implementation.
- Local MCP registration supplies the development-time connection between the agent and the adapter. Its project-level registration file is wiring only, not agent behavior.

The agent may consume MCP's documented response contract, errors, and readiness markers. MCP may call the external organization API, but neither the agent nor MCP may assume undocumented fields, bypass server-side provider or county validation, or expose secrets and raw authorization headers.

## What Belongs In Each Agent Layer

| Concern | Correct home |
| --- | --- |
| Agent registration and allowed tools | [.github/agents/carepay-advisor.agent.md](.github/agents/carepay-advisor.agent.md) |
| Persona, route selection, shared policies | [skills/agent-child-care-payment-advisor/SKILL.md](skills/agent-child-care-payment-advisor/SKILL.md) |
| Provider-facing response behavior | [skills/carepay-conversation-templates/SKILL.md](skills/carepay-conversation-templates/SKILL.md) and specialized skills |
| Attendance and payment interpretation | [skills/carepay-attendance-readiness/SKILL.md](skills/carepay-attendance-readiness/SKILL.md) and [skills/carepay-payment-readiness/SKILL.md](skills/carepay-payment-readiness/SKILL.md) |
| Data-quality and failure explanation | [skills/carepay-data-quality/SKILL.md](skills/carepay-data-quality/SKILL.md) |
| Deterministic counting, date logic, joins, classifications, and money | [skills/agent-child-care-payment-advisor/scripts](skills/agent-child-care-payment-advisor/scripts) |
| Source/API expectations | [skills/agent-child-care-payment-advisor/references](skills/agent-child-care-payment-advisor/references) |
| Authenticated read-only provider tools | [mcp/cccap-provider-api/src/server.ts](mcp/cccap-provider-api/src/server.ts) and [mcp/cccap-provider-api/src/client.ts](mcp/cccap-provider-api/src/client.ts) |
| MCP input validation and safe error handling | [mcp/cccap-provider-api/src/schemas.ts](mcp/cccap-provider-api/src/schemas.ts) and [mcp/cccap-provider-api/src/server.ts](mcp/cccap-provider-api/src/server.ts) |

## Production-Readiness Checklist

| Check | Status |
| --- | --- |
| Agent has a lean entrypoint | Present |
| Agent behavior is in skills, not project references | Present |
| Conversation templates are a dedicated skill | Present |
| Deterministic facts are computed in Python | Present |
| Agent consumes a documented plug-in response contract | Present |
| Live payment normalizer exists | Not yet; the current calculator remains fixture-only and marks output `production_ready: false` |
| Transaction-level live attendance is mapped | Not yet; the agent must not infer it from aggregate data |
| Complete production payment inputs are available | Not yet; fiscal rates, payment history, and related fields remain integration gaps |
| Production identity is platform-derived | Depends on the external plug-in deployment |
| MCP adapter tests and typecheck pass | Required for MCP changes |

## Relationship To architecture.md

[architecture.md](architecture.md) remains the broader platform architecture and may describe the external plug-in. This document intentionally stays narrower: it is the agent and MCP file map, not an inventory of Salesforce, Apex, or broader project-repository implementation files.