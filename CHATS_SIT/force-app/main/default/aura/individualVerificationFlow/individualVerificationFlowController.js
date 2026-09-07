({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                           
                                            var individual = response.objectData.individual;
                                            if(individual.Individual_Information__r!=undefined){
                                                component.set("v.indivInfos",individual.Individual_Information__r);
                                                delete individual.Individual_Information__r;              
                                            }
                                            component.set("v.caseIndiv",individual.Case_Individual__r);// CCCAP-13633
                                            component.set("v.individual",individual);
                                            component.set("v.indVerif",helper.merge(component.get('v.indVerif'),response.objectData.indVerif));
                                            helper.callServerAndHandleError(component,"c.isReadOnlyProfile", 
                                                    function(response){
                                                        
                                                        component.set("v.isReadOnly",response.objectData.isReadOnly);
                                                        
                                                    })
                                        }, {'indivId':component.get("v.recordId")}, false, null);
    },
    doFinish : function(component, event, helper) {
    	var individual = component.get("v.individual");
        var readOnly = component.get("v.isReadOnly");
        if(readOnly == true){
            helper.goToRecord(individual.Id, "detail");
        }else{
        var childCmp = component.find("individualVerificationLayout");
        childCmp.callValidateCurrentPage();
        // server side call
        if(component.get("v.isCurrentPageValid")==true){
            var indVerif = component.get("v.indVerif");
            var individual = component.get("v.individual");
            var indivInfos = component.get("v.indivInfos");
            if(indVerif.Id==undefined && indVerif.Id==null){
                if(indivInfos!=null && indivInfos.length>0){
                    indVerif.IDN_CLIENT__c = indivInfos[0].Id;
                    helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                    function(response){
                                                        helper.goToRecord(individual.Id, "detail");
                                                    }, {'lstSObject':[individual,indVerif], 'isFinalStep':true}, false, null);
                }else{
                    helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                    function(response){
                                                       
                                                        helper.goToRecord(individual.Id, "detail");
                                                    }, {'lstSObject':[individual],'isFinalStep':true}, false, null);
                }     
            }else{
                helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                function(response){
                                                   
                                                    helper.goToRecord(individual.Id, "detail");
                                                }, {'lstSObject':[indVerif,individual], 'isFinalStep':true}, false, null);
                
            }    
        }
    }
    }
})