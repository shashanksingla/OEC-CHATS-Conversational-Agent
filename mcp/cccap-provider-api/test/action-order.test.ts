import assert from "node:assert/strict";
import test from "node:test";

import { actionControls, orderedActionList, renderActionSections } from "../src/formatters/shared.js";

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