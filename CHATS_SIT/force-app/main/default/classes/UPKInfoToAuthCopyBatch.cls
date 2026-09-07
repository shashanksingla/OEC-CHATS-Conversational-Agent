/* CCCAP-15329
 * @description Batch class that copies UPK information from T_UPK_INDIV_AUTH_INFO__c records
 *              to matching T_AUTH__c (Authorization) records. 
 */
public with sharing class UPKInfoToAuthCopyBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    private Integer recordsProcessed = 0;
    private Integer authsUpdated = 0;
    private Integer totalFailures = 0;
    private List<String> errorMessages = new List<String>();
    private static final String CLASS_NAME = 'UPKInfoToAuthCopyBatch';
    private static final String ACTIVE_STATUS = '2';
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UPKInfoToAuthCopyBatch(), 200);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoffDate = CHATSUtility.getUPKCutoffDate();
        String query = 'SELECT Id, IDN_CLIENT__c, IDN_PROVR__c, Is_the_child_dually_enrolled_in_UPK__c, ' +
                       'UPK_Enrollment_Start_Date__c, UPK_Stacking_Hours__c, CreatedDate ' +
                       'FROM T_UPK_INDIV_AUTH_INFO__c WHERE Is_Copied_To_Auth__c = false ' +
                       'AND CreatedDate >= :cutoffDate ORDER BY CreatedDate DESC';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<T_UPK_INDIV_AUTH_INFO__c> upkInfoList) {
        try {
            if (upkInfoList.isEmpty()) {
                return;
            }
            
            Map<String, T_UPK_INDIV_AUTH_INFO__c> upkInfoByKey = new Map<String, T_UPK_INDIV_AUTH_INFO__c>();
            Map<String, Set<Id>> allUpkInfoIdsByKey = new Map<String, Set<Id>>();
            Set<String> clientIds = new Set<String>();
            Set<String> providerIds = new Set<String>();
            
            for (T_UPK_INDIV_AUTH_INFO__c upkInfo : upkInfoList) {
                if (String.isNotBlank(upkInfo.IDN_CLIENT__c) && String.isNotBlank(upkInfo.IDN_PROVR__c)) {
                    String key = upkInfo.IDN_CLIENT__c + '_' + upkInfo.IDN_PROVR__c;
                    // Only store the latest record for this key
                    if (!upkInfoByKey.containsKey(key)) {
                        upkInfoByKey.put(key, upkInfo);
                    }                    
                    if (!allUpkInfoIdsByKey.containsKey(key)) {
                        allUpkInfoIdsByKey.put(key, new Set<Id>());
                    }
                    allUpkInfoIdsByKey.get(key).add(upkInfo.Id);
                    clientIds.add(upkInfo.IDN_CLIENT__c);
                    providerIds.add(upkInfo.IDN_PROVR__c);
                }
            }
            
            if (upkInfoByKey.isEmpty()) {
                return;
            }
            
            Date juneThirtyNextYear = calculateJuneThirtyNextYear();
            List<T_AUTH__c> matchingAuths = queryMatchingAuthorizations(clientIds, providerIds, juneThirtyNextYear);
            
            List<T_AUTH__c> authsToUpdate = new List<T_AUTH__c>();
            Set<Id> processedUpkInfoIds = new Set<Id>();
            Set<String> processedKeys = new Set<String>();
            
            Map<Id, T_AUTH__c> oldAuthValuesMap = new Map<Id, T_AUTH__c>();
            for (T_AUTH__c auth : matchingAuths) {
                // Store old values before they get modified
                oldAuthValuesMap.put(auth.Id, new T_AUTH__c(Id = auth.Id, CDE_CHILD_ENROLLED_IN_UPK__c = auth.CDE_CHILD_ENROLLED_IN_UPK__c,
                    UPK_Awarded_Hours__c = auth.UPK_Awarded_Hours__c));
            }
            
            for (T_AUTH__c auth : matchingAuths) {
                // Build key using related record Name fields (same as the values in UPK Info)
                String authClientName = auth.IDN_CLIENT__r != null ? auth.IDN_CLIENT__r.Name : '';
                String authProviderName = auth.IDN_PROVR__r != null ? auth.IDN_PROVR__r.Name : '';
                String key = authClientName + '_' + authProviderName;
                
                T_UPK_INDIV_AUTH_INFO__c upkInfo = upkInfoByKey.get(key);
                if (upkInfo != null) {
                    auth.CDE_CHILD_ENROLLED_IN_UPK__c = upkInfo.Is_the_child_dually_enrolled_in_UPK__c;
                    auth.UPK_Awarded_Hours__c = upkInfo.UPK_Stacking_Hours__c;
                    auth.UPK_Start_date__c = upkInfo.UPK_Enrollment_Start_Date__c;
                    authsToUpdate.add(auth);
                    processedKeys.add(key);
                }
            }
            
            // Collect all UPK Info IDs for processed keys (including duplicates)
            for (String key : processedKeys) {
                Set<Id> allIdsForKey = allUpkInfoIdsByKey.get(key);
                if (allIdsForKey != null) {
                    processedUpkInfoIds.addAll(allIdsForKey);
                }
            }            
            if (!authsToUpdate.isEmpty()) {
                Database.SaveResult[] authResults = Database.update(authsToUpdate, false, AccessLevel.SYSTEM_MODE);
                List<T_AUTH__c> successfulAuthUpdates = new List<T_AUTH__c>();
                for (Integer i = 0; i < authResults.size(); i++) {
                    if (authResults[i].isSuccess()) {
                        authsUpdated++;
                        successfulAuthUpdates.add(authsToUpdate[i]);
                    } else {
                        totalFailures++;
                        for (Database.Error err : authResults[i].getErrors()) {
                            errorMessages.add('Auth Id: ' + authsToUpdate[i].Id + ' - Error: ' + err.getMessage());
                        }
                    }
                }
                if (!successfulAuthUpdates.isEmpty()) {
                    AuthorizationStatusController.insertATSRecords(successfulAuthUpdates);
                }
                // Create Task T122 for auths where UPK fields changed
                Set<Id> authIdsForT122Task = new Set<Id>();
                Set<Id> authIdsForCR215 = new Set<Id>(); 
                for (T_AUTH__c auth : successfulAuthUpdates) {
                    T_AUTH__c oldAuth = oldAuthValuesMap.get(auth.Id);
                    if (oldAuth != null) {
                        Boolean upkEnrolledChangedToYes = (oldAuth.CDE_CHILD_ENROLLED_IN_UPK__c != auth.CDE_CHILD_ENROLLED_IN_UPK__c && auth.CDE_CHILD_ENROLLED_IN_UPK__c == 'Yes');
                        Boolean upkHoursUpdated = (oldAuth.UPK_Awarded_Hours__c != auth.UPK_Awarded_Hours__c && auth.UPK_Awarded_Hours__c > 0 && oldAuth.UPK_Awarded_Hours__c > 0);
                        if (upkEnrolledChangedToYes || upkHoursUpdated) {
                            authIdsForT122Task.add(auth.Id);
                        }
                        if (upkEnrolledChangedToYes && auth.Is_UPK_Stacked__c == 'No' &&
                            (auth.IDN_PROVR__r.CDE_ATS_WAIVER__c == true || auth.IDN_PROVR__r.CDE_ELV_WAIVER__c == true)) {
                            authIdsForCR215.add(auth.Id);
                        }
                    }
                }
                if (!authIdsForT122Task.isEmpty()) {
                    AuthorizationServices.createTaskT122(authIdsForT122Task);
                }
                if (!authIdsForCR215.isEmpty()) {
                    AuthorizationFlowApxCtrl.CR215CorrBulk(authIdsForCR215, false);
                }
            }
            
            if (!processedUpkInfoIds.isEmpty()) {
                markUpkInfoAsProcessed(processedUpkInfoIds);
                recordsProcessed += processedUpkInfoIds.size();
            }
            
        } catch (Exception e) {
            logError('execute', e.getMessage() + ' | ' + e.getStackTraceString());
        }
    }
    
    // Calculates June 30 of the next fiscal year
    private Date calculateJuneThirtyNextYear() {
        Date today = System.today();
        Integer currentMonth = today.month();
        Integer currentYear = today.year();
        Integer targetYear = (currentMonth > 6) ? currentYear + 1 : currentYear;
        return Date.newInstance(targetYear, 6, 30);
    }
    
    // Queries authorizations matching by Individual Name and Provider Name fields
    private List<T_AUTH__c> queryMatchingAuthorizations(Set<String> clientNames, Set<String> providerNames, Date juneThirtyNextYear) {
        if (clientNames.isEmpty() || providerNames.isEmpty()) {
            return new List<T_AUTH__c>();
        }
        
        return [
            SELECT Id, Name, IDN_CLIENT__c, IDN_CLIENT__r.Name, IDN_PROVR__c, IDN_PROVR__r.Name,
                   Authorization_Status__c, DTE_BEGIN_EFFV_AUTH__c, CDE_CHILD_ENROLLED_IN_UPK__c,
                   UPK_Awarded_Hours__c, UPK_Start_date__c, UPK_Last_Updated_date__c, Number_of_Drop_in_Days__c,
                   Is_UPK_Stacked__c, IDN_PROVR__r.CDE_ATS_WAIVER__c, IDN_PROVR__r.CDE_ELV_WAIVER__c, isFinishedFlow__c
            FROM T_AUTH__c WHERE IDN_CLIENT__r.Name IN :clientNames AND IDN_PROVR__r.Name IN :providerNames AND Authorization_Status__c != '4'
            AND ((DTE_BEGIN_EFFV_AUTH__c <= :System.today() AND (DTE_END_EFFV_AUTH__c = null OR DTE_END_EFFV_AUTH__c >= :System.today()))
            OR (DTE_BEGIN_EFFV_AUTH__c > :System.today() AND DTE_BEGIN_EFFV_AUTH__c < :juneThirtyNextYear))
        ];
    }
    
    private void markUpkInfoAsProcessed(Set<Id> upkInfoIds) {
        List<T_UPK_INDIV_AUTH_INFO__c> upkInfosToUpdate = new List<T_UPK_INDIV_AUTH_INFO__c>();
        for (Id upkInfoId : upkInfoIds) {
            upkInfosToUpdate.add(new T_UPK_INDIV_AUTH_INFO__c(Id = upkInfoId, Is_Copied_To_Auth__c = true));
        }
        Database.SaveResult[] upkResults = Database.update(upkInfosToUpdate, false, AccessLevel.SYSTEM_MODE);
        for (Integer i = 0; i < upkResults.size(); i++) {
            if (!upkResults[i].isSuccess()) {
                totalFailures++;
                for (Database.Error err : upkResults[i].getErrors()) {
                    errorMessages.add('UPK Info Id: ' + upkInfosToUpdate[i].Id + ' - Error: ' + err.getMessage());
                }
            }
        }
    }
    
    private void logError(String methodName, String errorMessage) {
        errorMessages.add(methodName + ': ' + errorMessage.left(32000));
        totalFailures++;
    }
    
    public void finish(Database.BatchableContext bc) {        
        if (!errorMessages.isEmpty()) {
            try {
                Schema.SObjectType exceptionLogType = Schema.getGlobalDescribe().get('Exception_Log__c');
                if (exceptionLogType != null && exceptionLogType.getDescribe().isCreateable()) {
                    List<SObject> errorLogs = new List<SObject>();
                    
                    for (String errorMsg : errorMessages) {
                        SObject errorLog = exceptionLogType.newSObject();
                        Map<String, Schema.SObjectField> fieldMap = exceptionLogType.getDescribe().fields.getMap();
                        
                        if (fieldMap.containsKey('Class__c')) {
                            errorLog.put('Class__c', CLASS_NAME);
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