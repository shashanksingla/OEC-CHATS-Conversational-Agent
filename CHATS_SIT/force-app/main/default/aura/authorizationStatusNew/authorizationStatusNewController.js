({
    doInit : function(component, event, helper) {
        helper.fetchUserId(component, event, helper);
     // Getting User county check
        var action1 = component.get('c.checkOwnerCountyMatch');
        action1.setParams({
            'recordId' : component.get("v.recordId"),'fieldName':'CDE_COUNTY__c'
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                	//Setting create process boolean check to true
                    component.set("v.createProcess",res.objectData.createProcess);
                    component.set("v.isAuthFlowCompleted",res.objectData.isAuthFlowCompleted);
                    if((res.objectData.showWarning)){
                        component.set("v.showWarningForCounty",res.objectData.showWarning);
                       
                        component.set("v.countyMessage",res.objectData.warningMessage);
                    }else{
                        component.set("v.showWarningForCounty",false);
                        component.set("v.countyMessage",res.objectData.warningMessage);
                    }
                }
            } else {
               
            }
        });        
        $A.enqueueAction(action1);
    },
    verifyUserCounty : function(component, event, helper) {
        var authStatusRecord = component.get("v.authStatusRecord");
        var authRecord = component.get("v.proRecord");
        //authStatusRecord.idn_case_c__c = component.get('v.recordId');
        authStatusRecord.createdbyid__c = component.get('v.loggedInUserId');
        authStatusRecord.createddate__c = new Date();
        authStatusRecord.lastmodifiedbyid__c = component.get('v.loggedInUserId');
        authStatusRecord.lastmodifieddate__c = new Date();
        authStatusRecord.idn_auth__c = authRecord.IDN_EXTNL__c ;//component.get('v.recordId'); 
        authStatusRecord.cde_status_auth__c = '4';
        var authId = authRecord.Id;
        var timeConversionOffset = component.get("v.timeConversionOffset");
        var updateDate = helper.getDateInUTC(authStatusRecord.dte_begin_effv__c);
        var authEndDate = helper.getDateInUTC(authRecord.DTE_END_EFFV_AUTH__c);
        var authstatusBeginDate = helper.getDateInUTC(authStatusRecord.dte_begin_effv__c);
        console.log('authstatusBeginDate-->'+authstatusBeginDate);
        console.log('authEndDate-->'+authEndDate);
        var isValid =  component.find("chnageReasonId").showHelpMessageIfInvalid();
        component.find('input-field').showHelpMessageIfInvalid();
         if(authStatusRecord.dte_begin_effv__c != null && authStatusRecord.dte_begin_effv__c != '' && 
           authStatusRecord.cde_status_auth__c != null && authStatusRecord.cde_status_auth__c != '' &&
           component.find('input-field').get('v.validity').valid  && isValid
          ){
             if(authStatusRecord.dte_begin_effv__c != null && authStatusRecord.dte_begin_effv__c != '' && 
           authStatusRecord.cde_status_auth__c != null && authStatusRecord.cde_status_auth__c != '' &&
           authstatusBeginDate> authEndDate
               ){
                 component.set("v.message",'error');
                 component.set("v.recordError",['Authorization Status Effective Date can not be after Authorization End Date. ']);
             }else if(!component.get("v.isAuthFlowCompleted")){
                 var recordError2 =[];
                 recordError2.push('This action cannot be taken for an Incomplete Authorization. Please complete or delete the authorization.');
                 component.set("v.message",'error');
                 component.set("v.recordError",recordError2);
             }else{
                 var lstSObject = [];
                 if(authStatusRecord!=undefined){
                     lstSObject.push(authStatusRecord);
                 }
                 var showWarningForCounty = component.get("v.showWarningForCounty");
                 if(showWarningForCounty){
                   //  helper.saveRecord(component, event, helper);
                     helper.callModal(component,'confirmationModalOnParentFeeCheck');
                 }else{
                     component.set("v.message",'error');
                 	 component.set("v.recordError",[component.get("v.countyMessage")]);
                    // helper.callModal(component,'confirmationModalOnCountyCheck_1');
                 } 
             }
             
             
        }else{
            var recordError2 =[];
            recordError2.push('Please enter mandatory fields');
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
        }
    },
    handleCancelAuthNote :function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    confirmYes : function(component, event, helper){
        var cmp = component.find('confirmationModalOnParentFeeCheck');
        cmp.hideConfirmModal();
        helper.saveRecord(component, event, helper);
    },
    confirmCountyYes : function(component, event, helper){
        var cmp = component.find('confirmationModalOnCountyCheck_1');
        cmp.hideConfirmModal();
        helper.callModal(component,'confirmationModalOnParentFeeCheck');
    },
})