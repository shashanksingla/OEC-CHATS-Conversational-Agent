({
	handleIndivLink : function(component, event, helper) {
        
        helper.redirectToLightningComponent('c:eligibilityHistoryFlow_individualEligibility_indivDetails', 
                                            {"idnIndivFcompsn" : component.get("v.indivEligWrapper").idnIndivFcompsn,
                                             "returnId":component.get("v.returnId")});
	}
})