import { CccapClient } from "../dist/client.js";
import {
  requestApexViaSf,
  resolveAuthenticatedUserId,
} from "../dist/sf-cli.js";

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) {
  throw new Error("SF_TARGET_ORG is required");
}

async function timed(label, fn) {
  const start = Date.now();
  try {
    const result = await fn();
    console.log(`[OK] ${label} (${Date.now() - start}ms)`);
    return result;
  } catch (error) {
    console.log(`[FAIL] ${label} (${Date.now() - start}ms): ${error?.message ?? error}`);
    throw error;
  }
}

const client = new CccapClient({
  targetOrg,
  providerUserId: await resolveAuthenticatedUserId(targetOrg),
  requestApex: requestApexViaSf,
});

const init = await timed("client.initialize({ dateFilter: THIS_MONTH })", () =>
  client.initialize({ dateFilter: "THIS_MONTH" }),
);
console.log("providers:", JSON.stringify(init.providers?.[0] ?? null));
console.log("fiscalAgreements count:", init.fiscalAgreements?.length ?? 0);

await timed("client.getSchedules({ dateFilter: THIS_MONTH })", () =>
  client.getSchedules({ dateFilter: "THIS_MONTH" }),
);

await timed("client.getServicePeriods({ paymentAfter: TODAY, limitOne: true })", () =>
  client.getServicePeriods({ paymentAfter: "TODAY", limitOne: true }),
);

const historyResult = await timed("client.getPaymentHistory({ dateFilter: THIS_MONTH })", () =>
  client.getPaymentHistory({ dateFilter: "THIS_MONTH" }),
);
console.log("getPaymentHistory raw result:", JSON.stringify(historyResult, null, 2).slice(0, 2000));