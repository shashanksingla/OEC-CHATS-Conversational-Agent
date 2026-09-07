({
	doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                           
                                           component.set("v.indivEligWrapper",response.objectData.indivEligWrapper);
                                           component.set("v.eligibilityRunSFId", response.objectData.eligibilityRunSFId);
                                           component.set("v.eligibilityRunStatus", response.objectData.eligibilityRunStatus);
                                            if(response.objectData.eligibilityRunStatus=='CFM' || response.objectData.readOnlyMode==true){
                                               component.set("v.readOnlyMode",true);
                                            }
                                           component.set("v.initLoaded",true);
                                        }, {'idnIndivFcompsn':component.get("v.idnIndivFcompsn")}, 
                                        false, null);
    },
    doFinish : function(component, event, helper) {
        helper.redirectToLightningComponent('c:eligibilityFlow', {'recordId':component.get("v.eligibilityRunSFId")});
    }
})