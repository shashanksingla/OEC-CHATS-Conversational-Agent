/*************************************************************
Class Name      - UserUpdateBatch_Case
Test Class      - UserUpdateBatchTest_v2
Description     - Splitted 'UserUpdateBatch.apxc' into 2 parts. This is the Case part.
Author          - Rishav Maji
Requiremnt      - CCCAP-7119
**************************************************************/
global class UserUpdateBatch_Case implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new UserUpdateBatch_Case());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr = 'SELECT Id, Name, OwnerId, CDE_COUNTY__r.CDE_COUNTY__c, ';
        queryStr += '(SELECT toLabel(CDE_STATUS_CASE__c), toLabel(CDE_MODE_CASE__c) FROM T_SBSD_CASE10__r ';
        queryStr += 'WHERE DTE_END_EFFV__c >= TODAY OR DTE_END_EFFV__c = null ORDER BY DTE_BEGIN_EFFV__c, createdDate DESC NULLS FIRST LIMIT 1) ';
        queryStr += 'FROM T_SBSD_Case__c WHERE Owner.IsActive = false AND CDE_COUNTY__r.CDE_COUNTY__c != null';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_SBSD_Case__c> scope){
        try {
            List<T_SBSD_Case__c> caseList = new List<T_SBSD_Case__c>();
            for(T_SBSD_Case__c caseObj : scope){
                if(caseObj.T_SBSD_CASE10__r != null && caseObj.T_SBSD_CASE10__r.size() > 0){
                    if(caseObj.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c != 'Closed'){
                        caseList.add(caseObj);
                    }
                }
            }
            UserUpdateService.handleCaseOwnershipUpdate(caseList);
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'UserUpdateBatch_Case', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }

    global void finish(Database.BatchableContext bc){
        if(!errors.isEmpty()){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'UserUpdateBatch_Case'});
        }
    }
}