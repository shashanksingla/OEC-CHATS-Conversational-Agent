({
    doInit :function(component, event, helper){
        //CCCAP-11851
		var currentDate = new Date();
        var beginDate= new Date(currentDate.getUTCFullYear(), currentDate.getUTCMonth(), currentDate.getUTCDate());
        const date2 = new Date($A.get("$Label.c.Date_16Feb2025"));
        var beginDate2 = new Date(date2.getUTCFullYear(), date2.getUTCMonth(), date2.getUTCDate());
        if(beginDate >= beginDate2) {
            component.set("v.isDateAfter_16Feb2025", true);
        } else {
            component.set("v.isDateAfter_16Feb2025", false);
        }
        //end CCCAP-11851
        const JS_Activation_Date = Date.parse($A.get("$Label.c.CP_JS_Activation_Date")); 
        var countyPlanRec = component.get("v.countyPlanRec");
        if(Date.parse(countyPlanRec.DTE_BEGIN_EFFEV__c) >= JS_Activation_Date){
            component.set("v.jsActivated", true);
        }else{
            component.set("v.jsActivated", false);
        }
        helper.setRequired(component);
    },
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    handleCheckWaitlistEnrolmentFreeze: function(component, event, helper){
        helper.checkWaitlistEnrolmentFreeze(component);
    },
    handlesetRequired: function(component, event, helper){
        helper.setRequired(component);
    },
    handleNoSelectionValidation :function(component, event, helper){
        helper.handleNoSelectionValHelper(component);
    }   
})