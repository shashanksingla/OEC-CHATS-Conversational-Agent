import assert from "node:assert/strict";
import test from "node:test";

import { attendanceAnalysisSchema, paymentAnalysisSchema } from "../src/schemas.js";

test("composite schemas reject partial continuation references", () => {
  assert.equal(attendanceAnalysisSchema.safeParse({ dateFilter: "THIS_MONTH", contextRef: "ctx" }).success, false);
  assert.equal(paymentAnalysisSchema.safeParse({ view: "STATUS", actionRef: "action" }).success, false);
});

import {
  attendanceDataSchema,
  dateScopeSchema,
  paymentHistorySchema,
  servicePeriodSchema,
} from "../src/schemas.js";

test("DATE_RANGE requires both ordered ISO dates", () => {
  assert.equal(
    dateScopeSchema.safeParse({ dateFilter: "DATE_RANGE" }).success,
    false,
  );
  assert.equal(
    dateScopeSchema.safeParse({
      dateFilter: "DATE_RANGE",
      dateFrom: "2026-10-31",
      dateTo: "2026-10-01",
    }).success,
    false,
  );
  assert.equal(
    dateScopeSchema.safeParse({
      dateFilter: "DATE_RANGE",
      dateFrom: "2026-10-01",
      dateTo: "2026-10-31",
    }).success,
    true,
  );
});

test("LAST_N filters require a positive period count", () => {
  assert.equal(
    dateScopeSchema.safeParse({ dateFilter: "LAST_N_DAYS" }).success,
    false,
  );
  assert.equal(
    dateScopeSchema.safeParse({
      dateFilter: "LAST_N_MONTHS",
      periodCount: 2,
    }).success,
    true,
  );
});

test("service period requests require one supported selector", () => {
  assert.equal(servicePeriodSchema.safeParse({}).success, false);
  assert.equal(
    servicePeriodSchema.safeParse({ paymentAfter: "TODAY", limitOne: true })
      .success,
    true,
  );
});

test("attendance data requests require a valid date filter", () => {
  assert.equal(attendanceDataSchema.safeParse({}).success, false);
  assert.equal(
    attendanceDataSchema.safeParse({ dateFilter: "DATE_RANGE" }).success,
    false,
  );
  assert.equal(
    attendanceDataSchema.safeParse({ dateFilter: "THIS_MONTH" }).success,
    true,
  );
});

test("payment-history requests require a service-period date filter", () => {
  assert.equal(paymentHistorySchema.safeParse({}).success, false);
  assert.equal(
    paymentHistorySchema.safeParse({ dateFilter: "LAST_N_MONTHS", periodCount: 2 })
      .success,
    true,
  );
});

test("payment views provide their own date selector", () => {
  assert.equal(
    paymentAnalysisSchema.safeParse({ view: "NEXT_PAYOUT" }).success,
    true,
  );
  assert.equal(
    paymentAnalysisSchema.safeParse({ view: "CURRENT_WEEK_FORECAST" }).success,
    true,
  );
  assert.equal(paymentAnalysisSchema.safeParse({}).success, false);
  assert.equal(
    paymentAnalysisSchema.safeParse({ dateFilter: "THIS_MONTH" }).success,
    true,
  );
});

test("payment detail paging accepts bounded positive values", () => {
  assert.equal(paymentAnalysisSchema.safeParse({ view: "NEXT_PAYOUT", detailPage: 2, detailPageSize: 100 }).success, true);
  assert.equal(paymentAnalysisSchema.safeParse({ view: "NEXT_PAYOUT", detailPageSize: 101 }).success, false);
  assert.equal(paymentAnalysisSchema.safeParse({ view: "NEXT_PAYOUT", detailPage: 0 }).success, false);
});