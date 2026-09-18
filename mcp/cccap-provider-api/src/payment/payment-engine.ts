// Consolidated payment engine modules.

// ===== begin payment-schema.ts =====
export type RecordValue = Record<string, unknown>;

export interface CanonicalServicePeriod {
  id: string;
  start_date: string;
  end_date: string;
  // Preserve Apex's release date when available; omit it only for synthetic ranges without a stored period.
  payout_date?: string;
}

export interface CanonicalExistingSubPayment {
  authorization_id?: string;
  service_period_id: string;
  status: "PAID" | "REQUESTED";
  amount?: number;
}

export interface CanonicalPaymentFeeSchedule {
  authorization_id: string;
  fiscal_schedule_id: string;
  slot_contract_id: string;
  care_level: string;
  effective_start: string;
  effective_end?: string;
  authorization_effective_start?: string;
  authorization_effective_end?: string;
  authorization_status?: string;
  days_of_month?: number;
  days_of_week?: string | number;
  slot_rate_amount: number;
  activity_amount?: number;
  activity_authorization_amount?: number;
  activity_provider_cap?: number;
  activity_county_cap?: number;
  activity_frequency?: string;
  activity_months?: string;
  registration_amount?: number;
  registration_authorization_amount?: number;
  registration_provider_cap?: number;
  registration_county_cap?: number;
  registration_frequency?: string;
  registration_months?: string;
  transportation_amount?: number;
  transportation_authorization_amount?: number;
  transportation_provider_cap?: number;
  transportation_county_cap?: number;
  transportation_frequency?: string;
  transportation_months?: string;
}

export interface CanonicalVacantSlotSchedule {
  slot_contract_id: string;
  county_id: string;
  county_name?: string;
  fiscal_schedule_id: string;
  effective_start: string;
  effective_end?: string;
  days_of_month?: number;
  days_of_week?: string | number;
  slot_rate_amount: number;
  provider_closure_dates?: string[];
}

export function normalizePaymentStatus(value: unknown): "PAID" | "REQUESTED" | undefined {
  const status = String(value ?? "").trim().toUpperCase();
  if (status === "4" || status === "PAID") return "PAID";
  if (["1", "2", "3", "CREATED", "IN_PROGRESS", "CALCULATED", "REQUESTED"].includes(status)) {
    return "REQUESTED";
  }
  return undefined;
}

// Reject malformed top-level payloads before crossing the process boundary.
export function assertPaymentEnginePayload(payload: unknown): void {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw new Error("Payment engine payload must be an object");
  }
  const record = payload as RecordValue;
  if (record.rule_version !== "provider-risk-payment-v3") {
    throw new Error("Payment engine payload rule_version must be provider-risk-payment-v3");
  }
  const requiredArrayFields = [
    "authorizations",
    "attendance_days",
    "county_policies",
    "fiscal_rates",
    "existing_sub_payments",
  ] as const;
  for (const field of requiredArrayFields) {
    if (!Array.isArray(record[field])) {
      throw new Error(`Payment engine payload.${field} must be an array`);
    }
  }
  const servicePeriod = record.service_period;
  if (
    !servicePeriod
    || typeof servicePeriod !== "object"
    || Array.isArray(servicePeriod)
    || typeof (servicePeriod as RecordValue).id !== "string"
    || typeof (servicePeriod as RecordValue).start_date !== "string"
    || typeof (servicePeriod as RecordValue).end_date !== "string"
  ) {
    throw new Error("Payment engine payload.service_period must include id, start_date, and end_date");
  }
}
// ===== end payment-schema.ts =====

// ===== begin payment-payload-adapter.ts =====
import { normalizeQualityTier } from "../shared/normalizers.js";

function asRecord(value: unknown, label: string): RecordValue {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
  return value as RecordValue;
}

