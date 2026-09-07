/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/15/2017                                                          
*  @description    Test class for CustomLightningActionApxCtrl                          
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 15-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest
private class CustomLightningActionApxCtrl_Test {
    public static final String OPEN = 'OPN';
    public static final String FINALIZED = 'FIN';
    public static final String CLOSED = 'CLS';
    public static final String DRAFT = 'DFT';
    static testMethod void testFinalizeFiscalAgreementScenario1() {
        
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();  
        Date systDate = System.Today();
        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        Test.startTest();
        
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',systDate-10,county.Id);
        
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c= systDate-11;
        insert fiscalAgreement;
        
        CustomLightningActionApxCtrl.finalizeFiscalAgreement(fiscalAgreement.Id);
        
        T_PROVR_FISCAL_AGREMENT__c updatedFiscalAgreement =[Select Id,CDE_TYPE_STATUS__c,RecordtypeId from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id Limit 1];
        
        system.assertEquals(openRecordTypeId,updatedFiscalAgreement.RecordtypeId,'Recordtype is not updated to Open');
        
        system.assertEquals(OPEN,updatedFiscalAgreement.CDE_TYPE_STATUS__c,'Status not updated to Open');
        
        Test.stopTest();
    }
    
    static testMethod void testFinalizeFiscalAgreementScenario2() {
          Id finalizedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();  
        
        Date systDate = System.Today();
        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        Test.startTest();
        
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',systDate+10,county.Id);
        
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c= systDate+9;
        insert fiscalAgreement;
        
        CustomLightningActionApxCtrl.finalizeFiscalAgreement(fiscalAgreement.Id);
        
        T_PROVR_FISCAL_AGREMENT__c updatedFiscalAgreement =[Select Id,CDE_TYPE_STATUS__c,RecordtypeId from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id Limit 1];
        
        system.assertEquals(finalizedRecordTypeId,updatedFiscalAgreement.RecordtypeId,'Recordtype is not updated to Finalized');
        
        system.assertEquals(FINALIZED ,updatedFiscalAgreement.CDE_TYPE_STATUS__c,'Status not updated to Finalized');
        
        //negative scenario
        LightningServerResponse lightserresobj2= CustomLightningActionApxCtrl.finalizeFiscalAgreement(null);
        
        system.assert(string.valueOf(lightserresobj2).contains(Label.Not_finalized),'Failing with different error');
        
        Test.stopTest();
        
    }
    
    
    static testMethod void testcloseFiscalAgreementUpdate() {
        Id closedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();  
        Date systDate = System.Today();
       
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        Test.startTest();
        
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',systDate-10,county.Id);
        fiscalAgreement.CDE_REASON_END_AGRMT__c='NEW';
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        
        insert fiscalAgreement;
        
        CustomLightningActionApxCtrl.closeFiscalAgreement(fiscalAgreement.Id);
        
        T_PROVR_FISCAL_AGREMENT__c updatedFiscalAgreement =[Select Id,CDE_TYPE_STATUS__c,RecordtypeId from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id Limit 1];
        
        system.assertEquals(closedRecordTypeId,updatedFiscalAgreement.RecordtypeId,'Recordtype is not updated to Close');
        
        system.assertEquals(CLOSED,updatedFiscalAgreement.CDE_TYPE_STATUS__c,'Status not updated to Closed');
        
        //negative scenario
        LightningServerResponse lightserresobj2= CustomLightningActionApxCtrl.closeFiscalAgreement(null);
        
        system.assert((string.valueOf(lightserresobj2)).contains(Label.FA_cannot_be_closed_without_reason),'Failing with different error');
        
        Test.stopTest();
    }
    
