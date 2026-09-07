import assert from "node:assert/strict";
import test from "node:test";

import {
  addDefaultCountyToSchedules,
  addProviderQualityTierToSchedules,
  livePaymentReadiness,
  normalizePaymentStatus,
  normalizeScheduleAttendance,
} from "../src/attendance-snapshot.js";
import { formatAttendanceRiskResult } from "../src/server.js";
import {
  buildCanonicalPaymentPayload,
  deriveAttendanceEnrichment,
  normalizeAttendanceDays,
  normalizeAuthorizationCopays,
  normalizePaymentFeeHistory,
  normalizePaymentFeeSchedules,
  normalizeEncumbranceStatus,
  normalizeExistingSubPayments,
  normalizeQualityTier,
  normalizeServicePeriod,
} from "../src/payment-payload-adapter.js";

test("live payment readiness blocks amounts until canonical sources are available", () => {
  assert.deepEqual(livePaymentReadiness(), {
    status: "BLOCKED",
    ruleVersion: "provider-risk-payment-v1",
    sourceReadiness: "BLOCKED_MISSING_REQUIRED_INPUTS",
    missingInputs: [
      "fiscal_rates",
      "attendance_transactions",
      "parent_confirmations",
      "absence_approvals",
      "existing_sub_payments",
      "slot_contracts",
      "parent_fees",
      "holiday_payment_eligibility",
      "rate_unit_mapping",
      "art_fee_history",
      "care_not_offered_status",
    ],
  });
});

test("attendance analysis returns affected child drill-down rows", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    attendanceRisk: {
      pending_confirmation_days: 2,
      risk_child_count: 1,
      children: [
        {
          child_name: "Taylor Example",
          household_name: "Example Household",
          county: null,
          authorization_dates: ["2026-09-01", "2026-09-02"],
          pending_confirmation_days: 2,
          probable_absence_days: 0,
          note: "2 pending parent confirmation day(s) require review.",
          potential_impact: "Payment remains conditional until confirmation is completed.",
          risk_codes: ["PARENT_CONFIRMATION_PENDING"],
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /Current-month attendance review found 1 child\(ren\) needing attention\./);
  assert.match(text, /2 pending parent confirmation day\(s\) affect 1 child\(ren\)\./);
  assert.match(text, /\| Child name \| Household name \| County \| Authorization name \| Service dates \| Note \| Potential impact \|/);
  assert.match(text, /\| Taylor Example \| Example Household \| Unavailable from the current source \| Unavailable from the current source \| 2026-09-01, 2026-09-02 \|/);
  assert.match(text, /1\. Review pending parent confirmations in the provider system/);
  assert.match(text, /2\. View next payout details/);
});

test("attendance analysis prioritizes absence and incomplete attendance review", () => {
  const result = formatAttendanceRiskResult({
    attendanceRisk: {
      pending_confirmation_days: 0,
      risk_child_count: 2,
      children: [
        {
          child_name: "Absence Example",
          household_name: "Example Household",
          county: "denver",
          authorization_names: ["AUTH-ABSENCE-1"],
          authorization_dates: ["2026-09-01"],
          note: "3 probable absence days exceed the county limit.",
          potential_impact: "Up to 1 absence day may be excluded from reimbursement.",
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
        {
          child_name: "Incomplete Example",
          household_name: "Example Household",
          county: "denver",
          authorization_dates: ["2026-09-02"],
          note: "A check-in requires a matching check-out.",
          potential_impact: "Review required.",
          risk_codes: ["INCOMPLETE_ATTENDANCE_RECORD"],
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /1 child\(ren\) have an absence-limit concern\./);
  assert.match(text, /1 child\(ren\) have incomplete attendance records\./);
  assert.match(text, /1\. Review county absence limits for the affected children/);
  assert.match(text, /2\. View next payout details/);
  assert.doesNotMatch(text, /Review and complete the pending parent confirmations/);

  const countyPolicyResult = formatAttendanceRiskResult({
    attendanceRisk: {
      pending_confirmation_days: 0,
      children: [
        {
          child_name: "Absence Example",
          household_name: "Example Household",
          county: "denver",
          authorization_names: ["AUTH-ABSENCE-1"],
          authorization_dates: ["2026-09-01"],
          note: "3 probable absence days exceed the county limit.",
          potential_impact: "Up to 1 absence day may be excluded from reimbursement.",
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
      ],
    },
  });
  assert.match(
    countyPolicyResult.content[0].text,
    /1\. Review county absence limits for the affected children/,
  );
});

test("attendance analysis fails closed when aggregate totals contradict child details", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "LAST_MONTH" },
    attendanceRisk: {
      pending_confirmation_days: 4,
      probable_absence_days: 25,
      risk_child_count: 2,
      children: [
        {
          child_name: "Consistent Example",
          pending_confirmation_days: 0,
          probable_absence_days: 0,
          risk_codes: [],
        },
      ],
    },
  });

  assert.equal(result.isError, true);
  assert.match(result.content[0].text, /PROVIDER_DATA_INCONSISTENT/);
  assert.match(result.content[0].text, /LAST_MONTH/);
});

test("attendance analysis preserves structured action scope for follow-ups", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "LAST_MONTH" },
    attendanceRisk: {
      pending_confirmation_days: 2,
      risk_child_count: 1,
      children: [
        {
          child_name: "Taylor Example",
          pending_confirmation_days: 2,
          probable_absence_days: 0,
          risk_codes: ["PARENT_CONFIRMATION_PENDING"],
        },
      ],
    },
  });

  assert.equal(result.structuredContent?.capability, "attendance-risk-analysis");
  assert.deepEqual(result.structuredContent?.scope, { dateFilter: "LAST_MONTH" });
  assert.deepEqual(result.structuredContent?.actionIntents, [
    {
      actionId: "review-pending-parent-confirmations",
      capability: "attendance-risk-analysis",
      label: "Review pending parent confirmations in the provider system",
      scope: { dateFilter: "LAST_MONTH" },
      childNames: ["Taylor Example"],
    },
  ]);
});

