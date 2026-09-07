({
    openCaseReviewVFPage: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action1 = component.get("c.checkEligibility");
        action1.setParams({"recordId" : recordId,
                          "isDelete" : false});
        action1.setCallback(this, function(resp) {
            var state = resp.getState();
            if(state === "SUCCESS") {
                var res1 = resp.getReturnValue();
                console.log('result: ',res1);
                if(res1.isSuccessful){
                    var action = component.get("c.getVFBaseURL");
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if(state === "SUCCESS") {
                            var res = response.getReturnValue();
                            window.open(res+"/apex/caseReviewFlow_generatePDF?recordId="+component.get('v.recordId'), '_blank');
                        } else {
                            helper.showToast('error', response.getError);
                        }
                    });
                    $A.enqueueAction(action);
                }
                else{
                    component.set("v.showSpinner", false);
                    helper.showToast('error', res1.errorMessage);
                }
            }
            else {
                helper.showToast('error', resp.getError);
            }
        });
        $A.enqueueAction(action1);
    }
})