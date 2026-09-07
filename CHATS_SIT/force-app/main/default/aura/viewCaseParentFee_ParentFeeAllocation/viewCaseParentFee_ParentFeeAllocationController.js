({
    validateParentFeeAllocation : function(component, event, helper) {
        var parentFeeAllocationRows = component.find('parentFeeAllocationRow');
        var areAllFieldsValid = true;
        if(parentFeeAllocationRows){
            if(parentFeeAllocationRows.length>0){
                areAllFieldsValid = parentFeeAllocationRows.reduce(function (validSoFar, parentFeeAllocationRow) {
                    return parentFeeAllocationRow.validateEachRow() && validSoFar;
                }, true);
            }else{
                areAllFieldsValid = parentFeeAllocationRows.validateEachRow();
            }
        }
         return areAllFieldsValid;
    }
})