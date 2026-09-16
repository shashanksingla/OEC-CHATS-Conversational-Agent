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
} from "../src/attendance-engine.js";
import {
  formatCountyPolicyResult,
  formatAttendanceRiskResult,
  formatPayoutResult,
} from "../src/server.js";
import {
  buildCanonicalPaymentPayload,
  deriveAttendanceEnrichment,
  normalizeAttendanceDays,
  normalizeEncumbranceStatus,
  normalizeExistingSubPayments,
  normalizeQualityTier,
  normalizeServicePeriod,
} from "../src/payment-engine.js";

test("live payment readiness blocks amounts until canonical sources are available", () => {
  assert.deepEqual(livePaymentReadiness(), {
    status: "BLOCKED",
    ruleVersion: "provider-risk-payment-v3",
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
  // County-summary-first: an unscoped request no longer renders child rows -
  // this test is specifically about the drill-down shape, so it scopes to
  // the named child (the same narrowing the "Show affected children" action
  // would apply) to reach that shape.
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH", childNames: ["Taylor Example"] },
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
  // Column-hygiene fix: Outside window/Over limit/Est. risk are dropped when
  // every displayed row lacks a value for them (this fixture only has a
  // Pending count).
  assert.match(text, /\| Child \| Authorization \| County \| Pending \|/);
  assert.match(text, /\| Taylor Example \| Unavailable from the current source \| Unavailable from the current source \| 2 \|/);
  assert.match(text, /Review pending confirmations — 2 days/);
  assert.match(text, /\*\*Recommended actions\*\*/);
  // Already childNames-scoped (the drill-down shape itself), so the
  // facility-wide overview/county/available-views sections correctly do not
  // render here - those are for the unscoped county-summary-first response,
  // covered by other tests.
  assert.doesNotMatch(text, /Attendance overview:/);
  assert.doesNotMatch(text, /Attendance by county:/);
  const structuredSummary = result.structuredContent?.attendanceSummary as Record<string, unknown>;
  assert.equal(structuredSummary?.overview !== undefined, true);
  assert.equal(structuredSummary?.children, undefined);
  assert.equal(result.structuredContent?.availableViews, undefined);
  assert.equal(result.structuredContent?.viewControls, undefined);
  assert.equal(result.structuredContent?.actionIntents, undefined);
  assert.equal(result.structuredContent?.affectedChildNames, undefined);
  // This test now deliberately scopes the request by childNames (the
  // drill-down shape itself), so childNames legitimately appears in the
  // echoed scope - the no-childNames-leakage assertion moved to a test that
  // actually exercises the unscoped county-summary-first path.
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
    assert.match(text, /1 child\(ren\) over the absence limit\./);
  assert.match(text, /1 child\(ren\) have incomplete attendance records \(one of check-in\/check-out missing\)\./);
  assert.match(text, /Review absence-limit risk — 1 children/);
  assert.match(text, /Review incomplete attendance — 1 records/);
  // "This is not a payment-total table." was removed entirely from every
  // attendance county table per explicit follow-up request - it no longer
  // renders anywhere in this file.
  assert.doesNotMatch(text, /This is not a payment-total table/);
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
  assert.match(countyPolicyResult.content[0].text, /Review absence-limit risk — 1 children/);
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
  assert.equal(result.structuredContent?.providerMessage, result.content[0].text);
  assert.deepEqual(result.structuredContent?.scope, { dateFilter: "LAST_MONTH" });
  assert.equal(JSON.stringify(result.structuredContent).includes("childNames"), false);
  assert.equal(Array.isArray(result.structuredContent?.actionControls), true);
});

test("attendance continuation filters cached child details to the requested names", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH", childNames: ["Target Child"] },
    riskFocus: "ABSENCE_LIMITS",
    attendanceRisk: {
      risk_child_count: 2,
      children: [
        {
          child_name: "Target Child",
          county: "Denver",
          absence_days: 5,
          absence_limit: 4,
          absence_dates: ["2026-09-01"],
          authorization_names: ["AUTH-1"],
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
        {
          child_name: "Other Child",
          county: "Denver",
          absence_days: 5,
          absence_limit: 4,
          absence_dates: ["2026-09-01"],
          authorization_names: ["AUTH-2"],
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /Target Child/);
  assert.doesNotMatch(text, /Other Child/);
  assert.equal(result.structuredContent?.providerMessage, text);
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
  assert.equal(result.structuredContent?.providerMessage, text);
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
  assert.match(text, /over the absence limit/);
  assert.match(text, /5d total/);
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

test("accepts service-period-scoped payment history rows without authorization IDs", () => {
  assert.deepEqual(
    normalizeExistingSubPayments({
      subPayments: [
        { idn_period_serv__c: "892", cde_status_pmt_sub__c: "4" },
        { idn_period_serv__c: "892", cde_status_pmt_sub__c: "4" },
        { idn_period_serv__c: "893", cde_status_pmt_sub__c: "4" },
      ],
    }),
    [
      { service_period_id: "892", status: "PAID" },
      { service_period_id: "892", status: "PAID" },
      { service_period_id: "893", status: "PAID" },
    ],
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
      attendance_basis: "SCHEDULED",
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
      attendance_basis: "SCHEDULED",
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
    asOfDate: "2026-09-07",
  });

  assert.equal(payload.rule_version, "provider-risk-payment-v3");
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

test("payment results use a provider-facing table and preserve blocked states", () => {
  const result = formatPayoutResult({
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

  assert.match(result.content[0].text, /Upcoming payout summary: Blocked/);
  assert.match(result.content[0].text, /⚠️ \*Figures reflect the system's current data and are not an official payment notice\. Actual payments are subject to state and county verification, review, and may differ from these calculated estimates\.\*$/);
  assert.match(result.content[0].text, /\| Service period \| 7th Sep'26-13th Sep'26 \|/);
  assert.match(result.content[0].text, /24th Sep'26/);
  assert.match(result.content[0].text, /fiscal_rates, parent_confirmations/);
  assert.doesNotMatch(result.content[0].text, /amount \|/);
  assert.equal(result.structuredContent?.providerMessage, result.content[0].text);
  assert.deepEqual(result.structuredContent?.scope, { dateFilter: "THIS_MONTH" });
  assert.deepEqual(result.structuredContent?.paymentDisclaimers, [
    "⚠️ *Figures reflect the system's current data and are not an official payment notice. Actual payments are subject to state and county verification, review, and may differ from these calculated estimates.*",
  ]);
  assert.equal((result.structuredContent?.viewState as Record<string, unknown>)?.tableId, "payout-summary");
});

test("current week forecast renders actual and scheduled attendance basis split", () => {
  const result = formatPayoutResult({
    paymentView: "CURRENT_WEEK_FORECAST",
    status: "ok",
    payment: {
      status: "CONDITIONAL",
      amount: "293.50",
      summary_view: {
        categories: [
          { label: "Scheduled forecast", conditional_amount: "1206.00" },
        ],
      },
    },
    detailPagination: { page: 1, pageSize: 25, totalRows: 2, hasMore: false },
    attendance: {
      actual_hours_total: "5.00",
      scheduled_hours_total: "5.00",
      days: [
        { child_name: "Actual Child", service_date: "2026-09-09", classification: "ATTENDED", attendance_basis: "ACTUAL", unit_hours: "5.00", conditional: false },
        { child_name: "Scheduled Child", service_date: "2026-09-10", classification: "SCHEDULED_FORECAST", attendance_basis: "SCHEDULED", unit_hours: "5.00", conditional: true },
      ],
    },
  });
  const text = result.content[0].text;
  assert.match(text, /\| Net payment \| ~ \$293\.50 \|/);
  assert.match(text, /\| Conditional at-risk \| \$1206\.00 \|/);
  assert.match(text, /Actual \(checked in\): 5\.00 hours\. Scheduled \(projected\): 5\.00 hours\./);
  assert.match(text, /Attendance type \| Basis \| Scheduled hours/);
  assert.match(text, /Actual Child .*Actual \(checked in\)/);
  assert.match(text, /Scheduled Child .*Scheduled \(projected\)/);
  assert.equal(result.structuredContent?.providerMessage, text);
});

test("current week forecast structured summary uses canonical county composition", () => {
  const result = formatPayoutResult({
    paymentView: "CURRENT_WEEK_FORECAST",
    payment: {
      status: "CONDITIONAL",
      summary: [{ county_name: "Adams", children_served: 15, amount: 7342.8 }],
      summary_view: {
        overview: { children_served: 7 },
        county_composition: [{
          county: "Adams",
          children_served: 6,
          care: { amount: "7342.80" },
          amount_at_risk: "324.00",
          potential_total: "7775.30",
        }],
      },
    },
  });

  assert.deepEqual(result.structuredContent?.summary, [{
    county: "Adams",
    childrenServed: 6,
    hours: 0,
    amount: 7342.8,
    conditionalAmount: 324,
  }]);
});

test("payment results show scheduled forecast rows for child drill-down", () => {
  const result = formatPayoutResult({
    paymentView: "CURRENT_WEEK_FORECAST",
    calculation_mode: "CURRENT_WEEK_FORECAST",
    status: "ok",
    rule_version: "provider-risk-payment-v1",
    scope: { dateFilter: "DATE_RANGE", dateFrom: "2026-09-07", dateTo: "2026-09-13" },
    servicePeriod: { servicePeriodId: "SP-2026-09-07" },
    payment: { status: "CONDITIONAL", amount: "90.00", amount_at_risk: "45.00" },
    detailPagination: { page: 1, pageSize: 25, totalRows: 1, hasMore: false },
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
  assert.match(result.content[0].text, /⚠️ \*Figures reflect the system's current data and are not an official payment notice\. Actual payments are subject to state and county verification, review, and may differ from these calculated estimates\.\*$/);
  assert.match(result.content[0].text, /Taylor Example \| Unavailable from the current source \| Unavailable from the current source \| 9th Sep'26/);
  assert.match(result.content[0].text, /9th Sep'26 \| Scheduled \(forecast\) \| 5\.00/);
  assert.match(result.content[0].text, /\| Scheduled forecast \|/);
  assert.equal(result.structuredContent?.calculationMode, "CURRENT_WEEK_FORECAST");
});

test("payment results keep initial summary to the measure table, categories, and composition", () => {
  const result = formatPayoutResult({
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
  assert.match(text, /Payment by category:/);
  assert.doesNotMatch(text, /County detail:/);
  assert.doesNotMatch(text, /County payment totals:/);
  assert.doesNotMatch(text, /Detail preview/);
  assert.doesNotMatch(text, /\| Child \| County \| Service date \| Attendance type \|/);
  assert.match(text, /Upcoming payout summary: Conditional/);
  assert.deepEqual(result.structuredContent?.actionIntents, [
    {
      actionId: "open-payment-detail",
      capability: "payment-analysis",
      tool: "cccap_analyze_payment",
      label: "Open highest-impact child payment detail",
      reason: "Inspect the child and service-date rows behind this summary.",
      priority: "high",
      section: "drill-down",
      source: "current-result",
      input: { view: "NEXT_PAYOUT" },
    },
  ]);
});

test("payment detail reports its bounded page window", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    detailPagination: { page: 2, pageSize: 1, totalRows: 2, hasMore: false },
    attendance: { days: [
      {
        child_name: "Taylor Example",
        county_id: "denver",
        service_date: "2026-09-09",
        forecast_basis: "ACTUAL",
        classification: "ATTENDED",
        unit_hours: "5.00",
        conditional: false,
      },
      {
        child_name: "Taylor Example",
        county_id: "denver",
        service_date: "2026-09-10",
        forecast_basis: "ACTUAL",
        classification: "ATTENDED",
        unit_hours: "5.00",
        conditional: false,
      },
    ] },
  });

  assert.match(result.content[0].text, /Fetched rows 2-2 of 2 for this page \(page 2; page size 1\) - showing the top 2 by risk below\./);
  assert.deepEqual(result.structuredContent?.detailPagination, { page: 2, pageSize: 1, totalRows: 2, hasMore: false });
});

test("payment detail omits zero-value NO_CARE rows", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    detailPagination: { page: 1, pageSize: 25, totalRows: 2, hasMore: false },
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
  assert.match(text, /10th Sep'26 \| Absence \(paid\) \| 5/);
});

test("a named child-list with no riskFocus shows a complete, unpaginated view of just those children", () => {
  // Spec: "Ensure the child-level drill-down provides a complete view of the
  // selected children" - a request already scoped to exactly these 11
  // children by name is not a facility-wide drill-down that needs capping;
  // every one of the explicitly named children renders.
  const childNames = Array.from({ length: 11 }, (_, index) => `Child ${index + 1}`);
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH", childNames },
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
  assert.match(text, /Pending parent confirmation detail:/);
  assert.match(text, /\| Child 1 \|/);
  assert.match(text, /\| Child 8 \|/);
  assert.match(text, /\| Child 11 \|/);
  assert.doesNotMatch(text, /Showing the first/);
});

test("attendance detail caps the provider-facing table and reports the remainder for a riskFocus-scoped county narrowing", () => {
  // The real capping/pagination behavior this test name describes still
  // applies to a riskFocus-scoped, non-child-list request (here, a county
  // narrowing under PARENT_CONFIRMATIONS reaches the generic isNarrowedToDetail
  // child table, capped to 7, since it isn't the child-scoped-multi-risk path).
  const countyNames = ["Denver"];
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "PARENT_CONFIRMATIONS",
    countyNames,
    attendanceRisk: {
      pending_confirmation_days: 11,
      risk_child_count: 11,
      children: Array.from({ length: 11 }, (_, index) => ({
        child_name: `Child ${index + 1}`,
        county: "Denver",
        pending_confirmation_days: 1,
        absence_days: 0,
        risk_codes: ["PARENT_CONFIRMATION_PENDING"],
      })),
    },
  });

  const text = result.content[0].text;
  // PARENT_CONFIRMATIONS is exclusive-by-design (see D in the redesign plan):
  // an unscoped-by-child request always renders the county-first, top-4-
  // children shape rather than the generic capped table.
  assert.match(text, /Top children by pending confirmations:/);
  assert.match(text, /Showing the top 4 of 11 affected children by pending confirmations/);
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

test("payment summary keeps period metadata and defers child detail until requested", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "45.00" },
    servicePeriod: { id: "period-1", start_date: "2026-09-07", end_date: "2026-09-13" },
    detailPagination: { page: 0, pageSize: 0, totalRows: 182, hasMore: true },
    attendance: { days: [{ child_name: "Taylor Example", service_date: "2026-09-09", classification: "ATTENDED", unit_hours: "5.00", conditional: false }] },
  });

  const text = result.content[0].text;
  assert.match(text, /Upcoming payout summary: Expected/);
  assert.match(text, /\| Service period \| 7th Sep'26-13th Sep'26 \|/);
  assert.doesNotMatch(text, /Detail preview/);
  assert.doesNotMatch(text, /\| Child \| County \| Service date \| Attendance type \|/);
  assert.doesNotMatch(text, /Detail by child and service date:/);
});

test("payment continuation metadata mirrors the provider message in structured content", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "0.00",
      potential_total: "558.00",
      vacant_slot_fee: "18.00",
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
  assert.match(result.content[0].text, /Upcoming payout summary: Conditional/);
  assert.equal((result.structuredContent?.summaryView as Record<string, unknown>)?.children, undefined);
});

test("payment detail never exposes Salesforce record identifiers", () => {
  const result = formatPayoutResult({
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
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    highestImpactChildName: "Taylor Example",
    payment: { status: "CONDITIONAL", amount: "90.00" },
    attendance: { days: [
      { child_name: "Taylor Example", service_date: "2026-09-01", classification: "ATTENDED", unit_hours: "5.00", conditional: false },
      { child_name: "Taylor Example", service_date: "2026-09-02", classification: "ATTENDED", unit_hours: "5.00", conditional: false },
    ] },
  });

  // Item 4: a cross-capability "open-attendance-risk-for-child" action now
  // rides alongside the payment child-detail action, so a provider can jump
  // to the same child's 3-table attendance-risk breakdown, not just their
  // payment amounts.
  assert.deepEqual(result.structuredContent?.actionIntents, [{
    actionId: "open-payment-detail",
    capability: "payment-analysis",
    tool: "cccap_analyze_payment",
    label: "Open highest-impact child payment detail",
    reason: "Inspect the child and service-date rows behind this summary.",
    priority: "high",
    section: "drill-down",
    source: "current-result",
    input: { view: "NEXT_PAYOUT", childNames: ["Taylor Example"] },
  }, {
    actionId: "open-attendance-risk-for-child",
    capability: "attendance-risk-analysis",
    tool: "cccap_analyze_payment_risk",
    label: "Open attendance-risk detail for this child",
    reason: "See every risk area (absence, pending confirmations, incomplete attendance) for this child, not just the payment figures.",
    priority: "medium",
    section: "drill-down",
    source: "current-result",
    input: { childNames: ["Taylor Example"], dateFilter: "THIS_MONTH" },
  }]);
});

test("payment drill-down ranks the maximum amount at risk across all children", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    highestImpactChildName: "High at risk",
    highestImpactRankedByDollars: true,
    payment: { status: "EXPECTED", amount: "100.00" },
    child_payment_impacts: [
      { child_name: "High total", amount_at_risk: "5.00", total_amount: "500.00" },
      { child_name: "High at risk", amount_at_risk: "75.00", total_amount: "100.00" },
      { child_name: "No exposure", amount_at_risk: "0.00", total_amount: "0.00" },
    ],
    attendance: { days: [{ child_name: "High at risk", service_date: "2026-09-01", unit_hours: "5.00" }] },
    detailPagination: { page: 0, pageSize: 0, totalRows: 1, hasMore: true },
  });

  const action = (result.structuredContent?.actionIntents as Record<string, unknown>[])
    .find((candidate) => candidate.label === "Open highest-impact child payment detail");
  assert.deepEqual((action?.input as Record<string, unknown>)?.childNames, ["High at risk"]);
});

test("payment drill-down ranks maximum total amount when amount at risk is zero", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    highestImpactChildName: "High total",
    highestImpactRankedByDollars: true,
    payment: { status: "EXPECTED", amount: "100.00" },
    child_payment_impacts: [
      { child_name: "High total", amount_at_risk: "0.00", total_amount: "250.00" },
      { child_name: "Lower total", amount_at_risk: "0.00", total_amount: "50.00" },
    ],
    attendance: { days: [{ child_name: "High total", service_date: "2026-09-01", unit_hours: "5.00" }] },
    detailPagination: { page: 0, pageSize: 0, totalRows: 1, hasMore: true },
  });

  const action = (result.structuredContent?.actionIntents as Record<string, unknown>[])
    .find((candidate) => candidate.label === "Open highest-impact child payment detail");
  assert.deepEqual((action?.input as Record<string, unknown>)?.childNames, ["High total"]);
  // total_amount is a genuine dollar figure (tier 2 of the 3-tier ranking), so
  // this is still a real dollar-ranked result — the hours-fallback caveat is
  // reserved for highestImpactRankedByDollars === false (tier 3) only, per
  // payment-formatter.ts. Asserting the caveat's ABSENCE here is the correct
  // regression check: it must never render for a genuine dollar ranking.
  assert.doesNotMatch(
    result.content[0].text,
    /A verified dollar amount at risk isn't available for this scope yet/,
  );
});

test("payment drill-down uses the scheduled-hours fallback action without a dollar label", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    highestImpactChildName: "Most hours",
    highestImpactRankedByDollars: false,
    payment: { status: "EXPECTED", amount: "0.00" },
    child_payment_impacts: [
      { child_name: "Most hours", amount_at_risk: "0.00", total_amount: "0.00" },
      { child_name: "Less hours", amount_at_risk: "0.00", total_amount: "0.00" },
    ],
    attendance: { days: [{ child_name: "Most hours", service_date: "2026-09-01", unit_hours: "8.00" }] },
    detailPagination: { page: 0, pageSize: 0, totalRows: 1, hasMore: true },
  });

  const action = (result.structuredContent?.actionIntents as Record<string, unknown>[])[0];
  assert.equal(action.actionId, "open-highest-hours-child-detail");
  assert.notEqual(action.label, "Open highest-impact child payment detail");
  assert.match(result.content[0].text, /A verified dollar amount at risk isn't available for this scope yet, so the drill-down below shows the child with the most scheduled hours instead of the highest dollar impact\./);
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
  // County-summary-first: scope to the named child (the drill-down shape)
  // so the day-level detail table renders instead of the county-only view.
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH", childNames: ["Incomplete Example"] },
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
  // Column-hygiene fix: this fixture has no Pending/Outside window/Over
  // limit/Est. risk value on any displayed row, so all four are dropped.
  assert.match(text, /\| Child \| Authorization \| County \|/);
  assert.doesNotMatch(text, /Pending Example/);
});

test("payment summary does not inline child rollup rows before detail is requested", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "CONDITIONAL", amount: "0.00" },
    summary_view: {
      overview: { amount_at_risk: "100.00", excluded_days: 1 },
      children: [{ label: "Taylor Example", days: 7, hours: "40.00", amount: "0.00" }],
    },
    detailPagination: { page: 0, pageSize: 0, totalRows: 7, hasMore: true },
  });

  const text = result.content[0].text;
  // The old "Detail available: N rows" text-only fallback was removed as
  // dead code - attendance.days is never actually empty with a nonzero
  // totalRows on the real runtime path (the orchestration always
  // populates a small preview). With no attendance.days here at all
  // (this fixture provides none), neither the preview nor the full
  // detail table renders - only confirming the child rollup stays hidden.
  assert.doesNotMatch(text, /Taylor Example/);
  assert.doesNotMatch(text, /Detail by child and service date:/);
});

