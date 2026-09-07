@isTest
public class ProviderServicesTest {
    
    @testSetup
    static void testDataSetup()
    {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User fromUser = TestClassUtility.createUserWithPS(userProfile.Id, 'System_Administrator_PS', 'test1', 'test1', 'test1@example.com', 'test1@example.com.' + string.valueof(math.random() * 3), 'ttes1');
        if (fromUser != null) {
            fromUser.Owner_County__c = '1';
            update fromUser;
        }

        System.runAs(fromUser) {
            T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', CDE_TYPE_PROVR__c = 'PRS', Slot_Contract_Suggestion__c = 'test~BREAK~test:vlaue', TXT_CHATS_RATING__c = '0');
            insert provrObj;
            T_COUNTY__c county = TestClassUtility.createCounty('Test Name', 'Department', 2, true);
            T_AUTH__c authorization = TestClassUtility.createAuthorization(true, System.today().addDays(20), System.today().addDays(25), county.Id, provrObj.Id);

            T_SLOT_CONTRACT_ADDENDUM__c scAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
            	scAdd.CDE_COUNTY__c = county.Id;
            Insert scAdd;
            T_SLOT_CONTRACT__c sc = new T_SLOT_CONTRACT__c();
                sc.IDN_AUTH__c = authorization.Id;
                sc.CDE_COUNTY__c = county.Id;
                sc.IDN_PROVIDER__c = provrObj.Id;
                sc.IDN_ADDENDUM__c = scAdd.Id;
                sc.DTE_END_SLOT__c = System.today().addDays(1);
                sc.DTE_BEGIN_SLOT__c = system.today();
                sc.IND_AVAILABLE__c = true;
            Insert sc;

            T_PROVR_FISCAL_AGREMENT__c fiscAgrRec = new T_PROVR_FISCAL_AGREMENT__c(ID_SERVICE__c = provrObj.Id, CDE_TYPE_STATUS__c = 'DFT');
            insert fiscAgrRec;

            Task task1 = TestClassUtility.createTask(false, 'T116 – Provider has made a suggestion for a Slot Contract record', 'Test Decription', 'Not started', authorization.Id, fromUser.Id);
        }
    }
    
    static testmethod void testProviderTrigger(){
        T_CHATS_PROVR_STATUS__c provrClosedUpd = new T_CHATS_PROVR_STATUS__c();
        T_CHATS_PROVR_STATUS__c provrQRISUpd = new T_CHATS_PROVR_STATUS__c();
        
        T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', TXT_CHATS_RATING__c = 'abcdef');
        T_CHATS_PROVR_STATUS__c provrObj1 = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abcd', CDE_STATUS_PROVR__c = 'Open', TXT_CHATS_RATING__c = 'abcdef');
        T_CHATS_PROVR_STATUS__c provrObj2 = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'test', CDE_STATUS_PROVR__c = 'Open', TXT_CHATS_RATING__c = 'abcdef', CDE_TYPE_PROVR__c = 'EFACH', CDE_REQ_BGC_CHK_STATE__c = 'Cleared');
        T_COUNTY__c countyObj = new T_COUNTY__c (CDE_COUNTY__c = 3);
        T_COUNTY__c countyObj1 = new T_COUNTY__c (CDE_COUNTY__c = 4);
        GenericDMLHandler.insertRecords(new List<Sobject>{provrObj, provrObj1, provrObj2, countyObj, countyObj1}, null);
        
        Id recordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        Id recordTypeId2 = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c fiscAgrmntObj = new T_PROVR_FISCAL_AGREMENT__c (RecordTypeId = recordTypeId, CDE_TYPE_STATUS__c = 'FIN', ID_SERVICE__c = provrObj.Id, CDE_COUNTY__c = countyObj.Id, DTE_BEGIN_AGRMT__c = date.today(), DTE_RCV_AGRMT_FISCAL__c = date.today());
        T_PROVR_FISCAL_AGREMENT__c fiscAgrmntObj1 = new T_PROVR_FISCAL_AGREMENT__c (RecordTypeId = recordTypeId, CDE_TYPE_STATUS__c = 'FIN', ID_SERVICE__c = provrObj1.Id, CDE_COUNTY__c = countyObj.Id, DTE_BEGIN_AGRMT__c = date.today(), DTE_RCV_AGRMT_FISCAL__c = date.today());
        T_PROVR_FISCAL_AGREMENT__c fiscAgrmntObj2 = new T_PROVR_FISCAL_AGREMENT__c (RecordTypeId = recordTypeId2, CDE_TYPE_STATUS__c = 'OPN', ID_SERVICE__c = provrObj2.Id, CDE_COUNTY__c = countyObj1.Id, DTE_BEGIN_AGRMT__c = date.today(), DTE_RCV_AGRMT_FISCAL__c = date.today());
        GenericDMLHandler.insertRecords(new List<Sobject>{fiscAgrmntObj, fiscAgrmntObj1, fiscAgrmntObj2}, null);
        
