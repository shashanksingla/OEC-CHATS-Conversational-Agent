({
    doGetEligData : function(component, event) {
        // Create the action
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            var action = component.get("c.getInitData");
            action.setParams({caseId : component.get("v.recordId")});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.childCareProgram", response.getReturnValue().objectData['childCareProgram']);
                }
                else {
                }
            });
            $A.enqueueAction(action); 
        }
    }
})