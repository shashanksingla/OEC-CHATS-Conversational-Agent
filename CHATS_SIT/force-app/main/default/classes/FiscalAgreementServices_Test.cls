/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/16/2017                                                          
*  @description    Test class for Fiscal Agreement Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 16-Nov-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest
private class FiscalAgreementServices_Test {
    public static final String FINALIZED= 'FIN';
    public static final String OPEN = 'OPN';
    public static final String NEWFA = 'NEW';
    public static final String CLOSED = 'CLS';
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    public static final String finalizedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
    public static final String closedRecordTypeId= Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
    public static T_PROVR_FISCAL_AGREMENT__c fiscalAgreement;
    public static final string DRAFT='DFT';

    @testSetup static void setup() {
        
        List<T_COUNTY__c> countyList = new List<T_COUNTY__c>();
        List<T_CHATS_PROVR_STATUS__c> providerList = new List<T_CHATS_PROVR_STATUS__c >();
        
        Date datetoday=System.Today();
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today();
        
        for(Integer i=0;i<102;i++) {
            countyList.add((T_COUNTY__c)TestClassUtility.createCounty('County'+i,'Dept1',10,false));
            
        }
        
        insert countyList;
        
        for(Integer i=0;i<102;i++) {
            providerList.add(new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1'));
            
        }
        
        insert providerList;
        
        
    }
    
    static testMethod void testcloseExistingFA() {
        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        Date datetoday=System.Today();
        //Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        //Date enddate = begindate.addDays(20);
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        
        Test.startTest();
        
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c=begindateOpn;
        insert fiscalAgreement;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreementFinalized=TestClassUtility.createFiscaAgreement(false,'FA2',begindateFin,county.Id);
        fiscalAgreementFinalized.RecordtypeId=finalizedRecordTypeId;
        fiscalAgreementFinalized.CDE_TYPE_STATUS__c=FINALIZED;
        fiscalAgreementFinalized.ID_SERVICE__c=provider.Id;   
        
        insert fiscalAgreementFinalized;
        
        fiscalAgreementFinalized.RecordtypeId=openRecordTypeId;
        fiscalAgreementFinalized.CDE_TYPE_STATUS__c=OPEN;
        
        update fiscalAgreementFinalized;
        
        T_PROVR_FISCAL_AGREMENT__c updatedFA =[Select Id,CDE_TYPE_STATUS__c,CDE_REASON_END_AGRMT__c,DTE_END_AGRMT__c,RecordTypeId from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id Limit 1];
        
        system.assertEquals(CLOSED,updatedFA.CDE_TYPE_STATUS__c,'Status is not changed to Closed');
        system.assertEquals(NEWFA,updatedFA.CDE_REASON_END_AGRMT__c,'No Closure Reason');
        system.assertEquals(System.today()-1,updatedFA.DTE_END_AGRMT__c,'Date is not updated to day before begin date of new FA');
        system.assertEquals(Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId(),updatedFA.RecordTypeId,'Not a Closed RecordType');
        
        Test.stopTest();
    }
    
    static testMethod void testcloseExistingFABulk() {
        
        Date datetoday=System.Today();
        //Date begindate = date.newInstance(datetoday.year(),datetoday.month()+1,1);
        //Date enddate = begindate.addDays(20);
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementFinalizedList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        List<T_FISCAL_SCH__c> ratesheduleList= new List<T_FISCAL_SCH__c>();
        
        List<T_COUNTY__c> countyList=[Select Id from T_COUNTY__c where CNTY_DEPT_NAME__c='Dept1' Limit 210];
        List<T_CHATS_PROVR_STATUS__c> providerList=[Select Id from T_CHATS_PROVR_STATUS__c Limit 210];
        
        List<Task> taskList =new List<Task>();
        
        
        Map<string,string> countyProviderMap = new Map<string,string>();
        
        for(Integer i=0;i<102;i++) {
            fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
            fiscalAgreement = TestClassUtility.createFiscaAgreement(false,'FA'+i,begindateOpn,countyList[i].Id);
            fiscalAgreement.RecordtypeId=openRecordTypeId;
            fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
            fiscalAgreement.ID_SERVICE__c=providerList[i].Id;     
            fiscalAgreementList.add(fiscalAgreement);
            countyProviderMap.put(countyList[i].Id,providerList[i].Id);
            fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = begindateOpn;
            
        }
        
        insert fiscalAgreementList;
        
        for(Integer i=0;i<102;i++) {
            
            taskList.add(new Task(Type='Other',Description='testing task'+1,OwnerId=userinfo.getUserId(),WhatId=fiscalAgreementList[i].Id));
        }
        
        insert taskList;
        test.startTest();
        List<Task> notStartedTaskList= [Select Status from Task where WhatId IN:fiscalAgreementList Limit 202];
        
        system.assert(notStartedTaskList.size()>100,'No Task Records');
        
        for(Task t:notStartedTaskList) {
            
            system.assertEquals('Not Started',t.Status,'Task in not in Not Started Staus');
        }
        
        for(Integer i=0;i<1;i++) {
            ratesheduleList.add((T_FISCAL_SCH__c)TestClassUtility.createRateSchedule(false,datetoday+10,null,fiscalAgreementList[i].Id,'1'));
            
        }
        
        insert ratesheduleList;
        Set<Id> rateScheduleIds=new Set<Id>();
        for(T_FISCAL_SCH__c ratesch:ratesheduleList) {
            rateScheduleIds.add(ratesch.Id);
        }
        
        for(Integer i=0;i<102;i++) {
            fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
            fiscalAgreement = TestClassUtility.createFiscaAgreement(false,'FA'+i,begindateFin,countyList[i].Id);
            fiscalAgreement.RecordtypeId=finalizedRecordTypeId;
            fiscalAgreement.CDE_TYPE_STATUS__c=FINALIZED;
            fiscalAgreement.ID_SERVICE__c=countyProviderMap.get(countyList[i].Id);     
            fiscalAgreementFinalizedList.add(fiscalAgreement);
            
            
        }
        
        insert fiscalAgreementFinalizedList;
        
        
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreementFinalized:fiscalAgreementFinalizedList) {
            fiscalAgreementFinalized.RecordtypeId=openRecordTypeId;
            fiscalAgreementFinalized.CDE_TYPE_STATUS__c=OPEN;
            
        }
        
        update fiscalAgreementFinalizedList;
        
        /*for(T_PROVR_FISCAL_AGREMENT__c updatedFA:[Select Id,CDE_TYPE_STATUS__c,CDE_REASON_END_AGRMT__c,DTE_END_AGRMT__c,RecordTypeId from T_PROVR_FISCAL_AGREMENT__c where Id IN:fiscalAgreementList Limit 210]) {
            system.assertEquals(CLOSED,updatedFA.CDE_TYPE_STATUS__c,'Status is not changed to Closed');
            system.assertEquals(NEWFA,updatedFA.CDE_REASON_END_AGRMT__c,'No Closure Reason');
            system.assertEquals(System.today()-1,updatedFA.DTE_END_AGRMT__c,'Date is not updated to day before begin date of new FA');
            system.assertEquals(closedRecordTypeId,updatedFA.RecordTypeId,'Not a Closed RecordType');
            
        }*/
        
        //bulk test to end Rate schedules
        for(T_FISCAL_SCH__c ratesch:[Select Id, DTE_END_EFFV__c from T_FISCAL_SCH__c where Id IN:rateScheduleIds]) {
            system.assertEquals(datetoday,ratesch.DTE_END_EFFV__c,'End Date not updated to today');
            
        }
        
        
        List<Task> cancelledTaskList= [Select Status from Task where WhatId IN:fiscalAgreementList Limit 202];
        
        //system.assert(cancelledTaskList.size()>100,'No Task Records');
        
        for(Task t:cancelledTaskList) {
            
            //system.assertEquals('Cancelled',t.Status,'Task in not in Cancelled Staus');
        }
        test.stopTest();
    }
    static testMethod void testEndRateSchedule() {
        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        Date datetoday=System.Today();
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        Test.startTest();
        
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.RecordtypeId=openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c= begindateOpn-1;
        
        insert fiscalAgreement;
        
        List<T_FISCAL_SCH__c> ratesheduleList= new List<T_FISCAL_SCH__c>();
        ratesheduleList.add((T_FISCAL_SCH__c)TestClassUtility.createRateSchedule(false,datetoday,null,fiscalAgreement.Id,'1'));
        ratesheduleList.add((T_FISCAL_SCH__c)TestClassUtility.createRateSchedule(false,datetoday+10,null,fiscalAgreement.Id,'1'));
        
        insert ratesheduleList;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreementFinalized=TestClassUtility.createFiscaAgreement(false,'FA2',begindateFin,county.Id);
        fiscalAgreementFinalized.RecordtypeId=finalizedRecordTypeId;
        fiscalAgreementFinalized.CDE_TYPE_STATUS__c=FINALIZED;
        fiscalAgreementFinalized.ID_SERVICE__c=provider.Id;   
        fiscalAgreementFinalized.DTE_RCV_AGRMT_FISCAL__c= begindateFin;
        insert fiscalAgreementFinalized;
        
        fiscalAgreementFinalized.RecordtypeId=openRecordTypeId;
        fiscalAgreementFinalized.CDE_TYPE_STATUS__c=OPEN;
        
        update fiscalAgreementFinalized;
        
        T_PROVR_FISCAL_AGREMENT__c updatedFA =[Select Id,CDE_TYPE_STATUS__c,CDE_REASON_END_AGRMT__c,DTE_END_AGRMT__c,RecordTypeId from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id Limit 1];
        T_FISCAL_SCH__c ratesheduleUpdated = [Select Id, DTE_END_EFFV__c, IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c from T_FISCAL_SCH__c where Id=:ratesheduleList[0].Id limit 1];
        try {
            T_FISCAL_SCH__c ratesheduleUpdated2 = [Select Id, DTE_END_EFFV__c from T_FISCAL_SCH__c where Id=:ratesheduleList[1].Id limit 1];
            
        }
        catch(Exception ex) {
            system.assert((string.valueof(ex.getMessage())).contains('List has no rows for assignment to SObject'),'Rate Schedule is not deleted');
        }

        //system.assertEquals(datetoday,ratesheduleUpdated.DTE_END_EFFV__c,'End Date not updated to today');

        //system.assertEquals(ratesheduleUpdated.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c ,ratesheduleUpdated.DTE_END_EFFV__c,'End Date not updated to today');

        
        system.assertEquals(CLOSED,updatedFA.CDE_TYPE_STATUS__c,'Status is not changed to Closed');
        system.assertEquals(NEWFA,updatedFA.CDE_REASON_END_AGRMT__c,'No Closure Reason');
        system.assertEquals(System.today()-1,updatedFA.DTE_END_AGRMT__c,'Date is not updated to day before begin date of new FA');
        system.assertEquals(Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId(),updatedFA.RecordTypeId,'Not a Closed RecordType');
        
        Test.stopTest();
    }
    

