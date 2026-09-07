@isTest
public class EligibilityHistoryFlowCmpApxCtrlTest {
    
    public static testMethod void testGetInitDataError(){
        LightningServerResponse lsr = EligibilityHistoryFlowCmpApxCtrl.getInitData(null);
        System.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false');
    }

    public static testMethod void testGetInitData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '1';
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-25),'firstNameB','1','lastNameB','123','CC');
        insert new List<SObject>{caseRec,individual, individual2};
        List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isempty(), 'cases should not be empty');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id,false);
        T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual2.Id,true);
        caseIndiv.IDN_EXTNL__c='1';
        caseIndiv2.IDN_EXTNL__c='2';
        T_SBSD_INDIV_EMPLMT__c employment =  new T_SBSD_INDIV_EMPLMT__c(	IDN_CLIENT__c=individual.Id,
                                  		 									ADR_CITY__c = 'Denver',
                                 		  									IND_STUBS_PAY_RCVS__c = 'Y',
                                  		 									DTE_BEGIN_EFFV__c = date.today(),
                                         									NAM_BUSNS__c = 'DellCorp',
                                                                       		IDN_EXTNL__c='1',
                                                                       Ignore__c=true);
        insert new List<SObject>{caseIndiv, caseIndiv2, employment};
        LightningServerResponse lsr = EligibilityHistoryFlowCmpApxCtrl.getInitData(null);
    }

    public static testMethod void testValidateConfirmEligibility(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '1';
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-25),'firstNameA','1','lastNameA','123','CC');
        insert new List<SObject>{caseRec,individual, individual2};
        List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c FROM T_SBSD_CASE__c];
        System.assertEquals(false, cases.isempty(), 'cases should not be empty');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual.Id,false);
        T_SBSD_CASE_INDIV__c caseIndiv2 = TestClassUtility.createCaseIndividual(false, caseRec.Id, individual2.Id,true);
        caseIndiv.IDN_EXTNL__c='1';
        caseIndiv2.IDN_EXTNL__c='2';
        insert new List<SObject>{caseIndiv, caseIndiv2};
        LightningServerResponse lsr = EligibilityHistoryFlowCmpApxCtrl.validateConfirmEligibility(null);
    }

    public static testMethod void testValidateConfirmEligibilityError(){
        LightningServerResponse lsr = EligibilityHistoryFlowCmpApxCtrl.validateConfirmEligibility(null);
        System.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false');
    }
    
        
}