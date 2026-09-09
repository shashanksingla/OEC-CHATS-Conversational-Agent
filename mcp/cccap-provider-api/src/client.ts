import { normalizeFiscalRateResponse } from "./fiscal-rate-normalizer.js";
import {
  selectFiscalScheduleForAuthorization,
  type FiscalScheduleCandidate,
} from "./authorization-fiscal-schedule-matcher.js";

export interface ApiEnvelope {
  isSuccess: boolean;
  errorMessage?: string;
  data?: unknown;
}

export type RequestApex = (
  targetOrg: string,
  action: string,
  body: Record<string, unknown>,
) => Promise<ApiEnvelope>;

export type DateFilter =
  | "TODAY"
  | "THIS_MONTH"
  | "LAST_MONTH"
  | "LAST_N_MONTHS"
  | "LAST_N_DAYS"
  | "DATE_RANGE";

export interface DateScope {
  dateFilter?: DateFilter | undefined;
  periodCount?: number | undefined;
  dateFrom?: string | undefined;
  dateTo?: string | undefined;
}

export interface ServicePeriodScope extends DateScope {
  dateOn?: "TODAY" | undefined;
  paymentAfter?: "TODAY" | undefined;
  limitOne?: boolean | undefined;
}

type JsonRecord = Record<string, unknown>;

interface ClientOptions {
  targetOrg: string;
  providerUserId: string;
  requestApex: RequestApex;
}

export class CccapClient {
  private readonly targetOrg: string;
  private readonly providerUserId: string;
  private readonly requestApex: RequestApex;
  private providerSalesforceIds = new Set<string>();
  private providerExternalNames = new Set<string>();
  private countyIds = new Set<string>();
  private fiscalScheduleIds = new Set<string>();
  private fiscalSchedules: FiscalScheduleCandidate[] = [];
  private readonly readCache = new Map<string, unknown>();

  public constructor(options: ClientOptions) {
    this.targetOrg = options.targetOrg;
    this.providerUserId = options.providerUserId;
    this.requestApex = options.requestApex;
  }

  public async initialize(scope: DateScope = {}): Promise<unknown> {
    const data = await this.cachedCall("getProviderData", {
      ...scope,
      userId: this.providerUserId,
    });
    const result = this.requireRecord(data, "getProviderData.data");
    this.providerSalesforceIds = this.extractIds(result.providers, "Id");
    this.providerExternalNames = this.extractIds(result.providers, "Name");
    this.countyIds = this.extractIds(
      result.fiscalAgreements,
      "CDE_COUNTY__c",
    );
    this.fiscalScheduleIds = this.extractNestedIds(
      result.fiscalAgreements,
      "Rate_Schedules__r",
      "IDN_EXTNL__c",
    );
    this.fiscalSchedules = this.extractFiscalSchedules(result.fiscalAgreements);
    if (this.providerSalesforceIds.size === 0 || this.providerExternalNames.size === 0) {
      throw new Error("No provider identifiers were returned for the configured user");
    }
    if (this.countyIds.size === 0) {
      throw new Error("No active county agreements were returned for the provider");
    }
    return data;
  }

  public async getCases(
    input: DateScope & { countyIds?: string[] | undefined },
  ): Promise<unknown> {
    return this.cachedCall("getCaseData", {
      ...input,
      countyIds: this.allowedCounties(input.countyIds),
      providerIds: this.allowedCaseProviderNames(),
    });
  }

  public async getAuthorizations(
    input: DateScope & {
      caseIds?: string[] | undefined;
      countyIds?: string[] | undefined;
      authIds?: string[] | undefined;
      authNames?: string[] | undefined;
      careDate?: string | undefined;
      scheduleRateTypes?: Record<string, string> | undefined;
    },
  ): Promise<unknown> {
    const {
      scheduleRateTypes,
      careDate: _careDate,
      ...request
    } = input;
    const data = await this.cachedCall("getAuthData", {
      ...request,
      countyIds: this.allowedCounties(request.countyIds),
      providerIds: this.allowedProviders(),
    });
    const response = this.requireRecord(data, "getAuthData.data");
    const careDate = input.careDate ?? input.dateFrom ?? new Date().toISOString().slice(0, 10);
    const authorizations = response.authorizations;
    if (!Array.isArray(authorizations)) {
      return { ...response, normalizedAuthorizations: [] };
    }
    return {
      ...response,
      normalizedAuthorizations: authorizations.map((authorization) => {
        const scheduleRateType = scheduleRateTypes?.[String(authorization.Id)]
          ?? scheduleRateTypes?.[String(authorization.Name)]
          ?? scheduleRateTypes?.[String(authorization.IDN_EXTNL__c)];
        return {
          authorization,
          ...(scheduleRateType ? { rateTypeCode: scheduleRateType } : {}),
          fiscalScheduleMatch: selectFiscalScheduleForAuthorization(
          authorization,
          this.fiscalSchedules,
          careDate,
          scheduleRateType,
          ),
        };
      }),
    };
  }

  public async getCountyData(
    input: DateScope & { countyIds?: string[] | undefined },
  ): Promise<unknown> {
    return this.cachedCall("getCountyData", {
      ...input,
      countyIds: this.allowedCounties(input.countyIds),
    });
  }

  public async getSchedules(
    input: DateScope & { authNames?: string[] | undefined },
  ): Promise<unknown> {
    return this.cachedCall("getSchedules", {
      ...input,
      providerIds: this.allowedProviders(),
    });
  }

