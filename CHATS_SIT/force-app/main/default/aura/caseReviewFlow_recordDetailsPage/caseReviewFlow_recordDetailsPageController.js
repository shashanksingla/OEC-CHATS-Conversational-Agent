({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        component.set("v.showSpinner", true);
        var action = component.get("c.checkRecordAccess");
        action.setParams({"recordId" : recordId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set("v.showSpinner", false);
                    component.set("v.isAccessible", true);
                } else {
                    helper.showToast('error', res.errorMessage);
                    component.set("v.showSpinner", false);
                    component.set("v.isAccessible", false);
                    if(res.objectData.caseId){
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": res.objectData.caseId,
                            "slideDevName": "details"
                        });
                        navEvt.fire();
                    } else {
                        window.history.back();
                    }
                }
            } else {
                helper.showToast('error', response.getError);
                window.history.back();
            }
        });
        $A.enqueueAction(action);
    }
})