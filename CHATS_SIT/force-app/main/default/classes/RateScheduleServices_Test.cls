/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           2/7/2018                                                          
*  @description    Test class for Rate Schedule Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 7-Feb-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version 
*********************************************************************************************/
@isTest
private class RateScheduleServices_Test {
    public static final String OPEN = 'OPN';
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    public static final String AUTHORIZED ='2';
    @testSetup static void setup() {
        List<T_CHATS_PROVR_STATUS__c> providerList = new List<T_CHATS_PROVR_STATUS__c>();   
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        for(Integer i=0;i<51;i++) {
            providerList.add(new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c='Level '+i));
            
        }
        
        insert providerList;
    }
    
    static testMethod void updateQualityRatingTest() {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date enddate = begindate.addDays(100);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County2','Dept2',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, county.Id);
        caseRec.Name='Case 123';
        insert caseRec;
        
        T_AUTH__c authorization= TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=caseRec.Id;
        insert authorization;
        
        system.debug([select Id, IDN_PROVR__c ,CDE_COUNTY__c ,IDN_CASE__r.Name ,OwnerId  from T_AUTH__c where Id=:authorization.Id]);
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',System.Today().addDays(-10),county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_END_AGRMT__c=system.today().addDays(30);
        
        
        insert fiscalAgreement;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement2=TestClassUtility.createFiscaAgreement(false,'FA1',System.Today().addYears(40) ,county.Id);
        fiscalAgreement2.RecordtypeId=openRecordTypeId;
        fiscalAgreement2.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement2.ID_SERVICE__c=provider.Id;
        
        
        insert fiscalAgreement2;
        
        T_FISCAL_SCH__c rateSchedule = TestClassUtility.createRateSchedule(true,system.today()-1,null,fiscalAgreement2.Id,'1');
        
        for(T_FISCAL_SCH__c rateScheduleEach:[select Id, TXT_CHATS_RATING__c from T_FISCAL_SCH__c where Id=:rateSchedule.Id]) {
            system.assertEquals(provider.TXT_CHATS_RATING__c,rateScheduleEach.TXT_CHATS_RATING__c,'Quality Rating from Provider is not copied to Quality Rating on T_FISCAL_SCH__c');
        }
        
        //updating Quality Rating 
        provider.TXT_CHATS_RATING__c='Level 3';
        
        update provider;
        
        for(T_FISCAL_SCH__c rateScheduleEach:[select Id, TXT_CHATS_RATING__c from T_FISCAL_SCH__c where Id=:rateSchedule.Id]) {
            system.assert(provider.TXT_CHATS_RATING__c!=rateScheduleEach.TXT_CHATS_RATING__c,'Quality Rating from Provider is copied to Quality Rating on T_FISCAL_SCH__c which it should not');
        }
        
        //testing createTaskforAuthOwner method
        T_FISCAL_SCH__c rateSchedule2 = TestClassUtility.createRateSchedule(true,system.today()+40,null,fiscalAgreement2.Id,'1');
        
        for(Task taskEach:[select Id,Description,WhatId,ActivityDate,Status,Subject from Task Where WhatId=:authorization.Id]) {
            system.assertEquals(taskEach.ActivityDate,system.today().addDays(30),'Due Date should be after nexe 30 days' );
            system.assertEquals(taskEach.Status,'Not Started','Status mismatch');
            system.assertEquals(taskEach.Subject,'T106 - Fiscal Agreement Quality Rating Changed','Subject mismatch');
            
        } 

        T_FISCAL_SCH__c rateSchedule3 = TestClassUtility.createRateSchedule(false,system.today()+10,null,fiscalAgreement2.Id,'1');
        try{
            insert rateSchedule3;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('There is already an existing Rate Schedule with future begin date.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
    }
    
    static testMethod void updateQualityRatingBulkTest() {
        List<T_CHATS_PROVR_STATUS__c> providerList=[Select Id from T_CHATS_PROVR_STATUS__c Limit 210];
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        T_COUNTY__c county= [select Id from T_COUNTY__c where CNTY_DEPT_NAME__c='Dept1' Limit 1];
        List<T_FISCAL_SCH__c> ratesheduleList= new List<T_FISCAL_SCH__c>();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement;
        for(Integer i=0;i<51;i++) {
            fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
            fiscalAgreement = TestClassUtility.createFiscaAgreement(false,'FA'+i,system.today()-10,county.Id);
            fiscalAgreement.RecordtypeId=openRecordTypeId;
            fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
            fiscalAgreement.ID_SERVICE__c=providerList[i].Id;  
            
            fiscalAgreementList.add(fiscalAgreement);                    
        }
        
        insert fiscalAgreementList;
        
        for(Integer i=0;i<1;i++) {
            ratesheduleList.add((T_FISCAL_SCH__c)TestClassUtility.createRateSchedule(false,system.today()+10,null,fiscalAgreementList[i].Id,'1'));
        }
        
        insert ratesheduleList;
               for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement2:[Select Id,ID_SERVICE__r.TXT_CHATS_RATING__c,(select Id,TXT_CHATS_RATING__c from Rate_Schedules__r Limit 1) from T_PROVR_FISCAL_AGREMENT__c Limit 1]) {
                   if(!fiscalAgreement2.Rate_Schedules__r.isEmpty()){
                       system.assertEquals(fiscalAgreement2.ID_SERVICE__r.TXT_CHATS_RATING__c,fiscalAgreement2.Rate_Schedules__r[0].TXT_CHATS_RATING__c,'Quality Rating from Provider is not copied to Quality Rating on T_FISCAL_SCH__c');
                   }
        }
        Integer i=0;
        for(T_CHATS_PROVR_STATUS__c provider:providerList) {
            provider.TXT_CHATS_RATING__c='Level'+i;
            i++; 
        }
        
        update providerList;
             for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement3:[Select Id,ID_SERVICE__r.TXT_CHATS_RATING__c,(select Id,TXT_CHATS_RATING__c from Rate_Schedules__r Limit 1) from T_PROVR_FISCAL_AGREMENT__c Limit 1]) {
                 if(!fiscalAgreement3.Rate_Schedules__r.isEmpty()){
                 system.assert(fiscalAgreement3.ID_SERVICE__r.TXT_CHATS_RATING__c!=fiscalAgreement3.Rate_Schedules__r[0].TXT_CHATS_RATING__c,'Quality Rating from Provider is copied to Quality Rating on T_FISCAL_SCH__c which it should not');
                 }
        }
    } 
    
   
   static testMethod void updateEnddateonFiscalAgreementTest() {
        Date datetoday=System.Today();
        Date nulldate;
        Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        Date enddate = begindate.addDays(20);
        T_COUNTY__c county=TestClassUtility.createCounty('County2','Dept2',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',System.Today()-10,county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        
        
        insert fiscalAgreement;
        
        T_FISCAL_SCH__c rateSchedule = TestClassUtility.createRateSchedule(false,datetoday-10,null,fiscalAgreement.Id,'1');
        rateSchedule.Is_Flow_Completed__c = true;
         Insert rateSchedule;
        T_FISCAL_SCH__c rateScheduleNew = TestClassUtility.createRateSchedule(true,date.newInstance(begindate.year()+1,begindate.month()+1,1),null,fiscalAgreement.Id,'1');
          
        system.assertEquals(rateScheduleNew.DTE_BEGIN_EFFV__c.addDays(-1),[Select DTE_END_EFFV__c from T_FISCAL_SCH__c where Id=:rateSchedule.Id Limit 1].DTE_END_EFFV__c ,'End date is not updated to Begin date of New Rate Schedule');
       
        Delete rateScheduleNew;
        
        system.assertEquals(nulldate ,[Select DTE_END_EFFV__c from T_FISCAL_SCH__c where Id=:rateSchedule.Id Limit 1].DTE_END_EFFV__c ,'End date is not updated to blank for existing Rate Schedule');    
   }
   
   static testmethod void testDeleteRateSchedule() {
        Date datetoday=System.Today();
        Date nulldate;
        Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        Date enddate = begindate.addDays(20);
        T_COUNTY__c county=TestClassUtility.createCounty('County2','Dept2',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',System.Today()-10,county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        
        
        insert fiscalAgreement;
        
        T_FISCAL_SCH__c rateSchedule = TestClassUtility.createRateSchedule(true,datetoday-10,null,fiscalAgreement.Id,'1');
       
       LightningServerResponse lsr= RateScheduleServices.deleteRateSchedule(rateSchedule.Id);
       
       System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
       
        T_FISCAL_SCH__c rateSchedule1 = TestClassUtility.createRateSchedule(true,datetoday-9,null,fiscalAgreement.Id,'1');
        List<Id> rateScheduleIdList = new List<Id>();
        rateScheduleIdList.add(rateSchedule1.Id);
        
        RateScheduleServices.deleteFiscalRateRecord(rateScheduleIdList);
        System.assertEquals(false,rateScheduleIdList.isEmpty(),'rateScheduleIdList should not be empty');	
   }
}