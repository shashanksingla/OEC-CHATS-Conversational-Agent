({
    setNameIndivsToIncomes : function(component, arrayOfattr, variableToUpdate, caseIndivMap) {
        
        for(var i=0;i<arrayOfattr.length;i++) {
            if(component.get(arrayOfattr[i])) {
                var listOfRec = component.get(arrayOfattr[i]);
                for(var j=0;j<listOfRec.length; j++) {
                   
                   
                    
                    if(listOfRec[j]['idn_indiv_fcompsn__r']) {
                        var caseIndiv = listOfRec[j]['idn_indiv_fcompsn__r']['idn_case_indiv__c'];
                       
                        
                        if(caseIndivMap[0][caseIndiv]) {
                            listOfRec[j]['NAM_INDIV__c']=caseIndivMap[0][caseIndiv].NAM_INDIV__c;
                        }   
                    }
                }
               
              
                component.set(arrayOfattr[i],listOfRec);
            }
        }
    },
    doConfirmEligibility : function(component, helper){
        var caseEligibilityRun = component.get("v.caseEligibilityRun");
        var caseRec = component.get("v.caseRec");
        helper.doContinuousCallOuts(component,"BREConfirmEligibility",
                                    [caseRec.Name, caseEligibilityRun.idn_run_eligty__c], function(response){
                                        $A.get('e.force:refreshView').fire();

                                        helper.callServerAndHandleError(component, "c.saveCaseProgramType",
                                        function(resp){
                                            if(resp.isSuccessful==true)
                                                console.log('Assigned program type');
                                        }, {'caseId':caseRec.Id,
                                            'programType'	: component.get("v.caseEligibility") .cde_prog__c},
                                                false, null);

                                        helper.callServerAndHandleError(component,"c.updateAuthAndEnrollment", 
                                        function(response){                                            
                                            if(response.isSuccessful==true){
                                                console.log('Enrollment created successfully');
                                            }
                                        }, {'caseId':caseRec.Id,
                                            'programType'	: component.get("v.caseEligibility") .cde_prog__c }, 
                                            	false, null);

                                        //CCCAP-13251
                                        helper.callServerAndHandleError(component, "c.updateCaseApplnDateInfo",
                                        function(resp){
                                            if(resp.isSuccessful==true)
                                                console.log('Updated application date information');
                                        }, {'caseId':caseRec.Id}, false, null);
                                    });
        
    }
})