function requiredString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${label} is required`);
  }
  return value;
}

function resolveAuthorizationId(
  value: unknown,
  authorizations: RecordValue[],
  label: string,
): string {
  const reference = typeof value === "string" && value.length > 0 ? value : undefined;
  if (!reference) throw new Error(`${label} is required`);
  if (authorizations.length === 0) return reference;
  const authorization = authorizations.find((candidate) =>
    candidate.Name === reference || candidate.IDN_EXTNL__c === reference || candidate.Id === reference,
  );
  return requiredString(authorization?.Id, `${label} Salesforce authorization ID`);
}

function resolveOptionalAuthorizationId(
  value: unknown,
  authorizations: RecordValue[],
  label: string,
): string | undefined {
  if (value === undefined || value === null || value === "") return undefined;
  return resolveAuthorizationId(value, authorizations, label);
}

export function normalizeServicePeriod(value: unknown): CanonicalServicePeriod {
  const period = asRecord(value, "service period");
  // Preserve the release date when available; synthetic ranges may omit it.
  const releaseDate = period.paymentReleaseDate ?? period.payout_date;
  return {
    id: requiredString(period.servicePeriodId ?? period.id, "service period id"),
    start_date: requiredString(
      period.serviceBeginDate ?? period.start_date,
      "service period start date",
    ),
    end_date: requiredString(
      period.serviceEndDate ?? period.end_date,
      "service period end date",
    ),
    ...(typeof releaseDate === "string" && releaseDate.length > 0 ? { payout_date: releaseDate } : {}),
  };
}

export function normalizeExistingSubPayments(
  value: unknown,
  authorizations: RecordValue[] = [],
): CanonicalExistingSubPayment[] {
  const response = asRecord(value, "payment history response");
  const rows = response.subPayments;
  if (!Array.isArray(rows)) throw new Error("payment history subPayments must be an array");

  return rows.map((value, index) => {
    const row = asRecord(value, `subPayments[${index}]`);
    const status = normalizePaymentStatus(row.cde_status_pmt_sub__c);
    if (!status) throw new Error(`subPayments[${index}].cde_status_pmt_sub__c is unsupported`);
    const sourceAmount = row.amt_pmt_sub__c ?? row.amt_total_pmt_sub__c;
    const amount = typeof sourceAmount === "number" && Number.isFinite(sourceAmount)
      ? sourceAmount
      : typeof sourceAmount === "string" && Number.isFinite(Number(sourceAmount))
        ? Number(sourceAmount)
        : undefined;
    const authorizationId = resolveOptionalAuthorizationId(
      row.idn_auth__c,
      authorizations,
      `subPayments[${index}].idn_auth__c`,
    );
    return {
      service_period_id: requiredString(
        row.idn_period_serv__c,
        `subPayments[${index}].idn_period_serv__c`,
      ),
      status,
      ...(authorizationId ? { authorization_id: authorizationId } : {}),
      ...(amount !== undefined ? { amount } : {}),
    };
  });
}

export interface CanonicalAttendanceDay {
  authorization_id: string;
  service_date: string;
  authorized_hours: number;
  attended_hours: number;
  parent_confirmation: "CONFIRMED" | "PENDING" | "REJECTED";
  absence_parent_approved: boolean;
  age_band: "ZERO_TO_36_MONTHS" | "OVER_36_MONTHS";
  slot_contract_present: boolean;
  occupied_slot_contract: boolean;
  care_not_offered: boolean;
  observed_holiday: boolean;
  child_name?: string;
  county_id?: string;
  county_name?: string;
  forecast_basis?: "SCHEDULED";
  attendance_basis?: "ACTUAL" | "SCHEDULED";
  holiday_name?: string;
  holiday_date?: string;
  observed_holiday_date?: string;
  // Preserve the rate type for each day because one authorization may use several.
  rate_type_code?: string;
  // Schedule's own Type__c (CCCAP_AUTHORIZED / CCCAP_NOT_AUTHORIZED / CARE_NOT_OFFERED) - the
  // explicit primary signal for CARE_NOT_OFFERED/drop-in classification, kept string-permissive
  // so an unrecognized value never throws (Python treats anything else as the authorized path).
  authorization_type?: string;
}

function requiredNonNegativeNumber(value: unknown, label: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    throw new Error(`${label} must be a non-negative number`);
  }
  return value;
}

function requiredBoolean(value: unknown, label: string): boolean {
  if (typeof value !== "boolean") throw new Error(`${label} is required`);
  return value;
}

function optionalBoolean(value: unknown): boolean | undefined {
  return typeof value === "boolean" ? value : undefined;
}

function dateMatches(value: unknown, date: string): boolean {
  return typeof value === "string" && value.slice(0, 10) === date;
}

function sourceDate(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value.slice(0, 10) : undefined;
}

function childIsUnder36Months(dateOfBirth: unknown, careDate: string, authorizationId: string): boolean {
  if (typeof dateOfBirth !== "string" || dateOfBirth.length === 0) {
    throw new Error(`child date of birth is missing for ${authorizationId}`);
  }
  const birthDate = new Date(`${dateOfBirth.slice(0, 10)}T00:00:00Z`);
  const careDateValue = new Date(`${careDate.slice(0, 10)}T00:00:00Z`);
  if (Number.isNaN(birthDate.getTime()) || Number.isNaN(careDateValue.getTime())) {
    throw new Error(`child date of birth or care date is invalid for ${authorizationId} on ${careDate}`);
  }
  const thirtySixMonthDate = new Date(birthDate);
  thirtySixMonthDate.setUTCFullYear(thirtySixMonthDate.getUTCFullYear() + 3);
  return careDateValue < thirtySixMonthDate;
}

function findAuthorizationForSchedule(
  schedule: RecordValue,
  authorizations: RecordValue[],
): RecordValue | undefined {
  const references = [
    schedule.authorization_id,
    schedule.authorization_name,
    schedule.CI_Authorization_Id__c,
  ]
    .filter((reference): reference is string | number =>
      (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
    )
    .map(String);
  return authorizations.find((authorization) => [
    authorization.Id,
    authorization.Name,
    authorization.IDN_EXTNL__c,
  ]
    .filter((reference): reference is string | number =>
      (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
    )
    .map(String)
    .some((reference) => references.includes(reference)));
}

export function deriveAttendanceEnrichment(
  schedules: unknown[],
  authorizationData: unknown,
  holidayData: unknown,
): Record<string, RecordValue> {
  const response = asRecord(authorizationData, "authorization enrichment");
  const rawAuthorizations = Array.isArray(response.authorizations)
    ? response.authorizations
    : Array.isArray(response.normalizedAuthorizations)
      ? response.normalizedAuthorizations.map((value) => asRecord(value, "normalized authorization").authorization)
      : [];
  const authorizationRecords = rawAuthorizations
    .map((value, index) => asRecord(value, `authorizations[${index}]`));
  const slotContracts = Array.isArray(response.slotContracts) ? response.slotContracts : [];
  const encumbrances = Array.isArray(response.encumbrances) ? response.encumbrances : [];
  const holidays = asRecord(holidayData, "holiday enrichment").holidayList;
  if (!Array.isArray(holidays)) throw new Error("holiday enrichment holidayList must be an array");

  const result: Record<string, RecordValue> = {};
  schedules.forEach((value, index) => {
    const schedule = asRecord(value, `schedules[${index}]`);
    const authorizationId = requiredString(
      schedule.authorization_id,
      `schedules[${index}].authorization_id`,
    );
    const serviceDate = requiredString(schedule.work_date, `schedules[${index}].work_date`);
    const authorization = findAuthorizationForSchedule(schedule, authorizationRecords);
    // Skip schedules whose authorization link cannot be resolved; enrichment cannot safely infer their required authorization data.
    if (!authorization) return;
    const authorizationReferences = new Set([
      authorizationId,
      authorization?.Id,
      authorization?.Name,
      authorization?.IDN_EXTNL__c,
    ].filter((reference): reference is string => typeof reference === "string" && reference.length > 0));
    const matchingEncumbrances = encumbrances.filter((candidate) => {
      const row = asRecord(candidate, "authorization encumbrance");
      const references = [row.idn_auth__c, row.idn_encmbr_auth__c]
        .filter((reference): reference is string => typeof reference === "string" && reference.length > 0);
      return references.some((reference) => {
        if (authorizationRecords.length === 0) return reference === authorizationId;
        return authorizationReferences.has(reference);
      }) && dateMatches(row.dte_care__c, serviceDate);
    });
    const clientValue = authorization?.IDN_CLIENT__r;
    const client = clientValue && typeof clientValue === "object" && !Array.isArray(clientValue)
      ? asRecord(clientValue, "authorization client")
      : undefined;
    const ageBand = childIsUnder36Months(
      client?.DTE_DOB__c,
      serviceDate,
      authorizationId,
    ) ? "ZERO_TO_36_MONTHS" : "OVER_36_MONTHS";
    const encumbranceStatuses = new Set(
      matchingEncumbrances
        .map((candidate) => normalizeEncumbranceStatus(
          asRecord(candidate, "authorization encumbrance").cde_status_encmbr__c,
        ))
        .filter((status): status is EncumbranceStatus => status !== undefined),
    );
    if (encumbranceStatuses.size !== 1) {
      throw new Error(`encumbrance status is missing or ambiguous for ${authorizationId} on ${serviceDate}`);
    }

    const matchingSlots = slotContracts.filter((candidate) => {
      const row = asRecord(candidate, "slot contract");
      const begins = row.DTE_BEGIN_SLOT__c;
      const ends = row.DTE_END_SLOT__c;
      return authorizationReferences.has(String(row.IDN_AUTH__c))
        && (!begins || String(begins).slice(0, 10) <= serviceDate)
        && (!ends || String(ends).slice(0, 10) >= serviceDate);
    });
    const occupiedSlotContract = matchingSlots.length > 0;

    const matchingHoliday = holidays.find((candidate) => {
      const holiday = asRecord(candidate, "holiday");
      return dateMatches(holiday.DTE_HOL__c, serviceDate)
        || dateMatches(holiday.DTE_OBSERVED_HOL__c, serviceDate);
    });
    const holiday = matchingHoliday ? asRecord(matchingHoliday, "holiday") : undefined;
    // date_of_birth is a per-client constant (unlike age_band/holiday fields above, it never
    // varies across this authorization's schedule days), so overwriting it once per day here
    // is safe - normalizeAttendanceDays re-derives the fiscal age-group code PER DAY from this
    // same DOB against each day's own service_date, instead of a single value fixed at the
    // service period's start date (the previous behavior, which could misclassify a child's
    // fiscal age band for days after they cross a 6-month boundary mid-period).
    const dateOfBirth = typeof client?.DTE_DOB__c === "string" ? client.DTE_DOB__c : undefined;
    result[authorizationId] = {
      age_band: ageBand,
      ...(dateOfBirth ? { date_of_birth: dateOfBirth } : {}),
      slot_contract_present: matchingSlots.length > 0,
      occupied_slot_contract: occupiedSlotContract,
      care_not_offered: encumbranceStatuses.has("CARE_NOT_OFFERED")
        || optionalBoolean(schedule.care_not_offered) === true,
      observed_holiday: Boolean(holiday),
      ...(holiday?.CDE_HOL__c !== undefined ? { holiday_name: String(holiday.CDE_HOL__c) } : {}),
      ...(sourceDate(holiday?.DTE_HOL__c) ? { holiday_date: sourceDate(holiday?.DTE_HOL__c) } : {}),
      ...(sourceDate(holiday?.DTE_OBSERVED_HOL__c)
        ? { observed_holiday_date: sourceDate(holiday?.DTE_OBSERVED_HOL__c) }
        : {}),
    };
  });
  return result;
}

export function normalizeAttendanceDays(
  schedules: unknown[],
  enrichmentByAuthorization: Record<string, RecordValue>,
  options: { mode?: "STATUS" | "FORECAST"; asOfDate?: string } = {},
): CanonicalAttendanceDay[] {
  return schedules.map((value, index) => {
    const schedule = asRecord(value, `schedules[${index}]`);
    const authorizationId = requiredString(
      schedule.authorization_id,
      `schedules[${index}].authorization_id`,
    );
    const enrichment = enrichmentByAuthorization[authorizationId];
    if (!enrichment) throw new Error(`attendance enrichment is missing for ${authorizationId}`);
    const serviceDate = requiredString(schedule.work_date, `schedules[${index}].work_date`);
    const isForecast = options.mode === "FORECAST";
    const isFutureForecast =
      isForecast &&
      typeof options.asOfDate === "string" &&
      serviceDate > options.asOfDate;
    const parentConfirmation = isFutureForecast || schedule.parent_confirmation === undefined
      ? "PENDING"
      : schedule.parent_confirmation;
    if (parentConfirmation !== "CONFIRMED" && parentConfirmation !== "PENDING") {
      throw new Error(`schedules[${index}].parent_confirmation is required`);
    }
    const ageBand = enrichment.age_band;
    if (ageBand !== "ZERO_TO_36_MONTHS" && ageBand !== "OVER_36_MONTHS") {
      throw new Error(`attendance enrichment age_band is required for ${authorizationId}`);
    }
    return {
      authorization_id: authorizationId,
      service_date: serviceDate,
      authorized_hours: requiredNonNegativeNumber(
        schedule.ci_authorization_hours,
        `schedules[${index}].ci_authorization_hours`,
      ),
      attended_hours: isFutureForecast
        ? 0
        : typeof schedule.raw_hours === "number"
          ? requiredNonNegativeNumber(schedule.raw_hours, `schedules[${index}].raw_hours`)
          : isForecast
            ? 0
            : requiredNonNegativeNumber(schedule.raw_hours, `schedules[${index}].raw_hours`),
      parent_confirmation: parentConfirmation,
      absence_parent_approved: typeof schedule.absence_parent_approved === "boolean"
        ? schedule.absence_parent_approved
        : isForecast
          ? false
          : requiredBoolean(
              schedule.absence_parent_approved,
              `schedules[${index}].absence_parent_approved`,
            ),
      age_band: ageBand,
      slot_contract_present: requiredBoolean(
        enrichment.slot_contract_present ?? enrichment.occupied_slot_contract,
        `attendance enrichment slot_contract_present for ${authorizationId}`,
      ),
      occupied_slot_contract: requiredBoolean(
        enrichment.occupied_slot_contract,
        `attendance enrichment occupied_slot_contract for ${authorizationId}`,
      ),
      care_not_offered: requiredBoolean(
        enrichment.care_not_offered,
        `attendance enrichment care_not_offered for ${authorizationId}`,
      ),
      observed_holiday: requiredBoolean(
        enrichment.observed_holiday,
        `attendance enrichment observed_holiday for ${authorizationId}`,
      ),
      ...(typeof schedule.child_name === "string" ? { child_name: schedule.child_name } : {}),
      ...(typeof schedule.authorization_name === "string"
        ? { authorization_name: schedule.authorization_name }
        : typeof schedule.Authorization_Name__c === "string"
          ? { authorization_name: schedule.Authorization_Name__c }
          : {}),
      ...(typeof schedule.county_id === "string" ? { county_id: schedule.county_id } : {}),
      ...(typeof schedule.county_name === "string" ? { county_name: schedule.county_name } : {}),
      attendance_basis: (typeof schedule.check_in_count === "number" && schedule.check_in_count > 0)
        || schedule.attended_flag === true
        ? "ACTUAL" as const
        : "SCHEDULED" as const,
      ...(isFutureForecast ? { forecast_basis: "SCHEDULED" as const } : {}),
      ...(typeof enrichment.holiday_name === "string" ? { holiday_name: enrichment.holiday_name } : {}),
      ...(typeof enrichment.holiday_date === "string" ? { holiday_date: enrichment.holiday_date } : {}),
      ...(typeof enrichment.observed_holiday_date === "string"
        ? { observed_holiday_date: enrichment.observed_holiday_date }
        : {}),
      ...(typeof schedule.rate_type_code === "string" && schedule.rate_type_code.length > 0
        ? { rate_type_code: schedule.rate_type_code }
        : {}),
      // Explicit primary signal for CARE_NOT_OFFERED/drop-in classification (schedule's own
      // Type__c); the boolean care_not_offered/authorized_hours==0 inference remains as fallback.
      ...(typeof schedule.authorization_type === "string" && schedule.authorization_type.length > 0
        ? { authorization_type: schedule.authorization_type }
        : {}),
      // Fiscal age-group code derived from this specific day's own service_date, not the
      // authorization's service-period start date - a child's fiscal age band (there are 8,
      // each ~6 months wide) can genuinely change partway through a multi-week service period,
      // and the authorization is a contract spanning many schedule days, each of which is its
      // own care event. Deliberately independent of the coarser 2-value age_band above (which
      // only gates the enrollment-absence carve-out, not fiscal rate selection).
      ...(typeof enrichment.date_of_birth === "string"
        ? (() => {
            const fiscalAgeGroupCode = deriveFiscalAgeGroupCodes(enrichment.date_of_birth, serviceDate)?.[0];
            return fiscalAgeGroupCode ? { fiscal_age_group_code: fiscalAgeGroupCode } : {};
          })()
        : {}),
    };
  });
}

export interface CanonicalPaymentPayload {
  rule_version: "provider-risk-payment-v3";
  calculation_mode?: "STATUS" | "CURRENT_WEEK_FORECAST";
  as_of_date: string;
  service_period: CanonicalServicePeriod;
  authorizations: RecordValue[];
  attendance_days: CanonicalAttendanceDay[];
  county_policies: RecordValue[];
  fiscal_rates: RecordValue[];
  existing_sub_payments: CanonicalExistingSubPayment[];
  fee_history?: RecordValue[];
  vacant_slot_schedules?: CanonicalVacantSlotSchedule[];
}

function optionalNonNegativeNumber(value: unknown, label: string): number | undefined {
  if (value === undefined || value === null) return undefined;
  return requiredNonNegativeNumber(value, label);
}

function optionalFiniteNumber(value: unknown, label: string): number | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new Error(`${label} must be a finite number`);
  }
  return value;
}

// Retain fee history for absence/drop-in counts and paid-holiday detection.
export function normalizePaymentFeeHistory(
  value: unknown,
  authorizations: RecordValue[] = [],
): RecordValue[] {
  const response = asRecord(value, "payment history response");
  const subPayments = Array.isArray(response.subPayments) ? response.subPayments : [];
  const bySubPayment = new Map<string, RecordValue>();
  subPayments.forEach((item, index) => {
    const row = asRecord(item, `subPayments[${index}]`);
    if (row.idn_pmt_sub__c !== undefined) bySubPayment.set(String(row.idn_pmt_sub__c), row);
  });
  const details = [
    ...(Array.isArray(response.paymentDetails) ? response.paymentDetails : []),
    ...(Array.isArray(response.paymentDetailHistory) ? response.paymentDetailHistory : []),
  ];
  return details.map((item, index) => {
    const detail = asRecord(item, `payment detail[${index}]`);
    const subPayment = bySubPayment.get(String(detail.idn_pmt_sub__c));
    const normalized: RecordValue = {
      authorization_id: resolveAuthorizationId(
        subPayment?.idn_auth__c,
        authorizations,
        `payment detail[${index}].authorization_id`,
      ),
      service_date: requiredString(detail.dte_care__c, `payment detail[${index}].dte_care__c`),
    };
    if (detail.cde_type_info_addntl__c !== undefined) normalized.info_code = detail.cde_type_info_addntl__c;
    if (detail.ind_record_delete_logcl__c !== undefined) {
      normalized.deleted = detail.ind_record_delete_logcl__c === true;
    }
    return normalized;
  });
}

function requiredRecords(value: unknown, label: string): RecordValue[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`${label} must contain at least one record`);
  }
  return value.map((item, index) => asRecord(item, `${label}[${index}]`));
}

export function buildCanonicalPaymentPayload(input: {
  servicePeriod: unknown;
  schedules: unknown[];
  attendanceEnrichmentByAuthorization: Record<string, RecordValue>;
  authorizations: unknown;
  countyPolicies: unknown;
  fiscalRates: unknown;
  paymentHistory: unknown;
  authorizationRecords?: RecordValue[];
  feeHistory?: RecordValue[];
  vacantSlotSchedules?: CanonicalVacantSlotSchedule[];
  providerClosureDates?: string[];
  mode?: "STATUS" | "FORECAST";
  asOfDate?: string;
}): CanonicalPaymentPayload {
  const authorizationRows = input.authorizationRecords ?? [];
  const authorizationById = new Map(
    authorizationRows
      .filter((row) => typeof row.Id === "string")
      .map((row) => [row.Id as string, row]),
  );
  const countyPolicyRows = requiredRecords(input.countyPolicies, "county policies");
  const countyPolicyById = new Map(
    countyPolicyRows.map((row) => [String(row.countyId ?? row.CDE_COUNTY__c ?? ""), row]),
  );
  return {
    rule_version: "provider-risk-payment-v3",
    as_of_date: requiredString(input.asOfDate, "as-of date"),
    ...(input.mode
      ? { calculation_mode: input.mode === "FORECAST" ? "CURRENT_WEEK_FORECAST" as const : "STATUS" as const }
      : {}),
    service_period: normalizeServicePeriod(input.servicePeriod),
    authorizations: requiredRecords(input.authorizations, "authorizations"),
    attendance_days: normalizeAttendanceDays(
      input.schedules,
      input.attendanceEnrichmentByAuthorization,
      {
        ...(input.mode ? { mode: input.mode } : {}),
        ...(input.asOfDate ? { asOfDate: input.asOfDate } : {}),
      },
    ),
    county_policies: countyPolicyRows,
    ...(input.providerClosureDates && input.providerClosureDates.length > 0
      ? { provider_closure_dates: [...new Set(input.providerClosureDates.map((value) => value.slice(0, 10)))] }
      : {}),
    fiscal_rates: requiredRecords(input.fiscalRates, "fiscal rates"),
    existing_sub_payments: normalizeExistingSubPayments(input.paymentHistory, input.authorizationRecords),
    ...(input.feeHistory ? { fee_history: input.feeHistory } : {}),
    ...(input.vacantSlotSchedules ? { vacant_slot_schedules: input.vacantSlotSchedules } : {}),
  };
}

export { normalizeQualityTier } from "../shared/normalizers.js";

export type EncumbranceStatus =
  | "PENDING"
  | "AUTHORIZED"
  | "ATTENDED"
  | "PAID"
  | "CARE_NOT_OFFERED";

export function normalizeEncumbranceStatus(value: unknown): EncumbranceStatus | undefined {
  const status = String(value ?? "").trim().toUpperCase();
  const statuses: Record<string, EncumbranceStatus> = {
    "1": "PENDING",
    "2": "AUTHORIZED",
    "3": "ATTENDED",
    "4": "PAID",
    "5": "CARE_NOT_OFFERED",
    PENDING: "PENDING",
    AUTHORIZED: "AUTHORIZED",
    ATTENDED: "ATTENDED",
    PAID: "PAID",
    "CARE NOT OFFERED": "CARE_NOT_OFFERED",
    CARE_NOT_OFFERED: "CARE_NOT_OFFERED",
  };
  return statuses[status];
}

export function normalizeFiscalRatesForPayment(
  normalizedFiscalRates: unknown,
  authorizationMatches: Record<string, string>,
  // Match every rate type used by an authorization because its days may differ.
  authorizationRateTypeCodes: Record<string, string[]> = {},
): RecordValue[] {
  // Age-group is deliberately NOT filtered here anymore. The authorization is a service
  // contract spanning many schedule days; each day is its own care event, and a child's fiscal
  // age-group can genuinely change partway through a multi-week period (there are 8 age bands,
  // each about 6 months wide). Filtering by one age group per authorization (previously derived
  // once from the service period's start date) could silently drop the correct rate for days
  // after a child crossed a band boundary. Every rate_type-matching rate row is passed through
  // with its own age_group_code attached instead; the per-day join in the Python payment engine
  // matches each day's own fiscal_age_group_code (derived from that day's service_date) against
  // this field, so age-group filtering now happens at the correct granularity (per day, not per
  // authorization). Vacant slots are unaffected - they carry their own direct CDE_CARE_LEVEL__c
  // field per slot contract and never derive age from a child's DOB.
  const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
  return rates.flatMap((rate, index) => {
    const scheduleId = requiredString(
      rate.fiscalScheduleId,
      `normalized fiscal rates[${index}].fiscalScheduleId`,
    );
    const authorizationIds = Object.entries(authorizationMatches)
      .filter(([, matchedScheduleId]) => matchedScheduleId === scheduleId)
      .map(([authorizationId]) => authorizationId);
    const paidTier = rate.paidTier;
    if (authorizationIds.length === 0) return [];
    if (typeof paidTier !== "string") {
      throw new Error(`fiscal rate ${scheduleId} cannot be joined to a paid tier`);
    }
    return authorizationIds
      .filter((authorizationId) => {
        const rateTypeCodes = authorizationRateTypeCodes[authorizationId];
        return !rateTypeCodes || rateTypeCodes.length === 0 || rateTypeCodes.includes(String(rate.rateTypeCode));
      })
      .map((authorizationId) => ({
        authorization_id: authorizationId,
        paid_tier: paidTier,
        ...(rate.rateTypeCode !== undefined && rate.rateTypeCode !== null
          ? { rate_type_code: String(rate.rateTypeCode) }
          : {}),
        ...(rate.ageGroupCode !== undefined && rate.ageGroupCode !== null
          ? { age_group_code: String(rate.ageGroupCode) }
          : {}),
        amount: Number(rate.fiscalAgreementAmount),
        source_id: rate.sourceId,
      }));
  });
}

export function deriveFiscalAgeGroupCodes(
  dateOfBirth: unknown,
  careDate: string,
): string[] | undefined {
  if (typeof dateOfBirth !== "string" || dateOfBirth.length === 0) return undefined;
  const birthDate = new Date(`${dateOfBirth.slice(0, 10)}T00:00:00Z`);
  const careDateValue = new Date(`${careDate.slice(0, 10)}T00:00:00Z`);
  if (Number.isNaN(birthDate.getTime()) || Number.isNaN(careDateValue.getTime())) return undefined;
  let months = (careDateValue.getUTCFullYear() - birthDate.getUTCFullYear()) * 12
    + careDateValue.getUTCMonth() - birthDate.getUTCMonth();
  if (careDateValue.getUTCDate() < birthDate.getUTCDate()) months -= 1;
  if (months < 0) return undefined;
  if (months < 6) return ["1"];
  if (months < 12) return ["2"];
  if (months < 18) return ["3"];
  if (months < 24) return ["4"];
  if (months < 30) return ["5"];
  if (months < 36) return ["6"];
  return months < 60 ? ["7"] : ["8"];
}
// ===== end payment-payload-adapter.ts =====

// ===== begin payment-canonical-adapter.ts =====
import { normalizeProviderContext, normalizeScheduleAttendance } from "../shared/normalizers.js";

function record(value: unknown, label: string): RecordValue {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} is unavailable`);
  }
  return value as RecordValue;
}

