({
	doInit : function(component, event, helper) {
        var action2 = component.get("c.fetchObjectdata");
        var pickListTypeFields ; 
        if(!$A.util.isEmpty(component.get("v.pickListTypeFields"))){
            pickListTypeFields =component.get("v.pickListTypeFields").split(';');
        }
        
       
        var componentAttributesTypes;
        if(!$A.util.isEmpty(component.get("v.componentAttributesTypes"))){
            componentAttributesTypes= component.get("v.componentAttributesTypes").split(';');
        }
       
        action2.setParams({"recordId": component.get("v.recordId"),'listOfFieldsApiNames':componentAttributesTypes,'pickListTypeFields':pickListTypeFields});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
              
                component.set("v.fieldTypes",res);
            } else {
                
            }
        });
        $A.enqueueAction(action2);
    },
})