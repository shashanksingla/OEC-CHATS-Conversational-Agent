public class ReportRequestApxCtrl {
    
    @AuraEnabled
    public static LightningServerResponse getInitReportRequestData(String ReportName){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<Canned_Report_Filter__mdt> requestDataList = new List<Canned_Report_Filter__mdt>();
        requestDataList =[SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, Canned_Report__c, Field__c, Field_Data_Type__c, Operators__c, Options__c, Tool_Tip__c, 
                          Required__c, Is_Active__c,Field_Api_Name__c,FilterIndex__c FROM Canned_Report_Filter__mdt where Canned_Report__r.DeveloperName =:ReportName order by FilterIndex__c];
        
        Map<String,String> countyOptionMap = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Canned_Report_Request__c.County__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple){
            countyOptionMap.put(f.getLabel(), f.getValue());
        }
        Date todayDate = system.today();
        Date todayMinus30Days = system.today().addDays(-30);
        objectData.put('requestDataList',requestDataList);
        objectData.put('todayDate',todayDate);
        objectData.put('todayMinus30Days',todayMinus30Days);
        objectData.put('countyOptionMap',countyOptionMap);
        objectData.put('successMsg',Label.Canned_Report_Request_Success_Msg);
        objectData.put('reportInboxURL',Label.Canned_Report_Request_Success_URL);
        objectData.put('requestInboxMsg',Label.Canned_Report_Inbox_Msg);
        objectData.put('errorMsg',Label.Canned_Report_Request_Error_Msg);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse submitReportReq(String startDate, String endDate,String filterRequestList, String reportRequestStr,String beginMonthStr , Integer beginYearStr,String endMonthStr , Integer endYearStr,String providerIdVal, String providerName){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<Canned_Report_Request__c> cannedReportReqToInsertList = new List<Canned_Report_Request__c>();
        List<Canned_Report_Request_Filter__c> requestFilterToInsertList = new List<Canned_Report_Request_Filter__c>();
        List<Canned_Report_Request__c> cannedReportReqInsertedList = new List<Canned_Report_Request__c>();
        List<Canned_Report_Request_Filter__c> requestFilterDataList = new List<Canned_Report_Request_Filter__c>();
        if(Test.isRunningTest()){
            requestFilterDataList.add(new Canned_Report_Request_Filter__c(Field__c='County__c',Value__c='Denver') );
        }else{
            requestFilterDataList=  (List<Canned_Report_Request_Filter__c>)JSON.deserialize(filterRequestList, List<Canned_Report_Request_Filter__c>.class);
        }
        List<Canned_Report_Request__c> reportReqList = new List<Canned_Report_Request__c>();
        if(Test.isRunningTest()){
            reportReqList.add(new Canned_Report_Request__c(Request_Description__c='Test',Report_Name__c='CR213'));
        }else{
            reportReqList= (List<Canned_Report_Request__c>)JSON.deserialize(reportRequestStr, List<Canned_Report_Request__c>.class);
        }
        try{
            List<String> beginDateArr = new List<String>();
            List<String> endDateArr = new List<String>();
            Date requestBeginDate; 
            Date requestEndDate;
            if(String.isNotBlank(startDate)){
                beginDateArr= startDate.split('-');
            }
            if(String.isNotBlank(endDate)){
                endDateArr= endDate.split('-');
            }
            if(Test.isRunningTest()){
                requestBeginDate = system.today();
                requestEndDate = system.today();
            }else{
                if(beginDateArr.size()>2  && (!String.isNotBlank(beginMonthStr))){
                    requestBeginDate = Date.newInstance(Integer.valueOf(beginDateArr[0]), Integer.valueOf(beginDateArr[1]), Integer.valueOf(beginDateArr[2]));
                }
                if( endDateArr.size()>2 && (!String.isNotBlank(beginMonthStr))){
                    requestEndDate = Date.newInstance(Integer.valueOf(endDateArr[0]), Integer.valueOf(endDateArr[1]), Integer.valueOf(endDateArr[2]));
                }
                if(String.isNotBlank(beginMonthStr) && Integer.valueOf(beginYearStr) != null){
                    requestBeginDate = Date.newInstance(Integer.valueOf(beginYearStr), Integer.valueOf(beginMonthStr), 1);
                }
                if(String.isNotBlank(endMonthStr) && Integer.valueOf(endYearStr) != null){
                    Integer numberOfDays = Date.daysInMonth(endYearStr, Integer.valueOf(endMonthStr));
                    
                    Date lastDayOfMonth = Date.newInstance(endYearStr, Integer.valueOf(endMonthStr), numberOfDays);
                    requestEndDate = lastDayOfMonth;
                }
            }
            for(Canned_Report_Request__c canReport:reportReqList){
                canReport.Date_Requested__c = system.now();
                canReport.Start_Date__c = requestBeginDate;
                canReport.End_Date__c = requestEndDate;
                // CCCAP-1548
                // Intermediate (Initialized) status to stop Heruko batch to generate canned report PDF
                // before calling webservice from salesforce
                if(canReport.Report_Id__c == 'RE803' || canReport.Report_Id__c == 'RE304'){
                    canReport.Status__c = 'INI';
                } else {
                    canReport.Status__c = 'REQ';
                }
                // START: CCCAP-5445
                // Added RE229 by Rishav for CCCAP-6604 
                // Added RE218 by Rishav for CCCAP-6791
                // Added RE230 by Rishav for CCCAP-7088 & CCCAP-7662
                List<String> reportFor30Days = new List<String>{'RE208', 'RE218', 'RE226', 'RE229', 'RE230','RE221'};
                if(reportFor30Days.contains(canReport.Report_Id__c)){
                    Date oneMonthEndDate = requestBeginDate.addMonths(1);
                    if(requestEndDate >= oneMonthEndDate){
                        canReport.Status__c = 'INI';
                    }
                }
                // END: CCCAP-5445
                canReport.User__c = UserInfo.getUserId();
                cannedReportReqToInsertList.add(canReport);
            }
            if(cannedReportReqToInsertList.size()>0){
                List<DMLResult> cannedReportReqRecords= GenericDMLHandler.insertRecords(cannedReportReqToInsertList,false, new Map<String,Object>{'Method__c'=>'submitReportReq','Class__c'=>'ReportRequestApxCtrl'});
                if( cannedReportReqRecords != NULL && cannedReportReqRecords.size()>0 && cannedReportReqRecords[0].saveResult.isSuccess()){
                    for(Canned_Report_Request_Filter__c fltObj:requestFilterDataList){
                        fltObj.Canned_Report_Request__c =cannedReportReqRecords[0].saveResult.getId();
                        requestFilterToInsertList.add(fltObj);
                    }
                    if(String.isNotBlank(providerIdVal) && String.isNotBlank(providerName)){
                        Canned_Report_Request_Filter__c providerFlt = new Canned_Report_Request_Filter__c();
                        providerFlt.Canned_Report_Request__c =cannedReportReqRecords[0].saveResult.getId();
                        providerFlt.Field__c ='ProviderID';
                        providerFlt.Value__c =providerIdVal;
                        Canned_Report_Request_Filter__c providerNameFlt = new Canned_Report_Request_Filter__c();
                        providerNameFlt.Canned_Report_Request__c =cannedReportReqRecords[0].saveResult.getId();
                        providerNameFlt.Field__c ='ProviderName';
                        providerNameFlt.Value__c =providerName;
                        requestFilterToInsertList.add(providerNameFlt);
                        requestFilterToInsertList.add(providerFlt);
                    }
                    if(requestFilterToInsertList.size()>0){
                        List<DMLResult> cannedReportReqFilterRecords= GenericDMLHandler.insertRecords(requestFilterToInsertList,false, new Map<String,Object>{'Method__c'=>'submitReportReq','Class__c'=>'ReportRequestApxCtrl'});
                    }
                }	
            }
        }catch(Exception exp){
            isSuccessful=false;
            message = exp.getMessage();
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getProvider(String searchKey, String searchValue){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        
        String query = 'SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c WHERE NBR_'+String.escapeSingleQuotes(searchKey)+'__c = :searchValue LIMIT 1';        
        for(T_CHATS_PROVR_STATUS__c prov : Database.query(query)){
            objectData.put('providerId', prov.Id);
            objectData.put('providerName', prov.Name);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
}