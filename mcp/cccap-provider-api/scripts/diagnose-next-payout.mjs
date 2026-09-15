import { CccapClient } from "../dist/client.js";
import { requestApexViaSf, resolveAuthenticatedUserId } from "../dist/sf-cli.js";
import { getServicePeriodLedger, getUpcomingPayoutDetail } from "../dist/payment-orchestration.js";

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) {
  throw new Error("SF_TARGET_ORG is required");
}

const client = new CccapClient({
  targetOrg,
  providerUserId: await resolveAuthenticatedUserId(targetOrg),
  requestApex: requestApexViaSf,
});

const t0 = Date.now();
await client.initialize({ dateFilter: "TODAY" });
console.error(`initialize: ${Date.now() - t0}ms`);

const asOfDate = new Date().toISOString().slice(0, 10);
console.error(`asOfDate: ${asOfDate}`);

const t1 = Date.now();
const ledger = await getServicePeriodLedger(client, { dateFilter: "TODAY" }, asOfDate, {
  unbounded: true,
  isolateFailures: false,
});
console.error(`getServicePeriodLedger (unbounded, count=1): ${Date.now() - t1}ms`);
console.error("raw period(s) fetched:");
for (const p of ledger.periods) {
  console.error(JSON.stringify({
    servicePeriodId: p.servicePeriodId,
    serviceBeginDate: p.serviceBeginDate,
    serviceEndDate: p.serviceEndDate,
    payoutDate: p.payoutDate,
    periodStatus: p.periodStatus,
    netAmount: p.netAmount,
    calculatedAmount: p.calculatedAmount,
  }));
}

const t2 = Date.now();
const result = await getUpcomingPayoutDetail(client, { dateFilter: "TODAY" }, asOfDate);
console.error(`getUpcomingPayoutDetail: ${Date.now() - t2}ms`);
console.log(JSON.stringify(result, null, 2));