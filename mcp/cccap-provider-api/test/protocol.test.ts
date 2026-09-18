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
  assert.deepEqual((structured.resultGraph as Record<string, unknown>).currentView, structured.viewState);

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
        schedules: ["2026-09-01", "2026-09-02", "2026-09-03", "2026-09-04"].map((date, index) => ({
          Contact_Name__c: "Ava Example",
          CI_Authorization_Date__c: date,
          Check_In_Count__c: index === 3 ? 1 : 0,
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

  assert.match(text ?? "", /Children near or over county monthly absence limits/);
  assert.match(text ?? "", /1 child\(ren\), 1 counties;/);
  assert.equal(structured.responseMode, "SUMMARY");
  assert.equal(structured.providerMessage, text);
  assert.equal(structured.attendanceSummary, undefined);
  assert.equal(Array.isArray(structured.actionControls), true);
  assert.equal(structured.contextRef, undefined);
  assert.equal(JSON.stringify(structured.actionControls).includes("childNames"), false);
  assert.equal(structured.availableViews, undefined);
  assert.equal(structured.viewControls, undefined);
  assert.equal(structured.actionIntents, undefined);
  // Next actions are numbered and capped at two for consistent drill-down responses.
  // This fixture's absence usage is within the county tier (approaching, not crossed), so the
  // ranking engine's more precise "review-approaching-absence-limit" candidate applies here.
  assert.match(text ?? "", /\n1\. Review approaching absence limits — 1 children/);

  const offeredActions = structured.actionControls as Array<Record<string, unknown>>;
  const priorityActionTwo = offeredActions.find((action) => action.actionId === "review-incomplete-attendance");
  assert.ok(priorityActionTwo, JSON.stringify(offeredActions));
  // Signed action tokens replace the previous contextRef/actionRef credentials.
  const priorityActionTwoInput = priorityActionTwo.input as Record<string, unknown>;
  assert.equal(priorityActionTwoInput.actionId, "review-incomplete-attendance");
  assert.equal(typeof priorityActionTwoInput.actionToken, "string");
  assert.equal("contextRef" in priorityActionTwo, false);
  assert.equal("actionRef" in priorityActionTwo, false);
  const incompleteFollowUp = await client.callTool({
    name: "cccap_analyze_payment_risk",
    arguments: priorityActionTwo.input as Record<string, unknown>,
  });
  const incompleteStructured = incompleteFollowUp.structuredContent as Record<string, unknown>;
  assert.equal(incompleteFollowUp.isError, undefined);
  assert.match(incompleteFollowUp.content.find((item) => item.type === "text")?.text ?? "", /incomplete attendance/i);
  assert.equal(incompleteStructured.providerMessage, incompleteFollowUp.content.find((item) => item.type === "text")?.text);
  // Unscoped cross-risk actions re-derive affected children from riskFocus.
  assert.deepEqual(incompleteStructured.scope, {
    dateFilter: "THIS_MONTH",
    riskFocus: "INCOMPLETE_ATTENDANCE",
  });
  assert.equal(JSON.stringify(incompleteStructured.actionControls).includes("contextRef"), false);
  assert.equal(JSON.stringify(incompleteStructured.actionControls).includes("actionRef"), false);

  // Risk-focused responses offer only a return to summary, preserving exclusive drill-down.
  const returnToSummaryAction = (incompleteStructured.actionControls as Array<Record<string, unknown>>).find(
    (action) => action.actionId === "return-to-attendance-summary",
  );
  assert.ok(returnToSummaryAction);
  const summaryFollowUp = await client.callTool({
    name: "cccap_analyze_payment_risk",
    arguments: returnToSummaryAction.input as Record<string, unknown>,
  });
  const summaryStructured = summaryFollowUp.structuredContent as Record<string, unknown>;
  const returnedAbsenceAction = (summaryStructured.actionControls as Array<Record<string, unknown>>).find(
    (action) => action.actionId === "review-approaching-absence-limit",
  );
  assert.ok(returnedAbsenceAction);
  const returnedAbsenceActionInput = returnedAbsenceAction.input as Record<string, unknown>;
  assert.equal(returnedAbsenceActionInput.actionId, "review-approaching-absence-limit");
  assert.equal(typeof returnedAbsenceActionInput.actionToken, "string");
  const absenceFollowUp = await client.callTool({
    name: "cccap_analyze_payment_risk",
    arguments: returnedAbsenceAction.input as Record<string, unknown>,
  });
  const absenceStructured = absenceFollowUp.structuredContent as Record<string, unknown>;
  assert.equal(absenceFollowUp.isError, undefined);
  assert.match(absenceFollowUp.content.find((item) => item.type === "text")?.text ?? "", /absence[- ]limit/i);
  assert.equal(absenceStructured.providerMessage, absenceFollowUp.content.find((item) => item.type === "text")?.text);
  // Unscoped cross-risk actions do not carry childNames.
  assert.deepEqual(absenceStructured.scope, {
    dateFilter: "THIS_MONTH",
    riskFocus: "ABSENCE_LIMITS",
  }, JSON.stringify({ action: returnedAbsenceAction, response: absenceStructured }));
  // Continuation caching applies uniformly, so return-to-summary reuses the facility result.
  assert.equal(scheduleReads, 3);

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