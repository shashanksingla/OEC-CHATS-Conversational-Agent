({
    doGetMatchedIndividuals: function(component) {
        debugger;
        this.callServerAndHandleError(component, "c.findIndividualMatches",
            function(response) {
                console.log(response);
                component.set("v.lstCHATSMatchedIndividuals", response.objectData.lstMatchedCHATSIndividuals);
                component.set("v.lstSIDMODMatchedIndividuals", response.objectData.lstSIDMODMatchedIndividuals);
            
            //Start - warning popup on multiple Sidmod matches with above 96% - CCCAP-6418
            var lstSIDMODMatchedIndividuals = component.get("v.lstSIDMODMatchedIndividuals");
            var countOfSIDMODMatchesAbove96Percent = component.get("v.countOfSIDMODMatchesAbove96Percent");
            if(lstSIDMODMatchedIndividuals != undefined){
                for(var i= 0 ; i<lstSIDMODMatchedIndividuals.length; i++){
                    if(lstSIDMODMatchedIndividuals[i].score >= 96){
                        countOfSIDMODMatchesAbove96Percent = countOfSIDMODMatchesAbove96Percent + 1;
                    }
                }
            }
            if(countOfSIDMODMatchesAbove96Percent > 1){
                var warningModalCall = component.find('warningOnMultipleStateIDsAbove96');
                warningModalCall.openModal();
            }
            //End - warning popup on multiple Sidmod matches with above 96% - CCCAP-6418
            
            
                if(!$A.util.isEmpty(response.objectData.sidmodMessage)){
                    component.set("v.pageMessages",[response.objectData.sidmodMessage]);			                    
                    component.set("v.messageType","error");	
                    component.set("v.disableCreateNewStateIdButton",true);
                }
                component.set("v.showIndividualClearance", true);
            }, {
                'dob': component.get("v.individual").DTE_DOB__c,
                'ssn': component.get("v.individual").NBR_SSN__c,
                'fName': component.get("v.individual").NAM_FIRST__c,
                'lName': component.get("v.individual").NAM_LAST__c,
                'MI': component.get("v.individual").NAM_MI__c,
                'gndr': component.get("v.individual").CDE_GENDER__c
            }, false, null);

            // Getting individual information user entered
            this.callServerAndHandleError(component, "c.getIndivInfo",
            function(response) {
                console.log(response);
                debugger;
                if(!$A.util.isEmpty(response.objectData.indivInfoRecOld)){
                    debugger;
                    component.set("v.indivInfoRecOld",response.objectData.indivInfoRecOld);	
                    console.log('response.objectData.indivInfoRecOld----'+response.objectData.indivInfoRecOld);
                    console.log('Indiv id----'+component.get("v.individual").Id);
                    console.log('indivInfoRecOld--'+JSON.stringify(response.objectData.indivInfoRecOld));
                }
            }, {
                'indivId': component.get("v.individual").Id
                
            }, false, null);
    },
    doUpdateRecords: function(component, event, individual, overrideClearance) {
        console.log("individual:" + JSON.stringify(individual));
        var indivInfoRecToBeUpserted = component.get("v.indivInfoRec");
        indivInfoRecToBeUpserted.IDN_CASE__c = component.get("v.caseId");
        var indivInfoRecOld = component.get("v.indivInfoRecOld");
        indivInfoRecToBeUpserted.CDE_TYPE_INFO_INDIV__c = 'CS';
       // indivInfoRecToBeUpserted.CDE_VALUE_INFO_INDIV__c = 'CZN';
        indivInfoRecToBeUpserted.CDE_VALUE_INFO_INDIV__c = indivInfoRecOld.CDE_VALUE_INFO_INDIV__c;
        this.callServerAndHandleError(component, "c.updateRecords",
            function(response) {
                var idToBeRedirected = component.get("v.recordId");
                if (!$A.util.isEmpty(response.objectData.idToBeRedirected)) {
                    idToBeRedirected = response.objectData.idToBeRedirected;
                }
                this.callServerAndHandleError(component, "c.insertATSRecordForCaseIndividual",
                    function(response) {
                        if (overrideClearance == true) {
                            this.fireToast("duration", "success", "Success!", " Override was Successful ");
                        } else {
                            this.fireToast("duration", "success", "Success!", "Individual has been cleared.");
                        }
						indivInfoRecToBeUpserted.IDN_CLIENT__c = idToBeRedirected;
                        console.log('IndivRecordId---'+idToBeRedirected);
                        // Inserting the citizenship record
                         this.callServerAndHandleError(component,"c.upsertRecords", 
                                            function(response1){
                                                 if(response1){
                                                }
                                            },
                                            {"lstSObject": [indivInfoRecToBeUpserted]}, false, null);
                        // end
                        // added for CCCAP-10315 for SIDMOD Notify Feature
                        if(component.get('v.sidmodSelection')){
                            this.notifySIDMOD(component,individual.IDN_STATE__c,idToBeRedirected,false,true);
                        }else{
	                        this.redirectToRecord(idToBeRedirected);                            
                        }

                    }, {
                        caseId: component.get("v.caseId"),
                        indivId: individual.Id
                    }, false, null);
            }, {
                'lstSObject': [individual]
            }, false, null);
    },

    assignStateId: function(component, event, individual) {

        this.callServerAndHandleError(component, "c.assignStateId",
            function(resp) {
                //var state = resp.getState();
                var responseStateId = resp.objectData.respSidmodlst;
                if (responseStateId != null) {
                    //this.fireToast("duration", "success", "Success!", "New State Id has been assigned");
                    var individual = component.get("v.individual");
                    individual.IDN_STATE__c = responseStateId[0].stateId;
                    individual.DTE_Death__c = responseStateId[0].dateOfDeath; // added for sidmod CCCAP-7695
                    if (responseStateId.length > 0) {
                        this.callServerAndHandleError(component, "c.updateRecords",
                            function(response) {
                                var idToBeRedirected = component.get("v.recordId");
                                if (!$A.util.isEmpty(response.objectData.idToBeRedirected)) {
                                    idToBeRedirected = response.objectData.idToBeRedirected;
                                }
                                this.callServerAndHandleError(component, "c.insertATSRecordForCaseIndividual",
                                    function(response) {
                                        this.fireToast("duration", "success", "Success!", "New State Id has been assigned & Individual has been cleared.");
										// added for CCCAP-10315 for SIDMOD Notify Feature
                                        this.notifySIDMOD(component,individual.IDN_STATE__c,idToBeRedirected,false,true);
                                    }, {
                                        caseId: component.get("v.caseId"),
                                        indivId: individual.Id
                                    }, false, null);

                            }, {
                                'lstSObject': [individual]
                            }, false, null);
                    }
                } else {
                    this.fireToast("duration", "error", "Error!", "Exception: No State Id Assigned");
                }
            }, {
                'fName': component.get("v.individual").NAM_FIRST__c,
                'lName': component.get("v.individual").NAM_LAST__c,
                'MI': component.get("v.individual").NAM_MI__c,
                'dob': component.get("v.individual").DTE_DOB__c,
                'ssn': component.get("v.individual").NBR_SSN__c,
                'gndr': component.get("v.individual").CDE_GENDER__c
            }, false, null);

    },
    
    doOverrideClearance: function(component, event, individual) {

        this.callServerAndHandleError(component, "c.overrideClientClearance",
            function(r) {
                var returnCode = r.objectData.returnCode;
                var errorMsg = r.objectData.errorMsg;
                var retrunMessage = r.objectData.retrunMessage;
                if (returnCode == '202') {
                    //this.fireToast("duration", "success", "Success!", retrunMessage);
                    this.doUpdateRecords(component, event, individual, true)
                } else if ((retrunMessage != null) && (returnCode != '202')){
                    this.fireToast("duration", "error", "Error!", retrunMessage);
                } else if ((errorMsg != null) && (returnCode != '202')){
                    this.fireToast("duration", "error", "Error!", errorMsg);
                }else {
                    this.fireToast("duration", "error", "Error!", errorMsg);
                }
            }, {
                'fName': component.get("v.individual").NAM_FIRST__c,
                'lName': component.get("v.individual").NAM_LAST__c,
                'MI': component.get("v.individual").NAM_MI__c,
                'dob': component.get("v.individual").DTE_DOB__c,
                'ssn': component.get("v.individual").NBR_SSN__c,
                'gndr': (component.get("v.individual").CDE_GENDER__c=='M') ? '1' : (component.get("v.individual").CDE_GENDER__c=='F') ? '2' : (component.get("v.individual").CDE_GENDER__c=='U') ? '3' : '4'
            }, false, null);

    },
    checkIPVDisqualification: function(component, event, individualId) {
        this.callServerAndHandleError(component, "c.getIPVDisqualification",
                                      function(response) {
                                          var isSuccessful = response.isSuccessful;
                                          var ipvDisqualification = response.objectData.ipvDisqualification;
                                          if(ipvDisqualification ){
                                              component.set("v.ipvDisqualificationMsg", response.objectData.warningMsg);
                                              component.find("activeIPVDisqualification").openModal();
                                          }else{
                                              component.find("existingIndividualSelected").openModal();
                                          }
                                          
                                      }, {'individualId': individualId}, false, null);
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
                                              this.redirectToRecord(idToBeRedirected);
                                          }
                                      },{"stateId":stateId ,"indivId":idToBeRedirected,"isAppIndividual":isAppIndividual}, false, null);
    }

})