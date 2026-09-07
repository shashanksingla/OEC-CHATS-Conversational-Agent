@isTest
public class HerokuServiceTest {
    
    public static testmethod void testHerokuCallout() {
        Set<String> subPaymentDetailIdList = new Set<String>();
        subPaymentDetailIdList.add('test');
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        HerokuService.authEncubUpdateCareLevel();
        HerokuService.authStatusCreate();
        HerokuService.authCopayCreate();
        HerokuService.authCopayFetch();
        HerokuService.authCopayUpdate(); 
        HerokuService.subPaymentService(subPaymentDetailIdList, 'Claim');
        system.assertEquals(0,[select Id from batchsit_t_auth_status__x Limit 10].size(),'Zero rows should return');
        //HerokuService.authEncumbranceUpdate('[{"cde_Status_Encmbr":"8","idn_Auth":"a1fg0000001kMgQAAU","idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');
        //HerokuService.authCopayUpdate();
        //HerokuService.authCopayUpdate();
    }
    
    public static testmethod void testHerokuCallout1() {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, dob, 'firstName', '1', 'lastName', '123', 'CC');
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE__c case2 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        authorization.IDN_CASE__c= case1.Id;
        authorization.IDN_CLIENT__c= individual.Id;
        authorization.IDN_PROVR__c= provider.Id;
        insert authorization;
        List<EncumberenceWrapper> encumList = new List<EncumberenceWrapper>();
        List<EncumbranceEnrollWrapper> encumEnrollList = new List<EncumbranceEnrollWrapper>();
        
        EncumberenceWrapper  encumberence= new EncumberenceWrapper();
        encumberence.cde_Level_Care = '5';
        encumberence.cde_Status_Encmbr = '4';
        //encumberence.cde_Type_Unit_Care = encumberenceRec.cde_Type_Unit_Care__c;
        encumberence.cnt_Hour_Attnd_Actual = '0';
        encumberence.cnt_Hour_Care = '0';
        encumberence.idn_Auth = authorization.Id;
        encumberence.dte_Care = '2012-12-12';
        encumberence.createdbyid = 'test';
        encumberence.createddate = '2012-12-12 10:10:10';
        encumberence.nbr_Seq_Hist =  '1';
        encumberence.lastmodifieddate = '2012-12-12 10:10:10';
        encumberence.lastmodifiedbyid = 'test';
        encumberence.ind_0_36_months = 'N';
        encumList.add(encumberence);
        
