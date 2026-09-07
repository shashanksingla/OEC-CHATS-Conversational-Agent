({
    setNewCaseButtonVisibility : function(cmp, event, helper) {
        var action = cmp.get("c.getCaseButtonVisibility");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res =response.getReturnValue();
                if(res){
                    cmp.set("v.newCaseVisible", true); 
                }
            } else if(state === "ERROR") {}
        });
        $A.enqueueAction(action);
    },
    
    verifyCriteria : function(cmp, event, helper) {
        var indivSearchWrapper = cmp.get("v.indivSearchWrapper");
        // Added 'emailId' condition below by Rishav for CCCAP-3239
        if((indivSearchWrapper.indivRec.NAM_FIRST__c== null || indivSearchWrapper.indivRec.NAM_FIRST__c== undefined ||indivSearchWrapper.indivRec.NAM_FIRST__c=='' )
           &&(indivSearchWrapper.indivRec.NAM_LAST__c== null || indivSearchWrapper.indivRec.NAM_LAST__c== undefined ||indivSearchWrapper.indivRec.NAM_LAST__c=='' )
           &&(indivSearchWrapper.indivRec.IDN_STATE__c== null || indivSearchWrapper.indivRec.IDN_STATE__c== undefined ||indivSearchWrapper.indivRec.IDN_STATE__c=='' )
           &&(indivSearchWrapper.caseId== null || indivSearchWrapper.caseId== undefined ||indivSearchWrapper.caseId=='' )
           &&(indivSearchWrapper.indivRec.NBR_SSN__c== null || indivSearchWrapper.indivRec.NBR_SSN__c== undefined ||indivSearchWrapper.indivRec.NBR_SSN__c=='' )
           &&(indivSearchWrapper.indivRec.DTE_DOB__c== null || indivSearchWrapper.indivRec.DTE_DOB__c== undefined ||indivSearchWrapper.indivRec.DTE_DOB__c=='' )
           &&(indivSearchWrapper.phone== null || indivSearchWrapper.phone== undefined ||indivSearchWrapper.phone=='' )
           &&(indivSearchWrapper.city== null || indivSearchWrapper.city== undefined ||indivSearchWrapper.city=='' )
           &&(indivSearchWrapper.county== null || indivSearchWrapper.county== undefined ||indivSearchWrapper.county =='' )
           &&(indivSearchWrapper.zip== null || indivSearchWrapper.zip== undefined ||indivSearchWrapper.zip =='' )
           &&(indivSearchWrapper.emailId== null || indivSearchWrapper.emailId== undefined ||indivSearchWrapper.emailId =='')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": 'Please enter additional search criteria'
            });
            toastEvent.fire();
            cmp.set("v.newCaseDisabled", true);
            return false;
        } else {
            return true;
        }
    }
})