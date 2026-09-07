({
	doInit : function(component, event, helper) {
		console.log('careDateToAuthEncmbr init-->'+JSON.stringify(component.get("v.careDateToAuthEncmbr")));
	},
	printdata : function(component, event, helper) {
		console.log('careDateToAuthEncmbr change-->'+JSON.stringify(component.get("v.careDateToAuthEncmbr")));
	},
	handleUnsavedChanges : function(component, event, helper) {
		var childComponent = component.find("calendar");
        var isInvalid=childComponent.handleUnsavedChanges();
        return isInvalid;
	}
})