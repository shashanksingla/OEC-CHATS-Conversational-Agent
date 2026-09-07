/* 
    CCCAP-14467
    Batch class to process Individual Email records created with future begin date and update related Case Info records
*/
public class IndividualEmailProcessingBatch implements Database.Batchable<sObject>, Schedulable {    
   
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new IndividualEmailProcessingBatch(), 200);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();      
        return Database.getQueryLocator('SELECT Id, Individual__c, Email_Information__c FROM Individual_E_mail__c WHERE Effective_Begin_Date__c = :today AND Email_Information__c != null AND Individual__c != NULL AND (Effective_End_Date__c = null OR Effective_End_Date__c >= :today)');
    }
    
    public void execute(Database.BatchableContext bc, List<Individual_E_mail__c> scope) {
        Set<Id> individualIds = new Set<Id>();
        Map<Id, String> individualEmailMap = new Map<Id, String>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'IndividualEmailProcessingBatch','Method__c'=>'execute'};
        for (Individual_E_mail__c emailRecord : scope) {
            individualIds.add(emailRecord.Individual__c);
            individualEmailMap.put(emailRecord.Individual__c, emailRecord.Email_Information__c);
        }        
        if (individualIds.isEmpty()) {
            return;
        }
        
        List<T_SBSD_CASE_INDIV__c> caseIndividuals = [SELECT Id, IDN_CLIENT__c, IDN_CASE__c, Individual_Status__c, IDN_CASE__r.Id, IDN_CASE__r.Name
            FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN :individualIds AND Individual_Status__c = 'PC'];
        if (caseIndividuals.isEmpty()) {
            return;
        }
        
        Set<Id> caseIds = new Set<Id>();
        Map<Id, String> caseToEmailMap = new Map<Id, String>();        
        for (T_SBSD_CASE_INDIV__c caseIndividual : caseIndividuals) {
            if (caseIndividual.IDN_CASE__c != null && individualEmailMap.containsKey(caseIndividual.IDN_CLIENT__c)) {
                caseIds.add(caseIndividual.IDN_CASE__c);
                caseToEmailMap.put(caseIndividual.IDN_CASE__c, individualEmailMap.get(caseIndividual.IDN_CLIENT__c));
            }
        }
        if (caseIds.isEmpty()) {
            return;
        }
        
        Map<Id, T_SBSD_CASE_INFO__c> existingCaseInfoMap = new Map<Id, T_SBSD_CASE_INFO__c>();
        List<T_SBSD_CASE_INFO__c> existingCaseInfos = [SELECT Id, IDN_CASE__c, CDE_TYPE_INFO_CASE__c, TXT_VALUE_INFO_CASE__c
            FROM T_SBSD_CASE_INFO__c WHERE IDN_CASE__c IN :caseIds AND CDE_TYPE_INFO_CASE__c = 'EM'];
        for (T_SBSD_CASE_INFO__c caseInfo : existingCaseInfos) {
            existingCaseInfoMap.put(caseInfo.IDN_CASE__c, caseInfo);
        }        
        List<T_SBSD_CASE_INFO__c> recordsToInsert = new List<T_SBSD_CASE_INFO__c>();
        List<T_SBSD_CASE_INFO__c> recordsToUpdate = new List<T_SBSD_CASE_INFO__c>();        
        for (Id caseId : caseIds) {
            String emailValue = caseToEmailMap.get(caseId);            
            if (String.isNotBlank(emailValue)) {
                if (existingCaseInfoMap.containsKey(caseId)) {
                    // Update existing record
                    T_SBSD_CASE_INFO__c caseInfoRecord = existingCaseInfoMap.get(caseId);
                    caseInfoRecord.TXT_VALUE_INFO_CASE__c = emailValue;
                    recordsToUpdate.add(caseInfoRecord);
                } else {
                    // Create new record
                    T_SBSD_CASE_INFO__c caseInfoRecord = new T_SBSD_CASE_INFO__c();
                    caseInfoRecord.IDN_CASE__c = caseId;
                    caseInfoRecord.CDE_TYPE_INFO_CASE__c = 'EM';
                    caseInfoRecord.TXT_VALUE_INFO_CASE__c = emailValue;
                    recordsToInsert.add(caseInfoRecord);
                }
            }
        }
        
        if (!recordsToInsert.isEmpty()) {
            try {
                GenericDMLHandler.insertRecords(recordsToInsert, methodInfo);
                System.debug('Successfully inserted ' + recordsToInsert.size() + ' T_SBSD_CASE_INFO__c records');
            } catch (Exception e) {
                System.debug('Error inserting T_SBSD_CASE_INFO__c records: ' + e.getMessage());
                ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
            }
        }        
        if (!recordsToUpdate.isEmpty()) {
            try {
                GenericDMLHandler.updateRecords(recordsToUpdate, methodInfo);
                System.debug('Successfully updated ' + recordsToUpdate.size() + ' T_SBSD_CASE_INFO__c records');
            } catch (Exception e) {
                System.debug('Error updating T_SBSD_CASE_INFO__c records: ' + e.getMessage());
                ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('IndividualEmailProcessingBatch completed successfully');
    }
}