import assert from "node:assert/strict";
import test from "node:test";

import {
  addDefaultCountyToSchedules,
  livePaymentReadiness,
  normalizeScheduleAttendance,
} from "../src/attendance-snapshot.js";
import { formatAttendanceRiskResult } from "../src/server.js";

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
    attendanceRisk: {
      pending_confirmation_days: 2,
      risk_child_count: 1,
      children: [
        {
          child_name: "Taylor Example",
          household_name: "Example Household",
          county: null,
          authorization_dates: ["2026-09-01", "2026-09-02"],
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
  assert.match(text, /\| Child name \| Household name \| County \| Authorization name \| Authorization dates \| Note \| Potential impact \|/);
  assert.match(text, /\| Taylor Example \| Example Household \| Unavailable from the current source \| Unavailable from the current source \| 2026-09-01, 2026-09-02 \|/);
  assert.match(text, /1\. Review and complete the pending parent confirmations/);
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
  ], "county-1");

  assert.equal(normalized.schedules[0].schedule_id, "schedule-1");
  assert.equal(normalized.schedules[0].county_id, "county-1");
  assert.equal(normalized.schedules[0].county_name, "Denver County");
  assert.equal(normalized.schedules[0].auth_status, "APPROVED");
  assert.equal(normalized.schedules[0].actual_start_ts, "2026-08-18T14:00:00.000+0000");
  assert.equal(normalized.schedules[0].actual_end_ts, "2026-08-18T23:00:00.000+0000");
  assert.deepEqual(
    normalized.transactions.map((transaction) => transaction.type).sort(),
    [1, 2],
  );
  assert.equal(normalized.transactions[0].status, "PARENT_APPROVED");
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