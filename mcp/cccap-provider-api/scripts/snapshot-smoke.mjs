import { fileURLToPath } from "node:url";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

const serverPath = fileURLToPath(new URL("../dist/index.js", import.meta.url));
const client = new Client({ name: "cccap-snapshot-check", version: "1.0.0" });
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [serverPath],
  env: {
    ...process.env,
    SF_TARGET_ORG: "CHATS_SIT",
    CCCAP_PROVIDER_DISPLAY_NAME: "Shashank",
  },
  cwd: fileURLToPath(new URL("../../../CHATS_SIT", import.meta.url)),
  stderr: "pipe",
});

try {
  await client.connect(transport);
  const response = await client.callTool({
    name: "cccap_get_current_month_risk_snapshot",
    arguments: {},
  });
  if (response.isError) {
    throw new Error(String(response.content[0]?.text || "Snapshot tool failed"));
  }
  const snapshot = response.structuredContent ?? {};
  if (snapshot.responseMode !== "SUMMARY") {
    throw new Error("Snapshot is missing its summary response mode");
  }
  if (snapshot.providerMessage !== undefined || snapshot.attendanceSummary !== undefined || snapshot.actionControls !== undefined) {
    throw new Error("Snapshot structured content duplicates provider-facing output");
  }
  const analysisResponse = await client.callTool({
    name: "cccap_analyze_payment_risk",
    arguments: { dateFilter: "THIS_MONTH" },
  });
  if (analysisResponse.isError) {
    throw new Error(String(analysisResponse.content[0]?.text || "Attendance analysis failed"));
  }
  const analysisText = String(analysisResponse.content[0]?.text ?? "");
  if (!analysisText.startsWith("Current-month attendance review")) {
    throw new Error("Attendance analysis response is missing its provider-facing review");
  }
  if (typeof snapshot.providerMessage !== "string" || !snapshot.providerMessage.startsWith("Greetings for the day, Shashank.")) {
    throw new Error("Snapshot provider message is missing or malformed");
  }
  const analysis = analysisResponse.structuredContent ?? {};
  if (!analysis.attendanceSummary || !Array.isArray(analysis.availableViews) || !Array.isArray(analysis.viewControls)) {
    throw new Error("Attendance analysis is missing summary or dynamic view controls");
  }
  if (snapshot.scope?.dateFilter !== "THIS_MONTH" || !snapshot.providerMessage.includes("| Children scheduled |")) {
    throw new Error("Today's snapshot is missing its daily scope or scheduled-child count");
  }
  console.log(
    JSON.stringify({
      providerDisplayName: snapshot.providerDisplayName,
      facilityName: snapshot.facilityName,
      providerMessage: snapshot.providerMessage,
      scope: snapshot.scope,
      contract: {
        attendanceSummary: Boolean(snapshot.attendanceSummary),
        structuredRoutingOnly: snapshot.providerMessage === undefined && snapshot.attendanceSummary === undefined,
        attendanceAnalysisSummary: Boolean(analysis.attendanceSummary),
        attendanceAnalysisViews: Array.isArray(analysis.availableViews),
        attendanceAnalysisViewControls: Array.isArray(analysis.viewControls),
      },
    }),
  );
} finally {
  await client.close();
}