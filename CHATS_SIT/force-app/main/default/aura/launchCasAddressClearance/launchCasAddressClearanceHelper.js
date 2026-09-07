({
    getCaseAddressIdList : function(component) {
        
        var execSource = component.get("v.execSource");
        if(execSource == "Case"){
            component.set("v.showSpinner",true);
            var action = component.get('c.getCaseAddressIdList');
            action.setParams({"caseId":component.get("v.recordId"),
                             });
            action.setCallback(this, function(actionResult) {
                
                var returnValue = actionResult.getReturnValue();
                var caseAddressTracker = [], addressTracker = {}, j=0;
                if(returnValue!=null && returnValue.isSuccessful){
                    var returnedIdList = returnValue.objectData['caseAddressIdList'];
                    if(!$A.util.isEmpty(returnedIdList)){
                        for(var i=0; i<returnedIdList.length; i++){
                            addressTracker.Id = returnedIdList[i];
                            addressTracker.selectedValidAddress = false;
                            addressTracker.unvalidatedAddress = false;
                            caseAddressTracker[j] = addressTracker;
                            addressTracker = {};
                            j=j+1;
                        }
                    }
                    component.set("v.caseAddressTracker", caseAddressTracker);
                    component.set("v.caseAddressIdList", returnedIdList);
                    component.set("v.showSpinner",false);
                    
                }else if(returnValue!=null && !returnValue.isSuccessful ){
                    component.set("v.showSpinner",false);
                    component.set("v.recordError", returnValue.errorMessage )
                }
            });
            $A.enqueueAction(action);
        }
    }
})