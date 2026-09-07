({
    validateAddressClearance : function(component) {
        var caseAddressTracker = component.get("v.caseAddressTracker");
        var returnVal = false;
        if(!$A.util.isEmpty(caseAddressTracker)){
            for(var i=0; i<caseAddressTracker.length; i++){
                if(caseAddressTracker[i].selectedValidAddress || caseAddressTracker[i].unvalidatedAddress){
                    returnVal = true;
                }
                else{
                    returnVal = false;
                    return returnVal;
                }
            }
            return returnVal;
        }
    }
})