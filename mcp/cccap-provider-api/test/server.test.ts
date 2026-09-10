import assert from "node:assert/strict";
import test from "node:test";

import {
  addDefaultCountyToSchedules,
  addCanonicalCountyIdToSchedules,
  addNestedCountyIdToSchedules,
  addProviderQualityTierToSchedules,
  addAuthorizationNamesToSchedules,
  livePaymentReadiness,
  normalizePaymentStatus,
  normalizeScheduleAttendance,
} from "../src/attendance-snapshot.js";
import {
  formatCountyPolicyResult,
  formatAttendanceRiskResult,
  formatPaymentResult,
} from "../src/server.js";
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
          absence_days: 0,
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
  assert.match(text, /Review 2 pending parent confirmation day\(s\)/);
  assert.match(text, /\*\*Drill down\*\*/);
  assert.match(text, /Attendance overview:/);
  assert.match(text, /Attendance by county:/);
  assert.match(text, /Recommended attendance views:/);
  const structuredSummary = result.structuredContent?.attendanceSummary as Record<string, unknown>;
  assert.equal(structuredSummary?.overview !== undefined, true);
  assert.equal(structuredSummary?.children, undefined);
  assert.equal(result.structuredContent?.availableViews, undefined);
  assert.equal(result.structuredContent?.viewControls, undefined);
  assert.equal(result.structuredContent?.actionIntents, undefined);
  assert.equal(result.structuredContent?.affectedChildNames, undefined);
  assert.equal(JSON.stringify(result.structuredContent).includes('"childNames"'), false);
  assert.doesNotMatch(text, /View next payout details/);
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
          note: "3 absence days exceed the county limit.",
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
  assert.match(text, /Review 1 child\(ren\) near or over the absence limit/);
  assert.match(text, /Review 1 incomplete attendance record\(s\)/);
  assert.doesNotMatch(text, /View next payout details/);
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
          note: "3 absence days exceed the county limit.",
          potential_impact: "Up to 1 absence day may be excluded from reimbursement.",
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
      ],
    },
  });
  assert.match(countyPolicyResult.content[0].text, /Review 1 child\(ren\) near or over the absence limit/);
});

test("attendance analysis does not label unavailable absence limits as concerns", () => {
  const result = formatAttendanceRiskResult({
    attendanceRisk: {
      pending_confirmation_days: 0,
      absence_days: 1,
      risk_child_count: 1,
      children: [
        {
          child_name: "Unavailable Limit Example",
          county: "denver",
          absence_days: 1,
          risk_codes: ["ABSENCE_LIMIT_UNAVAILABLE"],
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /absence-limit concern/);
  assert.doesNotMatch(text, /Review county absence limits/);
});

test("attendance analysis fails closed when aggregate totals contradict child details", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "LAST_MONTH" },
    attendanceRisk: {
      pending_confirmation_days: 4,
      absence_days: 25,
      risk_child_count: 2,
      children: [
        {
          child_name: "Consistent Example",
          pending_confirmation_days: 0,
          absence_days: 0,
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
          absence_days: 0,
          risk_codes: ["PARENT_CONFIRMATION_PENDING"],
        },
      ],
    },
  });

  assert.equal(result.structuredContent?.capability, "attendance-risk-analysis");
  assert.deepEqual(result.structuredContent?.scope, { dateFilter: "LAST_MONTH" });
  assert.equal(JSON.stringify(result.structuredContent).includes("childNames"), false);
  assert.equal(Array.isArray(result.structuredContent?.actionControls), true);
});

