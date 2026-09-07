({
    /*goToRecord: function(authId, slideDevName){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": authId,
            "slideDevName": slideDevName
        });
        navEvt.fire();
    }*/
    getIsIntake: function(component){
        var caseId = component.get('v.recordId');
        this.callServerAndHandleError(component,"c.checkIfIntakeCase", 
                                      function(resp){
                                          debugger;
                                          if(resp){
                                              var isIntake = resp.objectData.isIntake;
                                              component.set("v.isIntake", isIntake);
                                              component.set('v.currentTabNumber',1);
                                          }
                                      },
                                      {'caseId': caseId}
                                      , false, null);     
        
    },
    getIndividualAge : function(component){
        var indivRecord = component.get("v.indivRec");
        var birthDate = new Date(indivRecord.DTE_DOB__c);        
        var today = new Date();
        var age = today.getFullYear() - birthDate.getFullYear();
        var m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }
        
        return age;
        
    },
    finishHlp : function(component, event, helper) {  
        var caseRec = component.get("v.caseRec");
        var indivRecToBeUpserted = component.get("v.indivRec");
        var indivInfoRecToBeUpserted = component.get("v.indivInfoRec");
        var indivMilRecToBeUpserted = component.get("v.indivMilRec");
        var indivEmailRecToBeUpserted=component.get("v.indivEmailRec");
        //var caseInfoEmailRecToBeUpserted=component.get("v.caseInfoEmailRec");
        var caseIndiv = component.get("v.caseIndiv");
        var today = new Date();
       // indivInfoRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
        indivInfoRecToBeUpserted.IDN_CASE__c = caseRec.Id;
        indivInfoRecToBeUpserted.IDN_CLIENT__c = indivRecToBeUpserted.Id;
        indivInfoRecToBeUpserted.CDE_TYPE_INFO_INDIV__c = 'CS';
        indivMilRecToBeUpserted.IDN_CLIENT__c = indivRecToBeUpserted.Id;
        caseIndiv.IDN_CLIENT__c = indivRecToBeUpserted.Id;
        caseIndiv.IDN_CASE__c = component.get("v.recordId");
        if(caseIndiv.Individual_Status__c=='PC'){
            caseIndiv.IND_CRTKR__c = true;
        }
        if(!$A.util.isEmpty(indivEmailRecToBeUpserted) && !$A.util.isEmpty(indivEmailRecToBeUpserted.Email_Information__c)){
            indivEmailRecToBeUpserted.Individual__c=indivRecToBeUpserted.Id;
            /*indivEmailRecToBeUpserted.Effective_Begin_Date__c=today;
            caseInfoEmailRecToBeUpserted.TXT_VALUE_INFO_CASE__c =indivEmailRecToBeUpserted.Email_Information__c;
            caseInfoEmailRecToBeUpserted.IDN_CASE__c =component.get("v.recordId");
            caseInfoEmailRecToBeUpserted.CDE_TYPE_INFO_CASE__c ='EM';*/
    }
        helper.callServerAndHandleError(component,"c.upsertRecords", 
                                        function(response){
                                            debugger;
                                            var objectData = response.objectData.upsertedRecords;
                                            var mergedIndiv;
                                            for(var i=0;i<objectData.length;i++){
                                                if(objectData[i].hasOwnProperty("Individual_Status__c")){// replaced with Individual_Status__c as part of CCCAP-13633
                                                    caseIndiv.Id = objectData[i].Id;
                                                }
                                                if(objectData[i].hasOwnProperty("NAM_FIRST__c")){
                                                    mergedIndiv = helper.merge(indivRecToBeUpserted, objectData[i]);
                                                }
                                                if(objectData[i].hasOwnProperty("CDE_STATUS_MIL__c")) {
                                                    indivMilRecToBeUpserted.Id= objectData[i].Id;
                                                }
                                              /*  if(objectData[i].hasOwnProperty("Email_Information__c")) {
                                                    indivEmailRecToBeUpserted.Id= objectData[i].Id;
                                                }*/
                                            }
                                            // email info call
                                            debugger;
                                             helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response1){
                                                 debugger;
                                                if(response1){
                                                     debugger;
                                                    indivEmailRecToBeUpserted.Id = response1.objectData.upsertedRecords[0].Id;
                                                    component.set("v.indivEmailRec",indivEmailRecToBeUpserted);
                                                }
                                            },
                                            {"lstSObject": [indivEmailRecToBeUpserted],"isFinalStep":true}, false, null);
                                            // end
                                            component.set("v.indivRec", mergedIndiv);
                                            component.set("v.caseIndiv",caseIndiv);	                                                    
                                            component.set("v.indivMilRec",indivMilRecToBeUpserted);
                                           // component.set("v.indivEmailRec",indivEmailRecToBeUpserted);
                                            helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                                                indivInfoRecToBeUpserted.Id = response.objectData.upsertedRecords[0].Id;
                                                component.set("v.indivInfoRec",indivInfoRecToBeUpserted);
                                                var indivVerifRecToBeUpserted = component.get("v.indivVerifRec");
                                                indivVerifRecToBeUpserted.IDN_CLIENT__c =  response.objectData.upsertedRecords[0].Id;
                                                indivVerifRecToBeUpserted.CDE_TYPE_INFO_INDIV__c = 'CS';
                                                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                                                function(response){
                                                                                    indivVerifRecToBeUpserted.Id = response.objectData.upsertedRecords[0].Id;
                                                                                    component.set("v.indivVerifRec",indivVerifRecToBeUpserted);
                                                                                    helper.redirectToLightningComponent("c:individualClearanceFlow",{"recordId":component.get("v.indivRec").Id,
                                                                                                                                                     "caseId":component.get("v.recordId")
                                                                                                                                                    });
                                                                                },{'lstSObject':[indivVerifRecToBeUpserted]}, false, null);	                                                        
                                            },{'lstSObject':[indivInfoRecToBeUpserted]}, false, null);	
                                        }, {'lstSObject':[caseIndiv, indivRecToBeUpserted,indivMilRecToBeUpserted]}, 
                                        false, null);
        /*if(caseIndiv.IND_CRTKR__c==true){
            debugger;
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                 debugger;
                                                if(response){
                                                    caseInfoEmailRecToBeUpserted.Id = response.objectData.upsertedRecords[0].Id;
                                                    component.set("v.caseInfoEmailRec",caseInfoEmailRecToBeUpserted);
                                                }
                                            },
                                            {"lstSObject": [caseInfoEmailRecToBeUpserted],"isFinalStep":true}, false, null);
            
        }*/
    }
})