        EncumbranceEnrollWrapper encumbEnroll = new EncumbranceEnrollWrapper();
        encumbEnroll.ind_0_36_months = 'Y';
        encumbEnroll.authId = authorization.Id;
        encumbEnroll.careDate = '2012-12-12';
        encumbEnroll.createdbyid = 'test';
        encumbEnroll.createddate = '2012-12-12 10:10:10';
        encumbEnroll.nbrSeqHist =  '1';
        encumbEnroll.lastmodifieddate = '2012-12-12 10:10:10';
        encumbEnroll.lastmodifiedbyid = 'test';
        encumEnrollList.add(encumbEnroll);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        HerokuService.authEncumbranceUpdate('[{"cde_Status_Encmbr":"8","idn_Auth":'+authorization.Id+',"idn_Encmbr_Auth":"33","lastmodifieddate":"2012-12-12 10:10:10","lastmodifiedbyid":"Salesforce"}]');
        HerokuService.authEncumbrancefetch('{"authId":'+authorization.Id+'}');
        //HerokuService.authEncumbranceEnrollfetch(authorization.Id);
        HerokuService.authEncumbranceCreate(encumList);
        //HerokuService.authEncumbranceEnrollCreate(encumEnrollList);
        HerokuService.caseCopyCreate('1','1','1','R','R','2012-12-12','2012-12-12','621003857','1','1','4','Y',true);
        HerokuService.caseCopyUpdate('1','1','1','R','R','2012-12-12','2012-12-12','621003857','1','1','4','Y','ExternalId');
        system.assertEquals(true,HerokuService.updateCaseParentFee('providerId').isSuccess);
        Test.stopTest();
    }
    
    public static testmethod void testHerokuCallout2() {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, dob, 'firstName', '1', 'lastName', '007', 'CC');
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE__c case2 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        authorization.IDN_CASE__c= case1.Id;
        authorization.IDN_CLIENT__c= individual.Id;
        authorization.IDN_PROVR__c= provider.Id;
        insert authorization; 
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        HerokuService.authCopayDelete(authorization.IDN_EXTNL__c, authorization.DTE_END_EFFV_AUTH__c,authorization.LastModifiedById);
        HerokuService.authEncumbranceDelete(authorization.IDN_EXTNL__c, authorization.DTE_END_EFFV_AUTH__c);
        //HerokuService.authEncumbranceEnrollDelete(authorization.IDN_EXTNL__c, authorization.DTE_END_EFFV_AUTH__c);
        HerokuService.getAmountPaidService(case1.Id, '1', '2022');
        Test.stopTest();
    }
    
    public static testmethod void testFiscalRateCallouts() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, '1234', system.today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        T_FISCAL_SCH__c fiscalSchedule = TestClassUtility.createRateSchedule(true, system.today(), null, fiscalAgreement.Id, '1');
        List<Id>fiscalScheduleIdLst = new List<Id>();
        fiscalScheduleIdLst.add(fiscalSchedule.Id);
        batchsit_t_fiscal_rate__x fiscalRate = new batchsit_t_fiscal_rate__x();
        fiscalRate.amt_fa__c= 10;
        fiscalRate.amt_provr__c= 15;
        fiscalRate.cde_age_group__c= '1';
        fiscalRate.cde_care_unit__c= '2';
        fiscalRate.cde_rate_type__c= '1';
        fiscalRate.idn_fiscal_sch__c = fiscalSchedule.Id;
        List<batchsit_t_fiscal_rate__x> lstFiscalRates = new List<batchsit_t_fiscal_rate__x>();
        lstFiscalRates.add(fiscalRate);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        system.assertEquals(true,HerokuService.fiscalRatefetch(fiscalScheduleIdLst).size()>0);
        system.assertEquals(true,HerokuService.createFiscalRateRecords(lstFiscalRates).isSuccess);
        system.assertEquals(true, HerokuService.deleteFiscalRateRecords(fiscalScheduleIdLst).isSuccess);
        Test.setMock(HttpCalloutMock.class, new HerokuServiceUnSuccessfullCalloutMock());
        system.assertEquals(false,HerokuService.fiscalRatefetch(fiscalScheduleIdLst).size()>0);
        system.assertEquals(false,HerokuService.createFiscalRateRecords(lstFiscalRates).isSuccess);
        system.assertEquals(false, HerokuService.deleteFiscalRateRecords(fiscalScheduleIdLst).isSuccess);
        Test.stopTest();
    }
    
    public static testmethod void testExceptionCallouts() {
        HerokuService.authEncubUpdateCareLevel();  
        HerokuService.authStatusCreate();
        HerokuService.authCopayCreate();
        HerokuService.authCopayFetch();
        HerokuService.authCopayUpdate();
        HerokuService.authEncumbranceCreate(new List<EncumberenceWrapper>());
        //HerokuService.authEncumbranceEnrollCreate(new List<EncumbranceEnrollWrapper>());
        HerokuService.authEncumbrancefetch('test');
        HerokuService.authEncumbranceUpdate('test');
        HerokuService.createFiscalRateRecords(new List<batchsit_t_fiscal_rate__x>());
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock2());
        HerokuService.authEncubUpdateCareLevel();
        HerokuService.authStatusCreate();
        HerokuService.authCopayCreate();
        HerokuService.authCopayFetch();
        HerokuService.authCopayUpdate();
        HerokuService.convertDateJSONToDate('/');
        HerokuService.authEncumbranceCreate(new List<EncumberenceWrapper>());
        //HerokuService.authEncumbranceEnrollCreate(new List<EncumbranceEnrollWrapper>());
        HerokuService.authEncumbrancefetch('test');
        //HerokuService.authEncumbranceEnrollfetch('test');
        Map<String, String> testMap=HerokuService.authEncumbranceUpdate('test');
        system.assertEquals(true, testMap.size()>0);
        HerokuService.createFiscalRateRecords(new List<batchsit_t_fiscal_rate__x>());
        HerokuService.subPaymentService(new set<string>(), 'Claim');
        HerokuService.getAmountPaidService('', null, null);
    }
    
    public class HerokuServiceHttpCalloutMock2 implements HttpCalloutMock {
        // Implement this interface method authEncumbrancefetch
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            if(request.getEndpoint().contains('AuthEncumbr/UpdateRecordsForCareLevel')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('AuthStatus/CreateRecord')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('AuthCopay/FetchRecords')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('AuthCopay/UpdateRecords')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('AuthEncumbr/CreateRecord')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('AuthEncumbr/FetchRecords')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('AuthEncumbr/UpdateRecord')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('SubpaymentDetail/UpdateExistingAdjustment')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('farates/create')){
                response.setStatusCode(100);
            }else if(request.getEndpoint().contains('CaseReview/GetSubsidyAmount')){
                response.setStatusCode(100);
            }
            return response; 
        }
    }
}