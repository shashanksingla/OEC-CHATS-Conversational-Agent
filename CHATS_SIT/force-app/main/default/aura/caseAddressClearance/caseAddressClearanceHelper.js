({
    doUpdate : function(component) {
       
        var inputToSend =JSON.stringify(component.get("v.selectedAddress"));
        if(!$A.util.isEmpty(component.get("v.selectedAddress"))) 
        {
            
            var action = component.get('c.updateAddress');
            component.set("v.showSpinner", true);
            
            action.setParams({"addressWrapperStr": inputToSend,
                              "recordId":component.get("v.caseRec.Id")
                             });
            action.setCallback(this, function(actionResult) {
                
                var returnValue = actionResult.getReturnValue();
                component.set("v.showSpinner", false);
                if(returnValue!=null && returnValue.isSuccessful ){
                    component.set("v.showSpinner",false);
                    /*var multipleAddress = component.get("v.multipleAddress");
                    if(!multipleAddress){
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({mode: 'sticky',message: 'Address Updated Successfully', title: 'Success!' , type: 'success'});
                        toastEvent.fire();
                    }
                    else{
                        component.set("v.updateSuccess", component.get("v.addressType")+' Address Updated Successfully')
                    }*/
                    component.set("v.updateSuccess", component.get("v.addressType")+' Address Updated Successfully');
                    component.set("v.showUpdate",false);
                    
                }else if (returnValue!=null && !returnValue.isSuccessful)
                {
                    component.set("v.showSpinner",false);
                    component.set("v.recordError" , returnValue.errorMessage);
                }
            });
            $A.enqueueAction(action);
        }
        /*else{
          
        }*/
    },
    setAddressType : function(component) {
        
        var addressType= component.get("v.caseRec").CDE_TYPE_ADR__c;
        if (addressType!=null && addressType =='MAL'){
            component.set("v.addressType",'Mailing');
        }
        else if(addressType!=null && addressType == 'HOM')
        {
            component.set("v.addressType",'Home');
        } 
    },
    navigateToSource: function(component){
        var caseAddressTracker = component.get("v.caseAddressTracker");
        var returnVal = false, displayError = false;
        var execSource = component.get("v.execSource");
        if(!$A.util.isEmpty(caseAddressTracker)){
            for(var i=0; i<caseAddressTracker.length; i++){
                if(caseAddressTracker[i].selectedValidAddress || caseAddressTracker[i].unvalidatedAddress){
                    returnVal = true;
                }
                else{
                    returnVal = false;
                    break;
                }
            }
        }
        else{
            returnVal = true; // This scenario is to handle case address invocation
        }
        if(!$A.util.isEmpty(component.get("v.selectedAddress")) || component.get("v.skipUpdate")){
            displayError = false;	
            component.set("v.displayError", displayError);
        }
        else{
            displayError = true; 
            component.set("v.displayError", displayError);
        }
        if((execSource == "Case" || execSource == "CaseAddress")){
            if(returnVal && !displayError){
                var navEvt = $A.get("e.force:navigateToSObject");
                if(execSource =="Case"){
                    navEvt.setParams({
                        "recordId": component.get("v.caseId")
                    });
                }
                else{
                    navEvt.setParams({
                        "recordId": component.get("v.caseRec.Id")
                    });
                }
                navEvt.fire();
            }
            if(displayError){
                component.set("v.pageMessages", "Please select an option for address clearance");
                component.set("v.messageType", "error");
            }
        }
    }
})