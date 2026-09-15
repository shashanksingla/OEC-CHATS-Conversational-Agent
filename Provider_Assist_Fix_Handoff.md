# Provider Assist — Fix Handoff for Agent Builder

**Branch reviewed:** `Redesigned_provider_assist`
**Status:** Phase 1 fixes below are implemented and typecheck-clean against the real repo. Apply via the diff in Section 3, or re-implement by hand following Sections 1–2 exactly (same effect either way).
**Important:** This repo already contains `Improvement to be done/PROVIDER_ASSIST_360_REDESIGN_HANDOFF.md`, a prior, more detailed redesign plan. That doc states the formatter-split workstream is already done (confirmed true — `server.ts` is 780 lines, formatters already live in `src/formatters/`). Read that doc alongside this one; do not duplicate its already-completed items, and reconcile its Workstream 3/6 (payout calendar, deadline parity) with the fixes below before starting new work, since they touch the same files.

---

## 1. Root causes confirmed directly in source (not just transcripts)

### 1.1 Double-`~` estimate marker
`src/formatters/shared.ts`'s `estimatedMoney()` already returns `~ $X.XX`. `src/formatters/payment-formatter.ts` line 739 (pre-fix) wrapped that in a second literal `~ `, producing `~ ~ $3555.42 net` — exactly the bug seen in the transcript. This was the only such occurrence repo-wide (checked with `grep -rn "estimatedMoney" src/`).

### 1.2 "Calculated amount" column showed the wrong field
The ledger table's `Calculated amount` column was rendering `period.guaranteedAmount`, not a calculated/estimate figure — `LedgerPeriodEntry` never had a `calculatedAmount` field at all. This explains why that column was always near-zero regardless of period status: guaranteed amounts (vacant slot / paid holiday) are typically small next to attendance-dependent totals.

### 1.3 "Upcoming payment" defaulted to a 5-period ledger instead of one period
`server.ts`'s `cccap_analyze_payment` tool, for `view: "NEXT_PAYOUT"`, always called `getServicePeriodLedger()` (multi-period, default count 5) — never the already-existing, already-correct single-entry function `getUpcomingPayoutDetail()`. A second tool (`cccap_get_service_period_payout_ledger` with `upcomingOnly: true`) already called the single-entry function correctly, but the skill files never routed a plain "upcoming payment" ask to it — they route to `cccap_analyze_payment` with `view: "NEXT_PAYOUT"`, which hit the buggy path.

### 1.4 `netAmount` was populated identically for paid and unpaid periods
`payment-orchestration.ts` set `netAmount: String(payment.amount ?? "0.00")` unconditionally, regardless of `periodStatus`. So an in-progress, unreleased period could show a nonzero "Net amount" right next to a nonzero "At-risk amount" on the same row — internally contradictory, since a released amount and an at-risk amount for the same money shouldn't both be presented as live at once.

### 1.5 `LAST_PAYOUT` did not exist as a capability
There was no view, orchestration function, or formatter path for "what was my last payout" — only forward-looking views existed.

### 1.6 Dead-duplicate branch in period-status classification
`periodStatus` assignment had two consecutive ternary branches that both evaluated to `"EXPECTED_AWAITING_PAYOUT"` (`asOfDate < payoutDate ? "EXPECTED_AWAITING_PAYOUT" : "EXPECTED_AWAITING_PAYOUT"`) — harmless today, but worth cleaning up since it signals an incomplete status split (e.g. a distinct "overdue" status was likely intended and never finished).

### 1.7 `CURRENT_WEEK_FORECAST` naming was misleading but the behavior was already correct
Traced `getPaymentAnalysis`'s service-period resolution: for this view it already calls `getServicePeriods({ dateOn: "TODAY", limitOne: true })` — i.e. it already resolves to "the service period containing today," not a fixed calendar week. Only the name needed correcting; no engine logic change was required here.

---

## 2. Product decisions this implementation encodes (confirmed with stakeholder)

| Concept | Rule |
|---|---|
| Plain "upcoming payment" (no period named) | Returns **Next Payout only** — one period, soonest upcoming release date. Never the multi-period ledger by default. |
| Payout ledger (multi-period) | **Explicit-request only** — provider must name a month/range ("show September," "show all upcoming"). |
| Last Payout | New, single-period view: most recently *released* period. **Never** a standing greeting/snapshot option — reachable only via explicit ask or as a grounded follow-up after Next Payout. |
| Net amount | Populated **only** when a period is released (`PAID`) — the real, historical, reconciled figure. |
| Calculated amount | Populated **only** when a period is not yet released — the current system estimate. Never both nonzero on the same row. |
| Current-period forecast | Renamed `CURRENT_WEEK_FORECAST` → `CURRENT_PERIOD_FORECAST` (old name kept as an accepted input alias). Scoped to "the service period containing today," not a fixed week — behavior unchanged, name corrected. |

