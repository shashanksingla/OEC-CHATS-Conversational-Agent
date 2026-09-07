({
    doInit : function(component, event, helper) {
        var countyRatePlan = component.get("v.countyRatePlan");
        var countyRateAmount = component.get("v.countyRateAmount");
        if(countyRateAmount.CDE_UNIT__c != '3' || (countyRateAmount.CDE_RATE_TYPE__c == '1' && !countyRatePlan.IND_RATE_PLAN_TEMPLT__c && countyRateAmount.CDE_PROVR_TYPE__c != 'EXE')){
            component.set("v.readOnly",true);
        }
        let parentCRAmount = JSON.parse(JSON.stringify(countyRateAmount));
        if(countyRateAmount.CDE_UNIT__c!='3'){
            let mapCountyRateAmount = component.get('v.mapCountyRateAmount');
            let checkKey = parentCRAmount.CDE_PROVR_TYPE__c+'_'+
                parentCRAmount.CDE_RATE_TYPE__c+'_'+
                parentCRAmount.CDE_AGE_GROUP__c+'_'+
                parentCRAmount.CDE_TIER__c+'_'+'3';
            if(mapCountyRateAmount[checkKey]!=undefined){
                parentCRAmount = mapCountyRateAmount[checkKey]; 
            }
            helper.careUnitsUpdate(component,countyRateAmount,parentCRAmount);
        }else{
            var appEvent2 = $A.get("e.c:updateCountyRateForCareUnits");
            appEvent2.setParams({"countyRateAmount" : countyRateAmount});
            appEvent2.fire();
        }
    },
    
    updateRecord : function(component, event, helper) {
        var countyRateAmount = component.get("v.countyRateAmount");
        if(countyRateAmount.NBR_AMOUNT__c == undefined || countyRateAmount.NBR_AMOUNT__c == null || countyRateAmount.NBR_AMOUNT__c > 500 || countyRateAmount.NBR_AMOUNT__c < 0) {
            $A.util.addClass(component.find("amount"),"cellError");
        } else {
            $A.util.removeClass(component.find("amount"),"cellError");
        }
        countyRateAmount.NBR_AMOUNT__c = Math.round(countyRateAmount.NBR_AMOUNT__c * 100) / 100;
        component.set("v.countyRateAmount",countyRateAmount);
        var appEvent = $A.get("e.c:createCountyRateEvent");
        appEvent.setParams({ "countyRateAmount" : countyRateAmount });
        appEvent.fire();
        if(countyRateAmount.CDE_UNIT__c =='3'){
        	var appEvent2 = $A.get("e.c:updateCountyRateForCareUnits");
        	appEvent2.setParams({"countyRateAmount" : countyRateAmount});
            appEvent2.fire();
        }
    },
    
    checkDecimalPlaces : function(component, event, helper){
        var countyRateAmount = component.get("v.countyRateAmount");
        try {
            countyRateAmount.NBR_AMOUNT__c = countyRateAmount.NBR_AMOUNT__c.toString().match(/^-?\d+(?:\.\d{0,2})?/)[0];
            component.set("v.countyRateAmount",countyRateAmount);
        } catch(ex) {}
    },
    
    validateRecord : function(component, event, helper) {
        var actionType = event.getParam("actionType");
        if(actionType == "validate") {
            var countyRateAmount = component.get("v.countyRateAmount");
            if(countyRateAmount.NBR_AMOUNT__c == undefined || countyRateAmount.NBR_AMOUNT__c == null || countyRateAmount.NBR_AMOUNT__c > 500 || countyRateAmount.NBR_AMOUNT__c < 0){
                $A.util.addClass(component.find("amount"),"cellError");
            } else {
                $A.util.removeClass(component.find("amount"),"cellError");
            }
        }
    },
    
    handleCareUnitsUpdate : function(component, event, helper) {
        var countyRateAmountReceived = event.getParam("countyRateAmount");
        var countyRateAmount = component.get("v.countyRateAmount");
        helper.careUnitsUpdate(component,countyRateAmount,countyRateAmountReceived);
    }
})