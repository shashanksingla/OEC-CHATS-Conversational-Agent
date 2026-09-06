

Working on an agent to calculate attendance and payment as diff modules, what i need to get from this repo, objects and fields required for each module in a table and list of calculations done to calculate attendance and payment for a child , another table of schema mapping where relationships and primary fields of those objects are listed down



# OEC-CHATS-Conversational-Agent
Conversational Agent for OEC-CHATS Attendance &amp; Payment Module Calculations - Python-based implementation guide
Perfect! I can now provide you with a comprehensive overview of the OEC-CHATS PGSQL repository. Based on my analysis of the codebase, here's what you need for your agent to calculate **Attendance** and **Payment** as diff modules:

---

## **TABLE 1: Objects & Fields Required for Attendance & Payment Modules**

| **Module** | **Objects** | **Key Fields** |
|---|---|---|
| **ATTENDANCE** | `t_auth_encmbr` | `dte_care`, `cnt_hour_care`, `cde_type_unit_care`, `cde_level_care`, `idn_auth` |
| | `t_auth__c` (Salesforce) | `idn_extnl__c` (auth ID), `idn_provr__c`, `cde_county__c`, `cde_trans_fee__c` |
| | `t_sbsd_indiv__c` | Child/individual information, enrollment details |
| **PAYMENT** | `t_sub_pmt_detail` | `dte_care`, `cde_level_care`, `idn_fiscal_rat_fee`, `amt_*` (various amounts) |
| | `t_indiv_rat_fees` | `amt_trans_paid`, `amt_act_paid`, `amt_reg_paid`, `dte_begin_effev`, `dte_end_effev` |
| | `t_fiscal_rat_fees__c` | `amt_trans_provr__c`, `amt_reg_provr__c`, `amt_act_provr__c`, frequencies |
| | `t_county_rate__c` | `PAYMENT_Q9_1__c`, `PAYMENT_Q10_1__c`, `PAYMENT_Q11_1__c` (fee ceilings) |
| | `t_copay_calculation` | `percentage_min_value`, `percentage_max_value`, `amt_fee_base_parent` |

---

## **TABLE 2: Calculations for Attendance & Payment (Per Child)**

### **A. ATTENDANCE CALCULATION**
```
Attendance Info = [Unit Care Type] + [Time Indicator] + [Fiscal Rate]

Components:
1. Unit Care Type: Retrieved from t_auth_encmbr.cde_type_unit_care (R00683 reference table)
2. Time Indicator: FN_GET_TRDNL_TIME_IND(cnt_hour_care) 
   - Converts care hours to time category
3. Fiscal Rate: FN_GET_FISCAL_RATE(
     - Standard/Type: 'STD'
     - Provider ID: idn_provr__c
     - Unit Care Type: cde_type_unit_care
     - Care Level: cde_level_care
     - Time Indicator: Calculated above
     - County Code: cde_county__c
     - Care Date: dte_care
   )
```

**Source**: `FN_GET_ATTENDANCE_INFO.sql` 
- Validates care date is within authorization period
- Combines unit type, time indicator, and rate into formatted string

---

### **B. PAYMENT CALCULATION**

#### **1. COPAY (Full-Time & Part-Time)**
```
IF FPG <= 100:
   Copay_FullTime = FLOOR((Total_Household_Income * 0.01) / 12)

IF FPG > 100:
   FPG_C1 = Reference_Table('R00393', '1')
   FPG_AddOn = Reference_Table('R00393', 'ADD')
   
   FPG_Income = FPG_C1 + ((Family_Size - 1) * FPG_AddOn)
   FPG_Income_130 = FPG_Income * 1.3
   FPG_Income_160 = FPG_Income * 1.6
   
   Income_Diff = Total_Household_Income - FPG_Income
   Income_Diff_130 = Total_Household_Income - FPG_Income_130
   Income_Diff_160 = Total_Household_Income - FPG_Income_160
   
   IF Current_Date >= 2028-08-01:
      IF FPG > 160:
         Copay_FullTime = FLOOR(((Income * 0.01) + (Income_Diff * 0.02) + (Diff_130 * 0.02) + (Diff_160 * 0.02)) / 12)
      ELSIF FPG > 130:
         Copay_FullTime = FLOOR(((Income * 0.01) + (Income_Diff * 0.02) + (Diff_130 * 0.02)) / 12)
      ELSE:
         Copay_FullTime = FLOOR(((Income * 0.01) + (Income_Diff * 0.02)) / 12)
   ELSE:
      Copay_FullTime = FLOOR(((Income * 0.01) + (Income_Diff * 0.14)) / 12) + ((Num_Children - 1) * 15)

Copay_PartTime = FLOOR(0.55 * Copay_FullTime)
```

