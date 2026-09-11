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

The MCP adapter must only construct this input from already authorized retrievals. It calls the deterministic engine for payment status, `NEXT_PAYOUT`, and `CURRENT_WEEK_FORECAST`; incomplete mappings still produce a provider-safe blocked response rather than inferred values. `CURRENT_WEEK_FORECAST` means the whole service period containing today, not a calendar week. Future forecast rows are explicitly classified as scheduled and conditional. Confirmed gross excludes conditional revenue; amount at risk includes pending confirmations and authorization-specific drop-in or absence limit exposure. Occupied slot contracts use the regular attendance route; only vacant slot contracts contribute separate slot-contract fees.

## Payment Engine Output Addendum (provider-risk-payment-v2)

The currently implemented Python engine sets `RULE_VERSION = "provider-risk-payment-v2"` (`scripts/provider_risk_payment_engine.py:17`). The fields below are additive output fields of that engine and are introduced under that rule version. `period_status` is not currently emitted by the Python engine; period-status classification remains a TypeScript concern and must not be documented as a Python output field until an implementation adds it.

### Python provider-risk payment output

| Location and field | Type | Presence and meaning | Introduced by |
| --- | --- | --- | --- |
| `payment.payout_date` | ISO date string | Present on a successful payment result; calculated as the service-period end plus eleven days (`provider_risk_payment_engine.py:1134-1136`, with the calculation at `:26-33`). | `provider-risk-payment-v2` |
| `payment.guaranteed_amount` | Money/decimal serialized as a JSON number | Present on a successful payment result; total classified amount for guaranteed payment days (`provider_risk_payment_engine.py:1001-1003,1123-1134`). | `provider-risk-payment-v2` |
| `attendance.days[].amount_incorrectly_at_risk` | Money/decimal serialized as a JSON number | Present only on entries in `holiday_classification_mismatches`; it is the amount exposed by that mismatch (`provider_risk_payment_engine.py:1007-1009`). Otherwise the per-day field is absent, not null. | `provider-risk-payment-v2` |
| `holiday_classification_mismatches` | Array of per-day objects | Present on a successful result (empty when no mismatch exists); each member copies the day and adds `amount_incorrectly_at_risk` and `risk_code` (`provider_risk_payment_engine.py:954-955,1007-1009,1112-1114`). | `provider-risk-payment-v2` |
| `total_amount_incorrectly_at_risk` | Money/decimal serialized as a JSON number | Present on a successful result (zero when no mismatch exists); sum of mismatch amounts (`provider_risk_payment_engine.py:954-955,1007-1009,1113-1114`). | `provider-risk-payment-v2` |
| `payment.total_amount_incorrectly_at_risk` | Money/decimal serialized as a JSON number | Present on a successful result and mirrors the top-level total (`provider_risk_payment_engine.py:1123-1135`). | `provider-risk-payment-v2` |
| `attendance.days[].confirm_by_date` | ISO date string | Present only while the explicit `as_of_date` is on or before the service date plus the confirmation window; otherwise absent (`provider-risk_payment_engine.py:834-839`). | `provider-risk-payment-v2` |
| `attendance.days[].payment_type` | String classification | Present on every emitted attendance day. The payment-class mapping assigns `GUARANTEED` to holiday/vacant-slot categories and `ATTENDANCE_DEPENDENT` to regular, absence, enrollment, and drop-in categories (`provider-risk-payment_engine.py:807-815`); the final emitted value is selected at `:850-853`. | `provider-risk-payment-v2` |
| `rule_version` | String | Present on blocked and successful engine results and equals `provider-risk-payment-v2` (`provider-risk_payment_engine.py:510-511,1107-1111`). | `provider-risk-payment-v2` |

The Python engine does **not** currently emit a `period_status` field. Also, because the implementation's final day-level expression preserves `REGULAR` for an attended regular day (`provider_risk_payment_engine.py:850-853`), consumers must not assume every emitted `payment_type` is limited to only the two payment-class labels without applying that existing output rule.

### Attendance-risk confirmation deadlines

These fields are emitted by `scripts/evaluate_attendance_risks.py` and are Python attendance-risk output, not fields of the payment engine's `payment` object. They are documented under the same `provider-risk-payment-v2` governance handoff, although the attendance-risk script itself does not declare a separate `RULE_VERSION` constant.

