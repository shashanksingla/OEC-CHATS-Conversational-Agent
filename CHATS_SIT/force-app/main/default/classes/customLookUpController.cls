public with sharing class customLookUpController{
    
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName) {
        system.debug('ObjectName-->' + ObjectName);
        String searchKey = searchKeyWord + '%';
        Set<Id> recordIds = new Set<Id>();
        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 100   
        String sQueryExact =  'select id, Name from ' + String.escapeSingleQuotes(ObjectName) + ' where Name =: searchKey order by Name ASC limit 100';
        List < sObject > lstOfRecordsName = Database.query(sQueryExact);
        for (sObject obj: lstOfRecordsName) {
            returnList.add(obj);
            recordIds.add(obj.id);
        } 
        String sQuery =  'select id, Name from ' +String.escapeSingleQuotes(ObjectName) + ' where Name LIKE: searchKey and id NOT IN:recordIds order by Name ASC limit 100';
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static List < sObject > fetchRecentLookUpValues(String ObjectName) {
        system.debug('ObjectName-->' + ObjectName);
        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Recent Records List with LIMIT 10   
        String sQuery =  'select id, Name from RecentlyViewed where Type = :ObjectName limit 10';
        List < sObject > lstOfRecords = Database.query(sQuery);
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static sObject fetchRecordFromParentRecordId(String parentRecordId, String ObjectName) {
        system.debug('ObjectName-->' + ObjectName);
        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 100   
        String sQuery =  'select id, Name from ' + String.escapeSingleQuotes(ObjectName) + ' where Id =: parentRecordId LIMIT 1';
        sObject  lstOfRecord = Database.query(sQuery);
        /*
		for (sObject obj: lstOfRecords) {
		returnList.add(obj);
		}*/
        return lstOfRecord;
    }
    
}