**Source**: `FN_CALCULATE_COPAY_FT_PT.sql`

#### **2. ART FEES (Activity, Registration, Transportation)**
```
For Each Fee Type (Transportation, Activity, Registration):

1. Get County Ceiling Amounts:
   - Transportation_Ceiling = COUNTY_RATE.PAYMENT_Q11_1__c
   - Activity_Ceiling = COUNTY_RATE.PAYMENT_Q10_1__c
   - Registration_Ceiling = COUNTY_RATE.PAYMENT_Q9_1__c

2. Get Provider Fee Amounts & Frequency:
   - Amount = FISCAL_RAT_FEES.amt_trans_provr__c (or amt_act_provr__c, amt_reg_provr__c)
   - Frequency = FISCAL_RAT_FEES.cde_trans_freq__c (ANNUAL, MONTHLY, ONE-TIME)
   - Restricted_Months = FISCAL_RAT_FEES.txt_trans_month__c

3. Handle Leap Year:
   - Begin & End Dates adjusted for Feb 29 in leap/non-leap years
   - Fiscal year boundary: Child's annual enrollment anniversary

4. Calculate Paid Amounts:
   - Annual Total = Sum of all months (Jan-Dec) within fiscal year
   - Monthly Total = Amount per month where not restricted
   - One-Time = Single payment per fiscal year
   
5. Apply Restrictions:
   - IF Frequency = MONTHLY and Current_Month IN Restricted_Months: Skip payment
   - IF Fee = Transportation: Check CRP & Auth Level questions (Payment_Q11_2, Payment_Q11_3)
   
6. Total Remaining:
   - Remaining = Ceiling_Amount - Total_Already_Paid (annual/monthly/one-time)
   - Actual_Payment = MIN(Fee_Amount, Remaining_Amount)
```

**Source**: `FN_GET_ART_FEES.sql` (24KB complex function)

---

## **TABLE 3: Schema Mapping - Objects & Relationships**

| **Object** | **Primary Key** | **Related Objects** | **Relationship** |
|---|---|---|---|
| `t_auth__c` | `idn_extnl__c` | `t_auth_encmbr` | 1:M (Auth has many encumbrances) |
| | | `t_sbsd_indiv__c` | M:M via enrollment (Child authorized on auth) |
| | | `t_chats_provr_status__c` | M:1 (Auth assigned to provider) |
| `t_auth_encmbr` | `idn_auth` + `dte_care` (composite) | `t_auth__c` | M:1 (Daily encumbrance detail) |
| `t_sbsd_indiv__c` | `idn_extnl__c` (child ID) | `t_auth__c` | M:M (Child on multiple auths) |
| | | `t_indiv_rat_fees` | 1:M (Child has multiple fee records) |
| `t_indiv_rat_fees` | `idn_client` + `dte_paid` | `t_sbsd_indiv__c` | M:1 (Fee history per child) |
| | | `t_fiscal_rat_fees__c` | M:1 (References provider fees) |
| `t_fiscal_rat_fees__c` | `idn_fiscal_sch__c` | `t_chats_provr_status__c` | 1:M (Fees per provider/county) |
| | | `t_county_rate__c` | M:1 (County fee ceilings) |
| `t_county_rate__c` | `idn_county__c` + `dte_begin_effv_rate__c` | All county entities | 1:M (County-wide rates, effective dated) |
| `t_sub_pmt_detail` | Composite: mult columns | `t_auth__c`, `t_indiv_rat_fees` | Staging for subsidiary payments |
| `t_copay_calculation` | `percentage_min_value` | Reference table | Static lookup (Copay % bands) |

---

## **Key Functions You'll Need**

| Function | Purpose | Module |
|---|---|---|
| `FN_GET_ATTENDANCE_INFO()` | Assembles attendance string | Attendance |
| `FN_GET_FISCAL_RATE()` | Retrieves provider rates | Attendance |
| `FN_CALCULATE_COPAY_FT_PT()` | Copay calculation | Payment |
| `FN_GET_ART_FEES()` | ART fee calculation | Payment |
| `FN_GET_RE_TABLE_VALUE()` | Reference table lookup | Both |
| `FN_GET_TRDNL_TIME_IND()` | Time indicator mapping | Attendance |

