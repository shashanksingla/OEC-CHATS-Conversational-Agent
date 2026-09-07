({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        return true;
    },
    doInit: function(component, event, helper){
        const TTANF_Removal_Date = Date.parse($A.get("$Label.c.CP_TTANF_Removal_Date")); 
        var countyPlanRec = component.get("v.countyPlanRec");
        if(Date.parse(countyPlanRec.DTE_BEGIN_EFFEV__c) >= TTANF_Removal_Date){
            component.set("v.ttanfRemoved", true);
        }else{
            component.set("v.ttanfRemoved", false);
        }
    },
    setRequired: function(cmp){
        var countyPlanRec = cmp.get("v.countyPlanRec") || {};
        if(countyPlanRec.CCCAP_Q1__c!='Y'){
            cmp.set('v.countyPlanRec.CCCAP_Q1_1__c','');
            cmp.set('v.countyPlanRec.CCCAP_Q1_1_Other__c','');
        }
        if(countyPlanRec.CCCAP_Q2__c!='Y'){
            cmp.set('v.countyPlanRec.CCCAP_Q2_1__c','');
        }
        if(countyPlanRec.CCCAP_Q10__c!='Y'){
            cmp.set('v.countyPlanRec.CCCAP_Q10_1__c','');
            cmp.set('v.countyPlanRec.CCCAP_Q10_2__c','');
        }
        if(countyPlanRec.CCCAP_Q11__c!='Y'){
            cmp.set('v.countyPlanRec.CCCAP_Q11_1__c','');
            cmp.set('v.countyPlanRec.CCCAP_Q11_2__c','');
        }

        //CCCAP-14692
        if(countyPlanRec.CCCAP_Q3__c && countyPlanRec.CCCAP_Q3__c.indexOf('7')!=-1){
            cmp.set("v.isQ3_otherRequired", true);
        }else{
            cmp.set("v.isQ3_otherRequired", false);
        }
        if(countyPlanRec.CCCAP_Q4__c && countyPlanRec.CCCAP_Q4__c.indexOf('7')!=-1){
            cmp.set("v.isQ4_otherRequired", true);
        }else{
            cmp.set("v.isQ4_otherRequired", false);
        }
        if(countyPlanRec.CCCAP_Q8__c && countyPlanRec.CCCAP_Q8__c.indexOf('9')!=-1){
            cmp.set("v.isQ8_otherRequired", true);
        }else{
            cmp.set("v.isQ8_otherRequired", false);
        }
    }
}
)