import {
  normalizePaymentStatus,
  type CanonicalExistingSubPayment,
  type CanonicalPaymentFeeSchedule,
  type CanonicalVacantSlotSchedule,
  type CanonicalServicePeriod,
  type RecordValue,
} from "./payment-schema.js";
import { normalizeQualityTier } from "./provider-policy.js";

export {
  normalizePaymentStatus,
  type CanonicalExistingSubPayment,
  type CanonicalPaymentFeeSchedule,
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
  authorization_copays?: RecordValue[];
  fee_schedules?: CanonicalPaymentFeeSchedule[];
  fee_history?: RecordValue[];
  vacant_slot_schedules?: CanonicalVacantSlotSchedule[];
}

export function normalizeAuthorizationCopays(
  value: unknown,
  authorizations: RecordValue[] = [],
): RecordValue[] {
  if (!Array.isArray(value)) throw new Error("authorization copays must be an array");
  return value.map((item, index) => {
    const row = asRecord(item, `authorizationCopays[${index}]`);
    const authorizationId = resolveAuthorizationId(
      row.idn_auth__c,
      authorizations,
      `authorizationCopays[${index}].idn_auth__c`,
    );
    const amount = row.amt_copay_auth__c;
    if (typeof amount !== "number" || !Number.isFinite(amount) || amount < 0) {
      throw new Error(`authorizationCopays[${index}].amt_copay_auth__c must be non-negative`);
    }
    return {
      authorization_id: authorizationId,
      amount,
      effective_start: row.dte_begin_effv__c,
      effective_end: row.dte_end_effv__c,
    };
  });
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
      activity_paid: optionalFiniteNumber(detail.amt_act_paid__c, `payment detail[${index}].amt_act_paid__c`) ?? 0,
      registration_paid: optionalFiniteNumber(detail.amt_reg_paid__c, `payment detail[${index}].amt_reg_paid__c`) ?? 0,
      transportation_paid: optionalFiniteNumber(detail.amt_trans_paid__c, `payment detail[${index}].amt_trans_paid__c`) ?? 0,
      slot_paid: optionalFiniteNumber(detail.amt_slot_paid__c, `payment detail[${index}].amt_slot_paid__c`) ?? 0,
    };
    if (detail.cde_type_info_addntl__c !== undefined) normalized.info_code = detail.cde_type_info_addntl__c;
    const expectedHours = optionalNonNegativeNumber(detail.cnt_unit_care_exptd__c, `payment detail[${index}].cnt_unit_care_exptd__c`);
    const actualHours = optionalNonNegativeNumber(detail.cnt_unit_care_actual__c, `payment detail[${index}].cnt_unit_care_actual__c`);
    if (expectedHours !== undefined) normalized.expected_hours = expectedHours;
    if (actualHours !== undefined) normalized.actual_hours = actualHours;
    if (detail.ind_adjmt__c !== undefined) normalized.adjusted = detail.ind_adjmt__c === true;
    if (detail.ind_recovery__c !== undefined) normalized.recovery = detail.ind_recovery__c === true;
    if (detail.ind_record_delete_logcl__c !== undefined) {
      normalized.deleted = detail.ind_record_delete_logcl__c === true;
    }
    return normalized;
  });
}

