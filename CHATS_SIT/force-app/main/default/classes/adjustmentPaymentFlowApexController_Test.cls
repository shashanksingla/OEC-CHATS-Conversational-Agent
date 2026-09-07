/*************************************************************
Class Name      - adjustmentPaymentFlowApexController_Test
Covering Class  - adjustmentPaymentFlowApexController
Author          - Rishav Maji
**************************************************************/
@isTest
public class adjustmentPaymentFlowApexController_Test {
    
    public static testMethod void testMethod1(){
        TestClassUtility.createCounty('County1', 'County1', 1, true);
        TestClassUtility.createCounty('County2', 'County2', 2, true);
        TestClassUtility.createCounty('County3', 'County3', 3, true);
        TestClassUtility.createCounty('County4', 'County4', 4, true);
        String profId1 = [SELECT Id, Name FROM Profile WHERE Name = 'Eligibility Worker Supervisor' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(profId1, 'test', 'test', 'test@example.com', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u1.Owner_County__c = '1';
        u1.common_county__c = '2;3;4';
        String profId2 = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u2 = TestClassUtility.createUser(profId2, 'test', 'test', 'test@example.com', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        Insert u2;
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Level 1');
        Test.startTest();
        System.runAs(u1){
            LightningServerResponse initData1 = adjustmentPaymentFlowApexController.getInitData(provRec.Id, 'T_CHATS_PROVR_STATUS__c');
            LightningServerResponse initData2 = adjustmentPaymentFlowApexController.getInitData(provRec.Id, 'Test');
            T_ADJMT_PMT__c ap = TestClassUtility.createAdjustmentPayment(false, null, provRec.Id);
            LightningServerResponse dmlResult = adjustmentPaymentFlowApexController.saveAdjustmentPayment(ap);
            System.assertEquals(true, initData1.isSuccessful);
            System.assertEquals(false, initData2.isSuccessful);
            System.assertEquals(true, dmlResult.isSuccessful);
        }
        System.runAs(u2){
            LightningServerResponse initData1 = adjustmentPaymentFlowApexController.getInitData(null, 'T_CHATS_PROVR_STATUS__c');
            System.assertEquals(true, initData1.isSuccessful);
        }
        Test.stopTest();
    }
}