---

## 3. Exact diff (apply directly, or use as the precise spec if re-implementing by hand)

Files touched:
- `mcp/cccap-provider-api/src/schemas.ts`
- `mcp/cccap-provider-api/src/view-state.ts`
- `mcp/cccap-provider-api/src/payment-orchestration.ts`
- `mcp/cccap-provider-api/src/server.ts`
- `mcp/cccap-provider-api/src/formatters/payment-formatter.ts`
- `mcp/cccap-provider-api/src/formatters/attendance-formatter.ts`
- `skills/carepay-payment-readiness/SKILL.md`

```diff
--- a/mcp/cccap-provider-api/src/schemas.ts
+++ b/mcp/cccap-provider-api/src/schemas.ts
@@
 export const paymentViewSchema = z.enum([
   "STATUS",
-  "NEXT_PAYOUT",
-  "CURRENT_WEEK_FORECAST",
-  "CUSTOM_RANGE",
+  // NEXT_PAYOUT: the single unpaid/upcoming period whose release date is
+  // soonest. This is the default view for a plain "upcoming payment"
+  // request - it must resolve to exactly one period, never a ledger.
+  "NEXT_PAYOUT",
+  // LAST_PAYOUT: the single most recently released period. Reachable only
+  // via explicit request or as a grounded follow-up; never a default and
+  // never offered as a standing greeting option.
+  "LAST_PAYOUT",
+  // PAYOUT_LEDGER: every service period falling within an explicitly named
+  // month/range. Only reached when the provider names a range - never the
+  // default for an unscoped "upcoming" ask.
+  "PAYOUT_LEDGER",
+  // Scoped to the service period containing today (begin <= today <= end),
+  // not a fixed calendar week. CURRENT_WEEK_FORECAST is kept as an accepted
+  // alias so existing callers are not broken by the rename.
+  "CURRENT_PERIOD_FORECAST",
+  "CURRENT_WEEK_FORECAST",
+  "CUSTOM_RANGE",
 ]);


--- a/mcp/cccap-provider-api/src/view-state.ts
+++ b/mcp/cccap-provider-api/src/view-state.ts
@@
   | "NEXT_UPCOMING_PAYOUT"
+  | "LAST_PAYOUT"
   | "PAYOUT_LEDGER"
@@
   | "payout-summary"
+  | "last-payout-summary"
   | "payout-ledger"


--- a/mcp/cccap-provider-api/src/payment-orchestration.ts
+++ b/mcp/cccap-provider-api/src/payment-orchestration.ts
@@
-export type PaymentView = "STATUS" | "NEXT_PAYOUT" | "CURRENT_WEEK_FORECAST" | "CUSTOM_RANGE";
+// NEXT_PAYOUT/LAST_PAYOUT/PAYOUT_LEDGER never reach getPaymentAnalysis - they
+// are intercepted in server.ts and routed to getUpcomingPayoutDetail /
+// getLastPayoutDetail / getServicePeriodLedger instead. They remain in this
+// union only so PaymentView stays the single source of truth for every
+// schema-level view name server.ts can receive.
+export type PaymentView = "STATUS" | "NEXT_PAYOUT" | "LAST_PAYOUT" | "PAYOUT_LEDGER" | "CURRENT_WEEK_FORECAST" | "CUSTOM_RANGE";
@@
 export type LedgerPeriodStatus = "IN_PROGRESS" | "PENDING_CONFIRMATION" | "EXPECTED_AWAITING_PAYOUT" | "PAID";
-export interface LedgerPeriodEntry { servicePeriodId: string; serviceBeginDate: string; serviceEndDate: string; payoutDate: string; periodStatus: LedgerPeriodStatus; netAmount: string; grossAmount: string; guaranteedAmount: string; amountAtRisk: string; }
+// Net amount is populated ONLY for a released (PAID) period - it is the
+// reconciled, historical, already-paid figure. Calculated amount is
+// populated ONLY for a period that has not yet been released - it is the
+// engine's current best estimate and is expected to change. A period row
+// must never carry both a nonzero netAmount and a nonzero calculatedAmount;
+// exactly one of the two is meaningful per periodStatus, enforced in the
+// mapping below rather than left to the renderer to infer.
+export interface LedgerPeriodEntry { servicePeriodId: string; serviceBeginDate: string; serviceEndDate: string; payoutDate: string; periodStatus: LedgerPeriodStatus; netAmount: string | undefined; calculatedAmount: string | undefined; grossAmount: string; guaranteedAmount: string; amountAtRisk: string; }
 function utcDayDifference(from: string, to: string): number { return Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / 86400000); }
 function utcPlusDays(date: string, days: number): string { const d = new Date(`${date}T00:00:00Z`); d.setUTCDate(d.getUTCDate() + days); return d.toISOString().slice(0, 10); }
 export async function getServicePeriodLedger(client: CccapClient, scope: DateScope, asOfDate: string, options: { periodCount?: number } = {}): Promise<{ periods: LedgerPeriodEntry[]; sourceRetrievedAt: string }> {
@@
   const results = await Promise.all(selected.map(async (period) => ({ period, result: record(await getPaymentAnalysis(client, { dateFilter: "DATE_RANGE", dateFrom: period.serviceBeginDate, dateTo: period.serviceEndDate }, "CUSTOM_RANGE", asOfDate), "Payment evaluation") })));
-  const periods = results.map(({ period, result }) => { const payment = record(result.payment, "Evaluated payment"); const payoutDate = typeof payment.payout_date === "string" ? payment.payout_date : computePayoutDate(period.serviceEndDate); // Fallback is non-fatal for older evaluator output.
-    const duplicatePaid = payment.status === "DUPLICATE_GUARD" && (payment.existing_status === "PAID" || payment.existing_status === "4");
-    const periodStatus: LedgerPeriodStatus = asOfDate < period.serviceEndDate ? "IN_PROGRESS" : duplicatePaid ? "PAID" : asOfDate < utcPlusDays(period.serviceEndDate, 5) ? "PENDING_CONFIRMATION" : asOfDate < payoutDate ? "EXPECTED_AWAITING_PAYOUT" : "EXPECTED_AWAITING_PAYOUT";
-    return { ...period, payoutDate, periodStatus, netAmount: String(payment.amount ?? "0.00"), grossAmount: String(payment.gross_amount ?? "0.00"), guaranteedAmount: String(payment.guaranteed_amount ?? "0.00"), amountAtRisk: String(payment.amount_at_risk ?? "0.00") }; });
+  const periods = results.map(({ period, result }) => { const payment = record(result.payment, "Evaluated payment"); const payoutDate = typeof payment.payout_date === "string" ? payment.payout_date : computePayoutDate(period.serviceEndDate); // Fallback is non-fatal for older evaluator output.
+    const duplicatePaid = payment.status === "DUPLICATE_GUARD" && (payment.existing_status === "PAID" || payment.existing_status === "4");
+    // Two originally-identical ternary branches ("not yet due" vs. "past due,
+    // still unpaid") both resolved to EXPECTED_AWAITING_PAYOUT, which is
+    // correct as a status label (both are legitimately "expected, awaiting
+    // payout" from the provider's point of view) - kept as one branch below
+    // rather than a dead duplicate condition.
+    const periodStatus: LedgerPeriodStatus = asOfDate < period.serviceEndDate
+      ? "IN_PROGRESS"
+      : duplicatePaid
+        ? "PAID"
+        : asOfDate < utcPlusDays(period.serviceEndDate, 5)
+          ? "PENDING_CONFIRMATION"
+          : "EXPECTED_AWAITING_PAYOUT";
+    const amount = String(payment.amount ?? "0.00");
+    return {
+      ...period,
+      payoutDate,
+      periodStatus,
+      // PAID: the duplicate-guarded amount is the reconciled historical
+      // figure - show it as Net, and treat this period as settled (no
+      // Calculated/At-risk breakdown, since nothing is still pending).
+      // Not yet PAID: the same engine figure is only a current estimate -
+      // show it as Calculated, never as Net, so a provider never reads an
+      // unreleased period's estimate as if it were an authoritative payout.
+      netAmount: periodStatus === "PAID" ? amount : undefined,
+      calculatedAmount: periodStatus === "PAID" ? undefined : amount,
+      grossAmount: String(payment.gross_amount ?? "0.00"),
+      guaranteedAmount: String(payment.guaranteed_amount ?? "0.00"),
+      amountAtRisk: periodStatus === "PAID" ? "0.00" : String(payment.amount_at_risk ?? "0.00"),
+    };
+  });
   return { periods, sourceRetrievedAt: new Date().toISOString() };
 }
-export async function getUpcomingPayoutDetail(client: CccapClient, scope: DateScope, asOfDate: string): Promise<{ entry: LedgerPeriodEntry | undefined; daysUntilPayout: number | undefined; sourceRetrievedAt: string }> {
-  const ledger = await getServicePeriodLedger(client, scope, asOfDate); const entry = ledger.periods.filter((period) => period.periodStatus !== "PAID" && period.payoutDate >= asOfDate).sort((a, b) => a.payoutDate.localeCompare(b.payoutDate))[0]; return { entry, daysUntilPayout: entry ? utcDayDifference(asOfDate, entry.payoutDate) : undefined, sourceRetrievedAt: ledger.sourceRetrievedAt };
-}
+// Next payout: the single unpaid/upcoming period whose payout (release)
+// date is soonest. This is the default view for a plain "upcoming payment"
+// request - it must never silently expand to the multi-period ledger.
+export async function getUpcomingPayoutDetail(client: CccapClient, scope: DateScope, asOfDate: string): Promise<{ entry: LedgerPeriodEntry | undefined; daysUntilPayout: number | undefined; sourceRetrievedAt: string }> {
+  const ledger = await getServicePeriodLedger(client, scope, asOfDate);
+  const entry = ledger.periods
+    .filter((period) => period.periodStatus !== "PAID")
+    .sort((a, b) => a.payoutDate.localeCompare(b.payoutDate))[0];
+  return { entry, daysUntilPayout: entry ? utcDayDifference(asOfDate, entry.payoutDate) : undefined, sourceRetrievedAt: ledger.sourceRetrievedAt };
+}
+// Last payout: the single most recently released (PAID) period. Distinct
+// capability from Next Payout; surfaced only on explicit provider request,
+// never as a standing greeting/snapshot option, per product decision.
+export async function getLastPayoutDetail(client: CccapClient, scope: DateScope, asOfDate: string): Promise<{ entry: LedgerPeriodEntry | undefined; sourceRetrievedAt: string }> {
+  const ledger = await getServicePeriodLedger(client, scope, asOfDate, { periodCount: 12 });
+  const entry = ledger.periods
+    .filter((period) => period.periodStatus === "PAID")
+    .sort((a, b) => b.payoutDate.localeCompare(a.payoutDate))[0];
+  return { entry, sourceRetrievedAt: ledger.sourceRetrievedAt };
+}


--- a/mcp/cccap-provider-api/src/server.ts
+++ b/mcp/cccap-provider-api/src/server.ts
@@
-import { comparePaymentPeriods, getPaymentAnalysis, getServicePeriodLedger, getUpcomingPayoutDetail } from "./payment-orchestration.js";
+import { comparePaymentPeriods, getLastPayoutDetail, getPaymentAnalysis, getServicePeriodLedger, getUpcomingPayoutDetail } from "./payment-orchestration.js";
@@
-      const request = resolvedContinuation?.tool === "cccap_analyze_payment"
-        ? resolvedContinuation.input as typeof input
-        : input;
+      const resolvedRequest = resolvedContinuation?.tool === "cccap_analyze_payment"
+        ? resolvedContinuation.input as typeof input
+        : input;
       if (hasContinuation && (!resolvedContinuation || resolvedContinuation.tool !== "cccap_analyze_payment")) {
         return toolError("payment analysis", new Error("Continuation reference is unavailable or expired"));
       }
+      // CURRENT_PERIOD_FORECAST is the current, correctly-named view for
+      // "the service period containing today"; CURRENT_WEEK_FORECAST is
+      // kept only as an accepted input alias so existing callers do not
+      // break. Normalize here, once, so every downstream orchestration and
+      // formatter call site keeps using the single existing internal name,
+      // and so `request.view`'s type never carries the alias past this point.
+      const normalizedView = resolvedRequest.view === "CURRENT_PERIOD_FORECAST" ? "CURRENT_WEEK_FORECAST" : resolvedRequest.view;
+      const request = { ...resolvedRequest, view: normalizedView };
@@
-      const runPayoutLedger = () => execute(
-        "payment payout ledger",
-        () => getServicePeriodLedger(client, request, new Date().toISOString().slice(0, 10)),
-        (data) => attachDialogueState(
-          contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"),
-          dialogueStore,
-          providerKey,
-          "payment-analysis",
-          recordValue(data)?.scope ?? request,
-          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
-        ),
-      );
-      if (request.view === "NEXT_PAYOUT") {
-        return runPayoutLedger();
-      }
+      // NEXT_PAYOUT resolves to a single upcoming period by default - a
+      // plain "upcoming payment" request must never silently expand to the
+      // multi-period ledger. PAYOUT_LEDGER is the only view that returns
+      // multiple periods, and only when the provider explicitly names a
+      // month/range. LAST_PAYOUT resolves to the single most recently
+      // released period; it is a distinct capability from NEXT_PAYOUT, not
+      // a fallback when no upcoming period exists.
+      const asOfDateForLedger = new Date().toISOString().slice(0, 10);
+      const runNextPayout = () => execute(
+        "payment payout ledger",
+        () => getUpcomingPayoutDetail(client, request, asOfDateForLedger),
+        (data) => attachDialogueState(
+          contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"),
+          dialogueStore,
+          providerKey,
+          "payment-analysis",
+          recordValue(data)?.scope ?? request,
+          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
+        ),
+      );
+      const runLastPayout = () => execute(
+        "payment payout ledger",
+        () => getLastPayoutDetail(client, request, asOfDateForLedger),
+        (data) => attachDialogueState(
+          contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"),
+          dialogueStore,
+          providerKey,
+          "payment-analysis",
+          recordValue(data)?.scope ?? request,
+          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
+        ),
+      );
+      const runPayoutLedger = () => execute(
+        "payment payout ledger",
+        () => getServicePeriodLedger(client, request, asOfDateForLedger),
+        (data) => attachDialogueState(
+          contextualize(formatServicePeriodLedgerResult(data), contextStore, providerKey, "continuation", data, "cccap_analyze_payment"),
+          dialogueStore,
+          providerKey,
+          "payment-analysis",
+          recordValue(data)?.scope ?? request,
+          typeof recordValue(data)?.sourceRetrievedAt === "string" ? recordValue(data)?.sourceRetrievedAt as string : undefined,
+        ),
+      );
+      if (request.view === "NEXT_PAYOUT") {
+        return runNextPayout();
+      }
+      if (request.view === "LAST_PAYOUT") {
+        return runLastPayout();
+      }
+      if (request.view === "PAYOUT_LEDGER") {
+        return runPayoutLedger();
+      }


--- a/mcp/cccap-provider-api/src/formatters/payment-formatter.ts
+++ b/mcp/cccap-provider-api/src/formatters/payment-formatter.ts
@@
   if (periods) {
-    const renderPeriodRow = (period: Record<string, unknown>): string => {
-      const begin = dateLabel(period.serviceBeginDate), end = dateLabel(period.serviceEndDate);
-      const servicePeriod = begin !== "Unavailable from the current source" && end !== "Unavailable from the current source" ? `${begin}-${end}` : "Unavailable from the current source";
-      return `| ${tableValue(servicePeriod)} | ${tableValue(dateLabel(period.payoutDate))} | ${tableValue(labels[String(period.periodStatus)] ?? "Unavailable from the current source")} | ${plainMoney(period.netAmount)} | ${plainMoney(period.guaranteedAmount)} | ${plainMoney(period.amountAtRisk)} |`;
-    };
-    if (multiPeriod) {
-      lines.push(`Showing ${periods.length} service periods from the verified payout ledger. The soonest upcoming payout is estimated at ~ ${estimatedMoney(upcoming?.netAmount)} net.`);
-      lines.push("", "> This ledger compares multiple service periods; select the next upcoming payout for a single-period view.", "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", ...periods.map(renderPeriodRow));
-    } else if (upcoming) {
-      lines.push(`Showing the next upcoming service period only: an estimated ${estimatedMoney(upcoming.netAmount)} net on ${dateLabel(upcoming.payoutDate)}.`, "", "> This shows only the next unpaid or upcoming payout identified from verified service-period data.", "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", renderPeriodRow(upcoming));
-    } else {
-      lines.push("No upcoming unpaid payout is currently identified from verified data.");
-    }
-  } else if (entry) {
-    const days = value.daysUntilPayout;
-    const countdown = typeof days === "number" ? `${days} day${days === 1 ? "" : "s"}` : "an undetermined number of days";
-    lines.push(`Payout in ${countdown}, on ${dateLabel(entry.payoutDate)}: an estimated ${estimatedMoney(entry.netAmount)} net.`);
-    lines.push(Number(entry.amountAtRisk) > 0
-      ? atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)
-      : DISCLAIMER_EXPECTED);
-  } else lines.push("No upcoming payout is currently identified from verified data.");
+    // A row shows exactly one of Net (released/paid, historical) or
+    // Calculated (not yet released, a current estimate) - never both, and
+    // never the guaranteed-amount field mislabeled as "Calculated".
+    const renderPeriodRow = (period: Record<string, unknown>): string => {
+      const begin = dateLabel(period.serviceBeginDate), end = dateLabel(period.serviceEndDate);
+      const servicePeriod = begin !== "Unavailable from the current source" && end !== "Unavailable from the current source" ? `${begin}-${end}` : "Unavailable from the current source";
+      const netCell = period.netAmount !== undefined ? plainMoney(period.netAmount) : "—";
+      const calculatedCell = period.calculatedAmount !== undefined ? plainMoney(period.calculatedAmount) : "—";
+      return `| ${tableValue(servicePeriod)} | ${tableValue(dateLabel(period.payoutDate))} | ${tableValue(labels[String(period.periodStatus)] ?? "Unavailable from the current source")} | ${netCell} | ${calculatedCell} | ${plainMoney(period.amountAtRisk)} |`;
+    };
+    // Headline figure uses whichever of Net/Calculated is populated for the
+    // soonest period - a released period never reaches here as "upcoming"
+    // (getUpcomingPayoutDetail/the ledger's own upcoming filter excludes
+    // PAID rows), so this is effectively always Calculated, but the
+    // fallback keeps the sentence accurate if that ever changes.
+    const upcomingHeadlineAmount = upcoming?.calculatedAmount ?? upcoming?.netAmount;
+    if (multiPeriod) {
+      lines.push(`Showing ${periods.length} service periods from the verified payout ledger. The soonest upcoming payout is estimated at ${estimatedMoney(upcomingHeadlineAmount)}.`);
+      lines.push("", "> This ledger shows every service period in the requested range; released periods show a Net amount, unreleased periods show a Calculated (current estimate) amount.", "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", ...periods.map(renderPeriodRow));
+    } else if (upcoming) {
+      lines.push(`Showing the next upcoming service period only: an estimated ${estimatedMoney(upcomingHeadlineAmount)} on ${dateLabel(upcoming.payoutDate)}.`, "", "> This shows only the single next unpaid or upcoming payout identified from verified service-period data.", "| Service period | Payout date | Status | Net amount | Calculated amount | At-risk amount |", "| --- | --- | --- | ---: | ---: | ---: |", renderPeriodRow(upcoming));
+    } else {
+      lines.push("No upcoming unpaid payout is currently identified from verified data.");
+    }
+  } else if (entry) {
+    const days = value.daysUntilPayout;
+    const countdown = typeof days === "number" ? `${days} day${days === 1 ? "" : "s"}` : "an undetermined number of days";
+    const isLastPayout = entry.periodStatus === "PAID";
+    const entryAmount = isLastPayout ? entry.netAmount : entry.calculatedAmount;
+    lines.push(isLastPayout
+      ? `Your last payout was released on ${dateLabel(entry.payoutDate)}: ${estimatedMoney(entryAmount)} net.`
+      : `Payout in ${countdown}, on ${dateLabel(entry.payoutDate)}: an estimated ${estimatedMoney(entryAmount)}.`);
+    lines.push(!isLastPayout && Number(entry.amountAtRisk) > 0
+      ? atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)
+      : DISCLAIMER_EXPECTED);
+  } else lines.push("No upcoming payout is currently identified from verified data.");
@@
-  const ledgerDisclaimers = [
-    DISCLAIMER_GLOBAL,
-    ...(entry && Number(entry.amountAtRisk) > 0
-      ? [atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)]
-      : entry ? [DISCLAIMER_EXPECTED] : []),
-  ];
+  const isLastPayoutEntry = Boolean(entry) && !periods && entry?.periodStatus === "PAID";
+  const ledgerDisclaimers = [
+    DISCLAIMER_GLOBAL,
+    ...(entry && !isLastPayoutEntry && Number(entry.amountAtRisk) > 0
+      ? [atRiskDisclaimer(entry.confirm_by_date ?? entry.confirmByDate ?? value.confirm_by_date)]
+      : entry && !isLastPayoutEntry ? [DISCLAIMER_EXPECTED] : []),
+  ];
   const ledgerScope = recordValue(value.scope);
   const selectedPeriod = upcoming ?? entry;
   const ledgerInput = selectedPeriod?.serviceBeginDate && selectedPeriod?.serviceEndDate
     ? {
         view: "STATUS",
         dateFilter: "DATE_RANGE",
         dateFrom: String(selectedPeriod.serviceBeginDate),
         dateTo: String(selectedPeriod.serviceEndDate),
         detailDepth: "DETAIL",
       }
     : {
         view: "NEXT_PAYOUT",
         ...(ledgerScope?.dateFilter ? { dateFilter: ledgerScope.dateFilter } : {}),
         ...(ledgerScope?.dateFrom ? { dateFrom: ledgerScope.dateFrom } : {}),
         ...(ledgerScope?.dateTo ? { dateTo: ledgerScope.dateTo } : {}),
       };
-  const actionIntents = multiPeriod
-    ? [
-        { actionId: "open-next-upcoming-payout", capability: "payment-analysis", label: "Open next upcoming payout", reason: "Focus on the nearest unpaid or upcoming service period.", priority: "high", section: "next-actions", source: "current-result", input: ledgerInput },
-      ]
-    : [{ actionId: "review-service-period-payout-ledger", capability: "payment-analysis", label: "Review payment details for this service period", reason: "Inspect the source-backed payment calculation behind this payout period.", priority: "medium", section: "next-actions", source: "current-result", input: ledgerInput }];
-  const currentView = viewState({
-    viewId: multiPeriod ? "PAYOUT_LEDGER" : "NEXT_UPCOMING_PAYOUT",
-    tableId: multiPeriod ? "payout-ledger" : "payout-summary",
-    tableTitle: multiPeriod ? "Payout ledger" : "Next upcoming payout",
-    tableDescription: multiPeriod ? "This table compares multiple verified service periods and their payout status." : "This table shows only the next unpaid or upcoming payout identified from verified service-period data.",
-    ...(value.scope !== undefined ? { scope: value.scope } : {}),
-    ...(typeof value.sourceRetrievedAt === "string" ? { sourceRetrievedAt: value.sourceRetrievedAt } : {}),
-  });
+  const actionIntents = multiPeriod
+    ? [
+        { actionId: "open-next-upcoming-payout", capability: "payment-analysis", label: "Open next upcoming payout", reason: "Focus on the nearest unpaid or upcoming service period.", priority: "high", section: "next-actions", source: "current-result", input: ledgerInput },
+      ]
+    : isLastPayoutEntry
+      ? [{ actionId: "open-next-upcoming-payout-from-last", capability: "payment-analysis", label: "View next upcoming payout", reason: "See the next payout still ahead, separate from this released one.", priority: "medium", section: "next-actions", source: "current-result", input: { view: "NEXT_PAYOUT" } }]
+      : [{ actionId: "review-service-period-payout-ledger", capability: "payment-analysis", label: "Review payment details for this service period", reason: "Inspect the source-backed payment calculation behind this payout period.", priority: "medium", section: "next-actions", source: "current-result", input: ledgerInput }];
+  const currentView = viewState({
+    viewId: multiPeriod ? "PAYOUT_LEDGER" : isLastPayoutEntry ? "LAST_PAYOUT" : "NEXT_UPCOMING_PAYOUT",
+    tableId: multiPeriod ? "payout-ledger" : isLastPayoutEntry ? "last-payout-summary" : "payout-summary",
+    tableTitle: multiPeriod ? "Payout ledger" : isLastPayoutEntry ? "Last payout" : "Next upcoming payout",
+    tableDescription: multiPeriod
+      ? "This table shows every verified service period in the requested range and its payout status."
+      : isLastPayoutEntry
+        ? "This shows only the most recently released payout identified from verified service-period data."
+        : "This table shows only the next unpaid or upcoming payout identified from verified service-period data.",
+    ...(value.scope !== undefined ? { scope: value.scope } : {}),
+    ...(typeof value.sourceRetrievedAt === "string" ? { sourceRetrievedAt: value.sourceRetrievedAt } : {}),
+  });


--- a/mcp/cccap-provider-api/src/formatters/attendance-formatter.ts
+++ b/mcp/cccap-provider-api/src/formatters/attendance-formatter.ts
@@
     actions.push({
-      actionId: "forecast-current-week-services",
+      actionId: "forecast-current-period-services",
       capability: "payment-analysis",
       tool: "cccap_analyze_payment",
-      label: "Forecast this week's services payout",
-      reason: "Project this week's actual and scheduled services into an estimated payout.",
+      label: "Estimate current week's service payout",
+      reason: "Project this service period's actual and scheduled services into an estimated payout.",
       priority: "medium",
       section: "available-options",
       source: "current-result",
-      view: "CURRENT_WEEK_FORECAST",
-      input: { view: "CURRENT_WEEK_FORECAST" },
+      view: "CURRENT_PERIOD_FORECAST",
+      input: { view: "CURRENT_PERIOD_FORECAST" },
       scope,
     });


--- a/skills/carepay-payment-readiness/SKILL.md
+++ b/skills/carepay-payment-readiness/SKILL.md
@@
-For next-payout detail, use `cccap_analyze_payment` with `view: "NEXT_PAYOUT"`. The tool selects the next service period whose payment has not run, then returns the service dates, processing date, release date, payment status, and any deterministic amount. Present payment amounts only when the result is complete and source-ready; otherwise show the service-period dates and the named missing source areas without inventing an amount.
-
-For a current-week forecast, use `cccap_analyze_payment` with `view: "CURRENT_WEEK_FORECAST"`. The deterministic engine treats dates through today as actuals and future scheduled dates as `SCHEDULED_FORECAST` conditional rows. Explain expected amount, conditional amount at risk, and the child/county/date classifications from the returned table. Never present future scheduled hours as attended actuals.
+## Payout view selection — three distinct capabilities, never interchange them
+
+A plain "upcoming payment" / "what am I getting paid" request with no period named is answered with `view: "NEXT_PAYOUT"` **only** — this always resolves to a single service period (the soonest unpaid/upcoming period by release date). Never call the multi-period ledger for this request shape, and never widen it to a range unless the provider names one.
+
+- **Next payout** (`view: "NEXT_PAYOUT"`) — the default for an unscoped "upcoming payment" question. Single period only: the soonest upcoming/unpaid period by release date. Returns service dates, payout date, status, and a `Calculated amount` (current estimate; the period has not yet been released) plus its at-risk breakdown. Never shows a `Net amount` — a period that has one is, by definition, no longer "upcoming."
+- **Last payout** (`view: "LAST_PAYOUT"`) — only on an explicit request about a past/last/most recent payment, or as a grounded follow-up after showing Next Payout. Never offered as a standing greeting/snapshot option. Single period only: the most recently released period. Shows a `Net amount` (the real, reconciled, historical figure) and no at-risk breakdown — it is settled.
+- **Payout ledger** (`view: "PAYOUT_LEDGER"`) — only when the provider explicitly names a month or range ("show September's payouts," "show this month," "show all upcoming periods"). Returns every service period in that range; each row shows either a `Net amount` (if released) or a `Calculated amount` (if not), never both, following the same rule as Next Payout / Last Payout.
+
+Present payment amounts only when the result is complete and source-ready; otherwise show the service-period dates and the named missing source areas without inventing an amount.
+
+For a forecast of the service period containing today, use `cccap_analyze_payment` with `view: "CURRENT_PERIOD_FORECAST"` (accepted alias: `CURRENT_WEEK_FORECAST`). This is scoped to whichever service period today falls inside (begin ≤ today ≤ end), not a fixed calendar week. The deterministic engine treats dates through today as actuals and future scheduled dates as `SCHEDULED_FORECAST` conditional rows. Explain expected amount, conditional amount at risk, and the child/county/date classifications from the returned table. Never present future scheduled hours as attended actuals. Note when this period is the same period as Next Payout (today can fall inside the next unpaid period) — say so explicitly rather than presenting the same period twice under different labels without comment.
```

