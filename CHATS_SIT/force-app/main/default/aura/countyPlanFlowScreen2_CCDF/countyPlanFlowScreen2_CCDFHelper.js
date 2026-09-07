({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        return true;
    },
    setRequired : function(cmp){
        var countyPlanRec = cmp.get("v.countyPlanRec") || {};
        if(countyPlanRec.CA_Q1_1__c && countyPlanRec.CA_Q1_1__c.indexOf('1')!=-1){
            cmp.set("v.isQ12_1Required", true);
        }else{
            cmp.set("v.isQ12_1Required", false);
            cmp.set("v.isQ4otherRequired", false);
            cmp.set('v.countyPlanRec.CA_Q1_2_County__c',''); //CA_Q1_2__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q1_3_N__c',''); // CA_Q1_3__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q1_4__c','');
            cmp.set('v.countyPlanRec.CA_Q1_4_other__c','');
        }
        if(!$A.util.isEmpty(countyPlanRec.CA_Q1_4__c) && countyPlanRec.CA_Q1_4__c.indexOf('3')!=-1){
            cmp.set("v.isQ4otherRequired", true);
        }
        else{
            cmp.set('v.countyPlanRec.CA_Q1_4_other__c','');
            cmp.set("v.isQ4otherRequired", false);
        }
        if(countyPlanRec.CA_Q1_1__c && countyPlanRec.CA_Q1_1__c.indexOf('2')!=-1){
            cmp.set("v.isQ12_2Required", true);
        }else{
            cmp.set("v.isQ12_2Required", false);
            cmp.set('v.countyPlanRec.CA_Q1_22_County__c',''); //CA_Q1_22__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q1_32_N__c',''); // CA_Q1_32__c for CCCAP-13426
        }

        if(countyPlanRec.CA_Q1_1__c && countyPlanRec.CA_Q1_1__c.indexOf('3')!=-1){
            cmp.set("v.isQ12_3Required", true);
        }else{
            cmp.set("v.isQ12_3Required", false);
            cmp.set('v.countyPlanRec.CA_Q1_23_County__c',''); //CA_Q1_23__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q1_33_N__c',''); // CA_Q1_33__c for CCCAP-13426
        }

        if(countyPlanRec.CA_Q1_1__c && countyPlanRec.CA_Q1_1__c.indexOf('4')!=-1){
            cmp.set("v.isQ12_4Required", true);
        }else{
            cmp.set("v.isQ12_4Required", false);
            cmp.set('v.countyPlanRec.CA_Q1_24_County__c',''); //CA_Q1_24__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q1_34_N__c',''); // CA_Q1_34__c for CCCAP-13426
        }

        if(countyPlanRec.CA_Q1_1__c && countyPlanRec.CA_Q1_1__c.indexOf('5')!=-1){
            cmp.set("v.isQ12_5Required", true);
        }else{
            cmp.set("v.isQ12_5Required", false);
            cmp.set('v.countyPlanRec.CA_Q1_25_County__c',''); // CA_Q1_25__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q1_35_N__c',''); // CA_Q1_35__c for CCCAP-13426
        }
        if(countyPlanRec.CA_Q1__c!='Y'){
            cmp.set('v.countyPlanRec.CA_Q1_1__c','');
        }
        //CCCAP-14327
        if(countyPlanRec.CA_Q2_new__c!='Y'){
            cmp.set('v.countyPlanRec.CA_Q2_1_new__c','');
        }
        if(countyPlanRec.CA_Q2__c!='Y'){
            cmp.set('v.countyPlanRec.CA_Q2_1__c','');
            cmp.set('v.countyPlanRec.CA_Q2_2__c','');
            cmp.set('v.countyPlanRec.CA_Q2_3__c','');
        }
        if(countyPlanRec.CA_Q2_3__c !='2'){
            cmp.set('v.countyPlanRec.DTE_TMP_UNI_ACC_END_DT__c','');
        }

        if(countyPlanRec.CA_Q2_1_new__c && countyPlanRec.CA_Q2_1_new__c.indexOf('1')!=-1){
            cmp.set("v.isQ2newRequired", true);
        }else{
            cmp.set("v.isQ2newRequired", false);
            cmp.set('v.countyPlanRec.CA_Q2_2_County__c',''); //CA_Q2_2_new__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q2_3_N__c',''); //CA_Q2_3_new__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q2_4_new__c','');

        }

        if(countyPlanRec.CA_Q2_4_new__c && countyPlanRec.CA_Q2_4_new__c.indexOf('3')!=-1){
            cmp.set("v.isQ2_4OtherRequired", true);
        }else{
            cmp.set("v.isQ2_4OtherRequired", false);
            cmp.set('v.countyPlanRec.CA_Q2_4_other__c','');
        }

        if(countyPlanRec.CA_Q2_1_new__c && countyPlanRec.CA_Q2_1_new__c.indexOf('2')!=-1){
            cmp.set("v.isQ2_2newRequired", true);
        }else{
            cmp.set("v.isQ2_2newRequired", false);
            cmp.set('v.countyPlanRec.CA_Q2_5_County__c',''); //CA_Q2_5_new__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q2_6_N__c',''); ////CA_Q2_6_new__c for CCCAP-13426
        }

        if(countyPlanRec.CA_Q2_1_new__c && countyPlanRec.CA_Q2_1_new__c.indexOf('3')!=-1){
            cmp.set("v.isQ2_3newRequired", true);
        }else{
            cmp.set("v.isQ2_3newRequired", false);
            cmp.set('v.countyPlanRec.CA_Q2_7_County__c',''); //CA_Q2_7_new__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q2_8_N__c',''); //CA_Q2_8_new__c for CCCAP-13426
        }

        if(countyPlanRec.CA_Q2_1_new__c && countyPlanRec.CA_Q2_1_new__c.indexOf('4')!=-1){
            cmp.set("v.isQ2_4newRequired", true);
        }else{
            cmp.set("v.isQ2_4newRequired", false);
            cmp.set('v.countyPlanRec.CA_Q2_9_County__c',''); //CA_Q2_9_new__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q2_10_N__c',''); //CA_Q2_10_new__c for CCCAP-13426
        }

        if(countyPlanRec.CA_Q2_1_new__c && countyPlanRec.CA_Q2_1_new__c.indexOf('5')!=-1){
            cmp.set("v.isQ2_5newRequired", true);
        }else{
            cmp.set("v.isQ2_5newRequired", false);
            cmp.set('v.countyPlanRec.CA_Q2_11_County__c',''); //CA_Q2_11_new__c for CCCAP-13426
            cmp.set('v.countyPlanRec.CA_Q2_12_N__c',''); //CA_Q2_12_new__c for CCCAP-13426
        }

        //CCCAP-14692
        if(countyPlanRec.CCDF_Q1__c && countyPlanRec.CCDF_Q1__c.indexOf('21')!=-1){
            cmp.set("v.isQ1_otherRequired", true);
        }else{
            cmp.set("v.isQ1_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q2__c && countyPlanRec.CCDF_Q2__c.indexOf('21')!=-1){
            cmp.set("v.isQ2_otherRequired", true);
        }else{
            cmp.set("v.isQ2_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q3__c && countyPlanRec.CCDF_Q3__c.indexOf('9')!=-1){
            cmp.set("v.isQ3_otherRequired", true);
        }else{
            cmp.set("v.isQ3_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q4__c && countyPlanRec.CCDF_Q4__c.indexOf('9')!=-1){
            cmp.set("v.isQ4_otherRequired", true);
        }else{
            cmp.set("v.isQ4_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q5__c && countyPlanRec.CCDF_Q5__c.indexOf('6')!=-1){
            cmp.set("v.isQ5_otherRequired", true);
        }else{
            cmp.set("v.isQ5_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q6__c && countyPlanRec.CCDF_Q6__c.indexOf('3')!=-1){
            cmp.set("v.isQ6_otherRequired", true);
        }else{
            cmp.set("v.isQ6_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q8__c && countyPlanRec.CCDF_Q8__c.indexOf('3')!=-1){
            cmp.set("v.isQ8_otherRequired", true);
        }else{
            cmp.set("v.isQ8_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q9__c && countyPlanRec.CCDF_Q9__c.indexOf('3')!=-1){
            cmp.set("v.isQ9_otherRequired", true);
        }else{
            cmp.set("v.isQ9_otherRequired", false);
        }
        if(countyPlanRec.CCDF_Q11__c && countyPlanRec.CCDF_Q11__c.indexOf('3')!=-1){
            cmp.set("v.isQ11_otherRequired", true);
        }else{
            cmp.set("v.isQ11_otherRequired", false);
        }
    }
}   
)