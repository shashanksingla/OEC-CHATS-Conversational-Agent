import assert from "node:assert/strict";
import test from "node:test";

import { normalizeAttendanceRiskSchedules } from "../src/attendance-canonical-adapter.js";
import { normalizePaymentSourceBundle } from "../src/payment-canonical-adapter.js";
import {
  deriveFiscalAgeGroupCodes,
  normalizeFiscalRatesForPayment,
} from "../src/payment-payload-adapter.js";
import { getPaymentAnalysis } from "../src/payment-orchestration.js";
import { normalizePaymentStatus } from "../src/payment-schema.js";
import { normalizeQualityTier } from "../src/provider-policy.js";
import { normalizeScheduleAttendance } from "../src/schedule-normalizer.js";
import {
  normalizeAuthorizations,
  normalizeCases,
  normalizeCountyPlans,
  normalizeFiscalRates,
  normalizeHolidays,
  normalizePaymentHistory,
  normalizeProviderInitialization,
  normalizeSchedules,
  normalizeServicePeriods,
} from "../src/read-model-adapters.js";

test("provider policy maps quality levels without provider-type drift", () => {
  assert.equal(normalizeQualityTier("Level 5", "EXE"), 5);
  assert.throws(() => normalizeQualityTier("Unknown", "LICENSED"));
});

test("ignores provider fiscal rates outside selected authorizations and expands shared schedules", () => {
  assert.deepEqual(
    normalizeFiscalRatesForPayment(
      [
        {
          fiscalScheduleId: "selected-schedule",
          paidTier: "PART_TIME",
          fiscalAgreementAmount: 45,
          sourceId: "selected-rate",
        },
        {
          fiscalScheduleId: "unrelated-schedule",
          paidTier: "FULL_TIME",
          fiscalAgreementAmount: 60,
          sourceId: "unrelated-rate",
        },
      ],
      { "auth-1": "selected-schedule", "auth-2": "selected-schedule" },
    ),
    [
      {
        authorization_id: "auth-1",
        paid_tier: "PART_TIME",
        amount: 45,
        source_id: "selected-rate",
      },
      {
        authorization_id: "auth-2",
        paid_tier: "PART_TIME",
        amount: 45,
        source_id: "selected-rate",
      },
    ],
  );
});

test("maps older children to the correct school-age fiscal group", () => {
  assert.deepEqual(deriveFiscalAgeGroupCodes("2022-01-01", "2026-09-01"), ["7"]);
  assert.deepEqual(deriveFiscalAgeGroupCodes("2019-01-01", "2026-09-01"), ["8"]);
});

test("generic read models expose canonical fields without source object keys", () => {
  const initialization = normalizeProviderInitialization({
    providers: [{
      Id: "provider-1",
      Name: "provider-name",
      NAM_FACILITY__c: "Example Facility",
      TXT_CHATS_RATING__c: "Level 1",
      CDE_TYPE_PROVR__c: "LICENSED",
    }],
    fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
  });
  const cases = normalizeCases({
    cases: [{ Id: "case-1", Name: "Case 1", CaseIndividuals__r: { records: [] } }],
  });
  const authorizations = normalizeAuthorizations({
    authorizations: [{ Id: "auth-1", CDE_COUNTY__c: "county-1" }],
    slotContracts: [],
  });
  const countyPlans = normalizeCountyPlans({ countyRatePlans: [{ countyId: "county-1" }] });
  const schedules = normalizeSchedules({ schedules: [{ Id: "schedule-1", CI_Authorization_Date__c: "2026-09-01" }] });
  const fiscalRates = normalizeFiscalRates({ normalizedFiscalRates: { fiscalRates: [], fiscalRateFees: [] } });
  const servicePeriods = normalizeServicePeriods({ servicePeriods: [{ servicePeriodId: "period-1", serviceBeginDate: "2026-09-01", serviceEndDate: "2026-09-07" }] });
  const holidays = normalizeHolidays({ holidayList: [{ CDE_HOL__c: "LABOR", DTE_HOL__c: "2026-09-07" }] });
  const paymentHistory = normalizePaymentHistory({ subPayments: [{ idn_pmt_sub__c: "sub-1" }] });
  const serialized = JSON.stringify({ initialization, cases, authorizations, countyPlans, schedules, fiscalRates, servicePeriods, holidays, paymentHistory });

  assert.equal(((initialization as Record<string, unknown>).fiscal_agreements as Array<Record<string, unknown>>)[0]?.county_id, "county-1");
  assert.equal(((cases as Record<string, unknown>).cases as Array<Record<string, unknown>>)[0]?.id, "case-1");
  assert.equal(((authorizations as Record<string, unknown>).authorizations as Array<Record<string, unknown>>)[0]?.id, "auth-1");
  assert.equal(((countyPlans as Record<string, unknown>).county_plans as Array<Record<string, unknown>>)[0]?.county_id, "county-1");
  assert.equal(((schedules as Record<string, unknown>).schedules as Array<Record<string, unknown>>)[0]?.schedule_id, "schedule-1");
  assert.equal(((servicePeriods as Record<string, unknown>).service_periods as Array<Record<string, unknown>>)[0]?.id, "period-1");
  assert.equal(((holidays as Record<string, unknown>).holidays as Array<Record<string, unknown>>)[0]?.date, "2026-09-07");
  assert.equal(((paymentHistory as Record<string, unknown>).sub_payments as Array<Record<string, unknown>>)[0]?.id, "sub-1");
  assert.equal(serialized.includes("CDE_COUNTY__c"), false);
  assert.equal(serialized.includes("CI_Authorization_Date__c"), false);
});

