@isTest
public class EducationTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_INDIV_EDUC__c indivEduc = new T_INDIV_EDUC__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                   	CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today() );
        insert indivEduc;
        Test.startTest();
        T_INDIV_EDUC_INFO__c indivEduc1 = new T_INDIV_EDUC_INFO__c(	IDN_EDUC_INDIV__c=indivEduc.Id,
                                   	CDE_TYPE_INFO_EDUC__c = 'MPL',
                                       CDE_TYPE_VERIF__c = 'NA',
                                   	DTE_BEGIN_EFFV__c = date.today() );
        insert indivEduc1;
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        TeenEduBreakBatch obj = new TeenEduBreakBatch();
        DataBase.executeBatch(obj);
        // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }

}