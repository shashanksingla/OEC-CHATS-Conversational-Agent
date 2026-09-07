({
	handleEvent : function(component, event, helper) {
		var booleanValue = event.getParam("context");
        component.set("v.cidboolean", booleanValue);
	}
})