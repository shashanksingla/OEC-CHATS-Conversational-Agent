public with sharing class CompareCountyRatePlanTemplateController {
    
    public List<String> keys {get ; set;}
    public List<String> tierKeys {get ; set;}
    public static String countyId {get ; set;}
    public static Boolean isvalidcompare {get ; set;}
    public static List<String>appvalues {get ; set;}
    public static List<String>subvalues {get ; set;}
    public static List<String>appvalueshome {get ; set;}
    public static List<String>subvalueshome {get ; set;}
    public static List<String>appvaluescenter {get ; set;}
    public static List<String>subvaluescenter {get ; set;}
    public static String notcontains{get ; set;}
    public static String notcontainsone{get ; set;}
    public static String notcontainstwo{get ; set;}
    public static String notcontainsthree{get ; set;}
    public static String notcontainsfour{get ; set;}
    public static String notcontainsfive{get ; set;}
    public static map<string, object> appexemptmapvalues{get ; set;}
    public static map<string, object> subexemptmapvalues{get ; set;}
    public static Map<String,Map<String,Map<String, String>>> apphomemapvalues{get ; set;}
    public static Map<String,Map<String,Map<String, String>>> subhomemapvalues{get ; set;}
    public static Map<String,Map<String,Map<String, String>>> appcentermapvalues{get ; set;}
    public static Map<String,Map<String,Map<String, String>>> subcentermapvalues{get ; set;}
    

    public CompareCountyRatePlanTemplateController(){
        keys = new List<String>{'PT', 'FT', 'FTPT', 'FTFT'};
            tierKeys = new List<String>{'T1PT', 'T1FT', 'T1FTPT','T1FTFT', 'T2PT', 'T2FT', 'T2FTPT','T2FTFT', 'T3PT', 'T3FT', 'T3FTPT','T3FTFT', 'T4PT', 'T4FT', 'T4FTPT','T4FTFT', 'T5PT', 'T5FT', 'T5FTPT','T5FTFT'};
             getCountyRatePlan();
                List<T_COUNTY_RATE__c>ListcntyRatePlanRecord;
                ListcntyRatePlanRecord = [ SELECT Id, 
                                      IDN_COUNTY__c,IDN_COUNTY__r.Name,CDE_STATUS__c,CDE_RATE_PLAN_TEMPLT__c,IND_RATE_PLAN_TEMPLT__c, DTE_BEGIN_EFFV_RATE__c,DTE_END_EFFV_RATE__c	
                                      FROM T_COUNTY_RATE__c  WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c= 'APV'AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE   ORDER BY DTE_BEGIN_EFFV_RATE__c DESC ];
        if(ListcntyRatePlanRecord.size()>0){
            isvalidcompare=true;
            appexemptmapvalues=getApprovedCntyRateAmtList();
            subexemptmapvalues=getCntyRateAmtList();
            apphomemapvalues=getApprovedCntyRateAmtHome();
            subhomemapvalues=getCntyRateAmtHome();
            appcentermapvalues=getApprovedCntyRateAmtCenter();
            subcentermapvalues= getCntyRateAmtCenter();
        }else {
            isvalidcompare=false;
        }    
                }
    
    public static T_COUNTY_RATE__c getCountyRatePlan(){
        T_COUNTY_RATE__c cntyRatePlanRec = new T_COUNTY_RATE__c();
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        cntyRatePlanRec = [ SELECT  toLabel(PAYMENT_Q1__c), PAYMENT_Q1_1__c, PAYMENT_Q1_OTHER__c, PAYMENT_Q2__c, toLabel(PAYMENT_Q3__c), PAYMENT_Q4__c, toLabel(PAYMENT_Q5__c), PAYMENT_Q5_1__c, PAYMENT_Q5_OTHER__c, 
                           toLabel(PAYMENT_Q7__c), PAYMENT_Q8__c, toLabel(PAYMENT_Q9__c), PAYMENT_Q9_1__c, toLabel(PAYMENT_Q10__c), PAYMENT_Q10_1__c, toLabel(PAYMENT_Q11__c), PAYMENT_Q11_1__c, toLabel(PAYMENT_Q11_2__c), toLabel(PAYMENT_Q11_3__c),
                           toLabel(PAYMENT_Q12__c), toLabel(PAYMENT_Q12_1__c), toLabel(PAYMENT_Q12_2__c), PAYMENT_Q12_2_OTHER__c, PAYMENT_Q13_a__c, PAYMENT_Q13_b__c,PAYMENT_Q13_c__c, PAYMENT_Q13_d__c, 
                           PAYMENT_Q13_e__c, toLabel(PAYMENT_Q13_1__c),toLabel(PAYMENT_Q13_2__c), toLabel(PAYMENT_Q14__c), PAYMENT_Q14_1__c, toLabel(PAYMENT_Q14_2__c),toLabel(PAYMENT_Q14_3__c),PAYMENT_Q14_4__c,PAYMENT_Q14_5__c, toLabel(PAYMENT_Q18__c), PAYMENT_Q18_1__c, toLabel(PAYMENT_Q18_2__c),toLabel(PAYMENT_Q18_3__c),PAYMENT_Q18_OTHER__c,
                           toLabel(RATE_TYPE__c),RT_Q2__c, RT_Q2_a__c, RT_Q2_b__c, RT_Q2_3__c, RT_Q2_c__c, RT_Q2_d__c,RT_Q2_e__c, RT_Q2_f__c, RT_Q2_g__c, PAYMENT_Q15__c, toLabel(PAYMENT_Q15_1__c), toLabel(PAYMENT_Q16__c), toLabel(CFS_Q1__c), CFS_Q1_1__c,CFS_Q1_2__c, toLabel(CFS_Q1_3__c),RT_Q1__c, CFS_Q1_4__c,toLabel(QEP_Q1__c),QEP_Q2__c,
                           toLabel(PAYMENT_Q17__c),PAYMENT_Q17_1__c,toLabel(PAYMENT_Q17_2__c),toLabel(PAYMENT_Q17_3__c),toLabel(PAYMENT_Q17_4__c),PAYMENT_Q17_OTHER__c,
                           IDN_COUNTY__c,IDN_COUNTY__r.Name,CDE_STATUS__c,CDE_RATE_PLAN_TEMPLT__c,IND_RATE_PLAN_TEMPLT__c, DTE_BEGIN_EFFV_RATE__c,DTE_END_EFFV_RATE__c,
                           toLabel(RT_Q8_1__c),toLabel(RT_Q8_2__c),toLabel(RT_Q8_3__c),toLabel(RT_Q8_4__c),
                           toLabel(RT_Q8_5__c),toLabel(RT_Q8_6__c),toLabel(RT_Q8_7__c),toLabel(RT_Q8_8__c),
                           RT_Q8_1P__c, RT_Q8_2P__c, RT_Q8_3P__c, RT_Q8_4P__c, RT_Q8_5P__c, RT_Q8_6P__c, RT_Q8_7P__c, RT_Q8_8P__c, RT_Q1_1__c,
                           toLabel(PAYMENT_Q17_1_1__c), PAYMENT_Q17_3_1__c, toLabel(PAYMENT_Q14_4_1__c),toLabel(PAYMENT_Q14_4_2__c), PAYMENT_Q14_4_3__c, PAYMENT_Q14_4_4__c
                           FROM T_COUNTY_RATE__c
                           WHERE Id =: countyRatePlanId //'a0sg0000003grvrAAA' //'a0sg0000003gFuHAAU'  //'a0sg0000003HQmeAAG'
                          ];
        
        countyId = cntyRatePlanRec.IDN_COUNTY__c;
        system.debug(countyId);
        return cntyRatePlanRec;
    }
    
    public static T_COUNTY_RATE__c getApprovedCountyRatePlan(){
        T_COUNTY_RATE__c cntyRatePlanRecord = new T_COUNTY_RATE__c();
        cntyRatePlanRecord = [ SELECT Id,toLabel(PAYMENT_Q1__c), PAYMENT_Q1_1__c, PAYMENT_Q1_OTHER__c, PAYMENT_Q2__c, toLabel(PAYMENT_Q3__c), PAYMENT_Q4__c, toLabel(PAYMENT_Q5__c), PAYMENT_Q5_1__c, PAYMENT_Q5_OTHER__c, 
                              toLabel(PAYMENT_Q7__c), PAYMENT_Q8__c, toLabel(PAYMENT_Q9__c), PAYMENT_Q9_1__c, toLabel(PAYMENT_Q10__c), PAYMENT_Q10_1__c, toLabel(PAYMENT_Q11__c), PAYMENT_Q11_1__c, toLabel(PAYMENT_Q11_2__c), toLabel(PAYMENT_Q11_3__c),
                              toLabel(PAYMENT_Q12__c), toLabel(PAYMENT_Q12_1__c), toLabel(PAYMENT_Q12_2__c), PAYMENT_Q12_2_OTHER__c, PAYMENT_Q13_a__c, PAYMENT_Q13_b__c,PAYMENT_Q13_c__c, PAYMENT_Q13_d__c, 
                              PAYMENT_Q13_e__c, toLabel(PAYMENT_Q13_1__c),toLabel(PAYMENT_Q13_2__c), toLabel(PAYMENT_Q14__c), PAYMENT_Q14_1__c, toLabel(PAYMENT_Q14_2__c),toLabel(PAYMENT_Q14_3__c),PAYMENT_Q14_4__c,PAYMENT_Q14_5__c, toLabel(PAYMENT_Q18__c), PAYMENT_Q18_1__c, toLabel(PAYMENT_Q18_2__c),toLabel(PAYMENT_Q18_3__c),PAYMENT_Q18_OTHER__c,
                              toLabel(RATE_TYPE__c),RT_Q2__c, RT_Q2_a__c, RT_Q2_b__c, RT_Q2_3__c, RT_Q2_c__c, RT_Q2_d__c,RT_Q2_e__c, RT_Q2_f__c, RT_Q2_g__c, PAYMENT_Q15__c, toLabel(PAYMENT_Q15_1__c), toLabel(PAYMENT_Q16__c), toLabel(CFS_Q1__c), CFS_Q1_1__c, CFS_Q1_2__c, toLabel(CFS_Q1_3__c), CFS_Q1_4__c,RT_Q1__c,toLabel(QEP_Q1__c),QEP_Q2__c, 
                              toLabel(PAYMENT_Q17__c),PAYMENT_Q17_1__c,toLabel(PAYMENT_Q17_2__c),toLabel(PAYMENT_Q17_3__c),toLabel(PAYMENT_Q17_4__c),PAYMENT_Q17_OTHER__c,
                              IDN_COUNTY__c,IDN_COUNTY__r.Name,CDE_STATUS__c,CDE_RATE_PLAN_TEMPLT__c,IND_RATE_PLAN_TEMPLT__c, DTE_BEGIN_EFFV_RATE__c,DTE_END_EFFV_RATE__c,
                              toLabel(RT_Q8_1__c),toLabel(RT_Q8_2__c),toLabel(RT_Q8_3__c),toLabel(RT_Q8_4__c),
                              toLabel(RT_Q8_5__c),toLabel(RT_Q8_6__c),toLabel(RT_Q8_7__c),toLabel(RT_Q8_8__c),
                              RT_Q8_1P__c, RT_Q8_2P__c, RT_Q8_3P__c, RT_Q8_4P__c, RT_Q8_5P__c, RT_Q8_6P__c, RT_Q8_7P__c, RT_Q8_8P__c, RT_Q1_1__c,
                              toLabel(PAYMENT_Q17_1_1__c), PAYMENT_Q17_3_1__c, toLabel(PAYMENT_Q14_4_1__c),toLabel(PAYMENT_Q14_4_2__c), PAYMENT_Q14_4_3__c, PAYMENT_Q14_4_4__c
                              FROM T_COUNTY_RATE__c
                              WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c= 'APV'AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE   ORDER BY DTE_BEGIN_EFFV_RATE__c DESC LIMIT 1 ];
        return cntyRatePlanRecord;
    }
    
    public static map<String, object> getCntyRateAmtList(){ 
        subvalues=new List<String>();
        List<T_COUNTY_RATE_AMT__c> cntyRateAmtList = new List<T_COUNTY_RATE_AMT__c>();
        map<string, map<string, decimal>> exemptRateMap1 = new map<string, map<string, decimal>>();
        
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        cntyRateAmtList = [SELECT toLabel(CDE_RATE_TYPE__c) , CDE_AGE_GROUP__c, CDE_UNIT__c, CDE_TIER__c,  NBR_AMOUNT__c, CDE_PROVR_TYPE__c 
                           FROM T_COUNTY_RATE_AMT__c 
                           WHERE CDE_PROVR_TYPE__c = 'EXE' AND IDN_COUNTY_RATE__c =:countyRatePlanId AND (CDE_AGE_GROUP__c = '7' or CDE_AGE_GROUP__c = '8') 
                           ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c , CDE_UNIT__c];
        
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
         for (String valueone : exemptRateMap1.keySet()){
            subvalues.add(valueone);
            }
        getappandsubvalues();
        
        return exemptRateMap1;
    }
    
    public static map<String, object> getApprovedCntyRateAmtList(){ 
        appvalues=new List<String>();
        List<T_COUNTY_RATE_AMT__c> ApprovedcntyRateAmtList = new List<T_COUNTY_RATE_AMT__c>();
        map<string, map<string, decimal>> exemptRateMap2 = new map<string, map<string, decimal>>();
        T_COUNTY_RATE__c cntyRatePlanRecord2 = new T_COUNTY_RATE__c();
        cntyRatePlanRecord2 = [SELECT Id
                               FROM T_COUNTY_RATE__c
                               WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c= 'APV'AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE  ORDER BY DTE_BEGIN_EFFV_RATE__c DESC LIMIT 1
                              ];
        ApprovedcntyRateAmtList = [SELECT toLabel(CDE_RATE_TYPE__c) , CDE_AGE_GROUP__c, CDE_UNIT__c, CDE_TIER__c,  NBR_AMOUNT__c, CDE_PROVR_TYPE__c,IDN_COUNTY_RATE__r.Id,IDN_COUNTY_RATE__c 
                                   FROM T_COUNTY_RATE_AMT__c 
                                   WHERE CDE_PROVR_TYPE__c = 'EXE' AND IDN_COUNTY_RATE__r.Id =:cntyRatePlanRecord2.Id AND (CDE_AGE_GROUP__c = '7' or CDE_AGE_GROUP__c = '8') 
                                   ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c , CDE_UNIT__c];
        
        String ApprovedtempRateType = '';
        String ApprovedtempAgeGroup = '';
        String ApprovedexemptAgeGroup;
        map<string, decimal> ApprovedamountsMap = new map<string, decimal>{'PT' => 0.0, 'FT' => 0.0, 'FTPT' =>0.0, 'FTFT' => 0.0};
        for(T_COUNTY_RATE_AMT__c ApprovedCountyRateAmt : ApprovedcntyRateAmtList){
            // Map initialization based on Rate type and AgeGroup (new Row)
            if(ApprovedtempRateType != ApprovedCountyRateAmt.CDE_RATE_TYPE__c ){
                ApprovedamountsMap = new map<string, decimal>{'FT' => 0.0, 'PT' => 0.0, 'FTPT' =>0.0, 'FTFT' => 0.0};
                    }else if((ApprovedtempRateType == ApprovedCountyRateAmt.CDE_RATE_TYPE__c) && (ApprovedtempAgeGroup != ApprovedCountyRateAmt.CDE_AGE_GROUP__c)){
                        ApprovedamountsMap = new map<string, decimal>{'FT' => 0.0, 'PT' => 0.0, 'FTPT' =>0.0, 'FTFT' => 0.0};          
                            }
            // Check unit care and assign to proper map
            if((ApprovedCountyRateAmt.CDE_UNIT__c == '2') && (ApprovedCountyRateAmt.CDE_TIER__c == '1')){
                ApprovedamountsMap.put('PT', ApprovedCountyRateAmt.NBR_AMOUNT__c );
            } else if((ApprovedCountyRateAmt.CDE_UNIT__c == '3') && (ApprovedCountyRateAmt.CDE_TIER__c == '1')){
                ApprovedamountsMap.put('FT', ApprovedCountyRateAmt.NBR_AMOUNT__c );
            } else if((ApprovedCountyRateAmt.CDE_UNIT__c == '4') && (ApprovedCountyRateAmt.CDE_TIER__c == '1')){
                ApprovedamountsMap.put('FTPT', ApprovedCountyRateAmt.NBR_AMOUNT__c );
            } else if((ApprovedCountyRateAmt.CDE_UNIT__c == '5') && (ApprovedCountyRateAmt.CDE_TIER__c == '1')){
                ApprovedamountsMap.put('FTFT', ApprovedCountyRateAmt.NBR_AMOUNT__c );
            }
            ApprovedexemptAgeGroup='';
            if(ApprovedCountyRateAmt.CDE_AGE_GROUP__c == '7') {
                ApprovedexemptAgeGroup = Label.X5_Years;
            } else if(ApprovedCountyRateAmt.CDE_AGE_GROUP__c == '8') {
                ApprovedexemptAgeGroup = Label.X5_Years_Less;
            }
            exemptRateMap2.put(ApprovedCountyRateAmt.CDE_RATE_TYPE__c+' '+ApprovedexemptAgeGroup, ApprovedamountsMap); //(string)eachCountyRateAmt.get('exemptAgeGroup')
            ApprovedtempRateType = ApprovedCountyRateAmt.CDE_RATE_TYPE__c;
            ApprovedtempAgeGroup = ApprovedCountyRateAmt.CDE_AGE_GROUP__c;
        }
        for (String value : exemptRateMap2.keySet()){
            appvalues.add(value);
            }
      
        return exemptRateMap2;
        
    }
    
    public static void getappandsubvalues(){
       List<String>notcontainslist=new List<String>();
       List<String>notcontainslistone=new List<String>();
        for(string av:appvalues){
            if(!subvalues.contains(av)){
                  notcontainslist.add(av);
                     }
        }
        system.debug(notcontainslist);
        if(!notcontainslist.isempty()){
        notcontains=String.join(notcontainslist, ';');
        }  
        else{
            notcontains=' ';
        }
         for(string sv:subvalues){
            if(!appvalues.contains(sv)){
                  notcontainslistone.add(sv);
                     }
        }
        if(!notcontainslistone.isempty()){
        notcontainsone=String.join(notcontainslistone, ';'); 
        }
        else{
            notcontainsone=' ';
        } 
    }

    public static Map<String,Map<String,Map<String, String>>> getCntyRateAmtCenter(){
        subvaluescenter=new List<String>();
        Map<String,Map<String,Map<String, String>>> centerRateMap = new Map<String,Map<String,Map<String, String>>>();
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        for(T_COUNTY_RATE_AMT__c eachCntyRateAmtCenter : [SELECT toLabel(CDE_RATE_TYPE__c) , CDE_TIER__c, toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c), NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:countyRatePlanId AND  CDE_PROVR_TYPE__c = 'CEN' ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c, CDE_TIER__c ]){
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
        for (String valuefour : centerRateMap.keySet()){
            subvaluescenter.add(valuefour);
            }
         getappandsubvaluescenter();
        return centerRateMap;
    }
     public static Map<String,Map<String,Map<String, String>>> getApprovedCntyRateAmtCenter(){
         appvaluescenter=new List<String>();
        Map<String,Map<String,Map<String, String>>> ApprovedcenterRateMap = new Map<String,Map<String,Map<String, String>>>();
         T_COUNTY_RATE__c cntyRatePlanRecord3 = new T_COUNTY_RATE__c();
        cntyRatePlanRecord3 = [SELECT Id
                               FROM T_COUNTY_RATE__c
                               WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c= 'APV'AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE ORDER BY DTE_BEGIN_EFFV_RATE__c DESC LIMIT 1
                              ];
         system.debug(cntyRatePlanRecord3.Id);
        
        for(T_COUNTY_RATE_AMT__c ApprovedeachCntyRateAmtCenter : [SELECT toLabel(CDE_RATE_TYPE__c) , CDE_TIER__c, toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c), NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__r.Id =:cntyRatePlanRecord3.Id AND  CDE_PROVR_TYPE__c = 'CEN' ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c, CDE_TIER__c ]){
            Map<String,Map<String, String>> ApprovedtempMap;
            if(ApprovedcenterRateMap.containsKey(ApprovedeachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+ApprovedeachCntyRateAmtCenter.CDE_AGE_GROUP__c)){
                ApprovedtempMap = ApprovedcenterRateMap.get(ApprovedeachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+ApprovedeachCntyRateAmtCenter.CDE_AGE_GROUP__c);
            }else{
                ApprovedtempMap = new Map<String,Map<String, String>>();
            }
            Map<String, String> ApprovedtempMap2;
            if(ApprovedtempMap.containsKey(ApprovedeachCntyRateAmtCenter.CDE_TIER__c)){
                ApprovedtempMap2 = ApprovedtempMap.get(ApprovedeachCntyRateAmtCenter.CDE_TIER__c);
            }else{
                ApprovedtempMap2 = new Map<String, String>();
            }
            ApprovedtempMap2.put(ApprovedeachCntyRateAmtCenter.CDE_UNIT__c,ApprovedeachCntyRateAmtCenter.NBR_AMOUNT__c+'');
            ApprovedtempMap.put(ApprovedeachCntyRateAmtCenter.CDE_TIER__c,ApprovedtempMap2);
            ApprovedcenterRateMap.put(ApprovedeachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+ApprovedeachCntyRateAmtCenter.CDE_AGE_GROUP__c,ApprovedtempMap);
        }
         for (String valuethree : ApprovedcenterRateMap.keySet()){
            appvaluescenter.add(valuethree);
            }
        return ApprovedcenterRateMap;
    }
    public static void getappandsubvaluescenter(){
       List<String>nconlist=new List<String>();
       List<String>nconlistone=new List<String>();
        for(string av:appvaluescenter){
            if(!subvaluescenter.contains(av)){
                  nconlist.add(av);
                     }
        }
        system.debug(nconlist);
        if(!nconlist.isempty()){
        notcontainsfour=String.join(nconlist, ';');
        }
        else{
            notcontainsfour=' ';
        }
         for(string sv:subvaluescenter){
            if(!appvaluescenter.contains(sv)){
                  nconlistone.add(sv);
                     }
        }
        if(!nconlistone.isempty()){
        notcontainsfive=String.join(nconlistone, ';'); 
        }
        else{
            notcontainsfive=' ';
        }
    }
    
    
    public static Map<String,Map<String,Map<String, String>>> getCntyRateAmtHome(){
        subvalueshome=new List<String>();
        Map<String,Map<String,Map<String, String>>> homeRateMap = new Map<String,Map<String,Map<String, String>>>();
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        for(T_COUNTY_RATE_AMT__c eachCntyRateAmtCenter : [SELECT toLabel(CDE_RATE_TYPE__c) , CDE_TIER__c, toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c), NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:countyRatePlanId AND  CDE_PROVR_TYPE__c = 'HOM' ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c, CDE_TIER__c ]){
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
        for (String valuetwo : homeRateMap.keySet()){
            subvalueshome.add(valuetwo);
            }
        getappandsubvalueshome();
        return homeRateMap;
    }
    public static Map<String,Map<String,Map<String, String>>> getApprovedCntyRateAmtHome(){
        appvalueshome=new List<String>();
        Map<String,Map<String,Map<String, String>>> ApprovedhomeRateMap = new Map<String,Map<String,Map<String, String>>>();
        T_COUNTY_RATE__c cntyRatePlanRecord4 = new T_COUNTY_RATE__c();
        cntyRatePlanRecord4 = [SELECT Id
                               FROM T_COUNTY_RATE__c
                               WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c= 'APV'AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE ORDER BY DTE_BEGIN_EFFV_RATE__c DESC LIMIT 1
                              ];
         system.debug(cntyRatePlanRecord4.Id);
        
        
        
        for(T_COUNTY_RATE_AMT__c ApprovedeachCntyRateAmtCenter : [SELECT toLabel(CDE_RATE_TYPE__c) , CDE_TIER__c, toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c), NBR_AMOUNT__c, CDE_PROVR_TYPE__c FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:cntyRatePlanRecord4.Id AND  CDE_PROVR_TYPE__c = 'HOM' ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c, CDE_TIER__c ]){
            Map<String,Map<String, String>>ApprovedtempMap;
            if(ApprovedhomeRateMap.containsKey(ApprovedeachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+ApprovedeachCntyRateAmtCenter.CDE_AGE_GROUP__c)){
                ApprovedtempMap = ApprovedhomeRateMap.get(ApprovedeachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+ApprovedeachCntyRateAmtCenter.CDE_AGE_GROUP__c);
            }else{
                ApprovedtempMap = new Map<String,Map<String, String>>();
            }
            Map<String, String> ApprovedtempMap2;
            if(ApprovedtempMap.containsKey(ApprovedeachCntyRateAmtCenter.CDE_TIER__c)){
                ApprovedtempMap2 = ApprovedtempMap.get(ApprovedeachCntyRateAmtCenter.CDE_TIER__c);
            }else{
                ApprovedtempMap2 = new Map<String, String>();
            }
            ApprovedtempMap2.put(ApprovedeachCntyRateAmtCenter.CDE_UNIT__c,ApprovedeachCntyRateAmtCenter.NBR_AMOUNT__c+'');
            ApprovedtempMap.put(ApprovedeachCntyRateAmtCenter.CDE_TIER__c,ApprovedtempMap2);
            ApprovedhomeRateMap.put(ApprovedeachCntyRateAmtCenter.CDE_RATE_TYPE__c+' '+ApprovedeachCntyRateAmtCenter.CDE_AGE_GROUP__c,ApprovedtempMap);
        }
        for (String valuethree : ApprovedhomeRateMap.keySet()){
            appvalueshome.add(valuethree);
            }
        return ApprovedhomeRateMap;
    }
    
    public static void getappandsubvalueshome(){
       List<String>nocontlist=new List<String>();
       List<String>nocontlistone=new List<String>();
        for(string av:appvalueshome){
            if(!subvalueshome.contains(av)){
                  nocontlist.add(av);
                     }
        }
        system.debug(nocontlist);
        if(!nocontlist.isempty()){
        notcontainstwo=String.join(nocontlist, ';');
        }
        else{
            notcontainstwo=' ';
        }
         for(string sv:subvalueshome){
            if(!appvalueshome.contains(sv)){
                  nocontlistone.add(sv);
                     }
        }
        if(!nocontlistone.isempty()){
        notcontainsthree=String.join(nocontlistone, ';');
        }
        else{
            notcontainsthree=' ';
        }
    }
    
    @auraEnabled
    public static boolean getJsActivated(){
        boolean jsActivated = false;
        Id countyRatePlanId = apexpages.currentpage().getparameters().get('countyRatePlanId');
        T_COUNTY_RATE__c cntyPlanRec = new T_COUNTY_RATE__c();
        cntyPlanRec = [SELECT  Id,DTE_BEGIN_EFFV_RATE__c,IND_RATE_PLAN_TEMPLT__c FROM T_COUNTY_RATE__c WHERE Id =:countyRatePlanId];
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
}