export function normalizePaymentFeeSchedules(
  normalizedFiscalRates: unknown,
  normalizedFiscalRateFees: unknown,
  slotContracts: unknown,
  authorizationMatches: Record<string, string>,
): CanonicalPaymentFeeSchedule[] {
  const rates = requiredRecords(normalizedFiscalRates, "normalized fiscal rates");
  const fees = requiredRecords(normalizedFiscalRateFees, "normalized fiscal rate fees");
  if (!Array.isArray(slotContracts)) throw new Error("slot contracts must be an array");
  return slotContracts
    .filter((item) => {
      const slot = asRecord(item, "slot contract");
      return slot.IDN_AUTH__c !== null && slot.IDN_AUTH__c !== undefined;
    })
    .flatMap((item, index) => {
    const slot = asRecord(item, `slotContracts[${index}]`);
    const authorizationId = requiredString(slot.IDN_AUTH__c, `slotContracts[${index}].IDN_AUTH__c`);
    const fiscalScheduleId = authorizationMatches[authorizationId];
    if (!fiscalScheduleId) return [];
    const rateTypeCode = requiredString(slot.CDE_RATE_TYPE__c, `slotContracts[${index}].CDE_RATE_TYPE__c`);
    const careUnitCode = requiredString(slot.CDE_CARE_UNIT__c, `slotContracts[${index}].CDE_CARE_UNIT__c`);
    const careLevelCode = requiredString(slot.CDE_CARE_LEVEL__c, `slotContracts[${index}].CDE_CARE_LEVEL__c`);
    const matchingRates = rates.filter((rate) =>
      rate.fiscalScheduleId === fiscalScheduleId
      && rate.rateTypeCode === rateTypeCode
      && rate.careUnitCode === careUnitCode
      && rate.ageGroupCode === careLevelCode,
    );
    if (matchingRates.length !== 1) return [];
    const rate = matchingRates[0];
    if (!rate) return [];
    const matchingFees = fees.filter((fee) => fee.fiscalScheduleId === fiscalScheduleId);
    if (matchingFees.length > 1) throw new Error(`fiscal schedule ${fiscalScheduleId} has ambiguous fee rows`);
    const fee = matchingFees[0];
    const result: CanonicalPaymentFeeSchedule = {
      authorization_id: authorizationId,
      fiscal_schedule_id: fiscalScheduleId,
      slot_contract_id: requiredString(slot.Id, `slotContracts[${index}].Id`),
      care_level: requiredString(slot.CDE_CARE_LEVEL__c, `slotContracts[${index}].CDE_CARE_LEVEL__c`),
      effective_start: requiredString(slot.DTE_BEGIN_SLOT__c, `slotContracts[${index}].DTE_BEGIN_SLOT__c`),
      slot_rate_amount: Number(rate.fiscalAgreementAmount),
    };
    const effectiveEnd = slot.DTE_END_SLOT__c;
    if (effectiveEnd !== undefined && effectiveEnd !== null) {
      result.effective_end = requiredString(effectiveEnd, `slotContracts[${index}].DTE_END_SLOT__c`);
    }
    const daysOfMonth = optionalNonNegativeNumber(slot.CNT_DAYS_OF_MONTH__c, `slotContracts[${index}].CNT_DAYS_OF_MONTH__c`);
    const daysOfWeek = slot.CNT_DAYS_OF_WEEK__c;
    if (daysOfMonth !== undefined) result.days_of_month = daysOfMonth;
    if (typeof daysOfWeek === "string" && daysOfWeek) result.days_of_week = daysOfWeek;
    else if (typeof daysOfWeek === "number" && Number.isFinite(daysOfWeek) && daysOfWeek >= 0) result.days_of_week = daysOfWeek;
    if (fee) {
      const amountFields: Array<[string, keyof CanonicalPaymentFeeSchedule]> = [
        ["activityFiscalAgreementAmount", "activity_amount"],
        ["registrationFiscalAgreementAmount", "registration_amount"],
        ["transportationFiscalAgreementAmount", "transportation_amount"],
      ];
      amountFields.forEach(([source, target]) => {
        if (fee[source] !== undefined) (result as unknown as RecordValue)[target] = Number(fee[source]);
      });
      const capFields: Array<[string, keyof CanonicalPaymentFeeSchedule]> = [
        ["activityFiscalAgreementAmount", "activity_provider_cap"],
        ["activityCountyAmount", "activity_county_cap"],
        ["registrationFiscalAgreementAmount", "registration_provider_cap"],
        ["registrationCountyAmount", "registration_county_cap"],
        ["transportationFiscalAgreementAmount", "transportation_provider_cap"],
        ["transportationCountyAmount", "transportation_county_cap"],
      ];
      capFields.forEach(([source, target]) => {
        if (fee[source] !== undefined) (result as unknown as RecordValue)[target] = Number(fee[source]);
      });
      const scheduleFields: Array<[string, keyof CanonicalPaymentFeeSchedule]> = [
        ["activityFrequency", "activity_frequency"],
        ["activityMonths", "activity_months"],
        ["registrationFrequency", "registration_frequency"],
        ["registrationMonths", "registration_months"],
        ["transportationFrequency", "transportation_frequency"],
        ["transportationMonths", "transportation_months"],
      ];
      scheduleFields.forEach(([source, target]) => {
        if (fee[source] !== undefined) (result as unknown as RecordValue)[target] = fee[source];
      });
    }
      return [result];
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
  feeSchedules?: CanonicalPaymentFeeSchedule[];
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
  const enrichedFeeSchedules = input.feeSchedules?.map((schedule) => {
    const authorization = authorizationById.get(schedule.authorization_id);
    const countyPolicy = countyPolicyById.get(String(authorization?.CDE_COUNTY__c ?? ""));
    const result = { ...schedule } as CanonicalPaymentFeeSchedule;
    if (typeof authorization?.DTE_BEGIN_EFFV_AUTH__c === "string") {
      result.authorization_effective_start = authorization.DTE_BEGIN_EFFV_AUTH__c;
    }
    if (typeof authorization?.DTE_END_EFFV_AUTH__c === "string") {
      result.authorization_effective_end = authorization.DTE_END_EFFV_AUTH__c;
    }
    const authorizationStatus = authorization?.Authorization_Status__c
      ?? authorization?.authorization_status
      ?? authorization?.expr0;
    if (authorizationStatus !== undefined && authorizationStatus !== null) {
      result.authorization_status = String(authorizationStatus);
    }
    const authorizationFields: Array<[string, keyof CanonicalPaymentFeeSchedule]> = [
      ["AMT_ACTV_AUTH__c", "activity_authorization_amount"],
      ["AMT_RGSTR_AUTH__c", "registration_authorization_amount"],
      ["AMT_TRANSP_AUTH__c", "transportation_authorization_amount"],
    ];
    authorizationFields.forEach(([source, target]) => {
      if (authorization?.[source] !== undefined && authorization?.[source] !== null) {
        (result as unknown as RecordValue)[target] = Number(authorization[source]);
      }
    });
    const countyFields: Array<[string, keyof CanonicalPaymentFeeSchedule]> = [
      ["activityArtCap", "activity_county_cap"],
      ["registrationArtCap", "registration_county_cap"],
      ["transportationArtCap", "transportation_county_cap"],
    ];
    countyFields.forEach(([source, target]) => {
      if (countyPolicy?.[source] !== undefined && countyPolicy?.[source] !== null) {
        (result as unknown as RecordValue)[target] = Number(countyPolicy[source]);
      }
    });
    return result;
  });
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
    ...(enrichedFeeSchedules ? { fee_schedules: enrichedFeeSchedules } : {}),
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
  authorizationRateTypeCodes: Record<string, string> = {},
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
        const rateTypeCode = authorizationRateTypeCodes[authorizationId];
        const ageGroups = authorizationAgeGroupCodes[authorizationId];
        return (!rateTypeCode || rate.rateTypeCode === rateTypeCode)
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