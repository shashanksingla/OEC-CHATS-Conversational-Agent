({   
    doInit: function(component, event, helper) {
    helper.checkForChildIndividuals(component);
},
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
    },
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    }
})