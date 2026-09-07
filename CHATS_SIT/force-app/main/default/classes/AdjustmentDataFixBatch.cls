/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/24/2022                                                         
*  @description    Adjustment batch class for datafix                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 244-May-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class AdjustmentDataFixBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public List<T_ADJMT__c> authNameList = new List<T_ADJMT__c>();
    public Set<Id> authTerminate = new Set<Id>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        Date weekDate = system.today()-7; // this is referred in below dynamic query
        String status ='2';
        Id RecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        String queryStr ='SELECT ID,Name, DTE_START_ADJMT__c,CreatedById,CreatedDate,DTE_EFFV_RECOVERY__c, IDN_EXTNL__c FROM T_ADJMT__c Where CDE_STATUS_ADJMT__c =:status and RecordTypeId = :RecordTypeId';
        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_ADJMT__c> adjList){
        try{
            List<T_ADJMT__c> adjLstToUpdate=  new List<T_ADJMT__c>();
            List<T_ADJMT__History> adjHist=  new List<T_ADJMT__History>();
            Set<Id> adjIds = new Set<Id>();
            for(T_ADJMT__c adj :adjList){
                adjIds.add(adj.id);
            }
            Triggers_On_Off_Settings__c triggerService =[select id,Active__c from Triggers_On_Off_Settings__c where name ='adjustmentTrigger' LIMIT 1];
            triggerService.Active__c = false;
            GenericDMLHandler.updateRecords(new List<SObject>{triggerService},new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
            
            Date legacyDate = Date.newInstance(2018, 09, 01);
            Map<string,Datetime> adjustMap= new Map<string,Datetime>();
            Map<string,string> adjustRecTypeMap= new Map<string,string>();
            for(T_ADJMT__History hist :[SELECT ParentId, Id, CreatedDate, CreatedById, Field, NewValue, OldValue FROM T_ADJMT__History where ParentId in:adjIds and
                                        (Field ='CDE_STATUS_ADJMT__c' or  Field='RecordType') order by CreatedDate desc]){
                                            if(hist.NewValue =='2'){
                                                adjustMap.put(hist.ParentId, hist.CreatedDate);
                                            }
                                            if(hist.Field=='RecordType' && hist.NewValue =='Finalized'){
                                                adjustRecTypeMap.put(hist.ParentId, String.valueOf(hist.NewValue));
                                            }
                                        }
            for(T_ADJMT__c adj :adjList){
                if(adjustMap.containsKey(adj.id) && adjustRecTypeMap.containsKey(adj.id)){
                    adj.DTE_EFFV_RECOVERY__c  =Date.valueOf(adjustMap.get(adj.id)).addDays(15);
                    adjLstToUpdate.add(adj);
                }else{
                    adj.DTE_EFFV_RECOVERY__c  =Date.valueOf(adj.CreatedDate).addDays(15);
                    adjLstToUpdate.add(adj);
                }
            }
            if(adjLstToUpdate != null && adjLstToUpdate.size()>0){
                Database.update(adjLstToUpdate);
            }
            triggerService.Active__c = true;
            GenericDMLHandler.updateRecords(new List<SObject>{triggerService},new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
            
            
        }
        catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'AdjustmentDataFixBatch';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'AdjustmentDataFixBatch  for adjustment'+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    }    
}