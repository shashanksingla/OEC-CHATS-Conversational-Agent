({
	doInit : function(component, event, helper) {
		 helper.fetchUserId(component, event, helper);
	},
    handleRecordUpdated :function(component, event, helper) {
		
	},
     handleCancelAuthNote :function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    saveRecord : function(component, event, helper) {
        var authStatusRecord = component.get("v.propertyRecord");
        //authStatusRecord.idn_case_c__c = component.get('v.recordId');
        authStatusRecord.lastmodifiedbyid__c = component.get('v.loggedInUserId');
        authStatusRecord.lastmodifieddate__c = new Date();
        if(authStatusRecord.dte_begin_effv__c != null && authStatusRecord.dte_begin_effv__c != '' && 
           authStatusRecord.cde_status_auth__c != null && authStatusRecord.cde_status_auth__c != '' &&
           authStatusRecord.cde_reason_change_auth__c != null && authStatusRecord.cde_reason_change_auth__c != '' &&
           authStatusRecord.idn_auth__c != null && authStatusRecord.idn_auth__c != ''
          ){
            var lstSObject = [];
            if(authStatusRecord!=undefined){
                lstSObject.push(authStatusRecord);
            }
            var isAuthIdChange = component.get("v.isAuthIdChange");
            var action = component.get("c.upsertAuthStatus");
            action.setParams({"authStatus":authStatusRecord,"isNew":false,"isAuthIdChange":isAuthIdChange});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var res = response.getReturnValue();
                    // Alert the user with the value returned 
                    // from the server
                   
                    if(res.isSuccessful){
                        helper.redirectToRecord(component.get("v.recordId"));
                    }
                    else{
                        var recordError2 =[];
                        var message = '';
                       
                        if((res.objectData.Authorized) && (res.objectData.Terminated)){
                            message ='Authorization has authorization status with status Authorized and Terminated'; 
                        }
                        else if(res.objectData.Authorized){
                            message ='Authorization has authorization status with status Authorized';
                        }
                            else if(res.objectData.Terminated){
                                message ='Authorization has authorization status with status Terminated';
                            }
                        if(res.objectData.EffectiveBeginInvalid){
                            recordError2.push('Authorization Status is Terminated so Effective Begin Date should be in Future.');
                        }
                        if(res.objectData.InvalidChangeReason){
                            recordError2.push('Invaid Authorization Change Reason');
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
                    }
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
        }else{
            var recordError2 =[];
            recordError2.push('Please enter mandatory fields');
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
        }
    },
    handleAuthIdChange :function(component, event, helper) {
       
        component.set("v.isAuthIdChange",true);
        var isAuthIdChangeFirst = component.get("v.isAuthIdChangeFirst");
        if(isAuthIdChangeFirst){
            component.set("v.isAuthIdChangeFirst",false);
            component.set("v.isAuthIdChange",false);
            
        }
    },
})