@isTest
public class caseInfoFlowApxCtrlTest {
    public static testMethod void testCaseInfo(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c sbsdcase=new T_SBSD_CASE__c();
        sbsdcase.CDE_COUNTY__c=countyRec.Id;
        sbsdcase.IND_ASSIST_PROVR__c = 'N';
        sbsdcase.IND_ELG_PRE_PROVR__c  = false;
        insert sbsdcase;
        T_SBSD_CASE_INFO__c caseinforec=new T_SBSD_CASE_INFO__c ();
        caseinforec.IDN_CASE__c=sbsdcase.Id;
        caseinforec.CDE_TYPE_INFO_CASE__c='PMC';
        caseinforec.TXT_VALUE_INFO_CASE__c='testing';
        insert caseinforec;
        
        Test.startTest();
        caseInfoFlowApxCtrl.getDoInit(caseinforec.id);
        Test.stopTest();
    }

}