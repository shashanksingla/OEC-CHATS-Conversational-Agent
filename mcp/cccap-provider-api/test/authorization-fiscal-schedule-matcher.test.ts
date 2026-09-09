import assert from "node:assert/strict";
import test from "node:test";

import { selectFiscalScheduleForAuthorization } from "../src/authorization-fiscal-schedule-matcher.js";

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
      "1",
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new" },
  );
});

test("fails closed when the authorization has no unique schedule match", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      "19",
    ),
    { status: "UNRESOLVED", reason: "NO_MATCH" },
  );
});

test("fails closed when more than one latest schedule matches", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      [...schedules, { ...schedules[1], id: "schedule-duplicate", externalId: "schedule-duplicate-external" }],
      "2026-08-01",
      "1",
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
      "1",
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new" },
  );
});

test("does not use slot-contract rate data for authorization-level matching", () => {
  assert.deepEqual(
    selectFiscalScheduleForAuthorization(
      authorization,
      schedules,
      "2026-08-01",
      "1",
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-new" },
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
      "1",
    ),
    { status: "MATCHED", fiscalScheduleId: "schedule-1" },
  );
});