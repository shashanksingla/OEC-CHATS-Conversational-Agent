/*************************************************************
Class Name	    - ApplicationProcessQueueInvokable_Test
Covering Class	- ApplicationProcessQueueInvokable
Author          - Rishav Maji
**************************************************************/
@isTest
public with sharing class ApplicationProcessQueueInvokable_Test {
    
    public static testMethod void exceptionTestMethod(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            try {
                ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(null);
                ApplicationProcessQueueInvokable.createT113Task(null);
            } catch (Exception e) {
                return;
            }
        }
    }
    
    static testMethod void testMethod1(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Eligibility Worker Supervisor'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName = dateString+'standarduser1@test.com', IsActive = true, Owner_County__c = '1');
        insert user1;
        User user2 = new User();
        user2 = [Select Id, Name from User Where Id =: user1.ID];
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, false);
        aCounty.OwnerId = user2.Id;
        aCounty.CDE_COUNTY__c = 1;
        insert aCounty;
        T_APPLN_PRCS_QUEUE__c appQueueRec = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec.CDE_SOURCE__c = 'PK';
        appQueueRec.CDE_STATUS_APPLN__c ='PEN';
        appQueueRec.DTE_RCVD_APPLN__c = System.today();
        appQueueRec.County_Name__c = aCounty.Id;
        appQueueRec.CDE_COUNTY__c = '1';
        insert appQueueRec; 
        
        Test.startTest();
        List<ApplicationProcessQueueInvokable.ApplicationRequest> appList = new List<ApplicationProcessQueueInvokable.ApplicationRequest>();
        ApplicationProcessQueueInvokable.ApplicationRequest app = new ApplicationProcessQueueInvokable.ApplicationRequest();
        app.methodName = 'createT113Task';
        app.recordId = (String)appQueueRec.Id;
        appList.add(app);
        ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(appList);
        Test.stopTest(); 
    }
    
    static testMethod void testMethod2(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Universal User'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standarduser2@test.com', IsActive = true, Owner_County__c = '1');
        insert user1;
        User user2 = new User();
        user2 = [Select Id, Name from User Where Id =: user1.ID];
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, false);
        aCounty.OwnerId = user2.Id;
        aCounty.CDE_COUNTY__c = 1;
        insert aCounty;
        T_APPLN_PRCS_QUEUE__c appQueueRec = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec.CDE_SOURCE__c = 'PK';
        appQueueRec.CDE_STATUS_APPLN__c ='PEN';
        appQueueRec.DTE_RCVD_APPLN__c = System.today();
        appQueueRec.County_Name__c = aCounty.Id;
        appQueueRec.CDE_COUNTY__c = '1';
        insert appQueueRec; 
        
        Test.startTest();
        List<ApplicationProcessQueueInvokable.ApplicationRequest> appList = new List<ApplicationProcessQueueInvokable.ApplicationRequest>();
        ApplicationProcessQueueInvokable.ApplicationRequest app = new ApplicationProcessQueueInvokable.ApplicationRequest();
        app.methodName = 'createT113Task';
        app.recordId = (String)appQueueRec.Id;
        appList.add(app);
        ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(appList);
        Test.stopTest();
    }
    
    static testMethod void testMethod3(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Provider Worker Supervisor'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standarduser3@test.com', IsActive = true, Owner_County__c = '1');
        insert user1;
        User user2 = new User();
        user2 = [Select Id, Name from User Where Id =: user1.ID];
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, false);
        aCounty.OwnerId = user2.Id;
        aCounty.CDE_COUNTY__c = 1;
        insert aCounty;
        
        T_APPLN_PRCS_QUEUE__c appQueueRec = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec.CDE_SOURCE__c = 'PK';
        appQueueRec.CDE_STATUS_APPLN__c ='PEN';
        appQueueRec.DTE_RCVD_APPLN__c = System.today();
        appQueueRec.County_Name__c = aCounty.Id;
        appQueueRec.CDE_COUNTY__c = '1';
        insert appQueueRec; 
        
        Test.startTest();
        List<ApplicationProcessQueueInvokable.ApplicationRequest> appList = new List<ApplicationProcessQueueInvokable.ApplicationRequest>();
        ApplicationProcessQueueInvokable.ApplicationRequest app = new ApplicationProcessQueueInvokable.ApplicationRequest();
        app.methodName = 'createT113Task';
        app.recordId = (String)appQueueRec.Id;
        appList.add(app);
        ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(appList);
        Test.stopTest();
    }
    
    static testMethod void testMethod4(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Fiscal Worker Supervisor'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standarduser4@test.com', IsActive = true, Owner_County__c = '1');
        insert user1;
        User user2 = new User();
        user2 = [Select Id, Name from User Where Id =: user1.ID];
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, false);
        aCounty.OwnerId = user2.Id;
        aCounty.CDE_COUNTY__c = 1;
        insert aCounty;
        T_APPLN_PRCS_QUEUE__c appQueueRec = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec.CDE_SOURCE__c = 'PK';
        appQueueRec.CDE_STATUS_APPLN__c ='PEN';
        appQueueRec.DTE_RCVD_APPLN__c = System.today();
        appQueueRec.County_Name__c = aCounty.Id;
        appQueueRec.CDE_COUNTY__c = '1';
        insert appQueueRec; 
        
        Test.startTest();
        List<ApplicationProcessQueueInvokable.ApplicationRequest> appList = new List<ApplicationProcessQueueInvokable.ApplicationRequest>();
        ApplicationProcessQueueInvokable.ApplicationRequest app = new ApplicationProcessQueueInvokable.ApplicationRequest();
        app.methodName = 'createT113Task';
        app.recordId = (String)appQueueRec.Id;
        appList.add(app);
        ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(appList);
        Test.stopTest();
    }
    
    static testMethod void testMethod5(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Business Office Worker'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standarduser5@test.com', IsActive = true, Owner_County__c = '1');
        insert user1;
        User user2 = new User();
        user2 = [Select Id, Name from User Where Id =: user1.ID];
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, false);
        aCounty.OwnerId = user2.Id;
        aCounty.CDE_COUNTY__c = 1;
        insert aCounty;
        T_APPLN_PRCS_QUEUE__c appQueueRec = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec.CDE_SOURCE__c = 'PK';
        appQueueRec.CDE_STATUS_APPLN__c ='PEN';
        appQueueRec.DTE_RCVD_APPLN__c = System.today();
        appQueueRec.County_Name__c = aCounty.Id;
        appQueueRec.CDE_COUNTY__c = '1';
        insert appQueueRec; 
        
        Test.startTest();
        List<ApplicationProcessQueueInvokable.ApplicationRequest> appList = new List<ApplicationProcessQueueInvokable.ApplicationRequest>();
        ApplicationProcessQueueInvokable.ApplicationRequest app = new ApplicationProcessQueueInvokable.ApplicationRequest();
        app.methodName = 'createT113Task';
        app.recordId = (String)appQueueRec.Id;
        appList.add(app);
        ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(appList);
        Test.stopTest();
    }
    
    static testMethod void testMethod6(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Read Only User'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standarduser6@test.com', IsActive = true, Owner_County__c = '1');
        insert user1;
        User user2 = new User();
        user2 = [Select Id, Name from User Where Id =: user1.ID];
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, false);
        aCounty.OwnerId = user2.Id;
        aCounty.CDE_COUNTY__c = 1;
        insert aCounty;
        T_APPLN_PRCS_QUEUE__c appQueueRec = new T_APPLN_PRCS_QUEUE__c();
        appQueueRec.CDE_SOURCE__c = 'PK';
        appQueueRec.CDE_STATUS_APPLN__c ='PEN';
        appQueueRec.DTE_RCVD_APPLN__c = System.today();
        appQueueRec.County_Name__c = aCounty.Id;
        appQueueRec.CDE_COUNTY__c = '1';
        insert appQueueRec; 
        
        Test.startTest();
        List<ApplicationProcessQueueInvokable.ApplicationRequest> appList = new List<ApplicationProcessQueueInvokable.ApplicationRequest>();
        ApplicationProcessQueueInvokable.ApplicationRequest app = new ApplicationProcessQueueInvokable.ApplicationRequest();
        app.methodName = 'createT113Task';
        app.recordId = (String)appQueueRec.Id;
        appList.add(app);
        ApplicationProcessQueueInvokable.invokeApplicationProcessQueueApex(appList);
        Test.stopTest();
    }
}