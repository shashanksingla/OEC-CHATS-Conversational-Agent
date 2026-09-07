({
    handleValidateCurrentPage : function(component, event, helper) {
        return helper.validateCurrentPage(component);
    },
    doInit : function(component, event, helper) {
        helper.divideZipCodeHelper(component, event, helper);
    },
    divideZipCode : function(component, event, helper) {
         helper.divideZipCodeHelper(component, event, helper);
    },
})