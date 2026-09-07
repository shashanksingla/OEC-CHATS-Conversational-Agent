/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/11/2017                                                          
*  @description    Handler class for Case Individual Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version
*  * CHAT-1204 : T_SBSD_CASE_INDIV-DTE_BEGIN_EFFV cannot be before DTE_BEGIN_EFFV of any T_AUTH records with a status of Authorized
*  * CHAT-1200 : If the child is not in Joint custody (T_INDIV_CUST) and they are already on another case, do not allow them to be added to a second case
*  * CHAT-1203 : creating SBSD_INIDV_ROLE record when Primary indicator is set to true
*  * CHATS-5052 : Updated the validation of effective begin date with latest application received date to run only when effective begin date is changed.
*********************************************************************************************/
public with sharing class caseIndividualServices {
    public static final String AUTHORIZED ='2';
    public static Boolean disableTrigger = false;
    public static Boolean atsRecordsCreated = false;
    public static Map<String,Boolean> caseIndivRecordMap = new Map<String,Boolean>();
    
    //CHAT-1204
    public static void effvBeginDate(List<T_SBSD_CASE_INDIV__c> newCaseIndividualList, Map<Id, T_SBSD_CASE_INDIV__c> oldCaseIndividualsMap){
        
        Map<Id,T_SBSD_CASE_INDIV__c> caseIndiv_ApplnPrcsQueue_Map = new Map<Id,T_SBSD_CASE_INDIV__c>();
        Map<Id,T_SBSD_CASE_INDIV__c> caseIndiv_Auth_Map = new Map<Id,T_SBSD_CASE_INDIV__c>();
        Map<Id,T_SBSD_CASE_INDIV__c> caseIndiv_Auth_Map1 = new Map<Id,T_SBSD_CASE_INDIV__c>();
        for(T_SBSD_CASE_INDIV__c eachCaseIndiv : newCaseIndividualList){
            if(eachCaseIndiv.IDN_CASE__c != NULL 
               && (eachCaseIndiv.Id==null || eachCaseIndiv.DTE_BEGIN_EFFV__c!=oldCaseIndividualsMap.get(eachCaseIndiv.Id).DTE_BEGIN_EFFV__c)){
                   caseIndiv_ApplnPrcsQueue_Map.put(eachCaseIndiv.IDN_CASE__c , eachCaseIndiv);
               }
            
            if((eachCaseIndiv.IDN_CASE__c != NULL) && (eachCaseIndiv.IDN_CLIENT__c != NULL)){
                caseIndiv_Auth_Map.put(eachCaseIndiv.IDN_CASE__c , eachCaseIndiv);
                caseIndiv_Auth_Map1.put(eachCaseIndiv.IDN_CLIENT__c , eachCaseIndiv);
            }
        }
        
        if(!caseIndiv_ApplnPrcsQueue_Map.isEmpty()){
            for(T_APPLN_PRCS_QUEUE__c applnPrcsQueue: [select DTE_RCVD_APPLN__c, IDN_CASE__c, IDN_CASE__r.is_Peak_Data__c From T_APPLN_PRCS_QUEUE__c WHERE IDN_CASE__c =:caseIndiv_ApplnPrcsQueue_Map.keySet() ORDER BY DTE_RCVD_APPLN__c DESC LIMIT 1]){
                if(caseIndiv_ApplnPrcsQueue_Map.get(applnPrcsQueue.IDN_CASE__c) != NULL){
                    T_SBSD_CASE_INDIV__c caseIndivRecord = caseIndiv_ApplnPrcsQueue_Map.get(applnPrcsQueue.IDN_CASE__c);
                    if(caseIndivRecord.DTE_BEGIN_EFFV__c < applnPrcsQueue.DTE_RCVD_APPLN__c && !applnPrcsQueue.IDN_CASE__r.is_Peak_Data__c){
                        caseIndivRecord.DTE_BEGIN_EFFV__c.addError('Effective Begin Date Cannot be before-Latest Appl Receive Date in Application Process Queue');
                    }
                }       
            }
        }
        if(!caseIndiv_Auth_Map.isEmpty() && !caseIndiv_Auth_Map1.isEmpty()){
            for(T_AUTH__c eachAuth : [select Id, IDN_CASE__c,IDN_CASE__r.Is_Peak_Data__c,IDN_CASE__r.Is_CBMS_Data__c, IDN_CLIENT__c, DTE_BEGIN_EFFV_AUTH__c FROM T_AUTH__c WHERE IDN_CASE__c IN: caseIndiv_Auth_Map.keySet() AND IDN_CLIENT__c IN: caseIndiv_Auth_Map1.keySet() AND DTE_END_EFFV_AUTH__c >=: system.today() ]){  //ID IN (select idn_auth__c FROM batchsit_t_auth_status__x WHERE cde_status_auth__c =:AUTHORIZED )
                T_SBSD_CASE_INDIV__c caseIndivRecord1 = caseIndiv_Auth_Map.get(eachAuth.IDN_CASE__c);
                if(caseIndivRecord1.DTE_BEGIN_EFFV__c > eachAuth.DTE_BEGIN_EFFV_AUTH__c && !eachAuth.IDN_CASE__r.Is_Peak_Data__c && !eachAuth.IDN_CASE__r.Is_CBMS_Data__c){
                    caseIndivRecord1.DTE_BEGIN_EFFV__c.addError('Effective Begin Date cannot be after the Auth Begin Date of Authorization with Status - Authorized');
                }
            }
        } 
    }
    
    //CHAT-1200 : If the child is not in Joint custody (T_INDIV_CUST) and are already on another case,
    //            do not allow them to be added to a second case
    public static void indivCaseAlreadyAssigned(List<T_SBSD_CASE_INDIV__c> newCaseIndividualList){
        Map<Id, T_SBSD_CASE_INDIV__c> allIndividualMap = new Map<Id, T_SBSD_CASE_INDIV__c>();
        set<string> indivPrsntInCustody = new set<string>();
        set<Id> teenParentIndivSet = new set<Id>();
        List<String> TEEN_PARENT_RELATIONSHIPS = new List<String>{'M','F','H','W','CLH','CLW','LIC'};
            for(T_SBSD_CASE_INDIV__c eachCaseIndiv : newCaseIndividualList){
                if(eachCaseIndiv.IDN_CLIENT__c != NULL && !eachCaseIndiv.IND_CRTKR__c){ 
                    allIndividualMap.put(eachCaseIndiv.IDN_CLIENT__c, eachCaseIndiv);
                }
            }
        
        for(T_SBSD_INDIV__c individual:[select Id,(SELECT Id FROM Relationship__r WHERE CDE_TYPE_REL_INDIV__c IN:TEEN_PARENT_RELATIONSHIPS) from T_SBSD_INDIV__c where Id IN:allIndividualMap.keySet() and Age__c<18]) {
            if(individual.Relationship__r.size()>0) {
                teenParentIndivSet.add(individual.Id);
            }
            
        } 
        
        if(!allIndividualMap.isEmpty()){
            for(T_INDIV_CUST__c eachIndivCustody : [select Id, IDN_CLIENT__c FROM T_INDIV_CUST__c WHERE IDN_CLIENT__c IN:allIndividualMap.keySet() AND DTE_BEGIN_EFFV__c <= :system.today() AND (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today())]){
                indivPrsntInCustody.add(eachIndivCustody.IDN_CLIENT__c);
            }
            for(T_SBSD_CASE_INDIV__c caseIndivCheck : [select Id, IDN_CASE__c,IDN_CASE__r.Is_Peak_Data__c,IDN_CLIENT__c,IDN_CASE__r.Is_CBMS_Data__c FROM T_SBSD_CASE_INDIV__c WHERE  IDN_CLIENT__c IN:allIndividualMap.keySet() AND IDN_CASE__c != NULL AND IDN_CASE__r.CLOSED_CASES_STATUS__c<=0 and DTE_BEGIN_EFFV__c <= :system.today() and (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today()) and IND_CRTKR__c=false  and IDN_CLIENT__r.Age__c<18]){ 
                if(caseIndivCheck.IDN_CLIENT__c != null ) {
                    T_SBSD_CASE_INDIV__c caseIndivUpd = allIndividualMap.get(caseIndivCheck.IDN_CLIENT__c);
                    
                    if((caseIndivUpd.IDN_CASE__c != caseIndivCheck.IDN_CASE__c) && (!indivPrsntInCustody.contains(caseIndivUpd.IDN_CLIENT__c)) && !teenParentIndivSet.contains(caseIndivUpd.IDN_CLIENT__c)){
                        caseIndivUpd.addError(Label.JOINT_CUSTODY_NOT_PRESENT);
                    }
                }
            }
        }
    }  
    
    //CHAT- 1203: cannot update primary careTaker when case is not in Intake mode
    public static final String INTAKE = 'INT';
    public static void prmryCareTakerCannotUpdtd(List<T_SBSD_CASE_INDIV__c> newCaseIndivList, map<Id, T_SBSD_CASE_INDIV__c> caseIndivOldMapList){
        set<Id> caseIndivRecIds = new set<Id>();
        set<Id> prmryCrtkrAvlbleForCase = new set<Id>();
        //set<Id> checkPrmryCrtkrCrtdToday = new set<Id>();
        //List<Id> lstCaseIndivRolesAlreadyCrtdWithTodayDate = new List<Id>();
        Map<Id, String> caseStatusMap = new map<Id, String>();
        Map<Id, String> caseStatusIds = new map<Id, String>();
        Map<Id, T_SBSD_CASE_INDIV__c> caseIndivMap = new Map<Id, T_SBSD_CASE_INDIV__c>();
        Map<String, Boolean> caseIdToIsPeakData = new Map<String, Boolean>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'prmryCareTakerCannotUpdtd'};
            for(T_SBSD_CASE_INDIV__c eachCaseIndiv : newCaseIndivList){
                if(eachCaseIndiv.IDN_CASE__c != Null){
                    system.debug('The Case Individual 1-->'+eachCaseIndiv);
                    caseIndivRecIds.add(eachCaseIndiv.Id);
                    caseIndivMap.put(eachCaseIndiv.IDN_CASE__c, eachCaseIndiv);
                }
            }
        
        //get status mode for all cases
        for(T_SBSD_CASE_STATUS_MODE__c caseStatusMode: [select IDN_CASE__c, CDE_MODE_CASE__c,CDE_STATUS_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:caseIndivMap.keySet() AND DTE_BEGIN_EFFV__c <=: system.today() AND (DTE_END_EFFV__c = Null OR DTE_END_EFFV__c >=: system.today())]){
            caseStatusIds.put(caseStatusMode.IDN_CASE__c, caseStatusMode.CDE_MODE_CASE__c);
            caseStatusMap.put(caseStatusMode.IDN_CASE__c, caseStatusMode.CDE_STATUS_CASE__c);
        }
        
        //get Previous Primary caretakers for case with status not in INTAKE.
        if(!caseIndivMap.isEmpty()){
            for(T_SBSD_CASE_INDIV__c prmryCrtkrAvlble : [select Id, IDN_CASE__c, IDN_CASE__r.is_Peak_Data__c, IDN_CASE__r.Is_CBMS_Data__c, IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c 
                                                         WHERE IDN_CASE__c IN: caseIndivMap.keySet() 
                                                         AND IND_CRTKR__c = True 
                                                         AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY)
                                                         AND Id NOT IN: caseIndivRecIds]){
                                                             caseIdToIsPeakData.put(prmryCrtkrAvlble.IDN_CASE__c, prmryCrtkrAvlble.IDN_CASE__r.is_Peak_Data__c);
                                                             prmryCrtkrAvlbleForCase.add(prmryCrtkrAvlble.IDN_CASE__c);
                                                             //checkPrmryCrtkrCrtdToday.add(prmryCrtkrAvlble.Id);
                                                         }
        }
        
        /*system.debug('The Primary Care Taker already Created today'+checkPrmryCrtkrCrtdToday);
// get all caseIndividual Role records with date begin = today for all cases.
for(T_SBSD_CASE_INDIV_ROLE__c eachCaseIndivRole : [select Id, DTE_BEGIN_EFFV__c, CASE_ID__c, IDN_CASE_INDIV__c FROM T_SBSD_CASE_INDIV_ROLE__c WHERE IDN_CASE_INDIV__c IN:checkPrmryCrtkrCrtdToday AND DTE_BEGIN_EFFV__c =:system.today() ]) {
try{
Id  sfid = eachCaseIndivRole.CASE_ID__c;
lstCaseIndivRolesAlreadyCrtdWithTodayDate.add(sfid);
}catch (System.StringException e){
System.debug('The following exception has occurred from Method prmryCareTakerCannotUpdtd Line 118 in Apex class caseIndividualServices: ' + e.getMessage()); // IronDome Report fix.        
ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
}
}
system.debug('case Indiv Role record - case Id'+lstCaseIndivRolesAlreadyCrtdWithTodayDate);*/
        
        for(T_SBSD_CASE_INDIV__c eachNewCaseIndiv : newCaseIndivList){
            if(caseStatusMap.get(eachNewCaseIndiv.IDN_CASE__c) == 'CLS' ){
                if(eachNewCaseIndiv.Id != null){
                    //CCCAP-14246
                    if((eachNewCaseIndiv.Individual_Status__c != caseIndivOldMapList.get(eachNewCaseIndiv.Id).Individual_Status__c) && (!caseIdToIsPeakData.containsKey(eachNewCaseIndiv.IDN_CASE__c) || !caseIdToIsPeakData.get(eachNewCaseIndiv.IDN_CASE__c))){
                        eachNewCaseIndiv.Individual_Status__c.addError('Cannot update when case is in Closed Status');
                    }
                }else if((eachNewCaseIndiv.Id == null) && (prmryCrtkrAvlbleForCase.contains(eachNewCaseIndiv.IDN_CASE__c)) && (eachNewCaseIndiv.Individual_Status__c=='PC') && (!caseIdToIsPeakData.containsKey(eachNewCaseIndiv.IDN_CASE__c) || !caseIdToIsPeakData.get(eachNewCaseIndiv.IDN_CASE__c))){
                    eachNewCaseIndiv.Individual_Status__c.addError('Cannot change the Primary CareTaker for Case which is in Closed Status');
                }
            }
        }
        /*   if(caseStatusIds.get(eachNewCaseIndiv.IDN_CASE__c) != INTAKE ){
if(eachNewCaseIndiv.Id != null){
if((eachNewCaseIndiv.IND_CRTKR__c != caseIndivOldMapList.get(eachNewCaseIndiv.Id).IND_CRTKR__c) && (!caseIdToIsPeakData.containsKey(eachNewCaseIndiv.IDN_CASE__c) || !caseIdToIsPeakData.get(eachNewCaseIndiv.IDN_CASE__c))){
eachNewCaseIndiv.IND_CRTKR__c.addError('cannot update when case is not in Intake mode');
}
}else if((eachNewCaseIndiv.Id == null) && (prmryCrtkrAvlbleForCase.contains(eachNewCaseIndiv.IDN_CASE__c)) && (eachNewCaseIndiv.IND_CRTKR__c) && (!caseIdToIsPeakData.containsKey(eachNewCaseIndiv.IDN_CASE__c) || !caseIdToIsPeakData.get(eachNewCaseIndiv.IDN_CASE__c))){
eachNewCaseIndiv.IND_CRTKR__c.addError('Cannot change the Primary CareTaker for Case which is not in Intake Mode');
}
}else if (caseStatusIds.get(eachNewCaseIndiv.IDN_CASE__c) == INTAKE){
system.debug('Case In INtake - before trigger');
system.debug('The Case Individual 2-->'+eachNewCaseIndiv);
system.debug('case id'+eachNewCaseIndiv.IDN_CASE__c);
if((lstCaseIndivRolesAlreadyCrtdWithTodayDate != Null) && (eachNewCaseIndiv.IND_CRTKR__c)) {
if(lstCaseIndivRolesAlreadyCrtdWithTodayDate.contains(eachNewCaseIndiv.IDN_CASE__c) && (!caseIdToIsPeakData.containsKey(eachNewCaseIndiv.IDN_CASE__c) || !caseIdToIsPeakData.get(eachNewCaseIndiv.IDN_CASE__c))) {
eachNewCaseIndiv.addError('The Primary Caretaker on a case cannot be updated more than once daily. If eligibility needs to be processed today, please close the case and create a new case manually.');
}
}
}
}*/
    }
    public static void createCaseIndivRoleRecord (List<T_SBSD_CASE_INDIV__c> newCaseIndivList) {
        Map<Id, T_SBSD_CASE_INDIV__c> caseIndivMap = new Map<Id, T_SBSD_CASE_INDIV__c>();
        map<Id, T_SBSD_CASE_INDIV__c> prevprmryCrtkrUpdMap = new map<Id, T_SBSD_CASE_INDIV__c>();
        map<Id, T_SBSD_CASE_INDIV_ROLE__c> oldCaseIndivRoleMap = new map<Id, T_SBSD_CASE_INDIV_ROLE__c>();
        List<Id> avoidDuplicatecaseIndivRole = new List<Id>();
        set<Id> caseStatusIdsInIntake = new set<Id>();
        set<Id> caseIndivIds = new set<Id>();
        set<Id> caseStatusIdsNotClosed = new set<Id>();
        T_SBSD_CASE_INDIV_ROLE__c newCaseIndivRoleRecord = new T_SBSD_CASE_INDIV_ROLE__c();
        List<T_SBSD_CASE_INDIV_ROLE__c> newCaseIndivRoleList = new List<T_SBSD_CASE_INDIV_ROLE__c>();
        List<T_INDIV_REL__c> updatedRelationLst = new List<T_INDIV_REL__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'createCaseIndivRoleRecord'};
            
            for(T_SBSD_CASE_INDIV__c eachCaseIndiv : newCaseIndivList){
                if(eachCaseIndiv.IDN_CASE__c != Null) {
                    caseIndivIds.add(eachCaseIndiv.Id);
                    caseIndivMap.put(eachCaseIndiv.IDN_CASE__c, eachCaseIndiv);
                }
                
            }
        
        //get status mode of case is INTAKE
        for(T_SBSD_CASE_STATUS_MODE__c caseStatusMode: [select IDN_CASE__c, CDE_MODE_CASE__c, CDE_STATUS_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:caseIndivMap.keySet() AND DTE_BEGIN_EFFV__c <=: system.today() AND (DTE_END_EFFV__c = Null OR DTE_END_EFFV__c >=: system.today())]){
            if(caseStatusMode.CDE_MODE_CASE__c == 'INT'){
                caseStatusIdsInIntake.add(caseStatusMode.IDN_CASE__c);    
            }
            if(caseStatusMode.CDE_STATUS_CASE__c != 'CLS'){
                caseStatusIdsNotClosed.add(caseStatusMode.IDN_CASE__c);
            }
        }
        
        Set<Id> indivIdSet = new Set<Id>();
        Map<Id,List<T_INDIV_REL__c>> indivRelationshipMap = new Map<Id,List<T_INDIV_REL__c>>();
        //getting the list of previous primary CareTakers for all Intake case 
        if(!caseStatusIdsInIntake.isEmpty()){
            List<T_SBSD_CASE_INDIV__c> caseIndivList = new List<T_SBSD_CASE_INDIV__c>();
            if(!caseStatusIdsNotClosed.isEmpty()){
                caseIndivList = [select Id, IDN_CASE__c, IDN_CLIENT__c , IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c IN: caseStatusIdsNotClosed AND Id NOT IN:caseIndivIds AND IND_CRTKR__c = True];
                for(T_SBSD_CASE_INDIV__c PrevPrmryCrtkr : caseIndivList){
                    PrevPrmryCrtkr.IND_CRTKR__c = False;
                    PrevPrmryCrtkr.Individual_Status__c = 'AC'; //added for CCCAP-13633
                    indivIdSet.add(PrevPrmryCrtkr.IDN_CLIENT__c); 
                    // PrevPrmryCrtkr.DTE_END_EFFV__c = date.today() - 1;
                    prevprmryCrtkrUpdMap.put(PrevPrmryCrtkr.Id, PrevPrmryCrtkr);
                }   
            }
            if(!indivIdSet.isEmpty()){
                for(T_INDIV_REL__c relationRec: [Select Id,IDN_CLIENT__c, DTE_END_EFFV__c From T_INDIV_REL__c Where IDN_CLIENT__c IN :indivIdSet]){
                    if(indivRelationshipMap.containsKey(relationRec.IDN_CLIENT__c)){
                        List<T_INDIV_REL__c> relationLst1 = indivRelationshipMap.get(relationRec.IDN_CLIENT__c);
                        relationLst1.add(relationRec);
                        indivRelationshipMap.put(relationRec.IDN_CLIENT__c, relationLst1);  
                    }else{
                        List<T_INDIV_REL__c> relationLst2 = new List<T_INDIV_REL__c>();
                        relationLst2.add(relationRec);
                        indivRelationshipMap.put(relationRec.IDN_CLIENT__c, relationLst2);   
                    }   
                }    
            }
            if(indivRelationshipMap.size()>0){
                for(T_SBSD_CASE_INDIV__c cseIdivRec: caseIndivList){
                    for(T_INDIV_REL__c relRec : indivRelationshipMap.get(cseIdivRec.IDN_CLIENT__c)){
                        if(relRec.DTE_END_EFFV__c == null){
                            relRec.DTE_END_EFFV__c = system.today();
                            updatedRelationLst.add(relRec);
                        }else if(relRec.DTE_END_EFFV__c != null && relRec.DTE_END_EFFV__c> system.today()){
                            relRec.DTE_END_EFFV__c = system.today();
                            updatedRelationLst.add(relRec);
                        }
                    }
                }  
            }            
        }
        
        // if case Individual role for caseIndiv is already created today
        for(T_SBSD_CASE_INDIV_ROLE__c eachCaseIndivRole : [select Id, DTE_BEGIN_EFFV__c, CASE_ID__c, IDN_CASE_INDIV__c FROM T_SBSD_CASE_INDIV_ROLE__c WHERE IDN_CASE_INDIV__c IN:caseIndivIds AND DTE_BEGIN_EFFV__c =:system.today() ]) {
            avoidDuplicatecaseIndivRole.add(eachCaseIndivRole.IDN_CASE_INDIV__c);
        }
        for(T_SBSD_CASE_INDIV__c eachNewCaseIndiv : newCaseIndivList){
            //  if((eachNewCaseIndiv.IND_CRTKR__c) && (caseStatusIdsInIntake.contains(eachNewCaseIndiv.IDN_CASE__c) && (!avoidDuplicatecaseIndivRole.contains(eachNewCaseIndiv.Id) ))){
            if((eachNewCaseIndiv.IND_CRTKR__c) && (caseStatusIdsNotClosed.contains(eachNewCaseIndiv.IDN_CASE__c))){
                newCaseIndivRoleRecord.DTE_BEGIN_EFFV__c = date.today();
                newCaseIndivRoleRecord.IDN_CASE_INDIV__c = eachNewCaseIndiv.Id;
                newCaseIndivRoleList.add(newCaseIndivRoleRecord);
            }
        }
        
        if(!prevprmryCrtkrUpdMap.isEmpty()){
            for(T_SBSD_CASE_INDIV_ROLE__c oldCaseIndivRole: [select Id, IDN_CASE_INDIV__c,ignoreEndDateValidation__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c FROM T_SBSD_CASE_INDIV_ROLE__c WHERE IDN_CASE_INDIV__c IN:prevprmryCrtkrUpdMap.keySet() AND DTE_END_EFFV__c = NULL]){
                oldCaseIndivRole.DTE_END_EFFV__c = date.today() - 1;
                oldCaseIndivRole.ignoreEndDateValidation__c = true;
                oldCaseIndivRoleMap.put(oldCaseIndivRole.Id, oldCaseIndivRole);
            }
        }
        
        if(!newCaseIndivRoleList.isEmpty()){
            system.debug('The case Individual Role List  - '+newCaseIndivRoleList);
            GenericDMLHandler.insertRecords(newCaseIndivRoleList,methodInfo); 
        }
        system.debug('previous primary careTaker update'+prevprmryCrtkrUpdMap);
        if(!prevprmryCrtkrUpdMap.isEmpty()){
            //update prevprmryCrtkrUpdMap.values();
            GenericDMLHandler.updateRecords(prevprmryCrtkrUpdMap.values(),methodInfo, new List<String>{'ind_crtkr__c'});
        }
        if(!updatedRelationLst.isEmpty()){
            GenericDMLHandler.updateRecords(updatedRelationLst,methodInfo); 
        }        
        if(!oldCaseIndivRoleMap.isEmpty()){
            //update oldCaseIndivRoleMap.values();
            GenericDMLHandler.updateRecords(oldCaseIndivRoleMap.values(),methodInfo);
        }
    }
    
    /**
* @description updates Primary caretaker flag on Individual
* @author Bharadwaj Gaddam
* @date 22/12/2017 
* @param List<T_SBSD_CASE_INDIV__c> trigger.new Case Individual list
* @return void
*/    
    public static void updatePrimarcaretakeronIndividual(List<T_SBSD_CASE_INDIV__c> caseIndividualList) {
        Map<Id,T_SBSD_INDIV__c> updateIndvidualMap = new Map<Id,T_SBSD_INDIV__c>();
        set<Id> individualSet = new set<Id>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'updatePrimarcaretakeronIndividual'};
            for(T_SBSD_CASE_INDIV__c caseIndivEach:caseIndividualList) {
                if(caseIndivEach.IDN_CLIENT__c!=null) {
                    individualSet.add(caseIndivEach.IDN_CLIENT__c);
                }
            }
        try {
            for(T_SBSD_INDIV__c individual:[select Id,Is_Primary_Parent_Caretaker__c,(SELECT Id FROM Case_Individual__r WHERE IND_CRTKR__c = true) from T_SBSD_INDIV__c where Id IN:individualSet]) {
                if(individual.Case_Individual__r.size()>0) {
                    if(!individual.Is_Primary_Parent_Caretaker__c) {
                        individual.Is_Primary_Parent_Caretaker__c=true;
                        updateIndvidualMap.put(individual.Id,individual);
                    }
                } 
                else if(individual.Is_Primary_Parent_Caretaker__c) {
                    individual.Is_Primary_Parent_Caretaker__c=false;
                    updateIndvidualMap.put(individual.Id,individual);
                }
            }
            
            if(!updateIndvidualMap.isEmpty()) {
                //update updateIndvidualMap.values();
                GenericDMLHandler.updateRecords(updateIndvidualMap.values(),methodInfo);
            }
        } catch(Exception e) {
            system.debug(e);
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
        }
        
    }
    
    
    /**    
* @description Insert Record in ATS Object
* @author Vineet Srivastava
* @date 4/12/2018   
* @param List<T_SBSD_CASE_INDIV__c> trigger.new CaseIndividual list,
* @return void
*/  
    public static void insertATSRecord(List<T_SBSD_CASE_INDIV__c> newCaseIndivList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        Set<Id> setCaseId = new Set<Id>();
        Set<Id> setIndividualId = new Set<Id>();
        Map<Id, String>mapCaseIdToName= new Map<Id, String>();
        Map<Id, String>mapIndividualIdToName= new Map<Id, String>();
        for(T_SBSD_CASE_INDIV__c caseIndivRec:newCaseIndivList) {
            setCaseId.add(caseIndivRec.IDN_CASE__c);
            setIndividualId.add(caseIndivRec.IDN_CLIENT__c);
        }
        System.debug('before setIndividualId:'+setIndividualId);
        for(Junk_Record__c junkRec:[SELECT Id, Record_ID_To_Be_Deleted__c FROM Junk_Record__c WHERE Record_ID_To_Be_Deleted__c IN:setIndividualId]){
            System.debug('Removing:'+junkRec.Record_ID_To_Be_Deleted__c+' from the set');
            setIndividualId.remove(junkRec.Record_ID_To_Be_Deleted__c);
        }
        System.debug('after setIndividualId:'+setIndividualId);
        for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT IDN_CASE__c, IDN_CASE__r.Name, IDN_CLIENT__c, IDN_CLIENT__r.Name FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c IN :setCaseId AND IDN_CLIENT__c IN:setIndividualId]){
            mapCaseIdtoName.put(caseIndiv.IDN_CASE__c,caseIndiv.IDN_CASE__r.Name);
            mapIndividualIdToName.put(caseIndiv.IDN_CLIENT__c,caseIndiv.IDN_CLIENT__r.Name);
        }
        for(T_SBSD_CASE_INDIV__c caseIndivRec:newCaseIndivList) {
            if(setIndividualId.contains(caseIndivRec.IDN_CLIENT__c)){
                System.debug('Creating ATS record for:'+caseIndivRec.IDN_CLIENT__c);
                batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
                atsRecord.CDE_STATUS_TRANS__c= '1';
                atsRecord.CDE_TYPE_TRANS__c ='2';
                if(mapIndividualIdToName.containsKey(caseIndivRec.IDN_CLIENT__c)){
                    atsRecord.IDN_CLIENT__c = mapIndividualIdToName.get(caseIndivRec.IDN_CLIENT__c);
                }
                atsRecord.DTE_CHANGE_LAST__c = system.today();
                lstATSRecords.add(atsRecord);
                
                batchsit_t_pos_trans_queue_ats__x atsRecord2 = new batchsit_t_pos_trans_queue_ats__x();
                atsRecord2.CDE_STATUS_TRANS__c= '1';
                atsRecord2.CDE_TYPE_TRANS__c ='3';
                if(mapIndividualIdToName.containsKey(caseIndivRec.IDN_CLIENT__c)){
                    atsRecord2.IDN_CLIENT__c = mapIndividualIdToName.get(caseIndivRec.IDN_CLIENT__c);
                }
                if(mapCaseIdToName.containsKey(caseIndivRec.IDN_CASE__c)){
                    atsRecord2.IDN_CASE__c = mapCaseIdToName.get(caseIndivRec.IDN_CASE__c);
                }
                atsRecord2.DTE_CHANGE_LAST__c = System.today();
                lstATSRecords.add(atsRecord2);
            }
        }
        ATSHandler.insertATSRecordForCaseIndividualAndIndividual(true, lstATSRecords);
    }
    
    public static void doUpdateRecentChildCareRequest(List<T_SBSD_CASE_INDIV__c> newCaseIndviduals, Map<Id, T_SBSD_CASE_INDIV__c> oldMapCaseIndividual){
        List<T_INDIV_CAT_RQ__c> childCareRequestsToBeUpdated = new List<T_INDIV_CAT_RQ__c>();
        Map<Id,T_SBSD_CASE_INDIV__c> ccrIdToCaseIndividualMap = new Map<Id,T_SBSD_CASE_INDIV__c>();
        for(T_SBSD_CASE_INDIV__c newCaseIndividual:[SELECT Id,DTE_END_EFFV__c, (SELECT Id FROM Child_Care_Requests__r WHERE DTE_END_EFFV__c = null ORDER BY DTE_BEGIN_EFFV__c DESC LIMIT 1) FROM T_SBSD_CASE_INDIV__c WHERE Id IN:newCaseIndviduals]){
            if(newCaseIndividual.DTE_END_EFFV__c!=oldMapCaseIndividual.get(newCaseIndividual.Id).DTE_END_EFFV__c  &&  !newCaseIndividual.Child_Care_Requests__r.isEmpty()){
                childCareRequestsToBeUpdated.add(new T_INDIV_CAT_RQ__c(
                    Id = newCaseIndividual.Child_Care_Requests__r.get(0).Id,
                    CDE_CHANGE_RQ_CAT__c = 'MH',
                    DTE_END_EFFV__c = newCaseIndividual.DTE_END_EFFV__c
                ));
                ccrIdToCaseIndividualMap.put(newCaseIndividual.Child_Care_Requests__r.get(0).Id, newCaseIndividual);
            }    
        }
        updateChildCareRequests(childCareRequestsToBeUpdated, ccrIdToCaseIndividualMap);
    }
    
    public static void updateChildCareRequests(List<T_INDIV_CAT_RQ__c> childCareRequestsToBeUpdated, Map<Id,T_SBSD_CASE_INDIV__c> ccrIdToCaseIndividualMap){
        List<Database.SaveResult> updateSaveResults = Database.update(childCareRequestsToBeUpdated, false); 
        
        for(Integer i=0;i<updateSaveResults.size();i++){
            Database.SaveResult updateSaveResult = updateSaveResults[i];
            if(!updateSaveResult.isSuccess()){
                List<Database.Error> lstError = updateSaveResult.getErrors();
                String failedDML = '';
                for(Database.Error error : lstError){
                    failedDML = failedDML + '\n' + error.getMessage();
                }
                if(ccrIdToCaseIndividualMap.containsKey(childCareRequestsToBeUpdated[i].Id)){
                    //ccrIdToCaseIndividualMap.get(childCareRequestsToBeUpdated[i].Id).addError('Error while updating the recent child care request record:'+failedDML);
                    throw new DmlException('Error while updating the recent child care request record:' + failedDML);
                }
            }
        }
    }
    
    /**    
* @description Update PrimaryCareTaker on Case 
* @author Bharadwaj Gaddam
* @date 6/14/2018   
* @param List<T_SBSD_CASE_INDIV__c> trigger.new CaseIndividual list,
* @return void
*/      
    public static void upadatePrimaryCareTakeronCase(List<T_SBSD_CASE_INDIV__c> caseIndivList) {
        Date nullDate;
        Map<Id, T_SBSD_CASE__c> caseMap = new Map<Id, T_SBSD_CASE__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'upadatePrimaryCareTakeronCase'};
            for(T_SBSD_CASE_INDIV__c caseIndiEach:caseIndivList ) {
                if(caseIndiEach.DTE_END_EFFV__c==nullDate && caseIndiEach.IND_CRTKR__c && caseIndiEach.IDN_CASE__c!=null && caseIndiEach.NAM_INDIV__c!=null) {
                    caseMap.put(caseIndiEach.IDN_CASE__c,new T_SBSD_CASE__c(Id=caseIndiEach.IDN_CASE__c,NAM_PRIMARY_CARETAKER__c=caseIndiEach.NAM_INDIV__c));                
                }
                
            }
        
        if(!caseMap.isEmpty()) {
            GenericDMLHandler.updateRecords(caseMap.values(),methodInfo);
        }
    }
    
    /**    
* @description End dating Case Individual Role record 
* @author Shubham Jain
* @date 11/14/2018   
* @param List<T_SBSD_CASE_INDIV__c> trigger.new CaseIndividual list,Map<Id,T_SBSD_CASE__c> trigger.oldMap oldCaseIndivMap
* @return void
*/
    public static void updateEndDateOnCaseIndivRole(List<T_SBSD_CASE_INDIV__c> caseIndivList,Map<Id,T_SBSD_CASE_INDIV__c> oldCaseIndivMap){
        Set<String> updatedCaseIndivIds= new Set<String>();
        for(T_SBSD_CASE_INDIV__c newCaseIndivRecord:caseIndivList){
            if(oldCaseIndivMap.containskey(newCaseIndivRecord.Id) && (!newCaseIndivRecord.IND_CRTKR__c && oldCaseIndivMap.get(newCaseIndivRecord.Id).IND_CRTKR__c ||newCaseIndivRecord.DTE_END_EFFV__c!=null )){   //CCCAP-15656 to update end date in role record when PC is end dated
                updatedCaseIndivIds.add(newCaseIndivRecord.Id);
            }
        }
        if(!updatedCaseIndivIds.isEmpty()){
            List<T_SBSD_CASE_INDIV_ROLE__c> listOfCaseIndivRoleRecords=[SELECT ID,DTE_END_EFFV__c,IDN_CASE_INDIV__r.DTE_END_EFFV__c FROM T_SBSD_CASE_INDIV_ROLE__C WHERE DTE_END_EFFV__c=null AND IDN_CASE_INDIV__c IN:updatedCaseIndivIds];  //CCCAP-15656
            for(T_SBSD_CASE_INDIV_ROLE__c caseIndivRole:listOfCaseIndivRoleRecords){
                caseIndivRole.DTE_END_EFFV__c=caseIndivRole.IDN_CASE_INDIV__r.DTE_END_EFFV__c!=null?caseIndivRole.IDN_CASE_INDIV__r.DTE_END_EFFV__c:System.today();  //CCCAP-15656
            }
            if(!listOfCaseIndivRoleRecords.isEmpty()){
                GenericDMLHandler.updateRecords(listOfCaseIndivRoleRecords, new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'updateEndDateOnCaseIndivRole'});
            }
        }
    }
    //Added for Hotfix CCCAP-3305
    public static void updateIndividualEmailInCaseInfo(Map<Id, T_SBSD_CASE_INDIV__c> triggerNewMap,Map<Id, T_SBSD_CASE_INDIV__c> triggerOldMap)
    {   
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'updateIndividualEmailInCaseInfo'};
            Set<Id> indivIds = new Set<Id>();
        List<String> caseIdList = new List<String>();
        List<T_SBSD_CASE_INFO__c> caseToinsert = new List<T_SBSD_CASE_INFO__c>();
        List<T_SBSD_CASE_INFO__c> caseToupdate = new List<T_SBSD_CASE_INFO__c>();
        for(T_SBSD_CASE_INDIV__c caseindivRecord : triggerNewMap.values()){ 
            if(caseindivRecord.IND_CRTKR__c == true && caseindivRecord.IND_CRTKR__c !=triggerOldMap.get(caseindivRecord.Id).IND_CRTKR__c){
                indivIds.add(caseindivRecord.IDN_CLIENT__c);
                caseIdList.add(caseindivRecord.IDN_CASE__c); 
            }  
        }
        if(!indivIds.isEmpty() && !caseIdList.isEmpty()){
            List<Individual_E_mail__c>ielist=[Select Id,Effective_End_Date__c,Effective_Begin_Date__c,Email_Information__c,Individual__c from Individual_E_mail__c where Individual__c IN: indivIds AND (Effective_End_Date__c=Null OR Effective_End_Date__c >= TODAY) AND Effective_Begin_Date__c<= TODAY order by Effective_Begin_Date__c DESC ];
            List<T_SBSD_CASE__c> caserecords = [SELECT Id,(Select Id, CDE_TYPE_INFO_CASE__c FROM T_SBSD_CASE13__r WHERE CDE_TYPE_INFO_CASE__c='EM')  
                                                FROM T_SBSD_CASE__c WHERE Id IN :caseIdList];
            for(T_SBSD_CASE__c caserec:caserecords){
                
                if(!caserec.T_SBSD_CASE13__r.isEmpty() && !ielist.isEmpty())
                {
                    T_SBSD_CASE_INFO__c caseinforecone=caserec.T_SBSD_CASE13__r[0];
                    caseinforecone.TXT_VALUE_INFO_CASE__c=ielist[0].Email_Information__c;
                    caseToupdate.add(caseinforecone);
                }
                else if(caserec.T_SBSD_CASE13__r.isEmpty() && !ielist.isEmpty())
                {
                    T_SBSD_CASE_INFO__c caseinforec=new T_SBSD_CASE_INFO__c ();
                    caseinforec.IDN_CASE__c=caserec.Id;
                    caseinforec.CDE_TYPE_INFO_CASE__c='EM';
                    caseinforec.TXT_VALUE_INFO_CASE__c=ielist[0].Email_Information__c;
                    caseToinsert.add(caseinforec);
                    
                }
            }
        }
        if(!caseToinsert.isEmpty()){
            GenericDMLHandler.insertRecords(caseToinsert, new Map<String,Object>{'Method__c'=>'updateIndividualEmailInCaseInfo','Class__c'=>'caseIndividualServices'});
        }
        if(!caseToupdate.isEmpty()){
            GenericDMLHandler.updateRecords(caseToupdate, new Map<String,Object>{'Method__c'=>'updateIndividualEmailInCaseInfo','Class__c'=>'caseIndividualServices'});
        }
    }    
    //  
    public static void updateEndDateForRelationships(List<T_SBSD_CASE_INDIV__c> caseIndivList){
        
        Set<Id> indivPrimaryIdSet = new Set<Id>();
        Set<Id> indivNonPrimaryIdSet = new Set<Id>();
        
        for(T_SBSD_CASE_INDIV__c caseIdivRec: caseIndivList){
            if(caseIdivRec.IND_CRTKR__c == true && caseIdivRec.DTE_END_EFFV__c != null && caseIdivRec.IDN_CLIENT__c != null){
                indivPrimaryIdSet.add(caseIdivRec.IDN_CLIENT__c); 
            }else if(caseIdivRec.IND_CRTKR__c == false && caseIdivRec.DTE_END_EFFV__c != null && caseIdivRec.IDN_CLIENT__c != null){
                indivNonPrimaryIdSet.add(caseIdivRec.IDN_CLIENT__c);
            }
        }
        Map<Id,List<T_INDIV_REL__c>> indivPrimaryRelationshipMap = new Map<Id,List<T_INDIV_REL__c>>();
        Map<Id,List<T_INDIV_REL__c>> indivNonPrimaryRelationshipMap = new Map<Id,List<T_INDIV_REL__c>>();
        if(!indivPrimaryIdSet.isEmpty()){
            for(T_INDIV_REL__c relationRec: [Select Id,IDN_CLIENT__c, DTE_END_EFFV__c From T_INDIV_REL__c Where IDN_CLIENT__c IN :indivPrimaryIdSet]){
                if(indivPrimaryRelationshipMap.containsKey(relationRec.IDN_CLIENT__c)){
                    List<T_INDIV_REL__c> relationLst1 = indivPrimaryRelationshipMap.get(relationRec.IDN_CLIENT__c);
                    relationLst1.add(relationRec);
                    indivPrimaryRelationshipMap.put(relationRec.IDN_CLIENT__c, relationLst1);  
                }else{
                    List<T_INDIV_REL__c> relationLst2 = new List<T_INDIV_REL__c>();
                    relationLst2.add(relationRec);
                    indivPrimaryRelationshipMap.put(relationRec.IDN_CLIENT__c, relationLst2);   
                }
            }            
        }

        if(!indivNonPrimaryIdSet.isEmpty()){
            for(T_INDIV_REL__c relationRec: [Select Id,IDN_CLIENT_RELTD__c,DTE_END_EFFV__c From T_INDIV_REL__c Where IDN_CLIENT_RELTD__c IN :indivNonPrimaryIdSet]){
                if(indivNonPrimaryRelationshipMap.containsKey(relationRec.IDN_CLIENT_RELTD__c)){
                    List<T_INDIV_REL__c> relationLst1 = indivNonPrimaryRelationshipMap.get(relationRec.IDN_CLIENT_RELTD__c);
                    relationLst1.add(relationRec);
                    indivNonPrimaryRelationshipMap.put(relationRec.IDN_CLIENT_RELTD__c, relationLst1);  
                }else{
                    List<T_INDIV_REL__c> relationLst2 = new List<T_INDIV_REL__c>();
                    relationLst2.add(relationRec);
                    indivNonPrimaryRelationshipMap.put(relationRec.IDN_CLIENT_RELTD__c, relationLst2);   
                }
            }    
        }
        List<T_INDIV_REL__c> updatedPrimaryRelationLst = new List<T_INDIV_REL__c>();
        if(indivPrimaryRelationshipMap.size()>0){
            for(T_SBSD_CASE_INDIV__c cseIdivRec: caseIndivList){
                for(T_INDIV_REL__c relRec : indivPrimaryRelationshipMap.get(cseIdivRec.IDN_CLIENT__c)){
                    if(relRec.DTE_END_EFFV__c == null){
                        relRec.DTE_END_EFFV__c = cseIdivRec.DTE_END_EFFV__c; 
                        updatedPrimaryRelationLst.add(relRec);
                    }else if(relRec.DTE_END_EFFV__c != null && cseIdivRec.DTE_END_EFFV__c < relRec.DTE_END_EFFV__c){
                        relRec.DTE_END_EFFV__c = cseIdivRec.DTE_END_EFFV__c; 
                        updatedPrimaryRelationLst.add(relRec);
                    }
                }
            }  
        }
        
        
        List<T_INDIV_REL__c> updatedNonPrimaryRelationLst = new List<T_INDIV_REL__c>();
        if(indivNonPrimaryRelationshipMap.size()>0){
            for(T_SBSD_CASE_INDIV__c cseIdivRec: caseIndivList){
                for(T_INDIV_REL__c relRec : indivNonPrimaryRelationshipMap.get(cseIdivRec.IDN_CLIENT__c)){
                    if(relRec.DTE_END_EFFV__c == null){
                        relRec.DTE_END_EFFV__c = cseIdivRec.DTE_END_EFFV__c; 
                        updatedNonPrimaryRelationLst.add(relRec);
                    }else if(relRec.DTE_END_EFFV__c != null && cseIdivRec.DTE_END_EFFV__c < relRec.DTE_END_EFFV__c){
                        relRec.DTE_END_EFFV__c = cseIdivRec.DTE_END_EFFV__c; 
                        updatedNonPrimaryRelationLst.add(relRec);
                    }
                }
            }
        }
        
        if(!updatedPrimaryRelationLst.isEmpty()){
            GenericDMLHandler.updateRecords(updatedPrimaryRelationLst, new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'updateEndDateForRelationships'});
        }else if(!updatedNonPrimaryRelationLst.isEmpty()){
            GenericDMLHandler.updateRecords(updatedNonPrimaryRelationLst, new Map<String,Object>{'Class__c'=>'caseIndividualServices','Method__c'=>'updateEndDateForRelationships'});
        }
    }
    //added for UFE-RAPID by Shashank
    public static void handleCaseIndivUpdatesforUFE(List<T_SBSD_CASE_INDIV__c> caseIndivList,Map<Id,T_SBSD_CASE_INDIV__c>oldMap){
        List<T_SBSD_CASE_INDIV__c> checkList 		= Trigger.isDelete ?oldMap.values() : caseIndivList;
        Map<String, String> indivEmailMap 			= new Map<String, String>();
        Set<Id> isUFEClient							= new Set<Id>();
        Map<String,Id> mailVsUFeMap		  			= new Map<String,Id>();
        Map<String,Id> mailVsAppCaseMap		  			= new Map<String,Id>();        
        Map<Id,T_SBSD_INDIV__c> indivsToUpdate 		= new Map<Id,T_SBSD_INDIV__c>();
        Map<Id,UFEChangeInterface__e> ufeUpdateMap 	= new Map<Id,UFEChangeInterface__e>();
        Map<Id,T_UFE_INDIV_EML__c> UFEEmailToDel 	= new Map<Id,T_UFE_INDIV_EML__c>();
        
        for(T_SBSD_INDIV__c indiv:[select Id,UFE_Request_Flag__c,
                                   (SELECT Email_Information__c FROM Individual_E_mails__r where Effective_End_Date__c = NUll OR Effective_End_Date__c>=TODAY order by Effective_Begin_Date__c DESC limit 1)
                                   from T_SBSD_INDIV__c where ID IN (select IDN_Client__c from T_SBSD_CASE_INDIV__c 
                                                                     where Id IN:checkList)])
        {
            if(indiv.Individual_E_mails__r!=null && !indiv.Individual_E_mails__r.isEmpty()){
                indivEmailMap.put(indiv.Id,indiv.Individual_E_mails__r[0].Email_Information__c.toLowerCase());
            }
            if(indiv.UFE_Request_Flag__c == true){
                isUFEClient.add(indiv.Id);
            }
        }
        if(!indivEmailMap.isEmpty()){
            for(T_UFE_INDIV_EML__c ufeEmail : [select id,UFE_Email__c from T_UFE_INDIV_EML__c where UFE_Email__c in:indivEmailMap.values()]){
                mailVsUFeMap.put(ufeEmail.UFE_Email__c.toLowerCase(),ufeEmail.Id);
            }
            for(T_APPLN_CASE__c appCase : [SELECT id,CDE_INFO_EM__c FROM T_APPLN_CASE__c 
                                           WHERE CDE_INFO_EM__c in :indivEmailMap.values() AND UFE_Request_Flag__c=true]){
                                               mailVsAppCaseMap.put(appCase.CDE_INFO_EM__c.toLowerCase(),appCase.Id);
                                           }
        }
        
        for(T_SBSD_CASE_INDIV__c caseIndiv : checkList){
            /* If Case Individual is getting created and Email of the Individual is Present in T_UFE_INDIV_EML__c then then,
				Set UFE Request flaf to true, Delete entry in T_UFE_INDIV_EML__c & publish the Platform Event and Inform Bridgecare.*/
            if(Trigger.isInsert){
                string currentEmail = indivEmailMap.get(caseIndiv.IDN_CLIENT__c)!=NULL?indivEmailMap.get(caseIndiv.IDN_CLIENT__c).toLowerCase():'';
                if(mailVsUFeMap.containsKey(currentEmail)){
                    Id ufeEmail_Id = mailVsUFeMap.get(currentEmail);
                    indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=true,Bypass_On__c=System.now())); //setting UFE_Request_Flag__c true on Individual
                    UFEEmailToDel.put(ufeEmail_Id,new T_UFE_INDIV_EML__c(Id=ufeEmail_Id)); //setting T_UFE_INDIV_EML__c record for deletion
                    ufeUpdateMap.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case')); // setting PE instance for publishing.
                }else if(mailVsAppCaseMap.containsKey(currentEmail)){
                    indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=true,Bypass_On__c=System.now()));
                    ufeUpdateMap.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case'));
                }
            }
            // If UFE Requested Case Individual is getting Inactive on Case then publish the Platform Event and Inform Bridgecare.
            else if(Trigger.isUpdate && isUFEClient.contains(caseIndiv.IDN_CLIENT__c) && 
                    caseIndiv.DTE_END_EFFV__c!=oldMap.get(caseIndiv.Id).DTE_END_EFFV__c && caseIndiv.DTE_END_EFFV__c<Date.today())
            {
                ufeUpdateMap.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case')); // setting PE instance for publishing.
            }
            // IF UFE Requested Case Individual is getting deleted then publish the Platform Event and Inform Bridgecare.
            else if(Trigger.isDelete && isUFEClient.contains(caseIndiv.IDN_CLIENT__c)){
                ufeUpdateMap.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case'));// setting PE instance for publishing.
            }
        }
        if(!indivsToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(indivsToUpdate.values(), new Map<String,Object>{'Method__c'=>'handleCaseIndivUpdatesforUFE','Class__c'=>'caseIndividualServices'});
        }
        if(!UFEEmailToDel.isEmpty()){
            delete UFEEmailToDel.values();
        }
        Eventbus.publish(ufeUpdateMap.values());
    }

    //added for CCCAP-13633
    public static void updateIndivDetailsForAdults(List<T_SBSD_CASE_INDIV__c> caseIndivList, Map<Id,T_SBSD_CASE_INDIV__c> oldMap){
        List<T_SBSD_INDIV__c> indivToUpdate = new List<T_SBSD_INDIV__c>();
        Set<Id> indivIds = new Set<Id>();
        List<T_SBSD_INDIV_INFO__c> caseInfoToUpdate = new List<T_SBSD_INDIV_INFO__c>();
        List<T_INDIV_VERIF__c> indivVerifToDelete = new List<T_INDIV_VERIF__c>();
        List<String> indivFieldsToUpdate = new List<String>{'CDE_GENDER__c','CDE_ATTENDING_SCHOOL1__c','IND_CHILD_IDEA__c','IND_CHILD_SCREEN__c','CDE_RACE__c','CDE_ETNCTY__c','IND_CDE_TYPE_VERIF_DOB__c','CDE_SOURCE_VRFYD_DOB__c','CDE_SOURCE_VRFYD_CITIZEN__c'};

        for(T_SBSD_CASE_INDIV__c caseIndiv : caseIndivList){
            if((Trigger.isInsert || (Trigger.isUpdate && caseIndiv.Individual_Status__c != oldMap.get(caseIndiv.Id).Individual_Status__c))  && (caseIndiv.Individual_Status__c == 'PC' || caseIndiv.Individual_Status__c == 'AC')){
                indivIds.add(caseIndiv.IDN_CLIENT__c);
            }            
        }
        for(T_SBSD_INDIV_INFO__c indivInfo : [SELECT Id,IDN_CLIENT__c, (SELECT Id FROM Individual_Verification__r WHERE CDE_TYPE_INFO_INDIV__c = 'CS') 
                                                FROM T_SBSD_INDIV_INFO__c WHERE IDN_CLIENT__c IN :indivIds AND CDE_TYPE_INFO_INDIV__c = 'CS' AND IDN_CASE__c != null]){
            indivInfo.CDE_VALUE_INFO_INDIV__c = 'N/A-adult caretaker';
            caseInfoToUpdate.add(indivInfo);
            if(indivInfo.Individual_Verification__r.size()>0){
                for(T_INDIV_VERIF__c indivVerif : indivInfo.Individual_Verification__r){
                    indivVerifToDelete.add(indivVerif);
                }
            }
        }
        if(!indivVerifToDelete.isEmpty()){
            GenericDMLHandler.deleteRecords(indivVerifToDelete, new Map<String,Object>{'Method__c'=>'updateIndivDetailsForAdults','Class__c'=>'caseIndividualServices'});
        }
        if(!caseInfoToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(caseInfoToUpdate, new Map<String,Object>{'Method__c'=>'updateIndivDetailsForAdults','Class__c'=>'caseIndividualServices'}, new List<String>{'CDE_VALUE_INFO_INDIV__c'});
        }
        
        Map<Id, T_SBSD_INDIV__c> indivMap = new Map<Id, T_SBSD_INDIV__c> ([SELECT Id, CDE_GENDER__c,CDE_ATTENDING_SCHOOL1__c, IND_CHILD_IDEA__c, IND_CHILD_SCREEN__c, CDE_RACE__c, CDE_ETNCTY__c,
                                        IND_CDE_TYPE_VERIF_DOB__c, CDE_SOURCE_VRFYD_DOB__c, CDE_SOURCE_VRFYD_CITIZEN__c  FROM T_SBSD_INDIV__c WHERE Id IN :indivIds]);
        for(T_SBSD_CASE_INDIV__c caseIndiv : caseIndivList){
            if(indivMap.containsKey(caseIndiv.IDN_CLIENT__c)) 
            {
                T_SBSD_INDIV__c indiv = indivMap.get(caseIndiv.IDN_CLIENT__c);
                indiv.CDE_GENDER__c = (indiv.CDE_GENDER__c != '3') ? '3' : indiv.CDE_GENDER__c;
                indiv.CDE_ATTENDING_SCHOOL1__c = (indiv.CDE_ATTENDING_SCHOOL1__c != 'Unknown') ? 'Unknown' : indiv.CDE_ATTENDING_SCHOOL1__c;
                indiv.IND_CHILD_IDEA__c = (indiv.IND_CHILD_IDEA__c != 'N') ? 'N' : indiv.IND_CHILD_IDEA__c;
                indiv.IND_CHILD_SCREEN__c = (indiv.IND_CHILD_SCREEN__c != 'N') ? 'N' : indiv.IND_CHILD_SCREEN__c;
                indiv.CDE_RACE__c = (indiv.CDE_RACE__c != '6') ? '6' : indiv.CDE_RACE__c; 
                indiv.CDE_ETNCTY__c = (indiv.CDE_ETNCTY__c != 'U') ? 'U' : indiv.CDE_ETNCTY__c;
                indiv.IND_CDE_TYPE_VERIF_DOB__c = (indiv.IND_CDE_TYPE_VERIF_DOB__c != 'N/A-adult caretaker') ? 'N/A-adult caretaker' : indiv.IND_CDE_TYPE_VERIF_DOB__c;
                indiv.CDE_SOURCE_VRFYD_DOB__c = (indiv.CDE_SOURCE_VRFYD_DOB__c != '' || indiv.CDE_SOURCE_VRFYD_DOB__c != null) ? '' : indiv.CDE_SOURCE_VRFYD_DOB__c;
                indiv.CDE_SOURCE_VRFYD_CITIZEN__c = (indiv.CDE_SOURCE_VRFYD_CITIZEN__c != '' || indiv.CDE_SOURCE_VRFYD_CITIZEN__c != null) ? '' : indiv.CDE_SOURCE_VRFYD_CITIZEN__c; 
                /* CCCAP-14243 - Setting the bypass field to skip individual validations. 
                For new individuals, all validations are already handled at creation, ensuring only accurate data is being created.
                For existing individuals with legacy data, allowing update of case individual status without being blocked by validations.*/
                indiv.Bypass_On__c = System.now();
                indivToUpdate.add(indiv);
            }
        }        
        if(!indivToUpdate.isEmpty()){
            IndividualServices.disableTrigger = true;
            GenericDMLHandler.updateRecords(indivToUpdate, new Map<String,Object>{'Method__c'=>'updateIndivDetailsForAdults','Class__c'=>'caseIndividualServices'}, indivFieldsToUpdate);
            IndividualServices.disableTrigger = false;
        }
    }

    //added for CCCAP-13633
    public static void updatePrimCrtkrOnIndivStatusUpdate(List<T_SBSD_CASE_INDIV__c> caseIndivList, Map<Id,T_SBSD_CASE_INDIV__c> oldCaseIndivMap){
        List<T_SBSD_CASE_INDIV__c> caseIndivsToUpdate = new List<T_SBSD_CASE_INDIV__c>();
        Set<Id> caseIndivIDs = new Set<Id>();
        for(T_SBSD_CASE_INDIV__c caseIndiv: caseIndivList){
            caseIndivIDs.add(caseIndiv.Id);
        }
        for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id, Individual_Status__c, IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c WHERE Id IN :caseIndivIDs]){
            if(Trigger.isInsert || (oldCaseIndivMap != null && oldCaseIndivMap.containsKey(caseIndiv.Id) && 
               caseIndiv.Individual_Status__c != oldCaseIndivMap.get(caseIndiv.Id).Individual_Status__c)){
                if(caseIndiv.Individual_Status__c == 'PC' && caseIndiv.IND_CRTKR__c != true){
                    caseIndiv.IND_CRTKR__c = true;
                    caseIndivsToUpdate.add(caseIndiv);            
                }
                if(caseIndiv.Individual_Status__c != 'PC' && caseIndiv.IND_CRTKR__c == true){
                    caseIndiv.IND_CRTKR__c = false;
                    caseIndivsToUpdate.add(caseIndiv);
                }
            }
        }
        if(!caseIndivsToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(caseIndivsToUpdate, new Map<String,Object>{'Method__c'=>'updatePrimCrtkrOnIndivStatusUpdate','Class__c'=>'caseIndividualServices'}, new List<String> {'IND_CRTKR__c'});
        }
    }
}