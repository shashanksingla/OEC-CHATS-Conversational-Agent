@isTest
private class UPKYearEndTaskBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create County
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test Dept', 1, true);
        
        // Create Provider
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 1');
        
        // Create Fiscal Agreement (required for authorization)
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
        fiscalAgreement.DTE_BEGIN_AGRMT__c = System.today().addDays(-30);
        fiscalAgreement.CDE_COUNTY__c = county.Id;
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = System.today().addDays(-30);
        insert fiscalAgreement;
        
        // Create Case
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, county.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-10);
        caseRec.IDN_EXTNL__c = '9999';
        caseRec.OwnerId = UserInfo.getUserId();
        insert caseRec;
        
        // Create Authorization
        T_AUTH__c authMatching = new T_AUTH__c();
        authMatching.IDN_CASE__c = caseRec.Id;
        authMatching.DTE_BEGIN_EFFV_AUTH__c = System.today();
        authMatching.DTE_END_EFFV_AUTH__c = System.today().addMonths(6);
        authMatching.CDE_COUNTY__c = county.Id;
        authMatching.IDN_PROVR__c = provider.Id;
        authMatching.CDE_CHILD_ENROLLED_IN_UPK__c = 'Yes';
        authMatching.Is_UPK_Stacked__c = 'Yes';
        insert authMatching;
    }
    
    @isTest
    static void testBatchExecute() {
        Test.startTest();
        UPKYearEndTaskBatch batch = new UPKYearEndTaskBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify tasks were created for matching authorization
        List<Task> createdTasks = [SELECT Id, Subject, WhatId, OwnerId FROM Task WHERE Subject = :System.Label.Task_T123_Subject];
        System.assert(createdTasks.size() > 0, 'Tasks should be created for matching authorizations');
        
        // Verify task was related to authorization
        T_AUTH__c matchingAuth = [SELECT Id FROM T_AUTH__c WHERE CDE_CHILD_ENROLLED_IN_UPK__c = 'Yes' AND Is_UPK_Stacked__c = 'Yes' LIMIT 1];
        Boolean taskFoundForAuth = false;
        for (Task tsk : createdTasks) {
            if (tsk.WhatId == matchingAuth.Id) {
                taskFoundForAuth = true;
                break;
            }
        }
        System.assert(taskFoundForAuth, 'Task should be created for the matching authorization');
    }
    
    @isTest
    static void testSchedulableExecute() {
        Test.startTest();
        UPKYearEndTaskBatch scheduler = new UPKYearEndTaskBatch();
        String cronExp = '0 0 0 16 4 ? 2030';
        String jobId = System.schedule('Test UPK Year End Task Batch', cronExp, scheduler);
        Test.stopTest();
        
        // Verify the job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, scheduledJobs.size(), 'Job should be scheduled');
    }
    
    @isTest
    static void testBatchStartMethod() {
        Test.startTest();
        UPKYearEndTaskBatch batch = new UPKYearEndTaskBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
    }
    
    @isTest
    static void testBatchFinishMethod() {
        Test.startTest();
        UPKYearEndTaskBatch batch = new UPKYearEndTaskBatch();
        
        batch.errorMessages.add('Auth Id: 001000000000001 - Error: Test Error Message 1');
        batch.errorMessages.add('Auth Id: 001000000000002 - Error: Test Error Message 2');
        batch.totalFailures = 2;
        
        batch.finish(null);
        Test.stopTest();
        
        // Verify error logs were inserted
        List<Exception_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Exception_Message__c 
                                             FROM Exception_Log__c 
                                             WHERE Class__c = 'UPKYearEndTaskBatch'];
        System.assertEquals(2, errorLogs.size(), 'Two error logs should be created when batch completes with errors');
    }
}