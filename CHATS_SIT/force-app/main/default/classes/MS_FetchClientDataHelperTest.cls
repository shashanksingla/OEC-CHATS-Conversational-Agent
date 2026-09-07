@isTest
public class MS_FetchClientDataHelperTest {
    @testSetup
    public static void prepareData(){
        Triggers_On_Off_Settings__c triggerOnOffRec= new Triggers_On_Off_Settings__c(Name='CaseTrigger',Active__c=false);
        Triggers_On_Off_Settings__c triggerOnOffRecIndiv= new Triggers_On_Off_Settings__c(Name='IndividualTrigger',Active__c=false);
        Triggers_On_Off_Settings__c triggerOnOffRecApp= new Triggers_On_Off_Settings__c(Name='applicationPrcsQueueTrigger',Active__c=false);
        
        
        insert new List<Triggers_On_Off_Settings__c>{triggerOnOffRec,triggerOnOffRecIndiv,triggerOnOffRecApp};
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(true, System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CC');
        Individual_E_mail__c emailRecord = new Individual_E_mail__c(
            Individual__c = indivRec.Id,
            Email_Information__c = 'test@info.com'
        );
        insert emailRecord;
        T_COUNTY__c countyObj = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseObj = TestClassUtility.createCase(true, countyObj.Id);
        TestClassUtility.createCaseIndividual(true, caseObj.Id, indivRec.Id,true);
        T_APPLN_CASE__c applnCaseRec = new T_APPLN_CASE__c(IDN_APPLN__c = 12345,CDE_INFO_EM__c='test@info.com');
        T_APPLN_CASE__c applnCaseRec1 = new T_APPLN_CASE__c(IDN_APPLN__c = 54321,CDE_INFO_EM__c='test@info.com');
        
        insert new List<T_APPLN_CASE__c>{applnCaseRec,applnCaseRec1};
            
            T_APPLN_PRCS_QUEUE__c applnPrcsQueueRec = new T_APPLN_PRCS_QUEUE__c(IDN_APPLN_COMPASS__c = 12345,
                                                                                IDN_Case__c=caseObj.Id,
                                                                                CDE_SOURCE__c ='PK',
                                                                                DTE_RCVD_APPLN__c = system.today(),
                                                                                IDN_APPLN__c=applnCaseRec.Id);
        T_APPLN_PRCS_QUEUE__c applnPrcsQueueRec1 = new T_APPLN_PRCS_QUEUE__c(IDN_APPLN_COMPASS__c = 54321,
                                                                             CDE_SOURCE__c ='CB',
                                                                             DTE_RCVD_APPLN__c = system.today(),
                                                                             IDN_APPLN__c=applnCaseRec1.Id);
        
        insert new list<T_APPLN_PRCS_QUEUE__c>{applnPrcsQueueRec,applnPrcsQueueRec1};
    }
    @isTest
    static void testGetClientInfoByEmail() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://example.com/getClientInfo';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serializePretty(new Map<String,String>{'email_id'=> 'test@info.com'}));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        List<UFE_ResponseWrapper> response = MS_FetchClientData.getClientInfobyPost();
        Test.stopTest();
    }
    @isTest
    static void testGetClientInfoByCaseId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://example.com/getClientInfo';
        req.httpMethod = 'POST';
        List<T_SBSD_Case__c> cases = [select id from T_SBSD_Case__c limit 1];
        req.requestBody = Blob.valueOf(JSON.serializePretty(new Map<String,String>{'id'=> cases[0].Id,'iType'=>'case'}));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        List<UFE_ResponseWrapper> response = MS_FetchClientData.getClientInfobyPost();
        Test.stopTest();
    }
    @isTest
    static void testGetClientInfoByAppId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'https://example.com/getClientInfo';
        req.httpMethod = 'POST';
        Id appId = [select id from T_APPLN_CASE__c limit 1]?.Id;
        req.requestBody = Blob.valueOf(JSON.serializePretty(new Map<String,String>{'id'=> appId,'iType'=>'application'}));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        List<UFE_ResponseWrapper> response = MS_FetchClientData.getClientInfobyPost();
        Test.stopTest();
    }
}