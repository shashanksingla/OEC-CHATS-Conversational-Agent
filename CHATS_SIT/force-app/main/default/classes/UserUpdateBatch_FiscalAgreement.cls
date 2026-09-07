/*************************************************************
Class Name      - UserUpdateBatch_FiscalAgreement
Test Class      - UserUpdateBatchTest_v2
Description     - Splitted 'UserUpdateBatch.apxc' into 2 parts. This is the Fiscal Agreement part.
Author          - Rishav Maji
Requiremnt      - CCCAP-7119
**************************************************************/
global class UserUpdateBatch_FiscalAgreement implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new UserUpdateBatch_FiscalAgreement());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr = 'Select Id, Name, OwnerId, CDE_COUNTY__r.CDE_COUNTY__c FROM T_PROVR_FISCAL_AGREMENT__c ';
        queryStr += 'WHERE Owner.IsActive = false AND CDE_COUNTY__r.CDE_COUNTY__c != null AND CDE_TYPE_STATUS__c != \'CLS\'';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_PROVR_FISCAL_AGREMENT__c> scope){
        try {
            UserUpdateService.handleFiscalOwnershipUpdate(scope);
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'UserUpdateBatch_FiscalAgreement', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext bc){
        if(!errors.isEmpty()){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'UserUpdateBatch_FiscalAgreement'});
        }
    }
}