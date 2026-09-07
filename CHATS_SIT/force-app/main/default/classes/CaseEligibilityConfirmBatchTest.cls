@isTest
public class CaseEligibilityConfirmBatchTest {
    class MockCareLevel extends QueryExternalObjects {
        final List<batchsit_t_eligty_run__x> externalRecords;
        MockCareLevel(List<batchsit_t_eligty_run__x> externalRecords) {
            this.externalRecords = externalRecords;
        }
        protected override List<SObject> passThrough(List<SObject> records) {
            return externalRecords;
        }
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            res.setBody('{"ErrorValue":[]}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }
    @isTest 
    static void CaseEligibilityConfirmBatchTestMethod(){
        T_COUNTY__c county = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, Date.newInstance(1988,3,3), 'firstnameT', '1', 'lastnameT', '123456789', 'CC');
        T_SBSD_INDIV__c indiv2 = TestClassUtility.createIndividual(true, Date.newInstance(1989,3,3), 'fnameT', '2', 'lnameT', '999999999', 'CC');
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE__c caseRec2 = new T_SBSD_CASE__c(IND_MissingInfo_Status__c='OPEN', IDN_EXTNL__c='Test12345');
        insert caseRec2;        
        List<String> caseIds = new List<String>();
        caseIds.add(caseRec2.Id);
        caseIds.add(caseRec.Id);
        T_SBSD_CASE_STATUS_MODE__c caseStatusMode = new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRec2.Id, CDE_MODE_CASE__c = 'RED');
        insert caseStatusMode;
        batchsit_t_eligty_run__x eligrun = new batchsit_t_eligty_run__x(idn_run_eligty__c=1234, idn_case__c = caseRec2.IDN_EXTNL__c, cde_eligty_cfmd__c = 'NCM', dte_run_eligty__c = System.today());
        List<batchsit_t_eligty_run__x> eligrunlist = new List<batchsit_t_eligty_run__x>();
        eligrunlist.add(eligrun);
        QueryExternalObjects.setMock(new MockCareLevel(eligrunlist));
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 

        Test.startTest();
        CaseEligibilityConfirmBatch batch = new CaseEligibilityConfirmBatch(caseIds);
        Database.executeBatch(batch,1);
        Test.stopTest();

        List<Task> tsk = [SELECT Id FROM Task WHERE WhatId = :caseRec2.Id];
        System.assertEquals(1, tsk.size(), 'There must be one task created');
    }
}