({
    doInit : function(component, event, helper) {
        var parentObjectId;
        var parentObjectAPI;
        var ref = component.get("v.pageReference");
        var state = ref.state; 
        var context = state.inContextOfRef;
        if(context.startsWith("1\.")){
            context = context.substring(2);
            var addressableContext = JSON.parse(window.atob(context));
            if(!helper.isEmpty(addressableContext)){
                if(!helper.isEmpty(addressableContext.attributes)){
                    if(!helper.isEmpty(addressableContext.attributes.recordId)){
                        parentObjectId = addressableContext.attributes.recordId;
                        component.set('v.parentObjectId', parentObjectId);
                    }
                    if(!helper.isEmpty(addressableContext.attributes.objectApiName)){
                        parentObjectAPI = addressableContext.attributes.objectApiName;
                        component.set('v.parentObjectAPI', parentObjectAPI);
                    }
                }
            }
        }
        helper.clearAllFields(component);
        var action = component.get("c.getInitData");
        action.setParams({
            "parentObjectId": parentObjectId,
            "parentObjectAPI": parentObjectAPI
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set('v.assignedCounties', res.objectData.assignedCounties);
                    component.set('v.parentObjectName', res.objectData.parentObjectName);
                    component.set('v.isReadyToRender', true);
                } else {
                    helper.handleError(res.message);
                }
            } else if(state === "ERROR") {
                var errors = response.getError();
                if(errors){
                    if (errors[0] && errors[0].message){
                        helper.handleError(errors[0].message);
                    }
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
        helper.callServerAndHandleError(component,"c.saveAdjustmentPayment", function(response){
            if(response.isSuccessful){
                helper.handleSuccess('Adjustment Payment created successfully');
                $A.get('e.force:refreshView').fire();
                if(helper.isEmpty(component.get('v.parentObjectId'))){
                    window.history.back();
                } else {
                    helper.redirectToRecord(component.get("v.parentObjectId"));
                }
            }
        },{"adjPaymentObj": component.get("v.adjPaymentObj")}, false, null);
    },
    
    doCancel : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        window.history.back();
    },
    
    handlePageError : function(component, event, helper) {
        var messageType = event.getParam("value");
        if(messageType == 'error'){
            component.find('confirmationModalOnFinish').hideConfirmModal();
        }
    }
})