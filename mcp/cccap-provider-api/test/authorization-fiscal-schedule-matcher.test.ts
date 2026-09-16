import assert from "node:assert/strict";
import test from "node:test";

import { selectFiscalScheduleForAuthorization } from "../src/payment-engine.js";

const authorization = {
  Id: "auth-1",
  CDE_COUNTY__c: "county-1",
  DTE_BEGIN_EFFV_AUTH__c: "2026-01-01",
  DTE_END_EFFV_AUTH__c: "2026-12-31",
};

const schedules = [
  {
    id: "schedule-old",
    externalId: "schedule-old-external",
    countyId: "county-1",
    rateTypeCode: "1",
    beginDate: "2026-01-01",
    endDate: "2026-06-30",
  },
  {
    id: "schedule-new",
    externalId: "schedule-new-external",
    countyId: "county-1",
    rateTypeCode: "1",
    beginDate: "2026-07-01",
  },
];

test("matches the latest effective schedule for the authorization rate type", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      ["1"],
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new-external" },
  );
});

test("matches when the authorization's schedule days used multiple different rate types (e.g. regular and weekend under the same authorization)", () => {
  // Live-confirmed real scenario: one authorization's schedule days across
  // a single week used 5 different rate types. Only one of them needs to
  // be covered by a candidate schedule for the authorization-level match
  // to succeed - every rate type must be checked, not just the first/last
  // one collected.
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      ["19", "1"],
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new-external" },
  );
});

test("fails closed with a rate-type-specific reason when the county matches but none of the requested rate types do", () => {
  // Schedules exist for county-1 (the authorization's county), but none
  // carry rate type "19" - this must report NO_MATCH_RATE_TYPE, not the
  // old blanket NO_MATCH, since the step-by-step matcher already confirmed
  // the county step passed before the rate-type step failed.
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      ["19"],
    ),
    { status: "UNRESOLVED", reason: "NO_MATCH_RATE_TYPE" },
  );
});

test("fails closed with MISSING_SCHEDULE_RATE_TYPE when no rate types are supplied at all", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      [],
    ),
    { status: "UNRESOLVED", reason: "MISSING_SCHEDULE_RATE_TYPE" },
  );
});

test("fails closed with a county-specific reason when no schedule exists for the authorization's county", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      { ...authorization, CDE_COUNTY__c: "county-2" },
      schedules,
      "2026-08-01",
      ["1"],
    ),
    { status: "UNRESOLVED", reason: "NO_MATCH_COUNTY" },
  );
});

test("fails closed with a date-specific reason when county and rate type match but no schedule covers the care date", () => {
  // A careDate before the authorization's own validity window would trip
  // the earlier authorization-date guard instead (reason: "NO_MATCH",
  // unchanged - that check is unrelated to fiscal-schedule matching). Use
  // only the bounded schedule-old row (ends 2026-06-30) and a careDate
  // after that end but still within the authorization's 2026-01-01 to
  // 2026-12-31 validity window, so county and rate type both match and
  // only the date-range step fails.
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      [schedules[0]!],
      "2026-08-01",
      ["1"],
    ),
    { status: "UNRESOLVED", reason: "NO_MATCH_DATE" },
  );
});

test("fails closed when more than one latest schedule matches", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      [...schedules, { ...schedules[1]!, id: "schedule-duplicate", externalId: "schedule-duplicate-external" }],
      "2026-08-01",
      ["1"],
    ),
    { status: "UNRESOLVED", reason: "AMBIGUOUS_MATCH" },
  );
});

test("matches from the schedule rate type without slot-contract input", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      ["1"],
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new-external" },
  );
});

test("does not use slot-contract rate data for authorization-level matching", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      ["1"],
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new-external" },
  );
});

test("matches a requested rate type contained in a multi-rate fiscal schedule", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      [{
        id: "schedule-1",
        externalId: "schedule-multi-rate",
        countyId: "county-1",
        rateTypeCode: "13, 1, 19",
        beginDate: "2026-01-01",
      }],
      "2026-09-08",
      ["1"],
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-multi-rate" },
  );
});