test("normalizes nested getSchedules attendance records into the Python contract", () => {
  const normalized = normalizeScheduleAttendance([
    {
      Id: "schedule-1",
      Type__c: "CCCAP_AUTHORIZED",
      Contact_Name__c: "YELLOWFOUR BALLOON",
      Authorization__r: {
        County__r: {
          County_Name__c: "Denver County",
        },
      },
      CI_Authorization_Rate_Type__c: "1",
      CI_Authorization_Id__c: "auth-1",
      CI_Authorization_Hours__c: 4,
      CI_Authorization_Date__c: "2026-08-18",
      Check_In_Count__c: 1,
      Check_Out_Count__c: 1,
      Hours__c: 9,
      Attendance__r: {
        records: [
          {
            Id: "transaction-out",
            Schedule__c: "schedule-1",
            Record_Type_Name__c: "Check-Out",
            Status__c: "PARENT_APPROVED",
            Sub_Type__c: "CCCAP",
            CI_Transaction_Time__c: "2026-08-18T23:00:00.000+0000",
            Creation_Source__c: "Provider",
          },
          {
            Id: "transaction-in",
            Schedule__c: "schedule-1",
            Record_Type_Name__c: "Check-In",
            Status__c: "PARENT_APPROVED",
            Sub_Type__c: "CCCAP",
            CI_Transaction_Time__c: "2026-08-18T14:00:00.000+0000",
            Creation_Source__c: "Provider",
          },
        ],
      },
    },
  ], "county-1", 5);

  assert.equal(normalized.schedules[0].schedule_id, "schedule-1");
  assert.equal(normalized.schedules[0].authorization_id, "auth-1");
  assert.equal(normalized.schedules[0].county_id, "county-1");
  assert.equal(normalized.schedules[0].county_name, "Denver County");
  assert.equal(normalized.schedules[0].quality_tier, 5);
  assert.equal(normalized.schedules[0].rate_type_code, "1");
  assert.equal(normalized.schedules[0].auth_status, "APPROVED");
  assert.equal(normalized.schedules[0].parent_confirmation, "CONFIRMED");
  assert.equal(normalized.schedules[0].absence_parent_approved, true);
  assert.equal(normalized.schedules[0].actual_start_ts, "2026-08-18T14:00:00.000+0000");
  assert.equal(normalized.schedules[0].actual_end_ts, "2026-08-18T23:00:00.000+0000");
  assert.deepEqual(
    normalized.transactions.map((transaction) => transaction.type).sort(),
    [1, 2],
  );
  assert.equal(normalized.transactions[0].status, "PARENT_APPROVED");
  assert.equal(normalized.transactions[0].authorization_id, "auth-1");
});

