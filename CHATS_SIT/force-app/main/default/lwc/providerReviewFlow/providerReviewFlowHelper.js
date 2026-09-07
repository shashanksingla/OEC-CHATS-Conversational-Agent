import { helper } from 'c/generic_Utilities';

export const providerReviewFlowHelper = {

    handleValueUpdates(cmp, targetField, value) {
        //normal change handlers
        if (targetField == 'FA_StartDate') {
            cmp.providerReviewObj.Fiscal_Agreement_Start_Date__c = value;
        } else if (targetField == 'imporperPaymentAmount') {
            cmp.providerReviewObj.Improper_Payment_Amount__c = value;
        } else if (targetField == 'recoveryAmount') {
            cmp.providerReviewObj.Recovery_Amount__c = value;
        } 
        //multiselect combobox event handlers
        else if (targetField == 'Provider_Review__c_Sample_Month__c') {
            cmp.providerReviewObj.Sample_Month__c = value;
            cmp.setFAReasonState();
            cmp.fetchLicense();
        } else if (targetField == 'Provider_Review__c_Sample_Year__c') {
            cmp.providerReviewObj.Sample_Year__c = value;
            cmp.showHideMonths();
            cmp.setFAReasonState();
            cmp.fetchLicense();
        } else if (targetField == 'Provider_Review__c_CDE_REASON_END_AGRMT__c') {
            cmp.providerReviewObj.CDE_REASON_END_AGRMT__c = value;
        } else if (targetField == 'Provider_Review__c_Attendance_Tracking__c') {
            cmp.providerReviewObj.Attendance_Tracking__c = value;
        } else if (targetField == 'Provider_Review__c_Improper_Payment__c') {
            cmp.providerReviewObj.Improper_Payment__c = value;
            cmp.providerReviewObj.Improper_Payment_Amount__c =0;            
        } else if (targetField == 'Provider_Review__c_Recovery_Needed__c') {
            cmp.providerReviewObj.Recovery_Needed__c = value;
            cmp.providerReviewObj.Recovery_Amount__c =0;
        }// CCCAP-13277
        else if (targetField == 'Provider_Review__c_Attendance_Recorded__c') {
            cmp.providerReviewObj.Attendance_Recorded__c = value ; 
        } // end CCCAP-13277
    },
    popUpMessage(cmp) {
        if (cmp.currentState == 'wouldYouLikeToPickWhereLeft') {
            return 'Would you like to pick up where you left off?';
        } else if (cmp.currentState == 'ownerForm') {
            return 'You are the file owner for this provider and there may be a conflict with creating this provider review. Do you wish to proceed?';
        } else if (cmp.currentState == 'diffReviewerForm') {
            return 'Please assign to a different reviewer';
        } else if (cmp.currentState == 'draftWillBeDeleted') {
            return 'The Provider Review in Draft Status will be deleted. Would you like to continue?'
        } else if (cmp.currentState == 'reviewWithin6M') {
            return 'The provider has been reviewed in the last 6 months. Were all the file corrections made from the last review?';
        } else if (cmp.currentState == 'wereThereChangesSinceLastReview') {
            return 'Were there provider changes since last review? (such as new fiscal agreement, Provider Rates, or a Licensing change)'
        }else if(cmp.currentState == 'sampleMonthAfterEndDate'){
            return 'Sample Month is after the Fiscal Agreement End Date. Click Ok to proceed';
        }
    },
    getButtons(cmp) {
        let buttons = [];
        if (cmp.currentState == 'diffReviewerForm'){
            buttons.push({ 'label': 'Ok', 'Id': 'Ok', 'variant': 'neutral' });
        }else if(cmp.currentState == 'sampleMonthAfterEndDate'){
            buttons.push({ 'label': 'Ok', 'Id': 'Ok', 'variant': 'brand' });
            }else {
            buttons.push({ 'label': 'No', 'Id': 'No', 'variant': 'brand' });
            buttons.push({ 'label': 'Yes', 'Id': 'Yes', 'variant': 'neutral' });
        }
        return buttons;
    },
    setReviewStatus(cmp) {
        if (cmp.errorCount > 0) {
            cmp.providerReviewObj.Review_Status__c = "3";
        } else if (cmp.errorCount < 0) {
            cmp.providerReviewObj.Review_Status__c = "1";
        } else {
            cmp.providerReviewObj.Review_Status__c = "2";
        }
    }
}