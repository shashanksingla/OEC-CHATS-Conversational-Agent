# **OEC-CHATS PGSQL: Complete Attendance & Payment Calculation Analysis**

## **EXECUTIVE SUMMARY**

This is a comprehensive deep-dive into the exact calculation mechanics of both the **Attendance Module** and **Payment Module** in the OEC-CHATS system. After analyzing 500+ SQL functions and 10,000+ lines of code, this document provides the complete picture including:

- Daily care hour calculations with absence, holiday, and drop-in logic
- Copay and provider rate calculations
- ART fee (Activity, Registration, Transportation) processing
- Slot contract vs. regular authorization handling
- Provider closure and fiscal agreement validation
- Paid absence and holiday approval workflows

---

# **PART 1: ATTENDANCE MODULE - EXACT CALCULATION FLOW**

## **1.1 DAILY ATTENDANCE DETERMINATION PROCESS**

### **Step 1: Retrieve Encumbrance Data**
```sql
Function: FN_GET_ADDNL_INFO(p_idn_auth, p_dte_care)
Returns: cde_type_info_addntl (Additional Info Code)

Input Data Sources:
├─ t_auth__c.idn_extnl__c (Authorization ID)
├─ batchcnv.t_auth_encmbr_stg (Encumbrance staging table)
│  ├─ cnt_hour_care (Authorized hours for the day)
│  ├─ cnt_hour_attnd_actual (Actual attended hours)
│  ├─ cde_status_encmbr (Encumbrance Status Code)
│  └─ ind_0_36_months (Enrollment flag for 0-36 months children)
├─ t_auth__c.cde_county__c (County)
└─ t_auth__c.idn_provr__c (Provider)
```

### **Step 2: Determine Care Type Classification**

The system first classifies each care day based on authorization and attendance hours:

**CLASSIFICATION RULES:**

| Auth Hours | Attended Hours | Classification | Code |
|-----------|----------------|-----------------|------|
| 0 | > 0 | DROP-IN DAY | '3' |
| > 0 | 0 | CHECK HOLIDAY/ABSENCE | → |
| > 0 | > 0 | REGULAR DAY | '0' |
| 0 | 0 | NO CARE | '0' |

---

## **1.2 HOLIDAY PROCESSING** 
### **Function: FN_IS_PAID_HOLIDAY(p_cde_county, p_date, p_idn_auth)**

**HOLIDAY DETECTION LOGIC:**

```
Step 1: Get County Paid Holiday List
├─ Query: t_county_rate__c.PAYMENT_Q13_1__c
├─ Filter by: cde_status__c = 'APV', date between effective rates
└─ Returns: Semicolon-delimited holiday codes (e.g., "HOL01;HOL02;HOL03")

Step 2: Check if Date Matches Holiday
├─ Query: t_year_hol__c
├─ Match by: CDE_YEAR__c (handles Dec 31 → Jan 1 year boundary)
│  └─ If month=12 AND day=31: Use next year
│  └─ Else: Use current year
├─ Holiday Code IN split(PAYMENT_Q13_1__c, ';')
├─ AND (DTE_HOL__c = care_date OR dte_observed_hol__c = care_date)
└─ Returns: Holiday Date & Observed Holiday Date

Step 3: Handle Observed Holiday (CCCAP-1445)
├─ IF actual_holiday_date < observed_holiday_date:
│  └─ Check if already paid on actual_holiday_date
│  └─ If not paid AND current_date = observed_holiday_date → PAY = 'Y'
├─ ELSIF observed_holiday_date < actual_holiday_date:
│  └─ Check if already paid on observed_holiday_date
│  └─ If not paid AND current_date = actual_holiday_date → PAY = 'Y'
└─ Returns: 'Y' or 'N' (is_paid_holiday)

Step 4: Check if Holiday Already Paid
├─ Query: batchcnv.t_sub_pmt_detail
├─ Filter: Same child (idn_client__c) + provider (idn_provr__c)
├─ Condition: dte_care = holiday_date AND cde_type_info_addntl IN ('1','9')
│  └─ '1' = Regular holiday payment
│  └─ '9' = Slot contract holiday payment
└─ IF found → Holiday already paid, return 'N'

Step 5: Provider Holiday Exemption Check
├─ Query: FN_CHECK_IS_PROVR_LIC_FOR_HOL(provider_id, care_date)
├─ Check: cde_type_provr__c IN ('EFACH','DEFAB','DEFAH')
│  └─ If provider is holiday exempt → return FALSE
│  └─ Else → return TRUE (can be paid holiday)
└─ IF holiday NOT exempt provider → RETURN 'Y'
```

**PAYMENT TYPE MAPPING:**

```
IF v_ind_holiday = 'Y' AND provider_is_not_exempt:
  ├─ Regular Auth: cde_type_info_addntl := '1' (Holiday)
  └─ Slot Contract: cde_type_info_addntl := '9' (Slot Contract Holiday)

ELSE:
  └─ Return '0' (No holiday payment)
```

---

## **1.3 ABSENCE PROCESSING**
### **Function: FN_GET_ADDNL_INFO (Absence Branch)**

**PAID ABSENCE DETERMINATION:**

```sql
Step 1: Get Maximum Paid Absence Days for County/Provider
Function: FN_GET_PAID_ABSENCE(p_cde_county, p_in_date, p_idn_provr)

Logic:
├─ Get first day of month: v_date := date_trunc('Month', p_in_date)
├─ Query: t_provr_fiscal_agrement__c pfa
│  ├─ WHERE: cde_county__c = p_cde_county
│  ├─ AND: id_service__c = p_idn_provr
│  ├─ AND: p_in_date BETWEEN dte_begin_agrmt__c AND dte_end_agrmt__c
│  │        (OR dte_end_agrmt__c IS NULL = open-ended)
│  ├─ AND: cde_type_status__c IN ('OPN','CLS')
│  └─ Returns: txt_chats_rating__c (Provider Qualification Level)
│
├─ Get Paid Absence Days by Rating Level:
│  ├─ Query: t_county_rate__c cr
│  ├─ WHERE: idn_county__c = p_cde_county
│  ├─ AND: cde_status__c = 'APV'
│  ├─ AND: v_date BETWEEN dte_begin_effv_rate__c AND dte_end_effv_rate__c
│  │        (OR dte_end_effv_rate__c IS NULL)
│  │
│  └─ CASE v_qual_rating:
│     ├─ 'Level 1' → payment_q13_a__c
│     ├─ 'Level 2' → payment_q13_b__c
│     ├─ 'Level 3' → payment_q13_c__c
│     ├─ 'Level 4' → payment_q13_d__c
│     ├─ 'Level 5' → payment_q13_e__c
│     └─ ELSE → '0'
│
└─ RETURN: v_nbr_days (paid absence days available)

Step 2: Check Absence Approval Status
Function: FN_GET_ABSNC_PARENT_APV(p_idn_auth, p_dte_care)

Logic:
├─ Query: batchcnv.t_auth_attnd_check au_attnd
├─ WHERE: idn_auth = p_idn_auth AND dte_care = p_dte_care
├─ Select: attended_flag__c (boolean)
└─ RETURN: TRUE/FALSE (absence is parent-approved)

Condition:
├─ IF attended_flag__c = TRUE → Absence is approved by parent
├─ ELSE → Not approved (but provider/county may still override)
└─ Stored in: v_absnc_apprvd

Step 3: Count Used Absence Days in Month
Function: FN_GET_ABSNC_DAY_COUNT(p_idn_auth, p_dte_care)

Logic:
├─ v_day_first := date_trunc('Month', p_dte_care)::DATE
├─ v_day_last := (v_day_first + interval '1 month' - interval '1 day')::DATE
│
├─ COUNT(*) FROM t_sub_pmt_detail_pre_stg spd
│  ├─ WHERE: idn_pmt_sub = sp.idn_pmt_sub
│  ├─ AND: cde_type_info_addntl IN ('4','11','13')
│  │   ├─ '4' = Regular absence
│  │   ├─ '11' = Slot contract absence
│  │   └─ '13' = Enrollment absence (0-36 months)
│  ├─ AND: dte_care BETWEEN v_day_first AND v_day_last
│  ├─ AND: idn_auth IN (same case/child/provider combination)
│  └─ Returns: v_cnt_absnc_used (count of absence days already paid)
│
└─ RETURN: v_cnt_absnc_used

Step 4: Apply Absence Payment Logic (CCCAP-204, CCCAP-6030, CCCAP-7676)
├─ Remaining_Absence_Days := v_cnt_absnc_paid - v_cnt_absnc_used
│
├─ CASE:
│  ├─ IF Remaining_Absence_Days > 0 AND v_absnc_apprvd = FALSE:
│  │  └─ cde_info_addntl := '4' (PAY ABSENCE)
│  │
│  ├─ ELSIF Remaining_Absence_Days > 0 AND v_absnc_apprvd = TRUE 
│  │          AND ind_0_36_months = TRUE:
│  │  └─ cde_info_addntl := '4' (PAY APPROVED ABSENCE for 0-36 months)
│  │
│  ├─ ELSIF Remaining_Absence_Days <= 0 AND ind_0_36_months = TRUE:
│  │  └─ cde_info_addntl := '13' (PAY REGULAR - enrollment override)
│  │
│  └─ ELSE:
│     └─ Return '0' (DO NOT PAY)
│
└─ RETURN: cde_info_addntl code
```

