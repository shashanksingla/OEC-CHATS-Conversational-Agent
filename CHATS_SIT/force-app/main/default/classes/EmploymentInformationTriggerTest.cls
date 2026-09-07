@isTest
public class EmploymentInformationTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
		Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
		
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=caseData.get('individual').Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today(),
                                         									NAM_BUSNS__c = 'DellCorp' );
        insert employment;
        insert new T_INDIV_EMPLMT_INFO__c (	IDN_EMPLMT_INDIV__c = employment.Id,
                                        	CDE_TYPE_INFO_EMPLMT__c = 'EIW',
                                          DTE_BEGIN_EFFV__c = system.today());
        
        Test.startTest();
		CaseLastUpdatedTestFactory.testCaseDataUpdate();
        EmploymentTempBreakBatch obj = new EmploymentTempBreakBatch();
        DataBase.executeBatch(obj);
        //05.16.2018 - Assert added for Code Review changes - Shubham K
        
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        
        Test.stopTest();
    }


}