  public async getFiscalRates(input: DateScope = {}): Promise<unknown> {
    this.requireInitialized();
    if (this.fiscalScheduleIds.size === 0) {
      throw new Error("No authorized fiscal rate schedules were returned for the provider");
    }
    const data = await this.cachedCall("getFiscalRates", {
      ...input,
      providerIds: this.allowedProviders(),
      fiscalScheduleIds: [...this.fiscalScheduleIds],
    });
    const response = this.requireRecord(data, "getFiscalRates.data");
    return {
      ...response,
      normalizedFiscalRates: normalizeFiscalRateResponse(response),
    };
  }

  public async getPaymentHistory(input: DateScope): Promise<unknown> {
    return this.cachedCall("getPaymentHistory", {
      ...input,
      providerIds: this.allowedProviders(),
    });
  }

  public async getServicePeriods(input: ServicePeriodScope): Promise<unknown> {
    return this.cachedCall("getServicePeriods", input as JsonRecord);
  }

  public async getHolidayList(input: DateScope = {}): Promise<unknown> {
    return this.cachedCall("getHolidayList", input as JsonRecord);
  }

  public async getVacantSlots(
    input: DateScope & { countyIds?: string[] | undefined } = {},
  ): Promise<unknown> {
    return this.cachedCall("getVacantSlots", {
      ...input,
      providerIds: this.allowedProviders(),
      countyIds: this.allowedCounties(input.countyIds),
    });
  }

  private allowedProviders(): string[] {
    this.requireInitialized();
    return [...this.providerSalesforceIds];
  }

  private extractFiscalSchedules(value: unknown): FiscalScheduleCandidate[] {
    if (!Array.isArray(value)) return [];
    return value.flatMap((agreementValue) => {
      const agreement = this.requireRecord(agreementValue, "fiscalAgreements");
      const countyId = agreement.CDE_COUNTY__c;
      const scheduleRelationship = agreement.Rate_Schedules__r;
      if (scheduleRelationship === undefined || scheduleRelationship === null) return [];
      const schedules = this.requireRecord(scheduleRelationship, "Rate_Schedules__r").records;
      if (typeof countyId !== "string" || !Array.isArray(schedules)) return [];
      return schedules.flatMap((scheduleValue) => {
        const schedule = this.requireRecord(scheduleValue, "Rate_Schedules__r.records");
        if (
          typeof schedule.Id !== "string"
          || typeof schedule.IDN_EXTNL__c !== "string"
          || typeof schedule.CDE_RATE_TYPE__c !== "string"
          || typeof schedule.DTE_BEGIN_EFFV__c !== "string"
        ) return [];
        const candidate: FiscalScheduleCandidate = {
          id: schedule.Id,
          externalId: schedule.IDN_EXTNL__c,
          countyId,
          rateTypeCode: schedule.CDE_RATE_TYPE__c,
          beginDate: schedule.DTE_BEGIN_EFFV__c,
        };
        if (typeof schedule.DTE_END_EFFV__c === "string") {
          candidate.endDate = schedule.DTE_END_EFFV__c;
        }
        return [candidate];
      });
    });
  }

  private allowedCaseProviderNames(): string[] {
    this.requireInitialized();
    return [...this.providerExternalNames];
  }

  private allowedCounties(requested?: string[]): string[] {
    this.requireInitialized();
    if (!requested || requested.length === 0) {
      return [...this.countyIds];
    }
    const disallowed = requested.filter((id) => !this.countyIds.has(id));
    if (disallowed.length > 0) {
      throw new Error(
        `County IDs are outside the authenticated provider scope: ${disallowed.join(", ")}`,
      );
    }
    return requested;
  }

  private requireInitialized(): void {
    if (
      this.providerSalesforceIds.size === 0 ||
      this.providerExternalNames.size === 0 ||
      this.countyIds.size === 0
    ) {
      throw new Error("Initialize provider context before requesting scoped data");
    }
  }

  private async call(action: string, body: JsonRecord): Promise<unknown> {
    const envelope = await this.requestApex(this.targetOrg, action, body);
    if (!envelope.isSuccess) {
      throw new Error(
        envelope.errorMessage || `Salesforce ${action} returned an unsuccessful response`,
      );
    }
    return envelope.data;
  }

  private async cachedCall(action: string, body: JsonRecord): Promise<unknown> {
    const key = `${action}:${JSON.stringify(body)}`;
    if (this.readCache.has(key)) {
      return this.readCache.get(key);
    }
    const data = await this.call(action, body);
    this.readCache.set(key, data);
    return data;
  }

  private requireRecord(value: unknown, label: string): JsonRecord {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      throw new Error(`${label} must be an object`);
    }
    return value as JsonRecord;
  }

  private extractIds(value: unknown, field: string): Set<string> {
    if (!Array.isArray(value)) {
      return new Set();
    }
    return new Set(
      value
        .map((item) =>
          item && typeof item === "object"
            ? (item as JsonRecord)[field]
            : undefined,
        )
        .filter((id): id is string => typeof id === "string" && id.length > 0),
    );
  }

  private extractNestedIds(value: unknown, relationship: string, field: string): Set<string> {
    if (!Array.isArray(value)) {
      return new Set();
    }
    const ids = new Set<string>();
    for (const item of value) {
      const record = item && typeof item === "object" ? (item as JsonRecord) : undefined;
      const related = record?.[relationship];
      const records =
        related && typeof related === "object" && !Array.isArray(related)
          ? (related as JsonRecord).records
          : undefined;
      if (Array.isArray(records)) {
        for (const child of records) {
          if (child && typeof child === "object") {
            const id = (child as JsonRecord)[field];
            if (typeof id === "string" && id.length > 0) {
              ids.add(id);
            }
          }
        }
      }
    }
    return ids;
  }
}