test("normalizes stable payment-level status codes for duplicate guards", () => {
  assert.equal(normalizePaymentStatus("1"), "REQUESTED");
  assert.equal(normalizePaymentStatus("2"), "REQUESTED");
  assert.equal(normalizePaymentStatus("3"), "REQUESTED");
  assert.equal(normalizePaymentStatus("4"), "PAID");
  assert.equal(normalizePaymentStatus("PAID"), "PAID");
  assert.equal(normalizePaymentStatus("UNKNOWN"), undefined);
});

test("adds only an unambiguous authenticated county to aggregate schedules", () => {
  const schedules = [
    { Id: "missing-county" },
    { Id: "source-county", County__c: "county-source" },
    {
      Id: "nested-county",
      Authorization__r: { County__r: { County_Name__c: "Denver County" } },
    },
  ];

  assert.deepEqual(addDefaultCountyToSchedules(schedules, "county-scope"), [
    { Id: "missing-county", countyId: "county-scope" },
    { Id: "source-county", County__c: "county-source" },
    schedules[2],
  ]);
  assert.deepEqual(addDefaultCountyToSchedules(schedules), schedules);
});

test("adds provider quality tier without changing schedule rate type", () => {
  const schedules = [{
    CI_Authorization_Rate_Type__c: "19",
    qualityTier: 1,
  }];

  assert.deepEqual(addProviderQualityTierToSchedules(schedules, 5), [{
    CI_Authorization_Rate_Type__c: "19",
    qualityTier: 5,
  }]);
});

test("adapts service periods and payment history to the canonical engine shape", () => {
  assert.deepEqual(
    normalizeServicePeriod({
      servicePeriodId: "SP-2026-09-01",
      serviceBeginDate: "2026-09-01",
      serviceEndDate: "2026-09-07",
    }),
    {
      id: "SP-2026-09-01",
      start_date: "2026-09-01",
      end_date: "2026-09-07",
    },
  );
  assert.deepEqual(
    normalizeExistingSubPayments({
      subPayments: [
        {
          idn_auth__c: "auth-1",
          idn_period_serv__c: "SP-2026-09-01",
          cde_status_pmt_sub__c: "4",
        },
        {
          idn_auth__c: "auth-2",
          idn_period_serv__c: "SP-2026-09-01",
          cde_status_pmt_sub__c: "2",
        },
      ],
    }),
    [
      {
        authorization_id: "auth-1",
        service_period_id: "SP-2026-09-01",
        status: "PAID",
      },
      {
        authorization_id: "auth-2",
        service_period_id: "SP-2026-09-01",
        status: "REQUESTED",
      },
    ],
  );
});

test("blocks unknown payment lifecycle statuses", () => {
  assert.throws(
    () => normalizeExistingSubPayments({
      subPayments: [{
        idn_auth__c: "auth-1",
        idn_period_serv__c: "SP-1",
        cde_status_pmt_sub__c: "9",
      }],
    }),
    /unsupported/,
  );
});

