({
    doInit : function(component, event, helper) {
        var countyRatePlanRecord = component.get("v.countyRatePlanRec");
        var date0 = new Date(countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c);
        var beginDate = new Date(date0.getUTCFullYear(), date0.getUTCMonth(), date0.getUTCDate());
        var date1 = new Date($A.get("$Label.c.CP_JS_Activation_Date"));
        var beginDate1 = new Date(date1.getUTCFullYear(), date1.getUTCMonth(), date1.getUTCDate());
        if(beginDate >= beginDate1) {
            component.set("v.jsActivated", true);
        } else {
            component.set("v.jsActivated", false);
        }
        // Start: Added by Rishav for CCCAP-5944
        const date2 = new Date($A.get("$Label.c.Date_1July2022"));
        var beginDate2 = new Date(date2.getUTCFullYear(), date2.getUTCMonth(), date2.getUTCDate());
        if(beginDate >= beginDate2) {
            component.set("v.isDateAfter_1July2022", true);
        } else {
            component.set("v.isDateAfter_1July2022", false);
        }
        // End: CCCAP-5944

        // Start : Added by Raina for CCCAP-12253
        const date3 = new Date($A.get("$Label.c.Date_Mar2025"));
        var beginDate3 = new Date(date3.getUTCFullYear(), date3.getUTCMonth(), date3.getUTCDate());
        if(beginDate >= beginDate3) {
            component.set("v.isDateAfter_Mar2025", true);
        } else {
            component.set("v.isDateAfter_Mar2025", false);
        }
        // End :CCCAP-12253
        helper.setReadOnly(component);
    },

    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },

    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },

    handleChange : function(component, event, helper) {
        if(component.get("v.countyRatePlanRec.PAYMENT_Q9__c") == 'N') {
            component.set("v.countyRatePlanRec.PAYMENT_Q9_1__c", 0);    
        }
        if(component.get("v.countyRatePlanRec.PAYMENT_Q10__c") == 'N') {
            component.set("v.countyRatePlanRec.PAYMENT_Q10_1__c", 0);    
        }
        if(component.get("v.countyRatePlanRec.PAYMENT_Q11__c") == 'N') {
            component.set("v.countyRatePlanRec.PAYMENT_Q11_1__c", 0);    
        }
    },

    handleRateTypeChange : function(component, event, helper){
        let countyRate = component.get("v.countyRatePlanRec");
        var rateType= countyRate.RATE_TYPE__c || '';
        if(rateType == '' || rateType.split(';').findIndex(val=>val == '1')==-1) {
           component.find("T_COUNTY_RATE__c-RATE_TYPE__c").set("v.message",'Regular Rate Type Cannot Be Removed');
        } else {
           component.find("T_COUNTY_RATE__c-RATE_TYPE__c").set("v.message",''); 
        }
        if(rateType && rateType.split(';').findIndex(val=> ['55'].includes(val))>-1){
            component.set('v.disabilityIncluded',true);
        }else{
            component.set('v.disabilityIncluded',false);
        }
        helper.setReadOnly(component);
    },

   handleDropinRequestChange : function(component, event, helper){
        let countyRate = component.get("v.countyRatePlanRec");
        var dropIn= countyRate.PAYMENT_Q14_4_1__c || '';
        if(dropIn && dropIn.split(';').findIndex(val=> ['4'].includes(val))>-1){
            component.set('v.otherDropIn',true);
        }else{
            component.set('v.otherDropIn',false);
            countyRate.PAYMENT_Q14_4_4__c = '';
        }
        helper.setReadOnly(component);
    },

    handleSetReadOnly : function(component, event, helper){
        helper.setReadOnly(component);
    },

    handleCheckHolidayAnswers : function(component, event, helper){
        helper.checkHolidayAnswers(component);
    }
})