test("attendance analysis focuses pending-confirmation follow-ups", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "PARENT_CONFIRMATIONS",
    attendanceRisk: {
      pending_confirmation_days: 2,
      absence_days: 3,
      risk_child_count: 1,
      children: [
        {
          child_name: "Taylor Example",
          pending_confirmation_days: 2,
          absence_days: 3,
          risk_codes: [
            "PARENT_CONFIRMATION_PENDING",
            "ABSENCE_LIMIT_APPROACHING",
          ],
          note: "2 pending parent confirmation day(s) require review.",
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /pending parent confirmation day\(s\)/);
  assert.doesNotMatch(text, /absence-limit concern/);
  assert.doesNotMatch(text, /county limit threshold/);
});

test("attendance analysis focuses absence-limit follow-ups", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "ABSENCE_LIMITS",
    attendanceRisk: {
      pending_confirmation_days: 2,
      absence_days: 5,
      risk_child_count: 1,
      children: [
        {
          child_name: "Absence Example",
          county: "Denver",
          pending_confirmation_days: 2,
          absence_days: 5,
          risk_codes: [
            "PARENT_CONFIRMATION_PENDING",
            "ABSENCE_LIMIT_EXCEEDED",
          ],
          note: "5 absence day(s) exceed the county limit.",
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /absence-limit concern/);
  assert.match(text, /5 absence day\(s\)/);
  assert.doesNotMatch(text, /pending parent confirmation day\(s\)/);
});

test("attendance absence follow-up points to child-level attendance retrieval", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    attendanceRisk: {
      pending_confirmation_days: 0,
      absence_days: 5,
      risk_child_count: 1,
      children: [
        {
          child_name: "Absence Example",
          county: "Denver",
          absence_days: 5,
          absence_limit: 4,
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
      ],
    },
  });

  assert.equal(JSON.stringify(result.structuredContent).includes("childNames"), false);
  assert.equal(Array.isArray(result.structuredContent?.actionControls), true);
});

test("county policy formatter returns provider-facing absence limits", () => {
  const result = formatCountyPolicyResult({
    county_plans: [
      {
        county_name: "Denver",
        effective_start: "2026-01-01",
        absence_days_by_tier: { "1": 5, "2": 7, "3": 9, "4": 11, "5": 13 },
      },
    ],
  });

  const text = result.content[0].text;
  assert.match(text, /\| Denver \| 2026-01-01 \| 5 \| 7 \| 9 \| 11 \| 13 \|/);
  assert.equal(result.structuredContent?.capability, "county-policy");
});

