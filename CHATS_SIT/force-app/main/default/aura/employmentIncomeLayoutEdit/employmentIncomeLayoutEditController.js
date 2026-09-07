({
    doInit : function(component, event, helper) {
        component.set('v.empIncomeObj.IDN_EMPLMT_INDIV__c', component.get("v.parentObjId"));
    },
    
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    }
})