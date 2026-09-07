({
	doInit : function(component, event, helper) {
        //component.set("v.recordId","x14g00000000001AAA");
        //helper.getAuthCopayRecords(component);
        var eDt = component.get('v.effectiveDate');
        if(eDt!=null && eDt!='null' && eDt!=undefined && eDt!='undefined' && eDt!=''){
            component.set('v.effAuthCopayDate', eDt);
        }
        var idnVal = component.get("v.caseCopayRec.idn_case__c");
        if(idnVal != undefined && idnVal != 'undefined'){
            helper.getAuthCopayRecords(component);
        }
	},
    handleCaseCopayRecChange: function(component, event, helper) {
        var idnVal = component.get("v.caseCopayRec.idn_case__c");
        if(idnVal != undefined && idnVal != 'undefined'){
            helper.getAuthCopayRecords(component);
        }
    },
    handleValidateCurrentPage : function(component, event, helper) {
    	helper.validateCurrentPage(component);
	},
	 validateAmountField : function(component, event, helper) {
	        helper.checkAmountFieldValidity(component,event.getSource().get("v.name"),event.getSource().get("v.value"));
	  }
})