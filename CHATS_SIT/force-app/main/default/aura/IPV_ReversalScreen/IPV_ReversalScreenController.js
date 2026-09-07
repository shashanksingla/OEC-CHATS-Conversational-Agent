({
	doInit : function(component, event, helper){
        helper.doInit(component,event,helper);
    },
    handleSaveRecord : function(component, event, helper) {
		helper.validateCurrentPage(component);
        if(component.get("v.isCurrentPageValid")){
            helper.handleSaveRecord(component,helper);
        }
	},
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    handleCancel : function(component, event, helper) {
		helper.redirectToRecord(component.get("v.recordId"));
    },
    verifyReversalDate : function(component, event, helper) {
		helper.verifyReversalDate(component);
    }
})