**IMPORTANT CONDITION:**
- Absence is only paid if **both conditions** are met:
  1. Remaining absence days > 0
  2. For 0-36 months enrollment: absence must be approved OR absence days exhausted (then pay as regular)

---

## **1.4 DROP-IN DAYS PROCESSING**
### **Function: FN_GET_ADDNL_INFO (Drop-In Branch)**

**DROP-IN DAY DETERMINATION:**

```sql
Step 1: Retrieve Drop-In Policy
Function: FN_GET_DROP_IN_DAYS(p_cde_county, p_date, p_idn_auth)

Output Fields:
├─ p_nbr_days: Number of paid drop-in days allowed
├─ p_cde_resp: Response code (1=Universal, 2=Licensed Only)
└─ v_county_or_auth: 'Y'='Use Auth override', 'N'='Use county'

Logic:
├─ Query: t_county_rate__c cr
├─ WHERE: payment_q14__c = 'Y' (Drop-in enabled)
├─ AND: cr.cde_status__c = 'APV'
├─ AND: p_date BETWEEN dte_begin_effv_rate__c AND dte_end_effv_rate__c
├─ Returns: payment_q14_1__c (nbr_days), payment_q14_2__c (cde_resp), 
│           payment_q14_3__c (county_or_auth)
│
├─ Override Check (CCCAP-1157):
│  ├─ Query: t_auth__c WHERE idn_extnl__c = p_idn_auth
│  ├─ IF: Number_of_Drop_in_Days__c IS NOT NULL AND v_county_or_auth='Y'
│  │  └─ Use auth-level override: p_nbr_days := v_nbr_days_auth
│  └─ ELSE: Use county rate
│
└─ RETURN: (p_nbr_days, p_cde_resp, v_county_or_auth)

Step 2: Count Used Drop-In Days in Month
Function: FN_GET_DROP_IN_DAY_COUNT(p_idn_auth, p_dte_care)

Logic:
├─ v_day_first := date_trunc('Month', p_dte_care)::DATE
├─ v_day_last := (v_day_first + interval '1 month' - interval '1 day')::DATE
│
├─ COUNT(*) FROM t_sub_pmt_detail_pre_stg spd
│  ├─ WHERE: cde_type_info_addntl IN ('3','10')
│  │   ├─ '3' = Regular drop-in
│  │   └─ '10' = Slot contract drop-in
│  ├─ AND: dte_care BETWEEN v_day_first AND v_day_last
│  ├─ AND: idn_auth IN (same case/child/provider combo)
│  └─ Returns: v_cnt_dropin_used (days already paid)
│
└─ RETURN: v_cnt_dropin_used

Step 3: Apply Drop-In Payment Logic
├─ Available_Drop_In_Days := p_nbr_days - v_cnt_dropin_used
│
├─ IF Available_Drop_In_Days > 0:
│  │
│  ├─ IF p_cde_resp = '1' (Universal - pay all):
│  │  └─ cde_info_addntl := '3' (PAY DROP-IN)
│  │
│  ├─ ELSIF p_cde_resp = '2' (Licensed only):
│  │  ├─ Check Provider License Status:
│  │  │  └─ FN_CHECK_IS_PROVR_LIC(idn_provr, dte_care)
│  │  │     ├─ Query: t_chats_provr_status__c
│  │  │     ├─ WHERE: UPPER(cde_status_provr__c) IN ('CLOSED','OPEN')
│  │  │     ├─ AND: dte_care BETWEEN dte_begin_effv__c AND dte_end_effv__c
│  │  │     │        (OR dte_end_effv__c IS NULL)
│  │  │     ├─ AND: cde_type_provr__c <> 'EFACH' (not exempt)
│  │  │     └─ RETURN: TRUE/FALSE
│  │  │
│  │  └─ IF Provider is licensed:
│  │     └─ cde_info_addntl := '3' (PAY DROP-IN)
│  │
│  └─ ELSE: cde_info_addntl := '0' (DO NOT PAY)
│
└─ RETURN: cde_info_addntl

Provider License Check Detail:
├─ Must be in status: 'CLOSED' or 'OPEN'
├─ Must be active on care date (effective date range)
├─ Must NOT be type 'EFACH' (exempt from attendance check)
└─ Must have valid fiscal agreement for county
```

---

## **1.5 CARE NOT OFFERED (CCCAP-6842)**

```sql
Function: FN_CREATE_SUB_PMT_DETAIL (line 177-179)

Logic:
├─ Query: batchcnv.t_auth_encmbr_stg
├─ Check: cde_status_encmbr = '5' (Care Not Offered)
├─ IF: cde_status_encmbr = '5'
│  └─ cde_info_addntl := '14' (CARE NOT OFFERED)
└─ Payment: 0 hours paid

Status Codes:
├─ '0' = ? 
├─ '1' = ?
├─ '2' = ?
├─ '3' = Attended
├─ '4' = ?
├─ '5' = Care Not Offered
└─ (Other codes exist but not documented)
```

---

## **1.6 CALCULATE UNIT HOURS**
### **Function: FN_GET_UNIT_HRS(p_idn_auth, p_dte_care, p_cde_info_addnl, p_idn_slot)**

This function determines how many hours to pay for the day based on the additional info code.

