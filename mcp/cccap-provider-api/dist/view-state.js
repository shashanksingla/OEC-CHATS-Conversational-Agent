export function viewState(state) {
    return Object.fromEntries(Object.entries(state).filter(([, value]) => value !== undefined));
}
export function actionViewMetadata(action, currentView) {
    const input = action.input && typeof action.input === "object" && !Array.isArray(action.input)
        ? action.input
        : undefined;
    return {
        ...action,
        sourceViewId: currentView.viewId,
        ...(input?.viewId ? { targetViewId: input.viewId } : { targetViewId: targetViewForAction(action.actionId) }),
        lockedView: currentView,
    };
}
function targetViewForAction(actionId) {
    if (typeof actionId !== "string")
        return undefined;
    if (actionId.startsWith("attendance-view-")) {
        const viewId = actionId.slice("attendance-view-".length);
        if (viewId === "ATTENDANCE_DATE_DETAIL" || viewId === "ATTENDANCE_COUNTY_ROLLUP")
            return viewId;
    }
    if (actionId.includes("absence") || actionId.includes("confirmation") || actionId.includes("incomplete")) {
        return "ATTENDANCE_DATE_DETAIL";
    }
    if (actionId.includes("payment-county"))
        return "PAYMENT_COUNTY_ROLLUP";
    if (actionId.includes("vacant-slot"))
        return "VACANT_SLOT_ROLLUP";
    if (actionId.includes("sub-payment"))
        return "SUB_PAYMENT_SUMMARY";
    if (actionId.includes("county"))
        return "ATTENDANCE_COUNTY_ROLLUP";
    if (actionId.includes("payout"))
        return "NEXT_UPCOMING_PAYOUT";
    if (actionId.includes("forecast"))
        return "CURRENT_SERVICE_PERIOD_FORECAST";
    if (actionId.includes("payment-detail"))
        return "SUB_PAYMENT_DETAIL";
    if (actionId.includes("payment-summary"))
        return "PAYMENT_CATEGORY_ROLLUP";
    return undefined;
}