test("normalizes attendance days only when payment enrichments are authoritative", () => {
  assert.deepEqual(
    normalizeAttendanceDays(
      [{
        authorization_id: "auth-1",
        work_date: "2026-09-01",
        ci_authorization_hours: 5,
        raw_hours: 4,
        parent_confirmation: "CONFIRMED",
        absence_parent_approved: false,
      }],
      {
        "auth-1": {
          age_band: "OVER_36_MONTHS",
          occupied_slot_contract: false,
          care_not_offered: false,
          observed_holiday: false,
        },
      },
    ),
    [{
      authorization_id: "auth-1",
      service_date: "2026-09-01",
      authorized_hours: 5,
      attended_hours: 4,
      parent_confirmation: "CONFIRMED",
      absence_parent_approved: false,
      age_band: "OVER_36_MONTHS",
      slot_contract_present: false,
      occupied_slot_contract: false,
      care_not_offered: false,
      observed_holiday: false,
    }],
  );
});

test("blocks attendance-day construction when enrichment is missing", () => {
  assert.throws(
    () => normalizeAttendanceDays([{
      authorization_id: "auth-1",
      work_date: "2026-09-01",
      ci_authorization_hours: 5,
      raw_hours: 4,
      parent_confirmation: "CONFIRMED",
      absence_parent_approved: false,
    }], {}),
    /enrichment is missing/,
  );
});

test("assembles the complete provider-risk-payment canonical payload", () => {
  const payload = buildCanonicalPaymentPayload({
    servicePeriod: {
      servicePeriodId: "SP-1",
      serviceBeginDate: "2026-09-01",
      serviceEndDate: "2026-09-07",
    },
    schedules: [{
      authorization_id: "auth-1",
      work_date: "2026-09-01",
      ci_authorization_hours: 5,
      raw_hours: 4,
      parent_confirmation: "CONFIRMED",
      absence_parent_approved: false,
    }],
    attendanceEnrichmentByAuthorization: {
      "auth-1": {
        age_band: "OVER_36_MONTHS",
        occupied_slot_contract: false,
        care_not_offered: false,
        observed_holiday: false,
      },
    },
    authorizations: [{ id: "auth-1", county_id: "county-1", quality_tier: 1 }],
    countyPolicies: [{ county_id: "county-1", quality_tier: 1, absence_limit: 2 }],
    fiscalRates: [{ authorization_id: "auth-1", paid_tier: "PART_TIME", amount: 45 }],
    paymentHistory: { subPayments: [] },
  });

  assert.equal(payload.rule_version, "provider-risk-payment-v1");
  assert.equal(payload.service_period.id, "SP-1");
  assert.equal(payload.attendance_days[0].authorization_id, "auth-1");
  assert.equal(payload.fiscal_rates[0].amount, 45);
});

test("derives age band, occupied slot, and observed holiday enrichment from source rows", () => {
  assert.deepEqual(
    deriveAttendanceEnrichment(
      [{
        authorization_id: "auth-1",
        work_date: "2026-09-01",
        care_not_offered: false,
      }],
      {
        encumbrances: [{
          idn_auth__c: "auth-1",
          dte_care__c: "2026-09-01",
          ind_0_36_months__c: true,
          cde_status_encmbr__c: "5",
        }],
        slotContracts: [{
          IDN_AUTH__c: "auth-1",
          DTE_BEGIN_SLOT__c: "2026-01-01",
          DTE_END_SLOT__c: "2026-12-31",
          IND_OCCUPIED__c: true,
        }],
      },
      {
        holidayList: [{
          CDE_HOL__c: "Labor Day",
          DTE_HOL__c: "2026-08-31",
          DTE_OBSERVED_HOL__c: "2026-09-01",
        }],
      },
    ),
    {
      "auth-1": {
        age_band: "ZERO_TO_36_MONTHS",
        slot_contract_present: true,
        occupied_slot_contract: true,
        care_not_offered: true,
        observed_holiday: true,
        holiday_name: "Labor Day",
        holiday_date: "2026-08-31",
        observed_holiday_date: "2026-09-01",
      },
    },
  );
});

