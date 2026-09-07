/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           01/06/2018                                                          
*  @description    Apex Class for Eligibility - Individual Flow
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 06-Jan-2018                                                            
*  * Author: Gaurav Dharra                                                      
*  * Description: Initial version                                                 
*********************************************************************************************/
public with sharing class IndividualFlowCtrl {
    public static final String EMPTY_STRING = null;
    @TestVisible
    private static Map<String,Object> queryData(String idnIndivFcompsn){
        Map<String,Object> data = new Map<String,Object>();
        if(Test.isRunningTest()){
            data.put('indivEligs', new List<SObject>{new batchsit_t_fcompsn_indiv_eligty__x(idn_eligty_fcompsn__c='123')});
            data.put('householdEligibilities', new List<SObject>{new batchsit_t_fcompsn_eligty__x(idn_eligty_fcompsn__c=123)});
            data.put('idnRunEligtyId','1');
        }else{
            List<batchsit_t_fcompsn_indiv_eligty__x> indivEligs = [SELECT Id, 
                                                                   cde_reason_ovrd__c, 
                                                                   txt_cmt_ovrd__c,
                                                                   idn_case_indiv__c,
                                                                   idn_case_indiv__r.IDN_CLIENT__c,
                                                                   idn_case_indiv__r.DTE_BEGIN_EFFV__c,
                                                                   idn_case_indiv__r.IDN_CLIENT__r.NAM_LAST__c,
                                                                   idn_case_indiv__r.IDN_CLIENT__r.NAM_FIRST__c,
                                                                   idn_indiv_fcompsn__c,
                                                                   idn_eligty_fcompsn__c,
                                                                   idn_eligty_fcompsn__r.idn_run_eligty__c
                                                                   FROM batchsit_t_fcompsn_indiv_eligty__x
                                                                   WHERE idn_indiv_fcompsn__c =: Decimal.valueOf(idnIndivFcompsn) AND
                                                                   idn_case_indiv__c!=null];
            data.put('indivEligs',indivEligs);
            List<batchsit_t_fcompsn_eligty__x> unfiltertedHouseholdEligibilities = [SELECT idn_run_eligty__r.Id, idn_eligty_fcompsn__c, idn_run_eligty__r.cde_eligty_cfmd__c, idn_run_eligty__r.dte_run_eligty__c, cde_reason_change_fcompsn__c FROM batchsit_t_fcompsn_eligty__x WHERE idn_run_eligty__c = :indivEligs.get(0).idn_eligty_fcompsn__r.idn_run_eligty__c ];
            System.debug('unfiltertedHouseholdEligibilities:'+unfiltertedHouseholdEligibilities);
            List<batchsit_t_fcompsn_eligty__x> householdEligibilities = new List<batchsit_t_fcompsn_eligty__x>();
            for(batchsit_t_fcompsn_eligty__x fcompsnEligty:unfiltertedHouseholdEligibilities){
                if(fcompsnEligty.idn_run_eligty__r.dte_run_eligty__c<=Date.newInstance(2018,8,31) || fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
                    householdEligibilities.add(fcompsnEligty);
                }
            }
            data.put('householdEligibilities',householdEligibilities);
        }
        return data;
    }
    
    @TestVisible
    private static List<batchsit_t_fcompsn_indiv_eligty__x> queryFcompsnIndivEligties(Map<String, batchsit_t_fcompsn_eligty__x> idnEligtyFcompsnToRecord, List<batchsit_t_fcompsn_indiv_eligty__x> indivEligs){
        if(Test.isRunningTest()){
            return new List<SObject>{new batchsit_t_fcompsn_indiv_eligty__x(idn_indiv_fcompsn__c=1234), new batchsit_t_fcompsn_indiv_eligty__x(idn_indiv_fcompsn__c=1235)};
                }else{
                    return [SELECT Id, cde_reason_ovrd__c, 
                            txt_cmt_ovrd__c,
                            idn_case_indiv__c,
                            idn_case_indiv__r.IDN_CLIENT__c,
                            idn_case_indiv__r.DTE_BEGIN_EFFV__c,
                            idn_indiv_fcompsn__c,
                            idn_eligty_fcompsn__c,
                            idn_eligty_fcompsn__r.idn_run_eligty__c
                            FROM batchsit_t_fcompsn_indiv_eligty__x
                            WHERE idn_eligty_fcompsn__c IN : idnEligtyFcompsnToRecord.keySet() AND idn_case_indiv__c=:indivEligs.get(0).idn_case_indiv__c];            
                }
    }

    @TestVisible
    private static List<batchsit_t_indiv_eligty_detail__x> queryIndivEligtyDetails(Map<String, batchsit_t_fcompsn_indiv_eligty__x> idnIndivFcompsnToRecord){
        if(Test.isRunningTest()){
                return new List<SObject>{new batchsit_t_indiv_eligty_detail__x(idn_indiv_fcompsn__c='1234', dte_begin_effv__c = System.today()),
                    new batchsit_t_indiv_eligty_detail__x(idn_indiv_fcompsn__c='1235', dte_begin_effv__c = System.today().addDays(-7), dte_end_effv__c = System.today().addDays(-5))
                    };
                }else{
                    return [SELECT Id, cde_status_detail_eligty_indiv__c, dte_end_effv__c, dte_begin_effv__c, idn_eligty_fcompsn__c, idn_indiv_fcompsn__c
                                                                                FROM batchsit_t_indiv_eligty_detail__x
                                                                                WHERE idn_indiv_fcompsn__c IN :idnIndivFcompsnToRecord.keySet() ORDER BY dte_begin_effv__c DESC];            
                }
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String idnIndivFcompsn) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try{
            if(String.isNotEmpty(idnIndivFcompsn)) {
                IndividualEligibilityWrapper indivEligWrapper = new IndividualEligibilityWrapper();
                Map<String,Object> data = queryData(idnIndivFcompsn);
                List<batchsit_t_fcompsn_indiv_eligty__x> indivEligs = (List<batchsit_t_fcompsn_indiv_eligty__x>)data.get('indivEligs');
                if(!indivEligs.isEmpty() && String.isNotEmpty(indivEligs.get(0).idn_eligty_fcompsn__c) ){
                    String idnRunEligtyId = String.isNotEmpty(indivEligs.get(0).idn_eligty_fcompsn__c)?indivEligs.get(0).idn_eligty_fcompsn__r.idn_run_eligty__c:EMPTY_STRING;
                    String clientId = String.isNotEmpty(indivEligs.get(0).idn_case_indiv__c)?indivEligs.get(0).idn_case_indiv__r.IDN_CLIENT__c:EMPTY_STRING;
                    if(Test.isRunningTest()){
                        idnRunEligtyId = (String)data.get('idnRunEligtyId');
                        clientId = [SELECT Id FROM T_SBSD_INDIV__c WITH SECURITY_ENFORCED limit 10][0].Id;
                    }
                    if(String.isNotEmpty(idnRunEligtyId) && String.isNotEmpty(clientId)){
                        List<batchsit_t_fcompsn_eligty__x> householdEligibilities = (List<batchsit_t_fcompsn_eligty__x>)data.get('householdEligibilities');
                        String eligibilityRunSFId = String.isNotEmpty(householdEligibilities.get(0).idn_run_eligty__c)?householdEligibilities.get(0).idn_run_eligty__r.Id:EMPTY_STRING;
                        String eligibilityRunStatus = String.isNotEmpty(householdEligibilities.get(0).idn_run_eligty__c)?householdEligibilities.get(0).idn_run_eligty__r.cde_eligty_cfmd__c:EMPTY_STRING;
                        objectData.put('eligibilityRunSFId',eligibilityRunSFId);
                        objectData.put('eligibilityRunStatus',eligibilityRunStatus);
                        Set<String> careTakerRelationships = new Set<String>{'F', 'M', 'CLH', 'CLW', 'W', 'H', 'LIC'};
                            List<T_SBSD_INDIV__c> individuals = [SELECT Id, NAM_FIRST__c, NAM_LAST__c, Age__c, IDN_STATE__c, (SELECT Id FROM Relationship__r WHERE CDE_TYPE_REL_INDIV__c IN:careTakerRelationships), (SELECT Id FROM Case_Individual__r WHERE IND_CRTKR__c=true) FROM T_SBSD_INDIV__c WHERE Id = :clientId WITH SECURITY_ENFORCED];
                        if(!individuals.isEmpty()){
                            if(!individuals.get(0).Case_Individual__r.isEmpty() || individuals.get(0).Age__c>18 || !individuals.get(0).Relationship__r.isEmpty()){
                                indivEligWrapper.isParentCaretaker = true;
                            }
                            indivEligWrapper.firstName = individuals.get(0).NAM_FIRST__c;
                            indivEligWrapper.lastName = individuals.get(0).NAM_LAST__c;
                        }
                        indivEligWrapper.individualEnteredHouseholdDate = indivEligs.get(0).idn_case_indiv__r.DTE_BEGIN_EFFV__c;
                        Map<String, batchsit_t_fcompsn_eligty__x> idnEligtyFcompsnToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
                        for(batchsit_t_fcompsn_eligty__x householdEligibility:householdEligibilities){
                            idnEligtyFcompsnToRecord.put(String.valueOf(householdEligibility.idn_eligty_fcompsn__c), householdEligibility);
                        }
                        Map<String, batchsit_t_fcompsn_indiv_eligty__x> idnIndivFcompsnToRecord = new Map<String, batchsit_t_fcompsn_indiv_eligty__x>();
                        for(batchsit_t_fcompsn_indiv_eligty__x indivEligty:queryFcompsnIndivEligties(idnEligtyFcompsnToRecord, indivEligs)){
                            idnIndivFcompsnToRecord.put(String.valueOf(indivEligty.idn_indiv_fcompsn__c),indivEligty);                           
                        }
                        List<batchsit_t_indiv_eligty_detail__x> indivDetails = queryIndivEligtyDetails(idnIndivFcompsnToRecord);
                        if(!indivDetails.isEmpty()) {
                            indivEligWrapper.indivEligDetail = indivDetails.get(0);   
                            indivEligWrapper.idnIndivFcompsn = indivDetails.get(0).idn_indiv_fcompsn__c;
                            if(idnIndivFcompsnToRecord.containsKey(indivDetails.get(0).idn_indiv_fcompsn__c)){
                                indivEligWrapper.indivElig = idnIndivFcompsnToRecord.get(indivDetails.get(0).idn_indiv_fcompsn__c);
                                indivEligWrapper.idnEligtyFcompsn = indivDetails.get(0).idn_eligty_fcompsn__c;
                            }
                            if(indivDetails.size()>1){
                                indivEligWrapper.lastIndivEligDetailEndDate = indivDetails.get(1).dte_end_effv__c;
                                indivEligWrapper.lastIndivEligDetail = indivDetails.get(1);
                                if(idnIndivFcompsnToRecord.containsKey(indivDetails.get(1).idn_indiv_fcompsn__c)){
                                    indivEligWrapper.lastIndivElig = idnIndivFcompsnToRecord.get(indivDetails.get(1).idn_indiv_fcompsn__c);
                                }
                                if(indivDetails.size()>2){
                                    indivEligWrapper.secondLastIndivEligDetail = indivDetails.get(2);
                                    if(idnIndivFcompsnToRecord.containsKey(indivDetails.get(2).idn_indiv_fcompsn__c)){
                                        indivEligWrapper.secondLastIndivElig = idnIndivFcompsnToRecord.get(indivDetails.get(2).idn_indiv_fcompsn__c);
                                    }
                                }
                            }
                            
                            List<batchsit_t_indiv_eligty_failr__x> indivIneligibilityFailure = [SELECT Id, CDE_REASON_FAILR_ELIGTY_INDIV__c
                                                                                                FROM batchsit_t_indiv_eligty_failr__x
                                                                                                WHERE IDN_INDIV_FCOMPSN__c =: idnIndivFcompsn WITH SECURITY_ENFORCED];
                            if(indivIneligibilityFailure.size() > 0) {
                                indivEligWrapper.indivEligFailrs = indivIneligibilityFailure;
                            } 
                            List<batchsit_t_fcompsn_eligty_detail__x> eligDetail = [SELECT dte_begin_effv__c FROM batchsit_t_fcompsn_eligty_detail__x WHERE idn_eligty_fcompsn__c = :indivEligWrapper.indivElig.idn_eligty_fcompsn__c WITH SECURITY_ENFORCED ORDER BY dte_begin_effv__c DESC ,idn_eligty_fcompsn__c  DESC];
                            if(!eligDetail.isEmpty()){
                                indivEligWrapper.householdEligibilityBeginDate = eligDetail.get(0).dte_begin_effv__c;                    
                            }
                            
                            objectData.put('indivEligWrapper',indivEligWrapper);
                            //Read Only view based on profile
                            /* Using Custom Permission CCCAP-14993 - decommissioning State IT User and State Program Administrator
                            Set<String> readOnlyForProfiles = new Set<String>{'Fiscal Worker', 'Business Office Supervisor','Business Office Worker','Fiscal Worker Supervisor', 'Provider Worker', 'Provider Worker Supervisor', 'Read Only User', 'State IT User', 'State Program Administrator'};
                            List<Profile> profiles = [select Name from profile where id = :userinfo.getProfileId()]; */
                            if(FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Business_Office_Supervisor') ||FeatureManagement.checkPermission('Business_Office_Worker') ||FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') ||
                            FeatureManagement.checkPermission('Provider_Worker') ||FeatureManagement.checkPermission('Provider_Worker_Supervisor') ||FeatureManagement.checkPermission('Read_Only_User')){
                                objectData.put('readOnlyMode', true);
                            }
                        }else{
                            isSuccessful = false;
                            message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
                        }    
                    }else{
                        isSuccessful = false;
                        message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
                    }    
                    
                }else{
                    isSuccessful = false;
                    message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
                }   
            }else{
                isSuccessful = false;
                message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
            objectData.put('error',ex.getLineNumber()+':'+ex.getCause()+'-'+ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'getInitData'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getIneligibleReason(Decimal FCEligibilityID){
        System.debug(FCEligibilityID);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        List<T_INELIG_REASON__c> ineligReasons = [SELECT Id, CDE_REASON__c, IDN_DOC__c, TXT_REASON_DESC_LONG__c, TXT_REASON_DESC_SHORT__c FROM T_INELIG_REASON__c WITH SECURITY_ENFORCED ORDER by CDE_REASON__c asc  limit 5000 ];
        if(!ineligReasons.isEmpty()){
            objectData.put('ineligReasons',ineligReasons);
            if(FCEligibilityID!=null){
                List<batchsit_t_fcompsn_eligty__x> householdEligibilities = [SELECT idn_run_eligty__c, idn_run_eligty__r.Id FROM batchsit_t_fcompsn_eligty__x WHERE  idn_eligty_fcompsn__c = :FCEligibilityID AND (cde_reason_change_fcompsn__c!='NCT' OR cde_reason_change_fcompsn__c=null) WITH SECURITY_ENFORCED];
                if(!householdEligibilities.isEmpty() && String.isNotEmpty(householdEligibilities.get(0).idn_run_eligty__c) && String.isNotEmpty(householdEligibilities.get(0).idn_run_eligty__r.Id)){
                    objectData.put('eligibleRunSFId', householdEligibilities.get(0).idn_run_eligty__r.Id);
                }else{
                    isSuccessful = false;
                    message= Label.Eligible_Run_record_is_not_properly_setup;
                }
            }
        }else{
            isSuccessful = false;
            message= Label.Ineligible_Reason_Codes_are_not_properly_setup_in_this_environment;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    // Called From ContinuationController
    public static Object doCallBRESaveIneligibilityReasonsContinuation(Continuation con, String FCEligibilityID, String FCIndividualID, String DocumentId, String FailureCodes){
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setEndpoint(System.Label.BRE_SaveIneligibilityReasons);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String body = '{"FCEligibilityID":'+FCEligibilityID+',';
        if(String.isNotEmpty(FCIndividualID)){
            body+='"FCIndividualID":'+FCIndividualID+',';
        }
        body+='"DocumentId":"'+DocumentId+'",';
        body+='"FailureCodes":[';
        if(String.isNotEmpty(FailureCodes)){
            FailureCodes = FailureCodes.removeEnd(',');
            for(String FailureCode:FailureCodes.split(',')){
                body+='"'+FailureCode+'",';
            }
            body = body.removeEnd(',');
        }
        body += '],';
        body += '"UserLastUpdated":"'+UserInfo.getUserId()+'"}';
        req.setBody(body);
        System.debug(body);
        // Adding req for continuation callBacks.
        con.state = con.addHttpRequest(req);
        con.continuationMethod = 'callbackForBRESaveIneligibilityReasons';        
        // Return it to the system for processing
        return con;
    }   
    
    // BRECreate Callback for ContinuationController 
    public static Object doCallBackBRESaveIneligibilityReasonsContinuation(Object state){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message='';
        try{
        System.debug(state);
        //HttpResponse response = Continuation.getResponse((String)state);
        HttpResponse response = Continuation.getResponse((String)state);
        System.debug('response'+response);
        
        
        Integer statusCode = response.getStatusCode();
        if (statusCode >= 2000) {
            isSuccessful = false;
            message = Label.CONTINUATION_ERROR + statusCode;
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});
        }else if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});

            isSuccessful = false;
            String error = Label.An_error_occurred_while_calling_BRE;
            error+=response.getStatus()!=null?String.valueOf(response.getStatus())+Label.SEPARATOR_COMMA:'';
            String errorBody = response.getBody();
            String actualError = errorBody.substringBetween('The exception message is', 'See server logs for more details');
            if(String.isNotEmpty(actualError)){
                error += actualError;
                error = error.replaceAll('\'', '');
            }else{
                error+= errorBody;
            }
            message = error;
            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});
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
		            ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'IndividualFlowCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});
                }
            }else{
                objectData.put('failureCodes',data.get('FailureCodes'));
            }
        }
        } catch(Exception ex) {
        	isSuccessful = false;
            message=ex.getMessage();
             ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualFlowCtrl','Method__c'=>'doCallBackBRESaveIneligibilityReasonsContinuation'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
}