function array(value: unknown, label: string): unknown[] {
  if (!Array.isArray(value)) throw new Error(`${label} is unavailable`);
  return value;
}

function first(value: unknown, label: string): RecordValue {
  const rows = array(value, label);
  if (rows.length === 0) throw new Error(`${label} is unavailable`);
  return record(rows[0], label);
}

function containsRateType(value: string, requested: string): boolean {
  return value
    .split(/[,;|\s]+/)
    .map((token) => token.trim())
    .filter((token) => token.length > 0)
    .includes(requested);
}

// Thread Apex's release date through when available; synthetic custom ranges may omit it.
export interface PaymentSourceBundle {
  initialization: unknown;
  servicePeriod: unknown;
  authorizationData: unknown;
  countyData: unknown;
  scheduleData: unknown;
  fiscalData: unknown;
  holidayData: unknown;
  vacantSlotData?: unknown;
  paymentData: unknown;
  mode: "STATUS" | "FORECAST";
  asOfDate: string;
}

export function normalizePaymentSourceBundle(
  sources: PaymentSourceBundle,
): {
  payload: CanonicalPaymentPayload;
  servicePeriod: ReturnType<typeof normalizeServicePeriod>;
  vacantSlotMappingGaps: number;
  authorizationMappingGaps: number;
} {
  const initialization = record(sources.initialization, "Provider context");
  const { qualityTier: providerTier, countyIds, countyIdByName } = normalizeProviderContext(initialization);
  const countyNameById = Object.fromEntries(
    Object.entries(countyIdByName).map(([countyName, countyId]) => [countyId, countyName]),
  );
  const countyPlanRows = array(
    record(sources.countyData, "County policies").countyRatePlans,
    "County policies",
  );
  for (const value of countyPlanRows) {
    const policy = record(value, "County policy");
    const countyId = policy.countyId ?? policy.County__c ?? policy.CDE_COUNTY__c;
    const county = policy.County__r;
    const countyRecord = county && typeof county === "object" && !Array.isArray(county)
      ? county as RecordValue
      : undefined;
    const countyName = policy.countyName ?? policy.County_Name__c ?? countyRecord?.Name ?? countyRecord?.County_Name__c;
    if ((typeof countyId === "string" || typeof countyId === "number") && typeof countyName === "string") {
      countyNameById[String(countyId)] = countyName;
    }
  }

  const servicePeriod = normalizeServicePeriod(sources.servicePeriod);
  const authorizationData = record(sources.authorizationData, "Authorizations");
  const normalizedAuthorizations = array(
    authorizationData.normalizedAuthorizations,
    "Normalized authorizations",
  );
  const authorizationRecords = normalizedAuthorizations.map((value, index) =>
    record(record(value, `Normalized authorization[${index}]`).authorization, `Authorization[${index}]`),
  );
  const authorizationMatches: Record<string, string> = {};
  // Preserve all schedule rate types because one authorization may use several.
  const authorizationRateTypeCodes: Record<string, string[]> = {};
  // Treat unresolved fiscal matches as per-authorization gaps, not whole-request failures.
  let authorizationMappingGaps = 0;
  const authorizations = normalizedAuthorizations.flatMap((value, index) => {
    const row = record(value, `Normalized authorization[${index}]`);
    const authorization = record(row.authorization, `Authorization[${index}]`);
    const match = record(row.fiscalScheduleMatch, `Fiscal schedule match[${index}]`);
    if (
      typeof authorization.Id !== "string" ||
      match.status !== "MATCHED" ||
      typeof match.fiscalScheduleId !== "string"
    ) {
      authorizationMappingGaps += 1;
      return [];
    }
    authorizationMatches[authorization.Id] = match.fiscalScheduleId;
    if (Array.isArray(row.rateTypeCode) && row.rateTypeCode.every((code): code is string => typeof code === "string") && row.rateTypeCode.length > 0) {
      authorizationRateTypeCodes[authorization.Id] = row.rateTypeCode;
    }
    // Fiscal age-group is no longer derived here (once per authorization, from the service
    // period's start date) - deriveAttendanceEnrichment/normalizeAttendanceDays now derive it
    // per schedule day, from that day's own service_date, and attach it directly to each
    // canonical attendance day as fiscal_age_group_code. See normalizeFiscalRatesForPayment's
    // header comment for why per-authorization age-group filtering was removed.
    return [{
      id: authorization.Id,
      county_id: authorization.CDE_COUNTY__c,
      quality_tier: providerTier,
      drop_in_limit: authorization.Number_of_Drop_in_Days__c,
    }];
  });

  const normalizedSchedules = normalizeScheduleAttendance(
    array(record(sources.scheduleData, "Schedules").schedules, "Schedules"),
    countyIds.length === 1 ? countyIds[0] : undefined,
    providerTier,
    authorizationData,
  );
  const schedulesWithCountyNames = normalizedSchedules.schedules.map((schedule) => {
    if (schedule.county_name || typeof schedule.county_id !== "string") return schedule;
    const countyName = countyNameById[schedule.county_id];
    return countyName ? { ...schedule, county_name: countyName } : schedule;
  });
  const enrichment = deriveAttendanceEnrichment(
    schedulesWithCountyNames,
    authorizationData,
    sources.holidayData,
  );
    // Exclude orphaned schedules because enrichment cannot derive their authorization data.
  const enrichedSchedules = schedulesWithCountyNames.filter((schedule) =>
    typeof schedule.authorization_id === "string" && schedule.authorization_id in enrichment,
  );
  authorizationMappingGaps += schedulesWithCountyNames.length - enrichedSchedules.length;
  const countyPolicies = countyPlanRows.map((value, index) => {
    const policy = record(value, `County policy[${index}]`);
    const absenceLimit = policy[`absenceDaysTier${providerTier}`];
    if (typeof absenceLimit !== "number") {
      throw new Error(`County policy absenceDaysTier${providerTier} is unavailable`);
    }
    return {
      county_id: policy.countyId,
      quality_tier: providerTier,
      absence_limit: absenceLimit,
      allow_paid_holidays: policy["allowPaidHolidays?"],
      county_holiday_list: policy.countyholidayList,
      allow_drop_in_days: policy.allowDropInDays,
      max_drop_in_days_per_month: policy.maxDropInDaysPerMonth,
      drop_in_response: policy.dropInResponse,
      manage_drop_in_at_auth_level: policy.manageDropInAtAuthLevel,
      activityArtCap: policy.activityArtCap,
      registrationArtCap: policy.registrationArtCap,
      transportationArtCap: policy.transportationArtCap,
    };
  });

  const normalizedFiscal = record(
    record(sources.fiscalData, "Fiscal rates").normalizedFiscalRates,
    "Normalized fiscal rates",
  );
  const fiscalRates = normalizeFiscalRatesForPayment(
    normalizedFiscal.fiscalRates,
    authorizationMatches,
    authorizationRateTypeCodes,
  );
  const providerClosures = Array.isArray(initialization.providerClosures)
    ? initialization.providerClosures
    : Array.isArray(initialization.provider_closures)
      ? initialization.provider_closures
      : [];
  const providerClosureDates = providerClosures.flatMap((value) => {
    const closure = record(value, "Provider closure");
    const date = closure.DTE_BEGIN_CLOSURE__c ?? closure.closure_date;
    return typeof date === "string" ? [date] : [];
  });
  const vacantSlotData = record(sources.vacantSlotData ?? { vacantSlots: [] }, "Vacant slots");
  const paymentHistory = sources.paymentData;
  let vacantSlotMappingGaps = 0;
  const payload = buildCanonicalPaymentPayload({
    servicePeriod,
    schedules: enrichedSchedules,
    attendanceEnrichmentByAuthorization: enrichment,
    authorizations,
    countyPolicies,
    fiscalRates,
    paymentHistory,
    authorizationRecords,
    providerClosureDates,
    vacantSlotSchedules: (() => {
      const resolved = normalizeVacantSlotSchedules(
        vacantSlotData.vacantSlots,
        normalizedFiscal.fiscalRates,
        countyIds,
        providerTier,
        sources.initialization,
        countyNameById,
      );
      vacantSlotMappingGaps = countEligibleVacantSlots(vacantSlotData.vacantSlots) - resolved.length;
      return resolved;
    })(),
    mode: sources.mode,
    asOfDate: sources.asOfDate,
  });
  return { payload, servicePeriod, vacantSlotMappingGaps, authorizationMappingGaps };
}

