import assert from "node:assert/strict";
import test from "node:test";

import { formatCasesResult, formatAuthorizationsResult } from "../src/server.js";

const salesforceId = "a1m2M00000427SJQAY";

test("case formatter never renders a raw Salesforce case or child record ID", () => {
  const result = formatCasesResult({
    cases: [{
      id: salesforceId,
      name: null,
      external_id: "CASE-2026-001",
      children: [{
        id: "a1c000000000001AAA",
        name: null,
        client_id: "958591",
        effective_start: "2026-01-01",
        effective_end: "2026-12-31",
      }],
    }],
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /a1m2M00000427SJQAY|a1c000000000001AAA/);
  assert.match(text, /CASE-2026-001/);
  assert.match(text, /Unavailable from the current source/);
});

test("case formatter prefers a human-readable name over external_id when both are safe", () => {
  const result = formatCasesResult({
    cases: [{
      id: salesforceId,
      name: "Example Case",
      external_id: "CASE-2026-001",
      children: [{ id: "child-1", name: "Taylor Example", effective_start: "2026-01-01", effective_end: "2026-12-31" }],
    }],
  });

  const text = result.content[0].text;
  assert.match(text, /Example Case/);
  assert.match(text, /Taylor Example/);
  assert.doesNotMatch(text, /a1m2M00000427SJQAY/);
});

test("case formatter reports no verified cases without inventing a table", () => {
  const result = formatCasesResult({ cases: [] });
  assert.match(result.content[0].text, /No verified cases were returned/);
});

test("authorization formatter never renders a raw Salesforce authorization or case ID", () => {
  const result = formatAuthorizationsResult({
    authorizations: [{
      id: salesforceId,
      external_id: "950241",
      name: null,
      case_id: "a1m41000002U8OJAA0",
      status: "APPROVED",
      effective_start: "2026-01-01",
      effective_end: "2026-12-31",
    }],
  });

  const text = result.content[0].text;
  assert.doesNotMatch(text, /a1m2M00000427SJQAY|a1m41000002U8OJAA0/);
  assert.match(text, /950241/);
  assert.match(text, /APPROVED/);
});

test("authorization formatter reports no verified authorizations without inventing a table", () => {
  const result = formatAuthorizationsResult({ authorizations: [] });
  assert.match(result.content[0].text, /No verified authorizations were returned/);
});