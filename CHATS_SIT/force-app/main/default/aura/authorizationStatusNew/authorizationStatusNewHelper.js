({
	fetchUserId : function(component, event, helper) {
        var action = component.get('c.fetchLoggedInUserId');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            	//Setting create process boolean check to true
                component.set("v.createProcess",true);
                component.set('v.loggedInUserId',response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                    }
                } else {
                    
                }
            }
        });
        $A.enqueueAction(action);
	},
	saveRecord : function(component, event, helper) {
        var cmp = component.find('confirmationModalOnCountyCheck_1');
        cmp.hideConfirmModal();
        var authStatusRecord = component.get("v.authStatusRecord");
        var authRecord = component.get("v.proRecord");
        //authStatusRecord.idn_case_c__c = component.get('v.recordId');
        authStatusRecord.createdbyid__c = component.get('v.loggedInUserId');
        authStatusRecord.createddate__c = helper.getDateInUTC(new Date());
        authStatusRecord.lastmodifiedbyid__c = component.get('v.loggedInUserId');
        authStatusRecord.lastmodifieddate__c = helper.getDateInUTC(new Date());
        authStatusRecord.idn_auth__c = authRecord.IDN_EXTNL__c ;//component.get('v.recordId'); 
        authStatusRecord.cde_status_auth__c = '4';
        var timeConversionOffset = component.get("v.timeConversionOffset");
        var updateDate = helper.getDateInUTC(authStatusRecord.dte_begin_effv__c);
        
        // authStatusRecord.dte_begin_effv__c =new Date(); helper.handleDate(updateDate,timeConversionOffset,0,0);
        // authStatusRecord.dte_begin_effv__c = helper.getDateInUTC(authStatusRecord.dte_begin_effv__c);
        var authId = authRecord.Id;
        if(authStatusRecord.dte_begin_effv__c != null && authStatusRecord.dte_begin_effv__c != '' && 
           authStatusRecord.cde_status_auth__c != null && authStatusRecord.cde_status_auth__c != ''
          ){
            var lstSObject = [];
            if(authStatusRecord!=undefined){
                lstSObject.push(authStatusRecord);
            }
            var createProcess = component.get('v.createProcess');
            
            if(component.get('v.createProcess') == true){
                component.set("v.showSpinner", true); // spinner on for action
                var action = component.get("c.upsertAuthStatus");
                action.setParams({"authStatus":authStatusRecord,"isNew":false,"isAuthIdChange":false,"authorizationId":authId,'isBatchInsert':false});
                action.setCallback(this, function(response) {
                    component.set("v.showSpinner", false); // spinner off for action 
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var res = response.getReturnValue();
                        // Alert the user with the value returned 
                        // from the server
                        
                        if(!$A.util.isEmpty(res.objectData)){
                            
                            if(!$A.util.isEmpty(res.objectData.xLog)){
                                this.logWebservice(component, event, helper,res.objectData.xLog);
                            }
                        }

                        
                        if(res.isSuccessful){
                            component.set("v.showSpinner", true); // spinner on for action 4
                            var action4 = component.get("c.authorizationCopayDelete");
                            action4.setParams({"recordId":authId});
                            action4.setCallback(this, function(response) {
                                var state4 = response.getState();
                                component.set("v.showSpinner", false); // spinner off for action 4
                                if (state4 === "SUCCESS") {
                                    component.set("v.showSpinner", true); // spinner on for action 2
                                    $A.enqueueAction(action3);
                                    //helper.redirectToRecord(component.get("v.recordId"));
                                }
                            }); 
                            $A.enqueueAction(action4);
                            var action3 = component.get("c.authEncumbDelete");
                            action3.setParams({"recordId":authId});
                            action3.setCallback(this, function(response) {
                                component.set("v.showSpinner", false); // spinner off for action 3
                                var state3 = response.getState();
                                if (state3 === "SUCCESS") {
                                    helper.redirectToRecord(component.get("v.recordId"));
                                }
                            }); 
                        }else{
                            var recordError2 =[];
                            var message = '';
                            if((res.objectData.Authorized) && (res.objectData.Terminated)){
                                message ='Authorization has authorization status with status Authorized and Terminated'; 
                            }
                            else if(res.objectData.Authorized){
                                message ='Authorization has authorization status with status Authorized';
                            }
                            /*else if(res.objectData.Terminated){
                                    message ='Authorization has authorization status with status Terminated';
                                }*/ 
                                else if(res.errorMessage){
                                    message =res.errorMessage;
                                }
                            if(res.objectData.EffectiveBeginInvalid){
                                recordError2.push('Authorization Status is Terminated so Effective Begin Date should be in Future.');
                            }
                            if(res.objectData.InvalidChangeReason){
                                recordError2.push('Authorization cannot be terminated with an effective date within 15 days except for reasons  \'Qualified Exempt Child Care Provider is no longer eligible to provide child care due to Must Take Action. (Maintain next day closure)\'');
                                
                            }
                            
                            if(res.objectData.HerokuValidFail){
                                var msg = res.errorMessage;
                                recordError2.push(msg);
                            }
                            if(message !=''){
                                recordError2.push(message);
                            }
                            component.set("v.message",'error');
                            component.set("v.recordError",recordError2);
                            //recordError2.push(message);
                            component.set("v.message",'error');
                            component.set("v.recordError",recordError2);
                        }
                    }else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                
                            }
                        } else {
                            
                        }
                    }
                });
                $A.enqueueAction(action); 
            }else{
                //Calling update and delete web services if 'createProcess Boolean is false.
            	var recordId = component.get("v.recordId");
                component.set("v.showSpinner", true); // spinner on for action1
                var action1 = component.get("c.updateAuthStatus");
                action1.setParams({"authStatus":authStatusRecord,"isNew":false,"isAuthIdChange":false,"authorizationId":authId});
                action1.setCallback(this, function(response) {
                    component.set("v.showSpinner", false); // spinner off for action 1
                    var state1 = response.getState();
                    if (state1 === "SUCCESS") {
                        var res = response.getReturnValue();
                        if(res.isSuccessful){
                            component.set("v.showSpinner", true); // spinner on for action4
                            var action4 = component.get("c.authorizationCopayDelete");
                            action4.setParams({"recordId":authId});
                            action4.setCallback(this, function(response) {
                                component.set("v.showSpinner", false); // spinner off for action 4
                                var state4 = response.getState();
                                if (state4 === "SUCCESS") {
                                    component.set("v.showSpinner", true); // spinner on for action 2
                                    $A.enqueueAction(action3);
                                    //helper.redirectToRecord(component.get("v.recordId"));
                                }
                            }); 
                            $A.enqueueAction(action4);
                            var action3 = component.get("c.authEncumbDelete");
                            action3.setParams({"recordId":authId});
                            action3.setCallback(this, function(response) {
                                component.set("v.showSpinner", false); // spinner off for action 3
                                var state3 = response.getState();
                                if (state3 === "SUCCESS") {
                                    helper.redirectToRecord(component.get("v.recordId"));
                                }
                            }); 
                        }else{
                            var recordError2 =[];
                            var message = '';
                            if(res.objectData.EffectiveBeginInvalid){
                                recordError2.push('Authorization Status is Terminated so Effective Begin Date should be in Future.');
                            }
                            if(res.objectData.InvalidChangeReason){
                                recordError2.push('Authorization cannot be terminated with an effective date within 15 days except for reasons  \'Qualified Exempt Child Care Provider is no longer eligible to provide child care due to Must Take Action. (Maintain next day closure)\'');
                            }
                            
                            if(message !=''){
                                recordError2.push(message);
                            }
                            component.set("v.message",'error');
                            component.set("v.recordError",recordError2);
                            component.set("v.message",'error');
                            component.set("v.recordError",recordError2);
                        }
                    }else if (state1 === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                
                            }
                        } else {
                            
                        }
                    }
                });
                $A.enqueueAction(action1);
            } 
        }else{
            var recordError2 =[];
            recordError2.push('Please enter mandatory fields');
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
        }
    },
	    getDateInUTC: function(date) {  
	        var date = new Date(date);
	        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
	    },
	    getDateInUTCWWithoutTime: function(date) {
	        var date = new Date(date);
	        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
	    },
	     logWebservice :function(component, event, helper,xlog){
        console.log('--logException--'+xlog);
        helper.callServer(component,"c.logException", 
                          function(response){
                              console.log("Exception occurred on server and has been logged.");
                          }, {"xLog":xlog}, false);
    } 	    
})