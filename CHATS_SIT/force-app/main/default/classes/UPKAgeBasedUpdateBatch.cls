/** CCCAP-15329
 * @description Daily batch job to update the 'Is this child dually enrolled in UPK' field
 * on T_AUTH__c records based on age of the child.
 *              - Age < 3: Set to 'Not Applicable'
 *              - Age 3-6 (turning 3 from 'Not Applicable'): Set to 'Unknown'
 *              - Age > 6: Set to 'Not Applicable'
 */
global with sharing class UPKAgeBasedUpdateBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private static final String NOT_APPLICABLE = 'Not Applicable';
    private static final String UNKNOWN = 'Unknown';
    global Integer totalRecordsProcessed = 0;
    global Integer totalRecordsUpdated = 0;
    global Integer totalFailures = 0;
    global List<String> errorMessages = new List<String>();

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new UPKAgeBasedUpdateBatch(), 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String notApplicableEscaped = String.escapeSingleQuotes(NOT_APPLICABLE);
        Date today = System.today();
        String query = 'SELECT Id, Name, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c, Number_of_Drop_in_Days__c FROM T_AUTH__c ' +
                       'WHERE IDN_CLIENT__c != null AND IDN_CLIENT__r.Age__c != null AND Authorization_Status__c != \'4\' AND DTE_END_EFFV_AUTH__c >= : today AND (' +
                           '(IDN_CLIENT__r.Age__c < 3 AND CDE_CHILD_ENROLLED_IN_UPK__c != \'' + notApplicableEscaped + '\') ' +
                           'OR (IDN_CLIENT__r.Age__c >= 3 AND IDN_CLIENT__r.Age__c < 6 AND CDE_CHILD_ENROLLED_IN_UPK__c = \'' + notApplicableEscaped + '\') ' +
                           'OR (IDN_CLIENT__r.Age__c >= 6 AND CDE_CHILD_ENROLLED_IN_UPK__c != \'' + notApplicableEscaped + '\')' +
                       ')';        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<T_AUTH__c> scope) {
        List<T_AUTH__c> recordsToUpdate = new List<T_AUTH__c>();
        
        for (T_AUTH__c auth : scope) {
            totalRecordsProcessed++;            
            Decimal age = auth.IDN_CLIENT__r.Age__c;
            String currentValue = auth.CDE_CHILD_ENROLLED_IN_UPK__c;
            String newValue = null;
            
            if (age < 3 || age >= 6) {
                if (currentValue != NOT_APPLICABLE) {
                    newValue = NOT_APPLICABLE;
                }
            } else if (age >= 3 && age < 6) {
                if (currentValue == NOT_APPLICABLE) {
                    newValue = UNKNOWN;
                }
            }
            
            if (newValue != null) {
                auth.CDE_CHILD_ENROLLED_IN_UPK__c = newValue;
                recordsToUpdate.add(auth);
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(recordsToUpdate, false, AccessLevel.SYSTEM_MODE);
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
        String summary = 'UPKAgeBasedUpdateBatch completed. ' +
                        'Records Processed: ' + totalRecordsProcessed + 
                        ', Records Updated: ' + totalRecordsUpdated + 
                        ', Failures: ' + totalFailures;
        if (!errorMessages.isEmpty()) {
            try {
                Schema.SObjectType exceptionLogType = Schema.getGlobalDescribe().get('Exception_Log__c');
                if (exceptionLogType != null && exceptionLogType.getDescribe().isCreateable()) {
                    List<SObject> errorLogs = new List<SObject>();
                    for (String errorMsg : errorMessages) {
                        SObject errorLog = exceptionLogType.newSObject();
                        Map<String, Schema.SObjectField> fieldMap = exceptionLogType.getDescribe().fields.getMap();
                        if (fieldMap.containsKey('Class__c')) {
                            errorLog.put('Class__c', 'UPKAgeBasedUpdateBatch');
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
                        Database.insert(errorLogs, false, AccessLevel.SYSTEM_MODE);
                    }
                }
            } catch (Exception ex) {
                System.debug('Error logging failed: ' + ex.getMessage());
            }
        }
    }
}