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
    const providerUserId = await resolveAuthenticatedUserId(targetOrg);
    const client = new CccapClient({
        targetOrg,
        providerUserId,
        requestApex: requestApexViaSf,
    });
    const server = createServer(client, providerDisplayName, undefined, providerUserId);
    await server.connect(new StdioServerTransport());
}
main().catch((error) => {
    const message = error instanceof Error ? error.message : "Unknown startup error";
    console.error(`CCCAP Provider API MCP failed to start: ${message}`);
    process.exit(1);
});
