public without sharing class JunkRecordServices {
    
    final static set<String> excludedObjects = new set<String>{'T_COUNTY_RATE_AMT__c', 'T_FISCAL_RATE__c', 'T_ADJMT_ADDR__c', 'T_NON_ADJMT_DETAIL__c', 'T_ADJMT_DETAIL__c','T_COUNTY_RATE__c','T_COUNTY_PLAN__c','T_INDIV_VERIF__c','T_SBSD_CASE_INDIV__c','T_SBSD_INDIV_MIL__c','T_SBSD_INDIV_INFO__c'};
        
        public static void deleteJunkRecordsByRecordIds(List<Id> recordId, Boolean deleteOrginalRecords){
            deleteJunkRecords([SELECT Id, Record_ID_To_Be_Deleted__c, Object_API_Name__c FROM Junk_Record__c where Record_ID_To_Be_Deleted__c IN :recordId],deleteOrginalRecords);
        }
    
    public static void deleteJunkRecordsByRecords(List<SObject> records, Boolean deleteOrginalRecords){
        if(!records.isEmpty()){
            List<Id> recordsIdsToBeDeleted = new List<Id>();
            for(SObject record:records){
                recordsIdsToBeDeleted.add(String.valueOf(record.get('Id')));
            }
            deleteJunkRecords([SELECT Id, Record_ID_To_Be_Deleted__c, Object_API_Name__c FROM Junk_Record__c where Record_ID_To_Be_Deleted__c IN :recordsIdsToBeDeleted],deleteOrginalRecords);
        }
    }
    
    public static List<Database.DeleteResult> deleteJunkRecords(List<Junk_Record__c> junkRecordsToBeDeleted, Boolean deleteOrginalRecords){
        Map<String,Decimal> recordIdToOrderOfDeletion = new Map<String,Decimal>();
        set<Id> authorizationIdSet = new set<Id>();
        List<Database.DeleteResult> finalDeleteResults = new List<Database.DeleteResult>();
        for(Junk_Record_Clean_Up_Batch_Configuration__mdt junkRecordMetadata:[SELECT MasterLabel, Order__c FROM Junk_Record_Clean_Up_Batch_Configuration__mdt where MasterLabel!=null and Order__c!=null]){
            recordIdToOrderOfDeletion.put(junkRecordMetadata.MasterLabel, junkRecordMetadata.Order__c);
        }
        Map<Decimal,List<Id>> orderOfDeletionToRecordIds = new Map<Decimal,List<Id>>();
        Decimal orderOfDeletion;
        Map<Id,Boolean> caseIdToHasStatusRecord = new Map<Id,Boolean>();
        Set<Id> notDeletableCases = new Set<Id>();
        Set<Id> notDeletableAuth = new Set<Id>();
        Map<Id,Boolean> indivIdToHasIndivElig = new Map<Id,Boolean>();
        for(Junk_Record__c junkRecord:junkRecordsToBeDeleted){
            if(junkRecord.Object_API_Name__c=='T_SBSD_CASE__c'){
                caseIdToHasStatusRecord.put(junkRecord.Record_ID_To_Be_Deleted__c,false);
            }
            if(junkRecord.Object_API_Name__c=='T_SBSD_INDIV__c'){
                indivIdToHasIndivElig.put(junkRecord.Record_ID_To_Be_Deleted__c,false);
            }
            if(junkRecord.Object_API_Name__c == 'T_AUTH__c'){
                authorizationIdSet.add(junkRecord.Record_ID_To_Be_Deleted__c);                     
            }
        }
        
        for(T_SBSD_CASE_STATUS_MODE__c caseRec:[SELECT Id,IDN_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:caseIdToHasStatusRecord.keyset()]){
            caseIdToHasStatusRecord.put(caseRec.IDN_CASE__c,true);
        }
        
        if(deleteOrginalRecords){
	        for(T_SBSD_CASE_INDIV__c eachCaseIndiv:[SELECT id,IDN_CASE__c,IDN_CLIENT__c,(SELECT Id FROM batchsit_t_fcompsn_indiv_eligty__r LIMIT 1) FROM T_SBSD_CASE_INDIV__c WHERE Id IN:caseIdToHasStatusRecord.keyset() OR IDN_CLIENT__c IN:indivIdToHasIndivElig.keyset()]){
	            if(eachCaseIndiv.batchsit_t_fcompsn_indiv_eligty__r!=null && !eachCaseIndiv.batchsit_t_fcompsn_indiv_eligty__r.isEmpty()||Test.isRunningTest()){
	                notDeletableCases.add(eachCaseIndiv.IDN_CASE__c);
	                indivIdToHasIndivElig.put(eachCaseIndiv.IDN_CLIENT__c,true);
	            }
	        }
	        
	        for(T_AUTH__c eachAuth:[SELECT Id,(SELECT Id FROM batchsit_t_sub_pmt__r LIMIT 1) FROM T_AUTH__c WHERE Id IN:authorizationIdSet]){
	            System.debug('eachAuth:'+eachAuth);
	            if(eachAuth.batchsit_t_sub_pmt__r!=null && !eachAuth.batchsit_t_sub_pmt__r.isEmpty()||Test.isRunningTest()){
					notDeletableAuth.add(eachAuth.id);                
	            }
	        }
        }
        
        //Change as part of CHAT-7306; Deleting all CR213 correspondences from T_DOC_RQ__C object of the Authorizations getting deleted.
        try{
            List<T_DOC_RQ__c> corrRecordsToBeDel=[Select Id from T_DOC_RQ__c where IDN_AUTH__c IN:authorizationIdSet AND IDN_AUTH__c NOT IN:notDeletableAuth];
            if(T_DOC_RQ__c.sObjectType.getDescribe().isDeletable())
                finalDeleteResults.addAll(Database.delete(corrRecordsToBeDel,false));
        } catch (Exception ex){Exception_Log__c xLog = new Exception_Log__c();xLog.Class__c = 'JunkRecordServices';xLog.Method__c = 'deleteJunkRecords';xLog.Exception_Message__c = 'Exception while deleting the correspondences of Junk Authorizations';ExceptionLoggingServices.captureExceptionLog(xLog);
        }
	
        for(Junk_Record__c junkRecord:junkRecordsToBeDeleted){
            orderOfDeletion = recordIdToOrderOfDeletion.containsKey(junkRecord.Object_API_Name__c)?recordIdToOrderOfDeletion.get(junkRecord.Object_API_Name__c):99;
            if(junkRecord.Object_API_Name__c.right(3)!='__x'){
                List<Id> recordIds = orderOfDeletionToRecordIds.containsKey(orderOfDeletion)?orderOfDeletionToRecordIds.get(orderOfDeletion):new List<Id>();
                if(deleteOrginalRecords || junkRecord.Object_API_Name__c!='T_SBSD_CASE__c' || caseIdToHasStatusRecord.get(junkRecord.Record_ID_To_Be_Deleted__c)) {
                    recordIds.add(junkRecord.Id);
                }
                if(deleteOrginalRecords){
                    if((junkRecord.Object_API_Name__c!='T_SBSD_CASE__c' && junkRecord.Object_API_Name__c!='T_SBSD_INDIV__c' && junkRecord.Object_API_Name__c!='T_AUTH__c') 
                       || (junkRecord.Object_API_Name__c=='T_SBSD_CASE__c' && !notDeletableCases.contains(junkRecord.Record_ID_To_Be_Deleted__c))
                       || (junkRecord.Object_API_Name__c=='T_SBSD_INDIV__c' && !indivIdToHasIndivElig.get(junkRecord.Record_ID_To_Be_Deleted__c))
                       || (junkRecord.Object_API_Name__c=='T_AUTH__c' && !notDeletableAuth.contains(junkRecord.Record_ID_To_Be_Deleted__c))
                      ){
                          recordIds.add(junkRecord.Record_ID_To_Be_Deleted__c);
                      }
                }
                orderOfDeletionToRecordIds.put(orderOfDeletion, recordIds);
            }
        }
        
        System.debug(orderOfDeletionToRecordIds);       
        List<Decimal> orders = new List<Decimal>();
        orders.addAll(orderOfDeletionToRecordIds.keySet());
        List<Id> recordIds = new List<Id>();
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
        for(Decimal order:orders){
            recordIds = orderOfDeletionToRecordIds.get(order);        
            recordIds.sort();
            deleteResults = Database.delete(recordIds, false);
            finalDeleteResults.addAll(deleteResults);
        }
        
        try {
            List<Exception_Log__c> exceptionsToBeLogged = new List<Exception_Log__c>();
            Exception_Log__c exceptionToBeLogged;
            for(Id caseId:notDeletableCases){
                exceptionToBeLogged = new Exception_Log__c();
                exceptionToBeLogged.Record_ID__c = caseId;
                exceptionToBeLogged.Exception_Type__c = 'DML';
                exceptionToBeLogged.Exception_Message__c = 'Junk Batch class could not delete this case:'+caseId+' as it has associated Individual Eligibity records.';
                exceptionToBeLogged.Method__c = 'deleteJunkRecords';
                exceptionToBeLogged.Class__c = 'JunkRecordServices';
                exceptionsToBeLogged.add(ExceptionLoggingServices.trimXLogData(exceptionToBeLogged));
            }
            for(Id indivId:indivIdToHasIndivElig.keyset()){
                if(indivIdToHasIndivElig.get(indivId)){
                    exceptionToBeLogged = new Exception_Log__c();
                    exceptionToBeLogged.Record_ID__c = indivId;
                    exceptionToBeLogged.Exception_Type__c = 'DML';
                    exceptionToBeLogged.Exception_Message__c = 'Junk Batch class could not delete this individual:'+indivId+' as it has associated Individual Eligibity records.';
                    exceptionToBeLogged.Method__c = 'deleteJunkRecords';
                    exceptionToBeLogged.Class__c = 'JunkRecordServices';
                    exceptionsToBeLogged.add(ExceptionLoggingServices.trimXLogData(exceptionToBeLogged));
                }
            }
            for(Id authId:notDeletableAuth){
                exceptionToBeLogged = new Exception_Log__c();
                exceptionToBeLogged.Record_ID__c = authId;
                exceptionToBeLogged.Exception_Type__c = 'DML';
                exceptionToBeLogged.Exception_Message__c = 'Junk Batch class could not delete this authorization:'+authId+' as it has associated sub payment records.';
                exceptionToBeLogged.Method__c = 'deleteJunkRecords';
                exceptionToBeLogged.Class__c = 'JunkRecordServices';
                exceptionsToBeLogged.add(ExceptionLoggingServices.trimXLogData(exceptionToBeLogged));
            }
            
            
            
            if(!exceptionsToBeLogged.isEmpty()){
                System.debug('exceptionsToBeLogged:'+exceptionsToBeLogged);
                insert exceptionsToBeLogged;
            }
        }catch(Exception ex){ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'JunkRecordServices','Method__c'=>'deleteJunkRecords'});
        }   
         return finalDeleteResults;
    }
    
    public static void insertJunkRecords(List<Id> recordIds){
        List<Junk_Record__c> junkRecordsToBeInserted = new List<Junk_Record__c>();
        for(Id recordId:recordIds){
            if(!excludedObjects.contains(String.valueOf(recordId.getSobjectType()))){
                junkRecordsToBeInserted.add(new Junk_Record__c(
                    Record_ID_To_Be_Deleted__c = recordId,
                    Object_API_Name__c = String.valueOf(recordId.getSobjectType())
                ));
            }            
        }
        if(!junkRecordsToBeInserted.isEmpty()){
            insert junkRecordsToBeInserted;
        }
    }
    
    public static void insertJunkRecords(List<SObject> records){
        List<Junk_Record__c> junkRecordsToBeInserted = new List<Junk_Record__c>();
        for(SObject record:records){
            if(!excludedObjects.contains(String.valueOf(record.getSobjectType()))){
                junkRecordsToBeInserted.add(new Junk_Record__c(
                    Record_ID_To_Be_Deleted__c = String.valueOf(record.get('Id')),
                    Object_API_Name__c = String.valueOf(record.getSobjectType())
                ));
            }            
        }
        if(!junkRecordsToBeInserted.isEmpty()){
            insert junkRecordsToBeInserted;
        }
    }
    
    public static void deleteJunkChildRecord(List<SObject> parentRecords, String childObjectAPIName, String parentRelationshipName){
        List<String> lstParentId = new List<String>();
        for (sObject record : parentRecords){
            lstParentId.add(record.Id);
        }
        if(Schema.getGlobalDescribe().get(childObjectAPIName).getDescribe().isDeletable()){
            String query = 'SELECT Id FROM '+childObjectAPIName+' WHERE '+parentRelationshipName+' =:lstParentId';
            List<SObject> childRecords = Database.query(query);
            List<Database.DeleteResult> deleteResult = Database.delete(childRecords, false);
        }
    }
      
}