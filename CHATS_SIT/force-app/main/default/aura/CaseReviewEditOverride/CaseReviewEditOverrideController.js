({
    doInit : function(component, event, helper) {
        // LWC is embedded directly in the template, no navigation needed
    },

    onRecordLoaded : function(component, event, helper) {
        var fields = component.get("v.caseReviewFields");
        if (fields && fields.Case__c) {
            component.set("v.caseId", fields.Case__c);
        }
    }
})