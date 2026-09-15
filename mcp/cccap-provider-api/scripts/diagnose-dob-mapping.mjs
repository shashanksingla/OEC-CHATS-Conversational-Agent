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

// Period 893 from the prior diagnostic run: 2026-09-07..2026-09-13
const scope = { dateFilter: "DATE_RANGE", dateFrom: "2026-09-07", dateTo: "2026-09-13" };
const [scheduleData, authData] = await Promise.all([
  client.getSchedules(scope),
  client.getAuthorizations({ ...scope, careDate: "2026-09-07" }),
]);

const schedules = Array.isArray(scheduleData?.schedules) ? scheduleData.schedules : [];
console.error(`schedules in period: ${schedules.length}`);
for (const s of schedules) {
  console.error(JSON.stringify({
    authorization_id: s.authorization_id,
    authorization_name: s.authorization_name,
    CI_Authorization_Id__c: s.CI_Authorization_Id__c,
    Authorization__c: s.Authorization__c,
  }));
}

const normalized = Array.isArray(authData?.normalizedAuthorizations) ? authData.normalizedAuthorizations : [];
console.error(`\nnormalizedAuthorizations returned: ${normalized.length}`);
for (const row of normalized) {
  const a = row.authorization ?? {};
  const client_ = a.IDN_CLIENT__r;
  console.error(JSON.stringify({
    Id: a.Id,
    Name: a.Name,
    IDN_EXTNL__c: a.IDN_EXTNL__c,
    CDE_COUNTY__c: a.CDE_COUNTY__c,
    DTE_BEGIN_EFFV_AUTH__c: a.DTE_BEGIN_EFFV_AUTH__c,
    DTE_END_EFFV_AUTH__c: a.DTE_END_EFFV_AUTH__c,
    fiscalScheduleMatch: row.fiscalScheduleMatch,
    hasClientRecord: Boolean(client_),
    clientDOB: client_?.DTE_DOB__c,
  }));
}