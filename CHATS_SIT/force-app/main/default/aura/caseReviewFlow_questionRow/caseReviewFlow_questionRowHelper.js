({
    resetErrorAndCausePicklists : function(component) {
        component.set('v.responseWrapper.responseRec.CaseReview_Cause1__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Cause2__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Cause3__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Cause4__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Error1__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Error2__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Error3__c', '');
        component.set('v.responseWrapper.responseRec.CaseReview_Error4__c', '');
        component.set('v.responseWrapper.responseRec.Causes_Payment_Error__c', ''); // Added by Rishav for CCCAP-7697
    },
    
    setApplicableOptions : function(component, errorFieldName, isInit) {
        var errorFieldValue = component.get('v.responseWrapper.responseRec.'+errorFieldName);
        var causeAttributeName = errorFieldName.replace("__c", "_Cause"); // CaseReview_Error1_Cause
        var applicableOptions = [{'label' : '--None--', 'value' : ''}];
        if(errorFieldValue){
            var allCauseOptions = component.get('v.allCauseOptions');
            var errorCauseMap = new Map();
            errorCauseMap.set("1", ["1","2","3"]);
            errorCauseMap.set("2", ["4","5","6"]);
            errorCauseMap.set("3", ["7","8"]);
            errorCauseMap.set("4", ["9","10"]);
            var causeAPIs = errorCauseMap.get(errorFieldValue);
            allCauseOptions.forEach(function(element) {
                if(causeAPIs.includes(element.value)) {
                    if(!isInit){
                        element.selected = false;
                    }
                    applicableOptions.push(element);
                }
            });
        }
        component.set('v.'+causeAttributeName, applicableOptions);
    },
    
    setErrorPicklistValues : function(component, errorFieldName) {
        var errorFields = ['CaseReview_Error1__c', 'CaseReview_Error2__c', 'CaseReview_Error3__c', 'CaseReview_Error4__c'];
        var error1Value = component.get('v.responseWrapper.responseRec.CaseReview_Error1__c');
        var error2Value = component.get('v.responseWrapper.responseRec.CaseReview_Error2__c');
        var error3Value = component.get('v.responseWrapper.responseRec.CaseReview_Error3__c');
        var error4Value = component.get('v.responseWrapper.responseRec.CaseReview_Error4__c');
        errorFields.forEach(function(currentFieldName) {
            if(errorFieldName == currentFieldName)
                return;
            var applicableOptions = [{'label' : '--None--', 'value' : ''}];
            let currentFieldValue = component.get('v.responseWrapper.responseRec.'+currentFieldName);
            var currentFieldAttribute = currentFieldName.replace("__c", "_Options"); // CaseReview_Error1_Options
            component.get('v.allErrorOptions').forEach(function(element) {
                if(element.value == currentFieldValue && !$A.util.isEmpty(currentFieldValue)){
                    element.selected = true;
                    applicableOptions.push(element);
                    return;
                }
                if(element.value != error1Value && element.value != error2Value && element.value != error3Value && element.value != error4Value){
                    element.selected = false;
                    applicableOptions.push(element);
                }
            });
            component.set('v.'+currentFieldAttribute, applicableOptions);
        });
        if(error1Value == undefined){
            component.set('v.responseWrapper.responseRec.CaseReview_Error1__c','');
        }
        if(error2Value == undefined){
            component.set('v.responseWrapper.responseRec.CaseReview_Error2__c','');
        }
        if(error3Value == undefined){
            component.set('v.responseWrapper.responseRec.CaseReview_Error3__c','');
        }
        if(error4Value == undefined){
            component.set('v.responseWrapper.responseRec.CaseReview_Error4__c','');
        }
    }
})