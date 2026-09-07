global with sharing class UserUpdateBatch implements Database.Batchable<sObject>{
    
    global List<SObject> start(Database.BatchableContext bc) {
        //GET ALL OBJECTS WITH INACTIVE OWNERS
        //TYPE -1 
        List<SObject> finalCaseList = new List<SObject>();
        List<T_SBSD_Case__c> caseList = [SELECT Id, Name, OwnerId, CDE_COUNTY__r.CDE_COUNTY__c,
                                         (SELECT toLabel(CDE_STATUS_CASE__c), toLabel(CDE_MODE_CASE__c) FROM T_SBSD_CASE10__r WHERE DTE_END_EFFV__c >= Today OR DTE_END_EFFV__c = null ORDER BY DTE_BEGIN_EFFV__c, createddate DESC NULLS FIRST LIMIT 1)
                                         FROM T_SBSD_Case__c 
                                         WHERE Owner.IsActive = false 
                                         AND CDE_COUNTY__r.CDE_COUNTY__c != null WITH SECURITY_ENFORCED];
        for(T_SBSD_Case__c caseObj : caseList ){
            if(caseObj.T_SBSD_CASE10__r != null && caseObj.T_SBSD_CASE10__r.size() > 0){
                if(caseObj.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c != 'Closed'){
                    finalCaseList.add(caseObj);
                }
            }
        }
        //TYPE-2
        List<SObject> fiscList = [SELECT Id, Name, OwnerId, CDE_COUNTY__r.CDE_COUNTY__c
                                  FROM T_PROVR_FISCAL_AGREMENT__c 
                                  WHERE Owner.IsActive = false AND CDE_COUNTY__r.CDE_COUNTY__c != null AND CDE_TYPE_STATUS__c != 'CLS'];
        List<SObject> fullList = new List<SObject>();
        fullList.addAll(finalCaseList);
        fullList.addAll(fiscList);
        return fullList;
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        // SEGREGATE INTO TYPES:
        List<T_SBSD_Case__c> caseList = new List<T_SBSD_Case__c>();
        List<T_PROVR_FISCAL_AGREMENT__c> fiscList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        for(sObject obj : scope) {
            if(String.valueOf(obj.Id.getsobjecttype()) == 'T_SBSD_CASE__c') {
                caseList.add((T_SBSD_Case__c)obj);
            } else if(String.valueOf(obj.Id.getsobjecttype()) == 'T_PROVR_FISCAL_AGREMENT__c') {
                fiscList.add((T_PROVR_FISCAL_AGREMENT__c)obj);
            }
        }
        UserUpdateService.handleCaseOwnershipUpdate(caseList);
        UserUpdateService.handleFiscalOwnershipUpdate(fiscList);
    }
    
    global void finish(Database.BatchableContext BC){}
    
}