test("normalizes nested getSchedules attendance records into the Python contract", () => {
  const normalized = normalizeScheduleAttendance([
    {
      Id: "schedule-1",
      Type__c: "CCCAP_AUTHORIZED",
      Contact_Name__c: "YELLOWFOUR BALLOON",
      Authorization__c: "auth-1",
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
            CI_Transaction_ID__c: "transaction-out-canonical",
            Reporting_Authorization_Id__c: "auth-reporting-1",
            CI_Transaction_Type__c: 2,
            CI_Transaction_Result__c: 1,
            CI_Attendance_Hours__c: 9,
            CI_Attendance_Date__c: "2026-08-18",
            CI_Provider_ID__c: "provider-1",
            CI_Client_Id__c: "client-1",
            CI_Begin_Date__c: "2026-08-18",
            CI_End_Date__c: "2026-08-18",
            Denial_Status__c: undefined,
            Schedule__c: "schedule-1",
            Record_Type_Name__c: "Check-Out",
            Status__c: "PARENT_APPROVED",
            Sub_Type__c: "CCCAP",
            CI_Transaction_Time__c: "2026-08-18T23:00:00.000+0000",
            Creation_Source__c: "Provider",
          },
          {
            Id: "transaction-in",
            CI_Transaction_ID__c: "transaction-in-canonical",
            Reporting_Authorization_Id__c: "auth-1",
            CI_Transaction_Type__c: 1,
            CI_Transaction_Result__c: 1,
            CI_Attendance_Hours__c: 0,
            CI_Attendance_Date__c: "2026-08-18",
            CI_Provider_ID__c: "provider-1",
            CI_Client_Id__c: "client-1",
            CI_Begin_Date__c: "2026-08-18",
            CI_End_Date__c: "2026-08-18",
            Denial_Status__c: undefined,
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

  assert.equal(normalized.schedules[0]?.schedule_id, "schedule-1");
  assert.equal(normalized.schedules[0]?.authorization_id, "auth-1");
  assert.equal(normalized.schedules[0]?.authorization_name, undefined);
  assert.equal(normalized.schedules[0]?.county_id, "county-1");
  assert.equal(normalized.schedules[0]?.county_name, "Denver County");
  assert.equal(normalized.schedules[0]?.quality_tier, 5);
  assert.equal(normalized.schedules[0]?.rate_type_code, "1");
  // No explicit Authorization_Status__c/authorization_status/expr0 value was
  // returned for this schedule, so auth_status must fail closed to undefined
  // rather than defaulting to APPROVED because Type__c is CCCAP_AUTHORIZED.
  assert.equal(normalized.schedules[0]?.auth_status, undefined);
  assert.equal(normalized.schedules[0]?.parent_confirmation, "CONFIRMED");
  assert.equal(normalized.schedules[0]?.absence_parent_approved, true);
  assert.equal(normalized.schedules[0]?.actual_start_ts, "2026-08-18T14:00:00.000+0000");
  assert.equal(normalized.schedules[0]?.actual_end_ts, "2026-08-18T23:00:00.000+0000");
  assert.deepEqual(
    normalized.transactions.map((transaction) => transaction.type).sort(),
    [1, 2],
  );
  assert.equal(normalized.transactions[0]?.status, "PARENT_APPROVED");
  assert.equal(normalized.transactions[0]?.transaction_id, "transaction-out-canonical");
  assert.equal(normalized.transactions[0]?.authorization_id, "auth-reporting-1");
  assert.equal(normalized.transactions[0]?.client_id, "client-1");
  assert.equal(normalized.transactions[0]?.result, 1);
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
    {
      Id: "nested-county",
      Authorization__r: { County__r: { County_Name__c: "Denver County" } },
      countyId: "county-scope",
    },
  ]);
  assert.deepEqual(addDefaultCountyToSchedules(schedules), schedules);
});

test("risk snapshots canonicalize source county fields for absence limits", () => {
  const schedules = addCanonicalCountyIdToSchedules([
    { County__c: "county-source" },
    { CDE_COUNTY__c: "county-code" },
    { countyId: "county-existing" },
  ]);

  assert.deepEqual(schedules, [
    { County__c: "county-source", countyId: "county-source" },
    { CDE_COUNTY__c: "county-code", countyId: "county-code" },
    { countyId: "county-existing" },
  ]);
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

test("forecast attendance defaults missing confirmation to pending", () => {
  assert.deepEqual(
    normalizeAttendanceDays(
      [{
        authorization_id: "auth-1",
        work_date: "2026-09-01",
        ci_authorization_hours: 5,
        raw_hours: 4,
      }],
      {
        "auth-1": {
          age_band: "OVER_36_MONTHS",
          occupied_slot_contract: false,
          care_not_offered: false,
          observed_holiday: false,
        },
      },
      { mode: "FORECAST", asOfDate: "2026-09-09" },
    )[0]?.parent_confirmation,
    "PENDING",
  );
});

test("forecast attendance defaults missing actual hours to zero", () => {
  assert.equal(
    normalizeAttendanceDays(
      [{
        authorization_id: "auth-1",
        work_date: "2026-09-01",
        ci_authorization_hours: 5,
      }],
      {
        "auth-1": {
          age_band: "OVER_36_MONTHS",
          occupied_slot_contract: false,
          care_not_offered: false,
          observed_holiday: false,
        },
      },
      { mode: "FORECAST", asOfDate: "2026-09-09" },
    )[0]?.attended_hours,
    0,
  );
});

test("future forecast rows retain authorized hours and ignore actual hours", () => {
  assert.deepEqual(
    normalizeAttendanceDays(
      [{
        authorization_id: "auth-1",
        work_date: "2026-09-10",
        ci_authorization_hours: 8,
        raw_hours: 2,
      }],
      {
        "auth-1": {
          age_band: "OVER_36_MONTHS",
          occupied_slot_contract: false,
          care_not_offered: false,
          observed_holiday: false,
        },
      },
      { mode: "FORECAST", asOfDate: "2026-09-09" },
    )[0],
    {
      authorization_id: "auth-1",
      service_date: "2026-09-10",
      authorized_hours: 8,
      attended_hours: 0,
      parent_confirmation: "PENDING",
      absence_parent_approved: false,
      age_band: "OVER_36_MONTHS",
      slot_contract_present: false,
      occupied_slot_contract: false,
      care_not_offered: false,
      observed_holiday: false,
      forecast_basis: "SCHEDULED",
    },
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
  assert.equal(payload.attendance_days[0]?.authorization_id, "auth-1");
  assert.equal(payload.fiscal_rates[0]?.amount, 45);
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
        authorizations: [{
          Id: "auth-1",
          IDN_CLIENT__r: { DTE_DOB__c: "2024-09-02" },
        }],
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

test("derives age band from child DOB and care date", () => {
  assert.deepEqual(
    deriveAttendanceEnrichment(
      [{ authorization_id: "auth-1", work_date: "2026-09-01", care_not_offered: false }],
      {
        authorizations: [{
          Id: "auth-1",
          IDN_CLIENT__r: { DTE_DOB__c: "2023-10-01" },
        }],
        encumbrances: [{
          idn_auth__c: "auth-1",
          dte_care__c: "2026-09-01",
          cde_status_encmbr__c: "2",
        }],
        slotContracts: [],
      },
      { holidayList: [] },
    )["auth-1"]?.age_band,
    "ZERO_TO_36_MONTHS",
  );
});

test("joins schedule DECL authorization references to Salesforce authorization names", () => {
  assert.equal(
    deriveAttendanceEnrichment(
      [{
        authorization_id: "a3ddl-decl-1",
        authorization_name: 950289,
        work_date: "2026-09-01",
        care_not_offered: false,
      }],
      {
        authorizations: [{
          Id: "a0s-salesforce-1",
          Name: "950289",
          IDN_CLIENT__r: { DTE_DOB__c: "2023-10-01" },
        }],
        encumbrances: [{
          idn_auth__c: "a0s-salesforce-1",
          dte_care__c: "2026-09-01",
          cde_status_encmbr__c: "2",
        }],
        slotContracts: [],
      },
      { holidayList: [] },
    )["a3ddl-decl-1"]?.age_band,
    "ZERO_TO_36_MONTHS",
  );
});

test("joins encumbrances through either external authorization reference", () => {
  assert.equal(
    deriveAttendanceEnrichment(
      [{ authorization_id: "auth-1", work_date: "2026-09-01", care_not_offered: false }],
      {
        authorizations: [{
          Id: "auth-1",
          IDN_EXTNL__c: "external-1",
          Name: "958591",
          IDN_CLIENT__r: { DTE_DOB__c: "2020-01-01" },
        }],
        encumbrances: [{
          idn_auth__c: "unrelated-reference",
          idn_encmbr_auth__c: "external-1",
          dte_care__c: "2026-09-01",
          cde_status_encmbr__c: "2",
        }],
        slotContracts: [],
      },
      { holidayList: [] },
    )["auth-1"]?.age_band,
    "OVER_36_MONTHS",
  );
});

test("normalizes provider quality rating and facility type to county policy tiers", () => {
  assert.equal(normalizeQualityTier("Level 1", "LICENSED"), 1);
  assert.equal(normalizeQualityTier("Level 2", "LICENSED"), 2);
  assert.equal(normalizeQualityTier("Level 3", "LICENSED"), 3);
  assert.equal(normalizeQualityTier("Level 4", "LICENSED"), 4);
  assert.equal(normalizeQualityTier("Level 5", "LICENSED"), 5);
  assert.equal(normalizeQualityTier("Level 5", "EXE"), 5);
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
        ageGroupCode: "5",
        careUnitCode: "3",
        fiscalAgreementAmount: "45.00",
        providerAmount: "45.00",
      }],
      [{
        fiscalScheduleId: "schedule-1",
        activityFiscalAgreementAmount: "10.00",
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
      }, {
        Id: "vacant-slot-1",
        IDN_AUTH__c: null,
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

test("does not let an ambiguous slot rate block authorization-level payment mapping", () => {
  assert.deepEqual(
    normalizePaymentFeeSchedules(
      [{
        fiscalScheduleId: "schedule-1",
        rateTypeCode: "1",
        ageGroupCode: "5",
        careUnitCode: "3",
        fiscalAgreementAmount: "45.00",
        providerAmount: "45.00",
      }, {
        fiscalScheduleId: "schedule-1",
        rateTypeCode: "1",
        ageGroupCode: "6",
        careUnitCode: "3",
        fiscalAgreementAmount: "46.00",
        providerAmount: "46.00",
      }],
      [{ fiscalScheduleId: "schedule-1" }],
      [{
        Id: "slot-ambiguous",
        IDN_AUTH__c: "auth-1",
        CDE_RATE_TYPE__c: "1",
        CDE_CARE_UNIT__c: "3",
        CDE_CARE_LEVEL__c: "7",
        DTE_BEGIN_SLOT__c: "2026-09-01",
      }],
      { "auth-1": "schedule-1" },
    ),
    [],
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

test("payment results use a provider-facing table and preserve blocked states", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    scope: { dateFilter: "THIS_MONTH" },
    source_readiness: "BLOCKED_MISSING_REQUIRED_INPUTS",
    sourceRetrievedAt: "2026-09-08T12:00:00.000Z",
    servicePeriod: {
      servicePeriodId: "SP-2026-09-07",
      serviceBeginDate: "2026-09-07",
      serviceEndDate: "2026-09-13",
      paymentReleaseDate: "2026-09-24",
      status: "SCHEDULED",
    },
    payment: {
      status: "BLOCKED",
      missing_inputs: ["fiscal_rates", "parent_confirmations"],
    },
  });

  assert.match(result.content[0].text, /Next payout summary: Blocked/);
  assert.match(result.content[0].text, /⚠️ \*All amounts shown are estimated based on current system data and are subject to change; they do not represent confirmed or final payout amounts\.\*$/);
  assert.match(result.content[0].text, /Services from/);
  assert.match(result.content[0].text, /2026-09-24/);
  assert.match(result.content[0].text, /fiscal_rates, parent_confirmations/);
  assert.doesNotMatch(result.content[0].text, /amount \|/);
  assert.equal(result.structuredContent?.providerMessage, result.content[0].text);
  assert.deepEqual(result.structuredContent?.scope, { dateFilter: "THIS_MONTH" });
});

test("payment results show scheduled forecast rows for child drill-down", () => {
  const result = formatPaymentResult({
    paymentView: "CURRENT_WEEK_FORECAST",
    calculation_mode: "CURRENT_WEEK_FORECAST",
    status: "ok",
    rule_version: "provider-risk-payment-v1",
    scope: { dateFilter: "DATE_RANGE", dateFrom: "2026-09-07", dateTo: "2026-09-13" },
    servicePeriod: { servicePeriodId: "SP-2026-09-07" },
    payment: { status: "CONDITIONAL", amount: "90.00", amount_at_risk: "45.00" },
    attendance: { days: [{
      child_name: "Taylor Example",
      county_id: "denver",
      service_date: "2026-09-09",
      forecast_basis: "SCHEDULED",
      classification: "SCHEDULED_FORECAST",
      unit_hours: "5.00",
      conditional: true,
    }] },
  });

  assert.match(result.content[0].text, /Current service-period forecast: Conditional/);
  assert.match(result.content[0].text, /⚠️ \*All amounts shown are estimated based on current system data and are subject to change; they do not represent confirmed or final payout amounts\.\*$/);
  assert.match(result.content[0].text, /Taylor Example \| Unavailable from the current source \| Unavailable from the current source \| 2026-09-09/);
  assert.match(result.content[0].text, /2026-09-09 \| SCHEDULED_FORECAST \| 5\.00/);
  assert.doesNotMatch(result.content[0].text, /\| Scheduled forecast \|/);
  assert.equal(result.structuredContent?.calculationMode, "CURRENT_WEEK_FORECAST");
});

test("payment results keep initial summary to the measure table and composition", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "90.00",
      summary: [{
        county_id: "denver",
        county_name: "Denver",
        paid_tier: "PART_TIME",
        rate: "9.00",
        basis: "ACTUAL",
        children_served: 1,
        hours: "10.00",
        amount: "90.00",
        conditional_amount: "90.00",
      }],
    },
    attendance: { days: [{
      child_name: "Taylor Example",
      county_id: "denver",
      service_date: "2026-09-09",
      forecast_basis: "ACTUAL",
      classification: "ATTENDED",
      unit_hours: "10.00",
      conditional: true,
    }] },
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /Payment differences:/);
  assert.doesNotMatch(text, /Payment by category:/);
  assert.doesNotMatch(text, /County detail:/);
  assert.doesNotMatch(text, /County payment totals:/);
  assert.match(text, /Next payout summary: Conditional/);
  assert.deepEqual(result.structuredContent?.actionIntents, [
    {
      actionId: "open-payment-detail",
      capability: "payment-analysis",
      tool: "cccap_analyze_payment",
      label: "Open the highest-impact child payment details",
      reason: "Inspect the child and service-date rows behind this summary.",
      priority: "high",
      section: "drill-down",
      source: "current-result",
      input: { view: "NEXT_PAYOUT", detailPage: 1 },
    },
  ]);
});

test("payment detail reports its bounded page window", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    detailPagination: { page: 2, pageSize: 1, totalRows: 2, hasMore: false },
    attendance: { days: [{
      child_name: "Taylor Example",
      county_id: "denver",
      service_date: "2026-09-10",
      forecast_basis: "ACTUAL",
      classification: "ATTENDED",
      unit_hours: "5.00",
      conditional: false,
    }] },
  });

  assert.match(result.content[0].text, /Showing detail rows 2-2 of 2 \(page 2; page size 1\)\./);
  assert.deepEqual(result.structuredContent?.detailPagination, { page: 2, pageSize: 1, totalRows: 2, hasMore: false });
});

test("payment detail omits zero-value NO_CARE rows", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    attendance: { days: [
      {
        child_name: "Taylor Example",
        authorization_name: "AUTH-2026-001",
        county_name: "Denver",
        service_date: "2026-09-09",
        classification: "NO_CARE",
        unit_hours: 0,
        conditional: false,
      },
      {
        child_name: "Taylor Example",
        authorization_name: "AUTH-2026-001",
        county_name: "Denver",
        service_date: "2026-09-10",
        classification: "ABSENCE",
        unit_hours: 5,
        conditional: false,
      },
    ] },
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /NO_CARE/);
  assert.match(text, /2026-09-10 \| ABSENCE \| 5/);
});