test("initial payment summary renders county composition columns", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "0.00",
      potential_total: "558.00",
      vacant_slot_fee: "18.00",
      summary_view: {
        county_composition: [{
          county: "Denver",
          care: { hours: "40.00", amount: "360.00" },
          absence: { days: 8, hours: "8.00", amount: "72.00" },
          drop_in: { hours: "4.00", amount: "36.00" },
          vacant_slots: { days: 2, amount: "18.00" },
          paid_holidays: { days: 1, hours: "8.00", amount: "72.00" },
          potential_total: "558.00",
        }],
      },
    },
    detailPagination: { page: 0, pageSize: 0, totalRows: 0, hasMore: false },
  });

  const text = result.content[0].text;
  assert.match(text, /County payment composition/);
  assert.match(text, /County \| Children served \| Enrollment absence \| Paid absence \| Paid holidays \| Drop-ins \| Regular care \| Vacant slots \| Conditional at-risk \| Maximum estimated payout/);
  assert.match(text, /\| Denver \| Unavailable from the current source \| \$0\.00 \| \$72\.00 \| \$72\.00 \| \$36\.00 \| \$360\.00 \| \$18\.00 \| \$0\.00 \| \$558\.00 \|/);
  assert.match(text, /\| Total \|/);
});

test("category tables omit payment measures that are absent from the requested scope", () => {
  const result = formatPayoutResult({
    paymentView: "CUSTOM_RANGE",
    payment: {
      status: "CONDITIONAL",
      amount: "90.00",
      summary_view: {
        categories: [
          { label: "Not paid", days: 2, amount: "0.00" },
          { label: "Care", days: 5, amount: "90.00" },
        ],
      },
    },
  });

  const text = result.content[0].text;
  assert.match(text, /\| Category \| Children served \| Days \| Care hours \| Net payment \| Scheduled forecast \| Conditional at-risk \| Unavailable days \(reason\) \| Maximum estimated payout \|/);
  assert.doesNotMatch(text, /Not paid/);
  assert.match(text, /\| Total \|/);
});

