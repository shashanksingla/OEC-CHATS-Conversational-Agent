import assert from "node:assert/strict";
import test from "node:test";

import { getPaymentAnalysis } from "../src/payment-orchestration.js";

function buildClient() {
  return {
    async initialize() {
      return {
        providers: [{ TXT_CHATS_RATING__c: "Level 1", CDE_TYPE_PROVR__c: "LICENSED" }],
        fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
      };
    },
    async getServicePeriods() {
      return {
        servicePeriods: [{
          servicePeriodId: "period-1",
          serviceBeginDate: "2026-09-01",
          serviceEndDate: "2026-09-07",
        }],
      };
    },
    async getAuthorizations() {
      return {
        normalizedAuthorizations: [
          {
            authorization: {
              Id: "auth-denver",
              CDE_COUNTY__c: "county-1",
              Number_of_Drop_in_Days__c: 0,
              IDN_CLIENT__r: { DTE_DOB__c: "2024-01-01" },
            },
            fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "fiscal-1" },
          },
          {
            authorization: {
              Id: "auth-adams",
              CDE_COUNTY__c: "county-1",
              Number_of_Drop_in_Days__c: 0,
              IDN_CLIENT__r: { DTE_DOB__c: "2024-01-01" },
            },
            fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "fiscal-1" },
          },
        ],
        slotContracts: [],
        encumbrances: [
          { idn_auth__c: "auth-denver", dte_care__c: "2026-09-01", ind_0_36_months__c: false, cde_status_encmbr__c: "3" },
          { idn_auth__c: "auth-adams", dte_care__c: "2026-09-01", ind_0_36_months__c: false, cde_status_encmbr__c: "3" },
        ],
        authorizationCopays: [],
      };
    },
    async getCountyData() {
      return { countyRatePlans: [{ countyId: "county-1", absenceDaysTier1: 4 }] };
    },
    async getSchedules() {
      return {
        schedules: [
          {
            Id: "schedule-denver",
            Authorization__c: "auth-denver",
            CI_Authorization_Id__c: "auth-denver",
            CI_Authorization_Rate_Type__c: "1",
            CI_Authorization_Date__c: "2026-09-01",
            CI_Authorization_Hours__c: 5,
            Hours__c: 4,
            Care_Not_Offered__c: false,
            Authorization__r: { County__r: { County_Name__c: "Denver" } },
            Attendance__r: { records: [{ Record_Type_Name__c: "Check-In", Status__c: "PARENT_APPROVED" }] },
          },
          {
            Id: "schedule-adams",
            Authorization__c: "auth-adams",
            CI_Authorization_Id__c: "auth-adams",
            CI_Authorization_Rate_Type__c: "1",
            CI_Authorization_Date__c: "2026-09-01",
            CI_Authorization_Hours__c: 5,
            Hours__c: 4,
            Care_Not_Offered__c: false,
            Authorization__r: { County__r: { County_Name__c: "Adams" } },
            Attendance__r: { records: [{ Record_Type_Name__c: "Check-In", Status__c: "PARENT_APPROVED" }] },
          },
        ],
      };
    },
    async getFiscalRates() {
      return {
        normalizedFiscalRates: {
          fiscalRates: [{
            fiscalScheduleId: "fiscal-1",
            rateTypeCode: "1",
            careUnitCode: "3",
            paidTier: "PART_TIME",
            fiscalAgreementAmount: 45,
            providerAmount: 45,
            sourceId: "rate-1",
          }],
          fiscalRateFees: [{ fiscalScheduleId: "fiscal-1" }],
        },
      };
    },
    async getHolidayList() {
      return { holidayList: [] };
    },
    async getPaymentHistory() {
      return { subPayments: [] };
    },
    async getVacantSlots() {
      return { vacantSlots: [] };
    },
  } as unknown as Parameters<typeof getPaymentAnalysis>[0];
}

test("countyNames narrows payment attendance days to the named county", async () => {
  const result = await getPaymentAnalysis(
    buildClient(),
    { dateFilter: "THIS_MONTH" },
    "STATUS",
    "2026-09-01",
    { countyNames: ["Denver"], detailPage: 1 },
  ) as Record<string, unknown>;

  const attendance = result.attendance as Record<string, unknown>;
  const days = attendance.days as Array<Record<string, unknown>>;
  const detailPagination = result.detailPagination as Record<string, unknown>;
  assert.equal(detailPagination.totalRows, 1);
  assert.ok(days.length > 0);
  assert.ok(days.every((day) => day.county_name === "Denver"));
});

test("a county filter matching nothing fails closed", async () => {
  await assert.rejects(
    getPaymentAnalysis(
      buildClient(),
      { dateFilter: "THIS_MONTH" },
      "STATUS",
      "2026-09-01",
      { countyNames: ["Jefferson"] },
    ),
    /Requested county filter did not match the selected provider scope and period\./,
  );
});