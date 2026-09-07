import { label } from 'c/labelUtility';

/**
 * Function to get the value part (Qlabel and section) for a given key.
 * If no key is passed, it returns the complete object.
 * @param {string} [key] - The key to look up in the Qlabel map.
 * @returns {object} - The value part containing the Qlabel and section, or the complete object if no key is passed.
 */
export function getQuestionByKey(key) {
    if (key) {
        return QlabelMap[key] || null;
    }
    return QlabelMap;
}
export function getSectionsByCategory(category) {
    if (category) {
        return sectionTitles[category] || null;
    }
    return sectionTitles;
}
export function getHeaderTitleByKey(category) {
    if (category) {
        return headerTitles[category] || null;
    }
    return headerTitles;
}
export function evaluateFormulaByApiName(instance, apiName) {
    switch (apiName) {
        case "OF_F1":
            return instance.PAYMENT_Q12_2__c || instance.PAYMENT_Q12_2_OTHER__c
                ? `${instance.PAYMENT_Q12_2__c || ""} Other: ${instance.PAYMENT_Q12_2_OTHER__c || ""}`.trim()
                : "";
        default:
            return "Invalid API Name or no formula available.";
    }
}
export function getLabel(labelKey) {
    return label[labelKey] || `Label ${labelKey} not found`;
}

