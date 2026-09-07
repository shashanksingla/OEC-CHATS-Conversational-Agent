({
    doInit : function(component, event, helper) {
        var action2 = component.get("c.getDoInit");
        action2.setParams({"recordId": component.get("v.recordId")});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res=response.getReturnValue();
                var parentFeeDelinq = component.get("v.newParentFeeDelinquencyObj");
                if(res.authCopay != undefined){
                    parentFeeDelinq.IDN_COPAY_AUTH__c =res.authCopay.Id;
                }
                if(res.getSobjectName != undefined){
                    if(res.getSobjectName == 'T_SBSD_CASE__c') {
                        parentFeeDelinq.IDN_CASE__c =component.get("v.recordId");
                    } else if(res.getSobjectName == 'T_SBSD_INDIV__c') {
                        parentFeeDelinq.IDN_CLIENT__c =component.get("v.recordId");
                    }
                }
                component.set("v.newParentFeeDelinquencyObj",parentFeeDelinq);
                component.set("v.oneTimeDateLoadValidatity",false);
                component.set("v.oneTimeDateLoadValidatity",true);
                component.set("v.sObjectName", res.getSobjectName);
                component.set("v.authCopayRec", res.authCopayObj);
                component.set("v.loggedUserName", res.loggedUserName);
            }
        });
        $A.enqueueAction(action2);
    },
    
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    }
})