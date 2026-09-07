import assert from "node:assert/strict";
import test from "node:test";

import { normalizeFiscalRateResponse } from "../src/fiscal-rate-normalizer.js";

test("normalizes the live fiscal-rate response without guessing payment tiers", () => {
  const result = normalizeFiscalRateResponse({
    fiscalSchedules: [{ Id: "schedule-1", CDE_RATE_TYPE__c: "1" }],
    fiscalRates: [{
      Id: "rate-1",
      idn_fiscal_sch__c: "schedule-1",
      cde_age_group__c: "2",
      cde_care_unit__c: "3",
      cde_rate_type__c: "1",
      amt_cty__c: 6,
      amt_fa__c: 13,
      amt_provr__c: 13,
    }],
    fiscalRateFees: [{
      Id: "fee-1",
      IDN_FISCAL_SCH__c: "schedule-1",
      CDE_ACT_FREQ__c: "ANN",
      AMT_ACT_CTY__c: 101,
      AMT_ACT_FA__c: 105,
      AMT_ACT_PROVR__c: 111,
    }],
  });

  assert.deepEqual(result.fiscalRates, [{
    sourceId: "rate-1",
    fiscalScheduleId: "schedule-1",
    rateTypeCode: "1",
    rateTypeLabel: "Regular",
    ageGroupCode: "2",
    ageGroupLabel: "06-12 Months",
    careUnitCode: "3",
    careUnitLabel: "FT",
    paidTier: "FULL_TIME",
    countyAmount: "6.00",
    fiscalAgreementAmount: "13.00",
    providerAmount: "13.00",
  }]);
  assert.deepEqual(result.fiscalRateFees, [{
    sourceId: "fee-1",
    fiscalScheduleId: "schedule-1",
    activityFrequency: "ANN",
    activityCountyAmount: "101.00",
    activityFiscalAgreementAmount: "105.00",
    activityProviderAmount: "111.00",
  }]);
  assert.equal(result.canonicalMappingStatus, "COMPLETE_CODE_MAPPING");
  assert.deepEqual(result.unresolvedMappings, []);
  assert.deepEqual(result.r00393Values, { "1": 15650, ADD: 5500 });
});

test("maps fiscal care units and represents NP as no payment", () => {
  const result = normalizeFiscalRateResponse({
    fiscalRates: [
      { Id: "pt", idn_fiscal_sch__c: "s", cde_age_group__c: "1", cde_care_unit__c: "2", cde_rate_type__c: "1", amt_cty__c: 1, amt_fa__c: 1, amt_provr__c: 1 },
      { Id: "ftpt", idn_fiscal_sch__c: "s", cde_age_group__c: "1", cde_care_unit__c: "4", cde_rate_type__c: "1", amt_cty__c: 1, amt_fa__c: 1, amt_provr__c: 1 },
      { Id: "np", idn_fiscal_sch__c: "s", cde_age_group__c: "1", cde_care_unit__c: "1", cde_rate_type__c: "1", amt_cty__c: 1, amt_fa__c: 1, amt_provr__c: 1 },
    ],
    fiscalRateFees: [],
  });

  assert.equal(result.fiscalRates[0].paidTier, "PART_TIME");
  assert.equal(result.fiscalRates[1].paidTier, "FULL_TIME_PLUS_PART_TIME");
  assert.equal(result.fiscalRates[2].paidTier, "NO_PAYMENT");
  assert.deepEqual(result.unresolvedMappings, []);
});

test("rejects malformed fiscal-rate rows instead of producing payment inputs", () => {
  assert.throws(
    () => normalizeFiscalRateResponse({ fiscalRates: [{ Id: "rate-1", amt_provr__c: -1 }], fiscalRateFees: [] }),
    /fiscalRates\[0\]\.idn_fiscal_sch__c is required/,
  );
});
