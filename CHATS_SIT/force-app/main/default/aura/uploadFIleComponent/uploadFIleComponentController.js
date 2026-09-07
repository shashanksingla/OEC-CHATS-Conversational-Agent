({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        if(recId.startsWith("a0w")){
            component.set("v.uLabel", "Attach File");
        }
    },
    handleUploadFinished: function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        helper.toastMessage("Success","Files uploaded successfully");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId"),
            "slideDevName": "related"
        });
        navEvt.fire();
    }
})