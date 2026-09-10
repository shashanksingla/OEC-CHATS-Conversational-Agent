import assert from "node:assert/strict";
import test from "node:test";

import { Client, InMemoryTransport as ClientTransport } from "@modelcontextprotocol/client";
import { InMemoryTransport as ServerTransport } from "@modelcontextprotocol/server";

import { createServer } from "../src/server.js";

test("MCP protocol preserves attendance provider text and structured scope", async () => {
  const fakeClient = {
    async initialize() {
      return {
        providers: [{
          NAM_FACILITY__c: "Example Facility",
          CDE_TYPE_PROVR__c: "EXE",
          TXT_CHATS_RATING__c: "Level 1",
        }],
        fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
      };
    },
    async getCountyData() {
      return { countyRatePlans: [] };
    },
    async getSchedules() {
      return { schedules: [] };
    },
  };
  const server = createServer(fakeClient as never, "Example Provider");
  const client = new Client({ name: "protocol-test-client", version: "1.0.0" });
  const [clientTransport, serverTransport] = ClientTransport.createLinkedPair();
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  const response = await client.callTool({
    name: "cccap_analyze_payment_risk",
    arguments: { dateFilter: "THIS_MONTH" },
  });
  const text = response.content.find((item) => item.type === "text")?.text;
  const structured = response.structuredContent as Record<string, unknown>;

  assert.equal(response.isError, undefined);
  assert.match(text ?? "", /no attendance records for the requested period/i);
  assert.equal(structured.providerMessage, text);
  assert.equal(structured.capability, "attendance-risk-analysis");
  assert.deepEqual(structured.scope, { dateFilter: "THIS_MONTH" });

  await client.close();
  await server.close();
});

test("current-month snapshot counts five-day-old unconfirmed absences toward county risk", async () => {
  let scheduleReads = 0;
  const fakeClient = {
    async initialize() {
      return {
        providers: [{
          NAM_FACILITY__c: "Example Facility",
          CDE_TYPE_PROVR__c: "EXE",
          TXT_CHATS_RATING__c: "Level 1",
        }],
        fiscalAgreements: [{ CDE_COUNTY__c: "denver" }],
      };
    },
    async getCountyData() {
      return {
        countyRatePlans: [{
          countyId: "denver",
          countyName: "Denver",
          absenceDaysTier1: 4,
          absenceDaysTier2: 4,
          absenceDaysTier3: 4,
          absenceDaysTier4: 4,
          absenceDaysTier5: 4,
        }],
      };
    },
    async getSchedules() {
      scheduleReads += 1;
      return {
        schedules: ["2026-09-01", "2026-09-02", "2026-09-03"].map((date) => ({
          Contact_Name__c: "Ava Example",
          CI_Authorization_Date__c: date,
          Check_In_Count__c: 0,
          Check_Out_Count__c: 0,
        })),
      };
    },
  };
  const server = createServer(fakeClient as never, "Example Provider");
  const client = new Client({ name: "snapshot-risk-test-client", version: "1.0.0" });
  const [clientTransport, serverTransport] = ClientTransport.createLinkedPair();
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  const response = await client.callTool({
    name: "cccap_get_current_month_risk_snapshot",
    arguments: {},
  });
  const text = response.content.find((item) => item.type === "text")?.text;
  const structured = response.structuredContent as Record<string, unknown>;

  assert.match(text ?? "", /Children approaching county monthly absence limits/);
  assert.ok(text?.includes("1 child(ren) of 1 counties; within 2 day(s) of exceeding the limit"));
  assert.equal(structured.responseMode, "SUMMARY");
  assert.equal(structured.providerMessage, text);
  assert.equal(structured.attendanceSummary, undefined);
  assert.equal(Array.isArray(structured.actionControls), true);
  assert.equal(typeof structured.contextRef, "string");
  assert.equal(JSON.stringify(structured.actionControls).includes("childNames"), false);
  assert.equal(structured.availableViews, undefined);
  assert.equal(structured.viewControls, undefined);
  assert.equal(structured.actionIntents, undefined);
  // Next actions are now numbered (capped to the top 2) rather than bulleted,
  // matching the drill-down action-list convention and avoiding an
  // open-ended pile of bullets across turns.
  assert.match(text ?? "", /\n1\. Review 1 child\(ren\) near or over the absence limit/);

  const absenceAction = (structured.actionControls as Array<Record<string, unknown>>).find(
    (action) => action.actionId === "review-absence-limit-risk",
  );
  assert.ok(absenceAction);
  const followUp = await client.callTool({
    name: "cccap_analyze_payment_risk",
    arguments: absenceAction.input as Record<string, unknown>,
  });
  assert.equal(followUp.isError, undefined);
  assert.match(followUp.content.find((item) => item.type === "text")?.text ?? "", /absence-limit concern/);
  assert.equal(scheduleReads, 1);

  await client.close();
  await server.close();
});

test("county policy lookup defaults to current-month scope and formats limits", async () => {
  const initializedScopes: unknown[] = [];
  const fakeClient = {
    async initialize(scope: unknown) {
      initializedScopes.push(scope);
      return {};
    },
    async getCountyData(scope: unknown) {
      assert.deepEqual(scope, { dateFilter: "THIS_MONTH" });
      return {
        countyRatePlans: [{
          countyName: "Denver",
          effectiveBeginDate: "2026-01-01",
          absenceDaysTier1: 5,
          absenceDaysTier2: 7,
          absenceDaysTier3: 9,
          absenceDaysTier4: 11,
          absenceDaysTier5: 13,
        }],
      };
    },
  };
  const server = createServer(fakeClient as never, "Example Provider");
  const client = new Client({ name: "policy-test-client", version: "1.0.0" });
  const [clientTransport, serverTransport] = ClientTransport.createLinkedPair();
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  const response = await client.callTool({
    name: "cccap_get_county_rate_plans",
    arguments: {},
  });
  const text = response.content.find((item) => item.type === "text")?.text;

  assert.deepEqual(initializedScopes, [{ dateFilter: "THIS_MONTH" }]);
  assert.match(text ?? "", /\| Denver \| 2026-01-01 \| 5 \| 7 \| 9 \| 11 \| 13 \|/);
  assert.equal((response.structuredContent as Record<string, unknown>).capability, "county-policy");

  await client.close();
  await server.close();
});