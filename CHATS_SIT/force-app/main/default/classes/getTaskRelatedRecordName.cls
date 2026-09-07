public class getTaskRelatedRecordName {
    @InvocableMethod(label='Get Obj/Record Name by ID' description='Returns the text Object & RecordName of any record ID dynamically' category='Task Utilities')
    public static List<String> getRecordNames(List<Id> recordIds) {
        List<String> results = new List<String>();
        
        if (recordIds == null || recordIds.isEmpty()) {
            return results;
        }

        //map to group recIds by their respective object name
        Map<String, List<Id>> objectToIdsMap = new Map<String, List<Id>>();
        //map to store the retrieved name/subject mapped to the recId
        Map<Id, String> idToNameMap = new Map<Id, String>();
        //map to keep track of object labels for fallbacks
        Map<String, String> objectToLabelMap = new Map<String, String>();

        for (Id recId : recordIds) {
            if (recId == null) continue;
            
            Schema.DescribeSObjectResult objectDescribe = recId.getSObjectType().getDescribe();
            String objectName = objectDescribe.getName();
            
            if (!objectToIdsMap.containsKey(objectName)) {
                objectToIdsMap.put(objectName, new List<Id>());
                objectToLabelMap.put(objectName, objectDescribe.getLabel());
            }
            objectToIdsMap.get(objectName).add(recId);
        }

        //bulk query records for each object type found
        for (String objectName : objectToIdsMap.keySet()) {
            List<Id> idsForObject = objectToIdsMap.get(objectName);
            Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            String nameField = 'Name';
            if(!fieldsMap.containsKey('Name') && fieldsMap.containsKey('Subject')) {
        		nameField = 'Subject'; // Fallback for standard Tasks or objects without a Name field
    		}
            
            try {
                // query all Ids for a specific object type in a single SOQL call
                String queryString = 'SELECT Id, ' + nameField + ' FROM ' + objectName + ' WHERE Id IN :idsForObject';
                List<sObject> records = Database.query(queryString);
                
                for (sObject record : records) {
                    idToNameMap.put(record.Id, (String)record.get(nameField));
                }
            } catch (Exception e) {
                System.debug('Error querying object ' + objectName + ': ' + e.getMessage());
            }
        }
        for (Id recId : recordIds) {
            if (recId == null) {
                results.add('');
            } else{
                Schema.DescribeSObjectResult objectDescribe = recId.getSobjectType().getDescribe();
                String objectLabel = objectDescribe.getLabel();
                if (idToNameMap.containsKey(recId)) {
                results.add(objectLabel + ': ' +idToNameMap.get(recId));
            } else {
                results.add(objectLabel);
           	}
        }
     }	        
	 return results;
    }
}