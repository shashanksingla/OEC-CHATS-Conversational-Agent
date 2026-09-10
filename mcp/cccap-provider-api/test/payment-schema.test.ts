import assert from "node:assert/strict";
import test from "node:test";

import { assertPaymentEnginePayload, normalizePaymentStatus } from "../src/payment-schema.js";

const validPayload = {
  rule_version: "provider-risk-payment-v1",
  service_period: { id: "SP-1", start_date: "2026-09-01", end_date: "2026-09-07" },
  authorizations: [],
  attendance_days: [],
  county_policies: [],
  fiscal_rates: [],
  existing_sub_payments: [],
};

test("accepts a well-formed payment engine payload", () => {
  assert.doesNotThrow(() => assertPaymentEnginePayload(validPayload));
});

test("fails closed on a non-object payload", () => {
  assert.throws(() => assertPaymentEnginePayload(null), /must be an object/);
  assert.throws(() => assertPaymentEnginePayload([]), /must be an object/);
  assert.throws(() => assertPaymentEnginePayload("payload"), /must be an object/);
});

test("fails closed on the wrong rule version", () => {
  assert.throws(
    () => assertPaymentEnginePayload({ ...validPayload, rule_version: "legacy-v0" }),
    /rule_version must be provider-risk-payment-v1/,
  );
});

test("fails closed when a required array field is missing or malformed", () => {
  for (const field of ["authorizations", "attendance_days", "county_policies", "fiscal_rates", "existing_sub_payments"]) {
    assert.throws(
      () => assertPaymentEnginePayload({ ...validPayload, [field]: "not-an-array" }),
      new RegExp(`${field} must be an array`),
    );
  }
});

test("fails closed when service_period is missing required fields", () => {
  assert.throws(
    () => assertPaymentEnginePayload({ ...validPayload, service_period: { id: "SP-1" } }),
    /service_period must include id, start_date, and end_date/,
  );
  assert.throws(
    () => assertPaymentEnginePayload({ ...validPayload, service_period: "SP-1" }),
    /service_period must include id, start_date, and end_date/,
  );
});

test("normalizes stable sub-payment lifecycle status codes", () => {
  assert.equal(normalizePaymentStatus("1"), "REQUESTED");
  assert.equal(normalizePaymentStatus("4"), "PAID");
  assert.equal(normalizePaymentStatus("PAID"), "PAID");
  assert.equal(normalizePaymentStatus("UNKNOWN"), undefined);
});