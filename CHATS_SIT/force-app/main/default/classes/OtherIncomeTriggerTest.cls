@isTest
public class OtherIncomeTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_INDIV_OTHER_INCOME__c(IDN_CLIENT__c=caseData.get('individual').Id,
                                           CDE_FREQ_INCOME__c='2PM',
                                           AMT_INCOME_OTHER_GROSS__c=100,
                                           CDE_SOURCE_VRFYD_INCOME__c='ACA',
                                           CDE_SOURCE_INCOME__c='AB',
                                           CDE_TYPE_VERIF__c='NA');
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        // 5/16 : Added below Assert statements for Code Review Changes : Shubham k 
        
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        System.assertEquals(true, caseRecords.get(0).IND_CHGD_DATA_ELIGTY__c, 'IND_CHGD_DATA_ELIGTY__c should be true');
        Test.stopTest();
    }
}