test("payout summaries always name the core payment categories", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: { status: "EXPECTED", amount: "90.00", forecasted_amount: "90.00", vacant_slot_fee: "18.00" },
    detailPagination: { page: 0, pageSize: 0, totalRows: 0, hasMore: false },
  });

  const text = result.content[0].text;
  assert.match(text, /Payment by category:/);
  assert.match(text, /Scheduled forecast/);
  assert.match(text, /Net payment/);
  assert.match(text, /Vacant slots/);
});

test("at-risk amount falls back to conditional attendance amounts", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "0.00",
      summary_view: { overview: { paid_days: 0, review_items: 1 } },
    },
    attendance: { days: [{
      child_name: "Pending Example",
      conditional: true,
      conditional_amount: "45.00",
      flags: ["PARENT_CONFIRMATION_PENDING"],
    }] },
  });

  assert.match(result.content[0].text, /\| Conditional at-risk \| \$45\.00 \|/);
  assert.doesNotMatch(result.content[0].text, /^Estimated total \(including-at-risk\):/m);
});

test("county composition omits component columns with no verified values", () => {
  const result = formatPayoutResult({
    paymentView: "NEXT_PAYOUT",
    payment: {
      status: "CONDITIONAL",
      amount: "90.00",
      summary_view: {
        county_composition: [{
          county: "Denver",
          care: { hours: "10.00", amount: "90.00" },
          potential_total: "90.00",
        }],
      },
    },
  });

  const text = result.content[0].text;
  assert.match(text, /\| County \| Children served \| Enrollment absence \| Paid absence \| Paid holidays \| Drop-ins \| Regular care \| Vacant slots \| Conditional at-risk \| Maximum estimated payout \|/);
  assert.match(text, /\| Denver \| Unavailable from the current source \| \$0\.00 \| \$0\.00 \| \$0\.00 \| \$0\.00 \| \$90\.00 \| \$0\.00 \| \$0\.00 \| \$90\.00 \|/);
  assert.match(text, /\| Total \|/);
});

