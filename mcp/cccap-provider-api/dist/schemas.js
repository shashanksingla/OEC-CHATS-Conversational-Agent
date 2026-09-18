import * as z from "zod/v4";
// Bound request-scoped identifiers to reject oversized payloads.
const boundedIdentifier = z.string().min(1).max(200);
const identifierList = z.array(boundedIdentifier).max(50);
// Semantic action identifier for display and deduplication, distinct from the signed token.
const continuationReference = z.string().min(1).max(64);
// Signed continuation token embeds scope, tool, and expiry without server-side lookup.
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
// Preserve the provider's exact utterance for logging; the server strips it before handling.
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
    // NEXT_PAYOUT resolves a plain upcoming-payment request to one period.
    "NEXT_PAYOUT",
    // LAST_PAYOUT is available only for explicit or grounded follow-up requests.
    "LAST_PAYOUT",
    // PAYOUT_LEDGER covers periods in an explicitly named month or range.
    "PAYOUT_LEDGER",
    // CURRENT_PERIOD_FORECAST covers today's service period; CURRENT_WEEK_FORECAST remains an alias.
    "CURRENT_PERIOD_FORECAST",
    "CURRENT_WEEK_FORECAST",
    "CUSTOM_RANGE",
]);
// CUSTOM_RANGE payouts are independent of any Salesforce ServicePeriod
// record, so the span is bounded here rather than by a source-side limit.
const CUSTOM_RANGE_MAX_DAYS = 31;
export const attendanceAnalysisSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema.optional(),
    childNames: identifierList.min(1).optional(),
    authNames: identifierList.min(1).optional(),
    countyNames: identifierList.min(1).optional(),
    riskFocus: z.enum(["PARENT_CONFIRMATIONS", "ABSENCE_LIMITS", "INCOMPLETE_ATTENDANCE"]).optional(),
    // Pagination lets providers page through the complete affected-child list.
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
