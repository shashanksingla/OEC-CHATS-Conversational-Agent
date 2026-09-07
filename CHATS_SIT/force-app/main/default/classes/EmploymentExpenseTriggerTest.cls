@isTest
public class EmploymentExpenseTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c; 
        Map<String,Schema.RecordTypeInfo> employmentRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(    IDN_CLIENT__c=caseData.get('individual').Id,
                                                                            ADR_CITY__c = 'Denver',
                                                                            IND_STUBS_PAY_RCVS__c = 'Y',
                                                                            DTE_BEGIN_EFFV__c = date.today(),
                                                                            NAM_BUSNS__c = 'DellCorp',
                                                                            RecordTypeId = employmentRecordTypeInfo .get('Self-Employment').getRecordTypeId());
        insert employment;
        T_EMPLMT_INCOME__c empIncome = new T_EMPLMT_INCOME__c ( IDN_EMPLMT_INDIV__c = employment.Id,
                                                                DTE_BEGIN_EFFV__c = date.today(),
                                                                CNT_WEEK_PER_HOURS_ESTMD__c = 20.00,
                                                               	AMT_INCOME_ANNUAL_ESTMD__c = 10000.00,
                                                               	CDE_FREQ_PAY_ESTMD__c = 'MON',
                                                                   CDE_TYPE_VERIF__c = 'NA'
                                                                );
        insert empIncome;
        insert new T_SBSD_EMPLMT_EXP__c (   IDN_EMPLMT_INDIV__c = employment.Id
                                             );
        
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        //05.16.2018 - Added assert statement for Code Review changes.:Shubham K
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        Test.stopTest();
    }

}