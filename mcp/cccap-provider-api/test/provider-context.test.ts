import assert from "node:assert/strict";
import test from "node:test";

import { normalizeProviderContext } from "../src/provider-context.js";

const baseInitialization = {
  providers: [{
    NAM_FACILITY__c: "Example Facility",
    TXT_CHATS_RATING__c: "Level 3",
    CDE_TYPE_PROVR__c: "LICENSED",
  }],
  fiscalAgreements: [{
    CDE_COUNTY__c: "county-1",
    CDE_COUNTY__r: { Name: "Denver" },
  }],
};

test("normalizes facility name, quality tier, and county map from provider initialization", () => {
  const context = normalizeProviderContext(baseInitialization);
  assert.equal(context.facilityName, "Example Facility");
  assert.equal(context.qualityTier, 3);
  assert.deepEqual(context.countyIds, ["county-1"]);
  assert.deepEqual(context.countyIdByName, { Denver: "county-1" });
});

test("deduplicates repeated county agreement rows", () => {
  const context = normalizeProviderContext({
    providers: baseInitialization.providers,
    fiscalAgreements: [
      { CDE_COUNTY__c: "county-1" },
      { CDE_COUNTY__c: "county-1" },
      { CDE_COUNTY__c: "county-2" },
    ],
  });
  assert.deepEqual(context.countyIds, ["county-1", "county-2"]);
});

test("fails closed when provider context is not an object", () => {
  assert.throws(() => normalizeProviderContext(null), /Provider context is unavailable/);
  assert.throws(() => normalizeProviderContext("not-an-object"), /Provider context is unavailable/);
});

test("fails closed when no provider facility is returned", () => {
  assert.throws(
    () => normalizeProviderContext({ providers: [], fiscalAgreements: [] }),
    /Provider facility is unavailable/,
  );
  assert.throws(
    () => normalizeProviderContext({ fiscalAgreements: [] }),
    /Provider facility is unavailable/,
  );
});

test("fails closed when county agreements are missing or empty", () => {
  assert.throws(
    () => normalizeProviderContext({ providers: baseInitialization.providers }),
    /Provider county agreements are unavailable/,
  );
  assert.throws(
    () => normalizeProviderContext({ providers: baseInitialization.providers, fiscalAgreements: [] }),
    /Provider county agreements are unavailable/,
  );
  assert.throws(
    () => normalizeProviderContext({
      providers: baseInitialization.providers,
      fiscalAgreements: [{ CDE_COUNTY__c: "" }],
    }),
    /Provider county agreements are unavailable/,
  );
});

test("fails closed when the provider quality rating is unsupported", () => {
  assert.throws(
    () => normalizeProviderContext({
      providers: [{ NAM_FACILITY__c: "Example Facility", TXT_CHATS_RATING__c: "Unknown" }],
      fiscalAgreements: baseInitialization.fiscalAgreements,
    }),
    /provider quality tier is unavailable or unsupported/,
  );
});

test("only normalizes the first provider row, matching single-provider scoping in this response shape", () => {
  const context = normalizeProviderContext({
    providers: [
      { NAM_FACILITY__c: "Primary Facility", TXT_CHATS_RATING__c: "Level 1" },
      { NAM_FACILITY__c: "Secondary Facility", TXT_CHATS_RATING__c: "Level 2" },
    ],
    fiscalAgreements: baseInitialization.fiscalAgreements,
  });
  assert.equal(context.facilityName, "Primary Facility");
  assert.equal(context.qualityTier, 1);
});