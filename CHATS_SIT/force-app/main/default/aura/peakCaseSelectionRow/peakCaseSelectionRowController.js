({
	doInit : function(component, event, helper) {
		var mapCaseIdCaseStatus = component.get("v.mapCaseIdCaseStatus");
        var caseIndividual = component.get("v.caseIndividual");
        component.set("v.caseStatus",mapCaseIdCaseStatus[caseIndividual.IDN_CASE__c]);
	},
    onIndividualMatchOptionSelection : function(component, event, helper) {
        var evt = $A.get("e.c:peakAppUpdateParentComponentAttribute");
        evt.setParams({'attributeName':'selectedCaseID'});
        evt.setParams({'attributeValue':component.get("v.caseIndividual.IDN_CASE__c")});
        evt.setParams({'caseStatus':component.get("v.caseStatus")});
        evt.fire();
    }
})