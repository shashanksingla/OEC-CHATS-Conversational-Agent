# CCCAP Provider API MCP Server

This local stdio MCP server gives Provider Assist read-only tools backed by `CccapPortalApiV1` in the Salesforce target org.

## Authentication and Scope

The server reuses the existing Salesforce CLI authorization for `SF_TARGET_ORG`. At startup it resolves that authenticated Salesforce username to its `User.Id`; VS Code does not prompt for a user ID, and the model cannot view or override it.

`cccap_initialize_provider` calls `getProviderData`, captures the provider IDs and active county agreements mapped to that user, and establishes the in-process authorization scope. Every provider-specific downstream call injects those provider IDs. County filters outside that scope are rejected before Salesforce is called.

For production, prefer per-user Salesforce OAuth and derive identity in Apex with `UserInfo.getUserId()` rather than accepting `userId` in the request body. The local input approach is for VS Code development.

## Commands

From this directory:

```powershell
npm install
npm test
npm run typecheck
npm run build
```

VS Code starts `node dist/index.js` from `.vscode/mcp.json` and uses the existing `CHATS_SIT` Salesforce CLI session. Ensure the authenticated Salesforce user has a matching `Provider_Persona_MD__mdt` record.

After changing tool code, rebuild and run **MCP: Reset Cached Tools**, then restart `cccapprovider` from **MCP: List Servers**.

The `dist/` directory is generated runtime output. Edit only `src/`, run `npm run typecheck`, `npm test`, and `npm run build`, then restart the MCP server so VS Code loads the rebuilt artifact.

## Module Flow

Source-shaped Salesforce responses stop at the canonical adapters. Generic read tools also pass through `read-model-adapters.ts`, so provider-facing MCP responses use canonical object and field names rather than Salesforce keys. Capability orchestration retrieves the scoped sources, passes the normalized contract to the deterministic evaluator, and returns the provider-safe result.

- Attendance: `attendance-snapshot.ts` owns retrieval/evaluator invocation; `attendance-canonical-adapter.ts` owns schedule, authorization-name, county, and quality-tier normalization, with `schedule-normalizer.ts` owning transaction normalization.
- Payment: `payment-orchestration.ts` owns retrieval/evaluator invocation; `payment-canonical-adapter.ts` owns the raw-source-to-`provider-risk-payment-v1` conversion.
- Shared mappings: `read-model-adapters.ts` owns generic cases, authorizations, county plans, schedules, fiscal rates, holidays, service periods, and payment-history response models; `provider-context.ts`, `schedule-normalizer.ts`, `provider-policy.ts`, `payment-schema.ts`, and `payment-payload-adapter.ts` own reusable canonical mappings. Do not add Salesforce field names to orchestration, server dispatch, or evaluator code.

When a source field changes, update the schema mapping, the owning canonical adapter, and its focused fixture/test before changing capability processing.

## Tool Selection

Prefer one high-level provider-facing tool for the provider's stated outcome. Attendance snapshots and attendance-risk analysis initialize provider scope, retrieve their required county/schedule data, and run the deterministic evaluator internally. Payment analysis similarly assembles its required scoped inputs. Do not call `cccap_initialize_provider` before those composite tools.

Use `cccap_initialize_provider` directly only when the provider explicitly needs provider context such as active fiscal agreements, authorized counties, or agreement dates, or when a lower-level diagnostic requires that context. Retrieve cases, authorizations, county rate plans, schedules, service periods, holidays, fiscal rates, and payment history only when the current intent requires that specific source. Stop and report the source error when a required tool or field is unavailable.

## Conversation Starter Contract

The greeting tool (`cccap_get_current_month_risk_snapshot`) keeps its complete provider-facing tables and next actions in the primary text content. Its structured response is routing metadata only (`capability`, `scope`, freshness, `responseMode`, and response sections); it does not repeat the provider message, rollups, or action controls. This prevents the conversation starter from parsing two competing representations of the same result.

Child-level dates, classifications, risk explanations, and child-scoped filters are returned only by an explicit `cccap_analyze_attendance_risk` drill-down. The in-process client cache may reuse authenticated source reads between these calls, but cached source records must not be copied into the summary envelope. Keep `content[0].text` as the provider-ready response; treat structured fields as compact routing metadata and inspect them only when a follow-up view is selected.

## Payment Readiness

Attendance responses include a deterministic payment-readiness result. The payment tool now assembles the available fiscal rates, attendance confirmations, historical sub-payment details, slot contracts, county holiday/drop-in policies, copays, and Care Not Offered status. It still fails closed when a required source value is missing or ambiguous. The canonical evaluator is `scripts/provider_risk_payment_engine.py` and requires rule version `provider-risk-payment-v1`.

