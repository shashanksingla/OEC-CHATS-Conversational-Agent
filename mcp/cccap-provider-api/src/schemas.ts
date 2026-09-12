import * as z from "zod/v4";

// Shared bound for a single request-scoped identifier or name string.
// Salesforce IDs are 15-18 chars and provider-facing names are short; 200
// is generous headroom while still rejecting an unbounded/oversized payload.
const boundedIdentifier = z.string().min(1).max(200);
const identifierList = z.array(boundedIdentifier).max(50);
const continuationReference = z.string().min(1).max(64);

function validateContinuation(value: { contextRef?: string | undefined; actionRef?: string | undefined }, context: z.core.$RefinementCtx): void {
  if (Boolean(value.contextRef) !== Boolean(value.actionRef)) {
    context.addIssue({ code: "custom", message: "contextRef and actionRef must be supplied together" });
  }
}

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

function validateDateScope(
  value: {
    dateFilter?: z.infer<typeof dateFilterSchema> | undefined;
    periodCount?: number | undefined;
    dateFrom?: string | undefined;
    dateTo?: string | undefined;
  },
  context: z.core.$RefinementCtx,
): void {
  if (
    (value.dateFilter === "LAST_N_MONTHS" ||
      value.dateFilter === "LAST_N_DAYS") &&
    value.periodCount === undefined
  ) {
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
    } else if (value.dateFrom > value.dateTo) {
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
  "NEXT_PAYOUT",
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
    actionId: continuationReference.optional(),
    contextRef: continuationReference.optional(),
    actionRef: continuationReference.optional(),
    refresh: z.boolean().optional(),
  })
  .strict()
  .superRefine((value, context) => {
    validateDateScope(value, context);
    validateContinuation(value, context);
    if (!value.dateFilter && !(value.contextRef && value.actionRef) && !value.actionId) {
      context.addIssue({ code: "custom", message: "dateFilter is required when a continuation is not supplied" });
    }
  });

export const paymentComparisonSchema = z.object({
  periodOne: z.object({ dateFrom: isoDateSchema, dateTo: isoDateSchema }).strict(),
  periodTwo: z.object({ dateFrom: isoDateSchema, dateTo: isoDateSchema }).strict(),
  significantDeltaThresholdPct: z.number().nonnegative().max(1000).optional(),
}).strict();

export const paymentAnalysisSchema = z
  .object({
    ...dateScopeShape,
    dateFilter: dateFilterSchema.optional(),
    view: paymentViewSchema.optional(),
    childNames: identifierList.min(1).optional(),
    authNames: identifierList.min(1).optional(),
    countyNames: identifierList.min(1).optional(),
    grouping: z.enum(["SERVICE_PERIOD", "COUNTY", "CHILD", "CATEGORY"]).optional(),
    detailDepth: z.enum(["SUMMARY", "DETAIL"]).optional(),
    detailPage: z.number().int().positive().max(10_000).optional(),
    detailPageSize: z.number().int().positive().max(100).optional(),
    // Narrows the detail table to rows the payment engine excluded from
    // payment (unpayable/excluded-authorization days), instead of the full
    // attendance detail. Backs the "review excluded payment days" action.
    excludedOnly: z.boolean().optional(),
    actionId: continuationReference.optional(),
    contextRef: continuationReference.optional(),
    actionRef: continuationReference.optional(),
    refresh: z.boolean().optional(),
  })
  .strict()
  .superRefine((value, context) => {
    validateDateScope(value, context);
    validateContinuation(value, context);
    if (!value.view && !value.dateFilter && !(value.contextRef && value.actionRef) && !value.actionId) {
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
      } else if (value.dateFrom > value.dateTo) {
        context.addIssue({
          code: "custom",
          message: "dateFrom cannot be later than dateTo",
        });
      } else {
        const spanDays = Math.round(
          (new Date(`${value.dateTo}T00:00:00Z`).getTime() - new Date(`${value.dateFrom}T00:00:00Z`).getTime())
            / 86_400_000,
        ) + 1;
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