({
    doFinish : function(component, event, helper) {
        var childCmp = component.find("newDelinqRecord");
        childCmp.callValidateCurrentPage();
        if(component.get("v.isCurrentPageValid")==true){
            component.set("v.showSpinner", true);
            /*
            var action2 = component.get("c.saveParentFeeDelinq");
            action2.setParams({"newParentFeeDelinquencyObj": component.get("v.newParentFeeDelinquencyObj")});
            action2.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    var res=response.getReturnValue();
                    if(res.isSuccessful){
                        helper.redirectToRecord(component.get("v.recordId")); 
                    }else{
                        var recordError2 =[];
                        var message = res.errorMessage;
                        recordError2.push(message);
                        component.set("v.message",'error');
                        component.set("v.recordError",recordError2);
                    }
                    
                } else {
                    component.set("v.showSpinner", false); 
                    
                }
            });
            $A.enqueueAction(action2);
            */
            helper.callServerAndHandleError(component,"c.saveParentFeeDelinq", function(resp){
                                                if(resp){
                                                    helper.redirectToRecord(component.get("v.recordId"));
                                                }
                                            },
                                            {"newParentFeeDelinquencyObj": component.get("v.newParentFeeDelinquencyObj")}
                                            , false, null); 
            
        } else {
            component.set("v.showSpinner", false); 
        }
    },
    
    doCancel : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    }
})