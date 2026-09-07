({
    checkCustomValidations : function(component, event, helper) {
        var isRequiredFieldsVerified = true;
        if(component.get('v.repaymentPlanObj.CDE_COUNTY__c') == null || 
           component.get('v.repaymentPlanObj.CDE_COUNTY__c') == undefined ||
           component.get('v.repaymentPlanObj.CDE_COUNTY__c') == ""){
            isRequiredFieldsVerified = false;
        }
        if(component.get('v.repaymentPlanObj.IDN_PROVR__c') == null || 
           component.get('v.repaymentPlanObj.IDN_PROVR__c') == undefined ||
           component.get('v.repaymentPlanObj.IDN_PROVR__c') == ""){
            isRequiredFieldsVerified = false;
        }
        if(component.get('v.repaymentPlanObj.AMT_PLAN_PMT__c') == null || 
           component.get('v.repaymentPlanObj.AMT_PLAN_PMT__c') == undefined ||
           component.get('v.repaymentPlanObj.AMT_PLAN_PMT__c') == ""){
            isRequiredFieldsVerified = false;
        }
        if(!isRequiredFieldsVerified){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": 'Please fill all the mandatory fields'
            });
            toastEvent.fire();
            return false;
        }
        var isCountyVerified = true;
        var allowedCounties = component.get('v.allowedCounties');
        if(!allowedCounties.includes(component.get('v.repaymentPlanObj.CDE_COUNTY__c')) && !component.get('v.isAdmin')){
            isCountyVerified = false;
        }
        if(!isCountyVerified){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": 'The Repayment Plan you are trying to update is with a county that does not match your assigned county/(ies). Changes made will not be save. Select Cancel to exit the record.'
            });
            toastEvent.fire();
            return false;
        }
        if(isRequiredFieldsVerified & isCountyVerified){
            return true;
        }
    },
    
    // Green Success Pop-up
    handleSuccess : function(message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":'success',
            "message": message
        });
        toastEvent.fire();
    }
})