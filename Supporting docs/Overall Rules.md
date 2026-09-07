# Rules Document — Attendance & Payment Calculation Agent

_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

> **THIS DOCUMENT IS FOR BUSINESS ANALYST VALIDATION ONLY.**
> **IT IS NOT USED AS THE AGENT'S RUNTIME INSTRUCTIONS.**
> It restates, in plain English, the rules extracted from `Attendance and Payment Calculations.md`, using the same terminology as that document, for a cross-check session with the Business Analyst team.

---

## 1. Attendance Classification Rules

1. If authorized hours are 0 and actual attended hours are greater than 0, the day is a candidate **Drop-In Day**.
2. If authorized hours are greater than 0 and actual attended hours are 0, the day is a candidate **Holiday** or **Absence** day (holiday is checked first).
3. If authorized hours are greater than 0 and actual attended hours are greater than 0, the day is a **Regular Day**.
4. If both authorized hours and actual attended hours are 0, the day is **No Care** (no payment).

## 2. Holiday Rules

1. Each county maintains a list of paid holiday codes (field `PAYMENT_Q13_1__c`), semicolon-delimited.
2. A care date is a holiday if it matches a holiday date or an observed holiday date in the year-holiday table, for the paid holiday codes belonging to that county.
3. If the care date is December 31, the holiday lookup uses the **next** calendar year (to correctly catch a January 1 holiday).
4. If the actual holiday date and the observed holiday date differ, the system pays exactly once — on whichever date has not already been paid.
5. A holiday is not paid if it was already paid on the other of the two dates (actual/observed).
6. A provider that is holiday-exempt (provider type `EFACH`, `DEFAB`, or `DEFAH`) does not receive holiday pay for its clients.
7. If holiday pay applies: for a regular authorization the additional-info code is `'1'`; for a slot contract it is `'9'`.

## 3. Absence Rules

1. Each county defines a maximum number of paid absence days per month, based on the provider's qualification rating level (Level 1 through Level 5), read from the county rate table.
2. The system counts how many absence days have already been paid for that authorization in the same calendar month.
3. Remaining paid absence days = maximum allowed − already used.
4. If remaining paid absence days > 0 and the absence is **not** parent-approved, the absence is paid (code `'4'`).
5. If remaining paid absence days > 0 and the absence **is** parent-approved, it is only paid if the child is enrolled under the 0–36-months program (code `'4'`).
6. If remaining paid absence days ≤ 0 **and** the child is enrolled under the 0–36-months program, the day is paid as a **regular** day instead (code `'13'`, Enrollment Override) — this guarantees continued payment for infants/toddlers even after absence days are exhausted.
7. If remaining paid absence days ≤ 0 and the child is **not** enrolled under the 0–36-months program, no payment is made (code `'0'`).

## 4. Drop-In Rules

1. Each county may allow a maximum number of paid drop-in days per month (field `payment_q14__c` = `'Y'` enables this).
2. An authorization can override the county's drop-in day limit if an auth-level override value exists and the county allows the override.
3. The system counts how many drop-in days have already been paid for that authorization in the same calendar month.
4. Remaining paid drop-in days = maximum allowed − already used.
5. If remaining paid drop-in days > 0 and the county's drop-in response code is Universal (`'1'`), the drop-in day is paid for any provider (code `'3'`).
6. If remaining paid drop-in days > 0 and the county's drop-in response code is Licensed Only (`'2'`), the drop-in day is only paid if the provider is currently licensed (status `OPEN` or `CLOSED`, active on the care date, and not provider type `EFACH`).
7. If remaining paid drop-in days ≤ 0, no drop-in payment is made.

## 5. Unit Hours (Hours-to-Pay) Rule Table

| Authorized Hours | Attended Hours | Additional-Info Code | Hours Paid |
|---|---|---|---|
| 0 | 0 | `'0'` Regular | 0 |
| 0 | 0 | `'3'` Drop-In | 0 |
| 0 | >0 | `'3'` Drop-In | Actual hours |
| >0 | 0 | `'1'` Holiday | Authorized hours |
| >0 | 0 | `'4'` Absence | Authorized hours |
| >0 | 0 | `'13'` Enrollment | Authorized hours |
| >0 | 0 | `'14'` Care Not Offered | 0 |
| >0 | >0 | `'0'` Regular | The lesser of authorized and actual hours |
| Slot contract or 0–36-months | Any | `'0'` Regular | Authorized hours, only if the provider's fiscal agreement is active for that county/date |

## 6. Time Indicator Rules

| Hours | Code | Meaning |
|---|---|---|
| 0 | `'1'` | NP — Not Paid |
| >0 and ≤5 | `'2'` | PT — Part-Time |
| >5 and ≤12 | `'3'` | FT — Full-Time |
| >12 and ≤17 | `'4'` | FTPT — Full-Time plus Part-Time |
| >17 | `'5'` | FTFT — Full-Time plus Full-Time |

## 7. Fiscal Rate Lookup Rule

