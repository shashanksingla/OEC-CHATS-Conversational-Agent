/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           06/25/2018                                                          
*  @description    Test class for ExceptionLoggingServices.
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Jun-2018                                                            
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: 
*  * 
*********************************************************************************************/
@isTest
public class ExceptionLoggingServicesTest {
    
    public static testMethod void testCaptureExceptionLog(){
        List<Exception_Log__c> xLogExistingRecords = [SELECT Id FROM Exception_Log__c];
        System.assertEquals(true, xLogExistingRecords.isEmpty(), 'xLogExistingRecords should be empty');
        Map<String, Object> methodInfo = new Map<String, Object>();
        methodInfo.put('Class__c','ExceptionLoggingServicesTest');
        methodInfo.put('Method__c','testCaptureExceptionLog');
        try{
            GenericDMLHandler.insertRecords(new List<SObject>{new T_SBSD_CASE_ADR__c()}, methodInfo);
            System.assert(true, 'Above line should throw exception, hence this line should not be executed');
        }catch(Exception ex){
            System.debug(ex);
            List<Exception_Log__c> xLogNewRecords = [SELECT Class__c,Method__c,Record_ID__c,Request__c,Response__c,Exception_Message__c,Exception_Type__c,Stack_Trace__c FROM Exception_Log__c];
            System.assertEquals(false, xLogNewRecords.isEmpty(), 'xLogNewRecords should not be empty');
            System.debug('Exception Log Records are:'+xLogNewRecords);
        }
    }
    
    public static testMethod void testCaptureExceptionLogWithSaveResults(){
        List<Exception_Log__c> xLogExistingRecords = [SELECT Id FROM Exception_Log__c];
        System.assertEquals(true, xLogExistingRecords.isEmpty(), 'xLogExistingRecords should be empty');
        Map<String, Object> methodInfo = new Map<String, Object>();
        methodInfo.put('Class__c','ExceptionLoggingServicesTest');
        methodInfo.put('Method__c','testCaptureExceptionLogWithSaveResults');
        List<DMLResult> lstDMLResult = GenericDMLHandler.insertRecords(new List<SObject>{new T_SBSD_CASE_ADR__c()}, false,methodInfo);
        System.debug('lstDMLResult:'+lstDMLResult);
        List<Exception_Log__c> xLogNewRecords = [SELECT Class__c,Method__c,Record_ID__c,Request__c,Response__c,Exception_Message__c,Exception_Type__c,Stack_Trace__c FROM Exception_Log__c];
        System.assertEquals(true, xLogNewRecords.isEmpty(), 'xLogNewRecords should not be empty');
        System.debug('Exception Log Records are:'+xLogNewRecords);
    }
    
    public static testMethod void testCaptureExceptionLogScenario1(){
        Map<String, Object> methodInfo = new Map<String, Object>();
        methodInfo.put('Class__c','ExceptionLoggingServicesTest');
        methodInfo.put('Method__c','testCaptureExceptionLog');
        methodInfo.put('Record_ID__c','test');
        try{
            insert new T_SBSD_INDIV__c();    
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
            System.assertEquals(1, [SELECT Count() FROM Exception_Log__c], 'One Exception log should have been created');
        }
        ExceptionLoggingServices.pIIDataInExceptionMsg = true;
        ExceptionLoggingServices.pIIDataInStackTrace = true;
        try{
            insert new T_SBSD_INDIV__c();    
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
            List<Exception_Log__c> xLogs = [SELECT Id, Class__c, Method__c, Exception_Type__c, Exception_Message__c, Stack_Trace__c, Request__c, Response__c, Record_ID__c, Environment__c, PII_Information__c FROM Exception_Log__c];
            System.assertEquals(2, xLogs.size(), 'Two Exception log should have been created');            
            ExceptionLoggingServices.captureExceptionLog(xLogs.get(0));
            System.assertEquals(3, [SELECT Count() FROM Exception_Log__c], 'Three Exception log should have been created');
        }
    }
    
