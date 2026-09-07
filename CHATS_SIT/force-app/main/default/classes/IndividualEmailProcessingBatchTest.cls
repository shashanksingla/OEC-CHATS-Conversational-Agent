@isTest
public class IndividualEmailProcessingBatchTest {
    
    @testSetup
    static void setupTestData() {
        T_COUNTY__c testCounty = TestClassUtility.createCounty('Test County Department', 'Test County Department', 1, true);
        
        List<T_SBSD_INDIV__c> individuals = new List<T_SBSD_INDIV__c>();
        for (Integer i = 0; i < 5; i++) {
            T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(
                false, 
                System.today().addYears(-25), 
                'Test', 
                '1', 
                'Individual', 
                '12345678' + i, 
                'CC'
            );
            individuals.add(individual);
        }
        insert individuals;
        
        List<T_SBSD_CASE__c> cases = new List<T_SBSD_CASE__c>();
        for (Integer i = 0; i < 5; i++) {
            T_SBSD_CASE__c testCase = TestClassUtility.createCase(false, testCounty.Id);
            cases.add(testCase);
        }
        insert cases;
        
        List<Individual_E_mail__c> emailRecords = new List<Individual_E_mail__c>();
        for (Integer i = 0; i < 5; i++) {
            Individual_E_mail__c emailRecord = new Individual_E_mail__c();
            emailRecord.Individual__c = individuals[i].Id;
            emailRecord.Email_Information__c = 'test' + i + '@example.com';
            emailRecord.Effective_Begin_Date__c = Date.today();
            emailRecords.add(emailRecord);
        }
        insert emailRecords;
        
        List<T_SBSD_CASE_INDIV__c> caseIndividuals = new List<T_SBSD_CASE_INDIV__c>();
        for (Integer i = 0; i < 3; i++) {
            T_SBSD_CASE_INDIV__c caseIndividual = TestClassUtility.createCaseIndividual(
                false, 
                cases[i].Id, 
                individuals[i].Id, 
                true
            );
            caseIndividuals.add(caseIndividual);
        }
        insert caseIndividuals; 
               
        T_SBSD_CASE_INFO__c existingCaseInfo = new T_SBSD_CASE_INFO__c();
        existingCaseInfo.IDN_CASE__c = cases[0].Id;
        existingCaseInfo.CDE_TYPE_INFO_CASE__c = 'EM';
        existingCaseInfo.TXT_VALUE_INFO_CASE__c = 'old@example.com';
        insert existingCaseInfo;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        IndividualEmailProcessingBatch batch = new IndividualEmailProcessingBatch();
        Id jobId = Database.executeBatch(batch, 200);        
        Test.stopTest();        
        List<T_SBSD_CASE_INFO__c> caseInfos = [SELECT Id, IDN_CASE__c, CDE_TYPE_INFO_CASE__c, TXT_VALUE_INFO_CASE__c
            FROM T_SBSD_CASE_INFO__c WHERE CDE_TYPE_INFO_CASE__c = 'EM'];
        System.assertEquals(3, caseInfos.size(), 'Expected 3 T_SBSD_CASE_INFO__c records');
        Set<String> expectedEmails = new Set<String>{'test0@example.com', 'test1@example.com', 'test2@example.com'};
        Set<String> actualEmails = new Set<String>();        
        for (T_SBSD_CASE_INFO__c caseInfo : caseInfos) {
            actualEmails.add(caseInfo.TXT_VALUE_INFO_CASE__c);
            System.assertEquals('EM', caseInfo.CDE_TYPE_INFO_CASE__c, 'CDE_TYPE_INFO_CASE__c should be Email');
        }        
        System.assertEquals(expectedEmails, actualEmails, 'Email values should match expected values');
    }
    
    @isTest
    static void testBatchWithNoData() {
        delete [SELECT Id FROM Individual_E_mail__c];
        delete [SELECT Id FROM T_SBSD_CASE_INDIV__c];        
        Test.startTest();        
        IndividualEmailProcessingBatch batch = new IndividualEmailProcessingBatch();
        Id jobId = Database.executeBatch(batch, 200);        
        Test.stopTest();        
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully even with no data');
    }

    @isTest
    static void testBatchWithNonPrimaryCaretakerStatus() {
        List<T_SBSD_CASE_INDIV__c> caseIndividuals = [SELECT Id, Individual_Status__c FROM T_SBSD_CASE_INDIV__c];
        for (T_SBSD_CASE_INDIV__c caseIndividual : caseIndividuals) {
            caseIndividual.Individual_Status__c = 'AC';
        }
        update caseIndividuals;        
        Test.startTest();        
        IndividualEmailProcessingBatch batch = new IndividualEmailProcessingBatch();
        Id jobId = Database.executeBatch(batch, 200);        
        Test.stopTest();
        List<T_SBSD_CASE_INFO__c> caseInfos = [SELECT Id FROM T_SBSD_CASE_INFO__c WHERE CDE_TYPE_INFO_CASE__c = 'EM'];        
        System.assertEquals(1, caseInfos.size(), 'Should not create new records for non-primary caretaker status');
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();        
        IndividualEmailProcessingBatch batch = new IndividualEmailProcessingBatch();
        SchedulableContext sc = null;
        batch.execute(sc);        
        Test.stopTest();
        System.assert(true, 'Schedulable execute method should complete without errors');
    }
}