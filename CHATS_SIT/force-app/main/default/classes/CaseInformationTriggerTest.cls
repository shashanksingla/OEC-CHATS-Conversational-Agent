@isTest
public class CaseInformationTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
    	T_SBSD_CASE_INFO__c caseInfoUpdate = new T_SBSD_CASE_INFO__c();
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE_INFO__c caseInfoInsert = new T_SBSD_CASE_INFO__c(IDN_CASE__c=caseData.get('caseRec').Id,TXT_VALUE_INFO_CASE__c='test@example.com',
                                        CDE_TYPE_INFO_CASE__c='EM');
		insert caseInfoInsert;
		
		caseInfoUpdate = [select Id from T_SBSD_CASE_INFO__c where Id =:caseInfoInsert.Id limit 1];
        caseInfoUpdate.TXT_VALUE_INFO_CASE__c = 'test1@example.com';
        update caseInfoUpdate;                                        
        
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
         // 5/16/2018 - Assert statement added for Code Review Changes : Shubham K.
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        
        // 5/28/2018 Restricting user from creating not more than one Email Type
        try {
            insert new T_SBSD_CASE_INFO__c(IDN_CASE__c=caseData.get('caseRec').Id,TXT_VALUE_INFO_CASE__c='test133@example.com',
                                        CDE_TYPE_INFO_CASE__c='PMC');
        
        } 
        catch(Exception ex) {
            system.assert(string.valueOf(ex.getMessage()).contains(Label.Please_update_the_existing_Email_record_for_that_case),'Should return right error message');      
        
        }
        
        Test.stopTest();
        
        
    }
}