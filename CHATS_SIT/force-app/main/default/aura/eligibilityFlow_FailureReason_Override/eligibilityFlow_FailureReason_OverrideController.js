({
    doSave : function(component, event, helper) {
        
        
        var FailureCodes = '';
        component.get("v.ineligReasons").forEach(function(ineligReason){
            if(ineligReason.selected==true){
                FailureCodes+=ineligReason.code+',';
            }
        });
        var overlayLib = component.find("overlayLib");
        helper.doContinuousCallOuts(component,"BRESaveIneligibilityReasons",
                                    [component.get("v.FCEligibilityID"),
                                     !$A.util.isEmpty(component.get("v.FCIndividualID"))?component.get("v.FCIndividualID"):'',
                                     component.get("v.DocumentId"),
                                     FailureCodes], 
                                    function(response){
                                        
                                        if(!$A.util.isEmpty(component.get("v.FCIndividualID"))){
                                            helper.redirectToLightningComponent('c:eligibilityFlow_individualEligibility_indivDetails', 
                                                                                {"idnIndivFcompsn" : component.get("v.FCIndividualID")});
                                        }else{
                                            helper.redirectToLightningComponent('c:eligibilityFlow', 
                                                                                {"recordId" : component.get('v.eligibleRunSFId')});
                                        }
                                        
                                    });
    },
    doCloseModal : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})