({
    
    handleSaveContact: function(component, event, helper) {
        component.find("editForm").submit();
    },
    handleSuccess: function(component, event, helper) {
        helper.handleSuccessHelper(component, event, helper);   
    },    
    doCancel: function(component, event, helper) {
        component.set("v.showCreateNewLinkComponent",false);
    }
})