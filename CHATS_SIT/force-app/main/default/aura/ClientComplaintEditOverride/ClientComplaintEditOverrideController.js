({
    doInit: function(component, event, helper) {
        // force:recordData loads asynchronously and triggers onRecordLoaded
    },

    onRecordLoaded: function(component, event, helper) {
        var changeType = event.getParam("changeType");
        if (changeType === "ERROR") { return; }
        component.set("v.recordLoaded", true);
    },

    handleCancel: function(component, event, helper) {
        var navService = component.find("navService");
        var pageRef = {
            type: "standard__recordPage",
            attributes: {
                recordId: component.get("v.recordId"),
                actionName: "view"
            }
        };
        navService.navigate(pageRef);
    },

    handleSaved: function(component, event, helper) {
        var navService = component.find("navService");
        var pageRef = {
            type: "standard__recordPage",
            attributes: {
                recordId: component.get("v.recordId"),
                actionName: "view"
            }
        };
        navService.navigate(pageRef);
    }
})