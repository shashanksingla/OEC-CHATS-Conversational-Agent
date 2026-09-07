({
	doInit : function(component, event, helper) {
		var indivEligWrappers = [];
        var indivEligIdToWrapper = component.get("v.indivEligIdToWrapper");
        for(var key in indivEligIdToWrapper){
            indivEligWrappers.push(indivEligIdToWrapper[key]);
        }
        component.set("v.indivEligWrappers",indivEligWrappers);
	}
})