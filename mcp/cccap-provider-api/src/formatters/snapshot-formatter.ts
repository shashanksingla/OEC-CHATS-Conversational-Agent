import { actionControls, compactActionControls, recordValue, renderActionSections, result, tableValue, type ToolResult } from './shared.js';
import { actionMetadata, attendanceSummary } from './attendance-formatter.js';
import { actionViewMetadata, viewState } from '../view-state.js';

export function snapshotResult(data: unknown): ToolResult {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return result(data);
  }
  const snapshot = data as Record<string, unknown>;
  const providerMessage = snapshot.providerMessage;
  if (typeof providerMessage !== "string" || providerMessage.length === 0) {
    return result(data);
  }
  const risk = recordValue(snapshot.attendanceRisk);
  const children = risk && Array.isArray(risk.children)
    ? risk.children
        .map(recordValue)
        .filter((child): child is Record<string, unknown> => Boolean(child))
    : [];
  const currentView = viewState({
    viewId: "ATTENDANCE_RISK_SUMMARY",
    tableId: "attendance-risk",
    tableTitle: "Attendance risk summary",
    tableDescription: "This table gives the provider the current attendance risks before any payment detail is opened.",
    scope: snapshot.scope,
    ...(typeof snapshot.sourceRetrievedAt === "string" ? { sourceRetrievedAt: snapshot.sourceRetrievedAt } : {}),
  });
  const actionIntents = risk
    ? actionMetadata(snapshot.scope, risk, children, true).map((action) => actionViewMetadata(action, currentView))
    : [];
  const attendanceView = risk
    ? attendanceSummary(risk, children, snapshot.scope, [], [], [])
    : undefined;
  const compactAttendanceView = compactAttendanceSummary(attendanceView);
  const overview = compactAttendanceView && recordValue(compactAttendanceView.overview);
  const snapshotSummary = overview
    ? [
      "",
      "Attendance overview:",
      `Scheduled days: ${tableValue(overview.scheduled_days)}; affected children: ${tableValue(overview.affected_children)}; pending confirmations: ${tableValue(overview.pending_confirmation_days)}; absence days: ${tableValue(overview.absence_days)}; incomplete children: ${tableValue(overview.incomplete_children)}.`,
    ].join("\n")
    : "";
  const renderedMessage = renderActionSections(`${providerMessage}${snapshotSummary}`, actionIntents);
  return {
    content: [{ type: "text" as const, text: renderedMessage }],
    structuredContent: {
      capability: "attendance-risk-snapshot",
      viewState: currentView,
      scope: snapshot.scope,
      sourceRetrievedAt: snapshot.sourceRetrievedAt,
      responseMode: "SUMMARY",
      responseSections: ["summary", "next-actions", "drill-down", "available-views"],
      providerMessage: renderedMessage,
      actionControls: actionControls(actionIntents),
    },
  };
}

export function compactAttendanceSummary(
  attendanceView: Record<string, unknown> | undefined,
): Record<string, unknown> | undefined {
  if (!attendanceView) return undefined;
  return {
    overview: attendanceView.overview,
    counties: attendanceView.counties,
  };
}
