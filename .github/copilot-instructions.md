# Workspace Copilot Instructions

- MCP servers use the current TypeScript SDK documented at https://github.com/modelcontextprotocol/typescript-sdk and https://modelcontextprotocol.io/docs.
- Keep `mcp/cccap-provider-api` read-only and scoped to the provider user configured outside model input.
- Never log Salesforce access tokens, authorization headers, provider user IDs, child data, or raw family data.
- Preserve server-side provider and county validation when adding CCCAP tools.
- Add hermetic tests before changing request schemas, authorization scope, or Apex response handling.