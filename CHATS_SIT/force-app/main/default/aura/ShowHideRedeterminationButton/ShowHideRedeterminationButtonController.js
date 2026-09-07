({
    doInit : function(component, event, helper) {
        helper.doGetEligData(component, event);	
    },
    
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:RedeterminationFlow",
            componentAttributes: {
                recordId : component.get("v.recordId")
            }
        });
        evt.fire(); 
    }
})