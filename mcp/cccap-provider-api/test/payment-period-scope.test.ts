import assert from "node:assert/strict";
import test from "node:test";

import {
  filterPaymentSchedules,
  scopeAuthorizationDataToSchedules,
  scopeScheduleData,
} from "../src/payment-orchestration.js";

test("scopes schedules and authorization mappings to the selected service period", () => {
  const scoped = scopeScheduleData({
    schedules: [
      {
        CI_Authorization_Id__c: "auth-in-period",
        CI_Authorization_Date__c: "2026-09-01",
      },
      {
        CI_Authorization_Id__c: "auth-future",
        CI_Authorization_Date__c: "2026-09-16",
      },
    ],
    transactions: [],
  }, "2026-08-31", "2026-09-06");

  assert.equal(scoped.rows.length, 1);
  assert.equal(scoped.rows[0]?.CI_Authorization_Id__c, "auth-in-period");

  const authorizationData = scopeAuthorizationDataToSchedules({
    normalizedAuthorizations: [
      {
        authorization: { Id: "auth-in-period", Name: "963389" },
        fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "schedule-1" },
      },
      {
        authorization: { Id: "auth-future", Name: "963424" },
        fiscalScheduleMatch: { status: "UNRESOLVED", reason: "NO_MATCH" },
      },
    ],
  }, scoped.rows);

  const retained = authorizationData.normalizedAuthorizations as Array<Record<string, unknown>>;
  assert.equal(retained.length, 1);
  assert.equal((retained[0]?.authorization as Record<string, unknown>).Id, "auth-in-period");
});

test("filters payout schedules before enrichment for an authorization request", () => {
  const retained = filterPaymentSchedules([
    { authorization_id: 963383, authorization_name: "963383", child_name: "MURTI SB" },
    { authorization_id: 963385, authorization_name: "963385", child_name: "Darrin Ashford" },
  ], { authNames: ["963383"] });

  assert.deepEqual(retained.map((schedule) => schedule.authorization_name), ["963383"]);
});