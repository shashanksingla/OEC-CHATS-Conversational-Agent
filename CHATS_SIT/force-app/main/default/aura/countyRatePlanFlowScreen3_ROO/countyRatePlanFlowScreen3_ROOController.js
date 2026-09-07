({
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
    },
         handleSetRequired : function(component, event, helper){
        helper.setRequired(component);
    },
    handleChange: function (cmp, event) {
        var changeValue = event.getParam("value");
        if (changeValue== true){
            cmp.set("v.value", true);
        }
        
    }

  
})