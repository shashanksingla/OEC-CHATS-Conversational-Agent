import assert from "node:assert/strict";
import test from "node:test";

import { formatAttendanceRiskResult } from "../src/server.js";

const baseAttendanceRisk = {
  pending_confirmation_days: 5,
  risk_child_count: 2,
  children: [
    {
      child_name: "Adams Child",
      county: "Adams",
      pending_confirmation_days: 3,
      absence_days: 0,
      risk_codes: ["PARENT_CONFIRMATION_PENDING"],
    },
    {
      child_name: "Denver Child",
      county: "Denver",
      pending_confirmation_days: 2,
      absence_days: 0,
      risk_codes: ["PARENT_CONFIRMATION_PENDING"],
    },
  ],
};

test("countyNames narrows the returned child rows to the named counties", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    countyNames: ["Denver"],
    attendanceRisk: baseAttendanceRisk,
  });

  const text = result.content[0].text;
  assert.match(text, /Denver Child/);
  assert.doesNotMatch(text, /Adams Child/);
});

test("countyNames matching is case-insensitive and trims whitespace", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    countyNames: [" denver "],
    attendanceRisk: baseAttendanceRisk,
  });

  assert.match(result.content[0].text, /Denver Child/);
});

test("a county with no affected children is named as unmatched rather than treated as unsupported", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    countyNames: ["Jefferson"],
    attendanceRisk: baseAttendanceRisk,
  });

  assert.match(result.content[0].text, /No affected children were found for the requested county\/counties: Jefferson\./);
});

test("countyNames combines with riskFocus without widening scope", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "PARENT_CONFIRMATIONS",
    countyNames: ["Denver"],
    attendanceRisk: baseAttendanceRisk,
  });

  const text = result.content[0].text;
  assert.match(text, /Denver Child/);
  assert.doesNotMatch(text, /Adams Child/);
});

test("omitting countyNames returns every county unfiltered", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    attendanceRisk: baseAttendanceRisk,
  });

  const text = result.content[0].text;
  assert.match(text, /Denver Child/);
  assert.match(text, /Adams Child/);
});