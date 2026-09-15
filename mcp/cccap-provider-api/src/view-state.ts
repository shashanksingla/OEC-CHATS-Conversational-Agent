export type ProviderViewId =
  | "COMBINED_SUMMARY"
  | "ATTENDANCE_RISK_SUMMARY"
  | "ATTENDANCE_DATE_DETAIL"
  | "ATTENDANCE_COUNTY_ROLLUP"
  | "NEXT_UPCOMING_PAYOUT"
  | "LAST_PAYOUT"
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
  | "last-payout-summary"
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

// AD-10: structuredContent (and everything derived from it - viewState,
// lockedView on every action, resultGraph.currentView) never carries a raw
// child list. A scope's childNames array was previously embedded in full
// here and then duplicated across every action's lockedView plus
// resultGraph, multiplying an N-name array by (actions + 2) copies in a
// single response - for a 23-child "show affected children" result, that
// is 6+ full copies of the same array, which is exactly the kind of
// oversized structuredContent this rule exists to prevent. The real
// continuation match still uses the FULL childNames array server-side (in
// ConversationContextStore's stored plan.input, never sent to the client);
// only this display-facing copy is compacted to a count.
function compactScopeForDisplay(scope: unknown): unknown {
  if (!scope || typeof scope !== "object" || Array.isArray(scope)) return scope;
  const record = scope as Record<string, unknown>;
  if (!Array.isArray(record.childNames) || record.childNames.length <= 3) return scope;
  const { childNames, ...rest } = record;
  return { ...rest, childNamesCount: childNames.length };
}

export function viewState(state: ProviderViewState): ProviderViewState {
  return Object.fromEntries(
    Object.entries({ ...state, scope: compactScopeForDisplay(state.scope) }).filter(([, value]) => value !== undefined),
  ) as unknown as ProviderViewState;
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
  // Exact-id routes for actions whose id doesn't carry a self-describing
  // substring (e.g. "show-affected-children" contains neither "absence",
  // "confirmation", nor "incomplete") - these previously fell through to
  // `undefined`, leaving the rendered action control with no targetViewId
  // even though the underlying tool input already resolved correctly.
  if (
    actionId === "show-affected-children"
    || actionId === "next-attendance-detail-page"
    || actionId === "open-attendance-detail"
    || actionId === "open-attendance-risk-for-child"
  ) {
    return "ATTENDANCE_DATE_DETAIL";
  }
  // Both routes open the same-mode (CUSTOM_RANGE) single-period detail
  // behind an already-computed ledger figure - see the `ledgerInput`/
  // `additionalPeriodActions` construction in payment-formatter.ts.
  if (actionId.startsWith("open-service-period-") || actionId === "review-service-period-payout-ledger") {
    return "SUB_PAYMENT_DETAIL";
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