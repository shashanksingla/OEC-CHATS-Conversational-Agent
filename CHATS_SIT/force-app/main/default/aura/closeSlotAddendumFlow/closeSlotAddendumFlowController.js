({
    doInit : function(component,event,helper) {
        console.log('objectName-----'+component.get("v.objectName"));
        console.log('sObjectName----'+component.get("v.sObjectName"));
        console.log('recordId----'+component.get("v.recordId"));
        component.set("v.parentId", component.get("v.recordId"));
        
        var fetchUserdataAction = component.get("c.fetchUserdata");
        fetchUserdataAction.setCallback(this, function(response){
            var lsr = response.getReturnValue();
            if(lsr.isSuccessful){
                component.set("v.userData",lsr.objectData);
            }
            helper.getInitData(component);
        });        
        $A.enqueueAction(fetchUserdataAction);
        
        var countyAction = component.get("c.SCfiscalCountyValidation");
        countyAction.setParams({
            slotContractId  : component.get("v.recordId")
        });
        countyAction.setCallback(this, function(response){
            var lsr = response.getReturnValue().objectData;
            if(lsr.countyMatched == false){
                var recordError = 'The Slot Contract record that you are trying to close belongs to '+lsr.countyName+' county. This does not match your assigned county(ies).';
                component.set("v.msgOnDiffOwnerCounty", recordError);
                helper.callModal(component,"warningModalOnDiffOwnerCounty");
            }
        });        
        $A.enqueueAction(countyAction);
    },
    
    doCancel: function(component, event, helper){
        var currentTabNumber = component.get("v.currentTabNumber");
        helper.callModal(component,'confirmationModalOnCancel_'+currentTabNumber);
    },
    
    actionOnCancelYesButton: function(component, event, helper){
        
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
        
    },
    
    doFinish: function(component, event, helper){
        var validationResult=helper.checkCustomValidations(component,helper);
        if(validationResult == true && component.get("v.errorDone")==false)
        {
        	helper.callModal(component,'warningMsgModal');
        }
        
        
        if(validationResult == true && component.get("v.errorDone")==true){
            var action = component.get("c.closeSCAddendumUpdate");
            var recordId = component.get("v.recordId");
            action.setParams({
                SCRecordId  : component.get("v.recordId"),
                endDate : component.get("v.effectiveEndDate"),
                reasonOfClosure : component.get("v.reasonForClosure")
            });
            
            action.setCallback(this, function(a) {
                if (a.getState() === "SUCCESS") {
                    var result = a.getReturnValue();
                    if(result){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "type":"success",
                            "message": "Your record has been successfully updated."
                        });
                        toastEvent.fire();
                        window.location.href = '/'+recordId ;
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type":"error",
                            "message": "Not able to save Slot Contract record."
                        });
                        toastEvent.fire();
                    }
                } else if (a.getState() === "ERROR") {
                    console.log('Error Recieved');
                }
            });
            $A.enqueueAction(action);
        } 
    },
    actiononNo : function(component, event, helper){
       var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    actionOnYes : function(component, event, helper){
        component.set("v.errorDone",true);
        var modalCall = component.find("warningMsgModal");
        modalCall.hideConfirmModal();
       
        //Call methodTwo from methodone
        var action = component.get('c.doFinish');
        $A.enqueueAction(action);
    },
    
})