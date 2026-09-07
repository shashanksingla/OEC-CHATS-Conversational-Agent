/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/07/2017                                                          
*  @description    Test class for County Plan Trigger                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Sept-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest(seeAllData=false)
public class CountyPlanServices_Test {
    public static T_COUNTY_PLAN__c aCountyPlan=null;
    public static T_COUNTY_PLAN__c countyPlan;
    public static T_COUNTY__c aCounty;
    public static T_COUNTY__c aCountNew;
    public static User user;
    public static User countyPlanApprover = new User();
    //public static User countyPlanApprover = new User();
    public static final String COUNTY_PLAN_APPROVAL_PROCESS = 'County_Plan_Approval_Process';
    static void createTestData(){
        
        aCountyPlan=TestClassUtility.createCountyPlan('PEN', false);
        aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);
        aCountyPlan.CDE_COUNTY__c = aCounty.Id;
        aCountyPlan.DTE_BEGIN_EFFEV__c = System.today().addMonths(1).toStartOfMonth();
        aCountyPlan.CDE_COUNTY_PLAN_TEMPLT__c = '1';
        //aCountyPlan.IND_COUNTY_PLAN_TEMPLT__c = true;
        insert aCountyPlan;
        
        countyPlan = TestClassUtility.createCountyPlan('PEN',false);
        aCountNew = TestClassUtility.createCounty('New County', 'New County Department', 11, true);
        countyPlan.CDE_COUNTY__c = aCountNew.Id;
        countyPlan.DTE_BEGIN_EFFEV__c = System.today().addMonths(2).toStartOfMonth();
        countyPlan.CDE_COUNTY_PLAN_TEMPLT__c = '1';
        countyPlan.Flow_Completed__c = true;
        if(countyPlan!=null){
            insert countyPlan;
        }
        
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.uesername','ttes');
        