    public static testMethod void testCaptureExceptionLogScenario2(){
        Map<String, Object> methodInfo = new Map<String, Object>();
        methodInfo.put('Class__c','ExceptionLoggingServicesTest');
        methodInfo.put('Method__c','testCaptureExceptionLog');
        methodInfo.put('Record_ID__c','test');
        List<Database.SaveResult> lstSaveResult = Database.insert(new List<SObject>{new T_SBSD_INDIV__c(NAM_FIRST__c='Sam',NAM_LAST__c='peter')},false);    
        ExceptionLoggingServices.captureExceptionLog(lstSaveResult, new List<SObject>{new T_SBSD_INDIV__c(NAM_FIRST__c='Sam',NAM_LAST__c='peter')}, methodInfo);
        System.assertEquals(0, [SELECT Count() FROM Exception_Log__c], 'As it\'s a validation error and should not be logged');
        
        ExceptionLoggingServices.pIIDataInExceptionMsg = true;
        ExceptionLoggingServices.pIIDataInStackTrace = true;
        lstSaveResult = Database.insert(new List<SObject>{new T_SBSD_INDIV__c(NAM_FIRST__c='Sam',NAM_LAST__c='peter')},false);    
        ExceptionLoggingServices.captureExceptionLog(lstSaveResult, new List<SObject>{new T_SBSD_INDIV__c(NAM_FIRST__c='Sam',NAM_LAST__c='peter')}, null);
        System.assertEquals(0, [SELECT Count() FROM Exception_Log__c], 'As it\'s a validation error and should not be logged');
        
    }
    
    public static testMethod void testCaptureExceptionLogScenario3(){
        Map<String, Object> methodInfo = new Map<String, Object>();
        methodInfo.put('Class__c','ExceptionLoggingServicesTest');
        methodInfo.put('Method__c','testCaptureExceptionLog');
        methodInfo.put('Record_ID__c','test');
        HttpRequest req = new HttpRequest();
        req.setBody('[{"authCopayExternalId":"123456","childName":"John Doe","authorizationId":"1550","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-15","authorizationEndDate":"2020-08-31","allocatedAuthAmount":"10","authCopayId":"12345","authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tLxEAI"},{"childName":"John Doe","authorizationId":"1556","dateofBirth":"1987-04-02","providerId":"1222","providerName":"Test Provider","authorizationBeginDate":"2018-08-28","authorizationEndDate":"2020-08-31","allocatedAuthorizationAmount":"0.0","authCopayId":null,"authCopayBeginDate":null,"authCopayEndDate":null,"individualId":"G651582","authExternalId":"a1Am00000023tUOEAY"}]');
        req.setMethod('get');
        req.setEndpoint('blahblah.com');
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"errorMessage":"some error"}');
        res.setStatusCode(200);
        ExceptionLoggingServices.captureExceptionLog(res, req, methodInfo);
        System.assertEquals(1, [SELECT Count() FROM Exception_Log__c], 'One Exception Log should have been created');
        ExceptionLoggingServices.pIIDataInResponse = true;
        ExceptionLoggingServices.pIIDataInRequest = true;
        ExceptionLoggingServices.pIIDataInExceptionMsg = true;
        ExceptionLoggingServices.captureExceptionLog(res, req, methodInfo);
        System.assertEquals(2, [SELECT Count() FROM Exception_Log__c], 'One Exception Log should have been created');
        
    }
    
    public static testMethod void testCaptureExceptionLogScenario4(){
        String t1 = 'mq1PaheMoAN724yarKz2cuhJ8dgPVLIL7ZygL1M7II10zih8NRFW0KQm2YOLL8U1udQK4I8R1tIuE2xHi3KTzZrJztL0ZhIoBQDK4W7biRX8lxMI35YTWP2TCU7Wdb5lzr3Q';
        String text='';
        for(Integer i=0;i<1000;i++){
            text+=t1;                
        }            
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c=text;
        xLog.Exception_Message__c = text;
        xLog.Exception_Type__c = text;
        xLog.Method__c = text;
        xLog.Record_ID__c = text;
        xLog.Request__c = text;
        xLog.Response__c = text;
        xLog.Stack_Trace__c = text;
        xLog.PII_Information__c = text;
        xLog = ExceptionLoggingServices.trimXLogData(xLog);
        System.assertEquals(true, xLog.Method__c.length()<51, 'Method length should have been substringed');
    }
    
    @testSetup
    public static void doSetupData(){
        Exception_Logging_Framework_Settings__c exceptionFrameworkSetting = new Exception_Logging_Framework_Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_Exception_Log__c = true);
        insert exceptionFrameworkSetting;
        
    }
}