({
    doInit : function(component, event, helper) {
        var parentObjectId;
        var parentObjectAPI;
        
        // Get context from URL parameters
        var ref = component.get("v.pageReference");
        var state = ref.state; 
        var context = state.inContextOfRef;
        
        if(context && context.startsWith("1\.")){
            context = context.substring(2);
            var addressableContext = JSON.parse(window.atob(context));
            if(addressableContext && addressableContext.attributes){
                if(addressableContext.attributes.recordId){
                    parentObjectId = addressableContext.attributes.recordId;
                    component.set('v.parentObjectId', parentObjectId);
                }
                if(addressableContext.attributes.objectApiName){
                    parentObjectAPI = addressableContext.attributes.objectApiName;
                    component.set('v.parentObjectAPI', parentObjectAPI);
                }
            }
        }
        
        // If we don't have values from context, use component attributes
        if(!parentObjectId){
            parentObjectId = component.get("v.recordId");
            if(parentObjectId){
                component.set('v.parentObjectId', parentObjectId);
            }
        }
        
        if(!parentObjectAPI){
            parentObjectAPI = component.get("v.sObjectName");
            if(parentObjectAPI){
                component.set('v.parentObjectAPI', parentObjectAPI);
            }
        }
        
        // Special handling for T_ADJMT_PMT__c
        if(parentObjectAPI === 'T_ADJMT_PMT__c' && !parentObjectId){
            component.set("v.parentObjectId", "DUMMY_ID_FOR_T_ADJMT_PMT");
        }
        
        // Call the LWC component's method to set the parent object values
        var timeoutId = setTimeout(function() {
            var lwcComponent = component.find("adjustmentPaymentFlowLwc");
            if(lwcComponent){
                var finalParentObjectId = component.get("v.parentObjectId");
                var finalParentObjectAPI = component.get("v.parentObjectAPI");
                
                if(finalParentObjectAPI){
                    lwcComponent.setParentObjectValues(finalParentObjectId, finalParentObjectAPI);
                }
            }
            component.set("v.initTimeoutId", null);
        }, 100);
        
        component.set("v.initTimeoutId", timeoutId);
      
    },
    
    handleRefresh : function(component, event, helper) {
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
    },
    
    handleDestroy : function(component, event, helper) {
        var timeoutId = component.get("v.initTimeoutId");
        if (timeoutId) {
            clearTimeout(timeoutId);
        }
    }
})