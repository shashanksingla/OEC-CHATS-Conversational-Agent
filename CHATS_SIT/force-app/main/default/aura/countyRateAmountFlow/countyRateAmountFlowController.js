({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getCountyRateWithCountyRateAmounts", 
                                            function(response){
                                                var countyRateWithCountyRateAmounts = response.objectData.countyRateWithCountyRateAmounts;
                                                var lstTierGroupValuetoLabel = JSON.parse(response.objectData.lstTierGroupValuetoLabel);
                                                component.set("v.lstAgeGroup",lstTierGroupValuetoLabel);
                                                var mapRateTypeValuetoLabel = JSON.parse(response.objectData.mapRateTypeValuetoLabel);
                                                component.set("v.mapRateTypes",mapRateTypeValuetoLabel);
                                                var mapStatus = component.get("v.mapStatus");
                                                component.set("v.status",mapStatus[countyRateWithCountyRateAmounts.CDE_STATUS__c]);
                                                var lstExistingCountyRateAmount = countyRateWithCountyRateAmounts.County_Rate__r;
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
                                                component.set("v.countyRatePlan",countyRateWithCountyRateAmounts);
                                            }, {"recordId":component.get("v.recordId"),"providerType":component.get("v.lstProviderType")[0]},
                                            false, null);
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
    },    
    doPrevious : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            var recordId = component.get("v.recordId");
            helper.redirectToLightningComponent("c:countyRatePlanFlow", {"recordId": recordId, "currentTabNumber" : 3});
        }
        if(currentTabNumber==2){
            helper.save(component,"HOM");  
        }else if(currentTabNumber==3){
            helper.save(component,"CEN"); 
        }
    },
    doFinish : function(component, event, helper) {
        var isValidated = helper.validate(component);
        if(isValidated){
            helper.save(component,null);
        }else{
            var appEvent = $A.get("e.c:createCountyRateValidateError");
            appEvent.setParams({ "actionType" : "validate" });
            appEvent.fire();  
        }
    },
    doHandleCustomButton : function(component, event, helper) {
        var isValidated = helper.validate(component);
        if(isValidated){
            helper.save(component,"SAVEASDRAFT");
        }else{
            var appEvent = $A.get("e.c:createCountyRateValidateError");
            appEvent.setParams({ "actionType" : "validate" });
            appEvent.fire();  
        }
    },
    doNext : function(component, event, helper) {
        var isValidated = helper.validate(component);
        if(isValidated){
            var currentTabNumber = component.get("v.currentTabNumber");
            if(currentTabNumber==1){
                helper.save(component,"CEN");  
            }else if(currentTabNumber==2){
                helper.save(component,"EXE"); 
            }
        }else{
            var appEvent = $A.get("e.c:createCountyRateValidateError");
            appEvent.setParams({ "actionType" : "validate" });
            appEvent.fire();  
        }
    },
    toggleFeedback: function(component,event,helper){
        component.set('v.showFeedback',!component.get('v.showFeedback'));
    }
    
})