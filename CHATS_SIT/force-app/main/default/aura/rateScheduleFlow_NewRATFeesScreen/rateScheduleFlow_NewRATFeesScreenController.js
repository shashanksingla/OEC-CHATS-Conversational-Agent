({
    doInit : function(component, event, helper) {
    	component.set("v.fiscalRateValues.IDN_FISCAL_SCH__c",component.get("v.rateScheduleId"));    
        helper.calcAmountPerPeriod(component);
    },
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
    },
    calcAmountToPeriod : function(component, event, helper){
        helper.calcAmountPerPeriod(component);
    }
})