test("attendance adapter canonicalizes source joins before evaluation", () => {
  const [schedule] = normalizeAttendanceRiskSchedules({
    schedules: [
      {
        CI_Authorization_Id__c: "AUTH-1",
        Authorization__r: { County__r: { County_Name__c: "Denver" } },
      },
    ],
    authorizationData: {
      authorizations: [{ Id: "AUTH-1", Name: "Authorization 1" }],
    },
    countyIdByName: { Denver: "COUNTY-1" },
    providerQualityTier: 2,
  });

  assert.deepEqual(schedule, {
    CI_Authorization_Id__c: "AUTH-1",
    Authorization__r: { County__r: { County_Name__c: "Denver" } },
    authorization_name: "Authorization 1",
    countyId: "COUNTY-1",
    qualityTier: 2,
  });
});

test("payment schema normalizes lifecycle statuses", () => {
  assert.equal(normalizePaymentStatus("4"), "PAID");
  assert.equal(normalizePaymentStatus("REQUESTED"), "REQUESTED");
  assert.equal(normalizePaymentStatus("UNKNOWN"), undefined);
});

test("payment adapter produces canonical input from source-shaped records", () => {
  const { payload } = normalizePaymentSourceBundle({
    initialization: {
      providers: [{ TXT_CHATS_RATING__c: "Level 1", CDE_TYPE_PROVR__c: "LICENSED" }],
      fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
    },
    servicePeriod: {
      servicePeriodId: "period-1",
      serviceBeginDate: "2026-09-01",
      serviceEndDate: "2026-09-07",
    },
    authorizationData: {
      normalizedAuthorizations: [{
        authorization: {
          Id: "auth-1",
          CDE_COUNTY__c: "county-1",
          Number_of_Drop_in_Days__c: 0,
          IDN_CLIENT__r: { DTE_DOB__c: "2024-01-01" },
        },
        fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "fiscal-1" },
      }],
      slotContracts: [{
        Id: "slot-1",
        IDN_AUTH__c: "auth-1",
        CDE_RATE_TYPE__c: "1",
        CDE_CARE_UNIT__c: "3",
        CDE_CARE_LEVEL__c: "5",
        DTE_BEGIN_SLOT__c: "2026-09-01",
        IND_OCCUPIED__c: true,
      }],
      encumbrances: [{
        idn_auth__c: "auth-1",
        dte_care__c: "2026-09-01",
        ind_0_36_months__c: false,
        cde_status_encmbr__c: "3",
      }],
      authorizationCopays: [],
    },
    countyData: {
      countyRatePlans: [{
        countyId: "county-1",
        absenceDaysTier1: 4,
      }],
    },
    scheduleData: {
      schedules: [{
        Id: "schedule-1",
        Authorization__c: "auth-1",
        CI_Authorization_Id__c: "auth-1",
        CI_Authorization_Date__c: "2026-09-01",
        CI_Authorization_Hours__c: 5,
        Hours__c: 4,
        Care_Not_Offered__c: false,
        Attendance__r: {
          records: [{ Record_Type_Name__c: "Check-In", Status__c: "PARENT_APPROVED" }],
        },
      }],
    },
    fiscalData: {
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
    },
    holidayData: { holidayList: [] },
    paymentData: { subPayments: [] },
    mode: "STATUS",
    asOfDate: "2026-09-08",
  });

  assert.equal(payload.rule_version, "provider-risk-payment-v3");
  assert.equal(payload.service_period.id, "period-1");
  assert.equal(payload.authorizations[0]?.id, "auth-1");
  assert.equal(payload.attendance_days[0]?.parent_confirmation, "CONFIRMED");
  assert.equal(payload.fiscal_rates[0]?.amount, 45);
  assert.equal(payload.existing_sub_payments.length, 0);
});