    public static testMethod void testNewPaymentPlan(){
        TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_STATUS_PROVR__c='OPEN');
        LightningServerResponse lsr = CustomLightningActionApxCtrl.newPaymentPlan(provider.Id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('redirect'), 'lsr.objectData should contain "redirect" as key.');
        System.assertEquals(true, lsr.objectData.containsKey('eventParams'), 'lsr.objectData should contain "eventParams" as key');
    }
    
    public static testMethod void testConfirmPopupForProcessApplication(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserWithPS(userProfile.Id ,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            TestClassUtility.createCounty('Denver','Denver',1,true);
            T_APPLN_CASE__c appCase = new T_APPLN_CASE__c();
            insert appCase;
            T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
                IDN_APPLN__c = appCase.Id,
                CDE_SOURCE__c = 'PK',
                DTE_RCVD_APPLN__c = System.today().addDays(-15),
                CDE_COUNTY__c = '1'
            );
            insert appProcessQueue;
            
            LightningServerResponse lsr =  CustomLightningActionApxCtrl.confirmPopupForProcessApplication(appProcessQueue.Id);
            System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should be true');            
            appProcessQueue.CDE_COUNTY__c = '2';
            appProcessQueue.County_Transfer_Notes__c ='County Update Transfer Notes'; 
            update appProcessQueue; 
            
            lsr =  CustomLightningActionApxCtrl.confirmPopupForProcessApplication(appProcessQueue.Id);
            System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should be false');                        
            delete appProcessQueue;

            lsr =  CustomLightningActionApxCtrl.confirmPopupForProcessApplication(appProcessQueue.Id);
            System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should be false');
        }        
    }
    
    static testMethod void testNewFiscalAgreement() {
        Id closedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();  
        TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_STATUS_PROVR__c='OPEN');
        insert provider;
        
        Test.startTest();
        LightningServerResponse lightserresobj= CustomLightningActionApxCtrl.newFiscalAgreement(provider.Id);
        system.assertEquals(true,lightserresobj.isSuccessful,'Can not proceed to New Fiscal Agreement Page');
        Test.stopTest();
    }
    
      static testMethod void testfinalizeSlotContractAddendum() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test Dept', 1 , true);  
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'FA-0001', System.today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        T_SLOT_CONTRACT_ADDENDUM__c SCaddRec=new T_SLOT_CONTRACT_ADDENDUM__c();
        SCaddRec.CDE_COUNTY__c=county.Id;
        SCaddRec.CDE_STATUS__c='DFT';
        SCaddRec.CNT_SLOT_CONTRACTS__c=2.0;
        SCaddRec.DTE_BEGIN_ADDENDUM__c=system.today().addDays(-5);
        SCaddRec.DTE_END_ADDENDUM__c=system.today().addDays(6);
        SCaddRec.IDN_FISCAL_AGREEMENT__c= fiscalAgreement.Id;
        insert SCaddRec;
        
        
        Test.startTest();
        LightningServerResponse lightserresobj= CustomLightningActionApxCtrl.finalizeSlotContractAddendum(SCaddRec.Id);
        system.assertEquals(true,lightserresobj.isSuccessful,'lightserresobj.isSuccessful should be true');
        Test.stopTest();
    }
    
    static testMethod void testDeleteRateSchedule() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test Dept', 1 , true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'FA-0001', System.today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        T_FISCAL_SCH__c rateschedule = TestClassUtility.createRateSchedule(false, System.today(), System.today().addDays(30), fiscalAgreement.Id, '1');
        rateschedule.Is_Flow_Completed__c = false;
        insert rateschedule;
        Test.startTest();
        LightningServerResponse lsr=CustomLightningActionApxCtrl.deleteRateSchedule(rateschedule.Id);
        System.assertEquals(true, lsr.isSuccessful , 'isSuccessful Should be true');
        Test.stopTest();
        }
    static testMethod void testDeleteParentFee() {
    	T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        
        T_SBSD_Case__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.IDN_EXTNL__c = '123456';
        upsert caseRec;
        
        batchsit_t_sbsd_case_copay__x caseCopayRec = new batchsit_t_sbsd_case_copay__x(ExternalId='11',amt_copay_case_assesd__c=10,cde_rec_copay__c='3',dte_begin_effv__c=Date.valueOf('2012-12-12'),amt_copay_case_ft__c=1,amt_copay_case_ft_qlty__c=1,amt_copay_case_pt__c=1,amt_copay_case_pt_qlty__c=1,cde_reason_ovrd__c='R',createddate__c=Date.valueOf('2010-08-24'),dte_end_effv__c=Date.valueOf('2018-04-30'),idn_sbsd_case_copay__c=11,ind_qlty__c='Y',lastmodifieddate__c=Date.valueOf('2018-03-06'),nbr_seq_hist__c=1, idn_case__c=caseRec.IDN_EXTNL__c);
        Database.insertAsync(caseCopayRec);
        test.startTest();
        LightningServerResponse lsr=CustomLightningActionApxCtrl.deleteCaseParentFee(caseCopayRec.Id);
        System.assertEquals(true, lsr.isSuccessful , 'isSuccessful Should be true');
        Test.stopTest();
    }
    static testMethod void testSubmitForApprovalCountyPlan() {
    	T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_County_Plan__c countyPlan = TestClassUtility.createCountyPlan('PEN', true);
        T_COUNTY_PLAN_NOTES__c countyplannotes=new T_COUNTY_PLAN_NOTES__c();
        countyplannotes.IDN_COUNTY_PLAN__c=countyPlan.Id;
        countyplannotes.BODY__c='Testing for Notes';
        countyplannotes.SUBJECT__c='Testing';
        insert countyplannotes;
        
        test.startTest();
        LightningServerResponse lsr=CustomLightningActionApxCtrl.submitForApprovalCountyPlan(countyPlan.Id);
        System.assertEquals(false, lsr.isSuccessful , 'isSuccessful Should be false');
        countyPlan.Flow_Completed__c = true;
        update countyPlan;
        LightningServerResponse lsr2=CustomLightningActionApxCtrl.submitForApprovalCountyPlan(countyPlan.Id);
        System.assertEquals(true, lsr2.isSuccessful , 'isSuccessful Should be true');
    }
    static testMethod void testSubmitForApprovalCountyRatePlan() {
    	T_County__c countyRec = TestClassUtility.createCounty('Denver', 'Test', 1, true);
        T_County_Rate__c countyRatePlan = TestClassUtility.createCountyRatePlan('PEN', true);
        T_COUNTY_RATE_NOTES__c notes=new T_COUNTY_RATE_NOTES__c();
        notes.IDN_COUNTY_RATE__c=countyRatePlan.Id;
        notes.SUBJECT__c='Testing the notes';
        notes.BODY__c='testing';
        insert notes;
        test.startTest();
        LightningServerResponse lsr=CustomLightningActionApxCtrl.submitForApprovalCountyRatePlan(countyRatePlan.Id);
        System.assertEquals(false, lsr.isSuccessful , 'isSuccessful Should be false');
        countyRatePlan.Flow_Completed__c = true;
        update countyRatePlan;
        LightningServerResponse lsr2=CustomLightningActionApxCtrl.submitForApprovalCountyRatePlan(countyRatePlan.Id);
        System.assertEquals(true, lsr2.isSuccessful , 'isSuccessful Should be true');
    }
    

    
        
        static testMethod void testDeleteFA() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test Dept', 1 , true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'FA-0001', System.today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        Test.startTest();
        LightningServerResponse lsr=CustomLightningActionApxCtrl.deleteFA(fiscalAgreement.Id);
        System.assertEquals(true, lsr.isSuccessful , 'isSuccessful Should be true');
        Test.stopTest();
    }
        }