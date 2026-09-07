/*************************************************************
Class Name	    - T233_TaskCreationBatch_Test
Covering Class	- T233_TaskCreationBatch
Author          - Shashank Singla
**************************************************************/
@isTest
public class T233_TaskCreationBatch_Test {
    
    @testSetup
    public static void doSetup(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u) {
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
            Task taskRec = TestClassUtility.createTask(false, 'T230 – RE106 is Available for Review', 'test', 'Not Started', countyRec.Id, u.Id);
            taskRec.ActivityDate = System.today();
            taskRec.County__c = '1';
            Insert taskRec;
        }
    }
    
    public static testMethod void T233_TaskCreationBatch_Test1(){
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobId = System.schedule('T233_TaskCreationBatch',  CRON_EXP, new T233_TaskCreationBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
    
    public static testMethod void T233_TaskCreationBatch_Test2(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T233_TaskCreationBatch batch = new T233_TaskCreationBatch();
            database.executebatch(batch);
            Test.stopTest();
        }
    }
}