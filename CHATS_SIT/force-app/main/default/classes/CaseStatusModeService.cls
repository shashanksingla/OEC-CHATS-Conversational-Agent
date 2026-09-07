/*
* Change Log :
* Developer Name                    Date                    Description
* Shubham Khandelwal              5/14/2018             Adding null ande size check on line number 68 before DML operation
* Azharuddin Mohammad             10/31/2018            Removed the Condition check for Closed status while inserting the record into ATS. will insert record on every insert/ update on case status record. (CHAT-6935)
* Azharuddin Mohammad			  11/04/2021			CCCAP-3672 : Added the condition for T112 - T112 will now be generated for only active individuals. i.e, if the individual is active on any open case and gets added as an active individual on any new open case

*/

public with sharing class CaseStatusModeService {
    public static final string CLOSED='CLS';
    public static final string OPEN='OPN';
    public static final string PENDING='PEN';
    public static final string INTAKE='INT';
    public static final string CANCELLED='Cancelled';
    public static boolean disableTrigger =false; // added for CCCAP-14909
    /* BG 6/2/2018 this method is no where used so commenting it
public static set<Id> validUpdatedCaseIds(List<T_SBSD_CASE__c> caseNewList,Map<Id,T_SBSD_CASE__c> caseOldMap) {
set<Id> caseIds = new set<Id>();
//Removed unused variable on 5/13/2018 BG  
for(T_SBSD_CASE__c eachCase:caseNewList) {
if(caseOldMap.get(eachCase.Id).DTE_RCVD_PACKET_REDET__c!=eachCase.DTE_RCVD_PACKET_REDET__c) {
caseIds.add(eachCase.Id);
}

}
return caseIds;
} 

public static void createCaseStatusModeFromCaseIds(Set<Id> caseIds){        
List<T_SBSD_CASE_STATUS_MODE__c> upsertCaseStatusMode = new List<T_SBSD_CASE_STATUS_MODE__c>();
for(T_SBSD_CASE__c cas:[Select Id,Name,(SELECT CDE_MODE_CASE__c,CDE_STATUS_CASE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,Id,
IDN_CASE__c FROM T_SBSD_CASE10__r ORDER BY DTE_BEGIN_EFFV__c DESC NULLS FIRST LIMIT 1) 
from T_SBSD_CASE__c where Id in :caseIds]){
if(cas.T_SBSD_CASE10__r.size()>0){
T_SBSD_CASE_STATUS_MODE__c sbsdCaseStaMod =  new T_SBSD_CASE_STATUS_MODE__c();
sbsdCaseStaMod.CDE_MODE_CASE__c= 'RED';
sbsdCaseStaMod.DTE_BEGIN_EFFV__c= date.today();
sbsdCaseStaMod.CDE_STATUS_CASE__c = cas.T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c;
sbsdCaseStaMod.IDN_CASE__c = cas.T_SBSD_CASE10__r.get(0).IDN_CASE__c;
upsertCaseStatusMode.add(sbsdCaseStaMod);  
if(cas.T_SBSD_CASE10__r.get(0).DTE_BEGIN_EFFV__c < date.today()-1){
cas.T_SBSD_CASE10__r.get(0).DTE_END_EFFV__c = date.today()-1; 
upsertCaseStatusMode.add(cas.T_SBSD_CASE10__r);    
}
}
}

if(!upsertCaseStatusMode.isEmpty()){
upsert upsertCaseStatusMode;
}
}  

BG 6/2/2018*/
    
    /**
* @description Check if CDE_STATUS_CASE__c is Closed then Cancel all its Case associated Tasks
* @author Bharadwaj Gaddam
* @date 1/25/2018   
* @param List<T_SBSD_CASE_STATUS_MODE__c> trigger.new Case Status Mode list
* @return void
*/
    public static void updateTaskStatus(List<T_SBSD_CASE_STATUS_MODE__c> caseStatusModeList){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CaseStatusModeService','Method__c'=>'updateTaskStatus'};
            Set<Id> caseIds = new Set<Id>();
        for (T_SBSD_CASE_STATUS_MODE__c  caseStatModEach : caseStatusModeList) {
            if(caseStatModEach.IDN_CASE__c!=null && caseStatModEach.CDE_STATUS_CASE__c==CLOSED) {
                caseIds.add(caseStatModEach.IDN_CASE__c);
            }
        }
        
        if (caseIds.size() > 0) {
            try{
                List<Task> tasks = [
                    select Id from Task
                    where WhatId in :caseIds
                    and Status !=:CANCELLED
                ];
                for (Task t : tasks) {
                    t.Status = CANCELLED;
                }
                if(tasks.size() > 0 && tasks != NULL ){
                    GenericDMLHandler.updateRecords(tasks,methodInfo);
                }
            }catch(Exception ex) {
                system.Debug(ex.getMessage());
                ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            }
        }
    }
    /**    
* @description Insert Record in ATS Object
* @author Vineet Srivastava
* @date 4/12/2018   
* @param List<T_SBSD_CASE_STATUS_MODE__c> trigger.new CaseStatusMode list,
* @return void
*/  
    public static void insertATSRecord(List<T_SBSD_CASE_STATUS_MODE__c> newCaseStatusModeList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        Set<Id> setCaseIds = new Set<Id>();
        Map<Id,String>mapCaseIdtoName = new Map<Id,String>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CaseStatusModeService','Method__c'=>'insertATSRecord'};  
            for(T_SBSD_CASE_STATUS_MODE__c caseStatusModeRec:newCaseStatusModeList) {
                setCaseIds.add(caseStatusModeRec.IDN_CASE__c);
            }
        for(T_SBSD_CASE__c caseRec:[Select Id, Name from T_SBSD_CASE__c where Id in :setCaseIds]){
            mapCaseIdtoName.put(caseRec.Id,caseRec.Name);
        }
        for(T_SBSD_CASE_STATUS_MODE__c caseStatusModeRec:newCaseStatusModeList) {
            
            //if(caseStatusModeRec.CDE_STATUS_CASE__c =='CLS'){
            batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord.CDE_STATUS_TRANS__c= '1';
            atsRecord.CDE_TYPE_TRANS__c ='1';
            if(mapCaseIdtoName.containsKey(caseStatusModeRec.IDN_CASE__c)){
                atsRecord.IDN_CASE__c = mapCaseIdtoName.get(caseStatusModeRec.IDN_CASE__c);
            }
            atsRecord.DTE_CHANGE_LAST__c = system.today();
            lstATSRecords.add(atsRecord);
            //}
        }
        if(!lstATSRecords.isEmpty()){
            ATSHandler.insertATSRecord(true, lstATSRecords);
        }
    }
    
    public static void createTaskT112(List<T_SBSD_CASE_STATUS_MODE__c> caseStatusModeList, Map<Id, T_SBSD_CASE_STATUS_MODE__c> oldMap){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CaseStatusModeService','Method__c'=>'updateTaskStatus'};
            Set<Id> caseIds = new Set<Id>();
        Map<Id, T_SBSD_CASE_STATUS_MODE__c> caseToStatusMode = new Map<Id, T_SBSD_CASE_STATUS_MODE__c>();
        for (T_SBSD_CASE_STATUS_MODE__c  caseState : caseStatusModeList) {
            if(caseState.IDN_CASE__c != null && caseState.CDE_STATUS_CASE__c == OPEN
               && (oldMap == null || oldMap.get(caseState.Id).CDE_STATUS_CASE__c == PENDING)) {
                   caseIds.add(caseState.IDN_CASE__c);
                   if(oldMap != null)
                       caseToStatusMode.put(caseState.IDN_CASE__c, oldMap.get(caseState.Id));
               }            
        }
        
        if (caseIds.size() > 0) {
            try{
                List<T_SBSD_CASE__c> caseList = [SELECT Id,Name,CDE_COUNTY__r.Name,CDE_COUNTY__c,
                                                 (SELECT ID,CDE_MODE_CASE__c,CDE_STATUS_CASE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c
                                                  FROM T_SBSD_CASE10__r WHERE ID NOT IN : caseStatusModeList 
                                                  ORDER BY DTE_BEGIN_EFFV__c DESC NULLS FIRST LIMIT 1),
                                                 (SELECT IDN_CLIENT__c FROM CaseIndividuals__r WHERE DTE_BEGIN_EFFV__c <= :system.today() AND (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today()))
                                                 FROM T_SBSD_CASE__c WHERE Id IN :caseIds];
                map<Id, T_SBSD_CASE__c> caseToIndividualMap = new map<Id, T_SBSD_CASE__c>();
                for(T_SBSD_CASE__c cs : caseList){
                    if((cs.T_SBSD_CASE10__r.size() > 0 && cs.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c == PENDING && cs.T_SBSD_CASE10__r[0].CDE_MODE_CASE__c == INTAKE)
                       || (oldMap != null && caseToStatusMode.get(cs.Id).CDE_STATUS_CASE__c == PENDING && caseToStatusMode.get(cs.Id).CDE_MODE_CASE__c == INTAKE)){
                           for(T_SBSD_CASE_INDIV__c ind : cs.CaseIndividuals__r){
                               caseToIndividualMap.put(ind.IDN_CLIENT__c, cs);
                           }
                       } 
                }
                
                List<T_SBSD_CASE_INDIV__c> existingIndivs = [SELECT IDN_Case__c, IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__c
                                                             WHERE IDN_Case__c NOT IN :caseIds AND IDN_CLIENT__c IN :caseToIndividualMap.keyset() AND DTE_BEGIN_EFFV__c <= :system.today() AND (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today())];
                set<Id> existingCaseIds = new set<Id>();
                for(T_SBSD_CASE_INDIV__c ind : existingIndivs){
                    existingCaseIds.add(ind.IDN_Case__c);
                }
                
                List<Task> tasksToBeCreated = new List<Task>();
                T_SBSD_CASE__c newCase;
                List<T_SBSD_CASE__c> existingCaseList = new List<T_SBSD_CASE__c>();
                for(T_SBSD_CASE__c cs : [SELECT Id, OwnerId, (SELECT ID,CDE_MODE_CASE__c,CDE_STATUS_CASE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c
                                                              FROM T_SBSD_CASE10__r ORDER BY DTE_BEGIN_EFFV__c DESC NULLS FIRST LIMIT 1),
                                         (SELECT Id, Name, IDN_CLIENT__c FROM CaseIndividuals__r WHERE DTE_BEGIN_EFFV__c <= :system.today() AND (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today()))
                                         FROM T_SBSD_CASE__c WHERE Id IN :existingCaseIds]){
                                             if(cs.T_SBSD_CASE10__r.size() > 0 && cs.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c == OPEN){
                                                 for(T_SBSD_CASE_INDIV__c ind : cs.CaseIndividuals__r){
                                                     if(caseToIndividualMap.containsKey(ind.IDN_CLIENT__c)){
                                                         newCase = caseToIndividualMap.get(ind.IDN_CLIENT__c);
                                                         Task tsk = new Task();
                                                         tsk.Subject = 'T112 - New case was created for Individual with existing Open case';
                                                         tsk.WhatId = cs.Id;
                                                         if(!Test.isRunningTest())
                                                             tsk.OwnerId = cs.OwnerId;
                                                         tsk.Status = 'New';
                                                         tsk.Priority = 'Normal';
                                                         tsk.ActivityDate = System.today().addDays(10);
                                                         tsk.Description = 'For Case Individual '+ind.Name+'('+getHyperlink(ind.Id)+'), a new case has been created for '+newCase.Name+'('+getHyperlink(newCase.Id)+') in '+newCase.CDE_COUNTY__r.Name+'('+getHyperlink(newCase.CDE_COUNTY__c)+') county. Please review to ensure no action is required.';
                                                         taskstoBeCreated.add(tsk);
                                                     }
                                                 }                    
                                             }
                                         }
                if(!taskstoBeCreated.isEmpty())
                    insert taskstoBeCreated;
            }catch(Exception ex) {
                system.Debug(ex.getMessage());
                ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            }
        }
    }
    
    public static String getHyperlink(Id recordId){
        return URL.getOrgDomainUrl().toExternalForm()+'/'+recordId;
    }
    
    public static void updateCase(List<T_SBSD_CASE_STATUS_MODE__c> caseStatusModeList){
        List<T_SBSD_CASE__c> caseToUpdate 	= new List<T_SBSD_CASE__c>();
        Map<String,Object> methodInfo 		= new Map<String,Object>{'Class__c'=>'CaseStatusModeService','Method__c'=>'updateCase'};
            for(T_SBSD_CASE_STATUS_MODE__c csm : caseStatusModeList){            
                //added status check for CCCAP-11857
                if(csm.CDE_MODE_CASE__c == 'RED' && csm.CDE_STATUS_CASE__c == 'OPN'){ // Added by Rishav for CCCAP-7088
                    T_SBSD_CASE__c cs = new T_SBSD_Case__c(Id=csm.IDN_CASE__c);
                    cs.DTE_REDET_MODE_CASE__c = System.today();
                    caseToUpdate.add(cs);
                }
            }
        if(!caseToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(caseToUpdate, methodInfo);
        }
    }
    public static void markReverseReferTrack(List<T_SBSD_CASE_STATUS_MODE__c> caseStatusModeList,Map<Id, T_SBSD_CASE_STATUS_MODE__c> oldMap){
        Set<Id> caseIdSet 				 = new set<Id>();
        List<T_SBSD_CASE__c> updateCases = new List<T_SBSD_CASE__c>();
        Map<String,Object> methodInfo 	 = new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_CASE_STATUS_MODE__c','T_SBSD_CASE__c'},'Class__c'=>'CaseStatusModeService','Method__c'=>'markReverseReferTrack'};
        List<T_SBSD_CASE_STATUS_MODE__c> caseStatModeToUpdate = new List<T_SBSD_CASE_STATUS_MODE__c>();
        for(T_SBSD_CASE_STATUS_MODE__c csm : caseStatusModeList){
            if(
                (Trigger.isInsert && (csm.CDE_STATUS_CASE__c == PENDING || csm.CDE_STATUS_CASE__c == CLOSED)) ||
                (Trigger.isUpdate && csm.CDE_STATUS_CASE__c!=oldMap.get(csm.Id).CDE_STATUS_CASE__c && csm.CDE_STATUS_CASE__c == PENDING)
            ){                
                caseIdSet.add(csm.IDN_CASE__c);                
            }           
        }
        if(!caseIdSet.isEmpty()){
            Map<Id, T_SBSD_CASE__c> caseMap = new Map<Id, T_SBSD_CASE__c>([SELECT Id, CHATS_Reverse_Refer_Mode__c,Case_Reverse_Refer_Track__c,Program_Type__c,
                                                                           (SELECT Id, CDE_STATUS_CASE__c FROM T_SBSD_CASE10__r WHERE Id NOT IN :Trigger.New ORDER BY DTE_BEGIN_EFFV__c DESC LIMIT 1) 
                                                                           FROM T_SBSD_CASE__c WHERE Id IN :caseIdSet]);
            for(T_SBSD_CASE_STATUS_MODE__c csm : caseStatusModeList){
                T_SBSD_Case__c cs 	= caseMap.get(csm.IDN_CASE__c);
                Boolean updateCase 	= false;
                String reverseStat 	= csm.CDE_STATUS_CASE__c == CLOSED ? 'Case Closure' : 'Pending Case';
                if(csm.CDE_STATUS_CASE__c == CLOSED 
                   && (cs.Program_Type__c == 'TF' || cs.Program_Type__c == 'LI')){
                       updateCase = true;
                   } else if(csm.CDE_STATUS_CASE__c == PENDING 
                             && (cs.Program_Type__c == 'TF' || cs.Program_Type__c == 'LI')){
                                 updateCase = true;
                             }
                if(updateCase){
                    if(cs.CHATS_Reverse_Refer_Mode__c == null || 
                       cs.CHATS_Reverse_Refer_Mode__c!=null && !cs.CHATS_Reverse_Refer_Mode__c.split(';').contains(reverseStat)){
                           cs.CHATS_Reverse_Refer_Mode__c = cs.CHATS_Reverse_Refer_Mode__c!=null?cs.CHATS_Reverse_Refer_Mode__c+';'+reverseStat :reverseStat;    
                       }
                    cs.Case_Reverse_Refer_Track__c = true;
                    T_SBSD_CASE_STATUS_MODE__c csmToUpdate = new T_SBSD_CASE_STATUS_MODE__c(Id=csm.Id,Case_Status_Reverse_Refer_Track__c=true);
                    caseStatModeToUpdate.add(csmToUpdate);    
                }
                //existing logic of UpdateCase method, merged here for reducing the case query count to 1.
                if(Trigger.isInsert && csm.CDE_STATUS_CASE__c == PENDING && !cs.T_SBSD_CASE10__r.isEmpty()){
                    if(cs.T_SBSD_CASE10__r.size() > 0 && cs.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c == CLOSED){
                        cs.DTE_REOPEN_LATEST__c = csm.DTE_BEGIN_EFFV__c;
                        updateCase = true;
                    }
                }
                if(updateCase){
                    updateCases.add(cs);
                }
            }
            if(!updateCases.isEmpty()){
                CaseLastUpdatedServices.disableTrigger = true; // added for CCCAP-14909
                GenericDMLHandler.updateRecords(updateCases, methodInfo);
                CaseLastUpdatedServices.disableTrigger = false; // added for CCCAP-14909
            }
            if(!caseStatModeToUpdate.isEmpty()){
                CaseStatusModeService.disableTrigger = true; // added for CCCAP-14909
                GenericDMLHandler.updateRecords(caseStatModeToUpdate, methodInfo); // added for CCCAP-10162 for CHATS reverse Referral
                CaseStatusModeService.disableTrigger = false; // added for CCCAP-14909
            }
        }
    }
    // added for UFE by Shashank 08/13/24
    public static void captureUpdate_UFE(List<T_SBSD_CASE_STATUS_MODE__c> caseStatusModeList,Map<Id, T_SBSD_CASE_STATUS_MODE__c> oldMap){
        Map<Id,UFEChangeInterface__e> ufeInfoUpdateEventyMap= new Map<Id,UFEChangeInterface__e>();
        Set<Id>cases = new Set<Id>();
        for(T_SBSD_CASE_STATUS_MODE__c csm : caseStatusModeList){
            if(
                (Trigger.isInsert && csm.CDE_STATUS_CASE__c == CLOSED) ||
                (Trigger.isUpdate && csm.CDE_STATUS_CASE__c == CLOSED && csm.CDE_STATUS_CASE__c!=oldMap.get(csm.Id).CDE_STATUS_CASE__c)
            ){
                cases.add(csm.IDN_CASE__c);
            }
            if(!cases.isEmpty()){
                for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id,IDN_CASE__c FROM T_SBSD_CASE_INDIV__c 
                                                      WHERE IDN_CASE__c IN:cases and IDN_Client__r.UFE_Request_Flag__c=true WITH SYSTEM_MODE])
                {
                    ufeInfoUpdateEventyMap.put(caseIndiv.IDN_CASE__c ,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case'));
                }
                Eventbus.publish(ufeInfoUpdateEventyMap.values());                
            }
        }
    }
}