import { StdioServerTransport } from "@modelcontextprotocol/server/stdio";
import { CccapClient } from "./client.js";
import { createServer } from "./server.js";
import { resolveSfConnection } from "./sf-cli.js";
function requiredEnvironment(name) {
    const value = process.env[name]?.trim();
    if (!value) {
        throw new Error(`${name} is required`);
    }
    return value;
}
async function main() {
    const client = new CccapClient({
        targetOrg: requiredEnvironment("SF_TARGET_ORG"),
        providerUserId: requiredEnvironment("CCCAP_PROVIDER_USER_ID"),
        resolveConnection: resolveSfConnection,
    });
    const server = createServer(client);
    await server.connect(new StdioServerTransport());
}
main().catch((error) => {
    const message = error instanceof Error ? error.message : "Unknown startup error";
    console.error(`CCCAP Provider API MCP failed to start: ${message}`);
    process.exit(1);
});
