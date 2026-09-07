/***********************************************************************
Class Name      - UserUpdateBatchTest_v2
Covering Class  - UserUpdateBatch_Case, UserUpdateBatch_FiscalAgreement
Author          - Rishav Maji
************************************************************************/
@isTest
public class UserUpdateBatchTest_v2 {
    
    @testSetup
    public static void doSetup(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u1.Owner_County__c = '16';
        u1.IsActive = true;
        Insert u1;
        
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 16, true);
        
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.OwnerId = u1.Id;
        Insert caseRec;
        
        T_SBSD_CASE_STATUS_MODE__c caseMode = TestClassUtility.createCaseStatusMode(true, caseRec.Id); 
        
        T_CHATS_PROVR_STATUS__c prov = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        Insert prov;
        
        String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c FA = TestClassUtility.createFiscaAgreement(false, 'FA', System.Today(), countyRec.Id);
        FA.OwnerId = u1.Id;
        FA.RecordTypeId = openRecordTypeId;
        FA.CDE_TYPE_STATUS__c = 'OPN';
        FA.ID_SERVICE__c = prov.Id;
        FA.DTE_RCV_AGRMT_FISCAL__c = System.today().addDays(-10);
        Insert FA;
    }
    
    public static testMethod void TestCron(){
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String CaseJobId = System.schedule('UserUpdateBatch_Case',  CRON_EXP, new UserUpdateBatch_Case());
        CronTrigger CaseCT = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :CaseJobId];
        System.assertEquals(CRON_EXP, CaseCT.CronExpression);
        System.assertEquals(0, CaseCT.TimesTriggered);
        String FAJobId = System.schedule('UserUpdateBatch_FiscalAgreement',  CRON_EXP, new UserUpdateBatch_FiscalAgreement());
        CronTrigger FACT = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :FAJobId];
        System.assertEquals(CRON_EXP, FACT.CronExpression);
        System.assertEquals(0, FACT.TimesTriggered);
        Test.stopTest(); 
    }
    
    public static testMethod void TestBatch(){
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' AND Owner_County__c = '16' LIMIT 1];
        u.IsActive = false;
        update u;
        Test.startTest();
        database.executebatch(new UserUpdateBatch_Case());
        database.executebatch(new UserUpdateBatch_FiscalAgreement());
        Test.stopTest();
    }
}