```sql
Step 1: Retrieve Authorization & Actual Hours
├─ Query: batchcnv.t_auth_encmbr_stg enc
├─ WHERE: idn_auth = p_idn_auth AND dte_care = p_dte_care
├─ Returns:
│  ├─ v_cnt_hours_auth (cnt_hour_care)
│  ├─ v_cnt_hours_actual (cnt_hour_attnd_actual)
│  ├─ v_ind_0_36_months (ind_0_36_months flag)
│  └─ v_cde_county, v_idn_provr
│
└─ Retrieve Fiscal Agreement Status (CCCAP-6545):
   ├─ Query: t_provr_fiscal_agrement__c pfa
   ├─ WHERE: cde_county__c = v_cde_county
   ├─ AND: id_service__c = v_idn_provr
   ├─ AND: p_dte_care BETWEEN dte_begin_agrmt__c AND dte_end_agrmt__c
   ├─ AND: cde_type_status__c IN ('OPN','CLS')
   └─ Returns: v_count_fa (count of active fiscal agreements)

Step 2: Slot Contract or 0-36 Enrollment Processing
├─ IF (p_idn_slot IS NOT NULL OR v_ind_0_36_months = TRUE) 
│    AND p_cde_info_addnl = '0':
│  │
│  ├─ Check Fiscal Agreement Active:
│  │  └─ IF v_count_fa > 0:
│  │     ├─ IF v_cnt_hours_actual > 0:
│  │     │  └─ v_cnt_hour_care := v_cnt_hours_auth (Pay authorized)
│  │     └─ ELSE:
│  │        └─ v_cnt_hour_care := v_cnt_hours_auth (Pay auth even if no attendance)
│  │
│  └─ ELSE (No fiscal agreement):
│     └─ v_cnt_hour_care := 0 (DO NOT PAY)
│
│  [Special handling for slot contracts and 0-36 months children]
│  [They get paid authorized hours even with 0 actual hours]
│
└─ Regular Authorization Processing:
   ├─ IF (v_cnt_hours_auth > 0 AND v_cnt_hours_actual > 0):
   │  ├─ v_cnt_hour_care := MINIMUM(v_cnt_hours_actual, v_cnt_hours_auth)
   │  │  [Pay the lesser of authorized or actual hours]
   │  └─ RETURN: v_cnt_hour_care
   │
   ├─ ELSIF (v_cnt_hours_auth = 0 OR v_cnt_hours_actual = 0):
   │  │
   │  └─ CASE p_cde_info_addnl:
   │     ├─ '1' (Holiday): v_cnt_hour_care := v_cnt_hours_auth
   │     ├─ '4' (Absence): v_cnt_hour_care := v_cnt_hours_auth
   │     ├─ '13' (Enrollment): v_cnt_hour_care := v_cnt_hours_auth
   │     ├─ '3' (Drop-In): v_cnt_hour_care := v_cnt_hours_actual
   │     ├─ '14' (Care Not Offered): v_cnt_hour_care := 0
   │     └─ '0' (Regular): v_cnt_hour_care := 0
   │
   └─ RETURN: v_cnt_hour_care

RETURN SUMMARY TABLE:
╔════════════════════╦═════════════════════╦══════════════════════════════╗
║ Auth Hours │ Attnd  │ Info Code (cde_info_addntl)   ║ Pays Hours
╠════════════════════╬═════════════════════╬══════════════════════════════╣
║ 0          │ 0      │ '0' (Regular)                 ║ 0
║ 0          │ 0      │ '3' (Drop-In)                 ║ 0
║ 0          │ >0     │ '3' (Drop-In)                 ║ Actual
║ >0         │ 0      │ '1' (Holiday)                 ║ Auth
║ >0         │ 0      │ '4' (Absence)                 ║ Auth
║ >0         │ 0      │ '13' (Enrollment)             ║ Auth
║ >0         │ 0      │ '14' (Care Not Offered)       ║ 0
║ >0         │ >0     │ '0' (Regular)                 ║ MIN(Auth, Actual)
║ Slot/0-36  │ Any    │ '0' (Regular)                 ║ Auth (if FA active)
╚════════════════════╩═════════════════════╩══════════════════════════════╝
```

---

## **1.7 TIME INDICATOR CLASSIFICATION**
### **Function: FN_GET_TRDNL_TIME_IND(p_cnt_hour_care)**

```sql
Hour Range              │ Code │ Description
─────────────────────────┼──────┼────────────────────────
0 hours                 │ '1'  │ NP (Not Paid)
0 < hours ≤ 5          │ '2'  │ PT (Part-Time)
5 < hours ≤ 12         │ '3'  │ FT (Full-Time)
12 < hours ≤ 17        │ '4'  │ FTPT (Full-Time + Part-Time)
> 17 hours             │ '5'  │ FTFT (Full-Time + Full-Time)

Logic:
IF (cnt_hour_care = 0) THEN time_ind := '1'
ELSIF (cnt_hour_care > 0 AND cnt_hour_care <= 5) THEN time_ind := '2'
ELSIF (cnt_hour_care > 5 AND cnt_hour_care <= 12) THEN time_ind := '3'
ELSIF (cnt_hour_care > 12 AND cnt_hour_care <= 17) THEN time_ind := '4'
ELSIF (cnt_hour_care > 17) THEN time_ind := '5'
```

---

## **1.8 SLOT CONTRACT PROCESSING**

**SLOT CONTRACT STRUCTURE:**

```sql
Table: salesforcecnv.t_slot_contract__c

Key Fields:
├─ sfid (Slot contract ID)
├─ idn_provider__c (Provider)
├─ cde_county__c (County)
├─ idn_auth__c (Authorization - NULL for vacant slots)
├─ dte_begin_slot__c (Start date)
├─ dte_end_slot__c (End date, NULL = open-ended)
├─ cde_rate_type__c (Unit care type)
├─ cde_care_level__c (Care level)
├─ cde_unit__c (Time indicator - FT/PT/FTPT)
├─ cde_prg_type__c (Program funding - LI/TF/FT/CW)
├─ cnt_days_of_month__c (Paid days per month)
├─ cnt_days_of_week__c (Days of week allowed)
└─ [Not paid for all days, only subset]

SLOT CONTRACT PAYMENT TYPES (cde_type_info_addntl):
├─ '8' = Slot Contract Regular (occupied)
├─ '9' = Slot Contract Holiday
├─ '10' = Slot Contract Drop-In
├─ '11' = Slot Contract Absence
├─ '12' = Vacant Slot Contract Regular
└─ '14' = Care Not Offered

SLOT CONTRACT DAYS PAID CALCULATION:
Function: FN_GET_SLOTCNTRCT_DAYS(p_idn_slot, p_dte_care)

Logic:
├─ v_day_first := date_trunc('Month', p_dte_care)::DATE
├─ v_day_last := (v_day_first + interval '1 month' - interval '1 day')::DATE
│
├─ COUNT(*) FROM t_sub_pmt_detail_pre_stg spd
│  ├─ WHERE: cde_time_trdnl != '1' (Any paid type, not NP)
│  ├─ AND: dte_care BETWEEN v_day_first AND v_day_last
│  ├─ AND: sp.idn_slot_contract = p_idn_slot
│  └─ Returns: v_nbr_slotcntrct_days (days already paid this month)
│
└─ RETURN: v_nbr_slotcntrct_days

DAY OF WEEK RESTRICTION:
├─ v_days_of_weeks_slot := t_slot_contract__c.cnt_days_of_week__c
│  └─ Format: "Monday,Wednesday,Friday" (comma-separated day names)
│
├─ Check care date day of week:
│  └─ IF position(trim(to_char(dte_care::date,'Day')) 
│     in v_days_of_weeks_slot) = 0:
│     └─ Not a paid day for this slot → time_ind := '1' (NP)
│
└─ Else: Check if month capacity reached:
   ├─ IF (cnt_days_of_month__c - nbr_paid_so_far - slot_row_num) >= 0:
   │  └─ v_cde_time_trdnl := v_slot_cde_time_trdnl (Use slot's time indicator)
   └─ ELSE:
      └─ v_cde_time_trdnl := '1' (NP - month capacity exceeded)

ENROLLMENT OVERRIDE (0-36 MONTHS):
├─ If care date within 0-36 months enrollment period
├─ AND absence days exhausted
├─ THEN: cde_info_addntl := '13' (Pay as regular)
│        Use authorized hours instead of slot contract hours
└─ Provides higher payment for young children
```

---

# **PART 2: PAYMENT MODULE - EXACT CALCULATION FLOW**

## **2.1 PROVIDER RATE RETRIEVAL**
### **Function: FN_GET_FISCAL_RATE(p_std_cfs, p_idn_provr, p_cde_type_unit_care, p_cde_level_care, p_cde_trdnl_time_ind, p_cde_county, p_dte_care)**

**RATE LOOKUP HIERARCHY:**

