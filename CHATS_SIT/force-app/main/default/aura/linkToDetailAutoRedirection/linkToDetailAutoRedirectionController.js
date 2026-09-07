({
    doRedirect : function(component, event, helper) {
        var action = component.get("c.fetchObjectdata");
        action.setParams({'recordId':component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": response.getReturnValue().Support_Ticket__c,
                "slideDevName": "detail"
            });
            navEvt.fire();
        });
        $A.enqueueAction(action);
    }
})