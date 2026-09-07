({
    getInitData : function(component, event, helper){
        helper.getInitData(component); 
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
        helper.deleteInvestigatoryInformations(component,helper);
        helper.redirectToRecord(component.get("v.recordId"));
    },
    calculateEndDate : function(component, event, helper) {
        helper.calculateEndDate(component,helper);
    },
    verifyBeginDate : function(component, event, helper) {
        helper.verifyBeginDate(component,helper);
    },
    verifyDeterminationDate : function(component, event, helper) {
        var isValid=helper.verifyDeterminationDate(component,helper);
        if(isValid){
            helper.calculateBeginDate(component);
        }
    },
    createInvestigatoryInfo : function(component, event, helper){
        helper.createInvestigatoryInfo(component, event, helper);
    },
    createInvestigatoryFinding : function(component, event, helper){
        helper.createInvestigatoryFinding(component, event, helper);
    },
    handleRowAction : function(component, event, helper){
        helper.handleRowAction(component, event, helper);
    }
})