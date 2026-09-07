/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           04/05/2018                                                          
*  @description    TEST CLASS for Report803GeneratorBatch                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 09-JUL-2020                                                             
*  * Author: Sahil Garg                                                    
*  * Description: Initial version

*********************************************************************************************/
@isTest(seeAllData=false)
public class Report803GeneratorBatch_Test {

    public static testMethod void testReport803GeneratorBatch(){
        
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c();
        provider.Name = 'XYZ';
        insert provider;
        
        Canned_Report_Request__c request = new 	Canned_Report_Request__c();
        request.Report_Id__c='RE803';
        request.Status__c='INI'; // CCCAP-1548
        request.Request_Type__c='MAN';
        request.Report_Name__c = 'RE803 - Attendance Report';
        request.Request_Description__c='A report that represents a record of the daily sign in/out method (ATS) containing date, the child�s name, the time child arrived/left and the signature/PIN of the parent/guardian/authorized person';
        request.Report_Type__c='1';
        request.Date_Requested__c=System.now();
        
        insert request;
        
        Canned_Report_Request_Filter__c filter1= new Canned_Report_Request_Filter__c();
        filter1.Field__c='FromDate';
        filter1.Value__c=String.valueOf(System.today().addDays(-30));
        filter1.Canned_Report_Request__c=request.Id;
        insert filter1;
        
        Canned_Report_Request_Filter__c filter2= new Canned_Report_Request_Filter__c();
        filter2.Field__c='ToDate';
        filter2.Value__c=String.valueOf(System.today());
        filter2.Canned_Report_Request__c=request.Id;
        insert filter2;
        
        Canned_Report_Request_Filter__c filter3= new Canned_Report_Request_Filter__c();
        filter3.Field__c='ProviderID';
        filter3.Value__c=provider.id;
        filter3.Canned_Report_Request__c=request.Id;
        insert filter3;
        
        Canned_Report_Request_Filter__c filter4= new Canned_Report_Request_Filter__c();
        filter4.Field__c='ProviderName';
        filter4.Value__c='XYZ';
        filter4.Canned_Report_Request__c=request.Id;
        insert filter4;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
        Database.executeBatch(new Report803GeneratorBatch(), 1);
        Test.stopTest();
        	
    }
	
    public static testMethod void testReport803GeneratorScheduler(){
        Canned_Report_Request__c request = new 	Canned_Report_Request__c();
        request.Report_Id__c='RE803';
        request.Status__c='INI'; // CCCAP-1548
        request.Request_Type__c='MAN';
        request.Report_Name__c = 'RE803 - Attendance Report';
        request.Request_Description__c='A report that represents a record of the daily sign in/out method (ATS) containing date, the child�s name, the time child arrived/left and the signature/PIN of the parent/guardian/authorized person';
        request.Report_Type__c='1';
        request.Date_Requested__c=System.now();
        
        insert request;
        
        Canned_Report_Request_Filter__c filter1= new Canned_Report_Request_Filter__c();
        filter1.Field__c='FromDate';
        filter1.Value__c=String.valueOf(System.today().addDays(-30));
        filter1.Canned_Report_Request__c=request.Id;
        insert filter1;
        
        Canned_Report_Request_Filter__c filter2= new Canned_Report_Request_Filter__c();
        filter2.Field__c='ToDate';
        filter2.Value__c=String.valueOf(System.today());
        filter2.Canned_Report_Request__c=request.Id;
        insert filter2;
        Test.startTest();	
        Datetime dt = Datetime.now().addMinutes(5);
        String cronStr = '0 ' +  dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month()+ ' ? ' + dt.year();
        system.debug(cronStr);
        String batchName = 'RE803-Rpt-Gen';
        system.schedule(batchName, cronStr, new RE803GeneratorBatchScheduler());
        Test.stopTest();
    }
    
}