test("schedule normalizer owns nested attendance mapping", () => {
  const normalized = normalizeScheduleAttendance([
    {
      Id: "schedule-1",
      Authorization__c: "auth-1",
      CI_Authorization_Date__c: "2026-09-08",
      CI_Authorization_Id__c: "auth-1",
      Contact_Name__c: "Ava Example",
      Attendance__r: {
        records: [
          {
            Id: "transaction-1",
            Record_Type_Name__c: "Check-In",
            Status__c: "PARENT_PENDING",
          },
        ],
      },
    },
  ], "denver", 5);

  assert.equal(normalized.schedules[0]?.schedule_id, "schedule-1");
  assert.equal(normalized.schedules[0]?.parent_confirmation, "PENDING");
  assert.equal(normalized.transactions[0]?.type, 1);
});

test("schedule county falls back to the joined authorization county", () => {
  const normalized = normalizeScheduleAttendance(
    [{
      Id: "schedule-1",
      CI_Authorization_Id__c: "950289",
      CI_Authorization_Date__c: "2026-08-24",
      CI_Authorization_Hours__c: 8,
      Attendance__r: { records: [] },
    }],
    undefined,
    undefined,
    {
      authorizations: [{
        Id: "auth-1",
        Name: "950289",
        CDE_COUNTY__c: "county-1",
      }],
    },
  );

  assert.equal(normalized.schedules[0]?.county_id, "county-1");
});

test("schedule normalizer matches numeric DECL authorization names", () => {
  const normalized = normalizeScheduleAttendance(
    [{
      Id: "schedule-1",
      CI_Authorization_Id__c: 950289,
      CI_Authorization_Date__c: "2026-08-24",
      Attendance__r: { records: [] },
    }],
    undefined,
    undefined,
    {
      authorizations: [{
        Id: "auth-1",
        Name: "950289",
        CDE_COUNTY__c: "county-1",
      }],
    },
  );

  assert.equal(normalized.schedules[0]?.authorization_id, "auth-1");
  assert.equal(normalized.schedules[0]?.county_id, "county-1");
});

test("schedule county reads the county from a normalized authorization wrapper", () => {
  const normalized = normalizeScheduleAttendance(
    [{
      Id: "schedule-1",
      CI_Authorization_Id__c: "950289",
      CI_Authorization_Date__c: "2026-08-24",
      Attendance__r: { records: [] },
    }],
    undefined,
    undefined,
    {
      authorizations: [{
        authorization: {
          Id: "auth-1",
          Name: "950289",
          CDE_COUNTY__c: "county-1",
        },
        fiscalScheduleMatch: { status: "MATCHED" },
      }],
    },
  );

  assert.equal(normalized.schedules[0]?.authorization_id, "auth-1");
  assert.equal(normalized.schedules[0]?.county_id, "county-1");
});

test("schedule county prefers the CCCAP authorization reference when another relationship is present", () => {
  const normalized = normalizeScheduleAttendance(
    [{
      Id: "schedule-1",
      Authorization__c: "unrelated-relationship",
      CI_Authorization_Id__c: "950289",
      CI_Authorization_Date__c: "2026-08-24",
      Attendance__r: { records: [] },
    }],
    undefined,
    undefined,
    {
      authorizations: [{
        Id: "auth-1",
        Name: "950289",
        CDE_COUNTY__c: "county-1",
      }],
    },
  );

  assert.equal(normalized.schedules[0]?.authorization_id, "auth-1");
  assert.equal(normalized.schedules[0]?.county_id, "county-1");
});

