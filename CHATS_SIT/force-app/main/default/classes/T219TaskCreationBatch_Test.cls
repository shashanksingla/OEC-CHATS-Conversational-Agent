/*************************************************************
Class Name	    - T219TaskCreationBatch_Test
Covering Class	- T219TaskCreationBatch
Author          - Rishav Maji
**************************************************************/
@isTest
public class T219TaskCreationBatch_Test {
    
    @testSetup
    public static void doSetup(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        // Use System.runAs to avoid MIXED_DML_OPERATION error
        System.runAs(u) {
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
            User_and_Email_Settings__c ues1 = new User_and_Email_Settings__c();
            ues1.Name = 'T219 Owner Email';
            ues1.Value__c = 'test@example.com.invalid';
            Insert ues1;
            T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(false, 'Level 1');
            T_CHATS_PROVR_STATUS__c provRec2 = TestClassUtility.createProvider(false, 'Level 1');
            provRec2.NAM_FACILITY__c = 'testProv';
            GenericDMLHandler.insertRecords(new List<Sobject>{provRec,provRec2}, null);
            T_PROVR_CBC__c cbcRec1 = new T_PROVR_CBC__c(
                IDN_PROVR__c = provRec.Id, NAM_FIRST__c = 'testF', NAM_LAST__c = 'testL', DTE_5yearFBIDueDate__c = Date.today().addDays(60)
            );
            T_PROVR_CBC__c cbcRec2 = new T_PROVR_CBC__c(
                IDN_PROVR__c = provRec2.Id, NAM_FIRST__c = 'testF', NAM_LAST__c = 'testL', DTE_5yearFBIDueDate__c = Date.today().addDays(60)
            );
            GenericDMLHandler.insertRecords(new List<Sobject>{cbcRec2, cbcRec1}, null);
        }
    }
    
    public static testMethod void T219TaskCreationBatch_Test1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T219TaskCreationBatch t219b = new T219TaskCreationBatch();
            database.executebatch(t219b);
            Test.stopTest();
        }
    }
    
    public static testMethod void T219TaskCreationBatch_Test_execute(){
        Test.startTest();
        String CRON_EXP = '0 0 0 ? * * *';
        String jobId = System.schedule('T219TaskCreationBatch',  CRON_EXP, new T219TaskCreationBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
}