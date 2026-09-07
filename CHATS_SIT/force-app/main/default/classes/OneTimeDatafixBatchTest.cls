// Test class for OneTimeDatafixBatch, to be updated as needed.
@isTest
private class OneTimeDatafixBatchTest {

    private static final String NOT_APPLICABLE = 'Not Applicable';
    private static final String UNKNOWN = 'Unknown';
    private static final String YES = 'Yes';
    private static final String NO = 'No';

    @testSetup
    static void setupTestData() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test Name', 'Department', 2, true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Quality');

        T_SBSD_INDIV__c childUnder3 = TestClassUtility.createIndividual(
            false, Date.today().addYears(-2), 'Child', '1', 'UnderThree', '111111111', 'CC'
        );
        T_SBSD_INDIV__c childAge3 = TestClassUtility.createIndividual(
            false, Date.today().addYears(-3), 'Child', '1', 'AgeThree', '222222222', 'CC'
        );
        T_SBSD_INDIV__c childAge5 = TestClassUtility.createIndividual(
            false, Date.today().addYears(-5), 'Child', '1', 'AgeFive', '333333333', 'CC'
        );
        T_SBSD_INDIV__c childOver6 = TestClassUtility.createIndividual(
            false, Date.today().addYears(-7), 'Child', '1', 'OverSix', '444444444', 'CC'
        );
        T_SBSD_INDIV__c childAlreadyCorrect = TestClassUtility.createIndividual(
            false, Date.today().addYears(-2), 'Child', '1', 'AlreadyCorrect', '555555555', 'CC'
        );
        insert new List<T_SBSD_INDIV__c>{childUnder3, childAge3, childAge5, childOver6, childAlreadyCorrect};

        T_AUTH__c authUnder3 = TestClassUtility.createAuthorization(
            false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id
        );
        authUnder3.IDN_CLIENT__c = childUnder3.Id;
        authUnder3.CDE_CHILD_ENROLLED_IN_UPK__c = YES;
        T_AUTH__c authAge3 = TestClassUtility.createAuthorization(
            false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id
        );
        authAge3.IDN_CLIENT__c = childAge3.Id;
        authAge3.CDE_CHILD_ENROLLED_IN_UPK__c = YES;
        T_AUTH__c authAge5 = TestClassUtility.createAuthorization(
            false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id
        );
        authAge5.IDN_CLIENT__c = childAge5.Id;
        authAge5.CDE_CHILD_ENROLLED_IN_UPK__c = NOT_APPLICABLE;
        T_AUTH__c authOver6 = TestClassUtility.createAuthorization(
            false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id
        );
        authOver6.IDN_CLIENT__c = childOver6.Id;
        authOver6.CDE_CHILD_ENROLLED_IN_UPK__c = NO;
        T_AUTH__c authAlreadyCorrect = TestClassUtility.createAuthorization(
            false, Date.today().addMonths(12), Date.today(), county.Id, provider.Id
        );
        authAlreadyCorrect.IDN_CLIENT__c = childAlreadyCorrect.Id;
        authAlreadyCorrect.CDE_CHILD_ENROLLED_IN_UPK__c = NOT_APPLICABLE;
        T_AUTH__c authFuture = TestClassUtility.createAuthorization(
            false, Date.today().addMonths(12), Date.today().addMonths(1), county.Id, provider.Id
        );
        authFuture.IDN_CLIENT__c = childUnder3.Id;
        authFuture.CDE_CHILD_ENROLLED_IN_UPK__c = YES;
        insert new List<T_AUTH__c>{authUnder3, authAge3, authAge5, authOver6, authAlreadyCorrect, authFuture};
    }

    /**
     * @description Verifies children under 3 have CDE_CHILD_ENROLLED_IN_UPK__c set to 'Not Applicable'.
     */
    @isTest
    static void testChildUnder3SetsNotApplicable() {
        Date today = Date.today();
        T_AUTH__c authBefore = [
            SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c
            FROM T_AUTH__c
            WHERE IDN_CLIENT__r.NAM_LAST__c = 'UnderThree'
            AND DTE_BEGIN_EFFV_AUTH__c = :today
            LIMIT 1
        ];
        System.assertEquals(YES, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial UPK value should be Yes');
        System.assert(authBefore.IDN_CLIENT__r.Age__c < 3, 'Child should be under 3 years old');

        Test.startTest();
        Database.executeBatch(new OneTimeDatafixBatch(), 200);
        Test.stopTest();

        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authBefore.Id];
        System.assertEquals(NOT_APPLICABLE, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c,
                'UPK field should be set to Not Applicable for child under 3');
    }

    /**
     * @description Verifies children aged 3–6 have CDE_CHILD_ENROLLED_IN_UPK__c set to 'Unknown'.
     */
    @isTest
    static void testChildAge3To6SetsUnknown() {
        T_AUTH__c authBefore = [
            SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c
            FROM T_AUTH__c
            WHERE IDN_CLIENT__r.NAM_LAST__c = 'AgeThree'
            LIMIT 1
        ];
        System.assertEquals(YES, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial UPK value should be Yes');
        System.assert(
            authBefore.IDN_CLIENT__r.Age__c >= 3 && authBefore.IDN_CLIENT__r.Age__c < 6,
            'Child should be between 3 and 6 years old'
        );

        Test.startTest();
        Database.executeBatch(new OneTimeDatafixBatch(), 200);
        Test.stopTest();

        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authBefore.Id];
        System.assertEquals(UNKNOWN, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c,
                'UPK field should be set to Unknown for child aged 3-6');
    }

    /**
     * @description Verifies children over 6 have CDE_CHILD_ENROLLED_IN_UPK__c set to 'Not Applicable'.
     */
    @isTest
    static void testChildOver6SetsNotApplicable() {
        T_AUTH__c authBefore = [
            SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, IDN_CLIENT__r.Age__c
            FROM T_AUTH__c
            WHERE IDN_CLIENT__r.NAM_LAST__c = 'OverSix'
            LIMIT 1
        ];
        System.assertEquals(NO, authBefore.CDE_CHILD_ENROLLED_IN_UPK__c, 'Initial UPK value should be No');
        System.assert(authBefore.IDN_CLIENT__r.Age__c >= 6, 'Child should be 6 years or older');

        Test.startTest();
        Database.executeBatch(new OneTimeDatafixBatch(), 200);
        Test.stopTest();

        T_AUTH__c authAfter = [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authBefore.Id];
        System.assertEquals(NOT_APPLICABLE, authAfter.CDE_CHILD_ENROLLED_IN_UPK__c,
                'UPK field should be set to Not Applicable for child over 6');
    }

    /**
     * @description Verifies the finish method handles error messages and logs without throwing exceptions.
     */
    @isTest
    static void testFinishMethodWithErrors() {
        Test.startTest();
        OneTimeDatafixBatch batch = new OneTimeDatafixBatch();
        batch.errorMessages.add('Record Id: 001000000000001 - Error: Test error message 1');
        batch.errorMessages.add('Record Id: 001000000000002 - Error: Test error message 2');
        batch.totalRecordsProcessed = 10;
        batch.totalRecordsUpdated = 8;
        batch.totalFailures = 2;
        batch.finish(null);
        Test.stopTest();

        System.assertEquals(2, batch.errorMessages.size(), 'Should have 2 error messages recorded');
        System.assertEquals(2, batch.totalFailures, 'Should have 2 failures tracked');
        System.assertEquals(10, batch.totalRecordsProcessed, 'Should have processed 10 records');
        System.assertEquals(8, batch.totalRecordsUpdated, 'Should have updated 8 records');
    }
}