import { McpServer } from "@modelcontextprotocol/server";
import { authorizationSchema, caseSchema, countySchema, dateScopeSchema, schedulesSchema, servicePeriodSchema, } from "./schemas.js";
const readOnlyAnnotations = {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: true,
};
function result(data) {
    return {
        content: [{ type: "text", text: JSON.stringify(data) }],
    };
}
function toolError(error) {
    return {
        isError: true,
        content: [
            {
                type: "text",
                text: error instanceof Error ? error.message : "Unexpected CCCAP API error",
            },
        ],
    };
}
async function execute(operation) {
    try {
        return result(await operation());
    }
    catch (error) {
        return toolError(error);
    }
}
export function createServer(client) {
    const server = new McpServer({
        name: "cccap-provider-api",
        version: "1.0.0",
    });
    server.registerTool("cccap_initialize_provider", {
        title: "Initialize CCCAP Provider",
        description: "Start here. Resolve the configured provider user to one authorized facility, active provider IDs, fiscal agreements, counties, rate schedules, and closures for the requested date scope. The server injects the provider user ID; never ask the model or provider to supply it.",
        inputSchema: dateScopeSchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.initialize(input)));
    server.registerTool("cccap_get_cases", {
        title: "Get CCCAP Cases and Children",
        description: "After initialization, retrieve active cases and related children for the authenticated provider. Omit countyIds for all authorized counties or pass only county IDs returned by initialization.",
        inputSchema: caseSchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.getCases(input)));
    server.registerTool("cccap_get_authorizations", {
        title: "Get CCCAP Authorizations",
        description: "After initialization, retrieve active child authorizations for the authenticated provider. Filter by case IDs, authorized counties, or authorization names only when needed for the provider's question.",
        inputSchema: authorizationSchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.getAuthorizations(input)));
    server.registerTool("cccap_get_county_rate_plans", {
        title: "Get CCCAP County Rate Plans",
        description: "After initialization, retrieve effective county rate plans, absence-day limits, holiday policy, and drop-in limits for authorized provider counties. Use this before any absence-risk calculation.",
        inputSchema: countySchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.getCountyData(input)));
    server.registerTool("cccap_get_service_periods", {
        title: "Get CCCAP Service Periods",
        description: "Retrieve stored or computed service periods and payment processing/release dates. Use dateOn TODAY for the current service period, paymentAfter TODAY with limitOne for the next payout, or a dateFilter for a range.",
        inputSchema: servicePeriodSchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.getServicePeriods(input)));
    server.registerTool("cccap_get_schedules", {
        title: "Get CCCAP Schedules and Attendance",
        description: "After initialization, retrieve schedules and check-in/check-out attendance transactions for the authenticated provider and date range. Use authorization names only to narrow an already authorized provider scope.",
        inputSchema: schedulesSchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.getSchedules(input)));
    server.registerTool("cccap_get_holidays", {
        title: "Get CCCAP Holidays",
        description: "Retrieve holiday and observed-holiday dates, optionally within a date scope. Combine only with an effective county rate plan that allows paid holidays.",
        inputSchema: dateScopeSchema,
        annotations: readOnlyAnnotations,
    }, async (input) => execute(() => client.getHolidayList(input)));
    return server;
}
