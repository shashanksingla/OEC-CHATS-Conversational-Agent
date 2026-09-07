/*************************************************************
Class Name      - SupportCommentTrigger_Test
Description     - Test class for SupportCommentTrigger and SupportServices.sendBellNotificationSupportComment
**************************************************************/
@isTest
public class SupportCommentTrigger_Test {
    
    @TestSetup
    static void setupTestData() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Assignee',
            Email = 'testassignee@test.com',
            Username = 'testassignee' + DateTime.now().getTime() + '@test.com',
            Alias = 'tassign',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        User awaitingUser = new User(
            FirstName = 'Awaiting',
            LastName = 'User',
            Email = 'awaitinguser@test.com',
            Username = 'awaitinguser' + DateTime.now().getTime() + '@test.com',
            Alias = 'awaitu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert awaitingUser;
    }
    
    @isTest
    static void testInsertSupportComment() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testassignee@test.com' LIMIT 1];
        Id supportTicketRecTypeId = Schema.SObjectType.CHATS_Support__c.getRecordTypeInfosByName().get('Support Ticket').getRecordTypeId();
        CHATS_Support__c supportRecord = new CHATS_Support__c(
            RecordTypeId = supportTicketRecTypeId,
            Status__c = 'New',
            Support_Team_Assignee__c = testUser.Id,
            Support_Category__c = 'System',
            Support_Type__c = 'System Issue/Request',
            Expected_Results__c = 'test results',
            Actual_Results__c ='test results',
            Page_URL__c ='url'
        );
        insert supportRecord;
        
        Test.startTest();
        CHATS_Support_Comment__c supportComment = new CHATS_Support_Comment__c(
            CHATS_Support_Number__c = supportRecord.Id,
            Communication_Log__c = 'Test communication log entry'
        );
        insert supportComment;
        Test.stopTest();
        
        List<CHATS_Support_Comment__c> insertedComments = [
            SELECT Id, Communication_Log__c, CHATS_Support_Number__c 
            FROM CHATS_Support_Comment__c 
            WHERE Id = :supportComment.Id
        ];
        System.assertEquals(1, insertedComments.size(), 'Support Comment should be inserted');
        System.assertEquals('Test communication log entry', insertedComments[0].Communication_Log__c, 'Communication Log should match');
    }
    
    @isTest
    static void testUpdateSupportComment() {
        User awaitingUser = [SELECT Id FROM User WHERE Email = 'awaitinguser@test.com' LIMIT 1];
        Id supportTicketRecTypeId = Schema.SObjectType.CHATS_Support__c.getRecordTypeInfosByName().get('Support Ticket').getRecordTypeId();
        CHATS_Support__c supportRecord = new CHATS_Support__c(
            RecordTypeId = supportTicketRecTypeId,
            Status__c = 'Awaiting User',
            Awaiting_User__c = awaitingUser.Id,
            Support_Category__c = 'System',
            Support_Type__c = 'System Issue/Request',
            Expected_Results__c = 'test results',
            Actual_Results__c ='test results',
            Page_URL__c ='url'
        );
        insert supportRecord;
        
        CHATS_Support_Comment__c supportComment = new CHATS_Support_Comment__c(
            CHATS_Support_Number__c = supportRecord.Id,
            Communication_Log__c = 'Initial log for awaiting user'
        );
        insert supportComment;
        
        Test.startTest();
        supportComment.Communication_Log__c = 'Updated log for awaiting user';
        update supportComment;
        Test.stopTest();
        
        CHATS_Support_Comment__c updatedComment = [
            SELECT Id, Communication_Log__c 
            FROM CHATS_Support_Comment__c 
            WHERE Id = :supportComment.Id
        ];
        System.assertEquals('Updated log for awaiting user', updatedComment.Communication_Log__c, 'Communication Log should be updated');
    }
}