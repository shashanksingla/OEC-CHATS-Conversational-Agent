({
	closeModal  : function(component, event, helper){
        component.set("v.isOpen", false);
        component.set("v.childAttr",false);
    },
    closeModalAndDelete : function(component, event, helper) {
        component.set("v.isOpen", false);
    	
        var compEvent = component.getEvent("eventOnYes");
        compEvent.setParams({ "context" : true });
        compEvent.fire();
    
    }
    
})