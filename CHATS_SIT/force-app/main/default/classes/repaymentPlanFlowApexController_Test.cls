/*************************************************************
Class Name      - repaymentPlanFlowApexController_Test
Covering Class  - repaymentPlanFlowApexController
Author          - Rishav Maji
**************************************************************/
@isTest
public with sharing class repaymentPlanFlowApexController_Test {
    
    public static testMethod void testMethod1(){
        TestClassUtility.createCounty('County1', 'County1', 1, true);
        TestClassUtility.createCounty('County2', 'County2', 2, true);
        TestClassUtility.createCounty('County3', 'County3', 3, true);
        TestClassUtility.createCounty('County4', 'County4', 4, true);
        String profId1 = [SELECT Id, Name FROM Profile WHERE Name = 'Eligibility Worker Supervisor' LIMIT 1].Id;
        User u1 = TestClassUtility.createUser(profId1, 'test', 'test', 'test@example.com', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        u1.Owner_County__c = '1';
        u1.Common_County__c = '2;3;4;';
        String profId2 = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u2 = TestClassUtility.createUser(profId2, 'test', 'test', 'test@example.com', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        Insert u2;
        T_CHATS_PROVR_STATUS__c provRec = TestClassUtility.createProvider(true, 'Level 1');
        Test.startTest();
        System.runAs(u1){
            List<Map<String, String>> assignedCounties = repaymentPlanFlowApexController.getAssignedCounties('1', 'T_PMT_PLAN__c', u1);
            T_PMT_PLAN__c rpp = TestClassUtility.createPaymentPlan(false, provRec.Id, 10, null, null);
            LightningServerResponse dmlResult = repaymentPlanFlowApexController.saveRepaymentPlan(rpp);
            LightningServerResponse initData1 = repaymentPlanFlowApexController.getInitData(provRec.Id);
            LightningServerResponse initData2 = repaymentPlanFlowApexController.getInitData(rpp.Id);
            System.assertEquals(5, assignedCounties.size());
            System.assertEquals(true, dmlResult.isSuccessful);
            System.assertEquals(true, initData1.isSuccessful);
            System.assertEquals(true, initData2.isSuccessful);
        }
        List<Map<String, String>> assignedCounties = repaymentPlanFlowApexController.getAssignedCounties('1', 'T_PMT_PLAN__c', u2);
        System.assertEquals(true, assignedCounties.size() > 1);
        Test.stopTest();
    }

}