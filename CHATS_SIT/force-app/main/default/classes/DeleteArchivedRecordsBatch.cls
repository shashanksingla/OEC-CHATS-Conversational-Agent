global without sharing class DeleteArchivedRecordsBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Integer numberOfDays = 0;
        numberOfDays =  Test.isRunningTest()?0:Integer.valueOf(Label.Archived_Record_Retaining_Days);
        DateTime todayMinusRecordRetainingDays = system.now().addHours(-(numberOfDays*24));
        String query = 'SELECT Id FROM Archived_Record__c where createdDate <='+ todayMinusRecordRetainingDays.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','UTC');
        return Database.getQueryLocator(query);   
    }
    
    global void execute(Database.BatchableContext BC, List<Archived_Record__c> scope){
        List<Id> lstArchivedRecordIdsToBeDeleted = new List<Id>();
        for(Archived_Record__c eachRecord : scope){
             lstArchivedRecordIdsToBeDeleted.add(eachRecord.Id); 
            }
        if(lstArchivedRecordIdsToBeDeleted.size()>0){
            GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(lstArchivedRecordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'DeletedRecordArchivalBatch'}) ;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //All the tasks which is to be completed post completion of the batch has to be written in this method.  
        
    }
}