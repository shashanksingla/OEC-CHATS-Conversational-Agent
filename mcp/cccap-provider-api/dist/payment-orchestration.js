import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { normalizePaymentSourceBundle } from "./payment-canonical-adapter.js";
import { normalizeProviderContext } from "./provider-context.js";
const execFileAsync = promisify(execFile);
const paymentEvaluatorPath = fileURLToPath(new URL("../../../skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py", import.meta.url));
function record(value, label) {
    if (!value || typeof value !== "object" || Array.isArray(value))
        throw new Error(`${label} is unavailable`);
    return value;
}
function array(value, label) {
    if (!Array.isArray(value))
        throw new Error(`${label} is unavailable`);
    return value;
}
function first(value, label) {
    const rows = array(value, label);
    if (rows.length === 0)
        throw new Error(`${label} is unavailable`);
    return record(rows[0], label);
}
export async function getPaymentAnalysis(client, scope, view = "STATUS", asOfDate = new Date().toISOString().slice(0, 10), filters = {}) {
    const initialization = view === "STATUS"
        ? record(await client.initialize(scope), "Provider context")
        : undefined;
    const servicePeriodData = await client.getServicePeriods(view === "NEXT_PAYOUT" ? { paymentAfter: "TODAY", limitOne: true } :
        view === "CURRENT_WEEK_FORECAST" ? { dateOn: "TODAY", limitOne: true } :
            { ...scope, limitOne: true, dateFilter: scope.dateFilter });
    const servicePeriod = first(record(servicePeriodData, "Service periods").servicePeriods, "Service period");
    const serviceBeginDate = servicePeriod.serviceBeginDate;
    const serviceEndDate = servicePeriod.serviceEndDate;
    if (typeof serviceBeginDate !== "string" || typeof serviceEndDate !== "string")
        throw new Error("Service period dates are unavailable");
    const sourceScope = view === "STATUS" ? scope : { dateFilter: "DATE_RANGE", dateFrom: serviceBeginDate, dateTo: serviceEndDate };
    const providerContext = initialization ?? record(await client.initialize(sourceScope), "Provider context");
    const { countyIds } = normalizeProviderContext(providerContext);
    const scheduleData = await client.getSchedules(sourceScope);
    const scheduleRows = array(record(scheduleData, "Schedules").schedules, "Schedules");
    const scheduleRateTypes = Object.fromEntries(scheduleRows.flatMap((value) => {
        const schedule = record(value, "Schedule");
        const authorizationKeys = [
            schedule.Authorization__c,
            schedule.authorization_id,
            schedule.authorization_name,
            schedule.CI_Authorization_Id__c,
        ].filter((key) => (typeof key === "string" && key.length > 0) || typeof key === "number");
        const rateType = schedule.rate_type_code ?? schedule.CI_Authorization_Rate_Type__c;
        return typeof rateType === "string"
            ? authorizationKeys.map((authorizationKey) => [String(authorizationKey), rateType])
            : [];
    }));
    const authorizationNames = [...new Set(scheduleRows.flatMap((value) => {
            const schedule = record(value, "Schedule");
            const authorizationName = schedule.authorization_name ?? schedule.CI_Authorization_Id__c;
            return typeof authorizationName === "string" || typeof authorizationName === "number"
                ? [String(authorizationName)]
                : [];
        }))];
    const [authorizationData, countyData, fiscalData, holidayData, paymentData] = await Promise.all([
        client.getAuthorizations({
            ...sourceScope,
            countyIds,
            ...(authorizationNames.length > 0 ? { authNames: authorizationNames } : {}),
            careDate: serviceBeginDate,
            scheduleRateTypes,
        }),
        client.getCountyData({ ...sourceScope, countyIds }),
        client.getFiscalRates(sourceScope),
        client.getHolidayList(sourceScope), client.getPaymentHistory(sourceScope),
    ]);
    const { payload, servicePeriod: canonicalServicePeriod } = normalizePaymentSourceBundle({
        initialization: providerContext,
        servicePeriod,
        authorizationData,
        countyData,
        scheduleData,
        fiscalData,
        holidayData,
        paymentData,
        mode: view === "STATUS" ? "STATUS" : "FORECAST",
        asOfDate,
    });
    const childNames = filters.childNames ? new Set(filters.childNames) : undefined;
    const authNames = filters.authNames ? new Set(filters.authNames) : undefined;
    if (childNames || authNames) {
        const normalizedAuthorizations = array(record(authorizationData, "Authorizations").normalizedAuthorizations, "Normalized authorizations");
        const authorizationIdsByName = new Set(normalizedAuthorizations.flatMap((value) => {
            const row = record(value, "Normalized authorization");
            const authorization = record(row.authorization, "Authorization");
            const references = [authorization.Id, authorization.Name, authorization.IDN_EXTNL__c]
                .filter((reference) => typeof reference === "string" && reference.length > 0);
            return authNames && references.some((reference) => authNames.has(reference)) && typeof authorization.Id === "string"
                ? [authorization.Id]
                : [];
        }));
        const selectedAuthorizations = new Set(payload.attendance_days
            .filter((day) => {
            const record = day;
            return typeof record.authorization_id === "string"
                && (!authNames || authorizationIdsByName.has(record.authorization_id))
                && (!childNames || (typeof record.child_name === "string" && childNames.has(record.child_name)));
        })
            .map((day) => day.authorization_id));
        payload.attendance_days = payload.attendance_days.filter((day) => {
            const record = day;
            return typeof record.authorization_id === "string" && selectedAuthorizations.has(record.authorization_id) && (!childNames || (typeof record.child_name === "string" && childNames.has(record.child_name)));
        });
        payload.fiscal_rates = payload.fiscal_rates.filter((rate) => typeof rate.authorization_id === "string" && selectedAuthorizations.has(rate.authorization_id));
        payload.existing_sub_payments = payload.existing_sub_payments.filter((payment) => {
            const record = payment;
            return typeof record.authorization_id === "string" && selectedAuthorizations.has(record.authorization_id);
        });
    }
    const directory = await mkdtemp(join(tmpdir(), "carepay-payment-"));
    const inputPath = join(directory, "payment.json");
    try {
        await writeFile(inputPath, JSON.stringify(payload), "utf8");
        const { stdout } = await execFileAsync("uv", ["run", paymentEvaluatorPath, inputPath], { windowsHide: true });
        const evaluated = JSON.parse(stdout);
        if (evaluated.status !== "ok" || !evaluated.result)
            throw new Error(evaluated.error || "Payment evaluation failed");
        const result = evaluated.result;
        const attendance = record(result.attendance, "Evaluated attendance");
        const allDays = Array.isArray(attendance.days) ? attendance.days : [];
        const showDetail = filters.detailPage !== undefined || filters.detailPageSize !== undefined;
        const detailPage = filters.detailPage ?? 1;
        const detailPageSize = filters.detailPageSize ?? 25;
        const detailStart = (detailPage - 1) * detailPageSize;
        const pagedAttendance = {
            ...attendance,
            days: showDetail ? allDays.slice(detailStart, detailStart + detailPageSize) : [],
        };
        return {
            ...result,
            attendance: pagedAttendance,
            detailPagination: {
                page: showDetail ? detailPage : 0,
                pageSize: showDetail ? detailPageSize : 0,
                totalRows: allDays.length,
                hasMore: showDetail ? detailStart + detailPageSize < allDays.length : allDays.length > 0,
            },
            scope: sourceScope,
            paymentView: view,
            servicePeriod: canonicalServicePeriod,
            sourceRetrievedAt: new Date().toISOString(),
        };
    }
    finally {
        await rm(directory, { recursive: true, force: true });
    }
}
