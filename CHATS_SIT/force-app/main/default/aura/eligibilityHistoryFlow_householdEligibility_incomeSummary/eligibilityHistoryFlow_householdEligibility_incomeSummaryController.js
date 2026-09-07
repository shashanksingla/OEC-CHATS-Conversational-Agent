({
	doInit : function(component, event, helper) {
		var action = component.get('c.incomeSummaryfetch');
        action.setParams({"eligibilityRunId":component.get("v.eligibilityHisRunId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res =response.getReturnValue();
                if(!$A.util.isEmpty(res.objectData.errorMessage)){
                    console.log('errorMessage------'+res.objectData.errorMessage);
                    // component.set("v.recordError",);
                    component.set("v.recordError",[res.objectData.errorMessage]);
                    component.set("v.message","error");
                }else{
                    component.set('v.eligIncomeWrap',res.objectData.eligHistoryIncomeWrap);
                    component.set("v.recordError",[]);
                }
                console.log('reponse--'+JSON.stringify(res));
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