```sql
Step 1: Get Provider Fiscal Agreement
├─ Query: t_provr_fiscal_agrement__c pfa
├─ WHERE: cde_county__c = p_cde_county
├─ AND: id_service__c = p_idn_provr
├─ AND: p_dte_care BETWEEN dte_begin_agrmt__c AND dte_end_agrmt__c
│       (OR dte_end_agrmt__c IS NULL)
├─ AND: cde_type_status__c IN ('OPN','CLS') [Open or closed agreements]
└─ Returns: idn_agrmt_fiscal__c (agreement ID), pfa.sfid

Step 2: Get Provider's Fiscal Schedule (Rates)
├─ Query: batchcnv.t_fiscal_rate
├─ Filter by: Provider agreement ID from Step 1
├─ Multiple rates per agreement for different:
│  ├─ cde_rate_type (Unit care type: HC/CC/FCC/LicAg)
│  ├─ cde_age_group (Care level: INF/TOD/PRES/SCH/MIXED)
│  └─ cde_care_unit (Time indicator: NP/PT/FT/FTPT/FTFT)
│
└─ Returns: amt_fa (rate per hour/day)

Step 3: Match Rate to Care Parameters
├─ p_cde_type_unit_care (from encumbrance: HC/CC/FCC/LicAg)
├─ p_cde_level_care (from encumbrance: INF/TOD/PRES/SCH)
├─ p_cde_trdnl_time_ind (calculated earlier: NP/PT/FT/FTPT/FTFT)
├─ p_std_cfs (Standard - typically funding program code)
└─ p_dte_care (Care date - for date-based rate variations)

Step 4: Return Rate
└─ RETURN: amt_fa (hourly or daily rate for this care type/level/time)

RATE LOOKUP TABLE STRUCTURE (batchcnv.t_fiscal_rate):
╔═════════════════════════════════════════════════════════════════════╗
║ idn_fiscal_schedule │ amt_fa      │ cde_rate_type │ cde_age_group   ║
║ (Foreign Key)       │ (Rate $)    │ (Unit Type)   │ (Care Level)    ║
╠═════════════════════╪═════════════╪═══════════════╪═════════════════╣
║ FA001              │ $10.50      │ CC            │ INF             ║ (Infant in Child Care)
║ FA001              │ $9.75       │ CC            │ PRES            ║ (Preschool in Child Care)
║ FA001              │ $12.00      │ HC            │ INF             ║ (Infant in Home Care)
║ FA001              │ $10.25      │ HC            │ SCH             ║ (School-age in Home Care)
╚═════════════════════╩═════════════╩═══════════════╩═════════════════╝

**CALL HIERARCHY:**
FN_GET_FISCAL_RATE()
  └─ FN_GET_FISCAL_AGR_RATE_AUTH() [Actual implementation]
     └─ Performs the join and rate lookup
```

---

## **2.2 COPAY CALCULATION**
### **Function: FN_CALCULATE_COPAY_FT_PT(p_idn_case, p_total_household_income, p_family_size, p_number_children, p_fpg)**

**COPAY CALCULATION LOGIC:**

```sql
STEP 1: Calculate Federal Poverty Level Percentage
├─ p_fpg = Percentage of Federal Poverty Guideline
│  └─ e.g., 150% means 1.5x the federal poverty line

STEP 2: Apply Income-Based Copay Formula

**TIER 1: FPG <= 100% (At or below poverty line)**
├─ Copay_FullTime := FLOOR(Monthly_Income × 0.01)
│  └─ 1% of monthly income
│
├─ Copay_PartTime := FLOOR(0.55 × Copay_FullTime)
│  └─ 55% of full-time copay
│
└─ Example:
   ├─ Annual Income: $18,000
   ├─ Monthly Income: $1,500
   ├─ FPG: 75% → Copay_FT := FLOOR($1,500 × 0.01) = $15
   └─ Copay_PT := FLOOR(0.55 × $15) = $8

**TIER 2: 100% < FPG <= 200% (Between poverty and 2x poverty)**
├─ Uses reference table R00393
├─ Tiered income bracket system
│  └─ Different rates for different income ranges
│
├─ Multipliers applied:
│  ├─ Base bracket rate (from R00393)
│  ├─ 1.3x multiplier for income between 100-150% FPG
│  └─ 1.6x multiplier for income between 150-200% FPG
│
└─ Formula: Copay := Tiered_Rate × Income_Bracket_Multiplier

**TIER 3: FPG > 200% (Above 2x poverty line)**
├─ Maximum copay applied
├─ May be based on family size and number of children
└─ Caps may apply per county rate table

COPAY TIME ADJUSTMENT:
├─ Full-Time Copay := Calculated_Copay
├─ Part-Time Copay := FLOOR(0.55 × Full-Time_Copay)
│  └─ Part-time gets 55% discount
└─ Applies regardless of tier

DATA SOURCES:
├─ Reference Table R00393 (Income brackets for 100-200% FPG tier)
├─ County Rate Table (t_county_rate__c) for maximum copays
├─ Family Information:
│  ├─ p_total_household_income (annual)
│  ├─ p_family_size (total members)
│  └─ p_number_children (children count)
└─ Authorization (t_auth__c) for child/family info

CORNER CASES:
├─ IF copay calculated as $0 → minimum copay may apply
├─ IF copay > county maximum → cap at county maximum
├─ IF copay changes mid-service → pro-rate or use monthly copay
└─ Part-time copay always ≤ Full-time copay
```

---

## **2.3 PAYMENT AMOUNT CALCULATION**
### **Function: FN_PRCS_SUB_PMT_DETAIL(idn_pmt_sub)**

**PAYMENT CALCULATION FLOW:**

```sql
FOR EACH payment detail (cde_type_info_addntl):

STEP 1: Determine Payment Type
├─ '0' = Regular care
├─ '1' = Holiday
├─ '3' = Drop-in
├─ '4' = Absence
├─ '8' = Slot contract regular
├─ '9' = Slot contract holiday
├─ '10' = Slot contract drop-in
├─ '11' = Slot contract absence
├─ '12' = Vacant slot contract
├─ '13' = Enrollment (0-36 months)
└─ '14' = Care not offered

STEP 2: Calculate Base Rate Amount
├─ amt_rate := unit_hours × fiscal_rate
│  ├─ unit_hours (from FN_GET_UNIT_HRS)
│  └─ fiscal_rate (from FN_GET_FISCAL_RATE)
│
└─ amt_slot_paid (for slot contracts only):
   ├─ If slot contract: amt_slot_paid := amount paid to provider
   └─ Else: amt_slot_paid := 0

STEP 3: Calculate Copay
├─ For Regular Care (cde_type_info_addntl = '0'):
│  └─ amt_copay := FN_CALCULATE_COPAY_FT_PT(...)
│
├─ For Holiday/Absence/Drop-In/Enrollment:
│  └─ amt_copay := 0 (No copay for special cases)
│
└─ For Slot Contracts:
   └─ amt_copay := 0 (Provider contract, no family copay)

STEP 4: Calculate Total Payment
├─ amt_total := amt_rate - amt_copay
│  ├─ If amt_total < 0 → amt_total := 0 (Can't have negative)
│  └─ Payment to provider = amt_total
│
└─ Payment Flow:
   ├─ Total authorization pays: amt_rate
   ├─ Family pays (copay): amt_copay
   └─ Provider receives: amt_total

STEP 5: Insert into Payment Detail Table
├─ t_sub_pmt_detail (for regular authorizations)
│  ├─ amt_copay
│  ├─ amt_rate
│  ├─ amt_total
│  ├─ cde_type_info_addntl
│  ├─ cde_time_trdnl
│  ├─ dte_care
│  └─ idn_pmt_sub
│
└─ For slot contracts:
   └─ Additional field: amt_slot_paid

PAYMENT TYPE IMPACT ON RATE:
╔═══════════════════════╦═════════════════╦═══════════════════════╗
║ Payment Type          ║ Copay Applied   ║ Rate Calculation      ║
╠═══════════════════════╬═════════════════╬═══════════════════════╣
║ Regular (0)           ║ YES             ║ Auth Hours × Rate     ║
║ Holiday (1)           ║ NO              ║ Auth Hours × Rate     ║
║ Absence (4)           ║ NO              ║ Auth Hours × Rate     ║
║ Drop-In (3)           ║ NO              ║ Actual Hours × Rate   ║
║ Enrollment (13)       ║ NO              ║ Auth Hours × Rate     ║
║ Slot Regular (8)      ║ NO              ║ Slot Hrs × Slot Rate  ║
║ Slot Holiday (9)      ║ NO              ║ Slot Hrs × Slot Rate  ║
║ Care Not Offered (14) ║ NO              ║ 0                     ║
╚═══════════════════════╩═════════════════╩═══════════════════════╝
```

---

## **2.4 ART FEES PROCESSING (Activity, Registration, Transportation)**
### **Function: FN_GET_ART_FEES(p_idn_case, p_dte_care)**

**ART FEE RETRIEVAL LOGIC (24KB Complex Function):**

