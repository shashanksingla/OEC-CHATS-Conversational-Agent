({
	doInit : function(component, event, helper) {
        if(component.get("v.casePhoneRec").CDE_TYPE_PHONE__c=="WOR"){
        	component.set("v.label","Message/Work Phone Number (XXX-XXX-XXXX)");
        }else if(component.get("v.casePhoneRec").CDE_TYPE_PHONE__c=="HOM"){
        	component.set("v.label","Home Phone Number (XXX-XXX-XXXX)");
        }else if(component.get("v.casePhoneRec").CDE_TYPE_PHONE__c=="MOB"){
        	component.set("v.label","Mobile Phone Number (XXX-XXX-XXXX)");
        }
	},
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		return helper.validateCurrentPage(component);
    }
})