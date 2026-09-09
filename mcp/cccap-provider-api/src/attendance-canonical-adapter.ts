type RecordValue = Record<string, unknown>;

function asRecord(value: unknown): RecordValue | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as RecordValue)
    : undefined;
}

function nestedCountyName(schedule: RecordValue): string | undefined {
  const authorization = asRecord(schedule.Authorization__r);
  const county = asRecord(authorization?.County__r);
  const countyName = county?.County_Name__c;
  return typeof countyName === "string" && countyName ? countyName : undefined;
}

// Schedule authorization identifiers may arrive as numbers from the DECL source.
export function authorizationKey(value: unknown): string | undefined {
  if (typeof value === "string" && value) return value;
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  return undefined;
}

export function isSalesforceId(value: string): boolean {
  return /^[A-Za-z0-9]{15}(?:[A-Za-z0-9]{3})?$/.test(value);
}

export function addDefaultCountyToSchedules(
  schedules: unknown[],
  defaultCountyId?: string,
): unknown[] {
  if (!defaultCountyId) return schedules;
  return schedules.map((value) => {
    const schedule = asRecord(value);
    if (!schedule) return value;
    const sourceCounty = schedule.countyId ?? schedule.County__c ?? schedule.CDE_COUNTY__c;
    return typeof sourceCounty === "string" && sourceCounty
      ? schedule
      : { ...schedule, countyId: defaultCountyId };
  });
}

export function addCanonicalCountyIdToSchedules(schedules: unknown[]): unknown[] {
  return schedules.map((value) => {
    const schedule = asRecord(value);
    if (!schedule || (typeof schedule.countyId === "string" && schedule.countyId)) {
      return value;
    }
    const countyId = schedule.County__c ?? schedule.CDE_COUNTY__c;
    return typeof countyId === "string" && countyId
      ? { ...schedule, countyId }
      : value;
  });
}

export function addProviderQualityTierToSchedules(
  schedules: unknown[],
  providerQualityTier: number,
): unknown[] {
  return schedules.map((value) => {
    const schedule = asRecord(value);
    return schedule ? { ...schedule, qualityTier: providerQualityTier } : value;
  });
}

export function addAuthorizationNamesToSchedules(
  schedules: unknown[],
  authorizationData: unknown,
): unknown[] {
  const response = asRecord(authorizationData);
  const authorizations = Array.isArray(response?.authorizations)
    ? response.authorizations
    : [];
  const namesById = new Map<string, string>();
  for (const value of authorizations) {
    const authorization = asRecord(value);
    const id = authorizationKey(authorization?.Id);
    const externalId = authorizationKey(authorization?.IDN_EXTNL__c);
    const name = authorization?.Name;
    if (id && typeof name === "string" && name) namesById.set(id, name);
    if (externalId && typeof name === "string" && name) namesById.set(externalId, name);
    if (typeof name === "string" && name) namesById.set(name, name);
  }
  return schedules.map((value) => {
    const schedule = asRecord(value);
    if (!schedule) return value;
    const existingName = schedule.authorization_name ?? schedule.Authorization_Name__c;
    if (typeof existingName === "string" && existingName) return schedule;
    const authorizationId = authorizationKey(
      schedule.CI_Authorization_Id__c ??
      schedule.Authorization__c ??
      schedule.IDN_AUTH__c ??
      schedule.Authorization_Id__c,
    );
    const name = authorizationId ? namesById.get(authorizationId) : undefined;
    return name ? { ...schedule, authorization_name: name } : schedule;
  });
}

// DECL county identifiers are joined to main-org county IDs by verified county name.
export function addNestedCountyIdToSchedules(
  schedules: unknown[],
  countyIdByName: Record<string, string>,
): unknown[] {
  return schedules.map((value) => {
    const schedule = asRecord(value);
    if (!schedule) return value;
    const existingCounty = schedule.countyId ?? schedule.County__c ?? schedule.CDE_COUNTY__c;
    if (typeof existingCounty === "string" && existingCounty) return schedule;
    const countyName = nestedCountyName(schedule);
    const countyId = countyName ? countyIdByName[countyName] : undefined;
    return countyId ? { ...schedule, countyId } : schedule;
  });
}

export function normalizeAttendanceRiskSchedules(input: {
  schedules: unknown[];
  authorizationData?: unknown;
  countyIdByName: Record<string, string>;
  defaultCountyId?: string;
  providerQualityTier: number;
}): unknown[] {
  const withAuthorizationNames = addAuthorizationNamesToSchedules(
    input.schedules,
    input.authorizationData,
  );
  const withCounties = addNestedCountyIdToSchedules(
    withAuthorizationNames,
    input.countyIdByName,
  );
  return addProviderQualityTierToSchedules(
    addCanonicalCountyIdToSchedules(
      addDefaultCountyToSchedules(withCounties, input.defaultCountyId),
    ),
    input.providerQualityTier,
  );
}