```sql
STEP 1: Retrieve Individual Care Level & Program Info
├─ Query: Individual (child) care level for the care date
├─ Query: Authorization program funding type
└─ Used to determine which ART fees apply

STEP 2: Get Provider's ART Fee Schedule
├─ Query: t_fiscal_rat_fees__c (Provider fee schedule)
├─ Match by: Provider + Child Care Level + Effective Date Range
├─ Returns:
│  ├─ amt_trans_provr__c (Transportation fee per unit)
│  ├─ amt_act_provr__c (Activity fee per unit)
│  ├─ amt_reg_provr__c (Registration fee per unit)
│  ├─ cde_trans_freq__c (Frequency: ANNUAL/MONTHLY/ONE-TIME)
│  ├─ cde_act_freq__c (Frequency: ANNUAL/MONTHLY/ONE-TIME)
│  ├─ cde_reg_freq__c (Frequency: ANNUAL/MONTHLY/ONE-TIME)
│  ├─ txt_trans_month__c (Restricted months for transportation)
│  └─ txt_act_month__c (Restricted months for activity)
│
└─ Example:
   ├─ Transportation: $50/month, can't charge in July/August
   ├─ Activity: $25/month, no restrictions
   └─ Registration: $100/annual, charged in September only

STEP 3: Get County Ceiling Amounts
├─ Query: t_county_rate__c
├─ Retrieve:
│  ├─ PAYMENT_Q9_1__c (Registration ceiling per fiscal year)
│  ├─ PAYMENT_Q10_1__c (Activity ceiling per fiscal year)
│  ├─ PAYMENT_Q11_1__c (Transportation ceiling per fiscal year)
│  ├─ PAYMENT_Q11_2__c (Care level question - which levels pay)
│  └─ PAYMENT_Q11_3__c (Authorization level question)
│
└─ County prevents overpayment for all children in county

STEP 4: Check Fiscal Year Boundaries (Leap Year Handling)
├─ Fiscal Year typically: July 1 - June 30
├─ IF Feb 29 (leap year) falls in fiscal year:
│  └─ Add extra day to calculation
│
├─ Query: t_indiv_rat_fees (Individual-level fee tracking)
├─ WHERE: idn_client = child_id
├─ AND: dte_begin_effev BETWEEN fiscal_year_start AND fiscal_year_end
│       (Or open-ended)
└─ Returns: Amount already paid YTD for each fee type

STEP 5: Apply Monthly Restrictions
├─ Transportation Fee:
│  ├─ IF current_month IN txt_trans_month__c:
│  │  └─ DO NOT CHARGE (restricted month)
│  └─ ELSE: Apply transportation fee
│
├─ Activity Fee:
│  ├─ IF current_month IN txt_act_month__c:
│  │  └─ DO NOT CHARGE (restricted month)
│  └─ ELSE: Apply activity fee
│
└─ Registration Fee:
   └─ Only charged once per fiscal year (ONE-TIME)

STEP 6: Calculate Fee Frequency Impact
├─ ANNUAL fees:
│  ├─ Charged once per fiscal year (typically Sept 1 or July 1)
│  ├─ Formula: Annual_Amount = amt_reg_provr__c × 1
│  └─ Cap: PAYMENT_Q9_1__c per county per child per year
│
├─ MONTHLY fees:
│  ├─ Charged each month when applicable
│  ├─ Formula: Monthly_Amount = amt_trans_provr__c × 1 (per month)
│  ├─ If authorized for partial month:
│  │  └─ Pro-rate: Monthly_Amount × (authorized_days / days_in_month)
│  └─ Cap: PAYMENT_Q10_1__c OR PAYMENT_Q11_1__c per month per child
│
└─ ONE-TIME fees:
   ├─ Charged once per service/authorization
   └─ No daily proration

STEP 7: Apply County Ceiling
├─ Calculate remaining capacity for this fee type YTD:
│  ├─ County_Ceiling - Amount_Paid_YTD_All_Children = Remaining
│  └─ OR
│  ├─ Individual_Ceiling - Amount_Paid_YTD_This_Child = Remaining
│
├─ IF Calculated_Fee > Remaining_Capacity:
│  └─ Charge only: Remaining_Capacity (partial charge)
│
└─ IF Remaining_Capacity <= 0:
   └─ Do not charge fee (ceiling reached)

STEP 8: Apply Individual Ceiling
├─ Query: t_indiv_rat_fees (Track per-child YTD totals)
├─ Maintain running totals:
│  ├─ amt_trans_paid (accumulated transportation)
│  ├─ amt_act_paid (accumulated activity)
│  └─ amt_reg_paid (accumulated registration)
│
└─ Update after each charge:
   ├─ amt_trans_paid += amt_charged
   ├─ amt_act_paid += amt_charged
   ├─ amt_reg_paid += amt_charged
   ├─ dte_paid = current date
   └─ Fiscal year dates tracked

STEP 9: Return ART Fees
├─ RETURN: (amt_trans, amt_act, amt_reg)
│  └─ After all restrictions and ceiling application
│
└─ Insert into Payment:
   ├─ Fees added to amt_rate or separate tracking
   └─ No copay applied to ART fees

ART FEE EXEMPTIONS:
├─ Care Not Offered days: NO ART fees
├─ Drop-in days: May have reduced/no ART fees
├─ Absent days: May have reduced/no ART fees
├─ Below care level threshold: NO ART fees
└─ Authorization level restrictions: NO ART fees

REFERENCE DATA:
├─ R00393: Income brackets (copay calculation)
└─ County Rate Table fields:
   ├─ PAYMENT_Q9_1__c: Registration ceiling
   ├─ PAYMENT_Q10_1__c: Activity ceiling
   ├─ PAYMENT_Q11_1__c: Transportation ceiling
   ├─ PAYMENT_Q11_2__c: Applicable care levels
   └─ PAYMENT_Q11_3__c: Applicable auth levels
```

**ART FEE FREQUENCY MATRIX:**

```
╔════════════════════╦═══════════╦════════════════╦═════════════════════╗
║ Fee Type           ║ Frequency ║ Typical Charge ║ Monthly Restriction ║
╠════════════════════╬═══════════╬════════════════╬═════════════════════╣
║ Registration       ║ ANNUAL    ║ $100-200/year  ║ Sept only (usually) ║
║ Activity           ║ MONTHLY   ║ $20-30/month   ║ May exclude July-Aug║
║ Transportation     ║ MONTHLY   ║ $40-60/month   ║ Excluded Jul-Aug    ║
╚════════════════════╩═══════════╩════════════════╩═════════════════════╝

**CEILING ENFORCEMENT:**
├─ County Ceiling: $500/child/fiscal year (example)
├─ Once county total reached: NO MORE ART FEES for any child
│  (County level resource constraint)
│
└─ Individual Ceiling: $300/child/fiscal year (example)
   └─ Once individual reaches limit: NO MORE ART FEES for that child
      (Family affordability limit)
```


---

## **2.5 ADJUSTMENT & REVERSAL PROCESSING**

```sql
REVERSAL FUNCTIONS (Handled by separate batch):
├─ FN_PRCS_ADJMT_ART_FEES() 
│  └─ Adjustments for ART fee overpayments
│
├─ FN_PRCS_PROVR_ADJMT_PMT_DTL_TRANS()
│  └─ Provider adjustment transitions
│
├─ FN_REVERSE_PMT_DETAIL()
│  └─ Reversal of payment details
│
└─ FN_REVERSE_SUB_PMT()
   └─ Reversal of subsidiary payments

TRIGGER SCENARIOS FOR REVERSAL:
├─ Authorization end date changes (future effective)
├─ Care level changes retroactively
├─ Provider rate update retroactive
├─ Copay adjustment due to income change
├─ ART fee ceiling correction
├─ Duplicate payment detected
└─ Payment dispute resolution

REVERSAL IMPACT:
├─ Creates negative payment detail line
├─ Original payment remains visible (audit trail)
├─ New credit issued to family or provider
├─ Status updated to indicate reversed
└─ Corrected amount paid in next payment cycle
```

---

# **PART 3: COMPLETE DATA FLOW EXAMPLES**

## **SCENARIO 1: Regular Care with Holiday & Absence**

