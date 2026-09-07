public with sharing class countyRatePlanTemplateController {  
    
    public List<String> keys {get ; set;}
    public List<String> tierKeys {get ; set;}
    public countyRatePlanTemplateController(){
        keys = new List<String>{'PT', 'FT', 'FTPT', 'FTFT'};
        tierKeys = new List<String>{'T1PT', 'T1FT', 'T1FTPT','T1FTFT', 'T2PT', 'T2FT', 'T2FTPT','T2FTFT', 'T3PT', 'T3FT', 'T3FTPT','T3FTFT', 'T4PT', 'T4FT', 'T4FTPT','T4FTFT', 'T5PT', 'T5FT', 'T5FTPT','T5FTFT'};    
    }
    
    public static T_COUNTY_RATE__c getCountyRatePlan(){
        T_COUNTY_RATE__c cntyRatePlanRec = new T_COUNTY_RATE__c();
        
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        
        cntyRatePlanRec = [ select  toLabel(PAYMENT_Q1__c), PAYMENT_Q1_1__c, PAYMENT_Q1_OTHER__c, PAYMENT_Q2__c, toLabel(PAYMENT_Q3__c), PAYMENT_Q4__c, toLabel(PAYMENT_Q5__c), PAYMENT_Q5_1__c, PAYMENT_Q5_OTHER__c, 
									toLabel(PAYMENT_Q7__c), PAYMENT_Q8__c, toLabel(PAYMENT_Q9__c), PAYMENT_Q9_1__c, toLabel(PAYMENT_Q10__c), PAYMENT_Q10_1__c, toLabel(PAYMENT_Q11__c), PAYMENT_Q11_1__c, toLabel(PAYMENT_Q11_2__c), toLabel(PAYMENT_Q11_3__c),
                           			toLabel(PAYMENT_Q12__c), toLabel(PAYMENT_Q12_1__c), toLabel(PAYMENT_Q12_2__c), PAYMENT_Q12_2_OTHER__c, PAYMENT_Q13_a__c, PAYMENT_Q13_b__c,PAYMENT_Q13_c__c, PAYMENT_Q13_d__c, 
                           			PAYMENT_Q13_e__c, toLabel(PAYMENT_Q13_1__c),toLabel(PAYMENT_Q13_2__c), toLabel(PAYMENT_Q14__c), PAYMENT_Q14_1__c, toLabel(PAYMENT_Q14_2__c),toLabel(PAYMENT_Q14_3__c),PAYMENT_Q14_4__c,PAYMENT_Q14_5__c, toLabel(PAYMENT_Q18__c), PAYMENT_Q18_1__c, toLabel(PAYMENT_Q18_2__c),
									toLabel(RATE_TYPE__c),RT_Q2__c, RT_Q2_a__c, RT_Q2_b__c, RT_Q2_3__c, RT_Q2_c__c, RT_Q2_d__c,RT_Q2_e__c, RT_Q2_f__c, RT_Q2_g__c, PAYMENT_Q15__c, toLabel(PAYMENT_Q15_1__c), toLabel(PAYMENT_Q16__c), toLabel(CFS_Q1__c), CFS_Q1_1__c,CFS_Q1_2__c, toLabel(CFS_Q1_3__c), CFS_Q1_4__c,
                           			toLabel(PAYMENT_Q17__c),PAYMENT_Q17_1__c,toLabel(PAYMENT_Q17_2__c),toLabel(PAYMENT_Q17_3__c),toLabel(PAYMENT_Q17_4__c),PAYMENT_Q17_OTHER__c,toLabel(PAYMENT_Q18_3__c),PAYMENT_Q18_OTHER__c,RT_Q1__c,toLabel(QEP_Q1__c),toLabel(QEP_Q1_new__c),QEP_Q2__c,
									IDN_COUNTY__r.Name, DTE_BEGIN_EFFV_RATE__c, toLabel(RT_Q8_1__c),toLabel(RT_Q8_2__c),toLabel(RT_Q8_3__c),toLabel(RT_Q8_4__c),
                           			toLabel(RT_Q8_5__c),toLabel(RT_Q8_6__c),toLabel(RT_Q8_7__c),toLabel(RT_Q8_8__c),
                           			RT_Q8_1P__c, RT_Q8_2P__c, RT_Q8_3P__c, RT_Q8_4P__c, RT_Q8_5P__c, RT_Q8_6P__c, RT_Q8_7P__c, RT_Q8_8P__c, RT_Q1_1__c,
                              		toLabel(PAYMENT_Q17_1_1__c), PAYMENT_Q17_3_1__c, toLabel(PAYMENT_Q14_4_1__c),toLabel(PAYMENT_Q14_4_2__c), PAYMENT_Q14_4_3__c, PAYMENT_Q14_4_4__c
                            FROM T_COUNTY_RATE__c
                            WHERE Id =: countyRatePlanId //'a0sg0000003grvrAAA' //'a0sg0000003gFuHAAU'  //'a0sg0000003HQmeAAG'
                             ];
        return cntyRatePlanRec;
    }
    
    public static map<String, object> getCntyRateAmtList(){                                                   
        List<T_COUNTY_RATE_AMT__c> cntyRateAmtList = new List<T_COUNTY_RATE_AMT__c>();
        map<string, map<string, decimal>> exemptRateMap1 = new map<string, map<string, decimal>>();
        
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        system.debug('the cntyRateAmtList list-->1 ');
        cntyRateAmtList = [select toLabel(CDE_RATE_TYPE__c) , CDE_AGE_GROUP__c, CDE_UNIT__c, CDE_TIER__c,  NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE CDE_PROVR_TYPE__c = 'EXE' AND IDN_COUNTY_RATE__c =:countyRatePlanId AND (CDE_AGE_GROUP__c = '7' or CDE_AGE_GROUP__c = '8') ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c , CDE_UNIT__c];
        system.debug('the cntyRateAmtList list-->2 ');
        
        map<string, decimal> amountsMap = new map<string, decimal>{'PT' => 0.0, 'FT' => 0.0, 'FTPT' =>0.0, 'FTFT' => 0.0};
        String tempRateType = '';
        String tempAgeGroup = '';
        String exemptAgeGroup;
        for(T_COUNTY_RATE_AMT__c eachCountyRateAmt : cntyRateAmtList){
            
            // Map initialization based on Rate type and AgeGroup (new Row)
            if(tempRateType != eachCountyRateAmt.CDE_RATE_TYPE__c ){
                amountsMap = new map<string, decimal>{'FT' => 0.0, 'PT' => 0.0, 'FTPT' =>0.0, 'FTFT' => 0.0};
            }else if((tempRateType == eachCountyRateAmt.CDE_RATE_TYPE__c) && (tempAgeGroup != eachCountyRateAmt.CDE_AGE_GROUP__c)){
                amountsMap = new map<string, decimal>{'FT' => 0.0, 'PT' => 0.0, 'FTPT' =>0.0, 'FTFT' => 0.0};          
            }
            // Check unit care and assign to proper map
            if((eachCountyRateAmt.CDE_UNIT__c == '2') && (eachCountyRateAmt.CDE_TIER__c == '1')){
                amountsMap.put('PT', eachCountyRateAmt.NBR_AMOUNT__c );
            } else if((eachCountyRateAmt.CDE_UNIT__c == '3') && (eachCountyRateAmt.CDE_TIER__c == '1')){
                amountsMap.put('FT', eachCountyRateAmt.NBR_AMOUNT__c );
            } else if((eachCountyRateAmt.CDE_UNIT__c == '4') && (eachCountyRateAmt.CDE_TIER__c == '1')){
                amountsMap.put('FTPT', eachCountyRateAmt.NBR_AMOUNT__c );
            } else if((eachCountyRateAmt.CDE_UNIT__c == '5') && (eachCountyRateAmt.CDE_TIER__c == '1')){
                amountsMap.put('FTFT', eachCountyRateAmt.NBR_AMOUNT__c );
            }
            exemptAgeGroup='';
            if(eachCountyRateAmt.CDE_AGE_GROUP__c == '7') {
                exemptAgeGroup = Label.X5_Years;
            } else if(eachCountyRateAmt.CDE_AGE_GROUP__c == '8') {
                exemptAgeGroup = Label.X5_Years_Less;
            }
            exemptRateMap1.put(eachCountyRateAmt.CDE_RATE_TYPE__c+' '+exemptAgeGroup, amountsMap); //(string)eachCountyRateAmt.get('exemptAgeGroup')
            tempRateType = eachCountyRateAmt.CDE_RATE_TYPE__c;
            tempAgeGroup = eachCountyRateAmt.CDE_AGE_GROUP__c;
        }
        return exemptRateMap1; 
    }
    
    public static Map<String,Map<String,Map<String, String>>> getCntyRateAmtCenter(){
        Map<String,Map<String,Map<String, String>>> centerRateMap = new Map<String,Map<String,Map<String, String>>>();
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        for(T_COUNTY_RATE_AMT__c eachCntyRateAmtCenter : [select toLabel(CDE_RATE_TYPE__c) , CDE_TIER__c, toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c), NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:countyRatePlanId AND  CDE_PROVR_TYPE__c = 'CEN' ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c, CDE_TIER__c ]){
            Map<String,Map<String, String>> tempMap;
            if(centerRateMap.containsKey(eachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+eachCntyRateAmtCenter.CDE_AGE_GROUP__c)){
                tempMap = centerRateMap.get(eachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+eachCntyRateAmtCenter.CDE_AGE_GROUP__c);
            }else{
                tempMap = new Map<String,Map<String, String>>();
            }
            Map<String, String> tempMap2;
            if(tempMap.containsKey(eachCntyRateAmtCenter.CDE_TIER__c)){
                tempMap2 = tempMap.get(eachCntyRateAmtCenter.CDE_TIER__c);
            }else{
                tempMap2 = new Map<String, String>();
            }
            tempMap2.put(eachCntyRateAmtCenter.CDE_UNIT__c,eachCntyRateAmtCenter.NBR_AMOUNT__c+'');
            tempMap.put(eachCntyRateAmtCenter.CDE_TIER__c,tempMap2);
            centerRateMap.put(eachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+eachCntyRateAmtCenter.CDE_AGE_GROUP__c,tempMap);
        }
        return centerRateMap;
    }
    
    public static Map<String,Map<String,Map<String, String>>> getCntyRateAmtHome(){
        Map<String,Map<String,Map<String, String>>> homeRateMap = new Map<String,Map<String,Map<String, String>>>();
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        for(T_COUNTY_RATE_AMT__c eachCntyRateAmtCenter : [select toLabel(CDE_RATE_TYPE__c) , CDE_TIER__c, toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c), NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:countyRatePlanId AND  CDE_PROVR_TYPE__c = 'HOM' ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c, CDE_TIER__c ]){
            Map<String,Map<String, String>> tempMap;
            if(homeRateMap.containsKey(eachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+eachCntyRateAmtCenter.CDE_AGE_GROUP__c)){
                tempMap = homeRateMap.get(eachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+eachCntyRateAmtCenter.CDE_AGE_GROUP__c);
            }else{
                tempMap = new Map<String,Map<String, String>>();
            }
            Map<String, String> tempMap2;
            if(tempMap.containsKey(eachCntyRateAmtCenter.CDE_TIER__c)){
                tempMap2 = tempMap.get(eachCntyRateAmtCenter.CDE_TIER__c);
            }else{
                tempMap2 = new Map<String, String>();
            }
            tempMap2.put(eachCntyRateAmtCenter.CDE_UNIT__c,eachCntyRateAmtCenter.NBR_AMOUNT__c+'');
            tempMap.put(eachCntyRateAmtCenter.CDE_TIER__c,tempMap2);
            homeRateMap.put(eachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+eachCntyRateAmtCenter.CDE_AGE_GROUP__c,tempMap);
        }
        return homeRateMap;
    }
    
    @auraEnabled
    public static boolean getJsActivated(){
        boolean jsActivated = false;
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        T_COUNTY_RATE__c cntyPlanRec = new T_COUNTY_RATE__c();
        cntyPlanRec = [select  Id,DTE_BEGIN_EFFV_RATE__c,IND_RATE_PLAN_TEMPLT__c FROM T_COUNTY_RATE__c WHERE Id =:countyRatePlanId];
        DateTime tTANFRemovalDateTime = (DateTime)JSON.deserialize('"' + Label.CP_JS_Activation_Date + '"', DateTime.class);
        Date tTANFRemovalDate =  date.newinstance(tTANFRemovalDateTime.year(), tTANFRemovalDateTime.month(), tTANFRemovalDateTime.day());
        if (cntyPlanRec.DTE_BEGIN_EFFV_RATE__c >= tTANFRemovalDate ||cntyPlanRec.IND_RATE_PLAN_TEMPLT__c){
            jsActivated = true;
        }
        return jsActivated;
    }
    
    @auraEnabled
    public static boolean getIsDateAfter_1July2022(){
        boolean isDateAfter_1July2022 = false;
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        T_COUNTY_RATE__c cntyPlanRec = new T_COUNTY_RATE__c();
        cntyPlanRec = [SELECT Id, DTE_BEGIN_EFFV_RATE__c, IND_RATE_PLAN_TEMPLT__c FROM T_COUNTY_RATE__c WHERE Id =:countyRatePlanId];
        DateTime dt = (DateTime)JSON.deserialize('"' + Label.Date_1July2022 + '"', DateTime.class);
        Date d =  date.newinstance(dt.year(), dt.month(), dt.day());
        if (cntyPlanRec.DTE_BEGIN_EFFV_RATE__c >= d || cntyPlanRec.IND_RATE_PLAN_TEMPLT__c){
            isDateAfter_1July2022 = true;
        }
        System.debug('isDateAfter_1July2022-->'+isDateAfter_1July2022);
        return isDateAfter_1July2022;
    }
    @auraEnabled
    public static boolean getIsDateAfter_16Mar2025(){
        boolean isDateAfter_16Mar2025 = false;
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        T_COUNTY_RATE__c cntyPlanRec = new T_COUNTY_RATE__c();
        cntyPlanRec = [SELECT Id, DTE_BEGIN_EFFV_RATE__c, IND_RATE_PLAN_TEMPLT__c FROM T_COUNTY_RATE__c WHERE Id =:countyRatePlanId];
        DateTime dt = (DateTime)JSON.deserialize('"' + Label.Date_Mar2025 + '"', DateTime.class);
        Date d =  date.newinstance(dt.year(), dt.month(), dt.day());
        if (cntyPlanRec.DTE_BEGIN_EFFV_RATE__c >= d || cntyPlanRec.IND_RATE_PLAN_TEMPLT__c){
            isDateAfter_16Mar2025 = true;
        }
        return isDateAfter_16Mar2025;
    }

    public static boolean getIsDateAfter_15June2025(){
        boolean isDateAfter_15June2025=false;
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        T_COUNTY_RATE__c cntyRatePlanRec = [select  Id, DTE_BEGIN_EFFV_RATE__c FROM T_COUNTY_RATE__c WHERE Id =:countyRatePlanId LIMIT 1];
        DateTime dt = (DateTime)JSON.deserialize('"' + Label.CP_CRP_New_Changes_Date + '"', DateTime.class);
        Date d =  date.newinstance(dt.year(), dt.month(), dt.day());
        if (cntyRatePlanRec.DTE_BEGIN_EFFV_RATE__c >= d){
            isDateAfter_15June2025 = true;
        }
        return isDateAfter_15June2025;
    }
}