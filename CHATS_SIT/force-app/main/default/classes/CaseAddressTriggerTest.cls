@isTest
public class CaseAddressTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_CASE_ADR__c(IDN_CASE__c=caseData.get('caseRec').Id,ADR_LINE_1__c='line1',
                                        CDE_TYPE_ADR__c='MAL',
                                        ADR_CITY__c='NY',
                                        CDE_SOURCE_VRFD_ADR__c='AR',
                                        ADR_STATE__c='CO',
                                        CDE_TYPE_VERIF__c='HL',
                                        ADR_ZIP_MAIN__c='12345'
                                        );
        
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 10];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }
}