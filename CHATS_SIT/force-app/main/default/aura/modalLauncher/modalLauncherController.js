({
    handleModalButtonClick: function(component, evt, helper) {
        if(component.get("v.callApexOrLaunchComponent").toLowerCase()=='component'){
            if(component.get("v.type").toLowerCase()=='modal'){
                helper.showComponentInModal(component);
            }else if(component.get("v.type").toLowerCase()=='redirect'){
                helper.redirectToComponent(component);
            }   
        }else{
            var apexMethodName = component.get("v.apexMethodName");
            helper.callApex(component, controllerMethod, 
                            actionParameter, successCallback);
        }
    }
})