    /*static testMethod void testUpdateEnddateonFA() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_TYPE_PROVR__c='EFACH');
        insert provider;
        
        Date datetoday=System.Today();
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        Test.startTest();
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        insert fiscalAgreement;
        
        // Below changes added as part of Change request CHATS-6801
        //system.assertEquals(begindateOpn.addYears(1),[Select DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id].DTE_END_AGRMT__c ,'End Date not updated as expected');
        Date dteBeginDate = begindateOpn.addYears(1).addmonths(-1);
        system.assertEquals(Date.newInstance(dteBeginDate.year(), dteBeginDate.month(), Date.daysInMonth(dteBeginDate.year(), dteBeginDate.month())),[Select DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id].DTE_END_AGRMT__c ,'End Date not updated as expected');
        
        //updting CDE_TYPE_PROVR__c on T_CHATS_PROVR_STATUS__c which should update enddate on FA
        provider.CDE_TYPE_PROVR__c='PRS';
        update provider;
        
        //system.assertEquals(begindateOpn.addYears(3),[Select DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id].DTE_END_AGRMT__c ,'End Date not updated as expected');
        // Below changes added as part of Change request CHATS-7209
        begindateOpn = begindateOpn.addYears(3).addmonths(-1);
        begindateOpn = Date.newInstance(begindateOpn.year(), begindateOpn.month(), Date.daysInMonth(begindateOpn.year(), begindateOpn.month()));
        system.assertEquals(begindateOpn,[Select DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where Id=:fiscalAgreement.Id].DTE_END_AGRMT__c ,'End Date not updated as expected');
        
        
        Test.stopTest();
        
    }*/
    
