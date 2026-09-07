public with sharing class ConvertPeakDataToCHATS {

    public static Date getNextBusinessDay(Date expectedNextBusinessDay, set<Date> holidays){
        DateTime dt = Datetime.newInstance(expectedNextBusinessDay.year(), expectedNextBusinessDay.month(), expectedNextBusinessDay.day());
        String dayOfWeek = dt.format('E');
        if(holidays.contains(expectedNextBusinessDay) || dayOfWeek=='Sat' || dayOfWeek=='Sun'){
            return getNextBusinessDay(expectedNextBusinessDay.addDays(1),holidays);
        }
        return expectedNextBusinessDay;
    }
    
    public static LightningServerResponse convertData(T_APPLN_PRCS_QUEUE__c appProcessQueue, List<String> individualIds){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message = 'Error: ';
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ConvertPeakDataToCHATS','Method__c'=>'convertData'};
        try{
        	//Get all the picklist translation mappings
            ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
            //Logic to clone T_APPLN records to T_SBSD records  
            //
            List<SObject> lstSObjectToBeInserted = new List<SObject>();
            List<T_SBSD_INDIV__c> lstIndiv = new List<T_SBSD_INDIV__c>();
            List<T_SBSD_INDIV_INFO__c> lstIndivInfo = new List<T_SBSD_INDIV_INFO__c>();
            List<T_SBSD_INDIV_MIL__c> lstIndivMil = new List<T_SBSD_INDIV_MIL__c>();
            List<SObject> existingIndivToUpdate = new List<SObject>(); // added for UFE
            List<String> additionalAdultRels = new List<String>{'H', 'CLH', 'CLW', 'LIC', 'SO', 'W', 'X'}; //added for CCCAP-13633
            
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
            Integer daysToBeAdded = 0;
            set<Date> holidays = new set<Date>();
            for(T_YEAR_HOL__c holiday:[SELECT DTE_HOL__c FROM T_YEAR_HOL__c WHERE DTE_HOL__c>=:appProcessQueue.CreatedDate.date() AND DTE_HOL__c<=:appProcessQueue.CreatedDate.date().addMonths(1)]){
                holidays.add(holiday.DTE_HOL__c);
            }
            if(appProcessQueue.CreatedDate.hour()>=17){
                daysToBeAdded = 1;
            }
            caseRec.DTE_APPLN__c = getNextBusinessDay(appProcessQueue.CreatedDate.date().addDays(daysToBeAdded), holidays);
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
            caseRec.Is_Peak_Data__c = true;
            caseRec.Bypass_CaseName_ValidationRule__c = TRUE; // Added by Rishav for CCCAP-2720
            
            GenericDMLHandler.insertRecords(new List<SObject>{caseRec}, methodInfo, new List<String>{'CDE_COUNTY__c','DTE_APPLN__c','DTE_CHGD_LAST_DATA_ELIGTY__c','IND_CHGD_DATA_ELIGTY__c','Is_Peak_Data__c','Bypass_CaseName_ValidationRule__c'}); // Added field names for CCCAP-8307

            //T_SBSD_CASE_STATUS_MODE record for the case with the following values: CDE_MODE_CASE = Intake, CDE_STATUS_CASE = Pending, DTE_EFFV_BEGIN = Today
            GenericDMLHandler.insertRecords(new List<SObject>{new T_SBSD_CASE_STATUS_MODE__c(
                IDN_CASE__c = caseRec.Id,
                CDE_MODE_CASE__c = 'INT',
                CDE_STATUS_CASE__c = 'PEN',
                DTE_BEGIN_EFFV__c = System.today()
            )}, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_CASE_STATUS_MODE__c'}}, new List<String>{'IDN_CASE__c','CDE_MODE_CASE__c','CDE_STATUS_CASE__c','DTE_BEGIN_EFFV__c'}); // Added field names for CCCAP-8307

            
            
             List<T_APPLN_INDIV__c> lstApplnIndiv = [SELECT Id, CDE_GENDER__c,CBMS_DENIAL_REASON__c,CDE_SOURCE_VRFYD_CITIZEN__c,CDE_VRFYD_CITIZEN__c,IDN_CBMS_CLIENT__c,IND_IPV__c,ROADMAP_CORR_ID__c,
                                                    CDE_LEVEL_GRADE_HGHST__c,
                                                    CDE_STATUS_MAR__c,
                                                    DTE_DOB__c,
                                                    DTE_Death__c,// added for SIDMOD CCCAP-7695 by Shashank
                                                    IND_NOTIF_SIDMOD__c,// added for SIDMOD CCCAP-10315 by Shashank
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
                                                    (SELECT id,IDN_INDIVIDUAL__c,NAM_FACILITY__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c FROM Application_Child_Cares__r),
                                                    (SELECT DTE_BEGIN_EFFV__c FROM Application_Job_Search__r),
                                                    (SELECT Id, CDE_TYPE_REL_INDIV__c, IDN_APPLN_REL__c, IDN_SEQ_INDIV_RELTD__c
                                                     FROM Application_Relationships__r
                                                    )
                                                    FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c AND Id IN:individualIds];
            Set<String> setDOB_SSN = new Set<String>();
            Map<String, String> mapStateIdWithPrimaryCaretaker = new Map<String, String>();
            List<T_APPLN_ADR__c> lstAppAdr = new List<T_APPLN_ADR__c>();
            Map<String,T_SBSD_CASE_INDIV__c> mapCaseIndividual = new Map<String,T_SBSD_CASE_INDIV__c>();
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
                mapIndivSequenceToIndiv.put(appIndiv.IDN_SEQ_INDIV__c, appIndiv.IDN_STATE__c);
            }
            
            for(T_APPLN_PRCS_ADDNL_INFO__c applnPrcsAddInfo:lstApplnCase.get(0).Application_case_38__r){
                lstCaseChildRecords.add(new T_CW_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseRec.Id,
                                                               TANF_RCVNG__c =applnPrcsAddInfo.IND_TANF_RCVNG__c,
                                                               DTE_BEGIN_EFFEV__c = caseRec.DTE_APPLN__c));
            }
            
            lstCaseChildRecords.add(new T_SBSD_CASE_INFO__c(IDN_CASE__c = caseRec.Id, CDE_TYPE_INFO_CASE__c =  'PMC', TXT_VALUE_INFO_CASE__c = lstApplnCase.get(0).CDE_INFO_PMC__c));
            //Added mapping for case information record with email data
            if(String.isNotEmpty(lstApplnCase.get(0).CDE_INFO_EM__c)){
                lstCaseChildRecords.add(new T_SBSD_CASE_INFO__c(IDN_CASE__c = caseRec.Id, CDE_TYPE_INFO_CASE__c =  'EM', TXT_VALUE_INFO_CASE__c = lstApplnCase.get(0).CDE_INFO_EM__c));
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
            
            Map<String,T_SBSD_INDIV__c> mapExistingIndiv = new Map<String,T_SBSD_INDIV__c>();
            List<T_SBSD_INDIV__c> existingIndivList = [SELECT Id, IDN_STATE__c, CDE_GENDER__c FROM T_SBSD_INDIV__c WHERE IDN_STATE__c IN:mapStateIdWithPrimaryCaretaker.keySet()];
            for(T_SBSD_INDIV__c existingIndiv: existingIndivList){
                mapExistingIndiv.put(existingIndiv.IDN_STATE__c,existingIndiv);
            }

            //added for CCCAP-13633
            Map<String,String> existingIndivToRelationshipMap = new Map<String,String>(); //added for CCCAP-13633
            String relationshipType, peakRefTable, gender;
            if(!mapExistingIndiv.isEmpty()){
                for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                    if(appIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code && appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0){
                        for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                            if(mapIndivSequenceToIndiv.containsKey(applnRel.IDN_SEQ_INDIV_RELTD__c) && mapExistingIndiv.containsKey(mapIndivSequenceToIndiv.get(applnRel.IDN_SEQ_INDIV_RELTD__c))){
                                gender = mapExistingIndiv.get(mapIndivSequenceToIndiv.get(applnRel.IDN_SEQ_INDIV_RELTD__c)).CDE_GENDER__c;
                                peakRefTable = 'TREL';
                                peakRefTable += gender=='1'?'_M':gender=='2'?'_F':'';
                                relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                                existingIndivToRelationshipMap.put(mapExistingIndiv.get(mapIndivSequenceToIndiv.get(applnRel.IDN_SEQ_INDIV_RELTD__c)).IDN_STATE__c, relationshipType);
                            }        
                        }
                    }
                } 
            }
            for(T_SBSD_INDIV__c existingIndiv: existingIndivList){
                T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseRec.id, IDN_CLIENT__c = existingIndiv.Id, DTE_BEGIN_EFFV__c = System.today(),
                                                    IND_CRTKR__c = mapStateIdWithPrimaryCaretaker.containsKey(existingIndiv.IDN_STATE__c) && mapStateIdWithPrimaryCaretaker.get(existingIndiv.IDN_STATE__c)=='Y'?true:false);                    
                caseIndividual.Individual_Status__c = caseIndividual.IND_CRTKR__c == true ? 'PC' : (existingIndivToRelationshipMap.containsKey(existingIndiv.IDN_STATE__c) && additionalAdultRels.contains(existingIndivToRelationshipMap.get(existingIndiv.IDN_STATE__c)) ? 'AC' : 'Child'); //added for CCCAP-13633
                mapCaseIndividual.put(existingIndiv.IDN_STATE__c, caseIndividual);
                
                // added for RAPID - UFE by SS
                if(lstApplnCase[0].UFE_Request_Flag__c == true && mapStateIdWithPrimaryCaretaker.get(existingIndiv.IDN_STATE__c)=='Y'){
                    existingIndiv.UFE_Request_Flag__c = true;
                }
                existingIndiv.Is_Peak_Data__c = true; //added for CCCAP-14243
                existingIndiv.Bypass_On__c = System.now(); //added for CCCAP-14243
                existingIndivToUpdate.add(existingIndiv);
            }        
            
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(!mapExistingIndiv.containsKey(appIndiv.IDN_STATE__c)){
                    if(String.isNotEmpty(appIndiv.NAM_MI__c)){
                           appIndiv.NAM_MI__c =  appIndiv.NAM_MI__c.subString(0,1);
                        }
                    lstApplnIndivToBeConverted.add(appIndiv);
                }
            } 
            
            Map<String,T_SBSD_INDIV__c> mapIndividual = new Map<String,T_SBSD_INDIV__c>();
            if(!lstApplnIndivToBeConverted.isEmpty()){
                for(SObject sOb:APXPolicyRecordsServices.createPolicyRecords(lstApplnIndivToBeConverted, false)){
                    if(sOb.getSObjectType()==Schema.T_SBSD_INDIV__c.getSObjectType()){
                        sOb.put('Is_Peak_Data__c',true);
                        mapIndividual.put(String.valueOf(sOb.get('IDN_STATE__c')),(T_SBSD_INDIV__c)sOb);
                    }
                }              
                
                for(T_APPLN_INDIV__c applnIndiv:lstApplnIndivToBeConverted){
                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                    String raceType='';
                    for(T_APPLN_INDIV_RACE__c indivRace:applnIndiv.Application_Race_Information__r){
                        if(String.isNotEmpty(indivRace.CDE_RACE__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)!=null){
                            raceType+=ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)+';';
                        }
                    }
                    if(String.isNotEmpty(raceType)){
                        individual.CDE_RACE__c = raceType;
                    }
                    individual.UFE_Request_Flag__c = applnIndiv.IND_CRTKR_PRIM__c =='Y' && lstApplnCase[0].UFE_Request_Flag__c;// added for RAPID - UFE by SS 
                    mapIndividual.put(applnIndiv.IDN_STATE__c,individual);
                }
                GenericDMLHandler.insertRecords(mapIndividual.values(), methodInfo);
            }

            //added for CCCAP-13633
            Map<String,String> indivToRelationshipMap = new Map<String,String>();
            gender = '';
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(appIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code && appIndiv.Application_Relationships__r!=null && appIndiv.Application_Relationships__r.size()>0){
                    for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                        if(mapIndivSequenceToIndiv.containsKey(applnRel.IDN_SEQ_INDIV_RELTD__c) && mapIndividual.containsKey(mapIndivSequenceToIndiv.get(applnRel.IDN_SEQ_INDIV_RELTD__c))){
                            gender = mapIndividual.get(mapIndivSequenceToIndiv.get(applnRel.IDN_SEQ_INDIV_RELTD__c)).CDE_GENDER__c;
                            peakRefTable = 'TREL';
                            peakRefTable += gender=='1'?'_M':gender=='2'?'_F':'';
                            relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                            indivToRelationshipMap.put(mapIndividual.get(mapIndivSequenceToIndiv.get(applnRel.IDN_SEQ_INDIV_RELTD__c)).IDN_STATE__c, relationshipType);
                        }        
                    }
                }
            }

            // added for RAPID - UFE by SS
            if(!existingIndivToUpdate.isEmpty()){
                methodInfo.put('byPassObjects',new Set<String>{'T_SBSD_INDIV__c'});
                GenericDMLHandler.updateRecords(existingIndivToUpdate, methodInfo, new list<String>{'Is_Peak_Data__c','Bypass_On__c','UFE_Request_Flag__c'}); // Added fields to update as part of CCCAP-8307
            }
            for(T_APPLN_INDIV__c applnIndiv:lstApplnIndivToBeConverted){
                if(mapIndividual.containsKey(applnIndiv.IDN_STATE__c)){
                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                    T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = individual.Id, IND_CRTKR__c = applnIndiv.IND_CRTKR_PRIM__c=='Y'?true:false, DTE_BEGIN_EFFV__c = caseRec.DTE_APPLN__c);
                    caseIndividual.Individual_Status__c = applnIndiv.IND_CRTKR_PRIM__c=='Y' ? 'PC' : (indivToRelationshipMap.containsKey(applnIndiv.IDN_STATE__c) && additionalAdultRels.contains(indivToRelationshipMap.get(individual.IDN_STATE__c)) ? 'AC' : 'Child'); //added for CCCAP-13633
                    lstCaseChildRecords.add(new T_SBSD_INDIV_MIL__c(IDN_CLIENT__c = individual.Id,CDE_STATUS_MIL__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TMLT', applnIndiv.CDE_STATUS_MIL__c)));
                    lstCaseChildRecords.add(new T_SBSD_INDIV_INFO__c(IDN_CASE__c = caseRec.id,IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = (caseIndividual.Individual_Status__c =='PC' || caseIndividual.Individual_Status__c =='AC') ? 'N/A-adult caretaker' : ((applnIndiv.IND_CTZN__c=='Y') ?'CZN':applnIndiv.IND_CTZN__c=='N'?'NCZ':null)));
                    //Code Added here by Pragyan Nayak
                    if(String.isNotEmpty(lstApplnCase.get(0).CDE_INFO_EM__c) && applnIndiv.IND_CRTKR_PRIM__c=='Y'){
                        lstCaseChildRecords.add(new Individual_E_mail__c(Individual__c = individual.Id, Effective_Begin_Date__c=System.today(), Email_Information__c = lstApplnCase.get(0).CDE_INFO_EM__c));
                    }
                    /*if(!lstApplnCase.get(0).Application_case_28__r.isEmpty()){
                        caseIndividual.DTE_BEGIN_EFFV__c = lstApplnCase.get(0).Application_case_28__r.get(0).DTE_WKDAY_APPLN__c;
                    }*/
                    mapCaseIndividual.put(applnIndiv.IDN_STATE__c,caseIndividual);
                        for(T_APPLN_JOB_SEARCH__c applnJobSearch:applnIndiv.Application_Job_Search__r){
                            lstCaseChildRecords.add(new T_JOB_SEARCH__c(IDN_CLIENT__c = individual.Id,DTE_BEGIN_EFFV__c = applnJobSearch.DTE_BEGIN_EFFV__c, Ignore__c = true));
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
                        lstCaseChildRecords.add(eachSOb);
                    }
                    
                }
            
            for(SObject sOb:lstCaseChildRecords){
                if(String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ADR__c' || String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ASSET__c' || String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_HOMELESS__c'){
                    sOb.put('IDN_CASE__c',caseRec.Id);
                }
                if(String.valueOf(sOb.getSObjectType())=='T_SBSD_CASE_ASSET__c'){
                           sOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);
                           
                       }
            }
            
            if(!lstCaseChildRecords.isEmpty()){
                // To avoid System.TypeException: Cannot have more than 10 chunks in a single operation.
                lstCaseChildRecords.sort();
                GenericDMLHandler.insertRecords(lstCaseChildRecords, methodInfo);
            }
            if(!mapCaseIndividual.isEmpty()){
                GenericDMLHandler.insertRecords(mapCaseIndividual.values(), methodInfo);
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
			listApplnIndivAndAllChilds = [select Id, Name, IDN_STATE__c,	
                                          		(SELECT Id, DTE_BIRTH_CUST_NON__c,IDN_STATE_CUST_NON__c,IND_CASE_OPEN__c,IND_COOP_PARENT__c,NAM_FIRST_CUST_NON__c,NAM_LAST_CUST_NON__c,NBR_SSN_CUST_NON__c FROM Application_Child_Support_Enforcements__r),
												(SELECT Id,IND_CC_GIVE_ABLE__c,IND_YR_DSBL__c FROM Application_Disabilities__r),
												(SELECT Id,AMT_DDTN_TOTAL__c,CDE_FREQ_PAID__c,NAM_PAYEE__c,NBR_DOCKET__c FROM Application_Child_Support_Deductions__r),
												(SELECT Id,AMT_INCOME_OTHER_GROSS__c,CDE_FREQ_INCOME__c,CDE_SOURCE_INCOME__c FROM Application_Other_Income__r),
                                                (SELECT Id,CDE_TYPE_SCHOOL__c,NAM_SCHOOL__c, City__c, ADR_ZIP_EXTN__c, ADR_LINE_2__c, ADR_LINE_1__c, ADR_STATE__c, ADR_ZIP_MAIN__c, HOURS_SUD__c FROM Application_Education__r),
										        (SELECT Id,IND_CC_REQ__c,DTE_JOINT_CUST__c,IND_JOINT_CUST__c,DTE_BEGIN_HEAD_START__c,DTE_FOSTER__c,IND_FOSTER__c,IND_HEAD_START__c FROM Application_Custodies__r),
												(SELECT Id, AMT_INCOME_MONTH_ESTMD__c,CDE_FREQ_EXP__c,CNT_WEEK_PER_HOURS_ESTMD__c,ADR_CITY__c,ADR_LINE_1__c,ADR_LINE_2__c,ADR_STATE__c,ADR_ZIP_EXTN__c,ADR_ZIP_MAIN__c,DTE_BEGIN_EMP__c,
														NAM_BUSNS__c,NBR_PHONE__c,DTE_BEGIN_INCOME__c,NBR_PHONE_EXTN__c,DTE_BEGIN_STRIKE__c,ADR_NAM__c FROM Application_Employments__r),
											    (SELECT Id,AMT_INCOME_MONTH_ESTMD__c,CNT_WEEK_PER_HOURS_ESTMD__c,DTE_BEGIN_EFFV__c,ADR_CITY__c,ADR_LINE_1__c,ADR_LINE_2__c,ADR_STATE__c,ADR_ZIP_EXTN__c,ADR_ZIP_MAIN__c,
														DTE_BEGIN_EMP__c,NAM_BUSNS__c,NBR_PHONE__c,NBR_PHONE_EXTN__c,AMT_EXP_MONTH__c FROM Application_Self_Employments__r)
							 from T_APPLN_INDIV__c
							 where Id IN:lstApplnIndivToBeConverted];
            
            for(T_APPLN_INDIV__c eachApplnIndividual : listApplnIndivAndAllChilds){
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
                if(eachApplnIndividual.Application_Other_Income__r != null && eachApplnIndividual.Application_Other_Income__r.size()>0){
                    for(T_APPLN_OTHER_INCOME__c applnDdtn:eachApplnIndividual.Application_Other_Income__r){
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
                        if(applnDdtn.IND_CC_REQ__c=='Y'){
                            lstSObjectToBeInserted.add(new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = mapCaseIndividual.get(key).Id,
                                                                             DTE_BEGIN_EFFV__c = System.today()));
                        }
                        
                        List<SObject> lstApplnDdtn = mapApplnIdChildRecords.containsKey(key)?mapApplnIdChildRecords.get(key):new List<SObject>();
                        lstApplnDdtn.add(applnDdtn);  
                        mapApplnIdChildRecords.put(key,lstApplnDdtn);
                    }
                }
                
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
            Map<String,List<T_SBSD_INDIV_EMPLMT__c>> mapEmployment = new Map<String,List<T_SBSD_INDIV_EMPLMT__c>>();
            Map<String,List<T_EMPLMT_INCOME__c>> mapEmploymentIncome = new Map<String,List<T_EMPLMT_INCOME__c>>();
            Map<String,List<T_INDIV_EMPLMT_INFO__c>> mapEmployInfo = new Map<String,List<T_INDIV_EMPLMT_INFO__c>>();
            list<T_EMPLMT_INCOME__c> listEmploymentIncome = new list<T_EMPLMT_INCOME__c>();
            list<T_EMPLMT_INCOME__c> listSelfEmploymentIncome = new list<T_EMPLMT_INCOME__c>();
            list<T_INDIV_EMPLMT_INFO__c> listEmployInfo = new list<T_INDIV_EMPLMT_INFO__c>();
            for(String key:mapApplnEmployment.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> listOfEmploymentRecords = mapApplnEmployment.get(key);
                    for(SObject sOb:APXPolicyRecordsServices.createPolicyRecords(listOfEmploymentRecords, false)){
                        if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                            sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId());
                            sOb.put('IDN_CLIENT__c',mapIndividual.get(key).Id);
                            sOb.put('IDN_CASE__c',caseRec.Id);
                            List<Sobject> sobjs = mapEmployment.containsKey(key)?mapEmployment.get(key):new List<Sobject>();
                            sobjs.add(sob);
                            mapEmployment.put(key,(List<T_SBSD_INDIV_EMPLMT__c>)sobjs);
                        }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                            List<Sobject> sobjs = mapEmploymentIncome.containsKey(key)?mapEmploymentIncome.get(key):new List<Sobject>();
                            sobjs.add(sob);
                            mapEmploymentIncome.put(key,(List<T_EMPLMT_INCOME__c>)sobjs);
                        }else if(sOb.getSObjectType()==Schema.T_INDIV_EMPLMT_INFO__c.getSObjectType()){
                            if(sOb.get('DTE_BEGIN_EFFV__c') != null){
                                sOb.put('CDE_TYPE_INFO_EMPLMT__c','EIW');
                                List<Sobject> sobjs = mapEmployInfo.containsKey(key)?mapEmployInfo.get(key):new List<Sobject>();
                                sobjs.add(sob);
                                mapEmployInfo.put(key,(List<T_INDIV_EMPLMT_INFO__c>)sobjs);                                        
                                

                            }
                        }
                    }
                }
            }
            if(!mapEmployment.isEmpty()){
                List<T_SBSD_INDIV_EMPLMT__c> empsToInsert = new List<T_SBSD_INDIV_EMPLMT__c>();
                for(string key : mapEmployment.keyset()){
                    empsToInsert.addAll(mapEmployment.get(key));
                }
                GenericDMLHandler.insertRecords(empsToInsert, methodInfo);
            }
            for(String key1:mapEmploymentIncome.keySet()){
                Integer index =0;
                for(T_EMPLMT_INCOME__c empIncome : mapEmploymentIncome.get(key1)){
                    if(mapEmployment.get(Key1)!=null && mapEmployment.get(Key1)[index]!=null){
                        empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key1)[index].Id;
                        empIncome.Is_Peak_Data__c = true;
                        listEmploymentIncome.add(empIncome);
                    }
                    index++;
                }
            }
            for(String key2:mapEmployInfo.keySet()){
                Integer index =0;
                for(T_INDIV_EMPLMT_INFO__c employInfo : mapEmployInfo.get(key2)){
                    if(mapEmployment.get(Key2)!=null && mapEmployment.get(Key2)[index]!=null){
	                    employInfo.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key2)[index].Id;
    	                listEmployInfo.add(employInfo);                
                    }
                    index++;
                }
            }
            
            if(!listEmploymentIncome.isEmpty()){
                GenericDMLHandler.insertRecords(listEmploymentIncome, methodInfo);
            }
            if(!listEmployInfo.isEmpty()){
                GenericDMLHandler.insertRecords(listEmployInfo, methodInfo);
            }
            
            // Creating Self Employment Records
            mapEmployment.clear();
            mapEmploymentIncome.clear();
            Map<String,List<T_SBSD_EMPLMT_EXP__c>> mapIncomeExpense = new Map<String,List<T_SBSD_EMPLMT_EXP__c>>();
            List<T_SBSD_EMPLMT_EXP__c> listEmploymentExpense = new List<T_SBSD_EMPLMT_EXP__c>();
            for(String key:mapApplnSelfEmployment.keySet()){
                if(mapIndividual.containsKey(key)){
                    List<SObject> listOfSelfEmploymentrecords = mapApplnSelfEmployment.get(key);
                    for(SObject sOb:APXPolicyRecordsServices.createPolicyRecords(listOfSelfEmploymentrecords, false)){
                        if(sOb.getSObjectType()==Schema.T_SBSD_INDIV_EMPLMT__c.getSObjectType()){
                            List<Sobject> sobjs = mapEmployment.containsKey(key)?mapEmployment.get(key):new List<Sobject>();
                            sOb.put('RecordTypeId',Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId());
                            sOb.put('IDN_CLIENT__c',mapIndividual.get(key).Id);
                            sOb.put('IDN_CASE__c',caseRec.Id);
                            sobjs.add(sob);
                            mapEmployment.put(key,(List<T_SBSD_INDIV_EMPLMT__c>)sobjs);
                        }else if(sOb.getSObjectType()==Schema.T_EMPLMT_INCOME__c.getSObjectType()){
                            List<Sobject> sobjs = mapEmploymentIncome.containsKey(key)?mapEmploymentIncome.get(key):new List<Sobject>();
                            sOb.put('CDE_FREQ_PAY_ESTMD__c','MON');
                            sobjs.add(sob);
                            mapEmploymentIncome.put(key,(List<T_EMPLMT_INCOME__c>)sobjs);
                        }else if(sOb.getSObjectType()==Schema.T_SBSD_EMPLMT_EXP__c.getSObjectType()){
                            List<Sobject> sobjs = mapIncomeExpense.containsKey(key)?mapIncomeExpense.get(key):new List<Sobject>();
                            sOb.put('CDE_FREQ_EXP__c','MON');
                            sOb.put('DTE_BEGIN_EFFV__c',caseRec.DTE_APPLN__c);
                            sobjs.add(sob);
                            mapIncomeExpense.put(key,(List<T_SBSD_EMPLMT_EXP__c>)sobjs);
                        }
                    }
                }
            }
            if(!mapEmployment.isEmpty()){
                List<T_SBSD_INDIV_EMPLMT__c> empsToInsert = new List<T_SBSD_INDIV_EMPLMT__c>();
                for(string key : mapEmployment.keyset()){
                    empsToInsert.addAll(mapEmployment.get(key));
                }
                GenericDMLHandler.insertRecords(empsToInsert, methodInfo);
            }
            for(String key1:mapEmploymentIncome.keySet()){
                Integer index = 0;
                for(T_EMPLMT_INCOME__c empIncome : mapEmploymentIncome.get(key1)){
                    if(mapEmployment.get(Key1)!=null && mapEmployment.get(Key1)[index]!=null){
                        empIncome.IDN_EMPLMT_INDIV__c = mapEmployment.get(Key1)[index].Id;
                        empIncome.Is_Peak_Data__c = true;
                        listEmploymentIncome.add(empIncome);
                        mapEmploymentIncome.get(key1)[index] = empIncome;
                    }
                    index++;
                }
            }
            for(String key2:mapIncomeExpense.keySet()){
                Integer index = 0;
                for(T_SBSD_EMPLMT_EXP__c incomeExpense : mapIncomeExpense.get(key2)){
                    if(mapEmploymentIncome.get(Key2)!=null && mapEmploymentIncome.get(Key2)[index]!=null){
                        incomeExpense.IDN_EMPLMT_INDIV__c = mapEmploymentIncome.get(Key2)[index].IDN_EMPLMT_INDIV__c;
                        listEmploymentExpense.add(incomeExpense);
                    }
                    index++;
                }
            }
            if(!listSelfEmploymentIncome.isEmpty()){
                GenericDMLHandler.insertRecords(listSelfEmploymentIncome, methodInfo);
            }
            if(!listEmploymentExpense.isEmpty()){
                GenericDMLHandler.insertRecords(listEmploymentExpense, methodInfo);
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
            List<SObject> recordsToBeUpserted = new List<SObject>();
            Map<String,String> mapIndivDOBSSNToName = new Map<String,String>();
            for(T_SBSD_INDIV__c indiv:[SELECT Name, DOB_SSN__c, IDN_STATE__c FROM T_SBSD_INDIV__c WHERE Id IN:mapIndividual.values()]){
                mapIndivDOBSSNToName.put(indiv.DOB_SSN__c,indiv.Name);
                //added for CCCAP-13633
                if(indivToRelationshipMap.containsKey(indiv.IDN_STATE__c) && String.isNotEmpty(primaryCaretakerId)){
                    recordsToBeUpserted.add(new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = mapIndividual.get(indiv.IDN_STATE__c).Id,
                                                    IDN_CLIENT__c = primaryCaretakerId,
                                                    CDE_TYPE_REL_INDIV__c =  indivToRelationshipMap.get(indiv.IDN_STATE__c)
                                                    ));
                }
            }
                        
            for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                if(mapIndivDOBSSNToName.containsKey(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c) && String.isNotEmpty(mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c))){
                    appIndiv.IDN_CLIENT__c = mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c).length()>15?mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c).subString(0,15):mapIndivDOBSSNToName.get(String.valueOf(appIndiv.DTE_DOB__c)+'_'+appIndiv.NBR_SSN__c);
                }
            }
            
            if(!lstApplnIndiv.isEmpty()){
                GenericDMLHandler.updateRecords(lstApplnIndiv, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'}}, new list<String>{'IDN_CLIENT__c'}); // Added IDN_CLIENT__c as part of CCCAP-8307
            }
            
            if(!recordsToBeUpserted.isEmpty()){
                GenericDMLHandler.insertRecords(recordsToBeUpserted, methodInfo, new list<String>{'IDN_CLIENT_RELTD__c','IDN_CLIENT__c','CDE_TYPE_REL_INDIV__c'}); // Added fields to update as part of CCCAP-8307
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
                                                                         if(sOb.getSObjectType()==Schema.T_INDIV_TRAIN__c.getSObjectType() || sOb.getSObjectType()==Schema.T_INDIV_EDUC__c.getSObjectType()){ //CCCAP-15444
                                                                             sOb.put('DTE_BEGIN_EFFV__c',System.today());
                                                                         }
                                                                         
                                                                         // Set How Verified = 'SA' (Self Attestation) only when type is SUD and verified = written verification CCCAP-15634
                                                                            if (sOb.getSObjectType() == Schema.T_INDIV_TRAIN__c.getSObjectType()) {
                                                                                String trainType = (String) sOb.get('CDE_TYPE_TRAIN__c');
                                                                                if (trainType == 'SUD') {
                                                                                    sOb.put('CDE_TYPE_VERIF__c', 'V');

                                                                                    sOb.put('CDE_SOURCE_VRFYD__c', 'SA');
                                                                                }
                                                                            } else if (sOb.getSObjectType() == Schema.T_INDIV_EDUC__c.getSObjectType()) {
                                                                                String educType = (String) sOb.get('CDE_TYPE_SCHOOL__c');
                                                                                if (educType == 'SUD') {
                                                                                    sOb.put('CDE_TYPE_VERIF__c', 'V');

                                                                                    sOb.put('CDE_SOURCE_VRFD_EDUC__c', 'SA');
                                                                                }
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