import assert from "node:assert/strict";
import test from "node:test";
import { CccapClient } from "../src/client.js";
const connection = {
    instanceUrl: "https://example.my.salesforce.com",
    accessToken: "test-token",
};
function jsonResponse(data) {
    return new Response(JSON.stringify({ isSuccess: true, data }), {
        status: 200,
        headers: { "content-type": "application/json" },
    });
}
test("initialization injects the configured provider user and captures allowed scope", async () => {
    const requests = [];
    const fetch = async (url, init) => {
        requests.push({
            url: String(url),
            body: JSON.parse(String(init?.body)),
        });
        return jsonResponse({
            providers: [{ Id: "provider-1", NAM_FACILITY__c: "Bright Start" }],
            fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
            providerClosures: [],
        });
    };
    const client = new CccapClient({
        targetOrg: "CHATS_SIT",
        providerUserId: "user-1",
        resolveConnection: async () => connection,
        fetch,
    });
    await client.initialize({ dateFilter: "TODAY" });
    assert.equal(requests[0]?.url.endsWith("/getProviderData"), true);
    assert.deepEqual(requests[0]?.body, {
        dateFilter: "TODAY",
        userId: "user-1",
    });
});
test("case requests always inject learned provider IDs", async () => {
    const requests = [];
    const fetch = async (url, init) => {
        const body = JSON.parse(String(init?.body));
        requests.push({ url: String(url), body });
        if (String(url).endsWith("/getProviderData")) {
            return jsonResponse({
                providers: [{ Id: "provider-1" }],
                fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
                providerClosures: [],
            });
        }
        return jsonResponse({ cases: [] });
    };
    const client = new CccapClient({
        targetOrg: "CHATS_SIT",
        providerUserId: "user-1",
        resolveConnection: async () => connection,
        fetch,
    });
    await client.initialize({ dateFilter: "TODAY" });
    await client.getCases({ countyIds: ["county-1"], dateFilter: "TODAY" });
    assert.deepEqual(requests[1]?.body, {
        countyIds: ["county-1"],
        dateFilter: "TODAY",
        providerIds: ["provider-1"],
    });
});
test("out-of-scope counties are rejected before an API call", async () => {
    let requestCount = 0;
    const fetch = async (url) => {
        requestCount += 1;
        if (String(url).endsWith("/getProviderData")) {
            return jsonResponse({
                providers: [{ Id: "provider-1" }],
                fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
                providerClosures: [],
            });
        }
        return jsonResponse({});
    };
    const client = new CccapClient({
        targetOrg: "CHATS_SIT",
        providerUserId: "user-1",
        resolveConnection: async () => connection,
        fetch,
    });
    await client.initialize({ dateFilter: "TODAY" });
    await assert.rejects(client.getCountyData({ countyIds: ["county-2"], dateFilter: "TODAY" }), /outside the authenticated provider scope/);
    assert.equal(requestCount, 1);
});
