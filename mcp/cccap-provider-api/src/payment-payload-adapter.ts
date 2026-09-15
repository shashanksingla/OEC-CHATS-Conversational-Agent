import {
  normalizePaymentStatus,
  type CanonicalExistingSubPayment,
  type CanonicalVacantSlotSchedule,
  type CanonicalServicePeriod,
  type RecordValue,
} from "./payment-schema.js";
import { normalizeQualityTier } from "./provider-policy.js";

export {
  normalizePaymentStatus,
  type CanonicalExistingSubPayment,
  type CanonicalServicePeriod,
} from "./payment-schema.js";

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
  // paymentReleaseDate is the real Apex-sourced release date (or its own
  // ISO-week fallback) from ServicePeriodService.cls - undefined only for a
  // synthetic CUSTOM_RANGE period with no matching T_SERV_PERIOD__c record.
  // payout_date stays optional precisely for that case.
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
  parent_confirmation: "CONFIRMED" | "PENDING";
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
  // The rate type actually scheduled for THIS specific day - an
  // authorization's schedule days can each carry a different rate type
  // across one period (live-confirmed: 31/31/31/1/91/43/37 across one
  // week under the same authorization). Threaded through so the Python
  // evaluator can select the fiscal rate matching this exact day instead
  // of collapsing every day of an authorization onto one rate type.
  rate_type_code?: string;
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
  return authorizations.find((authorization) => references.some((reference) =>
    authorization.Id === reference
      || authorization.Name === reference
      || authorization.IDN_EXTNL__c === reference,
  ));
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
    // A schedule whose authorization reference cannot be matched to any
    // authorization record in this response (e.g. its CI_Authorization_Id__c
    // is absent and its raw Authorization__c lookup does not correspond to
    // any authorization id/name/external-id returned for this scope) cannot
    // have its age band, encumbrance status, or client DOB derived at all -
    // there is nothing here to guess. Previously this fell through to
    // childIsUnder36Months with an undefined client and threw "child date
    // of birth is missing", which was misleading (the DOB is not actually
    // missing from the source - the authorization link for THIS schedule
    // row never resolved) and crashed enrichment for every other schedule
    // in the same call via the enclosing forEach. Skip only this
    // unresolved row; normalizePaymentSourceBundle excludes it from the
    // payload downstream instead of fabricating enrichment for it.
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
    result[authorizationId] = {
      age_band: ageBand,
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
    const parentConfirmation = isFutureForecast || (isForecast && schedule.parent_confirmation === undefined)
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

// Kept despite the ART/copay removal: this feeds evaluate_attendance's
// history-based absence-limit and drop-in-limit counting (_history_count)
// and paid-holiday-on-paired-date detection (_holiday_paid_on_paired_date)
// in provider_risk_payment_engine.py via payload.get("fee_history") -
// both explicitly kept features, unrelated to the removed ART fee-offset
// calculation that used to also read this same array's activity_paid/
// registration_paid/transportation_paid/slot_paid fields.
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

export { normalizeQualityTier } from "./provider-policy.js";

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
  authorizationAgeGroupCodes: Record<string, string[]> = {},
  // An authorization's own schedule rows can each use a DIFFERENT rate
  // type across one service period (live-confirmed: one authorization's 7
  // days in a week used rate types 31/31/31/1/91/43/37 - overnight,
  // regular, out-of-county, evening, weekend all under the same
  // authorization). A single rate-type string here would keep only the
  // fiscal rate rows for ONE of those rate types and silently exclude
  // every day whose rate type differs - the confirmed root cause of the
  // recurring "rate unavailable" exclusions. Every rate type list must be
  // checked for membership, not equality against one value.
  authorizationRateTypeCodes: Record<string, string[]> = {},
): RecordValue[] {
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
        const ageGroups = authorizationAgeGroupCodes[authorizationId];
        return (!rateTypeCodes || rateTypeCodes.length === 0 || rateTypeCodes.includes(String(rate.rateTypeCode)))
          && (!ageGroups || rate.ageGroupCode === undefined
          || ageGroups.includes(String(rate.ageGroupCode)));
      })
      .map((authorizationId) => ({
        authorization_id: authorizationId,
        paid_tier: paidTier,
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