/*************************************************************
Class Name      - SupportServices
Test Class      - SupportTrigger_Test
Trigger         - SupportTrigger
Description     - Trigger handler and other utility class for CHATS_Support__c object
Author          - Rishav Maji
Requirement     - Project 407 : CCCAP-6416
**************************************************************/
public with sharing class SupportServices {
    
    public static void sendEmailAndBellNotification(Map<Id, CHATS_Support__c> oldSupportMap, Map<Id, CHATS_Support__c> newSupportMap) {
        Id suppTicketRecTypeId = Schema.SObjectType.CHATS_Support__c.getRecordTypeInfosByName().get('Support Ticket').getRecordTypeId();
        List<Messaging.SingleEmailMessage> supportEmailList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.CustomNotification> supportNotificationList = new List<Messaging.CustomNotification>();
        EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Support_Help_Desk_Template_Awaiting_User' LIMIT 1];
        EmailTemplate emailTemplate2 = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Support_Help_Desk_Template' LIMIT 1];
        List<CustomNotificationType> notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Support_Ticket_Custom_Notification']; 
        List<String> awatingUserRecordIdList = new List<String>();

        Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);

        for(CHATS_Support__c supp : newSupportMap.values()) {
            CHATS_Support__c oldRecord = oldSupportMap.get(supp.Id);

            if(supp.RecordTypeId == suppTicketRecTypeId && String.isBlank(supp.Communication_Log__c) && !String.isBlank(oldRecord.Communication_Log__c)){
                continue; // CCCAP-6767: Skipping execution if triggered by 'CHATS Support comments creation' process builder
            }
            /*if(supp.RecordTypeId == suppTicketRecTypeId && supp.Ticket_Closure_Date__c == null && (supp.Status__c == 'Fixed/Completed' || supp.Status__c == 'Change Denied')){
                continue; // Skipping first mail trigger, allowing 'UpdateTicketClosureDate' workflow rule's field update to trigger mail
            }*/
            if(supp.RecordTypeId == suppTicketRecTypeId && supp.Elevated_to__c == 'Vendor Support' && oldRecord.Elevated_to__c != 'Vendor Support' && !supp.Reviewed_by_Vendor__c){
                continue; // Skipping first mail trigger, allowing 'Elevated to Vendor' workflow rule's field update to trigger mail
            }      
           if(supp.RecordTypeId == suppTicketRecTypeId && supp.Status__c == 'Awaiting User' &&  (supp.Status__c != oldRecord.Status__c || supp.Awaiting_User__c !=oldRecord.Awaiting_User__c)) 
            {
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, supp.Awaiting_User__c, supp.Id);
                mail.saveAsActivity = false;
                mail.setToAddresses(String.isBlank(supp.Awaiting_User_Email__c) ? new List<String>{User_and_Email_Settings__c.getInstance('Support Helpdesk Email').Value__c} : new List<String>{supp.Awaiting_User_Email__c});
                if(owEmailAddressId != null){
                    mail.setOrgWideEmailAddressId(owEmailAddressId);
                }
                supportEmailList.add(mail);
                if(!String.isBlank(supp.Awaiting_User__c) && !notificationType.isEmpty())
                {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle(UserInfo.getName() + ' has edited a helpdesk support ticket in Awaiting User status');
                    notification.setBody('Click on the notification to open ' + supp.Name);
                    notification.setNotificationTypeId(notificationType[0].Id);
                    notification.setTargetId(supp.Id);
                    notification.send(new Set<String>{supp.Awaiting_User__c});
                }
            }  
            else if(supp.RecordTypeId == suppTicketRecTypeId && (((supp.Status__c != oldRecord.Status__c || supp.Ticket_Closure_Date__c != oldRecord.Ticket_Closure_Date__c ) && (supp.Status__c == 'Change Denied' || supp.Status__c == 'Fixed/Completed') && supp.Ticket_Closure_Date__c != null) || supp.Status__c == 'Change Implemented')) 
            {
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate2.Id, supp.CreatedById, supp.Id);
                mail.saveAsActivity = false;
                mail.setToAddresses(new List<String>{supp.Requestor_s_Email__c});
                if(owEmailAddressId != null){
                    mail.setOrgWideEmailAddressId(owEmailAddressId);
                }
                supportEmailList.add(mail);
            }
        }
        // DML for sending Emails
        if(!supportEmaillist.isEmpty()){
            Messaging.sendEmail(supportEmailList);
        }
    }
