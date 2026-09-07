@isTest
public class CaseAssetTriggerTest {
public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_CASE_ASSET__c(IDN_CASE__c=caseData.get('caseRec').Id,NBR_LIQUID_AMT__c= 12,
                                        NBR_NON_LIQUID_AMT__c=10,
                                        IND_HAS_ASSET__c= false);
        
        Test.startTest();
       // CaseLastUpdatedTestFactory.testCaseDataUpdate();
       	List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }
}