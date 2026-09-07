({
	doInit : function(component, event, helper) {
        /*helper.callServer(component, "c.getRollupSummaryValue", function(response){
            
            if(response.isSuccessful){
	            component.set("v.value",response.objectData.value);
            }else{
              
            }
        }, {
            "query":component.get("v.query"), 
			"rollUpFieldAPIName":component.get("v.rollUpFieldAPIName"), 
            "rollupType":component.get("v.rollupType"),
			"recordId":component.get("v.recordId"),
            "isAuthObjRec":component.get("v.isAuthObjRec")
        }, true); */
       // component.set("v.showSpinner",true);
        var action = component.get("c.getRollupSummaryValue");
        action.setParams({ query:component.get("v.query"), 
			rollUpFieldAPIName:component.get("v.rollUpFieldAPIName"), 
            rollupType:component.get("v.rollupType"),
			recordId:component.get("v.recordId"),
            isAuthObjRec:component.get("v.isAuthObjRec") });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                // Alert the user with the value returned 
                // from the server
               
                //scomponent.set("v.showSpinner",false);
                component.set("v.value",response.getReturnValue());

                // You would typically fire a event here to trigger 
                // client-side notification that the server-side 
                // action is complete
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                       
                    }
                } else {
                   
                }
            }
        });

        
        $A.enqueueAction(action);
	}
})