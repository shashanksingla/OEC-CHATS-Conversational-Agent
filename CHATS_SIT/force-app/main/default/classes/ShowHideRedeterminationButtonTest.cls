@isTest
public class ShowHideRedeterminationButtonTest {
    public static testMethod void testGetInitData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,false);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '15';
        insert caseRec;
        List<T_SBSD_CASE__c> caseRecords = [SELECT id FROM T_SBSD_CASE__c LIMIT 1];
        LightningServerResponse lsr = ShowHideRedeterminationButtonCtrl.getInitData(caseRecords.get(0).Id); 
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSucessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('caseRecord'), 'lsr.objectData should contain caseRecord as key');
    }
}