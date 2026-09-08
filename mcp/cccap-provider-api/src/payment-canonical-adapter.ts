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
import { type RecordValue } from "./payment-schema.js";

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

export interface PaymentSourceBundle {
  initialization: unknown;
  servicePeriod: unknown;
  authorizationData: unknown;
  countyData: unknown;
  scheduleData: unknown;
  fiscalData: unknown;
  holidayData: unknown;
  paymentData: unknown;
  mode: "STATUS" | "FORECAST";
  asOfDate: string;
}

export function normalizePaymentSourceBundle(
  sources: PaymentSourceBundle,
): { payload: CanonicalPaymentPayload; servicePeriod: ReturnType<typeof normalizeServicePeriod> } {
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
  const paymentHistory = sources.paymentData;
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
    feeHistory: normalizePaymentFeeHistory(paymentHistory, authorizationRecords),
    mode: sources.mode,
    asOfDate: sources.asOfDate,
  });
  payload.authorization_copays = normalizeAuthorizationCopays(
    authorizationData.authorizationCopays,
    authorizationRecords,
  );
  return { payload, servicePeriod };
}
