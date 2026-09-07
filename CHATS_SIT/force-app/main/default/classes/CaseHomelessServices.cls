/*********************************************************************************************
*  @description    Handler class for Case Homeless record operations 
Updates the end date of previous homeless records when a record is inserted or updated with begin date.  
*  * Version: 1.0      CCCAP-12639                                                                                                                           
*********************************************************************************************/
public with sharing class CaseHomelessServices {
    
    public static void updatePreviousRecordEndDates(List<T_SBSD_CASE_HOMELESS__c> newHomelessRecords,Map<Id,T_SBSD_CASE_HOMELESS__c>oldHomelessRecordMap) {
        Map<Id, T_SBSD_CASE_HOMELESS__c> caseToRecordMap = new Map<Id, T_SBSD_CASE_HOMELESS__c>();
        Set<Id> recordIds = new Set<Id>();
        
        for(T_SBSD_CASE_HOMELESS__c record : newHomelessRecords) {
            if(record.IDN_CASE__c != null && record.DTE_BEGIN_EFFV__c != null && 
               (Trigger.isInsert || (Trigger.isUpdate && oldHomelessRecordMap.get(record.Id).DTE_BEGIN_EFFV__c != record.DTE_BEGIN_EFFV__c))) {
                   caseToRecordMap.put(record.IDN_CASE__c, record);
                   recordIds.add(record.Id);
               }
        }
        if(!caseToRecordMap.isEmpty()) {
            
            List<T_SBSD_CASE_HOMELESS__c> recordsToUpdate = new List<T_SBSD_CASE_HOMELESS__c>();
            
            // Process existing records to update end dates - only update the most recent record per case
            for(T_SBSD_CASE_HOMELESS__c existingRecord : [
                SELECT Id, IDN_CASE__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c 
                FROM T_SBSD_CASE_HOMELESS__c 
                WHERE IDN_CASE__c IN :caseToRecordMap.keySet() 
                AND (DTE_END_EFFV__c >= TODAY OR DTE_END_EFFV__c = null)
                AND Id NOT IN :recordIds
                ORDER BY IDN_CASE__c, DTE_BEGIN_EFFV__c DESC
            ]) 
            {
                T_SBSD_CASE_HOMELESS__c currentRecord = caseToRecordMap.get(existingRecord.IDN_CASE__c);
                
                // Only process existing records whose begin date is before the new record's begin date
                if(existingRecord.DTE_BEGIN_EFFV__c < currentRecord.DTE_BEGIN_EFFV__c || existingRecord.DTE_BEGIN_EFFV__c==null) {
                    Date newEndDate = currentRecord.DTE_BEGIN_EFFV__c.addDays(-1);
                    if(existingRecord.DTE_END_EFFV__c != newEndDate) {
                        existingRecord.DTE_END_EFFV__c = newEndDate; // Correcting End Date on existing records
                        existingRecord.bypassValidations__c = System.now(); // Set timestamp to bypass validation rule
                        recordsToUpdate.add(existingRecord);
                    }
                }
            }
            if(!recordsToUpdate.isEmpty()) {
                //FLS check as part of CCCAP-14224
                if(Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.isUpdateable() &&
                   Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.DTE_END_EFFV__c.isUpdateable() &&
                   Schema.sObjectType.T_SBSD_CASE_HOMELESS__c.fields.bypassValidations__c.isUpdateable()) {
                       update recordsToUpdate;                      
                   } else {
                       throw new System.NoAccessException();
                   }
            }
        }
    }
    
    public static void validateHomeless(List<T_SBSD_CASE_HOMELESS__c> newHomelessRecord,Map<Id,T_SBSD_CASE_HOMELESS__c>oldHomelessRecordMap){
        Map<Id,T_SBSD_CASE_HOMELESS__c> caseFromHomeless = new Map<Id,T_SBSD_CASE_HOMELESS__c>();
        Set<Id> recordIds = new Set<Id>();
        for(T_SBSD_CASE_HOMELESS__c record: newHomelessRecord){
            if(record.IDN_CASE__c != null && record.DTE_BEGIN_EFFV__c != null && 
               (Trigger.isInsert || (Trigger.isUpdate && oldHomelessRecordMap.get(record.Id).DTE_BEGIN_EFFV__c != record.DTE_BEGIN_EFFV__c))) {
                   caseFromHomeless.put(record.IDN_CASE__c, record);
                   if(record.Id != null) {
                       recordIds.add(record.Id);
                   }
               }
        }
        if(!caseFromHomeless.isEmpty()) {
            for(T_SBSD_CASE_HOMELESS__c existing:[
                SELECT Id, IDN_CASE__c, DTE_BEGIN_EFFV__c 
                FROM T_SBSD_CASE_HOMELESS__c 
                WHERE IDN_CASE__c IN :caseFromHomeless.keySet() 
                AND (DTE_END_EFFV__c >= TODAY OR DTE_END_EFFV__c = null)
                AND Id NOT IN :recordIds
                ORDER BY IDN_CASE__c, DTE_BEGIN_EFFV__c DESC
            ]){
                T_SBSD_CASE_HOMELESS__c currentRecord = caseFromHomeless.get(existing.IDN_CASE__c);
                if(currentRecord.DTE_BEGIN_EFFV__c<=existing.DTE_BEGIN_EFFV__c){
                    currentRecord.addError('Begin date can not be less than or equal to currently effective case homeless begin date.');
                }
            }
        }
    }
        
}