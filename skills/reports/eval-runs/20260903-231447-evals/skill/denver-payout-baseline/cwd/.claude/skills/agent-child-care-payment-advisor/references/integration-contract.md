# Integration Contract

Load `references/rule-governance.md` before accepting any rule or rate input for calculation.

## Trust Boundary

MCP derives the provider and single facility from the authenticated Salesforce session. The model must not choose or override provider identity. All tools are read-only and enforce record-level authorization server-side.

## Current Resources

Registered MCP tools should wrap these Salesforce REST resources rather than exposing arbitrary HTTP:

- `getAuthData` - authenticated context
- `getProviderData` - provider greeting and facility identity
- `getCountyData` - county fiscal agreement and rate-plan data
- `getHolidayList` - payment-calendar inputs
- `getSchedules` - child authorization, schedule, and check-in/out transactions
- `getServicePeriods` - service and payment periods

The endpoint inventory is not yet a complete production contract. Do not claim readiness until response schemas map every required normalized field.

## Normalized Payment Case

The hybrid adapter creates one case per child, county agreement, and service period. MCP returns authorized coherent datasets; Python performs calculation-specific relationship resolution and validation.

Required calculation inputs are:

- `case_id` and source record identifiers
- `as_of_date` supplied explicitly, never read from an implicit clock
- provider, facility, child, county, fiscal-agreement, authorization, service-period, and rate-plan identifiers
- authorized, attended, and absent days derived from valid schedule and check-in/out transactions
- reimbursable absence limit, daily county rate, and daily parent copay from the effective rate plan
- parent-confirmation status, deadline, and confirmation timestamp
- source system, retrieved-at timestamp, rule version, and effective dates

The calculator currently consumes `as_of_date`, `service_period`, `rate_plan`, and `parent_confirmation`; identity and provenance fields travel alongside its result for presentation and audit. A root `payment_cases` array requests facility aggregation.

## Missing Production Mappings

Before Salesforce deployment, approve and test the response paths for attendance transaction validity, absence classification, rate and copay adjustments, parent confirmation, payment status and history, service-period-to-payment-window anchoring, holidays, source freshness, and every relationship key. Missing mappings block the affected calculation.

## Tool Selection

Use the narrowest tools and filters that answer the provider's request. Retrieve provider/facility context first, then only relevant counties, periods, schedules, and calendars. The model chooses tools and valid API filters; it never joins records, applies rules, counts days, or calculates money.