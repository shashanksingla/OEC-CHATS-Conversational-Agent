export class CccapClient {
    targetOrg;
    providerUserId;
    resolveConnection;
    fetch;
    providerIds = new Set();
    countyIds = new Set();
    constructor(options) {
        this.targetOrg = options.targetOrg;
        this.providerUserId = options.providerUserId;
        this.resolveConnection = options.resolveConnection;
        this.fetch = options.fetch ?? globalThis.fetch;
    }
    async initialize(scope = {}) {
        const data = await this.call("getProviderData", {
            ...scope,
            userId: this.providerUserId,
        });
        const result = this.requireRecord(data, "getProviderData.data");
        this.providerIds = this.extractIds(result.providers, "Id");
        this.countyIds = this.extractIds(result.fiscalAgreements, "CDE_COUNTY__c");
        if (this.providerIds.size === 0) {
            throw new Error("No provider IDs were returned for the configured user");
        }
        if (this.countyIds.size === 0) {
            throw new Error("No active county agreements were returned for the provider");
        }
        return data;
    }
    async getCases(input) {
        return this.call("getCaseData", {
            ...input,
            countyIds: this.allowedCounties(input.countyIds),
            providerIds: this.allowedProviders(),
        });
    }
    async getAuthorizations(input) {
        return this.call("getAuthData", {
            ...input,
            countyIds: this.allowedCounties(input.countyIds),
            providerIds: this.allowedProviders(),
        });
    }
    async getCountyData(input) {
        return this.call("getCountyData", {
            ...input,
            countyIds: this.allowedCounties(input.countyIds),
        });
    }
    async getSchedules(input) {
        return this.call("getSchedules", {
            ...input,
            providerIds: this.allowedProviders(),
        });
    }
    async getServicePeriods(input) {
        return this.call("getServicePeriods", input);
    }
    async getHolidayList(input = {}) {
        return this.call("getHolidayList", input);
    }
    allowedProviders() {
        this.requireInitialized();
        return [...this.providerIds];
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
        if (this.providerIds.size === 0 || this.countyIds.size === 0) {
            throw new Error("Initialize provider context before requesting scoped data");
        }
    }
    async call(action, body) {
        const connection = await this.resolveConnection(this.targetOrg);
        const response = await this.fetch(`${connection.instanceUrl}/services/apexrest/CccapPortalApi/v1/${action}`, {
            method: "POST",
            headers: {
                accept: "application/json",
                authorization: `Bearer ${connection.accessToken}`,
                "content-type": "application/json",
            },
            body: JSON.stringify(body),
        });
        if (!response.ok) {
            throw new Error(`Salesforce ${action} failed with HTTP ${response.status}`);
        }
        const envelope = (await response.json());
        if (!envelope.isSuccess) {
            throw new Error(envelope.errorMessage || `Salesforce ${action} returned an unsuccessful response`);
        }
        return envelope.data;
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
}
