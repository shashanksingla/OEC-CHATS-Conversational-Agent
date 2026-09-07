/*************************************************************
Class Name	    - UpdateProviderFromFA_oneTimeBatch_Test
Covering Class	- UpdateProviderFromFA_oneTimeBatch
Author          - Rishav Maji
**************************************************************/
@isTest
public class UpdateProviderFromFA_oneTimeBatch_Test {

    @testSetup  
    public static void doSetup(){
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 1, true);
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(false, 'Level 1');
        provRec.NAM_FACILITY__c = 'testProv';
        Triggers_On_Off_Settings__c triggerService = new Triggers_On_Off_Settings__c();
        triggerService.Name = 'FiscalAgreementTrigger';
        triggerService.Active__c = false;
        GenericDMLHandler.insertRecords(new List<SObject>{provRec, triggerService}, null);
        
        T_PROVR_FISCAL_AGREMENT__c faRec = new T_PROVR_FISCAL_AGREMENT__c();
        faRec.DTE_BEGIN_AGRMT__c = System.today();
        faRec.CDE_COUNTY__c = countyRec.Id;
        faRec.DTE_RCV_AGRMT_FISCAL__c = System.today();
        faRec.ID_SERVICE__c = provRec.Id;
        faRec.CDE_TYPE_STATUS__c = 'OPN';
        faRec.RecordTypeId = openRecordTypeId;
        GenericDMLHandler.insertRecords(new List<Sobject>{faRec}, null);
        
        triggerService.Active__c = true;
        GenericDMLHandler.updateRecords(new List<SObject>{triggerService}, null);
    }
    
    public static testMethod void testMethod1(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u1 = TestClassUtility.createUserWithPS(uuId, 'System_Administrator_PS', 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        System.runAs(u1){
            Test.startTest();
            UpdateProviderFromFA_oneTimeBatch batch = new UpdateProviderFromFA_oneTimeBatch();
            database.executebatch(batch);
            Test.stopTest();
            T_CHATS_PROVR_STATUS__c prov = [SELECT Id, DTE_Original_FA__c FROM T_CHATS_PROVR_STATUS__c WHERE NAM_FACILITY__c = 'testProv' LIMIT 1];
            System.assertEquals(System.today(), prov.DTE_Original_FA__c);
        }
    }
}