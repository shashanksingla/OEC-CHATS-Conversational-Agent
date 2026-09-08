# Integration Contract

Load `references/rule-governance.md` before accepting any rule or rate input for calculation.

## Trust Boundary

MCP derives the provider and single facility from the authenticated Salesforce session. The model must not choose or override provider identity. All tools are read-only and enforce record-level authorization server-side.

## Current Resources

The `cccapprovider` MCP server exposes these read-only tools over the Salesforce REST resources:

- `cccap_initialize_provider` wraps `getProviderData` and must run first
- `cccap_get_cases` wraps `getCaseData` for cases and children
- `cccap_get_authorizations` wraps `getAuthData` for child authorizations
- `cccap_get_county_rate_plans` wraps `getCountyData` for attendance limits and county policy
- `cccap_get_holidays` wraps `getHolidayList` for payment-calendar inputs
- `cccap_get_schedules` wraps `getSchedules` for schedules and check-in/check-out transactions
- `cccap_get_fiscal_rates` wraps `getFiscalRates` for authorized fiscal schedules, fiscal-rate rows, and fiscal-rate fee rows
- `cccap_get_payment_history` wraps `getPaymentHistory` for authenticated-provider sub-payment history and duplicate-payment inputs
- `cccap_get_service_periods` wraps `getServicePeriods` for service and payment periods

The endpoint inventory is not yet a complete production contract. See `references/api-response-contract.json` for response-level gaps; do not claim readiness until response schemas map every required normalized field.

`getSchedules` returns aggregate `Check_In_Count__c`/`Check_Out_Count__c` fields and, when present, individual transaction records under `Attendance__r.records`. MCP maps those nested records into the normalized transaction contract before invoking the richer transaction-level ruleset in `scripts/analyze_attendance_transactions.py`.

`getFiscalRates` accepts only provider and schedule IDs injected by MCP from `getProviderData`. Apex re-derives active fiscal agreements and rate schedules for those provider IDs, then returns `batchsit_t_fiscal_rate__x` rows through the schedule external key and `T_FISCAL_RAT_FEES__c` rows through the Salesforce schedule lookup, including county, fiscal-agreement, and provider fee tiers. Fiscal-rate retrieval supplies source data but does not authorize a live payout amount until the remaining payment inputs are mapped.

`getPaymentHistory` requires a date scope and accepts only provider IDs injected by MCP. Apex resolves the scope to overlapping service-period records, queries local payment parents by authenticated provider and service-period record IDs, then queries external sub-payments by the parents' external payment IDs and service-period external IDs. This avoids traversing the external `idn_pmt__r` relationship, which can exceed Salesforce's external subquery limit. The route is service-period based because duplicate-payment checks must find payments for the care period even when processing or release dates differ; paid-date filtering is not used by this route. The response supplies payment date/status plus authorization, service-period, slot-contract, status, and amount fields, then returns current and historical detail rows keyed from those sub-payments; status-code and additional-info meanings still require an approved normalization map.

Source Salesforce and external-source objects, fields, and confirmed relationships are catalogued in `references/schema-mapping.json`. MCP routes, Python scripts, normalized inputs, response gaps, and derived outputs are catalogued separately in `references/api-response-contract.json`. Update the appropriate project contract when a source object or API response changes.

## Normalized Payment Case

The hybrid adapter creates one case per child, county agreement, and service period. MCP returns authorized coherent datasets; Python performs calculation-specific relationship resolution and validation. Provider identity has endpoint-specific forms: `getCaseData.providerIds` receives the numeric provider external name from `getProviderData.providers[].Name`; `getAuthData.providerIds` and `getSchedules.providerIds` receive the Salesforce provider record ID from `getProviderData.providers[].Id`.

Required calculation inputs are:

- `case_id` and source record identifiers
- `as_of_date` supplied explicitly, never read from an implicit clock
- provider, facility, child, county, fiscal-agreement, authorization, service-period, and rate-plan identifiers
- authorized, attended, and absent days derived from valid schedule and check-in/out transactions
- reimbursable absence limit, daily county rate, and daily parent copay from the effective rate plan
- parent-confirmation status, deadline, and confirmation timestamp
- source system, retrieved-at timestamp, rule version, and effective dates

The legacy calculator consumes fixture fields (`as_of_date`, `service_period`, `rate_plan`, and `parent_confirmation`) and remains unsuitable for live payout claims. The approved provider-risk-payment engine consumes the canonical payload assembled from authorized MCP reads. Identity and provenance fields travel alongside its result for presentation and audit. A production calculation remains blocked for incomplete canonical inputs, while complete inputs support payment status, next-payout detail, and current-week actual-plus-scheduled forecasting.

## Canonical Provider Risk and Payment Contract

`scripts/provider_risk_payment_engine.py` is the versioned deterministic engine for approved normalized inputs. Its required root fields are `service_period`, `authorizations`, `attendance_days`, `county_policies`, `fiscal_rates`, and `existing_sub_payments`; its approved rule version is `provider-risk-payment-v1`. Each attendance day carries authorization identity, service date, authorized and attended hours, per-day age/enrollment semantics, generic parent-confirmation state, and, for an absence, an independently sourced `absence_parent_approved` value. `care_not_offered` is an explicit zero-payment classification. Holiday and slot-contract eligibility must be resolved from authorized source data before entering the canonical engine.

The engine returns provider-ready attendance-day classifications, facility-authorized county counters, rule version, and source readiness. An incomplete canonical input returns `status: blocked` with missing input names and no amount. A `PAID` or `REQUESTED` sub-payment matching an authorization and service period returns `DUPLICATE_GUARD` with no amount. Care Not Offered and No Care are never payable. An over-36 absence is payable only while under the county limit and not parent-approved; a zero-to-36-months absence becomes `ENROLLMENT_ABSENCE` only after that limit is exhausted. The observed-holiday occupied-slot path is `SLOT_CONTRACT_HOLIDAY`; for over-36 regular care, the paid tier uses the lower of authorized and attended hours and flags over-attendance.

The MCP adapter must only construct this input from already authorized retrievals. It calls the deterministic engine for payment status, `NEXT_PAYOUT`, and `CURRENT_WEEK_FORECAST`; incomplete mappings still produce a provider-safe blocked response rather than inferred values. Future forecast rows are explicitly classified as scheduled and conditional.

## Missing Production Mappings

Before Salesforce deployment, approve and test the response paths for attendance transaction validity, absence classification and approval, Care Not Offered, rate-unit selection and copay adjustments, parent confirmation, payment status and history, service-period-to-payment-window anchoring, holidays, slot contracts, ART fees, source freshness, and every relationship key. Missing mappings block the affected calculation.

## Tool Selection

Use the narrowest tools and filters that answer the provider's request. Call `cccap_initialize_provider` first, then only relevant counties, cases, authorizations, periods, schedules, and calendars. The model chooses tools and valid API filters; it never supplies provider identity, joins records, applies rules, counts days, or calculates money.