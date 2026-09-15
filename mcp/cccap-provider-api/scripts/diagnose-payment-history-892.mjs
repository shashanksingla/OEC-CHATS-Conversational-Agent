import { CccapClient } from "../dist/client.js";
import { requestApexViaSf, resolveAuthenticatedUserId } from "../dist/sf-cli.js";

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) {
  throw new Error("SF_TARGET_ORG is required");
}

const client = new CccapClient({
  targetOrg,
  providerUserId: await resolveAuthenticatedUserId(targetOrg),
  requestApex: requestApexViaSf,
});

await client.initialize({ dateFilter: "TODAY" });

// Period 892: 2026-08-31..2026-09-06
const scope = { dateFilter: "DATE_RANGE", dateFrom: "2026-08-31", dateTo: "2026-09-06" };
const paymentHistory = await client.getPaymentHistory(scope);
console.error("raw getPaymentHistory response:");
console.error(JSON.stringify(paymentHistory, null, 2));