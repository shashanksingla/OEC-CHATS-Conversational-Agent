@isTest
public class CountyPlanApprovalActionTest {    
    @testSetup
    static void setupTestData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Test County', 'Test Department Name',1, true);
        T_COUNTY_PLAN__c cpRec = TestClassUtility.createCountyPlan('PEN', false);
        cpRec.CDE_COUNTY__c = countyRec.Id;
        cpRec.Flow_Completed__c = true;
        insert cpRec;
        Triggers_On_Off_Settings__c triggerService = new Triggers_On_Off_Settings__c();
        triggerService.Name = 'CountyPlanTrigger';
        triggerService.Active__c = false;
        GenericDMLHandler.insertRecords(new List<SObject>{triggerService}, null);
    }

    //test with no pending approval action
    @isTest
    static void testhandleApproval1(){
        T_COUNTY_PLAN__c cpRec = [SELECT Id FROM T_COUNTY_PLAN__c LIMIT 1];
        CountyPlanApprovalAction.InputWrapper input = new CountyPlanApprovalAction.InputWrapper();
        input.recordId = cpRec.Id;
        input.actionType = 'Approve';
        input.comments = 'Test Approval';
        Test.startTest();
        List<CountyPlanApprovalAction.OutputWrapper> outList = CountyPlanApprovalAction.handleApproval(new List<CountyPlanApprovalAction.InputWrapper>{input});
        System.assertEquals('No pending approval found for the record.', outList[0].message, 'The message should indicate no pending approval found.');
        Test.stopTest();
    }
    
    //test with pending approval action
    @isTest
    static void testhandleApproval2(){
        T_COUNTY_PLAN__c cpRec = [SELECT Id FROM T_COUNTY_PLAN__c LIMIT 1];
        CountyPlanApprovalAction.InputWrapper input = new CountyPlanApprovalAction.InputWrapper();
        input.recordId = cpRec.Id;
        input.actionType = 'Approve';
        input.comments = 'Test Approval';
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(cpRec.Id);
        req.setComments('Test submission');
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.Process(req);
        Test.startTest();
        List<CountyPlanApprovalAction.OutputWrapper> outList = CountyPlanApprovalAction.handleApproval(new List<CountyPlanApprovalAction.InputWrapper>{input});
        System.assertEquals('County Plan approval completed successfully.', outList[0].message, 'The message should indicate successful approval.');
        Test.stopTest();
    }
}