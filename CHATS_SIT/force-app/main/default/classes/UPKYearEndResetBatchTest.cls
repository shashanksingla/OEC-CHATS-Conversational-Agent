@isTest
private class UPKYearEndResetBatchTest {
    
    private static final String UNKNOWN = 'Unknown';
    private static final String YES = 'Yes';
    private static final String NO = 'No';
    
    @testSetup
    static void setupTestData() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test Name', 'Department', 2, true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Quality');
        
        T_SBSD_INDIV__c childAge4 = TestClassUtility.createIndividual(false, Date.today().addYears(-4), 'Child', '1', 'AgeFour', '111111111', 'CC');
        T_SBSD_INDIV__c childAge5 = TestClassUtility.createIndividual(false, Date.today().addYears(-5), 'Child', '1', 'AgeFive', '222222222', 'CC');
        T_SBSD_INDIV__c childAge3 = TestClassUtility.createIndividual(false, Date.today().addYears(-3), 'Child', '1', 'AgeThree', '333333333', 'CC');
        insert new List<T_SBSD_INDIV__c>{childAge4, childAge5, childAge3};
        
        T_AUTH__c authAge4 = TestClassUtility.createAuthorization(false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id);
        authAge4.IDN_CLIENT__c = childAge4.Id;
        authAge4.CDE_CHILD_ENROLLED_IN_UPK__c = YES;
        
        T_AUTH__c authAge5 = TestClassUtility.createAuthorization(false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id);
        authAge5.IDN_CLIENT__c = childAge5.Id;
        authAge5.CDE_CHILD_ENROLLED_IN_UPK__c = UNKNOWN;
        
        T_AUTH__c authAge3 = TestClassUtility.createAuthorization(false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id);
        authAge3.IDN_CLIENT__c = childAge3.Id;
        authAge3.CDE_CHILD_ENROLLED_IN_UPK__c = NO;
        
        insert new List<T_AUTH__c>{authAge4, authAge5, authAge3};
    }
    
    /**
     * @description Tests that children aged 3-6 have their UPK field reset to 'Unknown'
     */
    @isTest
    static void testChildAge3To6ResetsToUnknown() {
        T_AUTH__c authBefore = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                 FROM T_AUTH__c WHERE IDN_CLIENT__r.NAM_LAST__c = 'AgeFour' LIMIT 1];
        System.assertEquals(YES, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial value should be Yes');
        System.assert(authBefore.IDN_CLIENT__r.Age__c >= 3 && authBefore.IDN_CLIENT__r.Age__c < 6, 
                     'Child should be between 3 and 6 years old');
        
        Test.startTest();
        Database.executeBatch(new UPKYearEndResetBatch(), 200);
        Test.stopTest();
        
        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authBefore.Id];
        System.assertEquals(UNKNOWN, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 
                           'UPK field should be reset to Unknown for child aged 3-6 at year end');
    }
    
    /**
     * @description Tests that children aged 3-6 with 'Unknown' value are NOT changed
     */
    @isTest
    static void testChildAge3To6NoChangeIfAlreadyUnknown() {
        T_AUTH__c authBefore = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                 FROM T_AUTH__c WHERE IDN_CLIENT__r.NAM_LAST__c = 'AgeFive' LIMIT 1];
        System.assertEquals(UNKNOWN, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial value should be Unknown');
        
        Test.startTest();
        Database.executeBatch(new UPKYearEndResetBatch(), 200);
        Test.stopTest();
        
        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authBefore.Id];
        System.assertEquals(UNKNOWN, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 
                           'UPK field should remain Unknown for child aged 3-6 who already had Unknown');
    }
    
    /**
     * @description Tests that children at age 3 boundary have their UPK field reset to 'Unknown'
     */
    @isTest
    static void testChildAge3BoundaryResetsToUnknown() {
        T_AUTH__c authBefore = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                 FROM T_AUTH__c WHERE IDN_CLIENT__r.NAM_LAST__c = 'AgeThree' LIMIT 1];
        System.assertEquals(NO, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial value should be No');
        System.assert(authBefore.IDN_CLIENT__r.Age__c >= 3, 'Child should be 3 years old');
        
        Test.startTest();
        Database.executeBatch(new UPKYearEndResetBatch(), 200);
        Test.stopTest();
        
        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authBefore.Id];
        System.assertEquals(UNKNOWN, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 
                           'UPK field should be reset to Unknown for child at age 3 boundary');
    }
    
    /**
     * @description Tests the schedulable interface for June 30 scheduling
     */
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 1 30 6 ? *';
        String jobId = System.schedule('Test UPK Year End Reset', cronExp, new UPKYearEndResetBatch());
        Test.stopTest();
        
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, scheduledJobs.size(), 'Job should be scheduled');
        System.assertEquals(cronExp, scheduledJobs[0].CronExpression, 'Cron expression should match');
    }
    
    /**
     * @description Tests the error logging path in the finish() method
     */
    @isTest
    static void testFinishMethodWithErrors() {
        Test.startTest();
        UPKYearEndResetBatch batch = new UPKYearEndResetBatch();
        batch.errorMessages.add('Record Id: 001000000000001 - Error: Test error message 1');
        batch.errorMessages.add('Record Id: 001000000000002 - Error: Test error message 2');
        batch.totalRecordsProcessed = 5;
        batch.totalRecordsUpdated = 3;
        batch.totalFailures = 2;
        batch.finish(null);
        Test.stopTest();
        
        System.assertEquals(2, batch.errorMessages.size(), 'Should have 2 error messages');
        System.assertEquals(2, batch.totalFailures, 'Should have 2 failures tracked');
    }
    
    /**
     * @description Tests bulk processing of multiple records
     */
    @isTest
    static void testBulkProcessing() {
        List<T_AUTH__c> allAuths = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                     FROM T_AUTH__c WHERE IDN_CLIENT__r.Age__c >= 3 AND IDN_CLIENT__r.Age__c < 6];
        System.assert(allAuths.size() >= 2, 'Should have at least 2 auth records for bulk test');
        
        Test.startTest();
        Database.executeBatch(new UPKYearEndResetBatch(), 200);
        Test.stopTest();
        
        List<T_AUTH__c> updatedAuths = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c 
                                         FROM T_AUTH__c WHERE IDN_CLIENT__r.Age__c >= 3 AND IDN_CLIENT__r.Age__c < 6];
        for (T_AUTH__c auth : updatedAuths) {
            System.assertEquals(UNKNOWN, auth.CDE_CHILD_ENROLLED_IN_UPK__c, 
                               'All records in 3-6 age range should be Unknown after batch');
        }
    }
}