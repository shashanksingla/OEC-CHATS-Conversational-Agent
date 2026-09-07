({
    setReadOnly : function(component){
        let countyRatePlan = component.get("v.countyRatePlanRec") || {};
        var rateType = component.get("v.countyRatePlanRec").RATE_TYPE__c || '';
        if(rateType!= ''){
            let types = rateType.split(';');
            if(types.findIndex(val=> ['13'].includes(val))>-1) {
                component.set("v.isRT_Q2ReadOnly", false);
            } else {
                countyRatePlan.RT_Q2__c = '';
                countyRatePlan.RT_Q8_1__c = '';
                countyRatePlan.RT_Q8_1P__c = '';
                component.set("v.isRT_Q2ReadOnly", true);
            }
            if(types.findIndex(val=> ['19'].includes(val))>-1) {
                component.set("v.isRT_Q2_aReadOnly", false);
            } else {
                countyRatePlan.RT_Q2_a__c = '';                
                countyRatePlan.RT_Q8_2__c = '';
                countyRatePlan.RT_Q8_2P__c = '';
                component.set("v.isRT_Q2_aReadOnly", true);
            }
            if(types.findIndex(val=> ['25'].includes(val))>-1) {
                component.set("v.isRT_Q2_bReadOnly", false);
            } else {
                countyRatePlan.RT_Q2_b__c = '';               
                countyRatePlan.RT_Q8_3__c = '';
                countyRatePlan.RT_Q8_3P__c = '';
                component.set("v.isRT_Q2_bReadOnly", true);
            }
            if(types.findIndex(val=> ['31'].includes(val))>-1) {
                component.set("v.isRT_Q2_3ReadOnly", false);
            } else {
                countyRatePlan.RT_Q2_3__c = '';                               
                countyRatePlan.RT_Q8_4__c = '';
                countyRatePlan.RT_Q8_4P__c = '';
                component.set("v.isRT_Q2_3ReadOnly", true);
            }
            if(types.findIndex(val=> ['37'].includes(val))>-1) {
                component.set("v.isRT_Q2_cReadOnly", false);
            } else {
                countyRatePlan.RT_Q2_c__c = '';                              
                countyRatePlan.RT_Q8_5__c = '';
                countyRatePlan.RT_Q8_5P__c = '';
                component.set("v.isRT_Q2_cReadOnly", true);
            }
            if(types.findIndex(val=> ['43'].includes(val))>-1) {
                component.set("v.isRT_Q2_dReadOnly", false);
            } else {
                countyRatePlan.RT_Q2_d__c = '';                                              
                countyRatePlan.RT_Q8_6__c = '';
                countyRatePlan.RT_Q8_6P__c = '';
                component.set("v.isRT_Q2_dReadOnly", true);
            }
            if(types.findIndex(val=> ['55'].includes(val))> -1) {
                component.set("v.isRT_Q2_eReadOnly", false);
            } else {
                countyRatePlan.RT_Q2_e__c = '';                                                              
                countyRatePlan.RT_Q8_7__c = '';
                countyRatePlan.RT_Q8_7P__c = '';
                component.set("v.isRT_Q2_eReadOnly", true);
            }
            if(types.findIndex(val=> ['91'].includes(val))>-1) {
                component.set("v.isRT_Q2_fReadOnly", false);
            } else  {
                countyRatePlan.RT_Q2_f__c = '';                                              
                countyRatePlan.RT_Q8_8__c = '';
                countyRatePlan.RT_Q8_8P__c = '';
                component.set("v.isRT_Q2_fReadOnly", true);
            }
            if(types.findIndex(val=> ['55'].includes(val))>-1){
                component.set('v.disabilityIncluded',true);
            }else{
                countyRatePlan.RT_Q1__c = '';
                countyRatePlan.RT_Q1_1__c = '';
                component.set('v.disabilityIncluded',false);
            }
        }
        if(countyRatePlan.RT_Q8_1__c!='1'){
            countyRatePlan.RT_Q8_1P__c = '';
        }else if (countyRatePlan.RT_Q8_1__c!='2'){
            countyRatePlan.RT_Q2__c = '';
        }
        if(countyRatePlan.RT_Q8_2__c!='1'){
            countyRatePlan.RT_Q8_2P__c = '';
        }else if (countyRatePlan.RT_Q8_2__c!='2'){
            countyRatePlan.RT_Q2_a__c = '';
        }
        if(countyRatePlan.RT_Q8_3__c!='1'){
            countyRatePlan.RT_Q8_3P__c = '';
        }else if (countyRatePlan.RT_Q8_3__c!='2'){
            countyRatePlan.RT_Q2_b__c = '';
        }
        if(countyRatePlan.RT_Q8_4__c!='1'){
            countyRatePlan.RT_Q8_4P__c = '';
        }else if (countyRatePlan.RT_Q8_4__c!='2'){
            countyRatePlan.RT_Q2_3__c = '';
        }
        if(countyRatePlan.RT_Q8_5__c!='1'){
            countyRatePlan.RT_Q8_5P__c = '';
        }else if (countyRatePlan.RT_Q8_5__c!='2'){
            countyRatePlan.RT_Q2_c__c = '';
        }
        if(countyRatePlan.RT_Q8_6__c!='1'){
            countyRatePlan.RT_Q8_6P__c = '';
        }else if (countyRatePlan.RT_Q8_6__c!='2'){
            countyRatePlan.RT_Q2_d__c = '';
        }
        if(countyRatePlan.RT_Q8_7__c!='1'){
            countyRatePlan.RT_Q8_7P__c = '';
        }else if (countyRatePlan.RT_Q8_7__c!='2'){
            countyRatePlan.RT_Q2_e__c = '';
        }
        if(countyRatePlan.RT_Q8_8__c!='1'){
            countyRatePlan.RT_Q8_8P__c = '';
        }else if (countyRatePlan.RT_Q8_8__c!='2'){
            countyRatePlan.RT_Q2_f__c = '';
        }
        if(countyRatePlan.PAYMENT_Q17_4__c && countyRatePlan.PAYMENT_Q17_4__c.indexOf('Other')!=-1){
            component.set("v.isPAYMENT_Q17_OtherRequired", true);
        }else{
            component.set("v.isPAYMENT_Q17_OtherRequired", false);
            countyRatePlan.PAYMENT_Q17_OTHER__c = '';
        }
        if(countyRatePlan.PAYMENT_Q18_3__c && countyRatePlan.PAYMENT_Q18_3__c.indexOf('Other')!=-1){
            component.set("v.isPAYMENT_Q18_OtherRequired", true);
        }else{
            component.set("v.isPAYMENT_Q18_OtherRequired", false);
            countyRatePlan.PAYMENT_Q18_OTHER__c = '';
        }
        if(countyRatePlan.PAYMENT_Q11__c!= 'Y'){
            countyRatePlan.PAYMENT_Q11_2__c = '';
            countyRatePlan.PAYMENT_Q11_3__c = '';
        }
        if(countyRatePlan.PAYMENT_Q14_3__c!='Y' || countyRatePlan.PAYMENT_Q14__c!='Y'){
            countyRatePlan.PAYMENT_Q14_5__c = ''; 
        }
        if(countyRatePlan.PAYMENT_Q14__c!= 'Y'){
            countyRatePlan.PAYMENT_Q14_1__c = '';
            countyRatePlan.PAYMENT_Q14_2__c = '';
            countyRatePlan.PAYMENT_Q14_3__c = '';
            countyRatePlan.PAYMENT_Q14_4__c = '';
            countyRatePlan.PAYMENT_Q14_4_1__c = '';
            countyRatePlan.PAYMENT_Q14_4_2__c = '';
            countyRatePlan.PAYMENT_Q14_4_3__c = '';
            countyRatePlan.PAYMENT_Q14_4_4__c = '';
        }
        if(countyRatePlan.PAYMENT_Q15_1__c!= 'Y'){
            countyRatePlan.PAYMENT_Q15__c = '';
        }
        if(countyRatePlan.PAYMENT_Q18__c!='Y'){
            countyRatePlan.PAYMENT_Q18_1__c = '';
            countyRatePlan.PAYMENT_Q18_2__c = '';
            countyRatePlan.PAYMENT_Q18_3__c = '';
        }
        if(!$A.util.isEmpty(countyRatePlan.PAYMENT_Q14_4_1__c)){
            let dropIn = countyRatePlan.PAYMENT_Q14_4_1__c.split(';');
            if(dropIn.findIndex(val=> ['4'].includes(val))>-1){
                component.set('v.otherDropIn',true);
            }else{
                component.set('v.otherDropIn',false);
                countyRatePlan.PAYMENT_Q14_4_4__c = '';
            }
        }
        if(countyRatePlan.PAYMENT_Q14_4_2__c !='Y'){
            countyRatePlan.PAYMENT_Q14_4_3__c = '';
        }
        if(countyRatePlan.PAYMENT_Q17_3__c !='N'){
            countyRatePlan.PAYMENT_Q17_3_1__c = '';
        }
        // ADDED AS PART OF CCCAP-
        if(countyRatePlan.PAYMENT_Q13_2__c!= 'Y'){
            countyRatePlan.PAYMENT_Q13_1__c = '';
        }
        component.set('v.countyRatePlan',countyRatePlan);
    },
    
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        var isValid = true;
        isValid =this.checkHolidayAnswers(cmp);
        var rateType= cmp.get("v.countyRatePlanRec").RATE_TYPE__c;
        if(rateType!= null&& rateType!= '' && rateType!=undefined && rateType!=""){
            if(rateType.split(';').findIndex(val=>val == '1')==-1) {
                cmp.find("T_COUNTY_RATE__c-RATE_TYPE__c").set("v.message",'Regular Rate Type Cannot Be Removed');
                isValid = false;
            } else {
                cmp.find("T_COUNTY_RATE__c-RATE_TYPE__c").set("v.message",null); 
            }
        }
        return isValid;
    },
    
    checkHolidayAnswers : function(cmp){
        var isValid = true;
        var countyRatePlanRec = cmp.get("v.countyRatePlanRec")
        var countHolidays = 0;
        if(countyRatePlanRec.PAYMENT_Q13_1__c != null && countyRatePlanRec.PAYMENT_Q13_1__c != ''){
            countHolidays = countyRatePlanRec.PAYMENT_Q13_1__c.split(";").length - 1;
        }
        if(cmp.get("v.jsActivated")) {
            // Added below 'isDateAfter_1July2022' logic by Rishav for CCCAP-5944
            if(cmp.get("v.isDateAfter_1July2022")) {
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_a__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_a__c) && countyRatePlanRec.PAYMENT_Q13_a__c < 3)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_b__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_b__c) && countyRatePlanRec.PAYMENT_Q13_b__c < 3)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_c__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_c__c) && countyRatePlanRec.PAYMENT_Q13_c__c < 4)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_d__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_d__c) && countyRatePlanRec.PAYMENT_Q13_d__c < 4)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_e__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_e__c) &&  countyRatePlanRec.PAYMENT_Q13_e__c < 4)
            } else {
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_a__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_a__c) && countyRatePlanRec.PAYMENT_Q13_a__c < 2)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_b__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_b__c) && countyRatePlanRec.PAYMENT_Q13_b__c < 2)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_c__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_c__c) && countyRatePlanRec.PAYMENT_Q13_c__c < 3)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_d__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_d__c) && countyRatePlanRec.PAYMENT_Q13_d__c < 3)
                isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_e__c','Value too Low.',!$A.util.isEmpty(countyRatePlanRec.PAYMENT_Q13_e__c) &&  countyRatePlanRec.PAYMENT_Q13_e__c < 3)
            }
        } else {
            isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_a__c','Value too Low.',countyRatePlanRec.PAYMENT_Q13_a__c * 12 +countHolidays < 6)
            isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_b__c','Value too Low.',countyRatePlanRec.PAYMENT_Q13_b__c * 12 +countHolidays < 10)
            isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_c__c','Value too Low.',countyRatePlanRec.PAYMENT_Q13_c__c * 12 +countHolidays < 15)
            isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_d__c','Value too Low.',countyRatePlanRec.PAYMENT_Q13_d__c * 12 +countHolidays < 15)
            isValid = this.setMessage(cmp,'T_COUNTY_RATE__c-PAYMENT_Q13_e__c','Value too Low.',countyRatePlanRec.PAYMENT_Q13_e__c * 12 +countHolidays < 15)
        }
        return isValid;
    },
    setMessage: function(cmp,field,message,setMessage){
        if(setMessage){
            cmp.find(field).set("v.message",message);
        }else{
            cmp.find(field).set("v.message",null);
        }
        return !setMessage;
    }
})