/*
*/
@isTest
public class IndividualVerificationFlowApxCtrlTest {
	
    public static testMethod void testGetInitData(){
        LightningServerResponse lsr = null;
        List<T_SBSD_INDIV__c> indivRecs = [SELECT id FROM T_SBSD_INDIV__c];
        System.assertNotEquals(true, indivRecs.isEmpty(), 'indivRecs should not be empty');
        List<T_SBSD_INDIV_INFO__c> indivInfos = [SELECT id FROM T_SBSD_INDIV_INFO__c WHERE IDN_CLIENT__c = :indivRecs.get(0).Id];
		System.assertEquals(false, indivInfos.isEmpty(), 'indivInfos should not be empty');
        lsr = IndividualVerificationFlowApxCtrl.getInitData(indivRecs.get(0).Id);
        System.assertEquals(true, lsr.objectData.containsKey('indVerif'), 'objectData should contain not indVerif as key');
        T_INDIV_VERIF__c expectedRecord = (T_INDIV_VERIF__c)lsr.objectData.get('indVerif');
		System.assertEquals(null, expectedRecord.Id, 'Id should be null');
        insert new T_INDIV_VERIF__c(IDN_CLIENT__c = indivInfos.get(0).Id, CDE_TYPE_INFO_INDIV__c = 'CS', CDE_TYPE_VERIF__c = 'V');
        lsr = IndividualVerificationFlowApxCtrl.getInitData(indivRecs.get(0).Id);
        System.assertEquals(true, lsr.objectData.containsKey('indVerif'), 'objectData should contain indVerif as key');
        List<T_INDIV_VERIF__c> actualResults = [SELECT CDE_TYPE_VERIF__c FROM T_INDIV_VERIF__c WHERE IDN_CLIENT__r.IDN_CLIENT__c = :indivRecs.get(0).Id AND CDE_TYPE_INFO_INDIV__c = 'CS' LIMIT 1];
        System.assertNotEquals(true, actualResults.isEmpty(), 'actualResults should not be empty');
        expectedRecord = (T_INDIV_VERIF__c)lsr.objectData.get('indVerif');
        System.assertEquals(actualResults.get(0).Id, expectedRecord.Id, 'Id should match for both the records');
        IndividualVerificationFlowApxCtrl.isReadOnlyProfile();
        CitizenshipDatafixBatch obj = new CitizenshipDatafixBatch();
        DataBase.executeBatch(obj);
    }
    
    @testSetup
    public static void testSetup(){
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
		indivRec.CDE_SOURCE_VRFYD_CITIZEN__c = 'AC';
        insert indivRec;
        indivRec.Is_Peak_Data__c = true;
        update indivRec;
        T_SBSD_INDIV_INFO__c indivInfo =  new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = indivRec.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-15), DTE_END_EFFV__c = System.today().addDays(15), CDE_TYPE_INFO_INDIV__c= 'CS');
        insert indivInfo;
    }
}