**Validation performed:** `npx tsc --noEmit -p tsconfig.json` passes clean after all of the above. The existing test suite (`npm test`) has **not yet been run** against these changes — do that before merging, and expect to update fixtures in `test/` that assert on the old `NEXT_PAYOUT` → multi-period-ledger behavior, since that behavior is now intentionally changed.

---

## 4. Confirmed but NOT yet fixed — needs a data-flow audit before patching

**The ledger's At-risk figures escalate implausibly across adjacent weekly periods** (seen in transcript: $3,538 → $67,248 → $69,015 across three consecutive one-week periods). I traced the Python engine (`provider_risk_payment_engine.py`) and confirmed `at_risk_total` is accumulated only from the `attendance["days"]` passed into that single call — i.e., the engine itself is correctly period-scoped. The likely bug is upstream: what date range or attendance dataset gets passed in per period from `getServicePeriodLedger`'s per-period `getPaymentAnalysis(..., "CUSTOM_RANGE", asOfDate)` call. Recommend: instrument/log the exact `attendance.days` date range and count actually reaching the engine for periods 2 and 3 in a real multi-period ledger call, and confirm whether a wider-than-intended window (e.g. cumulative-to-date rather than single-week) is leaking in. **Do not patch this blind — verify the actual data flowing in first**, consistent with this repo's existing fail-closed discipline.

