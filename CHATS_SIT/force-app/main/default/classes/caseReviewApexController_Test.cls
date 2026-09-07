/*************************************************************
Class Name	    - caseReviewApexController_Test
Covering Class	- caseReviewApexController
Author          - Rishav Maji
**************************************************************/
@isTest
public class caseReviewApexController_Test {
    
    class MockParentFee extends QueryExternalObjects {
        final List<batchsit_t_sbsd_case_copay__x> externalRecords;
        MockParentFee(List<batchsit_t_sbsd_case_copay__x> externalRecords) {
            this.externalRecords = externalRecords;
        }
        protected override List<SObject> passThrough(List<SObject> records) {
            return externalRecords;
        }
    }

    @testSetup
    public static void doSetup(){
        String uuId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = TestClassUtility.createUser(uuId, 'test', 'test', 'test@example.com.invalid', 'test@example.com.'+string.valueof(math.random()*3), 'ttes');
        List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name='System_Administrator_PS' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = psList[0].Id, AssigneeId =u.Id);
        Insert u;
        String profileId = [SELECT Id, Name FROM Profile WHERE Name = 'Fiscal Worker' LIMIT 1].Id;
        User u2 = TestClassUtility.createUser(profileId, 'abc', 'abc', 'abc@example.com.invalid', 'abc@example.com.'+string.valueof(math.random()*3), 'abc');
        u2.Owner_County__c = '16';
        Insert  u2;
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver', 'Denver', 16, false);
        Insert countyRec;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        Review_Question__c rq = new Review_Question__c();
        rq.Active__c = true; rq.Case_Type__c = 'TF'; rq.Element__c = 'test'; rq.NA_Reason_Options__c = '1;2';
        rq.Order__c = 1; rq.Question__c = 'test'; rq.Review_Requirement__c = 'test'; rq.Review_Type__c = 'Case';
        Insert rq;
        Case_Review__c cr = new Case_Review__c(Case__c = caseRec.Id);
        Insert cr;
        Case_Review_Response__c crr = new Case_Review_Response__c();
        crr.Case_Review__c = cr.Id;
        Insert crr;
        /*
        User_and_Email_Settings__c ues1 = new User_and_Email_Settings__c();
        ues1.Name = 'T119 Assignee';
        ues1.Value__c = (String)u.Id;
        Insert ues1;*/
    }
    
    public static testMethod void caseReviewApexController_Test1(){
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' LIMIT 1];
        T_SBSD_CASE__c caseRec = [SELECT Id FROM T_SBSD_CASE__c LIMIT 1];
        Review_Question__c rq = [SELECT Id FROM Review_Question__c LIMIT 1];
        Case_Review__c cr = [SELECT Id FROM Case_Review__c WHERE Case__c = :caseRec.Id LIMIT 1];
        Case_Review_Response__c crr = [SELECT Id FROM Case_Review_Response__c WHERE Case_Review__c = :cr.Id LIMIT 1];
        
        Test.startTest();
        LightningServerResponse resp1_1 = caseReviewApexController.getInitData(caseRec.Id, 'NEW');
        LightningServerResponse resp1_2 = caseReviewApexController.getInitData(cr.Id, 'VIEW');
        LightningServerResponse resp1_3 = caseReviewApexController.getInitData(cr.Id, 'EDIT');
        LightningServerResponse resp2_1 = caseReviewApexController.resubmitLastReview(caseRec.Id);
        LightningServerResponse resp6_1 = caseReviewApexController.handleSampleMonthUpdates(caseRec.Id,'October','2024','NEW',caseRec.Id);
        LightningServerResponse resp6_2 = caseReviewApexController.handleSampleMonthUpdates(cr.Id,'October','2023','VIEW',caseRec.Id);
        LightningServerResponse resp6_3 = caseReviewApexController.handleSampleMonthUpdates(cr.Id,'October','2022','EDIT',caseRec.Id);
    
        User_and_Email_Settings__c ues2 = new User_and_Email_Settings__c();
        ues2.Name = 'T121 Assignee';
        ues2.Value__c = (String)u.Id;
        Insert ues2;
        LightningServerResponse resp3_1 = caseReviewApexController.sumbitForStateReversal(cr.Id, 'Test');
        
        List<Map<String, String>> NAReasonList = new List<Map<String, String>>();
        NAReasonList.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
        Case_Review__c crNew = new Case_Review__c(Case__c = caseRec.Id);
        Case_Review_Response__c crrNew = new Case_Review_Response__c();
        caseReviewApexController.responseWrapper wrp = new caseReviewApexController.responseWrapper();
        wrp.questionRec = rq;
        wrp.responseRec = crrNew;
        wrp.NAReasonOptions = NAReasonList;
        wrp.elementQuestionOptions = NAReasonList;
        LightningServerResponse resp4_1 = caseReviewApexController.saveCaseReview(crNew, new List<Object>{wrp}, 'NEW', 'doSubmit');
        
        String resp5_1 = caseReviewApexController.getVFBaseURL();
        Test.stopTest();
    }
    
    public static testMethod void caseReviewApexController_Test2(){
        T_SBSD_CASE__c caseRec = [SELECT Id FROM T_SBSD_CASE__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceTest.HerokuServiceHttpCalloutMock2());
        LightningServerResponse resp1 = caseReviewApexController.getInitData(null, 'VIEW');
        LightningServerResponse resp6 = caseReviewApexController.getInitData(null, 'NEW');
        LightningServerResponse resp7 = caseReviewApexController.getInitData(null, 'EDIT');

        LightningServerResponse resp2 = caseReviewApexController.resubmitLastReview(null);
        LightningServerResponse resp3 = caseReviewApexController.sumbitForStateReversal(null, 'Test');
        caseReviewApexController.responseWrapper wrp = new caseReviewApexController.responseWrapper();
        LightningServerResponse resp4 = caseReviewApexController.saveCaseReview(null, new List<Object>{wrp}, 'NEW', 'doSubmit');
        LightningServerResponse resp5 = caseReviewApexController.getParentFeeSubsidyAmount(caseRec.Id, '1', '2022','NEW');
        Test.stopTest();
    }
    
    public static testMethod void caseReviewApexController_Test3(){
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' LIMIT 1];
        User u2 = [SELECT Id FROM User WHERE Email = 'abc@example.com.invalid' LIMIT 1];
        T_SBSD_CASE__c caseRec = [SELECT Id FROM T_SBSD_CASE__c LIMIT 1];
        Case_Review__c cr = [SELECT Id FROM Case_Review__c WHERE Case__c = :caseRec.Id LIMIT 1];
        Group grp = [SELECT Id, Name FROM Group WHERE DeveloperName = 'Denver_Lead_Workers_Supervisors'];
        GroupMember gm = new GroupMember(GroupId = grp.id, UserOrGroupId = u.Id);
        Insert gm;
        Test.startTest();
        LightningServerResponse resp1 = caseReviewApexController.submitToReviewee(u.Id, cr.Id);
        System.runAs(u){
            LightningServerResponse resp2_1 = caseReviewApexController.checkEligibility(cr.Id,false);
            LightningServerResponse resp2_2 = caseReviewApexController.checkEligibility(caseRec.Id,false);
            LightningServerResponse resp3_1 = caseReviewApexController.checkRecordAccess(cr.Id);
        }
        System.runAs(u2){
            LightningServerResponse resp2_3 = caseReviewApexController.checkEligibility(cr.Id,false);
            LightningServerResponse resp2_4 = caseReviewApexController.checkEligibility(caseRec.Id,false);
            LightningServerResponse resp3_2 = caseReviewApexController.checkRecordAccess(cr.Id);
        }
        Test.stopTest();
    }
    
    public static testMethod void caseReviewApexController_Test4(){
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' LIMIT 1];
        T_SBSD_CASE__c caseRec = [SELECT Id, CDE_COUNTY__c FROM T_SBSD_CASE__c LIMIT 1];
        T_CHATS_PROVR_STATUS__c prov = TestClassUtility.createProvider(true, '1');
        
        Date nextMonthStartDate = Date.newInstance(System.today().year(), System.today().month()+1, 1);
        Date nextMonthEndDate = Date.newInstance(System.today().year(), System.today().month()+1, 28);
        
        T_AUTH__c auth = TestClassUtility.createAuthorization(false, nextMonthEndDate, nextMonthStartDate, caseRec.CDE_COUNTY__c, prov.Id);
        auth.IDN_CASE__c = caseRec.Id;
        Insert auth;
        
        Id finalizedRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        T_ADJMT__c adj = TestClassUtility.createAdjustment(false, caseRec.CDE_COUNTY__c, caseRec.Id, prov.Id);
        adj.CDE_STATUS_ADJMT__c = '4';
        adj.CDE_TYPE_ADJMT__c = '1';
        adj.DTE_START_ADJMT__c = nextMonthStartDate;
        adj.DTE_END_ADJMT__c = nextMonthEndDate;
        adj.RecordTypeId = finalizedRecordTypeId;
        Insert adj;
        
        T_NON_ADJMT_DETAIL__c nonAdjDet = new T_NON_ADJMT_DETAIL__c(IDN_ADJMT__c = adj.Id, AMT_DETAIL_ADJMT__c = 100, IDN_AUTH__c = auth.Id);
        Insert nonAdjDet;
        
        T_ADJMT_DETAIL__c adjDet = TestClassUtility.createAdjustmentDetail(false, adj.Id);
        adjDet.AMT_DETAIL_ADJMT__c = 200;
        adjDet.IDN_DETAIL_PMT_SUB__c = '44444444';
        Insert adjDet;
        
        List<batchsit_t_sbsd_case_copay__x> copList = new List<batchsit_t_sbsd_case_copay__x>();
        batchsit_t_sbsd_case_copay__x cop = new batchsit_t_sbsd_case_copay__x();
        cop.idn_case__c = caseRec.Id;
        cop.dte_end_effv__c = null;
        cop.dte_begin_effv__c = nextMonthStartDate;
        copList.add(cop);
        QueryExternalObjects.setMock(new MockParentFee(copList));
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        LightningServerResponse resp1 = caseReviewApexController.getParentFeeSubsidyAmount(caseRec.Id, '1', String.valueOf(nextMonthStartDate.year()),'NEW');

        Test.stopTest();
    }

    @isTest
    static void testDeleteCaseReview(){
        Case_Review__c cr = [SELECT Id FROM Case_Review__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' LIMIT 1];
        Boolean exceptionThrown = false;
        Test.startTest();
        System.runAs(u){
        	try {
                caseReviewApexController.deleteCaseReview(cr.Id);
                delete cr;
            } catch (DmlException e) {
                exceptionThrown = true;
            }
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'An exception should have been thrown.');
    }
    
        @isTest
    static void testGenerateTaskComment(){
        Case_Review__c cr = [SELECT Id FROM Case_Review__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' LIMIT 1];
        Test.startTest();
        System.runAs(u){
                String response = caseReviewApexController.generateTaskComment(cr.Id);

        }
        Test.stopTest();
    }
    
            @isTest
    static void getChildCareProgramBySampleMonthYear(){
        T_SBSD_Case__c caseRec = [SELECT id from T_SBSD_CASE__c limit 1];
        User u = [SELECT Id FROM User WHERE Email = 'test@example.com.invalid' LIMIT 1];
        Test.startTest();
        System.runAs(u){
			string resp = caseReviewApexController.getChildCareProgramBySampleMonthYear(caseRec.Id, '11', '2019');
        }
        Test.stopTest();
    }
    

}