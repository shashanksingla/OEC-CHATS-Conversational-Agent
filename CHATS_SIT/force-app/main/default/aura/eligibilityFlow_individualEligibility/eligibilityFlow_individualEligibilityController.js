({
	showOverrideEligibility : function(component, event, helper) {
        
        $A.createComponent("c:eligibilityFlow_individualEligibility_override", {
            firstName:component.get("v.indivEligWrapper.firstName"),
            lastName:component.get("v.indivEligWrapper.lastName"),
            indivDetails:component.get("v.indivEligWrapper.indivEligDetail"),
            indivElig:component.get("v.indivEligWrapper.indivElig"),
            indivIneligibilityFailure:component.get("v.indivEligWrapper.indivEligFailrs"),
            householdEligibilityBeginDate:component.get("v.indivEligWrapper.householdEligibilityBeginDate"),
            individualEnteredHouseholdDate:component.get("v.indivEligWrapper.individualEnteredHouseholdDate"),
            lastIndivEligDetailEndDate:component.get("v.indivEligWrapper.lastIndivEligDetailEndDate"),
            parentCaretaker:component.get("v.indivEligWrapper.isParentCaretaker")
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