/*************************************************************
Class Name	    - DeleteOldReverseInterfaceReportsBatch
Test Class	    - 
Description     - Batch Class for Clearing Revere Referral Interface records
Author          - Shashank S
JIRA Id			- CCCAP - 10162
**************************************************************/
global with sharing class DeleteOldReverseInterfaceReportsBatch implements Database.Batchable<sObject>, Database.Stateful, schedulable {
    global static List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        string dateField = Test.isRunningTest()?'Date_Sent_To_CBMS__C':'CreatedDate';
        Date thirtyDaysInPast = Date.today()-30;
        String queryStr ='SELECT Id,Name from Reverse_Referral_Interface_Report__c where ' +dateField+ ' <=: thirtyDaysInPast';
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<Reverse_Referral_Interface_Report__c> scope) {
        try{
            Integer index =0;
            for(Database.DeleteResult dr : Database.delete(scope,false)) {
                if(!dr.isSuccess()){
                    String errorMessage;
                    for(Database.Error err : dr.getErrors()){
                        errorMessage+=' '+err.getMessage();
                    }
                    setException(scope[index++]?.Name+' - '+errorMessage);
                }else{
                    index++;
                }
            }
        }catch(Exception e) {
            setException(e.getMessage());
        }
    }
    global void finish(Database.BatchableContext bc) {
        
    }
    global void execute(SchedulableContext sc){
        database.executebatch(new DeleteOldReverseInterfaceReportsBatch(), 200);
    }
    @testVisible
    private static void setException(string errorMessage){
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'DeleteOldReverseInterfaceReportsBatch';
        xLog.Method__c = 'execute';
        xLog.Exception_Message__c = errorMessage;
        xLog.Exception_Type__c = 'Error';
        errors.add(xLog);
    }
}