The generic `Salesforce DX` MCP server cannot invoke custom Apex REST resources; it remains useful for development operations such as SOQL, metadata, and tests.

Payment history requires a date filter. The filter is applied to overlapping service periods before sub-payments are queried, which keeps duplicate-payment checks anchored to the care period rather than the payment release date. The canonical adapter maps sub-payment status codes `1` (Created), `2` (In Progress), and `3` (Calculated) to `REQUESTED`, and `4` (Paid) to `PAID`; unknown codes fail closed. The response also includes current payment-detail and payment-detail-history rows keyed from the scoped sub-payments.

Attendance transaction normalization preserves `PARENT_APPROVED` and `PARENT_PENDING` as `parent_confirmation` (`CONFIRMED` or `PENDING`) and `absence_parent_approved` values for the downstream payment contract. Schedule and transaction records use `CI_Authorization_Id__c` as the authoritative authorization join.

Payment enrichment derives age bands from dated authorization encumbrances (`ind_0_36_months__c`) and observed holidays from `DTE_OBSERVED_HOL__c`. Encumbrance status codes are `1=Pending`, `2=Authorized`, `3=Attended`, `4=Paid`, and `5=Care Not Offered`; status `5` supplies the canonical `care_not_offered` value. Missing or conflicting source rows fail closed.

Authorization responses include linked slot-contract, encumbrance, and authorization-copay rows when present. Fiscal-rate responses include county, fiscal-agreement, and provider fee tiers. County rate-plan responses include the drop-in response code used to distinguish universal and licensed-only policies.

Fiscal-rate normalization maps Salesforce age-group codes `1`-`8`, care-unit codes `1`-`5`, and the canonical rate-type codes (`1`, `13`, `19`, `25`, `31`, `37`, `43`, `55`, `91`) to their Salesforce labels. The R00393 lookup is also exposed as `1 -> 15650` and `ADD -> 5500`. Authorization responses include a fail-closed fiscal-schedule match using the schedule's `CI_Authorization_Rate_Type__c`, provider scope, county, authorization dates, and requested `careDate`; raw `getVacantSlots` rows instead map by fiscal-agreement county, rate type, care unit, and care level. Ties use the latest schedule start date, while no-match and conflicting results remain unresolved.

Provider quality tiers follow the existing rate-schedule flow: provider type `EXE` maps to tier `1`; otherwise `Level 1` through `Level 5` map to tiers `2` through `6`. Unsupported or missing provider type/rating values remain unresolved.

Fiscal care-unit codes map to payment tiers as `PT -> PART_TIME`, `FT -> FULL_TIME`, `FTPT -> FULL_TIME_PLUS_PART_TIME`, and `FTFT -> FULL_TIME_PLUS_FULL_TIME`. `NP` maps to `NO_PAYMENT` and contributes zero base payment.

The read-only `cccap_analyze_payment` tool now initializes provider scope, retrieves the required source responses, assembles the canonical `provider-risk-payment-v1` payload, and invokes the Python payment engine. It returns the engine's deterministic expected, conditional, duplicate-guard, or blocked result; it never creates or updates payment records. Confirmed gross excludes conditional revenue; `amount_at_risk` includes pending confirmations and authorization-specific drop-in or absence limit exposure.

Payment responses are summary-first. The initial request returns the service-period dates, status, net/gross/conditional amounts, excluded counts, and compact county/tier/basis roll-up rows with applied rates, children, hours, and amounts. Child/date detail is omitted until a caller requests `detailPage`; those rows are paged to 25 by default, with `detailPageSize` capped at 100. The structured result reports `totalRows` and `hasMore` without changing calculated totals.

Authorization copays are validated with effective dates and deducted once per regular-care authorization-month, reflecting the monthly adjustment on the first of the month. Fiscal rates are multiplied by calculated payable unit hours. Attendance payment does not depend on occupied-slot flags. Raw vacant slots are active date-overlapping contracts with `IDN_AUTH__c = null`, scoped to authenticated providers and their fiscal-agreement counties; vacant-slot rates map through fiscal fields, count county holidays, exclude provider closure dates matching provider/county/date, and apply `CNT_DAYS_OF_MONTH__c` chronologically from the first of the month. Absence, drop-in, and attendance confirmation rules do not apply to vacant slots. Activity, registration, and transportation fees use the fiscal schedule frequency and restricted-month fields. All ambiguous joins and malformed amounts remain blocked.