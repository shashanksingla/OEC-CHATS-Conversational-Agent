({
    doGetRelatedApplicationIndividuals : function(component) {
        var action = component.get("c.getRelatedApplicationIndividuals"); 
        action.setParams({'appCaseId':component.get("v.appCaseId")});
        action.setCallback(this,function(actionResult){
            component.set("v.lstApplicationIndividuals",actionResult.getReturnValue());
            
        });
        $A.enqueueAction(action);
    },
    doUpdateRecords : function(component, event, applicationIndividualForClearance) {
        
        var action = component.get("c.updateRecords"); 
        action.setParams({'lstSObject':[applicationIndividualForClearance]});
        action.setCallback(this,function(actionResult){
            var response = actionResult.getReturnValue();
           
            if(response.isSuccessful==true){
                component.set("v.applicationIndividualForClearance",applicationIndividualForClearance);
                
                var lstApplicationIndividuals = component.get("v.lstApplicationIndividuals");
                for(var i=0;i<lstApplicationIndividuals.length;i++){
                    if(lstApplicationIndividuals[i].Id==applicationIndividualForClearance.Id){
                        lstApplicationIndividuals[i] = applicationIndividualForClearance;
                    }
                }
                component.set("v.lstApplicationIndividuals",lstApplicationIndividuals);
                
                var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
                for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
                    if(lstSelectedApplicationIndividuals[i].Id==applicationIndividualForClearance.Id){
                        lstSelectedApplicationIndividuals[i] = applicationIndividualForClearance;
                    }
                }
                component.set("v.lstSelectedApplicationIndividuals",lstSelectedApplicationIndividuals);
                component.set("v.currentState","APP_INDIV_CLEARANCE");
                component.set("v.currentStateTitle","Application Individual Clearance");
            }else{
                
            }
        });
        $A.enqueueAction(action);        
    },    
    doHandleExistingCaseSelection : function(component) {
        var action = component.get("c.handleCaseSelection"); 
        action.setParams({'caseId':component.get("v.selectedCaseID"),
                          'appCaseId':component.get("v.appCaseId")});
        action.setCallback(this,function(actionResult){
            
            var response = actionResult.getReturnValue();
            if(response.isSuccessful==true){
				
                //navigate it to selectedCase
            }else{
                component.set("v.lstError",['Error:'+response.message]);
                component.set("v.showError",true);
            }
        });
        $A.enqueueAction(action);
    },
    doGetMatchedIndividuals : function(component) {
        var action = component.get("c.findIndividualMatches");
		window.alert(component.get("v.applicationIndividualForClearance").NAM_FIRST__c);
        action.setParams({	'fName':component.get("v.applicationIndividualForClearance").NAM_FIRST__c,
                          	'lName':component.get("v.applicationIndividualForClearance").NAM_LAST__c,
                          	'MI':component.get("v.applicationIndividualForClearance").NAM_MI__c,
            				'dob':component.get("v.applicationIndividualForClearance").DTE_DOB__c,
                          	'ssn':component.get("v.applicationIndividualForClearance").NBR_SSN__c,
                          	'gndr':component.get("v.applicationIndividualForClearance").CDE_GENDER__c });
        action.setCallback(this,function(actionResult){
            
            var response = actionResult.getReturnValue();
            if(response.isSuccessful==true){
                component.set("v.lstCHATSMatchedIndividuals",response.objectData.lstMatchedCHATSIndividuals);
                component.set("v.lstSIDMODMatchedIndividuals",response.objectData.lstSIDMODMatchedIndividuals);
                component.set("v.currentState","CLEAR_INDIVIDUAL");
                component.set("v.currentStateTitle","Clear Individual");
            }else{
                component.set("v.lstError",['Error:'+response.message]);
                component.set("v.showError",true);
            }
        });
        $A.enqueueAction(action);
    },
    doFindCaseAndPrimaryCaretakerDetails : function(component) {
        var action = component.get("c.findCaseAndPrimaryCaretakerDetails"); 
        var stateIdOfPrimaryCaretaker; 
        var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
        for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
            if(lstSelectedApplicationIndividuals[i].IND_CRTKR_PRIM__c=='Y'){
                stateIdOfPrimaryCaretaker = lstSelectedApplicationIndividuals[i].IDN_STATE__c;
                break;
            }
        }
        action.setParams({'stateId':stateIdOfPrimaryCaretaker});
        action.setCallback(this,function(actionResult){
           
            var response = actionResult.getReturnValue();
            if(response.isSuccessful==true){
                component.set("v.lstCaseIndividual",response.objectData.lstCaseIndividual);
                component.set("v.mapCaseIdCaseStatus",response.objectData.mapCaseIdCaseStatus);
                component.set("v.currentState","CASE_SELECTION");
                component.set("v.currentStateTitle","Case Selection");
            }else{
                component.set("v.lstError",['Error:'+response.message]);
                component.set("v.showError",true);
            }
        });
        $A.enqueueAction(action);
    }
})