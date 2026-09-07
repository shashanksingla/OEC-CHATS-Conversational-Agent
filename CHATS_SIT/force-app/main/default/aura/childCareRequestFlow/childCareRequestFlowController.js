({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                           
                                            var caseIndividualsWithCCR = [];
                                            for(var i=0;i<response.objectData.caseIndividuals.length;i++){
                                                var ccRequest = false;
                                                var reasonEndingCare = null;
                                                //Start of change - CCCAP-65
                                                if(response.objectData.caseIndividuals[i].Child_Care_Requests__r!=undefined){
                                                	for(var j=0; j<response.objectData.caseIndividuals[i].Child_Care_Requests__r.length;j++){
                                                    	if(response.objectData.caseIndividuals[i].Child_Care_Requests__r[j].DTE_END_EFFV__c==null || 
                                                          response.objectData.caseIndividuals[i].Child_Care_Requests__r[j].DTE_END_EFFV__c== undefined ||
                                                          response.objectData.caseIndividuals[i].Child_Care_Requests__r[j].DTE_END_EFFV__c>helper.getCurrentSystemDate()
                                                          ){
                                                            ccRequest = true;
                                                        }
                                                	}
                                                }
                                                //End of change - CCCAP-65
                                                caseIndividualsWithCCR.push({
                                                    'caseIndividual':response.objectData.caseIndividuals[i],
                                                    'ccRequest':ccRequest,
                                                    'initialValueCCRequest':ccRequest,
                                                    'ccReqRecord':(response.objectData.caseIndividuals[i].Child_Care_Requests__r || [{}])[0]
                                                    /*,'reasonEndingCare': reasonEndingCare,
                                                    'initialReasonEndingCare': reasonEndingCare*/
                                                });
                                            }
                                            
                                            component.set("v.caseIndividualsWithCCR",caseIndividualsWithCCR);
                                            component.set("v.isReadOnly", response.objectData.isReadOnly);
                                            component.set("v.currentTabNumber", 1);
                                        }, {'caseId':component.get("v.recordId")}, false, null);
    },
    doFinish : function(component, event, helper) {
        var caseIndividualsWithCCR1 = component.get("v.caseIndividualsWithCCR");
        if(caseIndividualsWithCCR1.length > 0){
            var childCmp = component.find("childCareRequestLayout");
            var resultFromChild = childCmp.callValidateCurrentPage();
            // server side call
            
            if(resultFromChild==true){
                var caseIndividualsWithCCR = component.get("v.caseIndividualsWithCCR");
                var caseIndividualIdToCCR = {};
                
                var hasAnyUpdatedCCR = false;
                for(var i=0;i<caseIndividualsWithCCR.length;i++){
                    if(caseIndividualsWithCCR[i].ccRequest!=caseIndividualsWithCCR[i].initialValueCCRequest || 
                      caseIndividualsWithCCR[i].isOverriden == true){
                        hasAnyUpdatedCCR = true;
                        let beginDate;
                        if(caseIndividualsWithCCR[i].ccReqRecord && caseIndividualsWithCCR[i].ccReqRecord.applicableBeginDate){
                            beginDate = new Date(caseIndividualsWithCCR[i].ccReqRecord.applicableBeginDate);
                        }
                        caseIndividualIdToCCR[caseIndividualsWithCCR[i].caseIndividual.Id] = {//"reasonEndingCare":caseIndividualsWithCCR[i].reasonEndingCare,
                            "ccRequest":caseIndividualsWithCCR[i].ccRequest,
                            "beginDate":beginDate,
                            "beginDateOverriden":caseIndividualsWithCCR[i].isOverriden == true,
                            "ccChecboxChanged":caseIndividualsWithCCR[i].ccRequest!=caseIndividualsWithCCR[i].initialValueCCRequest,
                            "cde_reason_ovrd__c":(caseIndividualsWithCCR[i].ccReqRecord || {}).cde_reason_ovrd__c,
                            "txt_cmt_ovrd__c":(caseIndividualsWithCCR[i].ccReqRecord || {}).txt_cmt_ovrd__c
                        };
                    }
                }
                if(hasAnyUpdatedCCR){
                    helper.callServerAndHandleError(component,"c.submitData", 
                                                    function(response){
                                                        var childCareRequestsToBeUpserted = response.objectData.childCareRequestsToBeUpserted;
                                                        //added by vinathi
                                                        helper.callServerAndHandleError(component,"c.afterSubmitData", 
                                                                                        function(response){
                                                                                            
                                                                                            helper.fireToast("dismissible","success","","Data has changed. Please reassess and confirm eligibility");
                                                                                            helper.redirectToRecord(component.get("v.recordId"));
                                                                                        }, {'childCareRequestsToBeUpserted':childCareRequestsToBeUpserted}, false, null);
                                                        //ends
                                                        
                                                    }, {'caseIndividualIdToCCRJSON':JSON.stringify(caseIndividualIdToCCR)}, false, null);
                }else{
                    helper.redirectToRecord(component.get("v.recordId"));
                }
            }
            
        } else{
            helper.redirectToRecord(component.get("v.recordId"));
        }
    },
    doCancel : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    }
})