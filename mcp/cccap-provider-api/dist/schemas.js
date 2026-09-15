import * as z from "zod/v4";
// Shared bound for a single request-scoped identifier or name string.
// Salesforce IDs are 15-18 chars and provider-facing names are short; 200
// is generous headroom while still rejecting an unbounded/oversized payload.
const boundedIdentifier = z.string().min(1).max(200);
const identifierList = z.array(boundedIdentifier).max(50);
// Stable semantic identifier (e.g. "review-absence-limit-risk") for
// display/dedup/documentation - see action-labels.md. Distinct from
// actionToken below, which is the actual signed credential.
const continuationReference = z.string().min(1).max(64);
// Stateless signed continuation credential (see continuation-token.ts).
// Replaces the previous contextRef/actionRef pair - the token embeds its
// own scope/tool/expiry, so no server-side lookup is needed to verify it.
// Bounded generously: a token can carry a childNames array of up to 50
// names (see identifierList) plus a few scope fields, base64url-encoded.
const actionTokenSchema = z.string().min(1).max(4000);
export const dateFilterSchema = z.enum([
    "TODAY",
    "THIS_MONTH",
    "LAST_MONTH",
    "LAST_N_MONTHS",
    "LAST_N_DAYS",
    "DATE_RANGE",
]);
const isoDateSchema = z.iso.date();
// Debug-only passthrough: the provider's exact verbatim chat message/
// selection for this turn (e.g. "3", "Review absence-limit risk"). Never
// used for business logic - server.ts's withConversationLogging wrapper
// strips this out of every request before the real handler ever sees it,
// so it exists purely to give conversation-logger.ts something to log
// beyond the structured tool-call arguments (which never reveal what the
// provider actually typed or which numbered option they picked). Spread
// into dateScopeShape so every schema that spreads dateScopeShape (nearly
// all of them) accepts it without a separate per-schema edit.
const debugMetaShape = {
    providerUtterance: z.string().max(4000).optional(),
};
const dateScopeShape = {
    dateFilter: dateFilterSchema.optional(),
    periodCount: z.number().int().positive().optional(),
    dateFrom: isoDateSchema.optional(),
    dateTo: isoDateSchema.optional(),
    ...debugMetaShape,
};
function validateDateScope(value, context) {
    if ((value.dateFilter === "LAST_N_MONTHS" ||
        value.dateFilter === "LAST_N_DAYS") &&
        value.periodCount === undefined) {
        context.addIssue({
            code: "custom",
            message: "periodCount is required for LAST_N_MONTHS and LAST_N_DAYS",
        });
    }
    if (value.dateFilter === "DATE_RANGE") {
        if (!value.dateFrom || !value.dateTo) {
            context.addIssue({
                code: "custom",
                message: "dateFrom and dateTo are required for DATE_RANGE",
            });
        }
        else if (value.dateFrom > value.dateTo) {
            context.addIssue({
                code: "custom",
                message: "dateFrom cannot be later than dateTo",
            });
        }
    }
}
export const dateScopeSchema = z
    .object(dateScopeShape)
    .strict()
    .superRefine(validateDateScope);
export const caseSchema = z
    .object({
    ...dateScopeShape,
    countyIds: identifierList.optional(),
})
    .strict()
    .superRefine(validateDateScope);
export const authorizationSchema = z
    .object({
    ...dateScopeShape,
    careDate: z.string().date().optional(),
    caseIds: identifierList.optional(),
    countyIds: identifierList.optional(),
    authIds: identifierList.optional(),
    authNames: identifierList.optional(),
})
    .strict()
    .superRefine(validateDateScope);
export const countySchema = caseSchema;
export const schedulesSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema,
    authNames: identifierList.optional(),
})
    .strict()
    .superRefine(validateDateScope);
export const fiscalRatesSchema = dateScopeSchema;
export const paymentHistorySchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema,
})
    .strict()
    .superRefine(validateDateScope);
