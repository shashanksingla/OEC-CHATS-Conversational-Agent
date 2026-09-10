# Canonical Payment Vocabulary

This is the single source of truth for canonical provider-facing payment terms and canonical internal field names. TypeScript formatters and Python evaluators must render from and use the exact vocabulary below; neither layer may invent a parallel term for the same concept. When a renderer or evaluator changes a name, update this registry before changing the implementation.

## Vocabulary registry

| Internal field(s) found in code | Canonical provider-facing term | Canonical internal field name (target) | Status |
| --- | --- | --- | --- |
| `amount_at_risk` (payment engine: `provider_risk_payment_engine.py:357`, `361`, `470`, `490`, `1064`, `1073`; TypeScript formatter: `server.ts:1364`, `1424`, `1442`); `at_risk_amount` (payment engine: `provider_risk_payment_engine.py:1077`; TypeScript formatter: `server.ts:1381`, `1402`); `conditional_amount` (payment engine: `provider_risk_payment_engine.py:313`, `323-327`, `347`, `408`, `437`, `450`, `1044`; TypeScript formatter: `server.ts:970`, `975`, `1408`, `1427`, `1430`, `1436`, `1474`); `potential_impact` (attendance evaluator: `evaluate_attendance_risks.py:255-284`, `297`; TypeScript formatter: `server.ts:432-442`, `707`, `783`) | At risk | `at_risk_amount` | Migration needed — see Migration protocol below |
| `total_amount` (payment engine, per-child: `provider_risk_payment_engine.py:1065`, `1067`) | Total / Expected depending on day classification | `total_amount` | Already canonical, document only |
| `net`/`gross` (payout summary: `provider_risk_payment_engine.py:1015-1017`, `1071-1073`; TypeScript formatter: `server.ts:1351-1358`) | Keep as-is, but MUST always be paired with the Expected/Guaranteed/At-Risk/Forecasted breakdown beneath it, never shown alone | `amount` (net) / `gross_amount` | Migrated — rendering labels use Expected/At-risk; this pairing rule prevents the original $0-vs-$57K headline bug from recurring |
| `absence_risk_amount_estimate` (attendance evaluator: `evaluate_attendance_risks.py:120`, `197-200`, `252-253`); `risk_amount_estimate` (attendance evaluator output: `evaluate_attendance_risks.py:299`, `391`, `403`; TypeScript formatter: `server.ts:432-442`, `1205`) | Estimated risk ($) | `risk_amount_estimate` | Migration needed — consolidate the source estimate and rendered estimate name |

## Format and rendering rules

Provider-facing wording must use **At risk** for money that is not yet guaranteed or may be reduced. Use **Expected** for the elapsed confirmation-window classification and **Forecasted** for future or still-within-window amounts; do not substitute `Conditional`, `Potential`, or another synonym for the provider-facing classification. The underlying breakdown must remain additive and must not silently replace the net or gross headline.

The payment detail tables use `Confirmed amount` and `Conditional amount` as their column labels when those fields are still present during migration. A bare `Conditional` header is not a dollar amount label. `Attendance type` and `Status` remain the provider-facing labels for attendance classification and confirmation state, respectively, as specified by the Payment Template.

`server.ts` and the Python payment and attendance evaluators are multiple renderers/emitters of these facts. They must render from this table verbatim and must not maintain an independent vocabulary registry or parallel term set. The Payment Template in `skills/carepay-conversation-templates/SKILL.md` must likewise remain aligned with this registry.

## Migration protocol

Migrating an internal field name requires a `rule_version` bump per `references/rule-governance.md` if the field lives in a Python evaluator's output. A field that exists ONLY as a rendering/wording choice in a TypeScript formatter or a SKILL.md template can be changed without a `rule_version` bump, since it does not change the underlying deterministic calculation — only how it is labeled. Every migration must update this table's `Status` column to `Migrated` once the OLD name is fully removed (not just aliased) from every consuming file; until then leave it `Migration needed` or `Migration in progress` so nothing is silently declared done while dual names still exist somewhere.

No two files in this repository may use two different field names for the same concept without this document explicitly declaring which is canonical and which is deprecated-but-present-for-migration. When adding a new provider-facing dollar concept, add it here BEFORE writing the formatter/evaluator code that renders it.
