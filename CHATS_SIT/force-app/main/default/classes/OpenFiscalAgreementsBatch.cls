/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           08/26/2020                                                          
*  @description    Batch class for opening Fiscal Agreements which have begin date today and 
				   status finalized
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 08/26/2020
*  * Author: Balamurugan Chinnaiah
*  * Description: Initial version 
*********************************************************************************************/
global with sharing class OpenFiscalAgreementsBatch implements Database.Batchable<sObject>{
    Public Final Id OPEN_RECORD_TYPE_ID = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    Public Final String FINALIZED_STATUS = 'FIN';
	Public Final String OPEN_STATUS = 'OPN';
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date dateToday =  System.today() ;
        return Database.getQueryLocator('SELECT Id, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c FROM T_PROVR_FISCAL_AGREMENT__c where CDE_TYPE_STATUS__c =:FINALIZED_STATUS and DTE_BEGIN_AGRMT__c =:dateToday');   
    }
    
    global void execute(Database.BatchableContext BC, List<T_PROVR_FISCAL_AGREMENT__c> scope){
        List<T_PROVR_FISCAL_AGREMENT__c> lstFARecords = new List<T_PROVR_FISCAL_AGREMENT__c>();
        for(T_PROVR_FISCAL_AGREMENT__c faRecord: scope){
			faRecord.CDE_TYPE_STATUS__c = OPEN_STATUS;
			faRecord.RecordtypeId =  OPEN_RECORD_TYPE_ID;
            lstFARecords.add(faRecord); 
        }
        if(!lstFARecords.isEmpty()){
        	GenericDMLHandler.updateRecords(lstFARecords, false, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'OpenFiscalAgreementsBatch'});
        }   
    }
    
    global void finish(Database.BatchableContext BC){
        
        
    }
}