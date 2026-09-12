type RecordValue = Record<string, unknown>;

function asRecord(value: unknown): RecordValue | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as RecordValue)
    : undefined;
}

function transactionType(recordType: unknown, sourceType: unknown): number | undefined {
  if (typeof sourceType === "number" && Number.isFinite(sourceType)) return sourceType;
  if (typeof sourceType === "string" && /^\d+$/.test(sourceType)) return Number(sourceType);
  if (recordType === "Check-In") return 1;
  if (recordType === "Check-Out") return 2;
  return undefined;
}

function confirmationStatus(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const normalized = value.trim().toUpperCase();
  return normalized || undefined;
}

function directParentConfirmation(value: unknown): "CONFIRMED" | "PENDING" | "REJECTED" | undefined {
  const normalized = confirmationStatus(value);
  if (!normalized) return undefined;
  if (["CONFIRMED", "APPROVED", "PARENT_APPROVED", "COMPLETE"].includes(normalized)) return "CONFIRMED";
  if (["PENDING", "PARENT_PENDING", "UNCONFIRMED"].includes(normalized)) return "PENDING";
  if (["REJECTED", "PARENT_REJECTED", "DENIED"].includes(normalized)) return "REJECTED";
  return undefined;
}

// Salesforce boolean fields can arrive as an actual boolean or as the
// literal string "true"/"false" depending on the API layer. `Boolean("false")`
// is `true` for any non-empty string, so a plain `Boolean(...)` coercion here
// would silently invert a "false" string value; normalize known string forms
// explicitly instead.
function booleanValue(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") return value.trim().toLowerCase() === "true";
  return Boolean(value);
}

function authorizationStatus(value: unknown): string | undefined {
  const normalized = String(value ?? "").trim().toUpperCase();
  if (normalized === "2" || normalized === "AUTHORIZED") return "APPROVED";
  if (normalized === "4" || normalized === "TERMINATED") return "TERMINATED";
  return undefined;
}

function nestedCountyName(schedule: RecordValue): string | undefined {
  const authorization = asRecord(schedule.Authorization__r);
  const county = asRecord(authorization?.County__r);
  const countyName = county?.County_Name__c;
  return typeof countyName === "string" && countyName ? countyName : undefined;
}