test("attendance detail caps the provider-facing table and reports the remainder", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    attendanceRisk: {
      pending_confirmation_days: 11,
      risk_child_count: 11,
      children: Array.from({ length: 11 }, (_, index) => ({
        child_name: `Child ${index + 1}`,
        pending_confirmation_days: 1,
        absence_days: 0,
        risk_codes: ["PARENT_CONFIRMATION_PENDING"],
      })),
    },
  });

  const text = result.content[0].text;
  assert.match(text, /\| Child 1 \|/);
  assert.match(text, /\| Child 7 \|/);
  assert.doesNotMatch(text, /\| Child 8 \|/);
  assert.match(text, /Showing the first 7 of 11 affected children/);
});

test("attendance schedules inherit authorization names from scoped authorizations", () => {
  const schedules = addAuthorizationNamesToSchedules(
    [{ CI_Authorization_Id__c: "auth-1", Contact_Name__c: "Taylor Example" }],
    { authorizations: [{ Id: "auth-1", IDN_EXTNL__c: "DECL-AUTH-1", Name: "AUTH-2026-001" }] },
  );

  assert.deepEqual(schedules, [{
    CI_Authorization_Id__c: "auth-1",
    Contact_Name__c: "Taylor Example",
    authorization_name: "AUTH-2026-001",
  }]);

  assert.deepEqual(
    addAuthorizationNamesToSchedules(
      [{ CI_Authorization_Id__c: "DECL-AUTH-1" }],
      { authorizations: [{ Id: "auth-1", IDN_EXTNL__c: "DECL-AUTH-1", Name: "AUTH-2026-001" }] },
    ),
    [{ CI_Authorization_Id__c: "DECL-AUTH-1", authorization_name: "AUTH-2026-001" }],
  );

  assert.deepEqual(
    addAuthorizationNamesToSchedules(
      [{ CI_Authorization_Id__c: "AUTH-2026-001" }],
      { authorizations: [{ Id: "auth-1", IDN_EXTNL__c: "DECL-AUTH-1", Name: "AUTH-2026-001" }] },
    ),
    [{ CI_Authorization_Id__c: "AUTH-2026-001", authorization_name: "AUTH-2026-001" }],
  );

  assert.deepEqual(
    addAuthorizationNamesToSchedules(
      [{ CI_Authorization_Id__c: 950241 }],
      { authorizations: [{ Id: "auth-1", IDN_EXTNL__c: "950241", Name: "AUTH-2026-001" }] },
    ),
    [{ CI_Authorization_Id__c: 950241, authorization_name: "AUTH-2026-001" }],
  );
});

