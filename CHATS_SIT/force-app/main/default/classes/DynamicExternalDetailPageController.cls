/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           06/25/2018
*  @description
*
*  * Version: 1.0
*  * Date: 25-Jun-2018
*  * Author:
*  * Description: Initial version
*  * JIRA Ticket:
*  *
*  * *************************************Modification Log***************************************
*  * *********	Date	*********	Name	*********	Reason	******************************
*  * *********	8/6/18	*********	Caleb K	*********	Added error handling/returning functionality to fetchRelatedObjectdata method
*********************************************************************************************/
public with sharing class DynamicExternalDetailPageController {
	public static Map<String,Map<String,String>> masterPicklistMap = new Map<String,Map<String,String>>();
    // This method will return selected record picklist field and date field defintion along with field value
    @AuraEnabled
    public static List<externalObjectDefinition.fieldDefinition> fetchObjectdata(String recordId,List<String> listOfFieldsApiNames, List<String> pickListTypeFields){
        List<externalObjectDefinition.fieldDefinition> fldDefValues= new List<externalObjectDefinition.fieldDefinition>();
        List<Sobject> result = new List<Sobject>();
        if(!String.isBlank(recordId)){

            // Get object name from record id
            String SobjectName = CHATSAuraUtility.getSobjectName(recordId);

            // Get All fields
            Map<String, Schema.SObjectField> fieldMap = getFieldObject(SobjectName);

            Map<String,Object> objectData = new Map<String,Object>();
            String queryString ='Select Id ';
            system.debug('listOfFieldsApiNames---'+listOfFieldsApiNames);
            if(listOfFieldsApiNames.size()>0){
                for(String fld : listOfFieldsApiNames){
                    if(!String.isBlank(fld)){
                        queryString = queryString+ ' , '+String.escapeSingleQuotes(fld);
                    }
                }
            }
            // Split picklist field api with picklist field api in Field Utility Object.
            for(String picklstFld : pickListTypeFields){
                if(!String.isBlank(picklstFld)){
                    String[] fieldNameWithPickListInfo = picklstFld.split(',');
                    String fieldValue = fieldNameWithPickListInfo[0];
                    queryString = queryString+ ' , '+String.escapeSingleQuotes(fieldValue);
                }
            }
            queryString =queryString+ ' FROM '+ SobjectName+' WHERE Id =: recordId';
            result = DataBase.query(queryString);
            for(String picklstFld : pickListTypeFields){
                if(!String.isBlank(picklstFld)){
                    String[] fieldNameWithPickListInfo = picklstFld.split(',');
                    String fieldValue;
                    if(fieldNameWithPickListInfo.size()>2){
                        if(result.size()>0){
                            fieldValue=  String.valueOf(result[0].get(fieldNameWithPickListInfo[0]));
                        }
                        String fieldPickListName = fieldNameWithPickListInfo[1];
                        String masterPickListObj = fieldNameWithPickListInfo[2];
                        if(!String.isBlank(fieldNameWithPickListInfo[0])){
                            // Retrieving picklist map from Field Utility object
                            Map<String,String> pickListMap =new  Map<String,String>();
                            if(!String.isBlank(fieldPickListName)){
                                pickListMap =getPickListValue(masterPickListObj,fieldPickListName);
                            }
                            externalObjectDefinition.fieldDefinition fldDefValue = new externalObjectDefinition.fieldDefinition();
                            fldDefValue.fieldAPIName = fieldNameWithPickListInfo[0];
                            if(!String.isBlank(fieldValue)){
                                if(pickListMap.containsKey(fieldValue)){
                                    fldDefValue.fieldValue = pickListMap.get(fieldValue);
                                }
                            }else{
                                fldDefValue.fieldValue ='';
                            }
                            fldDefValue.fieldLabel = fieldMap.get(fieldNameWithPickListInfo[0]).getDescribe().getLabel();
                            fldDefValue.dataType = 'PickList' ;
                            fldDefValues.add(fldDefValue);
                        }
                    }
                }
            }
            for(String fldApi : listOfFieldsApiNames){
                if(!String.isBlank(fldApi)){
                    externalObjectDefinition.fieldDefinition fldDefValue1 = new externalObjectDefinition.fieldDefinition();
                    fldDefValue1.fieldAPIName = fldApi;
                    fldDefValue1.dataType = String.valueOf(fieldMap.get(fldApi).getDescribe().getType()) ;
                    if(fldDefValue1.dataType =='Date'){
                        fldDefValue1.fieldValueDate = Date.valueOf(result[0].get(fldApi));
                    }else if(fldDefValue1.dataType =='DateTime'){
                       fldDefValue1.fieldValueDateTime = DateTime.valueOf(result[0].get(fldApi)); 
                    }
                    else{
                        fldDefValue1.fieldValue = String.valueOf(result[0].get(fldApi));
                    }
                    fldDefValue1.fieldLabel = fieldMap.get(fldApi).getDescribe().getLabel();
                    fldDefValues.add(fldDefValue1);
                }
            }
        }
        return fldDefValues;
    }
    public static Map<String,String> getPickListValue(String objName, String FieldName){
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(objName);
        Map<String,String> options = new Map<String,String>();
        // Schema.sObjectType objType = sobjType.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = sobjType.getDescribe();
        Map<String, Schema.SObjectField> field_map = objDescribe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(FieldName).getDescribe().getPickListValues();

        for( Schema.PicklistEntry f : pick_list_values){
            options.put(f.getValue(), f.getLabel());
        }
        return options;
    }
    @AuraEnabled
    public static List<externalObjectDefinition> fetchRelatedObjectdata(String recordId, String FieldsApiNames, List<String> pickListTypeFields , String childApiName, String parentObjIdentifier, String orderByField, String recordsLimit, String sortAscDsc){
        List<externalObjectDefinition> fldDefValues= new List<externalObjectDefinition>();
        List<SObject> lstRelatedRecords = new List<SObject>();
        Map<String, String> pickListApiNameMap = new Map<String, String>();
        Map<String, String> masterPickListApiNameMap = new Map<String, String>();
        String parentId;
        try{
            String externalIdFieldName, parentQuery;
            String SobjectName = CHATSAuraUtility.getSobjectName(recordId);
            if(SobjectName == 'batchsit_t_sbsd_case_cmt__x'){
                batchsit_t_sbsd_case_cmt__x caseCmtRecord =[select id,createdbyid__c,idn_case__c from batchsit_t_sbsd_case_cmt__x where id=:recordId limit 1 ];
                if(caseCmtRecord != null){
                    parentQuery = 'Select id,Name,IDN_EXTNL__c from T_SBSD_CASE__c where IDN_EXTNL__c = \''+String.escapeSingleQuotes(caseCmtRecord.idn_case__c)+'\' limit 1';
                }
            } else {
                parentQuery = 'SELECT '+String.escapeSingleQuotes(parentObjIdentifier)+' FROM '+String.escapeSingleQuotes(SobjectName)+String.escapeSingleQuotes(' WHERE ID =:recordId');    
            }
            List<SObject> lstParentRecord = DataBase.query(parentQuery);
            if(lstParentRecord.size()>0){
                parentId = String.valueOf(lstParentRecord[0].get(parentObjIdentifier));
            }
            if(String.isNotBlank(parentId)){
            for(String picklstFld : pickListTypeFields){
                String[] fieldNameWithPickListInfo = picklstFld.split(',');
                if(fieldNameWithPickListInfo.size()>2){
                    String fieldPickListName = fieldNameWithPickListInfo[1];
                    String pickListApiNameExternalObj = fieldNameWithPickListInfo[0];
                    String pickListApiName = fieldNameWithPickListInfo[2];
                    pickListApiNameMap.put(pickListApiNameExternalObj, fieldPickListName);
                    masterPickListApiNameMap.put(pickListApiNameExternalObj, pickListApiName);
                }
            }
            String fieldsToBeQueried = getFieldsToBeQueried(childApiName,String.escapeSingleQuotes(FieldsApiNames));
            string lookupField;
            if(SobjectName == 'batchsit_t_sbsd_case_cmt__x'){
                lookupField = getRelationshipFieldWithParentObject(childApiName, 'T_SBSD_CASE__c') ;
            } else {
                lookupField = getRelationshipFieldWithParentObject(childApiName, CHATSAuraUtility.getSobjectName(recordId)) ;
            }
            String query = 'SELECT '+fieldsToBeQueried+' FROM '+String.escapeSingleQuotes(childApiName)+' WHERE '+lookupField+'=\''+String.escapeSingleQuotes(parentId)+'\'';

            if(String.isNotBlank(orderByField) && !String.isEmpty(orderByField.trim() ) && orderByField.trim() != null){
                query += ' ORDER BY '+String.escapeSingleQuotes(orderByField);
                if (!String.isEmpty(sortAscDsc.trim()) && sortAscDsc.trim() != null){
                    query += ' '+String.escapeSingleQuotes(sortAscDsc)+ ' NULLS LAST';
                }
            }
            if (String.isNotBlank(recordsLimit) && recordsLimit.trim() != null && !String.isEmpty(recordsLimit.trim())){
                query += ' LIMIT '+String.escapeSingleQuotes(recordsLimit);
            }
            if(Test.isRunningTest()){
               T_AUTH__c auth = new T_AUTH__c(CDE_IMM__c ='NMD',DTE_END_EFFV_AUTH__c = system.today().addDays(15));
                 T_AUTH__c auth1 = new T_AUTH__c(CDE_IMM__c ='NNW',DTE_END_EFFV_AUTH__c = system.today().addDays(15));
                lstRelatedRecords.add(auth);
                lstRelatedRecords.add(auth1);
            }else{
                lstRelatedRecords = DataBase.query(query);
            }
            Map<String, Schema.SObjectField> fieldMap = getFieldObject(childApiName);
            List<String> listOfFieldsApiNames = FieldsApiNames.split(';');
            Map<String, String> labelMap = new Map<String, String>();
            Map<String, String> dataTypeMap = new Map<String, String>();
            for(String fldApi : listOfFieldsApiNames){
                String labelVal =fieldMap.get(fldApi).getDescribe().getLabel();
                String dataTypeVal =String.valueOf(fieldMap.get(fldApi).getDescribe().getType()) ;
                labelMap.put(fldApi, labelVal);
                dataTypeMap.put(fldApi, dataTypeVal);
            }
            Integer recordCount =0;
            
            for(SObject sobj : lstRelatedRecords){
                List<externalObjectDefinition.fieldDefinition> recordDefValues= new List<externalObjectDefinition.fieldDefinition>();
                externalObjectDefinition extObjWrap = new externalObjectDefinition();

                for(String fldApi : listOfFieldsApiNames){
                    externalObjectDefinition.fieldDefinition fldDefValue1 = new externalObjectDefinition.fieldDefinition();
                    if(pickListApiNameMap.containsKey(fldApi)){
                        if(recordCount >0){
                            fldDefValue1.fieldAPIName = fldApi;
                            fldDefValue1.fieldLabel = fieldMap.get(fldApi).getDescribe().getLabel();
                            fldDefValue1.dataType = 'PickList' ;
                            Map<String,String> picklistMapTemp = new Map<String,String>();
                            picklistMapTemp = masterPicklistMap.get(pickListApiNameMap.get(fldApi));
                            if(String.isNotBlank(String.valueOf(sobj.get(fldApi)))){
                                fldDefValue1.fieldValue  = picklistMapTemp.get(String.valueOf(sobj.get(fldApi)));
                            }else{
                               fldDefValue1.fieldValue =''; 
                            }
                        }else{
                            fldDefValue1=  getPickListRecordDef(fldApi,pickListApiNameMap.get(fldApi),childApiName,String.valueOf(sobj.get(fldApi)),masterPickListApiNameMap.get(fldApi));
                        }
                         }else{
                         	
                        if(childApiName =='batchsit_t_indiv_rat_fees__x'){
                            if( fldApi =='idn_provr__c'){
                                if(dataTypeMap.get(fldApi) == 'REFERENCE'){
                                    String  lookupIdForProvider = String.valueOf(sobj.get(fldApi));
                                    if(String.isNotBlank(lookupIdForProvider)){
                                        
                                        List<T_CHATS_PROVR_STATUS__c> prodList = [Select id from T_CHATS_PROVR_STATUS__c where External_ID__c =:lookupIdForProvider];

                                        if(prodList != null && prodList.size()>0){
                                            String parentSFId =prodList[0].Id;
                                            fldDefValue1.parentRecordId =parentSFId;
                                        }
                                        
                                    }
                                }
                            }
                        }
                         	
                        fldDefValue1.fieldAPIName = fldApi;
                        fldDefValue1.dataType = dataTypeMap.get(fldApi);
                        if(fldDefValue1.dataType =='Date'){
                            fldDefValue1.fieldValueDate = Date.valueOf(sobj.get(fldApi));
                        }else if(fldDefValue1.dataType =='DateTime'){
                            fldDefValue1.fieldValueDateTime = DateTime.valueOf(sobj.get(fldApi));
                        }else{
                            fldDefValue1.fieldValue = String.valueOf(sobj.get(fldApi));
                        }
                        fldDefValue1.fieldLabel = labelMap.get(fldApi);
                    }
                    fldDefValue1.childRecordId =String.valueOf(sobj.get('Id'));
                    recordDefValues.add(fldDefValue1);
                }
                recordCount++;
                extObjWrap.fldDefList =recordDefValues;
                fldDefValues.add(extObjWrap);
            }
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            Map<String,Object> methodInfo = new Map<String,Object>();
            methodInfo.put('Class__c', 'DynamicExternalDetailPageController');
            methodInfo.put('Method__c', 'getPickListValue');
            ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
            if(e.getTypeName().contains('NullPointerException')){
                throw new AuraHandledException('There was a problem acessing external data. Contact your administrator.');
            }else{
                throw e;
            }
        }
        return fldDefValues;
    }
    @AuraEnabled
    public static List<externalObjectDefinition> fetchRelatedObjectdataBasedOnIndex(List<SObject> lstRelatedRecords, Integer startIndex, Integer endIndex, Integer numberOfRecords, String FieldsApiNames, List<String> pickListTypeFields , String childApiName){
        List<externalObjectDefinition> fldDefValues= new List<externalObjectDefinition>();
        List<SObject> lstRelatedRecordsTemp = new List<SObject>();
        Map<String, String> pickListApiNameMap = new Map<String, String>();
        Map<String, String> masterPickListApiNameMap = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = getFieldObject(childApiName);
        List<String> listOfFieldsApiNames = FieldsApiNames.split(';');
        Map<String, String> labelMap = new Map<String, String>();
        Map<String, String> dataTypeMap = new Map<String, String>();
        for(String fldApi : listOfFieldsApiNames){
            String labelVal = fieldMap.get(fldApi).getDescribe().getLabel();
            String dataTypeVal =String.valueOf(fieldMap.get(fldApi).getDescribe().getType()) ;
            labelMap.put(fldApi, labelVal);
            dataTypeMap.put(fldApi, dataTypeVal);
        }
        // lstRelatedRecordsTemp = lstRelatedRecords[start];
        for(Integer i=startIndex; i<= endIndex ;i++){
            lstRelatedRecordsTemp.add(lstRelatedRecords[i]);
        }
        for(SObject sobj : lstRelatedRecordsTemp){
            List<externalObjectDefinition.fieldDefinition> recordDefValues= new List<externalObjectDefinition.fieldDefinition>();
            externalObjectDefinition extObjWrap = new externalObjectDefinition();

            for(String fldApi : listOfFieldsApiNames){
                externalObjectDefinition.fieldDefinition fldDefValue1 = new externalObjectDefinition.fieldDefinition();
                if(pickListApiNameMap.containsKey(fldApi)){
                    fldDefValue1 = getPickListRecordDef(fldApi, pickListApiNameMap.get(fldApi), childApiName, String.valueOf(sobj.get(fldApi)), masterPickListApiNameMap.get(fldApi));
                }else{
                    fldDefValue1.fieldAPIName = fldApi;
                    fldDefValue1.dataType = dataTypeMap.get(fldApi);
                    if(fldDefValue1.dataType =='Date'){
                        fldDefValue1.fieldValueDate = Date.valueOf(sobj.get(fldApi));
                    }else if(fldDefValue1.dataType =='DateTime'){
                        fldDefValue1.fieldValueDateTime = DateTime.valueOf(sobj.get(fldApi));
                    }else{
                        fldDefValue1.fieldValue = String.valueOf(sobj.get(fldApi));
                    }
                    fldDefValue1.fieldLabel = labelMap.get(fldApi);//fieldMap.get(fldApi).getDescribe().getLabel();
                }
                fldDefValue1.childRecordId =String.valueOf(sobj.get('Id'));
                recordDefValues.add(fldDefValue1);
            }
            extObjWrap.fldDefList =recordDefValues;
            fldDefValues.add(extObjWrap);
        }

        return fldDefValues;
    }
    public static Map<String, Schema.SObjectField> getFieldObject(String SobjectName){
        // Get All fields
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType externalSchema = schemaMap.get(SobjectName);
        Map<String, Schema.SObjectField> fieldMap = externalSchema.getDescribe().fields.getMap();
        return fieldMap;
        //end
    }
    // This method is used for returning the Picklist field definition along with value.
    public static externalObjectDefinition.fieldDefinition getPickListRecordDef(String pickListApi, String masterPickListApiName, String SobjectName, String fieldValue, String masterObjName){
        Map<String, Schema.SObjectField> fieldMap = getFieldObject(SobjectName);
        Map<String,String> pickListMap = new  Map<String,String>();
        externalObjectDefinition.fieldDefinition fldDefValue = new externalObjectDefinition.fieldDefinition();
        try{
            if(!String.isBlank(masterPickListApiName)){
                pickListMap =  getPickListValue(masterObjName,masterPickListApiName);
                masterPicklistMap.put(masterPickListApiName, pickListMap);
            }
            fldDefValue.fieldAPIName = pickListApi;
            if(!String.isBlank(fieldValue)){
                if(pickListMap.containsKey(fieldValue)){
                    fldDefValue.fieldValue = pickListMap.get(fieldValue);
                }
            }else{
                fldDefValue.fieldValue ='';
            }
            fldDefValue.fieldLabel = fieldMap.get(pickListApi).getDescribe().getLabel();
            fldDefValue.dataType = 'PickList' ;
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'DynamicExternalDetailPageController','Method__c'=>'getPickListRecordDef'});
        }
        return fldDefValue;
    }
    // This is used for returning relationship field for querying on child object.
    public static String getRelationshipFieldWithParentObject(String childObjName, String parentObjName) {
        String fieldName;
        Map<String,Schema.SObjectField>  fieldSpec = Schema.getGlobalDescribe().get(childObjName).getDescribe().fields.getMap();
        if(fieldSpec.size()>0) {
            for(String eachFieldSpec : fieldSpec.keySet()) {
                if(String.valueOf(fieldSpec.get(eachFieldSpec).getDescribe().getType())=='REFERENCE'
                   && fieldSpec.get(eachFieldSpec).getDescribe().getReferenceTo().get(0).getDescribe().getName()==parentObjName) {
                       fieldName = eachFieldSpec;
                   }
            }
        }
        return fieldName;
    }
    // This method is used for returning fields to query on respective object.
    public static String getFieldsToBeQueried(String childObjectName,String fields){
        Map<String,List<String>> mapObjToReferenceIdFields = new Map<String,List<String>>();
        String fieldsToBeQueried;
        try{
            if(!String.isBlank(fields)){
                List<String> listFields = fields.split(';');
                List<externalObjectDefinition.fieldDefinition> listFieldsToBeDisplayed = getFieldDefinition(childObjectName, listFields);
                for(externalObjectDefinition.fieldDefinition fieldDefinition : getFieldDefinition(childObjectName, listFields)){
                    if(fieldDefinition.dataType == 'REFERENCE'){
                        if(mapObjToReferenceIdFields.containsKey(fieldDefinition.objectName)){
                            mapObjToReferenceIdFields.get(fieldDefinition.objectName).add(fieldDefinition.fieldAPIName);
                        }else{
                            mapObjToReferenceIdFields.put(fieldDefinition.objectName,new List<String>{fieldDefinition.fieldAPIName});
                        }
                    }
                }
                system.debug('mapObjToReferenceIdFields--'+mapObjToReferenceIdFields);
                Map<String,List<String>> mapObjToReferenceNameFields = new  Map<String,List<String>>();
                if(mapObjToReferenceIdFields.size()>0){
                    mapObjToReferenceNameFields =getLookupNameFromId(mapObjToReferenceIdFields);
                }
                fields = fields.replace(';', ',');
                fieldsToBeQueried = fields;
                if(mapObjToReferenceNameFields.size()>0){
                    fieldsToBeQueried = fieldsToBeQueried +' ,'+ String.join(mapObjToReferenceNameFields.get(childObjectName),',');
                }
            }
        }catch(Exception Ex){
            system.debug('Exception In method getFieldsToBeQueried== '+ex.getLineNumber());
        }
        return fieldsToBeQueried;
    }
    public static List<externalObjectDefinition.fieldDefinition> getFieldDefinition(String sObjectName, List<String> fieldAPINames) {
        SObjectType sObjectNameType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String,Schema.SObjectField> sObjectFields = sObjectNameType.getDescribe().fields.getMap();
        List<externalObjectDefinition.fieldDefinition> mapOfObjectToField = new List<externalObjectDefinition.fieldDefinition>();
        try{
            externalObjectDefinition.fieldDefinition fieldInfo;
            for(String eachFieldAPIName : fieldAPINames) {
                Schema.SObjectField field = sObjectFields.get(eachFieldAPIName);
                fieldInfo = new externalObjectDefinition.fieldDefinition();
                fieldInfo.fieldAPIName = eachFieldAPIName;
                fieldInfo.objectName = sObjectName;
                fieldInfo.dataType = String.valueOf(field.getDescribe().getType());
                fieldInfo.fieldLabel = String.valueOf(field.getDescribe().getLabel());
                mapOfObjectToField.add(fieldInfo);
            }
        }catch(Exception Ex){
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'DynamicExternalDetailPageController','Method__c'=>'getFieldDefinition'});
        }
        return mapOfObjectToField;
    }
    public static Map<String,List<String>> getLookupNameFromId(Map<String,List<String>> mapObjToLookupFields){
        Map<String,List<String>> mapObjToLookupFieldNames = new Map<String,List<String>>();
        for(String obj : mapObjToLookupFields.keyset()){
            for(String lookupIdField : mapObjToLookupFields.get(obj)){
                String lookupFieldName = '';
                if(lookupIdField.contains('__c')){
                    lookupFieldName = lookupIdField.removeEnd('c')+'r.Name';

                }else{
                    lookupFieldName = lookupIdField.removeEnd('Id')+'.Name';
                }
                if(!mapObjToLookupFieldNames.containsKey(obj)){
                    mapObjToLookupFieldNames.put(obj,new List<String>{lookupFieldName});
                }else{
                    mapObjToLookupFieldNames.get(obj).add(lookupFieldName);
                }
            }
        }
        return mapObjToLookupFieldNames;
    }
}