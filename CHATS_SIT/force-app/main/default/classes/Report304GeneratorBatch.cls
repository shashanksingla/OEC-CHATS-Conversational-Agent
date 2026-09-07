/*************************************************************
Class Name	    - Report304GeneratorBatch
Test Class	    - Report304GeneratorBatch_Test
Description     - Batch Class for RE304 -- Provider Notes Report
Author          - Pragyan P Nayak
JIRA Id			- CCCAP - 3225
**************************************************************/
global class Report304GeneratorBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{ 
    global final String reportName;
    global final String status;
    
    global  Report304GeneratorBatch(){
        this.reportName = 'RE304 - Provider Notes Report';
        this.status = 'INI';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id,Name,createddate FROM Canned_Report_Request__c WHERE Report_Name__c =:reportName AND Status__c =:status');
    }
    
    global void execute(Database.BatchableContext BC, List<Canned_Report_Request__c> zCannedReportRequests){
        
        for(Canned_Report_Request__c canReportReq: zCannedReportRequests){
            
            String cannedReportId = canReportReq.Id;
            List<Canned_Report_Request_Filter__c> filterList = [SELECT Id, Value__c, Field__c,Canned_Report_Request__r.County__c, Canned_Report_Request__c FROM Canned_Report_Request_Filter__c WHERE Canned_Report_Request__c =:cannedReportId];
            if(filterList.isEmpty()) continue;
            Map<String, String> paramsMap = new Map<String,String>();
            String countyCode;
            for(Canned_Report_Request_Filter__c filterObj : filterList){
                countyCode =filterObj.Canned_Report_Request__r.County__c;
                if(filterObj.Field__c == 'ProviderId' || filterObj.Field__c == 'ToDate' ||filterObj.Field__c == 'FromDate' ||filterObj.Field__c == 'Provider_Note_Type__c' ){
                    paramsMap.put(filterObj.Field__c, filterObj.Value__c);
                }
            }
            String providerId = paramsMap.get('ProviderId');          
            String toDate = paramsMap.get('ToDate');
            String fromDate = paramsMap.get('FromDate');
            List<String> beginDateArr = new List<String>();
            List<String> endDateArr = new List<String>();
            Date requestBeginDate; 
            datetime requestEndDate;
            List<Id> countyIds = new List<Id>();
            if(String.isNotBlank(countyCode) && countyCode!='66'){
                //Added by Nikita for CCCAP-9539
                String[] countyCodes = countyCode.split(';');
                List<Decimal> countyCodeList = new List<Decimal>(); 
                for(String c : countyCodes){
                    countyCodeList.add(Decimal.valueOf(c));
                }
                List<T_COUNTY__c> countyList = [Select id from T_COUNTY__c where CDE_COUNTY__c in :countyCodeList];
                if(countyList != null && countyList.size()>0){
                    for(T_COUNTY__c county : countyList){
                        countyIds.add(county.Id);
                    }
                }
            }
            if(String.isNotBlank(fromDate)){
                beginDateArr= fromDate.split('-');
            }
            if(String.isNotBlank(toDate)){
                endDateArr= toDate.split('-');
            }
            if(beginDateArr.size()>2  ){
                requestBeginDate = Date.newInstance(Integer.valueOf(beginDateArr[0]), Integer.valueOf(beginDateArr[1]), Integer.valueOf(beginDateArr[2]));
            }
            if( endDateArr.size()>2 ){
                requestEndDate = datetime.newInstance(Integer.valueOf(endDateArr[0]), Integer.valueOf(endDateArr[1]), Integer.valueOf(endDateArr[2]),23,59,59);
            }
            String noteType = paramsMap.get('Provider_Note_Type__c');
            T_CHATS_PROVR_STATUS__c  providerObj;
            List<T_PROVR_NOTES__c> providerNoteLst;
            String finalProviderParam='';
            if(paramsMap.get('ProviderId') != null){
                providerObj = [Select Id, Name from T_CHATS_PROVR_STATUS__c where Id=:providerId Limit 1];
                String queryStr ='Select id,Name,IDN_EXTNL__c,CreatedDate,County__c,CreatedBy.Common_County__c,LastModifiedDate,toLabel(CDE_TYPE_NOTES__c),TXT_SUBJECT__c,TXT_DESC_NOTES__c,CreatedById,ID_SERVICE__c,ID_SERVICE__r.CDE_COUNTY_OWNER__c from T_PROVR_NOTES__c where ID_SERVICE__c=:providerId ';
                if(paramsMap.get('Provider_Note_Type__c') != null){
                    queryStr+= ' AND CDE_TYPE_NOTES__c =:noteType';
                }
                if(requestBeginDate != null){
                    queryStr+= ' AND CreatedDate >=:requestBeginDate';
                }
                if(requestEndDate != null){
                    queryStr+= ' AND CreatedDate <=:requestEndDate';
                }
                if(countyIds != null && countyIds.size()>0 && countyCode!='66'){
                    queryStr+= ' AND County__c IN :countyIds';
                }
                providerNoteLst = DataBase.query(queryStr);
            }
            
            String reportJsonBody = '';
            
            reportJsonBody += '[{"cannedReportId":"'+cannedReportId+'",';
            reportJsonBody += '"data":[';
            if(providerNoteLst != null && providerNoteLst.size()>0){
                for(T_PROVR_NOTES__c providerNoteObj:providerNoteLst){
                    String subjectStr ='';
                    String subjectOutput ='';
                    String noteDescStr ='';
                    String noteDescOutput ='';
                    if(providerNoteObj.TXT_SUBJECT__c != null){
                        subjectStr =providerNoteObj.TXT_SUBJECT__c;
                        Blob beforeblob = Blob.valueOf(subjectStr);
                        subjectOutput = EncodingUtil.base64Encode(beforeblob);
                    }if(providerNoteObj.TXT_DESC_NOTES__c !=null){
                        noteDescStr =providerNoteObj.TXT_DESC_NOTES__c;
                        Blob beforeblobNote = Blob.valueOf(noteDescStr);
                        noteDescOutput = EncodingUtil.base64Encode(beforeblobNote);
                    }
                    reportJsonBody += '{"externalId":"' + (providerNoteObj.Name == null? '' : String.valueOf(providerNoteObj.Name))  + '",' ;
                    reportJsonBody += '"createDate":"' + (providerNoteObj.CreatedDate == null? '' : String.valueOf(providerNoteObj.CreatedDate.format('yyyy-MM-dd hh:mm a')))  + '",' ;
                    reportJsonBody += '"lastModDate":"' + (providerNoteObj.LastModifiedDate == null? '' : String.valueOf(providerNoteObj.LastModifiedDate.format('yyyy-MM-dd hh:mm a')))  + '",' ;
                    reportJsonBody += '"county":"' + (providerNoteObj.County__c == null? '' : String.valueOf(providerNoteObj.County__c))  + '",' ;
		            reportJsonBody += '"noteType":"' + (providerNoteObj.CDE_TYPE_NOTES__c == null? '' : String.valueOf(providerNoteObj.CDE_TYPE_NOTES__c))  + '",' ;
                    reportJsonBody += '"subject":"' + (subjectOutput == null? '' : subjectOutput)  + '",' ;
                    reportJsonBody += '"note":"' + (noteDescOutput == null? '' : noteDescOutput)  + '",' ;
                    reportJsonBody += '"createdByUser":"' + (providerNoteObj.CreatedById == null? '' : String.valueOf(providerNoteObj.CreatedById))  + '"' ;
                    reportJsonBody += '},';
                }
            }                
            reportJsonBody = reportJsonBody.removeEnd(',');
            reportJsonBody += ']}]';
            
            //SEND TO API CALL
            
            String report304apiEndpoint = Label.RE304_Generator_API_Endpoint;
            Http http = new Http();
            Httprequest request = new Httprequest();
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setMethod('POST');
            request.setEndpoint(report304apiEndpoint);
            request.setBody(reportJsonBody);
            
            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
            request.setTimeout(timeOutVal);
            HttpResponse response;
            
              try{
				if(!Test.isRunningTest()){
						response = http.send(request);
				}
                if(response == null || response.getStatusCode() != 200){
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'Report304GeneratorBatch';
                    xLog.Method__c = 'Execute';
                    if (response != null) {
                        xLog.Exception_Message__c = 'Status is :' + response.getStatus() + ',Status Code is :' + String.valueOf(response.getStatusCode());
                        if (response.getStatusCode() != null) {
                            xLog.Exception_Type__c = 'Web Service';
                        }
                        xLog.Response__c = response.getBody();
                    }
                    if (response != null) {
                        xLog.Request__c = 'End point:' + request.getEndpoint() + ':' + response.getBody();
                    }
                    ExceptionLoggingServices.captureExceptionLog(xLog); 
                }
                
            }catch(Exception ex){
                Exception_Log__c xLog = new Exception_Log__c();
                xLog.Class__c = 'Report304GeneratorBatch';
                xLog.Method__c = 'Execute';
                xLog.Exception_Message__c = 'API Callout failure';
                xLog.Request__c = report304apiEndpoint;
                xLog.Response__c = 'null';
                ExceptionLoggingServices.captureExceptionLog(xLog); 
            }
            
            try {
                if(response != null && response.getStatusCode() == 200){
                    Canned_Report_Request__c canRptReq = new Canned_Report_Request__c();
                    canRptReq.id = cannedReportId;
                    canRptReq.Status__c = 'REQ';
                    update canRptReq;
                }
            } catch (Exception ex){
                Exception_Log__c xLog = new Exception_Log__c();
                xLog.Class__c = 'Report304GeneratorBatch';
                xLog.Method__c = 'Execute';
                xLog.Exception_Message__c = 'INI -> REQ status update failure';
                xLog.Request__c = report304apiEndpoint;
                xLog.Response__c = 'null';
                ExceptionLoggingServices.captureExceptionLog(xLog); 
            }
            
            
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
}