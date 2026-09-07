({
    doInit : function(component, event, helper) {

        var actions= component.get("c.getWebserviceStatus");
        actions.setCallback(this,function(response){
            var respMap = response.getReturnValue();
            component.set('v.dataMap',respMap);
            component.set("v.showSpinner",false);
            console.log('-----'+JSON.stringify(respMap));
            
            helper.generateChart(component,'devStatus',respMap.dev_status);
            helper.generateChart(component,'ciStatus',respMap.ci_status);
            helper.generateChart(component,'sitStatus',respMap.sit_status);
            helper.generateChart(component,'pltStatus',respMap.sit_status);
            
        });
        $A.enqueueAction(actions);
        
    }
})