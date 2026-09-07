/*********************************************************************************************                                                         
*  @description    Batch Class for fixing case homeless records where multiple records are active at the same time. Ensures only one homeless record remains active by end-dating previous records.                             
*********************************************************************************************/

global with sharing class CaseHomelessDataFixBatch {
/*Commenting out as the batch is no longer in use. Add implements Database.Batchable<sObject>, Database.Stateful if uncommenting the code below
    public class customException extends Exception {}
    global Integer totalRecordsProcessed = 0;
    global Integer totalRecordsUpdated = 0;
    global List<String> errorMessages = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        // Check FLS for fields being queried
        if (!Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.IDN_CASE__c.isAccessible() ||
            !Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.DTE_BEGIN_EFFV__c.isAccessible() ||
            !Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.DTE_END_EFFV__c.isAccessible()) {
                throw new customException('Insufficient field level permissions for T_SBSD_CASE_HOMELESS__c');
            }
        
        Date today = Date.today();
        String query = 'SELECT Id, IDN_CASE__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c ' +
            'FROM T_SBSD_CASE_HOMELESS__c ' +
            'WHERE  DTE_BEGIN_EFFV__c != null ' +
            'AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c >= :today) ' +
            'ORDER BY IDN_CASE__c, DTE_BEGIN_EFFV__c ASC';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){        
        Set<Id> caseIdsInScope = new Set<Id>();
        
        for(sObject record : scope) {
            T_SBSD_CASE_HOMELESS__c homelessRecord = (T_SBSD_CASE_HOMELESS__c)record;
            // Fix: Add null check for dereferenced field
            if(homelessRecord != null && homelessRecord.IDN_CASE__c != null) {
                caseIdsInScope.add(homelessRecord.IDN_CASE__c);
            }
        }
        
        // Check which cases have overlapping records at database level, not just in current scope
        Set<Id> overlappingCaseIds = new Set<Id>();
        Date today = Date.today();
        
        for(AggregateResult ar : [SELECT IDN_CASE__c, COUNT(Id) recordCount 
                                  FROM T_SBSD_CASE_HOMELESS__c 
                                  WHERE IDN_CASE__c IN :caseIdsInScope 
                                  AND DTE_BEGIN_EFFV__c != null 
                                  AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c >= :today)
                                  GROUP BY IDN_CASE__c 
                                  HAVING COUNT(Id) > 1]) {
                                      overlappingCaseIds.add((Id)ar.get('IDN_CASE__c'));
                                  }
        
        totalRecordsProcessed += overlappingCaseIds.size();
        
        if(overlappingCaseIds.isEmpty()) {
            return;
        }
        
        try {
            Map<String, Object> results = fixOverlappingRecordsForCases(overlappingCaseIds);
            
            if(results.containsKey('totalRecordsUpdated')) {
                totalRecordsUpdated += (Integer)results.get('totalRecordsUpdated');
            }
            
            if(results.containsKey('errorMessages')) {
                List<String> batchErrors = (List<String>)results.get('errorMessages');
                if(batchErrors != null && !batchErrors.isEmpty()) {
                    errorMessages.addAll(batchErrors);
                }
            }
            
        } catch(Exception e) {
            errorMessages.add('Batch execution error: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('CaseHomelessDataFixBatch: Total cases processed: ' + totalRecordsProcessed);
        System.debug('CaseHomelessDataFixBatch: Total records updated: ' + totalRecordsUpdated);
        System.debug('CaseHomelessDataFixBatch: Total errors: ' + errorMessages.size());
        
        
        if(!errorMessages.isEmpty()) {
            // Safely concatenate error messages with a limit
            String combinedErrors = String.join(errorMessages, '\n');
            if (combinedErrors.length() > 32768) { // Typical long text area limit
                combinedErrors = combinedErrors.substring(0, 32768);
            }
            
            Exception_Log__c errorLog = new Exception_Log__c(
                Class__c = 'CaseHomelessDataFixBatch',
                Method__c = 'finish',
                Exception_Message__c = combinedErrors,
                Exception_Type__c = 'Data Fix Batch Error'
            );
            
            try {
                insert errorLog;
            } catch(Exception e) {
                System.debug('CaseHomelessDataFixBatch: Failed to create error log: ' + e.getMessage());
            }
        }
    }
    
    private Map<String, Object> fixOverlappingRecordsForCases(Set<Id> caseIds) {        
        Map<String, Object> results = new Map<String, Object>();
        List<String> processedCases = new List<String>();
        List<String> batchErrorMessages = new List<String>();
        Integer recordsUpdated = 0;
        
        try {
            List<T_SBSD_CASE_HOMELESS__c> homelessRecords = [
                SELECT Id, IDN_CASE__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c
                FROM T_SBSD_CASE_HOMELESS__c 
                WHERE IDN_CASE__c IN :caseIds
                AND DTE_BEGIN_EFFV__c != null
                ORDER BY IDN_CASE__c, DTE_BEGIN_EFFV__c ASC
            ];
            
            Map<Id, List<T_SBSD_CASE_HOMELESS__c>> caseToRecordsMap = new Map<Id, List<T_SBSD_CASE_HOMELESS__c>>();
            
            for(T_SBSD_CASE_HOMELESS__c record : homelessRecords) {
                // Fix: Add null check for dereferenced field
                if(record != null && record.IDN_CASE__c != null) {
                    if(!caseToRecordsMap.containsKey(record.IDN_CASE__c)) {
                        caseToRecordsMap.put(record.IDN_CASE__c, new List<T_SBSD_CASE_HOMELESS__c>());
                    }
                    caseToRecordsMap.get(record.IDN_CASE__c).add(record);
                }
            }
            
            List<T_SBSD_CASE_HOMELESS__c> recordsToUpdate = new List<T_SBSD_CASE_HOMELESS__c>();
            
            for(Id caseId : caseToRecordsMap.keySet()) {
                List<T_SBSD_CASE_HOMELESS__c> caseRecords = caseToRecordsMap.get(caseId);                
                if(caseRecords.size() <= 1) {
                    continue;
                }
                
                List<T_SBSD_CASE_HOMELESS__c> activeRecords = new List<T_SBSD_CASE_HOMELESS__c>();
                Date today = Date.today();
                
                for(T_SBSD_CASE_HOMELESS__c record : caseRecords) {
                    if(record.DTE_END_EFFV__c == null || record.DTE_END_EFFV__c >= today) {
                        activeRecords.add(record);
                    }
                }
                
                if(activeRecords.size() <= 1) {
                    continue;
                }
                
                activeRecords.sort(new HomelessRecordComparator());
                
                for(Integer i = 0; i < activeRecords.size() - 1; i++) {
                    T_SBSD_CASE_HOMELESS__c currentRecord = activeRecords[i];
                    T_SBSD_CASE_HOMELESS__c nextRecord = activeRecords[i + 1];
                    
                    // Fix: Add null checks for dereferenced fields
                    if(currentRecord != null && nextRecord != null) {
                        Date newEndDate = nextRecord.DTE_BEGIN_EFFV__c.addDays(-1);
                        if(currentRecord.DTE_END_EFFV__c != newEndDate && newEndDate >= currentRecord.DTE_BEGIN_EFFV__c) {
                            currentRecord.DTE_END_EFFV__c = newEndDate;
                            currentRecord.bypassValidations__c = System.now(); // Setting timestamp to bypass validation rule
                            recordsToUpdate.add(currentRecord);
                        }
                    }
                }
                processedCases.add(String.valueOf(caseId));
            }
            
            if(!recordsToUpdate.isEmpty()) {
                // Fix: Add FLS check before updating T_SBSD_CASE_HOMELESS__c records
                if(Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.isUpdateable() &&
                   Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.DTE_END_EFFV__c.isUpdateable() &&
                   Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.bypassValidations__c.isUpdateable()) {
                       try {
                           update recordsToUpdate;
                           recordsUpdated = recordsToUpdate.size();                                     
                       } catch(DmlException e) {
                           batchErrorMessages.add('Error updating records: ' + e.getMessage());
                       }
                   } else {
                       batchErrorMessages.add('Insufficient permissions to update T_SBSD_CASE_HOMELESS__c records');
                   }
            }
            
        } catch(Exception e) {
            batchErrorMessages.add('Unexpected error: ' + e.getMessage());
        }
        
        // Prepare results
        results.put('processedCases', processedCases);
        results.put('totalRecordsUpdated', recordsUpdated);
        results.put('errorMessages', batchErrorMessages);
        results.put('success', batchErrorMessages.isEmpty());
        
        return results;
    }
    
    public class HomelessRecordComparator implements Comparator<T_SBSD_CASE_HOMELESS__c> {
        public Integer compare(T_SBSD_CASE_HOMELESS__c record1, T_SBSD_CASE_HOMELESS__c record2) {
            // Add null checks for records and their fields
            if (record1 == null || record2 == null || record1.DTE_BEGIN_EFFV__c == record2.DTE_BEGIN_EFFV__c) {
                return 0;
            }
            return record1.DTE_BEGIN_EFFV__c < record2.DTE_BEGIN_EFFV__c ? -1 : 1;
        }
    }*/
}