public with sharing class CannedReportHomepageController {
    
    @AuraEnabled
    public static LightningServerResponse processViewResults(String reportType, String reportName){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        String soql, soqlSelect, soqlOrderBy, soqlcount;
        List<Canned_Report__mdt> searchResult = new List<Canned_Report__mdt>(); 
        soqlSelect = 'select Id, Report_Type__c, Report_Name__c, isOneYearReport__c, Description__c, DeveloperName, Request_Type__c, End_Date_Label__c, Hide_End_Date__c, Start_Date_Label__c, Date_Required__c, isMonthYear__c, County_Label__c, FutureBeginDate__c, FutureEndDate__c, isDateRange__c, EndDateRequired__c, isDateDefaulted__c, oneMonthDiffCheck__c, isMonthYearFilter__c, isProviderDependentLkUp__c, Hide_County__c, isCountyAutoAssigned__c from Canned_Report__mdt where ';
        soqlcount = 'select count() from Canned_Report__mdt where ';
        soql = 'id != null';
        if ((String.isNotBlank(reportType)) && reportType != 'None'){
            reportType = String.escapeSingleQuotes(reportType);
            soql += ' AND Report_Type__c =: reportType';
        }
        if ((String.isNotBlank(reportName)) && reportName != 'None'){
            reportName = String.escapeSingleQuotes(reportName);
            soql += ' AND Report_Name__c LIKE ';
            soql += '\'%'+reportName+'%\'';
        } 
        soqlOrderBy = ' LIMIT 200 ';    
        searchResult = Database.query(soqlSelect + soql + soqlOrderBy); 
        objectData.put('test',searchResult);
        // Start: Added for CCCAP-3230 by Rishav
        Map<String, String> userCountyMap = new Map<String, String>();
        User u = [SELECT Id, Owner_County__c, Common_County__c FROM User WHERE id =: userInfo.getUserId() LIMIT 1];
        userCountyMap.put('Owner_County__c', u.Owner_County__c);
        userCountyMap.put('Common_County__c', u.Common_County__c);
        objectData.put('userCountyMap', userCountyMap);
        // End: CCCAP-3230
        return new LightningServerResponse(isSuccessful,message,objectData); 
    }
    
    @AuraEnabled
    public static LightningServerResponse getAvailableReportsOnHomepage(){
        Boolean isSuccessful = true;
        String message = '';
        Map<String,Object> objectData = new Map<String,Object>();
        /* CCCAP-12937 : RE229 Report Decommission */
        List<Canned_Report__mdt> res = [SELECT toLabel(Report_Type__c), Report_Name__c, isOneYearReport__c, Request_Type__c, Description__c, DeveloperName, End_Date_Label__c, Hide_End_Date__c, Start_Date_Label__c, Date_Required__c, isMonthYear__c, County_Label__c, FutureBeginDate__c, FutureEndDate__c, isDateRange__c, EndDateRequired__c, isMonthYearFilter__c, isProviderDependentLkUp__c, Hide_County__c FROM Canned_Report__mdt 
                                        WHERE Request_Type__c ='MAN' AND Is_Active__c = true AND MasterLabel != 'RE229' ORDER BY Report_Name__c ASC];
        
        objectData.put('test',res);
        return new LightningServerResponse(isSuccessful,message, objectData);        
    }
    
    @AuraEnabled
    public static List<String> getAllReportName(){
        Set<String> reportTypeResultSet = new Set<String>();
        List<String> reportTypeResult = new List<String>();
        /* CCCAP-12937 : RE229 Report Decommission */
        List<Canned_Report__mdt> res = [SELECT Id, Report_Name__c FROM Canned_Report__mdt WHERE Request_Type__c ='MAN' AND Is_Active__c = true AND MasterLabel != 'RE229' ORDER BY Report_Name__c];
        if(res.size()>0){
            for(Canned_Report__mdt name : res){
                reportTypeResultSet.add(name.Report_Name__c);
            } 
        }
        reportTypeResult.addAll(reportTypeResultSet);
        return reportTypeResult; 
    }
    
    @AuraEnabled
    public static List<String> getReportName(String reportType){
        Set<String> reportTypeResultSet = new Set<String>();
        List<String> reportTypeResult = new List<String>();
        List<Canned_Report__mdt> res;
        /* CCCAP-12937 : RE229 Report Decommission */
        if(reportType != '1' && reportType != '2' && reportType != '3' && reportType != '4'){
            res = [SELECT Id, Report_Name__c FROM Canned_Report__mdt WHERE Request_Type__c ='MAN' AND Is_Active__c = true AND MasterLabel != 'RE229' ORDER BY Report_Name__c];
        }else{
            res = [SELECT Id, Report_Name__c FROM Canned_Report__mdt WHERE Report_Type__c =: reportType AND Request_Type__c ='MAN' AND Is_Active__c = true  AND MasterLabel != 'RE229' ORDER BY Report_Name__c];
        }
        if(res!= null && res.size()>0){
            for(Canned_Report__mdt name : res){
                reportTypeResultSet.add(name.Report_Name__c);
            } 
        }
        reportTypeResult.addAll(reportTypeResultSet);
        return reportTypeResult;  
    }
    
}