test("normalizes provider quality rating and facility type to county policy tiers", () => {
  assert.equal(normalizeQualityTier("Level 5", "LICENSED"), 6);
  assert.equal(normalizeQualityTier("Level 1", "LICENSED"), 2);
  assert.equal(normalizeQualityTier("Level 2", "LICENSED"), 3);
  assert.equal(normalizeQualityTier("Level 3", "LICENSED"), 4);
  assert.equal(normalizeQualityTier("Level 4", "LICENSED"), 5);
  assert.equal(normalizeQualityTier("Level 5", "EXE"), 1);
  assert.throws(
    () => normalizeQualityTier("Unknown", "LICENSED"),
    /unavailable or unsupported/,
  );
});

test("normalizes encumbrance lifecycle statuses including care not offered", () => {
  assert.equal(normalizeEncumbranceStatus("1"), "PENDING");
  assert.equal(normalizeEncumbranceStatus("2"), "AUTHORIZED");
  assert.equal(normalizeEncumbranceStatus("3"), "ATTENDED");
  assert.equal(normalizeEncumbranceStatus("4"), "PAID");
  assert.equal(normalizeEncumbranceStatus("5"), "CARE_NOT_OFFERED");
  assert.equal(normalizeEncumbranceStatus("UNKNOWN"), undefined);
});

test("normalizes authorization copays without allowing invalid amounts", () => {
  assert.deepEqual(
    normalizeAuthorizationCopays([{
      idn_auth__c: "auth-1",
      amt_copay_auth__c: 12.5,
      dte_begin_effv__c: "2026-09-01",
      dte_end_effv__c: "2026-09-30",
    }]),
    [{
      authorization_id: "auth-1",
      amount: 12.5,
      effective_start: "2026-09-01",
      effective_end: "2026-09-30",
    }],
  );
  assert.throws(
    () => normalizeAuthorizationCopays([{ idn_auth__c: "auth-1", amt_copay_auth__c: -1 }]),
    /must be non-negative/,
  );
});

test("normalizes scheduled slot and ART fees from fiscal and slot-contract sources", () => {
  assert.deepEqual(
    normalizePaymentFeeSchedules(
      [{
        fiscalScheduleId: "schedule-1",
        rateTypeCode: "1",
        careUnitCode: "3",
        providerAmount: "45.00",
      }],
      [{
        fiscalScheduleId: "schedule-1",
        activityProviderAmount: "10.00",
        activityFrequency: "MTH",
        activityMonths: "7,8",
      }],
      [{
        Id: "slot-1",
        IDN_AUTH__c: "auth-1",
        CDE_RATE_TYPE__c: "1",
        CDE_CARE_UNIT__c: "3",
        CDE_CARE_LEVEL__c: "5",
        DTE_BEGIN_SLOT__c: "2026-09-01",
        DTE_END_SLOT__c: "2026-09-30",
        CNT_DAYS_OF_MONTH__c: 20,
        CNT_DAYS_OF_WEEK__c: 5,
      }],
      { "auth-1": "schedule-1" },
    ),
    [{
      authorization_id: "auth-1",
      fiscal_schedule_id: "schedule-1",
      slot_contract_id: "slot-1",
      care_level: "5",
      effective_start: "2026-09-01",
      effective_end: "2026-09-30",
      days_of_month: 20,
      days_of_week: 5,
      slot_rate_amount: 45,
      activity_amount: 10,
      activity_frequency: "MTH",
      activity_months: "7,8",
    }],
  );
});

test("normalizes payment detail history by sub-payment authorization", () => {
  assert.deepEqual(
    normalizePaymentFeeHistory({
      subPayments: [{ idn_pmt_sub__c: 1001, idn_auth__c: "auth-1" }],
      paymentDetails: [{
        idn_pmt_sub__c: 1001,
        dte_care__c: "2026-09-01",
        amt_act_paid__c: 3,
        amt_slot_paid__c: 4,
      }],
    }),
    [{
      authorization_id: "auth-1",
      service_date: "2026-09-01",
      activity_paid: 3,
      registration_paid: 0,
      transportation_paid: 0,
      slot_paid: 4,
    }],
  );
});