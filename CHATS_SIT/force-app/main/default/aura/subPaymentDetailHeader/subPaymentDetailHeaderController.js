({
    mapPicklistValues : function(component, event, helper){
        
        helper.callServerAndHandleError(component,"c.subPaymentDetailsPicklistMap", function(response){
            component.set("v.subPaymentDetailData", response.objectData.subPaymentDetailInfo[0]);
            component.set("v.subPaymentId", response.objectData.subPaymentId);
            component.set("v.isVacantSlotPayment", response.objectData.vacantSlotPayment);
        },{recordId : component.get("v.recordId")}, false, null);
    }
})