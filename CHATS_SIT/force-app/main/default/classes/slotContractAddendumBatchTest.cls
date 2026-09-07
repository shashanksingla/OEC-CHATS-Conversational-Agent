@isTest
public class slotContractAddendumBatchTest {

    public static testMethod void testSCAddendumBatch(){
        Test.startTest();
        T_COUNTY__c countyRecord = TestClassUtility.createCounty('countyName', 'CD', 99, true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_PROVR_FISCAL_AGREMENT__c faRecord = TestClassUtility.createFiscaAgreement(false, 'FA-00001', System.today().addDays(-15), countyRecord.Id);
        faRecord.ID_SERVICE__c = provider.Id;
        insert faRecord;
        T_SLOT_CONTRACT_ADDENDUM__c slotContAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
        slotContAdd.CDE_COUNTY__c = countyRecord.Id;
        slotContAdd.IDN_FISCAL_AGREEMENT__c = faRecord.Id;
        slotContAdd.CDE_STATUS__c = 'OPN';
        slotContAdd.DTE_END_ADDENDUM__c = System.today().addDays(15);
        insert slotContAdd; 
        Database.executeBatch(new SlotContractAddendumBatch(),200);
        Test.stopTest();
        
        try{
            delete slotContAdd;
        }catch(Exception e){
            System.assert(e.getMessage().contains('Slot Contract Addendum is not in Draft or Finalized Status, so cannot be deleted.'));
        }
    }
}