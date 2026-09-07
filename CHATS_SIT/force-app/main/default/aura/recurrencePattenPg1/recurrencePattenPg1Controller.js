({
	doInit : function(component, event, helper) {
	},
     handleValidateCurrentPage : function(component, event, helper) {
         debugger;
         console.log('helper--'+helper);
        helper.validateCurrentPage(component);
    },
     handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
   
})