public with sharing class PeakInboxScreenCtrl {
    
    
    @AuraEnabled 
    public static User fetchUser(){
        
        User u = [select id,Owner_County__c, Name from User where id =: userInfo.getUserId()];
        return u ;
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitPeakRequestData(){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        
        User u = fetchUser();
        objectData.put('user', u.Owner_County__c);
        Date todayDate = system.today();
        Date todayMinus30Days = system.today().addDays(-30);
        objectData.put('todayDate',todayDate);
        objectData.put('todayMinus30Days',todayMinus30Days);
        objectData.put('statusPickList',APXInputPicklistCtrl.getPicklistValues('T_APPLN_PRCS_QUEUE__c','CDE_STATUS_APPLN__c'));
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    
    @AuraEnabled
    public static LightningServerResponse processViewResults(String peakSearchWrapperStr){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        PeakInboxWrapper peakSearchWrapper = (PeakInboxWrapper)JSON.deserialize(peakSearchWrapperStr, PeakInboxWrapper.class);
        
        objectData.put('test',PeakInboxScreenCtrl.createPeakResultWrapper(peakSearchWrapper));
        return new LightningServerResponse(true,message,objectData); 
    }
    
    
    public static String appProcessQueueQuery(PeakInboxWrapper wrpObj){
        
        
        String firstQuery;
        List<String> countyLst = new List<String>();
        List<String> statusLst = new List<String>();
        
        firstQuery = 'SELECT Id,County_Name__r.CDE_COUNTY__c, IDN_APPLN__c,IDN_APPLN__r.IDN_APPLN__c,County_Name__r.Name,Name,toLabel(CDE_STATUS_APPLN__c), DTE_RCVD_APPLN__c, IDN_CASE__c,IDN_CASE__r.Name, toLabel(CDE_REJECT_APPLN__c),CDE_SOURCE__c FROM T_APPLN_PRCS_QUEUE__c Where CDE_SOURCE__c =\'PK\'';
        if(wrpObj.status != null && wrpObj.status != ''){
            statusLst = wrpObj.status.split(';');
            firstQuery += ' AND CDE_STATUS_APPLN__c IN(';
            for(String includeValue :statusLst)
                firstQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
            firstQuery = firstQuery.removeEnd(',') +')';
        }
        //corrected below if block to correctly check if All County(State) is selected or not for CCCAP-14433 by Shashank
        if(wrpObj.county != null && wrpObj.county != '' && !wrpObj.county.split(';').contains('66')){
            countyLst = wrpObj.county.split(';');
            firstQuery += ' AND CDE_COUNTY__c IN (';
            for(String includeValue :countyLst){
                firstQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
                if(includeValue.length() == 1){	
                    includeValue = '0'+String.escapeSingleQuotes(includeValue);
                    firstQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ','; // added to include '1' and '01' both as county codes for CCCAP-14154/CCCAP-13978
                }
            }
            firstQuery = firstQuery.removeEnd(',')+')';
        }
        if (wrpObj.fromDate!= null){
            Date frmDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.fromDate).remove('00:00:00')));
            firstQuery += ' AND DTE_RCVD_APPLN__c >= :frmDate ';
        }
        if (wrpObj.toDate!= null){
            Date toEndDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.toDate).remove('00:00:00')));
            firstQuery += ' AND DTE_RCVD_APPLN__c <= :toEndDate ';
        }
        
        if (wrpObj.trackingNumber != null && wrpObj.trackingNumber != ''){
            firstQuery += ' AND IDN_APPLN__r.IDN_APPLN__c = '+String.escapeSingleQuotes(wrpObj.trackingNumber)+'.0 ';
        }
        
        firstQuery+= ' ORDER BY DTE_RCVD_APPLN__c ASC LIMIT 25000'; // adding this 25k limit to support second query for capping of 50k for CCCAP-9837
        return firstQuery;
    }
    
    
    
    public static String appIndivQuery(PeakInboxWrapper wrpObj,  Set<Id> appCaseId, Set<Id> applIndivId){
        String secondQuery;
        
        if(wrpObj.searchType != null && wrpObj.searchType == 'SoundexSearch'){
            
            //Set<Id> applIndivId = new Set<Id>();
            applIndivId.addAll(doSoundexSearch(wrpObj,  appCaseId));
            
            secondQuery = 'SELECT Id,NBR_SSN__c, NAM_FIRST__c,NAM_LAST__c, IDN_APPLN__c FROM  T_APPLN_INDIV__c Where IDN_APPLN__c IN:appCaseId AND id =:applIndivId AND IND_CRTKR_PRIM__c = \'Y\'';
            
            if(wrpObj.ssn != null && wrpObj.ssn != ''){
                secondQuery += ' AND NBR_SSN__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.ssn)+'%\'';
            }
            
        }else if(wrpObj.searchType != null && wrpObj.searchType == 'StringSearch'){
            secondQuery = 'SELECT Id,NBR_SSN__c, NAM_FIRST__c,NAM_LAST__c, IDN_APPLN__c FROM  T_APPLN_INDIV__c Where IDN_APPLN__c IN:appCaseId AND  IND_CRTKR_PRIM__c =  \'Y\'';
            
            if(wrpObj.ssn != null && wrpObj.ssn != ''){
                secondQuery += ' AND NBR_SSN__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.ssn)+'%\'';
            }
            if(wrpObj.firstName != null && wrpObj.firstName != ''){
                secondQuery += ' AND NAM_FIRST__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.firstName)+'%\'';
            }
            if(wrpObj.lastName != null && wrpObj.lastName != ''){
                secondQuery += ' AND NAM_LAST__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.lastName)+'%\'';
            }
        }
        //adding limits for CCCAP-9837
        Integer queryLimit = Limits.getLimitQueryRows() >= Limits.getQueryRows() ? Limits.getLimitQueryRows() - Limits.getQueryRows() : 0;
    	return secondQuery + ' LIMIT '+queryLimit;
    }
    
    
    public static List<PeakResultWrapper> createPeakResultWrapper(PeakInboxWrapper wrpObj){
        
        String firstQuery = PeakInboxScreenCtrl.appProcessQueueQuery(wrpObj);
        Date frmDate;
        Date toEndDate;
        Set<Id> applIndivId = new Set<Id>();
        //applIndivId.addAll(doSoundexSearch(wrpObj));
        
        if(wrpObj.fromDate != null){
            frmDate = Date.valueOf(String.valueOf(wrpObj.fromDate).remove('00:00:00'));	
        }
        if(wrpObj.toDate != null){
            toEndDate = Date.valueOf(String.valueOf(wrpObj.toDate).remove('00:00:00'));
        }
        
        List<Id> queueIds = new List<Id>();
        Map<Id,Map<Id,PeakResultWrapper>> peakInboxResultMap = new Map<Id,Map<Id,PeakResultWrapper>>();
        List<PeakResultWrapper> peakResultWrapperLst = new List<PeakResultWrapper>();
        Set<Id> appCaseId = new Set<Id>();
        Set<Id> secondAppCaseId = new Set<Id>();
        PeakResultWrapper peakInboxRec;
        
        List<T_APPLN_PRCS_QUEUE__c> displayResult = new List<T_APPLN_PRCS_QUEUE__c>();
        displayResult = Database.query(firstQuery);
        
        for(T_APPLN_PRCS_QUEUE__c queueRec : displayResult){
            queueIds.add(queueRec.Id);
            appCaseId.add(queueRec.IDN_APPLN__c);
            peakInboxRec = new PeakResultWrapper();
            if(!peakInboxResultMap.containsKey(queueRec.IDN_APPLN__c)){
                peakInboxResultMap.put(queueRec.IDN_APPLN__c, new Map<Id,PeakResultWrapper>());
            }
            peakInboxResultMap.get(queueRec.IDN_APPLN__c).put(queueRec.Id, peakInboxRec); 
            peakInboxRec.queuecounty =queueRec.County_Name__r.Name;
            peakInboxRec.appId =queueRec.Id;
            peakInboxRec.queueId =queueRec.Name;
            peakInboxRec.queuestatus =queueRec.CDE_STATUS_APPLN__c;
            peakInboxRec.trackingNumber = String.valueOf(queueRec.IDN_APPLN__r.IDN_APPLN__c); 
            peakInboxRec.queueReceivedDate = queueRec.DTE_RCVD_APPLN__c;
            peakInboxRec.queueCase = queueRec.IDN_CASE__r.Name;
            peakInboxRec.queueReason = queueRec.CDE_REJECT_APPLN__c;
        }
        
        String secondQuery = PeakInboxScreenCtrl.appIndivQuery(wrpObj,appCaseId, applIndivId);
        List<T_APPLN_INDIV__c> displayIndividualResult = new List<T_APPLN_INDIV__c>();
        displayIndividualResult = Database.query(secondQuery);
        
        for(T_APPLN_INDIV__c appIndiv: displayIndividualResult){
            secondAppCaseId.add(appIndiv.IDN_APPLN__c);
            for(Id queueId : peakInboxResultMap.get(appIndiv.IDN_APPLN__c).keySet()){
                peakInboxResultMap.get(appIndiv.IDN_APPLN__c).get(queueId).firstName = appIndiv.NAM_FIRST__c; 
                peakInboxResultMap.get(appIndiv.IDN_APPLN__c).get(queueId).lstName = appIndiv.NAM_LAST__c;   
            }
        }
        
        Map<Id, PeakResultWrapper> appIdPeakResultWrpMap = new Map<Id, PeakResultWrapper>();
        
        if(!(String.isEmpty(wrpObj.firstName) && String.isEmpty(wrpObj.lastName) && String.isEmpty(wrpObj.ssn))){
            for(String caseId : secondAppCaseId){
                if(appCaseId.contains(caseId)){
                    appIdPeakResultWrpMap.putAll(peakInboxResultMap.get(caseId));
                }
            }  
        }else{
            for(String caseId : peakInboxResultMap.keySet()){
                appIdPeakResultWrpMap.putAll(peakInboxResultMap.get(caseId));
            }
        }
        
        for(Id prcQueueId : queueIds){
            if(appIdPeakResultWrpMap.containsKey(prcQueueId)){
                peakResultWrapperLst.add(appIdPeakResultWrpMap.get(prcQueueId));   
            } 
        }
        
        return peakResultWrapperLst;
    }
    
    
    
    private static Set<Id> doSoundexSearch(PeakInboxWrapper peakSearchWrapper,  Set<Id> appCaseId){
        String soundexValue = '';
        Boolean fnLnProvided = false;
        List<T_APPLN_INDIV__c> searchConditions = new List<T_APPLN_INDIV__c>();
        List<String> listConditions = new List<String>();
        Set<Id> appIndivId = new Set<Id>();
        String firstName = peakSearchWrapper.firstName;
        String lastName = peakSearchWrapper.lastName;
        
        if((peakSearchWrapper.lastName !=null && peakSearchWrapper.lastName !='') && (peakSearchWrapper.firstName != null && peakSearchWrapper.firstName != '')){
            soundexValue = (peakSearchWrapper.lastName !=null? SoundexUtil.toSoundex(peakSearchWrapper.lastName).RightPad(6,'0'):'')+SoundexUtil.toSoundex(peakSearchWrapper.firstName); 
            fnLnProvided = true;
        } else if((peakSearchWrapper.lastName !=null && peakSearchWrapper.lastName != '') && (peakSearchWrapper.firstName == null || peakSearchWrapper.firstName == '')){
            soundexValue =(peakSearchWrapper.lastName !=null? SoundexUtil.toSoundex(peakSearchWrapper.lastName).RightPad(6,'0'):'');
            fnLnProvided = false;
        } else if((peakSearchWrapper.lastName ==null || peakSearchWrapper.lastName == '') && (peakSearchWrapper.firstName != null && peakSearchWrapper.firstName != '')){
            soundexValue =SoundexUtil.toSoundex(peakSearchWrapper.firstName);
            fnLnProvided = false;
        }
        if(soundexValue!=null && soundexValue !=''){
            soundexValue = soundexValue.replace('0', '_');
        }
        
        String query = 'SELECT Id, TXT_SNDX__c, NAM_FIRST__c,NAM_LAST__c FROM T_APPLN_INDIV__c Where IDN_APPLN__c IN:appCaseId and IND_CRTKR_PRIM__c =  \'Y\' ';
        
        if(soundexValue != null){
            listConditions.add('TXT_SNDX__c LIKE \'%'+String.escapeSingleQuotes(soundexValue)+'%\'');
        }
        
        if(!listConditions.isEmpty()){
            for(Integer i=0;i<listConditions.size();i++){
                query += ' AND '+listConditions.get(i);
            }  

            searchConditions = Database.query(query);
        }
        if(searchConditions.size()>0){
            for(T_APPLN_INDIV__c appIndivRec : searchConditions){
                appIndivId.add(appIndivRec.Id);  
            }   
        }
        return appIndivId;
    } 
        
    @auraEnabled
    public static LightningServerResponse validateCounty(string recordId){
        Map<String, Object> objectData = new map<String, Object>();
        T_APPLN_PRCS_QUEUE__c applnPrcs = [select id, County_Name__c, County_Name__r.Name from T_APPLN_PRCS_QUEUE__c where id =:recordId];
        Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(applnPrcs.County_Name__c);
        objectData.put('isValidCounty', countyMatched);
        objectData.put('countyName', applnPrcs.County_Name__r.Name);
        return new LightningServerResponse(false, null, objectData);
    }
}