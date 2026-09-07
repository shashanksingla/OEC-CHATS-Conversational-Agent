({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        
        var isValid = true;
        var adjustment = cmp.get("v.adjustment");
        var atLeastOneSelected =false;
        if(adjustment && adjustment.RecordType.DeveloperName!='Finalized'){
            var responsiblePartyList = cmp.get("v.responsiblePartyList");
            responsiblePartyList.forEach(function(existingResponsibleParty){
                if(existingResponsibleParty.Selected__c){
                    atLeastOneSelected = true; 
                }
                
            });
            if(!atLeastOneSelected){
                debugger;
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type":"error",
                    "message": 'At least one checkbox must be checked before proceeding to the next screen.'
                });
                toastEvent.fire();
                // cmp.find("selectedResponsibleParties").set("v.message","At least one checkbox must be checked before proceeding to the next screen.");
                isValid = false;
                // cmp.set("v.message",'error');
                // cmp.set("v.recordError",['At least one checkbox must be checked before proceeding to the next screen.']);
            }else{
                //  cmp.set("v.recordError",[]);
                // cmp.find("selectedResponsibleParties").set("v.message",null);
            }
        }
        return isValid;
    }
})