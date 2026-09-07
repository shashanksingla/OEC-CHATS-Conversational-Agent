({
	doInit : function(component, event, helper) {
        component.set("v.extSObject", component.get("v.sObjectName"))
        helper.getProviderHeader(component);    
    }
})