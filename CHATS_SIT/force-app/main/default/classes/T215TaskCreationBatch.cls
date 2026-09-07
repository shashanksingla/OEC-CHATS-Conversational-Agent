/*************************************************************
Class Name      - T215TaskCreationBatch 
Test Class      - T215TaskCreationBatch_Test
Description     - Task to remind users to review adjustments for tax intercept
Author          - Rishav Maji
Requiremnt      - Project 282 : CCCAP-4373
**************************************************************/
global with sharing class T215TaskCreationBatch implements Database.Batchable<sObject>, Database.Stateful {

    public List<Exception_Log__c> errors = new List<Exception_Log__c>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String currentYear = String.valueOf(System.today().year());
        String queryStr ='SELECT Id, Tax_Year__c, County__r.Name, Provider__c, Provider__r.Name, Case__c, Case__r.Name FROM Tax_Intercept__c WHERE Tax_Year__c =: currentYear';
        return Database.getQueryLocator(queryStr);
    }

    global void execute(Database.BatchableContext bc, List<Tax_Intercept__c> scope) {
        try {
            List<Task> finalTaskToInsert = new List<Task>(); // Final Tasks to be inserted
            List<Messaging.SingleEmailMessage> taskEmaillist = new List<Messaging.SingleEmailMessage>(); // Final Emails to be sent
            Map<String, Set<String>> caseProviderCountyMap = new Map<String, Set<String>>();
            Map<String, String> interceptQueueMap = new Map<String, String>();
            Map<String, Set<String>> queueMemberMap = new Map<String, Set<String>>();
            Set<String> totalUserIdList = new Set<String>();
            Map<String, User> userEmailMap = new Map<String, User>();
            Map<String, String> providerIdNameMap = new Map<String, String>();
            Map<String, String> caseIdNameMap = new Map<String, String>();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Task_Assignment_Custom_Template' LIMIT 1];
            Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);

            // Preparing Case/Provider IDs from scope
            for(Tax_Intercept__c ti : scope){
                String caseOrProviderId;
                if(!String.isBlank(ti.Provider__c) && String.isBlank(ti.Case__c)){
                    caseOrProviderId = ti.Provider__c;
                    providerIdNameMap.put(ti.Provider__c, ti.Provider__r.Name);
                }
                if(String.isBlank(ti.Provider__c) && !String.isBlank(ti.Case__c)){
                    caseOrProviderId = ti.Case__c;
                    caseIdNameMap.put(ti.Case__c, ti.Case__r.Name);
                }
                // Logic to handel single Case or Provider which have different county Tax Intercepts
                if(caseProviderCountyMap.containsKey(caseOrProviderId)){
                    Set<String> countySet = caseProviderCountyMap.get(caseOrProviderId);
                    if(!countySet.contains(ti.County__r.Name)){
                        countySet.add(ti.County__r.Name);
                    }
                    caseProviderCountyMap.put(caseOrProviderId, countySet);
                } else {
                    Set<String> countySet = new Set<String>{ti.County__r.Name};
                    caseProviderCountyMap.put(caseOrProviderId, countySet);
                }
            }
            // Fetching all Tax Intercept queue Ids
            for(Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE '%State_Tax_Intercept_Team']){
                interceptQueueMap.put(g.DeveloperName, g.Id);
            }
            // Fetching all members of all Tax Intercept queues
            for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE '%State_Tax_Intercept_Team' ORDER BY Group.DeveloperName]){
                if(queueMemberMap.containsKey(gm.GroupId)){
                    Set<String> memberList = queueMemberMap.get(gm.GroupId);
                    if(!memberList.contains(gm.UserOrGroupId)){
                        memberList.add(gm.UserOrGroupId);
                        totalUserIdList.add(gm.UserOrGroupId);
                    }
                    queueMemberMap.put(gm.GroupId, memberList);
                } else {
                    Set<String> memberList = new Set<String>{gm.UserOrGroupId};
                    totalUserIdList.add(gm.UserOrGroupId);
                    queueMemberMap.put(gm.GroupId, memberList);
                }
            }
            // Fetching emails of all Tax Intercept queue members
            for(User u : [SELECT Id, Email, Name FROM User WHERE Id IN: totalUserIdList]){
                userEmailMap.put(u.Id, u);
            }
            // Preparing Task data
            for(String whatId : caseProviderCountyMap.keySet()){
                for(String countyName : caseProviderCountyMap.get(whatId)){
                    Task t = new Task();
                    t.Subject = Label.Task_T215_Subject;
                    t.Description = Label.Task_T215_Description;
                    t.ActivityDate = Date.newInstance(System.today().year(), 10, 31);
                    t.WhatId = whatId;
                    t.OwnerId = InterceptQueueMap.get(countyName.replace(' ', '_') + '_State_Tax_Intercept_Team');
                    finalTaskToInsert.add(t);

                    // Preparing Email data
                    for(String queueMember : queueMemberMap.get(t.OwnerId)){
                        User u = userEmailMap.get(queueMember);
                        String htmlMailBody = emailTemplate.HtmlValue;
                        htmlMailBody = htmlMailBody.replace('{!recipientName}', u.Name);
                        htmlMailBody = htmlMailBody.replace('{!taskSubject}', Label.Task_T215_Subject);
                        if(providerIdNameMap.containsKey(whatId)){
                            htmlMailBody = htmlMailBody.replace('{!objectName}', 'Provider');
                            htmlMailBody = htmlMailBody.replace('{!recordName}', providerIdNameMap.get(whatId));
                        }
                        if(caseIdNameMap.containsKey(whatId)){
                            htmlMailBody = htmlMailBody.replace('{!objectName}', 'Case');
                            htmlMailBody = htmlMailBody.replace('{!recordName}', caseIdNameMap.get(whatId));
                        }
                        htmlMailBody = htmlMailBody.replace('{!taskDueDate}', t.ActivityDate.month() + '/' + t.ActivityDate.day() + '/' + t.ActivityDate.year());
                        htmlMailBody = htmlMailBody.replace('{!taskPriority}', 'Normal');
                        htmlMailBody = htmlMailBody.replace('{!taskDescription}', Label.Task_T215_Description);
                        htmlMailBody = htmlMailBody.replace('{!recordURL}', baseUrl + '/' + whatId);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new List<String>{u.Email});
                        mail.setSubject(Label.Task_T215_Subject);
                        mail.setHtmlBody(htmlMailBody);
                        if(owEmailAddressId != null){
                            mail.setOrgWideEmailAddressId(owEmailAddressId);
                        }
                        taskEmaillist.add(mail);
                    }
                }
            }
            // DML for final Tasks and sending Emails
            if(!finalTaskToInsert.isEmpty()){
                Database.insert(finalTaskToInsert, false);
                Messaging.sendEmail(taskEmaillist);
            }
        } catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'T215TaskCreationBatch';
            xLog.Method__c = 'execute';
            xLog.Exception_Message__c = e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }

    global void finish(Database.BatchableContext bc) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'T215TaskCreationBatch'});
        }
    }

}