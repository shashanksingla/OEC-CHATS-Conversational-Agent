global with sharing class DeletedRecordArchivalBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, Archival_Object__c, Is_Active__c FROM Record_Archival_Setup__c where Is_Active__c=true');   
    }
    
    global void execute(Database.BatchableContext BC, List<Record_Archival_Setup__c> scope){
        List<Archived_Record__c> lstArchivedRecord = new List<Archived_Record__c>();
        for(Record_Archival_Setup__c eachSetup : scope){
            String query='Select Id, Name, createdById, createdDate, lastModifiedById, lastModifiedDate from '+ String.escapeSingleQuotes(eachSetup.Archival_Object__c)+' where isDeleted =true and lastModifiedDate = TODAY ALL ROWS';
            List<SObject> archivedRecords= database.query(query);
            for(sObject eachRec: archivedRecords){
                Archived_Record__c archivedRec = new Archived_Record__c();
                archivedRec.Record_Id__c = String.valueof(eachRec.get('Id'));
                archivedRec.Created_Date__c = DateTime.valueOf(eachRec.get('CreatedDate')); 
                archivedRec.Created_By__c = String.valueof(eachRec.get('createdById'));
                archivedRec.Last_Modified_By__c = String.valueOf(eachRec.get('lastModifiedById'));
                archivedRec.Last_Modified_At__c = DateTime.valueOf(eachRec.get('lastModifiedDate'));
                archivedRec.Record_Name__c = String.valueOf(eachRec.get('Name'));
                archivedRec.Object_Name__c = eachSetup.Archival_Object__c;	
                lstArchivedRecord.add(archivedRec);  
            }
        }
        if(lstArchivedRecord.size()>0){
             GenericWithoutSharingDMLOperations.insertRecords(lstArchivedRecord, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'DeletedRecordArchivalBatch'}) ;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //All the tasks which is to be completed post completion of the batch has to be written in this method.  
        
    }
}