import assert from "node:assert/strict";
import test from "node:test";

import { formatAttendanceResult } from "../src/server.js";

test("county absence-limit table shows limit, remaining allowance, and status", () => {
  const result = formatAttendanceResult({
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
  // Verify county rollups use each child's limit and expose reconciliable absence-risk measures.
  assert.match(text, /\| County \| Children \| Absence days \| Monthly absence limit \| Children over limit \| Children approaching limit \| Status \|/);
  // Item G (chat_09_17_3 review): Status cells are now short labels ("Over limit (N/M)"), not
  // full sentences - the legend above the table defines what the label means.
  assert.match(text, /\| Adams \| 1 \| 5 \| 4 \| 1 \| 0 \| Over limit \(1\/1\) \|/);
  // Verify approaching risk is reflected in the county status rather than reported as within limit.
  assert.match(text, /\| Denver \| 2 \| 5 \| 5 \| 0 \| 2 \| Approaching limit \(2\/2\) \|/);
});

test("county absence-limit table reports an unavailable limit without guessing", () => {
  const result = formatAttendanceResult({
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

  // Verify an unresolved limit is shown as unavailable, while zero-valued optional columns remain omitted.
  assert.match(result.content[0].text, /\| Jefferson \| 1 \| 3 \| Unavailable from the current source \| 1 \| Over limit \(1\/1\) \|/);
});