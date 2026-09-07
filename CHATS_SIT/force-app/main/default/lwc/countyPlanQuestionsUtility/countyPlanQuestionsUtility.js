import { label } from "c/labelUtility";
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
        case "CA_F6":
            if (instance.DTE_TMP_UNI_ACC_END_DT__c) {
                const date = new Date(instance.DTE_TMP_UNI_ACC_END_DT__c);
                return `${date.getMonth() + 1} /${date.getDate()}/${date.getFullYear()} `;
            }
            return "";
            
        case "RI_F1":
            return instance.CCDF_Q1__c || instance.CCDF_Q1_OTHER__c
                ? `${instance.CCDF_Q1__c || ""}${instance.CCDF_Q1_OTHER__c ? `\n Other: ${instance.CCDF_Q1_OTHER__c}` : ""} `.trim()
                : "";

        case "RI_F2":
            return instance.CCDF_Q2__c || instance.CCDF_Q2_OTHER__c
                ? `${instance.CCDF_Q2__c || ""}${instance.CCDF_Q2_OTHER__c ? `\n Other: ${instance.CCDF_Q2_OTHER__c}` : ""} `.trim()
                : "";

        case "RI_F3":
            return instance.CCDF_Q3__c || instance.CCDF_Q3_OTHER__c
                ? `${instance.CCDF_Q3__c || ""}${instance.CCDF_Q3_OTHER__c ? `\n Other: ${instance.CCDF_Q3_OTHER__c}` : ""} `.trim()
                : "";

        case "RI_F4":
            return instance.CCDF_Q4__c || instance.CCDF_Q4_OTHER__c
                ? `${instance.CCDF_Q4__c || ""}${instance.CCDF_Q4_OTHER__c ? `\n Other: ${instance.CCDF_Q4_OTHER__c}` : ""} `.trim()
                : "";

        case "RI_F5":
            return instance.CCDF_Q5__c || instance.CCDF_Q5_OTHER__c
                ? `${instance.CCDF_Q5__c || ""}${instance.CCDF_Q5_OTHER__c ? `\n Other: ${instance.CCDF_Q5_OTHER__c}` : ""} `.trim()
                : "";

        case "VR_F1":
            return instance.CCDF_Q6__c || instance.CCDF_Q6_OTHER__c
                ? `${instance.CCDF_Q6__c || ""}${instance.CCDF_Q6_OTHER__c ? `\n Other: ${instance.CCDF_Q6_OTHER__c}` : ""} `.trim()
                : "";

        case "VR_F2":
            return instance.CCDF_Q7__c || instance.CCDF_Q7_OTHER__c
                ? `${instance.CCDF_Q7__c || ""}${instance.CCDF_Q7_OTHER__c ? `\n Other: ${instance.CCDF_Q7_OTHER__c}` : ""} `.trim()
                : "";

        case "VR_F3":
            return instance.CCDF_Q8__c || instance.CCDF_Q8_OTHER__c
                ? `${instance.CCDF_Q8__c || ""}${instance.CCDF_Q8_OTHER__c ? `\n Other: ${instance.CCDF_Q8_OTHER__c}` : ""} `.trim()
                : "";

        case "VR_F4":
            return instance.CCDF_Q9__c || instance.CCDF_Q9_OTHER__c
                ? `${instance.CCDF_Q9__c || ""}${instance.CCDF_Q9_OTHER__c ? `\n Other: ${instance.CCDF_Q9_OTHER__c}` : ""} `.trim()
                : "";

        case "VR_F5":
            return instance.CCDF_Q10__c || instance.CCDF_Q10_OTHER__c
                ? `${instance.CCDF_Q10__c || ""}${instance.CCDF_Q10_OTHER__c ? `\n Other: ${instance.CCDF_Q10_OTHER__c}` : ""} `.trim()
                : "";

        case "VR_F6":
            return instance.CCDF_Q11__c || instance.CCDF_Q11_OTHER__c
                ? `${instance.CCDF_Q11__c || ""}${instance.CCDF_Q11_OTHER__c ? `\n Other: ${instance.CCDF_Q11_OTHER__c}` : ""} `.trim()
                : "";

        case "ARF_F1":
            return instance.CCCAP_Q1_1__c || instance.CCCAP_Q1_1_Other__c
                ? `${instance.CCCAP_Q1_1__c || ""}${instance.CCCAP_Q1_1_Other__c ? `\n Other: ${instance.CCCAP_Q1_1_Other__c}` : ""} `.trim()
                : "";

        case "ARF_F2":
            return instance.CCCAP_Q3__c || instance.CCCAP_Q3_OTHER__c
                ? `${instance.CCCAP_Q3__c || ""}${instance.CCCAP_Q3_OTHER__c ? `\n Other: ${instance.CCCAP_Q3_OTHER__c}` : ""} `.trim()
                : "";

        case "ARF_F3":
            return instance.CCCAP_Q4__c || instance.CCCAP_Q4_OTHER__c
                ? `${instance.CCCAP_Q4__c || ""}${instance.CCCAP_Q4_OTHER__c ? `\n Other: ${instance.CCCAP_Q4_OTHER__c}` : ""} `.trim()
                : "";

        case "ARF_F4":
            return instance.CCCAP_Q8__c || instance.CCCAP_Q8_OTHER__c
                ? `${instance.CCCAP_Q8__c || ""}${instance.CCCAP_Q8_OTHER__c ? `\n Other: ${instance.CCCAP_Q8_OTHER__c}` : ""} `.trim()
                : "";
        case "AA_F1":
            return instance.ELIGIBILITY_Q1_1__c
                ? `${instance.ELIGIBILITY_Q1_1__c} `.trim()
                : "";

        default:
            return "Invalid API Name or no formula available.";
    }
}
export function getLabel(labelKey) {
    return label[labelKey] || `Label ${labelKey} not found`;
}
const QlabelMap = {
    // section CCDF
    CA_Q1__c: {
        Qlabel:
            "1. Does another county administer CCCAP for your county for any area of the program including, Case Reviews, County Security,  Eligibility Determination, Fiscal Management, or Provider Management?",
        section: "countyAdmin"
    },
    CA_Q1_1__c: {
        Qlabel:
            "1.1 If yes, select the program areas your county contracts out and which county administers it. The contract must be submitted to the State Department for review prior to executing the contract.",
        section: "countyAdmin"
    },
    CA_Q1_2_County__c: {
        Qlabel: "Case Reviews Administering County",
        section: "countyAdmin"
    },
    CA_Q1_3_N__c: {
        Qlabel:
            "Please describe the county's plan to complete county-level reviews, including what tasks the other county completes and how you communicate regarding the tasks being completed?",
        section: "countyAdmin"
    },
    CA_Q1_4__c: {
        Qlabel: "Select methods the county will use to ensure inter-reviewer consistency.",
        section: "countyAdmin"
    },
    CA_Q1_4_other__c: {
        Qlabel: "If other, please specify",
        section: "countyAdmin"
    },
    CA_Q2_new__c: {
        Qlabel: "2. Does your county administer CCCAP for another county for any area of the program including, Case Reviews, County Security,  Eligibility Determination, Fiscal Management, or Provider Management?",
        section: "countyAdmin"
    },
    CA_Q2_1_new__c: {
        Qlabel: "If yes, select which program areas your county administers and which county you administer those areas for. The contract must be submitted to the State Department for review prior to executing the contract. ",
        section: "countyAdmin"
    },
    CA_Q2_2_County__c: {
        Qlabel: "County you conduct Case Reviews for",
        section: "countyAdmin"
    },
    CA_Q2_3_N__c: {
        Qlabel: "Please describe the county's plan to complete county-level reviews, including how you communicate regarding the tasks being completed?",
        section: "countyAdmin"
    },
    CA_Q2_4_new__c: {
        Qlabel: "Select methods the county will use to ensure inter-reviewer consistency.",
        section: "countyAdmin"
    },
    CA_Q2_4_other__c: {
        Qlabel: "If other, please specify",
        section: "countyAdmin"
    },
    CA_Q2_5_County__c: {
        Qlabel: "County you conduct Security Administration tasks for",
        section: "countyAdmin"
    },
    CA_Q2_6_N__c: {
        Qlabel: "Please describe what tasks you complete for the other county and how you communicate regarding the tasks being completed.",
        section: "countyAdmin"
    },
     CA_Q2_7_County__c: {
        Qlabel: "County you determine eligibility for",
        section: "countyAdmin"
    },
    CA_Q2_8_N__c: {
        Qlabel: "Please describe what tasks your county completes for the other county  and how you communicate regarding the tasks being completed.",
        section: "countyAdmin"
    },

    CA_Q2_9_County__c: {
        Qlabel: "County you conduct Fiscal Management tasks for",
        section: "countyAdmin"
    },
    CA_Q2_10_N__c: {
        Qlabel: "Please describe what tasks you complete for the other county and how you communicate regarding the tasks being completed.",
        section: "countyAdmin"
    },
    CA_Q2_11_County__c: {
        Qlabel: "County you conduct Provider Management tasks for",
        section: "countyAdmin"
    },
    CA_Q2_12_N__c: {
        Qlabel: "Please describe what tasks you complete for the other county and how you communicate regarding the tasks being completed.",
        section: "countyAdmin"
    },
    CA_Q1_22_County__c: {
        Qlabel: "County Security Administration Administering County",
        section: "countyAdmin"
    },
    CA_Q1_32_N__c: {
        Qlabel:
            "Please describe how you communicate regarding the tasks being completed?",
        section: "countyAdmin"
    },
    CA_Q1_23_County__c: {
        Qlabel: "Eligibility Determination Administering County",
        section: "countyAdmin"
    },
    CA_Q1_33_N__c: {
        Qlabel:
            "Please describe what tasks the other county completes and how you communicate regarding the tasks being completed?",
        section: "countyAdmin"
    },
    CA_Q1_24_County__c: {
        Qlabel: "Fiscal Management Administering County",
        section: "countyAdmin"
    },
    CA_Q1_34_N__c: {
        Qlabel:
            "Please describe what tasks the other county completes and how you communicate regarding the tasks being completed?",
        section: "countyAdmin"
    },
    CA_Q1_25_County__c: {
        Qlabel: "Provider Management Administering County",
        section: "countyAdmin"
    },
    CA_Q1_35_N__c: {
        Qlabel:
            "Please describe what tasks the other county completes and how you communicate regarding the tasks being completed?",
        section: "countyAdmin"
    },
    CA_Q2__c: {
        Qlabel: "3. Does your county have a Universal User?",
        section: "countyAdmin"
    },
    CA_Q2_1__c: {
        Qlabel: "3.1 If Yes, User's Name",
        section: "countyAdmin"
    },
    CA_Q2_2__c: {
        Qlabel:
            "3.2 Please provide a detailed explanation as to why your county needs Universal User access.",
        section: "countyAdmin"
    },
    CA_Q2_3__c: {
        Qlabel: "3.3 Is the access temporary or permanent?",
        section: "countyAdmin"
    },
    CA_F6: {
        isComposite: true,
        Qlabel: "3.4 Temporary Universal User Access End Date",
        section: "countyAdmin"
    },
    CA_Q2_4__c: {
        Qlabel: 'Please provide a detailed explanation as to how your county will mitigate fraud and ensure that proper case and business office procedures are followed.',
        section: "countyAdmin"
    },
    RI_F1: {
        isComposite: true,

        Qlabel:
            "4. How are Colorado Works/TANF families informed of the availability of Child Care Assistance? Select all that apply.",
        section: "referralInfo"
    },
    RI_F2: {
        isComposite: true,

        Qlabel:
            "5. How are Low-Income families informed of the availability of Child Care Assistance? Select all that apply.",
        section: "referralInfo"
    },
    RI_F3: {
        isComposite: true,

        Qlabel:
            "6. How are families referred to other services? Select all that apply.",
        section: "referralInfo"
    },
    RI_F4: {
        isComposite: true,

        Qlabel:
            "7. How does a Colorado Works/TANF family apply for Child Care services? Select all that apply.",
        section: "referralInfo"
    },
    RI_F5: {
        isComposite: true,

        Qlabel:
            "8. How does a Low-Income family apply for Child Care services? Select all that apply.",
        section: "referralInfo"
    },
    VR_F1: {
        isComposite: true,

        Qlabel:
            "9. How do adult caretakers from Colorado Works/TANF families receive voter registration information? Select all that apply.",
        section: "voterRegis_Tanf"
    },
    VR_F2: {
        isComposite: true,        
        Qlabel:
            "10. When do you send completed voter registration information for Colorado Works/TANF families to the Secretary of State?",
        section: "voterRegis_Tanf"
    },
    VR_F3: {
        isComposite: true,

        Qlabel:
            "11. How do you ensure voter registration information for Colorado Works/TANF families is not maintained in client files? Select all that apply.",
        section: "voterRegis_Tanf"
    },
    VR_F4: {
        isComposite: true,

        Qlabel:
            "12. How do adult caretakers from Low-Income families receive voter registration information? Select all that apply.",
        section: "voterRegis_LI"
    },
    VR_F5: {
        isComposite: true,

        Qlabel:
            "13. When do you send completed voter registration information for Low-Income Families to the Secretary of State?",
        section: "voterRegis_LI"
    },
    VR_F6: {
        isComposite: true,

        Qlabel:
            "14. How do you ensure voter registration information for Low-Income families is not maintained in client files? Select all that apply.",
        section: "voterRegis_LI"
    },


    // Section CCCAP
    CCCAP_Q1__c: {
        Qlabel:
            "1. Does your county accept other program Applications in lieu of CCCAP Applications?",
        section: "appReferral"
    },
    ARF_F1: {
        isComposite: true,

        Qlabel: "1.1 If yes, Select all that apply.",
        section: "appReferral"
    },
    CCCAP_Q2__c: {
        Qlabel:
            "2. Does your county require a face to face interview or orientation as part of the application process?",
        section: "appReferral"
    },
    CCCAP_Q2_1__c: {
        Qlabel:
            "2.1 If yes, which does your county offer and how does your county ensure that the interview or orientation process does not present a burden to families?",
        section: "appReferral"
    },
    ARF_F2: {
        isComposite: true,

        Qlabel:
            "3. Typically, when do Colorado Works/TANF families receive information on child care choices?",
        section: "appReferral"
    },
    ARF_F3: {
        isComposite: true,

        Qlabel:
            "4. Typically, when do Low-Income families receive information on child care choices?",
        section: "appReferral"
    },
    CCCAP_Q9__c: {
        Qlabel:
            "5. Provide a brief overview of how your county ensures equal access to child care for families receiving CCCAP.",
        section: "appReferral"
    },
    CCCAP_Q10__c: {
        Qlabel:
            "6. Client Orientation: Is a child care group orientation required as part of your application process?",
        section: "appReferral"
    },
    CCCAP_Q10_1__c: {
        Qlabel:
            "6.1 If yes, what is your county's policy for gathering additional information needed to complete the application process?",
        section: "appReferral"
    },
    CCCAP_Q10_2__c: {
        Qlabel:
            "6.2 If yes, how does the county ensure that the orientation does not present a burden to families?",
        section: "appReferral"
    },
    CCCAP_Q11__c: {
        Qlabel:
            "7. Provider Orientation: Is a child care orientation required for providers?",
        section: "appReferral"
    },
    CCCAP_Q11_1__c: {
        Qlabel:
            "7.1 If yes, please check which providers must attend an orientation.",
        section: "appReferral"
    },
    CCCAP_Q11_2__c: {
        Qlabel: "7.2 What information is provided during provider orientation?",
        section: "appReferral"
    },
    ARF_F4: {
        isComposite: true,
        Qlabel:
            '8. Check the state-prescribed forms your county has changed below, or list them in the "Other" text box. Please mail or email a copy of each changed form to State CCCAP for approval.',
        section: "appReferral"
    },
    CCCAP_Q14__c: {
        Qlabel: "9. List all County forms that are not State prescribed forms. ",
        section: "appReferral"
    },

    // section Program Integrity
    PI_Q3_new__c: {
        Qlabel: '1. Please identify the staff (titles/positions of staff) responsible for researching potential erroneous client payments.',
        section: "programIntegrity"
    },
    PI_Q3_1_new__c: {
        Qlabel:
            "1.1 Please identify the methods used to identify questionable client information.",
        section: "programIntegrity"
    },
    PI_Q3_1_other__c: {
        Qlabel: "If other, please specify",
        section: "programIntegrity"
    },
    PI_Q4_new__c: {
        Qlabel:
            "2. Please identify the staff (titles/positions of staff) responsible for researching potential provider erroneous payments.",
        section: "programIntegrity"
    },
    PI_Q4_1_new__c: {
        Qlabel:
            "2.1 Please identify all of the methods used to identify questionable provider information.",
        section: "programIntegrity"
    },
    PI_Q4_1_other__c: {
        Qlabel: "If other, please specify",
        section: "programIntegrity"
    },
    PI_Q5_new__c: {
        Qlabel:
            "3. Please identify how your county ensures questionable information will be reported to other programs as applicable.",
        section: "programIntegrity"
    },
    PI_Q5_other__c: {
        Qlabel: "If other, please specify",
        section: "programIntegrity"
    },
    PI_Q6_new__c: {
        Qlabel:
            "4. Please explain the process your county follows to prevent and identify potential client and provider fraud:",
        section: "fraudPrevention"
    },
    PI_Q7_new__c: {
        Qlabel:
            "5. The county utilizes the following methods to ensure staff are made aware of the county's fraud prevention policies and procedures to mitigate fraud:",
        section: "fraudPrevention"
    },
    PI_Q7_1__c: {
        isMissing: "",
        Qlabel: "5.1. Please describe the other methods your county is using.",
        section: "fraudPrevention"
    },
    PI_Q9_new__c: {
        Qlabel:
            "6. How are the county's fraud prevention policies/expectations communicated with CCCAP applicants/recipients?",
        section: "fraudPrevention"
    },
    PI_Q9_other__c: {
        Qlabel: "If other, please specify",
        section: "fraudPrevention"
    },
    PI_Q10_new__c: {
        Qlabel:
            "7. How are the county's fraud prevention policies/expectations communicated with providers?",
        section: "fraudPrevention"
    },
    PI_Q10_other__c: {
        Qlabel: "If other, please specify",
        section: "fraudPrevention"
    },
    PI_Q11__c: {
        Qlabel:
            "8. The county utilizes the following methods to identify potential fraud:",
        section: "fraudDetection"
    },
    PI_Q11_1_new__c: {
        Qlabel: "Please identify the systems used as part of the review:",
        section: "fraudDetection"
    },
    PI_Q11_1_other__c: {
        Qlabel: "If other, please specify",
        section: "fraudDetection"
    },
    PI_Q11_2__c: {
        Qlabel:
            "Please identify the titles of the staff that conduct the investigation:",
        section: "fraudDetection"
    },
    PI_Q12__c: {
        Qlabel:
            "9. Please identify how your county coordinates investigations for CCCAP with other public assistance programs (Adult Financial, Colorado Works, SNAP) in your county to ensure that CCCAP-relevant information is obtained and how the county ensures that CCCAP is included in applicable IPV/fraud investigations:",
        section: "fraudDetection"
    },
    PI_Q13_new__c: {
        Qlabel:
            "10. Please describe the process your county uses to monitor provider attendance records and payments. This includes regular reviews/monitoring and random or targeted reviews of provider records suspected of submitting inaccurate information:",
        section: "fraudDetection"
    },
    PI_Q13_other__c: {
        Qlabel: "If other, please specify",
        section: "fraudDetection"
    },
    PI_Q14__c: {
        Qlabel:
            "11. Please identify who is responsible for reviewing the allegation and investigation details to authorize the county to pursue an IPV/fraud in your county:",
        section: "determiningIntentionProgram"
    },
    PI_Q14_1__c: {
        Qlabel: "Please identity the title of the position",
        section: "determiningIntentionProgram"
    },

    // section Eligibility Risk Based Reviews Policy
    CRP_Blank2: {
        feedbackDisabled: true,
        Qlabel: "1. Inter-Reviewer Consistency",
        section: "countyReviewPlan"
    },
    RBRP_Q1_new__c: {
        Qlabel:
            "Select the methods the county will use to ensure inter-reviewer consistency.",
        section: "countyReviewPlan"
    },
    RBRP_Q1_other__c: {
        Qlabel: "If other, please specify",
        section: "countyReviewPlan"
    },
    CRP_Blank5: {
        feedbackDisabled: true,
        Qlabel: "1.1 Case Review Logistics",
        section: "countyReviewPlan"
    },
    RBRP_Q1_1_new__c: {
        Qlabel: "Does the county have electronic or physical records?",
        section: "countyReviewPlan"
    },
    RBRP_Q1_2_new__c: {
        Qlabel: "Where does the record review occur?",
        section: "countyReviewPlan"
    },
    RBRP_Q1_2_other__c: {
        Qlabel: "Describe how the county ensures that the physical records remain secure during transport to the offsite location before the are reviewed.",
        section: "countyReviewPlan"
    },
    CRP_Blank6: {
        feedbackDisabled: true,
        Qlabel: "2. Plan for Follow Up on Findings",
        section: "countyReviewPlan"
    },
    RBRP_Q2_1__c: {
        Qlabel:
            "Describe the County’s plan to ensure that cases with errors are corrected: The County must create reports based on the data collected in the CCCAP County Review Performance Report and include statewide and county level performance indicators and top error trends. Indicate the number of business days in which the county will correct the errors.",
        section: "countyReviewPlan"
    },
    RBRP_Q2_2__c: {
        Qlabel:
            "If findings result in the creation of new policies and procedures, describe the County’s plan to incorporate the changes, including training staff, evaluating the effectiveness of the changes, and ensuring that staff consistently apply the new policies and procedures.:",
        section: "countyReviewPlan"
    },

    // Section Eligibility
    AA_Blank1: {
        feedbackDisabled: true,
        Qlabel: "1. County's Income Eligibility Level:",
        section: "approvedAcvities"
    },

    AA_F1: {
        isComposite: true,
        Qlabel: "% of poverty level at application (entry level)",
        section: "approvedAcvities"
    },
    ELIGIBILITY_Q2_1__c: {
        Qlabel:
            "2. How many weeks of training are approved for Post Secondary Education for a first bachelor's degree or Vocational/Job skill training? (Minimum is 104 weeks, Maximum is 208 weeks)",
        section: "approvedAcvities"
    },
    ELIGIBILITY_Q3_1__c: {
        Qlabel:
            "3. How many weeks of training are approved for GED, high school diploma, and adult basic education? (Maximum is 52 weeks)",
        section: "approvedAcvities"
    },
    ELIGIBILITY_Q4__c: {
        Qlabel:
            "4. How many weeks are allowed for job search activity? (Minimum is 13 weeks)",
        section: "approvedAcvities"
    },
    ELIGIBILITY_Q6__c: {
        Qlabel:
            "5. How many weeks is your stabilization period for families experiencing homelessness? (Minimum is 9 weeks).",
        section: "approvedAcvities"
    },
    ELG_ATS_Q1__c: {
        Qlabel:
            "1. What ATS information/ resources are provided to CCCAP families?",
        section: "AttendanceTracking"
    },
    ELIGIBILITY_Q7_2__c: {
        Qlabel:
            "2. What actions does your county take to support families prior to determining non- cooperation of ATS has occurred?",
        section: "AttendanceTracking"
    },
    ELIGIBILITY_Q7_1__c: {
        Qlabel:
            "3. Does your county close cases at re-determination for non-cooperation of ATS?",
        section: "AttendanceTracking"
    },
    ELG_ATS_Q2__c: {
        Qlabel:
            "If no, what action is taken if family non-cooperation (refusal to use ATS at all) continues?",
        section: "AttendanceTracking"
    },
    PF_Q1__c: {
        Qlabel: "4. Does your county offer Parent Fee hardships?",
        section: "parentFees"
    },
    PF_Q7_new__c: {
        Qlabel:
            "5. How does a family receiving Colorado Works/TANF request a parent fee hardship?",
        section: "parentFees"
    },
    PF_Q3__c: {
        Qlabel:
            "6. Who makes the final determination for a parent fee hardship for a family receiving Colorado Works/TANF?",
        section: "parentFees"
    },
    PF_Q4__c: {
        Qlabel:
            "7. How many months are allowed per occurrence for a parent fee hardship for a family receiving Colorado Works/TANF?",
        section: "parentFees"
    },
    PF_Q5__c: {
        Qlabel:
            "8. What is the process for establishing a parent fee hardship for a family receiving Low Income CCCAP?",
        section: "parentFees"
    },
    PF_Q6__c: {
        Qlabel:
            "9. Who makes the final determination for a parent fee hardship for a family receiving Low Income CCCAP?",
        section: "parentFees"
    },
    PF_Q7__c: {
        Qlabel:
            "10.  How many months are allowed per occurrence for a parent fee hardship for a family receiving Low Income CCCAP?",
        section: "parentFees"
    },
    PF_Q8__c: {
        Qlabel: "11. Does your county require a Parent Fee Hardship Application?",
        section: "parentFees"
    },
    PF_Q9__c: {
        Qlabel:
            "12. Does your county allow for a Parent Fee hardship extension with supporting justification?",
        section: "parentFees"
    },
    PF_Q10__c: {
        Qlabel:
            "13. Does your county require that Child care providers shall report nonpayment of parent fees earlier than (60) calendar-days after the end of the month following the month the parent fees are due?",
        section: "parentFees"
    },
    PF_Q10_1__c: {
        Qlabel:
            "If yes, what is the county's reporting timeframe requirements?",
        section: "parentFees"
    },
    PF_Q10_2__c: {
        Qlabel: "If yes, how is it communicated to providers?",
        section: "parentFees"
    },
    PF_Q11__c: {
        Qlabel:
            "14. Does your county waive the parent fee for a household that has a child that is dually enrolled in a head start or early head start program?",
        section: "parentFees"
    },
    ELIGIBILITY_Q9__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q9_Label_JS"),
        section: "waitlist"
    },
    ELIGIBILITY_Q9_1__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q9_1_Label_JS"),
        section: "waitlist"
    },
    ELIGIBILITY_Q9_3__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q9_3_Label_JS"),
        section: "waitlist"
    },
    ELIGIBILITY_Q9_2_1__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q9_2_1_Label_JS"),
        section: "waitlist"
    },
    ELIGIBILITY_Q9_2_2__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q9_2_2_Label_JS"),
        section: "waitlist"
    },
    ELIGIBILITY_Q9_5__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q9_5_Label_JS"),
        section: "waitlist"
    },
    ELIGIBILITY_Q12__c: {
        Qlabel: "16. Do you require any forms for the waitlist?",
        section: "waitlist"
    },
    ELIGIBILITY_Q12_1__c: {
        Qlabel:
            "Please list all of the forms accepted and submit them to State CCCAP for approval.",
        section: "waitlist"
    },
    ELIGIBILITY_Q10__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q10_Label_JS"),
        section: "enrollmentFreeze"
    },
    ELIGIBILITY_Q10_1__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q10_1_Label_JS"),
        section: "enrollmentFreeze"
    },
    ELIGIBILITY_Q10_2__c: {
        Qlabel: getLabel("CP_ELIGIBILITY_Q10_2_Label_JS"),
        section: "enrollmentFreeze"
    },
    ELIGIBILITY_Q20_new__c: {
        Qlabel:
            "18. In addition to the State-approved abbreviated application and/or redetermination forms, please list all of the forms and submit them to State CCCAP for approval.",
        section: "enrollmentFreeze"
    },
    ELIGIBILITY_Q20_other__c: {
        Qlabel: "If other, please specify",
        section: "enrollmentFreeze"
    },
    ELIGIBILITY_Q20_1__c: {
        Qlabel:
            "18.1 Will your county have families reinstate their intent to remain on the freeze list every twelve (12) months?",
        section: "enrollmentFreeze"
    },
    ELIGIBILITY_Q11__c: {
        Qlabel:
            "19. Does your county elect to cover the cost of Child Welfare Child Care under Protective Services Child Care? (Current county policy/procedure must be submitted to the State Department for review and approval)",
        section: "protectiveServices"
    },
    ELIGIBILITY_Q11_1__c: {
        Qlabel:
            "If yes, does your county waive the child's countable income on a case-by-case basis?",
        section: "protectiveServices"
    },
    ELIGIBILITY_Q11_1D__c: {
        Qlabel: "If yes, please explain when income is waived.",
        section: "protectiveServices"
    },
    ELIGIBILITY_Q14__c: {
        Qlabel: "20. What population will the county cover with PSCC?",
        section: "protectiveServices"
    }
};

const sectionTitles = {
    CP: {
        countyAdmin: "County Administration",
        referralInfo: "Referrals and Information",
        voterRegis_Tanf: "Voter Registration for Colorado Works/TANF Families",
        voterRegis_LI:
            "Voter Registration for Low-Income Families.",
        appReferral: "Applications and Referrals",
        programIntegrity: "Program Integrity",
        fraudPrevention: "Fraud Prevention",
        fraudDetection: "Fraud Detection",
        determiningIntentionProgram:
            "Determining Intentional Program Violations and/or Fraud",
        countyReviewPlan: "County Review Plan",
        approvedAcvities: "Approved Activities and Benefits",
        AttendanceTracking: "Attendance Tracking System - Family Policies",
        parentFees: "Parent Fees",
        waitlist: "Waitlist",
        enrollmentFreeze: "Enrollment Freeze",
        protectiveServices: "Protective Services"
    }
};
const headerTitles = {
    countyAdmin: "CCDF",
    appReferral: "CCCAP",
   // programIntegrity: "Program Integrity",
    countyReviewPlan: "Eligibility Risk Based Reviews Policy",
    approvedAcvities: "Eligibility"
};