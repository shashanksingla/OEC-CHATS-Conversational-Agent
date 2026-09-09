import { spawn } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
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
