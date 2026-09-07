({
    doGetEligData : function(component, event) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            var action = component.get("c.getInitData");
            action.setParams({elgRunId : component.get("v.recordId"), eligibilityRec : component.get("v.eligibilityRun")});
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var nameString;
                    component.set("v.childCareProgram", response.getReturnValue().objectData['childCareProgram']);
                }
                else {
                }
            });
            $A.enqueueAction(action);
        }
    },
    navigateToRecord :  function(component, event, helper) {
        var recordId = event.currentTarget.dataset.item;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId
        });
        navEvt.fire(); 
    }
})