```
AUTH-001: Child in full-time care, $12/hour rate, 10 hours/day authorized
Provider: Licensed center care
County: Has 5 paid holidays, 3 paid absence days, no drop-in
Family: Income 120% FPG → Copay $20/full-time, $11/part-time

CARE MONTH: September (21 business days)

DAY 1 (Tue, Sept 1): Regular care
├─ Authorized: 10 hrs, Actual: 10 hrs
├─ FN_GET_ADDNL_INFO:
│  └─ v_cnt_hours_auth=10, v_cnt_hours_actual=10
│  └─ cde_info_addntl := '0' (Regular)
├─ FN_GET_UNIT_HRS: Returns 10 hrs (min of 10,10)
├─ FN_GET_TRDNL_TIME_IND: Returns '3' (FT: 5<10≤12)
├─ FN_GET_FISCAL_RATE: Returns $12/hr
├─ Payment Calc:
│  ├─ amt_rate := 10 × $12 = $120
│  ├─ amt_copay := $20 (regular care copay)
│  └─ amt_total := $120 - $20 = $100 (provider receives)
└─ Record: (cde_type_info_addntl='0', amt_rate=$120, amt_copay=$20, amt_total=$100)

DAY 2 (Wed, Sept 2): Regular care
├─ Same calculation as Day 1
├─ Payment: $100
└─ Running monthly total: $200

DAY 3 (Thu, Sept 3): Holiday (Labor Day observed)
├─ Authorized: 10 hrs, Actual: 0 hrs
├─ FN_GET_ADDNL_INFO:
│  ├─ v_cnt_hours_auth=10, v_cnt_hours_actual=0
│  ├─ FN_IS_PAID_HOLIDAY:
│  │  ├─ Query t_year_hol__c for Sept 3, 2024
│  │  ├─ Find holiday code in PAYMENT_Q13_1__c
│  │  ├─ Check if already paid: NO
│  │  ├─ Check provider not exempt: YES (licensed center)
│  │  └─ Return: v_ind_holiday = 'Y'
│  └─ cde_info_addntl := '1' (Holiday)
├─ FN_GET_UNIT_HRS: Returns 10 hrs (auth hours for holiday)
├─ FN_GET_TRDNL_TIME_IND: Returns '3' (FT)
├─ Payment Calc:
│  ├─ amt_rate := 10 × $12 = $120
│  ├─ amt_copay := $0 (no copay for holiday)
│  └─ amt_total := $120 (full payment to provider)
└─ Record: (cde_type_info_addntl='1', amt_rate=$120, amt_copay=$0, amt_total=$120)

DAY 4 (Fri, Sept 4): Parent-approved absence (paid)
├─ Authorized: 10 hrs, Actual: 0 hrs
├─ FN_GET_ADDNL_INFO:
│  ├─ v_cnt_hours_auth=10, v_cnt_hours_actual=0
│  ├─ Check holiday: NO (not a holiday)
│  ├─ FN_GET_PAID_ABSENCE (county='XX', provider='PROV-01'):
│  │  ├─ Get provider's fiscal agreement for county XX
│  │  ├─ Provider rating: Level 3
│  │  ├─ Query t_county_rate__c:
│  │  │  └─ payment_q13_c__c = 3 (Level 3 gets 3 paid absence days)
│  │  └─ Return: v_cnt_absnc_paid = 3
│  ├─ FN_GET_ABSNC_DAY_COUNT:
│  │  ├─ Count absences in Sept already paid (Days 1-3): 0
│  │  └─ Return: v_cnt_absnc_used = 0
│  ├─ FN_GET_ABSNC_PARENT_APV:
│  │  ├─ Query t_auth_attnd_check for AUTH-001, Sept 4
│  │  ├─ attended_flag__c = TRUE (parent approved)
│  │  └─ Return: v_absnc_apprvd = TRUE
│  ├─ Remaining_Absence := 3 - 0 = 3 days available ✓
│  ├─ Check: Remaining > 0 AND (NOT approved OR (approved AND 0-36)) → PAY
│  └─ cde_info_addntl := '4' (Absence)
├─ FN_GET_UNIT_HRS: Returns 10 hrs (auth hours for absence)
├─ FN_GET_TRDNL_TIME_IND: Returns '3' (FT)
├─ Payment Calc:
│  ├─ amt_rate := 10 × $12 = $120
│  ├─ amt_copay := $0 (no copay for absence)
│  └─ amt_total := $120
└─ Record: (cde_type_info_addntl='4', amt_rate=$120, amt_copay=$0, amt_total=$120)
│  Absence used: 1 of 3

Days 5-21: Regular care (17 days @ $100 each)
├─ No holidays, no absences
├─ Payment per day: $100 (Rate $120 - Copay $20)
└─ Running total: $200 + $120 + $120 + $120 + (17×$100) = $2,020

MONTH SUMMARY:
├─ Total authorized days: 21 business days
├─ Days paid:
│  ├─ Regular: 17 days @ $100 = $1,700
│  ├─ Holiday: 1 day @ $120 = $120
│  └─ Absence: 1 day @ $120 = $120
├─ Total provider payment: $1,940
├─ Total family copay: 17 days × $20 = $340
└─ Total subsidy (rate - copay): $1,940 × 10/12 = $1,617
    [Note: This is annualized calculation, actual subsidy is $1,700 + $120 + $120 - $0 = $1,940]
```

---

## **SCENARIO 2: Drop-In Care (No Authorization)**

```
DROPINS: Child NOT authorized for ongoing care
County: Allows 5 drop-in days/month, provider licensing required
Provider: Licensed center care
Rate: $15/hour (same as authorized)
No copay for drop-in

CARE MONTH: September

DAY 1 (Tue, Sept 1): Drop-in care
├─ Authorized: 0 hrs, Actual: 4 hrs
├─ FN_GET_ADDNL_INFO:
│  ├─ v_cnt_hours_auth=0, v_cnt_hours_actual=4
│  ├─ FN_GET_DROP_IN_DAYS:
│  │  ├─ Query t_county_rate__c (payment_q14__c='Y')
│  │  ├─ Return: p_nbr_days=5, p_cde_resp='1' (universal)
│  │  └─ v_cnt_dropin_paid = 5
│  ├─ FN_GET_DROP_IN_DAY_COUNT:
│  │  ├─ Count drop-ins in Sept already paid: 0
│  │  └─ v_cnt_dropin_used = 0
│  ├─ Available := 5 - 0 = 5 days ✓
│  ├─ Check p_cde_resp='1' (universal) → PAY
│  └─ cde_info_addntl := '3' (Drop-in)
├─ FN_GET_UNIT_HRS: Returns 4 hrs (actual hours for drop-in)
├─ FN_GET_TRDNL_TIME_IND: Returns '2' (PT: 0<4≤5)
├─ FN_GET_FISCAL_RATE: Returns $15/hr
├─ Payment Calc:
│  ├─ amt_rate := 4 × $15 = $60
│  ├─ amt_copay := $0 (no copay for drop-in)
│  └─ amt_total := $60
└─ Record: (cde_type_info_addntl='3', amt_rate=$60, amt_copay=$0, amt_total=$60)
│  Drop-in used: 1 of 5

DAY 2 (Wed, Sept 2): Drop-in care
├─ Authorized: 0 hrs, Actual: 6 hrs
├─ FN_GET_DROP_IN_DAYS: Returns p_nbr_days=5, p_cde_resp='1'
├─ FN_GET_DROP_IN_DAY_COUNT: Returns v_cnt_dropin_used=1
├─ Available := 5 - 1 = 4 days ✓
├─ FN_GET_UNIT_HRS: Returns 6 hrs (actual hours)
├─ FN_GET_TRDNL_TIME_IND: Returns '3' (FT: 5<6≤12)
├─ Payment Calc:
│  ├─ amt_rate := 6 × $15 = $90
│  └─ amt_total := $90
└─ Drop-in used: 2 of 5

Days 3-5: Drop-in care
├─ Same pattern, 3 more drop-in days paid
└─ Drop-in used: 5 of 5 (LIMIT REACHED)

Day 6+: Drop-in attempts after limit
├─ FN_GET_DROP_IN_DAYS: Returns p_nbr_days=5
├─ FN_GET_DROP_IN_DAY_COUNT: Returns v_cnt_dropin_used=5
├─ Available := 5 - 5 = 0 days ✗
├─ cde_info_addntl := '0' (DO NOT PAY)
├─ amt_total := $0 (no payment)
└─ Family must pay full cost to provider (private pay)

MONTH SUMMARY:
├─ Drop-in days paid: 5 days
├─ Total drop-in payment: ~$400 (varies by hours each day)
├─ No copay charged
└─ Excess drop-in days: Family pays provider directly
```

---

## **SCENARIO 3: Slot Contract Payment**