---

## 5. Still open from the original review (not started)

These were part of the agreed plan but not yet implemented — recommend tackling in this order:

1. **Locking/permissions table** (top priority per stakeholder) — extend `skills/agent-child-care-payment-advisor/references/view-catalog.md` with, per view: visible fields, locked scope dimensions (frozen on drill-down), allowed follow-up transitions, and categorically unavailable actions (confirm/submit/edit — always "no," stated once).
2. **Dynamic next-actions/next-views audit** — build one shared action-generation function that reads from the locking table's allowed-transitions list and the active view's own returned evidence, deduplicates against actions already shown this turn, and ranks by `$ at risk` descending. This directly addresses the "repeated or irrelevant next actions" concern raised.
3. **Vocabulary migration finish** — `skills/agent-child-care-payment-advisor/references/vocabulary.md` still flags `amount_at_risk` / `at_risk_amount` / `conditional_amount` / `potential_impact` as "Migration needed." Consolidate to one canonical field name and one formatter path; add a contract test that fails if a new call site introduces a synonym.
4. **Reconcile with `Improvement to be done/PROVIDER_ASSIST_360_REDESIGN_HANDOFF.md`** — that doc's Workstream 3 (payout calendar) and Workstream 6 (deadline parity) touch the same `payment-orchestration.ts`/`provider_risk_payment_engine.py` files as the fixes above. Read it before starting further payout-calendar work so the two efforts don't diverge or duplicate.
5. Regression test coverage for everything in Section 3 (new `LAST_PAYOUT` tests, Net/Calculated mutual-exclusivity assertion, no-double-tilde lint/test).

---

## 6. Suggested order of work for the agent builder

1. Apply Section 3's diff (or hand-implement from it).
2. Run `npm test` and `npm run typecheck` in `mcp/cccap-provider-api/`; fix any fixture that asserted the old multi-period-default behavior for `NEXT_PAYOUT`.
3. Run the existing `chat_experiences_for_review/*` transcripts (or equivalent) against the updated build; confirm no double-`~`, no Net/Calculated overlap, and that a plain "upcoming" ask returns exactly one period.
4. Investigate Section 4 (At-risk escalation) with real logging before patching.
5. Move to Section 5's open items, starting with the locking table.