export const paymentViewSchema = z.enum([
    "STATUS",
    // NEXT_PAYOUT: the single unpaid/upcoming period whose release date is
    // soonest. This is the default view for a plain "upcoming payment"
    // request - it must resolve to exactly one period, never a ledger.
    "NEXT_PAYOUT",
    // LAST_PAYOUT: the single most recently released period. Reachable only
    // via explicit request or as a grounded follow-up; never a default and
    // never offered as a standing greeting option.
    "LAST_PAYOUT",
    // PAYOUT_LEDGER: every service period falling within an explicitly named
    // month/range. Only reached when the provider names a range - never the
    // default for an unscoped "upcoming" ask.
    "PAYOUT_LEDGER",
    // Scoped to the service period containing today (begin <= today <= end),
    // not a fixed calendar week. CURRENT_WEEK_FORECAST is kept as an accepted
    // alias so existing callers are not broken by the rename.
    "CURRENT_PERIOD_FORECAST",
    "CURRENT_WEEK_FORECAST",
    "CUSTOM_RANGE",
]);
// CUSTOM_RANGE payouts are independent of any Salesforce ServicePeriod
// record, so the span is bounded here rather than by a source-side limit.
const CUSTOM_RANGE_MAX_DAYS = 31;
export const attendanceDataSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema,
})
    .strict()
    .superRefine(validateDateScope);
export const attendanceAnalysisSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema.optional(),
    childNames: identifierList.min(1).optional(),
    authNames: identifierList.min(1).optional(),
    countyNames: identifierList.min(1).optional(),
    riskFocus: z.enum(["PARENT_CONFIRMATIONS", "ABSENCE_LIMITS", "INCOMPLETE_ATTENDANCE"]).optional(),
    // Real pagination for the ABSENCE_LIMITS child-level drill-down, matching
    // the same detailPage/detailPageSize contract already used by
    // paymentAnalysisSchema - lets a provider page through the complete
    // affected-child list instead of only seeing a capped preview.
    detailPage: z.number().int().positive().max(10_000).optional(),
    detailPageSize: z.number().int().positive().max(100).optional(),
    actionId: continuationReference.optional(),
    actionToken: actionTokenSchema.optional(),
    refresh: z.boolean().optional(),
})
    .strict()
    .superRefine((value, context) => {
    validateDateScope(value, context);
    if (!value.dateFilter && !value.actionToken && !value.actionId) {
        context.addIssue({ code: "custom", message: "dateFilter is required when a continuation is not supplied" });
    }
});
export const paymentComparisonSchema = z.object({
    periodOne: z.object({ dateFrom: isoDateSchema, dateTo: isoDateSchema }).strict(),
    periodTwo: z.object({ dateFrom: isoDateSchema, dateTo: isoDateSchema }).strict(),
    significantDeltaThresholdPct: z.number().nonnegative().max(1000).optional(),
    ...debugMetaShape,
}).strict();
export const paymentAnalysisSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema.optional(),
    view: paymentViewSchema.optional(),
    childNames: identifierList.min(1).optional(),
    authNames: identifierList.min(1).optional(),
    countyNames: identifierList.min(1).optional(),
    actionId: continuationReference.optional(),
    actionToken: actionTokenSchema.optional(),
    refresh: z.boolean().optional(),
})
    .strict()
    .superRefine((value, context) => {
    validateDateScope(value, context);
    if (!value.view && !value.dateFilter && !value.actionToken && !value.actionId) {
        context.addIssue({
            code: "custom",
            message: "dateFilter is required when view is not specified",
        });
    }
    if (value.view === "CUSTOM_RANGE") {
        if (!value.dateFrom || !value.dateTo) {
            context.addIssue({
                code: "custom",
                message: "dateFrom and dateTo are required for view CUSTOM_RANGE",
            });
        }
        else if (value.dateFrom > value.dateTo) {
            context.addIssue({
                code: "custom",
                message: "dateFrom cannot be later than dateTo",
            });
        }
        else {
            const spanDays = Math.round((new Date(`${value.dateTo}T00:00:00Z`).getTime() - new Date(`${value.dateFrom}T00:00:00Z`).getTime())
                / 86_400_000) + 1;
            if (spanDays > CUSTOM_RANGE_MAX_DAYS) {
                context.addIssue({
                    code: "custom",
                    message: `CUSTOM_RANGE cannot span more than ${CUSTOM_RANGE_MAX_DAYS} days; narrow dateFrom/dateTo`,
                });
            }
        }
    }
});
export const servicePeriodSchema = z
    .object({
    ...dateScopeShape,
    dateOn: z.literal("TODAY").optional(),
    paymentAfter: z.literal("TODAY").optional(),
    limitOne: z.boolean().optional(),
})
    .strict()
    .superRefine((value, context) => {
    validateDateScope(value, context);
    if (!value.dateFilter && !value.dateOn && !value.paymentAfter) {
        context.addIssue({
            code: "custom",
            message: "dateFilter, dateOn, or paymentAfter is required",
        });
    }
});
