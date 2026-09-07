/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           7/25/2018                                                          
*  @description    Test class for Health Check Controller                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Jul-2018                                                             
*  * Author: Vineet Srivastava                                                      
*  * Description: Initial version 
*********************************************************************************************/
@isTest
public class HealthCheckControllerTest {
    
    public static testmethod void testcheckGetService(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        String service = HealthCheckController.checkGetService('healthcheckendpoint');
        system.assert(service!=null,'service should not be null');
    }
    
    public static testmethod void testcheckService(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        Integer service = HealthCheckController.checkService('json','healthcheckendpoint','GET');
        system.assert(service!=null,'service should not be null');
    }
    
    public static testmethod void testsearchCorr(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        String corr = HealthCheckController.searchCorr('county','healthcheckendpoint','GET');
        system.assert(corr!=null,'corr should not be null');
    }
    
    public static testmethod void testfetchAuthEncmbr(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        Integer devStatus= HealthCheckController.fetchAuthEncmbr('Authid','healthcheckendpoint','GET');
        system.assert(devStatus!=null,'devStatus should not be null');
    }
    
    public static testmethod void testfetchAuthCopay(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        Integer devStatus= HealthCheckController.fetchAuthCopay('CaseID','healthcheckendpoint','GET');
        system.assert(devStatus!=null,'devStatus should not be null');     
    }
    
    public static testmethod void testfetchCounty(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        Integer devStatus=HealthCheckController.fetchCounty('CountryId','healthcheckendpoint','GET');
        system.assert(devStatus!=null,'devStatus should not be null');
    }
    
    public static testmethod void testgetChartData(){
        Map<String,String> test=new Map<String,String>();
        Map<String,Map<String,String>>  heathReportMap=new Map<String,Map<String,String>>(); 
        test.put('test','test');
        heathReportMap.put('test',test);
        Map<String,String> chartDataMap= HealthCheckController.getChartData('Env' ,heathReportMap);
        system.assert(chartDataMap!=null,'chartDataMap should not be null');
    }
    
    public static testmethod void testgetWebserviceStatus(){
        MockHttpResponseGenerator mockHttpResponseGenerator=new MockHttpResponseGenerator();
        test.setMock(HttpCalloutMock.class, mockHttpResponseGenerator);
        Map<String,Map<String,String>> webServiceStatusMap = HealthCheckController.getWebserviceStatus();
        system.assert(webServiceStatusMap!=null,'webServiceStatusMap should not be null');
    }
    
}