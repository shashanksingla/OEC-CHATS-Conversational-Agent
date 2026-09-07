({
    toastMessage: function(state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'duration': '10000',
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
        return;
    },
    
    navigateToApplnScreen : function (component, event, helper) {
        var navigationSObject = $A.get("e.force:navigateToSObject");
        navigationSObject.setParams({
            "recordId": component.get("v.recordId")
        });
        navigationSObject.fire();
    }    
})