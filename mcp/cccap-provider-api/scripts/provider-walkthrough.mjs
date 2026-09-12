import { fileURLToPath } from "node:url";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

// Diagnostic-only script: connects to the live MCP server and prints the
// actual provider-facing text for a spread of scenarios so a human can
// review tone, table relevance, and next-action/drill-down quality
// end-to-end against real org data. Not part of the committed test suite.

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) {
  throw new Error("SF_TARGET_ORG is required");
}

const serverPath = fileURLToPath(new URL("../dist/index.js", import.meta.url));
const client = new Client({ name: "carepay-provider-walkthrough", version: "1.0.0" });
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [serverPath],
  env: {
    ...process.env,
    SF_TARGET_ORG: targetOrg,
    CCCAP_PROVIDER_DISPLAY_NAME: process.env.CCCAP_PROVIDER_DISPLAY_NAME ?? "Provider",
  },
  cwd: fileURLToPath(new URL("../../../CHATS_SIT", import.meta.url)),
  stderr: "pipe",
});

function toolText(response) {
  return String(response.content?.[0]?.text ?? (response.isError ? JSON.stringify(response) : "<no text>"));
}

async function callTool(label, name, args) {
  console.log(`\n${"=".repeat(100)}`);
  console.log(`### ${label}  ->  ${name}(${JSON.stringify(args)})`);
  console.log("=".repeat(100));
  const response = await client.callTool({ name, arguments: args });
  console.log(toolText(response));
  return response;
}

try {
  await client.connect(transport);

  await callTool("1. Greeting", "cccap_get_current_month_risk_snapshot", {});

  await callTool("2. Plain 'upcoming payment' ask", "cccap_analyze_payment", { view: "NEXT_PAYOUT" });

  await callTool("3. 'Last payout' ask", "cccap_analyze_payment", { view: "LAST_PAYOUT" });

  await callTool("4. Explicit range ledger (this month)", "cccap_get_service_period_payout_ledger", { dateFilter: "THIS_MONTH" });

  await callTool("5. Absence-limit risk drill-down", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH", riskFocus: "ABSENCE_LIMITS" });

  await callTool("6. Pending parent confirmations drill-down", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH", riskFocus: "PARENT_CONFIRMATIONS" });

  await callTool("7. Incomplete attendance drill-down", "cccap_analyze_payment_risk", { dateFilter: "THIS_MONTH", riskFocus: "INCOMPLETE_ATTENDANCE" });

  await callTool("8. Current-period forecast (new canonical view name)", "cccap_analyze_payment", { view: "CURRENT_PERIOD_FORECAST" });

  await callTool("9. Payment status (default view)", "cccap_analyze_payment", { dateFilter: "THIS_MONTH" });

  console.log(`\n${"=".repeat(100)}\nWalkthrough complete.\n${"=".repeat(100)}`);
} finally {
  await client.close();
}