public static void sendBellNotificationSupportComment(Map<Id, CHATS_Support_Comment__c> oldSupportMap, Map<Id, CHATS_Support_Comment__c> newSupportMap) {
        Id suppTicketRecTypeId = Schema.SObjectType.CHATS_Support__c.getRecordTypeInfosByName().get('Support Ticket').getRecordTypeId();
        List<Messaging.CustomNotification> supportNotificationList = new List<Messaging.CustomNotification>();
        List<CustomNotificationType> notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Support_Ticket_Custom_Notification'];
        Set<Id> supportIds = new Set<Id>();
        Map<id,CHATS_Support__c> suppMap = new Map<id,CHATS_Support__c>();
        for(CHATS_Support_Comment__c suppCmt : newSupportMap.values()) {
            supportIds.add(suppCmt.CHATS_Support_Number__c);
            
        }
        for(CHATS_Support__c supp :[Select id,Support_Team_Assignee__c,RecordTypeId,name,Awaiting_User__c,Status__c from CHATS_Support__c where id in:supportIds ]){
            suppMap.put(supp.id,supp);
        }
        for(CHATS_Support_Comment__c suppCmt : newSupportMap.values()) {
            CHATS_Support_Comment__c oldRecord = new CHATS_Support_Comment__c();
            if(oldSupportMap != null){
                oldRecord = oldSupportMap.get(suppCmt.Id);
            }
            CHATS_Support__c supp = suppMap.get(suppCmt.CHATS_Support_Number__c);
            if(oldRecord != null && oldSupportMap != null){
                if(supp.RecordTypeId == suppTicketRecTypeId && supp.Status__c != 'Awaiting User'  && String.isNotBlank(suppCmt.Communication_Log__c)  ) 
                {
                    if(!(suppCmt.Communication_Log__c).equals(oldRecord.Communication_Log__c)){
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle(UserInfo.getName() + ' updated a message in Support Ticket '+supp.Name +' Communication Log');
                        notification.setBody('Click on the notification to open ' + supp.Name);
                        notification.setNotificationTypeId(notificationType[0].Id);
                        notification.setTargetId(supp.Id);
                        if(!string.isBlank(supp.Support_Team_Assignee__c)){
                            notification.send(new Set<String>{supp.Support_Team_Assignee__c}); 
                        }
                    }
                }
                if(supp.RecordTypeId == suppTicketRecTypeId && supp.Status__c == 'Awaiting User'  && String.isNotBlank(suppCmt.Communication_Log__c)  ) 
                {
                    if(!(suppCmt.Communication_Log__c).equals(oldRecord.Communication_Log__c)){
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle(UserInfo.getName() + ' updated a message in Support Ticket '+supp.Name +' Communication Log');
                    notification.setBody('Click on the notification to open ' + supp.Name +' in Awaiting User status.');
                    notification.setNotificationTypeId(notificationType[0].Id);
                    notification.setTargetId(supp.Id);
                    if(!string.isBlank(supp.Support_Team_Assignee__c)){
                            notification.send(new Set<String>{supp.Support_Team_Assignee__c});
                        } 
                }
                }
            }else{
                if(supp.RecordTypeId == suppTicketRecTypeId && supp.Status__c != 'Awaiting User' && String.isNotBlank(suppCmt.Communication_Log__c)  ) 
                {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle(UserInfo.getName() + ' added a message in Support Ticket '+supp.Name +' Communication Log');
                    notification.setBody('Click on the notification to open ' + supp.Name);
                    notification.setNotificationTypeId(notificationType[0].Id);
                    notification.setTargetId(supp.Id);
                    if(!string.isBlank(supp.Support_Team_Assignee__c)){
                        notification.send(new Set<String>{supp.Support_Team_Assignee__c}); 
                    }
                }
                if(supp.RecordTypeId == suppTicketRecTypeId && supp.Status__c == 'Awaiting User'&& String.isNotBlank(suppCmt.Communication_Log__c)  ) 
                {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle(UserInfo.getName() + ' added a message in Support Ticket '+supp.Name +' Communication Log');
                    notification.setBody('Click on the notification to open ' + supp.Name +' in Awaiting User status.');
                    notification.setNotificationTypeId(notificationType[0].Id);
                    notification.setTargetId(supp.Id);
                    if(!string.isBlank(supp.Support_Team_Assignee__c)){
                        notification.send(new Set<String>{supp.Support_Team_Assignee__c});  
                    }
                }
            }
            
        }
    }
}