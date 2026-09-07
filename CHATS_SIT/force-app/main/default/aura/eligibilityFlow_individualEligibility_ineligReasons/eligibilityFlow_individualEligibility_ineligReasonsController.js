({
    showIneligibilityReasons : function(component, event, helper) {
        
        $A.createComponent("c:eligibilityFlow_FailureReason", {
            ineligibilityFailures:component.get("v.indivIneligibilityFailure"),
            FCIndividualID:component.get("v.idnIndivFcompsn"),
            FCEligibilityID:component.get("v.idnEligtyFcompsn")
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: "Individual Ineligibility Reasons",
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