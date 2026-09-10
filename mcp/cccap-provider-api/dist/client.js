import { normalizeFiscalRateResponse } from "./fiscal-rate-normalizer.js";
import { selectFiscalScheduleForAuthorization, } from "./authorization-fiscal-schedule-matcher.js";
export class CccapClient {
    targetOrg;
    providerUserId;
    requestApex;
    providerSalesforceIds = new Set();
    providerExternalNames = new Set();
    countyIds = new Set();
    countyNameById = new Map();
    fiscalScheduleIds = new Set();
    fiscalSchedules = [];
    readCache = new Map();
    readCacheAt = new Map();
    readCacheTtlMs = 15 * 60 * 1000;
    readCacheMaxEntries = 100;
    constructor(options) {
        this.targetOrg = options.targetOrg;
        this.providerUserId = options.providerUserId;
        this.requestApex = options.requestApex;
    }
    async initialize(scope = {}) {
        const data = await this.cachedCall("getProviderData", {
            ...scope,
            userId: this.providerUserId,
        });
        const result = this.requireRecord(data, "getProviderData.data");
        this.providerSalesforceIds = this.extractIds(result.providers, "Id");
        this.providerExternalNames = this.extractIds(result.providers, "Name");
        this.countyIds = this.extractIds(result.fiscalAgreements, "CDE_COUNTY__c");
        this.countyNameById = this.extractCountyNames(result.fiscalAgreements);
        this.fiscalScheduleIds = this.extractNestedIds(result.fiscalAgreements, "Rate_Schedules__r", "IDN_EXTNL__c");
        this.fiscalSchedules = this.extractFiscalSchedules(result.fiscalAgreements);
        if (this.providerSalesforceIds.size === 0 || this.providerExternalNames.size === 0) {
            throw new Error("No provider identifiers were returned for the configured user");
        }
        if (this.countyIds.size === 0) {
            throw new Error("No active county agreements were returned for the provider");
        }
        return data;
    }
    async getCases(input) {
        return this.cachedCall("getCaseData", {
            ...input,
            countyIds: this.allowedCounties(input.countyIds),
            providerIds: this.allowedCaseProviderNames(),
        });
    }
    async getAuthorizations(input) {
        const { scheduleRateTypes, careDate: _careDate, ...request } = input;
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
                    fiscalScheduleMatch: selectFiscalScheduleForAuthorization(authorization, this.fiscalSchedules, careDate, scheduleRateType),
                };
            }),
        };
    }
    async getCountyData(input) {
        return this.cachedCall("getCountyData", {
            ...input,
            countyIds: this.allowedCounties(input.countyIds),
        });
    }
    async getSchedules(input) {
        return this.cachedCall("getSchedules", {
            ...input,
            providerIds: this.allowedProviders(),
        });
    }
    async getFiscalRates(input = {}) {
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
    async getPaymentHistory(input) {
        return this.cachedCall("getPaymentHistory", {
            ...input,
            providerIds: this.allowedProviders(),
        });
    }
    async getServicePeriods(input) {
        // Service periods are not provider- or county-scoped source data, but every
        // read must still occur only after the authenticated provider identity has
        // been resolved and validated by initialize(); otherwise an unauthorized or
        // misconfigured session could pull data before scope is ever established.
        this.requireInitialized();
        return this.cachedCall("getServicePeriods", input);
    }
    async getHolidayList(input = {}) {
        this.requireInitialized();
        return this.cachedCall("getHolidayList", input);
    }
    async getVacantSlots(input = {}) {
        return this.cachedCall("getVacantSlots", {
            ...input,
            providerIds: this.allowedProviders(),
            countyIds: this.allowedCounties(input.countyIds),
        });
    }
    allowedProviders() {
        this.requireInitialized();
        return [...this.providerSalesforceIds];
    }
    /**
     * Resolves a county ID to its provider-facing name, using the mapping
     * captured at initialize() time. Returns undefined (never the raw ID)
     * when no verified name is available for that ID.
     */
    getCountyName(countyId) {
        if (typeof countyId !== "string" || countyId.length === 0)
            return undefined;
        return this.countyNameById.get(countyId);
    }
    clearReadCache() {
        this.readCache.clear();
        this.readCacheAt.clear();
    }
    extractCountyNames(value) {
        const countyNameById = new Map();
        if (!Array.isArray(value))
            return countyNameById;
        for (const agreementValue of value) {
            const agreement = this.requireRecord(agreementValue, "fiscalAgreements");
            const countyId = agreement.CDE_COUNTY__c;
            const county = agreement.CDE_COUNTY__r;
            const countyName = county && typeof county === "object" && !Array.isArray(county)
                ? county.Name
                : undefined;
            if (typeof countyId === "string" && countyId && typeof countyName === "string" && countyName) {
                countyNameById.set(countyId, countyName);
            }
        }
        return countyNameById;
    }
    extractFiscalSchedules(value) {
        if (!Array.isArray(value))
            return [];
        return value.flatMap((agreementValue) => {
            const agreement = this.requireRecord(agreementValue, "fiscalAgreements");
            const countyId = agreement.CDE_COUNTY__c;
            const scheduleRelationship = agreement.Rate_Schedules__r;
            if (scheduleRelationship === undefined || scheduleRelationship === null)
                return [];
            const schedules = this.requireRecord(scheduleRelationship, "Rate_Schedules__r").records;
            if (typeof countyId !== "string" || !Array.isArray(schedules))
                return [];
            return schedules.flatMap((scheduleValue) => {
                const schedule = this.requireRecord(scheduleValue, "Rate_Schedules__r.records");
                if (typeof schedule.Id !== "string"
                    || typeof schedule.IDN_EXTNL__c !== "string"
                    || typeof schedule.CDE_RATE_TYPE__c !== "string"
                    || typeof schedule.DTE_BEGIN_EFFV__c !== "string")
                    return [];
                const candidate = {
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
    allowedCaseProviderNames() {
        this.requireInitialized();
        return [...this.providerExternalNames];
    }
    allowedCounties(requested) {
        this.requireInitialized();
        if (!requested || requested.length === 0) {
            return [...this.countyIds];
        }
        const disallowed = requested.filter((id) => !this.countyIds.has(id));
        if (disallowed.length > 0) {
            throw new Error(`County IDs are outside the authenticated provider scope: ${disallowed.join(", ")}`);
        }
        return requested;
    }
    requireInitialized() {
        if (this.providerSalesforceIds.size === 0 ||
            this.providerExternalNames.size === 0 ||
            this.countyIds.size === 0) {
            throw new Error("Initialize provider context before requesting scoped data");
        }
    }
    async call(action, body) {
        const envelope = await this.requestApex(this.targetOrg, action, body);
        if (!envelope.isSuccess) {
            throw new Error(envelope.errorMessage || `Salesforce ${action} returned an unsuccessful response`);
        }
        return envelope.data;
    }
    async cachedCall(action, body) {
        const key = `${action}:${JSON.stringify(body)}`;
        const cachedAt = this.readCacheAt.get(key);
        if (cachedAt !== undefined && Date.now() - cachedAt < this.readCacheTtlMs && this.readCache.has(key)) {
            return this.readCache.get(key);
        }
        const data = await this.call(action, body);
        this.readCache.set(key, data);
        this.readCacheAt.set(key, Date.now());
        while (this.readCache.size > this.readCacheMaxEntries) {
            const oldest = [...this.readCacheAt.entries()].sort((left, right) => left[1] - right[1])[0];
            if (!oldest)
                break;
            this.readCache.delete(oldest[0]);
            this.readCacheAt.delete(oldest[0]);
        }
        return data;
    }
    requireRecord(value, label) {
        if (!value || typeof value !== "object" || Array.isArray(value)) {
            throw new Error(`${label} must be an object`);
        }
        return value;
    }
    extractIds(value, field) {
        if (!Array.isArray(value)) {
            return new Set();
        }
        return new Set(value
            .map((item) => item && typeof item === "object"
            ? item[field]
            : undefined)
            .filter((id) => typeof id === "string" && id.length > 0));
    }
    extractNestedIds(value, relationship, field) {
        if (!Array.isArray(value)) {
            return new Set();
        }
        const ids = new Set();
        for (const item of value) {
            const record = item && typeof item === "object" ? item : undefined;
            const related = record?.[relationship];
            const records = related && typeof related === "object" && !Array.isArray(related)
                ? related.records
                : undefined;
            if (Array.isArray(records)) {
                for (const child of records) {
                    if (child && typeof child === "object") {
                        const id = child[field];
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
