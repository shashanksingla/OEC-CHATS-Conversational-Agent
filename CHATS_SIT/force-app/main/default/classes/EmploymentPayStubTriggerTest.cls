@isTest
public class EmploymentPayStubTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        
        T_SBSD_INDIV_EMPLMT__c employment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',IDN_CLIENT__c=caseData.get('individual').Id,
                                                                        NAM_BUSNS__c='test',
                                                                        DTE_BEGIN_EFFV__c=system.today(),
                                                                        Ignore__c=true);
                                
        
        insert employment;
        
        T_EMPLMT_INCOME__c empIncome = new T_EMPLMT_INCOME__c(IDN_EMPLMT_INDIV__c=employment.Id,
                                                              DTE_BEGIN_EFFV__c=system.today(),
                                                              CNT_WEEK_PER_HOURS_ESTMD__c = 20.00,
                                                              AMT_INCOME_ANNUAL_ESTMD__c = 10000.00,
                                                              CDE_FREQ_PAY_ESTMD__c = 'MON',
                                                              CDE_TYPE_VERIF__c = 'SD');
        insert empIncome;
        
        insert new T_EMPLMT_PAY_STUB__c(IDN_EMPLMT_INCOME__c=empIncome.Id, CDE_TYPE_VERIF__c ='NA');
        
        
        Test.startTest();
        CaseLastUpdatedTestFactory.testCaseDataUpdate();
        
        //05.16.2018 - Assert added for code review changes : Shubham K	 
        
        List<T_SBSD_CASE__c> caseRecords = [SELECT IND_CHGD_DATA_ELIGTY__c, DTE_CHGD_LAST_DATA_ELIGTY__c FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false,caseRecords.isEmpty(),'caseRecords should not be empty');
        System.assertEquals(System.today(), caseRecords.get(0).DTE_CHGD_LAST_DATA_ELIGTY__c, 'DTE_CHGD_LAST_DATA_ELIGTY__c should be equal to today');
        
        Test.stopTest();
    }
}