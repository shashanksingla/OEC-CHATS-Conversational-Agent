import assert from "node:assert/strict";
import test from "node:test";

import { CccapClient, type RequestApex } from "../src/client.js";

test("initialization injects the configured provider user and captures allowed scope", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    return {
      isSuccess: true,
      data: {
        providers: [
          { Id: "provider-1", Name: "20260722", NAM_FACILITY__c: "Bright Start" },
        ],
        fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
        providerClosures: [],
      },
    };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });

  await client.initialize({ dateFilter: "TODAY" });

  assert.equal(requests[0]?.action, "getProviderData");
  assert.deepEqual(requests[0]?.body, {
    dateFilter: "TODAY",
    userId: "user-1",
  });
});

test("reuses identical provider reads but refreshes when the date scope changes", async () => {
  const requests: string[] = [];
  const requestApex: RequestApex = async (_targetOrg, action) => {
    requests.push(action);
    return {
      isSuccess: true,
      data: {
        providers: [{ Id: "provider-1", Name: "20260722" }],
        fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
        providerClosures: [],
      },
    };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });

  await client.initialize({ dateFilter: "TODAY" });
  await client.initialize({ dateFilter: "TODAY" });
  await client.initialize({ dateFilter: "THIS_MONTH" });

  assert.deepEqual(requests, ["getProviderData", "getProviderData"]);
});

test("reuses current-month county plans across snapshot and policy reads", async () => {
  const requests: string[] = [];
  const requestApex: RequestApex = async (_targetOrg, action) => {
    requests.push(action);
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
          providerClosures: [],
        },
      };
    }
    return { isSuccess: true, data: { countyRatePlans: [] } };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });

  await client.initialize({ dateFilter: "THIS_MONTH" });
  await client.getCountyData({ dateFilter: "THIS_MONTH" });
  await client.getCountyData({ dateFilter: "THIS_MONTH" });

  assert.deepEqual(requests, ["getProviderData", "getCountyData"]);
});

test("case requests inject the provider external name returned by initialization", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
          providerClosures: [],
        },
      };
    }
    return { isSuccess: true, data: { cases: [] } };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });
  await client.initialize({ dateFilter: "TODAY" });

  await client.getCases({ countyIds: ["county-1"], dateFilter: "TODAY" });

  assert.deepEqual(requests[1]?.body, {
    countyIds: ["county-1"],
    dateFilter: "TODAY",
    providerIds: ["20260722"],
  });
});

test("authorization requests preserve case filters and inject the provider Salesforce ID", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
          providerClosures: [],
        },
      };
    }
    return { isSuccess: true, data: {} };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });
  await client.initialize({ dateFilter: "TODAY" });

  await client.getAuthorizations({
    caseIds: ["case-1"],
    dateFilter: "TODAY",
    careDate: "2026-09-09",
  });
  await client.getSchedules({ dateFilter: "TODAY", authNames: ["AUTH-1"] });

  assert.deepEqual(requests[1]?.body.providerIds, ["provider-1"]);
  assert.deepEqual(requests[1]?.body.caseIds, ["case-1"]);
  assert.equal(requests[1]?.body.careDate, undefined);
  assert.deepEqual(requests[2]?.body.providerIds, ["provider-1"]);
  assert.deepEqual(requests[2]?.body.authNames, ["AUTH-1"]);
});

test("out-of-scope counties are rejected before an API call", async () => {
  let requestCount = 0;
  const requestApex: RequestApex = async (_targetOrg, action) => {
    requestCount += 1;
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
          providerClosures: [],
        },
      };
    }
    return { isSuccess: true, data: {} };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });
  await client.initialize({ dateFilter: "TODAY" });

  await assert.rejects(
    client.getCountyData({ countyIds: ["county-2"], dateFilter: "TODAY" }),
    /outside the authenticated provider scope/,
  );
  assert.equal(requestCount, 1);
});

test("schedule requests inject configured provider IDs after initialization", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
        },
      };
    }
    return { isSuccess: true, data: { schedules: [], transactions: [] } };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });
  await client.initialize({ dateFilter: "TODAY" });

  await client.getSchedules({ dateFilter: "THIS_MONTH" });

  assert.deepEqual(requests[1], {
    action: "getSchedules",
    body: { dateFilter: "THIS_MONTH", providerIds: ["provider-1"] },
  });
});

test("payment-history requests preserve the date scope and inject provider IDs", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
        },
      };
    }
    return { isSuccess: true, data: { servicePeriodIds: [], subPayments: [] } };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });

  await client.initialize({ dateFilter: "TODAY" });
  await client.getPaymentHistory({ dateFilter: "LAST_N_MONTHS", periodCount: 2 });

  assert.deepEqual(requests[1], {
    action: "getPaymentHistory",
    body: {
      dateFilter: "LAST_N_MONTHS",
      periodCount: 2,
      providerIds: ["provider-1"],
    },
  });
});

test("fiscal-rate requests use only schedule IDs returned by provider initialization", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [
            {
              CDE_COUNTY__c: "county-1",
              Rate_Schedules__r: {
                records: [{ IDN_EXTNL__c: "schedule-external-1" }],
              },
            },
          ],
        },
      };
    }
    return { isSuccess: true, data: { fiscalRates: [], fiscalRateFees: [] } };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });

  await client.initialize({ dateFilter: "TODAY" });
  await client.getFiscalRates({ dateFilter: "THIS_MONTH" });

  assert.deepEqual(requests[1], {
    action: "getFiscalRates",
    body: {
      dateFilter: "THIS_MONTH",
      providerIds: ["provider-1"],
      fiscalScheduleIds: ["schedule-external-1"],
    },
  });
});

test("fiscal-rate requests fail closed when initialization returns no schedules", async () => {
  let requestCount = 0;
  const requestApex: RequestApex = async (_targetOrg, action) => {
    requestCount += 1;
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
        },
      };
    }
    return { isSuccess: true, data: {} };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });

  await client.initialize({ dateFilter: "TODAY" });
  await assert.rejects(
    client.getFiscalRates({ dateFilter: "TODAY" }),
    /No authorized fiscal rate schedules/,
  );
  assert.equal(requestCount, 1);
});

test("authorization requests preserve scoped authorization IDs", async () => {
  const requests: Array<{ action: string; body: Record<string, unknown> }> = [];
  const requestApex: RequestApex = async (_targetOrg, action, body) => {
    requests.push({ action, body });
    if (action === "getProviderData") {
      return {
        isSuccess: true,
        data: {
          providers: [{ Id: "provider-1", Name: "20260722" }],
          fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
        },
      };
    }
    return { isSuccess: true, data: { authorizations: [], slotContracts: [] } };
  };
  const client = new CccapClient({
    targetOrg: "CHATS_SIT",
    providerUserId: "user-1",
    requestApex,
  });
  await client.initialize({ dateFilter: "THIS_MONTH" });
  await client.getAuthorizations({
    dateFilter: "THIS_MONTH",
    authIds: ["auth-1", "auth-2"],
  });

  assert.deepEqual(requests[1]?.body.authIds, ["auth-1", "auth-2"]);
  assert.deepEqual(requests[1]?.body.providerIds, ["provider-1"]);
});