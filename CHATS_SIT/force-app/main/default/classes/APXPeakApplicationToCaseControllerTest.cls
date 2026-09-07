/*
* 
* Change Log
* Changeing Variable  Name from tempAppProcessQueue to tmpAppPrcsQueue
*
* 
* */
@isTest
public class APXPeakApplicationToCaseControllerTest {
    public final static String EMPTY_LOOKUP = null;
    
    public static testMethod void testGetNextBusinessDayForHoliday(){
        System.assertEquals(true,ConvertPeakDataToCHATS.getNextBusinessDay(System.today(), new set<Date>{System.today()})!=null,'It should be a date');
    }
    
    public static testMethod void testCheckIfAppHasPrimaryCaretaker(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(true,System.today().addYears(-15), 'Art', '1', 'Vandaley','12345',appProcessQueue.get(0).IDN_APPLN__c);
            
            LightningServerResponse lsr = APXPeakApplicationToCaseController.checkIfAppHasPrimaryCaretaker(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.containsKey('hasPrimaryCaretaker'), 'objectData should contain hasPrimaryCaretaker as a key');
            System.assertEquals(false, lsr.objectData.get('hasPrimaryCaretaker'), 'hasPrimaryCaretaker should be false');
            
            appIndiv.IND_CRTKR_PRIM__c = 'Y';
            update appIndiv;
            lsr = APXPeakApplicationToCaseController.checkIfAppHasPrimaryCaretaker(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.get('hasPrimaryCaretaker'), 'hasPrimaryCaretaker should be true');            
            
            delete appProcessQueue;
            lsr = APXPeakApplicationToCaseController.checkIfAppHasPrimaryCaretaker(appProcessQueue.get(0).Id);
            System.assertEquals(false, lsr.isSuccessful, 'isSuccessful should be be true');            
            
        }
    }    
    
    
    public static testMethod void testCheckCountyMatch(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test', null, 2, true); 
        User user;
        Profile userProfile=[Select id from Profile where Name ='Eligibility Worker'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            LightningServerResponse lsr = APXPeakApplicationToCaseController.checkCountyMatch(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.containsKey('showConfirmMessage'), 'objectData should contain showConfirmMessage as a key');
            System.assertEquals(true, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should contain be true');
            
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '2', County_Name__c = county.Id, County_Transfer_Notes__c ='County Update Transfer Notes');
            lsr = APXPeakApplicationToCaseController.checkCountyMatch(appProcessQueue.get(0).Id);
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should contain be true');            
            
            T_APPLN_CASE__c tempAppCase = new T_APPLN_CASE__c();
            insert tempAppCase;
            
            T_APPLN_PRCS_QUEUE__c tmpAppPrcsQueue = new T_APPLN_PRCS_QUEUE__c(
                IDN_APPLN__c = tempAppCase.Id,
                CDE_SOURCE__c = 'PK',
                DTE_RCVD_APPLN__c = System.today().addDays(-15),
                CDE_COUNTY__c = '6'
            );
            insert tmpAppPrcsQueue;
            delete tmpAppPrcsQueue;
            
            lsr = APXPeakApplicationToCaseController.checkCountyMatch(tmpAppPrcsQueue.Id);
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should contain be true');            
            
        }
    }    
    
    public static testMethod void testCheckCountyMatchException(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12', County_Transfer_Notes__c ='County Update Transfer Notes');
            LightningServerResponse lsr = APXPeakApplicationToCaseController.checkCountyMatch(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.containsKey('showConfirmMessage'), 'objectData should contain showConfirmMessage as a key');
        }
    }    
    
    
    public static testMethod void testGetIndividualDetails(){
        
        Date dob = System.today().addYears(-15);
        String ssn  = '123456789';
        
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false, dob, 'firstName','1', 'lastName', ssn,'CC');
        indivRec.IDN_STATE__c = '123456';
        insert indivRec;
        
        LightningServerResponse lsr1 = APXPeakApplicationToCaseController.getIndivInfo(indivRec.Id);
        
        LightningServerResponse lsr = APXPeakApplicationToCaseController.getIndividualDetails(indivRec.Id);
        System.assertEquals(true, lsr.objectData.containsKey('individual'), 'lsr should contain individual as a key');
        delete indivRec;        
        lsr = APXPeakApplicationToCaseController.getIndividualDetails(indivRec.Id);
        System.assertEquals(false, lsr.isSuccessful, 'isSuccessful should be false');        
    }
    
    public static testMethod void testGetInitData(){
        
        List<T_APPLN_CASE__c> appCases = [SELECT Id FROM T_APPLN_CASE__c];
        System.assertEquals(false, appCases.isEmpty(),'appCases should not be null');
        
        
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueue.isEmpty(),'appProcessQueue should not be null');
        
        LightningServerResponse lsr = APXPeakApplicationToCaseController.getInitData(null);
        System.assertEquals(false,lsr.isSuccessful,'lsr.isSuccessful should be false');
        
        lsr = APXPeakApplicationToCaseController.getInitData(appProcessQueue.get(0).Id);
        System.assertEquals(false,lsr.isSuccessful,'lsr.isSuccessful should be false');
        
        T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(false,System.today().addYears(-15), 'Art', '1', 'Vandaley','12345',appCases.get(0).Id);
        appIndiv.IND_CRTKR_PRIM__c = 'Y';
        appIndiv.IDN_SEQ_INDIV__c = 1;
        T_APPLN_INDIV__c appIndiv2 = TestClassUtility.createApplicationIndividual(false,System.today().addYears(-15), 'Regina', '2', 'Phalange','54321',appCases.get(0).Id);
        appIndiv2.IDN_SEQ_INDIV__c = 2;
        insert new List<T_APPLN_INDIV__c>{appIndiv,appIndiv2};
            insert new T_APPLN_REL__c(IDN_APPLN_INDIV__c=appIndiv.id,IDN_SEQ_INDIV_RELTD__c=2);
        Test.startTest();                    
        lsr = APXPeakApplicationToCaseController.getInitData(appProcessQueue.get(0).Id);
        System.assertEquals(true,lsr.isSuccessful,'lsr.isSuccessful should be true');            
        Test.stopTest();
        
        
    }
    
    public static testMethod void testUpdateRecords(){
        List<T_APPLN_CASE__c> appCases = [SELECT Id FROM T_APPLN_CASE__c];
        System.assertEquals(false, appCases.isEmpty(),'appCases should not be null');
        T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(true,System.today().addYears(-15), 'Art', '1', 'Vandaley','12345',appCases.get(0).Id);        
        System.assertEquals(true, String.isEmpty(appIndiv.IDN_STATE__c), 'IDN_STATE__c should be empty');
        appIndiv.IDN_STATE__c = '12345';
        Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.updateRecords(new List<SObject>{appIndiv});
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        Test.stopTest();        
    }
    
    public static testMethod void testUpdateRecordsIndividual(){
        APXPeakApplicationToCaseController.updateRecords(null);
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        T_SBSD_INDIV__c indivRec2 = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRec2.IDN_STATE__c = '12345';
        insert indivRec2;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        insert indivRec;
        //insert new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today()-10);
        indivRec.IDN_STATE__c = '12345';
        Test.startTest();
        APXPeakApplicationToCaseController.updateRecords(new List<SObject>{indivRec});
        APXPeakApplicationToCaseController.updateRecords(new List<SObject>{indivRec});
        Test.stopTest();        
    }
    
    public static testMethod void testUpdateRecordsExistingIndividual(){
        APXPeakApplicationToCaseController.updateRecords(null);
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        T_SBSD_INDIV__c indivRec2 = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRec2.IDN_STATE__c = '12345';
        insert indivRec2;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, counties.get(0).Id);
        T_SBSD_CASE__c caseRec2 = TestClassUtility.createCase(false, counties.get(0).Id);
        insert new List<T_SBSD_CASE__c>{caseRec,caseRec2};
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        insert indivRec;
        T_INDIV_CUST__c custRec = new T_INDIV_CUST__c(IDN_CLIENT__c = indivRec.Id, DTE_BEGIN_EFFV__c = System.today()-10);
        insert custRec;
        insert new List<T_SBSD_CASE_INDIV__c>{new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today()-10),
            new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec2.Id, DTE_BEGIN_EFFV__c = System.today()-10),
            new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec2.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today()-10)
            };
                indivRec.IDN_STATE__c = '12345';
        Test.startTest();
        APXPeakApplicationToCaseController.updateRecords(new List<SObject>{indivRec});
        APXPeakApplicationToCaseController.updateRecords(new List<SObject>{indivRec});
        Test.stopTest();        
    }

    public static testMethod void testUpdateRecordsExistingIndividualWithCaseIndividual(){
        APXPeakApplicationToCaseController.updateRecords(null);
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        T_SBSD_INDIV__c indivRec2 = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRec2.IDN_STATE__c = '12345';
        insert indivRec2;
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, counties.get(0).Id);
        T_SBSD_CASE__c caseRec2 = TestClassUtility.createCase(false, counties.get(0).Id);
        insert new List<T_SBSD_CASE__c>{caseRec,caseRec2};
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        insert indivRec;
        insert new List<T_SBSD_CASE_INDIV__c>{new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec2.Id, DTE_BEGIN_EFFV__c = System.today()-10),
            new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec2.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today()-10)
            };
                indivRec.IDN_STATE__c = '12345';
        Test.startTest();
        APXPeakApplicationToCaseController.updateRecords(new List<SObject>{indivRec});
        APXPeakApplicationToCaseController.updateRecords(new List<SObject>{indivRec});
        Test.stopTest();        
    }
    
    public static testMethod void testFindCaseAndPrimaryCaretakerDetails(){
         List<String> stateId=new List<String>();
        stateId.add('12345');
        stateId.add('56789');
        List<T_SBSD_CASE__c>caselist=new List<T_SBSD_CASE__c>();
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        List<T_COUNTY__c> countiesone = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        T_SBSD_CASE__c caseRecone = TestClassUtility.createCase(true, countiesone.get(0).Id);
        caselist.add(caseRec);
        caselist.add(caseRecone);
        List<T_SBSD_INDIV__c>indivlist=new List<T_SBSD_INDIV__c>();
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRec.IDN_STATE__c = stateId[0];
        indivlist.add(indivRec);
         T_SBSD_INDIV__c indivRecone = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRecone.IDN_STATE__c = stateId[1];
        indivlist.add(indivRecone);
        insert indivlist;
        insert new List<SObject>{new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today()-10),
            new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRec.Id, DTE_BEGIN_EFFV__c = System.today()-10),new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRecone.Id,IDN_CLIENT__c=indivRecone.Id, DTE_BEGIN_EFFV__c = System.today()-10),
            new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRecone.Id, DTE_BEGIN_EFFV__c = System.today()-11)
            };
                Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.findCaseAndPrimaryCaretakerDetails(stateId);
        Test.stopTest();
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        System.assertNotEquals(true, !lsr.objectData.containsKey('mapCaseIdCaseStatus') || !lsr.objectData.containsKey('lstCaseIndividual'),'lsr.objectData should have mapCaseIdCaseStatus or lstCaseIndividual as keys');
    }    
    
    public static testMethod void testFindIndividualMatches(){
        
        Date dob = System.today().addYears(-15);
        String ssn  = '123456789';
        
        LightningServerResponse lsr = APXPeakApplicationToCaseController.findIndividualMatches(null, null, null, String.valueOf(dob), ssn, null);
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false, dob, 'firstName','1', 'lastName', ssn,'CC');
        indivRec.IDN_STATE__c = '123456';
        insert indivRec;
        Test.startTest();
        
        lsr = APXPeakApplicationToCaseController.findIndividualMatches('firstName','lastName', null , String.valueOf(dob), ssn, null);
        
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('lstMatchedCHATSIndividuals') , 'lsr.objectData should have lstMatchedCHATSIndividuals as key');
        Test.stopTest();
    }
    
    public static testMethod void testFindIndividualMatchesScenario2(){
        
        Date dob = System.today().addYears(-15);
        String ssn  = '123456789';
        Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.findIndividualMatches(null,'Individual', null , String.valueOf(dob), ssn, null);
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        lsr = APXPeakApplicationToCaseController.findIndividualMatches('Individual',null, null , String.valueOf(dob), ssn, null);
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        Test.stopTest();
    }
    
    public static testMethod void testHandleCaseSelection(){
        
        LightningServerResponse lsr = APXPeakApplicationToCaseController.handleCaseSelection(null, null);                  
        System.assertEquals(false, lsr.isSuccessful,'lsr.isSuccessful should be false');
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        appProcessQueues.get(0).IDN_CASE__c = caseRec.Id;
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today()-15, 'Test','1', 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '11223344';
        T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today()-25, 'Test','1', 'IndividualB', '87654321',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '44332211';
        insert new List<SObject>{appIndivRec,appIndivRec2};
            
            lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        
        appProcessQueues.get(0).IDN_CASE__c = EMPTY_LOOKUP;
        insert new T_YEAR_HOL__c(DTE_HOL__c= System.today().addDays(2),CDE_YEAR__c=System.today().year());
        Test.startTest();
        lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true'); 
        Test.stopTest();
    }
    
    public static testMethod void testHandleCaseSelectionError(){
        
        LightningServerResponse lsr = APXPeakApplicationToCaseController.handleCaseSelection(null, null);                  
        System.assertEquals(false, lsr.isSuccessful,'lsr.isSuccessful should be false');
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        appProcessQueues.get(0).IDN_CASE__c = caseRec.Id;
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today()-15, 'Test','1', 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '11223344';
        T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today()-25, 'Test','1', 'IndividualB', '87654321',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '44332211';
        insert new List<SObject>{appIndivRec,appIndivRec2};
            
            lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        
        appProcessQueues.get(0).IDN_CASE__c = EMPTY_LOOKUP;
        
        Test.startTest();
        lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        Test.stopTest();
    }
    
    public static testMethod void testConvertDataError(){
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        appProcessQueues.get(0).IDN_CASE__c = caseRec.Id;
        appProcessQueues.get(0).CDE_SOURCE__c = 'PA';
        appProcessQueues.get(0).CDE_COUNTY__c = EMPTY_LOOKUP;
        Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), null);          
        System.debug(lsr);
        Test.stopTest();
    }    
    
     public static testMethod void testConvertData(){
        String stateId = '12345';
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        TestClassUtility.createCase(true, appProcessQueues.get(0).County_Name__c);
        
        T_COUNTY_PLAN_ADR__c countyAddress = new T_COUNTY_PLAN_ADR__c();
        countyAddress.IDN_COUNTY__c = counties.get(0).Id;
        countyAddress.RecordTypeId = Schema.SObjectType.T_COUNTY_PLAN_ADR__c.getRecordTypeInfosByName().get('Mailing').getRecordTypeId();
        insert countyAddress;
        
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','M', 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '11223344';
        appIndivRec.CDE_STATUS_MIL__c = 'NO';
        appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec.IDN_SEQ_INDIV__c = 1;
        appIndivRec.NAM_MI__c = 'TEST';
        
        T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-15), 'Test','F', 'Individual', '123456789',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec2.IDN_STATE__c = '10293876';
        appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec2.IDN_SEQ_INDIV__c = 2;
        appIndivRec2.CDE_STATUS_MIL__c = 'NO';
        /*
        T_APPLN_INDIV__c appIndivRec3 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-15), 'Test','F', 'Individual', '123456789',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec3.IDN_STATE__c = 'XX001';
        appIndivRec3.CDE_STATUS_MIL__c = 'NO';
        appIndivRec3.IND_CRTKR_PRIM__c = 'N';
        appIndivRec3.IDN_SEQ_INDIV__c = 3; */
        insert new List<SObject>{appIndivRec,appIndivRec2};

          insert new T_APPLN_REL__c(IDN_APPLN_INDIV__c=appIndivRec.id,IDN_SEQ_INDIV_RELTD__c=2, CDE_TYPE_REL_INDIV__c='FA');
            
            insert new List<SObject>{
                new T_APPLN_ADR__c(
                    ADR_CITY__c = 'test',
                    ADR_LINE_1__c = 'test line 1',
                    ADR_LINE_2__c = 'test line 2',
                    ADR_STATE__c = 'AK',
                    ADR_ZIP_EXTN__c = '1345',
                    ADR_ZIP_MAIN__c = '12345',
                    CDE_TYPE_ADR__c = 'ML',
                    IDN_APPLN_INDIV__c = appIndivRec.Id
                ),
                    new T_APPLN_INDIV_RACE__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_INDIV_RACE__c = 3, CDE_RACE__c = 'AA'),    
                    //new T_APPLN_PRCS_ADDNL_INFO__c(IND_TANF_RCVNG__c = 'Y', IDN_APPLN__c = appProcessQueues.get(0).IDN_APPLN__c),
                    //new T_APPLN_JOB_SEARCH__c(IDN_APPLN_INDIV__c = appIndivRec.Id, DTE_BEGIN_EFFV__c = System.today()),
                    new T_APPLN_CHILD_SUP__c(DTE_BIRTH_CUST_NON__c = System.today(),
                                             IDN_STATE_CUST_NON__c = '12',
                                             IND_CASE_OPEN__c = 'Y',
                                             IND_COOP_PARENT__c = 'Y',
                                             NAM_FIRST_CUST_NON__c = 'test',
                                             NAM_LAST_CUST_NON__c = 'test',
                                             IDN_APPLN_INDIV__c = appIndivRec.Id,
                                             NBR_SSN_CUST_NON__c = '12'
                                            ),
                    new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y',IDN_APPLN_INDIV__c = appIndivRec.Id),
                    new T_APPLN_DDTN__c(AMT_DDTN_TOTAL__c = 1,
                                        CDE_FREQ_PAID__c = '2PY',
                                        NAM_PAYEE__c = 'Test',
                                        NBR_DOCKET__c = '1',
                                        IDN_APPLN_INDIV__c = appIndivRec.Id
                                       ),
                    new T_APPLN_OTHER_INCOME__c( 
                        IDN_APPLN_INDIV__c = appIndivRec.Id,
                        IDN_APPLN_OTHER_INCOME__c = 12,
                        CDE_SOURCE_INCOME__c = '1',
                        IDN_COURT__c = '12',
                        CDE_FREQ_INCOME__c = '09',
                        AMT_INCOME_OTHER_GROSS__c = 23
                    ),
                    new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec.Id, NAM_SCHOOL__c = 'testSchool', CDE_TYPE_SCHOOL__c = '02'),
                    new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec.Id, NAM_SCHOOL__c = 'testSchool1', CDE_TYPE_SCHOOL__c = '13'),
                    new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec2.Id, NAM_SCHOOL__c = 'testSchool2', CDE_TYPE_SCHOOL__c = '13'),
                    new T_APPLN_CUST__c(
                        IDN_APPLN_INDIV__c = appIndivRec.Id,
                        IDN_APPLN_CUST__c = 12,
                        DTE_BEGIN_HEAD_START__c = System.today(),
                        IND_CC_REQ__c = 'Y',
                        IND_HEAD_START__c = 'N',
                        IND_FOSTER__c = 'Y',
                        IND_JOINT_CUST__c = 'Y',
                        DTE_JOINT_CUST__c = System.today(),
                        DTE_FOSTER__c = System.today()),
                    new T_APPLN_EMPLMT__c(
                        IDN_APPLN_INDIV__c = appIndivRec.Id,
                        ADR_CITY__c = 'test', ADR_SUFX__c = 'test', ADR_NAM__c = 'test',
                        ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'tewzt', ADR_STATE__c = 'AK',
                        CDE_UNIT__c = '1', NAM_BUSNS__c = '12', NBR_PHONE__c = '12387632',
                        ADR_ZIP_EXTN__c = '2625', NBR_PHONE_EXTN__c = '2222', ADR_POST__c = '26',
                        AMT_INCOME_MONTH_ESTMD__c = 12.00, ADR_ZIP_MAIN__c = '12235',
                        CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, ADR_PO_BOX__c = '1', ADR_PRE__c = '1',
                        DTE_BEGIN_INCOME__c = System.Date.newInstance(2017, 12, 01),
                        DTE_BEGIN_STRIKE__c = System.Date.newInstance(2017, 11, 07),
                        DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 11, 07), CDE_FREQ_EXP__c = '02'),
                    
                    new T_APPLN_SELF_EMPLMT__c(
                        IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', IDN_APPLN_SELF_EMPLMT__c = 1212,
                        CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, AMT_INCOME_MONTH_ESTMD__c = 12.00, IND_LLC_SCORP__c = '1',
                        ADR_ZIP_EXTN__c = '1234', NBR_PHONE_EXTN__c = '1234', NBR_PHONE__c = '4564362', ADR_ZIP_MAIN__c = '12445',
                        NAM_BUSNS__c = '12', AMT_EXP_MONTH__c = 12.00, ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'test', ADR_STATE__c = 'AK',
                        DTE_BEGIN_EFFV__c = System.Date.newInstance(2017, 11, 11))
                    };
                        
                      /*  insert new List<SObject>{
                            //new T_APPLN_CUST__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_CUST__c = 12, DTE_BEGIN_HEAD_START__c = System.today(), IND_CC_REQ__c = 'Y', IND_HEAD_START__c = 'N', IND_FOSTER__c = 'Y', IND_JOINT_CUST__c = 'Y', DTE_JOINT_CUST__c = System.today(), DTE_FOSTER__c = System.today()),
                            new T_APPLN_EMPLMT__c(IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', ADR_SUFX__c = 'test', ADR_NAM__c = 'test', ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'tewzt', ADR_STATE__c = 'AK', CDE_UNIT__c = '1', NAM_BUSNS__c = '12', NBR_PHONE__c = '12387632', ADR_ZIP_EXTN__c = '2625', NBR_PHONE_EXTN__c = '2222', ADR_POST__c = '26', AMT_INCOME_MONTH_ESTMD__c = 12.00, ADR_ZIP_MAIN__c = '12235', CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, ADR_PO_BOX__c = '1', ADR_PRE__c = '1',  DTE_BEGIN_INCOME__c = System.Date.newInstance(2017, 7, 11), DTE_BEGIN_STRIKE__c = System.Date.newInstance(2017, 15, 11), DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 14, 11), CDE_FREQ_EXP__c = '02'),
                                new T_APPLN_SELF_EMPLMT__c(IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', IDN_APPLN_SELF_EMPLMT__c = 1212, CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, AMT_INCOME_MONTH_ESTMD__c = 12.00, IND_LLC_SCORP__c = '1', ADR_ZIP_EXTN__c = '1234', NBR_PHONE_EXTN__c = '1234', NBR_PHONE__c = '4564362', ADR_ZIP_MAIN__c = '12445', NAM_BUSNS__c = '12', AMT_EXP_MONTH__c = 12.00, ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'test', ADR_STATE__c = 'AK', DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 14, 11),DTE_BEGIN_EFFV__c = System.Date.newInstance(2017, 13, 11))
                                };    */
        T_SBSD_INDIV__c existingIndiv = TestClassUtility.createIndividual(false, System.today().addYears(-15), 'Test', '2', 'Individual', '123456789', 'CC');
        existingIndiv.IDN_STATE__c = appIndivRec2.IDN_STATE__c;
        insert existingIndiv;
        Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id, appIndivRec2.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }

    public static testMethod void testConvertDataError2(){
        String stateId = '12345';
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        update new T_APPLN_CASE__c(NBR_PHONE_MSG_EXTN__c='abc',Id = appProcessQueues.get(0).IDN_APPLN__c);
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), null,null, 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        
        Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }

    public static testMethod void testConvertDataError3(){
        LightningServerResponse lsr = ConvertPeakDataToCHATS.convertData(null, null);   
        
        String stateId = '12345';
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');

        update new T_APPLN_CASE__c(NBR_PHONE_MSG_EXTN__c='abc',Id = appProcessQueues.get(0).IDN_APPLN__c);
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), null,null, 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        Test.startTest();
        LightningServerResponse lsr2 = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }

    
    public static testMethod void testConvertDataScenario2(){
        String stateId = '12345';
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        System.assertEquals(false, counties.isEmpty(), 'counties should not be empty');
        TestClassUtility.createCase(true, appProcessQueues.get(0).County_Name__c);
        
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','M', 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '11223344';
        appIndivRec.CDE_STATUS_MIL__c = 'NO';
        appIndivRec.IND_CRTKR_PRIM__c = 'Y';
        appIndivRec.NAM_MI__c = 'TEST';
        
        T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-15), 'Test','F', 'Individual', '123456789',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec2.IDN_STATE__c = stateId;
        appIndivRec2.CDE_STATUS_MIL__c = 'NO';
        
        T_APPLN_INDIV__c appIndivRec3 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-15), 'Test','F', 'Individual', '123456789',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec3.IDN_STATE__c = 'XX001';
        appIndivRec3.CDE_STATUS_MIL__c = 'NO';
        appIndivRec3.IND_CRTKR_PRIM__c = 'Y';
        insert new List<SObject>{appIndivRec, appIndivRec2, appIndivRec3};
            
          /*  insert new List<SObject>{
                new T_APPLN_ADR__c(
                    ADR_CITY__c = 'test',
                    ADR_LINE_1__c = 'test line 1',
                    ADR_LINE_2__c = 'test line 2',
                    ADR_STATE__c = 'AK',
                    ADR_ZIP_EXTN__c = '1345',
                    ADR_ZIP_MAIN__c = '12345',
                    CDE_TYPE_ADR__c = 'ML',
                    IDN_APPLN_INDIV__c = appIndivRec.Id
                ),
                    new T_APPLN_INDIV_RACE__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_INDIV_RACE__c = 3, CDE_RACE__c = 'AA'),    
                    new T_APPLN_PRCS_ADDNL_INFO__c(IND_TANF_RCVNG__c = 'Y', IDN_APPLN__c = appProcessQueues.get(0).IDN_APPLN__c),
                    new T_APPLN_JOB_SEARCH__c(IDN_APPLN_INDIV__c = appIndivRec.Id, DTE_BEGIN_EFFV__c = System.today()),
                    /*new T_APPLN_CHILD_SUP__c(DTE_BIRTH_CUST_NON__c = System.today(),
                                             IDN_STATE_CUST_NON__c = '12',
                                             IND_CASE_OPEN__c = 'Y',
                                             IND_COOP_PARENT__c = 'Y',
                                             NAM_FIRST_CUST_NON__c = 'test',
                                             NAM_LAST_CUST_NON__c = 'test',
                                             IDN_APPLN_INDIV__c = appIndivRec.Id,
                                             NBR_SSN_CUST_NON__c = '12'
                                            ),*/
                   /* new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y',IDN_APPLN_INDIV__c = appIndivRec.Id),
                    new T_APPLN_DDTN__c(AMT_DDTN_TOTAL__c = 1,
                                        CDE_FREQ_PAID__c = '2PY',
                                        NAM_PAYEE__c = 'Test',
                                        NBR_DOCKET__c = '1',
                                        IDN_APPLN_INDIV__c = appIndivRec.Id
                                       ),
                    new T_APPLN_OTHER_INCOME__c( 
                        IDN_APPLN_INDIV__c = appIndivRec.Id,
                        IDN_APPLN_OTHER_INCOME__c = 12,
                        CDE_SOURCE_INCOME__c = '1',
                        IDN_COURT__c = '12',
                        CDE_FREQ_INCOME__c = '09',
                        AMT_INCOME_OTHER_GROSS__c = 23
                    ),
                    new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec.Id, NAM_SCHOOL__c = 'testSchool', CDE_TYPE_SCHOOL__c = '02'),
                    new T_APPLN_REL__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_REL__c = 12, IDN_SEQ_INDIV_RELTD__c = 12, CDE_TYPE_REL_INDIV__c = 'AU')
                    };
                        
                        insert new List<SObject>{
                            //new T_APPLN_CUST__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_CUST__c = 12, DTE_BEGIN_HEAD_START__c = System.today(), IND_CC_REQ__c = 'Y', IND_HEAD_START__c = 'N', IND_FOSTER__c = 'Y', IND_JOINT_CUST__c = 'Y', DTE_JOINT_CUST__c = System.today(), DTE_FOSTER__c = System.today()),
                            new T_APPLN_EMPLMT__c(IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', ADR_SUFX__c = 'test', ADR_NAM__c = 'test', ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'tewzt', ADR_STATE__c = 'AK', CDE_UNIT__c = '1', NAM_BUSNS__c = '12', NBR_PHONE__c = '12387632', ADR_ZIP_EXTN__c = '2625', NBR_PHONE_EXTN__c = '2222', ADR_POST__c = '26', AMT_INCOME_MONTH_ESTMD__c = 12.00, ADR_ZIP_MAIN__c = '12235', CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, ADR_PO_BOX__c = '1', ADR_PRE__c = '1',  DTE_BEGIN_INCOME__c = System.Date.newInstance(2017, 7, 11), DTE_BEGIN_STRIKE__c = System.Date.newInstance(2017, 15, 11), DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 14, 11), CDE_FREQ_EXP__c = '02'),
                                new T_APPLN_SELF_EMPLMT__c(IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', IDN_APPLN_SELF_EMPLMT__c = 1212, CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, AMT_INCOME_MONTH_ESTMD__c = 12.00, IND_LLC_SCORP__c = '1', ADR_ZIP_EXTN__c = '1234', NBR_PHONE_EXTN__c = '1234', NBR_PHONE__c = '4564362', ADR_ZIP_MAIN__c = '12445', NAM_BUSNS__c = '12', AMT_EXP_MONTH__c = 12.00, ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'test', ADR_STATE__c = 'AK', DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 14, 11),DTE_BEGIN_EFFV__c = System.Date.newInstance(2017, 13, 11))
                                };    
                                    
                                    T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRec.IDN_STATE__c = appIndivRec2.IDN_STATE__c;
        insert indivRec;*/
        Test.startTest();
        LightningServerResponse lsr = APXPeakApplicationToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id, appIndivRec2.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }
    
    public static testMethod void testSetPeakDataFlagToFalse(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.Is_Peak_Data__c = true;
        insert caseRec;
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.Is_Peak_Data__c = true;
        insert individual;
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        insert new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c=caseIndiv.id,DTE_BEGIN_EFFV__c=System.today().addDays(-2));
        LightningServerResponse lsr = APXPeakApplicationToCaseController.setPeakDataFlagToFalse(caseRec.id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
    }
    
    
    @testSetup
    public static void setUpData(){
        TestClassUtility.createCounty('Denver','Denver',1,true);
        
        
        
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR',CDE_INFO_EM__c='test@test.com', IND_IS_HOMELESS__c='Y');
        
        insert appCase;
        
        insert new T_APPLN_PRCS_SEARCH__c(IDN_APPLN__c=appCase.id,DTE_WKDAY_APPLN__c=System.today());
        
        insert new T_APPLN_PRCS_ADDNL_INFO__c(IND_TANF_RCVNG__c = 'Y', IDN_APPLN__c = appCase.Id);
        
        T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1'
        );
        insert appProcessQueue;
    }
    
    @isTest
    static void testAssignStateId() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new assignStateIdMockTest());
        LightningServerResponse lsr=APXPeakApplicationToCaseController.assignStateId('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','2');
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
        LightningServerResponse lsr_1=APXPeakApplicationToCaseController.assignStateId('ABCDEFGH', 'XYZ','','2010-01-01','','1');
        system.assertEquals(true,lsr_1.isSuccessful,'isSuccessful should be true');
        LightningServerResponse lsr_2=APXPeakApplicationToCaseController.assignStateId('ABCDEFGH', 'XYZ','','2010-01-01','','3');
        system.assertEquals(true,lsr_2.isSuccessful,'isSuccessful should be true');
        
        Test.setMock(HttpCalloutMock.class, new HerokuServiceUnSuccessfullCalloutMock());
        LightningServerResponse lsr2=APXPeakApplicationToCaseController.assignStateId('ABCD', 'XYZ','M','19900505','762364379','2');
        system.assertEquals(true,lsr2.isSuccessful,'isSuccessful should be true');
        
        test.stopTest();
    }
    
    @isTest
    static void testOverrideClientClearance() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new getOverrideClientClearanceMockTest());
        LightningServerResponse lsr=APXPeakApplicationToCaseController.overrideClientClearance('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','2');
        LightningServerResponse lsr1=APXPeakApplicationToCaseController.overrideClientClearance('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','3');
        LightningServerResponse lsr2=APXPeakApplicationToCaseController.overrideClientClearance('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','4');
        LightningServerResponse lsr_override1 =APXPeakApplicationToCaseController.overrideClientClearance('ABCDEFGH', '','','2010-01-01','','1');
        test.stopTest();
    }
    
    public static testMethod void testCheckIfStateIdExisting(){
        LightningServerResponse lsr =  APXPeakApplicationToCaseController.checkStateIdExisting('PY0001');
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.IDN_STATE__c = 'PY0001';
        insert individual;
        LightningServerResponse lsr2 =  APXPeakApplicationToCaseController.checkStateIdExisting('PY0001');
    }
    
    public static testMethod void testInsertATSRecordForCaseIndividual(){
        APXPeakApplicationToCaseController.insertATSRecordForCaseIndividual('abc', 'abc');  
        APXPeakApplicationToCaseController.insertATSRecordForCaseIndividual('', 'abc');   
        
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new Junk_Record__c(Record_ID_To_Be_Deleted__c = caseData.get('individual').Id, Object_API_Name__c = 'T_SBSD_INDIV__C');
        /*insert new T_SBSD_CASE_INDIV__c(IDN_CLIENT__c = caseData.get('individual').Id,
                                        IDN_CASE__c = caseData.get('caseRec').Id,
                                        DTE_BEGIN_EFFV__c = date.today());*/
        //APXPeakApplicationToCaseController.insertATSRecordForCaseIndividual(caseData.get('caseRec').Id, caseData.get('individual').Id);   
        //List<T_POS_TRANS_QUEUE_ATS__c> posdata = [SELECT Id FROM T_POS_TRANS_QUEUE_ATS__c];
        //System.assertEquals(false, posdata.isEmpty(), 'posdata should not be empty');        
    }
    
        public static testMethod void testgetIPVDisqualification(){
			T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(false, System.today().addYears(-21), 'firstname', 'M',  'lastname', '1230987', 'CC') ;
			LightningServerResponse lsr = APXPeakApplicationToCaseController.getIPVDisqualification(indiv.Id);
            }
}