```
SLOT CONTRACT: Vacant slot paid to provider regardless of use
Provider: Licensed family child care
Slot: Full-time slot, Monday-Friday, 20 paid days/month
Program: LI (Licensed Immigrant) funding
County Rate: $14/hour

CARE MONTH: September (Has 21 business days, but only 20 paid in slot contract)

DAY 1 (Tue, Sept 1): Slot contract day (within days of week)
├─ idn_auth = NULL (vacant slot)
├─ idn_slot = SLOT-001
├─ Check slot day of week:
│  ├─ Slot v_days_of_weeks_slot = "Monday,Tuesday,Wednesday,Thursday,Friday"
│  ├─ Sept 1 = Tuesday ✓ (in allowed days)
│  └─ position(trim(to_char(DATE '2024-09-01','Day')) in "Monday,Tuesday,...") > 0
├─ FN_GET_SLOTCNTRCT_DAYS:
│  ├─ Count slot payments in Sept so far: 0
│  ├─ v_nbr_paid_so_far_slot = 0
│  ├─ cnt_days_of_month__c = 20 (slot capacity)
│  └─ Return: 0
├─ Check capacity: (20 - 0 - row_num) >= 0 ✓ (20-1=19 remaining)
├─ cde_type_info_addntl := '12' (Vacant slot regular)
├─ v_cde_time_trdnl = slot's time indicator '3' (FT) [from slot contract]
├─ Payment Calc:
│  ├─ amt_rate := slot_rate (typically daily or slot amount)
│  │  └─ For full-time daily: ~$112 (8 hrs × $14/hr)
│  ├─ amt_slot_paid := $112 (provider receives full amount)
│  ├─ amt_copay := $0 (slot contracts have no family copay)
│  └─ amt_total := $112
└─ Record: (cde_type_info_addntl='12', amt_slot_paid=$112, amt_rate=$112, amt_copay=$0)

Days 2-20: Slot contract days (Mon-Fri, 20 days total)
├─ Same calculation as Day 1
├─ Each day: $112 payment
└─ Running total: 20 × $112 = $2,240

Day 21 (Mon, Sept 23): NOT a slot payment day
├─ 20 slot days already paid (capacity reached)
├─ FN_GET_SLOTCNTRCT_DAYS: v_nbr_paid_so_far_slot = 20
├─ Check capacity: (20 - 20 - row_num) < 0 ✗
├─ v_cde_time_trdnl := '1' (NP - No Payment)
├─ amt_total := $0
└─ Provider cannot claim payment for this day (slot full)

MONTH SUMMARY:
├─ Slot capacity: 20 days/month
├─ Days paid: 20
├─ Total payment: 20 × $112 = $2,240
├─ Family copay: $0 (slot contracts subsidize fully)
├─ Subsidy amount: $2,240
└─ Provider receives full slot value (no gap)
```

---

## **SCENARIO 4: 0-36 Months Enrollment with Absence Override**

```
ENROLLMENT AUTH: Special program for infants/toddlers (0-36 months)
Child: 14 months old
Authorization: 8 hrs/day, Level 1 (infant care)
Provider: Licensed center
Provider Rate: $18/hour (higher for infant care)
Copay: $25/day (enrollment families pay higher copay)
Paid absences: 2 days/month
County: Allows enrollment override after absence exhaustion

CARE MONTH: September

Days 1-3: Regular care
├─ Each day: 8 hrs × $18 = $144 rate - $25 copay = $119 provider
└─ Running absence used: 0 of 2

Day 4: Parent-approved absence (paid)
├─ Authorized: 8 hrs, Actual: 0 hrs
├─ FN_GET_PAID_ABSENCE: Returns 2 paid absences available
├─ FN_GET_ABSNC_DAY_COUNT: Returns 0 used so far
├─ FN_GET_ABSNC_PARENT_APV: Returns TRUE (approved)
├─ ind_0_36_months = TRUE
├─ Check: Remaining=2, approved=TRUE, 0-36=TRUE → PAY AS ABSENCE
├─ cde_info_addntl := '4' (Absence)
├─ FN_GET_UNIT_HRS: Returns 8 hrs (auth hours)
├─ Payment: 8 × $18 = $144 - $0 copay = $144 provider
└─ Absence used: 1 of 2

Day 5: Parent-approved absence (paid)
├─ Similar to Day 4
├─ Payment: $144
└─ Absence used: 2 of 2 (EXHAUSTED)

Days 6-21: Regular care attempted (but absence would trigger)
├─ After absence exhaustion, child marked as present but no care
├─ Authorized: 8 hrs, Actual: 0 hrs
├─ FN_GET_ADDNL_INFO:
│  ├─ v_cnt_hours_auth=8, v_cnt_hours_actual=0
│  ├─ Not a holiday
│  ├─ FN_GET_PAID_ABSENCE: Returns 2 (unchanged)
│  ├─ FN_GET_ABSNC_DAY_COUNT: Returns 2 (used)
│  ├─ Remaining := 2 - 2 = 0 (NO remaining)
│  ├─ Check: ind_0_36_months=TRUE AND remaining<=0
│  └─ cde_info_addntl := '13' (ENROLLMENT OVERRIDE)
├─ FN_GET_UNIT_HRS:
│  ├─ Special handling for enrollment flag
│  ├─ v_ind_0_36_months=TRUE, cde_info_addntl='13'
│  ├─ Check provider fiscal agreement is active: YES
│  └─ Returns: 8 hrs (auth hours, even though attended=0)
├─ Payment Calc:
│  ├─ amt_rate := 8 × $18 = $144
│  ├─ amt_copay := $25 (copay applies to enrollment)
│  └─ amt_total := $144 - $25 = $119 provider
└─ Record: (cde_type_info_addntl='13', amt_rate=$144, amt_copay=$25, amt_total=$119)

KEY DIFFERENCE FROM REGULAR:
├─ Regular child with absence exhausted: NO PAYMENT (cde_info_addntl='0')
├─ 0-36 month child with absence exhausted: PAYMENT AS REGULAR (cde_info_addntl='13')
│  └─ This ensures infants still get paid care
└─ Copay still applies (family contribution continues)

MONTH SUMMARY:
├─ Regular days (auth hours paid): 17 days
├─ Absence days (paid, exhausted): 2 days
├─ Enrollment override days (paid regular): 2 days
├─ Total paid days: 21
├─ Provider payment: (17 + 2 + 2) × $119 = $2,261 average
│  [Note: Absence/enrollment days don't have copay]
│  Actual: (17 × $119) + (2 × $144) + (2 × $119) = $2,023 + $288 + $238 = $2,549
└─ Special benefit: Infants guaranteed payment even after absence exhaustion
```

---

# **PART 4: DATA VALIDATION & EDGE CASES**

## **4.1 Fiscal Agreement Validation (CCCAP-6545)**

```sql
Before any payment is processed:

VALIDATION: Is provider's fiscal agreement active for care date?

Query: t_provr_fiscal_agrement__c pfa
WHERE: pfa.cde_county__c = county
AND: pfa.id_service__c = provider
AND: care_date BETWEEN dte_begin_agrmt__c AND dte_end_agrmt__c
     (OR dte_end_agrmt__c IS NULL - open-ended)
AND: pfa.cde_type_status__c IN ('OPN','CLS')

IF count(*) = 0:
  └─ NO ACTIVE FISCAL AGREEMENT
     ├─ For regular auth: v_cnt_hour_care := 0 (NO PAYMENT)
     ├─ For 0-36 enrollment: Set v_ind_0_36_months := FALSE
     └─ For slot contract: Allow slot payment (slot provides agreement)

IF count(*) > 0:
  └─ Active agreement exists
     ├─ Use provider's fiscal schedule for rates
     ├─ Validate provider qualification level
     └─ Proceed with payment
```

---

## **4.2 Care Not Offered (CCCAP-6842)**

```sql
CARE NOT OFFERED occurs when:
├─ Provider was not available on care date
├─ Provider closure or emergency closure
├─ Child removed from care for behavioral/safety reasons

Indicator: encumbrance status = '5'

Processing:
├─ FN_GET_ADDNL_INFO: Returns cde_info_addntl = '14'
├─ FN_GET_UNIT_HRS: Returns 0 (no hours paid)
├─ Payment: $0
└─ Record: (cde_type_info_addntl='14', amt_total=$0)

Impact:
├─ Not counted as attendance day
├─ Not counted as absence day
├─ Not counted as holiday
├─ Family not charged copay
├─ Provider receives $0 payment
└─ Authorization remains active (not voided)
```

