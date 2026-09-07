({
    showIneligibilityReasons : function(component, event, helper) {
        
        $A.createComponent("c:eligibilityFlow_FailureReason", {
            ineligibilityFailures:component.get("v.householdIneligibilityFailure"),
            FCEligibilityID:component.get("v.householdEligibilityId")
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: "Household Ineligibility Reasons",
                    body: content,
                    showCloseButton: false,
                    cssClass: "slds-modal_large",
                    closeCallback: function() {
                        
                    }                                       
                });
            }
        });
        
        
        /*
       
        $A.createComponent("c:eligibilityFlow_householdEligibility_ineligUpdate", {
            householdIneligibilityFailure:component.get("v.householdIneligibilityFailure"),
            householdEligibilityId:component.get("v.householdEligibilityId"),
            ineligReasons:component.get("v.ineligReasons")
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: "Household Ineligibility Reasons",
                    body: content,
                    showCloseButton: true,
                    cssClass: "slds-modal_large",
                    closeCallback: function() {
                        
                    }                                       
                });
            }
        });*/
    }
})