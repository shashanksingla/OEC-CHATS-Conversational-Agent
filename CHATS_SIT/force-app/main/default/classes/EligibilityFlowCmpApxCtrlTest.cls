/*
*/
@isTest
public class EligibilityFlowCmpApxCtrlTest {
    public static testMethod void testGetInitDataError(){
        LightningServerResponse lsr = EligibilityFlowCmpApxCtrl.getInitData(null);
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
        LightningServerResponse lsr = EligibilityFlowCmpApxCtrl.getInitData(null);
        //System.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false');
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
        LightningServerResponse lsr = EligibilityFlowCmpApxCtrl.validateConfirmEligibility(null, null);
        System.assertEquals(true,lsr.isSuccessful);
    }

    public static testMethod void testValidateConfirmEligibilityError(){
        LightningServerResponse lsr = EligibilityFlowCmpApxCtrl.validateConfirmEligibility(null, null);
        System.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false');
    }

    public static testMethod void testsaveCaseProgramType(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false); 
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        Test.startTest();
        insert caseRec;
        LightningServerResponse lsr = EligibilityFlowCmpApxCtrl.saveCaseProgramType(caseRec.Id, 'LI');
        System.assertEquals(true, lsr.isSuccessful, 'isSuccessful should be true');
        Test.stopTest();
    }
	//
	public static testMethod void testdoCallBREConfirmEligibilityContinuation()
    {
		string caseId = 'CA-1';
		String RunID = '12345';
		CaseLastUpdatedTestFactory.createCaseData();
		//Continuation conti = (Continuation)ContinuationController.invoke(null, null);	
        List<T_SBSD_CASE__c> cases = [SELECT Id FROM T_SBSD_CASE__c limit 202];
        List<String> params = new List<String>{cases.get(0).Id,'TF'};
        Continuation conti = (Continuation)ContinuationController.invoke('BRECreate', params);
		EligibilityFlowCmpApxCtrl.doCallBREConfirmEligibilityContinuation(conti, caseId, RunID);
	}
    //
	public static testMethod void testdoCallBackBREConfirmEligibilityContinuation()
    {
		string stat = 'Continuation-1';
		EligibilityFlowCmpApxCtrl.doCallBackBREConfirmEligibilityContinuation(stat);
	}
	//
	public static testMethod void testupdateAuthAndEnrollment()
    {
		CaseLastUpdatedTestFactory.createCaseData();
		List<T_SBSD_CASE__c> cases = [SELECT Id FROM T_SBSD_CASE__c limit 202];
		String programType = 'not-CW';
		//
		T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        insert countyRec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_CASE_ADR__c caseAddr = new T_SBSD_CASE_ADR__c();
        caseAddr.ADR_CITY__c = 'Denver';
        caseAddr.ADR_LINE_1__c = '102 street- test';
        caseAddr.ADR_STATE__c = 'CO';
        caseAddr.ADR_ZIP_MAIN__c = '80111';
        caseAddr.CDE_TYPE_ADR__c = 'MAL';
        caseAddr.IDN_CASE__c = caseRec.Id;
        caseAddr.DTE_BEGIN_EFFV__c = Date.today()-1;
        insert caseAddr;
		//
		T_COUNTY__c county1 =TestClassUtility.createCounty('County11','Dept11',10,true);
		T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'Provider Test', TXT_CHATS_RATING__c ='Level 1', CDE_TYPE_PROVR__c = 'prs');
        insert provider;
		//
		T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, System.today().addYears(-1), 'firstName','1', 'lastName','989898989','CC');
        T_AUTH__c acc = new T_AUTH__c();
            acc.DTE_END_EFFV_AUTH__c = system.today();
            acc.DTE_BEGIN_EFFV_AUTH__c = System.today();
            acc.IDN_PROVR__c = provider.Id;
        	acc.CDE_COUNTY__c = county1.Id;
			acc.Protective_Services_Indicator__c = false;
        	acc.IDN_CASE__c = cases[0].Id;
			acc.IDN_CLIENT__c = individual.Id;
        insert acc;
		//
		
		//
		EligibilityFlowCmpApxCtrl.updateAuthAndEnrollment(cases[0].Id, programType);
	}
	//
}