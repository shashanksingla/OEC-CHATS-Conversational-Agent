export class CccapClient {
    targetOrg;
    providerUserId;
    requestApex;
    providerSalesforceIds = new Set();
    providerExternalNames = new Set();
    countyIds = new Set();
    fiscalScheduleIds = new Set();
    readCache = new Map();
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
        this.fiscalScheduleIds = this.extractNestedIds(result.fiscalAgreements, "Rate_Schedules__r", "IDN_EXTNL__c");
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
        return this.cachedCall("getAuthData", {
            ...input,
            countyIds: this.allowedCounties(input.countyIds),
            providerIds: this.allowedProviders(),
        });
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
        return this.cachedCall("getFiscalRates", {
            ...input,
            providerIds: this.allowedProviders(),
            fiscalScheduleIds: [...this.fiscalScheduleIds],
        });
    }
    async getServicePeriods(input) {
        return this.cachedCall("getServicePeriods", input);
    }
    async getHolidayList(input = {}) {
        return this.cachedCall("getHolidayList", input);
    }
    allowedProviders() {
        this.requireInitialized();
        return [...this.providerSalesforceIds];
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
        if (this.readCache.has(key)) {
            return this.readCache.get(key);
        }
        const data = await this.call(action, body);
        this.readCache.set(key, data);
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
