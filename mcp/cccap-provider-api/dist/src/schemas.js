import * as z from "zod/v4";
const dateFilterSchema = z.enum([
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
    caseIds: z.array(z.string().min(1)).optional(),
    countyIds: z.array(z.string().min(1)).optional(),
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
