@isTest
public class IndividualInformationTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_INDIV_INFO__c(	IDN_CLIENT__c = caseData.get('individual').Id,
                                        CDE_TYPE_INFO_INDIV__c = 'HDS',
                                        IDN_EXTNL__c = '12345',
                                        DTE_BEGIN_EFFV__c = date.today() );
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        // 5.16.2018 - Added assert statement as part of code review changes :Shubham K
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        
        Test.stopTest();
    }

}