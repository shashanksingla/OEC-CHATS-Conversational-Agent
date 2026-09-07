import { spawn } from "node:child_process";
const runSfCommand = (command, args, input) => new Promise((resolve, reject) => {
    const executable = process.platform === "win32" ? process.env.ComSpec || "cmd.exe" : command;
    const commandArgs = process.platform === "win32"
        ? ["/d", "/s", "/c", command, ...args]
        : args;
    const child = spawn(executable, commandArgs, {
        stdio: ["pipe", "pipe", "pipe"],
        windowsHide: true,
    });
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
        stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
        stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (exitCode) => {
        resolve({ stdout, stderr, exitCode: exitCode ?? 1 });
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
            "-",
            "--json",
        ], JSON.stringify(body));
        const result = JSON.parse(stdout);
        const statusCode = result.result?.statusCode;
        const responseBody = result.result?.body;
        if (exitCode !== 0 ||
            result.status !== 0 ||
            !statusCode ||
            statusCode < 200 ||
            statusCode >= 300 ||
            !responseBody) {
            throw new Error("Invalid Salesforce CLI response");
        }
        return typeof responseBody === "string"
            ? JSON.parse(responseBody)
            : responseBody;
    }
    catch {
        throw new Error(`Salesforce Apex request failed for ${action}`);
    }
}
