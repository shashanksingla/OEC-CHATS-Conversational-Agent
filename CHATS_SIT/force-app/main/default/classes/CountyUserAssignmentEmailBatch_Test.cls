/*************************************************************
Class Name	    - CountyUserAssignmentEmailBatch_Test
Covering Class	- CountyUserAssignmentEmailBatch
Author          - Rishav Maji
**************************************************************/
@isTest
public with sharing class CountyUserAssignmentEmailBatch_Test {
    
    @testSetup
    public static void doSetup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('County63', 'County63', 63, true);
    }
    
    public static testMethod void Rule1_Test(){
        TestClassUtility.createCounty('County99', 'County99', 99, true);
        Test.startTest();
        database.executebatch(new CountyUserAssignmentEmailBatch());
        Test.stopTest();
    }
    
    public static testMethod void Rule2_Rule7_Test(){
        //T_COUNTY__c countyRec = TestClassUtility.createCounty('County63', 'County63', 63, true);
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Provider Worker' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(profileId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u1.Owner_County__c = '63';
        Insert u1;
        Test.startTest();
        database.executebatch(new CountyUserAssignmentEmailBatch());
        Test.stopTest();
    }
    
    public static testMethod void Rule3_Rule8_Test(){
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Fiscal Worker' LIMIT 1].Id;
        String roleId = [SELECT Id, Name FROM UserRole WHERE Name = 'IPV Supervisor' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(profileId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u1.Owner_County__c = '63';
        u1.UserRoleId = roleId;
        Insert u1;
        Test.startTest();
        database.executebatch(new CountyUserAssignmentEmailBatch());
        Test.stopTest();
    }
    
    public static testMethod void Rule4_Rule9_Test(){
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Business Office Worker' LIMIT 1].Id;
        String roleId = [SELECT Id, Name FROM UserRole WHERE Name = 'IPV Update' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(profileId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u1.Owner_County__c = '63';
        u1.UserRoleId = roleId;
        Insert u1;
        Test.startTest();
        database.executebatch(new CountyUserAssignmentEmailBatch());
        Test.stopTest();
    }
    
    public static testMethod void Rule5_Test(){
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Eligibility Worker' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(profileId, 'test1', 'test1', 'test1@example.com.invalid', 'test1@example.com.'+string.valueof(math.random()*3), 'ttes1');
        u1.Owner_County__c = '63';
        Insert u1;
        String profileId2 = [SELECT Id, Name FROM Profile WHERE Name = 'Business Office Worker' LIMIT 1].Id;
        User u2 = TestClassUtility.createUser(profileId2, 'test2', 'test2', 'test2@example.com.invalid', 'test2@example.com.'+string.valueof(math.random()*3), 'ttes2');
        u2.Owner_County__c = '63';
        Insert u2;
        String profileId3 = [SELECT Id, Name FROM Profile WHERE Name = 'Fiscal Worker' LIMIT 1].Id;
        User u3 = TestClassUtility.createUser(profileId3, 'test3', 'test3', 'test3@example.com.invalid', 'test3@example.com.'+string.valueof(math.random()*3), 'ttes3');
        u3.Owner_County__c = '63';
        Insert u3;
        Test.startTest();
        database.executebatch(new CountyUserAssignmentEmailBatch());
        Test.stopTest();
    }
    
    public static testMethod void CronTest(){
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobId = System.schedule('CountyUserAssignmentEmailBatch',  CRON_EXP, new CountyUserAssignmentEmailBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
}