        if(user!=null){
            List<User> users = [SELECT Owner_County__c FROM User WHERE id = :UserInfo.getUserId()];
            if(!users.isEmpty()){
                user.Owner_County__c  = users.get(0).Owner_County__c;
            }
            insert user; 
        }
    }
    
    static testmethod void testCountyPlanTrigger(){
        boolean expectedExceptionThrown;
        createTestData();
        Test.startTest();
        aCountyPlan.CDE_STATUS__c='APV';
        createApprover();
        test.stopTest();
        System.runAs(countyPlanApprover){
            update aCountyPlan;
        }
        try{
            delete aCountyPlan;}
        Catch(Exception e){
            expectedExceptionThrown =  e.getMessage().contains(Label.County_Plan_Delete_ErrorMessage) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        List<T_COUNTY_PLAN__c> countyPlan=[Select ID from T_COUNTY_PLAN__c where Id=:aCountyPlan.Id];
        System.assertEquals(1,countyPlan.size(),'Should have one County Plan record');
        T_COUNTY_PLAN__c countyPlanNew = TestClassUtility.createCountyPlan('APV', false);
        countyPlanNew.CDE_COUNTY__c = aCountyPlan.CDE_COUNTY__c;
        countyPlanNew.DTE_BEGIN_EFFEV__c = system.today().addDays(1);
        try{
            insert countyPlanNew;
        }
        catch (Exception e){
            System.debug('There is an exception in Apex class CountyPlanServices_Test and Method testCountyPlanTrigger, Eception :'+e.getMessage());
        }
    }
    
    
    static testMethod void testInsertTasks(){
        createTestData();
        Map<Id,T_COUNTY_PLAN__c> mapFilteredRejectedCountyPlans = new Map<Id,T_COUNTY_PLAN__c>([Select ID from T_COUNTY_PLAN__c where Id=:aCountyPlan.Id]);
        System.assertEquals(false, mapFilteredRejectedCountyPlans.isEmpty(), 'mapFilteredRejectedCountyPlans should not be empty');
        CountyPlanServices.insertTasks(new List<Task>{new Task(WhatId = mapFilteredRejectedCountyPlans.values().get(0).Id)}, mapFilteredRejectedCountyPlans);
    }
    
    static testmethod  void testCountyPlanApprovalProcessRejection(){
        Boolean expectedExceptionThrown;
        createTestData();
        
        Test.startTest();
        createApprover();
        countyPlan.OwnerId = user.Id;
        update countyPlan;
        Test.stopTest();
        System.runAs(countyPlanApprover){
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Submitting request for approval.');
            approvalRequest.setObjectId(countyPlan.Id);
            approvalRequest.setSubmitterId(user.Id);
            approvalRequest.setProcessDefinitionNameOrId(COUNTY_PLAN_APPROVAL_PROCESS);
            approvalRequest.setSkipEntryCriteria(false); 
            
            Approval.ProcessResult result = Approval.process(approvalRequest);
            System.assert(result.isSuccess(),'isSuccess Should be true');
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            
            Approval.ProcessWorkitemRequest workItemRequest = new Approval.ProcessWorkitemRequest();
            workItemRequest.setComments('Rejecting request.');
            workItemRequest.setAction('Reject');
            workItemRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            workItemRequest.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(workItemRequest);       
            System.assert(result.isSuccess(),'isSuccess Should be true');
            List<Task> rejectionTask = [Select Id from Task where WhatId =: countyPlan.id ];
            System.assert(rejectionTask.size()>0,'Task list can not be empty');
            
            T_COUNTY_PLAN__c newCountyPlanDraft = TestClassUtility.createCountyPlan('PEN',false);
            newCountyPlanDraft.CDE_COUNTY__c = aCountNew.Id;
            newCountyPlanDraft.DTE_BEGIN_EFFEV__c = System.today().addMonths(2).toStartOfMonth();
            newCountyPlanDraft.CDE_COUNTY_PLAN_TEMPLT__c = '1';
            newCountyPlanDraft.IND_COUNTY_PLAN_TEMPLT__c = true;
            try{
                insert newCountyPlanDraft;
            }
            catch(Exception e){
                expectedExceptionThrown =  e.getMessage().contains('New County Plan can not be created prior to existing County Plan.') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            
            T_COUNTY_PLAN__c newCountyPlan = TestClassUtility.createCountyPlan('PEN',false);
            newCountyPlan.CDE_COUNTY__c = aCounty.Id;
            newCountyPlan.DTE_BEGIN_EFFEV__c = System.today().addMonths(2).toStartOfMonth();
            newCountyPlan.CDE_COUNTY_PLAN_TEMPLT__c = '1';
            try{
                insert newCountyPlan;
            }
            catch(Exception e){
                expectedExceptionThrown =  e.getMessage().contains('You can not add multiple draft version of County Plan') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            
            aCountyPlan.DTE_BEGIN_EFFEV__c = System.today().addMonths(2).toStartOfMonth();
            try{
                update aCountyPlan;
            }
            catch(Exception e){
                expectedExceptionThrown =  e.getMessage().contains('New County Plan can not be created prior to existing County Plan.') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            try{
                delete aCountyPlan;
            }
            catch(Exception e){
                expectedExceptionThrown =  e.getMessage().contains('New County Plan can not be created prior to existing County Plan.') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
            
            newCountyPlan.CDE_STATUS__c = 'APV';
            try{
                update newCountyPlan;
            }
            catch(Exception e){
                expectedExceptionThrown =  e.getMessage().contains('Id not specified in an update call') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }
        }
    }
    public static testMethod void testSubmitForApproval(){
        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_PLAN__c countyPlan = TestClassUtility.createCountyPlan('PEN', false);
        countyPlan.CDE_COUNTY__c = county.Id;
        insert countyPlan;
        T_COUNTY_PLAN_NOTES__c countyplannotes=new T_COUNTY_PLAN_NOTES__c();
        countyplannotes.IDN_COUNTY_PLAN__c=countyPlan.Id;
        countyplannotes.BODY__c='Testing for Notes';
        countyplannotes.SUBJECT__c='Testing';
        insert countyplannotes;
        List<T_COUNTY_PLAN_NOTES__c> CountyPlanNotestest=[Select Id,Name,IDN_COUNTY_PLAN__c,IDN_COUNTY_PLAN__r.Id from T_COUNTY_PLAN_NOTES__c where IDN_COUNTY_PLAN__r.Id=:countyPlan.Id];
        LightningServerResponse lsr =CountyPlanServices.submitForApproval(countyPlan.Id);
        system.assertEquals(false, lsr.isSuccessful,'lsr.isSuccessful should be false');
        countyPlan.Flow_Completed__c = true;
        update countyPlan;
        LightningServerResponse lsr2 =CountyPlanServices.submitForApproval(countyPlan.Id);
        system.assertEquals(true, lsr2.isSuccessful, 'lsr2.isSuccessful should be true');
        LightningServerResponse lsr3 =CountyPlanServices.submitForApproval(countyPlan.Id);
        system.assertEquals(false, lsr3.isSuccessful, 'lsr3.isSuccessful should be false');
    }
    @future
    public static void createApprover(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        UserRole role= [Select id from UserRole where DeveloperName ='Template_Administrator'];
        countyPlanApprover = TestClassUtility.createUserWithRole(userProfile.Id , 'test1','test2','test2@example.com','test2@example.com.uesername'+ System.currentTimeMillis(),'ttes2',role.Id);
        insert countyPlanApprover; 
    }
}