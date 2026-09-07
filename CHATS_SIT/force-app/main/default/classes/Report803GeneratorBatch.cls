// CCCAP-1548
global class Report803GeneratorBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    
    global final String reportName;
    global final String status;
    global final String reportId;
    
    global  Report803GeneratorBatch(){
        this.reportName = 'RE803 - Attendance Report';
        this.status = 'INI';
        this.reportId = null;
    }
    
    global  Report803GeneratorBatch(String reportId){
        this.reportName = 'RE803 - Attendance Report';
        this.status = 'INI';
        this.reportId = reportId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('IN START');
        String query;
        if(!String.isBlank(reportId)){
            query = 'SELECT Id,Name,createddate FROM Canned_Report_Request__c WHERE Name =:reportId';
        } else {
            query = 'SELECT Id,Name,createddate FROM Canned_Report_Request__c WHERE Report_Name__c =:reportName AND Status__c =:status';
        }
        System.debug('Report803GeneratorBatch: query : ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Canned_Report_Request__c> zCannedReportRequests){
        System.debug('========== (0) Report803GeneratorBatch: <<Heap>> Total Size : ' + Limits.getLimitHeapSize());
        System.debug('========== (1) Report803GeneratorBatch: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
        // Schedule delay in Mins
        Integer scheduleDelayInMins = 5; // Default
        String r803generatorScheduleDelayInMins = Label.RE803_Generator_Schedule_Delay_In_Mins;
        if(String.isNotBlank(r803generatorScheduleDelayInMins) && r803generatorScheduleDelayInMins.isNumeric()) {
            scheduleDelayInMins = Integer.valueOf(r803generatorScheduleDelayInMins);
        }
        for(Canned_Report_Request__c canReportReq: zCannedReportRequests){
            String cannedReportId = canReportReq.Id;
            // X mins Delay
            Boolean isCreateddateGreaterThanXmins = true;
            DateTime startDate = canReportReq.createddate;
            Datetime endDate = Datetime.now();
            integer intDays =  startDate.Date().daysBetween(endDate.Date());
            DateTime sameDayEndDate;
            decimal decMinutes;
            if(intDays < 1) {
                sameDayEndDate = startDate.addDays(intDays);
                decMinutes = ((endDate.getTime())/1000/60) - ((sameDayEndDate.getTime())/1000/60);
                if (decMinutes < scheduleDelayInMins) {
                    isCreateddateGreaterThanXmins = false;
                }   
            }
            if(Test.isRunningTest()){
                isCreateddateGreaterThanXmins = true;
            }
            if(!isCreateddateGreaterThanXmins) continue;
            List<Canned_Report_Request_Filter__c> filterList = [SELECT Id, Value__c, Field__c, Canned_Report_Request__c FROM Canned_Report_Request_Filter__c WHERE Canned_Report_Request__c =:cannedReportId];
            if(filterList.isEmpty()) continue;
            system.debug('IN HERE');
            system.debug(filterList.size());
            Map<String, String> paramsMap = new Map<String,String>();
            for(Canned_Report_Request_Filter__c filterObj : filterList){
                if(filterObj.Field__c == 'CaseId' || filterObj.Field__c == 'ToDate' || filterObj.Field__c == 'FromDate' || filterObj.Field__c == 'ProviderID' || filterObj.Field__c == 'IsPending'){
                    system.debug('INSERT INTO PARAMETER MAP');
                    paramsMap.put(filterObj.Field__c, filterObj.Value__c);
                }
            }
            system.debug('PARAMS MAP::' + paramsMap );
            String providerId = paramsMap.get('ProviderID');
            String caseId = paramsMap.get('CaseId');
            String fromDate = paramsMap.get('FromDate');
            String toDate = paramsMap.get('ToDate');
            String isPending = paramsMap.get('IsPending'); // Added by Rishav for CCCAP-5186
            T_CHATS_PROVR_STATUS__c  providerObj;
            T_SBSD_CASE__c  caseObj;
            String finalProviderParam='';
            String finalCaseParam='';
            if(paramsMap.get('ProviderID') != null){
                providerObj = [Select Id, Name from T_CHATS_PROVR_STATUS__c where Id=:providerId Limit 1];
                finalProviderParam = providerObj.Name;
            }
            if(paramsMap.get('CaseId') != null){
                caseObj = [Select Id, Name from T_SBSD_CASE__c where Id =:caseId Limit 1];   
                finalCaseParam = caseObj.Name;
            }
            Map<String,Object> retMap ;
            System.debug('========== (2) Report803GeneratorBatch: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
            if(Test.isRunningTest()) {
                retMap= new Map<String,Object>();
                retMap.put('lstTransaction1', new List<Transaction_c__x>{new Transaction_c__x(CI_Transaction_Time_c__c=System.now())});
                retMap.put('lstTransaction2', new List<Transaction_c__x>{new Transaction_c__x(CI_Transaction_Time_c__c=System.now())});
            } else {
                retMap = AttendanceSearchApxCtrl.getAttendanceResultsFor803Report(finalProviderParam, finalCaseParam, null, fromDate, toDate, isPending);
            }
            system.debug('FINAL RETURNED MAP ');
            system.debug(retMap);
            System.debug('========== (3) Report803GeneratorBatch: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
            String reportJsonBody = '';
            List<Transaction_c__x> finalList = new List<Transaction_c__x>();
            if(retMap != null){
                List<Transaction_c__x> list1 = (List<Transaction_c__x>) retMap.get('lstTransaction1');
                if(list1 != null){
                    for(Transaction_c__x transObj1:list1 ){
                        system.debug('INSIDE THE FOR LOOP!');
                        system.debug(transObj1.Id);
                        finalList.add(transObj1);
                    } 
                }
                List<Transaction_c__x> list2 = (List<Transaction_c__x>) retMap.get('lstTransaction2');
                if(list2 != null){
                    for(Transaction_c__x transObj2 : list2){
                        system.debug('HERE!');
                        finalList.add(transObj2);
                    }
                }
            }
            System.debug('========== (4) Report803GeneratorBatch: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
            system.debug('finalList.size()::' + finalList.size());
            reportJsonBody += '[{"cannedReportId":"' + cannedReportId + '",';
            if(finalList.size() > 0){
                reportJsonBody += '"data":[';
                for(Transaction_c__x transObj : finalList){
                    reportJsonBody += '{"transactionDate":"' ;
                    if(transObj.CI_Transaction_Time_c__c != null) {
                        reportJsonBody += String.valueOf(transObj.CI_Transaction_Time_c__c).split(' ')[0] + '",';
                    } else {
                        reportJsonBody += '"",';
                    }
                    reportJsonBody += '"providerId":"' + (transObj.Reporting_Provider_Id_c__c == null? '' : String.valueOf(transObj.Reporting_Provider_Id_c__c))  + '",' ;
                    reportJsonBody += '"childName":"' + (transObj.Reporting_Child_Name_c__c == null? '' : String.valueOf(transObj.Reporting_Child_Name_c__c)) + '",';
                    reportJsonBody += '"transactionType":"' + (transObj.Record_Type_Name_c__c == null? '' : String.valueOf(transObj.Record_Type_Name_c__c)) + '",';
                    reportJsonBody += '"transactionStatus":"' + (transObj.Status_c__c == null? '' : String.valueOf(transObj.Status_c__c)) + '",';
                    reportJsonBody += '"transactionTime":"';
                    if(transObj.CI_Transaction_Time_c__c != null) {
                        reportJsonBody += String.valueOf(transObj.CI_Transaction_Time_c__c.format('yyyy-MM-dd hh:mm a')) + '",';
                    } else {
                        reportJsonBody += '",' ;
                    }
                    reportJsonBody += '"creationSource":"' + String.valueOf(transObj.Creation_Source_c__c)+'",';
                    reportJsonBody += '"createdBy":"' + (transObj.Transaction_Created_By_Name__c == null? '' : String.valueOf(transObj.Transaction_Created_By_Name__c))+'",';
                    // Start: Modified below logic by Rishav for CCCAP-5186
                    if(transObj.Creation_Source_c__c == 'Parent' || (transObj.Creation_Source_c__c != 'Parent' && transObj.Status_c__c == 'PARENT_PENDING')){
                        reportJsonBody += '"approvalDateTime":"';
                        reportJsonBody += '",';
                        reportJsonBody += '"parentName":"';
                        reportJsonBody += '",';
                    } else {
                        reportJsonBody += '"approvalDateTime":"';
                        if(transObj.LastModifiedDate__c != null){
                            String a_time = String.valueOf(transObj.LastModifiedDate__c.format('yyyy-MM-dd hh:mm a'));
                            reportJsonBody += String.valueOf(a_time);
                            reportJsonBody += '",';
                        } else {
                            reportJsonBody += '",';
                        }
                        reportJsonBody += '"parentName":"';
                        reportJsonBody += String.valueOf(transObj.Reporting_Parent_Caretaker_Name_c__c);
                        reportJsonBody += '",';
                    }
                    /*
                    reportJsonBody += '"approvalDateTime":"';
                    if(transObj.LastModifiedDate__c != null) {
                        String a_time = String.valueOf(transObj.LastModifiedDate__c.format('yyyy-MM-dd hh:mm a'));
                        reportJsonBody += (transObj.Status_c__c == 'PARENT_APPROVED' && transObj.Creation_Source_c__c != 'Parent')? String.valueOf(a_time): '' ;
                        reportJsonBody += '",';
                    } else {
                        reportJsonBody += '",';
                    }
                    reportJsonBody += '"parentName":"';
                    reportJsonBody += transObj.Creation_Source_c__c  != 'Parent' ? String.valueOf(transObj.Reporting_Parent_Caretaker_Name_c__c ) : '';
                    reportJsonBody += '",';
                    */
                    // End: CCCAP-5186
                    reportJsonBody += '"elvCoreFlag":"';
                    reportJsonBody += (transObj.API_Flag_c__c == true)? 'Y':'N';
                    reportJsonBody += '"},';
                }
                reportJsonBody = reportJsonBody.removeEnd(',');
                reportJsonBody += ']}]';
                system.debug('JSON GENERATED');
                system.debug(reportJsonBody);
                System.debug('========== (5) Report803GeneratorBatch: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
                //SEND TO API CALL
                String report803apiEndpoint = Label.RE803_Generator_API_Endpoint;
                Http http = new Http();
                Httprequest request = new Httprequest();
                request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                request.setMethod('POST');
                request.setEndpoint(report803apiEndpoint);
                request.setBody(reportJsonBody);
                Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
                request.setTimeout(timeOutVal);
                HttpResponse response;
                try {
                    if(!Test.isRunningTest()){
                        response = http.send(request);
                    }
                    system.debug('RESPONSE IS:' + response);
                    if(response == null || response.getStatusCode() != 200){
                        Exception_Log__c xLog = new Exception_Log__c();
                        xLog.Class__c = 'Report803GeneratorBatch';
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
                } catch(Exception ex) {
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'Report803GeneratorBatch';
                    xLog.Method__c = 'Execute';
                    xLog.Exception_Message__c = 'API Callout failure';
                    xLog.Request__c = report803apiEndpoint;
                    xLog.Response__c = 'null';
                    ExceptionLoggingServices.captureExceptionLog(xLog); 
                }
                // CCCAP-1548
                try {
                    if(response != null && response.getStatusCode() == 200){
                        // Initialized 'INI' => Request 'REQ'
                        // Update status to 'REQ'. The Heruko batch will pick up this canned report and generate report.
                        Canned_Report_Request__c canRptReq = new Canned_Report_Request__c();
                        canRptReq.id = cannedReportId;
                        canRptReq.Status__c = 'REQ';
                        update canRptReq;
                    }
                } catch (Exception ex){
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'Report803GeneratorBatch';
                    xLog.Method__c = 'Execute';
                    xLog.Exception_Message__c = 'INI -> REQ status update failure';
                    xLog.Request__c = report803apiEndpoint;
                    xLog.Response__c = 'null';
                    ExceptionLoggingServices.captureExceptionLog(xLog); 
                }
            } else {
                System.debug('**** No RE803 Data to sent to atsreport transws');
                try {
                    // Initialized 'INI' => Request 'REQ'
                    // Update status to 'REQ'. The Heruko batch will pick up this canned report and generate report.
                    Canned_Report_Request__c canRptReq = new Canned_Report_Request__c();
                    canRptReq.id = cannedReportId;
                    canRptReq.Status__c = 'REQ';
                    update canRptReq;
                } catch (Exception ex){
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'Report803GeneratorBatch';
                    xLog.Method__c = 'Execute';
                    xLog.Exception_Message__c = 'INI -> REQ status update failure';
                    xLog.Request__c = Label.RE803_Generator_API_Endpoint;
                    xLog.Response__c = 'null';
                    ExceptionLoggingServices.captureExceptionLog(xLog); 
                }
            } 
        }
        System.debug('========== (6) Report803GeneratorBatch: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}