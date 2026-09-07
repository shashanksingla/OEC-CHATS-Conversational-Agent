global with sharing class ParentTrainingBreakBatch implements 
Database.Batchable<sObject>, Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        String queryStr ='SELECT id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_TRAIN_INDIV__c from T_INDIV_TRAIN_INFO__c Where DTE_BEGIN_EFFV__c =:todayDate and (DTE_END_EFFV__c >= :todayDate or DTE_END_EFFV__c =NULL) ';//+todayDate; Updated as of CHATS-6644
        
        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_INDIV_TRAIN_INFO__c> empTempBreakList){
        try{
            Map<String,T_INDIV_TRAIN_INFO__c> oldEmpInfoMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
            List<T_INDIV_TRAIN__c> empListToBeUpdated = new List<T_INDIV_TRAIN__c>();
            Set<String> empIds = new Set<String>();
            for(T_INDIV_TRAIN_INFO__c obj: empTempBreakList){
                empIds.add(obj.IDN_TRAIN_INDIV__c);
                oldEmpInfoMap.put(obj.IDN_TRAIN_INDIV__c,obj);
            }
            for(T_INDIV_TRAIN__c empObj:[SELECT Id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_INDIV_TRAIN__c WHERE Id IN:empIds]){
            
            if(oldEmpInfoMap.containsKey(empObj.Id)){
                T_INDIV_TRAIN_INFO__c obj = oldEmpInfoMap.get(empObj.Id);
                empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                empObj.CDE_TYPE_INFO_TRAIN__c = obj.CDE_TYPE_INFO_TRAIN__c;
                empListToBeUpdated.add(empObj);
            }           
        }
        if(empListToBeUpdated.size()>0){
            GenericDMLHandler.updateRecords(empListToBeUpdated, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'EmploymentTempBreakBatch'});
        }
        }catch(Exception e) {
            
        }
    }    
    global void finish(Database.BatchableContext bc){
        
        
    }    
    
}