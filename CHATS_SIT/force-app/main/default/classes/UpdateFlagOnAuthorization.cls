global with sharing class UpdateFlagOnAuthorization implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([select Id from T_AUTH__c WHERE Authorization_Status__c='2' AND Batch_Flag__c=false]);
    }
    
    global void execute(Database.BatchableContext BC, List<T_AUTH__c> authList){
        for(T_AUTH__c auth:authList){
            auth.Batch_Flag__c = true;
        }
  	    GenericDMLHandler.updateRecords(authList, false,new Map<String,Object>{'Class__c'=>'UpdateFlagOnAuthorization','Method__c'=>'execute'});
    }
    
    global void finish(Database.BatchableContext BC){

    }
}