({
	getSelectedAuth : function(component, event, helper) {
        component.set("v.selectedNonSubPayment", component.get("v.authorizationObj"));
	}
})