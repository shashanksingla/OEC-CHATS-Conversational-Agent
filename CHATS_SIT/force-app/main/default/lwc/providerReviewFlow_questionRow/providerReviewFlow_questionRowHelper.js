export const provReviewQuestionHelper = {

    handleValueUpdates(cmp, targetField, value) {
        let causeIndex = 0;
        //normal change handlers
        if (targetField == 'Action_Taken__c') {
            cmp.internalWrapper.responseRec.Action_Taken__c = value;
        } else if (targetField == 'Action_Date__c') {
            let dateCmp = cmp.template.querySelector(".dateCmp");
            if(value && new Date(value)>new Date()){
                dateCmp.value ='';
                cmp.internalWrapper.responseRec.Action_Date__c = '';
                dateCmp.setCustomValidity("Date of Action Taken can not be in future");
            }else{
                cmp.internalWrapper.responseRec.Action_Date__c = value;
                dateCmp.setCustomValidity("");
            }
            dateCmp.reportValidity();
        } else if (targetField == 'Observation_Details_Comments__c') {
            cmp.internalWrapper.responseRec.Observation_Details_Comments__c = value;
        }
        //multiselect combobox event handlers
        else if (targetField == 'Provider_Review_Response__c_ProviderReview_QuestionMain__c') {
            cmp.internalWrapper.responseRec.ProviderReview_QuestionMain__c = value;
            cmp.handelMainQuestionUpdate(value);

        } else if (targetField == 'Provider_Review_Response__c_Causes_Payment_Error__c') {
            cmp.internalWrapper.responseRec.Causes_Payment_Error__c = value;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Error1__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Error1__c = value;
            cmp.internalWrapper.responseRec.ProviderReview_Cause1__c = '';
            causeIndex = 1;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Error2__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Error2__c = value;
            cmp.internalWrapper.responseRec.ProviderReview_Cause2__c = '';
            causeIndex = 2;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Error3__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Error3__c = value;
            cmp.internalWrapper.responseRec.ProviderReview_Cause3__c = '';
            causeIndex = 3;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Error4__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Error4__c = value;
            cmp.internalWrapper.responseRec.ProviderReview_Cause4__c = '';
            causeIndex = 4;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Cause1__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Cause1__c = value;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Cause2__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Cause2__c = value;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Cause3__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Cause3__c = value;
        } else if (targetField == 'Provider_Review_Response__c_ProviderReview_Cause4__c') {
            cmp.internalWrapper.responseRec.ProviderReview_Cause4__c = value;
        } else if (targetField == 'Provider_Review_Response__c_Action_Required__c') {
            cmp.internalWrapper.responseRec.Action_Required__c = value;
            if (value != 'Y') {
                cmp.internalWrapper.responseRec.Action_Taken__c = undefined;
                cmp.internalWrapper.responseRec.Action_Date__c = undefined;
            }
        }
        //added order for CCCAP-13277
        if (causeIndex > 0) {
            cmp.findCauseValues(causeIndex,cmp.internalWrapper.questionRec.Element__c);
        }
    },
    resetErrorAndCausePicklists(cmp) {
        let responseRec = JSON.parse(JSON.stringify(cmp.internalWrapper.responseRec || {}));
        if (cmp.allErrorOptions && cmp.allErrorOptions.length > 0) {
            responseRec.ProviderReview_Error1__c = '';
            responseRec.ProviderReview_Cause1__c = '';
        }
        if (cmp.allErrorOptions && cmp.allErrorOptions.length > 1) {
            responseRec.ProviderReview_Error2__c = '';
            responseRec.ProviderReview_Cause2__c = '';
        }
        if (cmp.allErrorOptions && cmp.allErrorOptions.length > 2) {
            responseRec.ProviderReview_Error3__c = '';
            responseRec.ProviderReview_Cause3__c = '';
        }
        if (cmp.allErrorOptions && cmp.allErrorOptions.length > 3) {
            responseRec.ProviderReview_Error4__c = '';
            responseRec.ProviderReview_Cause4__c = '';
        }
        responseRec.Causes_Payment_Error__c = '';
        responseRec.Element_Apply_to_Case__c = '';
        responseRec.ProviderReview_NA_Reason__c ='';
        cmp.internalWrapper.responseRec = responseRec;
    }
}