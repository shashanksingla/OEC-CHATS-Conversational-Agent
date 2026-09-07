({
	onIndividualMatchOptionSelection : function(component, event, helper) {
        var evt = $A.get("e.c:peakAppUpdateParentComponentAttribute");
        evt.setParams({'attributeName':'stateID'});
        evt.setParams({'attributeValue':component.get("v.individual").IDN_STATE__c});
        evt.fire();
	}
})