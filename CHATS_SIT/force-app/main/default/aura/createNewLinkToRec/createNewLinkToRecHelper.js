({
    handleSuccessHelper : function(component, event, helper) {
        component.set("v.showCreateNewLinkComponent",false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "duration":' 5000', 
            "title": "Success!",
            "type":"success",
            "message": "Your record has been successfully linked."
        });
        toastEvent.fire();
    }
})