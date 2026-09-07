({
    doInit : function(component, event, helper) {
        component.set('v.empIncomeObjNew.IDN_EMPLMT_INDIV__c', component.get("v.recordId"));
    },
    
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    }
})