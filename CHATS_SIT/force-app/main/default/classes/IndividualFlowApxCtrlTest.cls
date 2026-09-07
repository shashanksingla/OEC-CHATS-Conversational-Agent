@isTest
public class IndividualFlowApxCtrlTest {
    public static testMethod void testCheckIfIntakeCase(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_CASE_STATUS_MODE__c caseStaMod = TestClassUtility.createCaseStatusMode(false, caseRec.Id);
        caseStaMod.CDE_MODE_CASE__c = 'INT';
        insert caseStaMod;
        LightningServerResponse lsr = IndividualFlowApxCtrl.checkIfIntakeCase(caseRec.Id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
    }
}