@isTest
public class providerCBCTriggerTest {
    
    static testmethod void testProviderCBCTrigger(){
        T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', TXT_CHATS_RATING__c = 'abcdef');
        insert provrObj;
        
        T_CHATS_PROVR_STATUS__c provrObj1 = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abcd', CDE_STATUS_PROVR__c = 'Open', TXT_CHATS_RATING__c = 'abcdefg',CDE_TYPE_PROVR__c = 'EFACH');
        insert provrObj1;
        
        T_COUNTY__c countyObj = new T_COUNTY__c (CDE_COUNTY__c = 3);
        insert countyObj;
        T_COUNTY__c countyObj2 = new T_COUNTY__c (CDE_COUNTY__c = 4);
        insert countyObj2;
        
        Id recordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c fiscAgrmntObj = new T_PROVR_FISCAL_AGREMENT__c (RecordTypeId = recordTypeId, CDE_TYPE_STATUS__c = 'FIN', 
                                                                                   ID_SERVICE__c = provrObj.Id, CDE_COUNTY__c = countyObj.Id, 
                                                                                   DTE_BEGIN_AGRMT__c = date.today(), DTE_RCV_AGRMT_FISCAL__c = date.today());
        insert fiscAgrmntObj;
        
        Id recordTypeId2 = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Draft').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c fiscAgrmntObj2 = new T_PROVR_FISCAL_AGREMENT__c (RecordTypeId = recordTypeId2, CDE_TYPE_STATUS__c = 'DFT', 
                                                                                   ID_SERVICE__c = provrObj1.Id, CDE_COUNTY__c = countyObj2.Id, 
                                                                                   DTE_BEGIN_AGRMT__c = date.today(), DTE_RCV_AGRMT_FISCAL__c = date.today(),
                                                                                   ownerId = Userinfo.getUserId());
        insert fiscAgrmntObj2;
        
        T_PROVR_CBC__c provrCBC = new T_PROVR_CBC__c (CDE_CBC_STATUS__c = 'MST', NAM_FIRST__c = 'fname', NAM_LAST__c = 'lname',
                                                      IDN_PROVR__c = provrObj.Id, CDE_BGC_CHK_STATUS__c = 'Cleared',
                                                      DTE_ProvFinFA_CareEff__c = System.today());
        
        T_PROVR_CBC__c provrCBC1 = new T_PROVR_CBC__c (CDE_CBC_STATUS__c = 'MST', NAM_FIRST__c = 'fname', NAM_LAST__c = 'lname',
                                                      IDN_PROVR__c = provrObj1.Id, CDE_BGC_CHK_STATUS__c = 'Cleared',
                                                      DTE_ProvFinFA_CareEff__c = System.today());
        
        Test.startTest();
        insert provrCBC;
        insert provrCBC1;
        for(Task taskeach:[Select Id, Subject from Task Limit 10]) {
            system.assertEquals(true, taskeach.subject.contains('T202') || taskeach.subject.contains('T218'), 'Task subject should be matching');
        }
        provrCBC.DTE_ProvFinFA_CareEff__c = null;
        update provrCBC;
        provrCBC.DTE_ProvFinFA_CareEff__c = System.today();
        update provrCBC;
        provrCBC1.DTE_ProvFinFA_CareEff__c = null;
        update provrCBC1;
        provrCBC1.DTE_ProvFinFA_CareEff__c = System.today();
        update provrCBC1;
        Test.stopTest();
    }
}