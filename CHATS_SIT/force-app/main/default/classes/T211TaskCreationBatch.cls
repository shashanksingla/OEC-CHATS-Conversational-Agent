/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/29/2020                                                          
*  @description    T211 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Jul-2020                                                             
*  * Author: Sahil Garg                                                     
*  * Description: Initial version 
*********************************************************************************************/
global with sharing class T211TaskCreationBatch implements Database.Batchable<sObject> {
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('Started batch T211TaskCreationBatch');
        String validationDate =  System.now().addDays(Integer.valueOf(System.Label.t211task_time_period)).format('yyyy-MM-dd') ;
        System.debug('validationDate::'+validationDate);
        String taskName='T210 - Fiscal Agreement without an open authorization for more than 90 days'; 
        if(!Test.isRunningTest())
            return Database.getQueryLocator('SELECT WhoId, WhatId, Subject, Id, ActivityDate, Status, Priority,  Description, Type, CreatedDate, CreatedById FROM Task where Subject=:taskName and DAY_ONLY(createddate)='+validationDate  );   
        else
            return Database.getQueryLocator('SELECT WhoId, WhatId, Subject, Id, ActivityDate, Status, Priority,  Description, Type, CreatedDate, CreatedById FROM Task' );       
    }
    
    global void execute(Database.BatchableContext BC, List<Task> scope){
        Set<Id> fiscalAgreementIds= new Set<Id>();
        List<Task> tasksToBeCreated = new List<Task>();
        if(null!=scope&&!scope.isEmpty()){
            System.debug('Size of Scope in T211 Task Creation Execute:'+scope.size());
            for(Task tsk:scope){
                //System.debug('CreatedDate::'+tsk.createddate);
                //System.debug('Subject::'+tsk.subject);
                fiscalAgreementIds.add(tsk.WhatId);
            }
        }
        Map<Id,T_PROVR_FISCAL_AGREMENT__c> fas;
        if(!fiscalAgreementIds.isEmpty()){
            fas=new Map<Id,T_PROVR_FISCAL_AGREMENT__c>([SELECT Id, Name, ID_SERVICE__r.Name,ID_SERVICE__r.CDE_COUNTY_OWNER__r.Name, CDE_COUNTY__r.Name,Owner.Name,DTE_END_AGRMT__c,CDE_COUNTY__c
                                                        FROM T_PROVR_FISCAL_AGREMENT__c
                                                        WHERE Id in:fiscalAgreementIds AND CDE_TYPE_STATUS__c != 'CLS']);
        }
        
        if(null!=fas&&!fas.isEmpty()){
            System.debug('Size of FAs in T211 Task execute:'+fas.size());
            List<Task> existingTask=[SELECT Id, Status, WhoId, WhatId, Subject FROM Task where whatId in:fiscalAgreementIds and status!='Completed' AND Subject like 'T211%' AND DAY_ONLY(CreatedDate) = TODAY];
            if(existingTask!=null&&!existingTask.isEmpty()){
                for(Task t:existingTask){
                    if(fas.containsKey(t.whatId))
                        fas.remove(t.whatId);
                }
            }
            for(T_PROVR_FISCAL_AGREMENT__c faObj: fas.values()){
                Task tsk = new Task();
                tsk.Subject = 'T211 - Fiscal Agreement without an open authorization for more than 90 days';
                tsk.WhatId = faObj.Id;
                if(!Test.isRunningTest())
                    tsk.OwnerId = String.valueOf(System.Label.qe_provider_task_asignee);
                tsk.Status = 'New';
                tsk.Priority = 'Normal';
                tsk.ActivityDate= System.today().addDays(5);
                tsk.Description = 'The provider '+faObj.ID_SERVICE__r.Name+'('+getHyperlink(faObj.ID_SERVICE__c)+') has not had an active authorization for '+faObj.Name+'('+getHyperlink(faObj.Id)+') for more than 90 days. 11 days ago '+faObj.Owner.Name;
                if(null!=faObj.ID_SERVICE__r.CDE_COUNTY_OWNER__r.Name){
                    tsk.Description=tsk.Description+' in '+faObj.ID_SERVICE__r.CDE_COUNTY_OWNER__r.Name;
                }
                tsk.Description=tsk.Description+' was notified to take necessary action to close the Fiscal Agreement';
                if(null!=faObj.DTE_END_AGRMT__c )
                    tsk.Description=tsk.Description+' with '+String.valueOf(faObj.DTE_END_AGRMT__c).split(' ')[0]+'.';
                taskstoBeCreated.add(tsk);
            }
        }
        if(!tasksToBeCreated.isEmpty()){
            System.debug('Tasks to be inserted for 211:'+taskstoBeCreated.size());
            GenericDMLHandler.insertRecords(taskstoBeCreated, true, new Map<String,Object>{'Method__c'=>'createTasks','Class__c'=>'T211TaskCreationBatch'});
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }
    public String getHyperlink(Id recordId){
        return URL.getOrgDomainUrl().toExternalForm()+'/'+recordId;
    }
}