---

This structure will enable you to build your agent with two distinct modules: **Attendance** (handling daily care tracking and rate retrieval) and **Payment** (handling copay, ART fees, and complex fiscal year calculations).


Perfect! I now have a comprehensive overview of the OEC-CHATS/PGSQL repository structure. Let me provide you with a detailed analysis of the **Attendance & Payment** architecture for your agent.

---

## **OEC-CHATS PGSQL Repository: Attendance & Payment Module Architecture**

### **Repository Overview**
The repository contains **500+ PostgreSQL functions** organized into distinct modules. The two primary modules are:
1. **Attendance Module** - Tracks daily care attendance and rates
2. **Payment Module** - Calculates provider payments, copays, and ART fees

---

## **ATTENDANCE MODULE STRUCTURE**

### **Key Functions**

| Function | Purpose |
|----------|---------|
| `FN_GET_ATTENDANCE_INFO()` | Main attendance information retrieval |
| `FN_GET_ENCMBR_DATA()` | Retrieves encumbrance details per day |
| `FN_GET_TRDNL_TIME_IND()` | Converts care hours to time indicator |
| `FN_GET_FISCAL_RATE()` | Retrieves provider rate for care type |
| `FN_GET_INDIV_CARE_LEVEL()` | Determines child's current care level |
| `FN_CREATE_AUTH_ENCMBR_STG()` | Stages encumbrance data |
| `FN_GET_ENCMBR_DATA()` | Gets authorized hours, actual hours |

### **Data Flow for Attendance**

```
Authorization (t_auth__c) → 
  ├─ Encumbrance (t_auth_encmbr) [per care date] →
  │   ├─ Care Hours (cnt_hour_care)
  │   ├─ Unit Care Type (cde_type_unit_care)
  │   ├─ Care Level (cde_level_care)
  │   └─ Actual Attendance Hours
  └─ Gets Fiscal Rate via:
       └─ FN_GET_FISCAL_RATE(provider, care_type, time_indicator)
```

---

## **PAYMENT MODULE STRUCTURE**

### **A. Subsidiary Payment Processing**

**Key Functions:**
- `FN_CREATE_SUB_PMT_DETAIL()` - Creates payment detail records
- `FN_PRCS_SUB_PMT()` - Processes subsidiary payments
- `FN_PRCS_SUB_PMT_DETAIL()` - Calculates payment details
- `FN_PRCS_SUB_PMT_DETAIL_RAT_FEE()` - Handles provider rates
- `FN_PRCS_SUB_PMT_DETAIL_SLOT()` - Handles slot contract payments

**Data Objects:**
- `t_sub_pmt` (Subsidiary Payment header)
- `t_sub_pmt_detail` (Payment detail lines with: amt_copay, amt_rate, amt_total)

### **B. Copay Calculation**

**Primary Function:** `FN_CALCULATE_COPAY_FT_PT()`

**Inputs:**
- `p_idn_case` - Case ID
- `p_total_household_income` - Total family income
- `p_family_size` - Number of family members
- `p_number_children` - Children count
- `p_fpg` - Federal Poverty Level percentage

**Calculation Logic:**
```
IF FPG <= 100:
   Copay = FLOOR(Monthly_Income × 0.01)

IF FPG > 100:
   Uses tiered calculation with reference table R00393
   Applies 1.3x and 1.6x multipliers
   Dynamic rates based on income brackets
   
Copay_PartTime = FLOOR(0.55 × Copay_FullTime)
```

### **C. ART Fees (Activity, Registration, Transportation)**

**Primary Function:** `FN_GET_ART_FEES()` - 24KB complex function

**Fee Types:**
1. **Transportation Fee** (amt_trans_provr__c)
2. **Activity Fee** (amt_act_provr__c)
3. **Registration Fee** (amt_reg_provr__c)

**Calculation Steps:**
1. Retrieve provider fee amounts & frequency
2. Get county ceiling amounts (PAYMENT_Q9_1, Q10_1, Q11_1)
3. Handle leap year fiscal year boundaries
4. Apply monthly restrictions
5. Calculate paid vs. remaining amounts