1. The provider must have an active fiscal agreement for the county and care date (agreement status `OPN` or `CLS`, and the care date within the agreement's begin/end dates, or open-ended).
2. The rate is looked up from the provider's fiscal rate schedule, matched by: unit care type (e.g., HC/CC/FCC/LicAg), care level (e.g., INF/TOD/PRES/SCH), and time indicator (NP/PT/FT/FTPT/FTFT).
3. The looked-up rate is expressed per hour or per day depending on the rate row.

## 8. Copay Rules

1. Copay is based on the family's Federal Poverty Guideline percentage (FPG%).
2. **Tier 1 — FPG ≤ 100%:** Full-time copay = 1% of monthly household income (rounded down). Part-time copay = 55% of the full-time copay (rounded down).
3. **Tier 2 — 100% < FPG ≤ 200%:** Uses reference table `R00393` tiered income brackets, with a 1.3x multiplier applied for income between 100–150% FPG and a 1.6x multiplier for income between 150–200% FPG. **The exact bracket values in R00393 are not detailed in the source document — flagged for BA confirmation.**
4. **Tier 3 — FPG > 200%:** Maximum copay applies; may be based on family size and number of children, with county-level caps.
5. Part-time copay is always ≤ full-time copay.
6. Copay only applies to **Regular** care (code `'0'`). Holiday, Absence, Drop-In, Enrollment Override, and Slot Contract payments never carry a family copay.
7. **Open question for BA:** the document states "if copay calculated as $0, a minimum copay may apply" — this is not a firm rule and needs a defined trigger/value.
8. **Open question for BA:** the document states copay may be pro-rated if it changes mid-service, or the monthly copay may be used instead — no single rule is defined.

## 9. ART Fee Rules (Activity, Registration, Transportation)

1. Each fee (Transportation, Activity, Registration) has its own provider rate and its own frequency: ANNUAL, MONTHLY, or ONE-TIME.
2. Transportation and Activity fees can be restricted from specific months (e.g., not charged in July/August); Registration is typically charged once per fiscal year.
3. Each county sets a ceiling amount per fiscal year for each fee type, shared across all children in the county.
4. Each child has an individual ceiling per fiscal year for each fee type, tracked separately.
5. If the calculated fee would exceed the remaining county or individual ceiling, only the remaining capacity is charged (partial charge).
6. If the remaining capacity is 0 or less, the fee is not charged at all.
7. ART fees are not charged on Care Not Offered days, and may be reduced or not charged on Drop-In or Absence days.
8. No family copay applies to ART fees.
9. Fiscal year boundaries account for leap years (February 29) when pro-rating monthly amounts.

## 10. Slot Contract Rules

1. A slot contract may or may not be linked to a specific authorization; if not linked, it is a "vacant slot" still paid to the provider.
2. A slot contract defines which days of the week it pays for (e.g., "Monday,Wednesday,Friday") and a maximum number of paid days per month.
3. A care date not matching the slot's allowed days of the week is not paid (time indicator `'1'` NP).
4. Once the slot's monthly paid-day capacity is reached, additional days in that month are not paid, even if they fall on an allowed day of the week.
5. Slot contract payment types: `'8'` Regular (occupied), `'9'` Holiday, `'10'` Drop-In, `'11'` Absence, `'12'` Vacant Slot Regular, `'14'` Care Not Offered.
6. Slot contracts never carry a family copay.
7. If a slot-contract child is within the 0–36-months enrollment period and absence days are exhausted, the day is paid as regular (code `'13'`) using authorized hours instead of the slot's own hours.

## 11. Missing / Invalid / Incomplete / Inconsistent Data Rules

1. If the provider has no active fiscal agreement for the county/care date: a regular authorization is not paid (0 hours), the 0–36-months flag is treated as false, but a slot contract can still be paid because the slot itself supplies the agreement.
2. If the encumbrance status is `'5'` (Care Not Offered): 0 hours are paid, $0 is paid, the day does not count as attendance, absence, or holiday, and no family copay is charged. The authorization stays active.
3. A holiday is never paid twice — the system checks both the actual and observed holiday dates before paying either.
4. If the care date is December 31, holiday lookups use next year's holiday calendar.
5. Total payment can never be negative — if rate minus copay would go below $0, the total is set to $0.

## 12. Rules and Data Flagged as Missing, Ambiguous, or Unsupported (for BA confirmation)

1. **What should happen when encumbrance status is `'0'`, `'1'`, `'2'`, or `'4'`?** The source document itself marks these as undocumented ("= ?"). Only `'3'` (Attended) and `'5'` (Care Not Offered) are defined.
2. **What happens if no fiscal rate row matches** the provider's unit type/care level/time indicator combination? Not defined.
3. **What happens if the county rate table has no active row** covering the care date (a gap in effective dates)? Not defined.
4. **What are the exact income brackets in reference table R00393** used for Tier 2 copay (100–200% FPG)? Referenced but not detailed.
5. **When exactly does the "minimum copay may apply" rule trigger**, and what is the minimum amount? Stated conditionally, not firmly.
6. **How is mid-service copay change handled** — pro-rated, or monthly copay substituted? Not firmly defined.
7. **How are competing ART fee ceilings resolved** when multiple fee types would exceed the same remaining ceiling in the same period? Not fully specified.
8. **Is there a human escalation or dispute-resolution path** for a provider conversation, beyond the batch reversal/adjustment process mentioned in Section 2.5 of the source document? Not defined — no handoff target exists in the source document.

---

*End of Rules Document — for Business Analyst cross-check only. Not for runtime use.*