import assert from "node:assert/strict";
import test from "node:test";

import {
  requestApexViaSf,
  resolveAuthenticatedUserId,
  type RunSfCommand,
} from "../src/sf-cli.js";

test("Salesforce CLI sends an authenticated Apex request with body on stdin", async () => {
  const calls: Array<{ command: string; args: string[]; input: string }> = [];
  const run: RunSfCommand = async (command, args, input) => {
    calls.push({ command, args, input });
    return {
      stdout: JSON.stringify({
        status: 0,
        result: {
          statusCode: 200,
          body: { isSuccess: true, data: { providers: [] } },
        },
      }),
      stderr: "",
      exitCode: 0,
    };
  };

  const result = await requestApexViaSf(
    "CHATS_SIT",
    "getProviderData",
    { dateFilter: "TODAY" },
    run,
  );

  assert.deepEqual(calls, [
    {
      command: "sf",
      args: [
        "api",
        "request",
        "rest",
        "/services/apexrest/CccapPortalApi/v1/getProviderData",
        "--target-org",
        "CHATS_SIT",
        "--method",
        "POST",
        "--body",
        "-",
        "--json",
      ],
      input: '{"dateFilter":"TODAY"}',
    },
  ]);
  assert.deepEqual(result, { isSuccess: true, data: { providers: [] } });
});

test("Salesforce CLI sends fiscal-rate requests to the Apex endpoint", async () => {
  const calls: Array<{ command: string; args: string[]; input: string }> = [];
  const run: RunSfCommand = async (command, args, input) => {
    calls.push({ command, args, input });
    return {
      stdout: JSON.stringify({
        status: 0,
        result: {
          statusCode: 200,
          body: { isSuccess: true, data: { fiscalRates: [] } },
        },
      }),
      stderr: "",
      exitCode: 0,
    };
  };

  await requestApexViaSf(
    "CHATS_SIT",
    "getFiscalRates",
    { providerIds: ["provider-1"], fiscalScheduleIds: ["schedule-1"] },
    run,
  );

  assert.equal(calls.length, 1);
  assert.equal(calls[0]?.args[3], "/services/apexrest/CccapPortalApi/v1/getFiscalRates");
  assert.equal(
    calls[0]?.input,
    '{"providerIds":["provider-1"],"fiscalScheduleIds":["schedule-1"]}',
  );
});

test("request errors do not include Salesforce CLI output", async () => {
  const run: RunSfCommand = async () => ({
    stdout: JSON.stringify({ status: 1, message: "secret diagnostic" }),
    stderr: "secret diagnostic",
    exitCode: 1,
  });

  await assert.rejects(
    requestApexViaSf("CHATS_SIT", "getProviderData", {}, run),
    (error: Error) =>
      error.message ===
      "Salesforce Apex request failed for getProviderData",
  );
});

test("the configured org's authenticated username resolves to one user ID", async () => {
  const calls: Array<{ command: string; args: string[]; input: string }> = [];
  const run: RunSfCommand = async (command, args, input) => {
    calls.push({ command, args, input });
    if (args[1] === "display") {
      return {
        stdout: JSON.stringify({
          status: 0,
          result: { username: "provider@example.test" },
        }),
        stderr: "",
        exitCode: 0,
      };
    }
    return {
      stdout: JSON.stringify({
        status: 0,
        result: { totalSize: 1, records: [{ Id: "user-1" }] },
      }),
      stderr: "",
      exitCode: 0,
    };
  };

  const userId = await resolveAuthenticatedUserId("CHATS_SIT", run);

  assert.equal(userId, "user-1");
  assert.deepEqual(calls, [
    {
      command: "sf",
      args: ["org", "display", "--target-org", "CHATS_SIT", "--json"],
      input: "",
    },
    {
      command: "sf",
      args: [
        "data",
        "query",
        "--target-org",
        "CHATS_SIT",
        "--query",
        "SELECT Id FROM User WHERE Username = 'provider@example.test' LIMIT 1",
        "--json",
      ],
      input: "",
    },
  ]);
});

test("Salesforce CLI sends payment-history requests to the Apex endpoint", async () => {
  const calls: Array<{ args: string[] }> = [];
  const run: RunSfCommand = async (_command, args) => {
    calls.push({ args });
    return {
      stdout: JSON.stringify({
        status: 0,
        result: { statusCode: 200, body: { isSuccess: true, data: { subPayments: [] } } },
      }),
      stderr: "",
      exitCode: 0,
    };
  };

  await requestApexViaSf(
    "CHATS_SIT",
    "getPaymentHistory",
    { providerIds: ["provider-1"] },
    run,
  );

  assert.equal(calls[0]?.args[3], "/services/apexrest/CccapPortalApi/v1/getPaymentHistory");
});