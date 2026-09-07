({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                           
                                            component.set("v.caseRec",response.objectData.caseRec);
                                            component.set("v.caseEligibility",response.objectData.caseEligibility);
                                            component.set("v.caseEligibilityRun",response.objectData.eligRun);
                                            component.set("v.caseEligibilityDetails",response.objectData.caseEligibilityDetails);
                                            if(!$A.util.isEmpty(response.objectData.lastCaseEligibilityDetails)){
                                               component.set("v.lastCaseEligibilityDetails",response.objectData.lastCaseEligibilityDetails); 
                                            }
                                            if(!$A.util.isEmpty(response.objectData.lastCaseEligibility)){
                                               component.set("v.lastCaseEligibility",response.objectData.lastCaseEligibility); 
                                            }
                                            if(!$A.util.isEmpty(response.objectData.secondLastCaseEligibility)){
                                               component.set("v.secondLastCaseEligibility",response.objectData.secondLastCaseEligibility); 
                                            }
                                            if(!$A.util.isEmpty(response.objectData.secondLastCaseEligibilityDetails)){
                                               component.set("v.secondLastCaseEligibilityDetails",response.objectData.secondLastCaseEligibilityDetails); 
                                            }
                                            component.set("v.householdIneligibilityFailure",response.objectData.caseEligibilityFailure);
                                            component.set("v.indivToIsParentCaretaker",response.objectData.indivToIsParentCaretaker);
                                            component.set("v.indivToStatus",response.objectData.indivToStatus);
                                            component.set("v.indivEligIdToWrapper",response.objectData.indivEligIdToWrapper);
                                            component.set("v.eligRunExtId",response.objectData.eligRun.idn_run_eligty__c);
                                            if(!$A.util.isEmpty(response.objectData.readOnlyMode)){
                                                component.set("v.readOnlyMode",response.objectData.readOnlyMode);
                                            }
                                            if(response.objectData.eligRun.cde_eligty_cfmd__c=='CFM') {
                                                component.set("v.readOnlyMode",true);
                                            }
                                            if(component.get("v.childCareProgram")=='FT' || component.get("v.childCareProgram")=='LI' ||  component.get("v.childCareProgram")=='TF' ) {
                                                component.set("v.readOnlyMode",true);
                                            }
                                            component.set("v.caseStatus",response.objectData.caseStatus);
                                            component.set("v.individual",response.objectData.individual);
                                            component.set("v.casePayment",response.objectData.casePayment);
                                            component.set("v.countyPlan",response.objectData.countyPlan);
                                            component.set("v.indivEmplmtIncomeTypeEmployment",response.objectData.indivEmplmtIncomeTypeEmployment);
                                            component.set("v.indivEmplmtIncomeTypeSelfEmployment",response.objectData.indivEmplmtIncomeTypeSelfEmployment);
                                            component.set("v.indivEmplmtExpense",response.objectData.indivEmplmtExpense);
                                            component.set("v.indivEligtyOtherIncome",response.objectData.indivEligtyOtherIncome);
                                            component.set("v.indivEligtyIncomeDeduction",response.objectData.indivEligtyIncomeDeduction);
                                            component.set("v.primCareTakerIndivElig",response.objectData.primCareTakerIndivElig);
                                            component.set("v.caseIndivs",response.objectData.caseIndivs);
											component.set("v.ineligReasons",response.objectData.ineligReasons);	
                                            if(component.get("v.caseIndivs")) {
                                               
                                                
                                                var arrayOfattr=['v.indivEmplmtIncomeTypeEmployment', 'v.indivEmplmtIncomeTypeSelfEmployment', 'v.indivEmplmtExpense', 'v.indivEligtyOtherIncome', 'v.indivEligtyIncomeDeduction'];
                                                helper.setNameIndivsToIncomes(component, arrayOfattr, 'idn_indiv_fcompsn__r.idn_case_indiv__r',component.get("v.caseIndivs"));
                                            }
                                            component.set("v.caseEligibilityDetails",response.objectData.caseEligibilityDetails);
                                           
                                            component.set("v.initLoaded",true);
                                        }, {'elgibilityRunId':component.get("v.recordId")}, false, null);
    },
    onClickCustomButton : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    doValidateConfirmEligibility : function(component, event, helper) {
                helper.callServerAndHandleError(component,"c.validateConfirmEligibility", 
                                        function(response){
                                            
                                            if(response.isSuccessful==true){
                                                if(!$A.util.isEmpty(response.objectData.pageMessages) && response.objectData.pageMessages.length>0){
                                                    component.set("v.pageMessages",response.objectData.pageMessages);
                                                    component.set("v.messageType","error");
                                                }else{
                                                	// do webservice callout here   
                                                	helper.doConfirmEligibility(component, helper); 
                                                }
                                            }
                                        }, {'elgibilityRunId':component.get("v.recordId"),
                                            'caseEligProg'	: component.get("v.caseEligibility") .cde_prog__c }, 
                                            	false, null);

    },
    doFinish : function(component, event, helper) {
        
        var eligibilityRun = component.get("v.caseEligibilityRun");
        if(eligibilityRun.cde_eligty_cfmd__c != 'CFM') {
            var caseRec = component.get("v.caseRec");
            var caseEligibilityDetails = component.get("v.caseEligibilityDetails");
            var individuals = component.get("v.individual");
            var primCareTakerIndivElig = component.get("v.primCareTakerIndivElig");
            var caseStatus = component.get("v.caseStatus");
            var caseEligibility = component.get("v.caseEligibility");
            eligibilityRun.cde_eligty_cfmd__c = 'CFM';
            var pageMessage='';
            
            
            helper.callServerAndHandleError(component,"c.validateEligibilityData", function(response){
               
                if(response.objectData.pageMessage!=null) {
                    component.set("v.pageMessages",response.objectData.pageMessage);
                    component.set("v.messageType",'error');    
                } else {
                    helper.callServerAndHandleError(component,"c.updateExternalObjRecords", function(response){
                        helper.callServerAndHandleError(component,"c.updateExternalRecordsOnEligibilityConfirmationDetails", function(response){
                           
                            //updateRecordsOnEligibilityConfirmationDetails
                            
                            
                            helper.redirectToRecord(component.get("v.recordId"));
                        },{'caseRecord':caseRec,
                           'eligibilityRun':eligibilityRun,
                           'caseStatus':caseStatus,
                           'caseEligibility':caseEligibility
                          },false,null);
                    },{'lstSObject':[eligibilityRun]},false,null);
                }  
            },{'caseRec':caseRec,
               'eligibilityRun':eligibilityRun,
               'caseEligibilityDetails':caseEligibilityDetails,
               'primaryCaretakerIndiv':primCareTakerIndivElig,
               'caseStatus':caseStatus,
               'caseEligibility':caseEligibility},false,null);
            
            /*if(caseEligibilityDetails.CDE_STATUS_ELIGTY_FAMILY__c == 'ELI') { messageType
            pageMessage+='Case can be Eligible only when all Parent Caretakers are Eligible';
        }*/
        } 
    }
})