export function normalizeScheduleAttendance(
  schedules: unknown[],
  defaultCountyId?: string,
  providerQualityTier?: number,
  authorizationData?: unknown,
): {
  schedules: RecordValue[];
  transactions: RecordValue[];
} {
  const transactions: RecordValue[] = [];
  const normalizedSchedules: RecordValue[] = [];
  const authorizationLimits = new Map<string, number>();
  const authorizationResponse = asRecord(authorizationData);
  const authorizationRows = Array.isArray(authorizationResponse?.authorizations)
    ? authorizationResponse.authorizations
    : Array.isArray(authorizationResponse?.normalizedAuthorizations)
      ? authorizationResponse.normalizedAuthorizations
      : [];
  for (const value of authorizationRows) {
    const authorization = asRecord(value);
    const id = authorization?.Id ?? authorization?.IDN_EXTNL__c;
    const limit = authorization?.Number_of_Drop_in_Days__c;
    if ((typeof id === "string" || typeof id === "number") && typeof limit === "number" && limit >= 0) {
      authorizationLimits.set(String(id), limit);
    }
  }
  for (const value of schedules) {
    const schedule = asRecord(value);
    if (!schedule) continue;
    const scheduleId = schedule.Id ?? schedule.Schedule__c;
    const workDate = schedule.CI_Authorization_Date__c ?? schedule.work_date;
    const rawAttendance = asRecord(schedule.Attendance__r);
    const records = rawAttendance?.records;
    const linkedRecords = Array.isArray(records) ? records : [];
    const scheduleTransactions = linkedRecords
      .map(asRecord)
      .filter((record): record is RecordValue => Boolean(record))
      .map((record) => ({
        transaction_id: record.CI_Transaction_ID__c ?? record.Id,
        reporting_authorization_id: record.Reporting_Authorization_Id__c,
        schedule_id: record.Schedule__c ?? scheduleId,
        authorization_id: record.Reporting_Authorization_Id__c ?? schedule.CI_Authorization_Id__c,
        client_id: record.CI_Client_Id__c,
        work_date: record.CI_Attendance_Date__c ?? record.CI_Begin_Date__c ?? workDate,
        begin_date: record.CI_Begin_Date__c,
        end_date: record.CI_End_Date__c,
        transaction_time: record.CI_Transaction_Time__c,
        attended_hours: record.CI_Attendance_Hours__c,
        type: transactionType(record.Record_Type_Name__c, record.CI_Transaction_Type__c),
        result: record.CI_Transaction_Result__c,
        status: confirmationStatus(record.Status__c),
        sub_type: record.Sub_Type__c,
        denial_reason: record.Denial_Status__c,
        is_historical: booleanValue(record.Previous_Transaction__c),
        provider_id: record.CI_Provider_ID__c,
        entered_by: record.Creation_Source__c === "Provider" ? "PROVIDER" : record.Creation_Source__c,
      }));
    transactions.push(...scheduleTransactions);
    const timestamps = scheduleTransactions
      .map((transaction) => transaction.transaction_time)
      .filter((timestamp): timestamp is string => typeof timestamp === "string")
      .sort();
    const parentStatuses = new Set(
      scheduleTransactions
        .map((transaction) => transaction.status)
        .filter((status): status is string => typeof status === "string"),
    );
    const scheduleParentConfirmation = directParentConfirmation(
      schedule.parent_confirmation
      ?? schedule.parentConfirmation
      ?? schedule.Parent_Confirmation__c
      ?? schedule.Parent_Confirmation_Status__c
      ?? schedule.parent_confirmation_status,
    );
    if (scheduleParentConfirmation) {
      parentStatuses.add(
        scheduleParentConfirmation === "CONFIRMED"
          ? "PARENT_APPROVED"
          : `PARENT_${scheduleParentConfirmation}`,
      );
    }
    const authorization = asRecord(schedule.Authorization__r);
    const authorizationReference = schedule.CI_Authorization_Id__c
      ?? schedule.Authorization__c
      ?? schedule.IDN_AUTH__c
      ?? schedule.Authorization_Id__c
      ?? authorization?.Id;
    const authorizationRecord = authorizationRows.find((value) => {
      const wrapper = asRecord(value);
      const candidate = asRecord(wrapper?.authorization) ?? wrapper;
      const candidateReferences = [candidate?.Id, candidate?.IDN_EXTNL__c, candidate?.Name]
        .filter((reference): reference is string | number =>
          (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
        )
        .map(String);
      const scheduleReferences = [authorizationReference, schedule.CI_Authorization_Id__c]
        .filter((reference): reference is string | number =>
          (typeof reference === "string" && reference.length > 0) || typeof reference === "number",
        )
        .map(String);
      return scheduleReferences.some((reference) => candidateReferences.includes(reference));
    });
    const authorizationWrapper = authorizationRecord ? asRecord(authorizationRecord) : undefined;
    const matchedAuthorization = asRecord(authorizationWrapper?.authorization) ?? authorizationWrapper;
    const authorizationId = matchedAuthorization?.Id ?? authorizationReference;
    const authorizationStatusValue = matchedAuthorization && (
      matchedAuthorization.Authorization_Status__c
      ?? matchedAuthorization.authorization_status
      ?? matchedAuthorization.expr0
    );
    const normalizedSchedule: RecordValue = {
      schedule_id: scheduleId,
      authorization_id:
        authorizationId,
      authorization_name:
        matchedAuthorization?.Name ??
        authorization?.Name ??
        schedule.authorization_name ??
        schedule.Authorization_Name__c,
      child_name: schedule.Contact_Name__c,
      county_id: schedule.County__c
        ?? schedule.county_id
        ?? matchedAuthorization?.CDE_COUNTY__c
        ?? defaultCountyId,
      county_name: nestedCountyName(schedule),
      authorization_drop_in_limit: authorizationLimits.get(String(
        schedule.Authorization__c ??
        schedule.IDN_AUTH__c ??
        schedule.Authorization_Id__c ??
        authorization?.Id ?? "",
      )),
      quality_tier: providerQualityTier,
      rate_type_code: schedule.CI_Authorization_Rate_Type__c,
      work_date: workDate,
      schedule_type: schedule.Type__c ?? schedule.schedule_type,
      is_deleted: false,
      denial_reason: undefined,
      // Do not default an absent/unknown authorization status to APPROVED.
      // A missing status must fail closed (undefined) so downstream evaluators
      // treat the day as care-not-offered/blocked rather than silently approved.
      auth_status: authorizationStatus(authorizationStatusValue),
      auth_begin_date: undefined,
      auth_end_date: undefined,
      ci_authorization_hours: schedule.CI_Authorization_Hours__c,
      raw_hours: schedule.Hours__c,
      care_not_offered: schedule.Care_Not_Offered__c ?? schedule.care_not_offered,
      check_in_count: schedule.Check_In_Count__c,
      check_out_count: schedule.Check_Out_Count__c,
      attended_flag: scheduleTransactions.length > 0,
      actual_start_ts: timestamps[0],
      actual_end_ts: timestamps[timestamps.length - 1],
    };
    if (parentStatuses.has("PARENT_PENDING")) {
      normalizedSchedule.parent_confirmation = "PENDING";
      normalizedSchedule.absence_parent_approved = booleanValue(
        schedule.absence_parent_approved
        ?? schedule.absenceParentApproved
        ?? schedule.Absence_Parent_Approved__c,
      );
    } else if (parentStatuses.has("PARENT_APPROVED")) {
      normalizedSchedule.parent_confirmation = "CONFIRMED";
      normalizedSchedule.absence_parent_approved = true;
    } else if (parentStatuses.has("PARENT_REJECTED")) {
      normalizedSchedule.parent_confirmation = "REJECTED";
      normalizedSchedule.absence_parent_approved = false;
    }
    normalizedSchedules.push(normalizedSchedule);
  }
  return { schedules: normalizedSchedules, transactions };
}