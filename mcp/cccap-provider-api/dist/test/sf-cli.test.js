import assert from "node:assert/strict";
import test from "node:test";
import { resolveSfConnection } from "../src/sf-cli.js";
test("Salesforce CLI credentials are parsed from the configured target org", async () => {
    const calls = [];
    const run = async (command, args) => {
        calls.push({ command, args });
        return {
            stdout: JSON.stringify({
                status: 0,
                result: {
                    instanceUrl: "https://example.my.salesforce.com",
                    accessToken: "test-token",
                },
            }),
            stderr: "",
        };
    };
    const result = await resolveSfConnection("CHATS_SIT", run);
    assert.deepEqual(calls, [
        {
            command: "sf",
            args: [
                "org",
                "display",
                "--target-org",
                "CHATS_SIT",
                "--json",
                "--verbose",
            ],
        },
    ]);
    assert.deepEqual(result, {
        instanceUrl: "https://example.my.salesforce.com",
        accessToken: "test-token",
    });
});
test("credential errors do not include Salesforce CLI output", async () => {
    const run = async () => ({
        stdout: JSON.stringify({ status: 1, message: "secret diagnostic" }),
        stderr: "secret diagnostic",
    });
    await assert.rejects(resolveSfConnection("CHATS_SIT", run), (error) => error.message ===
        "Unable to resolve Salesforce authentication for target org CHATS_SIT");
});
