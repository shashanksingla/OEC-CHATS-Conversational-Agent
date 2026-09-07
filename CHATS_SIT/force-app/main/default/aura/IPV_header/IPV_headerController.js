({
    doInit : function(component, event, helper) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            var action = component.get("c.getLatestIPVRecord");
            action.setParams({  individualId : component.get("v.recordId")});
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var nameString;
                    component.set("v.ipvRecordId", response.getReturnValue());
                }
                else{
                    
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    },
    handleClick :  function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.ipvRecordId")
        });
        navEvt.fire();
    }
})