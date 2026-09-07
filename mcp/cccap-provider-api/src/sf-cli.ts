import { spawn } from "node:child_process";

import type { ApiEnvelope } from "./client.js";

export type RunSfCommand = (
  command: string,
  args: string[],
  input: string,
) => Promise<{ stdout: string; stderr: string; exitCode: number }>;

const runSfCommand: RunSfCommand = (command, args, input) =>
  new Promise((resolve, reject) => {
    const executable =
      process.platform === "win32" ? process.env.ComSpec || "cmd.exe" : command;
    const commandArgs =
      process.platform === "win32"
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
    child.stdout.on("data", (chunk: string) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk: string) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (exitCode) => {
      resolve({ stdout, stderr, exitCode: exitCode ?? 1 });
    });
    child.stdin.end(input);
  });

interface SfApiResult {
  status?: number;
  result?: {
    statusCode?: number;
    body?: ApiEnvelope | string;
  };
}

interface SfOrgDisplayResult {
  status?: number;
  result?: {
    username?: string;
  };
}

interface SfUserQueryResult {
  status?: number;
  result?: {
    totalSize?: number;
    records?: Array<{ Id?: string }>;
  };
}

const allowedActions = new Set([
  "getProviderData",
  "getCaseData",
  "getAuthData",
  "getCountyData",
  "getServicePeriods",
  "getSchedules",
  "getHolidayList",
  "getFiscalRates",
]);

export async function resolveAuthenticatedUserId(
  targetOrg: string,
  run: RunSfCommand = runSfCommand,
): Promise<string> {
  try {
    const display = await run(
      "sf",
      ["org", "display", "--target-org", targetOrg, "--json"],
      "",
    );
    const displayResult = JSON.parse(display.stdout) as SfOrgDisplayResult;
    const username = displayResult.result?.username;
    if (display.exitCode !== 0 || displayResult.status !== 0 || !username) {
      throw new Error("Invalid Salesforce org display response");
    }

    const escapedUsername = username.replaceAll("'", "\\'");
    const user = await run(
      "sf",
      [
        "data",
        "query",
        "--target-org",
        targetOrg,
        "--query",
        `SELECT Id FROM User WHERE Username = '${escapedUsername}' LIMIT 1`,
        "--json",
      ],
      "",
    );
    const userResult = JSON.parse(user.stdout) as SfUserQueryResult;
    const userId = userResult.result?.records?.[0]?.Id;
    if (
      user.exitCode !== 0 ||
      userResult.status !== 0 ||
      userResult.result?.totalSize !== 1 ||
      !userId
    ) {
      throw new Error("Invalid Salesforce user query response");
    }
    return userId;
  } catch {
    throw new Error(
      `Unable to resolve the authenticated Salesforce user for target org ${targetOrg}`,
    );
  }
}

export async function requestApexViaSf(
  targetOrg: string,
  action: string,
  body: Record<string, unknown>,
  run: RunSfCommand = runSfCommand,
): Promise<ApiEnvelope> {
  if (!allowedActions.has(action)) {
    throw new Error(`Unsupported CCCAP action: ${action}`);
  }
  try {
    const { stdout, exitCode } = await run(
      "sf",
      [
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
      ],
      JSON.stringify(body),
    );
    const result = JSON.parse(stdout) as SfApiResult;
    const statusCode = result.result?.statusCode;
    const responseBody = result.result?.body;
    if (
      exitCode !== 0 ||
      result.status !== 0 ||
      !statusCode ||
      statusCode < 200 ||
      statusCode >= 300 ||
      !responseBody
    ) {
      throw new Error("Invalid Salesforce CLI response");
    }
    return typeof responseBody === "string"
      ? (JSON.parse(responseBody) as ApiEnvelope)
      : responseBody;
  } catch {
    throw new Error(`Salesforce Apex request failed for ${action}`);
  }
}