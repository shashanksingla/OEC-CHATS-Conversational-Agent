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