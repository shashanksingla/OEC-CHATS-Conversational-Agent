({
    checkValidations : function(component, event, helper) {
        var simpleNewAuthNotes = component.get("v.simpleNewAuthNotes");
        var isNew = component.get("v.isNew");
        var isAuthIdChangeFirst = component.get("v.isAuthIdChangeFirst");
        var authRecordId ='';
        authRecordId=simpleNewAuthNotes.idn_auth__c;
       
        var isAuthIdChange = component.get("v.isAuthIdChange");
        
        var action1 = component.get("c.getAuthorizationNotesStatus");
        action1.setParams({"authId": authRecordId,"isNew":isNew,"isAuthIdChange":isAuthIdChange});
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res =response.getReturnValue();
                component.set("v.authStatus", response.getReturnValue());
                component.set("v.auth", res.auth);
                var lstSObject = [];
                var simpleNewAuthNotes = component.get("v.simpleNewAuthNotes");
                var isNew = component.get("v.isNew");
                var authStatus = component.get("v.authStatus");
                if(isNew){
                    simpleNewAuthNotes.createddate__c =new Date();// helper.getDateInUTC(new Date());
                    simpleNewAuthNotes.createdbyid__c = component.get("v.loggedInUserId");
                }
                simpleNewAuthNotes.lastmodifieddate__c =new Date();// helper.getDateInUTC(new Date());
                simpleNewAuthNotes.lastmodifiedbyid__c = component.get("v.loggedInUserId");
                
                if(simpleNewAuthNotes!=undefined){
                    lstSObject.push(simpleNewAuthNotes);
                }
                if(authStatus!= null && !authStatus.isUpdate){
                    var recordError2 =[];
                    if(isNew){
                        recordError2.push('Can not create Authorization Note as it\'s Authorization is terminated');
                    }else{
                        recordError2.push('Can not update authorization Note as it\'s Authorization is terminated.');
                    }
                   // recordError2.push('Can not update authorization Id and Description');
                    component.set("v.message",'error');
                    component.set("v.recordError",recordError2);
                }else if(authStatus!= null && !authStatus.isAuthFlowCompleted){
                    var recordError2 =[];
                    if(isNew){
                        recordError2.push('This action cannot be taken for an Incomplete Authorization. Please complete or delete the authorization.');
                    }else{
                        recordError2.push('This action cannot be taken for an Incomplete Authorization. Please complete or delete the authorization.');
                    }
                   // recordError2.push('Can not update authorization Id and Description');
                    component.set("v.message",'error');
                    component.set("v.recordError",recordError2);
                }else{
                    if(authStatus != null){
                        simpleNewAuthNotes.idn_auth__c =  authStatus.auth.IDN_EXTNL__c;
                        helper.callServerForExternalObjAndHandleError(component,"c.insertExternalObjRecords", 
                                                                      function(response){
                                                                          helper.redirectToRecord(component.get("v.recordId"));
                                                                          //generating Correspondence CR213 once the AUTH_NOTES record is created, 
                                                                          //i.e, creating T_DOC Request record.
                                                                          var action2 = component.get("c.CR213Corr");
                                                                          action2.setParams({"authId": authRecordId});
            															  action2.setCallback(this, function(resp) {
                                                                              var state1 = resp.getState();
                															  if(state1 === "SUCCESS") {
                    			
                															  } else {
                    
                															  }
            															  });
																		  $A.enqueueAction(action2);
                                                                      }, {'lstSObject':lstSObject,"isFinalStep":true}, false, null);
                    }
                }
            } else {
               
            }
        });
        $A.enqueueAction(action1);
    },
    getDateInUTC: function(date) {  
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    },
})