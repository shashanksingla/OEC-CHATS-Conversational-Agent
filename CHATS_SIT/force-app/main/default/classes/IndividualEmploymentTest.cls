@isTest
public class IndividualEmploymentTest {
    
    public static testMethod void testGetEmploymentDetails(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, system.today(), 'firstName', '1', 'lastName', '123', 'CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id, true);
        caseIndiv.DTE_END_EFFV__c = null;
        Insert caseIndiv;
        T_SBSD_INDIV_EMPLMT__c emp = new T_SBSD_INDIV_EMPLMT__c();
        emp.IDN_CLIENT__c = individual.Id;
        emp.ADR_CITY__c = 'TestCity';
        emp.ADR_LINE_1__c = 'Line1';
        emp.ADR_LINE_2__c = 'Line2';
        emp.ADR_ZIP_MAIN__c = '12345';
        emp.ADR_ZIP_EXTN__c = '1234';
        emp.ADR_STATE__c = 'CO';
        emp.DTE_BEGIN_EFFV__c = System.today();
        emp.IND_STUBS_PAY_RCVS__c = 'N';
        emp.NAM_BUSNS__c = 'TestBusiness';
        emp.DTE_END_EFFV__c = null;
        emp.IDN_CASE__c = caseRec.Id;
        Insert emp;
        T_EMPLMT_INCOME__c income = new T_EMPLMT_INCOME__c();
        income.IDN_EMPLMT_INDIV__c = emp.Id;
        income.CDE_STATUS__c = 'ACT';
        income.DTE_BEGIN_EFFV__c = System.today();
        income.AMT_INCOME_ANNUAL_ESTMD__c = 50;
        income.CNT_WEEK_PER_HOURS_ESTMD__c = 20;
        income.CDE_FREQ_PAY_ESTMD__c = '1PY';
        income.CDE_TYPE_VERIF__c = 'SD';
        Insert income;
        
        Test.startTest();
        LightningServerResponse response = IndividualEmployment.getEmploymentDetails(caseRec.id);
        System.debug('response:' + response.objectData);
        System.assertEquals(true, response.objectData.get('data') != null);
        List<IndivEmploymeentWrapper> data = (List<IndivEmploymeentWrapper>)response.objectData.get('data');
        Test.stopTest();
    }
}