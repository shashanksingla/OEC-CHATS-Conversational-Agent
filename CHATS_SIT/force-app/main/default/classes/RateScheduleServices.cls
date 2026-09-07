/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           2/7/2018                                                          
*  @description    Handler class for Rate Schedule Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 7-Feb-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version  
*                CHAT-491 : Populating TXT_CHATS_RATING__c in T_FISCAL_SCH__c from T_CHATS_PROVR_STATUS.TXT_CHATS_RATING__c field.
*                CHAT-695 : Create a Task when Fiscal Agreement Quality Rating is Changed.
*                Change Log : Updating line 242 and 272 to check null before DML operation                  
*********************************************************************************************/                                              
public with sharing class RateScheduleServices {
    
    public static final String CLOSED = 'CLS';
    public static boolean run = true;
    /**
* @description CHAT-491 : copying TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS to TXT_CHATS_RATING__c field in T_FISCAL_SCH__c
* @author Bharadwaj Gaddam
* @date 2/7/2018   
* @param List<T_FISCAL_SCH__c> trigger.new Rate Schedules
* @return void
*/
    public static void updateQualityRating(List<T_FISCAL_SCH__c> rateScheduleList) {
        set<Id> fiscalAgreementIdSet = new set<Id>();
        Map<string,string> fiscalAgreementProviderMap= new Map<string,string>();
        for(T_FISCAL_SCH__c rateSchEach:rateScheduleList) {
            if(rateSchEach.IDN_AGRMT_FISCAL__c!=null) {
                fiscalAgreementIdSet.add(rateSchEach.IDN_AGRMT_FISCAL__c);
            }
            
        }    
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreementEach:[select Id, ID_SERVICE__r.TXT_CHATS_RATING__c from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__r.TXT_CHATS_RATING__c !=null and Id IN:fiscalAgreementIdSet]) {
            if(fiscalAgreementEach.ID_SERVICE__r.TXT_CHATS_RATING__c !=null) {
                fiscalAgreementProviderMap.put(fiscalAgreementEach.Id,fiscalAgreementEach.ID_SERVICE__r.TXT_CHATS_RATING__c);
            }
            
        }
        
        for(T_FISCAL_SCH__c rateSchEach:rateScheduleList) {
            if(rateSchEach.IDN_AGRMT_FISCAL__c!=null) {
                if(fiscalAgreementProviderMap.get(rateSchEach.IDN_AGRMT_FISCAL__c)!=null) {
                    rateSchEach.TXT_CHATS_RATING__c=fiscalAgreementProviderMap.get(rateSchEach.IDN_AGRMT_FISCAL__c);
                }
            }
        }
    }
    
    /**
* @description CHAT-695 Create a Task when a T_FISCAL_SCH__c is created in the system if it satisfies criteria as mentioned in the Jira ticket
* @author Bharadwaj Gaddam
* @date 2/8/2018   
* @param List<T_FISCAL_SCH__c> trigger.new Rate Schedules, Set<Id> set of T_FISCAL_SCH__c record Ids
* @return void
*/
    
    public static void createTaskforAuthOwner(List<T_FISCAL_SCH__c> rateScheduleList,Set<Id> rateScheduleIdSet) {
        set<Id> fiscalAgreementIdSet = new set<Id>();
        set<Id> providerIdSet = new set<Id>();
        set<Id> countyIdSet = new set<Id>();
        Map<string,List<T_AUTH__c>> authMap = new Map<string,List<T_AUTH__c>>();
        List<T_AUTH__c> tempAuthList;
        List<Task>  taskList = new List<Task>();
        string countyProviderConcat;
        List<string> levels= new List<string>{'Level 1','Level 2','Level 3','Level 4','Level 5'};
            T_FISCAL_SCH__c tempRateSchedule;
        set<string> caseNameSet = new set<string>();
        set<string> ownerIdSet = new set<string>();
        Date nulldate;
        for(T_FISCAL_SCH__c rateSchEach:rateScheduleList) {
            if(rateSchEach.IDN_AGRMT_FISCAL__c!=null && rateSchEach.TXT_CHATS_RATING__c!=null) {
                if(levels.contains(rateSchEach.TXT_CHATS_RATING__c)) {
                    fiscalAgreementIdSet.add(rateSchEach.IDN_AGRMT_FISCAL__c); //collecting set of Provider Fiscal Agreement record Ids
                }
            }
        }
        
        //Query returns T_PROVR_FISCAL_AGREMENT__c and its child T_FISCAL_SCH__c records where in this query returns only previous T_FISCAL_SCH__c  records for the T_PROVR_FISCAL_AGREMENT__c
        Map<Id,T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementMap= new Map<Id,T_PROVR_FISCAL_AGREMENT__c>([select Id, ID_SERVICE__c,CDE_COUNTY__c,(select Id, TXT_CHATS_RATING__c from Rate_Schedules__r where Id NOT IN:rateScheduleIdSet and TXT_CHATS_RATING__c IN:levels order by DTE_END_EFFV__c desc Limit 1) from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__c!=null and CDE_COUNTY__c!=null and Id IN:fiscalAgreementIdSet]); 
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreementEach:fiscalAgreementMap.values()) {
            if(fiscalAgreementEach.ID_SERVICE__c !=null && fiscalAgreementEach.CDE_COUNTY__c !=null) {
                providerIdSet.add(fiscalAgreementEach.ID_SERVICE__c); //collecting set of Provider Ids
                countyIdSet.add(fiscalAgreementEach.CDE_COUNTY__c); //collecting set of County Ids
            }
        }    
        
        //Iterating returned Authorzed T_AUTH__c records where each Authorization contains same Provider and same County which are captured on T_PROVR_FISCAL_AGREMENT__c records
        //authMap is a Map which would have Key as concatenation of County and Provider Ids and Value as List of T_AUTH__c records 
        for(T_AUTH__c authorizationEach:[select Id,IDN_PROVR__c,CDE_COUNTY__c,IDN_CASE__r.Name,IDN_CASE__r.OwnerId,OwnerId from T_AUTH__c where IDN_PROVR__c IN:providerIdSet and CDE_COUNTY__c IN:countyIdSet and IDN_CASE__r.Name !=null and OwnerId!=null and (DTE_END_EFFV_AUTH__c >= Today or DTE_END_EFFV_AUTH__c =:nulldate)]) {
            countyProviderConcat = string.valueOf(authorizationEach.CDE_COUNTY__c) + string.valueOf(authorizationEach.IDN_PROVR__c);
            tempAuthList = new List<T_AUTH__c>();
            if(authMap.get(countyProviderConcat)!=null) {
                tempAuthList.addAll(authMap.get(countyProviderConcat));
                tempAuthList.add(authorizationEach);
                authMap.put(countyProviderConcat,tempAuthList);
            } else {
                tempAuthList.add(authorizationEach);
                authMap.put(countyProviderConcat,tempAuthList);
            }
            
        }
        
        //Iterating T_FISCAL_SCH__c records to create Tasks for the owners associated to Authorization records
        for(T_FISCAL_SCH__c rateSchEach:rateScheduleList) {
            countyProviderConcat='';
            tempRateSchedule = new T_FISCAL_SCH__c();
            if(rateSchEach.IDN_AGRMT_FISCAL__c!=null) {
                if(fiscalAgreementMap.get(rateSchEach.IDN_AGRMT_FISCAL__c)!=null) {
                    if(fiscalAgreementMap.get(rateSchEach.IDN_AGRMT_FISCAL__c).Rate_Schedules__r.size()>0) {
                        tempRateSchedule=fiscalAgreementMap.get(rateSchEach.IDN_AGRMT_FISCAL__c).Rate_Schedules__r[0];
                        
                        //checking the TXT_CHATS_RATING__c on previous T_FISCAL_SCH__c record and as well as in current TXT_CHATS_RATING__c
                        if(((rateSchEach.TXT_CHATS_RATING__c=='Level 1' || rateSchEach.TXT_CHATS_RATING__c=='Level 2') && (tempRateSchedule.TXT_CHATS_RATING__c=='Level 3' || tempRateSchedule.TXT_CHATS_RATING__c=='Level 4' || tempRateSchedule.TXT_CHATS_RATING__c=='Level 5')) || ((tempRateSchedule.TXT_CHATS_RATING__c=='Level 1' || tempRateSchedule.TXT_CHATS_RATING__c=='Level 2') && (rateSchEach.TXT_CHATS_RATING__c=='Level 3' || rateSchEach.TXT_CHATS_RATING__c=='Level 4' || rateSchEach.TXT_CHATS_RATING__c=='Level 5'))) {
                            countyProviderConcat=string.valueOf(fiscalAgreementMap.get(rateSchEach.IDN_AGRMT_FISCAL__c).CDE_COUNTY__c) + string.valueOf(fiscalAgreementMap.get(rateSchEach.IDN_AGRMT_FISCAL__c).ID_SERVICE__c);
                            if(authMap.get(countyProviderConcat)!=null) {
                                for(T_AUTH__c authEach:authMap.get(countyProviderConcat)) {
                                    if(!(ownerIdSet.contains(authEach.OwnerId) && caseNameSet.contains(authEach.IDN_CASE__r.Name))) {
                                        ownerIdSet.add(authEach.OwnerId);
                                        caseNameSet.add(authEach.IDN_CASE__r.Name);
                                        taskList.add(new Task(ownerId=authEach.IDN_CASE__r.OwnerId,Description='Case ' + authEach.IDN_CASE__r.Name +' has a quality rating parent fee discrepancy, take appropriate action. Please update the case parent fee and the authorizations to accomodate the new quality rating.',
                                                              WhatId=authEach.Id,ActivityDate=system.today().addDays(30),Status='Not Started',Subject='T106 - Fiscal Agreement Quality Rating Changed'
                                                             ));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        try {
            //inserting Tasks
            if( taskList.size()>0) {
                GenericDMLHandler.insertRecords(taskList , null);
            }
            
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'RateScheduleServices','Method__c'=>'createTaskforAuthOwner'});
        }
    }
    
    /**
* @description CHAT-2106 : Validation on effective begin date
* @author Vineet Srivastava
* @date 3/6/2018   
* @param List<T_FISCAL_SCH__c> trigger.new Rate Schedules and Map<Id, T_FISCAL_SCH__c> old Rate Schedule records
* @return void
*/
    public static void validateEffectiveBeginEndDateOfExistingRateSchedules(List<T_FISCAL_SCH__c> newRateScheduleList, Map<Id, T_FISCAL_SCH__c> oldMap){
        Set<Id> fiscalAgreementIdSet = new Set<Id>();
        Set<Id> newRateScheduleIdForEdit = new Set<Id>();
        Map<Id, List<T_FISCAL_SCH__c>> faIdToExistingRateScheduleMap = new Map<Id, List<T_FISCAL_SCH__c>>();
        
        if(!newRateScheduleList.isEmpty()){
            for(T_FISCAL_SCH__c eachRateSchedule: newRateScheduleList){
                if(eachRateSchedule.IDN_AGRMT_FISCAL__c != null){
                    if(oldMap ==  null){
                        fiscalAgreementIdSet.add(eachRateSchedule.IDN_AGRMT_FISCAL__c);
                    }
                    else if(oldMap !=  null && oldMap.containskey(eachRateSchedule.Id) && eachRateSchedule.DTE_BEGIN_EFFV__c != oldMap.get(eachRateSchedule.Id).DTE_BEGIN_EFFV__c){
                        fiscalAgreementIdSet.add(eachRateSchedule.IDN_AGRMT_FISCAL__c);
                        newRateScheduleIdForEdit.add(eachRateSchedule.Id);
                    }
                }
            }
        }
        if(!fiscalAgreementIdSet.isEmpty()){
            List<T_FISCAL_SCH__c> existingRateSchedules = [SELECT Id, Name, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, IDN_AGRMT_FISCAL__c FROM T_FISCAL_SCH__c WHERE IDN_AGRMT_FISCAL__c in :fiscalAgreementIdSet];
            if(!existingRateSchedules.isEmpty()){
                for(T_FISCAL_SCH__c eachRateSchedule : existingRateSchedules){
                    if(!newRateScheduleIdForEdit.contains(eachRateSchedule.Id)){
                        if(faIdToExistingRateScheduleMap.containsKey(eachRateSchedule.IDN_AGRMT_FISCAL__c)){
                            List<T_FISCAL_SCH__c> tempRateScheduleList = faIdToExistingRateScheduleMap.get(eachRateSchedule.IDN_AGRMT_FISCAL__c);
                            tempRateScheduleList.add(eachRateSchedule);
                            faIdToExistingRateScheduleMap.put(eachRateSchedule.IDN_AGRMT_FISCAL__c, tempRateScheduleList);
                        }
                        else{
                            faIdToExistingRateScheduleMap.put(eachRateSchedule.IDN_AGRMT_FISCAL__c, new List<T_FISCAL_SCH__c>{eachRateSchedule});
                        }
                    }
                }
            }
        }
        if(!faIdToExistingRateScheduleMap.isEmpty()){
            for(T_FISCAL_SCH__c newRateSchedule : newRateScheduleList){
                if(newRateSchedule.IDN_AGRMT_FISCAL__c != null && faIdToExistingRateScheduleMap.containsKey(newRateSchedule.IDN_AGRMT_FISCAL__c)){
                    for(T_FISCAL_SCH__c existingRateSchedule : faIdToExistingRateScheduleMap.get(newRateSchedule.IDN_AGRMT_FISCAL__c)){
                        if(existingRateSchedule.DTE_BEGIN_EFFV__c > system.today()){
                            newRateSchedule.addError('There is already an existing Rate Schedule with future begin date.');
                        }
                    }
                }
            }
        }
    }
    
    /**
* @description : updates End Date with Begin Date-1 of newly created Rate Schedule on existing Rate Schedule.
* @author Bharadwaj Gaddam
* @date 3/6/2018   
* @param List<T_FISCAL_SCH__c> trigger.new Rate Schedules
* @return void
*/
    public static void updateEnddateonFiscalAgreement(List<T_FISCAL_SCH__c> rateScheduleList,Map<Id,T_FISCAL_SCH__c> oldRateMap) {
        Map<Id,T_FISCAL_SCH__c> fiscalAgreementMap = new Map<Id,T_FISCAL_SCH__c>();
        set<Id> rateScheduleIds = new set<Id>();
        
        Map<Id,T_FISCAL_SCH__c> updateExistingRateSchedule= new Map<Id,T_FISCAL_SCH__c>();
        Date nulldate;
        String cDate = System.Label.DateForExistingRateScheduleUpdateLogic;
        Date todayDate = System.Today();
         Date dateCheck;
        if(System.Label.skipRSBeginDateValidation =='Y'){
            dateCheck = string.isNotBlank(cDate) ? Date.valueOf(cDate) : System.Today();
        }else{
            dateCheck =System.Today();
        }
      
        for(T_FISCAL_SCH__c ratScheduleEach:rateScheduleList) {
            if((Trigger.isInsert || (Trigger.isUpdate && ratScheduleEach.DTE_BEGIN_EFFV__c!= oldRateMap.get(ratScheduleEach.Id).DTE_BEGIN_EFFV__c))&&
               ratScheduleEach.IDN_AGRMT_FISCAL__c!=null && ratScheduleEach.DTE_BEGIN_EFFV__c>= dateCheck && ratScheduleEach.DTE_BEGIN_EFFV__c!=nulldate) 
            {
                fiscalAgreementMap.put(ratScheduleEach.IDN_AGRMT_FISCAL__c,ratScheduleEach);
                rateScheduleIds.add(ratScheduleEach.Id);            
            }
        }
        
        for(T_PROVR_FISCAL_AGREMENT__c FiscalAgreement: [Select Id,DTE_END_AGRMT__c,CDE_TYPE_STATUS__c, (select Id,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from Rate_Schedules__r where DTE_BEGIN_EFFV__c<=:todayDate and ID NOT IN:rateScheduleIds order by DTE_BEGIN_EFFV__c desc Limit 1) from T_PROVR_FISCAL_AGREMENT__c where Id IN:fiscalAgreementMap.keySet()]) {
            if(FiscalAgreement.Rate_Schedules__r.size()>0) {
                if( FiscalAgreement.CDE_TYPE_STATUS__c =='OPN' || FiscalAgreement.CDE_TYPE_STATUS__c=='FIN') {
                    updateExistingRateSchedule.put(FiscalAgreement.Rate_Schedules__r[0].Id,new T_FISCAL_SCH__c(Id=FiscalAgreement.Rate_Schedules__r[0].Id,DTE_END_EFFV__c =fiscalAgreementMap.get(FiscalAgreement.Id).DTE_BEGIN_EFFV__c.addDays(-1) ));
                }
            }
        }  
        if(!updateExistingRateSchedule.isEmpty() && updateExistingRateSchedule != Null) {
            GenericDMLHandler.updateRecords(updateExistingRateSchedule.values(), null);  
        }
    }

    
    /**
* @description : updates End Date as blank for existing Rate Schedule on delete on a Rate Schedule
* @author Bharadwaj Gaddam
* @date 3/6/2018   
* @param List<T_FISCAL_SCH__c> trigger.new Rate Schedules
* @return void
*/
    public static void updateEnddateonExistingFiscalRate(List<T_FISCAL_SCH__c> rateScheduleList) {
        Map<Id,T_FISCAL_SCH__c> fiscalAgreementMap = new Map<Id,T_FISCAL_SCH__c>();
        set<Id> rateScheduleIds = new set<Id>();
        Map<Id,T_FISCAL_SCH__c> updateExistingRateSchedule= new Map<Id,T_FISCAL_SCH__c>();
        Date nulldate;
        Date todayDate=System.Today();
        if(run){
        for(T_FISCAL_SCH__c ratScheduleEach:rateScheduleList) {
            if(ratScheduleEach.IDN_AGRMT_FISCAL__c!=null && ratScheduleEach.DTE_BEGIN_EFFV__c>=todayDate && ratScheduleEach.DTE_BEGIN_EFFV__c!=nulldate) {
                fiscalAgreementMap.put(ratScheduleEach.IDN_AGRMT_FISCAL__c,ratScheduleEach);
                rateScheduleIds.add(ratScheduleEach.Id);            
            }
        }
        for(T_PROVR_FISCAL_AGREMENT__c FiscalAgreement: [Select Id,DTE_END_AGRMT__c,CDE_TYPE_STATUS__c, (select Id,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from Rate_Schedules__r where DTE_BEGIN_EFFV__c<=:todayDate and DTE_END_EFFV__c!=:nulldate and ID NOT IN:rateScheduleIds order by DTE_BEGIN_EFFV__c desc Limit 1) from T_PROVR_FISCAL_AGREMENT__c where Id IN:fiscalAgreementMap.keySet() and CDE_TYPE_STATUS__c!=:CLOSED]) {
            if(FiscalAgreement.Rate_Schedules__r.size()>0) {
                updateExistingRateSchedule.put(FiscalAgreement.Rate_Schedules__r[0].Id,new T_FISCAL_SCH__c(Id=FiscalAgreement.Rate_Schedules__r[0].Id,DTE_END_EFFV__c =nulldate));
            }
        }
        if(!updateExistingRateSchedule.isEmpty() && updateExistingRateSchedule != NULL ) {
            GenericDMLHandler.updateRecords(updateExistingRateSchedule.values(), null);  
        }
        }
    }
    
    
    public static void deleteRateScheduleChildRecords(List<T_FISCAL_SCH__c> rateScheduleList) {
        Set<Id> rateScheduleIds = new Set<Id>();
        List<Id> recordIdsToBeDeleted = new List<Id>();
        if(run){
        for(T_FISCAL_SCH__c ratScheduleEach:rateScheduleList) {
                rateScheduleIds.add(ratScheduleEach.Id);            
        }
        for(T_FISCAL_RAT_FEES__c rateFee : [Select Id,IDN_FISCAL_SCH__c from T_FISCAL_RAT_FEES__c where IDN_FISCAL_SCH__c IN:rateScheduleIds]){
            recordIdsToBeDeleted.add(rateFee.Id);
            
        }
        GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
        GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Method__c'=>'deleteRateScheduleChildRecords','Class__c'=>'RateScheduleServices'});
        
        List<Id> lstRateScheduleIds = new List<Id>(rateScheduleIds);
        if(system.isBatch()){
                deleteFiscalRateRecord(lstRateScheduleIds);  
            }else{
                deleteFiscalRateRecords(lstRateScheduleIds);//Future postfix
            }
        }
    }
    
    
    /**    
* @description Insert Record in ATS Object
* @author Ranjan Poojary
* @date 05/04/2018   
* @param List<T_FISCAL_SCH__c> trigger.new Rate Schedule list,
* @return void
*/  
    
    public static void insertATSRecord(List<T_FISCAL_SCH__c> newRateScheduleList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        Set<Id> providerFiscalAggrementIdset = new Set<Id>();
        Map<Id,String> fiscalAggrementtoProviderMap = new Map<Id,String>();
        Map<Id,String> fiscalAggrementtoCountyMap = new Map<Id,String>();
        Map<Id,string> fiscalAggrementNameMap = new Map<Id,string>();
        
        for(T_FISCAL_SCH__c rateSche : newRateScheduleList){
            providerFiscalAggrementIdset.add(rateSche.IDN_AGRMT_FISCAL__c);
        }
        
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement: [select ID_SERVICE__r.Name,CDE_COUNTY__c,CDE_COUNTY__r.CDE_COUNTY__c,Id,Name from T_PROVR_FISCAL_AGREMENT__c where Id in :providerFiscalAggrementIdset]) 
        {
            fiscalAggrementNameMap.put(fiscalAgreement.Id,fiscalAgreement.Name);
            fiscalAggrementtoProviderMap.put(fiscalAgreement.Id,fiscalAgreement.ID_SERVICE__r.Name);
            fiscalAggrementtoCountyMap.put(fiscalAgreement.Id,String.valueOf(fiscalAgreement.CDE_COUNTY__r.CDE_COUNTY__c));
        }
        batchsit_t_pos_trans_queue_ats__x atsRecord;
        for(T_FISCAL_SCH__c rateSchedule:newRateScheduleList) {
            if(rateSchedule.Is_Flow_Completed__c){
                atsRecord = new batchsit_t_pos_trans_queue_ats__x();
                atsRecord.CDE_STATUS_TRANS__c= '1';
                atsRecord.CDE_TYPE_TRANS__c ='5';
                if(fiscalAggrementNameMap.get(rateSchedule.IDN_AGRMT_FISCAL__c)!=null) {
                    atsRecord.IDN_AGRMT_FISCAL__c=fiscalAggrementNameMap.get(rateSchedule.IDN_AGRMT_FISCAL__c);   
                }
                if(fiscalAggrementtoProviderMap.containsKey(rateSchedule.IDN_AGRMT_FISCAL__c)){
                    atsRecord.IDN_PROVR__c = fiscalAggrementtoProviderMap.get(rateSchedule.IDN_AGRMT_FISCAL__c);
                }
                if(fiscalAggrementtoCountyMap.containsKey(rateSchedule.IDN_AGRMT_FISCAL__c)){
                    atsRecord.CDE_COUNTY__c = fiscalAggrementtoCountyMap.get(rateSchedule.IDN_AGRMT_FISCAL__c); // Updated by RP as per CHATS-5697
                }
                atsRecord.DTE_CHANGE_LAST__c = system.today();
                lstATSRecords.add(atsRecord);
            }
        }
        if(lstATSRecords.size()>0){
            ATSHandler.insertATSRecord(true, lstATSRecords);
        }
    }
    public static LightningServerResponse deleteRateSchedule(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        List<Id> lstRateScheduleIds= new List<Id>();
        lstRateScheduleIds.add(recordId);
        List<T_FISCAL_SCH__c> lstRateSchedule = [Select Id, IDN_AGRMT_FISCAL__c from T_FISCAL_SCH__c where Id=:recordId];
        
        //LightningServerResponse lsr = GenericWithoutSharingDMLOperations.deleteJunkRecordsByIds(lstRateScheduleIds);
        //GenericWithoutSharingDMLOperations.deleteRecords(lstRateSchedule, new Map<String, Object>{'Class__c'=>'RateScheduleServices','Method__c'=>'deleteRateSchedule'});
        GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(lstRateScheduleIds);
        GenericWithoutSharingDMLOperations.deleteRecords(new Map<String, Object>{'Class__c'=>'RateScheduleServices','Method__c'=>'deleteRateSchedule'});
        objectData.put('redirect',true);
        objectData.put('recordId',lstRateSchedule.get(0).IDN_AGRMT_FISCAL__c);
        objectData.put('eventParams','{"recordId": "'+lstRateSchedule.get(0).IDN_AGRMT_FISCAL__c+'"}');
        return new LightningServerResponse(true, 'Records has been deleted successfully',objectData);
    }
    @Future(callout=true)
    public static void deleteFiscalRateRecords(List<Id>rateScheduleIds){
        HerokuService.deleteFiscalRateRecords(rateScheduleIds);
    }
    
     public static void deleteFiscalRateRecord(List<Id>rateScheduleIds){
        HerokuService.deleteFiscalRateRecords(rateScheduleIds);
    }
}