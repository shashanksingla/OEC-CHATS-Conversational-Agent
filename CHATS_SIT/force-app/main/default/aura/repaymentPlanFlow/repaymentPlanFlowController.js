({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getInitData");
        action.setParams({"recordId": recordId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set('v.parentObjId', res.objectData.parentObjId);
                    component.set('v.sObjName', res.objectData.sObjName);
                    component.set('v.assignedCounties', res.objectData.assignedCounties);
                    component.set('v.parentObjName', res.objectData.parentObjName);
                    component.set('v.allowedCounties', res.objectData.allowedCounties);
                    component.set('v.isAdmin', res.objectData.isAdmin);
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    doFinish : function(component, event, helper){
        var requiredFieldsVerified = helper.checkCustomValidations(component, event, helper);
        if(requiredFieldsVerified){
            helper.callModal(component,'confirmationModalOnFinish');
        }
    },
    
    comfirmFinish : function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.callServerAndHandleError(component,"c.saveRepaymentPlan", function(response){
            if(response.isSuccessful){
                if(component.get('v.sObjName') == 'T_CHATS_PROVR_STATUS__c'){
                    helper.handleSuccess('Repayment Plan created successfully');
                    helper.redirectToRecord(component.get("v.recordId"));
                } else {
                    helper.handleSuccess('Repayment Plan updated successfully');
                    helper.redirectToRecord(component.get("v.recordId"));
                }
            }
        },{"repaymentPlanObj": component.get("v.repaymentPlanObj")}, false, null);
    },
    
    doCancel : function(component, event, helper) {
        if(component.get("v.sObjName") == 'T_CHATS_PROVR_STATUS__c'){
            helper.redirectToRecord(component.get("v.recordId"));
        } else {
            window.history.back();
        }
    },
    
    handleError : function(component, event, helper) {
        var messageType = event.getParam("value");
        if(messageType == 'error'){
            component.find('confirmationModalOnFinish').hideConfirmModal();
        }
    }
})