({
	doInit : function(component, event, helper) {
        helper.fetchAuthCopayRecordsHlp(component, event, helper);
		console.log("-- "+JSON.stringify(component.get("v.newCaseCopayRec")));
	},
    handleValidateCurrentPage : function(component, event, helper) {
    	helper.validateCurrentPage(component);
	},
	 validateAmountField : function(component, event, helper) {
	        helper.checkAmountFieldValidity(component,event.getSource().get("v.name"),event.getSource().get("v.value"));
	  },
    fetchAuthCopayRecords : function(component, event, helper) {
        helper.fetchAuthCopayRecordsHlp(component, event, helper);
		console.log("-- "+JSON.stringify(component.get("v.newCaseCopayRec")));
	},
})