test("risk snapshots join county by name from the DECL-sourced schedule, not by ID", () => {
  const schedules = addNestedCountyIdToSchedules(
    [{
      CI_Authorization_Id__c: 950241,
      Authorization__r: {
        County__c: "a3g1J0000004WB6QAM",
        County__r: { Id: "a3g1J0000004WB6QAM", County_Name__c: "Denver" },
      },
    }],
    { Denver: "a1441000004dc7KAAQ" },
  );

  assert.deepEqual(schedules, [{
    CI_Authorization_Id__c: 950241,
    Authorization__r: {
      County__c: "a3g1J0000004WB6QAM",
      County__r: { Id: "a3g1J0000004WB6QAM", County_Name__c: "Denver" },
    },
    countyId: "a1441000004dc7KAAQ",
  }]);
});

test("canonicalizes DECL authorization references to Salesforce authorization IDs", () => {
  assert.equal(
    normalizeScheduleAttendance(
      [{
        CI_Authorization_Id__c: "941328",
        CI_Authorization_Date__c: "2026-08-24",
      }],
      undefined,
      undefined,
      {
        authorizations: [{ Id: "a0sPg000009BE0rIAG", Name: "941328" }],
      },
    ).schedules[0]?.authorization_id,
    "a0sPg000009BE0rIAG",
  );
});

