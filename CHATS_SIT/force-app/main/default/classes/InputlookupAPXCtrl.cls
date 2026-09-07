public with sharing class InputlookupAPXCtrl {
    @AuraEnabled
    public static String getRecentRecords(String jsonString) {
        LookupResponseData responseData = new LookupResponseData();

        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            Map<Id, RecentlyViewed> recentlyViewedMap = new Map<Id, RecentlyViewed>([SELECT Id
                                                                                     FROM RecentlyViewed
                                                                                     WHERE Type = :((String)jsonMap.get('object'))]);
            List<Id> idList = new List<Id>(recentlyViewedMap.keySet());

            if (idList.size() > 0) {
                String filter = 'Id IN (\'' + String.join(idList, '\',\'') + '\')';

                if (InputlookupAPXCtrl.fieldNotEmpty(jsonMap, 'filter')) {
                    filter += ' AND (' + jsonMap.get('filter') + ')';
                }

                jsonMap.put('filter', filter);

                responseData.results = InputlookupAPXCtrl.getData(jsonMap);
            } else {
                responseData.results = new Map<String, Object>{
                    'data' => new List<String>(),
                    'searchTerm' => ''
                };
            }
        } catch (Exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'InputLookupAPXCtrl','Method__c'=>'getRecentRecords'});
            responseData.addError(e.getMessage());
            
        }

        return responseData.getJsonString();
    }

    @AuraEnabled
    public static String getRecordLabel(String jsonString) {
        LookupResponseData responseData = new LookupResponseData();

        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);

            String obj = (String)jsonMap.get('object');
            String objectLabel = Schema.describeSObjects(new List<String>{obj})[0].getLabel();

            responseData.results.put('objectLabel', objectLabel);
        } catch (Exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'InputLookupAPXCtrl','Method__c'=>'getRecordLabel'});
            responseData.addError(e.getMessage());
        }

        return responseData.getJsonString();
    }

    @AuraEnabled
    public static String getRecords(String jsonString) {
        LookupResponseData responseData = new LookupResponseData();

        
        try {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
            system.debug('jsonMap----'+jsonMap);
            responseData.results = InputlookupAPXCtrl.getData(jsonMap);
        } catch (Exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'InputLookupAPXCtrl','Method__c'=>'getRecords'});
            responseData.addError(e.getMessage());
        }

        return responseData.getJsonString();
    }

    private static Map<String, Object> getData(Map<String, Object> jsonMap) {
        List<Map<String, Object>> data = new List<Map<String, Object>>();

        String objType = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String query = InputlookupAPXCtrl.getQuery(jsonMap);
        String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
        String searchTerm = '';
        String subtitleField;

        if (InputlookupAPXCtrl.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
        }

        if (InputlookupAPXCtrl.fieldNotEmpty(jsonMap, 'searchTerm')) {
            searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
        }
        system.debug('subtitleField---'+subtitleField+'-query--'+query);
       
        string finQuery=String.escapeSingleQuotes(query);
       
        finQuery=finQuery.remove('\\');
        if (String.isEmpty(subtitleField)) {
            for (sObject obj : Database.query(finQuery)) {
                data.add(new Map<String, Object>{
                    'label' => InputLookupAPXCtrl.getValue(obj, objType, searchField),
                    'value' => obj.get('Id')
                });
            }
        } else {
            for (sObject obj : Database.query(finQuery)) {
                data.add(new Map<String, Object>{
                    'label' => InputLookupAPXCtrl.getValue(obj, objType, searchField),
                    'sublabel' => InputLookupAPXCtrl.getValue(obj, objType, subtitleField),
                    'value' => obj.get('Id')
                });
            }
        }
        
        system.debug('data records-->'+data);
        if(data.isEmpty()){
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'InputLookupAPXCtrl';
            xLog.Method__c = 'getData';
            xLog.Exception_Message__c = 'Exception occured with query: '+query;    
            ExceptionLoggingServices.captureExceptionLog(xLog);
        }

        return new Map<String, Object>{
                   'data' => data,
                   'searchTerm' => searchTerm
        };
    }

    private static String getQuery(Map<String, Object> jsonMap) {
        Set<String> queryFields = new Set<String>{'Id'};
        List<String> filters = new List<String>();
        List<String> orders = new List<String>();

        String query;
        String obj = String.escapeSingleQuotes((String)jsonMap.get('object'));
        String subtitleField;

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'subtitleField')) {
            subtitleField = String.escapeSingleQuotes((String)jsonMap.get('subtitleField'));
            queryFields.add(subtitleField);
        }

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'searchField')) {
            queryFields.add(String.escapeSingleQuotes((String)jsonMap.get('searchField')));

            if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'searchTerm')) {
                String searchField = String.escapeSingleQuotes((String)jsonMap.get('searchField'));
                String searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));

                filters.add(searchField + ' LIKE \'' + searchTerm + '%\'');
            }
        }
        if(InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'alternateSearchField') || InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'secondarySearchField')){
        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'alternateSearchField')) {
            queryFields.add(String.escapeSingleQuotes((String)jsonMap.get('alternateSearchField')));			
            if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'searchTerm')) {
                String alternateSearchField = String.escapeSingleQuotes((String)jsonMap.get('alternateSearchField'));
                String searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
                filters.add(alternateSearchField + ' LIKE \'' + searchTerm + '%\'');
            }
        }
        
        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'secondarySearchField')) {
            queryFields.add(String.escapeSingleQuotes((String)jsonMap.get('secondarySearchField')));
            if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'searchTerm')) {
                String secondarySearchField = String.escapeSingleQuotes((String)jsonMap.get('secondarySearchField'));
                String searchTerm = String.escapeSingleQuotes((String)jsonMap.get('searchTerm'));
                List<String> searchList=searchTerm.split(' ',2);
                String LastN='NAM_LAST__c';
                String fName='';
                String lName='';
                if(searchList.size()>=2){
                    fName=searchList.get(0);
                    lName=searchList.get(1);
                    if(fName==''){
                        filters.add(secondarySearchField + ' LIKE \'' + searchTerm + '%\'');
                    }else{
                    	filters.add('('+secondarySearchField + ' LIKE \'' + fName + '%\''+ ' AND '+LastN + ' LIKE \'' + lName + '%\''+')');
                	}
                }else{
                    filters.add(secondarySearchField + ' LIKE \'' + searchTerm + '%\'');
                }
            }
        }

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'filter')) {
            filters.add('(' + (String)jsonMap.get('filter') + ')');
        }

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'order')) {
            orders.add(String.escapeSingleQuotes((String)jsonMap.get('order')));
        }

        query = 'SELECT ' + String.join(new List<String>(queryFields), ', ');
        query += ' FROM ' + obj;

        if (filters.size() > 0) {
            query += ' WHERE ' + String.join(filters, ' OR ');
        }

        if (orders.size() > 0) {
            query += ' ORDER BY ' + String.join(orders, ', ');
        }

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'limit')) {
            query += ' LIMIT ' + String.escapeSingleQuotes((String)jsonMap.get('limit'));
        }
        }else{
        	    
            if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'filter')) {
            filters.add('(' + (String)jsonMap.get('filter') + ')');
        }

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'order')) {
            orders.add(String.escapeSingleQuotes((String)jsonMap.get('order')));
        }

        query = 'SELECT ' + String.join(new List<String>(queryFields), ', ');
        query += ' FROM ' + obj;

        if (filters.size() > 0) {
            query += ' WHERE ' + String.join(filters, ' AND ');
        }

        if (orders.size() > 0) {
            query += ' ORDER BY ' + String.join(orders, ', ');
        }

        if (InputLookupAPXCtrl.fieldNotEmpty(jsonMap, 'limit')) {
            query += ' LIMIT ' + String.escapeSingleQuotes((String)jsonMap.get('limit'));
        }
        }

        return query;
    }

    private static Boolean fieldNotEmpty(Map<String, Object> jsonMap, String field) {
        return jsonMap.containsKey(field) && !String.isEmpty((String)jsonMap.get(field));
    }

    private static String getValue(SObject obj, String objectType, String field) {
        List<String> fieldPath = field.split('[.]');
        Object label = LookupUtilities.convertObjectToMap(obj);
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap();
		Schema.DescribeFieldResult fieldDescribe;
        String fieldType;
        for (String fieldName : fieldPath) {
            fieldName = fieldName.replaceAll('__r$', '__c');

            label = ((Map<String, Object>)label).get(fieldName);

            if (label == null) {
                return '';
            }

            if (fieldMap.containsKey(fieldName + 'Id')) {
                fieldName = fieldName + 'Id';
            }

            fieldDescribe = fieldMap.get(fieldName).getDescribe();
            fieldType = String.valueOf(fieldDescribe.getType()).toUpperCase();

            if (fieldType == 'REFERENCE') {
                fieldMap = Schema.getGlobalDescribe().get(String.valueOf(fieldDescribe.getReferenceTo().get(0))).getDescribe().fields.getMap();
            } else if (fieldType == 'ADDRESS') {
                List<String> addressComponents = new List<String>();
                Map<String, Object> addr = (Map<String, Object>)label;

                if (addr.containsKey('street') && addr.get('street') != null) {
                    addressComponents.add((String)addr.get('street'));
                }

                if (addr.containsKey('city') && addr.get('city') != null) {
                    addressComponents.add((String)addr.get('city'));
                }

                if (addr.containsKey('state') && addr.get('state') != null) {
                    addressComponents.add((String)addr.get('state'));
                }

                if (addr.containsKey('country') && addr.get('country') != null) {
                    addressComponents.add((String)addr.get('country'));
                }

                if (addr.containsKey('postalCode') &&addr.get('postalCode') != null) {
                    addressComponents.add((String)addr.get('postalCode'));
                }

                // change later for user formatting?
                label = String.join(addressComponents, ', ');
            }
        }

        return String.valueOf(label);
    }
}