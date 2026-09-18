import assert from "node:assert/strict";
import test from "node:test";

import { ConversationContextStore, additiveRefinementsOnly, cacheKeyFor } from "../src/shared/conversation.js";

// Stored action input is authoritative; only explicit pagination refinements may be merged from caller input.
test("additiveRefinementsOnly keeps only detailPage/detailPageSize, dropping stale echoed filters", () => {
  const input = { riskFocus: "ABSENCE_LIMITS", providerUtterance: "1", childNames: ["Ava"], detailPage: 2, detailPageSize: 10 };
  assert.deepEqual(additiveRefinementsOnly(input), { detailPage: 2, detailPageSize: 10 });
});

test("additiveRefinementsOnly returns an empty object when the caller sends no additive keys", () => {
  assert.deepEqual(additiveRefinementsOnly({ riskFocus: "ABSENCE_LIMITS" }), {});
});

test("cached results are provider-bound and expire", () => {
  let now = 0;
  const store = new ConversationContextStore({ now: () => now, ttlMs: 10 });
  const key = cacheKeyFor("provider-a", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH" });
  store.cacheResult(key, "provider-a", "continuation", { attendanceRisk: { scheduled_days: 4 } }, "cccap_analyze_payment_risk");

  assert.deepEqual(store.getCachedResult(key, "provider-a"), {
    result: { attendanceRisk: { scheduled_days: 4 } },
    resultTool: "cccap_analyze_payment_risk",
  });
  assert.equal(store.getCachedResult(key, "provider-b"), undefined);
  now = 11;
  assert.equal(store.getCachedResult(key, "provider-a"), undefined);
});

test("cache store evicts least-recently-used entries within its entry cap", () => {
  let now = 0;
  const store = new ConversationContextStore({ now: () => now++, maxEntries: 1 });
  const firstKey = cacheKeyFor("provider-a", "cccap_analyze_payment", { view: "NEXT_PAYOUT" });
  const secondKey = cacheKeyFor("provider-a", "cccap_analyze_payment", { view: "STATUS" });
  store.cacheResult(firstKey, "provider-a", "continuation", { payment: { status: "EXPECTED" } }, "cccap_analyze_payment");
  store.cacheResult(secondKey, "provider-a", "continuation", { payment: { status: "CONDITIONAL" } }, "cccap_analyze_payment");

  assert.equal(store.getCachedResult(firstKey, "provider-a"), undefined);
  assert.equal(store.getCachedResult(secondKey, "provider-a")?.resultTool, "cccap_analyze_payment");
});

test("cached result reuse extends the entry's TTL (sliding window)", () => {
  let now = 0;
  const store = new ConversationContextStore({ now: () => now, ttlMs: 10 });
  const key = cacheKeyFor("provider-a", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH" });
  store.cacheResult(key, "provider-a", "continuation", { attendanceRisk: {} }, "cccap_analyze_payment_risk");

  now = 9;
  assert.ok(store.getCachedResult(key, "provider-a"));
  now = 15; // The read at now=9 extends the sliding TTL beyond the original deadline.
  assert.ok(store.getCachedResult(key, "provider-a"));
  now = 30;
  assert.equal(store.getCachedResult(key, "provider-a"), undefined);
});

test("cacheKeyFor only depends on the stable date-scope portion of a request", () => {
  const withNarrowing = cacheKeyFor("provider-a", "cccap_analyze_payment_risk", {
    dateFilter: "THIS_MONTH",
    riskFocus: "ABSENCE_LIMITS",
    childNames: ["Taylor Example"],
  });
  const unscoped = cacheKeyFor("provider-a", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH" });
  assert.equal(withNarrowing, unscoped);

  const differentDate = cacheKeyFor("provider-a", "cccap_analyze_payment_risk", { dateFilter: "LAST_MONTH" });
  assert.notEqual(withNarrowing, differentDate);
});

test("oversized results are simply not cached (never an error)", () => {
  const store = new ConversationContextStore({ maxBytes: 1_000 });
  const key = cacheKeyFor("provider-a", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH" });
  store.cacheResult(
    key,
    "provider-a",
    "continuation",
    { attendanceRisk: { children: [{ child_name: "Example", detail: "x".repeat(10_000) }] } },
    "cccap_analyze_payment_risk",
  );

  assert.equal(store.getCachedResult(key, "provider-a"), undefined);
});