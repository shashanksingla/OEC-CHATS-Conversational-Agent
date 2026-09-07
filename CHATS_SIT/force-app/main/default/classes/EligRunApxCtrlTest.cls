@isTest
public class EligRunApxCtrlTest {
    public static testMethod void testGetInitData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '15';
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstNameA','1','lastNameA','123','CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(false,system.today().addYears(-25),'firstNameB','1','lastNameB','123','CC');
        insert new List<SObject>{caseRec,individual,individual2};
            LightningServerResponse lsr = EligRunApxCtrl.getInitData(null, null); 
        
    }
}