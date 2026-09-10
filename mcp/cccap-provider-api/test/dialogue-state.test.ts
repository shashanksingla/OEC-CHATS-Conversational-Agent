import assert from "node:assert/strict";
import test from "node:test";

import { DialogueStateStore, hasShownGlossary, markGlossaryShown } from "../src/dialogue-state.js";

test("glossary state is tracked per provider", () => {
  const providerKey = `glossary-test-${Date.now()}`;
  assert.equal(hasShownGlossary(providerKey), false);
  markGlossaryShown(providerKey);
  assert.equal(hasShownGlossary(providerKey), true);
});

test("first turn for a provider always reports scope and capability changed", () => {
  const store = new DialogueStateStore();
  const diff = store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:00:00.000Z");
  assert.equal(diff.scopeChanged, true);
  assert.equal(diff.capabilityChanged, true);
  assert.equal(diff.sinceLastTurn, undefined);
});

test("repeating the same capability and scope reports no change and surfaces the prior freshness", () => {
  const store = new DialogueStateStore();
  store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:00:00.000Z");
  const diff = store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:05:00.000Z");
  assert.equal(diff.scopeChanged, false);
  assert.equal(diff.capabilityChanged, false);
  assert.equal(diff.sinceLastTurn, "2026-09-10T00:00:00.000Z");
});

test("a changed scope is reported even when the capability stays the same", () => {
  const store = new DialogueStateStore();
  store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:00:00.000Z");
  const diff = store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "LAST_MONTH" }, "2026-09-10T00:05:00.000Z");
  assert.equal(diff.scopeChanged, true);
  assert.equal(diff.capabilityChanged, false);
});

test("switching capability is reported even when scope stays structurally identical", () => {
  const store = new DialogueStateStore();
  store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:00:00.000Z");
  const diff = store.recordAndDiff("provider-a", "payment-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:05:00.000Z");
  assert.equal(diff.scopeChanged, false);
  assert.equal(diff.capabilityChanged, true);
});

test("state is tracked independently per provider key", () => {
  const store = new DialogueStateStore();
  store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:00:00.000Z");
  const diff = store.recordAndDiff("provider-b", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:05:00.000Z");
  assert.equal(diff.scopeChanged, true);
  assert.equal(diff.capabilityChanged, true);
});

test("expired state is treated as a fresh turn rather than compared against stale data", () => {
  let now = 0;
  const store = new DialogueStateStore({ now: () => now, ttlMs: 10 });
  store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T00:00:00.000Z");
  now = 20;
  const diff = store.recordAndDiff("provider-a", "attendance-risk-analysis", { dateFilter: "THIS_MONTH" }, "2026-09-10T01:00:00.000Z");
  assert.equal(diff.scopeChanged, true);
  assert.equal(diff.sinceLastTurn, undefined);
});

test("bounded entry count evicts the oldest provider state", () => {
  let now = 0;
  const store = new DialogueStateStore({ now: () => now, maxEntries: 2, ttlMs: 1_000_000 });
  store.recordAndDiff("provider-a", "attendance-risk-analysis", {}, "t0");
  now = 1;
  store.recordAndDiff("provider-b", "attendance-risk-analysis", {}, "t1");
  now = 2;
  store.recordAndDiff("provider-c", "attendance-risk-analysis", {}, "t2");
  now = 3;
  // provider-a should have been evicted as the oldest once the third entry was added.
  const diff = store.recordAndDiff("provider-a", "attendance-risk-analysis", {}, "t3");
  assert.equal(diff.scopeChanged, true);
  assert.equal(diff.sinceLastTurn, undefined);
});