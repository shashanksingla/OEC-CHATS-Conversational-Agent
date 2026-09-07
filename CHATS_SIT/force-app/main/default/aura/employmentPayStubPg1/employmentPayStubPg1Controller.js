({
	doInit : function(component, event, helper) {
      console.log('options--'+component.get('v.options'));
	},
     handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
     handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    getEmploymentPayStub : function(component, event, helper) {
        helper.getEmploymentPayStubHlp(component, event, helper);
        
    }
})