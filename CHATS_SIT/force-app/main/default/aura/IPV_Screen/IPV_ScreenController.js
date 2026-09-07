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
		helper.redirectToRecord(component.get("v.recordId"));
	},
    verifyReceivedDate : function(component, event, helper){
        helper.verifyReceivedDate(component,helper);
    },
    verifyStatusDate : function(component, event, helper){
        helper.verifyStatusDate(component,helper);
    },
    verifyResultDeterminationDate : function(component, event, helper){
        helper.verifyResultDeterminationDate(component,helper);
    }
})