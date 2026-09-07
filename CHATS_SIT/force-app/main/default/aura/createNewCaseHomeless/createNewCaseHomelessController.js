({
    handleFieldLevelValidation : function(component, event, helper) {
       
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		return helper.validateCurrentPage(component);
    },
    doHandleHomelessChange :  function(component, event, helper) {
        component.set("v.IND_IS_HOMELESS",event.getParam("value")=='Y'?true:false);
    }
})