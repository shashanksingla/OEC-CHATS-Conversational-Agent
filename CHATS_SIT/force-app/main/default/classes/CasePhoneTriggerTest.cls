@isTest
public class CasePhoneTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseData.get('caseRec').Id,NBR_PHONE__c='123456',
                                        NBR_PHONE_EXTN__c=3244,
                                        CDE_TYPE_PHONE__c='HOM');
        
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
         // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }
}