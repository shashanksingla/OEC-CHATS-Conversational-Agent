/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           08/25/2022
*  @description    Test class to send an email to users who have not logged in LAST 30 DAYS
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 25-August-2022
*  * Author: Jyoti Tyagi
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class SendEmailInActiveUsersTest {
    
    @testsetup static void setupData() {
        User usr = [Select Id,LastLoginDate,Email FROM User where IsActive=true And LastLoginDate != LAST_N_DAYS:30 LIMIT 1];
        Id recordTypeId  =  Schema.SObjectType.Communication_Log__c.getRecordTypeInfosByName().get('Last30DaysInActiveUsers').getRecordTypeId();
        List<Communication_Log__c> lstObject = new List<Communication_Log__c>();
        for(Integer i = 0; i < 200; i++) {
            lstObject.add(new Communication_Log__c(Email_Subject__c = 'test',Template_Body__c ='Hi,this is test email',User__c=usr.Id,To_Email__c='test@dispostable.com',Send_Email__c=true,RecordTypeId = recordTypeId));
        }
        insert lstObject;    
    }
    
    @isTest static void testInactiveUserBatch_Test1() {
        User_and_Email_Settings__c ues1 = new User_and_Email_Settings__c();
        ues1.Name = 'Support Helpdesk Email';
        ues1.Value__c = 'test@invalid.com';
        Insert ues1;
        Test.startTest();
        SendEmailToInactiveUsersBatch obj = new SendEmailToInactiveUsersBatch(); 
        DataBase.executeBatch(obj);
        Test.stopTest(); 
    }
    
    @isTest static void testInactiveUserBatch_Test2() {
        Test.startTest();
        SendEmailToInactiveUsersBatch obj = new SendEmailToInactiveUsersBatch(); 
        DataBase.executeBatch(obj);
        Test.stopTest(); 
    }
    
    static testMethod void CronTest(){
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobId = System.schedule('SendEmailToInactiveUsersBatch',  CRON_EXP, new SendEmailToInactiveUsersBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
}