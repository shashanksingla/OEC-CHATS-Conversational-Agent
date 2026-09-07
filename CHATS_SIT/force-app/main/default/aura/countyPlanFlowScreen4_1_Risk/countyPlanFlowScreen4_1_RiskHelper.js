({
    helperMethod : function() {

    },
    setRequired : function(cmp){
        var countyPlanRec = cmp.get("v.countyPlanRec") || {};
        if(!$A.util.isEmpty(countyPlanRec.RBRP_Q3_3__c) && countyPlanRec.RBRP_Q3_3__c!='1'){
            cmp.set('v.countyPlanRec.RBRP_Q3_3_1__c','');
            cmp.set('v.countyPlanRec.RBRP_Q3_3_2__c','');
        }
        if(!$A.util.isEmpty(countyPlanRec.RBRP_Q3_3__c) && countyPlanRec.RBRP_Q3_3__c!='2'){
            cmp.set('v.countyPlanRec.RBRP_Q3_3_3__c','');
        }
        if(!$A.util.isEmpty(countyPlanRec.RBRP_Q1_new__c) && countyPlanRec.RBRP_Q1_new__c.indexOf('3')!=-1){
            cmp.set("v.isQ1OtherRequired", true);
        } else{
            cmp.set("v.isQ1OtherRequired", false);
            cmp.set('v.countyPlanRec.RBRP_Q1_other__c','');
        }
        //CCCAP-14327
        if(countyPlanRec.RBRP_Q1_2_new__c!='Offsite'){
            cmp.set('v.countyPlanRec.RBRP_Q1_2_other__c','');
        }
        if(!$A.util.isEmpty(countyPlanRec.RBRP_Q2_1__c) && (countyPlanRec.RBRP_Q2_1__c <=0 || countyPlanRec.RBRP_Q2_1__c >10)){
            cmp.find("T_COUNTY_PLAN__c-RBRP_Q2_1__c").set("v.message","Please Provide a number between 1-10.");
        }
        else{
            cmp.find("T_COUNTY_PLAN__c-RBRP_Q2_1__c").set("v.message","");
        }
    },
    checkCustomValidations : function(cmp){
        var isValid = true;
        var countyPlanRec = cmp.get("v.countyPlanRec") || {};
        if(!$A.util.isEmpty(countyPlanRec.RBRP_Q2_1__c) && (countyPlanRec.RBRP_Q2_1__c <=0 || countyPlanRec.RBRP_Q2_1__c >10)){
            isValid = false;
        }
        return isValid;
    }
})