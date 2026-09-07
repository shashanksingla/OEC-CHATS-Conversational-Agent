/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/07/2017                                                          
*  @description    Test class for county rate plan trigger                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Sept-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/


@isTest(seeAllData=false)
public class CountyRatePlanServices_Test {
    
    static final String CENTER='CEN';
    static final String FT = '3'; 
    static final String PT = '2'; 
    static final String FTPT = '4';
    static final String FTFT = '5'; 
    public static User user;
    public static final String COUNTY_RATE_PLAN_APPROVAL_PROCESS = 'County_Rate_Plan_Approval_Process';
    public static T_COUNTY__c aCounty;
    public static T_COUNTY_RATE__c aCountyRateForApprovalProcess;
    public static T_COUNTY_RATE__c aCountyRatePlan=null; 
    public static T_COUNTY_RATE__c aCountyRatePlan1=null; 
    public static T_COUNTY_RATE__c aCountyRatePlan2=null; 
    
    static void createTestData(){
        aCounty = TestClassUtility.createCounty('County','Dept',10,true);
        T_COUNTY__c county1 = TestClassUtility.createCounty('County11','Dept11',10,true);
        aCountyRatePlan = TestClassUtility.createCountyRatePlan('PEN',false);
        aCountyRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        aCountyRatePlan.IND_RATE_PLAN_TEMPLT__c = true;
        aCountyRatePlan.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(3).toStartOfMonth();
        aCountyRatePlan.IDN_COUNTY__c = county1.id;
        
        aCountyRatePlan1 = TestClassUtility.createCountyRatePlan('PEN',false);
        aCountyRatePlan1.CDE_RATE_PLAN_TEMPLT__c = '1';
        aCountyRatePlan1.IND_RATE_PLAN_TEMPLT__c = false;
        aCountyRatePlan1.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(4).toStartOfMonth();
        aCountyRatePlan1.IDN_COUNTY__c = county1.id;
        
        aCountyRateForApprovalProcess = TestClassUtility.createCountyRatePlan('PEN',false);
        aCountyRateForApprovalProcess.IDN_COUNTY__c = aCounty.Id;
        aCountyRateForApprovalProcess.CDE_RATE_PLAN_TEMPLT__c = '1';
        aCountyRateForApprovalProcess.IND_RATE_PLAN_TEMPLT__c = false;
        aCountyRateForApprovalProcess.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(2).toStartOfMonth();
        aCountyRateForApprovalProcess.Flow_Completed__c = true;
        
        if(aCountyRateForApprovalProcess != null){
            insert aCountyRateForApprovalProcess;
        }
        
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.uesername','ttes');
        
        if(user != null){
            List<User> users = [SELECT Owner_County__c FROM User WHERE id = :UserInfo.getUserId()];
            if(!users.isEmpty()){
                user.Owner_County__c  = users.get(0).Owner_County__c;
            }
            insert user; 
        }
        
        Date dt = System.today().addMonths(4);
        Integer year = dt.year();
        List<T_YEAR_HOL__c> holidayList = new List<T_YEAR_HOL__c>();
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt, CDE_HOL__c = '1', CDE_YEAR__c = year));
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt.addDays(1), CDE_HOL__c = '2', CDE_YEAR__c = year));
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt.addDays(2), CDE_HOL__c = '3', CDE_YEAR__c = year));
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt.addDays(3), CDE_HOL__c = '4', CDE_YEAR__c = year));
        insert holidayList;
        
        T_CHATS_PROVR_STATUS__c prvder = TestClassUtility.createProvider(true, 'Level 2');
        T_PROVR_FISCAL_AGREMENT__c fa = TestClassUtility.createFiscaAgreement(false, 'Test', date.today(), county1.Id);
        fa.ID_SERVICE__c = prvder.Id;
        fa.DTE_END_AGRMT__c = date.today().addYears(1);
        fa.CDE_TYPE_STATUS__c = 'FIN';
        fa.RecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        insert fa;
        
        T_AUTH__c auth = TestClassUtility.createAuthorization(true, system.today().addMonths(6), system.today(), county1.id, prvder.id);
        T_AUTH_ENCUMBR__c authEncumb = new T_AUTH_ENCUMBR__c();
        authEncumb.cde_status_encmbr__c = '2';
        authEncumb.cnt_hour_care__c = 4;
        authEncumb.dte_care__c = dt;
        authEncumb.IDN_AUTH__c = auth.Id;
        authEncumb.ind_0_36_months__c = 'N';
        insert authEncumb;
            
        T_PROVR_CLOSURE__c pc = new T_PROVR_CLOSURE__c();
        pc.CDE_COUNTY__c = county1.Id;
        pc.IDN_PROVIDER__c = prvder.Id;
        pc.IND_ACTIVE__c = true;
        pc.DTE_BEGIN_CLOSURE__c = dt;
        insert pc;
    }
    
    static testmethod void testCountyRatePlanTrigger(){
        Boolean expectedExceptionThrown;
        createTestData();
        
        Test.startTest();
         User tempAdmin = [SELECT Id from User where UserRole.Name = 'Template Administrator' and IsActive = true limit 1];
        system.runAs(tempAdmin){
            aCountyRatePlan.PAYMENT_Q13_1__c = '2;3;4;';
            insert aCountyRatePlan;
            aCountyRatePlan.PAYMENT_Q13_1__c = '1;2;3;';      
            update aCountyRatePlan;
       }
        
        user u = [Select id from User where UserName='newuserchats@testorg.com'];
        system.debug('user'+u);
        system.runAs(u){
            insert aCountyRatePlan1;
        }
        aCountyRatePlan1.RATE_TYPE__c = '13';
        update aCountyRatePlan1;
        aCountyRatePlan1.RATE_TYPE__c = '1';
        update aCountyRatePlan1;
        aCountyRatePlan1.PAYMENT_Q13_1__c = '1;2;3;';
        aCountyRatePlan1.CDE_STATUS__c = CountyRatePlanServices.APPROVED;
        system.runAs(tempAdmin){
            try{
                update aCountyRatePlan1;
            }
            catch(Exception e){
                expectedExceptionThrown = e.getMessage().contains('Template already exists with Indicator checked') ? true : false;
                System.AssertEquals(expectedExceptionThrown, false);
            }  
        }
        Test.stopTest(); 
    }
    
    /*
    static testmethod  void testCountyRatePlanAfterInsertTrigger(){
        Test.startTest();
        
        createTestData();
        try{
            insert aCountyRatePlan;
        }catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('You can not add multiple draft version of County Rate Plan') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        T_COUNTY_RATE__c countyRatePlan=[Select Id,CDE_RATE_PLAN_TEMPLT__c,IND_RATE_PLAN_TEMPLT__c,(Select id from County_Rate__r ) from T_COUNTY_RATE__c where id=:aCountyRatePlan.id];
        System.assertNotEquals(countyRatePlan.id, null);
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmount=[Select id from T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c =:countyRatePlan.id];  
        System.assertEquals(countyRatePlan.IND_RATE_PLAN_TEMPLT__c, false);
        //System.assertNotEquals(lstCountyRateAmount.size(),0);
        Test.stopTest(); 
    }
	*/
    static testmethod  void testCountyRatePlanAfterUpdateForTaskCreation(){
        createTestData();
        aCountyRateForApprovalProcess.OwnerId = user.Id;
        update aCountyRateForApprovalProcess;
        Test.startTest();
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(aCountyRateForApprovalProcess.Id);
        approvalRequest.setSubmitterId(user.Id);
        approvalRequest.setProcessDefinitionNameOrId(COUNTY_RATE_PLAN_APPROVAL_PROCESS);
        approvalRequest.setSkipEntryCriteria(false); 
        
        Approval.ProcessResult result = Approval.process(approvalRequest);
        System.assert(result.isSuccess(),'isSuccess should be true');
        
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        
        Approval.ProcessWorkitemRequest workItemRequest = new Approval.ProcessWorkitemRequest();
        workItemRequest.setComments('Rejecting request.');
        workItemRequest.setAction('Reject');
        workItemRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        workItemRequest.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 =  Approval.process(workItemRequest);    
        System.assert(result.isSuccess(),'isSuccess Should be true');   
        
        List<Task> rejectionTask = [Select Id from Task where WhatId =: aCountyRateForApprovalProcess.id ];
        System.assert(rejectionTask.size()>0,'Task list should return task records');
        
        T_COUNTY_RATE__c newCountyRatePlan = TestClassUtility.createCountyRatePlan('PEN',false);
        newCountyRatePlan.IDN_COUNTY__c = aCounty.Id;
        newCountyRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        newCountyRatePlan.IND_RATE_PLAN_TEMPLT__c=false;
        newCountyRatePlan.DTE_BEGIN_EFFV_RATE__c=System.today().addMonths(2).toStartOfMonth();
        try{
            insert newCountyRatePlan;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('New County Rate Plan can not be created prior to existing County Rate Plan.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }
    
    @TestSetup
    public static void testDataSetup(){
        
        CHATSUtility.createTemplateUser();
        T_COUNTY__c aCounty = TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);
        T_COUNTY_RATE__c aCountyRate = TestClassUtility.createCountyRatePlan(CountyRatePlanServices.DRAFT, false);
        aCountyRate.IDN_COUNTY__c = aCounty.Id;
        aCountyRate.CDE_RATE_PLAN_TEMPLT__c = '1';
        aCountyRate.IND_RATE_PLAN_TEMPLT__c = false;
        aCountyRate.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth();       
        insert aCountyRate;
        
        aCountyRate.CDE_STATUS__c = CountyRatePlanServices.APPROVED;
        update aCountyRate;
        
        T_COUNTY_RATE_AMT__c aCountyRateAmount1=new  T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 123,
            CDE_UNIT__c = FT,
            IDN_COUNTY_RATE__c = aCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='4'
            
        );
        
        T_COUNTY_RATE_AMT__c aCountyRateAmount2=new  T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 125,
            CDE_UNIT__c = FT,
            IDN_COUNTY_RATE__c = aCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='4'
            
        );
        List<T_COUNTY_RATE_AMT__c> lstCountyRates=new List<T_COUNTY_RATE_AMT__c>{aCountyRateAmount1,aCountyRateAmount2};
            insert lstCountyRates ;
    }
    /*
    public static testMethod void testInsertATSRecords(){
        TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_TYPE_PROVR__c='EFACH');
        insert provider;
        
        //Removed unused variable on 5/13/2018 BG  
        Test.startTest();
        List<T_COUNTY_RATE__c> lstCountyRatePlanRecords =new List<T_COUNTY_RATE__c>();
        T_COUNTY_RATE__c countyRatePlan = TestClassUtility.createCountyRatePlan('APV', true);
        lstCountyRatePlanRecords.add(countyRatePlan);
        Integer intCount = 0;
        
        for(AggregateResult result :[SELECT COUNT(Id) intVal FROM T_POS_TRANS_QUEUE_ATS__c ])
        {
            intCount+=(Integer)result.get('intVal');
        }
        
        System.debug('No of records are: '+intCount);
        CountyRatePlanServices.insertATSRecord(lstCountyRatePlanRecords);
        Integer afterCount = 0;
        
        for(AggregateResult result :[SELECT COUNT(Id) intVal FROM T_POS_TRANS_QUEUE_ATS__c ])
        {
            afterCount+=(Integer)result.get('intVal');
        }
        System.debug('No of records after are: '+afterCount);
        system.assertEquals(afterCount, intCount+1,'Count should match');
    }
    */
    public static testMethod void testSubmitForApproval(){
       T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_RATE__c countyRatePlan = TestClassUtility.createCountyRatePlan('PEN', false);
        countyRatePlan.IDN_COUNTY__c = county.Id;
        insert countyRatePlan;
        T_COUNTY_RATE_NOTES__c notes=new T_COUNTY_RATE_NOTES__c();
        notes.IDN_COUNTY_RATE__c=countyRatePlan.Id;
        notes.SUBJECT__c='Testing the notes';
        notes.BODY__c='testing';
        insert notes;
        List<T_COUNTY_RATE_NOTES__c> CountyRatePlanNotestest=[Select Id,Name,IDN_COUNTY_RATE__c,IDN_COUNTY_RATE__r.Id from T_COUNTY_RATE_NOTES__c where IDN_COUNTY_RATE__r.Id=:countyRatePlan.Id];
        system.debug(CountyRatePlanNotestest.size());
        LightningServerResponse lsr =CountyRatePlanServices.submitForApproval(countyRatePlan.Id);
        system.assertEquals(false, lsr.isSuccessful,'lsr.isSuccessful should be false');
        countyRatePlan.Flow_Completed__c = true;
        update countyRatePlan;
        LightningServerResponse lsr2 =CountyRatePlanServices.submitForApproval(countyRatePlan.Id);
        system.assertEquals(true, lsr2.isSuccessful, 'lsr2.isSuccessful should be true');
        LightningServerResponse lsr3 =CountyRatePlanServices.submitForApproval(countyRatePlan.Id);
        system.assertEquals(false, lsr3.isSuccessful, 'You Cannot Submit Approval Again');
    }
    
    public static testMethod void testCreateCountyRateAmountRecords(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Dept', 1, true);
        T_COUNTY_RATE__c countyRatePlan = TestClassUtility.createCountyRatePlan('PEN', true);
        countyRatePlan.IDN_COUNTY__c = county.Id;
        countyRatePlan.DTE_BEGIN_EFFV_RATE__c= system.today().addMonths(1).toStartOfMonth() ;
        countyRatePlan.DTE_END_EFFV_RATE__c = system.today().addMonths(2).toStartOfMonth().addDays(-1) ;
        countyRatePlan.CDE_STATUS__c = 'APV';
        countyRatePlan.CDE_RATE_PLAN_TEMPLT__c= '1';
        countyRatePlan.IND_RATE_PLAN_TEMPLT__c= true;
        countyRatePlan.RATE_TYPE__c = '1';
        user u =[Select id from User where UserName='newuserchats@testorg.com'];

        system.runAs(u){
            update countyRatePlan;} 
        countyRatePlan.RATE_TYPE__c = '13;19;'; 
        system.runAs(u){
            update countyRatePlan;
        }
        T_COUNTY_RATE__c countyRatePlan2 = TestClassUtility.createCountyRatePlan('PEN', false);
        countyRatePlan2.IDN_COUNTY__c = county.Id;
        countyRatePlan2.CDE_RATE_PLAN_TEMPLT__c= '1';
        countyRatePlan2.DTE_BEGIN_EFFV_RATE__c= system.today().addMonths(2).toStartOfMonth() ;
        insert countyRatePlan2;
        countyRatePlan2.IND_RATE_PLAN_TEMPLT__c= false;
        countyRatePlan2.RATE_TYPE__c = '1';
        update countyRatePlan2;
        countyRatePlan2.RATE_TYPE__c = '13';
        update countyRatePlan2;
        countyRatePlan2.IND_RATE_PLAN_TEMPLT__c= true;
        try{
            update countyRatePlan2; 
        }
        Catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Template already exists for County') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true); 
        }
        T_COUNTY_RATE__c countyRatePlan3 = TestClassUtility.createCountyRatePlan('PEN', false);
        countyRatePlan3.IDN_COUNTY__c = county.Id;
        countyRatePlan3.CDE_RATE_PLAN_TEMPLT__c= '1';
        countyRatePlan3.DTE_BEGIN_EFFV_RATE__c= system.today().addMonths(1).toStartOfMonth() ;
        try{
            insert countyRatePlan3;}
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Template already exists for County') ? true : false;
            System.AssertEquals(expectedExceptionThrown, false);
        }
    }
    
    public static testMethod void testValidateBeforeDelete(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Dept', 1, true);
        T_COUNTY_RATE__c countyRatePlan = TestClassUtility.createCountyRatePlan('PEN', true);
        countyRatePlan.IDN_COUNTY__c = county.Id;
        countyRatePlan.DTE_BEGIN_EFFV_RATE__c= system.today().addMonths(1).toStartOfMonth() ;
        countyRatePlan.DTE_END_EFFV_RATE__c = system.today().addMonths(2).toStartOfMonth().addDays(-1) ;
        countyRatePlan.CDE_STATUS__c = 'APV';
        countyRatePlan.CDE_RATE_PLAN_TEMPLT__c= '1';
        countyRatePlan.IND_RATE_PLAN_TEMPLT__c= true;
        countyRatePlan.RATE_TYPE__c = '1';
        List<T_COUNTY_RATE__c> lstCountyRatePlan = new List<T_COUNTY_RATE__c>();
        lstCountyRatePlan.add(countyRatePlan);
        try{
            CountyRatePlanServices.validateBeforeDelete(lstCountyRatePlan);
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.County_Rate_Plan_Delete_ErrorMessage) ? true : false;
            System.AssertEquals(expectedExceptionThrown, false);
        }
    }
}