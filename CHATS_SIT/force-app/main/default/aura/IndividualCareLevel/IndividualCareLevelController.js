({
    doInit : function(component, event, helper) {
    },
    handleSaveIndivCare : function(component, event, helper) {
        helper.checkCustomValidations(component, event, helper);
    },
    handleCancelIndivCare : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    handleValueChange : function(component, event, helper) {
        helper.doInitHlp(component, event, helper);
    },
})