        test.startTest();
        provrClosedUpd.Id = provrObj.Id;
        provrClosedUpd.CDE_STATUS_PROVR__c = 'Closed';
        Update provrClosedUpd;
        
        List<Task> clsdTask = [select OwnerId, Subject, WhatId FROM TASk WHERE OwnerId =:UserInfo.getUserId() AND WhatId =:fiscAgrmntObj.Id];
        if(clsdTask.size()>0){
            system.assertEquals('T200 - Provider License is Closed' , clsdTask.get(0).Subject,'Subject of the task should match'); 
            // CHATS_1_46_2_H
        }
        
        provrQRISUpd.Id = provrObj1.Id;
        provrQRISUpd.TXT_CHATS_RATING__c = 'xyz';
        Update provrQRISUpd;
        
        List<Task> qrisUpdtdTask = [select OwnerId, Subject, WhatId FROM TASk WHERE OwnerId =:UserInfo.getUserId() AND WhatId =:fiscAgrmntObj1.Id];
        if (qrisUpdtdTask.size()> 0){
            system.assertEquals('T205 - Provider Rating Changed To Quality Rating Tier xyz' , qrisUpdtdTask.get(0).Subject,'Subject of the task should match');
        }
        
        provrObj2.CDE_REQ_BGC_CHK_STATE__c = 'Not Cleared';
        Update provrObj2;
        ProviderServices.getUserAssignedCounties();
        test.stopTest();
    }
    
    static testmethod void setDefaultValue(){
        Test.startTest();
        T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', CDE_TYPE_PROVR__c = 'PRS');
        insert provrObj;
        Test.stopTest();
    }
    
    static testmethod void updateFacilityTypeonFiscalAgreements_Test(){
        
        /*T_CHATS_PROVR_STATUS__c provrObj = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', CDE_TYPE_PROVR__c = 'PRS', Slot_Contract_Suggestion__c = 'test~BREAK~test:vlaue');
        insert provrObj;
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        T_AUTH__c authorization=TestClassUtility.createAuthorization(true,System.today().addDays(20),System.today().addDays(25),county.Id,provrObj.Id);
        
        T_SLOT_CONTRACT_ADDENDUM__c scAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
        	scAdd.CDE_COUNTY__c = county.Id;
        Insert scAdd;
        T_SLOT_CONTRACT__c sc = new T_SLOT_CONTRACT__c();
            sc.IDN_AUTH__c = authorization.Id;
            sc.CDE_COUNTY__c = county.Id;
            sc.IDN_PROVIDER__c = provrObj.Id;
            sc.IDN_ADDENDUM__c = scAdd.Id;
            sc.DTE_END_SLOT__c = System.today().addDays(1);
            sc.DTE_BEGIN_SLOT__c = system.today();
            sc.IND_AVAILABLE__c = true;
        Insert sc;
        
        T_PROVR_FISCAL_AGREMENT__c fiscAgrRec = new T_PROVR_FISCAL_AGREMENT__c(ID_SERVICE__c = provrObj.Id, CDE_TYPE_STATUS__c = 'DFT');
        insert fiscAgrRec;*/
        
        List<T_CHATS_PROVR_STATUS__c> provrObj = [Select Id, Name,NAM_FACILITY__c,CDE_STATUS_PROVR__c,CDE_TYPE_PROVR__c,Slot_Contract_Suggestion__c from T_CHATS_PROVR_STATUS__c LIMIT 1];
        List<T_AUTH__c> authorization = [Select Id, Name from T_AUTH__c LIMIT 1];
        List<T_SLOT_CONTRACT__c> sc = [Select Id, name from T_SLOT_CONTRACT__c LIMIT 1];
        List<Task> taskValue = [Select Id from Task LIMIT 1];
        
        Test.startTest();
        
        provrObj[0].TXT_CHATS_RATING__c = '0';
        provrObj[0].CDE_TYPE_PROVR__c = 'CPD ';
        provrObj[0].Slot_Contract_Suggestion__c = 'Authorization:' + authorization[0].Name + '~BREAK~'+'SlotContract:'+sc[0].Name+'~BREAK~COMMENT:' + authorization[0].Id;
        system.debug('value of Slot_Contract_Suggestion__c is: ' + provrObj[0].Slot_Contract_Suggestion__c);
        update provrObj;
        
        T_CHATS_PROVR_STATUS__c provrObj1 = new T_CHATS_PROVR_STATUS__c (NAM_FACILITY__c = 'abc', CDE_STATUS_PROVR__c = 'Open', CDE_TYPE_PROVR__c = 'CPD');
        insert provrObj1;
		T_PROVR_FISCAL_AGREMENT__c fiscAgrRec1 = new T_PROVR_FISCAL_AGREMENT__c(ID_SERVICE__c = provrObj1.Id, CDE_TYPE_STATUS__c = '');
        insert fiscAgrRec1;
        provrObj1.CDE_TYPE_PROVR__c = '';
        update provrObj1;  
       
        Test.stopTest();
    }
}