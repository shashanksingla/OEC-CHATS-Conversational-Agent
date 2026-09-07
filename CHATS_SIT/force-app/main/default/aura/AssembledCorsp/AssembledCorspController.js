({
    doInit : function(component, event, helper) {
        
        var pageReference = component.get("v.pageReference");
        
        component.set('v.contentDocumentId',pageReference.state.c__contentDocumentId)
        
        var fireEvent = $A.get("e.lightning:openFiles");
        
        fireEvent.fire({
            recordIds: [component.get('v.contentDocumentId')]
        });
    }
})