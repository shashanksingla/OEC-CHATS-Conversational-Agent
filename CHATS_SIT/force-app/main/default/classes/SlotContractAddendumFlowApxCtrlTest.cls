@isTest
public class SlotContractAddendumFlowApxCtrlTest {
    
       static testMethod void getInitDataTest() {
       T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
       provider.CDE_TYPE_PROVR__c = 'EFACH';
       insert provider;
       Date datetoday=System.Today();
       Date begindateOpn=System.Today()-10;
       Date nullDate;
       Date firstDayOfNextMonth = date.newInstance(datetoday.year(),datetoday.month()+1,1);
       T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
       T_COUNTY_RATE__c crp = new T_COUNTY_RATE__c( CFS_Q1__c = 'Y', CFS_Q1_2__c = 3.0, 
                                                    DTE_BEGIN_EFFV_RATE__c = firstDayOfNextMonth, DTE_END_EFFV_RATE__c = nullDate, 
                                                    CDE_STATUS__c = 'APV', IDN_COUNTY__c = county.Id);
        insert crp;
       T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
       fiscalAgreement.ID_SERVICE__c=provider.Id;
       insert fiscalAgreement;
       T_SLOT_CONTRACT_ADDENDUM__c scAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
       scAdd.IDN_FISCAL_AGREEMENT__c = fiscalAgreement.Id;
       scAdd.DTE_BEGIN_ADDENDUM__c = datetoday;
       insert scAdd;
       Test.startTest();
       LightningServerResponse lightserresobj= SlotContractAddendumFlowApxCtrl.getInitData(fiscalAgreement.Id);
       System.assertEquals(lightserresobj.isSuccessful,true);
       Test.stopTest();
       
    }
 
    static testMethod void saveSlotContractAddendumTestone() {
       
       T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
       provider.CDE_TYPE_PROVR__c = 'EFACH';
       insert provider;
       Date datetoday=System.Today();
       Date begindateOpn=System.Today()-10;
       Date nullDate;
       Date firstDayOfNextMonth = date.newInstance(datetoday.year(),datetoday.month()+1,1);
       T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
       T_COUNTY_RATE__c crp = new T_COUNTY_RATE__c( CFS_Q1__c = 'Y', CFS_Q1_2__c = 3.0, 
                                                    DTE_BEGIN_EFFV_RATE__c = firstDayOfNextMonth, DTE_END_EFFV_RATE__c = nullDate, 
                                                    CDE_STATUS__c = 'APV', IDN_COUNTY__c = county.Id);
        insert crp;
       T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
       fiscalAgreement.ID_SERVICE__c=provider.Id;
       insert fiscalAgreement;
       T_SLOT_CONTRACT_ADDENDUM__c scAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
       scAdd.IDN_FISCAL_AGREEMENT__c = fiscalAgreement.Id;
       scAdd.DTE_BEGIN_ADDENDUM__c = datetoday;
       scAdd.DTE_END_ADDENDUM__c = System.Today()+10;
       scAdd.CDE_STATUS__c = 'FIN';
       scAdd.CDE_COUNTY__c = county.Id;
       insert scAdd;
       Test.startTest();
       LightningServerResponse lightserresobjone= SlotContractAddendumFlowApxCtrl.saveSlotContractAddendum(scAdd); 
      System.assertEquals(lightserresobjone.isSuccessful,true);
        Test.stopTest();
       
    }
    

}