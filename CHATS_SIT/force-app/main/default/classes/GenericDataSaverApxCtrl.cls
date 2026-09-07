public with sharing class GenericDataSaverApxCtrl implements IRequest{
    public String jsonParam;
    private static Map<String, Object > requestObj;
    
    private static String getMapValue(String fieldName) {
        return (String)requestObj.get(fieldName);
    }
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }      
        if (methodName == 'upsertRecordsFinal') {
            List<Object> rawList = (List<Object>)requestObj.get('lstSObject');
            String sObjJson = JSON.serialize(rawList);
            List<SObject> sObjList = (List<SObject>)JSON.deserialize(sObjJson, List<SObject>.class);
            response = upsertRecordsFinal(sObjList, (Boolean)requestObj.get('isFinalStep'));
        } else if (methodName == 'logException') {
            Object xLogObj = requestObj.get('xLog');
            if(xLogObj != null) {
                String xLogJson = JSON.serialize(xLogObj);
                Exception_Log__c xLog = (Exception_Log__c)JSON.deserialize(xLogJson, Exception_Log__c.class);
                logException(xLog);
            }
            response = null;
        } else if(methodName == 'upsertRecordAuth'){
            Boolean isBeginDateValid = requestObj.get('isBeginDateValid') != null ? (Boolean)requestObj.get('isBeginDateValid') : true;
            List<T_AUTH__c> listAuthRec = 
                (List<T_AUTH__c>)JSON.deserialize(JSON.serialize(requestObj.get('lstSObject')), List<T_AUTH__c>.class);
            response = upsertRecordAuth(listAuthRec, getMapValue('lastDay'), isBeginDateValid);
        } else if(methodName == 'deleteJunkRecords'){
            List<Object> rawList = (List<Object>)requestObj.get('recordsToBeDeleted');
            String sObjJson = JSON.serialize(rawList);
            List<SObject> sObjList = (List<SObject>)JSON.deserialize(sObjJson, List<SObject>.class);
            response = deleteJunkRecords(sObjList);
        } else if(methodName == 'deleteJunkRecordsByIds'){
            List<Object> rawList = (List<Object>)requestObj.get('idsToBeDeleted');
            String sObjJson = JSON.serialize(rawList);
            List<Id> idList = (List<Id>)JSON.deserialize(sObjJson, List<Id>.class);
            response = deleteJunkRecordsByIds(idList);
        } else if(methodName == 'insertExternalObjRecords'){
            List<SObject> sObjList = (List<SObject>)JSON.deserialize((String)requestObj.get('lstSObject'), List<SObject>.class);
            response = insertExternalObjRecords(sObjList,(Boolean)requestObj.get('isFinalStep'));
        } else if(methodName == 'updateExternalObjRecords'){
            List<Object> rawList = (List<Object>)requestObj.get('lstSObject');
            String sObjJson = JSON.serialize(rawList);
            List<SObject> sObjList = (List<SObject>)JSON.deserialize(sObjJson, List<SObject>.class);
            response = updateExternalObjRecords(sObjList, (Boolean)requestObj.get('isFinalStep'));
        } else if(methodName == 'upsertRecords'){
            List<Object> rawList = (List<Object>)requestObj.get('lstSObject');
            String sObjJson = JSON.serialize(rawList);
            List<SObject> sObjList = (List<SObject>)JSON.deserialize(sObjJson, List<SObject>.class);
            response = upsertRecords(sObjList);
        } else if(methodName == 'deleteRecords'){
            List<Object> rawList = (List<Object>)requestObj.get('deleteObjects');
            String sObjJson = JSON.serialize(rawList);
            List<SObject> sObjList = (List<SObject>)JSON.deserialize(sObjJson, List<SObject>.class);
            LightningServerResponse lsr = new LightningServerResponse(true,'Records deleted successfully.',null);
            deleteRecords(sObjList);
            response = lsr;
        }
        return response;
    }
    
    //Method(Internal): should be used in final/finish button logic on each flow
    @auraEnabled
    public static LightningServerResponse upsertRecordsFinal(List<SObject> lstSObject, Boolean isFinalStep){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<APXFieldValidationError> lstAPXFieldValidationError; 
        List<SObject> lstRecordsToBeInserted = new List<SObject>(); 
        List<SObject> lstRecordsToBeUpdated = new List<SObject>();
        for(SObject sOb:lstSObject){
            if(String.isNotBlank(sOb.Id)){
                lstRecordsToBeUpdated.add(sOb);
            }else{
                lstRecordsToBeInserted.add(sOb);
            }
        }	
        
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        lstSaveResult.addAll(Database.insert(lstRecordsToBeInserted, false));
        lstSaveResult.addAll(Database.update(lstRecordsToBeUpdated, false));
        lstRecordsToBeUpdated.addAll(lstRecordsToBeInserted);
        lstAPXFieldValidationError = CrudResponseApxCtrl.getCrudResponseFromSaveResults(lstRecordsToBeUpdated, lstSaveResult);
        if(lstAPXFieldValidationError.isEmpty()){
            objectData.put('upsertedRecords',lstRecordsToBeUpdated);
            message = 'Record has been successfully updated.';
            isSuccessful = true;
            if(isFinalStep){
                JunkRecordServices.deleteJunkRecordsByRecords(lstRecordsToBeUpdated, false);
            }else{
                JunkRecordServices.insertJunkRecords(lstRecordsToBeInserted);
            }
        }else{
            objectData.put('upsertedRecords',lstRecordsToBeUpdated);
            message = 'There are errors on this page. Please correct them to proceed.';
            isSuccessful = false;
            // Rollback to the savepoint
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(lstSaveResult, lstRecordsToBeUpdated, new Map<String,Object>{'Class__c'=>'GenericDataSaverApxCtrl','Method__c'=>'upsertRecordsFinal'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData,lstAPXFieldValidationError);
    }
    
    //Method(Internal): should be used in all the steps except final/finish button logic on each flow
    @auraEnabled
    public static LightningServerResponse upsertRecords(List<SObject> lstSObject){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<APXFieldValidationError> lstAPXFieldValidationError; 
        List<SObject> lstRecordsToBeInserted = new List<SObject>();
        List<SObject> lstRecordsToBeUpdated = new List<SObject>();
        system.debug('Inside Upsert');
        for(SObject sOb:lstSObject){
            if(String.isNotBlank(sOb.Id)){
                lstRecordsToBeUpdated.add(sOb);
            }else{
                lstRecordsToBeInserted.add(sOb);
            }
        }	
        system.debug('lstRecordsToBeInserted----'+lstRecordsToBeInserted);
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        lstSaveResult.addAll(Database.insert(lstRecordsToBeInserted, false));
        lstSaveResult.addAll(Database.update(lstRecordsToBeUpdated, false));
        system.debug('lstSaveResult----'+lstSaveResult);
        lstRecordsToBeUpdated.addAll(lstRecordsToBeInserted);
        lstAPXFieldValidationError = CrudResponseApxCtrl.getCrudResponseFromSaveResults(lstRecordsToBeUpdated, lstSaveResult);
        system.debug('lstAPXFieldValidationError----'+lstAPXFieldValidationError);
        if(lstAPXFieldValidationError.isEmpty()){
            objectData.put('upsertedRecords',lstRecordsToBeUpdated);
            message = 'Record has been successfully updated.';
            isSuccessful = true;
            JunkRecordServices.insertJunkRecords(lstRecordsToBeInserted);
        }else{
            objectData.put('upsertedRecords',lstRecordsToBeUpdated);
            message = 'There are errors on this page. Please correct them to proceed.';
            isSuccessful = false;
            // Rollback to the savepoint
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(lstSaveResult, lstRecordsToBeUpdated, new Map<String,Object>{'Class__c'=>'GenericDataSaverApxCtrl','Method__c'=>'upsertRecords'});
        }
        LightningServerResponse lsr = new LightningServerResponse(isSuccessful,message,objectData,lstAPXFieldValidationError);
        return lsr;
    }
    
    @auraEnabled
    public static LightningServerResponse upsertRecordAuth(List<T_AUTH__c> lstSObject, String lastDay, Boolean isBeginDateValid){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<APXFieldValidationError> lstAPXFieldValidationError; 
        List<T_AUTH__c> lstRecordsToBeInserted = new List<T_AUTH__c>();
        List<T_AUTH__c> lstRecordsToBeUpdated = new List<T_AUTH__c>();
        List<T_AUTH__c> authUpdateList = new List<T_AUTH__c>();
        for(T_AUTH__c sOb:lstSObject){
            if(!String.isBlank(lastDay)){
                List<String> dateParts = new List<String>();
                dateParts= lastDay.split('-');
                Date endDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                sOb.DTE_END_EFFV_AUTH__c = endDate;
            }
            if(String.isNotBlank(sOb.Id)){
                if(Schema.sObjectType.T_AUTH__c.isUpdateable()) {
                lstRecordsToBeUpdated.add(sOb);
                }
            }else{
                if(Schema.sObjectType.T_AUTH__c.isCreateable()) {
                lstRecordsToBeInserted.add(sOb);
                authUpdateList.add(sOb);
                }
            }
        }   
        LightningServerResponse lsr ;
        if(isBeginDateValid){
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        lstSaveResult.addAll(Database.insert(authUpdateList, false));
        lstSaveResult.addAll(Database.update(lstRecordsToBeUpdated, false));
        lstRecordsToBeUpdated.addAll(authUpdateList);
        lstAPXFieldValidationError = CrudResponseApxCtrl.getCrudResponseFromSaveResults(lstRecordsToBeUpdated, lstSaveResult);
        if(lstAPXFieldValidationError.isEmpty()){
            objectData.put('upsertedRecords',lstRecordsToBeUpdated);
            message = 'Record has been successfully updated.';
            isSuccessful = true;
            JunkRecordServices.insertJunkRecords(authUpdateList);
        }else{
            objectData.put('upsertedRecords',lstRecordsToBeUpdated);
            message = 'There are errors on this page. Please correct them to proceed.';
            isSuccessful = false;
            // Rollback to the savepoint
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(lstSaveResult, lstRecordsToBeUpdated, new Map<String,Object>{'Class__c'=>'GenericDataSaverApxCtrl','Method__c'=>'upsertRecordsAuth'});
        }
        lsr = new LightningServerResponse(isSuccessful,message,objectData,lstAPXFieldValidationError);
        }
        else{
            objectData.put('message','Authorization begin date cannot be after redetermination month');
            message = 'Authorization begin date cannot be after redetermination month';
            isSuccessful = false;
            lsr = new LightningServerResponse(isSuccessful,message,objectData);
        }
        return lsr;
    }
    
    //Method(External): should be used in all the steps except final/finish button logic on each flow
    @AuraEnabled
    public static LightningServerResponse insertExternalObjRecords(List<SObject> lstSObject, Boolean isFinalStep){
        //  Savepoint sp = Database.setSavepoint();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message, recordToBeRedirected;
        List<APXFieldValidationError> lstAPXFieldValidationError; 
        List<SObject> lstRecordsToBeInserted = new List<SObject>();
        List<SObject> lstRecordsToBeUpdated = new List<SObject>();
        system.debug('Inside insert----'+lstSObject);
        for(SObject sOb:lstSObject){
            if(String.isNotBlank(sOb.Id)){
                lstRecordsToBeUpdated.add(sOb);
            }else{
                lstRecordsToBeInserted.add(sOb);
            }
        }   
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        if(!test.isRunningtest()){
            lstSaveResult.addAll(Database.insertImmediate(lstRecordsToBeInserted));
            lstSaveResult.addAll(Database.updateImmediate(lstRecordsToBeUpdated));
            
        }
        system.debug('');
        lstRecordsToBeUpdated.addAll(lstRecordsToBeInserted);
	    if(lstRecordsToBeUpdated.size() == 1){
            recordToBeRedirected = lstRecordsToBeUpdated.get(0).Id;
        }
        lstAPXFieldValidationError = CrudResponseApxCtrl.getCrudResponseFromSaveResults(lstRecordsToBeUpdated, lstSaveResult);
        if(lstAPXFieldValidationError.isEmpty()){
            objectData.put('insertRecords',lstRecordsToBeUpdated);
	    objectData.put('recordToBeRedirected',recordToBeRedirected);
            message = 'Record has been successfully inserted.';
            isSuccessful = true;
        }else{
            objectData.put('insertRecords',lstRecordsToBeUpdated);
            message = 'There are errors on this page. Please correct them to proceed.';
            isSuccessful = false;
            // Rollback to the savepoint
            //Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(lstSaveResult, lstRecordsToBeUpdated, new Map<String,Object>{'Class__c'=>'GenericDataSaverApxCtrl','Method__c'=>'insertExternalObjRecords'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData,lstAPXFieldValidationError);
    } 
    
    @AuraEnabled
    public static LightningServerResponse updateExternalObjRecords(List<SObject> lstSObject, Boolean isFinalStep){
        //  Savepoint sp = Database.setSavepoint();
        batchsit_t_sbsd_case_cmt__x t = new batchsit_t_sbsd_case_cmt__x();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<APXFieldValidationError> lstAPXFieldValidationError = new List<APXFieldValidationError>(); 
        List<SObject> lstRecordsToBeUpdated = new List<SObject>();
        system.debug('Inside insert----'+lstSObject);
        if(lstSObject.size()>0){
            lstRecordsToBeUpdated.addAll(lstSObject);
        }	
        System.debug(lstRecordsToBeUpdated);
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        if(!test.isRunningTest()){
	        lstSaveResult.addAll(Database.updateImmediate(lstRecordsToBeUpdated));
    	    lstAPXFieldValidationError = CrudResponseApxCtrl.getCrudResponseFromSaveResults(lstRecordsToBeUpdated, lstSaveResult);    
        }
        if(lstAPXFieldValidationError.isEmpty()){
            objectData.put('updateRecords',lstRecordsToBeUpdated);
            message = 'Record has been successfully inserted.';
            isSuccessful = true;
        }else{
            objectData.put('updateRecords',lstRecordsToBeUpdated);
            message = 'There are errors on this page. Please correct them to proceed.';
            isSuccessful = false;
            ExceptionLoggingServices.captureExceptionLog(lstSaveResult, lstRecordsToBeUpdated, new Map<String,Object>{'Class__c'=>'GenericDataSaverApxCtrl','Method__c'=>'updateExternalObjRecords'});
            // Rollback to the savepoint
            //Database.rollback(sp);
        }
        return new LightningServerResponse(isSuccessful,message,objectData,lstAPXFieldValidationError);
    }
    
    @AuraEnabled
    public static void deleteRecords(List<SObject> deleteObjects) {
        if(deleteObjects.size()>0) {
            try{
                delete deleteObjects;    
            }
            catch(Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'GenericDataSaverApxCtrl','Method__c'=>'deleteRecords'});
                System.debug(ex.getMessage());
            }   
        }
    }
    
     @AuraEnabled
    public static LightningServerResponse deleteJunkRecordsByIds(List<Id> idsToBeDeleted) {
        if(idsToBeDeleted.size()>0) {
            Database.delete(idsToBeDeleted, false);
        }
        return new LightningServerResponse(true, 'Records has been deleted successfully', null);
    }
    
    @AuraEnabled
    public static LightningServerResponse deleteJunkRecords(List<SObject> recordsToBeDeleted) {
        if(recordsToBeDeleted.size()>0) {
            System.debug('recordsToBeDeleted:'+recordsToBeDeleted);
            List<Id> individualIds = new List<Id>();
            for(SObject sOb:recordsToBeDeleted){
                System.debug('sOb:'+sOb);
                if(sOb.get('Id')!=null){
                    System.debug('sObId:'+sOb.get('Id'));
                    Id recordId = (Id)sOb.get('Id');
                    System.debug('recordId:'+recordId);
                    System.debug('sobjectype:'+recordId.getSObjectType());
                    if(String.valueOf(recordId.getSObjectType())=='T_SBSD_INDIV__c'){
                        individualIds.add(recordId);
                    }
                }
            }            
            List<Id> IdsToBeDeleted = new List<Id>();
            //extra logic to handle individual & its children
            for(T_SBSD_INDIV__c individual:[SELECT Id,(SELECT Id FROM Case_Individual__r),
                                            (SELECT Id FROM T_SBSD_INDIV26__r),
                                            (SELECT Id FROM Individual_Information__r)
                                            FROM T_SBSD_INDIV__c WHERE Id IN:individualIds]){
                                                for(T_SBSD_CASE_INDIV__c caseIndiv:individual.Case_Individual__r){
                                                    IdsToBeDeleted.add(caseIndiv.Id);    
                                                }
                                                for(T_SBSD_INDIV_MIL__c milStatus:individual.T_SBSD_INDIV26__r){
                                                    IdsToBeDeleted.add(milStatus.Id);    
                                                }
                                                for(T_SBSD_INDIV_INFO__c indivInfo:individual.Individual_Information__r){
                                                    IdsToBeDeleted.add(indivInfo.Id);    
                                                }
                                            }
            for(T_INDIV_VERIF__c indivVerif:[SELECT Id FROM T_INDIV_VERIF__c WHERE IDN_CLIENT__c IN :IdsToBeDeleted]){
                IdsToBeDeleted.add(indivVerif.Id);
            }        
            Database.delete(recordsToBeDeleted, false);
            System.debug('IdsToBeDeleted:'+IdsToBeDeleted);
            if(!IdsToBeDeleted.isEmpty()){
                List<Database.DeleteResult> deleteResultForIndividuals = Database.delete(IdsToBeDeleted, false);
                System.debug('deleteResultForIndividuals:'+deleteResultForIndividuals);
            }
        }
        return new LightningServerResponse(true, 'Records has been deleted successfully', null);
    }
    
    @AuraEnabled
    public static void logException(Exception_Log__c xLog){
        if(xLog!=null){
			ExceptionLoggingServices.captureExceptionLog(xLog);
        }
    }
    
}