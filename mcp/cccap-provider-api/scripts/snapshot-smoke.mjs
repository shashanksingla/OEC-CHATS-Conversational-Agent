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
  const snapshot = JSON.parse(String(response.content[0]?.text));
  const analysisResponse = await client.callTool({
    name: "cccap_analyze_attendance_risk",
    arguments: { dateFilter: "THIS_MONTH" },
  });
  if (analysisResponse.isError) {
    throw new Error(String(analysisResponse.content[0]?.text || "Attendance analysis failed"));
  }
  const analysis = JSON.parse(String(analysisResponse.content[0]?.text));
  if (!analysis.attendanceRisk || analysis.scope?.dateFilter !== "THIS_MONTH") {
    throw new Error("Attendance analysis response is missing scope or risk data");
  }
  const risk = snapshot.attendanceRisk;
  if (typeof snapshot.providerMessage !== "string" || !snapshot.providerMessage.startsWith("Greetings for the day, Shashank.")) {
    throw new Error("Snapshot provider message is missing or malformed");
  }
  console.log(
    JSON.stringify({
      providerDisplayName: snapshot.providerDisplayName,
      facilityName: snapshot.facilityName,
      providerMessage: snapshot.providerMessage,
      today: risk.today,
      scheduledDays: risk.scheduled_days,
      probableAbsenceDays: risk.probable_absence_days,
      pendingConfirmationDays: risk.pending_confirmation_days,
      incompleteAttendanceDays: risk.incomplete_attendance_days,
      absenceRiskChildren: risk.absence_risk_children,
      attendanceConcernChildren: risk.attendance_concern_children,
      riskChildCount: risk.risk_child_count,
    }),
  );
} finally {
  await client.close();
}