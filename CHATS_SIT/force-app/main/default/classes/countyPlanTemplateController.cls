public with sharing class countyPlanTemplateController {
    
    @auraEnabled
    public static T_COUNTY_PLAN__c getCountyPlan() {
        T_COUNTY_PLAN__c cntyPlanRec = new T_COUNTY_PLAN__c();
        
        Id countyPlanId = apexpages.currentpage().getparameters().get('countyPlanId');
        cntyPlanRec = [Select toLabel(CCDF_Q1__c), CCDF_Q1_OTHER__c, toLabel(CCDF_Q2__c), CCDF_Q2_OTHER__c, toLabel(CCDF_Q3__c), CCDF_Q3_OTHER__c, toLabel(CCDF_Q4__c), CCDF_Q4_OTHER__c, 			toLabel(CCDF_Q5__c), CCDF_Q5_OTHER__c,
                       toLabel(CCDF_Q6__c), CCDF_Q6_OTHER__c, toLabel(CCDF_Q7__c), CCDF_Q7_OTHER__c, toLabel(CCDF_Q8__c), CCDF_Q8_OTHER__c, toLabel(CCDF_Q9__c), CCDF_Q9_OTHER__c, toLabel(CCDF_Q10__c), CCDF_Q10_OTHER__c,
                       toLabel(CCDF_Q11__c), CCDF_Q11_OTHER__c,                                
                       toLabel(CCCAP_Q1__c), toLabel(CCCAP_Q1_1__C), CCCAP_Q1_1_Other__C, toLabel(CCCAP_Q2__c), CCCAP_Q2_1__c, toLabel(CCCAP_Q3__c), CCCAP_Q3_OTHER__c, toLabel(CCCAP_Q4__c), CCCAP_Q4_OTHER__c, CCCAP_Q5__c,  
                       toLabel(CCCAP_Q8__c), CCCAP_Q8_OTHER__c, CCCAP_Q9__c, toLabel(CCCAP_Q10__c), CCCAP_Q10_1__c,CCCAP_Q10_2__c,  toLabel(CCCAP_Q11__c), toLabel(CCCAP_Q11_1__c), CCCAP_Q11_2__c, toLabel(CCCAP_Q12__c), 
                       CCCAP_Q12_OTHER__c, CCCAP_Q13__c,
                       AF_Q1__c, AF_Q1_1__c, toLabel(AF_Q1_2__c), AF_Q1_3__c, toLabel(AF_Q1_4__c), AF_Q1_4_OTHER__c,AF_Q2__c , AF_Q2_1__c, AF_Q3__c, toLabel(AF_Q3_1__c), AF_Q3_1_OTHER__c, AF_Q4__c, AF_Q5__c,
                       ELIGIBILITY_Q1_1__c, toLabel(ELIGIBILITY_Q2__c), ELIGIBILITY_Q2_1__c, toLabel(ELIGIBILITY_Q3__c), ELIGIBILITY_Q3_1__c, ELIGIBILITY_Q4__c, toLabel(ELIGIBILITY_Q5__c), ELIGIBILITY_Q6__c,
                       ELIGIBILITY_Q7__c, toLabel(ELIGIBILITY_Q7_1__c),toLabel(ELIGIBILITY_Q7_2__c),
                       toLabel(ELIGIBILITY_Q8__c), ELIGIBILITY_Q8_1__c, toLabel(ELIGIBILITY_Q8_2__c), toLabel(ELIGIBILITY_Q8_3__c), ELIGIBILITY_Q8_4__c, toLabel(ELIGIBILITY_Q8_5__c), ELIGIBILITY_Q8_OTHER__c,
                       toLabel(ELIGIBILITY_Q9__c), toLabel(ELIGIBILITY_Q9_1__c), toLabel(ELIGIBILITY_Q9_2__c), toLabel(ELIGIBILITY_Q9_2_1__c), ELIGIBILITY_Q9_2_2__c, ELIGIBILITY_Q9_3__c, toLabel(ELIGIBILITY_Q9_4__c), ELIGIBILITY_Q9_4_2__c, ELIGIBILITY_Q9_5__c, ELIGIBILITY_Q11_1D__c,
                       toLabel(ELIGIBILITY_Q10__c), toLabel(ELIGIBILITY_Q10_1__c), ELIGIBILITY_Q10_2__c, toLabel(ELIGIBILITY_Q10_3_1__c), toLabel(ELIGIBILITY_Q10_3__c), tolabel(ELIGIBILITY_Q10_4__c), ELIGIBILITY_Q10_4_OTHER__c, toLabel(ELIGIBILITY_Q11__c), toLabel(ELIGIBILITY_Q11_1__c),  
                       
                       toLabel(CA_Q1__c), toLabel(CA_Q1_1__c), toLabel(CA_Q1_2_County__c), CA_Q1_3_N__c,toLabel(CA_Q1_22_County__c), CA_Q1_32_N__c,toLabel(CA_Q1_23_County__c), CA_Q1_33_N__c,toLabel(CA_Q1_24_County__c), CA_Q1_34_N__c,toLabel(CA_Q1_25_County__c), CA_Q1_35_N__c,
                       toLabel(CA_Q2__c), CA_Q2_1__c, CA_Q2_2__c, toLabel(CA_Q2_3__c), DTE_TMP_UNI_ACC_END_DT__c,
                       PI_Q1__c, PI_Q2__c, PI_Q3_ET__c, PI_Q3_BO__c, PI_Q3_FN__c, PI_Q3_LN__c, PI_Q3_BOFN__c, PI_Q3_BOLN__c, PI_Q3_1_EL__c, PI_Q3_1_BO__c, PI_Q3_2_EL__c, PI_Q3_2_BO__c,
                       PI_Q4_ET__c, PI_Q4_BO__c, PI_Q4_FN__c, PI_Q4_LN__c, PI_Q4_BOFN__c, PI_Q4_BOLN__c, PI_Q4_1_EL__c, PI_Q4_1_BO__c, PI_Q4_2_EL__c, PI_Q4_2_BO__c, PI_Q5__c,
                       toLabel(PI_Q6__c), toLabel(PI_Q7__c), PI_Q7_1__c, PI_Q8__c, PI_Q9__c, PI_Q10__c, toLabel(PI_Q11__c), PI_Q11_1__c, PI_Q11_2__c, PI_Q11_3__c, PI_Q11_4__c, PI_Q12__c, PI_Q13__c, toLabel(PI_Q14__c), PI_Q14_1__c, PI_Q15__c, toLabel(PI_Q16__c),  
                       PI_Q17_1__c, PI_Q17_2__c, PI_Q17_3__c, PI_Q18__c, PI_Q19__c, PI_Q19_1__c, PI_Q19_2__c, PI_Q19_3__c, PI_Q20__c, PI_Q21__c, PI_Q22__c, PI_Q23__c, PI_Q23_FN__c, PI_Q23_LN__c, PI_Q23_1__c, PI_Q24__c, PI_Q24_FN__c, PI_Q24_LN__c, PI_Q24_1__c, 
                       PI_Q25__c, PI_Q25_EL__c, PI_Q25_BO__c, PI_Q25_FN__c, PI_Q25_LN__c, PI_Q25_1__c, PI_Q26__c, PI_Q26_FN__c, PI_Q26_LN__c, PI_Q26_1__c, PI_Q27__c,
                       toLabel(PF_Q1__c), toLabel(PF_Q2__c), toLabel(PF_Q3__c), toLabel(PF_Q4__c), PF_Q4_1__c, toLabel(PF_Q5__c), toLabel(PF_Q6__c), PF_Q7_1__c,
                       toLabel(PF_Q7__c), toLabel(PF_Q8__c), toLabel(PF_Q9__c), toLabel(PF_Q10__c), PF_Q10_1__c, toLabel(PF_Q10_2__c), toLabel(PF_Q11__c), PF_Q11_1__c, 
                       toLabel(ELIGIBILITY_Q12__c), ELIGIBILITY_Q12_1__c, toLabel(ELIGIBILITY_Q13__c), ELIGIBILITY_Q13_1__c, ELIGIBILITY_Q14__c, toLabel(ELG_ATS_Q1__c), ELG_ATS_Q2__c, toLabel(PF_Q7_new__c), toLabel(ELIGIBILITY_Q20_1__c), ELIGIBILITY_Q20_other__c, toLabel(ELIGIBILITY_Q20_new__c),
                       toLabel(RBRP_Q1__c), toLabel(RBRP_Q1_1__c), RBRP_Q1_1D__c,RBRP_Q1_21A__c,RBRP_Q1_22A__c,RBRP_Q2__c,RBRP_Q3_4_1__c,RBRP_Q3_4_2__c,RBRP_Q3_4_3__c, RBRP_Q3_1_1__c, RBRP_Q3_1_2__c, RBRP_Q3_1_3__c, RBRP_Q3_2_1D__c, RBRP_Q3_2_2D__c, RBRP_Q3_2_3D__c, toLabel(RBRP_Q3_3__c), RBRP_Q3_3_1__c, RBRP_Q3_3_2__c, RBRP_Q3_3_3__c,
                       RBRP_Q3_4_2D__c, RBRP_Q3_4_31D__c, RBRP_Q3_4_32D__c, RBRP_Q3_4_33D__c, RBRP_Q3_5__c, RBRP_Q3_6__c, RBRP_Q3_6_1__c, RBRP_Q3_6_2__c, RBRP_Q3_6_3__c, RBRP_Q3_6_4__c, RBRP_Q3_7__c, RBRP_Q3_7_1__c, RBRP_Q3_7_2__c, RBRP_Q3_7_3__c,
                       toLabel(RBRP_Q1_new__c), RBRP_Q1_other__c, RBRP_Q1_2_other__c, toLabel(RBRP_Q1_2_new__c), toLabel(RBRP_Q1_1_new__c), RBRP_Q2_2__c, RBRP_Q2_1__c, CCCAP_Q14__c,
                       toLabel(CA_Q1_4__c), CA_Q1_4_other__c, toLabel(CA_Q2_new__c), toLabel(CA_Q2_1_new__c), toLabel(CA_Q2_2_County__c), CA_Q2_3_N__c, toLabel(CA_Q2_4_new__c), CA_Q2_4_other__c, toLabel(CA_Q2_5_County__c), CA_Q2_6_N__c, toLabel(CA_Q2_7_County__c), CA_Q2_8_N__c, toLabel(CA_Q2_9_County__c), CA_Q2_10_N__c, toLabel(CA_Q2_11_County__c), CA_Q2_12_N__c, CA_Q2_4__c, 
                       PI_Q3_new__c, toLabel(PI_Q3_1_new__c), PI_Q3_1_other__c, PI_Q4_new__c, toLabel(PI_Q4_1_new__c),PI_Q4_1_other__c, toLabel(PI_Q5_new__c), PI_Q5_other__c,PI_Q6_new__c, toLabel(PI_Q7_new__c),
                       toLabel(PI_Q9_new__c), PI_Q9_other__c, toLabel(PI_Q10_new__c),PI_Q10_other__c, toLabel(PI_Q11_1_new__c), PI_Q11_1_other__c, toLabel(PI_Q13_new__c), PI_Q13_other__c,
                       CDE_COUNTY__r.Name, DTE_BEGIN_EFFEV__c
                       FROM T_COUNTY_PLAN__c
                       WHERE Id =:countyPlanId //'a0pg0000004kPyNAAU'
                      ];
        return cntyPlanRec;
    }
    @auraEnabled
    public static boolean getJsActivated(){
        boolean jsActivated = false;
        DateTime jsActivationDateTime = (DateTime)JSON.deserialize('"' + Label.CP_JS_Activation_Date + '"', DateTime.class);
        Date  jsActivationDate=  date.newinstance(jsActivationDateTime.year(), jsActivationDateTime.month(), jsActivationDateTime.day()); 
        Id countyPlanId = apexpages.currentpage().getparameters().get('countyPlanId');
        T_COUNTY_PLAN__c cntyPlanRec = new T_COUNTY_PLAN__c();
        cntyPlanRec = [select  Id,DTE_BEGIN_EFFEV__c,IND_COUNTY_PLAN_TEMPLT__c FROM T_COUNTY_PLAN__c WHERE Id =:countyPlanId];
        if (cntyPlanRec.DTE_BEGIN_EFFEV__c >= jsActivationDate||cntyPlanRec.IND_COUNTY_PLAN_TEMPLT__c){
            jsActivated = true;
        }
        return jsActivated;
    }
    @auraEnabled
    public static boolean getTTANFRemoved(){
        boolean tTanfRemoved = false;
        DateTime tTANFRemovalDateTime = (DateTime)JSON.deserialize('"' + Label.CP_TTANF_Removal_Date + '"', DateTime.class);
        Date tTANFRemovalDate =  date.newinstance(tTANFRemovalDateTime.year(), tTANFRemovalDateTime.month(), tTANFRemovalDateTime.day()); 
        Id countyPlanId = apexpages.currentpage().getparameters().get('countyPlanId');
        T_COUNTY_PLAN__c cntyPlanRec = new T_COUNTY_PLAN__c();
        cntyPlanRec = [select  Id,DTE_BEGIN_EFFEV__c,IND_COUNTY_PLAN_TEMPLT__c FROM T_COUNTY_PLAN__c WHERE Id =:countyPlanId];
        if (cntyPlanRec.DTE_BEGIN_EFFEV__c >= tTANFRemovalDate||cntyPlanRec.IND_COUNTY_PLAN_TEMPLT__c ){
            tTanfRemoved = true;
        }
        return tTanfRemoved;
    }
    
    public static boolean getIsDateAfter_16Feb2025(){
        boolean isDateAfter_16Feb2025=false;
        Date beginDate= date.today();
        DateTime dt = (DateTime)JSON.deserialize('"' + Label.Date_16Feb2025 + '"', DateTime.class);
        Date d =  date.newinstance(dt.year(), dt.month(), dt.day());
		Id countyPlanId = apexpages.currentpage().getparameters().get('countyPlanId');
        T_COUNTY_PLAN__c cntyPlanRec = new T_COUNTY_PLAN__c();
        cntyPlanRec = [select  Id,DTE_BEGIN_EFFEV__c FROM T_COUNTY_PLAN__c WHERE Id =:countyPlanId];
        if (beginDate >= d && cntyPlanRec.DTE_BEGIN_EFFEV__c >= d){
            isDateAfter_16Feb2025 = true;
        }
        return isDateAfter_16Feb2025;
    }
    
    public static boolean getIsDateAfter_15June2025(){
        boolean isDateAfter_15June2025=false;
        Id countyPlanId = apexpages.currentpage().getparameters().get('countyPlanId');
        T_COUNTY_PLAN__c cntyPlanRec = [select  Id,DTE_BEGIN_EFFEV__c FROM T_COUNTY_PLAN__c WHERE Id =:countyPlanId LIMIT 1];
        DateTime dt = (DateTime)JSON.deserialize('"' + Label.CP_CRP_New_Changes_Date + '"', DateTime.class);
        Date d =  date.newinstance(dt.year(), dt.month(), dt.day());
        if (cntyPlanRec.DTE_BEGIN_EFFEV__c >= d){
            isDateAfter_15June2025 = true;
        }
        return isDateAfter_15June2025;
    }
}