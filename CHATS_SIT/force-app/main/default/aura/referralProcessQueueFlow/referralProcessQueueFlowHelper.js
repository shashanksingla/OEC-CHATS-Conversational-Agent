({
    doUpdateRecords : function(component, event, applicationIndividualForClearance) {
        this.callServerAndHandleError(component,"c.updateRecords", 
                                      function(response){
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
                                          component.set("v.currentTabNumber",3);
										  component.set("v.applicationIndividualForClearance",null);                                          
                                      }, {'lstSObject':[applicationIndividualForClearance]}, false, null);
    },
    doGetMatchedIndividuals : function(component) {
        this.callServerAndHandleError(component,"c.findIndividualMatches", 
                                      function(response){
                                          component.set("v.lstCHATSMatchedIndividuals",response.objectData.lstMatchedCHATSIndividuals);
                                          component.set("v.lstSIDMODMatchedIndividuals",response.objectData.lstSIDMODMatchedIndividuals);
                                          component.set("v.currentTabNumber",4);
                                          component.set("v.showPrevious",false);
                                          component.set("v.showNext",false);
                                          component.set("v.customButtonLabel","Clear Individual");
                                      }, {'dob':component.get("v.applicationIndividualForClearance").DTE_DOB__c,
                                          'ssn':component.get("v.applicationIndividualForClearance").NBR_SSN__c,
                                          'fName':component.get("v.applicationIndividualForClearance").NAM_FIRST__c,
                                          'lName':component.get("v.applicationIndividualForClearance").NAM_LAST__c,
                                          'MI':component.get("v.applicationIndividualForClearance").NAM_MI__c,
                                          'gndr':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='M'?'1':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='F'?'2':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='U'?'3':'4'
                                         }, false, null);
    },
    doFindCaseAndPrimaryCaretakerDetails : function(component) {
        var stateIdOfPrimaryCaretaker=[]; 
        var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
        var lstApplicationIndividualsOld = component.get("v.lstApplicationIndividualsOld");
        for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
          stateIdOfPrimaryCaretaker.push(lstSelectedApplicationIndividuals[i].IDN_STATE__c);
            
        }
        if(!$A.util.isEmpty(lstApplicationIndividualsOld)){
            for(var i=0;i<lstApplicationIndividualsOld.length;i++){
                stateIdOfPrimaryCaretaker.push(lstApplicationIndividualsOld[i].IDN_STATE__c);
            }  
        }
        this.callServerAndHandleError(component,"c.findCaseAndPrimaryCaretakerDetails", 
                                      function(response){
                                          component.set("v.lstCaseIndividual",response.objectData.lstCaseIndividual);
                                          component.set("v.mapCaseIdCaseStatus",response.objectData.mapCaseIdCaseStatus);
                                          component.set("v.currentTabNumber",5);
                                      }, {'stateId':stateIdOfPrimaryCaretaker}, false, null);
    },
    doHandleExistingCaseSelection : function(component) {
        
        component.set("v.appProcessQueueRec.IDN_CASE__c",component.get("v.selectedCaseID"));
        var individualIds = new Map();
        var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
        for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
            individualIds.set(lstSelectedApplicationIndividuals[i].Id,lstSelectedApplicationIndividuals[i].IDN_STATE__c);
        }
        this.callServerAndHandleError(component,"c.handleCaseSelection", 
                                      function(response){
                                          this.callServerAndHandleError(component,"c.updateApplProcessQueue",function(response3){
                                              this.callServerAndHandleError(component,"c.setPeakDataFlagToFalse",function(response2){
                                                if(!component.get("v.appProcessQueueRec").IDN_CASE__c){
                                                    for(const key of individualIds.keys()){
                                                        this.notifySIDMOD(component,individualIds.get(key),key,true,false);
                                                    }                                          
                                                 }
                                                  if(!component.get("v.hasPrimaryCaretaker")){
                                                      component.set("v.caseIdToRedirect",response.objectData.caseId);
                                                      // Needs to update code here
                                                      $A.util.toggleClass(component.find("backdropNewCase"),"slds-backdrop");
                                                      $A.util.toggleClass(component.find("backdropNewCase"),"slds-backdrop_open");
                                                      $A.util.toggleClass(component.find("NewCaseSection"),"slds-fade-in-open");
                                                      // for warning message
                                                  }
                                                  else{
                                                      this.redirectToRecord(response.objectData.caseId);
                                                  }
                                              },{'caseId':response.objectData.caseId}, false, null);
                                          },{'appProcessQueueRec':component.get("v.appProcessQueueRec"),'caseId':response.objectData.caseId}, false, null);
                                      }, {'appProcessQueue':component.get("v.appProcessQueueRec"),
                                          'individualIds':[...individualIds.keys()]}, false, null);
    },
    doHandleChangeRef :function(component) {
        var lstApplicationIndividualsOld = component.get("v.lstApplicationIndividualsOld");
        var primaryCaretakerId; 
        component.set("v.appProcessQueueRec.IDN_CASE__c",component.get("v.selectedCaseID"));
        var individualIds = new Map();
        var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
        var lstCaseIndividual=component.get("v.lstCaseIndividual");
        for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
            individualIds.set(lstSelectedApplicationIndividuals[i].Id,lstSelectedApplicationIndividuals[i].IDN_STATE__c);
        }
        if(!$A.util.isEmpty(lstCaseIndividual)){
            primaryCaretakerId =lstCaseIndividual[0].IDN_CLIENT__c;
       }
        this.callServerAndHandleError(component,"c.handleRefCaseSelection", 
                                      function(response){
                                          debugger;
							            this.callServerAndHandleError(component,"c.setPeakDataFlagToFalse",function(response2){
                                            if(component.get("v.appProcessQueueRec").IDN_CASE__c){
                                                for(const key of individualIds.keys()){
                                                    this.notifySIDMOD(component,individualIds.get(key),key,true,false);
                                                }
                                            }
							                if(!component.get("v.hasPrimaryCaretaker")){
                                                  				component.set("v.caseIdToRedirect",response.objectData.caseId);
                                                 				 // Needs to update code here
                                                 				 $A.util.toggleClass(component.find("backdropNewCase"),"slds-backdrop");
                                                 				 $A.util.toggleClass(component.find("backdropNewCase"),"slds-backdrop_open");
                                                 				 $A.util.toggleClass(component.find("NewCaseSection"),"slds-fade-in-open");
                                                 				 // for warning message
                                             				 }
                                             				 else{
                                                				  this.redirectToRecord(response.objectData.caseId);
                                             				      }
							            },{'caseId':response.objectData.caseId}, false, null);
                                      }, {'appProcessQueue':component.get("v.appProcessQueueRec"),
                                          'individualIds':[...individualIds.keys()],'primaryCaretakerId':primaryCaretakerId}, false, null);
    },
    assignStateId: function(component, event, individual) {
        this.callServerAndHandleError(component, "c.assignStateId",
                                      function(resp) {
                                          //var state = resp.getState();
                                          var responseStateId = resp.objectData.respSidmodlst;
                                          if (responseStateId != null) {
                                              //this.fireToast("duration", "success", "Success!", "New State Id has been assigned");
                                              var applicationIndividualForClearance = component.get("v.applicationIndividualForClearance");
                                              applicationIndividualForClearance.IDN_STATE__c = responseStateId[0].stateId;
                                              applicationIndividualForClearance.DTE_Death__c = responseStateId[0].dateOfDeath; // added for sidmod CCCAP-7695
                                              if (responseStateId.length > 0) {
                                                  this.callServerAndHandleError(component, "c.updateRecords",
                                                                                function(response) {
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
                                                                                    // added for CCCAP-10315 for SIDMOD Notify Feature
                                                                                    this.notifySIDMOD(component,applicationIndividualForClearance.IDN_STATE__c,applicationIndividualForClearance.Id,true,true);
                                                                                    component.set("v.lstSelectedApplicationIndividuals",lstSelectedApplicationIndividuals);
                                                                                    component.set("v.currentTabNumber",3);
                                                                                    component.set("v.applicationIndividualForClearance",null);                                          
                                                                                }, {
                                                                                    'lstSObject': [applicationIndividualForClearance]
                                                                                }, false, null);
                                              }
                                          } else {
                                              this.fireToast("duration", "error", "Error!", "Exception: No State Id Assigned");
                                          }
                                      }, {
                                          'fName': component.get("v.applicationIndividualForClearance").NAM_FIRST__c,
                                          'lName': component.get("v.applicationIndividualForClearance").NAM_LAST__c,
                                          'MI': component.get("v.applicationIndividualForClearance").NAM_MI__c,
                                          'dob': component.get("v.applicationIndividualForClearance").DTE_DOB__c,
                                          'ssn': component.get("v.applicationIndividualForClearance").NBR_SSN__c,
                                          'gndr': component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='M'?'1':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='F'?'2':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='U'?'3':'4'
                                      }, false, null);
        
    },
    doOverrideClearance: function(component, event, individual) {
        this.callServerAndHandleError(component, "c.overrideClientClearance",
                                      function(r) {
                                          var returnCode = r.objectData.returnCode;
                                          var errorMsg = r.objectData.errorMsg;
                                          var retrunMessage = r.objectData.retrunMessage;
                                          if (retrunMessage != null) {
                                              this.doUpdateRecords(component, event, individual, true)
                                          } else {
                                              this.fireToast("duration", "error", "Error!", errorMsg);
                                          }
                                      }, {
                                          'fName': component.get("v.applicationIndividualForClearance").NAM_FIRST__c,
                                          'lName': component.get("v.applicationIndividualForClearance").NAM_LAST__c,
                                          'MI': component.get("v.applicationIndividualForClearance").NAM_MI__c,
                                          'dob': component.get("v.applicationIndividualForClearance").DTE_DOB__c,
                                          'ssn': component.get("v.applicationIndividualForClearance").NBR_SSN__c,
                                          'gndr': component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='M'?'1':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='F'?'2':component.get("v.applicationIndividualForClearance").CDE_GENDER__c=='U'?'3':'4'
                                      }, false, null);
        
    },
    doUpdateRecords: function(component, event, applicationIndividualForClearance, overrideClearance) {
        console.log("individual:" + JSON.stringify(applicationIndividualForClearance));
        this.callServerAndHandleError(component, "c.updateRecords",
                                      function(response) {
                                          if (overrideClearance == true) {
                                              this.fireToast("duration", "success", "Success!", " Override was Successful");
                                          } else {
                                              this.fireToast("duration", "success", "Success!", "Individual has been cleared.");
                                          }
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
                                          // added for CCCAP-10315 for SIDMOD Notify Feature
                                          if(component.get('v.sidmodSelection')){
                                              this.notifySIDMOD(component,applicationIndividualForClearance.IDN_STATE__c,applicationIndividualForClearance.Id,true,true);
                                          }
                                          component.set("v.lstSelectedApplicationIndividuals",lstSelectedApplicationIndividuals);
                                          component.set("v.currentTabNumber",3);   
										  component.set("v.applicationIndividualForClearance",null);                                          
                                      }, {
                                          'lstSObject': [applicationIndividualForClearance]
                                      }, false, null);
    },
    // added for CCCAP-10315 for SIDMOD Notify Feature
    notifySIDMOD : function(component,stateId,idToBeRedirected,isAppIndividual,showTotast){
        this.callServerAndHandleError(component,"c.notifySIDMOD", 
                                      function(response1){
                                          if(response1){
                                              if(response1.isSuccessful){
                                                if(response1.successMessage == 'notified' && showTotast){
                                                    this.fireToast("duration", "success", "Success!", "SIDMOD has been notified.");
                                                }
                                              }else{
                                                  this.fireToast("duration", "error", "Error!", "Exception:"+response1.errorMessage);  
                                              }
                                          }
                                      },{"stateId":stateId ,"indivId":idToBeRedirected,"isAppIndividual":isAppIndividual}, false, null);
    }
})