({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        return true;
    },
    setRequired : function(cmp){
            var countyPlanRec = cmp.get("v.countyPlanRec") || {};
            if(!$A.util.isEmpty(countyPlanRec.PI_Q11__c) && countyPlanRec.PI_Q11__c.indexOf('3')!=-1){
                cmp.set("v.isQ11_1Required", true);
            }else{
                cmp.set("v.isQ11_1Required", false);
                cmp.set('v.countyPlanRec.PI_Q11_1_new__c','');//CCCAP-14327
                cmp.set('v.countyPlanRec.PI_Q11_1__c','');
                cmp.set("v.isQ11OtherRequired", false);
            }

            if(!$A.util.isEmpty(countyPlanRec.PI_Q11__c) && countyPlanRec.PI_Q11__c.indexOf('2')!=-1){
                cmp.set("v.isQ11_2Required", true);
            }else{
                cmp.set("v.isQ11_2Required", false);
                cmp.set('v.countyPlanRec.PI_Q11_2__c','');
            }

            if(!$A.util.isEmpty(countyPlanRec.PI_Q11__c) && countyPlanRec.PI_Q11__c.indexOf('4')!=-1){
                cmp.set("v.isQ11_3Required", true);
            }else{
                cmp.set("v.isQ11_3Required", false);
                cmp.set('v.countyPlanRec.PI_Q11_3__c','');
            }

            if(!$A.util.isEmpty(countyPlanRec.PI_Q11__c) && countyPlanRec.PI_Q11__c.indexOf('5')!=-1){
                cmp.set("v.isQ11_4Required", true);
            }else{
                cmp.set("v.isQ11_4Required", false);
                cmp.set('v.countyPlanRec.PI_Q11_4__c','');
            }
            if(countyPlanRec.PI_Q14__c !='4'){
                cmp.set('v.countyPlanRec.PI_Q14_1__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q3_1_new__c) && countyPlanRec.PI_Q3_1_new__c.indexOf('Other')!=-1){
                cmp.set("v.isQ3OtherReq", true);
            } else{
                cmp.set("v.isQ3OtherReq", false);
                cmp.set('v.countyPlanRec.PI_Q3_1_other__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q4_1_new__c) && countyPlanRec.PI_Q4_1_new__c.indexOf('Other')!=-1){
                cmp.set("v.isQ4OtherReq", true);
            } else{
                cmp.set("v.isQ4OtherReq", false);
                cmp.set('v.countyPlanRec.PI_Q4_1_other__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q5_new__c) && countyPlanRec.PI_Q5_new__c.indexOf('Other')!=-1){
                cmp.set("v.isQ5OtherReq", true);
            } else{
                cmp.set("v.isQ5OtherReq", false);
                cmp.set('v.countyPlanRec.PI_Q5_other__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q7_new__c) && countyPlanRec.PI_Q7_new__c.indexOf('6')!=-1){
                cmp.set("v.isQ7OtherReq", true);
            } else{
                cmp.set("v.isQ7OtherReq", false);
                cmp.set('v.countyPlanRec.PI_Q7_1__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q9_new__c) && countyPlanRec.PI_Q9_new__c.indexOf('4')!=-1){
                cmp.set("v.isQ9OtherReq", true);
            } else{
                cmp.set("v.isQ9OtherReq", false);
                cmp.set('v.countyPlanRec.PI_Q9_other__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q10_new__c) && countyPlanRec.PI_Q10_new__c.indexOf('4')!=-1){
                cmp.set("v.isQ10OtherReq", true);
            } else{
                cmp.set("v.isQ10OtherReq", false);
                cmp.set('v.countyPlanRec.PI_Q10_other__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q11__c) && countyPlanRec.PI_Q11__c.indexOf('5')!=-1){
                cmp.set("v.isQ11OtherRequired", true);
            } else{
                cmp.set("v.isQ11OtherRequired", false);
                cmp.set('v.countyPlanRec.PI_Q11_1_other__c','');
            }
            if(!$A.util.isEmpty(countyPlanRec.PI_Q13_new__c) && countyPlanRec.PI_Q13_new__c.indexOf('5')!=-1){
                cmp.set("v.isQ13OtherRequired", true);
            } else{
                cmp.set("v.isQ13OtherRequired", false);
                cmp.set('v.countyPlanRec.PI_Q13_other__c','');
            }
        }
    }
)