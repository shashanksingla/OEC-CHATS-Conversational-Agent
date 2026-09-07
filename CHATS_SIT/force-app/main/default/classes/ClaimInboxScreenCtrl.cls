public with sharing class ClaimInboxScreenCtrl implements IRequest {
    
    public String jsonParam;
    private static Map<String, Object > requestObj;
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(jsonParam!=null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);            
        }
        if(methodName == 'getInitClaimRequestData'){
            response = getInitClaimRequestData();
        }else if(methodName == 'processViewResults'){
            response = processViewResults(getMapValue('claimSearchWrapperStr'));
        }else if(methodName =='getFileDownloadUrl'){
            response = getFileDownloadUrl(getMapValue('fileIdentifier'),getMapValue('fileName'));
        }
        
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    @auraEnabled
    public static LightningServerResponse getInitClaimRequestData(){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        
        User u = fetchUser();
        Date todayDate = system.today();
        Date todayMinus30Days = system.today().addDays(-30);
        objectData.put('user', u.Owner_County__c);
        objectData.put('todayDate',todayDate);
        objectData.put('todayMinus30Days',todayMinus30Days);
        LightningServerResponse response = new LightningServerResponse(isSuccessful,message,objectData);
        return response;
    }
    
    @auraEnabled
    public static LightningServerResponse processViewResults(String claimSearchWrapperStr){
        Boolean isSuccessful = true;
        String message;
        Map<String, Object> objectData = new map<String, Object>();
        try{
            system.debug('claimSearchWrapperStr'+claimSearchWrapperStr);
            ClaimInboxWrapper claimSearchWrapper = (ClaimInboxWrapper)JSON.deserialize(claimSearchWrapperStr, ClaimInboxWrapper.class);
            objectData.put('claims',ClaimInboxScreenCtrl.createClaimResultWrapper(claimSearchWrapper));
            objectData.put('timeZone',Userinfo.getTimezone().getId());
        }catch (Exception e) {
            isSuccessful = false;
            objectData = new map<String, Object>();
            message = 'Failed to Load results at this moment, please try again later !'+ e.getMessage();
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'ClaimInboxScreenCtrl','Method__c'=>'processViewResults'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled 
    public static LightningServerResponse getFileDownloadUrl(String fileIdentifier,string fileName){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        try{
            Httprequest httpRequest = new Httprequest();
            Http http = new Http();
            httpRequest.setHeader('Content-type', 'application/json;charset=UTF-8');
            httpRequest.setHeader('Accept', 'application/json');
            String serverFName = fileName.trim().replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9._-]', '_').replaceAll('_+', '_');
            Integer lastDot = serverFName.lastIndexOf('.');
            if (lastDot > 0) {
                String namePart = serverFName.substring(0, lastDot);
                String extPart = serverFName.substring(lastDot);
                namePart = namePart.replaceAll('_+$', ''); // Remove trailing underscores
                serverFName =  namePart + extPart;
            } else {
                // No extension, just remove trailing underscores
                serverFName =  serverFName.replaceAll('_+$', '');
            }
            String encoded = System.label.Claim_File_Token_URL+'/download-link?fileName='+EncodingUtil.urlEncode(serverFName, 'UTF-8')+'&fileIdentifier='+fileIdentifier;
            httpRequest.setEndpoint(encoded);         
            httpRequest.setMethod('GET');
            httpRequest.setTimeout(120000);
            Httpresponse response = http.send(httpRequest);
            Map<String,Object > m = (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); //re is response body string.....changed re to body
            if(response.getStatusCode() == 200){
                string responseBody = response.getBody();
                system.debug('downloadUrl'+response.getBody());
                if(m.containsKey('fileUrl')) {
                    objectData.put('downloadUrl',(String)m.get('fileUrl'));
                }
            }else{
                isSuccessful = false;
                message =  'Failed to Load File at this moment with status ,'+(String)m.get('status')+' and Error : '+(String)m.get('status')+'. please try again later !';
                ExceptionLoggingServices.captureExceptionLog(response, httpRequest, new Map<String,Object>{'Record_ID__c'=>fileIdentifier,'Class__c'=>'ClaimInboxScreenCtrl','Method__c'=>'getFileDownloadUrl'});
            }
        }catch (System.CalloutException e) {
            isSuccessful = false;
            message = 'Failed to Load File at this moment, please try again later !';
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Record_ID__c'=>fileIdentifier,'Class__c'=>'ClaimInboxScreenCtrl','Method__c'=>'getFileDownloadUrl'});
        }catch (Exception e) {
            isSuccessful = false;
            message = 'Failed to Load File at this moment, please try again later !';
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Record_ID__c'=>fileIdentifier,'Class__c'=>'ClaimInboxScreenCtrl','Method__c'=>'getFileDownloadUrl'});
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled(cacheable=true)
    public static LightningServerResponse getClaimsData(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<Provider_Manual_Claim__c> claims = [SELECT Id, Name, Total_Amount_Claimed__c, toLabel(Claim_Status__c), Provider_phone__c, Denial_Reason__c, Care_Year__c, 
                                                 toLabel(Care_Month__c), Provider_Id__c, File_Uploaded__c, Provider_Name__c, Provider_Email__c,
                                                 County__c,IDN_EXTNL__c,County_Code__c,Denied_Claim_Queue__c,Created_By__c,Last_Modified_By__c,
                                                 Provider_Mailing_Address__c,format(createddate),format(Status_updated_date__c),Signature__c
                                                 FROM Provider_Manual_Claim__c 
                                                 WHERE Id=:recordId order by createddate desc, County__c desc];
        List<claimDetailWrap> cwraps = new List<claimDetailWrap>();
        for(Claim_Detail__c detail: [SELECT Id,Name,IDN_EXTNL__c,CreatedDate,Provider_Manual_Claim__c, Total_Child_Claimed_Amount__c, 
                                     Authorization_Id__c, Case_Id__c, Individual_Id__c, Child_First_Name__c,Child_Last_Name__c,
                                     Claim_for__c,Slot_contract_Id__c,
                                     (SELECT Id, Name,IDN_EXTNL__c,Provider_Manual_Claim__c, CreatedDate, Claim_Detail__c, Claim_Amount__c, Care_Date__c,toLabel(Authorized_Care_Amount__c),toLabel(Claim_Care_Amount__c), Reason_for_Claim__c, ART_Fee_Type__c, Detail_Type__c 
                                      FROM Claim_Day_Details__r order by Care_Date__c asc) 
                                     FROM Claim_Detail__c where Provider_Manual_Claim__c=:claims order by Claim_for__c ASC])
        {
            claimDetailWrap cwrap = new claimDetailWrap();
            cwrap.isVacantSlot = detail.Claim_For__c.containsIgnoreCase('Vacant Slot Contract')?true:false;
            cwrap.claimDetail = detail;
            for(Claim_Day_Detail__c dayDetail : detail.Claim_Day_Details__r){
                if(dayDetail.Detail_Type__c.containsIgnoreCase('Claim')){
                    if(cwrap.claimDayDetails!=null){
                        cwrap.claimDayDetails.add(dayDetail); 
                    }else{
                        cwrap.claimDayDetails = new List<Claim_Day_Detail__c>{dayDetail};
                            }
                }else if(dayDetail.Detail_Type__c.containsIgnoreCase('ART Fee')){
                    if(cwrap.artFees!=null){
                        cwrap.artFees.add(dayDetail); 
                    }else{
                        cwrap.artFees =  new List<Claim_Day_Detail__c>{dayDetail};
                            }
                }
            }
            cwraps.add(cwrap);
        }
        objectData.put('claimData',claims[0]);
        objectData.put('claimDetails',cwraps);
        LightningServerResponse response = new LightningServerResponse(true,message,objectData);
        return response;
    }
    
    private static User fetchUser(){
        User u = [select id,Owner_County__c, Name from User where id =: userInfo.getUserId()];
        return u ;
    }
    
    private static List<ClaimResultWrapper> createClaimResultWrapper(ClaimInboxWrapper wrpObj){
        Set<Id> applIndivId = new Set<Id>();
        List<Id> queueIds = new List<Id>();
        List<ClaimResultWrapper> claimResultWrapperLst = new List<ClaimResultWrapper>();
        List<Provider_Manual_Claim__c> displayResult = new List<Provider_Manual_Claim__c>();
        Set<Id> appCaseId = new Set<Id>();
        Set<Id> secondAppCaseId = new Set<Id>();
        Map<Id,Map<Id,ClaimResultWrapper>> claimInboxResultMap = new Map<Id,Map<Id,ClaimResultWrapper>>();
        ClaimResultWrapper claimInboxRec;
        displayResult = ClaimInboxScreenCtrl.claimProcessQueueQuery(wrpObj);
        
        for(Provider_Manual_Claim__c queueRec : displayResult){
            claimInboxRec = new ClaimResultWrapper();
            claimInboxRec.recordId =queueRec.Id; // Claim Id
            claimInboxRec.queueId =queueRec.Name; // Claim Name
            claimInboxRec.queuecounty =queueRec.County__c; // County Name
            claimInboxRec.queueSubmittedDate = queueRec.createdDate.date(); // Claim Submitted Date
            claimInboxRec.queuestatus =queueRec.Claim_Status__c; // Claim Status
            claimInboxRec.queueStatusUpdatedDate = queueRec.Status_Updated_Date__c; // Status updated Date
            claimInboxRec.queueProviderName = queueRec.Provider_Name__c;  // Provider Name
            claimInboxRec.queueProviderId = queueRec.Provider_Id__c;  // Provider Name
            claimInboxRec.queueProviderSfId = queueRec.CHATS_Provider__c;  // Provider Name
            claimInboxRec.queueCareYear = queueRec.Care_Year__c; // Care Year
            claimInboxRec.queueCareMonth = queueRec.Care_Month__c; // Care Month
            claimInboxRec.queueClaimAmount = queueRec.Total_Amount_Claimed__c; // Care Month
            claimResultWrapperLst.add(claimInboxRec);
        }
        return claimResultWrapperLst;
    }
    private static List<Provider_Manual_Claim__c> claimProcessQueueQuery(ClaimInboxWrapper wrpObj){
        String firstQuery;
        List<String> countyLst = new List<String>();
        List<String> statusLst = new List<String>();
        
        firstQuery = 'SELECT Id, Name, CreatedDate, Denial_Reason__c, Total_Amount_Claimed__c, File_Uploaded__c, Provider_Email__c, Adjustment__c, Provider_Mailing_Address__c, Provider_Name__c, County__c, Provider_phone__c, Status_Updated_Date__c, ToLabel(Care_Month__c), Claim_Status__c, Care_Year__c, CHATS_Provider__c, Provider_Id__c, County_Code__c FROM Provider_Manual_Claim__c Where County__c!=null ';
        // County Check filter
        if(wrpObj.county != null && wrpObj.county != '' && !wrpObj.county.contains('66')){
            countyLst = wrpObj.county.split(';');
            firstQuery += ' AND County_Code__c IN (';
            for(String includeValue :countyLst){
                if(includeValue!=''){
                    firstQuery += String.escapeSingleQuotes(includeValue) +',';
                }
            }
            firstQuery = firstQuery.removeEnd(',')+')';
        }
        // Status Check filter
        if(wrpObj.status != null && wrpObj.status != ''){
            statusLst = wrpObj.status.split(';');
            firstQuery += ' AND Claim_Status__c IN(';
            for(String includeValue :statusLst)
                firstQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
            firstQuery = firstQuery.removeEnd(',') +')';
        }
        // Care Month filter
        if (wrpObj.careMonth!= null && wrpObj.careMonth!=''){
            firstQuery += ' AND Care_Month__c ='+'\''+String.escapeSingleQuotes(wrpObj.careMonth)+'\' ';
        }
        // Care Year filter
        if (wrpObj.careYear!= null && wrpObj.careYear!=''){
            try {
                Decimal yearValue = Decimal.valueOf(String.escapeSingleQuotes(wrpObj.careYear));
                firstQuery += ' AND Care_Year__c =' + yearValue + '';
            } catch (Exception e) {
                System.debug('Invalid care year format: ' + wrpObj.careYear);
            }
        }
        // Status Submitted Date from filter
        DateTime frmDate;
        if (wrpObj.fromDate!= null){
            frmDate = Datetime.newInstance(wrpObj.fromDate, Time.newInstance(0, 0, 0, 0));
            firstQuery += ' AND createdDate >= :frmDate ';
        }
        // Status Submitted Date to filter
        DateTime toEndDate;
        if (wrpObj.toDate!= null){
            toEndDate = Datetime.newInstance(wrpObj.toDate, Time.newInstance(23, 59, 59, 59));
            firstQuery += ' AND createdDate <= :toEndDate ';
        }
        // Status Submitted Date to filter
        if (wrpObj.providerId!= null && wrpObj.providerId!=''){
        // Sanitize to prevent SOQL/SOSL injection as part of CCCAP-14167
            String sanitizedProviderId = String.escapeSingleQuotes(wrpObj.providerId);
            firstQuery += ' AND CHATS_Provider__c =\''+sanitizedProviderId+'\' ';
        }else if(wrpObj.providerName!=null){
            wrpObj.providerName = String.escapeSingleQuotes(wrpObj.providerName);
            firstQuery += ' AND Provider_Name__c LIKE '+'\'%'+wrpObj.providerName+'%\' ';
        }
        firstQuery+= ' WITH SECURITY_ENFORCED ORDER BY createdDate DESC,County__c desc  LIMIT 50000';
        system.debug('firstQuery'+firstQuery);
        return Database.query(firstQuery);
    }
    
    Public class claimDetailWrap{
        @auraEnabled
        public Boolean isVacantSlot{get;set;}
        @auraEnabled
        public Claim_Detail__c claimDetail{get;set;}
        @auraEnabled
        public list<Claim_Day_Detail__c> claimDayDetails{get;set;}
        @auraEnabled
        public list<Claim_Day_Detail__c> artFees{get;set;}
    }
}