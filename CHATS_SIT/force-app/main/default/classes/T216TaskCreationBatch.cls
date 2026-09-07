/*************************************************************
Class Name      - T216TaskCreationBatch 
Test Class      - T216TaskCreationBatch_Test
Description     - Task to inform worker of the availability of the Correspondence
Author          - Rishav Maji
Requiremnt      - Project 282 : CCCAP-4373
**************************************************************/
global with sharing class T216TaskCreationBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Exception_Log__c[] errors = new Exception_Log__c[0];
    @TestVisible private Date todayDate = Date.today();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryStr ='SELECT Id, IDN_CASE__c, IDN_PROVR__c, IDN_CASE__r.Name, IDN_PROVR__r.Name, CDE_COUNTY__r.Name FROM T_DOC_RQ__c WHERE NME_CORSPD__c = \'CR202\' AND DTE_REQ__c = THIS_YEAR AND CDE_CORSPD_STATUS__c = \'Generated\'';
        return Database.getQueryLocator(queryStr);
    }

    global void execute(Database.BatchableContext bc, List<T_DOC_RQ__c> scope) {
        try {
            List<Task> finalTaskToInsert = new List<Task>(); // Final Tasks to be inserted
            List<Messaging.SingleEmailMessage> taskEmaillist = new List<Messaging.SingleEmailMessage>(); // Final Emails to be sent
            Map<String, Set<String>> caseProviderCountyMap = new Map<String, Set<String>>();
            Map<String, String> interceptQueueMap = new Map<String, String>();
            List<Date> holidayList = new List<Date>();
            Map<String, Set<String>> queueMemberMap = new Map<String, Set<String>>();
            Set<String> totalUserIdList = new Set<String>();
            Map<String, User> userEmailMap = new Map<String, User>();
            Map<String, String> providerIdNameMap = new Map<String, String>();
            Map<String, String> caseIdNameMap = new Map<String, String>();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Task_Assignment_Custom_Template' LIMIT 1];
            Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);

            // Preparing Case/Provider IDs from scope
            for(T_DOC_RQ__c tDoc : scope){
                String caseOrProviderId;
                if(!String.isBlank(tDoc.IDN_PROVR__c) && String.isBlank(tDoc.IDN_CASE__c)){
                    caseOrProviderId = tDoc.IDN_PROVR__c;
                    providerIdNameMap.put(tDoc.IDN_PROVR__c, tDoc.IDN_PROVR__r.Name);
                }
                if(String.isBlank(tDoc.IDN_PROVR__c) && !String.isBlank(tDoc.IDN_CASE__c)){
                    caseOrProviderId = tDoc.IDN_CASE__c;
                    caseIdNameMap.put(tDoc.IDN_CASE__c, tDoc.IDN_CASE__r.Name);
                }
                // Logic to handel single Case or Provider which have different county Tax Intercepts
                if(caseProviderCountyMap.containsKey(caseOrProviderId)){
                    Set<String> countySet = caseProviderCountyMap.get(caseOrProviderId);
                    if(!countySet.contains(tDoc.CDE_COUNTY__r.Name)){
                        countySet.add(tDoc.CDE_COUNTY__r.Name);
                    }
                    caseProviderCountyMap.put(caseOrProviderId, countySet);
                } else {
                    Set<String> countySet = new Set<String>{tDoc.CDE_COUNTY__r.Name};
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
            // Determining next business day by skipping holiday and weekends
            Date nextBusinessDay = todayDate.addDays(1);
            DateTime dt = (DateTime)nextBusinessDay;
            String dayOfWeek = dt.format('u');
            if(dayOfWeek == '6'){ // Saturday
                nextBusinessDay = nextBusinessDay.addDays(2); // Monday
            }
            if(dayOfWeek == '7'){ // Sunday
                nextBusinessDay = nextBusinessDay.addDays(1); // Monday
            }
            for(T_YEAR_HOL__c hol : [SELECT DTE_HOL__c FROM T_YEAR_HOL__c WHERE DTE_HOL__c = THIS_YEAR AND DTE_HOL__c >=: todayDate]){
                if(nextBusinessDay == hol.DTE_HOL__c){
                    nextBusinessDay = nextBusinessDay.addDays(1);
                }
            }
            // Preparing Task data
            for(String whatId : caseProviderCountyMap.keySet()){
                for(String countyName : caseProviderCountyMap.get(whatId)){
                    Task t = new Task();
                    t.Subject = Label.Task_T216_Subject;
                    t.Description = Label.Task_T216_Description;
                    t.ActivityDate = nextBusinessDay;
                    t.WhatId = whatId;
                    t.OwnerId = InterceptQueueMap.get(countyName.replace(' ', '_') + '_State_Tax_Intercept_Team');
                    finalTaskToInsert.add(t);

                    // Preparing Email data
                    for(String queueMember : queueMemberMap.get(t.OwnerId)){
                        User u = userEmailMap.get(queueMember);
                        String htmlMailBody = emailTemplate.HtmlValue;
                        htmlMailBody = htmlMailBody.replace('{!recipientName}', u.Name);
                        htmlMailBody = htmlMailBody.replace('{!taskSubject}', Label.Task_T216_Subject);
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
                        htmlMailBody = htmlMailBody.replace('{!taskDescription}', Label.Task_T216_Description);
                        htmlMailBody = htmlMailBody.replace('{!recordURL}', baseUrl + '/' + whatId);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new List<String>{u.Email});
                        mail.setSubject(Label.Task_T216_Subject);
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
            xLog.Class__c = 'T216TaskCreationBatch';
            xLog.Method__c = 'execute';
            xLog.Exception_Message__c = e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }

    global void finish(Database.BatchableContext bc){
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'T216TaskCreationBatch'});
        }
    }

}