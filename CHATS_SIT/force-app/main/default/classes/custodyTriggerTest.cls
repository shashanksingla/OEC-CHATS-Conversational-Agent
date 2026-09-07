@isTest
public class custodyTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        update new T_SBSD_CASE_INDIV__c(Id=caseData.get('caseIndiv').Id,IND_CRTKR__c=false);
        insert new T_INDIV_CUST__c(IDN_CLIENT__c=caseData.get('individual').Id,
                                           Ignore__c=true);
        Test.startTest();
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
		T_INDIV_CUST__c custody =[Select Id, IDN_EXTNL__c  from T_INDIV_CUST__c Limit 1];
        system.assertEquals(custody.Id,custody.IDN_EXTNL__c,'External Id is not matching with record Id');
        Test.stopTest();
    }
}