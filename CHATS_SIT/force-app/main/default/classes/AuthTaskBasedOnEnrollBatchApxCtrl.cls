/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/25/2022                                                          
*  @description    Authorization batch class for T555 generation                          
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Oct-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class AuthTaskBasedOnEnrollBatchApxCtrl implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        Date beginBeforeTenDayInPastDate = system.today()-9; // this is referred in below dynamic query
        //String queryStr ='SELECT ID,Name,isFinishedFlow__c, DTE_BEGIN_EFFV_AUTH__c,CreatedById, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where DTE_END_EFFV_AUTH__c <=:todayDate ';//+todayDate;
        // Query Authorization for last one week and end date less than today.
        String queryStr;
        if(!Test.isRunningTest()){
            queryStr ='SELECT ID,Name,IDN_CASE__r.OwnerId,IDN_CASE__r.Name,IDN_CASE__c,IDN_PROVR__r.Name,IDN_PROVR__c,IDN_CLIENT__r.Name,IDN_CLIENT__c,isFinishedFlow__c,Authorization_Status__c, DTE_BEGIN_EFFV_AUTH__c, CreatedById, createdDate, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where DTE_BEGIN_EFFV_AUTH__c <=:beginBeforeTenDayInPastDate and DTE_END_EFFV_AUTH__c >=:todayDate' ;
        }else{
            queryStr ='SELECT ID,Name,IDN_CASE__r.OwnerId,IDN_CASE__r.Name,IDN_CASE__c,IDN_PROVR__r.Name,IDN_PROVR__c,IDN_CLIENT__r.Name,IDN_CLIENT__c,isFinishedFlow__c,Authorization_Status__c, DTE_BEGIN_EFFV_AUTH__c, CreatedById, createdDate, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where  DTE_END_EFFV_AUTH__c >=:todayDate' ;
        }system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_AUTH__c> authList){
        try{
            Set<String> authExternalId = new Set<String>();
            List<Task> taskstoBeCreated = new List<Task>();
             Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ChildEnrollmentServices','Method__c'=>'createT557Tasks'};
            String authIdTest;
            Set<Id> clientIDSet = new Set<Id>();
            Set<Id> providerIDSet = new Set<Id>();
            T_CHATS_CHILD_ENROLLMENT__c enroll;
            Map<string,List<T_CHATS_CHILD_ENROLLMENT__c> > childEnrollToBeOldMap = new Map<string,List<T_CHATS_CHILD_ENROLLMENT__c> >();
            //Removed unused variable on 5/13/2018 BG         
            for(T_AUTH__c auth :authList){
                if((auth.DTE_BEGIN_EFFV_AUTH__c < Date.valueOf(auth.createdDate) && Date.valueOf(auth.createdDate.addDays(10))<=Date.Today()) || auth.DTE_BEGIN_EFFV_AUTH__c >= Date.valueOf(auth.createdDate)){
                    authExternalId.add(auth.IDN_EXTNL__c);
                    clientIDSet.add(auth.IDN_CLIENT__c);
                    providerIDSet.add(auth.IDN_PROVR__c);
                }
            }      
            for(T_CHATS_CHILD_ENROLLMENT__c enrollObj :[select id,Enroll_Flag__c,IDN_PROVR__c,IDN_CLIENT__c from T_CHATS_CHILD_ENROLLMENT__c where IDN_CLIENT__c in:clientIDSet and IDN_PROVR__c in:providerIDSet and Enroll_Flag__c= 'Neutral' AND IsWavierProvider__c =FALSE]){
                string key = enrollObj.IDN_PROVR__c +'_'+enrollObj.IDN_CLIENT__c;
                if(childEnrollToBeOldMap.containsKey(key)){
                    List<T_CHATS_CHILD_ENROLLMENT__c> temp = childEnrollToBeOldMap.get(key);
                    temp.add(enrollObj);
                    childEnrollToBeOldMap.put(key,temp);
                }else{
                    childEnrollToBeOldMap.put(key,new List<T_CHATS_CHILD_ENROLLMENT__c>{enrollObj});
                }
            }
            Map<String,Task> taskMap = new  Map<String,Task>();
            for(Task tsk : [SELECT Id, WhatId, Subject, Status, ActivityDate FROM Task WHERE Subject = :System.Label.Task_T555_Subject]){
                taskMap.put(tsk.WhatId, tsk);
            }
            for(T_AUTH__c authorization: authList){
                String ownerId = authorization.IDN_CASE__r.OwnerId;
                string key = authorization.IDN_PROVR__c +'_'+authorization.IDN_CLIENT__c;
                Boolean validEnrollRecExist = false;
                if(childEnrollToBeOldMap.containsKey(key)){
                    for(T_CHATS_CHILD_ENROLLMENT__c obj :childEnrollToBeOldMap.get(key)){
                        if((obj.Enroll_Flag__c =='Neutral') ){
                            validEnrollRecExist = true;
                        }
                    }
                    if(validEnrollRecExist && (!taskMap.containsKey(authorization.Id))){
                        //Generate task T555
                        Task tsk = new Task();
                        tsk.Subject = System.Label.Task_T555_Subject;
                        tsk.WhatId = authorization.Id;
                        tsk.OwnerId = ownerId;
                        tsk.Status = 'New';
                        tsk.Priority = 'Normal';
                        tsk.ActivityDate = system.today().addDays(10);
                        tsk.Description = 'The provider '+authorization.IDN_PROVR__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_CHATS_PROVR_STATUS__c/'+authorization.IDN_PROVR__c
                            +'/view ) ' +' did not take any action to confirm authorization '+ authorization.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_AUTH__c/'+authorization.id
                            +'/view ) '+' for individual '+authorization.IDN_CLIENT__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_INDIV__c/'+authorization.IDN_CLIENT__c
                            +'/view ) '+' on case '+ authorization.IDN_CASE__r.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_CASE__c/'+authorization.IDN_CASE__c
                            +'/view ) '+' within 10 calendar days of the authorization creation date (or the authorization begin date if it is an authorization with a begin date in the future). Please contact the caretaker to see if this is an active authorization and take action on the authorization as necessary.';
                        
                        //tsk.Description = CHATSUtility.mergeText(authorization, System.Label.Task_T555_Description);
                        taskstoBeCreated.add(tsk);
                    }
                }else{
                    //This scenario shouldn't exist
                }                
            }
            if(taskstoBeCreated.size()>0){
                //Database.DMLOptions dm = new Database.DMLOptions();
            //dm.EmailHeader.triggerUserEmail=true;
            //dm.optAllOrNone = false;
            //GenericDMLHandler.insertRecordsWithEmailTrigger(taskstoBeCreated,dm,methodInfo);
                GenericDMLHandler.insertRecords(taskstoBeCreated,false,methodInfo);
        }
        }catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'AuthTaskBasedOnEnrollBatchApxCtrl';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'Authorization Batch for auth'+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
    global void finish(Database.BatchableContext bc){
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors,new Map<String,Object>{'Method__c'=>'authTerminate','Class__c'=>'AuthorizationBatchApxCtrl'});
            //insert errors;
        }
    }    
}