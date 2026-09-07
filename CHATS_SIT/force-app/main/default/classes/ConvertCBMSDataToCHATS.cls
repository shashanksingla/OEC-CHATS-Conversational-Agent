public with sharing  class ConvertCBMSDataToCHATS {
 
   public static LightningServerResponse converChangeReftData(T_SBSD_CASE__c caseRec,T_APPLN_PRCS_QUEUE__c appProcessQueue, List<String> individualIds,Id primaryCaretakerId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message = 'Error: ';
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ConvertCBMSDataToCHATS','Method__c'=>'convertData'};
        List<Referral_Information__c> refrenceInfoLst = new List<Referral_Information__c>();
        List<String> additionalAdultRels = new List<String>{'H', 'CLH', 'CLW', 'LIC', 'SO', 'W', 'X'}; //added for CCCAP-13633
        try{
            //Get all the picklist translation mappings
            ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
            //Logic to clone T_APPLN records to T_SBSD records  
            //
            List<SObject> lstSObjectToBeInserted = new List<SObject>();
            List<T_SBSD_INDIV__c> lstIndiv = new List<T_SBSD_INDIV__c>();
            List<T_SBSD_INDIV_INFO__c> lstIndivInfo = new List<T_SBSD_INDIV_INFO__c>();
            List<T_SBSD_INDIV_MIL__c> lstIndivMil = new List<T_SBSD_INDIV_MIL__c>();
            // added for RAPID - UFE by SS
            List<SObject> existingIndivToUpdate = new List<SObject>();
            List<T_APPLN_CASE__c> lstApplnCase = [SELECT Id,CBMS_CASE_NUM__c,IND_CW_PGM__c,IDN_CBMS_REF__c,CBMS_REF_REASON__c,IND_INTER_COUNTY_TRANSFER__c,NET_EARNED_INCOME__c,PAYMENT_MONTH__c,PRI_METHOD_OF_CON__c,PRIOR_COUNTY__c,WORK_SPECIALIST__c,
                                                  CDE_CBMS_REF_TYP__c, ADR_CITY_PROVR__c,ADR_LINE_1_PROVR__c,ADR_STATE_PROVR__c,ADR_ZIP_PROVR__c,CASE_CLOSURE_REASON__c,
                                                  CDE_LANG_CORR__c,IDN_PROVR__c,IND_ASSIST_PROVR__c,IND_ASST_HSN__c,IND_ASST_HSNG_ADDL__c,
                                                  IND_CHP__c,IND_CHP_ADDL__c,IND_FOOD_PGM__c,IND_FOOD_PGM_ADDL__c,IND_FS_RCVNG__c,
                                                  IND_FS_RCVNG_ADDL__c,IND_HEAD_START__c,IND_HEAD_START_ADDL__c,IND_IDEA_0_3__c,
                                                  IND_IDEA_0_3_ADDL__c,IND_IDEA_3_5__c,IND_IDEA_3_5_ADDL__c,IND_INCOME_FED_OTHER__c,
                                                  IND_INCOME_FED_OTHER_ADDL__c,IND_PENSION__c,IND_PENSION_ADDL__c,IND_REFUGEE__c,
                                                  IND_REFUGEE_ADDL__c,IND_SSI__c,IND_SSI_ADDL__c,IND_WIC__c,IND_WIC_ADDL__c,
                                                  LOC_ELG_DETERM__c,NAM_FACLTY_PROVR__c,NAM_FIRST_PROVR__c,NAM_LAST_PROVR__c,
                                                  IND_HAS_ASSET__c,NBR_LIQUID_AMT__c,NBR_NON_LIQUID_AMT__c,
                                                  DTE_BEGIN_HOMELESS__c,DTE_END_HOMELESS__c,IND_IS_HOMELESS__c,
                                                  IND_LEAP__c,IND_LEAP_ADDL__c,IND_LVG_CAMPGROUND__c,IND_LVG_HOTEL__c,
                                                  IND_LVG_OTHER__c,IND_LVG_SHELTER__c,IND_LVG_SUBSTANDARD__c,TXT_LVG_OTHER_CMT__c,
                                                  CDE_INFO_PMC__c, NBR_PHONE_CELL__c, NBR_PHONE_HOME__c, NBR_PHONE_MSG__c, NBR_PHONE_MSG_EXTN__c,
                                                  CDE_INFO_EM__c, DTE_RCVD_APPLN__c,UFE_Request_Flag__c,// added for RAPID - UFE by SS
                                                  (SELECT IND_TANF_RCVNG__c FROM Application_case_38__r),
                                                  (SELECT DTE_WKDAY_APPLN__c FROM Application_case_28__r)
                                                  FROM T_APPLN_CASE__c WHERE Id =: appProcessQueue.IDN_APPLN__c];
           // List<SObject> lstConvertedFromAppCase = APXPolicyRecordsServices.createPolicyRecords(lstApplnCase, false);
            List<SObject> lstCaseChildRecords = new List<SObject>();
            
            
            // Inserting Case related Info
            Referral_Information__c cseInfoObj = new Referral_Information__c();
            
            


            // Getting Referral Type
            String referralType = caseRec.CDE_CBMS_REF_TYP__c;
           Map<String, T_SBSD_CASE_INDIV__c> mapExistingCaseIndiv = new Map<String, T_SBSD_CASE_INDIV__c>();
            if(caseRec != null){
               for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id,IDN_CASE__c,IDN_CLIENT__r.IDN_STATE__c, Individual_Status__c, IND_CRTKR__c 
                                                          FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :caseRec.id]){
                        mapExistingCaseIndiv.put(caseIndiv.IDN_CLIENT__r.IDN_STATE__c, caseIndiv);
                    } 
            }
           
            
            List<T_APPLN_INDIV__c> lstApplnIndiv = [SELECT Id, CDE_GENDER__c,CBMS_DENIAL_REASON__c,CDE_SOURCE_VRFYD_CITIZEN__c,CDE_VRFYD_CITIZEN__c,IDN_CBMS_CLIENT__c,IND_IPV__c,ROADMAP_CORR_ID__c,
                                                    CDE_LEVEL_GRADE_HGHST__c,
                                                    CDE_STATUS_MAR__c,
                                                    DTE_DOB__c,
                                                    DTE_Death__c,// added for SIDMOD CCCAP-7695 by Shashank
                                                    IND_NOTIF_SIDMOD__c, // added for SIDMOD CCCAP-10315 by Shashank
                                                    IDN_STATE__c,
                                                    NAM_FIRST__c,
                                                    NAM_LAST__c,
                                                    NAM_MI__c,
                                                    NBR_SSN__c,
                                                    CDE_INFO_CS__c,
                                                    IND_CTZN__c,
                                                    CDE_STATUS_MIL__c,
                                                    IND_CRTKR_PRIM__c,
                                                    IDN_SEQ_INDIV__c,
                                                    ( SELECT Id,
                                                     ADR_CITY__c,
                                                     ADR_LINE_1__c,
                                                     ADR_LINE_2__c,
                                                     ADR_STATE__c,
                                                     ADR_ZIP_EXTN__c,
                                                     ADR_ZIP_MAIN__c,
                                                     CDE_TYPE_ADR__c,
                                                     ADR_NAM__c
                                                     FROM Application_Addresses__r
                                                    ),
                                                    (SELECT CDE_RACE__c,CDE_ETNCTY__c FROM Application_Race_Information__r),
                                                    (SELECT id,CDE_TYPE_ACTV__c,DTE_BEGIN_ACTV_PRIM__c,DTE_END_ACTV_PRIM__c,External_ID__c,IDN_INDIVIDUAL__c FROM Application_Activities__r),
                                                    (SELECT id,IDN_INDIVIDUAL__c,IND_NEED_CHILD_CARE__c,NAM_FACILITY__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c,
                                                    CHILD_NAME__c,CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,CNT_HOUR_ON_FRI__c,IDN_CBMS_PROVR__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,
                                                    DTE_WITH_LAST_PROVIDER__c,IND_PROVIDER_CHANGE__c,IND_SCHOOL_AGE_CARE__c FROM Application_Child_Cares__r),
                                                    (SELECT DTE_BEGIN_EFFV__c FROM Application_Job_Search__r),
                                                    (SELECT Id, CDE_TYPE_REL_INDIV__c, IDN_APPLN_REL__c, IDN_SEQ_INDIV_RELTD__c
                                                     FROM Application_Relationships__r
                                                    )
                                                    FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c AND Id IN:individualIds];
            Set<String> setDOB_SSN = new Set<String>();
            Map<String, String> mapStateIdWithPrimaryCaretaker = new Map<String, String>();
            Map<String, T_APPLN_INDIV__c> mapStateIdWithAppIndiv = new Map<String, T_APPLN_INDIV__c>();
            List<T_APPLN_ADR__c> lstAppAdr = new List<T_APPLN_ADR__c>();
            Map<String,T_SBSD_CASE_INDIV__c> mapCaseIndividual = new Map<String,T_SBSD_CASE_INDIV__c>();
            Map<String,T_SBSD_INDIV_INFO__c> mapIndividualInformation = new Map<String,T_SBSD_INDIV_INFO__c>();
	    set<String> roadmapCorrIdSet = new Set<String>();
            Map<String,T_SBSD_ROADMAP_CORR_ID__c> mapindivStateIdToRoadmapCorr = new Map<String,T_SBSD_ROADMAP_CORR_ID__c>();
            List<T_SBSD_ROADMAP_CORR_ID__c> lstOfexistingRoadmapIds = new List<T_SBSD_ROADMAP_CORR_ID__c>();
            Map<String,String> mapOfExstngRoadmapIds = new Map<String,String>();
            List<T_APPLN_INDIV__c> lstApplnIndivToBeConverted = new List<T_APPLN_INDIV__c>();
            Map<Decimal,String> mapIndivSequenceToIndiv = new Map<Decimal,String>();
            
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                    if(appIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code && appIndiv.Application_Addresses__r!=null && appIndiv.Application_Addresses__r.size()>0){
                        lstAppAdr.clear();
                        lstAppAdr.addAll(appIndiv.Application_Addresses__r);
                    }else if(lstAppAdr.isEmpty()){
                        lstAppAdr.addAll(appIndiv.Application_Addresses__r);
                    }
                if(appIndiv.DTE_DOB__c!=null && String.isNotEmpty(appIndiv.NBR_SSN__c)){
                    setDOB_SSN.add(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c);
                }
                mapStateIdWithPrimaryCaretaker.put(appIndiv.IDN_STATE__c, appIndiv.IND_CRTKR_PRIM__c);
                mapStateIdWithAppIndiv.put(appIndiv.IDN_STATE__c, appIndiv);
                mapIndivSequenceToIndiv.put(appIndiv.IDN_SEQ_INDIV__c, appIndiv.IDN_STATE__c);
            }
            List<T_SBSD_INDIV__c> existingIndivList= [SELECT Id, IDN_STATE__c FROM T_SBSD_INDIV__c WHERE IDN_STATE__c IN:mapStateIdWithPrimaryCaretaker.keySet()];
            Map<String,T_SBSD_INDIV__c> mapExistingIndiv = new Map<String,T_SBSD_INDIV__c>();
            for(T_SBSD_INDIV__c existingIndiv: existingIndivList){
                mapExistingIndiv.put(existingIndiv.IDN_STATE__c,existingIndiv);
            }
            Map<String,String> existingIndivToRelationshipMap = new Map<String,String>(); //added for CCCAP-13633
            String relationshipType, peakRefTable, gender;
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(!mapExistingIndiv.containsKey(appIndiv.IDN_STATE__c)){
                    if(String.isNotEmpty(appIndiv.NAM_MI__c)){
                        appIndiv.NAM_MI__c =  appIndiv.NAM_MI__c.subString(0,1);
                    }
                    lstApplnIndivToBeConverted.add(appIndiv);
                }
                else{ //added for CCCAP-13633
                    if(appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0){
                        for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                            if(applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                                gender = appIndiv.CDE_GENDER__c;
                                peakRefTable = 'CBMS_REL';
                                peakRefTable += (gender=='M' || gender == 'F') ? ('_'+gender) : '';
                                relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                                existingIndivToRelationshipMap.put(appIndiv.IDN_STATE__c, relationshipType);
                            }        
                        }
                    }
                }
            }  

            for(T_SBSD_INDIV__c existingIndiv: existingIndivList){
                T_SBSD_INDIV_INFO__c indivInfo = new T_SBSD_INDIV_INFO__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = existingIndiv.Id,CDE_TYPE_INFO_INDIV__c = 'CS');
                if(!mapExistingCaseIndiv.containsKey(existingIndiv.IDN_STATE__c)){
                    T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseRec.id, IDN_CLIENT__c = existingIndiv.Id, DTE_BEGIN_EFFV__c = System.today(),
                                                    IND_CRTKR__c = mapStateIdWithPrimaryCaretaker.containsKey(existingIndiv.IDN_STATE__c) && mapStateIdWithPrimaryCaretaker.get(existingIndiv.IDN_STATE__c)=='Y'?true:false);
                    caseIndividual.Individual_Status__c = caseIndividual.IND_CRTKR__c == true ? 'PC' : (existingIndivToRelationshipMap.containsKey(existingIndiv.IDN_STATE__c) && additionalAdultRels.contains(existingIndivToRelationshipMap.get(existingIndiv.IDN_STATE__c)) ? 'AC' : 'Child'); //added for CCCAP-13633
                    mapCaseIndividual.put(existingIndiv.IDN_STATE__c, caseIndividual);
                    indivInfo.CDE_VALUE_INFO_INDIV__c = (caseIndividual.Individual_Status__c =='PC' || caseIndividual.Individual_Status__c =='AC') ? 'N/A-adult caretaker' : (mapStateIdWithAppIndiv.get(existingIndiv.IDN_STATE__c).IND_CTZN__c=='Y' ? 'CZN': (mapStateIdWithAppIndiv.get(existingIndiv.IDN_STATE__c).IND_CTZN__c=='N' ? 'NCZ': null)); //modified for CCCAP-13633
                }
                else{ 
                    indivInfo.CDE_VALUE_INFO_INDIV__c = (mapExistingCaseIndiv.get(existingIndiv.IDN_STATE__c).Individual_Status__c == 'PC' || mapExistingCaseIndiv.get(existingIndiv.IDN_STATE__c).Individual_Status__c == 'AC') ? 'N/A-adult caretaker': mapStateIdWithAppIndiv.get(existingIndiv.IDN_STATE__c).IND_CTZN__c=='Y'? 'CZN': mapStateIdWithAppIndiv.get(existingIndiv.IDN_STATE__c).IND_CTZN__c=='N'? 'NCZ': null; //modified for CCCAP-13633
                }
                mapIndividualInformation.put(existingIndiv.IDN_STATE__c, indivInfo);
                // added for RAPID - UFE by SS
                if(lstApplnCase[0].UFE_Request_Flag__c == true && mapStateIdWithPrimaryCaretaker.get(existingIndiv.IDN_STATE__c)=='Y'){
                    existingIndiv.UFE_Request_Flag__c = true;
                }
                existingIndiv.Bypass_On__c = System.now(); //added for CCCAP-14243
                existingIndiv.Is_CBMS_Data__c = true; //added for CCCAP-14243
                existingIndivToUpdate.add(existingIndiv);
            }                  
            
            Map<String,T_SBSD_INDIV__c> mapIndividual = new Map<String,T_SBSD_INDIV__c>();
            if(!lstApplnIndivToBeConverted.isEmpty()){
                for(SObject sOb:APXPolicyRecordsServices.createPolicyRecords(lstApplnIndivToBeConverted, false)){
                    if(sOb.getSObjectType()==Schema.T_SBSD_INDIV__c.getSObjectType()){
                        sOb.put('Is_CBMS_Data__c',true);
                         sOb.put('IND_CDE_TYPE_VERIF_DOB__c','V');
                         sOb.put('CDE_SOURCE_VRFYD_DOB__c','TF');
                         sOb.put('CDE_VRFYD_IDNTY__c','V');
                         sOb.put('CDE_SOURCE_VRFYD_IDNTY__c','TF');
                         // CBMS Case is required for Roadmap Correspondence PDF request
                         if(!lstApplnCase.isEmpty() && !String.isBlank(lstApplnCase[0].IDN_CBMS_REF__c)) {
                         	sOb.put('CBMS_CASE_NUM__c',lstApplnCase[0].IDN_CBMS_REF__c);
                         }
                        mapIndividual.put(String.valueOf(sOb.get('IDN_STATE__c')),(T_SBSD_INDIV__c)sOb);
                    }
                }                    
                
                for(T_APPLN_INDIV__c applnIndiv:lstApplnIndivToBeConverted){
                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                    String raceType='';
                    String ethnicityType='';
                    // Ethnicity logic needs to be added like RACE
                    for(T_APPLN_INDIV_RACE__c indivRace:applnIndiv.Application_Race_Information__r){
                        if(String.isNotEmpty(indivRace.CDE_RACE__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)!=null){
                            raceType+=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)+';';
                        }
                        if(String.isNotEmpty(indivRace.CDE_ETNCTY__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE_E', indivRace.CDE_ETNCTY__c)!=null){
                            ethnicityType=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE_E', indivRace.CDE_ETNCTY__c);
                        }
                    }
                    if(String.isNotEmpty(raceType)){
                        individual.CDE_RACE__c = raceType;
                    }
                    if(String.isNotEmpty(ethnicityType)){
                        individual.CDE_ETNCTY__c = ethnicityType;
                    }
                    individual.CDE_SOURCE_VRFYD_CITIZEN__c = 'TF';
                    individual.UFE_Request_Flag__c = applnIndiv.IND_CRTKR_PRIM__c =='Y' && lstApplnCase[0].UFE_Request_Flag__c;// added for RAPID - UFE by SS
                    mapIndividual.put(applnIndiv.IDN_STATE__c,individual);
                }
                GenericDMLHandler.insertRecords(mapIndividual.values(), methodInfo, new List<String>{'ufe_request_flag__c','bypass_on__c'});
            }
            // added for RAPID - UFE by SS
            if(!existingIndivToUpdate.isEmpty()){
                methodInfo.put('byPassObjects',new Set<String>{'T_SBSD_INDIV__c'});
                GenericDMLHandler.updateRecords(existingIndivToUpdate, methodInfo, new List<String>{'ufe_request_flag__c','bypass_on__c','Is_CBMS_Data__c'}); // Added Is_CBMS_Data__c as part of CCCAP-8307
            }
            for(T_APPLN_INDIV__c eachApplnIndivRcrd : lstApplnIndivToBeConverted){
                roadmapCorrIdSet.add(eachApplnIndivRcrd.ROADMAP_CORR_ID__c);
            }
            if(roadmapCorrIdSet != null){
                lstOfexistingRoadmapIds = [select Id, INDIVIDUAL__c, INDIVIDUAL__r.IDN_STATE__c,ROADMAP_CORR_ID__c	 FROM T_SBSD_ROADMAP_CORR_ID__c where ROADMAP_CORR_ID__c IN:roadmapCorrIdSet];
                if(lstOfexistingRoadmapIds != null){
                    for(T_SBSD_ROADMAP_CORR_ID__c eachExstngRoadmapId : lstOfexistingRoadmapIds){
                        mapOfExstngRoadmapIds.put(eachExstngRoadmapId.INDIVIDUAL__r.IDN_STATE__c, eachExstngRoadmapId.ROADMAP_CORR_ID__c);
                    }
                }
            }

            Map<String,String> indivToRelationshipMap = new Map<String,String>();
            gender = '';
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0){
                    for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                        if(mapIndividual.containsKey(appIndiv.IDN_STATE__c) && applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                            gender = mapIndividual.get(appIndiv.IDN_STATE__c).CDE_GENDER__c;
                            peakRefTable = 'CBMS_REL';
                            peakRefTable += gender=='1'?'_M':gender=='2'?'_F':'';
                            relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                            indivToRelationshipMap.put(appIndiv.IDN_STATE__c, relationshipType);
                        }        
                    }
                }                
            }

            for(T_APPLN_INDIV__c applnIndiv:lstApplnIndivToBeConverted){
                if(mapIndividual.containsKey(applnIndiv.IDN_STATE__c)){
                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                    T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = individual.Id,IND_CRTKR__c = applnIndiv.IND_CRTKR_PRIM__c=='Y'?true:false, DTE_BEGIN_EFFV__c = caseRec.DTE_APPLN__c);
                    caseIndividual.Individual_Status__c = caseIndividual.IND_CRTKR__c == true ? 'PC' : (indivToRelationshipMap.containsKey(applnIndiv.IDN_STATE__c) && additionalAdultRels.contains(indivToRelationshipMap.get(applnIndiv.IDN_STATE__c)) ? 'AC' :'Child'); //added for CCCAP-13633
                    lstCaseChildRecords.add(new T_SBSD_INDIV_MIL__c(IDN_CLIENT__c = individual.Id,CDE_STATUS_MIL__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TMLT', applnIndiv.CDE_STATUS_MIL__c)));
                    T_SBSD_INDIV_INFO__c indivInfo = new T_SBSD_INDIV_INFO__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = (caseIndividual.Individual_Status__c == 'PC' || caseIndividual.Individual_Status__c =='AC') ? 'N/A-adult caretaker' : (applnIndiv.IND_CTZN__c=='Y'?'CZN':applnIndiv.IND_CTZN__c=='N'?'NCZ':null)); //modified for CCCAP-13633
                    if(applnIndiv.ROADMAP_CORR_ID__c != null ){
                        if(mapOfExstngRoadmapIds.containsKey(applnIndiv.IDN_STATE__c) && mapOfExstngRoadmapIds.get(applnIndiv.IDN_STATE__c) == applnIndiv.ROADMAP_CORR_ID__c){
                            
                        } else {
                            T_SBSD_ROADMAP_CORR_ID__c chatsIndivRoadmapCorr = new T_SBSD_ROADMAP_CORR_ID__c(APPLICATION_PROCESS_QUEUE__c = appProcessQueue.Id,  IDN_CASE__c = caseRec.Id, 
                                                                                                            CBMS_CASE_NUM__c = lstApplnCase[0].CBMS_CASE_NUM__c, DATE_RECEIVED__c = appProcessQueue.DTE_RCVD_APPLN__c,
                                                                                                            INDIVIDUAL__c = individual.Id, ROADMAP_CORR_ID__c = applnIndiv.ROADMAP_CORR_ID__c);
                            mapindivStateIdToRoadmapCorr.put(applnIndiv.IDN_STATE__c, chatsIndivRoadmapCorr);
                        }
                        
                    }
			
		            // lstCaseChildRecords.add(new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = applnIndiv.IND_CTZN__c=='Y'?'CZN':applnIndiv.IND_CTZN__c=='N'?'NCZ':null));
                    //lstCaseChildRecords.add(new T_INDIV_VERIF__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_TYPE_VERIF__c = applnIndiv.IND_CTZN__c=='Y'?'V':applnIndiv.IND_CTZN__c=='N'?'NA':null));
                   // lstCaseChildRecords.add(new T_INDIV_VERIF__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_TYPE_VERIF__c = applnIndiv.IND_CTZN__c=='Y'?'V':applnIndiv.IND_CTZN__c=='N'?'NA':null));
                    /*if(!lstApplnCase.get(0).Application_case_28__r.isEmpty()){
                        caseIndividual.DTE_BEGIN_EFFV__c = lstApplnCase.get(0).Application_case_28__r.get(0).DTE_WKDAY_APPLN__c;
                    }*/
		    mapCaseIndividual.put(applnIndiv.IDN_STATE__c,caseIndividual);
                    mapIndividualInformation.put(applnIndiv.IDN_STATE__c,indivInfo);
                    for(T_APPLN_JOB_SEARCH__c applnJobSearch:applnIndiv.Application_Job_Search__r){
                        lstCaseChildRecords.add(new T_JOB_SEARCH__c(IDN_CLIENT__c = individual.Id,DTE_BEGIN_EFFV__c = applnJobSearch.DTE_BEGIN_EFFV__c, Ignore__c = true));
                    }
                    for(T_APPLN_ACTIVITY__c applnActivity:applnIndiv.Application_Activities__r){
                        String activityType=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', applnActivity.CDE_TYPE_ACTV__c);
                       lstCaseChildRecords.add(new T_PRIM_ACTV__c(IDN_CLIENT__c = individual.Id,IDN_CASE__c = caseRec.Id,DTE_BEGIN_ACTV_PRIM__c = applnActivity.DTE_BEGIN_ACTV_PRIM__c, DTE_END_ACTV_PRIM__c = applnActivity.DTE_END_ACTV_PRIM__c,CDE_TYPE_ACTV__c=activityType,Is_CBMS_Data__c =true));
                        
                    }
                }
            }    
                //Iterate over lstAppAdr
                //check if there is a type of Mailing Address mailingRecordCount = 1
                Integer mailingRecordCount = 0, homeRecordCount = 0;
                            
            if(!lstCaseChildRecords.isEmpty()){
                // To avoid System.TypeException: Cannot have more than 10 chunks in a single operation.
                lstCaseChildRecords.sort();
                GenericDMLHandler.insertRecords(lstCaseChildRecords, methodInfo);
                APXPolicyRecordsServices.createRefData(lstApplnCase[0].IDN_CBMS_REF__c ,lstApplnCase[0].CDE_CBMS_REF_TYP__c, lstCaseChildRecords);
                
            }
            if(!mapCaseIndividual.isEmpty()){
                GenericDMLHandler.insertRecords(mapCaseIndividual.values(), methodInfo);
            }
            if(!mapIndividualInformation.isEmpty()){
                GenericDMLHandler.insertRecords(mapIndividualInformation.values(), methodInfo);
            }
	    if(!mapindivStateIdToRoadmapCorr.isEmpty()){
                GenericDMLHandler.insertRecords(mapindivStateIdToRoadmapCorr.values(), methodInfo);
            }
            //Finding salesforce of Primary Caretaker Individual record
           // Id primaryCaretakerId; 
          /*  for(T_SBSD_CASE_INDIV__c caseIndiv:mapCaseIndividual.values()){
                if(caseIndiv.IND_CRTKR__c){
                    primaryCaretakerId = caseIndiv.IDN_CLIENT__c;
                    break;
                }
            }*/
            
            Map<String,List<SObject>> mapApplnIdChildRecords = new Map<String,List<SObject>>();
            //handling creation of employment & self employment records:-
            Map<String, List<SObject>> mapApplnEmployment = new Map<String, List<SObject>>();
            Map<String, List<SObject>> mapApplnSelfEmployment = new Map<String, List<SObject>>();
            List<T_APPLN_INDIV__c> listApplnIndivAndAllChilds = new List<T_APPLN_INDIV__c>();
             List<T_INDIV_VERIF__c> verificationRecords= new List<T_INDIV_VERIF__c>();
              Map<String, T_APPLN_CHILD_CARE__c> childCareMap = new Map<String, T_APPLN_CHILD_CARE__c>();
			listApplnIndivAndAllChilds = [select Id, Name, IDN_STATE__c,	IND_CTZN__c,
                                          		(SELECT Id, DTE_BIRTH_CUST_NON__c,IDN_STATE_CUST_NON__c,IND_CASE_OPEN__c,IND_COOP_PARENT__c,NAM_FIRST_CUST_NON__c,NAM_LAST_CUST_NON__c,NBR_SSN_CUST_NON__c FROM Application_Child_Support_Enforcements__r),
												(SELECT Id,IND_CC_GIVE_ABLE__c,IND_YR_DSBL__c FROM Application_Disabilities__r),
												(SELECT Id,AMT_DDTN_TOTAL__c,CDE_FREQ_PAID__c,NAM_PAYEE__c,NBR_DOCKET__c FROM Application_Child_Support_Deductions__r),												
                                                (SELECT Id,CDE_TYPE_SCHOOL__c,NAM_SCHOOL__c FROM Application_Education__r),
										        (SELECT Id,IND_CC_REQ__c,DTE_JOINT_CUST__c,IND_JOINT_CUST__c,DTE_BEGIN_HEAD_START__c,DTE_FOSTER__c,IND_FOSTER__c,IND_HEAD_START__c FROM Application_Custodies__r),												
                                                        (SELECT id,CHILD_NAME__c,IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,CNT_HOUR_ON_FRI__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_APPLN__c,
                                                     CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_CBMS_REF__c,
                                                     CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,IDN_CBMS_PROVR__c,IDN_INDIVIDUAL__c,NAM_FACILITY__c,IND_NEED_CHILD_CARE__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c,
                                                     DTE_WITH_LAST_PROVIDER__c,IND_PROVIDER_CHANGE__c,IND_SCHOOL_AGE_CARE__c FROM Application_Child_Cares__r)
							 from T_APPLN_INDIV__c
							 where Id IN:lstApplnIndivToBeConverted];
            
            List<T_APPLN_CHILD_CARE__c> chilCareList = new List<T_APPLN_CHILD_CARE__c>();
            for(T_APPLN_INDIV__c eachApplnIndividual : listApplnIndivAndAllChilds){
                 if(eachApplnIndividual.Application_Child_Cares__r != null && eachApplnIndividual.Application_Child_Cares__r.size()>0){
                     chilCareList.addAll(eachApplnIndividual.Application_Child_Cares__r);
                 }
                if(eachApplnIndividual.Application_Child_Support_Enforcements__r != null && eachApplnIndividual.Application_Child_Support_Enforcements__r.size()>0){
                    for(T_APPLN_CHILD_SUP__c applnDdtn:eachApplnIndividual.Application_Child_Support_Enforcements__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(eachApplnIndividual.Application_Disabilities__r != null && eachApplnIndividual.Application_Disabilities__r.size()>0){
                    for(T_APPLN_DSBLTY__c applnDdtn:eachApplnIndividual.Application_Disabilities__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(eachApplnIndividual.Application_Child_Support_Deductions__r != null && eachApplnIndividual.Application_Child_Support_Deductions__r.size()>0){
                    for(T_APPLN_DDTN__c applnDdtn:eachApplnIndividual.Application_Child_Support_Deductions__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                
                
                if(eachApplnIndividual.Application_Education__r != null && eachApplnIndividual.Application_Education__r.size()>0){
                    for(T_APPLN_EDUC__c applnDdtn:eachApplnIndividual.Application_Education__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(eachApplnIndividual.Application_Custodies__r != null && eachApplnIndividual.Application_Custodies__r.size()>0){
                    for(T_APPLN_CUST__c applnDdtn:eachApplnIndividual.Application_Custodies__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        if(applnDdtn.IND_JOINT_CUST__c=='Y'){
                            lstSObjectToBeInserted.add(new T_INDIV_CUST__c(DTE_BEGIN_EFFV__c = applnDdtn.DTE_JOINT_CUST__c,Ignore__c = true,
                                                                           IDN_CLIENT__c = mapIndividual.get(key).Id));
                        }
                       
                        
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                 if(eachApplnIndividual.Application_Child_Cares__r != null && eachApplnIndividual.Application_Child_Cares__r.size()>0){
                    for(T_APPLN_CHILD_CARE__c applnDdtn:eachApplnIndividual.Application_Child_Cares__r){
                        String key = eachApplnIndividual.IDN_STATE__c;                        
                        if(!childCareMap.containsKey(mapCaseIndividual.get(key).Id)){
                            if(applnDdtn.IND_NEED_CHILD_CARE__c=='Y'){
                                childCareMap.put(mapCaseIndividual.get(key).Id,applnDdtn);
                                lstSObjectToBeInserted.add(new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = mapCaseIndividual.get(key).Id,
                                                                                 DTE_BEGIN_EFFV__c = System.today()));
                            }  
                        }
                        /*commenting out as part of CCCAP-14944
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);*/
                    }
                }
                
                
                //Adding Indiv Verifications
                T_SBSD_INDIV__c individual = mapIndividual.get(eachApplnIndividual.IDN_STATE__c);
                String key = eachApplnIndividual.IDN_STATE__c;                
                //end
            }
          if(chilCareList.size()>0){
                ChildCareLastUpdatedServices.updateRefInfo(new List<T_APPLN_CHILD_CARE__c>(),new Map<Id, T_APPLN_CHILD_CARE__c>(),chilCareList);
            }
            Map<String,T_SBSD_INDIV_EMPLMT__c> mapEmployment = new Map<String,T_SBSD_INDIV_EMPLMT__c>();
            Map<String,T_EMPLMT_INCOME__c> mapEmploymentIncome = new Map<String,T_EMPLMT_INCOME__c>();
            Map<String,T_INDIV_EMPLMT_INFO__c> mapEmployInfo = new Map<String,T_INDIV_EMPLMT_INFO__c>();
            for(String key:mapApplnEmployment.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(mapApplnEmployment.get(key), false);
                    for(SObject sOb:lstSObject){
                        if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                            sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId());
                            sOb.put('IDN_CLIENT__c',mapIndividual.get(key).Id);
                            mapEmployment.put(key,(T_SBSD_INDIV_EMPLMT__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                            mapEmploymentIncome.put(key,(T_EMPLMT_INCOME__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_INDIV_EMPLMT_INFO__c.getSObjectType()){
                            sOb.put('CDE_TYPE_INFO_EMPLMT__c','EIW');    
                            mapEmployInfo.put(key,(T_INDIV_EMPLMT_INFO__c)sOb);
                        }
                    }
                }
            }
            
            if(!mapEmployment.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmployment.values(), methodInfo);
            }
            for(String key:mapEmploymentIncome.keySet()){
                T_EMPLMT_INCOME__c empIncome = mapEmploymentIncome.get(key);
                empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key).Id;
		empIncome.Is_CBMS_Data__c = true;
                mapEmploymentIncome.put(key,empIncome);
            }
            if(!mapEmploymentIncome.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmploymentIncome.values(), methodInfo);
            }            
            for(String key:mapEmployInfo.keySet()){
                T_INDIV_EMPLMT_INFO__c employInfo = mapEmployInfo.get(key);
                employInfo.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key).Id;
                mapEmployInfo.put(key,employInfo);
            }
            if(!mapEmployInfo.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmployInfo.values(), methodInfo);
            }    
            
            // Creating Self Employment Records
            mapEmployment.clear();
            mapEmploymentIncome.clear();
            Map<String,T_SBSD_EMPLMT_EXP__c> mapIncomeExpense = new Map<String,T_SBSD_EMPLMT_EXP__c>();
            for(String key:mapApplnSelfEmployment.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(mapApplnSelfEmployment.get(key), false);
                    for(SObject sOb:lstSObject){
                        if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                            sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId());
                            sOb.put('IDN_CLIENT__c',mapIndividual.get(key).Id);
                            mapEmployment.put(key,(T_SBSD_INDIV_EMPLMT__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                            sOb.put('CDE_FREQ_PAY_ESTMD__c','MON');    
                            mapEmploymentIncome.put(key,(T_EMPLMT_INCOME__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_SBSD_EMPLMT_EXP__c.getSObjectType()){
                            sOb.put('CDE_FREQ_EXP__c','MON');
                            sOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);     
                            mapIncomeExpense.put(key,(T_SBSD_EMPLMT_EXP__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_SBSD_EMPLMT_EXP__c.getSObjectType()){
                            sOb.put('CDE_FREQ_EXP__c','MON');    
                            mapIncomeExpense.put(key,(T_SBSD_EMPLMT_EXP__c)sOb);
                        }
                    }
                }
            }
            if(!mapEmployment.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmployment.values(), methodInfo);
            }
            
            for(String key:mapEmploymentIncome.keySet()){
                T_EMPLMT_INCOME__c empIncome = mapEmploymentIncome.get(key);
                empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key).Id;
		empIncome.Is_CBMS_Data__c = true;
                mapEmploymentIncome.put(key,empIncome);
            }
            if(!mapEmploymentIncome.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmploymentIncome.values(), methodInfo);
            }
            for(String key:mapIncomeExpense.keySet()){
                T_SBSD_EMPLMT_EXP__c incomeExpense = mapIncomeExpense.get(key);
                incomeExpense.IDN_EMPLMT_INDIV__c = mapEmploymentIncome.get(Key).IDN_EMPLMT_INDIV__c ;
                mapIncomeExpense.put(key,incomeExpense);
            }
            if(!mapIncomeExpense.isEmpty()){
                GenericDMLHandler.insertRecords(mapIncomeExpense.values(), methodInfo);
            }    
            for(String key:mapApplnIdChildRecords.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(mapApplnIdChildRecords.get(key), false);
                    lstSObjectToBeInserted.addAll(ConvertPeakDataToCHATS.createIndividualChildRecords(mapIndividual.get(key),caseRec,lstSObject,mapCaseIndividual));
                }
            }
            
            // To avoid System.TypeException: Cannot have more than 10 chunks in a single operation.
            lstSObjectToBeInserted.sort();
            if(!lstSObjectToBeInserted.isEmpty()){
                GenericDMLHandler.insertRecords(lstSObjectToBeInserted, methodInfo);
            }       
            
            List<T_APPLN_INDIV__c> lstApplnIndivToBeUpdated = new List<T_APPLN_INDIV__c>();
            // Linking application individuals to individuals
            Map<String,String> mapIndivDOBSSNToName = new Map<String,String>();
            for(T_SBSD_INDIV__c indiv:[SELECT Name, DOB_SSN__c FROM T_SBSD_INDIV__c WHERE Id IN:mapIndividual.values()]){
                mapIndivDOBSSNToName.put(indiv.DOB_SSN__c,indiv.Name);
            }
            List<SObject> recordsToBeUpserted = new List<SObject>();
            if(!verificationRecords.isEmpty()){
                GenericDMLHandler.insertRecords(verificationRecords, methodInfo);
            }
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(mapIndivDOBSSNToName.containsKey(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c) && String.isNotEmpty(mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c))){
                    appIndiv.IDN_CLIENT__c = mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c).length()>15?mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c).subString(0,15):mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c);
                }
                //  if(appIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code && appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0 && String.isNotEmpty(primaryCaretakerId)){
                if(String.isNotEmpty(primaryCaretakerId) && indivToRelationshipMap.containsKey(appIndiv.IDN_STATE__c)){
                    recordsToBeUpserted.add(new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = mapIndividual.get(appIndiv.IDN_STATE__c).Id,
                                                                           IDN_CLIENT__c = primaryCaretakerId,
                                                                           CDE_TYPE_REL_INDIV__c =  indivToRelationshipMap.get(appIndiv.IDN_STATE__c)
                                                                          ));
                }
            }
            
            if(!lstApplnIndiv.isEmpty()){
                GenericDMLHandler.updateRecords(lstApplnIndiv, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'}}, new List<String>{'IDN_CLIENT__c'});// Added IDN_CLIENT__c as part of CCCAP-8307
            }
            
            if(!recordsToBeUpserted.isEmpty()){
                GenericDMLHandler.insertRecords(recordsToBeUpserted, methodInfo);
            }
            
            //return caseRec;
            objectData.put('caseRec', caseRec);
            isSuccessful = true;
        }catch(DMLException dEx){
            ExceptionLoggingServices.captureExceptionLog(dEx,methodInfo);
            isSuccessful = false;
            for (Integer i = 0; i < dEx.getNumDml(); i++) {
                message+=dEx.getDmlMessage(i); 
            }            
            message+='('+dEx.getLineNumber()+')';
        }catch(PeakDataToCHATSException ex){
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            isSuccessful = false;
            message += ex.message;
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            isSuccessful = false;
            message = ex.getLineNumber()+':'+ex.getMessage();
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
   
    public static LightningServerResponse convertData(T_APPLN_PRCS_QUEUE__c appProcessQueue, List<String> individualIds){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message = 'Error: ';
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ConvertCBMSDataToCHATS','Method__c'=>'convertData'};
        List<Referral_Information__c> refrenceInfoLst = new List<Referral_Information__c>();
        List<String> additionalAdultRels = new List<String>{'H', 'CLH', 'CLW', 'LIC', 'SO', 'W', 'X'}; //added for CCCAP-13633
        try{
            //Get all the picklist translation mappings
            ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
            //Logic to clone T_APPLN records to T_SBSD records  
            //
            List<SObject> lstSObjectToBeInserted = new List<SObject>();
            List<T_SBSD_INDIV__c> lstIndiv = new List<T_SBSD_INDIV__c>();
            List<T_SBSD_INDIV_INFO__c> lstIndivInfo = new List<T_SBSD_INDIV_INFO__c>();
            List<T_SBSD_INDIV_MIL__c> lstIndivMil = new List<T_SBSD_INDIV_MIL__c>();
             // added for RAPID - UFE by SS
            List<SObject> existingIndivToUpdate = new List<SObject>();
            List<T_APPLN_CASE__c> lstApplnCase = [SELECT Id,CBMS_CASE_NUM__c,IND_CW_PGM__c,IDN_CBMS_REF__c,CBMS_REF_REASON__c,IND_INTER_COUNTY_TRANSFER__c,NET_EARNED_INCOME__c,PAYMENT_MONTH__c,PRI_METHOD_OF_CON__c,PRIOR_COUNTY__c,WORK_SPECIALIST__c,
                                                  CDE_CBMS_REF_TYP__c, ADR_CITY_PROVR__c,ADR_LINE_1_PROVR__c,ADR_STATE_PROVR__c,ADR_ZIP_PROVR__c,CASE_CLOSURE_REASON__c,
                                                  CDE_LANG_CORR__c,IDN_PROVR__c,IND_ASSIST_PROVR__c,IND_ASST_HSN__c,IND_ASST_HSNG_ADDL__c,
                                                  IND_CHP__c,IND_CHP_ADDL__c,IND_FOOD_PGM__c,IND_FOOD_PGM_ADDL__c,IND_FS_RCVNG__c,
                                                  IND_FS_RCVNG_ADDL__c,IND_HEAD_START__c,IND_HEAD_START_ADDL__c,IND_IDEA_0_3__c,
                                                  IND_IDEA_0_3_ADDL__c,IND_IDEA_3_5__c,IND_IDEA_3_5_ADDL__c,IND_INCOME_FED_OTHER__c,
                                                  IND_INCOME_FED_OTHER_ADDL__c,IND_PENSION__c,IND_PENSION_ADDL__c,IND_REFUGEE__c,
                                                  IND_REFUGEE_ADDL__c,IND_SSI__c,IND_SSI_ADDL__c,IND_WIC__c,IND_WIC_ADDL__c,
                                                  LOC_ELG_DETERM__c,NAM_FACLTY_PROVR__c,NAM_FIRST_PROVR__c,NAM_LAST_PROVR__c,
                                                  IND_HAS_ASSET__c,NBR_LIQUID_AMT__c,NBR_NON_LIQUID_AMT__c,
                                                  DTE_BEGIN_HOMELESS__c,DTE_END_HOMELESS__c,IND_IS_HOMELESS__c,
                                                  IND_LEAP__c,IND_LEAP_ADDL__c,IND_LVG_CAMPGROUND__c,IND_LVG_HOTEL__c,
                                                  IND_LVG_OTHER__c,IND_LVG_SHELTER__c,IND_LVG_SUBSTANDARD__c,TXT_LVG_OTHER_CMT__c,
                                                  CDE_INFO_PMC__c, NBR_PHONE_CELL__c, NBR_PHONE_HOME__c, NBR_PHONE_MSG__c, NBR_PHONE_MSG_EXTN__c,
                                                  CDE_INFO_EM__c, DTE_RCVD_APPLN__c,UFE_Request_Flag__c,// added for RAPID - UFE by SS
                                                  (SELECT IND_TANF_RCVNG__c FROM Application_case_38__r),
                                                  (SELECT DTE_WKDAY_APPLN__c FROM Application_case_28__r)
                                                  FROM T_APPLN_CASE__c WHERE Id =: appProcessQueue.IDN_APPLN__c];
            List<SObject> lstConvertedFromAppCase = APXPolicyRecordsServices.createPolicyRecords(lstApplnCase, false);
            List<SObject> lstCaseChildRecords = new List<SObject>();
            
            T_SBSD_CASE__c caseRec = new T_SBSD_CASE__c();
            for(SObject sOb:lstConvertedFromAppCase){
                if(String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE__c'){
                    caseRec = (T_SBSD_CASE__c)sOb;
                }else{
                    lstCaseChildRecords.add(sOb);
                }
            }
            // Inserting Case related Info
            Referral_Information__c cseInfoObj = new Referral_Information__c();
            
            // End
                Integer daysToBeAdded = 0;
                set<Date> holidays = new set<Date>();
                for(T_YEAR_HOL__c holiday:[SELECT DTE_HOL__c FROM T_YEAR_HOL__c WHERE DTE_HOL__c>=:appProcessQueue.CreatedDate.date() AND DTE_HOL__c<=:appProcessQueue.CreatedDate.date().addMonths(1)]){
                    holidays.add(holiday.DTE_HOL__c);
                }
                if(appProcessQueue.CreatedDate.hour()>=17){
                    daysToBeAdded = 1;
                }
                 caseRec.DTE_APPLN__c = appProcessQueue.DTE_RCVD_APPLN__c;
             //   caseRec.DTE_APPLN__c = ConvertPeakDataToCHATS.getNextBusinessDay(appProcessQueue.CreatedDate.date().addDays(daysToBeAdded), holidays);

            Decimal countyCode = null;
            List<T_COUNTY_PLAN_ADR__c> countyPlanAddresses = new List<T_COUNTY_PLAN_ADR__c>();
            if(appProcessQueue.CDE_COUNTY__c!=null){
                countyCode = Decimal.valueOf(appProcessQueue.CDE_COUNTY__c);
                List<T_County__c> lstCounty = [SELECT Id,(SELECT Id,ADR_LINE_1__c,ADR_LINE_2__c,ADR_CITY__c,ADR_STATE__c,ADR_ZIP__c,ADR_ZIP_EXTN__c, Record_Type_Name__c FROM County3__r WHERE Record_Type_Name__c IN ('Mailing','Main_Location')) FROM T_County__c WHERE CDE_COUNTY__c =:countyCode];
                if(!lstCounty.isEmpty()){
                    caseRec.CDE_COUNTY__c = lstCounty.get(0).Id;
                        if(lstCounty.get(0).County3__r!=null && lstCounty.get(0).County3__r.size()>0){
                            countyPlanAddresses.addAll(lstCounty.get(0).County3__r);
                        }
                }
            }
            
                CaseLastUpdatedServices.isPeakApplicationContext = true;
                caseRec.DTE_CHGD_LAST_DATA_ELIGTY__c = System.today();
                caseRec.IND_CHGD_DATA_ELIGTY__c = true;
                caseRec.Is_CBMS_Data__c = true;
		        caseRec.Bypass_CaseName_ValidationRule__c = TRUE;
            
            
            GenericDMLHandler.insertRecords(new List<SObject>{caseRec}, methodInfo);
			APXPolicyRecordsServices.createRefData(lstApplnCase[0].IDN_CBMS_REF__c ,lstApplnCase[0].CDE_CBMS_REF_TYP__c,new List<SObject>{caseRec});
            //T_SBSD_CASE_STATUS_MODE record for the case with the following values: CDE_MODE_CASE = Intake, CDE_STATUS_CASE = Pending, DTE_EFFV_BEGIN = Today
            GenericDMLHandler.insertRecords(new List<SObject>{new T_SBSD_CASE_STATUS_MODE__c(
                IDN_CASE__c = caseRec.Id,
                CDE_MODE_CASE__c = 'INT',
                CDE_STATUS_CASE__c = 'PEN',
                DTE_BEGIN_EFFV__c = System.today()
            )}, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_CASE_STATUS_MODE__c'}});

            // Getting Referral Type
            String referralType = caseRec.CDE_CBMS_REF_TYP__c;
            if(referralType=='New'){
                //T_SBSD_CASE_STATUS_MODE record for the case with the following values: CDE_MODE_CASE = Intake, CDE_STATUS_CASE = Pending, DTE_EFFV_BEGIN = Today
                GenericDMLHandler.insertRecords(new List<SObject>{new T_CBMS_ADDNL_INFO__c(
                IDN_CASE_CHATS__c = caseRec.Id,
                DTE_BEGIN_EFFEV__c =caseRec.DTE_APPLN__c ,
                IDN_CASE_INTFC__c =lstApplnCase.get(0).CBMS_CASE_NUM__c ,
                //CDE_CAT_ACTIV__c = 'SEM',
                AMT_TANF_INCOME_HH_GROSS__c=lstApplnCase.get(0).NET_EARNED_INCOME__c,
                CDE_FREQ_INCOME__c='MON',
                CDE_PROG__c='TF',
                NME_CO_WORKER__c=lstApplnCase.get(0).WORK_SPECIALIST__c
            )}, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_CBMS_ADDNL_INFO__c'}});
            // End  
            List<T_CBMS_ADDNL_INFO__c> tanfLst = [SELECT Id,DTE_BEGIN_EFFEV__c,AMT_TANF_INCOME_HH_GROSS__c from T_CBMS_ADDNL_INFO__c where IDN_CASE_CHATS__c=:caseRec.Id];
                if(tanfLst!= null && tanfLst.size()>0){
                    APXPolicyRecordsServices.createRefData(lstApplnCase[0].IDN_CBMS_REF__c ,lstApplnCase[0].CDE_CBMS_REF_TYP__c,new List<SObject>{tanfLst[0]});
                   // APXPolicyRecordsServices.updateRefDataIncome(lstApplnCase[0].IDN_CBMS_REF__c ,new List<SObject>{tanfLst[0]});
                }  
            }
            
            List<T_APPLN_INDIV__c> lstApplnIndiv = [SELECT Id, CDE_GENDER__c,CBMS_DENIAL_REASON__c,CDE_SOURCE_VRFYD_CITIZEN__c,CDE_VRFYD_CITIZEN__c,IDN_CBMS_CLIENT__c,IND_IPV__c,ROADMAP_CORR_ID__c,
                                                    CDE_LEVEL_GRADE_HGHST__c,
                                                    CDE_STATUS_MAR__c,
                                                    DTE_DOB__c,
                                                    DTE_Death__c, // added for SIDMOD CCCAP-7695 by Shashank
                                                    IND_NOTIF_SIDMOD__c, // added for SIDMOD CCCAP-10315 by Shashank
                                                    IDN_STATE__c,
                                                    NAM_FIRST__c,
                                                    NAM_LAST__c,
                                                    NAM_MI__c,
                                                    NBR_SSN__c,
                                                    CDE_INFO_CS__c,
                                                    IND_CTZN__c,
                                                    CDE_STATUS_MIL__c,
                                                    IND_CRTKR_PRIM__c,
                                                    IDN_SEQ_INDIV__c,
                                                    ( SELECT Id,
                                                     ADR_CITY__c,
                                                     ADR_LINE_1__c,
                                                     ADR_LINE_2__c,
                                                     ADR_STATE__c,
                                                     ADR_ZIP_EXTN__c,
                                                     ADR_ZIP_MAIN__c,
                                                     CDE_TYPE_ADR__c,
                                                     ADR_NAM__c
                                                     FROM Application_Addresses__r
                                                    ),
                                                    (SELECT CDE_RACE__c,CDE_ETNCTY__c FROM Application_Race_Information__r),
                                                    (SELECT id,CDE_TYPE_ACTV__c,DTE_BEGIN_ACTV_PRIM__c,DTE_END_ACTV_PRIM__c,External_ID__c,IDN_INDIVIDUAL__c FROM Application_Activities__r),
                                                    (SELECT id,IDN_INDIVIDUAL__c,IND_NEED_CHILD_CARE__c,NAM_FACILITY__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c,
                                                    CHILD_NAME__c,CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,CNT_HOUR_ON_FRI__c,IDN_CBMS_PROVR__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,
                                                    DTE_WITH_LAST_PROVIDER__c,IND_PROVIDER_CHANGE__c,IND_SCHOOL_AGE_CARE__c FROM Application_Child_Cares__r),
                                                    (SELECT DTE_BEGIN_EFFV__c FROM Application_Job_Search__r),
                                                    (SELECT Id, CDE_TYPE_REL_INDIV__c, IDN_APPLN_REL__c, IDN_SEQ_INDIV_RELTD__c
                                                     FROM Application_Relationships__r
                                                    )
                                                    FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c AND Id IN:individualIds];
            Set<String> setDOB_SSN = new Set<String>();
            Map<String, String> mapStateIdWithPrimaryCaretaker = new Map<String, String>();
            Map<String, T_APPLN_INDIV__c> mapStateIdWithAppIndiv = new Map<String, T_APPLN_INDIV__c>();
            List<T_APPLN_ADR__c> lstAppAdr = new List<T_APPLN_ADR__c>();
            Map<String,T_SBSD_CASE_INDIV__c> mapCaseIndividual = new Map<String,T_SBSD_CASE_INDIV__c>();
            Map<String,T_SBSD_INDIV_INFO__c> mapIndividualInformation = new Map<String,T_SBSD_INDIV_INFO__c>();
	    map<String,T_SBSD_ROADMAP_CORR_ID__c> mapindivStateIdToRoadmapCorr = new map<String,T_SBSD_ROADMAP_CORR_ID__c>();
            List<T_APPLN_INDIV__c> lstApplnIndivToBeConverted = new List<T_APPLN_INDIV__c>();
            Map<Decimal,String> mapIndivSequenceToIndiv = new Map<Decimal,String>();
            
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                    if(appIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code && appIndiv.Application_Addresses__r!=null && appIndiv.Application_Addresses__r.size()>0){
                        lstAppAdr.clear();
                        lstAppAdr.addAll(appIndiv.Application_Addresses__r);
                    }else if(lstAppAdr.isEmpty()){
                        lstAppAdr.addAll(appIndiv.Application_Addresses__r);
                    }
                if(appIndiv.DTE_DOB__c!=null && String.isNotEmpty(appIndiv.NBR_SSN__c)){
                    setDOB_SSN.add(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c);
                }
                mapStateIdWithPrimaryCaretaker.put(appIndiv.IDN_STATE__c, appIndiv.IND_CRTKR_PRIM__c);
                mapStateIdWithAppIndiv.put(appIndiv.IDN_STATE__c, appIndiv);
                mapIndivSequenceToIndiv.put(appIndiv.IDN_SEQ_INDIV__c, appIndiv.IDN_STATE__c);
            }
            
            for(T_APPLN_PRCS_ADDNL_INFO__c applnPrcsAddInfo:lstApplnCase.get(0).Application_case_38__r){
                lstCaseChildRecords.add(new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseRec.Id,
                                                               TANF_RCVNG__c =applnPrcsAddInfo.IND_TANF_RCVNG__c,
                                                               DTE_BEGIN_EFFEV__c = caseRec.DTE_APPLN__c));
            }
            
            
            //Added mapping for case information record with email data
            if(String.isNotEmpty(lstApplnCase.get(0).CDE_INFO_EM__c)){
                lstCaseChildRecords.add(new T_SBSD_CASE_INFO__c(IDN_CASE__c = caseRec.Id, CDE_TYPE_INFO_CASE__c =  'EM', TXT_VALUE_INFO_CASE__c = lstApplnCase.get(0).CDE_INFO_EM__c));
            }
            if(String.isNotEmpty(lstApplnCase.get(0).PRI_METHOD_OF_CON__c)){
                lstCaseChildRecords.add(new T_SBSD_CASE_INFO__c(IDN_CASE__c = caseRec.Id, CDE_TYPE_INFO_CASE__c =  'PMC', TXT_VALUE_INFO_CASE__c = lstApplnCase.get(0).CDE_INFO_PMC__c));
            }
            
            if(String.isNotEmpty(lstApplnCase.get(0).NBR_PHONE_CELL__c)){
                lstCaseChildRecords.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c = caseRec.Id,DTE_BEGIN_EFFV__c=caseRec.DTE_APPLN__c, CDE_TYPE_PHONE__c =  'MOB', NBR_PHONE__c = lstApplnCase.get(0).NBR_PHONE_CELL__c));
            }
            
            if(String.isNotEmpty(lstApplnCase.get(0).NBR_PHONE_HOME__c)){
                lstCaseChildRecords.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c = caseRec.Id,DTE_BEGIN_EFFV__c=caseRec.DTE_APPLN__c, CDE_TYPE_PHONE__c =  'HOM', NBR_PHONE__c = lstApplnCase.get(0).NBR_PHONE_HOME__c));
            }
            
            if(String.isNotEmpty(lstApplnCase.get(0).NBR_PHONE_MSG__c)){
                Integer phoneExt;
                try{
                    if(String.isNotEmpty(lstApplnCase.get(0).NBR_PHONE_MSG_EXTN__c)){
                        phoneExt = Integer.valueOf(lstApplnCase.get(0).NBR_PHONE_MSG_EXTN__c);
                    }
                    lstCaseChildRecords.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c = caseRec.Id,DTE_BEGIN_EFFV__c=caseRec.DTE_APPLN__c, CDE_TYPE_PHONE__c =  'WOR', NBR_PHONE__c = lstApplnCase.get(0).NBR_PHONE_MSG__c, NBR_PHONE_EXTN__c = phoneExt));
                }catch(Exception ex){
                    ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
                    PeakDataToCHATSException peEx = new PeakDataToCHATSException();
                    peEx.message = 'Invalid Phone Number Ext.';
                    throw peEx;
                }
            }
            List<T_SBSD_INDIV__c> existingIndivList =[SELECT Id, IDN_STATE__c, CDE_GENDER__c FROM T_SBSD_INDIV__c WHERE IDN_STATE__c IN:mapStateIdWithPrimaryCaretaker.keySet()];
            Map<String,T_SBSD_INDIV__c> mapExistingIndiv = new Map<String,T_SBSD_INDIV__c>();
            Map<String,String> existingIndivToRelationshipMap = new Map<String,String>(); //added for CCCAP-13633
            String relationshipType, peakRefTable, gender;

            for(T_SBSD_INDIV__c existingIndiv : existingIndivList){
                mapExistingIndiv.put(existingIndiv.IDN_STATE__c,existingIndiv);
            }
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(!mapExistingIndiv.containsKey(appIndiv.IDN_STATE__c)){
                    if(String.isNotEmpty(appIndiv.NAM_MI__c)){
                           appIndiv.NAM_MI__c =  appIndiv.NAM_MI__c.subString(0,1);
                        }
                    lstApplnIndivToBeConverted.add(appIndiv);
                }
                else{ //added for CCCAP-13633
                    if(appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0){
                        for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                            if(applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                                gender = appIndiv.CDE_GENDER__c;
                                peakRefTable = 'CBMS_REL';
                                peakRefTable += (gender=='M' || gender == 'F') ? ('_'+gender) : '';
                                relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                                existingIndivToRelationshipMap.put(appIndiv.IDN_STATE__c, relationshipType);
                            }        
                        }
                    }
                }
            }   
            for(T_SBSD_INDIV__c existingIndiv : existingIndivList){
                T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseRec.id, IDN_CLIENT__c = existingIndiv.Id, DTE_BEGIN_EFFV__c = System.today(),
                                                    IND_CRTKR__c = mapStateIdWithPrimaryCaretaker.containsKey(existingIndiv.IDN_STATE__c) && mapStateIdWithPrimaryCaretaker.get(existingIndiv.IDN_STATE__c)=='Y'?true:false);
                //added for CCCAP-13633
                caseIndividual.Individual_Status__c = caseIndividual.IND_CRTKR__c == true ? 'PC' : (existingIndivToRelationshipMap.containsKey(existingIndiv.IDN_STATE__c) && additionalAdultRels.contains(existingIndivToRelationshipMap.get(existingIndiv.IDN_STATE__c)) ? 'AC' : 'Child');
                mapCaseIndividual.put(existingIndiv.IDN_STATE__c, caseIndividual);
                mapIndividualInformation.put(existingIndiv.IDN_STATE__c, new T_SBSD_INDIV_INFO__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = existingIndiv.Id,CDE_TYPE_INFO_INDIV__c = 'CS', 
                    CDE_VALUE_INFO_INDIV__c = (caseIndividual.Individual_Status__c =='PC' || caseIndividual.Individual_Status__c =='AC') ? 'N/A-adult caretaker' : ((mapStateIdWithAppIndiv.get(existingIndiv.IDN_STATE__c).IND_CTZN__c=='Y') ?'CZN': (mapStateIdWithAppIndiv.get(existingIndiv.IDN_STATE__c).IND_CTZN__c=='N')?'NCZ': null)));
                // added for RAPID - UFE by SS
                if(lstApplnCase[0].UFE_Request_Flag__c == true && mapStateIdWithPrimaryCaretaker.get(existingIndiv.IDN_STATE__c)=='Y'){
                    existingIndiv.UFE_Request_Flag__c = true;
                }
                existingIndiv.Is_CBMS_Data__c = true; //added for CCCAP-14243
                existingIndiv.Bypass_On__c = System.now(); //added for CCCAP-14243
                existingIndivToUpdate.add(existingIndiv);
            }              
            
            Map<String,T_SBSD_INDIV__c> mapIndividual = new Map<String,T_SBSD_INDIV__c>();
            if(!lstApplnIndivToBeConverted.isEmpty()){
                for(SObject sOb:APXPolicyRecordsServices.createPolicyRecords(lstApplnIndivToBeConverted, false)){
                    if(sOb.getSObjectType()==Schema.T_SBSD_INDIV__c.getSObjectType()){
                        sOb.put('Is_CBMS_Data__c',true);
                         sOb.put('IND_CDE_TYPE_VERIF_DOB__c','V');
                         sOb.put('CDE_SOURCE_VRFYD_DOB__c','TF');
                         sOb.put('CDE_VRFYD_IDNTY__c','V');
                         sOb.put('CDE_SOURCE_VRFYD_IDNTY__c','TF');
                        mapIndividual.put(String.valueOf(sOb.get('IDN_STATE__c')),(T_SBSD_INDIV__c)sOb);
                    }
                }                    
                
                for(T_APPLN_INDIV__c applnIndiv:lstApplnIndivToBeConverted){
                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                    String raceType='';
                    String ethnicityType='';
                    // Ethnicity logic needs to be added like RACE
                    for(T_APPLN_INDIV_RACE__c indivRace:applnIndiv.Application_Race_Information__r){
                        if(String.isNotEmpty(indivRace.CDE_RACE__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)!=null){
                            raceType+=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)+';';
                        }
                        if(String.isNotEmpty(indivRace.CDE_ETNCTY__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE_E', indivRace.CDE_ETNCTY__c)!=null){
                            ethnicityType=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE_E', indivRace.CDE_ETNCTY__c);
                        }
                    }
                    if(String.isNotEmpty(raceType)){
                        individual.CDE_RACE__c = raceType;
                    }
                    if(String.isNotEmpty(ethnicityType)){
                        individual.CDE_ETNCTY__c = ethnicityType;
                    }
                    individual.CDE_SOURCE_VRFYD_CITIZEN__c = 'TF';
                    individual.UFE_Request_Flag__c = applnIndiv.IND_CRTKR_PRIM__c =='Y' && lstApplnCase[0].UFE_Request_Flag__c; // added for RAPID - UFE by SS
                    mapIndividual.put(applnIndiv.IDN_STATE__c,individual);
                }
                GenericDMLHandler.insertRecords(mapIndividual.values(), methodInfo);
            }
            // added for RAPID - UFE by SS
            if(!existingIndivToUpdate.isEmpty()){
                methodInfo.put('byPassObjects',new Set<String>{'T_SBSD_INDIV__c'});
                GenericDMLHandler.updateRecords(existingIndivToUpdate, methodInfo, new List<String>{'Is_CBMS_Data__c','Bypass_On__c','UFE_Request_Flag__c'});// Added list of fields for CCCAP-8307
            }
            Map<String,String> indivToRelationshipMap = new Map<String,String>();
            String indivRelationshipType, indivGender;
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0){
                    for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                        if(mapIndividual.containsKey(appIndiv.IDN_STATE__c) && applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                            indivGender = mapIndividual.get(appIndiv.IDN_STATE__c).CDE_GENDER__c;
                            peakRefTable = 'CBMS_REL';
                            peakRefTable += indivGender=='1'?'_M':indivGender=='2'?'_F':'';
                            indivRelationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                            indivToRelationshipMap.put(appIndiv.IDN_STATE__c, indivRelationshipType);
                        }        
                    }
                }                
            }
            for(T_APPLN_INDIV__c applnIndiv:lstApplnIndivToBeConverted){
                if(mapIndividual.containsKey(applnIndiv.IDN_STATE__c)){
                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                    T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = individual.Id,IND_CRTKR__c = applnIndiv.IND_CRTKR_PRIM__c=='Y'?true:false, DTE_BEGIN_EFFV__c = caseRec.DTE_APPLN__c);
                    //added for CCCAP-13633
                    caseIndividual.Individual_Status__c = applnIndiv.IND_CRTKR_PRIM__c=='Y' ? 'PC' : (indivToRelationshipMap.containsKey(applnIndiv.IDN_STATE__c) && additionalAdultRels.contains(indivToRelationshipMap.get(individual.IDN_STATE__c)) ? 'AC' : 'Child'); //added for CCCAP-13633
                    lstCaseChildRecords.add(new T_SBSD_INDIV_MIL__c(IDN_CLIENT__c = individual.Id,CDE_STATUS_MIL__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TMLT', applnIndiv.CDE_STATUS_MIL__c)));
                    T_SBSD_INDIV_INFO__c indivInfo = new T_SBSD_INDIV_INFO__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = (caseIndividual.Individual_Status__c =='PC' || caseIndividual.Individual_Status__c =='AC') ? 'N/A-adult caretaker' : ((applnIndiv.IND_CTZN__c=='Y') ?'CZN':applnIndiv.IND_CTZN__c=='N'?'NCZ':null));
		            if(applnIndiv.ROADMAP_CORR_ID__c != null){
                        T_SBSD_ROADMAP_CORR_ID__c chatsIndivRoadmapCorr = new T_SBSD_ROADMAP_CORR_ID__c(APPLICATION_PROCESS_QUEUE__c = appProcessQueue.Id,  IDN_CASE__c = caseRec.Id, 
                                                                                                        CBMS_CASE_NUM__c = lstApplnCase[0].CBMS_CASE_NUM__c, DATE_RECEIVED__c = appProcessQueue.DTE_RCVD_APPLN__c,
                                                                                                        INDIVIDUAL__c = individual.Id, ROADMAP_CORR_ID__c = applnIndiv.ROADMAP_CORR_ID__c);
                        mapindivStateIdToRoadmapCorr.put(applnIndiv.IDN_STATE__c, chatsIndivRoadmapCorr);
                    }	
                   // lstCaseChildRecords.add(new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = applnIndiv.IND_CTZN__c=='Y'?'CZN':applnIndiv.IND_CTZN__c=='N'?'NCZ':null));
                    //lstCaseChildRecords.add(new T_INDIV_VERIF__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_TYPE_VERIF__c = applnIndiv.IND_CTZN__c=='Y'?'V':applnIndiv.IND_CTZN__c=='N'?'NA':null));
                   // lstCaseChildRecords.add(new T_INDIV_VERIF__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_TYPE_VERIF__c = applnIndiv.IND_CTZN__c=='Y'?'V':applnIndiv.IND_CTZN__c=='N'?'NA':null));
                    if(String.isNotEmpty(lstApplnCase.get(0).CDE_INFO_EM__c) && applnIndiv.IND_CRTKR_PRIM__c=='Y'){
                            lstCaseChildRecords.add(new Individual_E_mail__c(Individual__c = individual.Id, Effective_Begin_Date__c=System.today(), Email_Information__c = lstApplnCase.get(0).CDE_INFO_EM__c));
                        }
                    /*if(!lstApplnCase.get(0).Application_case_28__r.isEmpty()){
                        caseIndividual.DTE_BEGIN_EFFV__c = lstApplnCase.get(0).Application_case_28__r.get(0).DTE_WKDAY_APPLN__c;
                    }*/
		            mapCaseIndividual.put(applnIndiv.IDN_STATE__c,caseIndividual);
                    mapIndividualInformation.put(applnIndiv.IDN_STATE__c,indivInfo);
                    for(T_APPLN_JOB_SEARCH__c applnJobSearch:applnIndiv.Application_Job_Search__r){
                        lstCaseChildRecords.add(new T_JOB_SEARCH__c(IDN_CLIENT__c = individual.Id,DTE_BEGIN_EFFV__c = applnJobSearch.DTE_BEGIN_EFFV__c, Ignore__c = true));
                    }
                    for(T_APPLN_ACTIVITY__c applnActivity:applnIndiv.Application_Activities__r){
                        String activityType=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', applnActivity.CDE_TYPE_ACTV__c);
                       lstCaseChildRecords.add(new T_PRIM_ACTV__c(IDN_CLIENT__c = individual.Id,IDN_CASE__c = caseRec.Id,DTE_BEGIN_ACTV_PRIM__c = applnActivity.DTE_BEGIN_ACTV_PRIM__c, DTE_END_ACTV_PRIM__c = applnActivity.DTE_END_ACTV_PRIM__c,CDE_TYPE_ACTV__c=activityType,Is_CBMS_Data__c =true));
                        
                    }
                }
            }    
                //Iterate over lstAppAdr
                //check if there is a type of Mailing Address mailingRecordCount = 1
                Integer mailingRecordCount = 0, homeRecordCount = 0;
                
                if(lstApplnCase.get(0).IND_IS_HOMELESS__c=='Y' && !lstAppAdr.isEmpty()){
                     for(T_APPLN_ADR__c appAdrEach : lstAppAdr) {
                        if(appAdrEach.CDE_TYPE_ADR__c=='ML' && mailingRecordCount==0 && (appAdrEach.ADR_CITY__c!=null
                          || appAdrEach.ADR_LINE_1__c!=null || appAdrEach.ADR_LINE_2__c!=null || appAdrEach.ADR_STATE__c!=null
                                             || appAdrEach.ADR_ZIP_EXTN__c!=null  || appAdrEach.ADR_ZIP_MAIN__c !=null)) {
                            T_SBSD_CASE_ADR__c caseAddress = new T_SBSD_CASE_ADR__c();
                            caseAddress.ADR_CITY__c = appAdrEach.ADR_CITY__c;
                            caseAddress.ADR_LINE_1__c = appAdrEach.ADR_LINE_1__c;
                            caseAddress.ADR_LINE_2__c = appAdrEach.ADR_LINE_2__c;
                            caseAddress.ADR_STATE__c = appAdrEach.ADR_STATE__c;
                            caseAddress.ADR_ZIP_EXTN__c = appAdrEach.ADR_ZIP_EXTN__c;
                            caseAddress.ADR_ZIP_MAIN__c = appAdrEach.ADR_ZIP_MAIN__c;
                            caseAddress.DTE_BEGIN_EFFV__c=caseRec.DTE_APPLN__c;
                            caseAddress.CDE_TYPE_ADR__c = 'MAL';
                            caseAddress.CDE_TYPE_VERIF__c='V';
                    caseAddress.CDE_SOURCE_VRFD_ADR__c='TF';
                            lstCaseChildRecords.add(caseAddress);
                            mailingRecordCount++;                          
                        }
                         
                     }
                    for(T_COUNTY_PLAN_ADR__c countyPlanAddress:countyPlanAddresses){
                        T_SBSD_CASE_ADR__c caseAddress = new T_SBSD_CASE_ADR__c();
                        caseAddress.ADR_CITY__c = countyPlanAddress.ADR_CITY__c;
                        caseAddress.ADR_LINE_1__c = countyPlanAddress.ADR_LINE_1__c;
                        caseAddress.ADR_LINE_2__c = countyPlanAddress.ADR_LINE_2__c;
                        caseAddress.ADR_STATE__c = countyPlanAddress.ADR_STATE__c;
                        caseAddress.ADR_ZIP_EXTN__c = countyPlanAddress.ADR_ZIP_EXTN__c;
                        caseAddress.ADR_ZIP_MAIN__c = countyPlanAddress.ADR_ZIP__c;
                        caseAddress.DTE_BEGIN_EFFV__c=caseRec.DTE_APPLN__c;
                        caseAddress.CDE_TYPE_VERIF__c='V';
                    caseAddress.CDE_SOURCE_VRFD_ADR__c='TF';
                        if(countyPlanAddress.Record_Type_Name__c=='Mailing' && mailingRecordCount==0){
                            caseAddress.CDE_TYPE_ADR__c = 'MAL';
                            lstCaseChildRecords.add(caseAddress);
                            mailingRecordCount++;
                        }else if(countyPlanAddress.Record_Type_Name__c=='Main_Location' && homeRecordCount==0){
                            caseAddress.CDE_TYPE_ADR__c = 'HOM';
                            lstCaseChildRecords.add(caseAddress);
                            homeRecordCount++;
                        }
                    }                  
                }else if(!lstAppAdr.isEmpty()){
                    for(SObject eachSOb:APXPolicyRecordsServices.createPolicyRecords(lstAppAdr, false)){
                        eachSOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);
                        if(String.valueOf(eachSOb.getSObjectType())=='T_SBSD_CASE_ADR__c'){
                            eachSOb.put('CDE_TYPE_VERIF__c','V');
                            eachSOb.put('CDE_SOURCE_VRFD_ADR__c','TF');
                        }
                        lstCaseChildRecords.add(eachSOb);
                    }
                    
                }
            
            for(SObject sOb:lstCaseChildRecords){
                if(String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ADR__c' || String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ASSET__c' || String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_HOMELESS__c'){
                    sOb.put('IDN_CASE__c',caseRec.Id);
                    if(String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ASSET__c'){
                        sOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);
                    }
                    if(String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ADR__c'){
                            sOb.put('CDE_TYPE_VERIF__c','V');
                            sOb.put('CDE_SOURCE_VRFD_ADR__c','TF');
                        }
                }
            }
            
            if(!lstCaseChildRecords.isEmpty()){
                // To avoid System.TypeException: Cannot have more than 10 chunks in a single operation.
                lstCaseChildRecords.sort();
                GenericDMLHandler.insertRecords(lstCaseChildRecords, methodInfo);
                APXPolicyRecordsServices.createRefData(lstApplnCase[0].IDN_CBMS_REF__c ,lstApplnCase[0].CDE_CBMS_REF_TYP__c, lstCaseChildRecords);
                
            }
            if(!mapCaseIndividual.isEmpty()){
                GenericDMLHandler.insertRecords(mapCaseIndividual.values(), methodInfo);
            }
            if(!mapIndividualInformation.isEmpty()){
                GenericDMLHandler.insertRecords(mapIndividualInformation.values(), methodInfo);
            }
	    if(!mapindivStateIdToRoadmapCorr.isEmpty()){
                GenericDMLHandler.insertRecords(mapindivStateIdToRoadmapCorr.values(), methodInfo);
            }
            //Finding salesforce of Primary Caretaker Individual record
            Id primaryCaretakerId; 
            for(T_SBSD_CASE_INDIV__c caseIndiv:mapCaseIndividual.values()){
                if(caseIndiv.IND_CRTKR__c){
                    primaryCaretakerId = caseIndiv.IDN_CLIENT__c;
                    break;
                }
            }
            
            Map<String,List<SObject>> mapApplnIdChildRecords = new Map<String,List<SObject>>();
            //handling creation of employment & self employment records:-
            Map<String, List<SObject>> mapApplnEmployment = new Map<String, List<SObject>>();
            Map<String, List<SObject>> mapApplnSelfEmployment = new Map<String, List<SObject>>();
            List<T_APPLN_INDIV__c> listApplnIndivAndAllChilds = new List<T_APPLN_INDIV__c>();
             Map<String, T_APPLN_CHILD_CARE__c> childCareMap = new Map<String, T_APPLN_CHILD_CARE__c>();
             List<T_INDIV_VERIF__c> verificationRecords= new List<T_INDIV_VERIF__c>();
			listApplnIndivAndAllChilds = [select Id, Name, IDN_STATE__c,	IND_CTZN__c,
                                          		(SELECT Id, DTE_BIRTH_CUST_NON__c,IDN_STATE_CUST_NON__c,IND_CASE_OPEN__c,IND_COOP_PARENT__c,NAM_FIRST_CUST_NON__c,NAM_LAST_CUST_NON__c,NBR_SSN_CUST_NON__c FROM Application_Child_Support_Enforcements__r),
												(SELECT Id,IND_CC_GIVE_ABLE__c,IND_YR_DSBL__c FROM Application_Disabilities__r),
												(SELECT Id,AMT_DDTN_TOTAL__c,CDE_FREQ_PAID__c,NAM_PAYEE__c,NBR_DOCKET__c FROM Application_Child_Support_Deductions__r),
												(SELECT Id,AMT_INCOME_OTHER_GROSS__c,CDE_FREQ_INCOME__c,CDE_SOURCE_INCOME__c FROM Application_Other_Income__r),
                                                (SELECT Id,CDE_TYPE_SCHOOL__c,NAM_SCHOOL__c FROM Application_Education__r),
										        (SELECT Id,IND_CC_REQ__c,DTE_JOINT_CUST__c,IND_JOINT_CUST__c,DTE_BEGIN_HEAD_START__c,DTE_FOSTER__c,IND_FOSTER__c,IND_HEAD_START__c FROM Application_Custodies__r),
												(SELECT Id, AMT_INCOME_MONTH_ESTMD__c,CDE_FREQ_EXP__c,CNT_WEEK_PER_HOURS_ESTMD__c,ADR_CITY__c,ADR_LINE_1__c,ADR_LINE_2__c,ADR_STATE__c,ADR_ZIP_EXTN__c,ADR_ZIP_MAIN__c,DTE_BEGIN_EMP__c,
														NAM_BUSNS__c,NBR_PHONE__c,DTE_BEGIN_INCOME__c,NBR_PHONE_EXTN__c,DTE_BEGIN_STRIKE__c,ADR_NAM__c FROM Application_Employments__r),
											    (SELECT Id,AMT_INCOME_MONTH_ESTMD__c,CNT_WEEK_PER_HOURS_ESTMD__c,PROPRIETORSHIP__c,DTE_BEGIN_EFFV__c,ADR_CITY__c,ADR_LINE_1__c,ADR_LINE_2__c,ADR_STATE__c,ADR_ZIP_EXTN__c,ADR_ZIP_MAIN__c,
														DTE_BEGIN_EMP__c,NAM_BUSNS__c,NBR_PHONE__c,NBR_PHONE_EXTN__c,AMT_EXP_MONTH__c FROM Application_Self_Employments__r),
                                                         (SELECT id,CHILD_NAME__c,IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,CNT_HOUR_ON_FRI__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_APPLN__c,
                                                     CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_CBMS_REF__c,
                                                     CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,IDN_CBMS_PROVR__c,IDN_INDIVIDUAL__c,NAM_FACILITY__c,IND_NEED_CHILD_CARE__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c,
                                                     DTE_WITH_LAST_PROVIDER__c,IND_PROVIDER_CHANGE__c,IND_SCHOOL_AGE_CARE__c FROM Application_Child_Cares__r)
							 from T_APPLN_INDIV__c
							 where Id IN:lstApplnIndivToBeConverted];
            List<T_APPLN_CHILD_CARE__c> chilCareList = new List<T_APPLN_CHILD_CARE__c>();
            for(T_APPLN_INDIV__c eachApplnIndividual : listApplnIndivAndAllChilds){
                if(eachApplnIndividual.Application_Child_Cares__r != null && eachApplnIndividual.Application_Child_Cares__r.size()>0){
                     chilCareList.addAll(eachApplnIndividual.Application_Child_Cares__r);
                 }
                if(eachApplnIndividual.Application_Child_Support_Enforcements__r != null && eachApplnIndividual.Application_Child_Support_Enforcements__r.size()>0){
                    for(T_APPLN_CHILD_SUP__c applnDdtn:eachApplnIndividual.Application_Child_Support_Enforcements__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(eachApplnIndividual.Application_Disabilities__r != null && eachApplnIndividual.Application_Disabilities__r.size()>0){
                    for(T_APPLN_DSBLTY__c applnDdtn:eachApplnIndividual.Application_Disabilities__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(eachApplnIndividual.Application_Child_Support_Deductions__r != null && eachApplnIndividual.Application_Child_Support_Deductions__r.size()>0){
                    for(T_APPLN_DDTN__c applnDdtn:eachApplnIndividual.Application_Child_Support_Deductions__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(referralType != 'New'){
                    if(eachApplnIndividual.Application_Other_Income__r != null && eachApplnIndividual.Application_Other_Income__r.size()>0){
                    for(T_APPLN_OTHER_INCOME__c applnDdtn:eachApplnIndividual.Application_Other_Income__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                }
                
                if(eachApplnIndividual.Application_Education__r != null && eachApplnIndividual.Application_Education__r.size()>0){
                    for(T_APPLN_EDUC__c applnDdtn:eachApplnIndividual.Application_Education__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                if(eachApplnIndividual.Application_Custodies__r != null && eachApplnIndividual.Application_Custodies__r.size()>0){
                    for(T_APPLN_CUST__c applnDdtn:eachApplnIndividual.Application_Custodies__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        if(applnDdtn.IND_JOINT_CUST__c=='Y'){
                            lstSObjectToBeInserted.add(new T_INDIV_CUST__c(DTE_BEGIN_EFFV__c = applnDdtn.DTE_JOINT_CUST__c,Ignore__c = true,
                                                                           IDN_CLIENT__c = mapIndividual.get(key).Id));
                        }
                       
                        
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                 if(eachApplnIndividual.Application_Child_Cares__r != null && eachApplnIndividual.Application_Child_Cares__r.size()>0){
                    for(T_APPLN_CHILD_CARE__c applnDdtn:eachApplnIndividual.Application_Child_Cares__r){
                        String key = eachApplnIndividual.IDN_STATE__c;                        
                        if(!childCareMap.containsKey(mapCaseIndividual.get(key).Id)){
                            if(applnDdtn.IND_NEED_CHILD_CARE__c=='Y'){
                                childCareMap.put(mapCaseIndividual.get(key).Id,applnDdtn);
                                lstSObjectToBeInserted.add(new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = mapCaseIndividual.get(key).Id,
                                                                                 DTE_BEGIN_EFFV__c = System.today()));
                            }  
                        }
                        /*commenting out as part of CCCAP-14944
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);*/
                    }
                }
                if(referralType != 'New'){
                if(eachApplnIndividual.Application_Employments__r != null && eachApplnIndividual.Application_Employments__r.size()>0){
                    for(T_APPLN_EMPLMT__c applnDdtn:eachApplnIndividual.Application_Employments__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnEmployment.containsKey(key)?mapApplnEmployment.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnEmployment.put(key,lstApplnDdtn);    
                    }
                }
                if(eachApplnIndividual.Application_Self_Employments__r != null && eachApplnIndividual.Application_Self_Employments__r.size()>0){
                    for(T_APPLN_SELF_EMPLMT__c applnDdtn:eachApplnIndividual.Application_Self_Employments__r){
                        String key = eachApplnIndividual.IDN_STATE__c;
                        List<SObject> lstApplnDdtn = mapApplnSelfEmployment.containsKey(key)?mapApplnSelfEmployment.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnSelfEmployment.put(key,lstApplnDdtn);
                    }
                }
                }
                
                //Adding Indiv Verifications
                T_SBSD_INDIV__c individual = mapIndividual.get(eachApplnIndividual.IDN_STATE__c);
                String key = eachApplnIndividual.IDN_STATE__c;
                //end
            }
          if(chilCareList.size()>0){
                ChildCareLastUpdatedServices.updateRefInfo(new List<T_APPLN_CHILD_CARE__c>(),new Map<Id, T_APPLN_CHILD_CARE__c>(),chilCareList);
            }
            Map<String,T_SBSD_INDIV_EMPLMT__c> mapEmployment = new Map<String,T_SBSD_INDIV_EMPLMT__c>();
            Map<String,T_EMPLMT_INCOME__c> mapEmploymentIncome = new Map<String,T_EMPLMT_INCOME__c>();
            Map<String,T_INDIV_EMPLMT_INFO__c> mapEmployInfo = new Map<String,T_INDIV_EMPLMT_INFO__c>();
            for(String key:mapApplnEmployment.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(mapApplnEmployment.get(key), false);
                    for(SObject sOb:lstSObject){
                        if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                            sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId());
                            sOb.put('IDN_CLIENT__c',mapIndividual.get(key).Id);
                            mapEmployment.put(key,(T_SBSD_INDIV_EMPLMT__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                            mapEmploymentIncome.put(key,(T_EMPLMT_INCOME__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_INDIV_EMPLMT_INFO__c.getSObjectType()){
                            sOb.put('CDE_TYPE_INFO_EMPLMT__c','EIW');    
                            mapEmployInfo.put(key,(T_INDIV_EMPLMT_INFO__c)sOb);
                        }
                    }
                }
            }
            
            if(!mapEmployment.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmployment.values(), methodInfo);
            }
            for(String key:mapEmploymentIncome.keySet()){
                T_EMPLMT_INCOME__c empIncome = mapEmploymentIncome.get(key);
                empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key).Id;
		empIncome.Is_CBMS_Data__c = true;
                mapEmploymentIncome.put(key,empIncome);
            }
            if(!mapEmploymentIncome.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmploymentIncome.values(), methodInfo);
            }
            for(String key:mapEmployInfo.keySet()){
                T_INDIV_EMPLMT_INFO__c employInfo = mapEmployInfo.get(key);
                employInfo.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key).Id;
                mapEmployInfo.put(key,employInfo);
            }
            if(!mapEmployInfo.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmployInfo.values(), methodInfo);
            }    
            
            // Creating Self Employment Records
            mapEmployment.clear();
            mapEmploymentIncome.clear();
            Map<String,T_SBSD_EMPLMT_EXP__c> mapIncomeExpense = new Map<String,T_SBSD_EMPLMT_EXP__c>();
            for(String key:mapApplnSelfEmployment.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(mapApplnSelfEmployment.get(key), false);
                    for(SObject sOb:lstSObject){
                        if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                            sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId());
                            sOb.put('IDN_CLIENT__c',mapIndividual.get(key).Id);
                            mapEmployment.put(key,(T_SBSD_INDIV_EMPLMT__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                            sOb.put('CDE_FREQ_PAY_ESTMD__c','MON');    
                            mapEmploymentIncome.put(key,(T_EMPLMT_INCOME__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_SBSD_EMPLMT_EXP__c.getSObjectType()){
                            sOb.put('CDE_FREQ_EXP__c','MON');
                            sOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);     
                            mapIncomeExpense.put(key,(T_SBSD_EMPLMT_EXP__c)sOb);
                        }else if(sOb.getSObjectType()==Schema.T_SBSD_EMPLMT_EXP__c.getSObjectType()){
                            sOb.put('CDE_FREQ_EXP__c','MON');    
                            mapIncomeExpense.put(key,(T_SBSD_EMPLMT_EXP__c)sOb);
                        }
                    }
                }
            }
            if(!mapEmployment.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmployment.values(), methodInfo);
            }
            
            for(String key:mapEmploymentIncome.keySet()){
                T_EMPLMT_INCOME__c empIncome = mapEmploymentIncome.get(key);
                empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key).Id;
		empIncome.Is_CBMS_Data__c = true;
                mapEmploymentIncome.put(key,empIncome);
            }
            if(!mapEmploymentIncome.isEmpty()){
                GenericDMLHandler.insertRecords(mapEmploymentIncome.values(), methodInfo);
            }
            for(String key:mapIncomeExpense.keySet()){
                T_SBSD_EMPLMT_EXP__c incomeExpense = mapIncomeExpense.get(key);
                incomeExpense.IDN_EMPLMT_INDIV__c = mapEmploymentIncome.get(Key).IDN_EMPLMT_INDIV__c ;
                mapIncomeExpense.put(key,incomeExpense);
            }
            if(!mapIncomeExpense.isEmpty()){
                GenericDMLHandler.insertRecords(mapIncomeExpense.values(), methodInfo);
            }   
            for(String key:mapApplnIdChildRecords.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(mapApplnIdChildRecords.get(key), false);
                    lstSObjectToBeInserted.addAll(ConvertPeakDataToCHATS.createIndividualChildRecords(mapIndividual.get(key),caseRec,lstSObject,mapCaseIndividual));
                }
            }
            
            // To avoid System.TypeException: Cannot have more than 10 chunks in a single operation.
            List<SObject> ccCareLst = new List<SObject>();
            lstSObjectToBeInserted.sort();
            if(!lstSObjectToBeInserted.isEmpty()){
                GenericDMLHandler.insertRecords(lstSObjectToBeInserted, methodInfo);
                 for(SObject eachSOb:lstSObjectToBeInserted){
                    if(String.valueOf(eachSOb.getSObjectType())=='T_INDIV_CAT_RQ__c'){
                        ccCareLst.add(eachSOb);
                    }
                }
            }       
            
            List<T_APPLN_INDIV__c> lstApplnIndivToBeUpdated = new List<T_APPLN_INDIV__c>();
            // Linking application individuals to individuals
            Map<String,String> mapIndivDOBSSNToName = new Map<String,String>();
            for(T_SBSD_INDIV__c indiv:[SELECT Name, DOB_SSN__c FROM T_SBSD_INDIV__c WHERE Id IN:mapIndividual.values()]){
                mapIndivDOBSSNToName.put(indiv.DOB_SSN__c,indiv.Name);
            }
            List<SObject> recordsToBeUpserted = new List<SObject>();

            if(!verificationRecords.isEmpty()){
                GenericDMLHandler.insertRecords(verificationRecords, methodInfo);
            }
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(mapIndivDOBSSNToName.containsKey(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c) && String.isNotEmpty(mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c))){
                    appIndiv.IDN_CLIENT__c = mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c).length()>15?mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c).subString(0,15):mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c);
                }
                //  if(appIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code && appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0 && String.isNotEmpty(primaryCaretakerId)){
                if(String.isNotEmpty(primaryCaretakerId) && indivToRelationshipMap.containsKey(appIndiv.IDN_STATE__c)){
                    recordsToBeUpserted.add(new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = mapIndividual.get(appIndiv.IDN_STATE__c).Id,
                                                                           IDN_CLIENT__c = primaryCaretakerId,
                                                                           CDE_TYPE_REL_INDIV__c =  indivToRelationshipMap.get(appIndiv.IDN_STATE__c)
                                                                          ));   
                }
            }
            if(!lstApplnIndiv.isEmpty()){
                GenericDMLHandler.updateRecords(lstApplnIndiv, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'}}, new list<String>{'IDN_CLIENT__c'}); // Added IDN_CLIENT__c as part of CCCAP- 8307
            }
            
            if(!recordsToBeUpserted.isEmpty()){
                GenericDMLHandler.insertRecords(recordsToBeUpserted, methodInfo);
            }

            if(ccCareLst.size()>0){
                // IndividulCareLevelServices.doMethod(ccCareLst);
                objectData.put('ccCareLst', ccCareLst);
            }
            //return caseRec;
            objectData.put('caseRec', caseRec);
            isSuccessful = true;
        }catch(DMLException dEx){
            ExceptionLoggingServices.captureExceptionLog(dEx,methodInfo);
            isSuccessful = false;
            for (Integer i = 0; i < dEx.getNumDml(); i++) {
                message+=dEx.getDmlMessage(i); 
            }            
            message+='('+dEx.getLineNumber()+')';
        }catch(PeakDataToCHATSException ex){
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            isSuccessful = false;
            message += ex.message;
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            isSuccessful = false;
            message = ex.getLineNumber()+':'+ex.getMessage();
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    public static LightningServerResponse convertRefDataForTransition(string appProcessQueueId, list<String> allIndividualsList){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = 'Error: ';
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ConvertCBMSDataToCHATS','Method__c'=>'convertRefDataForTranstion'};
            List<String> indivStateIdList = new List<String>();
	    
	Set<String> indivRoadmapSet = new Set<String>();
        Map<String, String> mapOfStateIdToRoadmap = new Map<String, String>();
        Map<String,T_SBSD_ROADMAP_CORR_ID__c > mapindivStateIdToRoadmapCorr = new Map<String,T_SBSD_ROADMAP_CORR_ID__c>();
        
        List<T_APPLN_INDIV__c> lstApplnIndivs = new List<T_APPLN_INDIV__c>();
        Map<String,List<T_APPLN_EMPLMT__c>> mapApplnEmployment = new Map<String,List<T_APPLN_EMPLMT__c>>();
	Map<String,List<T_APPLN_SELF_EMPLMT__c>> mapApplnSelfEmployment = new Map<String,List<T_APPLN_SELF_EMPLMT__c>>();
        
        Map<String,List<T_APPLN_ACTIVITY__c>> mapApplnActivity = new Map<String,List<T_APPLN_ACTIVITY__c>>();
        Map<String,T_EMPLMT_INCOME__c> mapEmploymentIncome = new Map<String,T_EMPLMT_INCOME__c>();
	Map<String,T_SBSD_EMPLMT_EXP__c> mapIncomeExpense = new Map<String,T_SBSD_EMPLMT_EXP__c>();
        Map<String,List<T_APPLN_OTHER_INCOME__c>> mapApplnOtherIncome = new Map<String,List<T_APPLN_OTHER_INCOME__c>>();
        Map<String,List<SObject>> mapAppln = new Map<String,List<SObject>>();
        Map<String,T_SBSD_INDIV__c> mapStateIdToIndivRcrd = new Map<String,T_SBSD_INDIV__c>();
        
        Map<String,T_SBSD_INDIV_EMPLMT__c> mapEmployment = new Map<String,T_SBSD_INDIV_EMPLMT__c>();
        Map<String,T_INDIV_OTHER_INCOME__c> mapOtherIncome = new Map<String,T_INDIV_OTHER_INCOME__c>();
        List<T_INDIV_OTHER_INCOME__c> finalLstOfOthrIncomeToBeInserted = new List<T_INDIV_OTHER_INCOME__c>();
        List<T_EMPLMT_INCOME__c> finalLstOfEmplIncomeToBeInserted = new List<T_EMPLMT_INCOME__c>();
        List<T_EMPLMT_PAY_STUB__c> finalLstOfEmplPayStubToBeInserted= new List<T_EMPLMT_PAY_STUB__c>();
	List<T_INDIV_EMPLMT_VERIF__c> finalListOfEmplVerifRecrdToBeInserted= new List<T_INDIV_EMPLMT_VERIF__c>();
        List<T_PRIM_ACTV__c> lstPrmryActivityToBeInserted = new List<T_PRIM_ACTV__c>();
        
	Map<String,String> mapOfCBMSActvCodeTOCHATSActvType = new Map<String,String>();
        set<string> actvCodesSetForIndividual = new set<string>();
        try{
        //Get all the picklist translation mappings
        ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
        
        
        if(allIndividualsList != null && allIndividualsList.size()>0){
            lstApplnIndivs = [SELECT Id, IDN_STATE__c, IDN_APPLN__c, ROADMAP_CORR_ID__c,
                              (SELECT 	Id, CDE_TYPE_ACTV__C, DTE_BEGIN_ACTV_PRIM__C, DTE_END_ACTV_PRIM__C,External_ID__c FROM Application_Activities__r),
                              (SELECT	Id, CDE_FREQ_INCOME__c, AMT_INCOME_OTHER_GROSS__c, CDE_SOURCE_INCOME__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,CDE_TYPE_VERIF__c,CDE_SOURCE_VRFYD_INCOME__c,CNT_HOURS_WORKED__c FROM Application_Other_Income__r),
                              (SELECT 	Id, AMT_INCOME_MONTH_ESTMD__c,CDE_FREQ_EXP__c,CNT_WEEK_PER_HOURS_ESTMD__c,ADR_CITY__c,ADR_LINE_1__c,ADR_LINE_2__c,ADR_STATE__c,ADR_ZIP_EXTN__c,
                               				ADR_ZIP_MAIN__c,DTE_BEGIN_EMP__c,DTE_END_EMP__c,NAM_BUSNS__c,NBR_PHONE__c,DTE_BEGIN_INCOME__c,NBR_PHONE_EXTN__c,DTE_BEGIN_STRIKE__c,ADR_NAM__c,PROPRIETORSHIP__c, 
                               				DTE_BEGIN_EFFV_INCOME__c,CDE_FREQ_INCOME__c,INCOME_FREQUENCY__c,TOTAL_WEEKLY_HOURS_WORKED__c,DTE_PAY__c, CDE_TYPE_VERIF__c, AMT_INCOME_GROSS_PAY_STUB__c FROM Application_Employments__r),
                              (SELECT 	Id, NAM_BUSNS__c, ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c, NBR_PHONE__c, NBR_PHONE_EXTN__c,
							DTE_BEGIN_EMP__c,DTE_END_EMP__c,AMT_INCOME_MONTH_ESTMD__c, CNT_WEEK_PER_HOURS_ESTMD__c, DTE_BEGIN_EFFV__c,AMT_EXP_MONTH__c,CDE_FREQ_INCOME__c, 
							DTE_BEGIN_EFFV_INCOME__c,INCOME_FREQUENCY__c,TOTAL_WEEKLY_HOURS_WORKED__C, DTE_PAY__C, CDE_TYPE_VERIF__C,PROPRIETORSHIP__c,
                               				AMT_INCOME_GROSS_PAY_STUB__c FROM Application_Self_Employments__r)
                              FROM T_APPLN_INDIV__c where Id IN: allIndividualsList];
            
        }
        
        for(T_APPLN_INDIV__c eachApplnIndividual : lstApplnIndivs){
		
	    if(eachApplnIndividual.ROADMAP_CORR_ID__c != null){
                indivRoadmapSet.add(eachApplnIndividual.ROADMAP_CORR_ID__c);
            }
		
            if(eachApplnIndividual.IDN_STATE__c != null){
                indivStateIdList.add(eachApplnIndividual.IDN_STATE__c);
            }
            if(eachApplnIndividual.Application_Employments__r != null && eachApplnIndividual.Application_Employments__r.size()>0){
                for(T_APPLN_EMPLMT__c applnDdtn:eachApplnIndividual.Application_Employments__r){
                    String key = eachApplnIndividual.IDN_STATE__c;
                    List<T_APPLN_EMPLMT__c> lstApplnDdtn = mapApplnEmployment.containsKey(key)?mapApplnEmployment.get(key):new List<T_APPLN_EMPLMT__c>();
                    lstApplnDdtn.add(applnDdtn);  
                    mapApplnEmployment.put(key,lstApplnDdtn);    
                }
            }
            if(eachApplnIndividual.Application_Self_Employments__r != null && eachApplnIndividual.Application_Self_Employments__r.size()>0){
                for(T_APPLN_SELF_EMPLMT__c applnDdtn:eachApplnIndividual.Application_Self_Employments__r){
                    String key = eachApplnIndividual.IDN_STATE__c;
                    List<T_APPLN_SELF_EMPLMT__c> lstApplnDdtn = mapApplnSelfEmployment.containsKey(key)?mapApplnSelfEmployment.get(key):new List<T_APPLN_SELF_EMPLMT__c>();
                    lstApplnDdtn.add(applnDdtn);  
                    mapApplnSelfEmployment.put(key,lstApplnDdtn);    
                }
            }
            if(eachApplnIndividual.Application_Activities__r != null && eachApplnIndividual.Application_Activities__r.size()>0){
                for(T_APPLN_ACTIVITY__c applnDdtn:eachApplnIndividual.Application_Activities__r){
                    String key = eachApplnIndividual.IDN_STATE__c;
                    List<T_APPLN_ACTIVITY__c> lstApplnDdtn = mapApplnActivity.containsKey(key)?mapApplnActivity.get(key):new List<T_APPLN_ACTIVITY__c>();
                    lstApplnDdtn.add(applnDdtn);  
                    mapApplnActivity.put(key,lstApplnDdtn);    
                }
            }
            if(eachApplnIndividual.Application_Other_Income__r != null && eachApplnIndividual.Application_Other_Income__r.size()>0){
                for(T_APPLN_OTHER_INCOME__c applnDdtn:eachApplnIndividual.Application_Other_Income__r){
                    String key = eachApplnIndividual.IDN_STATE__c;
                    List<T_APPLN_OTHER_INCOME__c> lstApplnDdtn = mapApplnOtherIncome.containsKey(key)?mapApplnOtherIncome.get(key):new List<T_APPLN_OTHER_INCOME__c>();
                    lstApplnDdtn.add(applnDdtn);  
                    mapApplnOtherIncome.put(key,lstApplnDdtn);    
                }
            }
        }
        
        
        if(indivStateIdList != null){
            for(T_SBSD_INDIV__c eachChatsIndiv : [select Id,Name,IDN_STATE__c,Age__c, Is_Primary_Parent_Caretaker__c FROM T_SBSD_INDIV__c where IDN_STATE__c in: indivStateIdList]){
                mapStateIdToIndivRcrd.put(eachChatsIndiv.IDN_STATE__c, eachChatsIndiv);
            }
        }
	if(indivRoadmapSet != null){
            for(T_SBSD_ROADMAP_CORR_ID__c eachRoadmapRcrd : [select Id, ROADMAP_CORR_ID__c, INDIVIDUAL__c, INDIVIDUAL__r.IDN_STATE__c FROM T_SBSD_ROADMAP_CORR_ID__c where ROADMAP_CORR_ID__c IN:indivRoadmapSet]){
                mapOfStateIdToRoadmap.put(eachRoadmapRcrd.INDIVIDUAL__r.IDN_STATE__c, eachRoadmapRcrd.ROADMAP_CORR_ID__c);
            }
        }
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c,IDN_APPLN__r.CBMS_CASE_NUM__c, IDN_CASE__c, County_Name__r.Name, DTE_RCVD_APPLN__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId];
        
	for(T_APPLN_INDIV__c eachapplnIndivCheckForroadmap : lstApplnIndivs){
            if(eachapplnIndivCheckForroadmap.ROADMAP_CORR_ID__c != null){
                if(mapOfStateIdToRoadmap.containsKey(eachapplnIndivCheckForroadmap.IDN_STATE__c) && mapOfStateIdToRoadmap.get(eachapplnIndivCheckForroadmap.IDN_STATE__c) == eachapplnIndivCheckForroadmap.ROADMAP_CORR_ID__c){
                    
                } else {
                    T_SBSD_ROADMAP_CORR_ID__c chatsIndivRoadmapCorr = new T_SBSD_ROADMAP_CORR_ID__c(APPLICATION_PROCESS_QUEUE__c = appProcessQueue[0].Id,  IDN_CASE__c = appProcessQueue[0].IDN_CASE__c, 
                                                                                                        CBMS_CASE_NUM__c = appProcessQueue[0].IDN_APPLN__r.CBMS_CASE_NUM__c, DATE_RECEIVED__c = appProcessQueue[0].DTE_RCVD_APPLN__c,
                                                                                                        INDIVIDUAL__c = mapStateIdToIndivRcrd.get(eachapplnIndivCheckForroadmap.IDN_STATE__c).Id, ROADMAP_CORR_ID__c = eachapplnIndivCheckForroadmap.ROADMAP_CORR_ID__c);
                        mapindivStateIdToRoadmapCorr.put(eachapplnIndivCheckForroadmap.IDN_STATE__c, chatsIndivRoadmapCorr);
                }
            }
        }
		
        if(!mapindivStateIdToRoadmapCorr.isEmpty()){
            GenericDMLHandler.insertRecords(mapindivStateIdToRoadmapCorr.values(), methodInfo);
        }
        //Primary Activity Insert
	
        for(Conversion_Picklist_Mapping__mdt mapping:[SELECT MasterLabel ,PEAK_Data__c, CHATS_Picklist_Mapping__c FROM Conversion_Picklist_Mapping__mdt where MasterLabel = 'CBMS_ACTV_TYP']){
               mapOfCBMSActvCodeTOCHATSActvType.put(mapping.PEAK_Data__c, mapping.CHATS_Picklist_Mapping__c);
        }
        
        for(String key:mapApplnActivity.keySet()){
	    actvCodesSetForIndividual.clear();
	    for(T_APPLN_ACTIVITY__c eachApplnActivity : mapApplnActivity.get(key)){
                String peakData = String.valueOf(Integer.valueOf(eachApplnActivity.CDE_TYPE_ACTV__c));
                if(mapOfCBMSActvCodeTOCHATSActvType.containsKey(peakData)){
                    actvCodesSetForIndividual.add(mapOfCBMSActvCodeTOCHATSActvType.get(peakData));
                }
            }
            for(T_APPLN_ACTIVITY__c eachApplnActivity : mapApplnActivity.get(key)){
                T_PRIM_ACTV__c eachNewPrmActivity = new T_PRIM_ACTV__c();
		
		if(eachApplnActivity.CDE_TYPE_ACTV__c != null){
                    String peakData1 = String.valueOf(Integer.valueOf(eachApplnActivity.CDE_TYPE_ACTV__c));
                    if(mapOfCBMSActvCodeTOCHATSActvType.containsKey(peakData1)){
                        eachNewPrmActivity.CDE_TYPE_ACTV__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('CBMS_ACTV_TYP',peakData1);
                    } else if (actvCodesSetForIndividual.contains('EMP')){
                        eachNewPrmActivity.CDE_TYPE_ACTV__c = 'EMP';
                    } else if(actvCodesSetForIndividual.contains('GED')){
                        eachNewPrmActivity.CDE_TYPE_ACTV__c = 'GED';
                    } else {
                        eachNewPrmActivity.CDE_TYPE_ACTV__c = 'JS';
                    }
                    //eachNewPrmActivity.CDE_TYPE_ACTV__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('CBMS_ACTV_TYP', eachApplnActivity.CDE_TYPE_ACTV__c);
                }
		eachNewPrmActivity.DTE_BEGIN_ACTV_PRIM__c = eachApplnActivity.DTE_BEGIN_ACTV_PRIM__c;
                eachNewPrmActivity.DTE_END_ACTV_PRIM__c =eachApplnActivity.DTE_END_ACTV_PRIM__c;
                //eachNewPrmActivity.IDN_EXTNL__c = eachApplnActivity.External_ID__c;
		eachNewPrmActivity.Is_CBMS_Data__c = true;
                eachNewPrmActivity.IDN_CASE__c =appProcessQueue[0].IDN_CASE__c;
                eachNewPrmActivity.IDN_CLIENT__c = mapStateIdToIndivRcrd.get(key).Id;
                lstPrmryActivityToBeInserted.add(eachNewPrmActivity);
            }
        }
        if(!lstPrmryActivityToBeInserted.isEmpty()){
            GenericDMLHandler.insertRecords(lstPrmryActivityToBeInserted, methodInfo);
        }
        
        //Other Income Insert
        for(String key : mapApplnOtherIncome.keySet()){
            List<T_APPLN_OTHER_INCOME__c> listOfOtherIncomeRecords = mapApplnOtherIncome.get(key);
            for(T_APPLN_OTHER_INCOME__c eachOtherIncomeRecord : listOfOtherIncomeRecords){
                List<T_APPLN_OTHER_INCOME__c> listOfOneOtherIncomeRecord = new List<T_APPLN_OTHER_INCOME__c>();
                listOfOneOtherIncomeRecord.add(eachOtherIncomeRecord);
                
                List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(listOfOneOtherIncomeRecord, false);
                for(SObject sOb:lstSObject){
                    if(sOb.getSObjectType()==Schema.T_INDIV_OTHER_INCOME__c.getSObjectType()){
                        sOb.put('CDE_SOURCE_INCOME__c',ConversionPicklistMappingUtility.translatePEAKToCHATSData('TOIC', eachOtherIncomeRecord.CDE_SOURCE_INCOME__c));
                        sOb.put('CDE_TYPE_VERIF__c',eachOtherIncomeRecord.CDE_TYPE_VERIF__c=='Y'?'V':eachOtherIncomeRecord.CDE_TYPE_VERIF__c=='N'?'NA':null);
                        sOb.put('CDE_SOURCE_VRFYD_INCOME__c',eachOtherIncomeRecord.CDE_TYPE_VERIF__c=='Y'?'TF':null);
                        sOb.put('DTE_BEGIN_EFFV__c',eachOtherIncomeRecord.DTE_BEGIN_EFFV__c);
                        sOb.put('DTE_END_EFFV__c',eachOtherIncomeRecord.DTE_END_EFFV__c);
                        sOb.put('CNT_HOURS_WEEK__c',eachOtherIncomeRecord.CNT_HOURS_WORKED__c);
                        sOb.put('IDN_CLIENT__c',mapStateIdToIndivRcrd.get(key).Id);
                        
                        mapOtherIncome.put(key,(T_INDIV_OTHER_INCOME__c)sOb);
                        finalLstOfOthrIncomeToBeInserted.add((T_INDIV_OTHER_INCOME__c)sOb);
                        
                    }
                }
            }
        }
        if(!finalLstOfOthrIncomeToBeInserted.isEmpty()){
            GenericDMLHandler.insertRecords(finalLstOfOthrIncomeToBeInserted, methodInfo);
        }
        
        //Employment information and its related child objects Logic
        for(String key:mapApplnEmployment.keySet()){
            List<T_APPLN_EMPLMT__c> listOfEmploymentRecords = mapApplnEmployment.get(key);
            for(T_APPLN_EMPLMT__c eachEmploymentRecord : listOfEmploymentRecords){
                mapEmployment.clear();
                mapEmploymentIncome.clear();
                finalLstOfEmplIncomeToBeInserted.clear();
                finalLstOfEmplPayStubToBeInserted.clear();
                finalListOfEmplVerifRecrdToBeInserted.clear();
                List<T_APPLN_EMPLMT__c> listOfOneEmpRecord = new List<T_APPLN_EMPLMT__c>();
                listOfOneEmpRecord.add(eachEmploymentRecord);
                
                List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(listOfOneEmpRecord, false);
                for(SObject sOb:lstSObject){
                    if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                        sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId());
                        sOb.put('IDN_CLIENT__c',mapStateIdToIndivRcrd.get(key).Id);
			//Start--CCCAP-6576: set ignore__c to True when the individual is Non-Primary Caretaker and TeenAge
                            if(!mapStateIdToIndivRcrd.get(key).Is_Primary_Parent_Caretaker__c == true && mapStateIdToIndivRcrd.get(key).Age__c < Decimal.valueOf(Label.Teen_Parent_Age_Limit)){
                                sOb.put('Ignore__c', true);
                            }
                            //End--CCCAP-6576: set ignore__c to True when the individual is Non-Primary Caretaker and TeenAge    
			sOb.put('Is_CBMS_Data__c',true);
                        sOb.put('IDN_CASE__c',appProcessQueue[0].IDN_CASE__c);
                        sOb.put('DTE_END_EFFV__c',eachEmploymentRecord.DTE_END_EMP__c);
                        mapEmployment.put(key,(T_SBSD_INDIV_EMPLMT__c)sOb);
                    }else if(sOb.getSObjectType() == Schema.SObjectType.T_EMPLMT_INCOME__c.getSObjectType()){
                        sOb.put('PROPRIETORSHIP__c', eachEmploymentRecord.PROPRIETORSHIP__c);
                        sOb.put('DTE_BEGIN_EFFV__c', eachEmploymentRecord.DTE_BEGIN_EFFV_INCOME__c);
			sOb.put('CDE_TYPE_VERIF__c', 'V');
                        sOb.put('CDE_SOURCE_VRFYD_PAY__c', 'CWR');
			sOb.put('Is_CBMS_Data__c', true);
                        sOb.put('CDE_FREQ_PAY_ESTMD__c',ConversionPicklistMappingUtility.translatePEAKToCHATSData('TFRQ', eachEmploymentRecord.CDE_FREQ_INCOME__c));
                        mapEmploymentIncome.put(key,(T_EMPLMT_INCOME__c)sOb);
                    }
                }
                
                if(!mapEmployment.isEmpty()){
                    GenericDMLHandler.insertRecords(mapEmployment.values(), methodInfo);
                }
                //Employment Income Records insert
                for(String key1:mapEmploymentIncome.keySet()){
                    T_EMPLMT_INCOME__c empIncome = mapEmploymentIncome.get(key1);
                    empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key1).Id;
                    finalLstOfEmplIncomeToBeInserted.add(empIncome);
                    mapEmploymentIncome.put(key1,empIncome);
                }
                if(!finalLstOfEmplIncomeToBeInserted.isEmpty()){
                    GenericDMLHandler.insertRecords(finalLstOfEmplIncomeToBeInserted, methodInfo);
                }
                //EmploymentVerification Records
                for(T_SBSD_INDIV_EMPLMT__c eachEmpl : mapEmployment.values()){
                    T_INDIV_EMPLMT_VERIF__c eachEmplVerifRecrd = new T_INDIV_EMPLMT_VERIF__c();
                    eachEmplVerifRecrd.IDN_EMPLMT_INDIV__c = eachEmpl.Id;
                    eachEmplVerifRecrd.CDE_TYPE_VERIF__c = 'V';
                    finalListOfEmplVerifRecrdToBeInserted.add(eachEmplVerifRecrd);
                }
                if(!finalListOfEmplVerifRecrdToBeInserted.isEmpty()){
                    GenericDMLHandler.insertRecords(finalListOfEmplVerifRecrdToBeInserted, methodInfo);
                }
                //Employment Stub info - insert
                T_EMPLMT_PAY_STUB__c newPayStubRcrd = new T_EMPLMT_PAY_STUB__c();
                newPayStubRcrd.CDE_FREQ_PAY__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TFRQ', eachEmploymentRecord.INCOME_FREQUENCY__c);
                newPayStubRcrd.CNT_WORKED_HOURS_STUB_PAY__c = eachEmploymentRecord.TOTAL_WEEKLY_HOURS_WORKED__c;
                newPayStubRcrd.AMT_INCOME_GROSS__c = eachEmploymentRecord.AMT_INCOME_GROSS_PAY_STUB__c;
                newPayStubRcrd.DTE_PAY__c = eachEmploymentRecord.DTE_PAY__c;
                newPayStubRcrd.CDE_TYPE_VERIF__c = (eachEmploymentRecord.CDE_TYPE_VERIF__c=='Y' || eachEmploymentRecord.CDE_TYPE_VERIF__c=='R')?'V':eachEmploymentRecord.CDE_TYPE_VERIF__c=='N'?'NA':null;
                newPayStubRcrd.CDE_SOURCE_VRFYD_PAY__c = (eachEmploymentRecord.CDE_TYPE_VERIF__c=='Y' || eachEmploymentRecord.CDE_TYPE_VERIF__c=='R')?'CWR':null;
                newPayStubRcrd.IDN_EMPLMT_INCOME__c=finalLstOfEmplIncomeToBeInserted[0].Id;
                finalLstOfEmplPayStubToBeInserted.add(newPayStubRcrd);
                if(!finalLstOfEmplPayStubToBeInserted.isEmpty()){
                    GenericDMLHandler.insertRecords(finalLstOfEmplPayStubToBeInserted, methodInfo);
                }
            }
        }
        
        
        //employment records based on Self Employment
        for(String key:mapApplnSelfEmployment.keySet()){
            List<T_APPLN_SELF_EMPLMT__c> listOfSelfEmploymentRecords = mapApplnSelfEmployment.get(key);
            for(T_APPLN_SELF_EMPLMT__c eachSelfEmploymentRecord : listOfSelfEmploymentRecords){
                mapEmployment.clear();
                mapEmploymentIncome.clear();
                finalLstOfEmplIncomeToBeInserted.clear();
                finalLstOfEmplPayStubToBeInserted.clear();
                finalListOfEmplVerifRecrdToBeInserted.clear();
                List<T_APPLN_SELF_EMPLMT__c> listOfOneSelfEmpRecord = new List<T_APPLN_SELF_EMPLMT__c>();
                listOfOneSelfEmpRecord.add(eachSelfEmploymentRecord);
                
                List<SObject> lstSObject = APXPolicyRecordsServices.createPolicyRecords(listOfOneSelfEmpRecord, false);
                for(SObject sOb:lstSObject){
                            if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                                sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId());
                                sOb.put('IDN_CLIENT__c',mapStateIdToIndivRcrd.get(key).Id);
				//Start--CCCAP-6576: set ignore__c to True when the individual is Non-Primary Caretaker and TeenAge
                            	    if(!mapStateIdToIndivRcrd.get(key).Is_Primary_Parent_Caretaker__c == true && mapStateIdToIndivRcrd.get(key).Age__c < Decimal.valueOf(Label.Teen_Parent_Age_Limit)){
                                    sOb.put('Ignore__c', true);
                                }//End--CCCAP-6576: set ignore__c to True when the individual is Non-Primary Caretaker and TeenAge    
				sOb.put('Is_CBMS_Data__c',true);
                                sOb.put('IDN_CASE__c',appProcessQueue[0].IDN_CASE__c);
								sOb.put('DTE_END_EFFV__c',eachSelfEmploymentRecord.DTE_END_EMP__c);
                                mapEmployment.put(key,(T_SBSD_INDIV_EMPLMT__c)sOb);
                            }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                                //sOb.put('CDE_FREQ_PAY_ESTMD__c','MON');    
								sOb.put('PROPRIETORSHIP__c', eachSelfEmploymentRecord.PROPRIETORSHIP__c);
								sOb.put('DTE_BEGIN_EFFV__c', eachSelfEmploymentRecord.DTE_BEGIN_EFFV_INCOME__c);
								sOb.put('CDE_TYPE_VERIF__c', 'V');
								sOb.put('CDE_SOURCE_VRFYD_PAY__c', 'CWR');
				    				sOb.put('Is_CBMS_Data__c', true);
								sOb.put('CDE_FREQ_PAY_ESTMD__c',ConversionPicklistMappingUtility.translatePEAKToCHATSData('TFRQ', eachSelfEmploymentRecord.CDE_FREQ_INCOME__c));
                                mapEmploymentIncome.put(key,(T_EMPLMT_INCOME__c)sOb);
                            }else if(sOb.getSObjectType()==Schema.T_SBSD_EMPLMT_EXP__c.getSObjectType()){
                                sOb.put('CDE_FREQ_EXP__c','MON');
                                //sOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);     
                                mapIncomeExpense.put(key,(T_SBSD_EMPLMT_EXP__c)sOb);
                            }
                        }
                
                if(!mapEmployment.isEmpty()){
                    GenericDMLHandler.insertRecords(mapEmployment.values(), methodInfo);
                }
                //Employment Income Records insert
                for(String key1:mapEmploymentIncome.keySet()){
                    T_EMPLMT_INCOME__c empIncome = mapEmploymentIncome.get(key1);
                    empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key1).Id;
                    finalLstOfEmplIncomeToBeInserted.add(empIncome);
                    mapEmploymentIncome.put(key1,empIncome);
                }
                if(!finalLstOfEmplIncomeToBeInserted.isEmpty()){
                    GenericDMLHandler.insertRecords(finalLstOfEmplIncomeToBeInserted, methodInfo);
                }
                
                //Employment Stub info - insert
                if(eachSelfEmploymentRecord.DTE_PAY__c != null){
                    T_EMPLMT_PAY_STUB__c newPayStubRcrd = new T_EMPLMT_PAY_STUB__c();
                    newPayStubRcrd.CDE_FREQ_PAY__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TFRQ', eachSelfEmploymentRecord.INCOME_FREQUENCY__c);
                    newPayStubRcrd.CNT_WORKED_HOURS_STUB_PAY__c = eachSelfEmploymentRecord.TOTAL_WEEKLY_HOURS_WORKED__c;
                    newPayStubRcrd.AMT_INCOME_GROSS__c = eachSelfEmploymentRecord.AMT_INCOME_GROSS_PAY_STUB__c;
                    newPayStubRcrd.DTE_PAY__c = eachSelfEmploymentRecord.DTE_PAY__c;
                    newPayStubRcrd.CDE_TYPE_VERIF__c = (eachSelfEmploymentRecord.CDE_TYPE_VERIF__c=='Y' || eachSelfEmploymentRecord.CDE_TYPE_VERIF__c=='R')?'V':eachSelfEmploymentRecord.CDE_TYPE_VERIF__c=='N'?'NA':null;
                    newPayStubRcrd.CDE_SOURCE_VRFYD_PAY__c = (eachSelfEmploymentRecord.CDE_TYPE_VERIF__c=='Y' || eachSelfEmploymentRecord.CDE_TYPE_VERIF__c=='R')?'CWR':null;
                    newPayStubRcrd.IDN_EMPLMT_INCOME__c=finalLstOfEmplIncomeToBeInserted[0].Id;
                    finalLstOfEmplPayStubToBeInserted.add(newPayStubRcrd);
                    if(!finalLstOfEmplPayStubToBeInserted.isEmpty()){
                        GenericDMLHandler.insertRecords(finalLstOfEmplPayStubToBeInserted, methodInfo, new list<String>{'IDN_EMPLMT_INCOME__c','CDE_FREQ_PAY__c','CNT_WORKED_HOURS_STUB_PAY__c','AMT_INCOME_GROSS__c','DTE_PAY__c','CDE_TYPE_VERIF__c','CDE_SOURCE_VRFYD_PAY__c'}); // Added fields as part of CCCAP-8307
                    }
                }
            }
        }
        }catch(DMLException dEx){
            ExceptionLoggingServices.captureExceptionLog(dEx,methodInfo);
            isSuccessful = false;
            for (Integer i = 0; i < dEx.getNumDml(); i++) {
                message+=dEx.getDmlMessage(i); 
            }            
            message+='('+dEx.getLineNumber()+')';
        }catch(PeakDataToCHATSException ex){
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            isSuccessful = false;
            message += ex.message;
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            isSuccessful = false;
            message = ex.getLineNumber()+':'+ex.getMessage();
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
   
    public class PeakDataToCHATSException extends Exception{
        public String message;
    }
    
    public static List<SObject> createIndividualChildRecords(T_SBSD_INDIV__c individual, 
                                                             T_SBSD_CASE__c caseRec, 
                                                             List<SObject> lstChildRecords,
                                                             Map<String,T_SBSD_CASE_INDIV__c> mapCaseIndividual){
                                                                 List<SObject> lstIndividualChildRecords = new List<SObject>();
                                                                 for(SObject sOb:lstChildRecords){
                                                                     if(sOb.getSObjectType()==Schema.T_INDIV_EDUC__c.getSObjectType() || sOb.getSObjectType()==Schema.T_INDIV_TRAIN__c.getSObjectType()){
                                                                         Integer age = (System.today().year() - individual.DTE_DOB__c.year()) - 
                                                                             (System.today().month()<individual.DTE_DOB__c.month() || (System.today().month()==individual.DTE_DOB__c.month() 
                                                                                                                                       && System.today().day()<individual.DTE_DOB__c.day())?1:0);
                                                                         if((sOb.getSObjectType()==Schema.T_INDIV_EDUC__c.getSObjectType() && age>18) ||
                                                                            (sOb.getSObjectType()==Schema.T_INDIV_TRAIN__c.getSObjectType() && age<19) 
                                                                           ){
                                                                               continue;
                                                                           }
                                                                         if(sOb.getSObjectType()==Schema.T_INDIV_TRAIN__c.getSObjectType()){
                                                                             sOb.put('DTE_BEGIN_EFFV__c',System.today());
                                                                         }
                                                                         sOb.put('IDN_CLIENT__c',individual.Id);
                                                                         lstIndividualChildRecords.add(sOb);                                                                           
                                                                     }else{
                                                                         sOb.put('IDN_CLIENT__c',individual.Id);
                                                                         lstIndividualChildRecords.add(sOb);                                                                           
                                                                     }
                                                                 }
                                                                 return lstIndividualChildRecords;
                                                             }  
}