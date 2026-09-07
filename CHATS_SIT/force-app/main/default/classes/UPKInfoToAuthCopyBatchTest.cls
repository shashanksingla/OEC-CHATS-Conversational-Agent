@isTest
private class UPKInfoToAuthCopyBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create County
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test Dept', 1, true);
        
        // Create Individual
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, System.today().addYears(-5), 'TestFirst', '1', 'TestLast', '123456789', 'CC');
        
        // Create Provider
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 1');
        
        // Query back the auto-generated Names
        individual = [SELECT Id, Name FROM T_SBSD_INDIV__c WHERE Id = :individual.Id];
        provider = [SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c WHERE Id = :provider.Id];
        
        // Create Fiscal Agreement
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
        fiscalAgreement.DTE_BEGIN_AGRMT__c = System.today().addDays(-8);
        fiscalAgreement.CDE_COUNTY__c = county.Id;
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = System.today().addDays(-8);
        insert fiscalAgreement;
        
        // Create Case
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, county.Id);
        caseRec.DTE_APPLN__c = System.today().addDays(-8);
        caseRec.IDN_EXTNL__c = '9999';
        caseRec.OwnerId = UserInfo.getUserId();
        insert caseRec;
        
        // Create Authorization 
        T_AUTH__c authMatching = new T_AUTH__c();
        authMatching.IDN_CASE__c = caseRec.Id;
        authMatching.IDN_CLIENT__c = individual.Id;
        authMatching.IDN_PROVR__c = provider.Id;
        authMatching.DTE_BEGIN_EFFV_AUTH__c = System.today().addDays(-8);
        authMatching.DTE_END_EFFV_AUTH__c = System.today().addMonths(6);
        authMatching.CDE_COUNTY__c = county.Id;
        authMatching.Authorization_Status__c = '2'; // Active
        insert authMatching;
        
        T_UPK_INDIV_AUTH_INFO__c upkInfo = new T_UPK_INDIV_AUTH_INFO__c();
        upkInfo.IDN_CLIENT__c = individual.Name;
        upkInfo.IDN_PROVR__c = provider.Name;
        upkInfo.Is_the_child_dually_enrolled_in_UPK__c = 'Yes';
        upkInfo.UPK_Enrollment_Start_Date__c = System.today().addDays(-15);
        upkInfo.UPK_Stacking_Hours__c = 20;
        upkInfo.Is_Copied_To_Auth__c = false;
        insert upkInfo;
    }
    
    @isTest
    static void testBatchExecuteWithMatchingRecords() {
        // Verify initial state
        T_UPK_INDIV_AUTH_INFO__c upkInfoBefore = [SELECT Is_Copied_To_Auth__c FROM T_UPK_INDIV_AUTH_INFO__c LIMIT 1];
        System.assertEquals(false, upkInfoBefore.Is_Copied_To_Auth__c, 'UPK Info should not be marked as copied initially');
        
        T_AUTH__c authBefore = [SELECT CDE_CHILD_ENROLLED_IN_UPK__c, UPK_Awarded_Hours__c, UPK_Start_date__c FROM T_AUTH__c LIMIT 1];
        System.assertEquals(null, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Authorization should not have UPK enrollment initially');
        
        Test.startTest();
        UPKInfoToAuthCopyBatch batch = new UPKInfoToAuthCopyBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify UPK Info was marked as processed
        T_UPK_INDIV_AUTH_INFO__c upkInfoAfter = [SELECT Is_Copied_To_Auth__c FROM T_UPK_INDIV_AUTH_INFO__c LIMIT 1];
        System.assertEquals(true, upkInfoAfter.Is_Copied_To_Auth__c, 'UPK Info should be marked as copied after batch');
        
        // Verify Authorization was updated with UPK fields
        T_AUTH__c authAfter = [SELECT CDE_CHILD_ENROLLED_IN_UPK__c, UPK_Awarded_Hours__c, UPK_Start_date__c FROM T_AUTH__c LIMIT 1];
        System.assertEquals('Yes', authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 'Authorization should have UPK enrollment set to Yes');
        System.assertEquals(20, authAfter.UPK_Awarded_Hours__c, 'Authorization should have UPK hours copied');
        System.assertNotEquals(null, authAfter.UPK_Start_date__c, 'Authorization should have UPK start date copied');
    }
    
    @isTest
    static void testSchedulableExecute() {
        Test.startTest();
        UPKInfoToAuthCopyBatch scheduler = new UPKInfoToAuthCopyBatch();
        String cronExp = '0 0 2 1 * ?';
        String jobId = System.schedule('Test UPK Info to Auth Copy Batch', cronExp, scheduler);
        Test.stopTest();
        
        // Verify the job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, scheduledJobs.size(), 'Job should be scheduled');
    }
    
    @isTest
    static void testBatchStartMethod() {
        Test.startTest();
        UPKInfoToAuthCopyBatch batch = new UPKInfoToAuthCopyBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
    }

    @isTest
    static void testLogError() {
        Test.startTest();
        UPKInfoToAuthCopyBatch batch = new UPKInfoToAuthCopyBatch();
        batch.execute(null, null);
        batch.finish(null);
        Test.stopTest();

        System.assert(true, 'logError should handle the exception without re-throwing');
    }
}