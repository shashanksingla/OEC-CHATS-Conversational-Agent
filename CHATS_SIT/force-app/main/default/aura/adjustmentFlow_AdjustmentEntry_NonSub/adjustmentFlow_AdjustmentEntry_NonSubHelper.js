({
    checkCustomValidations : function(cmp) {
        var isValid = true;
        if(!(cmp.get("v.authId")!=null && cmp.get("v.authId")!='' && cmp.get("v.authId")!=undefined)) {
            isValid = false;
            var errorComponent = cmp.find('authId');
            if(errorComponent){
                errorComponent.set("v.message",'Invalid Authorization ID');
            }
        }
        if($A.util.isEmpty(cmp.get("v.authorizationAssocFundingProgVal"))){
            isValid = false;
            var errorComponent = cmp.find('adjustmentFundingProgram');
            if(errorComponent){
                errorComponent.set("v.message",'Please enter a value');
            }
        }
        if(cmp.get("v.AMT_DETAIL_ADJMT__c")<=0) {
            isValid = false;
            cmp.find("adjustmentAmount").set("v.message",'Amount should be greater than zero');
        } else {
            cmp.find("adjustmentAmount").set("v.message",null);
        }
        if(isValid) {
            isValid = true;
            var errorComponent = cmp.find('authId');
            if(errorComponent){
                errorComponent.set("v.message",'');
            }
            var errorComponentFP = cmp.find('adjustmentFundingProgram');
            if(errorComponentFP){
                errorComponentFP.set("v.message",'');
            }
        }
        return isValid;
    },
    
    // Added by Rishav for CCCAP-6051
    validateAdjustmentAmount : function(component, event, helper) {
        var currentAdjAmount = component.get("v.adjustmentObj").AMT_ADJMT__c;
        var oldAjdAmount = 0;
        if(component.get("v.nonAdjustmentDetail") != null){
            oldAjdAmount = component.get("v.nonAdjustmentDetail").AMT_DETAIL_ADJMT__c;
        }
        var newAdjAmount = currentAdjAmount - oldAjdAmount + parseFloat(component.get("v.AMT_DETAIL_ADJMT__c"));
        var action = component.get("c.getAdjustmentPaidAmount");
        action.setParams({adjustmentId : component.get("v.adjustmentObj").Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var totalPaidAmount = response.getReturnValue();
                if(newAdjAmount < totalPaidAmount){
                    component.set("v.pageMessages", $A.get("$Label.c.adjustment_error_totalPaidAmount") + " $" + totalPaidAmount.toFixed(2));
                    component.set("v.messageType", "error");
                } else {
                    component.set("v.pageMessages", null);
                    component.set("v.messageType", null);
                    helper.validateAuthDateRange(component, event, helper);
                }
            } else if(state === "ERROR") {
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        component.set("v.pageMessages", errors[0].message);
                        component.set("v.messageType", "error");
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    closeAdjEntryModal : function(cmp) {
        cmp.find("overlayLib").notifyClose();		
    },
    
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    
    validateAuthDateRange : function(component, event, helper) {
        // Validate authorization begin and end date
        var action1 = component.get('c.getAuthObj');
        action1.setParams({'authId' : component.get("v.authId")});
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    if(res.objectData.authObj){
                        var authObj = res.objectData.authObj;
                        var adjustmentObj = component.get("v.adjustmentObj");
                        if(authObj.DTE_BEGIN_EFFV_AUTH__c <= adjustmentObj.DTE_START_ADJMT__c && authObj.DTE_END_EFFV_AUTH__c >= adjustmentObj.DTE_END_ADJMT__c){
                            this.updateOrNewRec(component); 
                        }else{
                            helper.callModal(component,'confirmationModalOnAuthValidationNonDetail'); 
                        }
                    }
                }
            }
        });
        $A.enqueueAction(action1);
        // end
    },
    
    updateOrNewRec : function(component) {
        if(!component.get("v.isSaveProcessRunning")){ // Added 'isSaveProcessRunning' check by Rishav for CCCAP-7983
            component.set("v.isSaveProcessRunning", true);
            var inputCmp = component;
            if(component.get("v.adjustmentEntryEditMode") == true) {
                component.set("v.adjustmentEntryEditMode", false);
                var objToUpdate = inputCmp.get("v.nonAdjustmentDetail");
                var nonAdjustmentDetail = {'sobjectType':'T_NON_ADJMT_DETAIL__c',
                                           'IDN_AUTH__c':inputCmp.get("v.authId"),
                                           'AMT_DETAIL_ADJMT__c':inputCmp.get("v.AMT_DETAIL_ADJMT__c"),
                                           'IDN_PROG_FNDG__c':inputCmp.get("v.authorizationAssocFundingProgVal"),
                                           'Id':objToUpdate.Id};
                this.callServerAndHandleError(component,"c.upsertRecords", function(response){
                    if(response.isSuccessful == true){
                        var nonAdjustmentDetailObj = component.get("v.nonAdjustmentDetailObj");
                        nonAdjustmentDetailObj.forEach(function(eachNonAdjValue) {
                            if(eachNonAdjValue.Id === objToUpdate.Id) {
                                eachNonAdjValue.IDN_AUTH__c = nonAdjustmentDetail.IDN_AUTH__c;
                                eachNonAdjValue.AMT_DETAIL_ADJMT__c = nonAdjustmentDetail.AMT_DETAIL_ADJMT__c;
                                eachNonAdjValue.IDN_PROG_FNDG__c = inputCmp.get("v.authorizationAssocFundingProg");
                                
                            }
                        });
                        component.set("v.isSaveProcessRunning", false);
                        var confirmationModalOnNewNonDetail = component.find("confirmationModalOnNewNonDetail");
                        confirmationModalOnNewNonDetail.hideConfirmModal();
                        //this.closeAdjEntryModal(component);
                        if(component.get("v.userAction")=='Save') {
                            this.closeAdjEntryModal(component);
                        }
                        var appEvent = $A.get("e.c:confirmModalEventFire");
                        appEvent.setParam("nonAdjustmentDetailObj", nonAdjustmentDetailObj);
                        appEvent.fire();
                    } else {
                        component.set("v.isSaveProcessRunning", false);
                    }
                },{'lstSObject':[nonAdjustmentDetail]}, false, null);
            } else {
                var nonAdjustmentDetail = {'sobjectType':'T_NON_ADJMT_DETAIL__c',
                                           'IDN_AUTH__c':inputCmp.get("v.authId"),
                                           'AMT_DETAIL_ADJMT__c':inputCmp.get("v.AMT_DETAIL_ADJMT__c"),
                                           'IDN_PROG_FNDG__c':inputCmp.get("v.authorizationAssocFundingProgVal"),
                                           'IDN_ADJMT__c':inputCmp.get("v.adjustmentObj").Id};
                this.callServerAndHandleError(component,"c.upsertRecords", function(response){
                    if(response.isSuccessful == true){
                        var nonAdjustmentDetailObj = [];
                        if(component.get("v.nonAdjustmentDetailObj")) {
                            nonAdjustmentDetailObj = component.get("v.nonAdjustmentDetailObj");
                        }
                        nonAdjustmentDetail["IDN_AUTH__r"] = {"Name":inputCmp.get("v.valueLabel")};
                        nonAdjustmentDetail.IDN_PROG_FNDG__c = inputCmp.get("v.authorizationAssocFundingProg");
                        nonAdjustmentDetail.Id=response.objectData.upsertedRecords[0].Id;
                        if(inputCmp.get("v.authorizationAssocIndiv")) {
                            nonAdjustmentDetail.IDN_AUTH__r["IDN_CLIENT__r"] = {
                                "NAM_LAST__c":inputCmp.get("v.authorizationAssocIndiv").split(",")[1],
                                "NAM_FIRST__c":inputCmp.get("v.authorizationAssocIndiv").split(",")[0]
                            }
                        }
                        nonAdjustmentDetailObj.push(nonAdjustmentDetail);
                        component.set("v.nonAdjustmentDetailObj",nonAdjustmentDetailObj);    
                        component.set("v.authorizationAssocIndiv",""); 
                        component.set("v.authId",""); 
                        component.set("v.authorizationObj",{});
                        component.set("v.AMT_DETAIL_ADJMT__c",0);
                        component.set("v.adjustmentEntryEditMode", false);
                        component.set("v.isSaveProcessRunning", false);
                        var confirmationModalOnNewNonDetail = component.find("confirmationModalOnNewNonDetail");
                        confirmationModalOnNewNonDetail.hideConfirmModal();
                        var confirmationModalOnAuthValidationNonDetail = component.find("confirmationModalOnAuthValidationNonDetail");
                        confirmationModalOnAuthValidationNonDetail.hideConfirmModal();
                        if(component.get("v.userAction")=='Save') {
                            this.closeAdjEntryModal(component);
                        }
                        var appEvent = $A.get("e.c:confirmModalEventFire");
                        appEvent.setParam("nonAdjustmentDetailObj", nonAdjustmentDetailObj);
                        appEvent.fire();
                        var appEvent1 = $A.get("e.c:nonSubPaymentEvent");
                        appEvent1.setParam("isFirePrevious", true);
                        appEvent1.fire();
                        // compEvent.fire();
                    } else {
                        component.set("v.isSaveProcessRunning", false);
                    }
                },{'lstSObject':[nonAdjustmentDetail]}, false, null);
            }
        }
    }
})