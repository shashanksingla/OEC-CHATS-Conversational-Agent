@isTest
private class UpdateCaseIndividualStatusBatchTest {
    
/*Commenting out as the batch is no longer in use
@testSetup
static void setupTestData() {
    T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
    T_SBSD_CASE__c testCase = TestClassUtility.createCase(true, countyObj.Id);

    List<T_SBSD_INDIV__c> individuals = new List<T_SBSD_INDIV__c>();
    String[] firstNames = new String[]{'John', 'Jane', 'Robert', 'Mary', 'William', 'Patricia'};
    String[] lastNames = new String[]{'Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis'};

    for (Integer i = 0; i < 6; i++) {
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(
            false, 
            Date.today().addYears(-30),
            firstNames[i],
            '1',
            lastNames[i],
            '123456789',
            'CC'
        );
        individuals.add(indiv);
    }
    insert individuals;

    List<T_SBSD_CASE_INDIV__c> caseIndivs = new List<T_SBSD_CASE_INDIV__c>();
    for (Integer i = 0; i < 2; i++) {
        T_SBSD_CASE_INDIV__c record = TestClassUtility.createCaseIndividual(
            false, 
            testCase.Id,
            individuals[i].Id,
            true
        );
        //record.INDIVIDUAL_STATUS__c = null;
        caseIndivs.add(record);
    }
    for (Integer i = 2; i < 6; i++) {
        T_SBSD_CASE_INDIV__c record = TestClassUtility.createCaseIndividual(
            false,
            testCase.Id,
            individuals[i].Id,
            false
        );
        record.INDIVIDUAL_STATUS__c = null;
        caseIndivs.add(record);
    }
    insert caseIndivs;

    List<T_INDIV_REL__c> indivRels = new List<T_INDIV_REL__c>();
    String[] acRelationshipTypes = new String[]{'CLH', 'CLW'};
    for (Integer i = 2; i < 4; i++) {
        T_INDIV_REL__c rel = new T_INDIV_REL__c(
            IDN_CLIENT_RELTD__c = individuals[i].Id,
            IDN_CLIENT__c=individuals[i-2].Id,
            CDE_TYPE_REL_INDIV__c = acRelationshipTypes[i-2]
        );
        indivRels.add(rel);
    }
    for (Integer i = 4; i < 6; i++) {
        T_INDIV_REL__c rel = new T_INDIV_REL__c(
            IDN_CLIENT_RELTD__c = individuals[i].Id,
            IDN_CLIENT__c=individuals[i-4].Id,
            CDE_TYPE_REL_INDIV__c = 'SR'
        );
        indivRels.add(rel);
    }
    insert indivRels;  
}

    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        UpdateCaseIndividualStatusBatch batchJob = new UpdateCaseIndividualStatusBatch();
        Id batchId = Database.executeBatch(batchJob);
        Test.stopTest();
        
        //  PC 
        List<T_SBSD_CASE_INDIV__c> pcRecords = [
            SELECT Id, INDIVIDUAL_STATUS__c 
            FROM T_SBSD_CASE_INDIV__c 
            WHERE IND_CRTKR__c = true
        ];
        
        for (T_SBSD_CASE_INDIV__c record : pcRecords) {
            System.assertEquals('PC', record.INDIVIDUAL_STATUS__c, 'Caretaker status should be PC');
        }
        
        //  AC 
        List<T_SBSD_CASE_INDIV__c> acRecords = [
            SELECT Id, INDIVIDUAL_STATUS__c, IDN_CLIENT__c 
            FROM T_SBSD_CASE_INDIV__c 
            WHERE IND_CRTKR__c = false AND IDN_CLIENT__c IN (
                SELECT IDN_CLIENT_RELTD__c FROM T_INDIV_REL__c 
                WHERE CDE_TYPE_REL_INDIV__c IN ('CLH', 'CLW', 'H', 'LIC', 'SO')
            )
        ];
        
        for (T_SBSD_CASE_INDIV__c record : acRecords) {
            System.assertEquals('AC', record.INDIVIDUAL_STATUS__c, 'Status should be AC for qualifying relationships');
        }
        
        // Child
        List<T_SBSD_CASE_INDIV__c> childRecords = [
            SELECT Id, INDIVIDUAL_STATUS__c, IDN_CLIENT__c 
            FROM T_SBSD_CASE_INDIV__c 
            WHERE IND_CRTKR__c = false AND IDN_CLIENT__c IN (
                SELECT IDN_CLIENT_RELTD__c FROM T_INDIV_REL__c 
                WHERE CDE_TYPE_REL_INDIV__c = 'SR'
            )
        ];
        
        for (T_SBSD_CASE_INDIV__c record : childRecords) {
            System.assertEquals('Child', record.INDIVIDUAL_STATUS__c, 'Status should be Child for non-qualifying relationships');
        }
    }*/
}