test("payment orchestration preserves initialization failures", async () => {
  const client = {
    initialize: async () => {
      throw new Error("provider scope unavailable");
    },
  } as unknown as Parameters<typeof getPaymentAnalysis>[0];

  await assert.rejects(
    () => getPaymentAnalysis(client, {}),
    /provider scope unavailable/,
  );
});

test("next payout initializes provider scope before selecting its service period", async () => {
  const events: string[] = [];
  const client = {
    async getServicePeriods() {
      events.push("service period");
      return {
        servicePeriods: [{
          servicePeriodId: "period-1",
          serviceBeginDate: "2026-09-15",
          serviceEndDate: "2026-09-21",
        }],
      };
    },
    async initialize(input: Record<string, unknown>) {
      events.push(`initialize:${JSON.stringify(input)}`);
      throw new Error("provider scope unavailable");
    },
  } as unknown as Parameters<typeof getPaymentAnalysis>[0];

  await assert.rejects(
    () => getPaymentAnalysis(client, {}, "NEXT_PAYOUT"),
    /provider scope unavailable/,
  );
  assert.deepEqual(events, ["initialize:{}"]);
});

test("payment orchestration runs the canonical payload through the evaluator", async () => {
  let authorizationRequest: Record<string, unknown> | undefined;
  const client = {
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
    async getAuthorizations(input: Record<string, unknown>) {
      authorizationRequest = input;
      return {
        normalizedAuthorizations: [{
          authorization: {
            Id: "auth-1",
            CDE_COUNTY__c: "county-1",
            Number_of_Drop_in_Days__c: 0,
            IDN_CLIENT__r: { DTE_DOB__c: "2024-01-01" },
          },
          fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "fiscal-1" },
        }],
        slotContracts: [{
          Id: "slot-1",
          IDN_AUTH__c: "auth-1",
          CDE_RATE_TYPE__c: "1",
          CDE_CARE_UNIT__c: "3",
          CDE_CARE_LEVEL__c: "5",
          DTE_BEGIN_SLOT__c: "2026-09-01",
          IND_OCCUPIED__c: false,
        }],
        encumbrances: [{
          idn_auth__c: "auth-1",
          dte_care__c: "2026-09-01",
          ind_0_36_months__c: false,
          cde_status_encmbr__c: "3",
        }],
        authorizationCopays: [],
      };
    },
    async getCountyData() {
      return { countyRatePlans: [{ countyId: "county-1", absenceDaysTier1: 4 }] };
    },
    async getSchedules() {
      return {
        schedules: [{
          Id: "schedule-1",
          Authorization__c: "auth-1",
          authorization_id: "auth-1",
          rate_type_code: "1",
          CI_Authorization_Id__c: "auth-1",
          CI_Authorization_Rate_Type__c: "1",
          CI_Authorization_Date__c: "2026-09-01",
          CI_Authorization_Hours__c: 5,
          Hours__c: 4,
          Care_Not_Offered__c: false,
          Attendance__r: { records: [{ Record_Type_Name__c: "Check-In", Status__c: "PARENT_APPROVED" }] },
        }],
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
  } as unknown as Parameters<typeof getPaymentAnalysis>[0];

  const result = await getPaymentAnalysis(
    client,
    { dateFilter: "THIS_MONTH" },
    "STATUS",
    "2026-09-08",
  ) as Record<string, unknown>;
  const payment = result.payment as Record<string, unknown>;

  assert.deepEqual(authorizationRequest?.scheduleRateTypes, { "auth-1": "1" });
  assert.equal(result.paymentView, "STATUS");
  assert.equal(result.source_readiness, "COMPLETE");
  assert.equal(payment.status, "EXPECTED");
  assert.deepEqual((result.attendance as Record<string, unknown>).days, []);
  assert.deepEqual(result.detailPagination, { page: 0, pageSize: 0, totalRows: 1, hasMore: true });
});

test("payment orchestration filters payment analysis by authorization name", async () => {
  const client = {
    async initialize() {
      return {
        providers: [{ TXT_CHATS_RATING__c: "Level 1", CDE_TYPE_PROVR__c: "LICENSED" }],
        fiscalAgreements: [{ CDE_COUNTY__c: "county-1" }],
      };
    },
    async getServicePeriods() {
      return { servicePeriods: [{ servicePeriodId: "period-1", serviceBeginDate: "2026-09-01", serviceEndDate: "2026-09-07" }] };
    },
    async getAuthorizations() {
      return {
        normalizedAuthorizations: [
          { authorization: { Id: "auth-1", Name: "AUTH-ONE", CDE_COUNTY__c: "county-1", IDN_CLIENT__r: { DTE_DOB__c: "2024-01-01" } }, fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "fiscal-1" } },
          { authorization: { Id: "auth-2", Name: "AUTH-TWO", CDE_COUNTY__c: "county-1", IDN_CLIENT__r: { DTE_DOB__c: "2024-01-01" } }, fiscalScheduleMatch: { status: "MATCHED", fiscalScheduleId: "fiscal-1" } },
        ],
        slotContracts: [],
        encumbrances: [
          { idn_auth__c: "auth-1", dte_care__c: "2026-09-01", cde_status_encmbr__c: "3" },
          { idn_auth__c: "auth-2", dte_care__c: "2026-09-01", cde_status_encmbr__c: "3" },
        ],
        authorizationCopays: [],
      };
    },
    async getCountyData() { return { countyRatePlans: [{ countyId: "county-1", absenceDaysTier1: 4 }] }; },
    async getSchedules() {
      return { schedules: [
        { Id: "schedule-1", Authorization__c: "auth-1", authorization_id: "auth-1", authorization_name: "AUTH-ONE", CI_Authorization_Id__c: "AUTH-ONE", Contact_Name__c: "Child One", CI_Authorization_Rate_Type__c: "1", CI_Authorization_Date__c: "2026-09-01", CI_Authorization_Hours__c: 5, Hours__c: 5, Care_Not_Offered__c: false, Attendance__r: { records: [{ Record_Type_Name__c: "Check-In", Status__c: "PARENT_APPROVED" }] } },
        { Id: "schedule-2", Authorization__c: "auth-2", authorization_id: "auth-2", authorization_name: "AUTH-TWO", CI_Authorization_Id__c: "AUTH-TWO", Contact_Name__c: "Child Two", CI_Authorization_Rate_Type__c: "1", CI_Authorization_Date__c: "2026-09-01", CI_Authorization_Hours__c: 5, Hours__c: 5, Care_Not_Offered__c: false, Attendance__r: { records: [{ Record_Type_Name__c: "Check-In", Status__c: "PARENT_APPROVED" }] } },
      ] };
    },
    async getFiscalRates() { return { normalizedFiscalRates: { fiscalRates: [{ fiscalScheduleId: "fiscal-1", rateTypeCode: "1", careUnitCode: "2", paidTier: "PART_TIME", fiscalAgreementAmount: 9, sourceId: "rate-1" }], fiscalRateFees: [{ fiscalScheduleId: "fiscal-1" }] } }; },
    async getHolidayList() { return { holidayList: [] }; },
    async getPaymentHistory() { return { subPayments: [] }; },
  } as unknown as Parameters<typeof getPaymentAnalysis>[0];

  const result = await getPaymentAnalysis(client, { dateFilter: "THIS_MONTH" }, "STATUS", "2026-09-08", { authNames: ["AUTH-ONE"] }) as Record<string, unknown>;
  const payment = result.payment as Record<string, unknown>;
  assert.equal(payment.status, "EXPECTED");
  assert.equal(payment.amount, "45.00");

  const childResult = await getPaymentAnalysis(client, { dateFilter: "THIS_MONTH" }, "STATUS", "2026-09-08", { childNames: ["Child One"] }) as Record<string, unknown>;
  const childPayment = childResult.payment as Record<string, unknown>;
  assert.equal(childPayment.status, "EXPECTED");
  assert.equal(childPayment.amount, "45.00");

  const pagedResult = await getPaymentAnalysis(client, { dateFilter: "THIS_MONTH" }, "STATUS", "2026-09-08", { detailPage: 2, detailPageSize: 1 }) as Record<string, unknown>;
  const pagedAttendance = pagedResult.attendance as Record<string, unknown>;
  const pagination = pagedResult.detailPagination as Record<string, unknown>;
  assert.equal((pagedAttendance.days as unknown[]).length, 1);
  assert.equal(pagination.page, 2);
  assert.equal(pagination.pageSize, 1);
  assert.equal(pagination.totalRows, 2);
  assert.equal(pagination.hasMore, false);
});