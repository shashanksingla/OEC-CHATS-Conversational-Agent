/*********************************************************************************************
*  CCCAP-15329
*  @description    Batch and Scheduler class to create T123 tasks for UPK Program Year Ending
*                  Creates tasks for active authorizations where:
*                  - Is this child dually enrolled in UPK = Yes
*                  - Is UPK Stacked = Yes
*  
*  To schedule this job 75 days before June 30 (runs on April 16 every year):
*********************************************************************************************/
global with sharing class UPKYearEndTaskBatch implements 
    Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    global Integer recordsProcessed = 0;
    global Integer totalTasksCreated = 0;
    global Integer totalFailures = 0;
    global List<String> errorMessages = new List<String>();
    
    global void execute(SchedulableContext sc) {
        UPKYearEndTaskBatch batch = new UPKYearEndTaskBatch();
        Database.executeBatch(batch, 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = System.today();
        String queryStr = 'SELECT Id, Name, IDN_CASE__c, IDN_CASE__r.OwnerId, IDN_CASE__r.Name, ' +
            'IDN_PROVR__c, IDN_PROVR__r.Name, IDN_CLIENT__c, IDN_CLIENT__r.Name, ' +
            'DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, ' +
            'CDE_CHILD_ENROLLED_IN_UPK__c, Is_UPK_Stacked__c ' +
            'FROM T_AUTH__c ' +
            'WHERE Authorization_Status__c != \'4\' AND DTE_BEGIN_EFFV_AUTH__c <= :todayDate ' +
            'AND (DTE_END_EFFV_AUTH__c = null OR DTE_END_EFFV_AUTH__c >= :todayDate) ' +
            'AND CDE_CHILD_ENROLLED_IN_UPK__c = \'Yes\' ' +
            'AND Is_UPK_Stacked__c = \'Yes\'';
        
        System.debug('UPKYearEndTaskBatch Query: ' + queryStr);
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_AUTH__c> authList) {
        List<Task> tasksToCreate = new List<Task>();
        
        for (T_AUTH__c authorization : authList) {
            recordsProcessed++;
            if (authorization.IDN_CASE__r.OwnerId == null) {
                continue;
            }
            Task tsk = new Task();
            tsk.Subject = System.Label.Task_T123_Subject;
            tsk.Description = System.Label.Task_T123_Description;
            tsk.WhatId = authorization.Id;
            tsk.OwnerId = authorization.IDN_CASE__r.OwnerId;
            tsk.Priority = 'Normal';                
            tasksToCreate.add(tsk);
        }
        
        if (!tasksToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(tasksToCreate, false, AccessLevel.SYSTEM_MODE);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    totalTasksCreated++;
                } else {
                    totalFailures++;
                    for (Database.Error err : results[i].getErrors()) {
                        errorMessages.add('Auth Id: ' + tasksToCreate[i].WhatId + ' - Error: ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        String summary = 'UPKYearEndTaskBatch completed. ' +
                        'Records Processed: ' + recordsProcessed + 
                        ', Tasks Created: ' + totalTasksCreated + 
                        ', Failures: ' + totalFailures;
        System.debug(summary);
        
        if (!errorMessages.isEmpty()) {
            try {
                Schema.SObjectType exceptionLogType = Schema.getGlobalDescribe().get('Exception_Log__c');
                if (exceptionLogType != null && exceptionLogType.getDescribe().isCreateable()) {
                    List<SObject> errorLogs = new List<SObject>();
                    
                    for (String errorMsg : errorMessages) {
                        SObject errorLog = exceptionLogType.newSObject();
                        Map<String, Schema.SObjectField> fieldMap = exceptionLogType.getDescribe().fields.getMap();
                        
                        if (fieldMap.containsKey('Class__c')) {
                            errorLog.put('Class__c', 'UPKYearEndTaskBatch');
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