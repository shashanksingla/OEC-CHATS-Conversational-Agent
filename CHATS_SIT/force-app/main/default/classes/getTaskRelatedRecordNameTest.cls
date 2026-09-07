@isTest
private class getTaskRelatedRecordNameTest {

    @testSetup
    public static void doSetup() {
        Date datetoday = System.today();
        Date firstDayOfNextMonth = Date.newInstance(datetoday.year(), datetoday.month() + 1, 1);
        
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Level 1');
        
        T_COUNTY_PLAN__c CPRec = TestClassUtility.createCountyPlan('PEN', false);
        CPRec.CDE_COUNTY__c = countyRec.Id;
        insert CPRec;
        
        T_PROVR_FISCAL_AGREMENT__c FARec = TestClassUtility.createFiscaAgreement(false, 'FA1', firstDayOfNextMonth, countyRec.Id);
        FARec.ID_SERVICE__c = provRec.Id;
        FARec.CDE_COUNTY__c = countyRec.Id;
        insert FARec;
        
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.CDE_COUNTY__c = countyRec.Id;
        insert caseRec;
        
        T_AUTH__c authRec = TestClassUtility.createAuthorization(false, null, System.today().addDays(-8), countyRec.Id, provRec.Id);
        authRec.IDN_CASE__c = caseRec.Id;
        authRec.CDE_COUNTY__c = countyRec.Id;
        insert authRec;
    }

    @isTest
    static void testGetRecordNames() {        
        T_COUNTY__c countyRec = [SELECT Id FROM T_COUNTY__c LIMIT 1];
        T_SBSD_CASE__c caseRec = [SELECT Id FROM T_SBSD_CASE__c WHERE CDE_COUNTY__c = :countyRec.Id LIMIT 1];
        T_AUTH__c authRec = [SELECT Id FROM T_AUTH__c WHERE CDE_COUNTY__c = :countyRec.Id LIMIT 1];

        List<Id> inputIds = new List<Id>{
            caseRec.Id,
            authRec.Id,
            countyRec.Id,
            null
        };

        Test.startTest();
        List<String> results = getTaskRelatedRecordName.getRecordNames(inputIds);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'should return a result for each input ID');
        System.assertNotEquals('', results[0], 'should return the obj label and Name/Subject for case record');
        System.assertNotEquals('', results[1], 'should return obj label and Name/Subject for Auth record');
        System.assertEquals('', results[3], 'null Id input should return an empty string');
    }

    @isTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        List<String> nullResults = getTaskRelatedRecordName.getRecordNames(null);
        List<String> emptyResults = getTaskRelatedRecordName.getRecordNames(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, nullResults.size(), 'null input list should return an empty list');
        System.assertEquals(0, emptyResults.size(), 'empty input list should return an empty list');
    }
}