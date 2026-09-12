export type ProviderViewId =
  | "COMBINED_SUMMARY"
  | "ATTENDANCE_RISK_SUMMARY"
  | "ATTENDANCE_DATE_DETAIL"
  | "ATTENDANCE_COUNTY_ROLLUP"
  | "NEXT_UPCOMING_PAYOUT"
  | "PAYOUT_LEDGER"
  | "PAYMENT_CATEGORY_ROLLUP"
  | "PAYMENT_COUNTY_ROLLUP"
  | "VACANT_SLOT_ROLLUP"
  | "SUB_PAYMENT_SUMMARY"
  | "SUB_PAYMENT_DETAIL"
  | "CURRENT_SERVICE_PERIOD_FORECAST";

export type ProviderTableId =
  | "attendance-risk"
  | "attendance-date-detail"
  | "attendance-county-rollup"
  | "payout-summary"
  | "payout-ledger"
  | "payment-category-rollup"
  | "payment-county-rollup"
  | "vacant-slot-rollup"
  | "sub-payment-summary"
  | "sub-payment-detail"
  | "forecast-date-detail";

export interface ProviderViewState {
  viewId: ProviderViewId;
  tableId?: ProviderTableId;
  tableTitle?: string;
  tableDescription?: string;
  parentViewId?: ProviderViewId;
  scope?: unknown;
  filters?: Record<string, unknown>;
  sourceRetrievedAt?: string;
  ruleVersion?: string;
  page?: number;
  pageSize?: number;
  totalRows?: number;
}

export function viewState(state: ProviderViewState): ProviderViewState {
  return Object.fromEntries(
    Object.entries(state).filter(([, value]) => value !== undefined),
  ) as ProviderViewState;
}

export function actionViewMetadata(
  action: Record<string, unknown>,
  currentView: ProviderViewState,
): Record<string, unknown> {
  const input = action.input && typeof action.input === "object" && !Array.isArray(action.input)
    ? action.input as Record<string, unknown>
    : undefined;
  return {
    ...action,
    sourceViewId: currentView.viewId,
    ...(input?.viewId ? { targetViewId: input.viewId } : { targetViewId: targetViewForAction(action.actionId) }),
    lockedView: currentView,
  };
}

function targetViewForAction(actionId: unknown): ProviderViewId | undefined {
  if (typeof actionId !== "string") return undefined;
  if (actionId.startsWith("attendance-view-")) {
    const viewId = actionId.slice("attendance-view-".length);
    if (viewId === "ATTENDANCE_DATE_DETAIL" || viewId === "ATTENDANCE_COUNTY_ROLLUP") return viewId;
  }
  if (actionId.includes("absence") || actionId.includes("confirmation") || actionId.includes("incomplete")) {
    return "ATTENDANCE_DATE_DETAIL";
  }
  if (actionId.includes("payment-county")) return "PAYMENT_COUNTY_ROLLUP";
  if (actionId.includes("vacant-slot")) return "VACANT_SLOT_ROLLUP";
  if (actionId.includes("sub-payment")) return "SUB_PAYMENT_SUMMARY";
  if (actionId.includes("county")) return "ATTENDANCE_COUNTY_ROLLUP";
  if (actionId.includes("payout")) return "NEXT_UPCOMING_PAYOUT";
  if (actionId.includes("forecast")) return "CURRENT_SERVICE_PERIOD_FORECAST";
  if (actionId.includes("payment-detail")) return "SUB_PAYMENT_DETAIL";
  if (actionId.includes("payment-summary")) return "PAYMENT_CATEGORY_ROLLUP";
  return undefined;
}