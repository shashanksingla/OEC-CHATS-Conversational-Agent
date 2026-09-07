({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                            debugger;
                                            component.set("v.indivDetails",response.objectData.indEligibilityDetail);
                                            component.set("v.indivElig",response.objectData.indEligibilityHist);
                                            component.set("v.indivEligWrapper",response.objectData.indivEligWrapper);
                                            console.log('response.objectData.indivDetails---'+JSON.stringify(response.objectData.indEligibilityDetail));
                                            console.log('response.objectData.indivElig---'+JSON.stringify(response.objectData.indEligibilityHist));
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
        helper.redirectToLightningComponent('c:EligibilityHistoryFlow', {'recordId':component.get("v.returnId")});
    }
})