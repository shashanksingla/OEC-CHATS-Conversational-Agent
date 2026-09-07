/*************************************************************
Class Name      - UpdateProviderFromFA_oneTimeBatch
Test Class      - UpdateProviderFromFA_oneTimeBatch_Test
Description     - One time batch to update 'CCCAP Original Fiscal Agreement Date' date in all Providers
Author          - Rishav Maji
Requiremnt      - Project 475 : CCCAP-7432
**************************************************************/
global with sharing class UpdateProviderFromFA_oneTimeBatch implements Database.Batchable<sObject>, Database.Stateful {
      
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, DTE_Original_FA__c, (
                SELECT Id, DTE_BEGIN_AGRMT__c FROM Provider_Fiscal_Agreements__r 
                WHERE CDE_TYPE_STATUS__c IN ('OPN', 'CLS') AND DTE_BEGIN_AGRMT__c != null 
                ORDER BY DTE_BEGIN_AGRMT__c ASC LIMIT 1
            ) FROM T_CHATS_PROVR_STATUS__c 
            WHERE Id IN (SELECT ID_SERVICE__c FROM T_PROVR_FISCAL_AGREMENT__c) AND DTE_Original_FA__c = null
            ORDER BY createdDate DESC]);
    }
    
    global void execute(Database.BatchableContext bc, List<T_CHATS_PROVR_STATUS__c> scope) {
        List<T_CHATS_PROVR_STATUS__c> ProvrListToUpdate = new List<T_CHATS_PROVR_STATUS__c>();
        for(T_CHATS_PROVR_STATUS__c provr : scope){
            List<T_PROVR_FISCAL_AGREMENT__c> firstFA = provr.Provider_Fiscal_Agreements__r;
            if(!firstFA.isEmpty() && Schema.sObjectType.T_CHATS_PROVR_STATUS__c.fields.DTE_Original_FA__c.isUpdateable()){
                provr.DTE_Original_FA__c = firstFA[0].DTE_BEGIN_AGRMT__c;
                ProvrListToUpdate.add(provr);
            }
        }
        if(!ProvrListToUpdate.isEmpty()) {
            GenericDMLHandler.updateRecords(ProvrListToUpdate, new Map<String, Object>{'Method__c'=>'execute','Class__c'=>'UpdateProviderFromFA_oneTimeBatch'});
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}