// Count unoccupied slots that could silently drop without a matching rate, excluding genuinely occupied slots.
function countEligibleVacantSlots(slots: unknown): number {
  if (!Array.isArray(slots)) return 0;
  return slots.filter((value) => {
    const slot = value && typeof value === "object" && !Array.isArray(value) ? value as RecordValue : undefined;
    if (!slot) return false;
    return slot.IDN_AUTH__c === null || slot.IDN_AUTH__c === undefined;
  }).length;
}

export function normalizeVacantSlotSchedules(
  slots: unknown,
  normalizedFiscalRates: unknown,
  countyIds: string[],
  providerQualityTier: number,
  initialization: unknown,
  countyNameById: Record<string, string> = {},
): CanonicalVacantSlotSchedule[] {
  if (!Array.isArray(slots)) throw new Error("vacantSlots must be an array");
  const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
  const context = record(initialization, "Provider context");
  const agreements = Array.isArray(context.fiscalAgreements) ? context.fiscalAgreements : [];
  const closures = Array.isArray(context.providerClosures) ? context.providerClosures : [];
  const scheduleByCounty = new Map<string, Array<{
    id: string;
    rateTypeCode: string;
    qualityTier?: number;
    beginDate: string;
    endDate?: string;
  }>>();
  for (const value of agreements) {
    const agreement = record(value, "Provider county agreement");
    const countyId = agreement.CDE_COUNTY__c;
    const schedules = agreement.Rate_Schedules__r;
    const rows = schedules && typeof schedules === "object" && !Array.isArray(schedules)
      ? (schedules as RecordValue).records
      : undefined;
    if (typeof countyId !== "string" || !countyIds.includes(countyId) || !Array.isArray(rows)) continue;
    scheduleByCounty.set(countyId, rows.flatMap((row) => {
      const schedule = record(row, "Rate schedule");
      if (
        typeof schedule.IDN_EXTNL__c !== "string"
        || typeof schedule.CDE_RATE_TYPE__c !== "string"
        || typeof schedule.DTE_BEGIN_EFFV__c !== "string"
      ) return [];
      const qualityTier = typeof schedule.TXT_CHATS_RATING__c === "string"
        ? normalizeQualityTier(schedule.TXT_CHATS_RATING__c, undefined)
        : undefined;
      return [{
        id: schedule.IDN_EXTNL__c,
        rateTypeCode: schedule.CDE_RATE_TYPE__c,
        ...(qualityTier !== undefined ? { qualityTier } : {}),
        beginDate: schedule.DTE_BEGIN_EFFV__c,
        ...(typeof schedule.DTE_END_EFFV__c === "string" ? { endDate: schedule.DTE_END_EFFV__c } : {}),
      }];
    }));
  }
  return slots.flatMap((value, index) => {
    const slot = record(value, `vacantSlots[${index}]`);
    if (slot.IDN_AUTH__c !== null && slot.IDN_AUTH__c !== undefined) return [];
    const countyId = requiredString(slot.CDE_COUNTY__c, `vacantSlots[${index}].CDE_COUNTY__c`);
    const slotStart = requiredString(slot.DTE_BEGIN_SLOT__c, `vacantSlots[${index}].DTE_BEGIN_SLOT__c`);
    const slotEnd = typeof slot.DTE_END_SLOT__c === "string" ? slot.DTE_END_SLOT__c : undefined;
    const scheduleMatches = (scheduleByCounty.get(countyId) ?? []).filter((schedule) =>
      containsRateType(schedule.rateTypeCode, String(slot.CDE_RATE_TYPE__c))
      && schedule.qualityTier === providerQualityTier
      && schedule.beginDate <= (slotEnd ?? slotStart)
      && (schedule.endDate === undefined || schedule.endDate >= slotStart),
    );
    if (scheduleMatches.length === 0) return [];
    const firstScheduleMatch = scheduleMatches[0];
    if (!firstScheduleMatch) return [];
    const latestBeginDate = scheduleMatches.reduce(
      (latest, schedule) => schedule.beginDate > latest ? schedule.beginDate : latest,
      firstScheduleMatch.beginDate,
    );
    const effectiveSchedules = scheduleMatches.filter((schedule) => schedule.beginDate === latestBeginDate);
    if (effectiveSchedules.length !== 1) return [];
    const selectedSchedule = effectiveSchedules[0];
    if (!selectedSchedule) return [];
    const matches = rates.filter((rate) =>
      rate.fiscalScheduleId === selectedSchedule.id
      && rate.rateTypeCode === String(slot.CDE_RATE_TYPE__c)
      && rate.careUnitCode === String(slot.CDE_CARE_UNIT__c)
      && rate.ageGroupCode === String(slot.CDE_CARE_LEVEL__c),
    );
    if (matches.length !== 1 || !matches[0]) return [];
    const rate = matches[0];
    const closureDates = closures.flatMap((value) => {
      const closure = record(value, "Provider closure");
      return closure.IDN_PROVIDER__c === slot.IDN_PROVIDER__c
        && closure.CDE_COUNTY__c === countyId
        && typeof closure.DTE_BEGIN_CLOSURE__c === "string"
        ? [closure.DTE_BEGIN_CLOSURE__c.slice(0, 10)]
        : [];
    });
    const daysOfMonth = optionalNonNegativeNumber(
      slot.CNT_DAYS_OF_MONTH__c,
      `vacantSlots[${index}].CNT_DAYS_OF_MONTH__c`,
    );
    return [{
      slot_contract_id: requiredString(slot.Id, `vacantSlots[${index}].Id`),
      county_id: countyId,
      ...(countyNameById[countyId] ? { county_name: countyNameById[countyId] } : {}),
      fiscal_schedule_id: selectedSchedule.id,
      effective_start: slotStart,
      ...(slot.DTE_END_SLOT__c ? { effective_end: requiredString(slot.DTE_END_SLOT__c, `vacantSlots[${index}].DTE_END_SLOT__c`) } : {}),
      ...(daysOfMonth !== undefined ? { days_of_month: daysOfMonth } : {}),
      ...(typeof slot.CNT_DAYS_OF_WEEK__c === "string" || typeof slot.CNT_DAYS_OF_WEEK__c === "number"
        ? { days_of_week: slot.CNT_DAYS_OF_WEEK__c }
        : {}),
      slot_rate_amount: Number(rate.fiscalAgreementAmount),
      ...(closureDates.length > 0 ? { provider_closure_dates: closureDates } : {}),
    }];
  });
}
// ===== end payment-canonical-adapter.ts =====

