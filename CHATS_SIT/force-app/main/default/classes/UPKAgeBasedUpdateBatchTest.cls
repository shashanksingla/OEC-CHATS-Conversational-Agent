@isTest
private class UPKAgeBasedUpdateBatchTest {
    
    private static final String NOT_APPLICABLE = 'Not Applicable';
    private static final String UNKNOWN = 'Unknown';
    private static final String YES = 'Yes';
    private static final String NO = 'No';
    
    @testSetup
    static void setupTestData() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Quality');
        T_SBSD_INDIV__c childUnder3 = TestClassUtility.createIndividual(false, Date.today().addYears(-2), 'Child', 
            '1', 'UnderThree', '111111111','CC');
        T_SBSD_INDIV__c childAge3 = TestClassUtility.createIndividual(false, Date.today().addYears(-3), 
            'Child', '1', 'AgeThree', '222222222','CC');
        T_SBSD_INDIV__c childOver6 = TestClassUtility.createIndividual(false, Date.today().addYears(-7), 
            'Child', '1', 'OverSix', '444444444', 'CC' );
        List<T_SBSD_INDIV__c> individuals = new List<T_SBSD_INDIV__c>{childUnder3, childAge3, childOver6};
        insert individuals;

        T_AUTH__c authUnder3 = TestClassUtility.createAuthorization(false, Date.today().addMonths(12), 
            Date.today(), county.Id, provider.Id);
        authUnder3.IDN_CLIENT__c = childUnder3.Id;
        authUnder3.CDE_CHILD_ENROLLED_IN_UPK__c = YES;
        
        T_AUTH__c authAge3to6 = TestClassUtility.createAuthorization(false, Date.today().addMonths(12), 
            Date.today(), county.Id, provider.Id);
        authAge3to6.IDN_CLIENT__c = childAge3.Id;
        authAge3to6.CDE_CHILD_ENROLLED_IN_UPK__c = NOT_APPLICABLE;
        
        T_AUTH__c authOver6 = TestClassUtility.createAuthorization(false, Date.today().addMonths(12), 
            Date.today(), county.Id, provider.Id);
        authOver6.IDN_CLIENT__c = childOver6.Id;
        authOver6.CDE_CHILD_ENROLLED_IN_UPK__c = NO;
        List<T_AUTH__c> auths = new List<T_AUTH__c>{authUnder3, authAge3to6, authOver6};
        insert auths;
    }
    
    /**
     * @description Tests that children under 3 have their UPK field set to 'Not Applicable'
     */
    @isTest
    static void testChildUnder3SetsNotApplicable() {
        T_AUTH__c authBefore = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                 FROM T_AUTH__c 
                                 WHERE IDN_CLIENT__r.NAM_LAST__c = 'UnderThree' LIMIT 1];
        System.assertEquals(YES, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial value should be Yes');
        System.assert(authBefore.IDN_CLIENT__r.Age__c < 3, 'Child should be under 3 years old');
        
        Test.startTest();
        Database.executeBatch(new UPKAgeBasedUpdateBatch(), 200);
        Test.stopTest();

        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c 
                                FROM T_AUTH__c 
                                WHERE Id = :authBefore.Id];
        System.assertEquals(NOT_APPLICABLE, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 
                           'UPK field should be set to Not Applicable for child under 3');
    }
    
    /**
     * @description Tests that children aged 3-6 with 'Not Applicable' get changed to 'Unknown'
     */
    @isTest
    static void testChildAge3To6ChangesToUnknown() {
        T_AUTH__c authBefore = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                 FROM T_AUTH__c 
                                 WHERE IDN_CLIENT__r.NAM_LAST__c = 'AgeThree' LIMIT 1];
        System.assertEquals(NOT_APPLICABLE, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial value should be Not Applicable');
        System.assert(authBefore.IDN_CLIENT__r.Age__c >= 3 && authBefore.IDN_CLIENT__r.Age__c <= 6, 
                     'Child should be between 3 and 6 years old');
        
        Test.startTest();
        Database.executeBatch(new UPKAgeBasedUpdateBatch(), 200);
        Test.stopTest();
        
        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c 
                                FROM T_AUTH__c 
                                WHERE Id = :authBefore.Id];
        System.assertEquals(UNKNOWN, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 
                           'UPK field should be set to Unknown for child aged 3-6 who had Not Applicable');
    }
    
    /**
     * @description Tests that children over 6 have their UPK field set to 'Not Applicable'
     */
    @isTest
    static void testChildOver6SetsNotApplicable() {
        T_AUTH__c authBefore = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c 
                                 FROM T_AUTH__c 
                                 WHERE IDN_CLIENT__r.NAM_LAST__c = 'OverSix' LIMIT 1];
        System.assertEquals(NO, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial value should be No');
        System.assert(authBefore.IDN_CLIENT__r.Age__c > 6, 'Child should be over 6 years old');
        
        Test.startTest();
        Database.executeBatch(new UPKAgeBasedUpdateBatch(), 200);
        Test.stopTest();
        
        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c 
                                FROM T_AUTH__c 
                                WHERE Id = :authBefore.Id];
        System.assertEquals(NOT_APPLICABLE, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c, 
                           'UPK field should be set to Not Applicable for child over 6');
    }
    
    /**
     * @description Tests the schedulable interface
     */
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 1 * * ?';
        String jobId = System.schedule('Test UPK Age Based Update', cronExp, new UPKAgeBasedUpdateBatch());
        Test.stopTest();
        
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression, State 
                                            FROM CronTrigger 
                                            WHERE Id = :jobId];
        System.assertEquals(1, scheduledJobs.size(), 'Job should be scheduled');
        System.assertEquals(cronExp, scheduledJobs[0].CronExpression, 'Cron expression should match');
    }

    /**
     * @description Tests the finish method with errors
     */
    @isTest
    static void testFinishMethodWithErrors() {
        Test.startTest();
        UPKAgeBasedUpdateBatch batch = new UPKAgeBasedUpdateBatch();
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
}