| Location and field | Type | Presence and meaning | Introduced by |
| --- | --- | --- | --- |
| `children[].next_confirmation_deadline` | ISO date string or null | Null when the child has no pending confirmation dates; otherwise the earliest pending date plus the confirmation window (`evaluate_attendance_risks.py:243-250,285-300`). | `provider-risk-payment-v2` |
| `children[].confirmation_days_remaining` | Integer or null | Null without pending confirmations; otherwise calendar days from `as_of_date` to that child's next deadline (`evaluate_attendance_risks.py:244-250,295-296`). | `provider-risk-payment-v2` |
| `earliest_confirmation_deadline` | ISO date string or null | Top-level minimum non-null child deadline, or null when no child has one (`evaluate_attendance_risks.py:337-345`). | `provider-risk-payment-v2` |
| `earliest_confirmation_days_remaining` | Integer or null | Top-level minimum remaining-day value for children with a deadline, or null when none exists (`evaluate_attendance_risks.py:346-355`). | `provider-risk-payment-v2` |

### TypeScript ledger-period contract status

`mcp/cccap-provider-api/src/payment-orchestration.ts` currently contains no `LedgerPeriodEntry` or `LedgerPeriodStatus` declaration (no implementation was found when this contract was updated). Their field list and status values are therefore **planned, not yet implemented**, and are intentionally not documented as an active contract. If added later, those TypeScript fields will not be gated by `rule_version`; `rule_version` applies to the Python evaluator contract only.

## Missing Production Mappings

Before Salesforce deployment, approve and test the response paths for attendance transaction validity, absence classification and approval, Care Not Offered, rate-unit selection and copay adjustments, parent confirmation, payment status and history, service-period-to-payment-window anchoring, holidays, slot contracts, ART fees, source freshness, and every relationship key. Missing mappings block the affected calculation.

## Confirmed Schema Decisions

- Authorization identity is explicit: `Authorization.Id` is the Salesforce ID, `Authorization.Name` is the primary authorization reference for external authorization-related rows, and `Authorization.IDN_EXTNL__c` is the fallback external reference.
- `T_SLOT_CONTRACT__c.IDN_AUTH__c` is a Salesforce authorization ID. `idn_auth__c` on encumbrances, authorization copays, and payment sub-payments is an authorization name, resolved through `Authorization.Name` and then `Authorization.IDN_EXTNL__c`.
- `Attendance__r.records[].Schedule__c` is the transaction-to-schedule relationship. Confirmed attendance requires `Status__c = PARENT_APPROVED`; confirmed attendance hours use schedule `Hours__c`.
- Authorization status codes are `1 = Pending`, `2 = Authorized`, `3 = Attended`, `4 = Paid`, and `5 = Care Not Offered`. Unknown authorization statuses block the affected calculation.
- Supported schedule types are `CCCAP_AUTHORIZED` and `DROP_IN`. `CI_Authorization_Rate_Type__c` supplies one schedule rate type; fiscal schedules can contain multiple rate types, so the schedule value selects the matching fiscal row.
- Fiscal-rate selection uses fiscal schedule `IDN_EXTNL__c`, rate type, age group, care unit, and care date. The latest effective match is selected. Payment uses `amt_fa__c`; provider and county amounts are not fallbacks.
- Age-group codes are `1: 0-6 Months`, `2: 06-12 Months`, `3: 12-18 Months`, `4: 18-24 Months`, `5: 24-30 Months`, `6: 30-36 Months`, `7: 36 - School Age`, and `8: School Age`. The age is evaluated on the care date, with the third birthday included in the 0-36-month boundary as confirmed by the business mapping.
- A vacant slot is an active date-overlapping `T_SLOT_CONTRACT__c` row with `IDN_AUTH__c = null`, scoped by authenticated provider and fiscal-agreement county. Apex returns raw rows; the canonical adapter maps rate type, care unit, and care level through the county fiscal schedule.
- Vacant-slot payment is calculated independently from attendance. It applies configured weekdays and chronological monthly limits, includes county holidays, excludes matching provider/county closure dates, and does not apply absence, drop-in, or parent-confirmation rules. Attendance payment is independent of occupied-slot flags.
- Paid absence limits are monthly, child-scoped, and county/provider-quality based. An authorization-level drop-in limit takes precedence over the county limit; `Number_of_Drop_in_Days__c` is the authorization monthly limit. The county `drop_in_response` value `licensed` is the currently confirmed licensed-provider rule.
- Payment status codes are `1 = Created`, `2 = In Progress`, `3 = Calculated`, and `4 = Paid`. Copay is monthly from the first day of the month. Date calculations currently use IST.

## Tool Selection

Use the narrowest tools and filters that answer the provider's request. Call `cccap_initialize_provider` first, then only relevant counties, cases, authorizations, periods, schedules, and calendars. The model chooses tools and valid API filters; it never supplies provider identity, joins records, applies rules, counts days, or calculates money.