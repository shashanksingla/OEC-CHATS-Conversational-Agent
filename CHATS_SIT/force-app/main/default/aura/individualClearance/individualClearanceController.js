({
    onIndividualMatchOptionSelection : function(component, event, helper) {
        
        var evt = $A.get("e.c:peakAppUpdateParentComponentAttribute");
        evt.setParams({'attributeName':'stateID'});
        evt.setParams({'attributeValue':$A.get("$Label.c.SIDMOD_STATE_ID_REQUIRED")});
        evt.fire();
    }
})