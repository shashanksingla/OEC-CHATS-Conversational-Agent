({
    fireEventHlp :function(component, event, helper) {
        var adjustmentDetail = component.get("v.adjustmentDetail");
        var adjustmentDetailTemp = component.get("v.adjustmentDetailTemp");
        var subPaymentDetail = component.get("v.subPaymentDetail");        
        var appEvent = $A.get("e.c:createAdjustDetails");
       appEvent.setParams({ "adjustmentDetailObj" : adjustmentDetail ,"key":subPaymentDetail.ExternalId, "adjustmentDetailTemp" : adjustmentDetailTemp,"isARTFee":component.get("v.ARTFeeFlag") });
        appEvent.fire();
    }
})