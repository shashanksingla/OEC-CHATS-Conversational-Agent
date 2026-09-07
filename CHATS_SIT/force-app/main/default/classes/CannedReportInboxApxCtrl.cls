public with sharing class CannedReportInboxApxCtrl {
    
    public static Integer noOfRetryAttempts = 0;
    public static Integer totalRetryAttemptsAllowed = 20;
    public static string url {get; set;}
    
    @AuraEnabled 
    public static User fetchUser(){
        User u = [select id,Name from User where id =: userInfo.getUserId()];
        return u ;
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitReportRequestData(String reportType){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        Date todayDate = system.today();
        Date todayMinus30Days = system.today().addDays(-30);
        objectData.put('todayDate',todayDate);
        objectData.put('todayMinus30Days',todayMinus30Days);
        User u = fetchUser();
        objectData.put('user', u );
        List<String> reportTypeResult = getReportType();
        objectData.put('reportTypeResult',reportTypeResult);
        List<String> reportTypeName = getAllReportName();
        objectData.put('reportTypeName',reportTypeName);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse processViewResults(String county, String reportType, String reportName, String requestedBy, String requestStatus, Date beginDtae, Date endDate){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        String soql, soqlSelect, soqlOrderBy, soqlcount;
        List<Canned_Report_Request__c> searchResult = new List<Canned_Report_Request__c>(); 
        List<String> countyLst = new List<String>();
        List<String> beginDateArr = new List<String>();
        List<String> endDateArr= new List<String>();
        soqlSelect = 'select id,Name, Report_Id__c,IDN_EXTNL__c, toLabel(Status__c), toLabel(County__c), toLabel(Report_Type__c), Report_Name__c, Request_Description__c, User__c,User__r.Name,CreatedBy.Name,Date_Requested__c, Failure_Reason__c,Date_Generated__c from Canned_Report_Request__c where ';
        soqlcount = 'select count() from Canned_Report_Request__c where ';
        soql = 'id != null';
        
        if (String.isNotBlank(county)){
            countyLst = county.split(';');
            soql += ' AND County__c INCLUDES(';
            for(String includeValue :countyLst)
                soql +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
            soql = soql.removeEnd(',') +')';
        }
        if ((String.isNotBlank(reportType)) && reportType != ''){
            soql += ' AND Report_Type__c = ';
            soql += '\''+String.escapeSingleQuotes(reportType)+'\'';
        }
        if ((String.isNotBlank(reportName)) && reportName != '--None--'){
            soql += ' AND Report_Name__c LIKE ';
            soql += '\'%'+String.escapeSingleQuotes(reportName)+'%\'';
        }   
        if ( String.isNotBlank(requestedBy)){
            requestedBy =String.escapeSingleQuotes(requestedBy);
            soql += ' AND User__c =:requestedBy ';
        }
        if (String.isNotBlank(requestStatus)){
            requestStatus =String.escapeSingleQuotes(requestStatus);
            soql += ' AND Status__c =:requestStatus ';
            //soql += ' AND Status__c LIKE ';
            //soql += '\'%'+requestStatus +'%\'';
        }
        if (beginDtae!= null){
            Date requestBeginDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(beginDtae)));
            DateTime fromDateTime = datetime.newInstanceGmt(requestBeginDate.year(), requestBeginDate.month(),requestBeginDate.day());
            date fromDate = fromDateTime.dateGMT();
            soql += ' AND DAY_ONLY(convertTimezone(Date_Requested__c)) >= :fromDate ';
        }
        if (endDate!= null){
            Date requestEndDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(endDate)));
            DateTime toDateTime = datetime.newInstanceGmt(requestEndDate.year(), requestEndDate.month(),requestEndDate.day()+1,system.now().hourGmt(),system.now().minuteGmt(),system.now().secondGmt());
            date toDate = toDateTime.dateGMT();
            soql += ' AND DAY_ONLY(convertTimezone(Date_Requested__c)) < :toDate ';
        }
        soqlOrderBy = ' Order By Date_Requested__c desc LIMIT 201';
        searchResult = Database.query(soqlSelect + soql + soqlOrderBy);
        objectData.put('test',searchResult);
        return new LightningServerResponse(isSuccessful,message,objectData); 
    }
    
    @AuraEnabled
    public static List<String> getReportName(String reportType){
        List<String> reportTypeResult = new List<String>();
        Set<String> reportTypeResultSet = new Set<String>();
        List<Canned_Report__mdt> res;
        if(reportType == ''|| reportType == null){
            res = [SELECT Id, Report_Name__c FROM Canned_Report__mdt WHERE Is_Active__c = true ORDER BY Report_Name__c ];
        }else{
            res = [SELECT Id, Report_Name__c FROM Canned_Report__mdt WHERE Report_Type__c =: reportType AND Is_Active__c = true ORDER BY Report_Name__c];
        }      
        if(res!= null && res.size()>0){
            for(Canned_Report__mdt name : res){
                reportTypeResultSet.add(name.Report_Name__c);
            } 
        }
        reportTypeResult.addAll(reportTypeResultSet);
        return reportTypeResult;  
    }
    
    @AuraEnabled
    public static List<String> getAllReportName(){
        List<String> reportTypeResult = new List<String>();
        Set<String> reportTypeResultSet = new Set<String>();
        List<Canned_Report__mdt> res = [select Id, Report_Name__c from Canned_Report__mdt order by Report_Name__c];
        if(res.size()>0){
            for(Canned_Report__mdt name : res){
                reportTypeResultSet.add(name.Report_Name__c);
            } 
        }
        reportTypeResult.addAll(reportTypeResultSet);
        return reportTypeResult;  
    }
    
    @AuraEnabled
    public static List<String> getReportType(){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<String> reportTypeResult = new List<String>();
        Schema.DescribeFieldResult fieldResult = Canned_Report_Request__c.Report_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Set<String> countyOptionMap = new Set<String>();
        for( Schema.PicklistEntry f : ple){
            countyOptionMap.add(f.getLabel());
        }
        reportTypeResult.addAll(countyOptionMap);
        return reportTypeResult;  
    }
    
    @auraEnabled(cacheable=true)
    public static String geReportFromAWS(String fileName){
        String reportStrConvertedBlob = '';
        if(noOfRetryAttempts<totalRetryAttemptsAllowed){
            try{
                Blob blobResponse;
                string responseString;
                //String fileName1 = System.currentPageReference().getParameters().get('fileName');
                //fileName = fileName1;
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('POST');
                String url = Label.correspondenceTargetPdfServlet + 'pathInAws=Reports/Canned/output'+'&fileName=' + fileName;
                String myBase64String = EncodingUtil.base64Encode(Blob.valueOf(Label.AEMAuthenticationCredentials));
                request.setHeader('Authorization', 'Basic '+ myBase64String);
                request.setEndpoint(url);
                Integer timeOutVal = Integer.valueOf(System.Label.AEMWebServiceTimeOut);
                request.setTimeout(timeOutVal);
                HttpResponse response = http.send(request);
                //System.debug(response.getStatusCode()+':'+response.getBody());
                if (response <> null && response.getStatusCode() == 200 && response.getBody()!=null) {
                    blobResponse = response.getBodyAsBlob();
                    reportStrConvertedBlob = EncodingUtil.base64Encode(blobResponse);
                    noOfRetryAttempts = 0;
                }else{
                    noOfRetryAttempts++;
                    geReportFromAWS(fileName);
                }
            } catch (exception e){
                noOfRetryAttempts++;
                geReportFromAWS(fileName);
            }
        }else{
            reportStrConvertedBlob = 'File does not exist.';
        }
        return reportStrConvertedBlob;
    }
    
    @AuraEnabled
    public static LightningServerResponse getReportResponse(String fileName) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        try{
            String jsonBody = '{"requestId": "' + fileName + '"}';
            url = Label.PSSPWebserviceReports;
            HttpRequest req = new HttpRequest(); 
            req.setMethod('POST');
            req.setbody(jsonBody);
            req.setHeader('content-type', 'application/json');
            req.setEndpoint(url);
            req.settimeout(30000);
            Http http = new Http(); 
            HTTPResponse response = http.send(req);
            System.debug('!!!!!!!!!!!!!!!!!!!!!!!!!! URL with ID ' + url);
            if(!string.valueOf(response.getStatusCode()).startsWith('2')){
                /*
                Map<String,Object > ls = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Exception_Log__c xLog = new Exception_Log__c();
                xLog.Class__c = 'CannedReportInboxApxCtrl';
                xLog.Method__c = 'getReportResponse';
                if(ls.containsKey('errors')) {
                    xLog.Exception_Message__c = string.valueOf(ls.get('errors'));
                }
                ExceptionLoggingServices.captureExceptionLog(xLog);
                
                system.debug('THIS IS MAP LS ' + ls);
				*/
                message = Label.Canned_Report_Download_Error_Msg;
            } else {
                try {
                    //List<Object> ls = (List<Object>)JSON.deserializeUntyped(body);
                    Map<String,Object > m = (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); //re is response body string.....changed re to body
                    if(m.containsKey('reportIdUrl')) {
                        objectData.put('reportIdUrl',string.valueOf(m.get('reportIdUrl')));
                        new LightningServerResponse(true,'Got Report',objectData);
                        // return string.valueOf(m.get('reportIdUrl'));
                    }
                }catch(Exception e){
                    isSuccessful = false;
                    message = Label.Canned_Report_Download_Error_Msg;
                }
            }
        }
        catch(Exception exp){
            isSuccessful = false;
            message = Label.Canned_Report_Download_Error_Msg;
        }
        return new LightningServerResponse(true,message,objectData);
    }
}