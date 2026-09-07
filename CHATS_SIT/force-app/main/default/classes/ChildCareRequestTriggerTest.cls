@isTest
public class ChildCareRequestTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_INDIV_CAT_RQ__c(	IDN_CASE_INDIV__c = caseData.get('caseIndiv').Id,
                                  		CDE_CAT_PROG__c = 'CC',
                                    	DTE_BEGIN_EFFV__c = date.today() );
        Test.startTest();
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
         // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }

}