// ===== begin authorization-fiscal-schedule-matcher.ts =====
export interface FiscalScheduleCandidate {
  id: string;
  externalId: string;
  countyId: string;
  rateTypeCode: string;
  beginDate: string;
  endDate?: string;
}

export interface AuthorizationScheduleMatch {
  status: "MATCHED" | "UNRESOLVED";
  fiscalScheduleId?: string;
  // Distinct no-match reasons identify whether county, rate type, or date matching failed.
  reason?: "MISSING_SCHEDULE_RATE_TYPE" | "RATE_TYPE_CONFLICT" | "NO_MATCH" | "NO_MATCH_COUNTY" | "NO_MATCH_RATE_TYPE" | "NO_MATCH_DATE" | "AMBIGUOUS_MATCH";
}

function containsDate(beginDate: string, endDate: string | undefined, date: string): boolean {
  return beginDate <= date && (endDate === undefined || endDate >= date);
}

export function selectFiscalScheduleForAuthorization(
  authorizationValue: unknown,
  schedules: FiscalScheduleCandidate[],
  careDate: string,
  // Match any rate type used by the authorization because one authorization may legitimately span multiple daily rate types.
  scheduleRateTypes?: readonly string[],
): AuthorizationScheduleMatch {
  const authorization = record(authorizationValue, "authorization");
  const countyId = requiredString(authorization.CDE_COUNTY__c, "authorization.CDE_COUNTY__c");
  const authorizationBegin = requiredString(
    authorization.DTE_BEGIN_EFFV_AUTH__c,
    "authorization.DTE_BEGIN_EFFV_AUTH__c",
  );
  const authorizationEnd = typeof authorization.DTE_END_EFFV_AUTH__c === "string"
    ? authorization.DTE_END_EFFV_AUTH__c
    : undefined;
  if (!containsDate(authorizationBegin, authorizationEnd, careDate)) {
    return { status: "UNRESOLVED", reason: "NO_MATCH" };
  }

  const requestedRateTypes = (scheduleRateTypes ?? []).filter((value) => value.length > 0);
  if (requestedRateTypes.length === 0) {
    return { status: "UNRESOLVED", reason: "MISSING_SCHEDULE_RATE_TYPE" };
  }

  // Filter in stages so unresolved matches identify the failing criterion.
  const countyMatches = schedules.filter((schedule) => schedule.countyId === countyId);
  if (countyMatches.length === 0) return { status: "UNRESOLVED", reason: "NO_MATCH_COUNTY" };

  const rateTypeMatches = countyMatches.filter((schedule) =>
    requestedRateTypes.some((rateType) => containsRateType(schedule.rateTypeCode, rateType)),
  );
  if (rateTypeMatches.length === 0) return { status: "UNRESOLVED", reason: "NO_MATCH_RATE_TYPE" };

  const matches = rateTypeMatches.filter((schedule) => containsDate(schedule.beginDate, schedule.endDate, careDate));
  if (matches.length === 0) return { status: "UNRESOLVED", reason: "NO_MATCH_DATE" };
  const firstMatch = matches[0];
  if (!firstMatch) return { status: "UNRESOLVED", reason: "NO_MATCH_DATE" };

  const latestBeginDate = matches.reduce(
    (latest, schedule) => schedule.beginDate > latest ? schedule.beginDate : latest,
    firstMatch.beginDate,
  );
  const latestMatches = matches.filter((schedule) => schedule.beginDate === latestBeginDate);
  if (latestMatches.length !== 1) {
    return { status: "UNRESOLVED", reason: "AMBIGUOUS_MATCH" };
  }
  const selectedMatch = latestMatches[0];
  if (!selectedMatch) return { status: "UNRESOLVED", reason: "NO_MATCH" };
  return { status: "MATCHED", fiscalScheduleId: selectedMatch.externalId };
}
// ===== end authorization-fiscal-schedule-matcher.ts =====

