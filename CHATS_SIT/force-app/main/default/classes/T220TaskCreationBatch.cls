/*************************************************************
Class Name      - T220TaskCreationBatch
Test Class      - T220TaskCreationBatch_Test
Description     - Task to remind user to send training requirements to Provider due to an upcoming visit
Author          - Rishav Maji
Requiremnt      - Project 363 : CCCAP-5765
**************************************************************/
global with sharing class T220TaskCreationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new T220TaskCreationBatch());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date past275Days = System.today().addDays(-275);
        String queryStr ='SELECT Id, Name, DTE_VisitOccurred__c FROM T_CHATS_PROVR_STATUS__c WHERE CDE_TYPE_PROVR__c = \'EFACH\' AND DTE_VisitOccurred__c <=: past275Days';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_CHATS_PROVR_STATUS__c> scope) {
        try {
            List<Task> taskToInsert = new List<Task>();
            List<String> provrIdList = new List<String>();
            Set<String> provWithExistingTask = new Set<String>();
            List<User> taskOwnerList = new List<User>();
            User_and_Email_Settings__c ues = User_and_Email_Settings__c.getInstance('T220 Owner Email');
            taskOwnerList = [SELECT Id FROM User WHERE Email =: ues.Value__c AND isActive = true WITH SECURITY_ENFORCED LIMIT 1];
            List<String> taskOwnerEmailList = new List<String>();
            if(!taskOwnerList.isEmpty()){
                User taskOwner = taskOwnerList[0];
                for(T_CHATS_PROVR_STATUS__c provr : scope){
                    provrIdList.add(provr.Id);
                }
                // Task will not be created if one exists for the provider
                for(Task t : [SELECT WhatId, OwnerId FROM Task WHERE WhatId IN: provrIdList AND Subject LIKE '%T220%' WITH SECURITY_ENFORCED]){
                    provWithExistingTask.add(t.WhatId);
                }
                // Determining next 10th business day by skipping holiday and weekends
                String dayOfWeek = System.now().format('u');
                Date dueDate = dayOfWeek == '7' ? System.today().addDays(12) : dayOfWeek == '6' ? System.today().addDays(13) : System.today().addDays(14);
                for(T_YEAR_HOL__c hol : [SELECT DTE_HOL__c FROM T_YEAR_HOL__c WHERE DTE_HOL__c = THIS_YEAR AND DTE_HOL__c >=: dueDate]){
                    dueDate = dueDate == hol.DTE_HOL__c ? dueDate.addDays(1) : dueDate;
                }
                dayOfWeek = ((DateTime)dueDate).format('u');
                dueDate = dayOfWeek == '7' ? dueDate.addDays(1) : dayOfWeek == '6' ? dueDate.addDays(2) : dueDate;
                // Preparing Task records
                for(T_CHATS_PROVR_STATUS__c provr : scope){
                    if(!provWithExistingTask.contains(provr.Id)){
                        Task t = new Task();
                        t.Subject = Label.Task_T220_Subject;
                        t.Description = (Label.Task_T220_Description).replace('{!providerId}', provr.Name);
                        t.ActivityDate = dueDate;
                        t.WhatId = provr.Id;
                        t.OwnerId = taskOwner.Id;
                        taskToInsert.add(t);
                    }
                }
                if(!taskToInsert.isEmpty()){
                    //Database.DMLOptions dmo = new Database.DMLOptions();
                    //dmo.EmailHeader.triggerUserEmail = true;
                    //dmo.optAllOrNone = false;
                    GenericDMLHandler.insertRecords(taskToInsert,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'T220TaskCreationBatch'});
                }
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'T220TaskCreationBatch', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'T220TaskCreationBatch'});
        }
    }
}