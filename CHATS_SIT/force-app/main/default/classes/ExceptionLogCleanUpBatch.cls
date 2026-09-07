/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/10/2018                                                          
*  @description    Batch Class for cleaning up Exception Log Object.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-Jul-2018                                                             
*  * Author: Vineet Srivastava                                                     
*  * Description: Initial version 
*********************************************************************************************/

global with sharing class ExceptionLogCleanUpBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id FROM Exception_Log__c where CreatedDate < LAST_N_DAYS : 89' );
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Id> recordIdsToBeDeleted = new List<String>();
        if(!scope.isEmpty()){
            scope.sort();
            for(SObject sOb:scope){
                recordIdsToBeDeleted.add((Id)sOb.get('Id'));
            }
	        GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'ExceptionLogCleanUpBatch'});
            recordIdsToBeDeleted.clear();
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //All the tasks which is to be completed post completion of the batch has to be written in this method.  
        
    }
}