import assert from "node:assert/strict";
import test from "node:test";

import { ConversationContextStore } from "../src/conversation-context.js";

test("context references are provider-bound, expiring, and action-bound", () => {
  let now = 0;
  const store = new ConversationContextStore({ now: () => now, ttlMs: 10 });
  const { contextRef, actionRefs } = store.create("provider-a", "continuation", [{
    tool: "cccap_analyze_attendance_risk",
    input: { dateFilter: "THIS_MONTH", childNames: ["Taylor Example"] },
  }]);

  assert.deepEqual(store.resolve("provider-a", contextRef, actionRefs[0], "continuation"), {
    tool: "cccap_analyze_attendance_risk",
    input: { dateFilter: "THIS_MONTH", childNames: ["Taylor Example"] },
  });
  assert.equal(store.resolve("provider-b", contextRef, actionRefs[0], "continuation"), undefined);
  now = 11;
  assert.equal(store.resolve("provider-a", contextRef, actionRefs[0], "continuation"), undefined);
});

test("context store evicts least-recently-used entries within its entry cap", () => {
  let now = 0;
  const store = new ConversationContextStore({ now: () => now++, maxEntries: 1 });
  const first = store.create("provider-a", "continuation", [{ tool: "cccap_analyze_payment", input: { view: "NEXT_PAYOUT" } }]);
  const second = store.create("provider-a", "continuation", [{ tool: "cccap_analyze_payment", input: { view: "STATUS" } }]);

  assert.equal(store.resolve("provider-a", first.contextRef, first.actionRefs[0], "continuation"), undefined);
  assert.equal(store.resolve("provider-a", second.contextRef, second.actionRefs[0], "continuation")?.tool, "cccap_analyze_payment");
});

test("context stores the canonical result alongside its continuation plan", () => {
  const result = { attendanceRisk: { scheduled_days: 4 } };
  const store = new ConversationContextStore();
  const { contextRef, actionRefs } = store.create("provider-a", "continuation", [{
    tool: "cccap_analyze_attendance_risk",
    input: { dateFilter: "THIS_MONTH", riskFocus: "PARENT_CONFIRMATIONS" },
  }], result, "cccap_analyze_attendance_risk");

  assert.deepEqual(
    store.resolve("provider-a", contextRef, actionRefs[0], "continuation"),
    {
      tool: "cccap_analyze_attendance_risk",
      input: { dateFilter: "THIS_MONTH", riskFocus: "PARENT_CONFIRMATIONS" },
      result,
      resultTool: "cccap_analyze_attendance_risk",
    },
  );
});

test("provider session retains executable actions across capability drill-downs", () => {
  const store = new ConversationContextStore();
  store.create(
    "provider-a",
    "continuation",
    [{ tool: "cccap_analyze_payment", input: { view: "NEXT_PAYOUT" } }],
    undefined,
    undefined,
    undefined,
    [{
      actionId: "review-next-payout",
      label: "Review the next payout summary",
      tool: "cccap_analyze_payment",
      input: { view: "NEXT_PAYOUT" },
    }],
  );

  const inherited = store.getInheritedActions("provider-a", [{ actionId: "review-incomplete-attendance" }]);
  assert.equal(inherited.length, 1);
  assert.equal(inherited[0]?.actionId, "review-next-payout");
  assert.deepEqual(inherited[0]?.plan, {
    tool: "cccap_analyze_payment",
    input: { view: "NEXT_PAYOUT" },
  });
});

test("continuation compatibility ignores reference transport fields but rejects changed filters", () => {
  const store = new ConversationContextStore();
  const { contextRef, actionRefs } = store.create("provider-a", "continuation", [{
    tool: "cccap_analyze_payment",
    input: { dateFilter: "THIS_MONTH", view: "STATUS" },
  }]);

  assert.ok(store.resolve("provider-a", contextRef, actionRefs[0], "continuation", undefined));
  assert.equal(store.resolve("provider-a", contextRef, actionRefs[0], "continuation", undefined, { dateFilter: "LAST_MONTH", view: "STATUS" }), undefined);
});

test("context byte accounting includes provenance and action metadata", () => {
  let now = 0;
  const store = new ConversationContextStore({ now: () => now++, maxBytes: 400 });
  const first = store.create("provider-a", "continuation", [{
    tool: "cccap_analyze_payment",
    input: { view: "STATUS" },
    provenance: { capability: "attendance-risk-analysis", scope: { dateFilter: "THIS_MONTH" } },
  }], { large: "x".repeat(100) }, undefined, undefined, [{ actionId: "a", label: "A" }]);
  assert.equal(store.resolve("provider-a", first.contextRef, first.actionRefs[0], "continuation"), undefined);
});