**Related Functions:**
- `FN_PRCS_ADJMT_ART_FEES()` - Adjustment processing for ART fees
- `FN_PRCS_PROVR_ADJMT_PMT_DTL_TRANS()` - Provider adjustment transitions

---

## **DATABASE SCHEMA - KEY TABLES**

### **Attendance Tables**
```
t_auth_encmbr
├─ idn_auth (PK)
├─ dte_care (PK)
├─ cnt_hour_care (authorized hours)
├─ cnt_hour_attnd_actual (actual hours)
├─ cde_type_unit_care (care type code)
├─ cde_level_care (care level)
└─ linked to t_auth__c.idn_extnl__c

t_auth__c (Salesforce)
├─ idn_extnl__c (auth ID)
├─ idn_client__c (child reference)
├─ idn_provr__c (provider)
├─ cde_county__c (county code)
├─ dte_begin_effv_auth__c
└─ dte_end_effv_auth__c
```

### **Payment Tables**
```
t_sub_pmt
├─ idn_pmt_sub (PK)
├─ idn_pmt (payment reference)
├─ idn_auth
├─ idn_slot_contract
└─ cde_status_pmt_sub (status)

t_sub_pmt_detail
├─ idn_pmt_sub (FK)
├─ dte_care
├─ amt_copay
├─ amt_rate
├─ amt_total
├─ cde_level_care
├─ cde_time_trdnl (full-time/part-time)
├─ cde_type_unit_care
└─ future_payment__c

t_indiv_rat_fees
├─ idn_client (FK to child)
├─ amt_trans_paid (transportation)
├─ amt_act_paid (activity)
├─ amt_reg_paid (registration)
├─ dte_begin_effev (fiscal year start)
├─ dte_end_effev (fiscal year end)
└─ dte_paid (date payment made)

t_fiscal_rat_fees__c
├─ idn_fiscal_sch__c (PK)
├─ amt_trans_provr__c
├─ amt_act_provr__c
├─ amt_reg_provr__c
├─ cde_trans_freq__c (ANNUAL/MONTHLY/ONE-TIME)
├─ cde_act_freq__c
├─ cde_reg_freq__c
├─ txt_trans_month__c (restricted months)
└─ txt_act_month__c

t_county_rate__c
├─ idn_county__c (PK)
├─ PAYMENT_Q9_1__c (registration ceiling)
├─ PAYMENT_Q10_1__c (activity ceiling)
├─ PAYMENT_Q11_1__c (transportation ceiling)
├─ PAYMENT_Q11_2__c (care level question)
├─ PAYMENT_Q11_3__c (auth level question)
├─ dte_begin_effv_rate__c
└─ dte_end_effv_rate__c
```

---

## **REFERENCE DATA**

### **Reference Tables (R-codes)**
| Code | Purpose |
|------|---------|
| R00393 | FPG income calculation parameters |
| R00683 | Unit care type descriptions |
| R00710 | Care level descriptions |
| R00715 | Time indicator mappings |
| R00728 | Program funding codes |

---

## **INTEGRATION POINTS FOR YOUR AGENT**

### **Module 1: Attendance Calculation**
```
Input: Authorization ID + Care Date
Process: 
  1. Call FN_GET_ENCMBR_DATA()
  2. Retrieve hours & care type
  3. Call FN_GET_FISCAL_RATE()
  4. Format attendance string
Output: Attendance info for display/reporting
```

### **Module 2: Payment Calculation**
```
Input: Authorization + Service Period
Process:
  1. Retrieve all eligible children
  2. For each child:
     a. Call FN_CALCULATE_COPAY_FT_PT()
     b. Call FN_GET_ART_FEES()
     c. Sum total payment
  3. Create payment records
Output: Payment amounts ready for processing
```

---

## **Available Resources**

The repository contains **700+ SQL files** with supporting functions for:
- Report generation (FN_RPT_RE207, RE208, RE219, etc.)
- Eligibility determination (FN_GET_ELIGTY_*)
- Status management (FN_TGR_*, FN_UPDATE_*)
- Reversal/adjustment handling (FN_PRCS_ADJMT_*, FN_REVERSE_*)

Would you like me to:
1. **Drill deeper into any specific function** (e.g., FN_GET_ART_FEES leap year logic)?
2. **Map out data flow diagrams** for end-to-end scenarios?
3. **Create pseudocode** for your agent's calculation engine?
4. **Generate sample test cases** for both modules?




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

**TIER 2: 100% < FPG <