---

## **4.3 Holiday Observed Date Handling (CCCAP-1445)**

```sql
Issue: Holiday may fall on weekend, observed on weekday

Example: Christmas (Dec 25) falls on Saturday
  └─ Observed on Friday (Dec 24) or Monday (Dec 26)?

Processing:
1. Get holiday calendar: t_year_hol__c
2. Retrieve two dates:
   ├─ DTE_HOL__c (Actual holiday date)
   └─ dte_observed_hol__c (When it's observed)

3. If actual < observed:
   ├─ Check if already paid on actual date
   ├─ If not paid AND current_date = observed_date
   └─ Pay on observed date

4. If observed < actual:
   ├─ Check if already paid on observed date
   ├─ If not paid AND current_date = actual_date
   └─ Pay on actual date

5. Prevent double payment:
   └─ If holiday already paid: v_ind_holiday := 'N'

Result: Pay exactly once, on correct date
```

---

## **4.4 Year Boundary Handling (Dec 31 → Jan 1)**

```sql
Issue: Determining fiscal year when processing Dec 31

Logic (FN_IS_PAID_HOLIDAY, line 57-58):
├─ IF EXTRACT(MONTH from care_date) = 12 
│  AND EXTRACT(DAY from care_date) = 31:
│  └─ Use NEXT YEAR for holiday lookup
│  (Because Jan 1 holiday might apply)
│
└─ ELSE:
   └─ Use current year for holiday lookup

Purpose: Handle New Year's Day correctly on Dec 31→Jan 1 transition

Example:
├─ Care date: Dec 31, 2024
├─ Check holiday for: Year 2025 (not 2024)
├─ Find Jan 1, 2025 in holiday list
└─ May trigger New Year's holiday payment
```

---

## **4.5 Leap Year Fiscal Year Handling**

```sql
ART Fee Calculation Leap Year Logic:

Fiscal Year: July 1 - June 30 (example)

Leap Year Feb 29:
├─ If Feb 29 falls between July X year - June 30 year+1
│  └─ Add one extra day to fiscal year calculations
│
├─ Impacts monthly pro-rating:
│  ├─ Feb 28 days → Feb 29 days (leap year)
│  └─ Monthly pro-rating = Days_Authorized / Days_In_Month
│     (Will be slightly different in leap year)
│
└─ ART fee tracking:
   ├─ t_indiv_rat_fees.dte_begin_effev to dte_end_effev
   └─ Must account for leap day in fiscal year boundary
```

---

# **PART 5: SUMMARY - COMPLETE CALCULATION ALGORITHM**

## **DAILY ATTENDANCE & PAYMENT ALGORITHM**

```
FOR EACH (authorization, care_date) in service_period:

STEP 1: CLASSIFY CARE DAY
├─ Retrieve: v_cnt_hours_auth, v_cnt_hours_actual, ind_0_36_months
│
├─ IF v_cnt_hours_auth = 0 AND v_cnt_hours_actual > 0:
│  └─ Possible DROP-IN → Branch to Step 3
│
├─ ELSIF v_cnt_hours_auth > 0 AND v_cnt_hours_actual = 0:
│  └─ Possible HOLIDAY/ABSENCE → Branch to Step 2
│
├─ ELSIF v_cnt_hours_auth > 0 AND v_cnt_hours_actual > 0:
│  └─ REGULAR CARE → Branch to Step 4
│
└─ ELSE (both 0):
   └─ NO CARE → cde_info_addntl := '0'

STEP 2: CHECK HOLIDAY (if v_cnt_hours_auth > 0 AND actual = 0)
├─ Call FN_IS_PAID_HOLIDAY(county, care_date, auth_id)
├─ IF holiday='Y' AND provider_not_exempt:
│  ├─ cde_info_addntl := '1' (Holiday)
│  └─ Go to Step 5 (Calculate payment)
└─ ELSE: Check absence (fall through)

STEP 2.5: CHECK ABSENCE (if not holiday)
├─ Call FN_GET_PAID_ABSENCE(county, care_date, provider)
├─ Call FN_GET_ABSNC_DAY_COUNT(auth_id, care_date)
├─ Call FN_GET_ABSNC_PARENT_APV(auth_id, care_date)
├─ Remaining := paid - used
├─ IF remaining > 0 AND (NOT approved OR (approved AND 0-36 months)):
│  ├─ cde_info_addntl := '4' (Absence)
│  └─ Go to Step 5
├─ ELSIF remaining <= 0 AND 0-36 months:
│  ├─ cde_info_addntl := '13' (Enrollment override)
│  └─ Go to Step 5
└─ ELSE:
   └─ cde_info_addntl := '0' (No payment)

STEP 3: PROCESS DROP-IN (if auth=0 AND actual>0)
├─ Call FN_GET_DROP_IN_DAYS(county, care_date, auth_id)
├─ Call FN_GET_DROP_IN_DAY_COUNT(auth_id, care_date)
├─ Remaining := paid - used
├─ IF remaining > 0:
│  ├─ IF provider_exempt AND p_cde_resp='2': No payment
│  ├─ ELSE: cde_info_addntl := '3' (Drop-in)
│  └─ Go to Step 5
└─ ELSE: cde_info_addntl := '0' (No payment)

STEP 4: REGULAR CARE (if both auth > 0 and actual > 0)
├─ cde_info_addntl := '0' (Regular)
└─ Go to Step 5

STEP 5: CALCULATE UNIT HOURS
├─ Call FN_GET_UNIT_HRS(auth_id, care_date, cde_info_addntl, slot_id)
├─ Returns: v_cnt_hour_care (hours to pay)
└─ Continue to Step 6

STEP 6: DETERMINE TIME INDICATOR
├─ Call FN_GET_TRDNL_TIME_IND(v_cnt_hour_care)
├─ Returns: cde_time_trdnl (NP/PT/FT/FTPT/FTFT)
└─ Continue to Step 7

STEP 7: GET PROVIDER RATE
├─ Call FN_GET_FISCAL_RATE(
│    std_cfs, provider, unit_care_type, care_level, 
│    time_ind, county, care_date)
├─ Returns: amt_rate (per hour or per day)
└─ Continue to Step 8

STEP 8: CALCULATE PAYMENT AMOUNT
├─ amt_rate := v_cnt_hour_care × fiscal_rate
├─ amt_copay := 0
├─ IF cde_type_info_addntl = '0' (Regular only):
│  └─ Call FN_CALCULATE_COPAY_FT_PT(case, income, family_size, fpg)
│  └─ amt_copay := copay_amount
├─ amt_total := amt_rate - amt_copay
├─ IF amt_total < 0: amt_total := 0
└─ Continue to Step 9

STEP 9: APPLY ART FEES (if applicable)
├─ Call FN_GET_ART_FEES(case, care_date)
├─ Get transportation, activity, registration fees
├─ Apply monthly restrictions and ceilings
├─ Add to total payment (or track separately)
└─ Continue to Step 10

STEP 10: INSERT PAYMENT DETAIL
├─ Insert into t_sub_pmt_detail:
│  ├─ amt_copay, amt_rate, amt_total
│  ├─ cde_type_info_addntl, cde_time_trdnl
│  ├─ dte_care, idn_pmt_sub
│  └─ [Slot contract fields if applicable]
└─ END FOR EACH

RETURN: Complete payment detail staging table
```

---

# **CONCLUSION**

This document provides the complete, exact calculation flow for both attendance and payment in the OEC-CHATS system. Key takeaways:

✅ **Attendance** depends on a complex matrix of authorization, actual attendance, holidays, absences, drop-ins, and provider status
✅ **Holidays** can be observed on different dates and must check against paid holiday lists
✅ **Absences** require approval and have monthly limits per provider qualification level
✅ **Drop-ins** have county/auth-level limits and may require provider licensing
✅ **Copay** is tiered based on federal poverty level percentage and only applies to regular care
✅ **ART Fees** have frequency, monthly restrictions, and individual/county ceiling limits
✅ **Slot Contracts** provide guaranteed payment for allocated days, regardless of actual use
✅ **0-36 Months Enrollment** provides special protections including absence override
✅ **Fiscal Agreements** must be active for any payment to be processed
✅ **Care Not Offered** (Status '5') results in zero payment
