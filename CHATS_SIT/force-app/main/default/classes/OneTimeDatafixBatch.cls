/**
 * @description One-time datafix batch to be updated as needed
 * CCCAP-15329 - Updates CDE_CHILD_ENROLLED_IN_UPK__c field on active/future T_AUTH__c records based on child's age.
 */
global with sharing class OneTimeDatafixBatch implements Database.Batchable<sObject>, Database.Stateful {
    private static final String NOT_APPLICABLE = 'Not Applicable';
    private static final String UNKNOWN = 'Unknown';
    
    global Integer totalRecordsProcessed = 0;
    global Integer totalRecordsUpdated = 0;
    global Integer totalFailures = 0;
    global List<String> errorMessages = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        
        String query = 'SELECT Id, Name, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE IDN_CLIENT__c != null ' +
                       'AND IDN_CLIENT__r.Age__c != null AND (' +
                           '(DTE_BEGIN_EFFV_AUTH__c <= :today AND (DTE_END_EFFV_AUTH__c >= :today OR DTE_END_EFFV_AUTH__c = null)) ' +
                           'OR DTE_BEGIN_EFFV_AUTH__c > :today' +
                       ')';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<T_AUTH__c> scope) {
        List<T_AUTH__c> recordsToUpdate = new List<T_AUTH__c>();
        for (T_AUTH__c auth : scope) {
            totalRecordsProcessed++;
            Decimal age = auth.IDN_CLIENT__r.Age__c;
            String newValue = null;
            if (age < 3 || age >= 6) {
                newValue = NOT_APPLICABLE;
            } else if (age >= 3 && age < 6) {
                newValue = UNKNOWN;
            }
            
            if (newValue != null && auth.CDE_CHILD_ENROLLED_IN_UPK__c != newValue) {
                auth.CDE_CHILD_ENROLLED_IN_UPK__c = newValue;
                recordsToUpdate.add(auth);
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            List<T_AUTH__c> successfulAuthUpdates = new List<T_AUTH__c>();
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    totalRecordsUpdated++;
                    successfulAuthUpdates.add(recordsToUpdate[i]);
                } else {
                    totalFailures++;
                    for (Database.Error err : results[i].getErrors()) {
                        errorMessages.add('Record Id: ' + recordsToUpdate[i].Id + ' - Error: ' + err.getMessage());
                    }
                }
            }
            if (!successfulAuthUpdates.isEmpty()) {
                AuthorizationStatusController.insertATSRecords(successfulAuthUpdates);
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        String summary = 'OneTimeDatafixBatch completed. ' +
                        'Records Processed: ' + totalRecordsProcessed + 
                        ', Records Updated: ' + totalRecordsUpdated + 
                        ', Failures: ' + totalFailures;
        
        System.debug(summary);
        
        if (!errorMessages.isEmpty()) {
            logExceptions();
        }
    }
    
    private void logExceptions() {
        try {
            Schema.SObjectType exceptionLogType = Schema.getGlobalDescribe().get('Exception_Log__c');
            if (exceptionLogType != null && exceptionLogType.getDescribe().isCreateable()) {
                List<SObject> errorLogs = new List<SObject>();
                Map<String, Schema.SObjectField> fieldMap = exceptionLogType.getDescribe().fields.getMap();
                
                for (String errorMsg : errorMessages) {
                    SObject errorLog = exceptionLogType.newSObject();
                    
                    if (fieldMap.containsKey('Class__c')) {
                        errorLog.put('Class__c', 'OneTimeDatafixBatch');
                    }
                    if (fieldMap.containsKey('Exception_Message__c')) {
                        errorLog.put('Exception_Message__c', errorMsg.left(32000));
                    }
                    if (fieldMap.containsKey('Method__c')) {
                        errorLog.put('Method__c', 'execute');
                    }
                    if (fieldMap.containsKey('Exception_Type__c')) {
                        errorLog.put('Exception_Type__c', 'Error');
                    }
                    
                    errorLogs.add(errorLog);
                }
                
                if (!errorLogs.isEmpty()) {
                    Database.insert(errorLogs, false);
                }
            }
        } catch (Exception ex) {
            System.debug('Error logging failed: ' + ex.getMessage());
        }
    }
}