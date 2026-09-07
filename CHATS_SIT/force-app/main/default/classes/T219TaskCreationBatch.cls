/*************************************************************
Class Name      - T219TaskCreationBatch
Test Class      - T219TaskCreationBatch_Test
Description     - Task to remind user that 5-year FBI fingerprinting due in Provider BG check
Author          - Rishav Maji
Requiremnt      - Project 282 : CCCAP-4768 , corrected batch logic to refer most recent 5-year FBI fingerprinting for creating reminder task for CCCAP-12701
**************************************************************/
global with sharing class T219TaskCreationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    private static Date sixtyfromToday = Date.today().addDays(60);
    global void execute(SchedulableContext ctx) {
        database.executebatch(new T219TaskCreationBatch());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String CLOSED = 'Closed';
        String provQuery = 'select Id,Name,NAM_FACILITY__c,(select id,DTE_5yearFBIDueDate__c from Providers_CBC__r where DTE_5yearFBIDueDate__c!=null order by createddate desc limit 1) from T_CHATS_PROVR_STATUS__c where id in (select IDN_PROVR__c from T_PROVR_CBC__c where DTE_5yearFBIDueDate__c=:sixtyfromToday) and CDE_STATUS_PROVR__c!=:CLOSED';
        return Database.getQueryLocator(provQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<T_CHATS_PROVR_STATUS__c> scope) {
        try {
            List<Task> taskToInsert 	= new List<Task>();
            Set<Id> provrIdList 	= new Set<Id>();
            List<User> taskOwnerList 	= new List<User>();
            User_and_Email_Settings__c ues 		= User_and_Email_Settings__c.getInstance('T219 Owner Email');
            taskOwnerList = [SELECT Id FROM User WHERE Email =: ues.Value__c AND isActive = true WITH SECURITY_ENFORCED LIMIT 1];
            if(!taskOwnerList.isEmpty()){
                User taskOwner = taskOwnerList[0];
                for(T_CHATS_PROVR_STATUS__c provr : scope){
                    provrIdList.add(provr.Id);
                }
                for(Task t : [SELECT WhatId FROM Task WHERE WhatId IN: provrIdList AND Subject LIKE '%T219%' and createddate = TODAY WITH SECURITY_ENFORCED]){
                    provrIdList.remove(t.WhatId);// To avoid Task creation when one T219 already exists
                }
                for(T_CHATS_PROVR_STATUS__c provr : scope){
                    T_PROVR_CBC__c cbc = provr.Providers_CBC__r[0];
                    if(cbc.DTE_5yearFBIDueDate__c == sixtyfromToday && provrIdList.contains(provr.Id)){
                        Task t = new Task();
                        t.Subject = (Label.Task_T219_Subject).replace('{!providerName}', provr.NAM_FACILITY__c);
                        t.Description = (Label.Task_T219_Description).replace('{!providerId}', provr.Name);
                        t.ActivityDate = System.today().addDays(10);
                        t.WhatId = provr.Id;
                        t.OwnerId = taskOwner.Id;
                        taskToInsert.add(t);
                    }
                }
                if(!taskToInsert.isEmpty()){
                    //Database.DMLOptions dmo = new Database.DMLOptions();
                    //dmo.EmailHeader.triggerUserEmail = true;
                    //dmo.optAllOrNone = false;
                    GenericDMLHandler.insertRecords(taskToInsert,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'T219TaskCreationBatch'});
                }
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'T219TaskCreationBatch', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'T219TaskCreationBatch'});
        }
    }
}