({
    showComponentInModal: function(component) {
        
        var modalBody;
        var componentName = component.get("v.componentName");//"c:revisitCountyRatePlan"
        var params = {"recordId": component.get("v.recordId")};
        if(componentName){
            $A.createComponent(componentName, params,
                               function(content, status) {
                                   if (status === "SUCCESS") {
                                       modalBody = content;
                                       component.find('overlayLib').showCustomModal({
                                           header: component.get("v.buttonLabel"),
                                           body: modalBody,
                                           showCloseButton: true,
                                           cssClass: "slds-modal_large"
                                       })
                                   }
                               });
        }
    },
    redirectToComponent: function(component) {
        var evt = $A.get("e.force:navigateToComponent");
        var componentAttributes = {
            recordId : component.get("v.recordId"),
            sObjectName : component.get("v.sObjectName")
        };
        
        if(component.get("v.recordIdAttribute")!=null && component.get("v.recordIdAttribute")!=''){
            componentAttributes[component.get("v.recordIdAttribute")] = component.get("v.recordId");
            componentAttributes['sObjectName'] = component.get("v.sObjectName");
        }
       
        
        evt.setParams({
            componentDef : component.get("v.componentName"),
            componentAttributes: componentAttributes
        });
        evt.fire();            
    },
    
    //Calling Apex class
    callApex : function(component,controllerMethod) {
        var action = component.get(controllerMethod);
        action.setParms(actionParameter);
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
            }                        
        })
    }
    
    
    
    
})