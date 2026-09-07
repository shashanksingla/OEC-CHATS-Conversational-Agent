@isTest(seeAllData=false)
public class Report304GeneratorBatch_Test {

    public static testMethod void testReport304GeneratorBatch(){
        Test.startTest();
        T_COUNTY__c county= TestClassUtility.createCounty('countyName', 'countyDepartmentName', 01, true);
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c();
        provider.Name = 'XYZ';
        provider.CDE_COUNTY_OWNER__c=county.Id;
        insert provider;
        T_PROVR_NOTES__c pronotes =new T_PROVR_NOTES__c();
        pronotes.ID_SERVICE__c=provider.Id;
        pronotes.CDE_TYPE_NOTES__c='1';
        pronotes.TXT_SUBJECT__c= 'Testing';
        pronotes.TXT_DESC_NOTES__c= 'TESTING DONE';
        insert pronotes;
        
        Canned_Report_Request__c request = new Canned_Report_Request__c();
        request.Report_Id__c='RE304';
        request.Status__c='INI'; 
        request.Request_Type__c='MAN';
        request.Report_Name__c = 'RE304 - Provider Notes Report';
        request.Request_Description__c='A report for a specific provider containing all provider notes for a given time period.';
        request.Report_Type__c='3';
        request.Date_Requested__c=System.now();
        
        insert request;
        
        Canned_Report_Request_Filter__c filter1= new Canned_Report_Request_Filter__c();
        filter1.Field__c='FromDate';
        filter1.Value__c=String.valueOf(System.today().addDays(-30));
        filter1.Canned_Report_Request__c=request.Id;
        insert filter1;
        
        Canned_Report_Request_Filter__c filter2= new Canned_Report_Request_Filter__c();
        filter2.Field__c='ToDate';
        filter2.Value__c=String.valueOf(System.today()+1);
        filter2.Canned_Report_Request__c=request.Id;
        insert filter2;
        
        Canned_Report_Request_Filter__c filter3= new Canned_Report_Request_Filter__c();
        filter3.Field__c='ProviderId';
        filter3.Value__c=provider.id;
        filter3.Canned_Report_Request__c=request.Id;
        insert filter3;
        
        Canned_Report_Request_Filter__c filter4= new Canned_Report_Request_Filter__c();
        filter4.Field__c='Provider_Note_Type__c';
        filter4.Value__c='1';
        filter4.Canned_Report_Request__c=request.Id;
        insert filter4;
        
        
        Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
        Database.executeBatch(new Report304GeneratorBatch(), 1);
        Test.stopTest();
        	
    }
	
    public static testMethod void testReport304GeneratorScheduler(){
        Canned_Report_Request__c request = new 	Canned_Report_Request__c();
        request.Report_Id__c='RE304';
        request.Status__c='INI'; 
        request.Request_Type__c='MAN';
        request.Report_Name__c = 'RE304 - Provider Notes Report';
        request.Request_Description__c='A report for a specific provider containing all provider notes for a given time period.';
        request.Report_Type__c='3';
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
        String batchName = 'RE304-Rpt-Gen';
        system.schedule(batchName, cronStr, new RE304GeneratorBatchScheduler());
        Test.stopTest();
    }
    
}