({
	doInit : function(component, event, helper) {
      
	},
    navigateToOverrideEligibility : function(component, event, helper) {
        
        $A.createComponent("c:eligibilityFlow_householdEligibility_override", {
            caseRec:component.get("v.caseRec"),
            caseEligibilityDetails:component.get("v.caseEligibilityDetails"),
            caseEligibility:component.get("v.caseEligibility"),
            caseEligibilityRun:component.get("v.caseEligibilityRun"),
            value:component.get("v.caseEligibilityDetails").CDE_STATUS_ELIGTY_FAMILY__c,
            householdIneligibilityFailure:component.get("v.householdIneligibilityFailure"),
            indivEligIdToWrapper:component.get("v.indivEligIdToWrapper"),
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: "Override Household Eligibility",
                    body: content,
                    showCloseButton: false,
                    cssClass: "slds-modal_large",
                    closeCallback: function() {
                        
                    }                                       
                });
            }
        });
    }
})