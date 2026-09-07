public with sharing class CBMSInboxScreenCtrl {
    
    private static Boolean specificCountiesSelected = false;
    private static Boolean statuscheckforCounty = false;
    /**
     * @description Calculates the remaining SOQL query rows available in the current transaction
     * @return Integer - The number of rows that can still be queried without hitting governor limits
     */
    private static Integer getRemainingQueryRows() {
        return Limits.getLimitQueryRows() - Limits.getQueryRows();
    }

    @AuraEnabled 
    public static User fetchUser(){
        
        User u = [select id,Owner_County__c, Name from User where id =: userInfo.getUserId()];
        return u ;
    }
    
    @AuraEnabled
    public static LightningServerResponse getInitCBMSRequestData(){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        
        User u = fetchUser();
        objectData.put('user', u.Owner_County__c);
        Date todayDate = system.today();
        Date todayMinus30DaysTemp = todayDate.addMonths(-1);
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
        CBMSInboxWrapper cbmsSearchWrapper = (CBMSInboxWrapper)JSON.deserialize(peakSearchWrapperStr, CBMSInboxWrapper.class);
        
        objectData.put('test',CBMSInboxScreenCtrl.createCBMSResultWrapper(cbmsSearchWrapper));
        return new LightningServerResponse(true,message,objectData); 
    }
    
    
    public static String appProcessQueueQuery(CBMSInboxWrapper wrpObj){
        String retQuery;
        List<String> countyLst = new List<String>();
        List<String> statusLst = wrpObj.status == ''?new List<String>(): wrpObj.status.split(';');
        List<String> oldCountyStatusList = new List<String>{'NEW','PEN','REJ','INC'};
            retQuery = 'SELECT Id,County_Name__r.CDE_COUNTY__c, IDN_APPLN__c,IDN_APPLN__r.IDN_APPLN__c,IDN_APPLN__r.CBMS_REF_REASON__c,IDN_APPLN__r.IDN_CBMS_REF__c,County_Name__r.Name,Name,toLabel(CDE_STATUS_APPLN__c), DTE_RCVD_APPLN__c,DTE_RCVD_REF__c, IDN_CASE__c,IDN_CASE__r.Name,IDN_APPLN__r.CDE_CBMS_REF_TYP__c, toLabel(CDE_REJECT_APPLN__c),CDE_SOURCE__c FROM T_APPLN_PRCS_QUEUE__c Where CDE_SOURCE__c =\'CB\'';
        statuscheckforCounty = (specificCountiesSelected && 
                                (statusLst.size()==0 || (statusLst.contains('NEW') || statusLst.contains('PEN') || statusLst.contains('REJ') || statusLst.contains('INC'))));
        if(wrpObj.status != null && wrpObj.status != ''){
            retQuery += ' AND CDE_STATUS_APPLN__c IN(';
            for(String includeValue :statusLst)
                retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
            retQuery = retQuery.removeEnd(',') +')';
        }
        if(specificCountiesSelected){
            countyLst = wrpObj.county.split(';');
            
            retQuery += ' AND CDE_COUNTY__c IN (';
            for(String includeValue :countyLst){
                retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
                if(includeValue.length() == 1){	
                    includeValue = '0'+String.escapeSingleQuotes(includeValue);
                    retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ','; // added to include '1' and '01' both as county codes for CCCAP-14154/CCCAP-13978
                }
            }
            retQuery = retQuery.removeEnd(',')+')';
        }
        if (wrpObj.fromDate!= null){
            Date frmDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.fromDate).remove('00:00:00')));
            retQuery += ' AND DTE_RCVD_REF__c >= :frmDate ';
        }
        if (wrpObj.toDate!= null){
            Date toEndDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.toDate).remove('00:00:00')));//Date.valueOf(String.valueOf(wrpObj.toDate).remove('00:00:00'));
            retQuery += ' AND DTE_RCVD_REF__c <= :toEndDate ';
        }
        if (wrpObj.referralType != null && wrpObj.referralType != ''){
            String referralType =String.escapeSingleQuotes(wrpObj.referralType);
            retQuery += ' AND (IDN_APPLN__r.CDE_CBMS_REF_TYP__c =:referralType )';
        }
        
        if(statuscheckforCounty){
            retQuery += ' AND (IDN_APPLN__r.CBMS_REF_REASON__c NOT IN ('+'\''+ 'Inter County Transfer'+'\'' + ','+ '\''+ 'CW Case Closure'+'\')';
            retQuery += ' OR (IDN_APPLN__r.CBMS_REF_REASON__c	IN ('+'\''+ 'Inter County Transfer'+'\'' + ','+ '\''+ 'CW Case Closure'+'\') AND CDE_STATUS_APPLN__c NOT IN(';
            List<String> checkList = statusLst.size()>0?statusLst:oldCountyStatusList;
            for(String includeValue :checkList){
                if(oldCountyStatusList.contains(includeValue)){
                    retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
                }
            }                                        
            retQuery = retQuery.removeEnd(',')+')';
            retQuery +='))';
        }
        retQuery+= ' ORDER BY DTE_RCVD_REF__c ASC';

         // Apply dynamic LIMIT using getRemainingQueryRows() to prevent exceeding governor limits
        Integer remainingRows = getRemainingQueryRows();
        if(remainingRows > 0) {
            retQuery += ' LIMIT ' + remainingRows;
        }
        system.debug('1st retQuery---'+retQuery);
        return retQuery;
    }
    
    public static String tranferQueuQuery(CBMSInboxWrapper wrpObj){
        String retQuery;
        List<String> countyLst = new List<String>();
        List<String> statusLst = wrpObj.status == ''?new List<String>(): wrpObj.status.split(';');
        List<String> oldCountyStatusList = new List<String>{'NEW','PEN','REJ','INC'};
            retQuery = 'SELECT Id,County_Name__r.CDE_COUNTY__c, IDN_APPLN__c,IDN_APPLN__r.IDN_APPLN__c,IDN_APPLN__r.CBMS_REF_REASON__c,IDN_APPLN__r.IDN_CBMS_REF__c,County_Name__r.Name,Name,toLabel(CDE_STATUS_APPLN__c), DTE_RCVD_APPLN__c,DTE_RCVD_REF__c, IDN_CASE__c,IDN_CASE__r.Name,IDN_APPLN__r.CDE_CBMS_REF_TYP__c, toLabel(CDE_REJECT_APPLN__c),CDE_SOURCE__c FROM T_APPLN_PRCS_QUEUE__c Where CDE_SOURCE__c =\'CB\'';
        statuscheckforCounty = (specificCountiesSelected && 
                                (statusLst.size()==0 || (statusLst.contains('NEW') || statusLst.contains('PEN') || statusLst.contains('REJ') || statusLst.contains('INC'))));
        if(wrpObj.status != null && wrpObj.status != ''){
            retQuery += ' AND CDE_STATUS_APPLN__c IN(';
            if(statuscheckforCounty){
                for(String includeValue :statusLst)
                    if(oldCountyStatusList.contains(includeValue)){	
                        retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';                                        
                    }
            }
            retQuery = retQuery.removeEnd(',') +')';
        }else if(statuscheckforCounty){
            retQuery += ' AND CDE_STATUS_APPLN__c IN(';
            for(String includeValue :oldCountyStatusList)
                retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
            retQuery = retQuery.removeEnd(',') +')';   
        }
        if(specificCountiesSelected){
            countyLst = wrpObj.county.split(';');
            retQuery += ' AND (IDN_APPLN__r.PRIOR_COUNTY__c IN (';
            for(String includeValue :countyLst){
                retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
                if(includeValue.length() == 1){	
                    includeValue = '0'+String.escapeSingleQuotes(includeValue);
                    retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ','; // added to include '1' and '01' both as county codes for CCCAP-14154/CCCAP-13978
                }
            }
            retQuery = retQuery.removeEnd(',')+')';  
            retQuery += ' OR (IDN_APPLN__r.PRIOR_COUNTY__c =NULL ';
            retQuery += ' AND CDE_COUNTY__c IN (';
            for(String includeValue :countyLst){
                retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ',';
                if(includeValue.length() == 1){	
                    includeValue = '0'+String.escapeSingleQuotes(includeValue);
                    retQuery +='\''+ String.escapeSingleQuotes(includeValue) +'\''+ ','; // added to include '1' and '01' both as county codes for CCCAP-14154/CCCAP-13978
                }
            }
            retQuery = retQuery.removeEnd(',')+')))'; 
            //system.debug('retQuery OR---'+retQuery);                  
        }
        if (wrpObj.fromDate!= null){
            Date frmDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.fromDate).remove('00:00:00')));
            retQuery += ' AND DTE_RCVD_REF__c >= :frmDate ';
        }
        if (wrpObj.toDate!= null){
            Date toEndDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.toDate).remove('00:00:00')));//Date.valueOf(String.valueOf(wrpObj.toDate).remove('00:00:00'));
            retQuery += ' AND DTE_RCVD_REF__c <= :toEndDate ';
        }
        if (wrpObj.referralType != null && wrpObj.referralType != ''){
            String referralType =String.escapeSingleQuotes(wrpObj.referralType);
            //system.debug('firstQuery-referralType---'+referralType);
            retQuery += ' AND (IDN_APPLN__r.CDE_CBMS_REF_TYP__c =:referralType )';
        }
        if(statuscheckforCounty){
            retQuery += ' AND (IDN_APPLN__r.CBMS_REF_REASON__c IN ('+'\''+ 'Inter County Transfer'+'\'' + ','+ '\''+ 'CW Case Closure'+'\')) ';
        }
        retQuery+= ' ORDER BY DTE_RCVD_REF__c ASC';

         // Apply dynamic LIMIT using getRemainingQueryRows() to prevent exceeding governor limits
        Integer remainingRows = getRemainingQueryRows();
        if(remainingRows > 0) {
            retQuery += ' LIMIT ' + remainingRows;
        }
        system.debug('Transfer Query---'+retQuery);
        return retQuery;
    }
    
    public static String appIndivQuery(CBMSInboxWrapper wrpObj, Set<Id> appCaseId, Set<Id> applIndivId){
        String secondQuery;
        
        if(wrpObj.searchType != null && wrpObj.searchType == 'SoundexSearch'){
            
            //Set<Id> applIndivId = new Set<Id>();
            applIndivId.addAll(doSoundexSearch(wrpObj, appCaseId));
            
            secondQuery = 'SELECT Id,NBR_SSN__c, NAM_FIRST__c,NAM_LAST__c, IDN_APPLN__c FROM  T_APPLN_INDIV__c Where IDN_APPLN__c IN:appCaseId AND id =:applIndivId AND IND_CRTKR_PRIM__c = \'Y\'';
            
            if(wrpObj.ssn != null && wrpObj.ssn != ''){
                secondQuery += ' AND NBR_SSN__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.ssn)+'%\'';
            }
            
        }else if(wrpObj.searchType != null && wrpObj.searchType == 'StringSearch'){
            secondQuery = 'SELECT Id,NBR_SSN__c, NAM_FIRST__c,NAM_LAST__c, IDN_APPLN__c FROM  T_APPLN_INDIV__c Where IDN_APPLN__c IN:appCaseId AND  IND_CRTKR_PRIM__c =  \'Y\'';
            
            /*if(wrpObj.ssn != null && wrpObj.ssn != ''){
                secondQuery += ' AND NBR_SSN__c LIKE ';
                secondQuery += '\'%'+wrpObj.ssn+'%\'';
            }*/
            if(wrpObj.firstName != null && wrpObj.firstName != ''){
                secondQuery += ' AND NAM_FIRST__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.firstName)+'%\'';
            }
            if(wrpObj.lastName != null && wrpObj.lastName != ''){
                secondQuery += ' AND NAM_LAST__c LIKE ';
                secondQuery += '\'%'+String.escapeSingleQuotes(wrpObj.lastName)+'%\'';
            }
        }
         // Apply dynamic LIMIT using getRemainingQueryRows() to prevent exceeding governor limits
        if(secondQuery != null) {
            Integer remainingRows = getRemainingQueryRows();
            if(remainingRows > 0) {
                secondQuery += ' LIMIT ' + remainingRows;
            }
        }
         
        //system.debug('secondQuery---'+secondQuery);
        return secondQuery;
    }
    
    public static List<CBMSResultWrapper> createCBMSResultWrapper(CBMSInboxWrapper wrpObj){
        specificCountiesSelected = wrpObj.county != null && wrpObj.county != '' && !wrpObj.county.split(';').contains('66');
        String firstQuery = CBMSInboxScreenCtrl.appProcessQueueQuery(wrpObj);
        String TransfcountyQuery;
        Date frmDate;
        Date toEndDate;
        Set<Id> applIndivId = new Set<Id>();
        String referralType;
        //applIndivId.addAll(doSoundexSearch(wrpObj));
        
        if(wrpObj.fromDate != null){
            frmDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.fromDate).remove('00:00:00')));	
        }
        if(wrpObj.toDate != null){
            toEndDate = Date.valueOf(String.escapeSingleQuotes(String.valueOf(wrpObj.toDate).remove('00:00:00')));
        }
        if (wrpObj.referralType != null && wrpObj.referralType != ''){
            referralType =String.escapeSingleQuotes(wrpObj.referralType);
            //system.debug('firstQuery-referralType---'+referralType);
        }
        List<Id> queueIds = new List<Id>();
        Map<Id,Map<Id,CBMSResultWrapper>> peakInboxResultMap = new Map<Id,Map<Id,CBMSResultWrapper>>();
        List<CBMSResultWrapper> CBMSResultWrapperLst = new List<CBMSResultWrapper>();
        Set<Id> appCaseId = new Set<Id>();
        Set<Id> secondAppCaseId = new Set<Id>();
        CBMSResultWrapper peakInboxRec;
        
        List<T_APPLN_PRCS_QUEUE__c> displayResult = new List<T_APPLN_PRCS_QUEUE__c>();
        List<T_APPLN_PRCS_QUEUE__c> transferCountyR = new List<T_APPLN_PRCS_QUEUE__c>();
        displayResult = Database.query(firstQuery);
        // Execute transfer county query - getRemainingQueryRows() is called inside appProcessQueueQuery
        if(statuscheckforCounty && specificCountiesSelected){
            // Only execute if we have remaining capacity
            if(getRemainingQueryRows() > 0) {
                TransfcountyQuery = CBMSInboxScreenCtrl.tranferQueuQuery(wrpObj);
                transferCountyR = Database.query(TransfcountyQuery);
                displayResult.addAll(transferCountyR);
            }
        } 
        system.debug('displayResult--'+displayResult);
        for(T_APPLN_PRCS_QUEUE__c queueRec : displayResult){
            queueIds.add(queueRec.Id);
            appCaseId.add(queueRec.IDN_APPLN__c);
            peakInboxRec = new CBMSResultWrapper();
            if(!peakInboxResultMap.containsKey(queueRec.IDN_APPLN__c)){
                peakInboxResultMap.put(queueRec.IDN_APPLN__c, new Map<Id,CBMSResultWrapper>());
            }
            peakInboxResultMap.get(queueRec.IDN_APPLN__c).put(queueRec.Id, peakInboxRec); 
            peakInboxRec.queuecounty =queueRec.County_Name__r.Name;
            peakInboxRec.appId =queueRec.Id;
            peakInboxRec.queueId =queueRec.Name;
            peakInboxRec.queuestatus =queueRec.CDE_STATUS_APPLN__c;
            peakInboxRec.referralId = String.valueOf(queueRec.IDN_APPLN__r.IDN_CBMS_REF__c); 
            peakInboxRec.queueReceivedDate = queueRec.DTE_RCVD_REF__c;
            peakInboxRec.queueCase = queueRec.IDN_CASE__r.Name;
            peakInboxRec.referralReason = queueRec.IDN_APPLN__r.CBMS_REF_REASON__c;
            peakInboxRec.referralType = queueRec.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
            //peakInboxRec.queueReason = queueRec.CDE_REJECT_APPLN__c;
        }
        
        List<T_APPLN_INDIV__c> displayIndividualResult = new List<T_APPLN_INDIV__c>();
        // Only execute individual query if we have remaining capacity
        if(getRemainingQueryRows() > 0) {
            // Build individual query - getRemainingQueryRows() is called inside appIndivQuery
            String secondQuery = CBMSInboxScreenCtrl.appIndivQuery(wrpObj, appCaseId, applIndivId);
            if(secondQuery != null) {
                displayIndividualResult = Database.query(secondQuery);
            }
        }
        for(T_APPLN_INDIV__c appIndiv: displayIndividualResult){
            secondAppCaseId.add(appIndiv.IDN_APPLN__c);
            for(Id queueId : peakInboxResultMap.get(appIndiv.IDN_APPLN__c).keySet()){
                peakInboxResultMap.get(appIndiv.IDN_APPLN__c).get(queueId).firstName = appIndiv.NAM_FIRST__c; 
                peakInboxResultMap.get(appIndiv.IDN_APPLN__c).get(queueId).lstName = appIndiv.NAM_LAST__c;   
            }
        }
        //system.debug('displayIndividualResult--'+displayIndividualResult);
        Map<Id, CBMSResultWrapper> appIdPeakResultWrpMap = new Map<Id, CBMSResultWrapper>();
        
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
                CBMSResultWrapperLst.add(appIdPeakResultWrpMap.get(prcQueueId));   
            } 
        }
        //system.debug('CBMSResultWrapperLst--'+CBMSResultWrapperLst);
        return CBMSResultWrapperLst;
    }
    
    private static Set<Id> doSoundexSearch(CBMSInboxWrapper peakSearchWrapper, Set<Id> appCaseId){
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
            // Apply dynamic LIMIT using getRemainingQueryRows() to prevent exceeding governor limits
            Integer remainingRows = getRemainingQueryRows();
            if(remainingRows > 0) {
                query += ' LIMIT ' + remainingRows;
                searchConditions = Database.query(query);
            }
        }
        if(searchConditions.size()>0){
            for(T_APPLN_INDIV__c appIndivRec : searchConditions){
                appIndivId.add(appIndivRec.Id);  
            }   
        }
        return appIndivId;
    }
}