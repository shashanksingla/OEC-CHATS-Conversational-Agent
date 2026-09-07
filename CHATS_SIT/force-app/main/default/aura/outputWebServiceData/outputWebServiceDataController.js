({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.getDataFromWebService");
        action.setParams({endPoint:component.get("v.endPoint"), 
                          method:component.get("v.method"), 
                          requestBody:component.get("v.requestBody"),
                          requiredParams:component.get("v.requiredParams")
                         });
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var lsr = response.getReturnValue();
               
                if(lsr.isSuccessful==true){
                    var value = "";
                    component.get("v.requiredParams").forEach(function(requiredParam){
                        value += lsr.objectData[requiredParam];
                    });
	                component.set("v.value",value);
                }else if(lsr.isSuccessful==false){
                    component.set("v.value",lsr.errorMessage);
                }else{
                    component.set("v.value",JSON.stringify(lsr));
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.value","Error message: " + 
                                      errors[0].message);
                    }
                } else {
                    component.set("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})