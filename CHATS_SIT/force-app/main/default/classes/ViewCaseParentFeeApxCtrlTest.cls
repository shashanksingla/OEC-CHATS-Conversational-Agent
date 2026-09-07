@isTest
public class ViewCaseParentFeeApxCtrlTest {
    
    public static testMethod void testUpdateParentFeeDataSuccess(){
        String caseParentFeeAllocationsJSON = '[{"authCopayExternalId":"123456","childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"10","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"},{"childName":"John Doe","authorizationId":"1556","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-28","authorizationEndDate":"2020-08-31","allocatedAuthorizationAmount":"0.0","authCopayId":null,"authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tUOEAY"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.updateParentFeeData(caseParentFeeAllocationsJSON,'2',2015);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateParentFeeDataError(){
        String caseParentFeeAllocationsJSON = '[{"authCopayExternalId":"123456","childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":null,"authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.updateParentFeeData(caseParentFeeAllocationsJSON,'2',2015);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateParentFeeDataError2(){
        String caseParentFeeAllocationsJSON = '[{"authCopayExternalId":"123456","childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"123","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.updateParentFeeData(caseParentFeeAllocationsJSON,'2',2015);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateParentFeeDataException(){
        String caseParentFeeAllocationsJSON = '[{"authCopayExternalId":"123456","childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"abc","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.updateParentFeeData(caseParentFeeAllocationsJSON,'2',2015);
        Test.stopTest();
    }
    
    public static testMethod void testCreateParentFeeDataSuccess(){
        String caseParentFeeAllocationsJSON = '[{"childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"10","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"},{"childName":"John Doe","authorizationId":"1556","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-28","authorizationEndDate":"2020-08-31","allocatedAuthorizationAmount":"0.0","authCopayId":null,"authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tUOEAY"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.createParentFeeData(caseParentFeeAllocationsJSON,JSON.serialize(System.today()),'3',2015);
        Test.stopTest();
    }
    
    public static testMethod void testCreateParentFeeDataError(){
        String caseParentFeeAllocationsJSON = '[{"childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":null,"authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.createParentFeeData(caseParentFeeAllocationsJSON,JSON.serialize(System.today()),'2',2016);
        Test.stopTest();
    }
    
    public static testMethod void testCreateParentFeeDataError2(){
        String caseParentFeeAllocationsJSON = '[{"childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"123","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.createParentFeeData(caseParentFeeAllocationsJSON,JSON.serialize(System.today()),'3',2017);
        Test.stopTest();
    }
    
    public static testMethod void testCreateParentFeeDataException(){
        String caseParentFeeAllocationsJSON = '[{"childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"abc","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.createParentFeeData(caseParentFeeAllocationsJSON,JSON.serialize(System.today()),'2',2015);
        Test.stopTest();
    }
    
    public static testMethod void testDeleteParentFeeDataSuccess(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.deleteParentFeeData('999');
        Test.stopTest();
    }
    
    public static testMethod void testDeleteParentFeeDataError(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.deleteParentFeeData('123');
        Test.stopTest();
    }
    
    public static testMethod void testDeleteParentFeeDataException(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
        ViewCaseParentFeeApxCtrl.deleteParentFeeData('456');
        Test.stopTest();
    }
    
    public static testMethod void getParentFeeData(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        List<T_SBSD_CASE__c> casRec = [Select Id from T_SBSD_CASE__c Limit 1];
        LightningServerResponse lsr;
        if(casRec.size()>0) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
            lsr = ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, '1', 2018,null);
            Test.stopTest();
        }
    }
    
    public static testMethod void getParentFeeDataWithoutParentFeeAllocation(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        List<T_SBSD_CASE__c> casRec = [Select Id from T_SBSD_CASE__c Limit 1];
        LightningServerResponse lsr;
        if(casRec.size()>0) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
            lsr = ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, '2', 2018,null);
            Test.stopTest();
        }
    }
    
    public static testMethod void getParentFeeDataMonthCustomError(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        List<T_SBSD_CASE__c> casRec = [Select Id from T_SBSD_CASE__c Limit 1];
        if(casRec.size()>0) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
            ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, 'abc', 2018,null);
            Test.stopTest();
            delete casRec;
            ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, '1', 2018,null);
        }
    }
    
    public static testMethod void getParentFeeDataMonthError(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        List<T_SBSD_CASE__c> casRec = [Select Id from T_SBSD_CASE__c Limit 1];
        if(casRec.size()>0) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
            ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, 'error', 2018,null);
            Test.stopTest();
        }
        
    }
    public static testMethod void getParentFeeDataMonthException(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        List<T_SBSD_CASE__c> casRec = [Select Id from T_SBSD_CASE__c Limit 1];
        if(casRec.size()>0) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CallSearchParentFeeWSMockup());
            ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, 'parsingerror', 2018,null);
            Test.stopTest();
        }
    }
    
    public static testMethod void webServiceCalloutException(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        List<T_SBSD_CASE__c> casRec = [Select Id from T_SBSD_CASE__c Limit 1];
        if(casRec.size()>0) {
            Test.startTest();
            ViewCaseParentFeeApxCtrl.getParentFeeData(casRec.get(0).id, 'parsingerror', 2018,null);
            ViewCaseParentFeeApxCtrl.deleteParentFeeData('999');
            String caseParentFeeAllocationsJSON = '[{"childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"abc","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
            ViewCaseParentFeeApxCtrl.createParentFeeData(caseParentFeeAllocationsJSON,JSON.serialize(System.today()),'6',2015);
            String caseParentFeeAllocationsJSON2 = '[{"authCopayExternalId":"123456","childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"123","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"}]';
            ViewCaseParentFeeApxCtrl.updateParentFeeData(caseParentFeeAllocationsJSON2,'3',2015);
            Test.stopTest();
        }
    }
    
}