// ===== begin fiscal-rate-normalizer.ts =====
export interface NormalizedFiscalRate {
  sourceId: string;
  fiscalScheduleId: string;
  rateTypeCode: string;
  rateTypeLabel: string;
  ageGroupCode: string;
  ageGroupLabel: string;
  careUnitCode: string;
  careUnitLabel: string;
  paidTier?: "NO_PAYMENT" | "PART_TIME" | "FULL_TIME" | "FULL_TIME_PLUS_PART_TIME" | "FULL_TIME_PLUS_FULL_TIME";
  countyAmount: string;
  fiscalAgreementAmount: string;
  providerAmount: string;
}

export interface NormalizedFiscalRateFee {
  sourceId: string;
  fiscalScheduleId: string;
  activityFrequency?: string;
  registrationFrequency?: string;
  transportationFrequency?: string;
  activityCountyAmount?: string;
  activityFiscalAgreementAmount?: string;
  activityProviderAmount?: string;
  registrationCountyAmount?: string;
  registrationFiscalAgreementAmount?: string;
  registrationProviderAmount?: string;
  transportationCountyAmount?: string;
  transportationFiscalAgreementAmount?: string;
  transportationProviderAmount?: string;
  activityMonths?: string;
  registrationMonths?: string;
  transportationMonths?: string;
}

