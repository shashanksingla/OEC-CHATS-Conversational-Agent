({
    // Closing details modal
	closeModal : function(component, event, helper) {
        var taxRecord = component.get("v.taxRecord");
        component.set("v.removeReason", taxRecord.Remove_Reason__c);
        component.set("v.showDetailsModal", false);
	},
    
    // Save button function
    save : function(component, event, helper) {
        var taxRecord = component.get("v.taxRecord");
        // Added below if condition by Rishav for CCCAP-4909
        if(helper.validateReinstate(component)){
            var action = component.get("c.saveRecord");
            action.setParams({
                recordId : taxRecord.Id,
                removeReasonOld : taxRecord.Remove_Reason__c,
                removeReasonNew : component.get("v.removeReason")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    component.set("v.taxRecord.Remove_Reason__c", res.objectData.taxRecord.Remove_Reason__c);
                    component.set("v.taxRecord.Remove_Reason_Text__c", res.objectData.taxRecord.Remove_Reason_Text__c);
                    component.set("v.taxRecord.Reinstate__c", res.objectData.taxRecord.Reinstate__c);
                    component.set("v.taxRecord.Remove_Date__c", res.objectData.taxRecord.Remove_Date__c);
                    component.set("v.taxRecord.Reinstate_Date__c", res.objectData.taxRecord.Reinstate_Date__c);
                    var message = 'Update successful';
                    helper.handleSuccess(message);
                } else if(state === "ERROR") {
                    helper.handleError(response);
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    // Opens Adjustment details page in a new browser tab
    gotoAdjustmentRecord : function(component, event, helper) {
        var taxRecord = component.get("v.taxRecord");
        helper.nevigationHelper(component, taxRecord.Adjustment__c);
    },
    
    // Opens Tax Intercept details page in a new browser tab
    gotoTaxInterceptRecord : function(component, event, helper) {
        var taxRecord = component.get("v.taxRecord");
        helper.nevigationHelper(component, taxRecord.Id);
    },
    
    // Opens Provider details page in a new browser tab
    gotoProviderRecord : function(component, event, helper) {
        var taxRecord = component.get("v.taxRecord");
        helper.nevigationHelper(component, taxRecord.Provider__c);
    },
    
    // Opens Case details page in a new browser tab
    gotoCaseRecord : function(component, event, helper) {
        var taxRecord = component.get("v.taxRecord");
        helper.nevigationHelper(component, taxRecord.Case__c);
    }
})