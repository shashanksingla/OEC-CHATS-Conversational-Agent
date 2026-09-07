@isTest
public class ProviderClosureDatesBatch_Test {
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    
    public static testmethod void unitBatchTest(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1]?.Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        
        System.runAs(u1){
            ByPass_Validation_Setting__c byPass=new ByPass_Validation_Setting__c();
            byPass.Is_Batch_Excluded__c=false;
            insert byPass;
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
            Date datetoday=System.Today();
            T_PROVR_CLOSURE__c provClosure = new T_PROVR_CLOSURE__c(IDN_PROVIDER__c=provider.Id, CDE_COUNTY__c = county.Id,IND_ACTIVE__c = true,DTE_BEGIN_CLOSURE__c=datetoday-8);
            insert provClosure;
            
            Test.startTest();
            ProviderClosureDatesBatch batch = new ProviderClosureDatesBatch();
            database.executebatch(batch);
            Test.stopTest();
        }
    }
}