export interface FiscalRateNormalization {
  fiscalRates: NormalizedFiscalRate[];
  fiscalRateFees: NormalizedFiscalRateFee[];
  canonicalMappingStatus: "COMPLETE_CODE_MAPPING" | "PARTIAL_CODE_MAPPING";
  unresolvedMappings: string[];
  r00393Values: Record<string, number>;
}

const AGE_GROUP_LABELS: Record<string, string> = {
  "1": "0-6 Months",
  "2": "06-12 Months",
  "3": "12-18 Months",
  "4": "18-24 Months",
  "5": "24-30 Months",
  "6": "30-36 Months",
  "7": "36 - School Age",
  "8": "School Age",
};

const CARE_UNIT_LABELS: Record<string, string> = {
  "1": "NP",
  "2": "PT",
  "3": "FT",
  "4": "FTPT",
  "5": "FTFT",
};

const PAID_TIER_BY_CARE_UNIT: Record<string, NonNullable<NormalizedFiscalRate["paidTier"]>> = {
  "1": "NO_PAYMENT",
  "2": "PART_TIME",
  "3": "FULL_TIME",
  "4": "FULL_TIME_PLUS_PART_TIME",
  "5": "FULL_TIME_PLUS_FULL_TIME",
};

const RATE_TYPE_LABELS: Record<string, string> = {
  "1": "Regular",
  "13": "Before School",
  "19": "After School",
  "25": "B and A School",
  "31": "Overnight",
  "37": "Weekend",
  "43": "Evening",
  "55": "Disability",
  "91": "Out-of-County",
};

export const R00393_VALUES: Record<string, number> = {
  "1": 15650,
  ADD: 5500,
};

function money(value: unknown, label: string): string {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    throw new Error(`${label} must be a non-negative number`);
  }
  return value.toFixed(2);
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function optionalMoney(value: unknown, label: string): string | undefined {
  if (value === undefined || value === null) return undefined;
  return money(value, label);
}

function mappedLabel(
  value: unknown,
  mappings: Record<string, string>,
  label: string,
): string {
  const code = requiredString(value, label);
  const mapped = mappings[code];
  if (!mapped) throw new Error(`${label} has unsupported code ${code}`);
  return mapped;
}

