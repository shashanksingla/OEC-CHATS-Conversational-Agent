({
    doInit : function(component, event, helper) {
        helper.getPicklistValues(component);
    },
    handleChange : function(component, event, helper) {
        
        var changeValue = event.getParam("value");
       
        component.set("v.value",changeValue);
        helper.checkValidity(component);
        
        // CHAT-2139 : aura handling to populate PAYMENT_Q9_1, PAYMENT_Q10_1, PAYMENT_Q11_1 to 0 if their respective questions are No.
        var compEvent = component.getEvent("eventOnChange");
        compEvent.setParams({ "context" : true });
        compEvent.fire();
       
    },
    highlightError : function(component, event, helper) {
		helper.checkValidity(component);
    }
})