/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/24/2022                                                         
*  @description    Adjustment batch class for datafix                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 24-Jan-2024                                                            
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class CitizenshipDatafixBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Set<Id> caseIds = new Set<Id>();
    public Set<String> providerCountySet = new Set<String>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    public List<batchsit_t_sbsd_case_cmt__x> caseCommentList = new List<batchsit_t_sbsd_case_cmt__x>();
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        List<String> clientIds = new List<String>();
        clientIds = system.Label.CitizenshipIndivIds.split(';');
        String status ='CS';
        String queryStr ;
        if(Test.isRunningTest()){
            queryStr ='select id,createdDate,IDN_CASE__c,IDN_CLIENT__r.name,IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c,IDN_CLIENT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,CDE_TYPE_INFO_INDIV__c,CDE_VALUE_INFO_INDIV__c from T_SBSD_INDIV_INFO__c where CDE_TYPE_INFO_INDIV__c=:status';
            
        }else{
            queryStr ='select id,createdDate,IDN_CASE__c,IDN_CLIENT__r.name,IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c,IDN_CLIENT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,CDE_TYPE_INFO_INDIV__c,CDE_VALUE_INFO_INDIV__c from T_SBSD_INDIV_INFO__c where CDE_TYPE_INFO_INDIV__c=:status and IDN_CLIENT__r.name=:clientIds and IDN_CASE__c!= null';
            
        }        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_SBSD_INDIV_INFO__c> indivInfoList){
        try{
            Map<String,T_SBSD_INDIV_INFO__c> indivInfoMap = new Map<String,T_SBSD_INDIV_INFO__c>();
            Map<String,List<String>> indivCaseMap = new Map<String,List<String>>();
            Set<String> indivIds = new Set<String>();
            Map<String,String> caseMap= new Map<String,String>();
            Map<String,String> caseExternalIdMap= new Map<String,String>();
            List<T_SBSD_INDIV_INFO__c> indivInfoToBeInserted= new List<T_SBSD_INDIV_INFO__c>();
            List<T_INDIV_VERIF__c> indivInfoVerifToBeInserted= new List<T_INDIV_VERIF__c>();
            Map<string,T_INDIV_VERIF__c> indivInfoVerif = new Map<string,T_INDIV_VERIF__c>();
            List<T_SBSD_INDIV_INFO__c> indivInfoToBeDatafixed= new List<T_SBSD_INDIV_INFO__c>();
            Set<String> infoInfoIds = new Set<String>();
            for(T_SBSD_INDIV_INFO__c indivInfo :indivInfoList){
                indivIds.add(indivInfo.IDN_CLIENT__c);
                indivInfoMap.put(indivInfo.IDN_CLIENT__c,indivInfo);
                
            }
            system.debug('indivIds--'+indivIds);
            system.debug('indivInfoMap--'+indivInfoMap);
            
            for(T_SBSD_CASE_INDIV__c caseIndiv :[Select id,IDN_CASE__c,IDN_CASE__r.name,IDN_CASE__r.IDN_EXTNL__c,IDN_CLIENT__c from T_SBSD_CASE_INDIV__c where IDN_CLIENT__c in :indivIds ]){
               caseMap.put(caseIndiv.IDN_CASE__c,caseIndiv.IDN_CASE__r.name);
                caseExternalIdMap.put(caseIndiv.IDN_CASE__c,caseIndiv.IDN_CASE__r.IDN_EXTNL__c);
                if(indivCaseMap.containskey(caseIndiv.IDN_CLIENT__c)){
                    List<String> caseids = indivCaseMap.get(caseIndiv.IDN_CLIENT__c);
                    caseids.add(caseIndiv.IDN_CASE__c);
                    indivCaseMap.put(caseIndiv.IDN_CLIENT__c,caseids);
                }else{
                    indivCaseMap.put(caseIndiv.IDN_CLIENT__c,new List<String>{caseIndiv.IDN_CASE__c});
                }
                
            }
            system.debug('indivCaseMap--'+indivCaseMap);
            for(String indiv:indivCaseMap.keySet()){
                for(String caseId:indivCaseMap.get(indiv)){
                    if(indivInfoMap.get(indiv) != null){
                        T_SBSD_INDIV_INFO__c indivInfo = indivInfoMap.get(indiv);
                        if(indivInfo.IDN_CASE__c !=caseId){
                            T_SBSD_INDIV_INFO__c indivInfoCloneCopy  = indivInfo.clone(false, false, false, false);
                            indivInfoCloneCopy.Parent_Record__c =indivInfo.Id;
                            indivInfoCloneCopy.IDN_CASE__c =caseId;
                            caseIds.add(caseId);
                            indivInfoToBeInserted.add(indivInfoCloneCopy);
                            batchsit_t_sbsd_case_cmt__x cmtObj = new batchsit_t_sbsd_case_cmt__x();
                            cmtObj.createdbyid__c =UserInfo.getUserId();
                            cmtObj.cde_type_cmt__c='System-Generated';
                            cmtObj.cde_type_note_cmt__c ='General';
                            cmtObj.createddate__c = System.now();
                            cmtObj.idn_case__c=caseExternalIdMap.get(caseId);
                            cmtObj.lastmodifiedbyid__c=UserInfo.getUserId();
                            cmtObj.lastmodifieddate__c= System.now();
                            cmtObj.txt_cmt__c='A data fix was performed on this case and individual '+ caseMap.get(caseId) +' AND '+ indivInfo.IDN_CLIENT__r.name+' on 02/01/2024 to properly associate the case and county with their Citizenship Verification Record. As needed, view the history record associated with Individual Information Record '+'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_INDIV_INFO__c/'+indivInfo.Id +'/view )'+' to view all of the citizenship verification associated with this individual.';
                            cmtObj.txt_subj__c='Citizenship Datafix';
                           // cmtObj.nbr_seq_hist__c=0;
                            caseCommentList.add(cmtObj);
                        }
                        
                    }
                    
                }
            }
            
            /*  for(T_SBSD_INDIV_INFO__c indivInfo :[select id,Parent_Record__c,createdDate,IDN_CASE__c,IDN_CLIENT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,CDE_TYPE_INFO_INDIV__c,CDE_VALUE_INFO_INDIV__c from T_SBSD_INDIV_INFO__c
where CDE_TYPE_INFO_INDIV__c='CS' and createdDate = today and createdById='0052M00000AqYDJQA3']){

infoInfoIds.add(indivInfo.id);
indivInfoToBeDatafixed.add(indivInfo);
}*/
            system.debug('indivInfoToBeInserted--'+indivInfoToBeInserted.size());
            system.debug('indivInfoToBeInserted--'+indivInfoToBeInserted);
            List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
            lstSaveResult.addAll(Database.insert(indivInfoToBeInserted, false));
            for(T_INDIV_VERIF__c verif :[Select id,CDE_TYPE_VERIF__c,IDN_CLIENT__c,CDE_TYPE_INFO_INDIV__c from T_INDIV_VERIF__c where IDN_CLIENT__c in:indivInfoList  ]){
                indivInfoVerif.put(verif.IDN_CLIENT__c,verif);
            }
            for(T_SBSD_INDIV_INFO__c indivInfo:indivInfoToBeInserted){
                system.debug('indivInfo---'+indivInfo);
                
                if(indivInfoVerif.get(indivInfo.Parent_Record__c) != null){
                    T_INDIV_VERIF__c indivInfoVerifObj = indivInfoVerif.get(indivInfo.Parent_Record__c);
                    T_INDIV_VERIF__c indivInfoCloneCopy  = indivInfoVerifObj.clone(false, false, false, false);
                    indivInfoCloneCopy.IDN_CLIENT__c =indivInfo.id;
                    indivInfoVerifToBeInserted.add(indivInfoCloneCopy);
                }
                
            }
            if(indivInfoVerifToBeInserted != null && indivInfoVerifToBeInserted.size()>0){
                database.insert(indivInfoVerifToBeInserted);
            }
            
        }
        catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'CitizenshipDatafixBatch';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'CitizenshipDatafixBatch  for citizenship'+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
    global void finish(Database.BatchableContext bc){
        
        if(caseCommentList!= null && caseCommentList.size()>0){
            system.debug('caseCommentList--'+caseCommentList);
            //GenericDataSaverApxCtrl.insertExternalObjRecords(caseCommentList, TRUE);
            Database.insertAsync(caseCommentList);
        }
        
    }   
}