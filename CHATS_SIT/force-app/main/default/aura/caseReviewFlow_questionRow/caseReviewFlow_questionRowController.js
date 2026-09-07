({
    doInit : function(component, event, helper) {
        if(component.get("v.screenMode") == 'NEW'){
            var NAReasonOptions = component.get('v.responseWrapper.NAReasonOptions');
            if(NAReasonOptions.length == 2){
                component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', NAReasonOptions[1].value);
                component.set('v.isNAReasonDisabled', true);
            }
            component.set('v.responseWrapper.responseRec.CaseReview_QuestionMain__c', '');
            helper.resetErrorAndCausePicklists(component);
            if(NAReasonOptions.length != 2){
                component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', '');
            }
            var applicableOptions = [{'label' : '--None--', 'value' : null}];
            component.get('v.allErrorOptions').forEach( function(element, index) {
                applicableOptions.push(element);
            });
            component.set('v.CaseReview_Error1_Options', applicableOptions);
            component.set('v.CaseReview_Error2_Options', applicableOptions);
            component.set('v.CaseReview_Error3_Options', applicableOptions);
            component.set('v.CaseReview_Error4_Options', applicableOptions);
        } 
        if(component.get("v.screenMode") == 'EDIT'){
            var NAReasonOptions = component.get('v.responseWrapper.NAReasonOptions');
            if(NAReasonOptions.length == 2){
                component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', NAReasonOptions[1].value);
                component.set('v.isNAReasonDisabled', true);
            }
            if(component.get('v.responseWrapper.responseRec.CaseReview_QuestionMain__c') != 'NA'){
                component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', '');
            }
            helper.setErrorPicklistValues(component, undefined);
            helper.setApplicableOptions(component, 'CaseReview_Error1__c', true);
            helper.setApplicableOptions(component, 'CaseReview_Error2__c', true);
            helper.setApplicableOptions(component, 'CaseReview_Error3__c', true);
            helper.setApplicableOptions(component, 'CaseReview_Error4__c', true);
        }
    },
    
    setCausePicklistValues : function(component, event, helper) {
        var errorFieldName = event.getParam("index"); // CaseReview_Error1__c
        if(errorFieldName && component.get('v.rendered')){
            var causeFieldName = errorFieldName.replace("Error", "Cause"); // CaseReview_Cause1__c
            helper.setErrorPicklistValues(component, errorFieldName);
            helper.setApplicableOptions(component, errorFieldName, false);
            component.set('v.responseWrapper.responseRec.'+causeFieldName, null);
        }
    },
    
    handelMainQuestionUpdate : function(component, event, helper) {
        var errorCount = component.get("v.errorCount");
        if(event.getParam('oldValue') != 'NO' && event.getParam('value') == 'NO'){
            if(errorCount < 0){
                errorCount = errorCount + 2;
            } else {
                errorCount = errorCount + 1;
            }
            component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', '');
            helper.resetErrorAndCausePicklists(component);
        }
        if(event.getParam('oldValue') == 'NO' && event.getParam('value') != 'NO'){
            errorCount = errorCount - 1;
        }
        if(event.getParam('oldValue') != 'NA' && event.getParam('value') == 'NA'){
            helper.resetErrorAndCausePicklists(component);
            var NAReasonOptions = component.get('v.responseWrapper.NAReasonOptions');
            if(NAReasonOptions.length == 2){
                component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', NAReasonOptions[1].value);
                component.set('v.isNAReasonDisabled', true);
            }
            if(errorCount < 0){
                errorCount = 0;
            }
        }
        if(event.getParam('oldValue') != 'YES' && event.getParam('value') == 'YES'){
            component.set('v.responseWrapper.responseRec.CaseReview_NA_Reason__c', '');
            helper.resetErrorAndCausePicklists(component);
            if(errorCount < 0){
                errorCount = 0;
            }
        }
        component.set("v.errorCount", errorCount);
    },
    
    checkRowValidity : function(component, event, helper) {
        var isValid = helper.validateCurrentPage(component, event, helper);
        return isValid;
    },

    onRender: function(component, event, helper) {
        component.set('v.rendered', true);
    }
})