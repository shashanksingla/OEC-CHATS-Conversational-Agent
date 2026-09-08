import { normalizeQualityTier } from "./provider-policy.js";

type RecordValue = Record<string, unknown>;

function record(value: unknown, label: string): RecordValue {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} is unavailable`);
  }
  return value as RecordValue;
}

export interface CanonicalProviderContext {
  facilityName: string | undefined;
  qualityTier: number;
  countyIds: string[];
  countyIdByName: Record<string, string>;
}

export function normalizeProviderContext(value: unknown): CanonicalProviderContext {
  const initialization = record(value, "Provider context");
  const providers = initialization.providers;
  if (!Array.isArray(providers) || providers.length === 0) {
    throw new Error("Provider facility is unavailable");
  }
  const provider = record(providers[0], "Provider facility");
  const agreements = initialization.fiscalAgreements;
  if (!Array.isArray(agreements)) {
    throw new Error("Provider county agreements are unavailable");
  }

  const countyIds = [...new Set(agreements
    .map((value) => record(value, "Provider county agreement").CDE_COUNTY__c)
    .filter((value): value is string => typeof value === "string" && value.length > 0))];
  if (countyIds.length === 0) {
    throw new Error("Provider county agreements are unavailable");
  }

  const countyIdByName: Record<string, string> = {};
  for (const value of agreements) {
    const agreement = record(value, "Provider county agreement");
    const countyId = agreement.CDE_COUNTY__c;
    const county = agreement.CDE_COUNTY__r;
    const countyName = county && typeof county === "object" && !Array.isArray(county)
      ? (county as RecordValue).Name
      : undefined;
    if (typeof countyId === "string" && countyId && typeof countyName === "string" && countyName) {
      countyIdByName[countyName] = countyId;
    }
  }

  return {
    facilityName: typeof provider.NAM_FACILITY__c === "string" ? provider.NAM_FACILITY__c : undefined,
    qualityTier: normalizeQualityTier(provider.TXT_CHATS_RATING__c, provider.CDE_TYPE_PROVR__c),
    countyIds,
    countyIdByName,
  };
}
