// Merged: client.ts (scoped Salesforce read API) + sf-cli.ts (Salesforce CLI transport).
// sf-cli.ts's only import was `ApiEnvelope` from client.ts - now internal to this file.
import { normalizeFiscalRateResponse, selectFiscalScheduleForAuthorization, } from "../payment/payment-engine.js";
import { spawn } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
export class CccapClient {
    targetOrg;
    providerUserId;
    requestApex;
    onFiscalMatchUnresolved;
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
        this.onFiscalMatchUnresolved = options.onFiscalMatchUnresolved;
    }
    async initialize(scope = {}) {
        const data = await this.cachedCall("getProviderData", {
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
        const { scheduleRateTypes, scheduleCareDates, careDate: _careDate, ...request } = input;
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
                const scheduleRateTypeList = scheduleRateTypes?.[String(authorization.Id)]
                    ?? scheduleRateTypes?.[String(authorization.Name)]
                    ?? scheduleRateTypes?.[String(authorization.IDN_EXTNL__c)];
                const scheduleCareDate = scheduleCareDates?.[String(authorization.Id)]
                    ?? scheduleCareDates?.[String(authorization.Name)]
                    ?? scheduleCareDates?.[String(authorization.IDN_EXTNL__c)];
                const resolvedCareDate = scheduleCareDate ?? careDate;
                const fiscalScheduleMatch = selectFiscalScheduleForAuthorization(authorization, this.fiscalSchedules, resolvedCareDate, scheduleRateTypeList);
                // Only the rate-type-specific failure - county matched, but no candidate
                // schedule carried the requested rate type. This is the exact "rate not yet
                // available for these dates" root cause; other UNRESOLVED reasons (county/date/
                // ambiguous match) are not logged here.
                if (fiscalScheduleMatch.reason === "NO_MATCH_RATE_TYPE" && typeof authorization.Id === "string") {
                    const requestedRateTypes = (scheduleRateTypeList ?? []).filter((value) => value.length > 0);
                    const countyId = authorization.CDE_COUNTY__c;
                    const candidateSchedules = this.fiscalSchedules
                        .filter((schedule) => schedule.countyId === countyId)
                        .map((schedule) => ({ scheduleId: schedule.id, rateTypeCode: schedule.rateTypeCode }));
                    this.onFiscalMatchUnresolved?.({
                        authorizationId: authorization.Id,
                        careDate: resolvedCareDate,
                        requestedRateTypes,
                        candidateSchedules,
                    });
                }
                return {
                    authorization,
                    ...(scheduleRateTypeList && scheduleRateTypeList.length > 0 ? { rateTypeCode: scheduleRateTypeList } : {}),
                    fiscalScheduleMatch,
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
const CLI_TIMEOUT_MS = 60_000;
const MAX_CAPTURED_OUTPUT_BYTES = 5_000_000;
function truncate(value) {
    return value.length > MAX_CAPTURED_OUTPUT_BYTES
        ? `${value.slice(0, MAX_CAPTURED_OUTPUT_BYTES)}\n[truncated: output exceeded ${MAX_CAPTURED_OUTPUT_BYTES} bytes]`
        : value;
}
const runSfCommand = (command, args, input) => new Promise((resolve, reject) => {
    const executable = process.platform === "win32" ? process.env.ComSpec || "cmd.exe" : command;
    const commandArgs = process.platform === "win32"
        ? ["/d", "/s", "/c", command, ...args]
        : args;
    const child = spawn(executable, commandArgs, {
        stdio: ["pipe", "pipe", "pipe"],
        windowsHide: true,
        timeout: CLI_TIMEOUT_MS,
        killSignal: "SIGKILL",
    });
    let stdout = "";
    let stderr = "";
    let timedOut = false;
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
        if (stdout.length < MAX_CAPTURED_OUTPUT_BYTES)
            stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
        if (stderr.length < MAX_CAPTURED_OUTPUT_BYTES)
            stderr += chunk;
    });
    child.on("error", (error) => {
        reject(new Error(`Failed to start Salesforce CLI command: ${error.message}`));
    });
    child.on("close", (exitCode, signal) => {
        if (signal === "SIGKILL" || signal === "SIGTERM")
            timedOut = true;
        resolve({
            stdout: truncate(stdout),
            stderr: timedOut
                ? `${truncate(stderr)}\n[Salesforce CLI command timed out after ${CLI_TIMEOUT_MS}ms]`
                : truncate(stderr),
            exitCode: timedOut ? 124 : exitCode ?? 1,
        });
    });
    child.stdin.end(input);
});
const allowedActions = new Set([
    "getProviderData",
    "getCaseData",
    "getAuthData",
    "getCountyData",
    "getServicePeriods",
    "getSchedules",
    "getHolidayList",
    "getFiscalRates",
    "getPaymentHistory",
    "getVacantSlots",
]);
export async function resolveAuthenticatedUserId(targetOrg, run = runSfCommand) {
    try {
        const display = await run("sf", ["org", "display", "--target-org", targetOrg, "--json"], "");
        const displayResult = JSON.parse(display.stdout);
        const username = displayResult.result?.username;
        if (display.exitCode !== 0 || displayResult.status !== 0 || !username) {
            throw new Error("Invalid Salesforce org display response");
        }
        const escapedUsername = username.replaceAll("'", "\\'");
        const user = await run("sf", [
            "data",
            "query",
            "--target-org",
            targetOrg,
            "--query",
            `SELECT Id FROM User WHERE Username = '${escapedUsername}' LIMIT 1`,
            "--json",
        ], "");
        const userResult = JSON.parse(user.stdout);
        const userId = userResult.result?.records?.[0]?.Id;
        if (user.exitCode !== 0 ||
            userResult.status !== 0 ||
            userResult.result?.totalSize !== 1 ||
            !userId) {
            throw new Error("Invalid Salesforce user query response");
        }
        return userId;
    }
    catch {
        throw new Error(`Unable to resolve the authenticated Salesforce user for target org ${targetOrg}`);
    }
}
export async function requestApexViaSf(targetOrg, action, body, run = runSfCommand) {
    if (!allowedActions.has(action)) {
        throw new Error(`Unsupported CCCAP action: ${action}`);
    }
    const directory = await mkdtemp(join(tmpdir(), "cccap-apex-"));
    const bodyPath = join(directory, "request.json");
    await writeFile(bodyPath, JSON.stringify(body), "utf8");
    try {
        const { stdout, exitCode } = await run("sf", [
            "api",
            "request",
            "rest",
            `/services/apexrest/CccapPortalApi/v1/${action}`,
            "--target-org",
            targetOrg,
            "--method",
            "POST",
            "--body",
            `@${bodyPath}`,
            "--json",
        ], "");
        const result = JSON.parse(stdout);
        const statusCode = result.result?.statusCode;
        const responseBody = result.result?.body;
        if (exitCode !== 0 ||
            result.status !== 0 ||
            !statusCode ||
            statusCode < 200 ||
            statusCode >= 300 ||
            !responseBody) {
            const body = typeof responseBody === "string"
                ? responseBody
                : responseBody && typeof responseBody === "object"
                    ? JSON.stringify(responseBody)
                    : undefined;
            throw new Error(body || "Invalid Salesforce CLI response");
        }
        return typeof responseBody === "string"
            ? JSON.parse(responseBody)
            : responseBody;
    }
    catch (error) {
        if (error instanceof Error) {
            try {
                const response = JSON.parse(error.message);
                if (typeof response.errorMessage === "string" && response.errorMessage.length > 0) {
                    throw new Error(`Salesforce Apex ${action} failed: ${response.errorMessage}`);
                }
            }
            catch (parseError) {
                if (parseError instanceof Error && parseError.message.startsWith("Salesforce Apex")) {
                    throw parseError;
                }
            }
        }
        throw new Error(`Salesforce Apex request failed for ${action}`);
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
// ===== end sf-cli.ts =====
