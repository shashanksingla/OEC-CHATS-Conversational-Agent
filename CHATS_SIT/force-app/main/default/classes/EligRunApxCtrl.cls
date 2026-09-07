public With Sharing class EligRunApxCtrl {
    @AuraEnabled
    public static LightningServerResponse getInitData(String elgRunId, batchsit_t_eligty_run__x eligibilityRec){
        Map<String, Object> objectData = new map<String, Object>(); 
        Boolean isSuccessful;
        String message;
        List<batchsit_t_eligty_run__x> eligRunRecord;
        if(Test.isRunningTest()){
            isSuccessful = true;
            List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
            objectData.put('eligRunRecord',new List<SObject>{new batchsit_t_eligty_run__x(idn_case__c = cases.get(0).IDN_EXTNL__c,idn_run_eligty__c=15)});
        }else{
            eligRunRecord = [SELECT Id, dte_run_eligty__c, idn_case__c,idn_case__r.Id, idn_case__r.Name, idn_case__r.IND_CHGD_DATA_ELIGTY__c, idn_run_eligty__c, 
                             cde_eligty_cfmd__c, dte_redet_prpsd__c, dte_redet_ovrd__c, 
                             cde_date_redet_ovrd__c, txt_cmt_ovrd__c, createddate__c, dte_appln_old__c, dte_appln_new__c, rsn_appln_dte_override__c, cmt_appln_dte_override__c
                             FROM batchsit_t_eligty_run__x
                             WHERE Id =: elgRunId];
            
            
            if(String.isNotBlank(eligRunRecord[0].idn_case__r.Id)){
                T_SBSD_CASE__c caseRec = [SELECT Id, Program_Type__c FROM T_SBSD_CASE__c WHERE Id=:eligRunRecord[0].idn_case__r.Id LIMIT 1];
                String pgmType = caseRec.Program_Type__c != null ? caseRec.Program_Type__c : CaseHeaderApxCtrl.getChildCareProgram(eligRunRecord[0].idn_case__r.Id);
                objectData.put('childCareProgram', pgmType);
            }
            if(!eligRunRecord.isEmpty()){
                objectData.put('eligRunRecord',eligRunRecord);
                isSuccessful=true;
            }
            else{
                isSuccessful=false;
                message = Label.eligRecord_Not_Found;
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
}