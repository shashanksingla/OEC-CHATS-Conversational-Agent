@isTest
public class CBMSAdditionalInformTriggerTest {
    public static testMethod void testCaseServices(){
        Test.startTest();
        T_CBMS_ADDNL_INFO__c cs = new T_CBMS_ADDNL_INFO__c();
        cs.IDN_CASE_INTFC__c = 'test';
        cs.CDE_CAT_ACTIV__c = 'CMA';
        cs.DTE_BEGIN_EFFEV__c = system.today();
        insert cs; 
        List<T_CBMS_ADDNL_INFO__c> csList = [Select Id from T_CBMS_ADDNL_INFO__c where Id =:cs.Id];
        System.assertEquals(csList.size(),1);
        Test.stopTest();
        
    }
}