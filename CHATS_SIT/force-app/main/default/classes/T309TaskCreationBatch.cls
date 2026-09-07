/*************************************************************
Class Name      - T309TaskCreationBatch
Test Class      - T309TaskCreationBatch_Test
Description     - Task to remind users to initiate Redetermination once packet Received date is not null
Author          - Shashank Singla
Requiremnt      - CCCAP-9179
**************************************************************/
global with sharing class T309TaskCreationBatch implements Database.Batchable<sObject>, Database.Stateful, schedulable {
    
    global static List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        date past_13_day = Date.today()-13;
        String queryStr ='SELECT Id,DTE_RCVD_PACKET_REDET__c,DTE_SENT_PACKET_REDET__c from T_SBSD_CASE__c where DTE_RCVD_PACKET_REDET__c=:past_13_day';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_SBSD_CASE__c> scope) {
        try {
            List<Task> tasksToInsert = new List<Task>();
            Set<Id> selCases = new Set<Id>();
            // Preparing Case/Provider IDs from scope
            for(T_SBSD_CASE__c cs : scope){
                if(cs.DTE_RCVD_PACKET_REDET__c > cs.DTE_SENT_PACKET_REDET__c){
                    selCases.add(cs.Id);
                }                
            }
            Set<Id> REDfound = new Set<Id>();
            Map<Id,T_SBSD_CASE__c> caseModeIdVsCase = new Map<Id,T_SBSD_CASE__c>();
            for(T_SBSD_CASE__c csRecord : [select id,DTE_RCVD_PACKET_REDET__c ,Name,OwnerId, (select name,DTE_BEGIN_EFFV__c,CDE_MODE_CASE__c from T_SBSD_CASE10__r order by createddate desc) from T_SBSD_CASE__c where id In:selCases]){
                if(!csRecord.T_SBSD_CASE10__r.isEmpty()){
                    for(T_SBSD_CASE_STATUS_MODE__c csMode: csRecord.T_SBSD_CASE10__r){
                        caseModeIdVsCase.put(csMode.Id,csRecord);
                    }
                }
            }
            // if same case status mode is being modified for status(RED) after packet received date then below logic will detect that
            for(T_SBSD_CASE_STATUS_MODE__History csmH: [select  parentId,OldValue, NewValue,createdDate from T_SBSD_CASE_STATUS_MODE__History 
                                                        where ParentId IN:caseModeIdVsCase.keyset() and Field ='CDE_MODE_CASE__c']){
                                                            if(csmH.NewValue == 'RED' || (csmH.OldValue == 'RED' && csmH.NewValue == 'ONG')){
                                                              T_SBSD_CASE__c chatsCase = caseModeIdVsCase.get(csmH.ParentId);
                                                                if(csmH.CreatedDate >= chatsCase.DTE_RCVD_PACKET_REDET__c){
                                                                    REDfound.add(caseModeIdVsCase.get(csmH.parentId).Id); // RED record found after pckt received date                                                                    
                                                                }
                                                            }
                                                        }
            for(T_SBSD_CASE__c csRecord : [select id,DTE_RCVD_PACKET_REDET__c ,Name,OwnerId, 
                                           (select name,DTE_BEGIN_EFFV__c,CDE_MODE_CASE__c,createddate from T_SBSD_CASE10__r order by createddate desc)
                                           from T_SBSD_CASE__c where id In:selCases]){
                                               boolean noREDfound = !REDfound.contains(csRecord.Id);
                                               for(T_SBSD_CASE_STATUS_MODE__c csMode : csRecord.T_SBSD_CASE10__r){
                                                   if(csMode.CDE_MODE_CASE__c == 'RED' 
                                                      && (csMode.DTE_BEGIN_EFFV__c >=csRecord.DTE_RCVD_PACKET_REDET__c || csMode.createddate >=csRecord.DTE_RCVD_PACKET_REDET__c)){
                                                       noREDfound = false;
                                                   }
                                               }
                                               if(noREDfound){ //if no track of RED found , create Task T309
                                                   tasksToInsert.add(new Task(
                                                       OwnerId		=	csRecord.OwnerId,
                                                       description 	= 'The redetermination for '+csRecord.Name + '  has not been processed. Please process the packet and put the case into redetermination mode.',
                                                       Subject		=	'T309 Redetermination packet received date is 12 days ago',
                                                       Status		=	'Not Started',
                                                       WhatId		=	csRecord.Id,
                                                       ActivityDate =  csRecord.DTE_RCVD_PACKET_REDET__c+15));
                                               }
                                           }
            // DML for final Tasks and sending Emails
            if(!tasksToInsert.isEmpty()){
                Database.insert(tasksToInsert, false);
            }
        } catch(Exception e) {
            setException(e);
        }
    }
    global void finish(Database.BatchableContext bc) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'T309TaskCreationBatch'});
        }
    }
    global void execute(SchedulableContext sc){
        database.executebatch(new T309TaskCreationBatch(), 200);
    }
    @testVisible
    private static void setException(Exception e){
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'T309TaskCreationBatch';
        xLog.Method__c = 'execute';
        xLog.Exception_Message__c = e.getMessage();
        xLog.Exception_Type__c = 'Error';
        errors.add(xLog);
    }
}