import { fileURLToPath } from "node:url";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) {
  throw new Error("SF_TARGET_ORG is required");
}

const serverPath = fileURLToPath(new URL("../dist/index.js", import.meta.url));
const client = new Client({ name: "carepay-provider-conversation-check", version: "1.0.0" });
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
  return String(response.content?.[0]?.text ?? "");
}

async function callTool(name, args) {
  const response = await client.callTool({ name, arguments: args });
  if (response.isError) {
    throw new Error(`${name} returned a provider-data error`);
  }
  return toolText(response);
}

try {
  await client.connect(transport);

  const greeting = await callTool("cccap_get_current_month_risk_snapshot", {});
  if (!greeting.startsWith("Greetings for the day,")) {
    throw new Error("Greeting did not return the provider-ready snapshot");
  }

  const attendanceText = await callTool("cccap_get_attendance_analysis", {
    dateFilter: "THIS_MONTH",
  });
  const attendance = JSON.parse(attendanceText);
  if (
    !attendance ||
    typeof attendance !== "object" ||
    !("rule_version" in attendance) ||
    !Array.isArray(attendance.children) ||
    !Array.isArray(attendance.counties) ||
    !Array.isArray(attendance.data_quality_blockers)
  ) {
    throw new Error("Attendance detail did not return the expected analysis contract");
  }

  const confirmationReview = await callTool("cccap_analyze_payment_risk", {
    dateFilter: "THIS_MONTH",
  });
  if (!confirmationReview.includes("**Next actions**")) {
    throw new Error("Confirmation review did not return provider next actions");
  }

  const nextPayoutText = await callTool("cccap_get_service_periods", {
    paymentAfter: "TODAY",
    limitOne: true,
  });
  const nextPayout = JSON.parse(nextPayoutText);
  if (!nextPayout || typeof nextPayout !== "object") {
    throw new Error("Next payout detail did not return the expected service-period contract");
  }

  console.log(
    JSON.stringify({
      greeting: "ok",
      attendanceDetail: "ok",
      confirmationReview: "ok",
      nextPayout: "ok",
    }),
  );
} finally {
  await client.close();
}
