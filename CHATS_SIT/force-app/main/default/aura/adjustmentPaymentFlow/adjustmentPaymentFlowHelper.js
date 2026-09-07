({
    checkCustomValidations : function(component, event, helper) {
        var isRequiredFieldsVerified = true;
        var blankFieldNames = '';
        if(helper.isEmpty(component.get('v.adjPaymentObj.AMT_PMT_ADJMT__c'))){
            isRequiredFieldsVerified = false;
            blankFieldNames = helper.checkBlankFields(blankFieldNames, 'Amount');
        }
        if(helper.isEmpty(component.get('v.adjPaymentObj.CDE_COUNTY__c'))){
            isRequiredFieldsVerified = false;
            blankFieldNames = helper.checkBlankFields(blankFieldNames, 'County');
        }
        if(helper.isEmpty(component.get('v.adjPaymentObj.CDE_TYPE_PMT_ADJMT__c'))){
            isRequiredFieldsVerified = false;
            blankFieldNames = helper.checkBlankFields(blankFieldNames, 'Payment Type');
        }
        if(helper.isEmpty(component.get('v.adjPaymentObj.DTE_PMT_ADJMT__c'))){
            isRequiredFieldsVerified = false;
            blankFieldNames = helper.checkBlankFields(blankFieldNames, 'Date Paid');
        }
        if(!isRequiredFieldsVerified){
            helper.handleError('Please fill all the mandatory fields: ' + blankFieldNames);
            return false;
        } else {
            return true;
        }
    },
    
    checkBlankFields : function(blankFieldNames, fieldName){
        if(this.isEmpty(blankFieldNames)){
            blankFieldNames += fieldName;
        } else {
            blankFieldNames += ', ' + fieldName;
        }
        return blankFieldNames;
    },
    
    isEmpty : function(value){
        if(value == null || value == undefined || value == ""){
            return true;
        } else {
            return false;
        }
    },
    
    handleSuccess : function(message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":'success',
            "message": message
        });
        toastEvent.fire();
    },
    
    handleError : function(message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type":'error',
            "message": message
        });
        toastEvent.fire();
    },
    
    clearAllFields : function(component) {
        component.set('v.adjPaymentObj.AMT_PMT_ADJMT__c', '');
        component.set('v.adjPaymentObj.CDE_COUNTY__c', '');
        component.set('v.adjPaymentObj.CDE_ACTION_ADMIN__c', '');
        component.set('v.adjPaymentObj.CDE_TYPE_PMT_ADJMT__c', '');
        component.set('v.adjPaymentObj.IDN_CASE__c', '');
        component.set('v.adjPaymentObj.DTE_PMT_ADJMT__c', '');
        component.set('v.adjPaymentObj.IDN_PROVR__c', '');
        component.set('v.adjPaymentObj.IDN_PMT__c', '');
        component.set('v.adjPaymentObj.TXT_INFO_OTHER__c', '');
        component.set('v.adjPaymentObj.IDN_RCPT_PMT__c', '');
        component.set('v.adjPaymentObj.TXT_NBR_CHECK_PMT__c', '');
    }
})