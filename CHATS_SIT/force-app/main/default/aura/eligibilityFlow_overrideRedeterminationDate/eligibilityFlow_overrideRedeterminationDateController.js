({
    doInit : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.caseEligibilityRun"))){
            component.set("v.dte_redet_ovrd__c",component.get("v.caseEligibilityRun.dte_redet_ovrd__c"));
            component.set("v.cde_date_redet_ovrd__c",component.get("v.caseEligibilityRun.cde_date_redet_ovrd__c"));
            component.set("v.txt_cmt_ovrd__c",component.get("v.caseEligibilityRun.txt_cmt_ovrd__c"));
        }
    },
    updateRedeterminationDate : function(component, event, helper) {
        
        var areAllFieldsValid = helper.validateFields(component);
        if(areAllFieldsValid) {
            var eligRunRec = {"sobjectType":'batchsit_t_eligty_run__x',
                              "idn_run_eligty__c":component.get("v.caseEligibilityRun").idn_run_eligty__c,
                              "dte_redet_ovrd__c":component.get("v.caseEligibilityRun").dte_redet_ovrd__c,
                              "cde_date_redet_ovrd__c":component.get("v.caseEligibilityRun").cde_date_redet_ovrd__c,
                              "txt_cmt_ovrd__c":component.get("v.caseEligibilityRun").txt_cmt_ovrd__c
                             };
            helper.callServer(component, "c.updateExternalObjRecords", function(response){
                // pass returned value to callback function
                if(response.isSuccessful==true){
                    component.find("overlayLib").notifyClose();
                    helper.fireToast("duration", "success", "Success!", "Redetermination date has been successfully overridden.");
                    $A.get('e.force:refreshView').fire();
                }else{
                    var pageMessages = [response.errorMessage];
                    component.set("v.pageMessages",pageMessages);
                }
            }, {"lstSObject":[component.get("v.caseEligibilityRun")],
                "isFinalStep":true}, false); 
        }
        
    },
    closeModal : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})