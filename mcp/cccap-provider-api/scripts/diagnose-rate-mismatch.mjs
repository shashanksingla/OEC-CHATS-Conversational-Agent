import { CccapClient } from "../dist/client.js";
import { requestApexViaSf, resolveAuthenticatedUserId } from "../dist/sf-cli.js";

const targetOrg = process.env.SF_TARGET_ORG;
if (!targetOrg) throw new Error("SF_TARGET_ORG is required");

const client = new CccapClient({
  targetOrg,
  providerUserId: await resolveAuthenticatedUserId(targetOrg),
  requestApex: requestApexViaSf,
});
await client.initialize({ dateFilter: "TODAY" });

// Current-period forecast window from the conversation log: 2026-09-14..2026-09-20
const scope = { dateFilter: "DATE_RANGE", dateFrom: "2026-09-14", dateTo: "2026-09-20" };
const scheduleData = await client.getSchedules(scope);
const scheduleRows = scheduleData.schedules || [];
console.error(`schedule rows: ${scheduleRows.length}`);

// Replicate payment-orchestration.ts's scheduleRateTypes construction exactly.
const scheduleRateTypes = Object.fromEntries(scheduleRows.flatMap((schedule) => {
  const authorizationKeys = [
    schedule.Authorization__c,
    schedule.authorization_id,
    schedule.authorization_name,
    schedule.CI_Authorization_Id__c,
  ].filter((key) => (typeof key === "string" && key.length > 0) || typeof key === "number");
  const rateType = schedule.rate_type_code ?? schedule.CI_Authorization_Rate_Type__c;
  return typeof rateType === "string" || typeof rateType === "number"
    ? authorizationKeys.map((k) => [String(k), String(rateType)])
    : [];
}));
console.error(`scheduleRateTypes map size: ${Object.keys(scheduleRateTypes).length}`);
console.error(`scheduleRateTypes for the 5 flagged auths: ${JSON.stringify({
  "963381": scheduleRateTypes["963381"],
  "963382": scheduleRateTypes["963382"],
  "963383": scheduleRateTypes["963383"],
  "963386": scheduleRateTypes["963386"],
  "963389": scheduleRateTypes["963389"],
})}`);

// Now fetch authorizations exactly like getPaymentAnalysis does.
const authData = await client.getAuthorizations({
  ...scope,
  careDate: "2026-09-14",
  scheduleRateTypes,
});
const normalized = authData.normalizedAuthorizations || [];
for (const row of normalized) {
  const a = row.authorization || {};
  if (["963381", "963382", "963383", "963386", "963389"].includes(String(a.Name))) {
    console.error(JSON.stringify({
      Id: a.Id,
      Name: a.Name,
      rateTypeCodeUsed: row.rateTypeCode,
      fiscalScheduleMatch: row.fiscalScheduleMatch,
      DTE_BEGIN_EFFV_AUTH__c: a.DTE_BEGIN_EFFV_AUTH__c,
      DTE_END_EFFV_AUTH__c: a.DTE_END_EFFV_AUTH__c,
      CDE_COUNTY__c: a.CDE_COUNTY__c,
    }));
  }
}

// Also dump the fiscal schedules the matcher is choosing among for this county.
const fiscalData = await client.getFiscalRates(scope);
const fiscalRates = fiscalData?.normalizedFiscalRates?.fiscalRates ?? [];
console.error(`fiscalRates count: ${Array.isArray(fiscalRates) ? fiscalRates.length : "n/a"}`);