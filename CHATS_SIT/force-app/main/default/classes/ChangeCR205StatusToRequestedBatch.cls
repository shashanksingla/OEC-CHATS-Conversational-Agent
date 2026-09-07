// Created by Balamurugan Chinnaiah 01/03/2023
// Created for CCCAP-7613

global  class ChangeCR205StatusToRequestedBatch implements Database.Batchable<sObject> {
    
	global Database.QueryLocator start(Database.BatchableContext bc) {            
		String query = 'select id, NME_CORSPD__c, CDE_CORSPD_STATUS__c from  T_DOC_RQ__c where NME_CORSPD__c  = \'CR205\' and CDE_CORSPD_STATUS__c = \'Pending\'';
		return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<T_DOC_RQ__c> docReqs) {
       
        // process each batch of records
        
        for(T_DOC_RQ__c docReq : docReqs)
        {        
            // Update the status 
            docReq.CDE_CORSPD_STATUS__c = 'Requested';
        }
        try {
            // Update the docreqs
            update docReqs;
        
        } catch(Exception e) {
			Exception_Log__c xLog = new Exception_Log__c();
			xLog.Class__c = 'ChangeCR205StatusToRequestedBatch';
			xLog.Method__c = 'Execute';
			xLog.Exception_Message__c = 'Status Update failure';
			xLog.Request__c = 'null';
			xLog.Response__c = 'null';
			ExceptionLoggingServices.captureExceptionLog(xLog); 
        }
        
    }

    global void finish(Database.BatchableContext BC){
    }
}