test("service period ledger formatter translates statuses and renders each payout row", () => {
  const result = formatPayoutResult({ sourceRetrievedAt: "2026-09-01T00:00:00Z", periods: [
    { servicePeriodId: "a0B000000000001AAA", serviceBeginDate: "2026-08-24", serviceEndDate: "2026-08-30", payoutDate: "2026-09-10", periodStatus: "EXPECTED_AWAITING_PAYOUT", netAmount: "125.50", grossAmount: "140.00", guaranteedAmount: "10.00", amountAtRisk: "4.50" },
    { servicePeriodId: "a0B000000000002AAA", serviceBeginDate: "2026-08-17", serviceEndDate: "2026-08-23", payoutDate: "2026-09-03", periodStatus: "PAID", netAmount: "90.00", grossAmount: "90.00", guaranteedAmount: "0.00", amountAtRisk: "0.00" },
  ] });
  assert.match(result.content[0].text, /Expected, awaiting payout/);
  assert.match(result.content[0].text, /24th Aug'26-30th Aug'26/);
  assert.match(result.content[0].text, /~ \$125\.50/);
  assert.match(result.content[0].text, /Paid/);
  assert.equal(result.structuredContent?.providerMessage, result.content[0].text);
  const actionControls = result.structuredContent?.actionControls as Array<Record<string, unknown>>;
  const drillDownInput = (actionControls[0]?.input ?? {}) as Record<string, unknown>;
  // Drill-down from a ledger row now routes through CUSTOM_RANGE (FORECAST
  // mode), not STATUS - the ledger's own per-period figure for this exact
  // date range was already computed via CUSTOM_RANGE, and STATUS mode's
  // stricter fail-closed handling could block on a period the ledger already
  // showed a complete breakdown for (see payment-formatter.ts ledgerInput).
  assert.deepEqual(drillDownInput, {
    view: "CUSTOM_RANGE",
    dateFilter: "DATE_RANGE",
    dateFrom: "2026-08-24",
    dateTo: "2026-08-30",
  });
});