test("payment summary omits detail rows but keeps period metadata", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    servicePeriod: { id: "period-1", start_date: "2026-09-07", end_date: "2026-09-13" },
    detailPagination: { page: 0, pageSize: 0, totalRows: 182, hasMore: true },
    attendance: { days: [] },
  });

  const text = result.content[0].text;
  assert.match(text, /Next payout summary: Expected/);
  assert.match(text, /Services from.*2026-09-07/);
  assert.match(text, /Services through.*2026-09-13/);
  assert.match(text, /Detail available: 182 child\/date rows/);
  assert.doesNotMatch(text, /Detail by child and service date/);
});

test("payment continuation metadata preserves the complete provider message", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "0.00",
      summary_view: {
        overview: { amount_at_risk: "100.00", excluded_days: 1 },
        county_composition: [{
          county: "Denver",
          care: { hours: "40.00", amount: "360.00" },
          absence: { hours: "8.00", amount: "72.00" },
          drop_in: { hours: "0.00", amount: "0.00" },
          vacant_slots: { days: 0, amount: "0.00" },
          paid_holidays: { hours: "0.00", amount: "0.00" },
          potential_total: "432.00",
        }],
      },
    },
    detailPagination: { page: 0, pageSize: 0, totalRows: 0, hasMore: false },
  });

  assert.equal(result.structuredContent?.providerMessage, result.content[0].text);
  assert.match(String(result.structuredContent?.providerMessage), /County payment composition \(potential amounts\)/);
  assert.equal((result.structuredContent?.summaryView as Record<string, unknown>)?.children, undefined);
});

