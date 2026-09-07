/*************************************************************
Class Name	    - T220TaskCreationBatch_Test
Covering Class	- T220TaskCreationBatch
Author          - Rishav Maji
**************************************************************/
@isTest
public class T220TaskCreationBatch_Test {
    
    @testSetup
    public static void doSetup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(false, 'Level 1');
        provRec.DTE_VisitOccurred__c = System.today().addDays(-275);
        provRec.NAM_FACILITY__c = 'testProv';
        provRec.CDE_TYPE_PROVR__c = 'EFACH';
        GenericDMLHandler.insertRecords(new List<Sobject>{provRec}, null);
        String dayOfWeek = System.now().format('u');
        Date dueDate = dayOfWeek == '7' ? System.today().addDays(12) : dayOfWeek == '6' ? System.today().addDays(13) : System.today().addDays(14);
        T_YEAR_HOL__c hol = new T_YEAR_HOL__c(DTE_HOL__c = dueDate, CDE_YEAR__c = dueDate.year());
        Insert hol;
    }
    
    public static testMethod void T220TaskCreationBatch_Test1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T220TaskCreationBatch batch = new T220TaskCreationBatch();
            database.executebatch(batch);
            Test.stopTest();
        }
    }
    
    public static testMethod void T220TaskCreationBatch_Test2(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            T_CHATS_PROVR_STATUS__c provr = [SELECT Id FROM T_CHATS_PROVR_STATUS__c WHERE NAM_FACILITY__c = 'testProv' LIMIT 1];
            Task t = new Task();
            t.Subject = Label.Task_T220_Subject;
            t.Description = Label.Task_T220_Description;
            t.ActivityDate = System.today().addDays(10);
            t.WhatId = provr.Id;
            t.OwnerId = u1.Id;
            Insert t;
            Test.startTest();
            T220TaskCreationBatch batch = new T220TaskCreationBatch();
            database.executebatch(batch);
            Test.stopTest();
        }
    }
    
    public static testMethod void T220TaskCreationBatch_Test_execute(){
        Test.startTest();
        String CRON_EXP = '0 0 0 ? * * *';
        String jobId = System.schedule('T220TaskCreationBatch',  CRON_EXP, new T220TaskCreationBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
    
    /*
     * Test method for weekend date calculations
     */
    public static testMethod void testWeekendDateCalculations(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User testUser = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'testLast', 'testFirst', 'test@example.com.invalid', 'test@example.com.invalid' + String.valueOf(Math.random() * 1000), 'tUser');
        
        System.runAs(testUser){
            User_and_Email_Settings__c validEmailSetting = new User_and_Email_Settings__c();
            validEmailSetting.Name = 'T220 Owner Email';
            validEmailSetting.Value__c = 'test@example.com.invalid';
            insert validEmailSetting;
            
            T_CHATS_PROVR_STATUS__c provRec = [Select id from T_CHATS_PROVR_STATUS__c];
            Test.startTest();
            T220TaskCreationBatch batch = new T220TaskCreationBatch();
            Database.executeBatch(batch);
            Test.stopTest();
            
            List<Task> createdTasks = [SELECT Id, ActivityDate FROM Task WHERE Subject LIKE '%T220%' AND WhatId = :provRec.Id];
            if(!createdTasks.isEmpty()){
                // Verify the activity date is not on a weekend
                String dayOfWeek = ((DateTime)createdTasks[0].ActivityDate).format('u');
                System.assertNotEquals('6', dayOfWeek, 'Task due date should not be Saturday');
                System.assertNotEquals('7', dayOfWeek, 'Task due date should not be Sunday');
            }
        }
    }
}