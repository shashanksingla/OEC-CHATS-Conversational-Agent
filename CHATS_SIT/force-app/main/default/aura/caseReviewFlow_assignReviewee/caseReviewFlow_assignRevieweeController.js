({
    doComplete : function(component, event, helper) {
        var isValid = helper.validateCurrentPage(component, event, helper);
        if(isValid){
            var action = component.get("c.submitToReviewee");
            action.setParams({"revieweeId" : component.get('v.revieweeId'),
                              "recordId" : component.get('v.recordId')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    if(res.isSuccessful){
                        helper.showToast('success', 'Task T118 – Case Review Complete is created on Case ' + res.objectData.caseNumber + ' and assigned to ' + res.objectData.userName + '.');
                        helper.redirectToRecord(component.get('v.recordId'));
                    } else {
                        helper.showToast('error', res.errorMessage);
                    }
                } else {
                    helper.showToast('error', response.getError);
                }
            });
            $A.enqueueAction(action);
        }
    }
})