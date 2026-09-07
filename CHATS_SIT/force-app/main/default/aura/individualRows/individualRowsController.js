({
	handleIndivLink : function(component, event, helper) {
        
        helper.redirectToLightningComponent('c:eligibilityFlow_individualEligibility_indivDetails', 
                                            {"idnIndivFcompsn" : component.get("v.indivEligWrapper").idnIndivFcompsn});
	}
})