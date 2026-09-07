public with sharing class HistoryFlowCtrl {
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String idnIndivFcompsn) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        IndividualEligibilityHistoryWrapper indivEligWrapper = new IndividualEligibilityHistoryWrapper();
        try{
            List<batchsit_t_fcompsn_indiv_eligty_hist__x> indEligibilityHistList;
            if(Test.isRunningTest()){               
                indEligibilityHistList = new List<batchsit_t_fcompsn_indiv_eligty_hist__x>();
                batchsit_t_fcompsn_indiv_eligty_hist__x individualEligibilityHistory = new batchsit_t_fcompsn_indiv_eligty_hist__x();
                individualEligibilityHistory.cde_reason_ovrd__c = '';
                individualEligibilityHistory.txt_cmt_ovrd__c = '';
                indEligibilityHistList.add(individualEligibilityHistory);
            }else{
                indEligibilityHistList = [SELECT Id, 
                                          cde_reason_ovrd__c, 
                                          txt_cmt_ovrd__c,
                                          idn_case_indiv__c,
                                          idn_case_indiv__r.IDN_CLIENT__c,
                                          idn_case_indiv__r.DTE_BEGIN_EFFV__c,
                                          idn_case_indiv__r.IDN_CLIENT__r.NAM_LAST__c,
                                          idn_case_indiv__r.IDN_CLIENT__r.NAM_FIRST__c,
                                          idn_eligty_fcompsn__c,
                                          idn_indiv_fcompsn__c,
                                          idn_indiv_fcompsn__r.idn_indiv_fcompsn__c
                                          FROM batchsit_t_fcompsn_indiv_eligty_hist__x
                                          Where idn_indiv_fcompsn__c =: idnIndivFcompsn AND
                                          idn_case_indiv__c!=null order by dte_created_hist__c LIMIT 200];
            }
            
            List<batchsit_t_indiv_eligty_detail_hist__x> indEligibilityDetlList;
            if(Test.isRunningTest()){
                indEligibilityDetlList = new List<batchsit_t_indiv_eligty_detail_hist__x>();
            }else{
                indEligibilityDetlList = [SELECT Id, idn_indiv_eligty_detail_hist__c, cde_status_detail_eligty_indiv__c, dte_end_effv__c, dte_begin_effv__c, idn_eligty_fcompsn__c, idn_indiv_fcompsn__c
                                          FROM batchsit_t_indiv_eligty_detail_hist__x
                                          WHERE idn_indiv_eligty_detail_hist__c != null 
                                          and idn_indiv_fcompsn__c =:indEligibilityHistList[0].idn_eligty_fcompsn__c  LIMIT 200];
            }
            
            Set<String> indivResIdSet = new Set<String>();
            for(batchsit_t_indiv_eligty_failr__x indivReason : [SELECT id,idn_indiv_eligty_failr__c from batchsit_t_indiv_eligty_failr__x where idn_indiv_fcompsn__c =: idnIndivFcompsn]){
                indivResIdSet.add(String.valueOf(indivReason.idn_indiv_eligty_failr__c));
            }
            
            List<batchsit_t_indiv_eligty_failr_hist__x> indivIneligibilityFailureList;
            if(Test.isRunningTest()){
                indivIneligibilityFailureList = new List<batchsit_t_indiv_eligty_failr_hist__x>();
            }else{
                indivIneligibilityFailureList = [SELECT Id, idn_indiv_eligty_failr_hist__c, idn_indiv_eligty_failr__c, CDE_REASON_FAILR_ELIGTY_INDIV__c
                                                 FROM batchsit_t_indiv_eligty_failr_hist__x
                                                 WHERE idn_indiv_eligty_failr__c IN:indivResIdSet LIMIT 200];
            }
            
            
            indivEligWrapper.firstName = indEligibilityHistList[0].idn_case_indiv__r.IDN_CLIENT__r.NAM_FIRST__c;
            indivEligWrapper.lastName = indEligibilityHistList[0].idn_case_indiv__r.IDN_CLIENT__r.NAM_LAST__c;
            indivEligWrapper.indivEligFailrs = indivIneligibilityFailureList;
            indivEligWrapper.idnIndivFcompsn = idnIndivFcompsn;
            if(indEligibilityHistList.size()>0){
                indivEligWrapper.indivElig = indEligibilityHistList[0];
            }
            if(indEligibilityDetlList.size()>0 ){
                indivEligWrapper.indivEligDetail = indEligibilityDetlList[0];
                indivEligWrapper.idnEligtyFcompsn = String.valueOf(indEligibilityDetlList[0].idn_eligty_fcompsn__c) ;
                objectData.put('indEligibilityDetail',indEligibilityDetlList[0]);
            }
            if(indEligibilityHistList.size()>2){
            indivEligWrapper.secondLastIndivElig = indEligibilityHistList[2] ;
            
            }
            if(indEligibilityHistList.size()>1){
            indivEligWrapper.lastIndivElig = indEligibilityHistList[1] ;
            }
            
            objectData.put('indivEligWrapper',indivEligWrapper);
            objectData.put('indEligibilityHist',indEligibilityHistList[0]);
            
            
        }catch(Exception ex){
            isSuccessful = false;
            message = System.Label.ELIGIBILITY_NO_PROPER_DATA;
            objectData.put('error',ex.getLineNumber()+':'+ex.getCause()+'-'+ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HistoryFlowCtrl','Method__c'=>'getInitData'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getIneligibleReason(String idnIndivFcompsn){
        System.debug(idnIndivFcompsn);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        //List<T_INELIG_REASON__c> ineligReasons = [SELECT Id, CDE_REASON__c, IDN_DOC__c, TXT_REASON_DESC_LONG__c, TXT_REASON_DESC_SHORT__c FROM T_INELIG_REASON__c limit 5000];
        //if(!ineligReasons.isEmpty()){
            //objectData.put('ineligReasons',ineligReasons);
            Set<String> indivResIdSet = new Set<String>();
        if(idnIndivFcompsn != null){
           for(batchsit_t_indiv_eligty_failr_hist__x indivReason : [SELECT id,idn_indiv_eligty_failr__c from batchsit_t_indiv_eligty_failr_hist__x where idn_indiv_fcompsn__c =: Decimal.valueOf(idnIndivFcompsn) ]){
                indivResIdSet.add(String.valueOf(indivReason.idn_indiv_eligty_failr__c));
            }  
        }
           
            
             List<batchsit_t_indiv_eligty_failr_hist__x> indivIneligibilityFailureList = [SELECT Id, idn_indiv_eligty_failr_hist__c, idn_indiv_eligty_failr__c, CDE_REASON_FAILR_ELIGTY_INDIV__c
                                                                                         FROM batchsit_t_indiv_eligty_failr_hist__x
                                                                                         WHERE idn_indiv_eligty_failr__c IN:indivResIdSet LIMIT 200];
        objectData.put('IndivEligFailureReasonLst',indivIneligibilityFailureList);
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse incomeSummaryfetch(String eligibilityRunId){
        EligibilityHistoryWrapper eligHistoryIncomeWrap = new EligibilityHistoryWrapper();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        String eligHistIdnExtrl;
        if(String.isNotBlank(eligibilityRunId)){
            for(batchsit_t_eligty_run_hist__x eligHist : [Select idn_run_eligty__c,idn_run_eligty_hist__c ,id from batchsit_t_eligty_run_hist__x where id=:eligibilityRunId]){
                eligHistIdnExtrl = String.valueOf(eligHist.idn_run_eligty__c);
            }
        }
        String method = 'POST';
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.EligibilityIncomeFetch);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String jsonStr = '{"eligbilityRunId":"'+eligHistIdnExtrl +'"}';
            system.debug('jsonStr----'+jsonStr);
            request.setBody(jsonStr);
            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'incomeSummaryfetch'});             
                
            } else {
                System.debug('The status code returned was not expected: ' +
                             response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
               // List<Object> lst_JsonParse = (List<Object>) JSON.deserializeUntyped(response.getBody());
               // for(Object obj : lst_JsonParse)
              //  {
                    Map<String,Object> mp_StrObj = (Map<string,Object>)JSON.deserializeUntyped(response.getBody());
                    if((String)mp_StrObj.get('errorMsg') == null){
                        if(mp_StrObj.get('eligRunId') != null){
                            eligHistoryIncomeWrap.eligRunId = (String)mp_StrObj.get('eligRunId');
                        }
                        if(mp_StrObj.get('totalIncomeDeductions') != null){
                            eligHistoryIncomeWrap.totalIncomeDeductions = Decimal.valueOf(String.valueOf(mp_StrObj.get('totalIncomeDeductions')).replaceAll(',','')).setScale(2);
                        }
                        if(mp_StrObj.get('annualExpenses') != null){
                            eligHistoryIncomeWrap.annualExpenses = Decimal.valueOf(String.valueOf(mp_StrObj.get('annualExpenses')).replaceAll(',','')).setScale(2);   
                        }
                        if(mp_StrObj.get('totalAnnualAdjustedIncome') != null){
                            eligHistoryIncomeWrap.totalAnnualAdjustedIncome = Decimal.valueOf(String.valueOf(mp_StrObj.get('totalAnnualAdjustedIncome')).replaceAll(',','')).setScale(2); //(String)mp_StrObj.get('amt_Cty');
                        }
                        if(mp_StrObj.get('totalOtherIncome') != null){
                            eligHistoryIncomeWrap.totalOtherIncome = Decimal.valueOf(String.valueOf(mp_StrObj.get('totalOtherIncome')).replaceAll(',','')).setScale(2);//(String)mp_StrObj.get('amt_Fa');
                        }
                    }else{
                        objectData.put('errorMessage',(String)mp_StrObj.get('errorMsg'));
                    }
                    objectData.put('eligHistoryIncomeWrap',eligHistoryIncomeWrap);
               // }
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'HerokuService','Method__c'=>'incomeSummaryfetch'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
}