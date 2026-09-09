import * as z from "zod/v4";
export const dateFilterSchema = z.enum([
    "TODAY",
    "THIS_MONTH",
    "LAST_MONTH",
    "LAST_N_MONTHS",
    "LAST_N_DAYS",
    "DATE_RANGE",
]);
const isoDateSchema = z.iso.date();
const dateScopeShape = {
    dateFilter: dateFilterSchema.optional(),
    periodCount: z.number().int().positive().optional(),
    dateFrom: isoDateSchema.optional(),
    dateTo: isoDateSchema.optional(),
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
    countyIds: z.array(z.string().min(1)).optional(),
})
    .strict()
    .superRefine(validateDateScope);
export const authorizationSchema = z
    .object({
    ...dateScopeShape,
    careDate: z.string().date().optional(),
    caseIds: z.array(z.string().min(1)).optional(),
    countyIds: z.array(z.string().min(1)).optional(),
    authIds: z.array(z.string().min(1)).optional(),
    authNames: z.array(z.string().min(1)).optional(),
})
    .strict()
    .superRefine(validateDateScope);
export const countySchema = caseSchema;
export const schedulesSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema,
    authNames: z.array(z.string().min(1)).optional(),
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
    "NEXT_PAYOUT",
    "CURRENT_WEEK_FORECAST",
]);
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
    dateFilter: dateFilterSchema,
    childNames: z.array(z.string().min(1)).min(1).optional(),
    authNames: z.array(z.string().min(1)).min(1).optional(),
    riskFocus: z.enum(["PARENT_CONFIRMATIONS", "ABSENCE_LIMITS"]).optional(),
})
    .strict()
    .superRefine(validateDateScope);
export const paymentAnalysisSchema = z
    .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema.optional(),
    view: paymentViewSchema.optional(),
    childNames: z.array(z.string().min(1)).min(1).optional(),
    authNames: z.array(z.string().min(1)).min(1).optional(),
    detailPage: z.number().int().positive().optional(),
    detailPageSize: z.number().int().positive().max(100).optional(),
})
    .strict()
    .superRefine((value, context) => {
    validateDateScope(value, context);
    if (!value.view && !value.dateFilter) {
        context.addIssue({
            code: "custom",
            message: "dateFilter is required when view is not specified",
        });
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
