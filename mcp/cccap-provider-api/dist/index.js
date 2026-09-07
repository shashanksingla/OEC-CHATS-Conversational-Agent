import { StdioServerTransport } from "@modelcontextprotocol/server/stdio";
import { CccapClient } from "./client.js";
import { createServer } from "./server.js";
import { requestApexViaSf, resolveAuthenticatedUserId } from "./sf-cli.js";
function requiredEnvironment(name) {
    const value = process.env[name]?.trim();
    if (!value) {
        throw new Error(`${name} is required`);
    }
    return value;
}
async function main() {
    const targetOrg = requiredEnvironment("SF_TARGET_ORG");
    const providerDisplayName = requiredEnvironment("CCCAP_PROVIDER_DISPLAY_NAME");
    const client = new CccapClient({
        targetOrg,
        providerUserId: await resolveAuthenticatedUserId(targetOrg),
        requestApex: requestApexViaSf,
    });
    const server = createServer(client, providerDisplayName);
    await server.connect(new StdioServerTransport());
}
main().catch((error) => {
    const message = error instanceof Error ? error.message : "Unknown startup error";
    console.error(`CCCAP Provider API MCP failed to start: ${message}`);
    process.exit(1);
});
