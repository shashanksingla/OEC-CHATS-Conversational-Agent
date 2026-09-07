@isTest
public class APXCBMSReferralToCaseControllerTest {
 public final static String EMPTY_LOOKUP = null;
    
    public static testMethod void testGetNextBusinessDayForHoliday(){
        System.assertEquals(true,ConvertPeakDataToCHATS.getNextBusinessDay(System.today(), new set<Date>{System.today()})!=null,'It should be a date');
    }
    
    public static testMethod void testgetInitDataChangeRef(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id, 'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12');
            LightningServerResponse lsr = APXCBMSReferralToCaseController.getInitDataChangeRef(appProcessQueue.get(0).Id,appProcessQueue.get(0).Id);
            
        }
    }
   
    public static testMethod void testgetAppAndRelatedChildDataChange(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id, 'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12');
            LightningServerResponse lsr = APXCBMSReferralToCaseController.getAppAndRelatedChildDataChange(appProcessQueue.get(0).Id);
            
        }
    } 
    
   
    public static testMethod void testhandleRefCaseSelection(){
        
        
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
        T_APPLN_INDIV__c appindiv=new T_APPLN_INDIV__c();
        appIndiv.DTE_DOB__c=System.today()-30;
        appIndiv.NAM_FIRST__c='Testing';
        appIndiv.CDE_GENDER__c='1';
        appIndiv.NAM_LAST__c='IndividualC';
        appIndiv.NBR_SSN__c='12345675';
        appIndiv.IDN_APPLN__c =appProcessQueues.get(0).IDN_APPLN__c;
        insert appIndiv;
        Test.startTest();
        LightningServerResponse lsr= APXCBMSReferralToCaseController.handleRefCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id},appindiv.Id);          
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true'); 
        Test.stopTest();
    }
   
     public static testMethod void exceptionTestMethod(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            try {
               LightningServerResponse lsr= APXCBMSReferralToCaseController.getInitDataChangeRef(null,null);
            } catch (Exception e) {
                return;
            }
        }
    }
     public static testMethod void testcreateTask(){
         Test.startTest();
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c]; 
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
          T_APPLN_PRCS_QUEUE__c apprcque=new T_APPLN_PRCS_QUEUE__c();
         apprcque.IDN_CASE__c=caseRec.Id;
         insert apprcque;
        LightningServerResponse lsr= APXCBMSReferralToCaseController.createTask(caseRec.Id,null);            
        Test.stopTest();
     }
    
    public static testMethod void testupdateCHATSObjsInfo(){
        List<Referral_Information__c>RefInfo=new List<Referral_Information__c>();
        List<String>RefIds=new List<String>();
         List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c]; 
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        Referral_Information__c refrec=new Referral_Information__c();
        refrec.Name='Testing';
        refrec.Old_Value__c='Testing1';
        refrec.New_Value__c='Testing2';
        refrec.SF_Record_Id__c=caseRec.Id;
        refrec.Field_API_Name__c='CDE_COUNTY__c';
        refrec.Referral_Id__c='123';
        refrec.Referral_Type__c='New';
        refrec.Object_API_Name__c='T_SBSD_CASE__c';
        refrec.CBMS_Object_Name__c='T_APPLN_CASE__c';
        refrec.Field_Name__c='COUNTY';
        RefInfo.add(refrec);
        insert RefInfo;
         for(Referral_Information__c rec:RefInfo){
                RefIds.add(rec.Id);
            }   
        Test.startTest();    
        LightningServerResponse lsr= APXCBMSReferralToCaseController.updateCHATSObjsInfo(RefIds);            
        Test.stopTest();
     }
     
    
        
 public static testMethod void testgetAppAndRelatedChildData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12');
            LightningServerResponse lsr = APXCBMSReferralToCaseController.getAppAndRelatedChildData(appProcessQueue.get(0).Id);
            
        }
    }   
    public static testMethod void testgetAppAndRelatedLowIncomeData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id, 'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12');
            T_APPLN_INDIV__c appIndiv1 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test', '1', 'Individual1', '123456789', appProcessQueue.get(0).IDN_APPLN__c);
            T_APPLN_INDIV__c appIndiv2 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-20), 'Test', '2', 'Individual2', '987654321', appProcessQueue.get(0).IDN_APPLN__c);
            insert new List<T_APPLN_INDIV__c>{appIndiv1, appIndiv2};
            insert new List<SObject>{
                new T_APPLN_ACTIVITY__c(IDN_INDIVIDUAL__c = appIndiv1.Id, CDE_TYPE_ACTV__c = '13', DTE_BEGIN_ACTV_PRIM__c = System.today().addDays(-30)),
                new T_APPLN_OTHER_INCOME__c(IDN_APPLN_INDIV__c = appIndiv1.Id, IDN_APPLN_OTHER_INCOME__c = 12, CDE_SOURCE_INCOME__c = '1',
                        IDN_COURT__c = '12', CDE_FREQ_INCOME__c = '09', AMT_INCOME_OTHER_GROSS__c = 23),
                new T_APPLN_EMPLMT__c(
                    IDN_APPLN_INDIV__c = appIndiv1.Id,
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
                    IDN_APPLN_INDIV__c = appIndiv1.Id, ADR_CITY__c = 'test', IDN_APPLN_SELF_EMPLMT__c = 1212,
                    CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, AMT_INCOME_MONTH_ESTMD__c = 12.00, IND_LLC_SCORP__c = '1',
                    ADR_ZIP_EXTN__c = '1234', NBR_PHONE_EXTN__c = '1234', NBR_PHONE__c = '4564362', ADR_ZIP_MAIN__c = '12445',
                    NAM_BUSNS__c = '12', AMT_EXP_MONTH__c = 12.00, ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'test', ADR_STATE__c = 'AK',
                    DTE_BEGIN_EFFV__c = System.Date.newInstance(2017, 11, 11))
            };
            Test.startTest();
            LightningServerResponse lsr = APXCBMSReferralToCaseController.getAppAndRelatedLowIncomeData(appProcessQueue.get(0).Id);
            Test.stopTest();
            System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
            System.assertEquals(true, lsr.objectData.containsKey('incomeTypesLIRefInfo') || lsr.objectData.containsKey('noDataMessage'), 'Should contain activity data or no data message');
        }
    }
    public static testMethod void testprocessTransitionOnFinish(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12');
            LightningServerResponse lsr = APXCBMSReferralToCaseController.processTransitionOnFinish(appProcessQueue.get(0).Id);
            
        }
    }
      public static testMethod void testcheckPeakDataflag(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            try {
               LightningServerResponse lsr= APXCBMSReferralToCaseController.setPeakDataFlagToFalse(null);
            } catch (Exception e) {
                return;
            }
        }
    }
    
    public static testMethod void testCheckIfAppHasPrimaryCaretaker(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(true,System.today().addYears(-15), 'Art', '1', 'Vandaley','12345',appProcessQueue.get(0).IDN_APPLN__c);
            
            LightningServerResponse lsr = APXCBMSReferralToCaseController.checkIfAppHasPrimaryCaretaker(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.containsKey('hasPrimaryCaretaker'), 'objectData should contain hasPrimaryCaretaker as a key');
            System.assertEquals(false, lsr.objectData.get('hasPrimaryCaretaker'), 'hasPrimaryCaretaker should be false');
            
            appIndiv.IND_CRTKR_PRIM__c = 'Y';
            update appIndiv;
            lsr = APXCBMSReferralToCaseController.checkIfAppHasPrimaryCaretaker(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.get('hasPrimaryCaretaker'), 'hasPrimaryCaretaker should be true');            
            
            delete appProcessQueue;
            lsr = APXCBMSReferralToCaseController.checkIfAppHasPrimaryCaretaker(appProcessQueue.get(0).Id);
            System.assertEquals(false, lsr.isSuccessful, 'isSuccessful should be be true');            
            
        }
    }    
    
    
    public static testMethod void testCheckCountyMatch(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test', null, 2, true); 
        User user;
        Profile userProfile=[Select id from Profile where Name ='Eligibility Worker'];
        user = TestClassUtility.createUser(userProfile.Id, 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            List<PermissionSet> ps = [SELECT Id FROM PermissionSet WHERE Name = 'Eligibility_Worker_PS'];
            if(!ps.isEmpty()){
                // 3. Assign the permission set to the user
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = user.Id;
                psa.PermissionSetId = ps[0].Id;
                insert psa;
            } 
        }
        System.runAs(user){
            Test.startTest();
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            LightningServerResponse lsr = APXCBMSReferralToCaseController.checkCountyMatch(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.containsKey('showConfirmMessage'), 'objectData should contain showConfirmMessage as a key');
            System.assertEquals(true, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should contain be true');
            
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '2', County_Name__c = county.Id);
            lsr = APXCBMSReferralToCaseController.checkCountyMatch(appProcessQueue.get(0).Id);
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should contain be true');            
            
            T_APPLN_CASE__c tempAppCase = new T_APPLN_CASE__c();
            insert tempAppCase;
            
            T_APPLN_PRCS_QUEUE__c tmpAppPrcsQueue = new T_APPLN_PRCS_QUEUE__c(
                IDN_APPLN__c = tempAppCase.Id,
                CDE_SOURCE__c = 'CB',
                DTE_RCVD_APPLN__c = System.today().addDays(-15),
                CDE_COUNTY__c = '6'
            );
            insert tmpAppPrcsQueue;
            delete tmpAppPrcsQueue;
            
            lsr = APXCBMSReferralToCaseController.checkCountyMatch(tmpAppPrcsQueue.Id);
            Test.stopTest();
            System.assertEquals(false, lsr.objectData.get('showConfirmMessage'), 'showConfirmMessage should contain be true');            
            
        }
    }    
    
    public static testMethod void testCheckCountyMatchException(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            update new T_APPLN_PRCS_QUEUE__c(Id = appProcessQueue.get(0).Id, CDE_COUNTY__c = '12');
            LightningServerResponse lsr = APXCBMSReferralToCaseController.checkCountyMatch(appProcessQueue.get(0).Id);
            System.assertEquals(true, lsr.objectData.containsKey('showConfirmMessage'), 'objectData should contain showConfirmMessage as a key');
        }
    }    
      public static testMethod void testAppandRelatedChildDataChange(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            try {
                LightningServerResponse lsr= APXCBMSReferralToCaseController.getAppAndRelatedChildDataChange('');
            } catch (Exception e) {
                return;
            }
        }
    }
     public static testMethod void testexceptionfind(){
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        System.runAs(user){
            try {
                LightningServerResponse lsr= APXCBMSReferralToCaseController.handleRefCaseSelection(Null,Null,Null);
            } catch (Exception e) {
                return;
            }
        }
    }
     
    
    public static testMethod void testGetIndividualDetails(){
        
        Date dob = System.today().addYears(-15);
        String ssn  = '123456789';
        
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false, dob, 'firstName','1', 'lastName', ssn,'CC');
        indivRec.IDN_STATE__c = '123456';
        insert indivRec;
        
        LightningServerResponse lsr = APXCBMSReferralToCaseController.getIndividualDetails(indivRec.Id);
        System.assertEquals(true, lsr.objectData.containsKey('individual'), 'lsr should contain individual as a key');
        delete indivRec;        
        lsr = APXCBMSReferralToCaseController.getIndividualDetails(indivRec.Id);
        System.assertEquals(false, lsr.isSuccessful, 'isSuccessful should be false');        
    }
    
    public static testMethod void testGetInitData(){
        
        List<T_APPLN_CASE__c> appCases = [SELECT Id FROM T_APPLN_CASE__c];
        System.assertEquals(false, appCases.isEmpty(),'appCases should not be null');
        
        
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueue.isEmpty(),'appProcessQueue should not be null');
        
        LightningServerResponse lsr = APXCBMSReferralToCaseController.getInitData(null);
        System.assertEquals(false,lsr.isSuccessful,'lsr.isSuccessful should be false');
        
        lsr = APXCBMSReferralToCaseController.getInitData(appProcessQueue.get(0).Id);
        System.assertEquals(false,lsr.isSuccessful,'lsr.isSuccessful should be false');
        
        T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(false,System.today().addYears(-15), 'Art', '1', 'Vandaley','12345',appCases.get(0).Id);
        appIndiv.IND_CRTKR_PRIM__c = 'Y';
        appIndiv.IDN_SEQ_INDIV__c = 1;
        T_APPLN_INDIV__c appIndiv2 = TestClassUtility.createApplicationIndividual(false,System.today().addYears(-15), 'Regina', '2', 'Phalange','54321',appCases.get(0).Id);
        appIndiv2.IDN_SEQ_INDIV__c = 2;
        insert new List<T_APPLN_INDIV__c>{appIndiv,appIndiv2};
            insert new T_APPLN_REL__c(IDN_APPLN_INDIV__c=appIndiv.id,IDN_SEQ_INDIV_RELTD__c=2);
        Test.startTest();                    
        lsr = APXCBMSReferralToCaseController.getInitData(appProcessQueue.get(0).Id);
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
        LightningServerResponse lsr = APXCBMSReferralToCaseController.updateRecords(new List<SObject>{appIndiv});
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        Test.stopTest();        
    }
    
    public static testMethod void testUpdateRecordsIndividual(){
        APXCBMSReferralToCaseController.updateRecords(null);
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
        APXCBMSReferralToCaseController.updateRecords(new List<SObject>{indivRec});
        APXCBMSReferralToCaseController.updateRecords(new List<SObject>{indivRec});
        Test.stopTest();        
    }
     
    
    public static testMethod void testUpdateRecordsExistingIndividual(){
        APXCBMSReferralToCaseController.updateRecords(null);
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
        APXCBMSReferralToCaseController.updateRecords(new List<SObject>{indivRec});
        APXCBMSReferralToCaseController.updateRecords(new List<SObject>{indivRec});
        Test.stopTest();        
    }

    public static testMethod void testUpdateRecordsExistingIndividualWithCaseIndividual(){
        APXCBMSReferralToCaseController.updateRecords(null);
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
        APXCBMSReferralToCaseController.updateRecords(new List<SObject>{indivRec});
        APXCBMSReferralToCaseController.updateRecords(new List<SObject>{indivRec});
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
        LightningServerResponse lsr = APXCBMSReferralToCaseController.findCaseAndPrimaryCaretakerDetails(stateId);
        Test.stopTest();
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        System.assertNotEquals(true, !lsr.objectData.containsKey('mapCaseIdCaseStatus') || !lsr.objectData.containsKey('lstCaseIndividual'),'lsr.objectData should have mapCaseIdCaseStatus or lstCaseIndividual as keys');
    }    
    
    public static testMethod void testFindIndividualMatches(){
        
        Date dob = System.today().addYears(-15);
        String ssn  = '123456789';
        
        LightningServerResponse lsr = APXCBMSReferralToCaseController.findIndividualMatches(null, null, null, String.valueOf(dob), ssn, null);
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        
        T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false, dob, 'firstName','1', 'lastName', ssn,'CC');
        indivRec.IDN_STATE__c = '123456';
        insert indivRec;
        Test.startTest();
        
        lsr = APXCBMSReferralToCaseController.findIndividualMatches('firstName','lastName', null , String.valueOf(dob), ssn, null);
        
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('lstMatchedCHATSIndividuals') , 'lsr.objectData should have lstMatchedCHATSIndividuals as key');
        Test.stopTest();
    }
    
    public static testMethod void testFindIndividualMatchesScenario2(){
        
        Date dob = System.today().addYears(-15);
        String ssn  = '123456789';
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.findIndividualMatches(null,'Individual', null , String.valueOf(dob), ssn, null);
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        lsr = APXCBMSReferralToCaseController.findIndividualMatches('Individual',null, null , String.valueOf(dob), ssn, null);
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        Test.stopTest();
    }
    
    public static testMethod void testHandleCaseSelection(){
        
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleCaseSelection(null, null);                  
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
            
            lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        
        appProcessQueues.get(0).IDN_CASE__c = EMPTY_LOOKUP;
        insert new T_YEAR_HOL__c(DTE_HOL__c= System.today().addDays(2),CDE_YEAR__c=System.today().year());
        Test.startTest();
        lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true'); 
        Test.stopTest();
    }
    
    public static testMethod void testHandleCaseSelectionError(){
        
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleCaseSelection(null, null);                  
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
            
            lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
        System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be true');
        
        appProcessQueues.get(0).IDN_CASE__c = EMPTY_LOOKUP;
        
        Test.startTest();
        lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id,appIndivRec2.Id});          
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
        appProcessQueues.get(0).CDE_SOURCE__c = 'CB';
        appProcessQueues.get(0).CDE_COUNTY__c = EMPTY_LOOKUP;
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), null);          
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
        
       /* T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-15), 'Test','F', 'Individual', '123456789',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec2.IDN_STATE__c = stateId;
        appIndivRec2.IDN_SEQ_INDIV__c = 2;
        appIndivRec2.CDE_STATUS_MIL__c = 'NO';
        
        T_APPLN_INDIV__c appIndivRec3 = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-15), 'Test','F', 'Individual', '123456789',appProcessQueues.get(0).IDN_APPLN__c);
        appIndivRec3.IDN_STATE__c = 'XX001';
        appIndivRec3.CDE_STATUS_MIL__c = 'NO';
        appIndivRec3.IND_CRTKR_PRIM__c = 'N';
        appIndivRec3.IDN_SEQ_INDIV__c = 3; */
        insert new List<SObject>{appIndivRec};

          // insert new T_APPLN_REL__c(IDN_APPLN_INDIV__c=appIndivRec.id,IDN_SEQ_INDIV_RELTD__c=2, CDE_TYPE_REL_INDIV__c='FA');
            
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
                    new T_APPLN_EDUC__c(IDN_APPLN_INDIV__c = appIndivRec.Id, NAM_SCHOOL__c = 'testSchool', CDE_TYPE_SCHOOL__c = '02')
                    };
                        
                      /*  insert new List<SObject>{
                            //new T_APPLN_CUST__c(IDN_APPLN_INDIV__c = appIndivRec.Id, IDN_APPLN_CUST__c = 12, DTE_BEGIN_HEAD_START__c = System.today(), IND_CC_REQ__c = 'Y', IND_HEAD_START__c = 'N', IND_FOSTER__c = 'Y', IND_JOINT_CUST__c = 'Y', DTE_JOINT_CUST__c = System.today(), DTE_FOSTER__c = System.today()),
                            new T_APPLN_EMPLMT__c(IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', ADR_SUFX__c = 'test', ADR_NAM__c = 'test', ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'tewzt', ADR_STATE__c = 'AK', CDE_UNIT__c = '1', NAM_BUSNS__c = '12', NBR_PHONE__c = '12387632', ADR_ZIP_EXTN__c = '2625', NBR_PHONE_EXTN__c = '2222', ADR_POST__c = '26', AMT_INCOME_MONTH_ESTMD__c = 12.00, ADR_ZIP_MAIN__c = '12235', CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, ADR_PO_BOX__c = '1', ADR_PRE__c = '1',  DTE_BEGIN_INCOME__c = System.Date.newInstance(2017, 7, 11), DTE_BEGIN_STRIKE__c = System.Date.newInstance(2017, 15, 11), DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 14, 11), CDE_FREQ_EXP__c = '02'),
                                new T_APPLN_SELF_EMPLMT__c(IDN_APPLN_INDIV__c = appIndivRec.Id, ADR_CITY__c = 'test', IDN_APPLN_SELF_EMPLMT__c = 1212, CNT_WEEK_PER_HOURS_ESTMD__c = 12.00, AMT_INCOME_MONTH_ESTMD__c = 12.00, IND_LLC_SCORP__c = '1', ADR_ZIP_EXTN__c = '1234', NBR_PHONE_EXTN__c = '1234', NBR_PHONE__c = '4564362', ADR_ZIP_MAIN__c = '12445', NAM_BUSNS__c = '12', AMT_EXP_MONTH__c = 12.00, ADR_LINE_1__c = 'test', ADR_LINE_2__c = 'test', ADR_STATE__c = 'AK', DTE_BEGIN_EMP__c = System.Date.newInstance(2017, 14, 11),DTE_BEGIN_EFFV__c = System.Date.newInstance(2017, 13, 11))
                                };    */ 
                /*                    
                                    T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        indivRec.IDN_STATE__c = appIndivRec2.IDN_STATE__c;
        insert indivRec;*/
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }

    public static testMethod void testConvertDataError2(){
        String stateId = '12345';
        
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');
        
        update new T_APPLN_CASE__c(NBR_PHONE_MSG_EXTN__c='abc',Id = appProcessQueues.get(0).IDN_APPLN__c,CDE_CBMS_REF_TYP__c='New');
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), null,null, 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }

    public static testMethod void testConvertDataError3(){
        LightningServerResponse lsr = ConvertCBMSDataToCHATS.convertData(null, null);   
        
        String stateId = '12345';
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueues = [SELECT Id, IDN_APPLN__c, County_Name__c, IDN_CASE__c, CDE_COUNTY__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c];
        System.assertEquals(false, appProcessQueues.isEmpty(), 'appProcessQueues should not be empty');

        update new T_APPLN_CASE__c(NBR_PHONE_MSG_EXTN__c='abc',Id = appProcessQueues.get(0).IDN_APPLN__c,CDE_CBMS_REF_TYP__c='New');
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), null,null, 'Individual', '12345678',appProcessQueues.get(0).IDN_APPLN__c);
        Test.startTest();
        LightningServerResponse lsr2 = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id});          
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
        
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleCaseSelection(appProcessQueues.get(0), new List<String>{appIndivRec.Id, appIndivRec2.Id});          
        System.debug(lsr);
        //System.assertEquals(true, lsr.isSuccessful,'lsr.isSuccessful should be false');
        Test.stopTest();
    }
    
    public static testMethod void testSetPeakDataFlagToFalse(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.Is_CBMS_Data__c = true;
        insert caseRec;
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.Is_CBMS_Data__c = true;
        insert individual;
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        insert new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c=caseIndiv.id,DTE_BEGIN_EFFV__c=System.today().addDays(-2));
        LightningServerResponse lsr = APXCBMSReferralToCaseController.setPeakDataFlagToFalse(caseRec.id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
    }
    
    
    @testSetup
    public static void setUpData(){
        TestClassUtility.createCounty('Denver','Denver',1,true);
        
        
        
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c(CDE_CBMS_REF_TYP__c='New',NBR_PHONE_CELL__c='9999999999', NBR_PHONE_HOME__c = '9999999999', NBR_PHONE_MSG_EXTN__c = '9876', NBR_PHONE_MSG__c = '9999999999', CDE_INFO_PMC__c = 'WOR',CDE_INFO_EM__c='test@test.com', IND_IS_HOMELESS__c='Y');
        
        insert appCase;
        
        insert new T_APPLN_PRCS_SEARCH__c(IDN_APPLN__c=appCase.id,DTE_WKDAY_APPLN__c=System.today());
        
        T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'CB',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1'
        );
        insert appProcessQueue;
    }
    
    @isTest
    static void testAssignStateId() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new assignStateIdMockTest());
        LightningServerResponse lsr=APXCBMSReferralToCaseController.assignStateId('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','2');
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
        LightningServerResponse lsr_1=APXCBMSReferralToCaseController.assignStateId('ABCDEFGH', 'XYZ','','2010-01-01','','1');
        system.assertEquals(true,lsr_1.isSuccessful,'isSuccessful should be true');
        LightningServerResponse lsr_2=APXCBMSReferralToCaseController.assignStateId('ABCDEFGH', 'XYZ','','2010-01-01','','3');
        system.assertEquals(true,lsr_2.isSuccessful,'isSuccessful should be true');
        
        Test.setMock(HttpCalloutMock.class, new HerokuServiceUnSuccessfullCalloutMock());
        LightningServerResponse lsr2=APXCBMSReferralToCaseController.assignStateId('ABCD', 'XYZ','M','19900505','762364379','2');
        system.assertEquals(true,lsr2.isSuccessful,'isSuccessful should be true');
        
        test.stopTest();
    }
    
    @isTest
    static void testOverrideClientClearance() {
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new getOverrideClientClearanceMockTest());
        LightningServerResponse lsr=APXCBMSReferralToCaseController.overrideClientClearance('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','2');
        LightningServerResponse lsr_override1 =APXCBMSReferralToCaseController.overrideClientClearance('ABCDEFGH', '','','2010-01-01','','1');
        test.stopTest();
    }
    
    public static testMethod void testCheckIfStateIdExisting(){
        LightningServerResponse lsr =  APXCBMSReferralToCaseController.checkStateIdExisting('PY0001');
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.IDN_STATE__c = 'PY0001';
        insert individual;
        LightningServerResponse lsr2 =  APXCBMSReferralToCaseController.checkStateIdExisting('PY0001');
    }
    
    public static testMethod void testInsertATSRecordForCaseIndividual(){
        APXCBMSReferralToCaseController.insertATSRecordForCaseIndividual('abc', 'abc');   
        
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        insert new Junk_Record__c(Record_ID_To_Be_Deleted__c = caseData.get('individual').Id, Object_API_Name__c = 'T_SBSD_INDIV__C');
               
    }
    
    public static testMethod void testGetCaseSelectionData(){
        User user;
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today()-15, 'Test','1', 'Individual', '12345678', appProcessQueue.get(0).IDN_APPLN__c);
            appIndivRec.IDN_STATE__c = '11223344';
            appIndivRec.IND_CRTKR_PRIM__c = 'Y';
            appIndivRec.IDN_SEQ_INDIV__c = 1;
            
            T_APPLN_INDIV__c appIndivRec2 = TestClassUtility.createApplicationIndividual(false, System.today()-25, 'Test2','2', 'Individual2', '87654321', appProcessQueue.get(0).IDN_APPLN__c);
            appIndivRec2.IDN_STATE__c = '44332211';
            appIndivRec2.IND_CRTKR_PRIM__c = 'N';
            appIndivRec2.IDN_SEQ_INDIV__c = 2;
            insert new List<SObject>{appIndivRec, appIndivRec2};
            insert new T_APPLN_REL__c(IDN_APPLN_INDIV__c = appIndivRec2.id, IDN_SEQ_INDIV_RELTD__c = 1, CDE_TYPE_REL_INDIV__c = 'CH');

            List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
            T_SBSD_INDIV__c chatsIndiv = TestClassUtility.createIndividual(false, System.today()-15, 'Test','1', 'Individual', '12345678','CC');
            chatsIndiv.IDN_STATE__c = '11223344';
            insert chatsIndiv;
            insert new T_SBSD_CASE_INDIV__c(IND_CRTKR__c = true, IDN_CASE__c = caseRec.Id, IDN_CLIENT__c = chatsIndiv.Id, DTE_BEGIN_EFFV__c = System.today()-10);
            insert new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = caseRec.Id, DTE_BEGIN_EFFV__c = System.today()-10);

            Test.startTest();
            LightningServerResponse lsr = APXCBMSReferralToCaseController.getCaseSelectionData(appProcessQueue.get(0).Id);
            Test.stopTest();

            System.assertEquals(true, lsr.isSuccessful, 'getCaseSelectionData should be successful');
            System.assertEquals(true, lsr.objectData.containsKey('hasOtherIndividuals'), 'objectData should contain hasOtherIndividuals');
            System.assertEquals(true, lsr.objectData.containsKey('applicationIndividuals'), 'objectData should contain applicationIndividuals');
            System.assertEquals(true, lsr.objectData.containsKey('lstCaseIndividual'), 'objectData should contain lstCaseIndividual');
        }
    }
    
    public static testMethod void testGetCaseSelectionDataException(){
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.getCaseSelectionData('invalid_id');
        Test.stopTest();
        System.assertEquals(false, lsr.isSuccessful, 'getCaseSelectionData should fail with invalid ID');
    }
    
    public static testMethod void testHandleReferralCaseSelection(){
        User user;
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
            caseRec.DTE_APPLN__c = System.today().addDays(-14);
            update caseRec;
            T_APPLN_INDIV__c appindiv=new T_APPLN_INDIV__c();
            appIndiv.DTE_DOB__c=System.today()-30;
            appIndiv.NAM_FIRST__c='Testing';
            appIndiv.CDE_GENDER__c='1';
            appIndiv.NAM_LAST__c='IndividualC';
            appIndiv.NBR_SSN__c='12345675';
            appIndiv.IDN_STATE__c = '112233';
            appIndiv.IND_CRTKR_PRIM__c = 'N';
            appIndiv.IDN_APPLN__c =appProcessQueue.get(0).IDN_APPLN__c;
            insert appIndiv;
            insert new T_CBMS_ADDNL_INFO__c(IDN_CASE_CHATS__c = caseRec.Id, IDN_CASE_INTFC__c = 'test1', CDE_CAT_ACTIV__c = 'CMA', DTE_BEGIN_EFFEV__c = system.today(),DTE_END_EFFEV__c = system.today() +10);
            
            Test.startTest();
            LightningServerResponse lsr = APXCBMSReferralToCaseController.handleReferralCaseSelection(appProcessQueue.get(0).Id, caseRec.Id, new List<String>{appIndiv.Id});
            Test.stopTest();
            
            System.assertEquals(true, lsr.isSuccessful, 'handleReferralCaseSelection should be successful');
            System.assertEquals(true, lsr.objectData.containsKey('caseId'), 'objectData should contain caseId');
            T_APPLN_PRCS_QUEUE__c updatedQueue = [SELECT CDE_STATUS_APPLN__c, IDN_CASE__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id = :appProcessQueue.get(0).Id];
            System.assertEquals('PRC', updatedQueue.CDE_STATUS_APPLN__c, 'Status should be updated to PRC');
            System.assertEquals(caseRec.Id, updatedQueue.IDN_CASE__c, 'Case ID should be updated');
        }
    }
    
    public static testMethod void testHandleReferralCaseSelectionNullCase(){
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id FROM T_APPLN_PRCS_QUEUE__c];
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.handleReferralCaseSelection(appProcessQueue.get(0).Id, null, null);
        Test.stopTest();
        System.assertEquals(false, lsr.isSuccessful, 'handleReferralCaseSelection should fail with null case ID');
    }
    
    public static testMethod void testUpdateApplProcessQueue(){
        User user;
        Profile userProfile = [Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
            List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c, CDE_STATUS_APPLN__c FROM T_APPLN_PRCS_QUEUE__c];
            System.assertEquals(false, appProcessQueue.isEmpty(), 'appProcessQueue should not be empty');
            List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
            
            Test.startTest();
            LightningServerResponse lsr = APXCBMSReferralToCaseController.updateApplProcessQueue(appProcessQueue.get(0), caseRec.Id);
            Test.stopTest();
            
            System.assertEquals(true, lsr.isSuccessful, 'updateApplProcessQueue should be successful');
            T_APPLN_PRCS_QUEUE__c updatedQueue = [SELECT CDE_STATUS_APPLN__c, IDN_CASE__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id = :appProcessQueue.get(0).Id];
            System.assertEquals('PRC', updatedQueue.CDE_STATUS_APPLN__c, 'Status should be updated to PRC');
            System.assertEquals(caseRec.Id, updatedQueue.IDN_CASE__c, 'Case ID should be updated');
        }
    }
    
    public static testMethod void testUpdateApplProcessQueueNull(){
        List<T_COUNTY__c> counties = [SELECT Id FROM T_COUNTY__c];
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, counties.get(0).Id);
        Test.startTest();
        LightningServerResponse lsr = APXCBMSReferralToCaseController.updateApplProcessQueue(null, caseRec.Id);
        Test.stopTest();
        System.assertEquals(false, lsr.isSuccessful, 'updateApplProcessQueue should fail with null record');
        System.assertEquals(true, lsr.errorMessage.contains('should not be blank'), 'Error message should indicate blank record');
    }
    @isTest
    static void testNotifySIDMOD() {
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, System.today().addYears(-25), 'Test', '1', 'Individual', '123456789', 'CC');
        individual.IDN_STATE__c = '12345678';
        update individual;
        
        Test.startTest();        
        LightningServerResponse lsr1 = APXCBMSReferralToCaseController.notifySIDMOD('12345678', individual.Id, false);
        System.assertNotEquals(null, lsr1, 'Response should not be null');
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c LIMIT 1];
        if (!appProcessQueue.isEmpty()) {
            T_APPLN_INDIV__c appIndiv = TestClassUtility.createApplicationIndividual(true, System.today().addYears(-20), 'App', '2', 'Individual', '987654321', appProcessQueue[0].IDN_APPLN__c);
            appIndiv.IDN_STATE__c = '87654321';
            update appIndiv;
            LightningServerResponse lsr2 = APXCBMSReferralToCaseController.notifySIDMOD('87654321', appIndiv.Id, true);
            System.assertNotEquals(null, lsr2, 'Response should not be null');
        }        
        // Test with null values
        LightningServerResponse lsr3 = APXCBMSReferralToCaseController.notifySIDMOD(null, null, false);
        System.assertNotEquals(null, lsr3, 'Response should not be null');
        // Test with empty string
        LightningServerResponse lsr4 = APXCBMSReferralToCaseController.notifySIDMOD('', individual.Id, true);
        System.assertNotEquals(null, lsr4, 'Response should not be null');
        Test.stopTest();
    }
}