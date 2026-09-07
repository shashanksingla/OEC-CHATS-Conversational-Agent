import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

const serverPath = fileURLToPath(new URL("../dist/index.js", import.meta.url));
const client = new Client({ name: "cccap-protocol-check", version: "1.0.0" });
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [serverPath],
  env: {
    ...process.env,
    SF_TARGET_ORG: "CHATS_SIT",
    CCCAP_PROVIDER_DISPLAY_NAME: "protocol-check",
  },
  cwd: fileURLToPath(new URL("../../../CHATS_SIT", import.meta.url)),
  stderr: "pipe",
});

const expectedTools = [
  "cccap_analyze_attendance_risk",
  "cccap_analyze_payment",
  "cccap_get_attendance_analysis",
  "cccap_get_attendance_risk_snapshot",
  "cccap_get_authorizations",
  "cccap_get_cases",
  "cccap_get_county_rate_plans",
  "cccap_get_current_month_risk_snapshot",
  "cccap_get_fiscal_rates",
  "cccap_get_holidays",
  "cccap_get_payment_history",
  "cccap_get_schedules",
  "cccap_get_service_periods",
  "cccap_initialize_provider",
];

try {
  await client.connect(transport);
  const { tools } = await client.listTools();
  const actualTools = tools.map((tool) => tool.name).sort();
  assert.deepEqual(actualTools, expectedTools);
  console.log(JSON.stringify({ toolCount: tools.length, tools: actualTools }));
} finally {
  await client.close();
}