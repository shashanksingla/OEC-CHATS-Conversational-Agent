/*************************************************************
Class Name	    - T216TaskCreationBatch_Test
Covering Class	- T216TaskCreationBatch, T216TaskCreationBatchSchedulable
Author          - Rishav Maji
**************************************************************/
@isTest
public class T216TaskCreationBatch_Test {
    
    @testSetup
    public static void doSetup(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Level 1');
        T_ADJMT__c caseAdj = TestClassUtility.createAdjustment(true, countyRec.Id, caseRec.Id, null);
        T_ADJMT__c provAdj = new T_ADJMT__c(
            CDE_COUNTY__c = countyRec.Id, IDN_PROVR__c = provRec.Id,
            CDE_AGNST_ADJMT__c = '2', CDE_STATUS_ADJMT__c = '1', 
            DTE_END_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 15)),
            DTE_START_ADJMT__c = Date.valueOf(Date.newInstance(2018, 01, 01))
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{provAdj}, null);
        T_DOC_RQ__c tdoc1 = new T_DOC_RQ__c(
            CDE_COUNTY__c = countyRec.Id, IDN_CASE__c = caseRec.Id, NME_CORSPD__c = 'CR202', CDE_TYPE_RCPT__c = 'C',
            DTE_REQ__c = Date.today(), CDE_CORSPD_STATUS__c = 'Generated', RSN_CODE__c = 'CR0024'
        );
        T_DOC_RQ__c tdoc2 = new T_DOC_RQ__c(
            CDE_COUNTY__c = countyRec.Id, IDN_PROVR__c = provRec.Id, NME_CORSPD__c = 'CR202', CDE_TYPE_RCPT__c = 'P',
            DTE_REQ__c = Date.today(), CDE_CORSPD_STATUS__c = 'Generated', RSN_CODE__c = 'CR0024'
        );
        T_YEAR_HOL__c hol = new T_YEAR_HOL__c(
            DTE_HOL__c = Date.newInstance(2021, 12, 28), CDE_YEAR__c = 2021, CDE_HOL__c = '1'
        );
        GenericDMLHandler.insertRecords(new List<Sobject>{tdoc1, tdoc2, hol}, null);
    }
    
    public static testMethod void T216TaskCreationBatch_Test1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T216TaskCreationBatch t216b = new T216TaskCreationBatch();
            t216b.todayDate = Date.newInstance(2021, 12, 25);
            database.executebatch(t216b);
            t216b.todayDate = Date.newInstance(2021, 12, 26);
            database.executebatch(t216b);
            Test.stopTest();
        }
    }
    
    public static testMethod void T216TaskCreationBatch_Test2(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            T216TaskCreationBatch t216b = new T216TaskCreationBatch();
            database.executebatch(t216b);
            Test.stopTest();
            Exception_Log__c xLog = [SELECT Id, Exception_Message__c FROM Exception_Log__c WHERE Class__c = 'T216TaskCreationBatch' LIMIT 1];
            System.assertEquals('Attempt to de-reference a null object', xLog.Exception_Message__c);
        }
    }
    
    public static testMethod void T216TaskCreationBatchSchedulable_Test(){
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobId = System.schedule('T216TaskCreationBatchSchedulable',  CRON_EXP, new T216TaskCreationBatchSchedulable());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest(); 
    }
}