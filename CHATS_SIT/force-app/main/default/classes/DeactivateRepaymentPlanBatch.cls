global with sharing class DeactivateRepaymentPlanBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, CDE_COUNTY__c, IND_ACTIVE__c, IDN_PROVR__c FROM T_PMT_PLAN__c WHERE IND_ACTIVE__c = true AND CDE_COUNTY__c != null');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Integer> countyCodes = new Set<Integer>();
        for(T_PMT_PLAN__c rplan : (List<T_PMT_PLAN__c>)scope){
            countyCodes.add(Integer.valueOf(rplan.CDE_COUNTY__c));
        }
        
        String countyCode;
        Map<string, set<id>> countyRecoveries = new Map<string, set<id>>();
        for(T_COUNTY__c county : [SELECT Id, CDE_COUNTY__c, (SELECT Id, IDN_PROVR__c FROM Adjustment_County__r WHERE CDE_TYPE_ADJMT__c = '2' AND CDE_STATUS_ADJMT__c = '2') FROM T_COUNTY__c WHERE CDE_COUNTY__c IN :countyCodes]){
            for(T_ADJMT__c adj : county.Adjustment_County__r){
                countyCode = String.valueOf(county.CDE_COUNTY__c);
                if(!countyRecoveries.containsKey(countyCode)){
                    countyRecoveries.put(countyCode, new set<Id>());
                }                            
                countyRecoveries.get(countyCode).add(adj.IDN_PROVR__c);
            }
        }
        
        List<T_PMT_PLAN__c> rPlanToUpdate = new List<T_PMT_PLAN__c>();
        for(T_PMT_PLAN__c rplan : (List<T_PMT_PLAN__c>)scope){
            if(!countyRecoveries.containsKey(rplan.CDE_COUNTY__c) || !countyRecoveries.get(rplan.CDE_COUNTY__c).contains(rplan.IDN_PROVR__c)){
                rplan.IND_ACTIVE__c = false;
                rPlanToUpdate.add(rplan);
            }
        }
        
        if(!rPlanToUpdate.isEmpty()){
            update rPlanToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC){
      //All the tasks which is to be completed post completion of the batch has to be written in this method.  
    }

}