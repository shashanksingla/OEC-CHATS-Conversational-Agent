global with sharing class UpdateFlagonFiscalAgreement implements Database.Batchable<sObject>{

   global Database.QueryLocator start(Database.BatchableContext BC){
       Id finalizedRecType = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
       Id closedRecType = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
      return Database.getQueryLocator([select Id,Batch_Flag__c from T_PROVR_FISCAL_AGREMENT__c where ((DTE_END_AGRMT__c !=null and CDE_TYPE_STATUS__c='OPN' and ID_SERVICE__r.CDE_STATUS_PROVR__c='Open' and DTE_END_AGRMT__c > NEXT_N_DAYS:50) or (CDE_TYPE_STATUS__c='FIN' and DTE_BEGIN_AGRMT__c>=Today and RecordTypeId=:finalizedRecType) or (CDE_TYPE_STATUS__c !='CLS' and DTE_END_AGRMT__c >=Today and RecordTypeId !=:closedRecType)) and Batch_Flag__c!=true]);
   }

   global void execute(Database.BatchableContext BC, List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList){
     for(T_PROVR_FISCAL_AGREMENT__c fiscal : fiscalAgreementList){
         fiscal.Batch_Flag__c =true;
     }
     
     GenericDMLHandler.updateRecords(fiscalAgreementList,false, new Map<String,Object>{'Class__c'=>'UpdateFlagonFiscalAgreement','Method__c'=>'execute'});
     
    }

   global void finish(Database.BatchableContext BC){
   }
}