export function normalizeFiscalRateResponse(value: unknown): FiscalRateNormalization {
  const data = record(value, "fiscal-rate response");
  const rawRates = data.fiscalRates;
  const rawFees = data.fiscalRateFees;
  if (!Array.isArray(rawRates)) throw new Error("fiscalRates must be an array");
  if (!Array.isArray(rawFees)) throw new Error("fiscalRateFees must be an array");

  const unresolvedMappings: string[] = [];
  const fiscalRates = rawRates.map((value, index) => {
    const row = record(value, `fiscalRates[${index}]`);
    const sourceId = requiredString(row.Id, `fiscalRates[${index}].Id`);
    const fiscalScheduleId = requiredString(
        row.idn_fiscal_sch__c,
        `fiscalRates[${index}].idn_fiscal_sch__c`,
    );
    const rateTypeCode = requiredString(
        row.cde_rate_type__c,
        `fiscalRates[${index}].cde_rate_type__c`,
    );
    const ageGroupCode = requiredString(
      row.cde_age_group__c,
      `fiscalRates[${index}].cde_age_group__c`,
    );
    const careUnitCode = requiredString(
      row.cde_care_unit__c,
      `fiscalRates[${index}].cde_care_unit__c`,
    );
    const paidTier = PAID_TIER_BY_CARE_UNIT[careUnitCode];
    if (!paidTier) unresolvedMappings.push(`fiscalRates[${index}].cde_care_unit__c=${careUnitCode}`);
    return {
      sourceId,
      fiscalScheduleId,
      rateTypeCode,
      rateTypeLabel: mappedLabel(
        row.cde_rate_type__c,
        RATE_TYPE_LABELS,
        `fiscalRates[${index}].cde_rate_type__c`,
      ),
      ageGroupCode,
      ageGroupLabel: mappedLabel(
        row.cde_age_group__c,
        AGE_GROUP_LABELS,
        `fiscalRates[${index}].cde_age_group__c`,
      ),
      careUnitCode,
      careUnitLabel: mappedLabel(
        row.cde_care_unit__c,
        CARE_UNIT_LABELS,
        `fiscalRates[${index}].cde_care_unit__c`,
      ),
      ...(paidTier ? { paidTier } : {}),
      countyAmount: money(row.amt_cty__c, `fiscalRates[${index}].amt_cty__c`),
      fiscalAgreementAmount: money(
        row.amt_fa__c,
        `fiscalRates[${index}].amt_fa__c`,
      ),
      providerAmount: money(row.amt_provr__c, `fiscalRates[${index}].amt_provr__c`),
    };
  });

  const fiscalRateFees = rawFees.map((value, index) => {
    const row = record(value, `fiscalRateFees[${index}]`);
    const fee: NormalizedFiscalRateFee = {
      sourceId: requiredString(row.Id, `fiscalRateFees[${index}].Id`),
      fiscalScheduleId: requiredString(
        row.IDN_FISCAL_SCH__c,
        `fiscalRateFees[${index}].IDN_FISCAL_SCH__c`,
      ),
    };
    const activityFrequency = optionalString(row.CDE_ACT_FREQ__c);
    const registrationFrequency = optionalString(row.CDE_REG_FREQ__c);
    const transportationFrequency = optionalString(row.CDE_TRANS_FREQ__c);
    const activityMonths = optionalString(row.TXT_ACT_MONTH__c);
    const registrationMonths = optionalString(row.TXT_REG_MONTH__c);
    const transportationMonths = optionalString(row.TXT_TRANS_MONTH__c);
    const activityCountyAmount = optionalMoney(
      row.AMT_ACT_CTY__c,
      `fiscalRateFees[${index}].AMT_ACT_CTY__c`,
    );
    const activityFiscalAgreementAmount = optionalMoney(
      row.AMT_ACT_FA__c,
      `fiscalRateFees[${index}].AMT_ACT_FA__c`,
    );
    const activityProviderAmount = optionalMoney(
      row.AMT_ACT_PROVR__c,
      `fiscalRateFees[${index}].AMT_ACT_PROVR__c`,
    );
    const registrationCountyAmount = optionalMoney(
      row.AMT_REG_CTY__c,
      `fiscalRateFees[${index}].AMT_REG_CTY__c`,
    );
    const registrationFiscalAgreementAmount = optionalMoney(
      row.AMT_REG_FA__c,
      `fiscalRateFees[${index}].AMT_REG_FA__c`,
    );
    const registrationProviderAmount = optionalMoney(
      row.AMT_REG_PROVR__c,
      `fiscalRateFees[${index}].AMT_REG_PROVR__c`,
    );
    const transportationCountyAmount = optionalMoney(
      row.AMT_TRANS_CTY__c,
      `fiscalRateFees[${index}].AMT_TRANS_CTY__c`,
    );
    const transportationFiscalAgreementAmount = optionalMoney(
      row.AMT_TRANS_FA__c,
      `fiscalRateFees[${index}].AMT_TRANS_FA__c`,
    );
    const transportationProviderAmount = optionalMoney(
      row.AMT_TRANS_PROVR__c,
      `fiscalRateFees[${index}].AMT_TRANS_PROVR__c`,
    );
    if (activityFrequency) fee.activityFrequency = activityFrequency;
    if (registrationFrequency) fee.registrationFrequency = registrationFrequency;
    if (transportationFrequency) fee.transportationFrequency = transportationFrequency;
    if (activityMonths) fee.activityMonths = activityMonths;
    if (registrationMonths) fee.registrationMonths = registrationMonths;
    if (transportationMonths) fee.transportationMonths = transportationMonths;
    if (activityCountyAmount !== undefined) fee.activityCountyAmount = activityCountyAmount;
    if (activityFiscalAgreementAmount !== undefined) {
      fee.activityFiscalAgreementAmount = activityFiscalAgreementAmount;
    }
    if (activityProviderAmount !== undefined) fee.activityProviderAmount = activityProviderAmount;
    if (registrationCountyAmount !== undefined) fee.registrationCountyAmount = registrationCountyAmount;
    if (registrationFiscalAgreementAmount !== undefined) {
      fee.registrationFiscalAgreementAmount = registrationFiscalAgreementAmount;
    }
    if (registrationProviderAmount !== undefined) fee.registrationProviderAmount = registrationProviderAmount;
    if (transportationCountyAmount !== undefined) fee.transportationCountyAmount = transportationCountyAmount;
    if (transportationFiscalAgreementAmount !== undefined) {
      fee.transportationFiscalAgreementAmount = transportationFiscalAgreementAmount;
    }
    if (transportationProviderAmount !== undefined) fee.transportationProviderAmount = transportationProviderAmount;
    return fee;
  });

  return {
    fiscalRates,
    fiscalRateFees,
    // Derive mapping status from unresolved mappings because callers trust this field.
    canonicalMappingStatus: unresolvedMappings.length > 0 ? "PARTIAL_CODE_MAPPING" : "COMPLETE_CODE_MAPPING",
    unresolvedMappings,
    r00393Values: { ...R00393_VALUES },
  };
}
// ===== end fiscal-rate-normalizer.ts =====

// ===== begin payout-date.ts =====
// The +12-day formula is a last-resort fallback; prefer the Apex release date.
export const PAYOUT_DATE_OFFSET_DAYS = 12;

// Engine payment.payout_date is authoritative when available; use this for call sites without a full engine run.
export function computePayoutDate(serviceEndDateIso: string): string {
  const parsed = new Date(`${serviceEndDateIso}T00:00:00Z`);
  parsed.setUTCDate(parsed.getUTCDate() + PAYOUT_DATE_OFFSET_DAYS);
  return parsed.toISOString().slice(0, 10);
}
// ===== end payout-date.ts =====