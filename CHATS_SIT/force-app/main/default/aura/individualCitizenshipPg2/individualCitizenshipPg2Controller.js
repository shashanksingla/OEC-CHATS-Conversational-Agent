({
	doInit : function(component, event, helper) {
        helper.handleStsUpdate(component, event, helper);		
	},
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
    },
    //CCCAP-13633
    handleStsUpdate : function(component, event, helper) {
        helper.handleStsUpdate(component, event, helper);
    }
})