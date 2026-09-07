({
	fetchUserId : function(component, event, helper) {
        var action = component.get('c.fetchLoggedInUserId');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.loggedInUserId',response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                       
                    }
                } 
            }
        });
        $A.enqueueAction(action);
         var action1 = component.get('c.doGetInitData');
        action1.setCallback(this, function(response) {
            var state1 = response.getState();
            if (state1 === "SUCCESS") {
                component.set('v.authStatusOptions',response.getReturnValue().objectData.authStatusOptions);
                component.set('v.statusChangeReasonOptions',response.getReturnValue().objectData.changeReasonOptions);
            }
            else if (state1 === "ERROR") {
                var errors1 = response.getError();
                if (errors1) {
                    if (errors1[0] && errors1[0].message) {
                        
                    }
                } else {
                    
                }
            }
        });
        $A.enqueueAction(action1);
	},
})