import {
  buildCanonicalPaymentPayload,
  deriveAttendanceEnrichment,
  deriveFiscalAgeGroupCodes,
  normalizeAuthorizationCopays,
  normalizeFiscalRatesForPayment,
  normalizePaymentFeeHistory,
  normalizePaymentFeeSchedules,
  normalizeServicePeriod,
  type CanonicalPaymentPayload,
} from "./payment-payload-adapter.js";
import { normalizeQualityTier } from "./provider-policy.js";
import { normalizeProviderContext } from "./provider-context.js";
import { normalizeScheduleAttendance } from "./schedule-normalizer.js";
import {
  type CanonicalVacantSlotSchedule,
  type RecordValue,
} from "./payment-schema.js";

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

function requiredString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) throw new Error(`${label} is required`);
  return value;
}

function requiredRecords(value: unknown, label: string): RecordValue[] {
  if (!Array.isArray(value) || value.length === 0) throw new Error(`${label} must contain at least one record`);
  return value.map((item, index) => record(item, `${label}[${index}]`));
}

function optionalNonNegativeNumber(value: unknown, label: string): number | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    throw new Error(`${label} must be a non-negative number`);
  }
  return value;
}

function containsRateType(value: string, requested: string): boolean {
  return value
    .split(/[,;|\s]+/)
    .map((token) => token.trim())
    .filter((token) => token.length > 0)
    .includes(requested);
}

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
  const authorizationRateTypeCodes: Record<string, string> = {};
  const authorizationAgeGroupCodes: Record<string, string[]> = {};
  const authorizations = normalizedAuthorizations.map((value, index) => {
    const row = record(value, `Normalized authorization[${index}]`);
    const authorization = record(row.authorization, `Authorization[${index}]`);
    const match = record(row.fiscalScheduleMatch, `Fiscal schedule match[${index}]`);
    if (
      typeof authorization.Id !== "string" ||
      match.status !== "MATCHED" ||
      typeof match.fiscalScheduleId !== "string"
    ) {
      const authorizationKey = [
        ["id", authorization.Id],
        ["name", authorization.Name],
        ["external", authorization.IDN_EXTNL__c],
        ["county", authorization.CDE_COUNTY__c],
      ]
        .filter(([, value]) => typeof value === "string" && value.length > 0)
        .map(([key, value]) => `${key}=${value}`)
        .join(", ");
      const reason = typeof match.reason === "string" ? match.reason : "UNKNOWN";
      throw new Error(
        `Authorization fiscal schedule mapping failed for row ${index}`
        + ` (${authorizationKey || "no authorization identity"}; reason=${reason})`,
      );
    }
    authorizationMatches[authorization.Id] = match.fiscalScheduleId;
    if (typeof row.rateTypeCode === "string" && row.rateTypeCode.length > 0) {
      authorizationRateTypeCodes[authorization.Id] = row.rateTypeCode;
    }
    const client = authorization.IDN_CLIENT__r;
    const ageGroupCodes = client && typeof client === "object" && !Array.isArray(client)
      ? deriveFiscalAgeGroupCodes(
          (client as RecordValue).DTE_DOB__c,
          servicePeriod.start_date,
        )
      : undefined;
    if (ageGroupCodes) authorizationAgeGroupCodes[authorization.Id] = ageGroupCodes;
    return {
      id: authorization.Id,
      county_id: authorization.CDE_COUNTY__c,
      quality_tier: providerTier,
      drop_in_limit: authorization.Number_of_Drop_in_Days__c,
    };
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
    };
  });

  const normalizedFiscal = record(
    record(sources.fiscalData, "Fiscal rates").normalizedFiscalRates,
    "Normalized fiscal rates",
  );
  const fiscalRates = normalizeFiscalRatesForPayment(
    normalizedFiscal.fiscalRates,
    authorizationMatches,
    authorizationAgeGroupCodes,
    authorizationRateTypeCodes,
  );
  const feeSchedules = normalizePaymentFeeSchedules(
    normalizedFiscal.fiscalRates,
    normalizedFiscal.fiscalRateFees,
    authorizationData.slotContracts,
    authorizationMatches,
  );
  const vacantSlotData = record(sources.vacantSlotData ?? { vacantSlots: [] }, "Vacant slots");
  const paymentHistory = sources.paymentData;
  let vacantSlotMappingGaps = 0;
  const payload = buildCanonicalPaymentPayload({
    servicePeriod,
    schedules: schedulesWithCountyNames,
    attendanceEnrichmentByAuthorization: enrichment,
    authorizations,
    countyPolicies,
    fiscalRates,
    paymentHistory,
    authorizationRecords,
    feeSchedules,
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
    feeHistory: normalizePaymentFeeHistory(paymentHistory, authorizationRecords),
    mode: sources.mode,
    asOfDate: sources.asOfDate,
  });
  payload.authorization_copays = normalizeAuthorizationCopays(
    authorizationData.authorizationCopays,
    authorizationRecords,
  );
  return { payload, servicePeriod, vacantSlotMappingGaps };
}

// A vacant slot that is genuinely occupied (IDN_AUTH__c set) is correctly
// excluded by normalizeVacantSlotSchedules and is not a mapping gap. Any
// other vacant slot that normalizeVacantSlotSchedules could not price
// (no matching rate schedule) is a silent-drop risk: it contributes $0 to
// the vacant-slot fee instead of surfacing as a data-quality gap. Track that
// count here so callers can report it rather than let it vanish untraced.
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