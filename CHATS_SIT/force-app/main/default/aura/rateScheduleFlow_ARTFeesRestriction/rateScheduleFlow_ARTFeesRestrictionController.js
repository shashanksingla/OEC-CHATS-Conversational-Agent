({
    doInit: function(component, event, helper) {
        if(component.get("v.isReadOnly")) {
            if(component.get("v.fiscalRateValues.TXT_ACT_MONTH__c"))
                component.set("v.preSelectedActivityMonths", helper.reFormatMonthList(component.get("v.fiscalRateValues.TXT_ACT_MONTH__c")));
            if(component.get("v.fiscalRateValues.TXT_REG_MONTH__c"))
                component.set("v.preSelectedRegistrationMonths", helper.reFormatMonthList(component.get("v.fiscalRateValues.TXT_REG_MONTH__c")));
            if(component.get("v.fiscalRateValues.TXT_TRANS_MONTH__c"))
                component.set("v.preSelectedTransportationMonth", helper.reFormatMonthList(component.get("v.fiscalRateValues.TXT_TRANS_MONTH__c")));
        } else {
            helper.resetFieldValues(component, event, helper);
        }
    },
    
    // Stores selected Activity months into T_FISCAL_RAT_FEES__c object field
    storeActMonth: function(component, event, helper) {
        var actMon = event.getParam("value");
        if(actMon){
            var actMonString = helper.formatMonthList(actMon);
            component.set("v.fiscalRateValues.TXT_ACT_MONTH__c", actMonString);
        }
    },
    
    // Stores selected Registration months into T_FISCAL_RAT_FEES__c object field
    storeRegMonth: function(component, event, helper) {
        var regMon = event.getParam("value");
        if(regMon){
            var regMonString = helper.formatMonthList(regMon);
            component.set("v.fiscalRateValues.TXT_REG_MONTH__c", regMonString);
        }
    },
    
    // Stores selected Transportation months into T_FISCAL_RAT_FEES__c object field
    storeTransMonth: function(component, event, helper) {
        var tranMon = event.getParam("value");
        if(tranMon){
            var tranMonString = helper.formatMonthList(tranMon);
            component.set("v.fiscalRateValues.TXT_TRANS_MONTH__c", tranMonString);
        }
    }
})