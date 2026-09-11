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
  // Section 5 redesign: report how many children in the county are over
  // their OWN individual monthly limit, not a county-wide day-sum compared
  // against a single-child limit (which produced nonsensical negative
  // "remaining allowance" figures for every county). The county table also
  // carries a "Monthly absence limit" column, tier-resolved per child and
  // reported when every child in the county actually shares the same value
  // (Adams: 4; Denver: 5, since both Denver children share limit 5 here).
  assert.match(text, /\| County \| Children \| Monthly absence limit \| Children over limit \| Status \|/);
  assert.match(text, /\| Adams \| 1 \| 4 \| 1 \| 1 of 1 children over limit \|/);
  assert.match(text, /\| Denver \| 2 \| 5 \| 0 \| Within limit \|/);
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

  // No child in Jefferson has a resolved absence_limit (unavailable, not
  // conflicting), so the county limit reads "Unavailable" rather than
  // "Multiple" - "Multiple" is reserved for an actual conflicting-values case.
  assert.match(result.content[0].text, /\| Jefferson \| 1 \| Unavailable from the current source \| 1 \| 1 of 1 children over limit \|/);
});