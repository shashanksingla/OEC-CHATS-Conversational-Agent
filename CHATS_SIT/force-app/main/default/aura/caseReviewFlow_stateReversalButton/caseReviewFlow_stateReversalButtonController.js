({
    doInit : function(component, event, helper) {
        // Updated 'taskComment' logic by Rishav for CCCAP-7603
        var action = component.get("c.generateTaskComment");
        action.setParams({"recordId" : component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set('v.taskComment', response.getReturnValue());
            } else {
                helper.showToast('error', response.getError);
            }
        });
        $A.enqueueAction(action);
    },
    
    doComplete : function(component, event, helper) {
        var isValid = helper.validateCurrentPage(component, event, helper);
        if(isValid){
            var action = component.get("c.sumbitForStateReversal");
            action.setParams({"taskComment" : component.get('v.taskComment'), 
                              "recordId" : component.get('v.recordId')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res = response.getReturnValue();
                    if(res.isSuccessful){
                        helper.showToast('success', 'Task T121 – State Reversal Request is created on Case Review '+res.objectData.recordName+' and assigned to '+res.objectData.userName+'.');
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