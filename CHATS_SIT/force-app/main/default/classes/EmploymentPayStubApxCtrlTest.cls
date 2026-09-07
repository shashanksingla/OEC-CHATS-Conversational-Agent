@isTest
public class EmploymentPayStubApxCtrlTest {
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
        T_EMPLMT_PAY_STUB__c payStub = new T_EMPLMT_PAY_STUB__c(IDN_EMPLMT_INCOME__c=empIncome.Id, CDE_TYPE_VERIF__c ='NA');
        insert payStub;
        
        
        Test.startTest();
        EmploymentPayStubApxCtrl.getDoInit(empIncome.id);
        EmploymentPayStubApxCtrl.getDoInit(payStub.id);
        EmploymentPayStubApxCtrl.getDoInit('');
        Test.stopTest();
    }
}