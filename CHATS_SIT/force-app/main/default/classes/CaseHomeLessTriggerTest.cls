@isTest
public class CaseHomeLessTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new T_SBSD_CASE_HOMELESS__c(IDN_CASE__c=caseData.get('caseRec').Id,DTE_BEGIN_EFFV__c= date.today().addDays(-1),                                           
                                           Is_family_homeless__c='N');
        
        T_SBSD_CASE_HOMELESS__c homeless = new T_SBSD_CASE_HOMELESS__c(IDN_CASE__c=caseData.get('caseRec').Id,DTE_BEGIN_EFFV__c= System.Today(),                                           
                                           Is_family_homeless__c='N');
        Test.startTest();
        insert homeless;
        T_SBSD_CASE_HOMELESS__c Rec = [Select DTE_END_EFFV__c from T_SBSD_CASE_HOMELESS__c order by createddate asc limit 1 ];
        System.assertEquals(System.Today().addDays(-1),rec.DTE_END_EFFV__c,'Should be end dated');
        // CaseLastUpdatedTestFactory.testCaseDataUpdate();
        // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }
}