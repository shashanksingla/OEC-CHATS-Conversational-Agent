import assert from "node:assert/strict";
import test from "node:test";

import { normalizeVacantSlotSchedules } from "../src/payment-canonical-adapter.js";

test("vacant slots select the fiscal amount for the provider quality tier", () => {
  const schedules = normalizeVacantSlotSchedules(
    [{
      Id: "slot-1",
      IDN_AUTH__c: null,
      IDN_PROVIDER__c: "provider-1",
      CDE_COUNTY__c: "county-1",
      CDE_RATE_TYPE__c: "1",
      CDE_CARE_UNIT__c: "2",
      CDE_CARE_LEVEL__c: "7",
      DTE_BEGIN_SLOT__c: "2026-09-01",
      DTE_END_SLOT__c: "2026-09-30",
      CNT_DAYS_OF_MONTH__c: 5,
    }],
    [
      {
        fiscalScheduleId: "schedule-level-1",
        rateTypeCode: "1",
        careUnitCode: "2",
        ageGroupCode: "7",
        fiscalAgreementAmount: "10.00",
      },
      {
        fiscalScheduleId: "schedule-level-3",
        rateTypeCode: "1",
        careUnitCode: "2",
        ageGroupCode: "7",
        fiscalAgreementAmount: "20.00",
      },
    ],
    ["county-1"],
    3,
    {
      fiscalAgreements: [{
        CDE_COUNTY__c: "county-1",
        Rate_Schedules__r: {
          records: [
            {
              IDN_EXTNL__c: "schedule-level-1",
              CDE_RATE_TYPE__c: "1",
              TXT_CHATS_RATING__c: "Level 1",
              DTE_BEGIN_EFFV__c: "2026-01-01",
            },
            {
              IDN_EXTNL__c: "schedule-level-3",
              CDE_RATE_TYPE__c: "1",
              TXT_CHATS_RATING__c: "Level 3",
              DTE_BEGIN_EFFV__c: "2026-01-01",
            },
          ],
        },
      }],
      providerClosures: [],
    },
  );

  assert.equal(schedules.length, 1);
  assert.equal(schedules[0]?.fiscal_schedule_id, "schedule-level-3");
  assert.equal(schedules[0]?.slot_rate_amount, 20);
});