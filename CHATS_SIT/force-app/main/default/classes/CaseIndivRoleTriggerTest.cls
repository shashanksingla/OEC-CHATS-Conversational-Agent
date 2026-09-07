@isTest
public class CaseIndivRoleTriggerTest {
 public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_CASE_INDIV_ROLE__c(IDN_CASE_INDIV__c=caseData.get('caseIndiv').Id,DTE_BEGIN_EFFV__c= System.today(),
                                        DTE_END_EFFV__c=System.today(),
                                        CDE_ROLE_CASE__c='HOH');
        
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
     	 // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }
}