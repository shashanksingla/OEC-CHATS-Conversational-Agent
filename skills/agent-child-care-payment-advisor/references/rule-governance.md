# Colorado Rule Governance

Authoritative sources currently live at `{project-root}/State Docs/8 CCR 1403-1.pdf` and `{project-root}/State Docs/CCCAP Provider Handbook English.pdf`. County-specific limits and rates come from effective county rate-plan records.

`Supporting docs/Attendance and Payment Calculations.md` and `Supporting docs/Overall Rules.md` are useful calculation-analysis inputs, but the latter explicitly requires Business Analyst validation and is not runtime authority. Use them to identify implementation and mapping work; do not promote inferred, ambiguous, or unapproved rules into a live calculation.

Do not send entire rule documents to the model on each provider request. Extract calculation-relevant rules into versioned structured data with source document, section/page citation, jurisdiction, effective start and end dates, interpretation notes, and test cases. Business and compliance owners must approve each version before engineering releases it.

Runtime calculations use only the approved structured rule version and effective county rate-plan data. A missing, expired, conflicting, or unapproved rule blocks the affected result. Preserve the applied rule version and source provenance in calculation output.

The currently approved build decision treats pending parent confirmation as conditional before its deadline and disputed after the deadline. This policy still requires citation and business/compliance sign-off before production deployment.