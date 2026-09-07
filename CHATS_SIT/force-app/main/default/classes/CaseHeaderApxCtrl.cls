public With Sharing class CaseHeaderApxCtrl {
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String caseId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        
        List<T_SBSD_CASE__c> caseRecord = new List<T_SBSD_CASE__c>
            (
                [SELECT Id,Name,CDE_COUNTY__R.NAME,OWNER.NAME,
                 (SELECT IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c FROM CaseIndividuals__r WHERE IND_CRTKR__c=true 
                  AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY) Limit 1),
                 (SELECT toLabel(CDE_STATUS_CASE__c),toLabel(CDE_MODE_CASE__c), DTE_BEGIN_EFFV__c FROM T_SBSD_CASE10__r where DTE_END_EFFV__c>=Today OR DTE_END_EFFV__c = null Order by DTE_BEGIN_EFFV__c,createddate Desc NULLS FIRST Limit 1)
                 FROM T_SBSD_CASE__c WHERE Id =:caseId]
            );
		if(String.isNotBlank(caseId)){
            objectData.put('childCareProgram', getChildCareProgram(caseId));
            objectData.put('scheduledCloseDate', getLatestIneligBeginDate(caseId));
            objectData.put('SecondaryCaretakerEmails', getSecondaryCaretakerInfo(caseId));
            objectData.put('SecondaryCaretakerDates', getSecondaryCaretakerDate(caseId));
        }
	    
	List<T_SBSD_CASE_ADR__c> caseAddresses = [SELECT Id, ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, IDN_CASE__c, CDE_TYPE_ADR__c
                                                   FROM T_SBSD_CASE_ADR__c
                                                  WHERE IDN_CASE__c =:caseId AND DTE_BEGIN_EFFV__c <= Today AND (DTE_END_EFFV__c >= Today OR DTE_END_EFFV__c = null)]; 
        for(T_SBSD_CASE_ADR__c cAdd : caseAddresses){
            if(cAdd.CDE_TYPE_ADR__c == 'MAL')
                objectData.put('mailingAddressRecord',cAdd);
            if(cAdd.CDE_TYPE_ADR__c == 'HOM')
                objectData.put('homeAddressRecord',cAdd);
        }
	    
        if(!caseRecord.isEmpty()){
          if(caseRecord[0].CaseIndividuals__r.size()>0){
                for(Individual_E_mail__c indEmail: [Select Id, Effective_Begin_Date__c, Effective_End_Date__c, Email_Information__c, Individual__c from Individual_E_mail__c where Individual__c =: caseRecord[0].CaseIndividuals__r[0].IDN_CLIENT__c AND Effective_Begin_Date__c<=TODAY AND (Effective_End_Date__c = null OR Effective_End_Date__c>=TODAY) Limit 1]){
                    objectData.put('individualEmailRecordforPrimary',indEmail);
                    
                }
            }
            objectData.put('caseRecord',caseRecord);
            isSuccessful=true;
        }
        else{
            isSuccessful=false;
            message = Label.caseRecord_Not_Found;
        }
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getCaseId(String recordId,String sobjectName){
        String caseExtId;
        String caseId;
        LightningServerResponse lightningServerResponse;
        if(sobjectName == 'batchsit_t_eligty_run__x' && recordId!= null){
            if(Test.isRunningTest()){
                caseExtId=System.Label.TEST_EXTERNAL_ID;
            }else{
                caseExtId = [select Id,idn_case__c from batchsit_t_eligty_run__x where id =: recordId limit 1].idn_case__c;
            }
        }
        else if(sobjectName == 'batchsit_t_fcompsn_eligty__x' && recordId!= null){
            if(Test.isRunningTest()){
                caseExtId=System.Label.TEST_EXTERNAL_ID;
            }else{
                string eligiblityId  = [select Id,idn_run_eligty__c from batchsit_t_fcompsn_eligty__x where id =: recordId limit 1].idn_run_eligty__c;
                caseExtId = [select Id,idn_case__c from batchsit_t_eligty_run__x where ExternalId =: eligiblityId limit 1].idn_case__c;
            }
        }else if (sobjectName == 'batchsit_t_fcompsn_indiv_eligty__x' && recordId!= null){
            if(Test.isRunningTest()){
                caseExtId=System.Label.TEST_EXTERNAL_ID;
            }else{
                string householdeligiblityId  = [select Id,idn_eligty_fcompsn__c from batchsit_t_fcompsn_indiv_eligty__x where id =: recordId limit 1].idn_eligty_fcompsn__c;
                string eligiblityId  = [select Id,idn_run_eligty__c from batchsit_t_fcompsn_eligty__x where ExternalId =: householdeligiblityId limit 1].idn_run_eligty__c;
                caseExtId = [select Id,idn_case__c from batchsit_t_eligty_run__x where ExternalId =: eligiblityId limit 1].idn_case__c;
            }
        }else if(sobjectName=='batchsit_t_sbsd_case_cmt__x' && recordId!= null){
            caseExtId = [select Id,idn_case__c from batchsit_t_sbsd_case_cmt__x where id =: recordId limit 1].idn_case__c;
        }
        
        if(!String.isEmpty(caseExtId) && !String.isBlank(caseExtId)){
            if(Test.isRunningTest()){
                caseId=System.Label.TEST_EXTERNAL_ID;
            }else{
                caseId = [Select Id from T_SBSD_CASE__c where IDN_EXTNL__c = :caseExtId].Id;
            }
        }
        if(!String.isEmpty(caseId) && !String.isBlank(caseId)){
            lightningServerResponse = getInitData(caseId);
       }
        return lightningServerResponse;
    }
    
 @AuraEnabled
    public static String getChildCareProgram(String caseId){
        String childCareProg;
        List<batchsit_t_fcompsn_eligty__x> householdEligity = new List<batchsit_t_fcompsn_eligty__x>();
        List<batchsit_t_fcompsn_eligty_detail__x> eligDetail = new List<batchsit_t_fcompsn_eligty_detail__x>();
        String caseExternalId;
        List<batchsit_t_sbsd_case_copay__x> caseCopayRecord =new List<batchsit_t_sbsd_case_copay__x>();
        if(String.isNotBlank(caseId)){
            for(T_SBSD_CASE__c cse :[Select id, IDN_EXTNL__c, Program_Type__c from T_SBSD_CASE__c where id=:caseId]){
                caseExternalId =cse.IDN_EXTNL__c;
                childCareProg = cse.Program_Type__c;
            }
        }
        if(String.isBlank(childCareProg)){
            if(!String.isBlank(caseExternalId)){
                Set<String> eliRunIds = new Set<String>();
                for(batchsit_t_eligty_run__x eli : [Select Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c from batchsit_t_eligty_run__x where
                                                    idn_case__c=:caseExternalId and cde_eligty_cfmd__c='CFM'  order by ExternalId DESC limit 1]){
                                                        eliRunIds.add(String.valueOf(eli.idn_run_eligty__c));
                                                        
                                                    }
                if(Test.isRunningTest()){
                    eliRunIds.add('123');
                }
                if(eliRunIds.size()>0) {
                    Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
                    Set<Decimal> eligibilityHouseHoldIdSet = new Set<Decimal>();
                    List<batchsit_t_fcompsn_eligty__x> unfilteredCaseEligibility = [SELECT Id, cde_prog__c, txt_values_comptd_xml__c, cde_reason_ovrd__c, txt_cmt_ovrd__c, ExternalId,
                                                                    idn_run_eligty__c, nbr_size_fcompsn__c, cnt_chldrn_rqng_care__c, amt_copay_ft__c, amt_copay_pt__c,
                                                                    amt_income_county_max__c, amt_income_annual__c, amt_grant_total_annual__c, amt_fpg_pctg__c, cde_income_result__c,
                                                                    amt_clg_county_new__c, amt_income_smi__c, amt_ddtn_total_annual__c, amt_income_gross_annual__c, idn_eligty_fcompsn__c, cde_reason_change_fcompsn__c
                                                                    FROM batchsit_t_fcompsn_eligty__x
                                                                    WHERE idn_run_eligty__c IN: eliRunIds AND idn_eligty_fcompsn__c!=null];
                    for(batchsit_t_fcompsn_eligty__x fcompsnEligty:unfilteredCaseEligibility){
                        if( fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
                            fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
                        }
                    }
                    for(batchsit_t_fcompsn_eligty_detail__x fcomElig : [Select Id,idn_eligty_fcompsn__c,cde_status_eligty_family__c 
                                                                        from batchsit_t_fcompsn_eligty_detail__x 
                                                                        where idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet()  order by dte_begin_effv__c DESC ,idn_eligty_fcompsn__c DESC limit 1])
                    {
                        eligibilityHouseHoldIdSet.add(decimal.valueOf(fcomElig.idn_eligty_fcompsn__c));
                    }
                    if(!eligibilityHouseHoldIdSet.isEmpty()){
                        householdEligity = [select id,ExternalId,idn_run_eligty__c,cde_prog__c,amt_copay_ft__c,amt_copay_pt__c,idn_eligty_fcompsn__c 
                                            from batchsit_t_fcompsn_eligty__x where idn_eligty_fcompsn__c IN :eligibilityHouseHoldIdSet order by idn_eligty_fcompsn__c LIMIT 1];
                        if(!householdEligity.isEmpty()){
                            childCareProg = householdEligity[0].cde_prog__c;
                        }
                    }                    
                }
            }
        }
        return childCareProg;
    }
    
    @AuraEnabled
    public static Date getLatestIneligBeginDate(String caseId){
        Date scheduledCloseDate;
        List<batchsit_t_fcompsn_eligty__x> householdEligity = new List<batchsit_t_fcompsn_eligty__x>();
        List<batchsit_t_fcompsn_eligty_detail__x> eligDetail = new List<batchsit_t_fcompsn_eligty_detail__x>();
        String caseExternalId;
        
        if(String.isNotBlank(caseId)){
            for(T_SBSD_CASE__c cse :[Select id,IDN_EXTNL__c from T_SBSD_CASE__c where id=:caseId]){
                caseExternalId =cse.IDN_EXTNL__c;
            }
        }
        if(!String.isBlank(caseExternalId)){
            Set<String> eliRunIds = new Set<String>();
            for(batchsit_t_eligty_run__x eli : [Select Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c from batchsit_t_eligty_run__x where
                                                idn_case__c=:caseExternalId and cde_eligty_cfmd__c='CFM' order by ExternalId DESC limit 1]){
                                                    eliRunIds.add(String.valueOf(eli.idn_run_eligty__c));
                                                    
                                                }
            if(Test.isRunningTest()){
                eliRunIds.add('123');
            }
            if(eliRunIds.size()>0) {
                Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
                List<batchsit_t_fcompsn_eligty__x> unfilteredCaseEligibility = [SELECT Id,ExternalId, idn_run_eligty__c,
                                                                                idn_eligty_fcompsn__c, cde_reason_change_fcompsn__c
                                                                                FROM batchsit_t_fcompsn_eligty__x
                                                                                WHERE idn_run_eligty__c IN: eliRunIds AND idn_eligty_fcompsn__c!=null];
                
                for(batchsit_t_fcompsn_eligty__x fcompsnEligty:unfilteredCaseEligibility){
                    if( fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
                        fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
                    }
                }
                for(batchsit_t_fcompsn_eligty_detail__x fcomElig : [Select Id,idn_eligty_fcompsn__c,cde_status_eligty_family__c, dte_begin_effv__c, dte_end_effv__c 
                                                                    from batchsit_t_fcompsn_eligty_detail__x 
                                                                    where idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet() AND cde_status_eligty_family__c = 'INE' AND dte_end_effv__c = null order by dte_begin_effv__c DESC ,idn_eligty_fcompsn__c DESC limit 1])
                {
                    if(fcomElig.dte_begin_effv__c != null){
                        scheduledCloseDate = fcomElig.dte_begin_effv__c; 
                    }else{
                        scheduledCloseDate = null; 
                    } 
                }  
            }
        }
        return scheduledCloseDate;
    }
  @AuraEnabled
    public static String getSecondaryCaretakerInfo(String caseId){
        List<String>EmailInfo = new List<String>();
        List <Id> IndivIds =new List<Id>();
        String commaSepSecondaryEmailList='';
        integer i;
        List<Id> IndivRecords = new List<Id>();
        for(T_SBSD_CASE_INDIV__c caseindiv:[SELECT IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c,IDN_CASE__c,IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c=:caseId AND IND_CRTKR__c=false  
                                   AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                                  ]){
                                     IndivRecords.add(caseindiv.IDN_CLIENT__c); 
                                  }
        if(!IndivRecords.isEmpty()){
            for(T_SBSD_INDIV__c indiv:[SELECT Id, Name, Age__c, Has_Allowed_Relationship__c FROM T_SBSD_INDIV__c WHERE Id In :IndivRecords AND (Age__c>18.0 OR (Age__c<=18.0 AND Has_Allowed_Relationship__c =True ))])
            {
                IndivIds.add(indiv.Id);
            }
        }
        if(!IndivIds.isEmpty()){ 
        for(Individual_E_mail__c indEmail: [Select Id, Effective_Begin_Date__c, Effective_End_Date__c, Email_Information__c, Individual__c from Individual_E_mail__c where Individual__c IN:IndivIds AND Effective_Begin_Date__c<=TODAY AND (Effective_End_Date__c = null OR Effective_End_Date__c>=TODAY)]){  
            EmailInfo.add(indEmail.Email_Information__c) ;           
        }
        }     
        commaSepSecondaryEmailList = String.join(EmailInfo, ', ');
        return commaSepSecondaryEmailList;
    }
    
    @AuraEnabled
    public static String getSecondaryCaretakerDate(String caseId){
        List<String>dateList = new List<String>();
        List <Id> IndivIds =new List<Id>();
        String commaSepSecondaryDateList='';
        integer i;
        List<Id> IndivRecords = new List<Id>();
        for(T_SBSD_CASE_INDIV__c caseindiv:[SELECT IDN_CLIENT__c, IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c,IDN_CASE__c,IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c=:caseId AND IND_CRTKR__c=false 
                                            AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                                           ]){
                                               IndivRecords.add(caseindiv.IDN_CLIENT__c); 
                                           }
         if(!IndivRecords.isEmpty()){
        for(T_SBSD_INDIV__c indiv:[SELECT Id, Name, Age__c, Has_Allowed_Relationship__c FROM T_SBSD_INDIV__c WHERE Id In :IndivRecords AND (Age__c>18.0 OR (Age__c<=18.0 AND Has_Allowed_Relationship__c =True ))])
        {
            IndivIds.add(indiv.Id);
        }
       } 
        if(!IndivIds.isEmpty()){
        for(Individual_E_mail__c indEmail: [Select Id, Effective_Begin_Date__c, Effective_End_Date__c, Email_Information__c, Individual__c from Individual_E_mail__c where Individual__c IN:IndivIds AND Effective_Begin_Date__c<=TODAY AND (Effective_End_Date__c = null OR Effective_End_Date__c>=TODAY)]){  
            Datetime dtTodayDateTime = datetime.newInstance((indEmail.Effective_Begin_Date__c).year(), (indEmail.Effective_Begin_Date__c).month(),(indEmail.Effective_Begin_Date__c).day());
            string strDate = dtTodayDateTime.format('MM/dd/yyyy');        
            dateList.add(strDate) ;           
        }
        }
        commaSepSecondaryDateList = String.join(dateList, ', ');
        return commaSepSecondaryDateList;
    }
}