({
    validateAmountField : function(component, event, helper) {
        var isValid = true;
        var eachParentFeeAllocation = component.get("v.eachParentFeeAllocation");
        if(!$A.util.isEmpty(eachParentFeeAllocation) && component.get('v.isAuthCopayEditable')){
            component.find('input-field').showHelpMessageIfInvalid();
            isValid = component.find('input-field').get('v.validity').valid;
            if(isValid){
                
                eachParentFeeAllocation.allocatedAuthAmountDecimal = Math.floor(eachParentFeeAllocation.allocatedAuthAmountDecimal);
                eachParentFeeAllocation.allocatedAuthAmount = eachParentFeeAllocation.allocatedAuthAmountDecimal;
                component.set('v.eachParentFeeAllocation',eachParentFeeAllocation);
            }
        }
        return isValid;
    }
})