test("payment detail never exposes Salesforce record identifiers", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    detailPagination: { page: 1, pageSize: 1, totalRows: 1, hasMore: false },
    attendance: { days: [{
      child_name: "Taylor Example",
      authorization_id: "a0sPg000009BE0rIAG",
      county_name: "a1441000004dc7KAAQ",
      service_date: "2026-09-10",
      classification: "ATTENDED",
      unit_hours: "5.00",
      conditional: false,
    }] },
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /a0sPg000009BE0rIAG|a1441000004dc7KAAQ/);
  assert.match(text, /Unavailable from the current source/);
});

test("payment drill-down targets the highest-impact child", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    highestImpactChildName: "Taylor Example",
    payment: { status: "CONDITIONAL", amount: "90.00" },
    detailPagination: { page: 0, pageSize: 0, totalRows: 2, hasMore: true },
    attendance: { days: [] },
  });

  assert.deepEqual(result.structuredContent?.actionIntents, [{
    actionId: "open-payment-detail",
    capability: "payment-analysis",
    tool: "cccap_analyze_payment",
    label: "Open the highest-impact child payment details",
    reason: "Inspect the child and service-date rows behind this summary.",
    priority: "high",
    section: "drill-down",
    source: "current-result",
    input: { view: "NEXT_PAYOUT", detailPage: 1, childNames: ["Taylor Example"] },
  }]);
});

