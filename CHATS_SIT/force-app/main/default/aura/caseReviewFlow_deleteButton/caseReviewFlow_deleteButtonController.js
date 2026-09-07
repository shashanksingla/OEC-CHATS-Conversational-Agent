({
    doDelete: function(component, event, helper) {
        component.set("v.showSpinner", true);
        var action = component.get("c.deleteCaseReviewButton");
        var recordId = component.get("v.recordId");
        action.setParams({"recordId" : recordId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set("v.showSpinner", false);
                    helper.showToast('success', 'Case Review deleted successfully');
                    helper.redirectToRecord(res.objectData.parentCase);
                } else {
                    component.set("v.showSpinner", false);
                    helper.showToast('error', res.errorMessage);
                }
            } else {
                var errors = response.getError();
                var message = 'Unknown error'; // Default message
                if (errors && errors[0] && errors[0].pageErrors) {
                    message = errors[0].pageErrors[0].message;
                }else if(errors && errors[0] && errors[0].fieldErrors){
                    message = errors[0].fieldErrors[0].message;
                }
                helper.showToast('error', message);
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);
    }
})