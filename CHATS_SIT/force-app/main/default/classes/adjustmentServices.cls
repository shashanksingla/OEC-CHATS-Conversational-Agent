/*************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           09/11/2017
*  @description    Handler class for Adjustment Trigger
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 10-Dec-2017
*  * Author: Azharuddin Mohammad
*  * Description: Chat-680 - Event Based correspondence trigger - CR206

*  * Rishav : CCCAP-7647 - Updated test coverage to 88% (adjustmentTriggerTest)
*************************************************************************/
public with sharing class adjustmentServices {
    public static final String CR206RsnCode = 'CR0008';
    public static final String CR208RsnCode = 'CR0009';
    public static final String CR209RsnCode = 'CR0026';
    public static final String CLIENT = 'C';
    public static final String PROVIDER = 'P';
    public static final String newRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
    public static final String inProcessRecordTypeId = Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('In Process').getRecordTypeId();
    
	/**
    * @description Event Based correspondence trigger -CR206
    * @author Azharuddin Mohammad
    * @date 10-Dec-2017
    * @param Set<Id> newAdjustmentList - set of Adjustment Ids
    * @return void
    */    
    public static void triggerCorspdCR206(Map<Id, T_ADJMT__c> newAdjustmentList, Map<Id, T_ADJMT__c> oldAdjustmentList){
        Map<Id, T_ADJMT__c> adjmtMap = new Map<Id, T_ADJMT__c>([SELECT Id, Name, IDN_CASE__r.Name, CDE_COUNTY__r.CDE_COUNTY__c, IDN_PROVR__r.Name,
                                                                CDE_STATUS_ADJMT__c, CDE_TYPE_ADJMT__c, CHK_CR206ForceTrigger__c,
                                                                (SELECT Id,Name, ADR_LINE_1__c,Adjustment_Responsible_Party__c, Responsible_Party_Client_Id__c, Responsible_Party_Name__c,
                                                                 ADR_LINE_2__c, ADR_CITY__c, toLabel(ADR_STATE__c), ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c FROM Adjustment__r) 
                                                                FROM T_ADJMT__c WHERE Id IN:newAdjustmentList.keySet()]);
        Map<string,string> keyParams;
        String sendTo;
        Integer countyCode;
        System.debug('The adjmt Map -->'+adjmtMap);
        System.debug('The old Adjmnt Map -->'+oldAdjustmentList);
        Set<Id> recordKeys = new Set<Id>();
        Set<Id> recordKeys2 = new Set<Id>(); // Added by Rishav for CCCAP-7019
        Map<Id, String> rsnCodeMap = new Map<Id, String>();
        Map<Id, String> corspdnameMap = new Map<Id, String>();
        Map<Id, String> sendToMap = new Map<Id, String>();
        Map<Id, Integer> countyCodeMap = new Map<Id, Integer>();
        Map<Id, Map<string,string>> keyParamsMap = new Map<Id, Map<string,string>>();
        Map<Id, Set<Id>> adjustmentAddressMap = new Map<Id, Set<Id>>();
        List<T_ADJMT__c> adjmtListToUpdate = new List<T_ADJMT__c>();
        
        // Start: Added by Rishav for CCCAP-7019
        Map<Id, Map<String, String>> keyParamsMap2 = new Map<Id, Map<String, String>>();
        Map<String, String> keyParams2;
        Map<Id, String> rsnCodeMap2 = new Map<Id, String>();
        Set<Id> adjTotriggerCR207 = new Set<Id>(); // Added by Rishav for CCCAP-7570
        Set<String> respPartySFID = new Set<String>();
        for(Id eachAdjmt : adjmtMap.keySet()){
            for(T_ADJMT_ADDR__c resp :adjmtMap.get(eachAdjmt).Adjustment__r){
                respPartySFID.add(resp.Responsible_Party_Client_Id__c);
            }
        }
        Map<Id, T_SBSD_INDIV__c> clientIdNameMap = new Map<Id, T_SBSD_INDIV__c>([SELECT Id, Name FROM T_SBSD_INDIV__c WHERE Id IN: respPartySFID]);
        // End: CCCAP-7019
        // Start: Added by Rishav for CCCAP-7570
        Set<String> adjWithExistingCR206 = new Set<String>();
        Set<String> adjWithExistingCR207 = new Set<String>();
        for(T_DOC_RQ__c corr : [SELECT Id, IDN_ADJMT__c, IDN_CASE__c, IDN_PROVR__c, NME_CORSPD__c FROM T_DOC_RQ__c WHERE NME_CORSPD__c IN ('CR206', 'CR207') AND CDE_CORSPD_STATUS__c = 'Requested' AND IDN_ADJMT__c IN :newAdjustmentList.keySet()]){
            if(adjmtMap.containsKey(corr.IDN_ADJMT__c) && corr.NME_CORSPD__c == 'CR206'){
                adjWithExistingCR206.add(corr.IDN_ADJMT__c);
            }
            if(adjmtMap.containsKey(corr.IDN_ADJMT__c) && corr.NME_CORSPD__c == 'CR207'){
                adjWithExistingCR207.add(corr.IDN_ADJMT__c);
            }
        }
        // End: CCCAP-7570

        for(Id eachAdjmt : adjmtMap.keySet()){
            keyParams = new Map<string, string>();
            keyParams2 = new Map<String, String>(); // Added by Rishav for CCCAP-7019
            Set<Id> adjustmentAdd = new Set<Id>();
            if((adjmtMap.get(eachAdjmt).CDE_STATUS_ADJMT__c == '2') && (adjmtMap.get(eachAdjmt).CDE_STATUS_ADJMT__c != oldAdjustmentList.get(eachAdjmt).CDE_STATUS_ADJMT__c) && (adjmtMap.get(eachAdjmt).CDE_TYPE_ADJMT__c == '2')) { //Calculation Complete
                for(T_ADJMT_ADDR__c resp :adjmtMap.get(eachAdjmt).Adjustment__r){
                    adjustmentAdd.add(resp.Id);
                    keyParams = new Map<string, string>();
                    keyParams2 = new Map<String, String>(); // Added by Rishav for CCCAP-7019
                    keyParams.put('AdjustmentAddress', resp.Id);
                    if(adjmtMap.get(eachAdjmt).CDE_COUNTY__c != NULL){
                        decimal cntyCode = adjmtMap.get(eachAdjmt).CDE_COUNTY__r.CDE_COUNTY__c;
                        countyCode = Integer.valueOf(cntyCode);
                    }
                    keyParams.put('adjmtId', eachAdjmt); // adjmtMap.get(eachAdjmt).Name
                    keyParams2.put('adjmtId', eachAdjmt); // Added by Rishav for CCCAP-7019
                    if(adjmtMap.get(eachAdjmt).IDN_CASE__c != NULL) {
                        //sendTo = CLIENT;
                        keyParams.put('caseId', adjmtMap.get(eachAdjmt).IDN_CASE__r.Name);
                        keyParams2.put('caseId', adjmtMap.get(eachAdjmt).IDN_CASE__r.Name); // Added by Rishav for CCCAP-7019
                        keyParams2.put('clientId', clientIdNameMap.get(resp.Responsible_Party_Client_Id__c)?.Name); // Added by Rishav for CCCAP-7019
                    } else if(adjmtMap.get(eachAdjmt).IDN_PROVR__r != NULL) {
                        //sendTo = PROVIDER;
                        keyParams.put('providerId', adjmtMap.get(eachAdjmt).IDN_PROVR__r.Name);
                        keyParams2.put('providerId', adjmtMap.get(eachAdjmt).IDN_PROVR__r.Name); // Added by Rishav for CCCAP-7019
                    }
                    recordKeys.add(eachAdjmt);
                    recordKeys2.add(eachAdjmt); // Added by Rishav for CCCAP-7019
                    rsnCodeMap.put(eachAdjmt, CR206RsnCode);
                    corspdnameMap.put(eachAdjmt, NULL);
                    sendToMap.put(eachAdjmt, sendTo);
                    countyCodeMap.put(eachAdjmt, countyCode);
                }
                keyParamsMap.put(eachAdjmt, keyParams); 
                adjustmentAddressMap.put(eachAdjmt,adjustmentAdd); 
                rsnCodeMap2.put(eachAdjmt, 'CR0020'); // Added by Rishav for CCCAP-7019
                keyParamsMap2.put(eachAdjmt, keyParams2); // Added by Rishav for CCCAP-7019
                adjTotriggerCR207.add(eachAdjmt); // Added by Rishav for CCCAP-7570
            } else if((adjmtMap.get(eachAdjmt).CDE_STATUS_ADJMT__c == '3') && (adjmtMap.get(eachAdjmt).CDE_STATUS_ADJMT__c != oldAdjustmentList.get(eachAdjmt).CDE_STATUS_ADJMT__c) && (adjmtMap.get(eachAdjmt).CDE_TYPE_ADJMT__c == '2')) { //Satisfied
                for(T_ADJMT_ADDR__c resp :adjmtMap.get(eachAdjmt).Adjustment__r){
                    adjustmentAdd.add(resp.Id);
                    keyParams = new Map<string, string>();
                    keyParams.put('AdjustmentAddress', resp.Id); 
                    if(adjmtMap.get(eachAdjmt).CDE_COUNTY__c != NULL){
                        decimal cntyCode = adjmtMap.get(eachAdjmt).CDE_COUNTY__r.CDE_COUNTY__c;
                        countyCode = Integer.valueOf(cntyCode);
                    }
                    keyParams.put('adjmtId', eachAdjmt); // adjmtMap.get(eachAdjmt).Name
                    if(adjmtMap.get(eachAdjmt).IDN_CASE__c != NULL){
                        //sendTo = CLIENT;
                        keyParams.put('caseId', adjmtMap.get(eachAdjmt).IDN_CASE__r.Name);    
                    }else if(adjmtMap.get(eachAdjmt).IDN_PROVR__r != NULL){
                        //sendTo = PROVIDER;
                        keyParams.put('providerId', adjmtMap.get(eachAdjmt).IDN_PROVR__r.Name); 
                    }
                    recordKeys.add(eachAdjmt);
                    rsnCodeMap.put(eachAdjmt, CR208RsnCode);
                    corspdnameMap.put(eachAdjmt, NULL);
                    sendToMap.put(eachAdjmt, sendTo);
                    countyCodeMap.put(eachAdjmt, countyCode);
                }
                keyParamsMap.put(eachAdjmt, keyParams);
                adjustmentAddressMap.put(eachAdjmt,adjustmentAdd);
            } else if(adjmtMap.get(eachAdjmt).CDE_TYPE_ADJMT__c == '2' && adjmtMap.get(eachAdjmt).CHK_CR206ForceTrigger__c == true) { // Recovery + Flag is true
                // Added else if condition to generate CR206 on every edit of a Calculation Complete Recovery by Rishav for CCCAP-6051
                for(T_ADJMT_ADDR__c resp :adjmtMap.get(eachAdjmt).Adjustment__r){
                    adjustmentAdd.add(resp.Id);
                    keyParams = new Map<string, string>();
                    keyParams2 = new Map<String, String>(); // Added by Rishav for CCCAP-7019
                    keyParams.put('AdjustmentAddress', resp.Id);
                    if(adjmtMap.get(eachAdjmt).CDE_COUNTY__c != NULL){
                        decimal cntyCode = adjmtMap.get(eachAdjmt).CDE_COUNTY__r.CDE_COUNTY__c;
                        countyCode = integer.valueOf(cntyCode);
                    }
                    keyParams.put('adjmtId', eachAdjmt);
                    keyParams2.put('adjmtId', eachAdjmt); // Added by Rishav for CCCAP-7019
                    if(adjmtMap.get(eachAdjmt).IDN_CASE__c != NULL) {
                        keyParams.put('caseId', adjmtMap.get(eachAdjmt).IDN_CASE__r.Name);
                        keyParams2.put('caseId', adjmtMap.get(eachAdjmt).IDN_CASE__r.Name); // Added by Rishav for CCCAP-7019
                        keyParams2.put('clientId', clientIdNameMap.get(resp.Responsible_Party_Client_Id__c)?.Name); // Added by Rishav for CCCAP-7019
                    } else if(adjmtMap.get(eachAdjmt).IDN_PROVR__r != NULL) {
                        keyParams.put('providerId', adjmtMap.get(eachAdjmt).IDN_PROVR__r.Name);
                        keyParams2.put('providerId', adjmtMap.get(eachAdjmt).IDN_PROVR__r.Name); // Added by Rishav for CCCAP-7019
                    }
                    if(!adjWithExistingCR206.contains((String)eachAdjmt)){ // Added by Rishav for CCCAP-7570
                        recordKeys.add(eachAdjmt);
                    }
                    recordKeys2.add(eachAdjmt); // Added by Rishav for CCCAP-7019
                    rsnCodeMap.put(eachAdjmt, CR206RsnCode);
                    corspdnameMap.put(eachAdjmt, NULL);
                    sendToMap.put(eachAdjmt, sendTo);
                    countyCodeMap.put(eachAdjmt, countyCode);
                }
                keyParamsMap.put(eachAdjmt, keyParams);
                adjustmentAddressMap.put(eachAdjmt, adjustmentAdd);
                rsnCodeMap2.put(eachAdjmt, 'CR0020'); // Added by Rishav for CCCAP-7019
                keyParamsMap2.put(eachAdjmt, keyParams2); // Added by Rishav for CCCAP-7019
                adjTotriggerCR207.add(eachAdjmt); // Added by Rishav for CCCAP-7570
                T_ADJMT__c adjToUpdate = adjmtMap.get(eachAdjmt);
                adjToUpdate.CHK_CR206ForceTrigger__c = false;
                adjmtListToUpdate.add(adjToUpdate);
            }
        }
        if(!adjmtListToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(adjmtListToUpdate, new Map<String, Object>{'Class__c'=>'adjustmentServices','Method__c'=>'triggerCorspdCR206'});
        }
        if(recordKeys.size() > 0){
            CorspdTrigger.createCorspdRequestBulk(recordKeys, rsnCodeMap, corspdnameMap, sendToMap, countyCodeMap, keyParamsMap, adjustmentAddressMap);
        }
        // Start: Added by Rishav for CCCAP-7019
        for(Id eachAdjmt : adjTotriggerCR207){
            if(!adjWithExistingCR207.contains((String)eachAdjmt)){  // Added by Rishav for CCCAP-7570
                if(adjmtMap.get(eachAdjmt).IDN_CASE__c != NULL){
                    for(T_ADJMT_ADDR__c resp : adjmtMap.get(eachAdjmt).Adjustment__r){
                        recordKeys2 = new Set<Id>{eachAdjmt};
                        keyParamsMap2.get(eachAdjmt).put('clientId', clientIdNameMap.get(resp.Responsible_Party_Client_Id__c)?.Name);
                        CorspdTrigger.createCorspdRequestBulk(recordKeys2, rsnCodeMap2, corspdnameMap, sendToMap, countyCodeMap, keyParamsMap2, adjustmentAddressMap);
                    }
                } else {
                    CorspdTrigger.createCorspdRequestBulk(recordKeys2, rsnCodeMap2, corspdnameMap, sendToMap, countyCodeMap, keyParamsMap2, adjustmentAddressMap);
                }
            }
        }
        // End: CCCAP-7019
    }
    
    public static void deleteAllChildAdjustmentRecords(List<T_ADJMT__c> adjustmentDeleteList) {       
        Set<Id> adjustmentIds = new Set<Id>();
        for(T_ADJMT__c admnt:adjustmentDeleteList) {
            if(admnt.RecordtypeId==newRecordTypeId || admnt.RecordtypeId==inProcessRecordTypeId ) {
                adjustmentIds.add(admnt.Id);
            }
        }
        if(adjustmentIds.size()>0) {
            Savepoint sp = Database.setSavepoint();
            try{
                //delete [Select Id from T_ADJMT_RESPBL_PARTY__c where IDN_ADJMT__c IN:adjustmentIds];
                GenericDMLHandler.deleteRecords([Select Id from T_ADJMT_RESPBL_PARTY__c where IDN_ADJMT__c IN:adjustmentIds], null);
                //delete [Select Id from T_ADJMT_ADDR__c where IDN_ADJMT__c IN:adjustmentIds];
                GenericDMLHandler.deleteRecords([Select Id from T_ADJMT_ADDR__c where IDN_ADJMT__c IN:adjustmentIds], null);
                //delete [Select Id from T_ADJMT_CMT__c where IDN_ADJMT__c IN:adjustmentIds];
                GenericDMLHandler.deleteRecords([Select Id from T_ADJMT_CMT__c where IDN_ADJMT__c IN:adjustmentIds], null);
            } catch(Exception ex) {
                System.debug(ex.getMessage());
                Database.rollback(sp);
                Map<String,Object> exceptionMap = new Map<String,Object>();
                exceptionMap.put('Class__c','adjustmentServices');
                exceptionMap.put('Method__c','deleteAllChildAdjustmentRecords');
                ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
                for(T_ADJMT__c admnt:adjustmentDeleteList) {
                    admnt.addError('Unable to delete its child records');
                }
            }
        }  
    }
    
    public static void triggerCorspdCR209(List<T_ADJMT__c> newAdjustmentList, Map<Id, T_ADJMT__c> oldMap){
        Map<string,string> keyParams;
        String sendTo;
        Integer countyCode;
        Set<Id> recordKeys = new Set<Id>();
        Map<Id, String> rsnCodeMap = new Map<Id, String>();
        Map<Id, String> corspdnameMap = new Map<Id, String>();
        Map<Id, String> sendToMap = new Map<Id, String>();
        Map<Id, Integer> countyCodeMap = new Map<Id, Integer>();
        Map<Id, Map<string,string>> keyParamsMap = new Map<Id, Map<string,string>>();
        Map<Id, Set<Id>> adjustmentAddressMap = new Map<Id, Set<Id>>();
        Map<Id, Set<String>> respPartyMap = new Map<Id, Set<String>>();
        Set<String> allRespPartyId = new Set<String>();
        Map<Id, String> cancelRsnMap = new Map<Id, String>();
        List<T_ADJMT__c> cancelledAdjList = new List<T_ADJMT__c>();
        for(T_ADJMT__c adj : newAdjustmentList){
            if(adj.CDE_TYPE_ADJMT__c == '2' && adj.CDE_STATUS_ADJMT__c == '6' && oldMap.get(adj.Id).CDE_STATUS_ADJMT__c != '6'){
                cancelledAdjList.add(adj);
            }
        }
        for(T_ADJMT_CANCEL__c adjCancel : [SELECT IDN_ADJMT__c, CDE_RSN_CANCELLATION__c FROM T_ADJMT_CANCEL__c
                                           WHERE IDN_ADJMT__c IN :cancelledAdjList
                                           AND CDE_STATUS__c = '3' order by LastModifiedDate desc]){
                                               if(!cancelRsnMap.containsKey(adjCancel.IDN_ADJMT__c)) {
                                                   cancelRsnMap.put(adjCancel.IDN_ADJMT__c, adjCancel.CDE_RSN_CANCELLATION__c);
                                               }                                              
                                           }
        Map<Id, T_ADJMT__c> adjmtMap = new Map<Id, T_ADJMT__c>([SELECT Id, Name, IDN_CASE__r.Name, CDE_COUNTY__r.CDE_COUNTY__c, IDN_PROVR__r.Name,
                                                                CDE_STATUS_ADJMT__c, CDE_TYPE_ADJMT__c,
                                                                (SELECT Id,Name, ADR_LINE_1__c,Adjustment_Responsible_Party__c, Responsible_Party_Client_Id__c, Responsible_Party_Name__c,
                                                                 ADR_LINE_2__c, ADR_CITY__c, toLabel(ADR_STATE__c), ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c FROM Adjustment__r)
                                                                FROM T_ADJMT__c WHERE Id IN :cancelledAdjList]);
        for(Id eachAdjmt : adjmtMap.keySet()){
            for(T_ADJMT_ADDR__c resp : adjmtMap.get(eachAdjmt).Adjustment__r){
                allRespPartyId.add(resp.Responsible_Party_Client_Id__c);
                if(respPartyMap.containsKey(eachAdjmt)){
                    Set<String> clientList = respPartyMap.get(eachAdjmt);
                    if(!clientList.contains(resp.Responsible_Party_Client_Id__c)){
                        clientList.add(resp.Responsible_Party_Client_Id__c);
                    }
                    respPartyMap.put(eachAdjmt, clientList);
                } else {
                    Set<String> clientList = new Set<String>{resp.Responsible_Party_Client_Id__c};
                    respPartyMap.put(eachAdjmt, clientList);
                }
            }
        }
        
        Map<Id, T_SBSD_INDIV__c> clientIdNameMap = new Map<Id, T_SBSD_INDIV__c>([SELECT Id, Name FROM T_SBSD_INDIV__c WHERE Id IN: allRespPartyId]);
        
        for(T_ADJMT__c adj : cancelledAdjList){
            keyParams = new Map<string, string>();
            Set<Id> adjustmentAdd = new Set<Id>();
            if(adj.CDE_TYPE_ADJMT__c == '2' && adj.CDE_STATUS_ADJMT__c == '6' && oldMap.get(adj.Id).CDE_STATUS_ADJMT__c != '6' && cancelRsnMap.get(adj.id) != '2'){
                keyParams = new Map<string, string>();
                if(adj.CDE_COUNTY__c != NULL){
                    decimal cntyCode = adjmtMap.get(adj.Id).CDE_COUNTY__r.CDE_COUNTY__c;
                    countyCode = Integer.valueOf(cntyCode);
                }
                keyParams.put('adjmtId', adj.Id); // adjmtMap.get(eachAdjmt).Name
                if(adjmtMap.get(adj.Id).IDN_CASE__c != NULL) { // sendTo = CLIENT;
                    keyParams.put('caseId', adjmtMap.get(adj.Id).IDN_CASE__r.Name);
                } else if(adjmtMap.get(adj.Id).IDN_PROVR__r != NULL) { // sendTo = PROVIDER;
                    keyParams.put('providerId', adjmtMap.get(adj.Id).IDN_PROVR__r.Name);
                }
                recordKeys.add(adj.Id);
                rsnCodeMap.put(adj.Id, CR209RsnCode);
                corspdnameMap.put(adj.Id, NULL);
                sendToMap.put(adj.Id, sendTo);
                countyCodeMap.put(adj.Id, countyCode);
            }
            keyParamsMap.put(adj.Id, keyParams); 
            adjustmentAddressMap.put(adj.Id, adjustmentAdd);
        }
        if(recordKeys.size() > 0){
            for(Id eachAdjmt : adjmtMap.keySet()){
                if(adjmtMap.get(eachAdjmt).IDN_CASE__c != NULL){
                    for(String clientId : respPartyMap.get(eachAdjmt)){
                        recordKeys = new Set<Id>{eachAdjmt};
                        keyParamsMap.get(eachAdjmt).put('clientId', clientIdNameMap.get(clientId)?.Name);
                        CorspdTrigger.createCorspdRequestBulk(recordKeys, rsnCodeMap, corspdnameMap, sendToMap, countyCodeMap, keyParamsMap, adjustmentAddressMap);
                    }
                } else {
                    CorspdTrigger.createCorspdRequestBulk(recordKeys, rsnCodeMap, corspdnameMap, sendToMap, countyCodeMap, keyParamsMap, adjustmentAddressMap);
                }
            }
        }
    }
    
    // CCCAP-2805 Changes for Provider status check for the Claim type Adjustment based on Care dates
    public static void providerStatusCheck(List<T_ADJMT__c>  newAdjustmentList, map<Id, T_ADJMT__c> oldAdjustmentList){
        system.debug('The old Adjmnt Map -->'+oldAdjustmentList);
        system.debug('The new Adjmnt Map -->'+newAdjustmentList);
        Set<Id> providerIds = new Set<Id>();
        Map<Id,List<T_CHATS_PROVR_STATUS__History>> providerHistMap = new Map<Id,List<T_CHATS_PROVR_STATUS__History>>();
        Map<Id,String> providerMap = new Map<Id,String>();
        Map<Id,T_CHATS_PROVR_STATUS__c> providerDetailsMap = new Map<Id,T_CHATS_PROVR_STATUS__c>();
        if(newAdjustmentList!= null && newAdjustmentList.size()>0){
            for(T_ADJMT__c eachAdjmt: newAdjustmentList){
                providerIds.add(eachAdjmt.IDN_PROVR__c);
            }   
        }
        for(T_CHATS_PROVR_STATUS__c prov:[SELECT ID,CDE_STATUS_PROVR__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c  from T_CHATS_PROVR_STATUS__c where id IN:providerIds]){
            providerMap.put(prov.id, prov.CDE_STATUS_PROVR__c);
            providerDetailsMap.put(prov.id, prov);
        }
        system.debug('providerIds--'+providerIds);
        List<T_CHATS_PROVR_STATUS__History> providerHistLst = new List<T_CHATS_PROVR_STATUS__History>();
        if(providerIds!= null && providerIds.size()>0){
            for(T_CHATS_PROVR_STATUS__History obj :[SELECT ParentId, OldValue, NewValue, Field, CreatedById, CreatedDate FROM T_CHATS_PROVR_STATUS__History where parentId IN:providerIds and Field = 'CDE_STATUS_PROVR__c' order by CreatedDate ASC]){
                if(providerHistMap.containsKey(obj.ParentId)){
                    List<T_CHATS_PROVR_STATUS__History> lst = providerHistMap.get(obj.ParentId);
                    lst.add(obj);
                    providerHistMap.put(obj.ParentId,lst);
                }else{
                    List<T_CHATS_PROVR_STATUS__History> lst = new List<T_CHATS_PROVR_STATUS__History>();
                    lst.add(obj);
                    providerHistMap.put(obj.ParentId,lst); 
                }                
            }
        }
        system.debug('providerHistMap--'+providerHistMap);
        for(T_ADJMT__c eachAdjmt: newAdjustmentList){
            if((eachAdjmt.CDE_STATUS_ADJMT__c == '1') && (eachAdjmt.CDE_TYPE_ADJMT__c == '1')) { //Calculation Complete
                if(providerHistMap.containsKey(eachAdjmt.IDN_PROVR__c)){
                    Map<Date,List<T_CHATS_PROVR_STATUS__History>> histMap = new Map<Date,List<T_CHATS_PROVR_STATUS__History>>();
                    List<T_CHATS_PROVR_STATUS__History> providHist= new List<T_CHATS_PROVR_STATUS__History>();
                    //New Code
                    List<T_CHATS_PROVR_STATUS__History> histLst= providerHistMap.get(eachAdjmt.IDN_PROVR__c);
                    Integer recordCount = histLst.size();
                    recordCount =recordCount-1;
                    system.debug('recordCount--'+recordCount);
                    DateTime dt1 = DateTime.newInstanceGmt(histLst[0].CreatedDate.Year(), histLst[0].CreatedDate.Month(), histLst[0].CreatedDate.day(),histLst[0].CreatedDate.hour(), histLst[0].CreatedDate.minute(), histLst[0].CreatedDate.second());
                    Date tempDT1 = date.newinstance(dt1.year(), dt1.month(), dt1.day());
                    DateTime dt2 = DateTime.newInstanceGmt(histLst[recordCount].CreatedDate.Year(), histLst[recordCount].CreatedDate.Month(), histLst[recordCount].CreatedDate.day(),histLst[recordCount].CreatedDate.hour(), histLst[recordCount].CreatedDate.minute(), histLst[recordCount].CreatedDate.second());
                    Date tempDT2 = date.newinstance(dt2.year(), dt2.month(), dt2.day());
                    system.debug('tempDT1--'+tempDT1);
                    system.debug('histLst[0].OldValue--'+histLst[0].OldValue);
                    if(tempDT1>eachAdjmt.DTE_START_ADJMT__c && tempDT1 > eachAdjmt.DTE_END_ADJMT__c) {
                        if(histLst[0].OldValue =='Closed'){
                            eachAdjmt.addError('Adjustment cannot be created for the care dates when provider license status is closed');
                        }
                    } else if(tempDT2<eachAdjmt.DTE_START_ADJMT__c && tempDT2  <eachAdjmt.DTE_END_ADJMT__c) {
                        if(histLst[recordCount].NewValue =='Closed'){
                            eachAdjmt.addError('Adjustment cannot be created for the care dates when provider license status is closed');
                        }
                    } else {
                        List<T_CHATS_PROVR_STATUS__History> providerHistList = providerHistMap.get(eachAdjmt.IDN_PROVR__c);
                        if(providerHistList!= null && providerHistList.size()>0){
                            for(Integer i=0;i<providerHistList.size();i++){
                                T_CHATS_PROVR_STATUS__History hist = providerHistList[i];
                                system.debug('CreatedDate--'+hist.CreatedDate);
                                DateTime dt = DateTime.newInstanceGmt(hist.CreatedDate.Year(), hist.CreatedDate.Month(), hist.CreatedDate.day(),hist.CreatedDate.hour(), hist.CreatedDate.minute(), hist.CreatedDate.second());
                                Date tempDT = date.newinstance(dt.year(), dt.month(), dt.day());
                                system.debug('dt---'+dt);
                                Date nextRecordDate ;
                                system.debug('i=='+i);
                                system.debug('size=='+recordCount);
                                Integer j=i+1;
                                system.debug('j---'+j);
                                if(j<=recordCount){
                                    DateTime dtnext = DateTime.newInstanceGmt(providerHistList[i+1].CreatedDate.Year(), providerHistList[i+1].CreatedDate.Month(), providerHistList[i+1].CreatedDate.day(),providerHistList[i+1].CreatedDate.hour(), providerHistList[i+1].CreatedDate.minute(), providerHistList[i+1].CreatedDate.second());
                                    nextRecordDate = date.newinstance(providerHistList[i+1].CreatedDate.year(), providerHistList[i+1].CreatedDate.month(), providerHistList[i+1].CreatedDate.day());
                                }
                                system.debug('tempDT=='+tempDT);
                                system.debug('nextRecordDate--'+nextRecordDate);
                                system.debug('start date--'+eachAdjmt.DTE_START_ADJMT__c);
                                system.debug('end date--'+eachAdjmt.DTE_END_ADJMT__c);
                                if((tempDT>=eachAdjmt.DTE_START_ADJMT__c && tempDT<=eachAdjmt.DTE_END_ADJMT__c && hist.NewValue =='Closed') ||
                                   (tempDT<=eachAdjmt.DTE_START_ADJMT__c && nextRecordDate>eachAdjmt.DTE_END_ADJMT__c && hist.NewValue =='Closed')|| 
                                   (tempDT<=eachAdjmt.DTE_START_ADJMT__c && nextRecordDate>eachAdjmt.DTE_START_ADJMT__c && nextRecordDate<eachAdjmt.DTE_END_ADJMT__c && hist.NewValue =='Closed') ||
                                   (tempDT<=eachAdjmt.DTE_START_ADJMT__c && nextRecordDate>eachAdjmt.DTE_START_ADJMT__c && nextRecordDate>=eachAdjmt.DTE_END_ADJMT__c &&  hist.NewValue =='Closed') ){
                                       system.debug('satisfied--'+hist);
                                       if(nextRecordDate!=tempDT){
                                           eachAdjmt.addError('Adjustment cannot be created for the care dates when provider license status is closed');
                                       } else {
                                           if(providerHistList[i+1].NewValue =='Closed'){
                                               eachAdjmt.addError('Adjustment cannot be created for the care dates when provider license status is closed');
                                           }
                                       }
                                   }
                            }
                        }
                        Boolean isStatusClosed = false;
                    }
                    //End
                } else {
                    if(providerMap.containsKey(eachAdjmt.IDN_PROVR__c) && providerMap.get(eachAdjmt.IDN_PROVR__c) == 'Closed'){
                        eachAdjmt.addError('Adjustment cannot be created for the care dates when provider license status is closed');
                    }
                }
            }
        }
    }
    // Added by Shashank for CCCAP-12974
    public static void updateManualClaimRecord(List<T_ADJMT__c> newAdjustmentList, Map<Id, T_ADJMT__c> oldMap){
        Set<Id>paidAdjIds = new Set<Id>();
        List<Provider_Manual_Claim__c>manualClaimsToUpdate = new List<Provider_Manual_Claim__c>();
        for(T_ADJMT__c adj : newAdjustmentList){
            if(adj.CDE_STATUS_ADJMT__c == '4' && adj.CDE_STATUS_ADJMT__c != oldMap.get(adj.Id).CDE_STATUS_ADJMT__c){
                paidAdjIds.add(adj.Id);
            }
        }
        for(Provider_Manual_Claim__c claim : [select id from Provider_Manual_Claim__c where Adjustment__c in :paidAdjIds 
                                              AND Claim_Status__c NOT IN('Cancelled','Paid','Denied')]){
            claim.Claim_Status__c = 'Paid';
            manualClaimsToUpdate.add(claim);
        }
        if(!manualClaimsToUpdate.isEmpty()){
            Update manualClaimsToUpdate;
        }
    }
    // Added by Raina for CCCAP-7029/ Modified for CCCAP-7657
    public static void updateTaxInterceptFields(List<T_ADJMT__c> newAdjustmentList, Map<Id, T_ADJMT__c> oldMap){
        Set<Id> adjIds = new Set<Id>();
        Set<Id> uncancelledAdjId = new Set<Id>();
        List<Tax_Intercept__c> taxToUpdate = new List<Tax_Intercept__c>();
        
        for(T_ADJMT__c adj : newAdjustmentList){
            if(adj.CDE_STATUS_ADJMT__c == '5' && oldMap.get(adj.Id).CDE_STATUS_ADJMT__c != '5'){
                adjIds.add(adj.Id);
            }
            if(adj.CDE_STATUS_ADJMT__c == '2' && oldMap.get(adj.Id).CDE_STATUS_ADJMT__c == '5'){
                uncancelledAdjId.add(adj.Id);
            }
        }

        If(!adjIds.isEmpty()){
            for(Tax_Intercept__c tax : [SELECT Id, Adjustment__c, SEND_UPDATE_TO_CDOR__c, Current_Balance__c,Intercept_Status__c FROM Tax_Intercept__c WHERE Adjustment__c IN :adjIds]){
                If(tax.Intercept_Status__c != 'Expired'){
                    tax.SEND_UPDATE_TO_CDOR__c = true;
                    tax.Current_Balance__c = 0;
                    taxToUpdate.add(tax);
                }
            }
        }else if(!uncancelledAdjId.isEmpty()){
            for(Tax_Intercept__c updTax : [SELECT Id, Adjustment__c, SEND_UPDATE_TO_CDOR__c, Current_Balance__c,Intercept_Status__c, Adjustment__r.AMT_ADJMT__c FROM Tax_Intercept__c WHERE Adjustment__c IN :uncancelledAdjId]){
                 If(updTax.Intercept_Status__c != 'Expired'){
                        updTax.SEND_UPDATE_TO_CDOR__c = true;
                        updTax.Current_Balance__c = updTax.Adjustment__r.AMT_ADJMT__c;
                        updTax.CDOR_RECORD_TYPE__c ='A'; //Value 'A' means Add the intercept record for CDOR
                        taxToUpdate.add(updTax);
                 }
            }
        }
        
        if(!taxToUpdate.isEmpty()){
            Update taxToUpdate;
        }
    }

    // Added by Diya as part of CCCAP-6369
  /*  public static void duplicateAdjustmentCheck(List<T_ADJMT__c>  newAdjustmentList){
        Set<Id> providerIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        List<T_ADJMT__c>  oldAdjustmentList = new List<T_ADJMT__c>();
        Map<Id,String> providerMap = new Map<Id,String>();
        Id recordTypeId =Schema.SObjectType.T_ADJMT__c.getRecordTypeInfosByName().get('Finalized').getRecordTypeId();
        Date beginDateFilter;
        Date endDateFilter;
        if(newAdjustmentList!= null && newAdjustmentList.size()>0){
            for(T_ADJMT__c eachAdjmt: newAdjustmentList){
                providerIds.add(eachAdjmt.IDN_PROVR__c);
                caseIds.add(eachAdjmt.IDN_CASE__c);
                if(beginDateFilter != null && beginDateFilter > eachAdjmt.DTE_START_ADJMT__c){
                     beginDateFilter= eachAdjmt.DTE_START_ADJMT__c;
                }else if(beginDateFilter == null){
                    beginDateFilter= eachAdjmt.DTE_START_ADJMT__c;
                }
                
                if(endDateFilter != null && endDateFilter < eachAdjmt.DTE_END_ADJMT__c){
                     endDateFilter= eachAdjmt.DTE_END_ADJMT__c;
                }else if(beginDateFilter == null){
                    endDateFilter= eachAdjmt.DTE_END_ADJMT__c;
                }
            }   
        }
        oldAdjustmentList = [Select id,DTE_START_ADJMT__c,IDN_CASE__c,IDN_PROVR__c,DTE_END_ADJMT__c,CDE_COUNTY__c,CDE_TYPE_ADJMT__c,CDE_AGNST_ADJMT__c from T_ADJMT__c where (IDN_CASE__c in :caseIds or IDN_PROVR__c in :providerIds) and
                              ((DTE_START_ADJMT__c >=:beginDateFilter and  DTE_END_ADJMT__c <=:endDateFilter) or
                              (DTE_START_ADJMT__c <=:beginDateFilter and DTE_END_ADJMT__c >=:beginDateFilter) or
                            (DTE_END_ADJMT__c >=:beginDateFilter and DTE_END_ADJMT__c <=:endDateFilter))];
        for(T_ADJMT__c newAdj : newAdjustmentList){
            for(T_ADJMT__c oldAdj : oldAdjustmentList){
                if(
                    ((newAdj.IDN_CASE__c == oldAdj.IDN_CASE__c && oldAdj.IDN_CASE__c!= null && newAdj.IDN_CASE__c != null) || (newAdj.IDN_PROVR__c == oldAdj.IDN_PROVR__c && oldAdj.IDN_PROVR__c!= null && newAdj.IDN_PROVR__c != null)) && 
                    (newAdj.CDE_COUNTY__c == oldAdj.CDE_COUNTY__c) &&                    
                    (newAdj.CDE_TYPE_ADJMT__c == oldAdj.CDE_TYPE_ADJMT__c) &&
                     (newAdj.CDE_AGNST_ADJMT__c == oldAdj.CDE_AGNST_ADJMT__c) &&
                   ( (newAdj.DTE_START_ADJMT__c <= oldAdj.DTE_START_ADJMT__c && newAdj.DTE_END_ADJMT__c >= oldAdj.DTE_START_ADJMT__c) ||
                     (newAdj.DTE_START_ADJMT__c <= oldAdj.DTE_START_ADJMT__c && newAdj.DTE_END_ADJMT__c >= oldAdj.DTE_END_ADJMT__c) ||
                     (newAdj.DTE_START_ADJMT__c >= oldAdj.DTE_START_ADJMT__c && newAdj.DTE_END_ADJMT__c <= oldAdj.DTE_END_ADJMT__c) ||
                     (newAdj.DTE_START_ADJMT__c <= oldAdj.DTE_END_ADJMT__c && newAdj.DTE_END_ADJMT__c >= oldAdj.DTE_END_ADJMT__c)
                   )
                ){
                                             if((newAdj.id != null)){
                        if(newAdj.id != oldAdj.id){
                            system.debug('oldAdj--'+oldAdj);
                            newAdj.addError('Duplicate Adjustment for the same provider or Case');
                        }
                    } else{
                        system.debug('oldAdj--'+oldAdj);
                        newAdj.addError('Duplicate Adjustment for the same provider or Case');
                    }

				}
            }
            
        }
       
    }*/

}