test("attendance formatter reports unmatched child filters", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "ABSENCE_LIMITS",
    attendanceRisk: {
      children: [],
      unmatched_child_names: ["Missing Child"],
    },
  });

  assert.match(result.content[0].text, /No attendance records were found for 1 requested child\(ren\)/);
});

test("incomplete attendance action returns child-level detail rows", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "INCOMPLETE_ATTENDANCE",
    attendanceRisk: {
      pending_confirmation_days: 4,
      absence_days: 3,
      children: [
        {
          child_name: "Incomplete Example",
          household_name: "Example Household",
          county: "denver",
          authorization_names: ["AUTH-INCOMPLETE-1"],
          authorization_dates: ["2026-09-02"],
          service_dates: ["2026-09-02"],
          note: "A check-in requires a matching check-out.",
          potential_impact: "Review required.",
          risk_codes: ["INCOMPLETE_ATTENDANCE_RECORD"],
        },
        {
          child_name: "Pending Example",
          risk_codes: ["PARENT_CONFIRMATION_PENDING"],
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /Incomplete Example/);
  assert.match(text, /A check-in requires a matching check-out/);
  assert.doesNotMatch(text, /Pending Example/);
});

test("payment summary does not inline child rollup rows before detail is requested", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "CONDITIONAL", amount: "0.00" },
    summary_view: {
      overview: { amount_at_risk: "100.00", excluded_days: 1 },
      children: [{ label: "Taylor Example", days: 7, hours: "40.00", amount: "0.00" }],
    },
    detailPagination: { page: 0, pageSize: 0, totalRows: 7, hasMore: true },
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /Taylor Example/);
  assert.match(text, /Detail available: 7 child\/date rows/);
});

test("initial payment summary renders county composition columns", () => {
  const result = formatPaymentResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "0.00",
      summary_view: {
        county_composition: [{
          county: "Denver",
          care: { hours: "40.00", amount: "360.00" },
          absence: { hours: "8.00", amount: "72.00" },
          drop_in: { hours: "4.00", amount: "36.00" },
          vacant_slots: { days: 2, amount: "18.00" },
          paid_holidays: { hours: "8.00", amount: "72.00" },
          potential_total: "558.00",
        }],
      },
    },
    detailPagination: { page: 0, pageSize: 0, totalRows: 0, hasMore: false },
  });

  const text = result.content[0].text;
  assert.match(text, /County payment composition \(potential amounts\)/);
  assert.match(text, /Care hours \| Care amount/);
  assert.match(text, /Absence hours \| Absence amount/);
  assert.match(text, /Drop-in hours \| Drop-in amount/);
  assert.match(text, /Vacant slot days \| Vacant slot amount/);
  assert.match(text, /Paid holiday hours \| Paid holiday amount/);
  assert.match(text, /\| Denver \| 40\.00 \| ~ \$360\.00/);
  assert.match(text, /~ \$558\.00/);
});