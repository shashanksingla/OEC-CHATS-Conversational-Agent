@isTest
public class CHATSAuraUtility_Test {
    
    static testmethod  void testfetchLoggedInUserId(){
        Test.startTest();
        system.assertEquals(UserInfo.getUserId(),CHATSAuraUtility.fetchLoggedInUserId(),'Should return logged in User Id');
        Test.stopTest();
    }

    public static testmethod  void testGetDataFromWebService(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        LightningServerResponse lsr = CHATSAuraUtility.getDataFromWebService(System.Label.AUTH_ENCUMBR_FETCH_COUNTY, 'POST', '', new List<String>{'count'});
        system.assertEquals(true,lsr.isSuccessful);
    }
    
    public static testmethod  void testGetSobjectName(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test', 'Dept', 1, true);
        String sObjectName = CHATSAuraUtility.getSObjectName(county.Id);
        system.assertEquals(sObjectName ,'T_COUNTY__c', 'sObject Name should be T_COUNTY__c');
    }
    
    public static testmethod  void fetchLoggedInProfileId_Test(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test', 'Dept', 1, true);
        T_SBSD_CASE__c sbsdcase = TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c ='12345'; // Dont Change the value
        upsert sbsdcase;
        batchsit_t_sbsd_case_cmt__x caseComm = new batchsit_t_sbsd_case_cmt__x();
        caseComm.idn_case__c = sbsdcase.IDN_EXTNL__c;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        
        System.runAs(user){
            LightningServerResponse res = CHATSAuraUtility.fetchLoggedInProfileId(caseComm.Id);
            System.assertEquals(res.objectData.get('profileName') ,'System Administrator');
        }        
    }
    
    public static testmethod  void getCaseOrCaseCommentObjectAPI_Test(){
        T_COUNTY__c county = TestClassUtility.createCounty('Test', 'Dept', 1, true);
        T_SBSD_CASE__c sbsdcase = TestClassUtility.createCase(false,county.Id);
        sbsdcase.IDN_EXTNL__c ='12345'; // Dont Change the value
        upsert sbsdcase;
        batchsit_t_sbsd_case_cmt__x caseComm = new batchsit_t_sbsd_case_cmt__x();
        caseComm.idn_case__c = sbsdcase.IDN_EXTNL__c;
        
        LightningServerResponse res = CHATSAuraUtility.getCaseOrCaseCommentObjectAPI(caseComm.Id, 'true');
        LightningServerResponse res2 = CHATSAuraUtility.getCaseOrCaseCommentObjectAPI(caseComm.Id, 'false');
        LightningServerResponse res3 = CHATSAuraUtility.getCaseOrCaseCommentObjectAPI(sbsdcase.Id, 'true');
        LightningServerResponse res4 = CHATSAuraUtility.getCaseOrCaseCommentObjectAPI(sbsdcase.Id, 'false');
        
        System.assertEquals(res.isSuccessful, true);
        System.assertEquals(res2.isSuccessful, true);
        System.assertEquals(res3.isSuccessful, true);
        System.assertEquals(res4.isSuccessful, true);
    }
    
    public static testmethod  void checkOwnerCountyMatch_Test(){
        Date nullDate;
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),datetoday.day());
        begindate = begindate.addDays(-5);
        String begDate = String.valueOf(begindate);
        Date enddate = begindate.addDays(20);
        
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false, county.Id);
        sbsdcase.IDN_EXTNL__c='12345';
        sbsdcase.DTE_REDET_CASE__c = begindate;
        upsert sbsdcase;
        
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,nullDate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.IDN_EXTNL__c='123';
        authorization.AMT_ACTV_AUTH__c =1;
        authorization.AMT_TRANSP_AUTH__c =11;
        insert authorization;
        
        T_SBSD_CASE_STATUS_MODE__c caseStatus = new T_SBSD_CASE_STATUS_MODE__c();
        caseStatus.CDE_STATUS_CASE__c = 'CLS';
        caseStatus.IDN_CASE__c = sbsdcase.Id;
        insert caseStatus;
        
        String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'FA1', begindate, county.Id);
        fiscalAgreement.RecordtypeId = openRecordTypeId;
        fiscalAgreement.CDE_TYPE_STATUS__c = 'OPN';
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        fiscalAgreement.DTE_RCV_AGRMT_FISCAL__c = begindate;
        fiscalAgreement.DTE_END_AGRMT__c = nullDate;
        insert fiscalAgreement;
        
        T_FISCAL_SCH__c fiscalRateSch = TestClassUtility.createRateSchedule(false, begindate, null, fiscalAgreement.Id, '1');
        fiscalRateSch.DTE_END_EFFV__c = nullDate;
        fiscalRateSch.IDN_AGRMT_FISCAL__c = fiscalAgreement.Id;
        insert fiscalRateSch;
        
        CHATSAuraUtility.checkOwnerCountyMatch(authorization.Id,'CDE_COUNTY__c');
        CHATSAuraUtility.checkOwnerCountyMatch(sbsdcase.Id,'CDE_COUNTY__c');
        String hoursPerWeekDay = '[{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"0"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"8"},{"CDE_TYPE_UNIT_CARE__c":"1","CNT_HOUR_CARE__c":"0"}]';
        CHATSAuraUtility.careLevelOfferedByProvider(authorization.Id, authorization.Id, begDate, provider.Id, sbsdIndiv.Id, hoursPerWeekDay);
        CHATSAuraUtility.careLevelOfferedByProvider(sbsdcase.Id, sbsdcase.Id, begDate, provider.Id, sbsdIndiv.Id, hoursPerWeekDay);
    }
}