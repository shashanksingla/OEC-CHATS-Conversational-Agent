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