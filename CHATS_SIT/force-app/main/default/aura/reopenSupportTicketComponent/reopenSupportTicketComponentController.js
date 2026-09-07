({
    doInit :  function(component, event, helper){
        /* Commented as part of CCCAP-5733 
        var canAccessReopenButtonComponent = component.get('c.canAccessReopenButtonComponent');
        canAccessReopenButtonComponent.setCallback(this, function(res) {
            if (res.getState() === 'SUCCESS' && res.getReturnValue()==false) {
                component.set("v.canAccessReopenButtonComponentFlag",false);
            } 
            component.set("v.toggleSpinner",false);
        });
        $A.enqueueAction(canAccessReopenButtonComponent);*/
        component.set("v.toggleSpinner",false);
    },
    doCancel : function(component, event, helper){
        window.history.back();
    },
    closeModel  : function(component, event, helper){
        var recId = component.get("v.recordId");
        component.set("v.isOpen", false);
        window.parent.location = '/' + recId;
    },
    updReopenSupportTicket : function(component, event, helper){
        var recId = component.get("v.recordId");
        var input = component.get("v.param");
        var time = 1;
        if(!$A.util.isEmpty(input.Reopen_Reason__c)){
            var reopenSupportTicket = component.get('c.onReopenButtonClick');
            reopenSupportTicket.setParams({ recordId: recId, reOpenReason: input.Reopen_Reason__c });
            
            reopenSupportTicket.setCallback(this, function(res) {
                if (res.getState() === 'SUCCESS') {
                	var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Success!",
                        "message": "Ticket Reopened Successfully",
                        "type":"success"
                    });
                    window.parent.location = '/' + recId;
                    resultsToast.fire();
                } else {
                    window.parent.location = '/' + recId;
                }
            });
            $A.enqueueAction(reopenSupportTicket);
            /*
            input.Status__c = 'New';
            input.Root_Cause__c= 'Pending Triage';
            input.Ticket_Closure_Date__c= null;
            input.Date_Elevated__c = null;
            input.Reopened_By_User__c= true;
            input.Elevated_to__c = null;
            component.set("v.param",input);
            component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Success!",
                        "message": "Ticket Reopened Successfully",
                        "type":"success"
                    });
                    window.parent.location = '/' + recId;
                    resultsToast.fire();
                } else if (saveResult.state === "INCOMPLETE") {
                    console.log("User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    console.log('Problem saving record, error: ' + 
                                JSON.stringify(saveResult.error));
                } else {
                    console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                }
            })); */   
        }else{
            helper.toastMessage('Error', 'Please provide the Reopen Reason');
        } 
    }
})