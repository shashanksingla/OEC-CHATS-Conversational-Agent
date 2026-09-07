({
    doInit : function(component, event, helper){
        helper.initializeNewRecord(component);  
    }
    ,handleSaveRecord : function(component, event, helper) {
		helper.validateCurrentPage(component);
        if(component.get("v.isCurrentPageValid")){
            helper.handleSaveRecord(component,helper);
        }
	},
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    handleCancel : function(component, event, helper) {
		helper.handleCancel(component.get("v.recordId"));
    },
    verifyDate : function(component, event, helper) {
		helper.verifyDate(component);
    }
})