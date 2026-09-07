global without sharing class JunkRecordDeletionBatch implements Database.Batchable<sObject>,Database.Stateful{
    global List<String> finalDeleteResults= new List<String>();
        global Database.QueryLocator start(Database.BatchableContext BC){
        Integer dateLabel = Integer.valueOf(System.Label.Time_Junk_Record_Deletion);
        DateTime nowMinus4Hours =  System.now().addHours(dateLabel);
        if(!Test.isRunningTest()){
        return Database.getQueryLocator('SELECT Id, Object_API_Name__c, Record_ID_To_Be_Deleted__c FROM Junk_Record__c WHERE CreatedDate<'+ nowMinus4Hours.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','UTC') );
        }else{
         return Database.getQueryLocator('SELECT Id, Object_API_Name__c, Record_ID_To_Be_Deleted__c FROM Junk_Record__c ');   
        }
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        //System.debug('finalDeleteResults:'+finalDeleteResults);
		List<Database.DeleteResult> results=JunkRecordServices.deleteJunkRecords(scope, true);
        for(Database.DeleteResult dr: results){
            if(!dr.isSuccess()){
              String result='';
              
              result+=dr.getId()+';;'+'Fail'; 
              
              String errorMessage='';
                for(Database.Error er: dr.getErrors()){
                    errorMessage+=er.getMessage();
                }
              result+=';;'+errorMessage;
              finalDeleteResults.add(result);
            }
        //System.debug('finalDeleteResults:'+JunkRecordServices.deleteJunkRecords(scope, true));
    }
    }
    
    global void finish(Database.BatchableContext BC){
      //All the tasks which is to be completed post completion of the batch has to be written in this method.
        if(finalDeleteResults.size()>0){
      EmailReportForFailedRecord emailService = new EmailReportForFailedRecord();
        emailService.sendEmail(finalDeleteResults,'Junk Record Deletion Batch');  
            }
      
    }  
}