({
	doGetCaseData : function(component, event) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            var action = component.get("c.getInitData");
            action.setParams({  caseId : component.get("v.recordId")});
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var nameString;
                    component.set("v.childCareProgram", response.getReturnValue().objectData['childCareProgram']);
                    
                }
                else {
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        }
    },
})