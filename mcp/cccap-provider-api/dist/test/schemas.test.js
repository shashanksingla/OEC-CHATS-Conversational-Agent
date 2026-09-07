import assert from "node:assert/strict";
import test from "node:test";
import { dateScopeSchema, servicePeriodSchema } from "../src/schemas.js";
test("DATE_RANGE requires both ordered ISO dates", () => {
    assert.equal(dateScopeSchema.safeParse({ dateFilter: "DATE_RANGE" }).success, false);
    assert.equal(dateScopeSchema.safeParse({
        dateFilter: "DATE_RANGE",
        dateFrom: "2026-10-31",
        dateTo: "2026-10-01",
    }).success, false);
    assert.equal(dateScopeSchema.safeParse({
        dateFilter: "DATE_RANGE",
        dateFrom: "2026-10-01",
        dateTo: "2026-10-31",
    }).success, true);
});
test("LAST_N filters require a positive period count", () => {
    assert.equal(dateScopeSchema.safeParse({ dateFilter: "LAST_N_DAYS" }).success, false);
    assert.equal(dateScopeSchema.safeParse({
        dateFilter: "LAST_N_MONTHS",
        periodCount: 2,
    }).success, true);
});
test("service period requests require one supported selector", () => {
    assert.equal(servicePeriodSchema.safeParse({}).success, false);
    assert.equal(servicePeriodSchema.safeParse({ paymentAfter: "TODAY", limitOne: true })
        .success, true);
});
