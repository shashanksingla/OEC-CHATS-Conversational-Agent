@isTest 
public class T108_AppQueueCheckBatch_Test {
    static testMethod void testMethod1(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Eligibility Worker Supervisor'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standard1@testorg.com', IsActive = true, Owner_County__c = '1');
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
        
        appQueueRec.DTE_RCVD_APPLN__c = System.today() - 10;
        update appQueueRec;
        
        Task taskRcrd = new Task();
        taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
        taskRcrd.Status = 'Not Started';
        taskRcrd.Priority = 'Normal';
        taskRcrd.WhatId = appQueueRec.Id;
        taskRcrd.ActivityDate = system.today().addDays(+5);
        taskRcrd.OwnerId = aCounty.OwnerId;
        insert taskRcrd;
        
        Test.startTest();
        T108_AppQueueCheckBatch batch = new T108_AppQueueCheckBatch();
        database.executeBatch(batch,10);
        Test.stopTest(); 
    }
    
    static testMethod void testMethod2(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Universal User'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standard2@testorg.com', IsActive = true, Owner_County__c = '1');
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
        
        appQueueRec.DTE_RCVD_APPLN__c = System.today() - 10;
        update appQueueRec;
        
        Task taskRcrd = new Task();
        taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
        taskRcrd.Status = 'Not Started';
        taskRcrd.Priority = 'Normal';
        taskRcrd.WhatId = appQueueRec.Id;
        taskRcrd.ActivityDate = system.today().addDays(+5);
        taskRcrd.OwnerId = aCounty.OwnerId;
        insert taskRcrd;
        
        Test.startTest();
        T108_AppQueueCheckBatch batch = new T108_AppQueueCheckBatch();
        database.executeBatch(batch,10);
        Test.stopTest();
    }
    
    static testMethod void testMethod3(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Provider Worker Supervisor'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standard3@testorg.com', IsActive = true, Owner_County__c = '1');
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
        
        appQueueRec.DTE_RCVD_APPLN__c = System.today() - 10;
        update appQueueRec;
        
        Task taskRcrd = new Task();
        taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
        taskRcrd.Status = 'Not Started';
        taskRcrd.Priority = 'Normal';
        taskRcrd.WhatId = appQueueRec.Id;
        taskRcrd.ActivityDate = system.today().addDays(+5);
        taskRcrd.OwnerId = aCounty.OwnerId;
        insert taskRcrd;
        
        Test.startTest();
        T108_AppQueueCheckBatch batch = new T108_AppQueueCheckBatch();
        database.executeBatch(batch,10);
        Test.stopTest();
    }
    
    static testMethod void testMethod4(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Fiscal Worker Supervisor'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standard4@testorg.com', IsActive = true, Owner_County__c = '1');
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
        
        appQueueRec.DTE_RCVD_APPLN__c = System.today() - 10;
        update appQueueRec;
        
        Task taskRcrd = new Task();
        taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
        taskRcrd.Status = 'Not Started';
        taskRcrd.Priority = 'Normal';
        taskRcrd.WhatId = appQueueRec.Id;
        taskRcrd.ActivityDate = system.today().addDays(+5);
        taskRcrd.OwnerId = aCounty.OwnerId;
        insert taskRcrd;
        
        Test.startTest();
        T108_AppQueueCheckBatch batch = new T108_AppQueueCheckBatch();
        database.executeBatch(batch,10);
        Test.stopTest();
    }
    
    static testMethod void testMethod5(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Business Office Worker'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standard5@testorg.com', IsActive = true, Owner_County__c = '1');
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
        
        appQueueRec.DTE_RCVD_APPLN__c = System.today() - 10;
        update appQueueRec;
        
        Task taskRcrd = new Task();
        taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
        taskRcrd.Status = 'Not Started';
        taskRcrd.Priority = 'Normal';
        taskRcrd.WhatId = appQueueRec.Id;
        taskRcrd.ActivityDate = system.today().addDays(+5);
        taskRcrd.OwnerId = aCounty.OwnerId;
        insert taskRcrd;
        
        Test.startTest();
        T108_AppQueueCheckBatch batch = new T108_AppQueueCheckBatch();
        database.executeBatch(batch,10);
        Test.stopTest();
    }
    
    static testMethod void testMethod6(){
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Profile p = [SELECT Id FROM Profile WHERE Name='Read Only User'];
        User user1 = new User(Alias = 'standt', Email='standarduser12@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                              UserName=dateString+'standard6@testorg.com', IsActive = true, Owner_County__c = '1');
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
        
        appQueueRec.DTE_RCVD_APPLN__c = System.today() - 10;
        update appQueueRec;
        
        Task taskRcrd = new Task();
        taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
        taskRcrd.Status = 'Not Started';
        taskRcrd.Priority = 'Normal';
        taskRcrd.WhatId = appQueueRec.Id;
        taskRcrd.ActivityDate = system.today().addDays(+5);
        taskRcrd.OwnerId = aCounty.OwnerId;
        insert taskRcrd;
        
        Test.startTest();
        T108_AppQueueCheckBatch batch = new T108_AppQueueCheckBatch();
        database.executeBatch(batch,10);
        Test.stopTest();
    }
    
    public static testMethod void testSchedulableT108Batch(){
        Test.startTest();
        SchedulableT108AppQueueCheckBatch schObj =  new SchedulableT108AppQueueCheckBatch();
        String sch = '0 0 7 * * ?';
        String jobId =system.schedule('Test Deleted Record Archive Batch Check', sch, schObj); 
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered,'Cron trigger should return zero jobs'); 
        
        Test.stopTest();
    }
}