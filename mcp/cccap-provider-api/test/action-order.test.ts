import assert from "node:assert/strict";
import test from "node:test";

import { actionControls, actionViewMetadata, isNoOpAction, orderedActionList, renderActionSections } from "../src/shared/formatters/shared.js";

test("numbered action text and continuation controls use the same order", () => {
  const actions = [
    { actionId: "pending", label: "Review pending confirmations", section: "next-actions" },
    { actionId: "absence", label: "Review absence-limit risk", section: "next-actions" },
    { actionId: "incomplete", label: "Review incomplete attendance", section: "next-actions" },
    { actionId: "payout", label: "View upcoming payout summary", section: "available-options" },
  ];
  const ordered = orderedActionList(actions);
  const controls = actionControls(actions);
  const rendered = renderActionSections("Summary", actions);

  assert.deepEqual(controls.map((control) => control.actionId), ordered.map((action) => action.actionId));
  assert.match(rendered, /1\. Review pending confirmations/);
  assert.match(rendered, /2\. Review absence-limit risk/);
  assert.match(rendered, /3\. View upcoming payout summary/);
  assert.equal(rendered.includes("Review incomplete attendance"), false);
});

test("an action pointing back at the current view and scope is suppressed as a no-op", () => {
  const currentView = { viewId: "ATTENDANCE_DATE_DETAIL" as const, scope: { childNames: ["Taylor Example"] } };
  const sameScopeAction = actionViewMetadata(
    { actionId: "review-pending-parent-confirmations", label: "Review pending confirmations", section: "next-actions", input: { childNames: ["Taylor Example"] } },
    currentView,
  );
  assert.equal(isNoOpAction(sameScopeAction, currentView), true);
});

test("an action pointing to a different view or a different scope is never suppressed", () => {
  const currentView = { viewId: "ATTENDANCE_DATE_DETAIL" as const, scope: { childNames: ["Taylor Example"] } };
  const differentView = actionViewMetadata(
    { actionId: "review-service-period-payout-ledger", label: "Return to attendance risk summary", section: "return", input: {} },
    currentView,
  );
  assert.equal(isNoOpAction(differentView, currentView), false);

  const differentScope = actionViewMetadata(
    { actionId: "open-attendance-detail", label: "Open a different child's detail", section: "drill-down", input: { childNames: ["Someone Else"] } },
    currentView,
  );
  assert.equal(isNoOpAction(differentScope, currentView), false);
});