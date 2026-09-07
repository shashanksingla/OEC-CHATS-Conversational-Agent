({
	doInit : function(component, event, helper) {
		
	},
    getChildName : function(component, event, helper) {
		
    },
    confirmNewRec :function(component, event, helper) {
		
    },
    fireEvent: function(component, event, helper) {
		
    },
    updateAdjDetails : function(component, event, helper){
        var sObjectList = [];
        var adjustmentDetail = component.get("v.adjustmentDtlWarp");
        var rateTypeOptions = component.get("v.rateTypeOptions");
        var rateTypeLabel =adjustmentDetail.CDE_TYPE_RATE_ADJD__c;
        for(var i=0;i<rateTypeOptions.length;i++){
            if(adjustmentDetail.CDE_TYPE_RATE_ADJD__c== rateTypeOptions[i].label){
                adjustmentDetail.CDE_TYPE_RATE_ADJD__c = rateTypeOptions[i].value;
            }
        }
        if(adjustmentDetail != null){
            sObjectList.push(adjustmentDetail);
        }
        if(component.get("v.adjustmentEntryEditMode")==true) {
            component.set("v.adjustmentEntryEditMode", false);
            helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                if(response.isSuccessful){
                    var objToUpdate = component.get("v.adjustmentDtlWarp");
                    var adjustmentDtlWarpArr = component.get("v.adjustmentDtlWarpArr");
                   
                    adjustmentDtlWarpArr.forEach(function(eachNonAdjValue) {
                        if(eachNonAdjValue.ajustmentDetails.Id === objToUpdate.Id) {
                            eachNonAdjValue.ajustmentDetails.AMT_DETAIL_ADJMT__c = objToUpdate.AMT_DETAIL_ADJMT__c;
                            eachNonAdjValue.ajustmentDetails.IND_OVERRIDE__c = objToUpdate.IND_OVERRIDE__c;
                            eachNonAdjValue.ajustmentDetails.NBR_HOURS_ATTND_ADJD__c = objToUpdate.NBR_HOURS_ATTND_ADJD__c;
                            eachNonAdjValue.ajustmentDetails.CDE_TYPE_RATE_ADJD__c = rateTypeLabel;
                            eachNonAdjValue.ajustmentDetails.AMT_PAID_RATE_ADJD__c = objToUpdate.AMT_PAID_RATE_ADJD__c;
                           
                        }
                    });
                    
                    var appEvent = $A.get("e.c:adjustmentdetailEditEvent");
                    appEvent.setParam("adjustmentDtlWarp", adjustmentDtlWarpArr);
                    appEvent.fire();
                    var confirmationModalOnNewNonDetail = component.find("confirmationModalOnNewNonDetail");
                    confirmationModalOnNewNonDetail.hideConfirmModal();
                    component.set("v.adjustmentEntryEditMode", false);
                    helper.closeAdjEntryModal(component);
                }
                
            },{'lstSObject':sObjectList,"isFinalStep":true}, false, null);
        }
    },
     closeModal : function(component, event, helper) {
        component.set("v.adjustmentEntryEditMode", false);
     	helper.closeAdjEntryModal(component);
    },
})