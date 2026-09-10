import assert from "node:assert/strict";
import test from "node:test";

import { formatAttendanceRiskResult } from "../src/server.js";

test("county absence-limit table shows limit, remaining allowance, and status", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "ABSENCE_LIMITS",
    attendanceRisk: {
      pending_confirmation_days: 0,
      children: [
        {
          child_name: "Adams Child",
          county: "Adams",
          absence_days: 5,
          absence_limit: 4,
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED"],
        },
        {
          child_name: "Denver Child A",
          county: "Denver",
          absence_days: 3,
          absence_limit: 5,
          risk_codes: ["ABSENCE_LIMIT_APPROACHING"],
        },
        {
          child_name: "Denver Child B",
          county: "Denver",
          absence_days: 2,
          absence_limit: 5,
          risk_codes: ["ABSENCE_LIMIT_APPROACHING"],
        },
      ],
    },
  });

  const text = result.content[0].text;
  assert.match(text, /\| County \| Children \| Absence days \| Applicable limit \| Remaining allowance \| Status \|/);
  assert.match(text, /\| Adams \| 1 \| 5 \| 4 \| -1 \| Over limit \|/);
  assert.match(text, /\| Denver \| 2 \| 5 \| 5 \| 0 \| Approaching limit \|/);
});

test("county absence-limit table reports an unavailable limit without guessing", () => {
  const result = formatAttendanceRiskResult({
    scope: { dateFilter: "THIS_MONTH" },
    riskFocus: "ABSENCE_LIMITS",
    attendanceRisk: {
      pending_confirmation_days: 0,
      children: [
        {
          child_name: "Jefferson Child",
          county: "Jefferson",
          absence_days: 3,
          risk_codes: ["ABSENCE_LIMIT_EXCEEDED", "ABSENCE_LIMIT_UNAVAILABLE"],
        },
      ],
    },
  });

  assert.match(result.content[0].text, /\| Jefferson \| 1 \| 3 \| Unavailable from the current source \| Unavailable from the current source \| Limit unavailable \|/);
});