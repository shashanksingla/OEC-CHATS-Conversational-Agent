import assert from "node:assert/strict";
import test from "node:test";

import { computePayoutDate } from "../src/payout-date.js";

test("matches the shared payout-date fixtures", () => {
  const fixtures = [
    ["2024-12-28", "2025-01-08"],
    ["2024-02-25", "2024-03-07"],
  ] as const;

  for (const [serviceEndDate, expectedPayoutDate] of fixtures) {
    assert.equal(computePayoutDate(serviceEndDate), expectedPayoutDate);
  }
});

test("a Sunday service-period end always produces a Thursday payout date", () => {
  const sundayDates = [
    "2023-12-24",
    "2023-12-31",
    "2024-02-25",
    "2024-03-03",
    "2024-06-30",
    "2025-01-05",
  ];

  for (const serviceEndDate of sundayDates) {
    const payoutDate = computePayoutDate(serviceEndDate);
    assert.equal(new Date(`${serviceEndDate}T00:00:00Z`).getUTCDay(), 0);
    assert.equal(new Date(`${payoutDate}T00:00:00Z`).getUTCDay(), 4, `${serviceEndDate} -> ${payoutDate}`);
  }
});
