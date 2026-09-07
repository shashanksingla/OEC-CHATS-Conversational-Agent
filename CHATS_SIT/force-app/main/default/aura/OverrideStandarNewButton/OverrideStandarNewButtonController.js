({
    showToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "",
            "type": "info",
            "message": "You are not authorized to create a new record using this button."
        });
        toastEvent.fire();
        window.history.back(); 
    }
})