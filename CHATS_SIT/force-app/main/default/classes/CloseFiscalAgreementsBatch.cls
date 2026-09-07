/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08/13/2019                                                          
*  @description    Batch class for closing Fiscal Agreements which have past their End dates and somehow got 
				   missed by the time dependent workflow action.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 13-Aug-2019                                                             
*  * Author: Vineet Srivastava                                                     
*  * Description: Initial version 
*********************************************************************************************/
global with sharing class CloseFiscalAgreementsBatch implements Database.Batchable<sObject>{
    Public Final Id CLOSED_RECORD_TYPE_ID = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
    Public Final String CLOSED_STATUS = 'CLS';
    Public Final String REASON_FOR_CLOSURE = 'NEW';
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date dateToday =  System.today() ;
        return Database.getQueryLocator('SELECT Id, CDE_TYPE_STATUS__c, CDE_REASON_END_AGRMT__c, RecordtypeId FROM T_PROVR_FISCAL_AGREMENT__c where CDE_TYPE_STATUS__c !=:CLOSED_STATUS and DTE_END_AGRMT__c <:dateToday');   
    }
    
    global void execute(Database.BatchableContext BC, List<T_PROVR_FISCAL_AGREMENT__c> scope){
        List<T_PROVR_FISCAL_AGREMENT__c> lstFARecords = new List<T_PROVR_FISCAL_AGREMENT__c>();
        for(T_PROVR_FISCAL_AGREMENT__c faRecord: scope){
            faRecord.CDE_TYPE_STATUS__c = CLOSED_STATUS;
            faRecord.RecordtypeId =  CLOSED_RECORD_TYPE_ID;
            faRecord.CDE_REASON_END_AGRMT__c = REASON_FOR_CLOSURE;
            lstFARecords.add(faRecord); 
        }
        if(!lstFARecords.isEmpty()){
        	GenericDMLHandler.updateRecords(lstFARecords, false, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'CloseFiscalAgreementsBatch'});
        }   
    }
    
    global void finish(Database.BatchableContext BC){
        
        
    }
}