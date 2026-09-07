({
    doInit : function(component, event, helper) {        
        var parentObjectId;
        var recordId = component.get("v.recordId");
        
        // Check if this is an edit mode (recordId exists and belongs to T_INDIV_TRAIN__c)
        if (recordId ) { 
            return;
        }
        
        // For new record mode, get context from URL parameters
        var ref = component.get("v.pageReference");
        
        if (ref && ref.state) {
            var state = ref.state;           
            var context = state.inContextOfRef;
            
            if(context && context.startsWith("1\.")){
                context = context.substring(2);
                var addressableContext = JSON.parse(window.atob(context));

                if(addressableContext && addressableContext.attributes){
                    if(addressableContext.attributes.recordId){
                        parentObjectId = addressableContext.attributes.recordId;
                    }
                }
            }
        }
        
        
        if (parentObjectId) {
            component.set("v.clientId", parentObjectId);
        }
    },
    
    handleRefresh: function(component,event,helper){
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
    }

})