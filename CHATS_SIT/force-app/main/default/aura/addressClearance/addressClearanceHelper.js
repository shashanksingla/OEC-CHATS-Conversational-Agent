({
    doCalloutAndGetMatchingAddress : function(component) {
        var self = this;
        var action = component.get('c.getMatchingAddress');
        action.setParams({"street":component.get("v.street"),
                          "street2":component.get("v.street2"),
                          "secondary":component.get("v.secondary"),
                          "city":component.get("v.city"),
                          "state":component.get("v.state"),
                          "zipcode":component.get("v.zipcode"),
                          "lastline":component.get("v.lastline"),
                          "addressee":component.get("v.addressee"),
                          "urbanization":component.get("v.urbanization"),
                          "candidates":component.get("v.candidates"),
                          "match":component.get("v.match"),
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if(returnValue!=null && returnValue.isSuccessful){
                component.set("v.returnedAddressList", returnValue.objectData['addressList']);
                component.set("v.showSpinner",false);
            }else if(returnValue!=null && !returnValue.isSuccessful ){
                component.set("v.showSpinner",false);
                component.set("v.recordError", returnValue.errorMessage )
            }
            if(!$A.util.isEmpty(returnValue.objectData) && !$A.util.isEmpty(returnValue.objectData.xLog)){
                self.callServer(component, "c.logException", function(response){
                    // pass returned value to callback function
                    console.log(response);
                }, {'xLog':returnValue.objectData.xLog}, false);
            }
            
        });
        $A.enqueueAction(action);
    }
})