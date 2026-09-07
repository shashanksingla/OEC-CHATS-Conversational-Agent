/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/27/2022                                                          
*  @description    T204 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 27-Nov-2022                                                             
*  * Author: Azharuddin Mohammad                                                     
*  * Description: Initial version 
*
*  * Version: 2.0
*  * Date: 16-Jan-2025
*  * Author: Raina Yeole
*  * Description: Updated trigger logic to 90 days from 60 and task due date to 30 days from task trigger date
*********************************************************************************************/
global with sharing class T204TaskCreationBatch implements Database.Batchable<sObject> {
    
    public String provrStatusOpen = 'Open';
    List<Task> taskstoBeCreated = new List<Task>();
    Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'T204TaskCreationBatch','Method__c'=>'execute'};
        Date NoDaysFromToday;  
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(!Test.isRunningTest()){
            NoDaysFromToday = System.today().addDays(integer.valueOf(System.Label.t204task_time_period));
        }else {
            NoDaysFromToday = system.today().addDays(90); // Updated logic as part of CCCAP-12518
        }
        String FAStatusOPN = 'OPN';
        String queryStr ='SELECT Id, Name, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, CDE_COUNTY__c, CDE_TYPE_STATUS__c, OwnerId, ID_SERVICE__c, ID_SERVICE__r.Name, ID_SERVICE__r.CDE_STATUS_PROVR__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_TYPE_STATUS__c =:FAStatusOPN AND DTE_END_AGRMT__c =: NoDaysFromToday';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_PROVR_FISCAL_AGREMENT__c> scope) {
        String FAStatusFIN = 'FIN';
        Set<Id> counties= new Set<Id>();
        Map<Id,T_PROVR_FISCAL_AGREMENT__c> FaMap = new Map<Id,T_PROVR_FISCAL_AGREMENT__c>();
        Set<Id> provIds = new Set<Id>();
        if(null!=scope &&!scope.isEmpty()){
            System.debug('Number of records fetched from start method :'+scope.size());
            for(T_PROVR_FISCAL_AGREMENT__c openFA : scope){
                if(openFA.ID_SERVICE__r.CDE_STATUS_PROVR__c == provrStatusOpen){
                    provIds.add(openFA.ID_SERVICE__c);
                    counties.add(openFA.CDE_COUNTY__c);
                    FaMap.put(openFA.Id,openFA);
                }
            }
        }
        Map<Id,T_CHATS_PROVR_STATUS__c> providers  = new Map<Id,T_CHATS_PROVR_STATUS__c>([select id,(select id,CDE_COUNTY__c,DTE_BEGIN_AGRMT__c from Provider_Fiscal_Agreements__r 
                                                                                                     where CDE_County__c in :counties and DTE_BEGIN_AGRMT__c>TODAY and CDE_TYPE_STATUS__c=:FAStatusFIN  order by DTE_BEGIN_AGRMT__c desc)  
                                                                                          FROM T_CHATS_PROVR_STATUS__c WHERE id in :provIds]);
        for(T_PROVR_FISCAL_AGREMENT__c openFA : FaMap.values()){
            List<T_PROVR_FISCAL_AGREMENT__c> finalizedFAs = providers.get(openFA.ID_Service__c)?.Provider_Fiscal_Agreements__r;
            if(finalizedFAs!=null && !finalizedFAs.isEmpty()){
                for(T_PROVR_FISCAL_AGREMENT__c finFA : finalizedFAs){
                    if(finFA.CDE_COUNTY__c == openFA.CDE_COUNTY__c && finFA.DTE_BEGIN_AGRMT__c > openFA.DTE_END_AGRMT__c){
                        FaMap.remove(openFA.Id);
                        break;
                    }
                }
            }
        }
        for(T_PROVR_FISCAL_AGREMENT__c eachFA : FaMap.values()){
            Task tsk= new Task();
            tsk.Subject = 'T204 - Fiscal Agreement Renewal Date is within 90 days';
            tsk.WhatId = eachFA.Id;
            tsk.OwnerId = eachFA.OwnerId;
            tsk.Status = 'Not Started';
            tsk.Priority = 'Normal';
            //tsk.ActivityDate= eachFA.DTE_END_AGRMT__c; // Updated logic as part of CCCAP-12518
            tsk.ActivityDate= system.today().addDays(30);
            tsk.Description = 'Provider '+ eachFA.ID_SERVICE__r.Name +' has a fiscal agreement with a Renewal Date within 90 days. Please generate a new Fiscal Agreement and obtain Provider signatures.';
            taskstoBeCreated.add(tsk);    
        }
        
        system.debug(taskstoBeCreated.size());
        system.debug('The task Info -> ' +taskstoBeCreated);
        if(null!=taskstoBeCreated&&!taskstoBeCreated.isEmpty()){
            //Database.DMLOptions dm = new Database.DMLOptions();
            //dm.EmailHeader.triggerUserEmail=true;
            //dm.optAllOrNone = false;
            GenericDMLHandler.insertRecords(taskstoBeCreated,false,methodInfo);
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}