({
    doInit : function(component, event, helper) {
        
    },
    mapPicklistValues : function(component, event, helper){
        
        helper.callServerAndHandleError(component,"c.subPaymentPicklistMap", function(response){
            var spObj = response.objectData.subPaymentInfo[0];
            component.set("v.subPaymentData", spObj);
            if(spObj.idn_slot_contract__c != null && spObj.idn_auth__c == null){
                component.set("v.isVacantSlotPayment", true);
            }
        },{recordId : component.get("v.recordId")}, false, null);
    }
})