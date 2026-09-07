@isTest(seeAllData=false)
public class FiscalAgreementTriggerTest {
    public static testMethod void testCaseLastUpdatedFields(){
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_STATUS_PROVR__c='Open');
        insert provider;
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        
        Test.startTest();
        T_COUNTY__c county = TestClassUtility.createCounty('TestCounty','Test1',12,true);
        //String providerId =TestClassUtility.createProvider(true,'Test').Id;
        T_PROVR_FISCAL_AGREMENT__c providerFA1 =  TestClassUtility.createFiscaAgreement(false,'test',System.today(),county.Id);
        providerFA1.ID_SERVICE__c=provider.Id;
        providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.CDE_TYPE_STATUS__c='OPN';
        insert providerFA1;
        insert new T_PAYMT__c(IDN_PROVR__c=provider.Id,CDE_COUNTY__c=county.Id,
                                    CDE_METHOD_PMT__c='EBT',
                                    AMT_PMT__c=22
                                   );
		// 05.16.2018 - Assert added for code Review changes :Shubham K.
	        
        T_PROVR_FISCAL_AGREMENT__c openFA = [Select Id,DTE_END_AGRMT__c,RecordtypeId,CDE_TYPE_STATUS__c,CDE_REASON_END_AGRMT__c,CDE_COUNTY__c,
                                              ID_SERVICE__c from T_PROVR_FISCAL_AGREMENT__c];
        
        T_PAYMT__c paymt = [Select Id,IDN_EXTNL__c from T_PAYMT__c];
        
        System.assertEquals('OPN', openFA.CDE_TYPE_STATUS__c,'Fiscal Agreement should be in open status');
        System.assertEquals(paymt.id, paymt.IDN_EXTNL__c,'Payment record id and external id should match');
        Test.stopTest();
    }
}