({
	doInit : function(component, event, helper) {
        if(component.get("v.caseInfoRec").CDE_TYPE_INFO_CASE__c=="PMC"){
        	component.set("v.label","Preferred Method of Contact");
        }		
	},
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		return helper.validateCurrentPage(component);
    }
    
})