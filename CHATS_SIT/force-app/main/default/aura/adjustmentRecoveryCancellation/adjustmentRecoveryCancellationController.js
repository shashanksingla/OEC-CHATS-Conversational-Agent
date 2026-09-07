({
    doInit: function (component, event, helper) {
        component.set('v.isLoading',true);
        var action = component.get("c.getAdjustmentDetails");
        action.setParams({ 'adjustmentId': component.get('v.recordId') });
        action.setCallback(this, function (response) {
            let cancelRecord = {};
            var lsr = response.getReturnValue();
            if (lsr.isSuccessful) {
                let profile = lsr.objectData.userProfile;
                if(profile.toLowerCase().includes('admin')){
                    component.set('v.isAdmin',true);
                }
                component.set('v.userProfile',lsr.userProfile);
                let rsp = JSON.parse(JSON.stringify(lsr.objectData));
                let adjCanRecList = rsp.adjCanRecList || {};
                if (adjCanRecList.Id) {
                    cancelRecord = JSON.parse(JSON.stringify(adjCanRecList));
                }else{
                    cancelRecord.IDN_ADJMT__c = component.get('v.recordId');
                    cancelRecord.CDE_STATUS__c = '1'; // Draft
                }
                component.set('v.adjCancellationRecord', cancelRecord);
                
            }
            component.set('v.isLoading',false);
        });
        $A.enqueueAction(action);
    },
    handleRecordUpdated:function(component,event,helper){
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            // get the fields that changed for this record
            var changedFields = eventParams.changedFields;
            if(changedFields.CDE_STATUS__c){
                helper.checkforWarning(component,event,helper);
                //console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            }
        } else if(eventParams.changeType === "LOADED") {
            //console.log("account loaded:::::" + JSON.stringify(component.get("v.adjRecord")));
        }
    },
    closePopUp: function (component, event, helper) {
        component.find("overlayLib").notifyClose();
    },
    handleSuccess: function (component, event, helper) {
        $A.get('e.force:refreshView').fire();
        component.set('v.isLoading',false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success",
            "message": component.get('v.successToastMsg'),
            "type":"success"
        });
        toastEvent.fire();
        component.find("overlayLib").notifyClose();
    },
    SubmitCancellation: function (component, event, helper) {
        let cancelRecord = component.get('v.adjCancellationRecord') || {};
        cancelRecord.CDE_STATUS__c = '2'; // Submitted
        component.set('v.action','submit');
        component.set('v.successToastMsg',"Adjustment Cancellation Submitted Successfully");
        if( component.get('v.adjRecord') && !component.get('v.adjRecord').DTE_INIT_CANCEL__c){
            component.set('v.warningAccepted',true); 
        }
        helper.validateForm(component, event, helper, cancelRecord);
    },
    
    WithdrawCancellation: function (component, event, helper) {
        event.preventDefault();
        let cancelRecord = component.get('v.adjCancellationRecord') || {};
        cancelRecord.CDE_STATUS__c = '6'; //Withdrawn
        component.set('v.action','withdraw');
        component.set('v.successToastMsg',"Adjustment Cancellation Withdrawn Successfully");
        helper.validateForm(component, event, helper, cancelRecord);
    },
    
    SaveCancellation: function (component, event, helper) {
        let cancelRecord = component.get('v.adjCancellationRecord') || {};
        component.set('v.action','save');
        component.set('v.successToastMsg',"Adjustment Cancellation Saved Successfully");
        helper.validateForm(component, event, helper, cancelRecord);
    },
    handleError: function (component, event, helper) {
        component.set("v.messageType", 'error');
        let errors = [];
        errors.push(event.getParam("detail"));
        component.set("v.recordError", errors);
        component.set('v.isLoading',false);
    },
    handlewarningAccept:function(component,event,helper){
        component.set('v.showConfirmDialog',false);
        component.set('v.warningAccepted',true);
    },
    handleContinue:function(component,event,helper){
        component.set('v.showConfirmDialog',false);
        component.set('v.warningAccepted',true);
        helper.validateForm(component,event,helper,component.get('v.adjCancellationRecord'));
    },
    hideConfirmModal: function(component, evt, helper){
        component.set('v.showConfirmDialog',false);
    },
    redirectToCancellation: function(component, evt, helper){
        window.open('/'+component.get('v.adjCancellationRecord').Id,'_blank');
    }
})