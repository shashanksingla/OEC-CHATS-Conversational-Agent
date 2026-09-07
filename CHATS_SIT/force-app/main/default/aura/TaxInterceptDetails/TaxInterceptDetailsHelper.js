({
    // Green Success Pop-up
    handleSuccess : function(message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":'success',
            "message": message
        });
        toastEvent.fire();
    },
    
    // Red Error Pop-up
    handleError : function(response) {
        var errors = response.getError();
        if(errors){
            console.log(errors);
            if (errors[0] && errors[0].message){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type":'error',
                    "message": errors[0].message
                });
                toastEvent.fire();
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type":'error',
                    "message": "Update unsuccessful"
                });
                toastEvent.fire();
            }
        }
    },
    
    // Opens record details page in a new browser tab
    nevigationHelper : function(component, recordId) {
        var navService = component.find("navService");
        var pageReference = {
            "type": "standard__recordPage",
            "attributes": {
                "recordId": recordId,
                "actionName": "view"
            }
        }
        navService.generateUrl(pageReference)
        .then($A.getCallback(function(url) {
            window.open(url,'_blank');
        }));
    },
    
    // Cannot be reinstated after November 1st
    validateReinstate : function(component) {
        var canReinstate = true;
        var today = new Date();
        var november1st = new Date(today.getFullYear(), 10, 1);
        var removeReasonOld = component.get("v.taxRecord.Remove_Reason__c");
        var removeReasonNew = component.get("v.removeReason");
        if(!component.get("v.isAdmin") && today >= november1st && $A.util.isEmpty(removeReasonNew) && !$A.util.isEmpty(removeReasonOld)){
            canReinstate = false;
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": $A.get("$Label.c.taxIntercept_reinstateError")
            });
            toastEvent.fire();
        }
        return canReinstate;
    }
})