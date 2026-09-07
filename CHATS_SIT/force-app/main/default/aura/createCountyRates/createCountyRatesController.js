({
    doInit : function(component, event, helper) {
        
        var action = component.get('c.getCountyRate');
        action.setParams({"recordId":component.get("v.recordId"),
                          "providerType":component.get("v.lstProviderType")[0]
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if(returnValue!=null){
                component.set("v.countyRatePlan",returnValue);
                var mapStatus = component.get("v.mapStatus");
                component.set("v.status",mapStatus[returnValue.CDE_STATUS__c]);
                var lstExistingCountyRateAmount = returnValue.County_Rate__r;
                if(lstExistingCountyRateAmount && lstExistingCountyRateAmount.length>0){
                  
                    var mapExistingCountyRateAmount = {};
                    for(var i=0;i<lstExistingCountyRateAmount.length;i++){
                        var key = lstExistingCountyRateAmount[i].CDE_PROVR_TYPE__c+'_'+
                            lstExistingCountyRateAmount[i].CDE_RATE_TYPE__c+'_'+
                            lstExistingCountyRateAmount[i].CDE_AGE_GROUP__c+'_'+
                            lstExistingCountyRateAmount[i].CDE_TIER__c+'_'+
                            lstExistingCountyRateAmount[i].CDE_UNIT__c;
                        mapExistingCountyRateAmount[key] = lstExistingCountyRateAmount[i];
                    }      
                    component.set("v.mapExistingCountyRateAmount",mapExistingCountyRateAmount);
                }
                component.set("v.showSpinner",false);
            }else{
                component.set("v.showSpinner",false);
            }
        });
        $A.enqueueAction(action);
    },
    doNext : function(component, event, helper) {
        var isValidated = helper.validate(component);
        if(isValidated){
            var lstProviderType = component.get("v.lstProviderType");
            var tabNo = component.get("v.tabNo");
            tabNo++;
            component.set("v.tabNo",tabNo);
            component.set("v.showSpinner",true);
            helper.save(component,lstProviderType[tabNo]);
        }else{
            var appEvent = $A.get("e.c:createCountyRateValidateError");
            appEvent.setParams({ "actionType" : "validate" });
            appEvent.fire();  
        }
    },
    doBack : function(component, event, helper) {
        var isValidated = helper.validate(component);
        if(isValidated){
            var lstProviderType = component.get("v.lstProviderType");
            var tabNo = component.get("v.tabNo");
            tabNo--;
            component.set("v.tabNo",tabNo);
            component.set("v.showSpinner",true);
            helper.save(component,lstProviderType[tabNo]);
        }else{
            var appEvent = $A.get("e.c:createCountyRateValidateError");
            appEvent.setParams({ "actionType" : "validate" });
            appEvent.fire();  
        }
    },
    doSave : function(component, event, helper){
        
        var isValidated = helper.validate(component);
        if(isValidated){
            helper.save(component,null);
        }else{
            var appEvent = $A.get("e.c:createCountyRateValidateError");
            appEvent.setParams({ "actionType" : "validate" });
            appEvent.fire();  
        }
    },
    updateMapCountyRateAmount : function(component, event, helper) {
        
        var mapCountyRateAmount = component.get("v.mapCountyRateAmount");
        var countyRateAmount = event.getParam("countyRateAmount"); 
        if(countyRateAmount && countyRateAmount!=null){
            var key = countyRateAmount.CDE_PROVR_TYPE__c+'_'+
                countyRateAmount.CDE_RATE_TYPE__c+'_'+
                countyRateAmount.CDE_AGE_GROUP__c+'_'+
                countyRateAmount.CDE_TIER__c+'_'+
                countyRateAmount.CDE_UNIT__c;
            mapCountyRateAmount[key] = countyRateAmount;
        }
        var lstCountyRateAmount = event.getParam("lstCountyRateAmount"); 
        if(lstCountyRateAmount && lstCountyRateAmount.length>0){
            for(var i=0;i<lstCountyRateAmount.length;i++){
                countyRateAmount = lstCountyRateAmount[i];
                var key = countyRateAmount.CDE_PROVR_TYPE__c+'_'+
                    countyRateAmount.CDE_RATE_TYPE__c+'_'+
                    countyRateAmount.CDE_AGE_GROUP__c+'_'+
                    countyRateAmount.CDE_TIER__c+'_'+
                    countyRateAmount.CDE_UNIT__c;
                mapCountyRateAmount[key] = countyRateAmount;
            }
        }
        component.set("v.mapCountyRateAmount",mapCountyRateAmount);
    }    
})