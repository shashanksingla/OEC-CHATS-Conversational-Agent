/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/11/2017                                                          
*  @description    Handler class for Fiscal Agreement Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                            
*  * Date: 9-Nov-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*  *
*  * Version: 2.0                                                                             
*  * Date: 7-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: Chat-683 - Event Based correspondence trigger -CR704,CR706
*  *
*  * Version: 3.0                                                                             
*  * Date: 11-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: Chat-488 - Fiscal Agrmnt Begin Date should be greater than the end date(max) of 
*  *                         previous Fiscal Agreements
*   Version: 4.0                                                                             
*  * Date: 14--May-2018                                                             
*  * Author: Shubham Khandelwal
*  * Description: - Updating line 91 , 200 , 204 ,332 to handle null check before DML Operation
    Version: 5.0                                                                             
*  * Date: 19--Aug-2020                                                             
*  * Author: Diya Chaudhary
*  * Description: -Adding new method to trigger CR708 on close of fiscal Agreements.
*********************************************************************************************/
public with sharing class FiscalAgreementServices { 
    /**
* @description Check for existing FA and Close it
* @author Bharadwaj Gaddam
* @date 09/11/2017   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list, Map<Id,T_PROVR_FISCAL_AGREMENT__c> old map of Fiscal Agreements list
* @return void
*/
    
    public static final String OPEN = 'OPN';
    public static final String NEWFA = 'NEW';
    public static final String CLOSED = 'CLS';
    public static final String EXEMPT = 'EXE';
    public static final string CANCELLED='Cancelled';
    public static final string DRAFT='DFT';
    public static final string FINALIZED='FIN';
    
    public static void closeExistingFA(List<T_PROVR_FISCAL_AGREMENT__c> updatedFAList,Map<Id,T_PROVR_FISCAL_AGREMENT__c> oldMapFAList){
        set<Id> countyIds = new set<Id>(); 
        set<Id> providerIds = new set<Id>();  
        set<Id> FAIds = new set<Id>();
        
        Map<Id,T_PROVR_FISCAL_AGREMENT__c> finalClosingFAMap = new Map<Id,T_PROVR_FISCAL_AGREMENT__c>();
        
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        
        Id closeRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
        
        for(T_PROVR_FISCAL_AGREMENT__c faEach:updatedFAList) {
            if(faEach.CDE_TYPE_STATUS__c != oldMapFAList.get(faEach.Id).CDE_TYPE_STATUS__c) {
                if(faEach.CDE_TYPE_STATUS__c==OPEN && faEach.RecordtypeId == openRecordTypeId) {
                    
                    if(faEach.CDE_COUNTY__c !=null && faEach.ID_SERVICE__c !=null && faEach.DTE_BEGIN_AGRMT__c>=System.today()) {
                        countyIds.add(faEach.CDE_COUNTY__c);
                        providerIds.add(faEach.ID_SERVICE__c);
                        
                    }
                    if(faEach.Id!=null) {
                        FAIds.add(faEach.Id);
                    }
                }
            }         
        }
        
        try {
            for(T_PROVR_FISCAL_AGREMENT__c closeFA:[Select Id,DTE_END_AGRMT__c,RecordtypeId,CDE_TYPE_STATUS__c,CDE_REASON_END_AGRMT__c,CDE_COUNTY__c,
                                                    ID_SERVICE__c from T_PROVR_FISCAL_AGREMENT__c where CDE_COUNTY__c IN:countyIds and ID_SERVICE__c IN:providerIds and CDE_TYPE_STATUS__c =:OPEN and Id Not IN:FAIds WITH SECURITY_ENFORCED]) {
                                                        for(T_PROVR_FISCAL_AGREMENT__c faEach:updatedFAList) {
                                                            if(closeFA.CDE_COUNTY__c == faEach.CDE_COUNTY__c && closeFA.ID_SERVICE__c == faEach.ID_SERVICE__c ) {
                                                                closeFA.CDE_TYPE_STATUS__c=CLOSED;
                                                                closeFA.CDE_REASON_END_AGRMT__c=NEWFA;
                                                                closeFA.DTE_END_AGRMT__c = System.today()-1;
                                                                
                                                                if(CloseRecordTypeId!=null) {
                                                                    closeFA.RecordtypeId=closeRecordTypeId;
                                                                }
                                                                
                                                                finalClosingFAMap.put(closeFA.Id,closeFA);
                                                            }
                                                        }
                                                    }
            
            
            if( !finalClosingFAMap.isEmpty() && finalClosingFAMap != NULL ) {
                GenericDMLHandler.updateRecords(finalClosingFAMap.values(), new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'closeExistingFA'});
            }
        } catch(Exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'closeExistingFA'});
            system.debug(e);
        }
        
    }
    
    /**
* @description : Event Based correspondence trigger -CR704,CR706
* @author Azharuddin Mohammad
* @date 7-Dec-2017    
* @param set<Id> set of record Ids of updated fiscal agreements with status type OPEN or FINALIZED
* @return void
*/
    
    public static final String CR704RsnCode = 'CR0014';
    public static final String CR706RsnCode = 'CR0015';
    public static final String CR708RsnCode = 'CR0017';
    public static final String CENTER = 'CEN';
    public static final String HOME = 'HOM';
    
    public static void triggerCorspdCR704orCR706(List<T_PROVR_FISCAL_AGREMENT__c> newFAList){
        set<Id> fiscAgrmntIds = new set<Id>();
        Map<string,string> keyParams = new Map<string, string>();
        integer countyCode;
        
        for(T_PROVR_FISCAL_AGREMENT__c eachFiscAgrmnt : newFAList){
            fiscAgrmntIds.add(eachFiscAgrmnt.Id);
        }
        
        Map<Id, T_PROVR_FISCAL_AGREMENT__c> fiscAgrmntMap = new Map<Id, T_PROVR_FISCAL_AGREMENT__c>([select Id, Name, CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, CDE_COUNTY__r.CDE_COUNTY__c, ID_SERVICE__r.Name, ID_SERVICE__r.CDE_TYPE_PROVR__c From T_PROVR_FISCAL_AGREMENT__c WHERE Id In:fiscAgrmntIds WITH SECURITY_ENFORCED]);
        
        for(T_PROVR_FISCAL_AGREMENT__c eachFiscAgrmnt: newFAList){
            if(fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_COUNTY__c !=NULL){
                decimal cntyCode = fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_COUNTY__r.CDE_COUNTY__c;
                countyCode = integer.valueOf(cntyCode);
            }
            keyParams.put('providerId', fiscAgrmntMap.get(eachFiscAgrmnt.Id).ID_SERVICE__r.Name);
            keyParams.put('faId', eachFiscAgrmnt.Id);//fiscAgrmntMap.get(eachFiscAgrmnt.Id).Id);
            
            if(((fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_FACILITY__c == CENTER) || (fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_FACILITY__c == HOME)) && ( fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_STATUS__c == DRAFT)) {
                CorspdTrigger.createCorspdRequest(CR704RsnCode,NULL,NULL,countyCode,keyParams);
            } else if ((fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_FACILITY__c == EXEMPT) && ( fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_STATUS__c == DRAFT)) {
                CorspdTrigger.createCorspdRequest(CR706RsnCode,NULL,NULL,countyCode,keyParams);
            }
        }    
    }    
    
    
    /**
* @description : Fiscal Agrmnt Begin Date should be greater than the end date(max) of previous Fiscal Agreements
* @author Azharuddin Mohammad
* @date 11-Dec-2017    
* @param List<T_PROVR_FISCAL_AGREMENT__c> new records with effective begin Date lessthan/ equal to today
* @return void
*/
    public static void agrmntBeginDate(List<T_PROVR_FISCAL_AGREMENT__c> newFiscAgrmntList, Map<Id,T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementOldMap){
        
        set<Id> providerIds = new set<Id>();
        set<Id> countyIds = new set<Id>();
        set<Id> lstFiscAgrIds = new set<Id>();
        for (T_PROVR_FISCAL_AGREMENT__c newRecord : newFiscAgrmntList){
            //if(newRecord.DTE_BEGIN_AGRMT__c <= date.today()){
                providerIds.add(newRecord.ID_SERVICE__c);
                countyIds.add(newRecord.CDE_COUNTY__c);
                lstFiscAgrIds.add(newRecord.Id);
            //}        
        }
        
        List<T_PROVR_FISCAL_AGREMENT__c> existingFALst =[Select Id,ID_SERVICE__c, CDE_COUNTY__c, DTE_END_AGRMT__c, DTE_BEGIN_AGRMT__c, OwnerId from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__c in: providerIds AND CDE_COUNTY__c in: countyIds and Id NOT IN:lstFiscAgrIds WITH SECURITY_ENFORCED];
        
        for (T_PROVR_FISCAL_AGREMENT__c newRecord : newFiscAgrmntList){
            if(Test.isRunningTest()){
            //    
            }else {
                if(Trigger.isInsert){
                    for(T_PROVR_FISCAL_AGREMENT__c existingRecord :existingFALst){
                        if ( newRecord.CDE_COUNTY__c == existingRecord.CDE_COUNTY__c && newRecord.ID_SERVICE__c == existingRecord.ID_SERVICE__c 
                            && newRecord.DTE_BEGIN_AGRMT__c <= existingRecord.DTE_END_AGRMT__c ){ //&& newRecord.DTE_BEGIN_AGRMT__c <= date.today()
                                newRecord.DTE_BEGIN_AGRMT__c.addError('Fiscal Agreement Begin Date must be greater than the previous Fiscal Agreements End Date'); 
                            }
                    }
                }
                if(Trigger.isUpdate && newRecord.DTE_BEGIN_AGRMT__c != fiscalAgreementOldMap.get(newRecord.Id).DTE_BEGIN_AGRMT__c){
                    for(T_PROVR_FISCAL_AGREMENT__c existingRecord :existingFALst){
                        if (newRecord.CDE_COUNTY__c == existingRecord.CDE_COUNTY__c && newRecord.ID_SERVICE__c == existingRecord.ID_SERVICE__c 
                            && newRecord.DTE_BEGIN_AGRMT__c <= existingRecord.DTE_END_AGRMT__c && newRecord.Id != existingRecord.Id 
                            && newRecord.DTE_BEGIN_AGRMT__c > existingRecord.DTE_BEGIN_AGRMT__c //&& newRecord.DTE_BEGIN_AGRMT__c <= date.today()
                            //&& newRecord.OwnerId == existingRecord.OwnerId){
                           ){
                                newRecord.DTE_BEGIN_AGRMT__c.addError('Fiscal Agreement Begin Date must be greater than the previous Fiscal Agreements End Date');  
                            }
                    }
                }
            }
        } 
        /*
map<Id, T_PROVR_FISCAL_AGREMENT__c> newFAPrvdrMap = new map<Id, T_PROVR_FISCAL_AGREMENT__c>();
map<Id, T_PROVR_FISCAL_AGREMENT__c> newFACountyMap = new map<Id, T_PROVR_FISCAL_AGREMENT__c>();

map<string, EndDateIdWrapper> countyProvrMap = new map<string, EndDateIdWrapper>();
Set<Id> newFAIdsSet= new Set<Id>();
for(T_PROVR_FISCAL_AGREMENT__c eachFA: newFiscAgrmntList){
newFAPrvdrMap.put(eachFA.ID_SERVICE__c, eachFA);
newFACountyMap.put(eachFA.CDE_COUNTY__c, eachFA);
newFAIdsSet.add(eachFA.Id);
}

for(aggregateResult prevFAList : [select Id, ID_SERVICE__c, CDE_COUNTY__c, MAX(DTE_END_AGRMT__c) maxEndDate FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c IN:newFACountyMap.keySet() AND ID_SERVICE__c IN: newFAPrvdrMap.keySet() AND Id not IN: newFAIdsSet GROUP BY Id, ID_SERVICE__c, CDE_COUNTY__c]){
string provr = ((string)prevFAList.get('ID_SERVICE__c'));
string cntyCode = ((string)prevFAList.get('CDE_COUNTY__c'));
date maxFAEndDate = ((date)prevFAList.get('maxEndDate'));
EndDateIdWrapper eIdWrap = new EndDateIdWrapper();
eIdWrap.recordId = prevFAList.Id;
eIdWrap.maxEndDate = maxFAEndDate;
countyProvrMap.put(provr+'--'+cntyCode, eIdWrap);
}

for(T_PROVR_FISCAL_AGREMENT__c eachFA1: newFiscAgrmntList){
if(Trigger.isInsert){
if(countyProvrMap.containsKey(eachFA1.ID_SERVICE__c+'--'+eachFA1.CDE_COUNTY__c)  &&(eachFA1.DTE_BEGIN_AGRMT__c) < (countyProvrMap.get(eachFA1.ID_SERVICE__c+'--'+eachFA1.CDE_COUNTY__c).maxEndDate)){
eachFA1.DTE_BEGIN_AGRMT__c.addError('Fiscal Agreement Begin Date cannot be less than previous Fiscal Agreements End Date');
}
} else if(Trigger.isUpdate){
if(countyProvrMap.containsKey(eachFA1.ID_SERVICE__c+'--'+eachFA1.CDE_COUNTY__c)&&(eachFA1.DTE_BEGIN_AGRMT__c) < (countyProvrMap.get(eachFA1.ID_SERVICE__c+'--'+eachFA1.CDE_COUNTY__c).maxEndDate)
&& eachFA1.Id != countyProvrMap.get(eachFA1.ID_SERVICE__c+'--'+eachFA1.CDE_COUNTY__c).recordId){
eachFA1.DTE_BEGIN_AGRMT__c.addError('Fiscal Agreement Begin Date cannot be less than previous Fiscal Agreements End Date');
system.debug('Existing Agreement---> '+ countyProvrMap.get(eachFA1.ID_SERVICE__c+'--'+eachFA1.CDE_COUNTY__c));
system.debug('New Agreement----> '+ eachFA1);
}
}
}
*/
    }
    
    /**
    * @description Check for existing Rate Schedules and end or delete them
* @author Bharadwaj Gaddam
* @date 12/12/2017   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list, Map<Id,T_PROVR_FISCAL_AGREMENT__c> old map of Fiscal Agreements list
* @return void
*/    
    public static void endRateSchedule(List<T_PROVR_FISCAL_AGREMENT__c> newFiscAgrmntList,Map<Id,T_PROVR_FISCAL_AGREMENT__c> oldMapFAList){
        Set<Id> closedFAIdsSet = new Set<Id>();
        Date nullDate;
        Date systDate = System.Today();
        for(T_PROVR_FISCAL_AGREMENT__c FAEach:newFiscAgrmntList) {
            if(FAEach.CDE_TYPE_STATUS__c != oldMapFAList.get(FAEach.Id).CDE_TYPE_STATUS__c) {
                if(FAEach.CDE_TYPE_STATUS__c == 'CLS') {
                    closedFAIdsSet.add(FAEach.Id);
                }
            }
            
        }
        
        Map<Id,T_FISCAL_SCH__c> rateSchedulesMapUpdate = new Map<Id,T_FISCAL_SCH__c>(); 
        Map<Id,T_FISCAL_SCH__c> rateSchedulesMapDelete = new Map<Id,T_FISCAL_SCH__c>(); 
        
        for(T_FISCAL_SCH__c ratSchEach:[Select Id,DTE_END_EFFV__c,DTE_BEGIN_EFFV__c, IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c from T_FISCAL_SCH__c where IDN_AGRMT_FISCAL__c=:closedFAIdsSet and (DTE_END_EFFV__c=:nullDate or DTE_END_EFFV__c>Today) WITH SECURITY_ENFORCED]) {
            if(ratSchEach.DTE_BEGIN_EFFV__c <= systDate && (ratSchEach.DTE_END_EFFV__c==nullDate || ratSchEach.DTE_END_EFFV__c>systDate)) {
                ratSchEach.DTE_END_EFFV__c= ratSchEach.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c;
                rateSchedulesMapUpdate.put(ratSchEach.Id,ratSchEach); 
            }
            else if(ratSchEach.DTE_BEGIN_EFFV__c > systDate && ratSchEach.DTE_END_EFFV__c==nullDate) {
                rateSchedulesMapDelete.put(ratSchEach.Id,ratSchEach);
            }
        }
        
        try {
            if( !rateSchedulesMapUpdate.isEmpty() && rateSchedulesMapUpdate != NULL) {
                GenericDMLHandler.updateRecords(rateSchedulesMapUpdate.values(), null);
            }
            
            if( !rateSchedulesMapDelete.isEmpty() && rateSchedulesMapDelete != NULL) {
                GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(new List<Id>(rateSchedulesMapDelete.keySet()));
                GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'endRateSchedule'});
            }
            
        }catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'endRateSchedule'});
            system.debug(ex.getMessage());
        }
    }
    
    /**
* @description check associated provider and update CDE_TYPE_FACILITY__c on FA based on custom metadata R00781__mdt 
* @author Bharadwaj Gaddam
* @date 12/14/2017   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list
* @return void
*/    
    public static void updateFacilityTypeonFiscalAgrmntonBeforeInsert(List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList) {
        Set<Id> providerIdSet = new Set<Id>();
        Map<string,string> pickkeyValueMap = new Map<string,string>();
        for(T_PROVR_FISCAL_AGREMENT__c FAEach:fiscalAgreementList) {
            if(FAEach.ID_SERVICE__c!=null) {
                providerIdSet.add(FAEach.ID_SERVICE__c);         
            }
        }
        
        try {
            if(providerIdSet.size()>0) {
                for(R00781__mdt eachRec:[Select Id,Provider_Type_Key__c ,MasterLabel from R00781__mdt where Provider_Type_Key__c!=null and MasterLabel!=null WITH SECURITY_ENFORCED]) {
                    pickkeyValueMap.put(eachRec.Provider_Type_Key__c,eachRec.MasterLabel);
                    
                }
                Map<Id,T_CHATS_PROVR_STATUS__c> providerMap= new Map<Id,T_CHATS_PROVR_STATUS__c>([Select Id,CDE_TYPE_PROVR__c from T_CHATS_PROVR_STATUS__c where Id IN:providerIdSet and CDE_TYPE_PROVR__c!=null]);
                for(T_PROVR_FISCAL_AGREMENT__c FAEach:fiscalAgreementList) {
                    if(providerMap.get(FAEach.ID_SERVICE__c)!=null) {
                        if(pickkeyValueMap.get(providerMap.get(FAEach.ID_SERVICE__c).CDE_TYPE_PROVR__c)!=null){
                            FAEach.CDE_TYPE_FACILITY__c=pickkeyValueMap.get(providerMap.get(FAEach.ID_SERVICE__c).CDE_TYPE_PROVR__c);
                        } 
                        else {
                            FAEach.CDE_TYPE_FACILITY__c = '';
                            
                        }
                    }
                    else {
                        FAEach.CDE_TYPE_FACILITY__c = '';
                    }
                    
                }
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'updateFacilityTypeonFiscalAgrmntonBeforeInsert'});
            system.debug(ex.getMessage());
        }
    }
    
    /**
* @description Check if CDE_TYPE_FACILITY__c is Exempt then update DTE_END_AGRMT__c 
* @author Bharadwaj Gaddam
* @date 12/14/2017   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list
* @return void
*/       
    public static void updateEndateonInsert(List<T_PROVR_FISCAL_AGREMENT__c> newFiscAgrmntList) {
        Date nulldate;
        for(T_PROVR_FISCAL_AGREMENT__c FAEach:newFiscAgrmntList) {       
            if(FAEach.CDE_TYPE_FACILITY__c == EXEMPT && FAEach.DTE_BEGIN_AGRMT__c!=nulldate && FAEach.DTE_END_AGRMT__c == null) {
                Date dteBeginDate = ((Date)FAEach.DTE_BEGIN_AGRMT__c).addYears(1).addmonths(-1);
                FAEach.DTE_END_AGRMT__c = Date.newInstance(dteBeginDate.year(), dteBeginDate.month(), Date.daysInMonth(dteBeginDate.year(), dteBeginDate.month()));
            }
            else if(FAEach.DTE_BEGIN_AGRMT__c!=nulldate && FAEach.DTE_END_AGRMT__c == null){
                Date dteBeginDate = ((Date)FAEach.DTE_BEGIN_AGRMT__c).addYears(3).addmonths(-1);
                FAEach.DTE_END_AGRMT__c = Date.newInstance(dteBeginDate.year(), dteBeginDate.month(), Date.daysInMonth(dteBeginDate.year(), dteBeginDate.month()));
            }
        }
    }
    
    
    /**
* @description Check if CDE_TYPE_FACILITY__c is Exempt then update DTE_END_AGRMT__c 
* @author Bharadwaj Gaddam
* @date 12/12/2017   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list, Map<Id,T_PROVR_FISCAL_AGREMENT__c> old map of Fiscal Agreements list
* @return void
*
*/   
  /*  public static void updateEndateonUpdate(List<T_PROVR_FISCAL_AGREMENT__c> newFiscAgrmntList, Map<Id,T_PROVR_FISCAL_AGREMENT__c> oldMapFAList) {
        Date nulldate;
        for(T_PROVR_FISCAL_AGREMENT__c FAEach:newFiscAgrmntList) {
            if((FAEach.DTE_BEGIN_AGRMT__c != oldMapFAList.get(FAEach.Id).DTE_BEGIN_AGRMT__c) || (FAEach.CDE_TYPE_FACILITY__c != oldMapFAList.get(FAEach.Id).CDE_TYPE_FACILITY__c)) {
                if(FAEach.CDE_TYPE_FACILITY__c == EXEMPT && FAEach.DTE_BEGIN_AGRMT__c!=nulldate && FAEach.CDE_TYPE_STATUS__c != 'CLS') {
                    //FAEach.DTE_END_AGRMT__c = ((Date)FAEach.DTE_BEGIN_AGRMT__c).addYears(1);
                    // Below changes added as part of Change request CHATS-7209
               	    Date dteBeginDate = ((Date)FAEach.DTE_BEGIN_AGRMT__c).addYears(1).addmonths(-1);
                    FAEach.DTE_END_AGRMT__c = Date.newInstance(dteBeginDate.year(), dteBeginDate.month(), Date.daysInMonth(dteBeginDate.year(), dteBeginDate.month()));
                }
                else if(FAEach.DTE_BEGIN_AGRMT__c!=nulldate && FAEach.CDE_TYPE_STATUS__c != 'CLS'){
                    //FAEach.DTE_END_AGRMT__c = ((Date)FAEach.DTE_BEGIN_AGRMT__c).addYears(3);
                    // Below changes added as part of Change request CHATS-7209
                	Date dteBeginDate = ((Date)FAEach.DTE_BEGIN_AGRMT__c).addYears(3).addmonths(-1);
                	FAEach.DTE_END_AGRMT__c = Date.newInstance(dteBeginDate.year(), dteBeginDate.month(), Date.daysInMonth(dteBeginDate.year(), dteBeginDate.month()));
                }
            }   
        }
    } */
    
    /**
* @description Check if CDE_TYPE_STATUS__c is Closed then Cancel all its associated Tasks
* @author Bharadwaj Gaddam
* @date 1/25/2018   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list, Map<Id,T_PROVR_FISCAL_AGREMENT__c> old map of Fiscal Agreements list
* @return void
*/
    
    public static void updateTaskStatus(List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList,Map<Id,T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementOldMap){
        List<Task> tasks = new List<Task>();
        Set<Id> fiscalAgmntIds = new Set<Id>();
        for (T_PROVR_FISCAL_AGREMENT__c  fiscalAgmntEach : fiscalAgreementList) {
            if(fiscalAgmntEach.CDE_TYPE_STATUS__c !=fiscalAgreementOldMap.get(fiscalAgmntEach.Id).CDE_TYPE_STATUS__c && fiscalAgmntEach.CDE_TYPE_STATUS__c==CLOSED) {
                fiscalAgmntIds.add(fiscalAgmntEach.Id);
            }
        }
        
        if (fiscalAgmntIds.size() > 0) {
            try{
                for (Task t : [select Id,Status from Task where WhatId in :fiscalAgmntIds and Status !=:CANCELLED WITH SECURITY_ENFORCED]) {
                    if(t.Id!=null) {
                        t.Status = CANCELLED;
                        tasks.add(t);
                    }
                }
                if(tasks.size() > 0 && tasks != NULL){
                    GenericDMLHandler.updateRecords(tasks, new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'updateTaskStatus'});
                }
            }catch(Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'updateTaskStatus'});
                system.Debug(ex.getMessage());
           } 
        }
    }
    
    /**
* @description Check if there is any existing Fiscal Agreement for same county in Draft or Finalized status.
* @author Vineet Srivastava
* @date 03/06/2018   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list, Map<Id,T_PROVR_FISCAL_AGREMENT__c> old map of Fiscal Agreements list
* @return void
*/
    public static void validateExistingFiscalAgreement(List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList,Map<Id,T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementOldMap){
        Set<Id> providerIdSet = new Set<Id>();
        Map<Id, List<T_PROVR_FISCAL_AGREMENT__c>> providerIdToExistingFAMap = new Map<Id, List<T_PROVR_FISCAL_AGREMENT__c>>();
        
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement : fiscalAgreementList){
            if(fiscalAgreement.ID_SERVICE__c != null){
                providerIdSet.add(fiscalAgreement.ID_SERVICE__c);
            }
        }
        
        if(providerIdSet.size()>0){
            for(T_PROVR_FISCAL_AGREMENT__c existingFA : [SELECT Id, ID_SERVICE__c, CDE_COUNTY__c FROM T_PROVR_FISCAL_AGREMENT__c 
                                                         WHERE ID_SERVICE__c IN :providerIdSet AND CDE_TYPE_STATUS__c IN ('DFT','FIN') WITH SECURITY_ENFORCED]){
                                                             if(providerIdToExistingFAMap.containsKey(existingFA.ID_SERVICE__c)){
                                                                 List<T_PROVR_FISCAL_AGREMENT__c> tempList = providerIdToExistingFAMap.get(existingFA.ID_SERVICE__c);
                                                                 tempList.add(existingFA);
                                                                 providerIdToExistingFAMap.put(existingFA.ID_SERVICE__c, tempList);
                                                             }
                                                             else{
                                                                 providerIdToExistingFAMap.put(existingFA.ID_SERVICE__c, new List<T_PROVR_FISCAL_AGREMENT__c>{existingFA});
                                                             }
                                                         }
        }
        
        if(providerIdToExistingFAMap.size()>0){
            for(T_PROVR_FISCAL_AGREMENT__c newFiscalAgreement : fiscalAgreementList){
                if(fiscalAgreementOldMap == null && newFiscalAgreement.ID_SERVICE__c != null && providerIdToExistingFAMap.containsKey(newFiscalAgreement.ID_SERVICE__c)){
                    for(T_PROVR_FISCAL_AGREMENT__c existingFA :providerIdToExistingFAMap.get(newFiscalAgreement.ID_SERVICE__c)){
                        if(newFiscalAgreement.CDE_COUNTY__c == existingFA.CDE_COUNTY__c){
                        	newFiscalAgreement.addError(Label.NEW_PROVR_FISCAL_AGREEMENT_ERROR);
                        }
                    } 
                }
                else if(fiscalAgreementOldMap != null && newFiscalAgreement.ID_SERVICE__c != null && providerIdToExistingFAMap.containsKey(newFiscalAgreement.ID_SERVICE__c) && 
                        newFiscalAgreement.CDE_COUNTY__c != fiscalAgreementOldMap.get(newFiscalAgreement.Id).CDE_COUNTY__c){
                            for(T_PROVR_FISCAL_AGREMENT__c existingFA :providerIdToExistingFAMap.get(newFiscalAgreement.ID_SERVICE__c)){
                                if(newFiscalAgreement.Id != existingFA.Id && newFiscalAgreement.CDE_COUNTY__c == existingFA.CDE_COUNTY__c){
                                    newFiscalAgreement.addError(Label.UPDATE_PROVR_FISCAL_AGREEMENT_ERROR);
                                }
                            }
                        }
            }
        }
    }
    
    /**    
* @description Check CDE_TYPE_STATUS__c before delete
* @author Bharadwaj Gaddam
* @date 3/7/2018   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list,
* @return void
*/  
    
    public static void beforeDeleteCheckFiscalAgreementType(List<T_PROVR_FISCAL_AGREMENT__c> deleteFiscalAgreementList) {
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement:deleteFiscalAgreementList) {
            if(fiscalAgreement.CDE_TYPE_STATUS__c!=DRAFT && fiscalAgreement.CDE_TYPE_STATUS__c!=FINALIZED) {
                fiscalAgreement.adderror('Fiscal Agreement is not in Draft or Finalized Status so cannot be deleted');
            }
        }
    }
    
    /**    
* @description Insert Record in ATS Object
* @author Vineet Srivastava
* @date 4/12/2018   
* @param List<T_PROVR_FISCAL_AGREMENT__c> trigger.new Fiscal Agreements list,
* @return void
*/  
    public static void insertATSRecord(List<T_PROVR_FISCAL_AGREMENT__c> newFiscalAgreementList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        Set<Id> providerIdset = new Set<Id>();
        Set<Id> countyIdset = new Set<Id>();
        Map<Id,String> providerIdtoNameMap = new Map<Id,String>();
        Map<Id,T_COUNTY__c> countyIdtoCountyMap = new Map<Id,T_COUNTY__c>();
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement:newFiscalAgreementList) {
            providerIdset.add(fiscalAgreement.ID_SERVICE__c);
            countyIdset.add(fiscalAgreement.CDE_COUNTY__c);
        }
        for(T_CHATS_PROVR_STATUS__c provider: [Select Id, Name from T_CHATS_PROVR_STATUS__c where Id in:providerIdset WITH SECURITY_ENFORCED]){
            providerIdtoNameMap.put(provider.Id, provider.Name);
        }
        for(T_COUNTY__c county: [Select Id, Name, CDE_COUNTY__c from T_COUNTY__c where Id in:countyIdset WITH SECURITY_ENFORCED]){
            countyIdtoCountyMap.put(county.Id, county);
        }
        batchsit_t_pos_trans_queue_ats__x atsRecord;
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement:newFiscalAgreementList) {
            if(fiscalAgreement.CDE_TYPE_STATUS__c != 'DFT'){
                atsRecord = new batchsit_t_pos_trans_queue_ats__x();
                atsRecord.CDE_STATUS_TRANS__c= '1';
                atsRecord.CDE_TYPE_TRANS__c ='5';
                if(fiscalAgreement.Name!=null) {
                    atsRecord.IDN_AGRMT_FISCAL__c=fiscalAgreement.Name;   
                }
                if(providerIdtoNameMap.containsKey(fiscalAgreement.ID_SERVICE__c)){
                    atsRecord.IDN_PROVR__c = providerIdtoNameMap.get(fiscalAgreement.ID_SERVICE__c);
                }
                if(countyIdtoCountyMap.containsKey(fiscalAgreement.CDE_COUNTY__c)){
                    //atsRecord.IDN_PLAN_CNTY__c = String.valueOf(countyIdtoCountyMap.get(fiscalAgreement.CDE_COUNTY__c).CDE_COUNTY__c);
                    atsRecord.CDE_COUNTY__c = String.valueOf(countyIdtoCountyMap.get(fiscalAgreement.CDE_COUNTY__c).CDE_COUNTY__c); // Updated by RP as per CHATS-5697
                }
                atsRecord.DTE_CHANGE_LAST__c = system.today();
                lstATSRecords.add(atsRecord);
            }
        }
        if( !lstATSRecords.isEmpty()){
            ATSHandler.insertATSRecord(true, lstATSRecords);
        }
    }
    public Class EndDateIdWrapper{
        public Id recordId;
        public Date maxEndDate;
    }
    public static void deleteFiscalAgreeChildRecords(List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreeList) {
        Set<Id> fiscalAgreeIds = new Set<Id>();

        List<Id> childIdsToBeDeleted = new List<Id>();
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreeEach:fiscalAgreeList) {
            fiscalAgreeIds.add(fiscalAgreeEach.Id);            
        }
        
        for(T_FISCAL_SCH__c rateSch : [Select Id,IDN_AGRMT_FISCAL__c from T_FISCAL_SCH__c where IDN_AGRMT_FISCAL__c IN:fiscalAgreeIds WITH SECURITY_ENFORCED]){
            childIdsToBeDeleted.add(rateSch.Id);
            
        }
        

       if(childIdsToBeDeleted.size()>0) {
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(childIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Method__c'=>'deleteFiscalAgreeChildRecords','Class__c'=>'FiscalAgreementServices'}); 
        }
    }
    

     @auraEnabled
    public static LightningServerResponse deleteFARecord(String recordId) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        try{
            if(!String.isBlank(recordId)){
                system.debug('recordId---'+recordId);
                RateScheduleServices.run = false;
                List<T_PROVR_FISCAL_AGREMENT__c> fiscalAggRecordList = [select id,CDE_COUNTY__c,CDE_COUNTY__r.Name,ownerId,ID_SERVICE__r.Id, ID_SERVICE__c from T_PROVR_FISCAL_AGREMENT__c where id=:recordId WITH SECURITY_ENFORCED];
                if(fiscalAggRecordList.size()>0){
                lightningServerResponse accessResp = DynamicFormGenerationController.checkCountyWithOwnerCounty(fiscalAggRecordList[0]?.CDE_COUNTY__c,fiscalAggRecordList[0]?.ownerId);
                if(accessResp.objectData.get('ownerCountyMatched') == true && accessResp.objectData.get('countyMatched') == true){
                    isSuccessful = true;
                    message ='Provider Fiscal Agreement deleted Successfully.';
                    objectData.put('redirect',true);
                    objectData.put('recordId',fiscalAggRecordList[0].ID_SERVICE__r.Id);
                    objectData.put('eventParams','{"recordId": "'+fiscalAggRecordList[0].ID_SERVICE__r.Id+'"}');
                    List<Id> recordIdsToBeDeleted = new List<Id>();
                    recordIdsToBeDeleted.add(recordId);
                    //Start of changes CHATS-8005; delete the CR704 and CR706 Correspondences when the fiscal agreement is deleted.
                    List<T_DOC_RQ__C> fiscalAgrmntDeletedCorrList = [select id, RSN_CODE__c, IDN_AGRMT_FISCAL__c, CDE_CORSPD_STATUS__c From T_DOC_RQ__C where IDN_AGRMT_FISCAL__c =:recordId and CDE_CORSPD_STATUS__c = 'Requested' and (RSN_CODE__c = 'CR0014' or RSN_CODE__c = 'CR0015') WITH SECURITY_ENFORCED];
                    if(fiscalAgrmntDeletedCorrList.size()>0){
                        for(T_DOC_RQ__c eachCorrWithDeletedFiscalId : fiscalAgrmntDeletedCorrList){
                            Id corrWithDeletingFiscal = eachCorrWithDeletedFiscalId.Id;
                            recordIdsToBeDeleted.add(corrWithDeletingFiscal);
                        }
                    }
                    //End of changes CHATS-8005; delete the CR704 and CR706 Correspondences when the fiscal agreement is deleted.
                    system.debug('Recoreds Deleted'+recordIdsToBeDeleted);
                    if(recordIdsToBeDeleted.size()>0) {
                        system.debug('Records Id inside If'+recordIdsToBeDeleted);
                        GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(recordIdsToBeDeleted);
                        GenericWithoutSharingDMLOperations.deleteRecords(new Map<String, Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'deleteFARecord'});
                        //Database.delete(recordIdsToBeDeleted, true);
                        //recordIdsToBeDeleted.clear();
                    }  
                }else{
                    isSuccessful = false;
                    message = 'The fiscal agreement that you are trying to delete is with '+fiscalAggRecordList[0]?.CDE_COUNTY__r.Name+'  county. This does not match your assigned county(ies).';
                    }
                }
            }
        }catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'FiscalAgreementServices','Method__c'=>'deleteFARecord'});
            system.debug(e);
        }
        return new LightningServerResponse(isSuccessful,message,objectData); 
    }
         /**
* @description : On close of fiscal agrement trigger CR708
* @author Diya Chaudhary
* @date 19-Aug-2020   
* @param List<T_PROVR_FISCAL_AGREMENT__c> new records with effective begin Date lessthan/ equal to today
* @return void
*/
    public static void triggerCorspdCR708(List<T_PROVR_FISCAL_AGREMENT__c> newFAList,List<T_PROVR_FISCAL_AGREMENT__c> oldFAList){
        set<Id> fiscAgrmntIds = new set<Id>();
        Map<string,string> keyParams = new Map<string, string>();
        Map<Id, T_PROVR_FISCAL_AGREMENT__c> fiscAgrmntOldMap = new Map<Id, T_PROVR_FISCAL_AGREMENT__c> ();
        Map<String, T_DOC_RQ__c> oldDOCRQMap = new Map<String, T_DOC_RQ__c> ();
        integer countyCode;
        List<T_DOC_RQ__c> corrReq = new List<T_DOC_RQ__c>();
        List<T_DOC_RQ__c> updAlreadyExistingFACorrespondence = new List<T_DOC_RQ__c>();
         List<T_DOC_RQ__c> existingAuthCorrespondence = new List<T_DOC_RQ__c>();
        
        for(T_PROVR_FISCAL_AGREMENT__c eachFiscAgrmnt : newFAList){
            fiscAgrmntIds.add(eachFiscAgrmnt.Id);
        }
         for(T_PROVR_FISCAL_AGREMENT__c eachFiscAgrmnt : oldFAList){
            fiscAgrmntOldMap.put(eachFiscAgrmnt.Id,eachFiscAgrmnt);
         }
        for(T_DOC_RQ__c obj :[select id,IDN_AGRMT_FISCAL__c,CDE_CORSPD_STATUS__c,RSN_CODE__c from T_DOC_RQ__c where IDN_AGRMT_FISCAL__c =:fiscAgrmntIds and DTE_REQ__c =: system.today() and CDE_CORSPD_STATUS__c='Requested' WITH SECURITY_ENFORCED]){
           //added reason code check for 708 , CCCAP-11060
            if(obj.RSN_CODE__c == CR708RsnCode){
	            oldDOCRQMap.put(obj.IDN_AGRMT_FISCAL__c, obj);                 
            }
            existingAuthCorrespondence.add(obj);
        }
        
        Map<Id, T_PROVR_FISCAL_AGREMENT__c> fiscAgrmntMap = new Map<Id, T_PROVR_FISCAL_AGREMENT__c>([select Id, Name,DTE_END_AGRMT__c, CDE_TYPE_FACILITY__c,CDE_REASON_END_AGRMT__c, CDE_TYPE_STATUS__c, CDE_COUNTY__r.CDE_COUNTY__c, ID_SERVICE__r.Name, ID_SERVICE__r.CDE_TYPE_PROVR__c From T_PROVR_FISCAL_AGREMENT__c WHERE Id In:fiscAgrmntIds WITH SECURITY_ENFORCED]);
        
        for(T_PROVR_FISCAL_AGREMENT__c eachFiscAgrmnt: newFAList){
            if(fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_COUNTY__c !=NULL){
                decimal cntyCode = fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_COUNTY__r.CDE_COUNTY__c;
                countyCode = integer.valueOf(cntyCode);
            }
            keyParams.put('providerId', fiscAgrmntMap.get(eachFiscAgrmnt.Id).ID_SERVICE__r.Name);
            keyParams.put('faId', eachFiscAgrmnt.Id);//fiscAgrmntMap.get(eachFiscAgrmnt.Id).Id);
            
           /*  if(fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_REASON_END_AGRMT__c !='DEC' && fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_STATUS__c == OPEN){
                system.debug('before calling createCorspdRequest--'+CR708RsnCode);
                 CorspdTrigger.createCorspdRequest(CR708RsnCode,NULL,NULL,countyCode,keyParams);
            }*/
            
            if( fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_REASON_END_AGRMT__c !='DEC' && fiscAgrmntOldMap.get(eachFiscAgrmnt.Id).DTE_END_AGRMT__c !=fiscAgrmntMap.get(eachFiscAgrmnt.Id).DTE_END_AGRMT__c){
                if(!oldDOCRQMap.containsKey(eachFiscAgrmnt.id)){
                    CorspdTrigger.createCorspdRequest(CR708RsnCode,NULL,NULL,countyCode,keyParams);
                }else{
                    // Add logic to update existing req
                }
            } 
            /*(if(((fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_FACILITY__c == CENTER) || (fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_FACILITY__c == HOME)) && ( fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_STATUS__c == DRAFT)) {
                CorspdTrigger.createCorspdRequest(CR704RsnCode,NULL,NULL,countyCode,keyParams);
            } else if ((fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_FACILITY__c == EXEMPT) && ( fiscAgrmntMap.get(eachFiscAgrmnt.Id).CDE_TYPE_STATUS__c == DRAFT)) {
                CorspdTrigger.createCorspdRequest(CR706RsnCode,NULL,NULL,countyCode,keyParams);
            }*/
        }    
        if(!existingAuthCorrespondence.isEmpty()){
            for(T_DOC_RQ__c eachCorrFoundForAuth : existingAuthCorrespondence){
                T_DOC_RQ__C updAuthCorrRecrds = new T_DOC_RQ__c();
                updAuthCorrRecrds.Id = eachCorrFoundForAuth.Id;
                updAlreadyExistingFACorrespondence.add(updAuthCorrRecrds);
            }
            if(!Test.isRunningTest()){
        		GenericDMLHandler.updateRecords(updAlreadyExistingFACorrespondence, null);    
        	}
        }
    }

    // Added below method by Rishav for CCCAP-7432
    public static void updateProviderFields(Map<Id, T_PROVR_FISCAL_AGREMENT__c> newFAMap){
        List<T_CHATS_PROVR_STATUS__c> ProvrListToUpdate = new List<T_CHATS_PROVR_STATUS__c>();
        Map<String, String> provrFAIdMap = new Map<String, String>();
        for(T_PROVR_FISCAL_AGREMENT__c fa : newFAMap.values()){
            if(fa.CDE_TYPE_STATUS__c == 'OPN'){
                provrFAIdMap.put(fa.ID_SERVICE__c, fa.Id);
            }
        }
        for(T_CHATS_PROVR_STATUS__c provr : [SELECT Id, DTE_Original_FA__c FROM T_CHATS_PROVR_STATUS__c WHERE Id IN :provrFAIdMap.keyset()]){
            T_PROVR_FISCAL_AGREMENT__c currentFA = newFAMap.get(provrFAIdMap.get(provr.Id));
            if(provr.DTE_Original_FA__c == null || provr.DTE_Original_FA__c > currentFA.DTE_BEGIN_AGRMT__c){
                provr.DTE_Original_FA__c = currentFA.DTE_BEGIN_AGRMT__c;
                ProvrListToUpdate.add(provr);
            }
        }
        if(!ProvrListToUpdate.isEmpty()) {
            Set<String> byPassObjects = new Set<String>{'T_CHATS_PROVR_STATUS__c'};
            GenericDMLHandler.updateRecords(ProvrListToUpdate, new Map<String, Object>{'byPassObjects'=>byPassObjects,'Method__c'=>'updateProviderFields','Class__c'=>'FiscalAgreementServices'});
        }
    }
}