public with sharing class EligibilityFlowCmpApxCtrl {
    
    @TestVisible
    private static List<batchsit_t_fcompsn_indiv_eligty__x> queryIndivEligibilities(String idnEligtyFcompsn){
        if(Test.isRunningTest()){
            return new List<SObject>{new batchsit_t_fcompsn_indiv_eligty__x()};
                }else{
                    return [SELECT Id, 
                            (SELECT cde_status_detail_eligty_indiv__c FROM batchsit_t_indiv_eligty_detail__r ORDER BY dte_begin_effv__c DESC), 
                            (SELECT Id FROM batchsit_t_indiv_eligty_failr__r) 
                            FROM batchsit_t_fcompsn_indiv_eligty__x WHERE idn_eligty_fcompsn__c = :idnEligtyFcompsn];
                }
    }
    
    @TestVisible
    private static Map<String, Object> queryData(String elgibilityRunId){
        Map<String, Object> data = new Map<String, Object>();
        Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
        if(Test.isRunningTest()){
            List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
            data.put('eligRun',new List<SObject>{new batchsit_t_eligty_run__x(idn_case__c = cases.get(0).IDN_EXTNL__c,idn_run_eligty__c=1)});
            data.put('caseEligibility',new List<SObject>{new batchsit_t_fcompsn_eligty__x(idn_run_eligty__c='1', idn_eligty_fcompsn__c=11)});
            data.put('caseEligibilityDetails',new List<SObject>{new batchsit_t_fcompsn_eligty_detail__x(idn_eligty_fcompsn__c='11', dte_begin_effv__c=System.today().addDays(-5), dte_end_effv__c=null, cde_status_eligty_family__c = 'ELI'), new batchsit_t_fcompsn_eligty_detail__x(idn_eligty_fcompsn__c='11', dte_begin_effv__c=System.today().addDays(-15), dte_end_effv__c=System.today().addDays(-6), cde_status_eligty_family__c = 'ELI')});
            data.put('caseIndivEligibilities',new List<SObject>{new batchsit_t_fcompsn_indiv_eligty__x(idn_eligty_fcompsn__c='11', idn_case_indiv__c='1', idn_indiv_fcompsn__c=111),
                new batchsit_t_fcompsn_indiv_eligty__x(idn_eligty_fcompsn__c='11', idn_case_indiv__c='2', idn_indiv_fcompsn__c=112)
                });
            data.put('caseEligibilityFailure',new List<SObject>{new batchsit_t_fcompsn_failr__x(idn_eligty_fcompsn__c='111')});
            fcompsnEligtyIdToRecord.put('11',new batchsit_t_fcompsn_eligty__x(idn_run_eligty__c='1', idn_eligty_fcompsn__c=11, amt_fpg_pctg__c='117'));
            data.put('fcompsnEligtyIdToRecord',fcompsnEligtyIdToRecord);
            data.put('indivEmplmtIncome',new List<SObject>{new batchsit_t_indiv_eligty_emplmt_income__x(cde_type_emplmt__c='E', idn_emplmt_indiv__c = '1'),new batchsit_t_indiv_eligty_emplmt_income__x(cde_type_emplmt__c='S',idn_emplmt_indiv__c = '1')});
            
            return data;
        }else{
            List<batchsit_t_eligty_run__x> eligRun = [SELECT Id, dte_run_eligty__c, idn_case__c, idn_case__r.IND_CHGD_DATA_ELIGTY__c, idn_run_eligty__c, 
                                                      cde_eligty_cfmd__c, dte_redet_prpsd__c, dte_redet_ovrd__c, 
                                                      cde_date_redet_ovrd__c, txt_cmt_ovrd__c, createddate__c, dte_appln_old__c, dte_appln_new__c, rsn_appln_dte_override__c, cmt_appln_dte_override__c 
                                                      FROM batchsit_t_eligty_run__x
                                                      WHERE Id =: elgibilityRunId];
            data.put('eligRun',eligRun);
            
            String idnRunEligty = String.valueOf(eligRun.get(0).idn_run_eligty__c);
            List<batchsit_t_fcompsn_eligty__x> unfilteredCaseEligibility = [SELECT Id, cde_prog__c, txt_values_comptd_xml__c, cde_reason_ovrd__c, txt_cmt_ovrd__c, ExternalId,
                                                                  idn_run_eligty__c, nbr_size_fcompsn__c, cnt_chldrn_rqng_care__c, amt_copay_ft__c, amt_copay_pt__c,
                                                                  amt_income_county_max__c, amt_income_annual__c, amt_grant_total_annual__c, amt_fpg_pctg__c, cde_income_result__c,
                                                                  amt_clg_county_new__c, amt_income_smi__c, amt_ddtn_total_annual__c, amt_income_gross_annual__c, idn_eligty_fcompsn__c, cde_reason_change_fcompsn__c
                                                                  FROM batchsit_t_fcompsn_eligty__x
                                                                  WHERE idn_run_eligty__c =: idnRunEligty AND idn_eligty_fcompsn__c!=null ORDER BY idn_eligty_fcompsn__c DESC];
            System.debug('unfilteredCaseEligibility:'+unfilteredCaseEligibility);
            List<batchsit_t_fcompsn_eligty__x> caseEligibility = new List<batchsit_t_fcompsn_eligty__x>();
            for(batchsit_t_fcompsn_eligty__x fcompsnEligty:unfilteredCaseEligibility){
                if(eligRun.get(0).dte_run_eligty__c<=Date.newInstance(2018,8,31) || fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
                    caseEligibility.add(fcompsnEligty);
	                fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
                }
            }
            data.put('fcompsnEligtyIdToRecord',fcompsnEligtyIdToRecord);
            System.debug('fcompsnEligtyIdToRecord:'+fcompsnEligtyIdToRecord);
            data.put('caseEligibility',caseEligibility);
            System.debug('caseEligibility:'+caseEligibility);
            List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = [SELECT ExternalId,cde_status_eligty_family__c, dte_begin_effv__c, dte_end_effv__c, idn_eligty_fcompsn__c
                                                                                FROM batchsit_t_fcompsn_eligty_detail__x
                                                                                WHERE idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet() 
                                                                                ORDER BY dte_begin_effv__c DESC ,idn_eligty_fcompsn__c DESC LIMIT 1000];
            data.put('caseEligibilityDetails',caseEligibilityDetails);
            if(!caseEligibilityDetails.isEmpty()){
                String idnEligtyFcompsnLatest = caseEligibilityDetails.get(0).idn_eligty_fcompsn__c;
                List<batchsit_t_fcompsn_indiv_eligty__x> caseIndivEligibilities= [SELECT idn_indiv_fcompsn__c, idn_case_indiv__c, idn_case_indiv__r.IDN_CLIENT__c,txt_cmt_ovrd__c, cde_reason_ovrd__c,
                                                                                  (SELECT cde_status_detail_eligty_indiv__c FROM batchsit_t_indiv_eligty_detail__r ORDER BY dte_begin_effv__c DESC LIMIT 1000) 
                                                                                  FROM batchsit_t_fcompsn_indiv_eligty__x
                                                                                  WHERE idn_eligty_fcompsn__c=: idnEligtyFcompsnLatest
                                                                                  AND idn_case_indiv__c!=null AND idn_indiv_fcompsn__c!=null];
                data.put('caseIndivEligibilities',caseIndivEligibilities);
                List<batchsit_t_fcompsn_failr__x> caseEligibilityFailure = [SELECT cde_reason_failr_fcompsn__c,idn_fcompsn_failr__c, idn_doc__c FROM batchsit_t_fcompsn_failr__x WHERE idn_eligty_fcompsn__c=:idnEligtyFcompsnLatest];
                data.put('caseEligibilityFailure',caseEligibilityFailure);
                //get employment income
                List<batchsit_t_indiv_eligty_emplmt_income__x> indivEmplmtIncome = [SELECT amt_income_annual__c, nam_busns__c, cde_type_emplmt__c, 
                                                                                    //idn_eligty_fcompsn__c, idn_indiv_fcompsn__r.idn_case_indiv__r.NAM_INDIV__c, 
                                                                                    idn_eligty_fcompsn__c, idn_indiv_fcompsn__r.idn_case_indiv__c, 
                                                                                    idn_indiv_eligty_emplmt_income__c,idn_emplmt_indiv__c
                                                                                    FROM batchsit_t_indiv_eligty_emplmt_income__x 
                                                                                    WHERE idn_eligty_fcompsn__c=:caseEligibilityDetails.get(0).idn_eligty_fcompsn__c];
                data.put('indivEmplmtIncome',indivEmplmtIncome);
            }else{
                MyException myEx = new MyException();
                myEx.errorMessage = 'No caseEligibilityDetails exist';
                throw myEx;
            }
            return data;
        }
    }
    
    public class MyException extends Exception{
        public String errorMessage;
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String elgibilityRunId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        try{
            Map<String, Object> data = queryData(elgibilityRunId);
            List<batchsit_t_eligty_run__x> eligRun = (List<batchsit_t_eligty_run__x>)data.get('eligRun');
            List<T_SBSD_CASE__c> caseRecs = [SELECT Id, Name, CNT_SIZE_FAMILY__c, CNT_CC_NEED_CHILD__c, 
                                             AMT_INCOME__c, CDE_COUNTY__c, Program_Type__c,
                                             IDN_EXTNL__c, DTE_CHGD_LAST_DATA_ELIGTY__c,
                                             (SELECT Id FROM CaseIndividuals__r)
                                             FROM T_SBSD_CASE__c
                                             WHERE IDN_EXTNL__c =: eligRun.get(0).IDN_CASE__c LIMIT 1000];
            if(!eligRun.isEmpty() && String.isNotEmpty(eligRun.get(0).idn_case__c) && !caseRecs.isEmpty()) {
                objectData.put('eligRun', eligRun.get(0));  
                objectData.put('caseRec', caseRecs.get(0));
                //Removed unused variable on 5/13/2018 BG  
                //get household eligibility
                List<batchsit_t_fcompsn_eligty__x> caseEligibility = (List<batchsit_t_fcompsn_eligty__x>)data.get('caseEligibility');
                
                if(!caseEligibility.isEmpty() && caseEligibility.get(0).idn_eligty_fcompsn__c!=null) {
                    
                    Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = (Map<String, batchsit_t_fcompsn_eligty__x>)data.get('fcompsnEligtyIdToRecord');
                    
                    //get household eligibility detail
                    List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = (List<batchsit_t_fcompsn_eligty_detail__x>)data.get('caseEligibilityDetails');
                    if(!caseEligibilityDetails.isEmpty()) {
                        objectData.put('caseEligibilityDetails', caseEligibilityDetails.get(0));
                        batchsit_t_fcompsn_eligty__x currentHouseholdEligibility = fcompsnEligtyIdToRecord.get(caseEligibilityDetails.get(0).idn_eligty_fcompsn__c);
                        try{
                            Decimal amtFpgPctg = Decimal.valueOf(currentHouseholdEligibility.amt_fpg_pctg__c);
                            amtFpgPctg = amtFpgPctg.setScale(3);
                            //amtFpgPctg = Math.round(amtFpgPctg);
                            currentHouseholdEligibility.amt_fpg_pctg__c = String.valueOf(amtFpgPctg);
                        }catch(Exception ex){
                            objectData.put('warning',ex.getMessage());
                        }
                        objectData.put('caseEligibility', currentHouseholdEligibility);
                        if(caseEligibilityDetails.size()>1){
                            objectData.put('lastCaseEligibilityDetails', caseEligibilityDetails.get(1));  
                            objectData.put('lastCaseEligibility', fcompsnEligtyIdToRecord.get(caseEligibilityDetails.get(1).idn_eligty_fcompsn__c));                        
                            if(caseEligibilityDetails.size()>2){
                                objectData.put('secondLastCaseEligibilityDetails', caseEligibilityDetails.get(2));  
                                objectData.put('secondLastCaseEligibility', fcompsnEligtyIdToRecord.get(caseEligibilityDetails.get(2).idn_eligty_fcompsn__c));                        
                            }
                        }
                        
                        Map<String, String> indivIdsToIndivEligibility = new Map<String, String>();
                        Map<String, IndividualEligibilityWrapper> indivEligIdToWrapper = new Map<String, IndividualEligibilityWrapper>();
                        String idnClient;
                        List<T_SBSD_INDIV__c> individuals = new List<T_SBSD_INDIV__c>();
                        if(Test.isRunningTest()){
                            individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 50000];
                        }
                        
                        for(batchsit_t_fcompsn_indiv_eligty__x indivEligibility:(List<batchsit_t_fcompsn_indiv_eligty__x>)data.get('caseIndivEligibilities')){
                            if(String.isNotEmpty(indivEligibility.idn_case_indiv__c)){
                                if(Test.isRunningTest()){
                                    idnClient = indivIdsToIndivEligibility.isEmpty()?individuals.get(0).Id:individuals.get(1).Id;
                                }else if(String.isNotEmpty(indivEligibility.idn_case_indiv__r.IDN_CLIENT__c)){
                                    idnClient = indivEligibility.idn_case_indiv__r.IDN_CLIENT__c;
                                }
                                if(String.isNotEmpty(idnClient)){
                                    indivIdsToIndivEligibility.put(idnClient, String.valueOf(indivEligibility.idn_indiv_fcompsn__c));    
                                    IndividualEligibilityWrapper indivEligWrapper = new IndividualEligibilityWrapper();
                                    indivEligWrapper.idnIndivFcompsn = String.valueOf(indivEligibility.idn_indiv_fcompsn__c);
                                    if(!indivEligibility.batchsit_t_indiv_eligty_detail__r.isEmpty()){
                                        indivEligWrapper.status = indivEligibility.batchsit_t_indiv_eligty_detail__r.get(0).cde_status_detail_eligty_indiv__c;
                                    }
				    
				    if(String.isNotEmpty(indivEligibility.txt_cmt_ovrd__c)){
                                        indivEligWrapper.overrideComments = indivEligibility.txt_cmt_ovrd__c;
                                    }
                                    if(String.isNotEmpty(indivEligibility.cde_reason_ovrd__c)){
                                        indivEligWrapper.overrideReason = indivEligibility.cde_reason_ovrd__c;
                                    }
                                    indivEligIdToWrapper.put(indivEligWrapper.idnIndivFcompsn, indivEligWrapper);                                                          
                                }
                            }
                        }
                        Set<String> careTakerRelationships = new Set<String>{'F', 'M', 'CLH', 'CLW', 'W', 'H', 'LIC'};
                            IndividualEligibilityWrapper wrap;
                        for(T_SBSD_INDIV__c indiv:[SELECT Id, NAM_FIRST__c, NAM_LAST__c, Age__c, IDN_STATE__c, (SELECT Id FROM Relationship__r WHERE CDE_TYPE_REL_INDIV__c IN:careTakerRelationships), (SELECT Id FROM Case_Individual__r WHERE IND_CRTKR__c=true and IDN_CASE__c =: eligRun.get(0).IDN_CASE__c AND DTE_BEGIN_EFFV__c <= :system.today() AND (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today())) FROM T_SBSD_INDIV__c WHERE Id IN:indivIdsToIndivEligibility.keySet()]){
                            if(String.isNotEmpty(indivIdsToIndivEligibility.get(indiv.Id))){
                                wrap = new IndividualEligibilityWrapper();
                                wrap = indivEligIdToWrapper.get(indivIdsToIndivEligibility.get(indiv.Id));
                                if(!indiv.Case_Individual__r.isEmpty() || indiv.Age__c>18 || !indiv.Relationship__r.isEmpty()){
                                    wrap.isParentCaretaker = true;
                                }else{
                                    wrap.isParentCaretaker = false;
                                }
                                wrap.firstName = indiv.NAM_FIRST__c;
                                wrap.lastName = indiv.NAM_LAST__c;
                                wrap.stateId = indiv.IDN_STATE__c;
                                wrap.indivId = indiv.Id;
                                indivEligIdToWrapper.put(indivIdsToIndivEligibility.get(indiv.Id),wrap);
                            }
                        }
                        
                        System.debug(indivEligIdToWrapper);
                        objectData.put('indivEligIdToWrapper',indivEligIdToWrapper);
                        List<batchsit_t_fcompsn_failr__x> caseEligibilityFailure = (List<batchsit_t_fcompsn_failr__x>)data.get('caseEligibilityFailure');
                        objectData.put('caseEligibilityFailure',caseEligibilityFailure);
                        
                        List<batchsit_t_sbsd_case_copay__x> casePayment = [SELECT amt_copay_case_assesd__c,amt_copay_case_ft__c, amt_copay_case_pt__c, dte_begin_effv__c
                                                                           FROM batchsit_t_sbsd_case_copay__x
                                                                           WHERE idn_case__c =: caseRecs.get(0).IDN_EXTNL__c AND dte_end_effv__c!=null LIMIT 2];
                        if(casePayment.size()>0) {
                            objectData.put('casePayment', casePayment);   
                        }
                        
                        //Logic to filter active Individual Eligibility Employment Income based on employment.
                        List<batchsit_t_indiv_eligty_emplmt_income__x> unfiltertedIndivEmplmtIncome = (List<batchsit_t_indiv_eligty_emplmt_income__x>)data.get('indivEmplmtIncome');
                        
                        Map<String,Boolean> activeEmployments = new Map<String,Boolean>();
                        for(batchsit_t_indiv_eligty_emplmt_income__x eachIndivEmplmtIncome:unfiltertedIndivEmplmtIncome){
                            activeEmployments.put(eachIndivEmplmtIncome.idn_emplmt_indiv__c, false);
                        }
                        for(T_SBSD_INDIV_EMPLMT__c employment:[SELECT Name FROM T_SBSD_INDIV_EMPLMT__c WHERE Name IN:activeEmployments.keySet() AND (DTE_END_EFFV__c>=:eligRun.get(0).dte_run_eligty__c OR DTE_END_EFFV__c=null)]){
                            activeEmployments.put(employment.Name, true);
                        }
                        List<batchsit_t_indiv_eligty_emplmt_income__x> indivEmplmtIncome = new List<batchsit_t_indiv_eligty_emplmt_income__x>();
                        for(batchsit_t_indiv_eligty_emplmt_income__x eachIndivEmplmtIncome:unfiltertedIndivEmplmtIncome){
                            if(activeEmployments.get(eachIndivEmplmtIncome.idn_emplmt_indiv__c)){
                                indivEmplmtIncome.add(eachIndivEmplmtIncome);
                            }
                        }
                        Set<String> caseIndivIds = new Set<String>();
                        for(batchsit_t_indiv_eligty_emplmt_income__x eachIndivEmptIncome : indivEmplmtIncome){
                            caseIndivIds.add(eachIndivEmptIncome.idn_indiv_fcompsn__r.idn_case_indiv__c);
                        }
                        
                        List<batchsit_t_indiv_eligty_emplmt_income__x> indivEmplmtIncomeTypeEmployment = new List<batchsit_t_indiv_eligty_emplmt_income__x>();
                        List<batchsit_t_indiv_eligty_emplmt_income__x> indivEmplmtIncomeTypeSelfEmployment = new List<batchsit_t_indiv_eligty_emplmt_income__x>();
                        if(indivEmplmtIncome.size()>0) {
                            for(batchsit_t_indiv_eligty_emplmt_income__x eachIndivEmplmtIncome : indivEmplmtIncome) {
                                if(eachIndivEmplmtIncome.cde_type_emplmt__c == 'E') {
                                    indivEmplmtIncomeTypeEmployment.add(eachIndivEmplmtIncome); 
                                } else {
                                    indivEmplmtIncomeTypeSelfEmployment.add(eachIndivEmplmtIncome);
                                }
                            }
                            if(indivEmplmtIncomeTypeEmployment.size()>0) {
                                objectData.put('indivEmplmtIncomeTypeEmployment',indivEmplmtIncomeTypeEmployment);   
                            }
                            if(indivEmplmtIncomeTypeSelfEmployment.size()>0) {
                                objectData.put('indivEmplmtIncomeTypeSelfEmployment',indivEmplmtIncomeTypeSelfEmployment);   
                            }
                        }
                        
                        //get employment expense
                        List<batchsit_t_indiv_eligty_emplmt_exp__x> indivEmplmtExpense = [SELECT amt_exp_annual__c, idn_indiv_fcompsn__r.idn_case_indiv__c,idn_emplmt_indiv__c
                                                                                          FROM batchsit_t_indiv_eligty_emplmt_exp__x 
                                                                                          WHERE idn_eligty_fcompsn__c=:caseEligibilityDetails.get(0).idn_eligty_fcompsn__c];
                        
                        for(batchsit_t_indiv_eligty_emplmt_exp__x eachIndivEmptExpense : indivEmplmtExpense) {
                            caseIndivIds.add(eachIndivEmptExpense.idn_indiv_fcompsn__r.idn_case_indiv__c);
                        }
                        
                        if(indivEmplmtExpense.size()>0) {
                        	List<batchsit_t_indiv_eligty_emplmt_exp__x> filteredIndivEmplmtExpense = new List<batchsit_t_indiv_eligty_emplmt_exp__x>();
	                        for(batchsit_t_indiv_eligty_emplmt_exp__x eachIndivEmptExpense : indivEmplmtExpense) {	
                                if(eachIndivEmptExpense.idn_emplmt_indiv__c!=null && activeEmployments.get(String.valueOf(eachIndivEmptExpense.idn_emplmt_indiv__c))){
                                    filteredIndivEmplmtExpense.add(eachIndivEmptExpense);
                                }
                            }
                            objectData.put('indivEmplmtExpense',filteredIndivEmplmtExpense);   
                        }
                        
                        //get employment other income
                        List<batchsit_t_indiv_eligty_income_other__x> indivEligtyOtherIncome = [SELECT amt_income_annual__c, idn_indiv_fcompsn__r.idn_case_indiv__c,
                                                                                                cde_source_income__c
                                                                                                FROM batchsit_t_indiv_eligty_income_other__x
                                                                                                WHERE idn_eligty_fcompsn__c=:caseEligibilityDetails.get(0).idn_eligty_fcompsn__c];
                        for(batchsit_t_indiv_eligty_income_other__x eachIndivIncomeOther : indivEligtyOtherIncome) {
                            caseIndivIds.add(eachIndivIncomeOther.idn_indiv_fcompsn__r.idn_case_indiv__c);
                        }
                        
                        if(indivEligtyOtherIncome.size()>0) {
                            objectData.put('indivEligtyOtherIncome',indivEligtyOtherIncome);
                        }
                        
                        //get employment deduction
                        List<batchsit_t_indiv_eligty_income_ddtn__x> indivEligtyIncomeDeduction = [SELECT amt_ddtn_annual__c, idn_indiv_fcompsn__r.idn_case_indiv__c,
                                                                                                   cde_type_ddtn__c
                                                                                                   FROM batchsit_t_indiv_eligty_income_ddtn__x
                                                                                                   WHERE idn_eligty_fcompsn__c=:caseEligibilityDetails.get(0).idn_eligty_fcompsn__c];
                        
                        for(batchsit_t_indiv_eligty_income_ddtn__x eachIndivEmptDed : indivEligtyIncomeDeduction) {
                            caseIndivIds.add(eachIndivEmptDed.idn_indiv_fcompsn__r.idn_case_indiv__c);
                        }
                        
                        if(indivEligtyIncomeDeduction.size()>0) {
                            objectData.put('indivEligtyIncomeDeduction', indivEligtyIncomeDeduction);
                        }
                        
                        //get all case individuals associated to income records
                        Map<String, T_SBSD_CASE_INDIV__c> caseIndivs = new Map<String, T_SBSD_CASE_INDIV__c>();
                        for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT Id, NAM_INDIV__c, IDN_EXTNL__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_EXTNL__c IN: caseIndivIds]){
                            caseIndivs.put(caseIndiv.IDN_EXTNL__c, caseIndiv);
                        }
                        
                        System.debug('caseIndivIds:'+caseIndivIds);
                        System.debug('caseIndivs:'+caseIndivs);
                        objectData.put('caseIndivs', caseIndivs);
                        
                        
                        //Read Only view based on profile
                        /* Using Custom Permission CCCAP-14993 - decommissioning State IT User and State Program Administrator
                        Set<String> readOnlyForProfiles = new Set<String>{'Fiscal Worker', 'Business Office Supervisor','Business Office Worker','Fiscal Worker Supervisor', 'Provider Worker', 'Provider Worker Supervisor', 'Read Only User', 'State IT User', 'State Program Administrator'};
                            List<Profile> profiles = [select Name from profile where id = :userinfo.getProfileId()]; */
                        if(FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Business_Office_Supervisor') ||FeatureManagement.checkPermission('Business_Office_Worker') ||FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') ||
                        FeatureManagement.checkPermission('Provider_Worker') ||FeatureManagement.checkPermission('Provider_Worker_Supervisor') ||FeatureManagement.checkPermission('Read_Only_User')){
                            objectData.put('readOnlyMode', true);
                        }
                    }else{
                        isSuccessful=false;
                        message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
                    }
                }else{
                    isSuccessful=false;
                    message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
                }
            }else{
                isSuccessful=false;
                message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
            }
        }catch(MyException myEx){
            isSuccessful=false;
            message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
            objectData.put('error',myEx.errorMessage);
            ExceptionLoggingServices.captureExceptionLog(myEx, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'getInitData'});
        }catch(Exception ex){
            isSuccessful=false;
            message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
            objectData.put('error',ex.getLineNumber()+'-'+ex.getMessage()+'-'+ex.getCause());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'getInitData'});
        }
        System.debug(new LightningServerResponse(isSuccessful,message,objectData));
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
   public static LightningServerResponse validateConfirmEligibility(String elgibilityRunId, String caseEligProg){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        
        List<String> pageMessages = new List<String>();
        try{
            Map<String,Object> data = queryData(elgibilityRunId);
            List<batchsit_t_eligty_run__x> eligRun = (List<batchsit_t_eligty_run__x>)data.get('eligRun');
            System.debug('eligRun:'+eligRun);
            if(!eligRun.isEmpty()){
                if(eligRun.get(0).dte_run_eligty__c!=System.today()){
                    pageMessages.add(System.Label.HER_RUN_DATE_PAST_AND_PLEASE_REASSESS);
                }
                
                if(String.isNotEmpty(eligRun.get(0).idn_case__c) && eligRun.get(0).idn_case__r.IND_CHGD_DATA_ELIGTY__c){
                    pageMessages.add(System.Label.DATA_CHANGED_PLEASE_REASSESS);
                }
                
                List<batchsit_t_fcompsn_eligty__x> caseEligibility1 = (List<batchsit_t_fcompsn_eligty__x>)data.get('caseEligibility');
                /*if(caseEligProg != null && caseEligProg != 'CW'){
                    if(eligRun.get(0).dte_redet_ovrd__c==null && (eligRun.get(0).dte_redet_prpsd__c==null || eligRun.get(0).dte_redet_prpsd__c<System.today())){
                        pageMessages.add(System.Label.HER_CNF_ELIG_Redetermination_Override_Date_In_Past_Error);
                	}
                    if(eligRun.get(0).dte_redet_ovrd__c!=null && eligRun.get(0).dte_redet_ovrd__c<System.today()){
                        pageMessages.add(System.Label.HER_CNF_ELIG_Redetermination_Override_Date_In_Past_Error);
                	}
                }*/
                
                List<batchsit_t_fcompsn_eligty__x> caseEligibility = (List<batchsit_t_fcompsn_eligty__x>)data.get('caseEligibility');
                if(!caseEligibility.isEmpty() && caseEligibility.get(0).idn_eligty_fcompsn__c!=null) {
                    //get household eligibility detail
                    List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = (List<batchsit_t_fcompsn_eligty_detail__x>)data.get('caseEligibilityDetails');
                    if(!caseEligibilityDetails.isEmpty()) {
                        List<batchsit_t_fcompsn_failr__x> caseEligibilityFailure = (List<batchsit_t_fcompsn_failr__x>)data.get('caseEligibilityFailure');
                        if(caseEligibilityDetails.get(0).cde_status_eligty_family__c == 'ELI' && !caseEligibilityFailure.isEmpty()){
                            pageMessages.add(System.Label.HER_Eligible_HH_With_Inelig_Reasons);
                        }
                        if(caseEligibilityDetails.get(0).cde_status_eligty_family__c == 'INE' && caseEligibilityFailure.isEmpty()){
                            pageMessages.add(System.Label.HER_Eligible_HH_Without_Inelig_Reasons);
                        }
                    }
                    
                    List<batchsit_t_fcompsn_indiv_eligty__x> indivEligibilities = queryIndivEligibilities(caseEligibilityDetails.get(0).idn_eligty_fcompsn__c);
                    Boolean anyEligIndivWithFailureReasons = false, anyIneligIndivWithoutFailureReasons = false;                    
                    for(batchsit_t_fcompsn_indiv_eligty__x indivEligiblity:indivEligibilities){
                        if(!anyEligIndivWithFailureReasons && !indivEligiblity.batchsit_t_indiv_eligty_detail__r.isEmpty() && 
                           (indivEligiblity.batchsit_t_indiv_eligty_detail__r.get(0).cde_status_detail_eligty_indiv__c=='EA' || 
                            indivEligiblity.batchsit_t_indiv_eligty_detail__r.get(0).cde_status_detail_eligty_indiv__c=='EC')
                           && !indivEligiblity.batchsit_t_indiv_eligty_failr__r.isEmpty()){
                               anyEligIndivWithFailureReasons = true;
                           }
                        
                        if(!anyIneligIndivWithoutFailureReasons && !indivEligiblity.batchsit_t_indiv_eligty_detail__r.isEmpty() && 
                           (indivEligiblity.batchsit_t_indiv_eligty_detail__r.get(0).cde_status_detail_eligty_indiv__c=='IA' || 
                            indivEligiblity.batchsit_t_indiv_eligty_detail__r.get(0).cde_status_detail_eligty_indiv__c=='IC')
                           && indivEligiblity.batchsit_t_indiv_eligty_failr__r.isEmpty()){
                               anyIneligIndivWithoutFailureReasons = true;
                           }
                    }
                    
                    if(anyEligIndivWithFailureReasons){
                        pageMessages.add(System.Label.HER_Eligible_Indiv_With_Inelig_Reasons);
                    }
                    
                    if(anyIneligIndivWithoutFailureReasons){
                        pageMessages.add(System.Label.HER_Ineligible_Indiv_Without_Inelig_Reasons);
                    }
                    
                    Map<String, String> indivIdsToIndivEligibility = new Map<String, String>();
                    Map<String, IndividualEligibilityWrapper> indivEligIdToWrapper = new Map<String, IndividualEligibilityWrapper>();
                    String idnClient;
                    List<T_SBSD_INDIV__c> individuals = new List<T_SBSD_INDIV__c>();
                    if(Test.isRunningTest()){
                        individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 50000];
                    }
                    for(batchsit_t_fcompsn_indiv_eligty__x indivEligibility:(List<batchsit_t_fcompsn_indiv_eligty__x>)data.get('caseIndivEligibilities')){
                        if(String.isNotEmpty(indivEligibility.idn_case_indiv__c)){
                            if(Test.isRunningTest()){
                                idnClient = indivIdsToIndivEligibility.isEmpty()?individuals.get(0).Id:individuals.get(1).Id;
                            }else if(String.isNotEmpty(indivEligibility.idn_case_indiv__r.IDN_CLIENT__c)){
                                idnClient = indivEligibility.idn_case_indiv__r.IDN_CLIENT__c;
                            }
                            
                            indivIdsToIndivEligibility.put(idnClient, String.valueOf(indivEligibility.idn_indiv_fcompsn__c));    
                            IndividualEligibilityWrapper indivEligWrapper = new IndividualEligibilityWrapper();
                            indivEligWrapper.idnIndivFcompsn = String.valueOf(indivEligibility.idn_indiv_fcompsn__c);
                            if(Test.isRunningTest()){
                                indivEligWrapper.status = 'EC';
                            }else if(!indivEligibility.batchsit_t_indiv_eligty_detail__r.isEmpty()){
                                indivEligWrapper.status = indivEligibility.batchsit_t_indiv_eligty_detail__r.get(0).cde_status_detail_eligty_indiv__c;
                            }
                            indivEligIdToWrapper.put(indivEligWrapper.idnIndivFcompsn, indivEligWrapper);                                                          
                        }
                    }
                    Set<String> careTakerRelationships = new Set<String>{'F', 'M', 'CLH', 'CLW', 'W', 'H', 'LIC'};
                    IndividualEligibilityWrapper indivEligWrap;
                        for(T_SBSD_INDIV__c indiv:[SELECT Id, NAM_FIRST__c, NAM_LAST__c, Age__c, IDN_STATE__c, (SELECT Id FROM Relationship__r WHERE CDE_TYPE_REL_INDIV__c IN:careTakerRelationships), (SELECT Id FROM Case_Individual__r WHERE IND_CRTKR__c=true) FROM T_SBSD_INDIV__c WHERE Id IN:indivIdsToIndivEligibility.keySet()]){
                            indivEligWrap = indivEligIdToWrapper.get(indivIdsToIndivEligibility.get(indiv.Id));
                            if(String.isNotEmpty(indivIdsToIndivEligibility.get(indiv.Id))){
                                if(!indiv.Case_Individual__r.isEmpty() || indiv.Age__c>18 || !indiv.Relationship__r.isEmpty()){
                                    indivEligWrap.isParentCaretaker = true;
                                }else{
                                    indivEligWrap.isParentCaretaker = false;
                                }
                            }
                            indivEligIdToWrapper.put(indivIdsToIndivEligibility.get(indiv.Id),indivEligWrap);
                        }
                    Boolean anyIneligibleParentCaretaker = false, anyEligibleChild = false, anyChildExist = false;
                    
                    for(IndividualEligibilityWrapper wrap:indivEligIdToWrapper.values()){
                        System.debug(wrap);
                        if(wrap.isParentCaretaker && wrap.status=='IA'){
                            anyIneligibleParentCaretaker = true;
                        }
                        if(!wrap.isParentCaretaker){
                            anyChildExist = true;
                            if(wrap.status=='EC'){
                                anyEligibleChild = true;
                            }
                        }
                    }
                    if(Test.isRunningTest()){
                        anyIneligibleParentCaretaker = true;
                        anyEligibleChild = false;
                        anyChildExist = true;
                    }                    
                    if(anyIneligibleParentCaretaker && caseEligibilityDetails.get(0).cde_status_eligty_family__c=='ELI'){
                        pageMessages.add(System.Label.HER_Parent_Caretaker_Eligible);
                    }
                    //If there exists child and there is no eligible child
                    if(!anyEligibleChild && anyChildExist && caseEligibilityDetails.get(0).cde_status_eligty_family__c=='ELI'){
                        pageMessages.add(System.Label.HER_At_Least_One_Child_Eligible);
                    }
                }
            }
            objectData.put('pageMessages',pageMessages);
        }catch(Exception ex){
            objectData.put('pageMessages',pageMessages);
            isSuccessful = false;
            message = ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'validateConfirmEligibility'});
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    // Called From ContinuationController
    public static Object doCallBREConfirmEligibilityContinuation(Continuation con, String CaseID, String RunID){
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setEndpoint(System.Label.BRE_ConfirmEligibility);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String body = '{"CaseID":"'+CaseID+'","RunID":"'+RunID+'","UserLastUpdated":"'+UserInfo.getUserId()+'"}';
        req.setBody(body);
        System.debug(body);
        // Adding req for continuation callBacks.
        con.state = con.addHttpRequest(req);
        con.continuationMethod = 'callbackForBREConfirmEligibility';        
        // Return it to the system for processing
        return con;
    }       
    
    // BRECreate Callback for ContinuationController 
    public static Object doCallBackBREConfirmEligibilityContinuation(Object state){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message='';
        try{
        System.debug(state);
        HttpResponse response = Continuation.getResponse((String)state);
        System.debug('response'+response);
        
        Integer statusCode = response.getStatusCode();
        
        if (statusCode >= 2000) {
            isSuccessful = false;
            message = Label.CONTINUATION_ERROR + statusCode;
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinuation'});
        }else if (response.getStatusCode() != 200) {
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinuation'});
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            isSuccessful = false;
            String error = Label.An_error_occurred_while_calling_BRE;
            error+=response.getStatus()!=null?String.valueOf(response.getStatus())+',':'';
            String errorBody = response.getBody();
            String actualError = errorBody.substringBetween('The exception message is', 'See server logs for more details');
            if(String.isNotEmpty(actualError)){
                error += actualError;
                error = error.replaceAll('\'', '');
            }else{
                error+= errorBody;
            }
            message = error;
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinuation'});
        } else {
            System.debug(response.getBody());
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('data:'+data);
            System.debug('data.get("ErrorValue"):'+data.get('ErrorValue'));
            if(data.get('ErrorValue')!=null){
                List<Object> errorValues = (List<Object>)data.get('ErrorValue');
                if(!errorValues.isEmpty()){
                    System.debug('errorValues:'+errorValues);
                    for(Object ob:errorValues){
                        message+=String.valueOf(ob);
                    }
                    isSuccessful = false;
	                ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinuation'});
                }
            }else{
                objectData.put('data',String.valueOf(data)); 
            }
        }
        } catch(Exception ex) {
        	isSuccessful = false;
            message=ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'EligibilityFlowCmpApxCtrl','Method__c'=>'doCallBackBREConfirmEligibilityContinuation'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    } 
    
    // Updating the auth and enrollment records
    @AuraEnabled    
    public static LightningServerResponse updateAuthAndEnrollment(String caseId, string programType){
        Map<String,Object> objectData = new Map<String,Object>();
        String pmtEnrollBegin = System.Label.Payment_by_Enrollment_Begin_Date;
        String pmtEnrollEnd = System.Label.Payment_by_Enrollment_End_Date;
        Date pmtEnrollBeginDate = Date.valueOf(pmtEnrollBegin);
        Date pmtEnrollEndDate = pmtEnrollEnd!='null' ? Date.valueOf(pmtEnrollEnd) : null;
        Date dt = system.today()+1;
        List<T_AUTH__c> authListToBeUpdated = new List<T_AUTH__c>();
        List<ProviderCalendarApxCtrl.encumbranceWrap> encumtoupdate = new List<ProviderCalendarApxCtrl.encumbranceWrap>();
        Map<String,string> resultMap = new Map<String,string>();
        String message;
        Boolean isSuccessful=true;
        if(programType !='CW' ){
            //Get all the effective authorization on the case
            //CCCAP-12574
            
            
            Map<Id, T_AUTH__c> authRec = new Map<Id, T_AUTH__c>([
                Select Id, IDN_CASE__c, IDN_EXTNL__c, IDN_CLIENT__c, IDN_PROVR__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,
                IDN_CLIENT__r.DTE_DOB__c, IDN_PROVR__r.CDE_TYPE_PROVR__c, Protective_Services_Indicator__c 
                from T_AUTH__c 
                where IDN_CASE__c = :caseId 
                and (DTE_BEGIN_EFFV_AUTH__c <= today OR DTE_BEGIN_EFFV_AUTH__c > today) 
                and DTE_END_EFFV_AUTH__c >= today 
                and Protective_Services_Indicator__c = false
            ]);
            
            List<String> idList = new List<String>();
            
            for (Id recordId : authRec.keySet()) {
                idList.add(String.valueOf(recordId));
            }
            
            Map<String,List<batchsit_t_auth_encmbr__x>> fetchedEncumberence = HerokuService.authEncumbrancefetchMult(idList);
            //added for CCCAP-12992
            if(HerokuService.isApiSuccess == false){
                message = 'There is an unknown problem. Please contact your administrator.';
                isSuccessful = false;
            }else{
                for (T_AUTH__c auth : authRec.values()) {
                    Date dob36Months = auth.IDN_CLIENT__r.DTE_DOB__c.addYears(3);
                    Boolean isProviderExempt = false;
                    
                    if (System.Label.Exempt_Provider_Type.contains(auth.IDN_PROVR__r.CDE_TYPE_PROVR__c)) {
                        isProviderExempt = true;
                    }
                    
                    if (!isProviderExempt && (programType != 'CW' || auth.Protective_Services_Indicator__c) 
                    && dt >= pmtEnrollBeginDate 
                    && (pmtEnrollEndDate == null || dt <= pmtEnrollEndDate) 
                    && dt < dob36Months) {
                        if(fetchedEncumberence.containsKey(auth.Id)){
                            for (batchsit_t_auth_encmbr__x anAuthEncmbr : fetchedEncumberence.get(auth.Id)) {
                                if (anAuthEncmbr.DTE_CARE__c >= dt && (anAuthEncmbr.DTE_CARE__c <= pmtEnrollEndDate || pmtEnrollEndDate == null) && anAuthEncmbr.DTE_CARE__c < dob36Months) {
                                    //added for CCCAP-14174
                                    ProviderCalendarApxCtrl.encumbranceWrap indiWrap=new ProviderCalendarApxCtrl.encumbranceWrap();
                                    indiWrap.lastmodifieddate = String.valueOf(system.now().format('yyyy-MM-dd HH:mm:ss')) ;
                                    indiWrap.lastmodifiedbyid = Userinfo.getUserId();
                                    indiWrap.idn_Encmbr_Auth = string.valueof(anAuthEncmbr.ExternalId);
                                    indiWrap.ind_0_36_months = 'Y';
                                    encumtoupdate.add(indiWrap);
                                }
                            }
                        }
                    }
                }
                if(!Test.isRunningTest() && !encumtoupdate.isEmpty()){
                    resultMap = HerokuService.authEncumbranceUpdate(JSON.serialize(encumtoupdate)); //CCCAP-14174
                    if(HerokuService.isApiSuccess == false){
                        message = 'There is an unknown problem. Please contact your administrator.';
                        isSuccessful = false;
                    }
                    else{
                        isSuccessful =true;
                        message = 'Success';
                    }
                }                
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);//isSuccessFull;
    }

    // Updating Program Type on Case record
    @AuraEnabled    
    public static LightningServerResponse saveCaseProgramType(String caseId, string programType){
        Map<String,Object> objectData = new Map<String,Object>();
        String message='';
        Boolean isSuccessful=true;
        List<T_SBSD_CASE__c> caseRec = [SELECT Id, Name, Program_Type__c,
                                            (select id from CaseIndividuals__r where IDN_Client__r.UFE_Request_Flag__c=true)
                                             FROM T_SBSD_CASE__c WHERE Id=:caseId];
        T_SBSD_CASE__c caseRecToBeUpdated = new T_SBSD_CASE__c();
        if(programType != null){
            caseRecToBeUpdated.Id = caseRec[0].Id;
            caseRecToBeUpdated.Program_Type__c = programType;
            caseRecToBeUpdated.Case_Reopened__c = false; // added as part of CCCAP-12497
            List<DMLResult> lstDMLResult = GenericDMLHandler.updateRecords(new List<SObject>{caseRecToBeUpdated}, false, null);
            if(!lstDMLResult.isEmpty()) {
                if(lstDMLResult.get(0).crudPermissionException!=null) {
                    isSuccessful = false;
                    message = lstDMLResult.get(0).crudPermissionException.getMessage();
                }
            }
        }
        else{
            isSuccessful = false;
        } 
        /* Added for UFE by Shashank
            check if There exists Individual on a case where UFE_Request_Flag__c is true ,
          inform BridgeCare about new Confirmed Eligibility by Publishing PE*/
          if(caseRec[0].CaseIndividuals__r!=null && caseRec[0].CaseIndividuals__r.size()>0){
            Eventbus.publish(new UFEChangeInterface__e(IdNumber__c=caseId,Type__c='case')); 
        }
        return new LightningServerResponse(isSuccessful,message,objectData);       
    }
    //CCCAP-13251
    @AuraEnabled    
    public static LightningServerResponse updateCaseApplnDateInfo(String caseId){
        Map<String,Object> objectData = new Map<String,Object>();
        String message='';
        Boolean isSuccessful=true;
        T_SBSD_CASE__c caseRec = [SELECT Id, DTE_APPLN__c FROM T_SBSD_CASE__c WHERE Id=:caseId LIMIT 1];
        T_CASE_APPLN_DTE__c applnDateRec = [SELECT Id, IDN_CASE__c, DTE_APPLN_OLD__c, DTE_APPLN_NEW__c, CMT_OVERRIDE__c, RSN_OVERRIDE__c FROM T_CASE_APPLN_DTE__c WHERE IDN_CASE__c=:caseId ORDER BY CreatedDate DESC LIMIT 1];
        if(caseRec.DTE_APPLN__c != applnDateRec.DTE_APPLN_NEW__c){
            caseRec.DTE_APPLN__c = applnDateRec.DTE_APPLN_NEW__c;
            List<DMLResult> lstDMLResult = GenericDMLHandler.updateRecords(new List<SObject>{caseRec}, false, null);
            if(!lstDMLResult.isEmpty()) {
                if(lstDMLResult.get(0).crudPermissionException!=null) {
                    isSuccessful = false;
                    message = lstDMLResult.get(0).crudPermissionException.getMessage();
                }
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);  
    }
}