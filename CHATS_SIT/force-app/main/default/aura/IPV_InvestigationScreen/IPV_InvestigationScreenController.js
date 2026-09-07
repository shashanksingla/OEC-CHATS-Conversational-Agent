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
    verifyInvStatusDate : function(component, event, helper){
        helper.verifyInvStatusDate(component,helper);
    },
    verifyInvBeginDate : function(component, event, helper){
        helper.verifyInvBeginDate(component,helper);
    },
    verifyInvEndDate : function(component, event, helper){
        helper.verifyInvEndDate(component,helper);
    },
    verifyInvResultDate : function(component, event, helper){
        helper.verifyInvResultDate(component,helper);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    handleCancel : function(component, event, helper) {
		helper.redirectToRecord(component.get("v.recordId"));
	}
})