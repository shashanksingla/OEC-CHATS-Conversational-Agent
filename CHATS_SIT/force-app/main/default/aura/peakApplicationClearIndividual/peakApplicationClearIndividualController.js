({
    doInit : function(component, event, helper) {
        var applicationIndividualForClearance = component.get("v.applicationIndividualForClearance");
        component.set("v.showRow",true);
    },
    onIndividualMatchOptionSelection : function(component, event, helper) {
        var evt = $A.get("e.c:peakAppUpdateParentComponentAttribute");
        evt.setParams({'attributeName':'stateID'});
        evt.setParams({'attributeValue':null});
        evt.fire();
    }
})