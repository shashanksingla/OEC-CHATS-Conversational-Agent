public without Sharing class GenericWithoutSharingDMLOperations {
    private static List<id> recordsIdsToBeDeleted = new List<id>();
    private static List<id> childIdsToBeDeleted = new List<id>();
    
    public static void insertRecords(List<SObject> lstRecords, Map<String,Object> methodInfo){
        if(lstRecords != null && !lstRecords.isEmpty()){
            try{
                insert lstRecords;
            }catch(Exception ex){
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    public static void setRecordsIdsToBeDeleted(List<Id> recordIds){
        Set<String> allowObjectDeletionSet = new Set<String>();
        for(String allowObjectDeletion: System.Label.ALLOW_OBJECT_DELETION.split(';')){
            allowObjectDeletionSet.add(allowObjectDeletion);
        }
        String recordIdStr =  null;
        for(Id recordId:recordIds){
            recordIdStr = String.valueOf(recordId);
            if(allowObjectDeletionSet.contains(String.valueOf(recordId.getSObjectType())) && recordIdStr==String.escapeSingleQuotes(recordIdStr)){
                recordsIdsToBeDeleted.add(recordId);
            }
        }
    }
    
    public static void deleteRecords(Map<String,Object> methodInfo){
        if(recordsIdsToBeDeleted != null && !recordsIdsToBeDeleted.isEmpty()){
            try{
                Database.delete(recordsIdsToBeDeleted, true);
                recordsIdsToBeDeleted.clear();
            }catch(Exception ex){
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    
    public static void setChildIdsToBeDeleted(List<Id> recordIds){
        Set<String> allowObjectDeletionSet = new Set<String>();
        for(String allowObjectDeletion: System.Label.ALLOW_OBJECT_DELETION.split(';')){
            allowObjectDeletionSet.add(allowObjectDeletion);
        }
        String recordIdStr =  null;
        for(Id recordId:recordIds){
            recordIdStr = String.valueOf(recordId);
            if(allowObjectDeletionSet.contains(String.valueOf(recordId.getSObjectType())) && recordIdStr==String.escapeSingleQuotes(recordIdStr)){
                childIdsToBeDeleted.add(recordId);
            }
        }
    }
    
    public static void deleteChildRecords(Map<String,Object> methodInfo){
        if(childIdsToBeDeleted != null && !childIdsToBeDeleted.isEmpty()){
            try{
                Database.delete(childIdsToBeDeleted, true);
                childIdsToBeDeleted.clear();
            }catch(Exception ex){
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    
    public static void updateRecords(List<SObject> lstRecords, Map<String,Object> methodInfo){
        if(lstRecords != null && !lstRecords.isEmpty()){
            try{
                update lstRecords;
            }catch(Exception ex){
                ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
                throw ex;
            }
        }
    }
    public static LightningServerResponse deleteJunkRecordsByIds(List<Id> idsToBeDeleted) {
        if(idsToBeDeleted!=null && !idsToBeDeleted.isEmpty()) {
            Database.delete(idsToBeDeleted, false);
        }
        return new LightningServerResponse(true, 'Records has been deleted successfully', null);
    }
}