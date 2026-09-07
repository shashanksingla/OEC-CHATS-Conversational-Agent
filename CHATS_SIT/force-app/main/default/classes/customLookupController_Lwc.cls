public with sharing class customLookupController_Lwc implements IRequest{
    public String jsonParam; 
    private static Map<String, Object > requestObj;
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        
        if (methodName == 'fetchLookUpValues') {
            response = fetchLookUpValues(getMapValue('searchKeyWord'),getMapValue('ObjectName'),getMapValue('searchField'),getMapValue('filter'));
        }
        else if(methodName == 'fetchRecentLookUpValues'){
            response = fetchRecentLookUpValues(getMapValue('ObjectName'),getMapValue('filter'));
        }
        else if(methodName == 'fetchRecordFromParentRecordId'){
            response = fetchRecordFromParentRecordId(getMapValue('parentRecordId'),getMapValue('ObjectName'));
        }
        return response;
    }
    private static String getMapValue(String fieldName){
        return (String)requestObj.get(fieldName);
    }

    @TestVisible
    private static String sanitizeFilter(String filterClause) {
        if (String.isBlank(filterClause)) {
            return null;
        }
        String sanitized = filterClause
            .replaceAll('--', '')          // strip line comments
            .replaceAll('/\\*', '')        // strip block-comment open
            .replaceAll('\\*/', '');        // strip block-comment close
        return String.isBlank(sanitized) ? null : sanitized;
    }

    @AuraEnabled
    public static LightningServerResponse fetchLookUpValues(String searchKeyWord, String ObjectName, String searchField, String filterClause) {
        Map<String, Object> objectData = new Map<String, Object>();
        String searchKey = searchKeyWord + '%';
        Set<Id> recordIds = new Set<Id>();
        List<sObject> returnList = new List<sObject>();

        // Sanitize searchField to prevent SOQL/SOSL injection as part of CCCAP-14167
        String sanitizedSearchField = String.escapeSingleQuotes(searchField).replaceAll('[^a-zA-Z0-9_.]', '');

        // Sanitize and build optional filter suffix — only appended when a filter is provided
        String safeFilter = sanitizeFilter(filterClause);
        String filterSuffix = String.isNotBlank(safeFilter) ? ' AND (' + safeFilter + ')' : '';

        // Exact-match query first, then LIKE — preserves existing ordering behaviour
        String sQueryExact = 'SELECT Id,' + sanitizedSearchField +' FROM ' + String.escapeSingleQuotes(ObjectName) + ' WHERE '+ sanitizedSearchField +' =: searchKey'
            + filterSuffix + ' ORDER BY Name ASC LIMIT 100';
        List<sObject> lstOfRecordsName = Database.query(sQueryExact);
        for (sObject obj: lstOfRecordsName) {
            returnList.add(obj);
            recordIds.add(obj.Id);
        } 
        String sQuery = 'SELECT Id,'+ sanitizedSearchField +' FROM ' +String.escapeSingleQuotes(ObjectName) + ' WHERE '+ sanitizedSearchField +' LIKE: searchKey and id NOT IN:recordIds'
            + filterSuffix + ' ORDER BY Name ASC LIMIT 100';
        List<sObject> lstOfRecords = Database.query(sQuery);
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        objectData.put('records',returnList);
        LightningServerResponse response = new LightningServerResponse(true, '', objectData);
        response.status = RequestStatus.OK;
        return response;
    }
    
    @AuraEnabled(cacheable=true)
    public static LightningServerResponse fetchRecentLookUpValues(String ObjectName, String filterClause) {
        Map<String, Object> objectData = new Map<String, Object>();
        List < sObject > returnList = new List < sObject > ();
        // Step 1 — fetch recently-viewed Ids for this object (unchanged behaviour)
        String sQuery =  'SELECT Id,Name FROM RecentlyViewed WHERE Type = :ObjectName limit 10';
        List < sObject > lstOfRecords = Database.query(sQuery);

        // Step 2 — if a filter is provided, re-query the real object to apply it
        String safeFilter = sanitizeFilter(filterClause);
        if (String.isNotBlank(safeFilter) && !lstOfRecords.isEmpty()) {
            Set<Id> recentIds = new Map<Id, sObject>(lstOfRecords).keySet();
            String filteredQuery = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(ObjectName)
                + ' WHERE Id IN :recentIds AND (' + safeFilter + ')'+ ' LIMIT 10';
            lstOfRecords = Database.query(filteredQuery);
        }

        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        objectData.put('records',returnList);
        LightningServerResponse response = new LightningServerResponse(true,'',objectData);
        response.status = RequestStatus.OK;
        return response;
    }
    
    @AuraEnabled
    public static LightningServerResponse fetchRecordFromParentRecordId(String parentRecordId, String ObjectName) {
        Map<String, Object> objectData = new Map<String, Object>();
        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 100   
        String sQuery =  'SELECT Id, Name FROM ' + String.escapeSingleQuotes(ObjectName) + ' WHERE Id =: parentRecordId LIMIT 1';
        sObject  lstOfRecord = Database.query(sQuery);       
        objectData.put('record',lstOfRecord);
        LightningServerResponse response = new LightningServerResponse(true,'',objectData);
        response.status = RequestStatus.OK;
        return response;
    }
    
}