    static testMethod void validateExistingFiscalAgreementTest() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY__c county1=TestClassUtility.createCounty('County2','Dept2',10,true);
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_TYPE_PROVR__c='EFACH');
        insert provider;
        
        Date datetoday=System.Today();
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        Test.startTest();
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.CDE_TYPE_STATUS__c='DFT';
        insert fiscalAgreement;
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement1=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement1.ID_SERVICE__c=provider.Id;
        fiscalAgreement1.CDE_TYPE_STATUS__c=FINALIZED;
        try{
            insert fiscalAgreement1;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.NEW_PROVR_FISCAL_AGREEMENT_ERROR) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement2=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county1.Id);
        fiscalAgreement2.ID_SERVICE__c=provider.Id;
        //fiscalAgreement2.CDE_TYPE_STATUS__c=FINALIZED;
        insert fiscalAgreement2;
        try{
            fiscalAgreement2.CDE_COUNTY__c = county.Id;
            update fiscalAgreement2;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(Label.UPDATE_PROVR_FISCAL_AGREEMENT_ERROR) ? true : false;
            //   System.AssertEquals(expectedExceptionThrown, true);
        }
        
        Test.stopTest();
        
    }
    
    
    static testMethod void beforeDeleteCheckFiscalAgreementTypeTest() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_TYPE_PROVR__c='EFACH');
        insert provider;
        
        Date datetoday=System.Today();
        
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        Test.startTest();
        
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.CDE_TYPE_STATUS__c='DFT';
        insert fiscalAgreement;
        
        try{
            delete fiscalAgreement;
            
        }catch(Exception ex) {
            system.assert(string.valueOf(ex.getMessage()).contains('Fiscal Agreement is not in Draft or Finalized Status so cannot be deleted'));
            
        }
    }
    
    static testMethod void testdeleteFARecord() {
        T_COUNTY__c county = TestClassUtility.createCounty('Test County', 'Test Dept', 1 , true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'FA-0001', System.today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        Test.startTest();
        FiscalAgreementServices.deleteFARecord(fiscalAgreement.Id);
        Test.stopTest();
        }
    
    /*
    public static testMethod void testInsertATSRecords(){
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_TYPE_PROVR__c='EFACH');
        insert provider;
        
        Date begindateOpn=System.Today()-10;
        Test.startTest();
        List<T_PROVR_FISCAL_AGREMENT__c> lstFiscalAgreementRecords =new List<T_PROVR_FISCAL_AGREMENT__c>();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement=TestClassUtility.createFiscaAgreement(false,'FA1',begindateOpn,county.Id);
        fiscalAgreement.ID_SERVICE__c=provider.Id;
        fiscalAgreement.CDE_TYPE_STATUS__c='OPN';
        lstFiscalAgreementRecords.add(fiscalAgreement);
        Integer intCount = 0;
        
        for(AggregateResult result :[SELECT COUNT(Id) intVal FROM T_POS_TRANS_QUEUE_ATS__c])
        {
            intCount+=(Integer)result.get('intVal');
        }
        
        System.debug('No of records are: '+intCount);
        FiscalAgreementServices.insertATSRecord(lstFiscalAgreementRecords);
        Integer afterCount = 0;
        
        for(AggregateResult result :[SELECT COUNT(Id) intVal FROM T_POS_TRANS_QUEUE_ATS__c])
        {
            afterCount+=(Integer)result.get('intVal');
        }
        System.debug('No of records after are: '+afterCount);
        system.assertEquals(afterCount, intCount+1);
    } */
}