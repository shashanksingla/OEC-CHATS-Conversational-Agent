({
	doInit : function(component, event, helper) {
        
		component.set("v.requestBody",'{"countyId":"'+component.get("v.recordId")+'"}');
        component.set("v.initLoaded", true);
	}
})