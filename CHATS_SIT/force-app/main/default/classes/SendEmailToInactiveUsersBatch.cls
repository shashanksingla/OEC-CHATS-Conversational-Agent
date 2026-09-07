/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           08/25/2022
*  @description    Batch class to send an email to users who have not logged in LAST 30 DAYS
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 25-August-2022
*  * Author: Jyoti Tyagi, Rishav Maji
*  * Description: Initial version created for Project 359, JIRA CCCAP-5489
*********************************************************************************************/
global class SendEmailToInactiveUsersBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public List<Exception_Log__c> errors = new List<Exception_Log__c>();
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new SendEmailToInactiveUsersBatch());
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id recordTypeId = Schema.SObjectType.Communication_Log__c.getRecordTypeInfosByName().get('Last30DaysInActiveUsers').getRecordTypeId();
        List<Communication_Log__c> lstCommunicationUser = [SELECT User__c FROM Communication_Log__c WHERE Send_Email__c = true AND RecordTypeId =: recordTypeId WITH SECURITY_ENFORCED];
        List<String> lstUserId = new List<String>();
        for(Communication_Log__c objLog : lstCommunicationUser) {
            lstUserId.add(objLog.User__c);
        }
        String query;
        if(Test.isRunningTest()){
            query = 'SELECT Id, LastLoginDate, Email FROM User WHERE IsActive = true AND ((LastLoginDate != LAST_N_DAYS:30 AND LastLoginDate != null) OR (LastLoginDate = null AND CreatedDate != LAST_N_DAYS:30)) AND Id Not IN :lstUserId AND Name NOT IN (\'Automated Process\') LIMIT 10';
        } else {
            query = 'SELECT Id, LastLoginDate, Email FROM User WHERE IsActive = true AND ((LastLoginDate != LAST_N_DAYS:30 AND LastLoginDate != null) OR (LastLoginDate = null AND CreatedDate != LAST_N_DAYS:30)) AND Id Not IN :lstUserId AND Name NOT IN (\'Automated Process\')';  
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<User> usrList) {
        try {
            List<Communication_Log__c> lstCommunicationLogInsert = new List<Communication_Log__c>();
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Id recordTypeId = Schema.SObjectType.Communication_Log__c.getRecordTypeInfosByName().get('Last30DaysInActiveUsers').getRecordTypeId();
            List<OrgWideEmailAddress> owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'CHATS Support Team (Do Not Reply)' WITH SECURITY_ENFORCED];
            EmailTemplate emailTemplate = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'InactiveUser_30Days_Template' WITH SECURITY_ENFORCED LIMIT 1];
            
            for(User usr : usrList){
                if(Schema.sObjectType.Communication_Log__c.fields.Email_Subject__c.isCreateable() && Schema.sObjectType.Communication_Log__c.fields.Template_Body__c.isCreateable() &&
                   Schema.sObjectType.Communication_Log__c.fields.User__c.isCreateable() && Schema.sObjectType.Communication_Log__c.fields.To_Email__c.isCreateable() && 
                   Schema.sObjectType.Communication_Log__c.fields.From_Email__c.isCreateable() && Schema.sObjectType.Communication_Log__c.fields.CC_Address__c.isCreateable() && 
                   Schema.sObjectType.Communication_Log__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Communication_Log__c.fields.Send_Email__c.isCreateable() && 
                   Schema.sObjectType.Communication_Log__c.isCreateable()){
                       Communication_Log__c objCommunicationNub = new Communication_Log__c();
                       objCommunicationNub.Email_Subject__c = emailTemplate.Subject;
                       objCommunicationNub.Template_Body__c = emailTemplate.Body;
                       objCommunicationNub.User__c = usr.Id;
                       objCommunicationNub.To_Email__c = usr.Email;
                       objCommunicationNub.From_Email__c = User_and_Email_Settings__c.getInstance('Support Helpdesk Email').Value__c;
                       objCommunicationNub.CC_Address__c = User_and_Email_Settings__c.getInstance('Support Helpdesk Email').Value__c;
                       objCommunicationNub.RecordTypeId = recordTypeId;
                       objCommunicationNub.Send_Email__c = true;
                       lstCommunicationLogInsert.add(objCommunicationNub);
                       
                       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                       mail.setToAddresses(new List<String>{usr.Email});
                       mail.setCcAddresses(new List<String>{User_and_Email_Settings__c.getInstance('Support Helpdesk Email').Value__c});
                       mail.setSubject(emailTemplate.Subject);
                       mail.setHtmlBody(emailTemplate.HtmlValue);
                       if(!owa.isEmpty()){
                           mail.setOrgWideEmailAddressId(owa[0].Id);
                       }
                       mails.add(mail);
                   }
            }
            if(!lstCommunicationLogInsert.isEmpty()) {
                GenericDMLHandler.insertRecords(lstCommunicationLogInsert, new Map<String, Object>{'Method__c'=>'execute','Class__c'=>'SendEmailToInactiveUsersBatch'});
            }
            if(!mails.isEmpty()){
                Messaging.sendEmail(mails);
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'SendEmailToInactiveUsersBatch', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'SendEmailToInactiveUsersBatch'});
        }
    }
}