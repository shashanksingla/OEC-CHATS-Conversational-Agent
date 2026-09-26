# AAF CCCAP Payment Calculation Starter Prompt

You are building a read-only CCCAP payment calculation workflow inside AAF.

AAF receives raw Salesforce-shaped responses from tools. First connect related records, then calculate payment. Do not assume raw responses are canonical. Do not invent missing relationships, statuses, rates, attendance, or amounts.

## Tools

Use these tools:

```text
cccap_initialize_provider
cccap_get_cases
cccap_get_authorizations
cccap_get_county_rate_plans
cccap_get_schedules
cccap_get_fiscal_rates
cccap_get_payment_history
cccap_get_service_periods
cccap_get_holidays
```

Call `cccap_initialize_provider` first. It provides two keys:

- `providers[].Id`: Salesforce provider ID. Use for authorizations, schedules, fiscal rates, and payment history.
- `providers[].Name`: provider external/name key. Use for cases when required.

Never substitute them. Select one service period and use its date range for the other calls.

Fiscal rates:

```json
{"providerIds":["<providers[].Id>"],"fiscalScheduleIds":["<known IDN_EXTNL__c>"],"dateFilter":"DATE_RANGE","dateFrom":"YYYY-MM-DD","dateTo":"YYYY-MM-DD"}
```

`fiscalScheduleIds` is optional and uses rate-schedule `IDN_EXTNL__c`, not Salesforce `Id`.

Payment history:

```json
{"providerIds":["<providers[].Id>"],"dateFilter":"DATE_RANGE","dateFrom":"YYYY-MM-DD","dateTo":"YYYY-MM-DD"}
```

Do not send `servicePeriodIds`; payment history resolves periods by date.

## Objects and Relationships

Join by stable Salesforce IDs or approved external IDs, never by display name alone:

```text
Provider.Id -> Authorization.IDN_PROVR__c and schedule provider scope
Provider.Name -> Case.IDN_PROVR__c when required
Case.Id -> CaseIndividual.IDN_CASE__c -> Child.IDN_CLIENT__c
Case.Id -> Authorization.IDN_CASE__c
Authorization.Id -> canonical authorization ID
Authorization.Name or IDN_EXTNL__c -> authorization external ID
Authorization.IDN_CLIENT__c -> child ID
Authorization.CDE_COUNTY__c -> county ID
Authorization.Name -> schedule authorization key
Schedule.Id -> AttendanceTransaction.Schedule__c
Provider -> FiscalAgreement -> RateSchedule
RateSchedule.IDN_EXTNL__c -> FiscalRate.idn_fiscal_sch__c
Payment.IDN_PERIOD_SERV__c -> ServicePeriod
SubPayment.idn_pmt_sub__c -> PaymentDetail.idn_pmt_sub__c
SubPayment.idn_auth__c -> authorization external ID
PaymentDetail.dte_care__c -> service date
```

Orphaned, cross-provider, duplicate, or conflicting records must be flagged and excluded from calculation.

## Raw Fields That Matter

Authorization: `Id`, `Name`, `IDN_EXTNL__c`, `IDN_CASE__c`, `IDN_PROVR__c`, `IDN_CLIENT__c`, `CDE_COUNTY__c`, effective dates, status, drop-in allowance, and slot information.

Schedule/attendance: `CI_Authorization_Date__c`, `CI_Authorization_Hours__c`, `Hours__c`, `CI_Authorization_Rate_Type__c`, `Attendance__r.records`, `Schedule__c`, `CI_Attendance_Date__c`, `CI_Attendance_Hours__c`, `CI_Transaction_Result__c`, `Status__c`, `Sub_Type__c`, and `Previous_Transaction__c`.

Fiscal rate: `idn_fiscal_sch__c`, `cde_rate_type__c`, `cde_age_group__c`, `cde_care_unit__c`, and `amt_fa__c`.

Payment history: `IDN_PERIOD_SERV__c`, `idn_pmt_sub__c`, `idn_auth__c`, `idn_period_serv__c`, `cde_status_pmt_sub__c`, `DTE_PAID_PMT__c`, `dte_care__c`, `cde_type_info_addntl__c`, and amount fields.

Attendance rules:

- `CI_Authorization_Hours__c` is authorized-hours truth.
- Only transaction result `1` counts.
- `PARENT_APPROVED` confirms; `PARENT_PENDING` remains pending; `PARENT_REJECTED` is excluded.
- Exclude previous/superseded transactions.
- Missing detail means unresolved attendance; do not infer it.

Additional-info codes: `0` regular, `1` holiday, `3` drop-in, `4` absence, `8` slot regular, `9` slot holiday, `10` slot drop-in, `11` slot absence, `12` vacant slot, `13` enrollment/0-36-month absence, `14` care not offered.

## Attended-Care Payment

For each authorization and service date:

1. Resolve child, authorization, county, schedule, and service period.
2. Confirm the authorization and schedule are effective on the date.
3. Link transactions through `Schedule__c`.
4. Keep only valid result `1` transactions and exclude rejected/superseded rows.
5. Determine attended hours and confirmation state.
6. Determine the day type: regular care, holiday, absence, drop-in, care not offered, or forecast.
7. Determine payable hours:

```text
regular care -> min(authorized hours, attended hours)
holiday/absence -> authorized hours
drop-in -> attended hours
care not offered -> 0
forecast -> authorized hours
```

8. Derive the payment tier from payable hours:

```text
0 hours -> NO_PAYMENT
0 < hours <= 5 -> PART_TIME
5 < hours <= 12 -> FULL_TIME
12 < hours <= 17 -> FULL_TIME_PLUS_PART_TIME
hours > 17 -> FULL_TIME_PLUS_FULL_TIME
```

9. Match one effective fiscal rate using authorization, tier, rate type, age group, and date. Use `amt_fa__c` only.
10. Check payment history before presenting a new payment.
11. If a required relationship, policy, rate, or status mapping is missing, return a blocker instead of an amount.

The raw meaning of `cde_status_pmt_sub__c` is not confirmed. Do not assume its values mean `PAID` or `REQUESTED`.

## Vacant-Slot Payment

A vacant slot is a slot-contract record without an enrolled authorization, normally identified by missing `IDN_AUTH__c`.

For each vacant slot:

1. Resolve provider, county, slot ID, effective dates, care level, rate type, care unit, allowed weekdays, and monthly capacity.
2. Confirm the slot is effective on the date and the weekday is allowed.
3. Exclude provider closures and inapplicable holidays.
4. Count earlier eligible vacant-slot days in the same month in chronological order.
5. Stop when monthly capacity is reached.
6. Match the effective fiscal rate for the slot's rate type, age group, and care unit.
7. Calculate the slot amount separately from enrolled-child attendance payment.

Vacant slots do not use parent confirmation, child absence limits, or an enrolled authorization. Missing scope, capacity, dates, or rate blocks the slot amount.

## First Build

Start with one authenticated provider, one service period, one authorization with attendance, and one vacant slot. Return the stitched records, unresolved joins, missing fields, and calculation blockers. Ask questions only when a missing decision prevents these two payment paths from being implemented.