test("service period payout formatter renders countdown and verified-data absence", () => {
  const entry = { servicePeriodId: "a0B000000000001AAA", serviceBeginDate: "2026-08-24", serviceEndDate: "2026-08-30", payoutDate: "2026-09-10", periodStatus: "EXPECTED_AWAITING_PAYOUT", netAmount: "125.50", grossAmount: "140.00", guaranteedAmount: "10.00", amountAtRisk: "0.00" } as const;
  const payoutText = formatPayoutResult({ entry, daysUntilPayout: 9, sourceRetrievedAt: "2026-09-01T00:00:00Z" }).content[0].text;
  assert.match(payoutText, /Upcoming payout in 9 days/);
  assert.match(payoutText, /Payment by category:/);
  assert.match(payoutText, /Net payment/);
  assert.match(payoutText, /Payment amounts:/);
  assert.match(formatPayoutResult({ entry: undefined, daysUntilPayout: undefined, sourceRetrievedAt: "2026-09-01T00:00:00Z" }).content[0].text, /No upcoming payout is currently identified from verified data/);
});

test("payout structured data contains compact navigation metadata only", () => {
  const result = formatPayoutResult({
    entry: {
      servicePeriodId: "internal-period-id",
      serviceBeginDate: "2026-08-31",
      serviceEndDate: "2026-09-06",
      payoutDate: "2026-09-18",
      periodStatus: "EXPECTED_AWAITING_PAYOUT",
      calculatedAmount: "7324.20",
      amountAtRisk: "324.00",
      estimatedTotal: "7648.20",
      childrenServed: 7,
      countyComposition: [{
        county: "Adams",
        children_served: 6,
        amount_at_risk: "324.00",
        potential_total: "6233.70",
        absence: { days: 20, amount: "5470.00" },
      }],
      categories: [{ label: "Paid absence", days: 23, amount: "6824.50", conditional_amount: "324.00" }],
    },
    daysUntilPayout: 2,
    sourceRetrievedAt: "2026-09-16T00:00:00Z",
  });
  const structured = result.structuredContent as Record<string, unknown>;
  const periods = structured.periods as Array<Record<string, unknown>>;

  assert.equal(JSON.stringify(structured).includes("internal-period-id"), false);
  assert.equal(structured.summaryView, undefined);
  assert.equal(structured.entry, undefined);
  assert.deepEqual(structured.selectedPeriod, {
    serviceBeginDate: "2026-08-31",
    serviceEndDate: "2026-09-06",
    payoutDate: "2026-09-18",
    periodStatus: "EXPECTED_AWAITING_PAYOUT",
    amountAtRisk: "324.00",
    estimatedTotal: "7648.20",
    childrenServed: 7,
  });
  const structuredWithoutProviderMessage = { ...structured };
  delete structuredWithoutProviderMessage.providerMessage;
  assert.equal(JSON.stringify(structuredWithoutProviderMessage).includes("Paid absence"), false);
  assert.equal(JSON.stringify(structuredWithoutProviderMessage).includes("county_composition"), false);
  assert.equal(periods[0]?.servicePeriodId, undefined);
});

test("payment drill-down preserves service-period identity and reconciles risk totals", () => {
  const text = formatPayoutResult({
    paymentView: "CUSTOM_RANGE",
    payment: {
      status: "CONDITIONAL",
      amount: "7143.30",
      potential_total: "7648.20",
      amount_at_risk: "324.00",
    },
    servicePeriod: {
      servicePeriodId: "892",
      serviceBeginDate: "2026-08-31",
      serviceEndDate: "2026-09-06",
      paymentReleaseDate: "2026-09-18",
    },
    detailPagination: { page: 1, pageSize: 25, totalRows: 0, hasMore: false },
  }).content[0].text;

  assert.match(text, /\| Service period \| 31st Aug'26-6th Sep'26 \|/);
  assert.doesNotMatch(text, /Custom period/);
  assert.match(text, /\| Net payment \| \$7324\.20 \|/);
  assert.match(text, /\| Conditional at-risk \| \$324\.00 \|/);
  assert.match(text, /\| Maximum estimated payout \| ~ \$7648\.20 \|/);
});