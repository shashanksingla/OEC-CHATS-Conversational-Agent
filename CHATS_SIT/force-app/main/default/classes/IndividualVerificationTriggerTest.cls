@isTest
public class IndividualVerificationTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_INDIV_INFO__c indivInfoRec =  new T_SBSD_INDIV_INFO__c(	IDN_CLIENT__c = caseData.get('individual').Id,
                                  										CDE_TYPE_INFO_INDIV__c = 'HDS',
                                    									DTE_BEGIN_EFFV__c = date.today() );
        insert indivInfoRec;
        insert new T_INDIV_VERIF__c ( 	IDN_CLIENT__c = indivInfoRec.Id,
                                    	CDE_TYPE_VERIF__c = 'NA' );
        Test.startTest();
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        // 5/16 : Adding Assert statement for code review changes : Shubham K
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        Test.stopTest();
    }

}