({
	showOverrideModal : function(component, event, helper) {
		 $A.createComponent("c:eligibilityFlow_overrideRedeterminationDate", {
            caseEligibilityRun:component.get("v.caseEligibilityRun"),
             caseRecId:component.get("v.caseRecId")
        },function(content, status) {
            if (status === "SUCCESS") {
                component.find('overlayLib').showCustomModal({
                    header: "Override Redetermination Date",
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