const QlabelMap = {
    // Other Fees.
    PAYMENT_Q10__c: { feedback: '', Qlabel: "1. Does your county pay for Activity fees?", section: "Otherfees" },
    PAYMENT_Q10_1__c: { feedback: '', Qlabel: "1.1 If yes, what is the maximum amount per child per year?", section: "Otherfees" },
    PAYMENT_Q9__c: { feedback: '', Qlabel: "2. Does your county pay for Registration fees?", section: "Otherfees" },
    PAYMENT_Q9_1__c: { feedback: '', Qlabel: "2.1 If yes, what is the maximum amount per child per year?", section: "Otherfees" },
    PAYMENT_Q11__c: { feedback: '', Qlabel: "3. Does your county pay for Transportation fees?", section: "Otherfees" },
    PAYMENT_Q11_1__c: { feedback: '', Qlabel: "3.1 If yes, what is the maximum amount per child per year?", section: "Otherfees" },
    PAYMENT_Q11_2__c: { feedback: '', Qlabel: getLabel('countyRatePlan_question_schoolAgeLevel'), section: "Otherfees" },
    PAYMENT_Q11_3__c: { feedback: '', Qlabel: getLabel('countyRatePlan_question_authLevel'), section: "Otherfees" },
    PAYMENT_Q12__c: { feedback: '', Qlabel: "4. Does your county underwrite costs of fees charged to exempt family child care home providers to obtain fingerprint-based background checks?", section: "Otherfees" },
    PAYMENT_Q12_1__c: { feedback: '', Qlabel: "4.1 What fingerprint-based fees does your county underwrite?", section: "Otherfees" },
    OF_F1: { isComposite: true, feedback: '', Qlabel: "4.2 When are the fees that are underwritten by the county paid?", section: "Otherfees" },
    // Holidays and Absences
    HBlank: { feedback: '', Qlabel: "5. What is your county policy on the maximum number of absences your county pays per month? (You must meet the following minimum absence requirements for each Tier per month - Tier 1: 3 days, Tier 2: 3 days,Tier 3: 4 days, Tier 4: 4 days, Tier 5: 4 days)", section: "Holiday", "feedbackDisabled": true },
    PAYMENT_Q13_a__c: { feedback: '', Qlabel: "Tier 1: Days per month", section: "Holiday" },
    PAYMENT_Q13_b__c: { feedback: '', Qlabel: "Tier 2: Days per month", section: "Holiday" },
    PAYMENT_Q13_c__c: { feedback: '', Qlabel: "Tier 3: Days per month", section: "Holiday" },
    PAYMENT_Q13_d__c: { feedback: '', Qlabel: "Tier 4: Days per month", section: "Holiday" },
    PAYMENT_Q13_e__c: { feedback: '', Qlabel: "Tier 5: Days per month", section: "Holiday" },
    PAYMENT_Q13_2__c: { feedback: '', Qlabel: "5.1 Does your county policy allow for paid holidays?", section: "Holiday" },
    PAYMENT_Q13_1__c: { feedback: '', Qlabel: "5.2 If your county pays holidays, which holidays does your county pay for?", section: "Holiday" },
    // Drop-In Days: County Policy
    PAYMENT_Q14__c: { feedback: '', Qlabel: "6. Does your county pay for drop-in days?", section: "Drop_In" },
    PAYMENT_Q14_1__c: { feedback: '', Qlabel: "6.1 If yes, what are the maximum number of drop-in days allowed per month? (unless managed at authorization level, maximum number of drop-in days will be available for use on all authorizations)", section: "Drop_In" },
    PAYMENT_Q14_2__c: { feedback: '', Qlabel: "6.2 If yes, what type of providers does your county pay?", section: "Drop_In" },
    PAYMENT_Q14_4_1__c: { feedback: '', Qlabel: "6.3 How are drop-in days requested?", section: "Drop_In" },
    PAYMENT_Q14_4_4__c: { feedback: '', Qlabel: "Please explain what other methods you use to request drop-in days.", section: "Drop_In" },
    PAYMENT_Q14_4_2__c: { feedback: '', Qlabel: "Does the county require that a drop-in day be requested within a certain timeframe?", section: "Drop_In" },
    PAYMENT_Q14_4_3__c: { feedback: '', Qlabel: "If yes, what is the required timeframe?", section: "Drop_In" },
    PAYMENT_Q14_3__c: { feedback: '', Qlabel: "6.4 Does your county want to manage drop in days at the authorization level? (when managed at authorization level, all authorizations will default to 0 drop-in days and can be edited individually by the case worker up to the monthly maximum identified in 6.1)?", section: "Drop_In" },
    PAYMENT_Q14_5__c: { feedback: '', Qlabel: "6.5 If drop-in days are managed at the authorization level, how is it determined when drop-in days are allowed?", section: "Drop_In" },
    PAYMENT_Q18__c: { feedback: '', Qlabel: "7. Does your county pay for hold slots?", section: "Drop_In" },
    PAYMENT_Q18_1__c: { feedback: '', Qlabel: "7.1 If yes, how many days per month?", section: "Drop_In" },
    PAYMENT_Q18_2__c: { feedback: '', Qlabel: "7.2 If yes, what type of providers does your county pay?", section: "Drop_In" },
    PAYMENT_Q18_3__c: { feedback: '', Qlabel: "7.3 When are hold slots utilized for unattended, authorized care?", section: "Drop_In" },
    PAYMENT_Q18_OTHER__c: { feedback: '', Qlabel: "Please list other allowed uses of hold slots.", section: "Drop_In" },
    // Rates and County Owned Facilities
    RATE_TYPE__c: { feedback: '', Qlabel: "8. In addition to the State-Established Regular Rate, which types of alternative rates does your county offer?", "section": "Rates" },
    RT_Q8_1__c: { feedback: '', Qlabel: "8.1 Please explain how your county determined the reimbursement rate for Before School Care.", section: "Rates" },
    RT_Q8_1P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Before School rates.", section: "Rates" },
    RT_Q2__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Before School rates.", section: "Rates" },
    RT_Q8_2__c: { feedback: '', Qlabel: "8.2 Please explain how your county determined the reimbursement rate for After School Care.", section: "Rates" },
    RT_Q8_2P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for After School rates.", section: "Rates" },
    RT_Q2_a__c: { feedback: '', Qlabel: "Explain the method your county used to determine the After School rates. (Rates will need to be entered by the county into the rate fields for each age band.)", section: "Rates" },
    RT_Q8_3__c: { feedback: '', Qlabel: "8.3 Please explain how your county determined the reimbursement rate for Before and After School Care.", section: "Rates" },
    RT_Q8_3P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Before and After School rates.", section: "Rates" },
    RT_Q2_b__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Before and After School rates. (Rates will need to be entered by the county into the rate fields for each age band.)", section: "Rates" },
    RT_Q8_4__c: { feedback: '', Qlabel: "8.4 Please explain how your county determined the reimbursement rate for Overnight Care.", section: "Rates" },
    RT_Q8_4P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Overnight.", section: "Rates" },
    RT_Q2_3__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Overnight rates. (Rates will need to be entered by the county into the rate fields for each age band.)", section: "Rates" },
    RT_Q8_5__c: { feedback: '', Qlabel: "8.5 Please explain how your county determined the reimbursement rate for Weekend Care.", section: "Rates" },
    RT_Q8_5P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Weekend care.", section: "Rates" },
    RT_Q2_c__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Weekend rates. (Rates will need to be entered by the county into the rate fields for each age band.)", section: "Rates" },
    RT_Q8_6__c: { feedback: '', Qlabel: "8.6 Please explain how your county determined the reimbursement rate for Evening Care.", section: "Rates" },
    RT_Q8_6P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Evening rates.", section: "Rates" },
    RT_Q2_d__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Evening rates.", section: "Rates" },
    RT_Q8_7__c: { feedback: '', Qlabel: "8.7 Please explain how your county determined the reimbursement rate for Disability Care.", section: "Rates" },
    RT_Q8_7P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Disability.", section: "Rates" },
    RT_Q2_e__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Disability rates.", section: "Rates" },
    RT_Q1__c: { feedback: '', Qlabel: "List the title of the role responsible for approving the use of disability in your county.", section: "Rates" },
    RT_Q1_1__c: {
        feedback: '', Qlabel: `How does the county ensure that the provider can meet the child's additional care needs to be approved to be paid the
        disability rate? The county must accept:
        \n ● Child Eligibility: individual health care plan (IHCP), individual education plan (IEP), physician’s/professional’s
        statement, child welfare, or individualized family service plan (IFSP)
        \n ● Provider Eligibility: provider-created individualized care plan (ICP) for children with additional care needs
        based upon the Individual Education Plan (IEP), or Individual Health Care Plan (IHCP)`, section: "Rates"
    },
    RT_Q8_8__c: { feedback: '', Qlabel: "8.8 Please explain how your county determined the reimbursement rate for Out of County Care.", section: "Rates" },
    RT_Q8_8P__c: { feedback: '', Qlabel: "Please enter the percentage of the State-Established Regular Rate for Out of County care.", section: "Rates" },
    RT_Q2_f__c: { feedback: '', Qlabel: "Explain the method your county used to determine the Out of County rates.", section: "Rates" },
    RT_Q2_g__c: {
        feedback: '', Qlabel: `9. Understanding that Qualified Exempt Provider Rates should not exceed 75% of tier 1 licensed home provider rates for
        corresponding age bands, please explain how your county determined the reimbursement rate for Qualified Exempt Providers.
        If the rate is based on the Regular, please explain how the county calculated the rates for Qualified Exempt Providers.
        \n● (ex: _________ County will be maintaining rates from xx-xx-xxxx and will ensure that the rate is not higher than
        75% of the quality Tier 1 rate for licensed home providers at the youngest age band OR
        \n ● ___________County determined the Qualified Exempt Rate by ______ to ensure that the rate is not higher than 75%
        of the quality Tier 1 rate for licensed home providers at the youngest age band and that it will not deter Qualified
        Exempt providers from becoming licensed.`, section: "Rates"
    },
    PAYMENT_Q15_1__c: { feedback: '', Qlabel: "10. Does your county have a county-owned facility?", section: "Rates" },
    PAYMENT_Q15__c: { feedback: '', Qlabel: "10.1 What is your county's policy for maintaining arms length with a county-owned facility?", section: "Rates" },
    PAYMENT_Q16__c: { feedback: '', Qlabel: "11. Understanding that CHATS functionality allows a new rate schedule to be entered in CHATS as of the first of a future month, how does your county adjust existing Provider Rates when a Provider reports a change to their Private Pay Rates?", section: "Rates" },
    // Attendance Tracking System Policy: Non-cooperation of the Attendance Tracking System (ATS) for Providers
    PAYMENT_Q17_1_1__c: {
        feedback: '', Qlabel: "12. What ATS information/resources are provided to CCCAP Providers?", section: "Attendance"
    },
    PAYMENT_Q17_2__c: { feedback: '', Qlabel: "12.1 What actions does your county take to support providers prior to determining that non-cooperation of ATS (refusal to use ATS at all) has occurred?", section: "Attendance" },
    PAYMENT_Q17_3__c: { feedback: '', Qlabel: "12.2 Does your county close Fiscal Agreements with providers when it has been determined that non-cooperation of ATS has occurred?", section: "Attendance" },
    PAYMENT_Q17_3_1__c: {
        feedback: '', Qlabel: "If no, what action is taken if provider non-cooperation (refusal to use ATS at all) continues?", section: "Attendance"
    },
    PAYMENT_Q17_4__c: {
        feedback: '', Qlabel: "12.3 How does your county issue provider correspondences?", section: "Attendance"
    },
    PAYMENT_Q17_OTHER__c: {
        feedback: '', Qlabel: "Please describe other provider correspondence issuance methods used.", section: "Attendance"
    },
    // Qualified Exempt Providers
    QEP_Q1_new__c: {
        feedback: '', Qlabel: `1. Does your county designate authority to process the following application requirements for Qualified Exempt Provider applicants to the State, or does the county opt to complete these requirements? 
        \n● Complete Trails Legacy, Trails Mod, and Colorado Sexual Offender Registry background checks for the provider applicant and all applicable adults.
                   \n● Create the provider profile in Trails Mod (after the provider applicant and all applicable adults have cleared all of the above mentioned background checks).
                    \n● Refer the provider applicant and all applicable adults to complete their CBI/FBI fingerprinting with a state-approved CABS vendor.
                    \n● Maintain the provider profile and close the provider in Trails Mod, when necessary.`, section: "QE"
    },
    QEP_Q2__c: {
        feedback: '', Qlabel: `1.1 If the county opts to complete these application requirements, please indicate the individual that will
                    complete these requirements for Qualified Exempt Provider applicants and applicable adults in your county.`, section: "QE"
    },
    // Slot Contracts
    CFS_Q1__c: { feedback: '', Qlabel: "2. Would you like to enable the Slot Contracts option? (Current county policy/procedure must be submitted to the State Department for review and approval)", section: "SC" },
    CFS_Q1_1__c: { feedback: '', Qlabel: "2.1 If Yes, how many providers do you have Slot Contracts with?", section: "SC" },
    CFS_Q1_2__c: { feedback: '', Qlabel: "2.2 If Yes, what is the maximum number of slot contracts per provider?", section: "SC" },
    CFS_Q1_3__c: { feedback: '', Qlabel: "2.3 What are the County identified Target populations and Areas for Slot Contracts?", section: "SC" },
    CFS_Q1_4__c: { feedback: '', Qlabel: "2.4 Other county-identified target populations or areas (Enter other Target Population/Area):", section: "SC" },
};

const sectionTitles = {

    'CRP': {
        'Otherfees': "Other fees",
        'Holiday': "Holidays and Absences",
        'Drop_In': "Drop-In Days: County Policy",
        'Rates': "Rates and County Owned Facilities",
        'Attendance': "Attendance Tracking System Policy: Non-cooperation of the Attendance Tracking System (ATS) for Providers",
        'QE': "Qualified Exempt Providers",
        'SC': "Slot Contracts"
    },
    'CRP_Rate': {
        'Home': 'County Ceiling Rates: Provider Type (Home)',
        'Center': 'County Ceiling Rates: Provider Type (Center)',
        'Exempt': 'County Ceiling Rates: Provider Type (Exempt)',
    }
}
const headerTitles = {
    //'QE': "Qualified Exempt Providers",
   // 'SC': "Slot Contracts",
    'Otherfees': 'Payment'
}