@isTest
public class BatchUpdateProviderBackground_Test {
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    
 public static testMethod void testUpdateProviderBackground(){
        T_COUNTY__c county = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Test');
     	provider.CDE_TYPE_PROVR__c = 'EFACH';
     	provider.CDE_REQ_BGC_CHK_STATE__c = 'Cleared';
     	provider.CDE_STATUS_PROVR__c = 'Open';
     	update provider;
   
     	Date begindateOpn=System.Today()-10;
     
     	T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.RecordtypeId = openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c = 'OPN';
        fiscalAgreement.ID_SERVICE__c = provider.Id;
     	fiscalAgreement.DTE_END_AGRMT__c = Date.Today()+10;
        insert fiscalAgreement;	
     
     	T_PROVR_CBC__c provrCBC = new T_PROVR_CBC__c (CDE_CBC_STATUS__c = 'MST', NAM_FIRST__c = 'fname', NAM_LAST__c = 'lname',
                                                      IDN_PROVR__c = provider.Id, CDE_BGC_CHK_STATUS__c = 'Cleared',
                                                      DTE_ProvFinFA_CareEff__c = System.today());
        insert provrCBC;
     
        Test.startTest();
		String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            BatchUpdateProviderBackground batch = new BatchUpdateProviderBackground();
            database.executebatch(batch);
        }
        Test.stopTest();

    }
}