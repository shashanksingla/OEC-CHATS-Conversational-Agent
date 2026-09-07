({
	showOverrideEligibility : function(component, event, helper) {
        
        $A.createComponent("c:eligibilityFlow_individualEligibility_override", {
            firstName:component.get("v.firstName"),
            lastName:component.get("v.lastName"),
            indivDetails:component.get("v.indivDetails"),
            indivElig:component.get("v.indivElig"),
            indivIneligibilityFailure:component.get("v.indivIneligibilityFailure"),
            householdEligibilityBeginDate:component.get("v.householdEligibilityBeginDate"),
            individualEnteredHouseholdDate:component.get("v.individualEnteredHouseholdDate"),
            lastIndivEligDetailEndDate:component.get("v.lastIndivEligDetailEndDate"),
            parentCaretaker:component.get("v.parentCaretaker")
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: "Override Individual Eligibility",
                    body: content,
                    showCloseButton: true,
                    cssClass: "slds-modal_large",
                    closeCallback: function() {
                        
                    }                                       
                });
            }
        });
		
	}
})