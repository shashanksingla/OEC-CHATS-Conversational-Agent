import { CccapClient } from "../dist/client.js";
import {
  requestApexViaSf,
  resolveAuthenticatedUserId,
} from "../dist/sf-cli.js";

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) {
  throw new Error("SF_TARGET_ORG is required");
}

const client = new CccapClient({
  targetOrg,
  providerUserId: await resolveAuthenticatedUserId(targetOrg),
  requestApex: requestApexViaSf,
});
const data = await client.initialize({ dateFilter: "TODAY" });

console.log(
  JSON.stringify({
    providerCount: data.providers?.length ?? 0,
    fiscalAgreementCount: data.fiscalAgreements?.length ?? 0,
    closureCount: data.providerClosures?.length ?? 0,
  }),
);