/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           01/04/2018
*  @description    Apex Class for Eligibility Flow
*
*  Modification Log-
*  * Version: 1.0
*  * Date: 05-Apr-2018
*  * Author: Shubham Jain
*  * Description: Initial version
*********************************************************************************************/
public with sharing class AssessEligibilityFlowApxCtrl {
    public static String requestLabel;
    
    @AuraEnabled
    public static LightningServerResponse getDoInit(Id caseRecId) {
       Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        List<T_SBSD_CASE__c> caseRecord = [SELECT Id, CDE_COUNTY__c, CDE_COUNTY__r.Name,Is_CBMS_Data__c,CDE_CBMS_REF_TYP__c,IDN_CBMS_REF__c, DTE_APPLN__c, IDN_EXTNL__c FROM T_SBSD_CASE__c
                                               WHERE Id =: caseRecId];
      /*  if(caseRecord != null && caseRecord.size()>0){
            if((caseRecord[0].CDE_CBMS_REF_TYP__c =='New' || caseRecord[0].CDE_CBMS_REF_TYP__c =='Change' ) && String.isNotBlank(caseRecord[0].IDN_CBMS_REF__c) ){
                objectData.put('isOnlyTANFProgram',true);
            }else{
               objectData.put('isOnlyTANFProgram',false); 
            }
        }*/
	    objectData.put('isOnlyTANFProgram',false);
        if(!caseRecord.isEmpty()){
            objectData.put('caseRecord',caseRecord[0]);
        }
        objectData.put('loggedInUserId', CHATSAuraUtility.fetchLoggedInUserId());
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse validateCaseForEligibility(Id caseRecId, String programType) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        String eligibilityStatus;
        date runDate;
        String CONFIRMED = Label.CFM;

        try {
            String TRANSITIONAL_TANF = Label.FT;
            String TANF = 'TF';
            String LOW_INCOME_CHILD_CARE = 'LI';
            List<String> assessPageMessages = new List<String>();
            List<String> assessPageWarnings = new List<String>();
            List<String> assessProgramWarnings = new List<String>();
            List<T_SBSD_CASE_INDIV__c> adultsWithNoActivity = new List<T_SBSD_CASE_INDIV__c>();
            List<T_SBSD_CASE__c> caseRecord = [SELECT Id, CDE_COUNTY__c, CDE_COUNTY__r.Name,IDN_EXTNL__c,DTE_CHGD_LAST_DATA_ELIGTY__c,Program_Type__c,
                                               (SELECT Id FROM T_SBSD_CASE13__r WHERE CDE_TYPE_INFO_CASE__c='EM'),
                                               (SELECT Id FROM T_SBSD_CASE3__r WHERE CDE_TYPE_VERIF__c= Null AND DTE_BEGIN_EFFV__c <= TODAY
                                                AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>=TODAY) Order by DTE_BEGIN_EFFV__c DESC , createddate Desc NULLS FIRST),
                                               (SELECT Id, CDE_STATUS_CASE__c, CDE_MODE_CASE__c FROM T_SBSD_CASE10__r WHERE DTE_BEGIN_EFFV__c <= TODAY
                                                AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>=TODAY) Order by DTE_BEGIN_EFFV__c DESC , createddate Desc NULLS FIRST),
                                               (SELECT Id FROM T_SBSD_CASE7__r)
                                               FROM T_SBSD_CASE__c
                                               WHERE Id =: caseRecId];
            date last_conf_elig= caseRecord.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c;
            String caseProgram = caseRecord[0].Program_Type__c != null ? caseRecord[0].Program_Type__c : CaseHeaderApxCtrl.getChildCareProgram(caseRecord[0].Id);
            List<batchsit_t_eligty_run__x> eligRuns = [SELECT idn_run_eligty__c,dte_run_eligty__c FROM batchsit_t_eligty_run__x WHERE idn_case__c = :caseRecord.get(0).IDN_EXTNL__c AND cde_eligty_cfmd__c = :CONFIRMED ORDER BY idn_run_eligty__c DESC];
            
            if(!eligRuns.isEmpty()) {
                String idn_run_eligty = String.valueOf(eligRuns.get(0).idn_run_eligty__c);
        
            	runDate= eligRuns.get(0).dte_run_eligty__c;
                List<batchsit_t_fcompsn_eligty__x> caseEligibility = [SELECT idn_eligty_fcompsn__c, cde_prog__c FROM batchsit_t_fcompsn_eligty__x WHERE idn_run_eligty__c =: idn_run_eligty AND idn_eligty_fcompsn__c!=null];
                Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
                for(batchsit_t_fcompsn_eligty__x fcompsnEligty:caseEligibility) {
                    fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
                }
                List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = [SELECT idn_eligty_fcompsn__c,cde_status_eligty_family__c FROM batchsit_t_fcompsn_eligty_detail__x
                                                                                    WHERE idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet() 
                                                                                    ORDER BY idn_eligty_fcompsn__c  DESC, dte_begin_effv__c DESC LIMIT 1000];
                eligibilityStatus = caseEligibilityDetails.get(0).cde_status_eligty_family__c;
        
                if(!caseRecord[0].T_SBSD_CASE10__r.isEmpty()){
                    String  caseStatus = caseRecord[0].T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c;
                    String caseMode = caseRecord[0].T_SBSD_CASE10__r[0].CDE_MODE_CASE__c;    
                    // scenario 1 CCCAP-11849
                    if(caseStatus == 'PEN' && caseMode == 'INT' && eligibilityStatus == 'INE' && programType!=caseProgram && 
                       runDate==date.Today()){
                           assessPageMessages.add(System.Label.child_care_diff_programType_error);
                       }
                    // end scenario 1 CCCAP-11849
                    // scenario 2 CCCAP-11849

                    if(caseStatus == 'OPN' && caseMode == 'ONG' && eligibilityStatus=='ELI' && runDate==date.Today() &&
                       caseProgram!=programType){
                          assessPageMessages.add(System.Label.child_care_program_reassessment_error);
                       }
                    if(caseStatus == 'OPN' && caseMode == 'ONG' && eligibilityStatus=='INE' && runDate==date.Today() &&
                       caseProgram!=programType){

                           assessPageMessages.add(System.Label.child_care_diff_opn_ong_ine_error);
                       }
                    
                    // end scenario 2 CCCAP-11849
                }
            }
            // Case Asset
            List<T_SBSD_CASE_ASSET__c> caseAssetList =new List<T_SBSD_CASE_ASSET__c>();
            caseAssetList = [Select id,DTE_BEGIN_EFFV__c,Name from T_SBSD_CASE_ASSET__c where IDN_CASE__c =:caseRecId order by Name Desc limit 1];
            if(caseAssetList.size()>0 && caseAssetList[0].DTE_BEGIN_EFFV__c == null) {
                String errMsg = 'Case Asset '+caseAssetList[0].Name +' must have a begin date to access eligibility.';
                assessPageMessages.add(errMsg);
            }
             if(!caseRecord.get(0).T_SBSD_CASE3__r.isEmpty()) {
                //System.Label.Assess_Eligibility_Case_Info_Err
                assessPageMessages.add(System.Label.ErrMsg_If_Verified_of_Case_Address_is_Null);
            }
            // TANF Details
            List<T_CBMS_ADDNL_INFO__c> TANFDetailsList =new List<T_CBMS_ADDNL_INFO__c>();
            TANFDetailsList = [Select id,DTE_BEGIN_EFFEV__c,Name from T_CBMS_ADDNL_INFO__c where IDN_CASE_CHATS__c =:caseRecId order by Name Desc limit 1];
            if(TANFDetailsList.size()>0 && TANFDetailsList[0].DTE_BEGIN_EFFEV__c == null) {
                String errMsg = 'TANF Details '+TANFDetailsList[0].Name +' must have a begin date to access eligibility.';
                assessPageMessages.add(errMsg);
            }
            //CW Details
            List<T_CW_ADDNL_INFO__c> CWDetailsList =new List<T_CW_ADDNL_INFO__c>();
            CWDetailsList = [Select id,DTE_BEGIN_EFFEV__c,Name from T_CW_ADDNL_INFO__c where IDN_CASE_CHATS__c =:caseRecId order by Name Desc limit 1];
            if(CWDetailsList.size()>0 && CWDetailsList[0].DTE_BEGIN_EFFEV__c == null) {
                String errMsg = 'CW Details '+CWDetailsList[0].Name +' must have a begin date to access eligibility.';
                assessPageMessages.add(errMsg);
            }
            //Start of Change for CCCAP-129
            List<T_CBMS_ADDNL_INFO__c> activeTANFDetailsList =new List<T_CBMS_ADDNL_INFO__c>();
            activeTANFDetailsList = [Select id,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c, Name from T_CBMS_ADDNL_INFO__c where IDN_CASE_CHATS__c =:caseRecId and DTE_BEGIN_EFFEV__c <=TODAY and (DTE_END_EFFEV__c >TODAY or DTE_END_EFFEV__c = null)];
            if(activeTANFDetailsList.size() == 0 && programType == TANF) {
                String errMsg = 'A TANF Detail Record must be created for this case to assess eligibility.';
                assessPageMessages.add(errMsg);
            }
            if(programType == TRANSITIONAL_TANF || programType == LOW_INCOME_CHILD_CARE) {
                List<Id> adultIndividualsOnCase = new List<Id>();
                List<T_SBSD_CASE_INDIV__c> activeAdultCaseIndivLst = [SELECT Id, IDN_CLIENT__c, IND_CRTKR__c, IDN_CLIENT__r.Name, IDN_CLIENT__r.Age__c
                                                                      FROM T_SBSD_CASE_INDIV__c 
                                                                      WHERE IDN_CASE__c =: caseRecId 
                                                                      AND (IND_CRTKR__c = true OR IDN_CLIENT__r.Age__c >= 19)
                                                                      AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)];
                
                for(T_SBSD_CASE_INDIV__c eachCaseIndiv : activeAdultCaseIndivLst) {
                    List<T_PRIM_ACTV__c> activePrimaryActivityRecord = [SELECT Id, IDN_CASE__c,IDN_CLIENT__c, Name
                                                                        FROM T_PRIM_ACTV__c
                                                                        WHERE IDN_CASE__c =: caseRecId 
                                                                        AND IDN_CLIENT__c =: eachCaseIndiv.IDN_CLIENT__c
                                                                        AND ((DTE_BEGIN_ACTV_PRIM__c<=TODAY AND (DTE_END_ACTV_PRIM__c = null OR DTE_END_ACTV_PRIM__c>TODAY))OR DTE_BEGIN_ACTV_PRIM__c>TODAY )];
                    if(activePrimaryActivityRecord.size() == 0) {
                        adultsWithNoActivity.add(eachCaseIndiv);
                    }
                }
            }
            // End of change for CCCAP-129
            // Start change for CCCAP-848
            // Fixed duplicate error message issue for CCCAP-7609 by Rishav
            Set<String> empNumberSet = new Set<String>();
            Set<Id> ids = new Set<Id>();
            for(T_SBSD_CASE_INDIV__c listOfIndivId : [SELECT ID, IDN_CASE__c, IDN_CLIENT__c, IDN_CLIENT__R.NAME FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :caseRecId AND DTE_BEGIN_EFFV__c <= TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY)]){
                ids.add(listOfIndivId.IDN_CLIENT__c);
            }
            List<T_EMPLMT_INCOME__c> listOfEmpIncome = [SELECT Id, Name, IDN_EMPLMT_INDIV__r.Name, IND_STUBS_PAY_SUFFT__c, CNT_WEEK_PER_HOURS_ESTMD__c, IDN_EMPLMT_INDIV__c, 
                                                        AMT_INCOME_ANNUAL_ESTMD__c, CDE_FREQ_PAY_ESTMD__c, CDE_STATUS__c, (SELECT Id, Name FROM Employment_Pay_Stub__r) 
                                                        FROM T_EMPLMT_INCOME__c 
                                                        WHERE IDN_EMPLMT_INDIV__r.IDN_CLIENT__c IN :ids AND (IDN_EMPLMT_INDIV__r.DTE_END_EFFV__c = NULL OR IDN_EMPLMT_INDIV__r.DTE_END_EFFV__c > TODAY) AND CDE_STATUS__c = 'ACT' AND IND_STUBS_PAY_SUFFT__c='N'];
            for(T_EMPLMT_INCOME__c incomeRecord : listOfEmpIncome){
                if(incomeRecord.IND_STUBS_PAY_SUFFT__c == 'N' && (programType == TRANSITIONAL_TANF || programType == LOW_INCOME_CHILD_CARE) && (incomeRecord.AMT_INCOME_ANNUAL_ESTMD__c == 0 || incomeRecord.CDE_FREQ_PAY_ESTMD__c == null || incomeRecord.CNT_WEEK_PER_HOURS_ESTMD__c == 0)){
                    empNumberSet.add(incomeRecord.IDN_EMPLMT_INDIV__r.Name);
                    //String errMsg = 'Employment Record '+' '+incomeRecord.IDN_EMPLMT_INDIV__r.Name + ' '+System.label.Paystub_Error_Message1;//+' '+incomeRecord.IDN_EMPLMT_INDIV__r.Name+' '+System.label.Paystub_Error_Message2;
                    //assessPageMessages.add(errMsg);
                    //assessPageWarnings.add(errMsg);
                }
            }
            for(String empNumber : empNumberSet){ // Added for CCCAP-7609 by Rishav
                String errMsg = 'Employment Record ' + ' ' + empNumber + ' ' + System.label.Paystub_Error_Message1;
                assessPageWarnings.add(errMsg);
            }
            // End for CCCAP-848
            //[SJ 3/29: Warning 1: Checking if County in User's profile (User.Owner_County) is different from the CDE_COUNTY on the case (T_SBSD_CASE) record]        
            if(!CHATSUtility.checkCountyWithUserCounty(caseRecord.get(0).CDE_COUNTY__c)){
                //[SJ 3/21: Changed Error into Warning]
                //assessPageWarnings.add(System.Label.Assess_Eligibility_County_Err);
                assessPageMessages.add('The case record that you are trying to assess eligibility for belongs to '+caseRecord.get(0).CDE_COUNTY__r.Name+' county. This does not match your assigned county(ies).');
            }
            if(!adultsWithNoActivity.isEmpty()) {
                for(T_SBSD_CASE_INDIV__c eachIndividual :  adultsWithNoActivity){
                    assessPageWarnings.add('Individual '+eachIndividual.IDN_CLIENT__r.Name+' must have a Primary Activity record to assess eligibility.');    
                }
            }
            Schema.DescribeFieldResult fieldResult = Field_Utility__c.R00373__c.getDescribe();
            List<Schema.PicklistEntry> picklistLst = fieldResult.getPicklistValues();
            Map<String,String> valueLableMap = new Map<String,String>();
            for(Schema.PicklistEntry pickistSet: picklistLst) {
                valueLableMap.put(pickistSet.getValue(), pickistSet.getLabel());
            }
            String programLabel = valueLableMap.get(programType);
            if(caseProgram != null && programType != caseProgram) {
                assessProgramWarnings.add('Program type is being changed to '+programLabel+'. Would you like to continue?');                
            }
            //[SJ 3/29: Error 1: Checking if there is no case email T_SBSD_CASE_INFO record with CDE_TYPE_INFO_CASE = 'EM' related to the case]        
            /*if(caseRecord.get(0).T_SBSD_CASE13__r.isEmpty()) {
                //System.Label.Assess_Eligibility_Case_Info_Err
                assessPageMessages.add(System.Label.Assess_Eligibility_Case_Info_Err);    
            }*/
            //[SJ 3/29: Error 2: Checking if there is Related effective T_SBSD_CASE_STATUS_MODE (DTE_BEGIN_EFFV <= today, DTE_END_EFFV is NULL) has CDE_STATUS_CASE = 'CLS']        
            if(!caseRecord.get(0).T_SBSD_CASE10__r.isEmpty()) {
                if(caseRecord.get(0).T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c == 'CLS'){
                    assessPageMessages.add(System.Label.Assess_Eligibility_Case_Mode_Err);    
                }
                //[SJ 4/21: Error 2.1: Checking if there is Related effective T_SBSD_CASE_STATUS_MODE (DTE_BEGIN_EFFV <= today, DTE_END_EFFV is NULL) has CDE_STATUS_CASE = 'REO' & CDE_MODE_CASE__c = INT OR ONG]        
                if(caseRecord.get(0).T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c == 'REO' && caseRecord.get(0).T_SBSD_CASE10__r.get(0).CDE_MODE_CASE__c == 'INT'){
                   /* commenting it to Allow REO/ONG cases to undergo eligibility run for CCCAP-11857
                    * ( caseRecord.get(0).T_SBSD_CASE10__r.get(0).CDE_MODE_CASE__c == 'INT'||
                    caseRecord.get(0).T_SBSD_CASE10__r.get(0).CDE_MODE_CASE__c == 'ONG' )){ */
                        assessPageMessages.add(System.Label.CANNOT_ASSESS_ELIG_REO_INT_ONG_CASE);    
                    }
            }
            //[SJ 3/29: Error 3: Checking if No case homeless record exist]        
            if(caseRecord.get(0).T_SBSD_CASE7__r.isEmpty()) {
                assessPageMessages.add(System.Label.Assess_Eligibility_Case_HomeLess_Err);    
            }
            List<T_SBSD_CASE_INDIV__c> caseIndiv = [SELECT Id, IDN_CLIENT__c, IND_CRTKR__c
                                                    FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c =: caseRecId 
                                                    AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                                                   ];
            if(!caseIndiv.isEmpty()) {
                List<Id> indivIds = new List<Id>();
                Id primaryCaretakerId;
                for(T_SBSD_CASE_INDIV__c eachCaseIndiv : caseIndiv) {
                    //[SJ 3/21: Storing primary caretaker Id]
                    if(eachCaseIndiv.IND_CRTKR__c) {
                        primaryCaretakerId = eachCaseIndiv.IDN_CLIENT__c;
                    }
                    indivIds.add(eachCaseIndiv.IDN_CLIENT__c);
                }
                if(indivIds.size()>0) {
                    // Child Support Deduction
                    List<T_INDIV_DDTN__c> childSupportDeductionList =new List<T_INDIV_DDTN__c>();
                    childSupportDeductionList = [Select id,DTE_BEGIN_EFFV__c,Name from T_INDIV_DDTN__c where IDN_CLIENT__c IN:indivIds];
                    for(T_INDIV_DDTN__c childDed : childSupportDeductionList ){
                        if(childDed.DTE_BEGIN_EFFV__c == null){
                            String errMsg = 'Child Support Deduction '+childDed.Name +' must have a begin date to access eligibility.';
                            assessPageMessages.add(errMsg);
                        }  
                    }
                    
                    // Other Income
                    List<T_INDIV_OTHER_INCOME__c> otherIncomeList =new List<T_INDIV_OTHER_INCOME__c>();
                    otherIncomeList = [Select id,DTE_BEGIN_EFFV__c,Name from T_INDIV_OTHER_INCOME__c where IDN_CLIENT__c IN:indivIds];
                    for(T_INDIV_OTHER_INCOME__c otherInc : otherIncomeList ){
                        if(otherInc.DTE_BEGIN_EFFV__c == null){
                            String errMsg = 'Other Income '+otherInc.Name +' must have a begin date to access eligibility.';
                            assessPageMessages.add(errMsg);
                        }  
                    }
                    
                    //Employment Income
                    //Query on Employment based on Individual
                    Set<String> employmentIds = new Set<String>();
                    for(T_SBSD_INDIV_EMPLMT__c emp : [Select id from T_SBSD_INDIV_EMPLMT__c where IDN_CLIENT__c IN:indivIds and IDN_CASE__c=: caseRecord[0].Id]){
                        employmentIds.add(emp.id);
                    }
                    for(T_SBSD_EMPLMT_EXP__c empIncome :[Select id,DTE_BEGIN_EFFV__c,Name from T_SBSD_EMPLMT_EXP__c where IDN_EMPLMT_INDIV__c IN:employmentIds]){
                        IF(empIncome.DTE_BEGIN_EFFV__c == NULL){
                            String errMsg = 'Employment Expense '+empIncome.Name +' must have a begin date to access eligibility.';
                            assessPageMessages.add(errMsg);
                        }
                    }
                }
                if(indivIds.size()>0) {
                    Boolean noStateIdPresent = false, noIndivRelationshipPresent = false, noActivityForCaretaker = false, noCaretakerWithTEE = true, employmentWithNoIncomeOrVerif = false, selfEmploymentWithNoIncome = false, selfEmploymentWithNoIncomeVerif = false;
                    List<String> employmentWithNoIncomeErrorList = new List<String>(); // Added by Rishav for CCCAP-2558
                    List<String> selfEmploymentWithNoIncomeErrorList = new List<String>(); // Added by Rishav for CCCAP-2558
                    
                    Set<Id> indivRequestingCC = new Set<Id>();
                    Set<Id> indivWithVerifiedInfo = new Set<Id>();
                    Set<String> careTakerRelationships = new Set<String>{'F', 'M', 'CLH', 'CLW', 'W', 'H', 'LIC'};
                    
                    for(T_INDIV_CAT_RQ__c childCareRequest:[SELECT IDN_CASE_INDIV__r.IDN_CLIENT__c FROM T_INDIV_CAT_RQ__c WHERE IDN_CASE_INDIV__r.IDN_CLIENT__c IN: indivIds AND ((DTE_BEGIN_EFFV__c<=Today and OVERRIDDEN_DTE_BEGIN_EFFV__c=null) or OVERRIDDEN_DTE_BEGIN_EFFV__c <=Today) AND (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY)]) {
                        if(String.isNotEmpty(childCareRequest.IDN_CASE_INDIV__c)) {
                            indivRequestingCC.add(childCareRequest.IDN_CASE_INDIV__r.IDN_CLIENT__c);    
                        }
                    }
                    for(T_INDIV_VERIF__c indivVerif:[SELECT IDN_CLIENT__r.IDN_CLIENT__c FROM T_INDIV_VERIF__c WHERE IDN_CLIENT__r.IDN_CLIENT__c IN: indivIds AND CDE_TYPE_INFO_INDIV__c='CS']) {
                        if(String.isNotEmpty(indivVerif.IDN_CLIENT__c)) {
                            indivWithVerifiedInfo.add(indivVerif.IDN_CLIENT__r.IDN_CLIENT__c);
                        }
                    }
                    //[SJ 3/29: Error 4: Checking If there is an employment record (T_SBSD_INDIV_EMPLMT with record type employment), but no related employment income (T_EMPLMT_INCOME)]
                    //[SJ 3/29: Error 5: Checking If there is an employment record (T_SBSD_INDIV_EMPLMT with record type employment), but no related employment verification (T_INDIV_EMPLMT_VERIF)]
                    //[SJ 3/29: Error 6: Checking If there is a self-employment record (T_SBSD_INDIV_EMPLMT with record type unemployment), but no related self-employment income (T_EMPLMT_INCOME)]
                    
                    for(T_SBSD_INDIV_EMPLMT__c employment:[SELECT Id, RecordType.DeveloperName, IDN_CLIENT__c, Name, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c,
                                                           (SELECT Id, CDE_TYPE_VERIF__c, CDE_SOURCE_VRFYD_PAY__c, CDE_STATUS__c FROM T_SBSD_INDIV_EMPLMT1__r),
                                                           (SELECT Id FROM Employment_Verifications__r)
                                                           FROM T_SBSD_INDIV_EMPLMT__c WHERE IDN_CLIENT__c IN:indivIds and IDN_CASE__c=: caseRecord[0].Id and (DTE_END_EFFV__c>=Today or DTE_END_EFFV__c=null) and DTE_BEGIN_EFFV__c<=Today]) {
                                                               if(employment.RecordType.DeveloperName=='Employment' && (employment.T_SBSD_INDIV_EMPLMT1__r.isEmpty() || employment.Employment_Verifications__r.isEmpty())) {
                                                                   employmentWithNoIncomeOrVerif=true;
                                                                   // Start: Added by Rishav for CCCAP-2558
                                                                   String empErrorMessage = CHATSUtility.mergeText(employment, System.Label.Assess_Eligibility_Employment_Err);
                                                                   employmentWithNoIncomeErrorList.add(empErrorMessage);
                                                                   // End: CCCAP-2558
                                                               }
                                                               // Start: Added by Rishav for CCCAP-2558 & CCCAP-2943 & CCCAP-3111
                                                               /* if(employment.RecordType.DeveloperName=='Self_Employment' && employment.T_SBSD_INDIV_EMPLMT1__r.isEmpty()) {
                                                                   selfEmploymentWithNoIncome=true;
                                                               } */
                                                               if(employment.RecordType.DeveloperName == 'Self_Employment') {
                                                                   if(employment.T_SBSD_INDIV_EMPLMT1__r.isEmpty()) {
                                                                       selfEmploymentWithNoIncome = true;
                                                                       String selfEmpErrorMessage = CHATSUtility.mergeText(employment, System.Label.Assess_Eligibility_Self_Employment_Err);
                                                                       selfEmploymentWithNoIncomeErrorList.add(selfEmpErrorMessage);
                                                                   } else {
                                                                       for(T_EMPLMT_INCOME__c income : employment.T_SBSD_INDIV_EMPLMT1__r) {
                                                                           if(income.CDE_STATUS__c == 'ACT'){
                                                                               if(String.isBlank(income.CDE_TYPE_VERIF__c)){ // Error if 'Verified' is blank
                                                                                   selfEmploymentWithNoIncomeVerif = true;
                                                                               } else if(income.CDE_TYPE_VERIF__c == 'V' && String.isBlank(income.CDE_SOURCE_VRFYD_PAY__c)){ // Error if 'Written Verification' but 'How Verified' is blank
                                                                                   selfEmploymentWithNoIncomeVerif = true;
                                                                               }
                                                                           }
                                                                       }
                                                                       if(selfEmploymentWithNoIncomeVerif){
                                                                           String selfEmpErrorMessage = CHATSUtility.mergeText(employment, System.Label.Assess_Eligibility_Self_Employment_Err);
                                                                           selfEmploymentWithNoIncomeErrorList.add(selfEmpErrorMessage);
                                                                       }
                                                                   }
                                                               }
                                                               // End: CCCAP-2558 & CCCAP-2943 & CCCAP-3111
                                                           }
                    List<T_SBSD_INDIV__c> individuals = [SELECT Id, IDN_STATE__c, Name, Age__c,
                                                         (SELECT Id FROM Case_Individual__r WHERE IND_CRTKR__c=true AND IDN_CASE__c=:caseRecId),
                                                         (SELECT Id, CDE_TYPE_REL_INDIV__c FROM Relationship__r WHERE IDN_CLIENT__c = :primaryCaretakerId),
                                                         (SELECT Id, Effective_Begin_Date__c,Effective_End_Date__c FROM Individual_E_mails__r WHERE Effective_Begin_Date__c<=TODAY AND (Effective_End_Date__c=null OR Effective_End_Date__c>=TODAY)),
                                                         (SELECT Id FROM T_SBSD_INDIV22__r WHERE IDN_CASE__c=:caseRecId AND (DTE_BEGIN_ACTV_PRIM__c<=TODAY AND (DTE_END_ACTV_PRIM__c>TODAY OR DTE_END_ACTV_PRIM__c=null))),
                                                         (SELECT Id FROM T_SBSD_INDIV12__r where CDE_TYPE_TRAIN__c = 'JST' AND (DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c>TODAY OR DTE_END_EFFV__c=null))),
                                                         (SELECT Id FROM T_SBSD_INDIV7__r where CDE_TYPE_SCHOOL__c = 'JST' AND (DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c>TODAY OR DTE_END_EFFV__c=null))),
                                                         (SELECT Id FROM T_SBSD_INDIV19__r WHERE DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c>TODAY OR DTE_END_EFFV__c=null))
                                                         FROM T_SBSD_INDIV__c WHERE Id IN :indivIds];
                    Boolean isCaretaker;
                    for(T_SBSD_INDIV__c individual:individuals) {
                        //[SJ 3/29: Error 7: Checking if an individual on the case does not have a State ID populated]
                        if(String.isEmpty(individual.IDN_STATE__c) || individual.IDN_STATE__c==System.Label.SIDMOD_STATE_ID_REQUIRED) {
                            noStateIdPresent = true;
                        }
                        
                        //[SJ 3/29: Error 8: Checking if an individual (who is not the primary caretaker) on the case does not have a relationship (T_INDIV_REL) defined with the Primary Caretaker on the case]
                        if(individual.Id!=primaryCaretakerId && individual.Relationship__r.isEmpty()) {
                            noIndivRelationshipPresent = true;
                        }
                        
                        //[SJ 3/30: Error 9: Checking if the individual is requesting care (T_INDIV_CAT_RQ where today is on or between T_INDIV_CAT_RQ.DTE_BEGIN_EFFV and T_INDIV_CAT_RQ.DTE_END_EFFV) and there is no related citizenship record (T_INDIV_VERIF.CDE_TYPE_VERIF where CDE_TYPE_INFO_INDIV  = 'CS' does not exist)]
                        if(indivRequestingCC.contains(individual.Id) && !indivWithVerifiedInfo.contains(individual.Id)) {
                            assessPageMessages.add(individual.Name +' ' +System.Label.Assess_Eligibility_Indiv_CCR_Without_Verif);
                        }
                         if(!individual.Case_Individual__r.isEmpty() && individual.Individual_E_mails__r.isEmpty()) {
                            //System.Label.Assess_Eligibility_Individual_Email_Err
                            assessPageMessages.add(System.Label.Individual_Email_Error);    
                        }
                        
                        isCaretaker = individual.Age__c>18 || !individual.Case_Individual__r.isEmpty() || (!individual.Relationship__r.isEmpty() && careTakerRelationships.contains(individual.Relationship__r.get(0).CDE_TYPE_REL_INDIV__c));
                        //[SJ 4/3: Warning 2: Checking if a caretaker on the case doesn't have a primary activity for the case (Warning message: ""Not every caretaker on the case has a primary activity."")]
                        if(isCaretaker && individual.T_SBSD_INDIV22__r.isEmpty()) {
                            noActivityForCaretaker = true;
                        }
                        
                        //[SJ 4/3: Warning 3: Checking if user selects Program 'Transitional TANF' and no caretaker on the case has a current (DTE_END_EFFV < run date or DTE_BEGIN_EFFV > run date) T_INDIV_TRAIN activity where CDE_TYPE_TRAIN = 'JST' OR a current T_INDIV_EDUC activity where CDE_TYPE_SCHOOL = 'JST' OR a current T_SBSD_INDIV_EMPLMT activity]
                        if(programType==TRANSITIONAL_TANF && isCaretaker && (!individual.T_SBSD_INDIV12__r.isEmpty() || !individual.T_SBSD_INDIV7__r.isEmpty() || !individual.T_SBSD_INDIV19__r.isEmpty())) {
                            noCaretakerWithTEE = false;
                        }
                    }
                    
                    //[SJ 4/3: Individual related Errors & Warnings]
                    if(noStateIdPresent) {
                        assessPageMessages.add(System.Label.Assess_Eligibility_State_ID_Err);    
                    }
                    if(noIndivRelationshipPresent) {
                        assessPageMessages.add(System.Label.Assess_Eligibility_Indiv_Rel_Err);    
                    }
                    /*
                    if(noActivityForCaretaker){
                        assessPageWarnings.add(System.Label.Assess_Eligibility_Caretaker_Without_Primary_Activity);
                    }
					*/
                    if(programType==TRANSITIONAL_TANF && noCaretakerWithTEE) {
                        assessPageWarnings.add(System.Label.Assess_Eligibility_CRTKR_OTHR);
                    }
                    if(employmentWithNoIncomeOrVerif) {
                        // Start: Added by Rishav for CCCAP-2558
                        // assessPageMessages.add(System.Label.Assess_Eligibility_Employment_Err);
                        assessPageMessages.addAll(employmentWithNoIncomeErrorList);
                        // End: CCCAP-2558
                    }
                    if(selfEmploymentWithNoIncome || selfEmploymentWithNoIncomeVerif) {
                        // Start: Added by Rishav for CCCAP-2558
                        //assessPageMessages.add(System.Label.Assess_Eligibility_Self_Employment_Err);
                        assessPageMessages.addAll(selfEmploymentWithNoIncomeErrorList);
                        // End: CCCAP-2558 
                    }
                }
            }
            objectData.put('caseProgram', caseProgram); 
            objectData.put('assessProgramWarnings', assessProgramWarnings);
            objectData.put('assessPageMessages', assessPageMessages);
            objectData.put('assessPageWarnings', assessPageWarnings);
        } catch(Exception ex) {
            isSuccessful = false;
            message = ex.getMessage();
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','AssessEligibilityFlowApxCtrl');    
            exceptionMap.put('Method__c','validateCaseForEligibility');            
            ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    // Called From ContinuationController
    public static Object doCallAssessEligibilityContinuation(Continuation con, String caseId, String programName) {
        String CONFIRMED = Label.CFM;
        String caseMode, caseStatus;
        String eligibilityStatus;
        List<T_SBSD_CASE__c> cases = [SELECT Name,IDN_EXTNL__c,DTE_CHGD_LAST_DATA_ELIGTY__c,
                                      (SELECT Id, CDE_MODE_CASE__c, CDE_STATUS_CASE__c,CDE_ELIGTY_CONTNUS__c
                                      FROM T_SBSD_CASE10__r 
                                      WHERE DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY)) 
                                      FROM T_SBSD_CASE__c WHERE Id = :caseId];
        date last_conf_elig= cases.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c;
        if(!cases.get(0).T_SBSD_CASE10__r.isEmpty()) {
            caseMode = cases.get(0).T_SBSD_CASE10__r.get(0).CDE_MODE_CASE__c;
            caseStatus = cases.get(0).T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c;
        }
        String oldProgram=null;
        Date runDate;
        List<batchsit_t_eligty_run__x> eligRuns = [SELECT idn_run_eligty__c,dte_run_eligty__c FROM batchsit_t_eligty_run__x WHERE idn_case__c = :cases.get(0).IDN_EXTNL__c AND cde_eligty_cfmd__c = :CONFIRMED ORDER BY idn_run_eligty__c DESC];
        if(!eligRuns.isEmpty()) {
            String idn_run_eligty = String.valueOf(eligRuns.get(0).idn_run_eligty__c);
            runDate= eligRuns.get(0).dte_run_eligty__c;
            List<batchsit_t_fcompsn_eligty__x> caseEligibility = [SELECT idn_eligty_fcompsn__c, cde_prog__c FROM batchsit_t_fcompsn_eligty__x WHERE idn_run_eligty__c =: idn_run_eligty AND idn_eligty_fcompsn__c!=null];
            Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
            for(batchsit_t_fcompsn_eligty__x fcompsnEligty:caseEligibility) {
                fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
            }
            List<batchsit_t_fcompsn_eligty_detail__x> caseEligibilityDetails = [SELECT idn_eligty_fcompsn__c,cde_status_eligty_family__c FROM batchsit_t_fcompsn_eligty_detail__x
                                                                                 WHERE idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet() 
                                                                                 ORDER BY idn_eligty_fcompsn__c  DESC, dte_begin_effv__c DESC LIMIT 1000];
            if(!caseEligibilityDetails.isEmpty()) {
                String idnEligtyFcompsnLatest = caseEligibilityDetails.get(0).idn_eligty_fcompsn__c;
                eligibilityStatus = caseEligibilityDetails.get(0).cde_status_eligty_family__c;
                if(fcompsnEligtyIdToRecord.containsKey(idnEligtyFcompsnLatest)) {
                    oldProgram = fcompsnEligtyIdToRecord.get(idnEligtyFcompsnLatest).cde_prog__c;
                }
            } else {
                oldProgram = caseEligibility.get(0).cde_prog__c;
            }            
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setEndpoint(System.Label.BRECreate);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        Boolean programChange;
        if(!cases.get(0).T_SBSD_CASE10__r.isEmpty()) {
            //modified the existing If-Else block to handle additional scenarios for CCCAP-11849
            if(caseStatus == 'PEN' && caseMode == 'INT' && cases.get(0).T_SBSD_CASE10__r[0].CDE_ELIGTY_CONTNUS__c == 'N' ){
                programChange=false;
            }else if(caseStatus == 'PEN' && caseMode == 'INT' && eligibilityStatus =='INE' && runDate<date.Today() &&  
                     programName!=oldProgram && oldProgram!=null)
            {
                programChange= false;
            }else {
                programChange = oldProgram==null || programName==oldProgram?false:true;
            }
        }
        String syncDataJSON;
        try {
            DateTime startTime = System.now();
            syncDataJSON = SyncDataJSONCreator.SyncDataJSONForm(caseId);
            DateTime endTime = System.now();
            Long timeTaken = endTime.getTime() - startTime.getTime(); 
        } catch(Exception ex) {
            Map<String,Object> methodInfo = new Map<String,Object>();
            methodInfo.put('Class__c','AssessEligibilityFlowApxCtrl');            
            methodInfo.put('Method__c','doCallBackAssessEligibilityContinuation');            
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
        }
        String body = '{"CaseID":'+cases.get(0).Name+//Name of the case(Int-32): CHATS-3525
            ',"CaseMode":"'+caseMode+//from latest case status mode record: CHATS-3525
            '","CaseStatus":"'+caseStatus+//from latest case status mode record: CHATS-3525
            '","ConfirmEligibilityCode":"INP",'+//It should always be INP: CHATS-3525
            '"ProgramChange":"'+programChange+'",'+//It is stored in cde_prog__c of batchsit1$t_fcompsn_eligty, so need to do a query on the last confirmed elig run record.: CHATS-3525
            '"ProgramName":"'+programName+'",'+//whatever user selected on the screen
            '"UserLastUpdated":"'+UserInfo.getUserId();//Salesforce Id of current user
        if(String.isNotEmpty(syncDataJSON)) {
            body = body +'","SyncData":'+syncDataJSON;//SyncData required for Assessing Eligibility
        }
        body = body + '}';
        req.setBody(body);
        System.debug('[AssessEligibilityFlowApxCtrl.doCallAssessEligibilityContinuation]--Body-->'+body);
        // Adding req for continuation callBacks.
        con.state = con.addHttpRequest(req);
        con.continuationMethod = 'callbackForBRECreate';        
        // Return it to the system for processing
        return con;
    }   
    
    // BRECreate Callback for ContinuationController 
    public static Object doCallBackAssessEligibilityContinuation(Object state){
        Map<String, Object> objectData = new map<String, Object>();
        String CONFIRMED = 'CFM';
        Boolean isSuccessful=true;
        String message='';
        try {
            //HttpResponse response = Continuation.getResponse((String)state);
            HttpResponse response = Continuation.getResponse((String)state);
            System.debug('[AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation]--response-->'+response);
            Integer statusCode = response.getStatusCode();
            if(statusCode >= 2000) {
                isSuccessful = false;
                message = 'Continuation error: ' + statusCode;
                Map<String,Object> methodInfo = new Map<String,Object>();
                methodInfo.put('Class__c','AssessEligibilityFlowApxCtrl');    
                methodInfo.put('Method__c','doCallBackAssessEligibilityContinuation');            
                ExceptionLoggingServices.captureExceptionLog(response, null, methodInfo);
            } else if(response.getStatusCode() != 200) {
                System.debug('[AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation]--Status error-->' + response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                isSuccessful = false;
                String error = 'An error occurred while calling BRE: ';
                error+=response.getStatus()!=null?String.valueOf(response.getStatus())+',':'';
                String errorBody = response.getBody();
                String actualError = errorBody.substringBetween('The exception message is', 'See server logs for more details');
                if(String.isNotEmpty(actualError)){
                    error += actualError;
                    error = error.replaceAll('\'', '');
                } else {
                    error+= errorBody;
                }
                message = error;
                Map<String,Object> methodInfo = new Map<String,Object>();
                methodInfo.put('Class__c','AssessEligibilityFlowApxCtrl');            
                methodInfo.put('Method__c','doCallBackAssessEligibilityContinuation');            
                ExceptionLoggingServices.captureExceptionLog(response, null, methodInfo);
            } else {
                System.debug('[AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation]--response.getBody-->'+response.getBody());
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('[AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation]--data-->'+data);
                List<Object> errorValues = (List<Object>)data.get('ErrorValue');
                if(errorValues!=null && !errorValues.isEmpty()){
                    System.debug('[AssessEligibilityFlowApxCtrl.doCallBackAssessEligibilityContinuation]--errorValues-->'+errorValues);
                    for(Object ob:errorValues) {
                        message+=String.valueOf(ob);
                    }
                    isSuccessful = false;
                    Map<String,Object> methodInfo = new Map<String,Object>();
                    methodInfo.put('Class__c','AssessEligibilityFlowApxCtrl');            
                    methodInfo.put('Method__c','doCallBackAssessEligibilityContinuation');            
                    ExceptionLoggingServices.captureExceptionLog(response, null, methodInfo);
                } else {
                    String ruId = String.valueOf(data.get('RunID'));
                    if(String.isNotEmpty(ruId)){
                        List<batchsit_t_eligty_run__x> eligRunRecords = [SELECT Id, idn_case__c, idn_run_eligty__c, idn_case__r.Id, idn_case__r.IND_CHGD_DATA_ELIGTY__c
                                                                          FROM batchsit_t_eligty_run__x WHERE idn_run_eligty__c = :integer.valueof(ruId)];
                        if(!eligRunRecords.isEmpty()) {
                            objectData.put('eligRunSFID',eligRunRecords.get(0).Id);
                            if(String.isNotEmpty(eligRunRecords.get(0).idn_case__c) && eligRunRecords.get(0).idn_case__r.IND_CHGD_DATA_ELIGTY__c && Schema.SObjectType.T_SBSD_CASE__c.isUpdateable()){
                                T_SBSD_CASE__c caseRecToBeUpdated = new T_SBSD_CASE__c();
                                caseRecToBeUpdated.Id = eligRunRecords.get(0).idn_case__r.Id;
                                caseRecToBeUpdated.IND_CHGD_DATA_ELIGTY__c = false;
                                List<DMLResult> lstDMLResult = GenericDMLHandler.updateRecords(new List<SObject>{caseRecToBeUpdated}, false, null);
                                if(!lstDMLResult.isEmpty()) {
                                    if(lstDMLResult.get(0).crudPermissionException!=null) {
                                        isSuccessful = false;
                                        message = lstDMLResult.get(0).crudPermissionException.getMessage();
                                    } else {
                                        objectData.put('updateSaveResult',lstDMLResult.get(0).saveResult);    
                                    }
                                }
                            }
                        } else {
                            isSuccessful = false;
                            message = 'There exists no record in DB corresponding to external id:'+ruId;
                        }                    
                    }
                }
            }
        } catch(Exception ex) {
            isSuccessful = false;
            message=ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AssessEligibilityFlowApxCtrl','Method__c'=>'doCallBackAssessEligibilityContinuation'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse insertApplnDateInfoRec(T_CASE_APPLN_DTE__c applnDateRec, T_SBSD_CASE__c caseRec){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;        
        try{
            applnDateRec.IDN_CASE__c = caseRec.Id;
            List<DMLResult> lstDMLResult = GenericDMLHandler.insertRecords(new List<SObject>{applnDateRec}, false, new Map<String,Object>{'Method__c'=>'insertApplnDateInfoRec','Class__c'=>'AssessEligibilityFlowApxCtrl'}, new List<String>{'IDN_CASE__c','DTE_APPLN_OLD__c','DTE_APPLN_NEW__c','RSN_OVERRIDE__c','CMT_OVERRIDE__c','Reopened_or_Elig__c'});
            List<Database.SaveResult> lstSaveResult = GenericDMLHandler.getSaveResultsFromDMLResults(lstDMLResult);
            List<CRUDPermissionException> lstCrudPermissionException = GenericDMLHandler.getCRUDPermissionExceptionsFromDMLResults(lstDMLResult);
            
            Set<String> lstErrors = new Set<String>();
            if(!lstCrudPermissionException.isEmpty()){
                for(CRUDPermissionException crudPermissionException:lstCrudPermissionException){
                    lstErrors.add(JSON.serialize(new List<Object>{new Map<String,String>{'message'=>crudPermissionException.getMessage()}}));
                }
            }else{
                for(Database.SaveResult saveResult:lstSaveResult){
                    if(!saveResult.getErrors().isEmpty()){
                        lstErrors.add(JSON.serialize(saveResult.getErrors()));
                    }
                }
            }

            if(!lstErrors.isEmpty()){
                isSuccessful = false;
                objectData.put('lstErrors', lstErrors);
            }else{
                isSuccessful = true;
            }
        }
        catch(Exception ex){
            isSuccessful = false;
            message = ex.getMessage();
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','AssessEligibilityFlowApxCtrl');    
            exceptionMap.put('Method__c','insertApplnDateInfoRec');            
            ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
	}
}