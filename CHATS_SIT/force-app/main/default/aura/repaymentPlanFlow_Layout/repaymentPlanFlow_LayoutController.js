({
    doInit : function(component, event, helper) {
        component.set('v.repaymentPlanObj.IDN_PROVR__c', component.get("v.recordId"));
        if(component.get('v.sObjName') == 'T_PMT_PLAN__c'){
            component.set('v.repaymentPlanObj.IDN_PROVR__c', component.get("v.parentObjId"));
        }
    },

    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    }
})