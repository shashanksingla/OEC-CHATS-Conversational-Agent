public with sharing class IndividualFlowApxCtrl {
    
    @auraEnabled
    public static LightningServerResponse checkIfIntakeCase(Id caseId){
        try {
            Boolean isIntake = false;
            for(T_SBSD_CASE_STATUS_MODE__c caseStatus : [SELECT CDE_MODE_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c =: caseId WITH SECURITY_ENFORCED ORDER BY DTE_BEGIN_EFFV__c DESC LIMIT 1]){
                if(caseStatus.CDE_MODE_CASE__c =='INT'){
                    isIntake = true;
                }
            }
            return new LightningServerResponse(true, 'isIntake fetched', new Map<String, object>{'isIntake' => isIntake});
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'IndividualFlowApxCtrl','Method__c'=>'checkIfIntakeCase'});
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }
}