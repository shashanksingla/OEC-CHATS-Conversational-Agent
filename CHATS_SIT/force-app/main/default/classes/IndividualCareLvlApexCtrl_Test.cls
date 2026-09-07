@isTest(seeAllData=false)
public class IndividualCareLvlApexCtrl_Test {
    static T_SBSD_INDIV__c obj = new T_SBSD_INDIV__c();
    static T_AUTH__c authObj = new T_AUTH__c();
    public static T_SBSD_INDIV__c sbsdIndiv = new T_SBSD_INDIV__c();
    public static void testDataSetup(){
        List<SObject> sobjects = new List<SObject> ();
        List<batchsit_t_sbsd_indiv_care_level__x> indivList = new  List<batchsit_t_sbsd_indiv_care_level__x>();
        batchsit_t_sbsd_indiv_care_level__x x = new batchsit_t_sbsd_indiv_care_level__x();
         batchsit_t_sbsd_indiv_care_level__x z = new batchsit_t_sbsd_indiv_care_level__x();
        x.idn_sbsd_indiv_care_level__c = 12;
        x.cde_level_care__c = '8';
        x.dte_begin_effv__c= System.today();
        x.createdbyid__c = UserInfo.getUserId();
        x.ExternalId ='test';
        
         z.idn_sbsd_indiv_care_level__c = 12;
        z.cde_level_care__c = '8';
        z.dte_begin_effv__c= System.today().addYears(-11);
        z.createdbyid__c = UserInfo.getUserId();
        z.ExternalId ='test';
        
                
         batchsit_t_sbsd_indiv_care_level__x y = new batchsit_t_sbsd_indiv_care_level__x();
        y.idn_sbsd_indiv_care_level__c = 13;
        y.cde_level_care__c = '7';
        y.createdbyid__c = UserInfo.getUserId();
        y.dte_begin_effv__c= System.today();
        y.ExternalId ='test';

        indivList.add(x);
         indivList.add(y);
        
        obj =TestClassUtility.createIndividual(true,System.today(),'first','1','last','123','CC');
        T_COUNTY__c  countyObj =TestClassUtility.createCounty('Test','PEN',1,true);
        T_CHATS_PROVR_STATUS__c provObj = TestClassUtility.createProvider(true,'Test');
        authObj =TestClassUtility.createAuthorization(true,System.today(),System.today(),countyObj.Id,provObj.Id);
        x.idn_client__c =  obj.Id;
        x.lastmodifiedbyid__c =UserInfo.getUserId();
        sobjects.add(x);
        //BG Temp Fix
        Date datetoday=System.Today();
        
        
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'first','1','last','123','CC');
         sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstNameA','1','lastNameA','1','CC');
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,countyObj.Id);
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today().addYears(4);
        sbsdcase.IDN_EXTNL__c='12345';
        upsert sbsdcase;
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,countyObj.Id,provObj.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.CDE_TYPE_VERIF__c = 'NA';
        authorization.CDE_SOURCE_VRFYD_IMMU__c ='PRO';
        authorization.CDE_IMM__c ='NRL';
        insert authorization;
        IndividualCareLvlApexCtrl.encumbranceUpdate('TEST',null);
        IndividualCareLvlApexCtrl.fetchAuthEncumbrance('TEST');
        IndividualCareLvlApexCtrl.authEncumbranceUpdate('TEST');
        
            
    }
    static testmethod  void testgetIndividualCareLvls(){
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        testDataSetup();
        Boolean isError;
        List<batchsit_t_sbsd_indiv_care_level__x> indCareLvl;
        Id indivId;
        String message;
        Test.startTest();
        IndividualCareLvlApexCtrl.getIndividualCareLvls(obj.Id);
        IndividualCareLvlApexCtrl.indivCareLevelWrapper wrap = new IndividualCareLvlApexCtrl.indivCareLevelWrapper( isError, indCareLvl, message, indivId);
        system.assertEquals(null,wrap.message,'Message should be null');
         Test.stopTest();
    }
    static testmethod  void testgetIndividualCareLvls_Scneriao2(){
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        Boolean isError;
        List<batchsit_t_sbsd_indiv_care_level__x> indCareLvl;
        Id indivId;
        String message;
        Test.startTest();
        IndividualCareLvlApexCtrl.fetchAuthEncumbrance('test');
        IndividualCareLvlApexCtrl.authEncumbranceUpdate('test');
        Test.stopTest();
    }
    static testmethod  void testgetIndividualCareLvls_Scneriao7(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Boolean isError;
        List<batchsit_t_sbsd_indiv_care_level__x> indCareLvl;
        Id indivId;
        String message;
        Test.startTest();
        IndividualCareLvlApexCtrl.authEncumbranceUpdate('test');
        IndividualCareLvlApexCtrl.fetchAuthEncumbrance('test');
        Test.stopTest();
    }
    static testmethod  void testgetIndividualCareLvls_Scneriao1(){
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock()); 
        Test.startTest();
        IndividualCareLvlApexCtrl.encumbranceUpdate('TEST',null);
        Test.stopTest();
    }
    static testmethod  void testgetIndividualCareLvls_Scneriao3(){
        testDataSetup();
        Test.startTest();
        IndividualCareLvlApexCtrl.insertATSRecord(sbsdIndiv.Id);
        Test.stopTest();
    }
    static testmethod  void testgetIndividualCareLvls_Scneriao4(){
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock());
        List<batchsit_t_sbsd_indiv_care_level__x> indivList = new  List<batchsit_t_sbsd_indiv_care_level__x>();
         batchsit_t_sbsd_indiv_care_level__x x = new batchsit_t_sbsd_indiv_care_level__x();
         batchsit_t_sbsd_indiv_care_level__x z = new batchsit_t_sbsd_indiv_care_level__x();
        x.idn_sbsd_indiv_care_level__c = 12;
        x.cde_level_care__c = '8';
        x.dte_begin_effv__c= System.today();
        x.createdbyid__c = UserInfo.getUserId();
        x.ExternalId ='test';
        
         z.idn_sbsd_indiv_care_level__c = 12;
        z.cde_level_care__c = '8';
        z.dte_begin_effv__c= System.today().addYears(-11);
        z.createdbyid__c = UserInfo.getUserId();
        z.ExternalId ='test';
        
                
         batchsit_t_sbsd_indiv_care_level__x y = new batchsit_t_sbsd_indiv_care_level__x();
        y.idn_sbsd_indiv_care_level__c = 13;
        y.cde_level_care__c = '7';
        y.createdbyid__c = UserInfo.getUserId();
        y.dte_begin_effv__c= System.today();
        y.ExternalId ='test';
		Id indivId = 'a2Am0000001VeqY';
        indivList.add(x);
         indivList.add(y);
        Test.startTest();
        IndividualCareLvlApexCtrl.validateIndCareLst(indivId,indivList);
        Test.stopTest();
    }
     static testmethod  void testgetIndividualCareLvls_Scneriao5(){
        Test.setMock(HttpCalloutMock.class, new UpdateParentFeeApxCtrlMock());
        List<batchsit_t_sbsd_indiv_care_level__x> indivList = new  List<batchsit_t_sbsd_indiv_care_level__x>();
         batchsit_t_sbsd_indiv_care_level__x x = new batchsit_t_sbsd_indiv_care_level__x();
         batchsit_t_sbsd_indiv_care_level__x z = new batchsit_t_sbsd_indiv_care_level__x();
        x.idn_sbsd_indiv_care_level__c = 12;
        x.cde_level_care__c = '7';
        x.dte_begin_effv__c= System.today();
        x.createdbyid__c = UserInfo.getUserId();
        x.ExternalId ='test';
        
         z.idn_sbsd_indiv_care_level__c = 12;
        z.cde_level_care__c = '8';
        z.dte_begin_effv__c= System.today().addDays(-10);
        z.createdbyid__c = UserInfo.getUserId();
        z.ExternalId ='test';
        
                
         batchsit_t_sbsd_indiv_care_level__x y = new batchsit_t_sbsd_indiv_care_level__x();
        y.idn_sbsd_indiv_care_level__c = 13;
        y.cde_level_care__c = '7';
        y.createdbyid__c = UserInfo.getUserId();
        y.dte_begin_effv__c= System.today();
        y.ExternalId ='test';
		Id indivId = 'a2Am0000001VeqY';
        indivList.add(x);
         indivList.add(y);
         indivList.add(z);
        Test.startTest();
        IndividualCareLvlApexCtrl.validateIndCareLst(indivId,indivList);
        Test.stopTest();
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //res.setBody('{"example":"test"}');
            res.setBody('[{"cde_Level_Care":"1892","cde_Type_Unit_Care":"8",errMessage":"Test","successInd":"Y"},{"authCopayId":"1893","errMessage":"Test","successInd":"Y"}]');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }
}