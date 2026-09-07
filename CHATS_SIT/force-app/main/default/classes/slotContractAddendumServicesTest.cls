@isTest
public class slotContractAddendumServicesTest {

    static testMethod void finalizeSlotContractAddendumUpdateTest() {
        T_SLOT_CONTRACT_ADDENDUM__c SCAdde = new T_SLOT_CONTRACT_ADDENDUM__c();
        SCAdde.CDE_STATUS__c = 'DFT';
        insert SCAdde;
        Test.startTest();
       LightningServerResponse lightserresobj= SlotContractAddendumServices.finalizeSlotContractAddendumUpdate(SCAdde.Id);
        System.assertEquals(lightserresobj.isSuccessful,true);
        Test.stopTest();
    }
    
    static testMethod void beforeDeleteCheckAddendumStatusTest() {
        List<T_SLOT_CONTRACT_ADDENDUM__c> SCAddRecs = new List<T_SLOT_CONTRACT_ADDENDUM__c>();
        T_SLOT_CONTRACT_ADDENDUM__c SCAdde = new T_SLOT_CONTRACT_ADDENDUM__c();
        SCAdde.CDE_STATUS__c = 'OPN';
        insert SCAdde;
        SCAddRecs.add(SCAdde);
        T_SLOT_CONTRACT_ADDENDUM__c SCAddeone = new T_SLOT_CONTRACT_ADDENDUM__c();
        SCAdde.CDE_STATUS__c = 'CLS';
        insert SCAddeone;
        SCAddRecs.add(SCAddeone);
        Test.startTest();
        SlotContractAddendumServices.beforeDeleteCheckAddendumStatus(SCAddRecs);
        
        Test.stopTest();
    }
      static testMethod void deleteSlotContractAddendumRecordTest() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        Date begindateOpn=System.Today()-10;
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        T_SLOT_CONTRACT_ADDENDUM__c SCAdde = new T_SLOT_CONTRACT_ADDENDUM__c();
        SCAdde.CDE_STATUS__c = 'OPN';
        SCAdde.CDE_COUNTY__c = county.Id;
        SCAdde.IDN_FISCAL_AGREEMENT__c = fiscalAgreement.Id;
        insert SCAdde;
        Test.startTest();
       LightningServerResponse lightserresobj= SlotContractAddendumServices.deleteSlotContractAddendumRecord(SCAdde.Id);
        System.assertEquals(lightserresobj.isSuccessful,true);
          Test.stopTest();
    }
    
}