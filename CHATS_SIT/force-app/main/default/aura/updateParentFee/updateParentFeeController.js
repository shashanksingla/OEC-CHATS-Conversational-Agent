({
	doInit : function(component, event, helper) {
		component.set("v.amt_copay_case_ft_qlty__c",Math.floor(component.get("v.caseCopayRec").amt_copay_case_ft__c * 0.8));
	    component.set("v.amt_copay_case_pt_qlty__c",Math.floor(component.get("v.caseCopayRec").amt_copay_case_pt__c * 0.8));
        component.set("v.amt_copay_case_ft__c", Math.floor(component.get("v.caseCopayRec").amt_copay_case_ft__c));
        component.set("v.amt_copay_case_pt__c", Math.floor(component.get("v.caseCopayRec").amt_copay_case_pt__c));
	},
    handleValidateCurrentPage : function(component, event, helper) {
    	helper.validateCurrentPage(component);
	},
     handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
   validateField : function(component, event, helper) {
		
        helper.checkFieldValidity(component,event.getSource().get("v.label"),event.getSource().get("v.value"));
    }
})