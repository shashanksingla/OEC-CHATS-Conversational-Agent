@isTest
public class T204TaskCreationBatchTest {
    
    public static testMethod void testT204TaskCreationBatch(){
        
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_COUNTY__c countyObj2 = TestClassUtility.createCounty('countyName2', 'countyDepartmentName2',12,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(false, 'Test');
        providerObj.CDE_STATUS_PROVR__c='Open';
        providerObj.cde_type_provr__c='EFACH';
        insert providerObj;
        
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c providerFA1 =  TestClassUtility.createFiscaAgreement(false,'test',System.today(),countyObj.Id);
        providerFA1.ID_SERVICE__c=providerObj.Id;
        providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.CDE_TYPE_STATUS__c='OPN';
        providerFA1.DTE_END_AGRMT__c = System.today().addDays(90);
        
        
        insert providerFA1;
        providerFA1=[select Id,Name,OwnerId from T_PROVR_FISCAL_AGREMENT__c where id=:providerFA1.Id];
    
    
    	/*Task tsk= new Task();
        tsk.Subject = 'T204 - Fiscal Agreement Renewal Date is within 60 days';
        tsk.WhatId = providerFA1.Id;
        tsk.OwnerId = providerFA1.OwnerId;
        tsk.Status = 'Not Started';
        tsk.Priority = 'Normal';
        tsk.ActivityDate= System.today().addDays(60);
        insert tsk;*/
        
        Test.startTest();
        Database.executeBatch(new T204TaskCreationBatch());
        Test.stopTest();
        System.assertEquals(1, [Select Subject from Task where Subject='T204 - Fiscal Agreement Renewal Date is within 90 days'].size());
    
    
    }

}