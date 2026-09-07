/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/11/2017                                                          
*  @description    Handler class for Correspondence Request Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 23-Oct-2018                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version
*  * CHAT-7416 : updating the Language field with ENG or SPN based on client/ provider correspondence
*********************************************************************************************/
public with sharing class CorrespondenceRequestServices {
    public static void updLanguage(List<T_DOC_RQ__c> newRequestList){
        set<Id> caseIds = new set<Id>();
        set<Id> provrIds = new set<Id>();
        set<Id> corrSfIds = new set<Id>();
        map<Id, string> casePreferredLangMap = new map<Id, string>();
        map<Id, string> provrPreferredlangMap = new map<Id, string>();
        List<T_DOC_RQ__c> corrListToBeUpdtd = new List<T_DOC_RQ__C>();
        
        for(t_doc_rq__c eachCorr : newRequestList){
            if(eachCorr.IDN_CASE__c != null){
                caseIds.add(eachCorr.IDN_CASE__c);
            }
            if(eachCorr.IDN_PROVR__c != null){
                provrIds.add(eachCorr.IDN_PROVR__c);
            }
            corrSfIds.add(eachCorr.Id);
        }
        
        if(caseIds!=null){
            for(t_sbsd_case__c  eachCorrCase : [select Id, Name, CDE_LANG_CORR__c from T_SBSD_CASE__C where Id in:caseIds]){
                if(eachCorrCase.CDE_LANG_CORR__c != null && eachCorrCase.CDE_LANG_CORR__c == 'SPN'){
                    casePreferredLangMap.put(eachCorrCase.Id, eachCorrCase.CDE_LANG_CORR__c);
                } else {
                    casePreferredLangMap.put(eachCorrCase.Id, 'ENG');
                }
            }
        }
        
        if(provrIds!=null){
            for(T_PROVR_PREF__c  eachCorrProvr : [select Id, Name, CDE_PREF_LANG_PROVR__c, IDN_PROVR__c from T_PROVR_PREF__c where IDN_PROVR__c in:provrIds and CDE_PREF_CORR_PROVR__c = '1' and IND_ACTIVE__c = true]){
                if(eachCorrProvr.CDE_PREF_LANG_PROVR__c != null && eachCorrProvr.CDE_PREF_LANG_PROVR__c == 'SPN'){
                    provrPreferredlangMap.put(eachCorrProvr.IDN_PROVR__c, eachCorrProvr.CDE_PREF_LANG_PROVR__c);
                } else {
                    provrPreferredlangMap.put(eachCorrProvr.IDN_PROVR__c, 'ENG');
                }
            }
        }
        
        if(corrSfIds!=null){
            for(T_DOC_RQ__C eachCorrReq : [select id, Name, NME_CORSPD__c, idn_case__c, idn_provr__c, cde_lang_doc__c from T_DOC_RQ__C where id in:corrSfIds]){
                system.debug('correspondence record-->'+eachCorrReq);
                if(eachCorrReq.idn_case__c!=null && casePreferredLangMap.get(eachCorrReq.idn_case__c)!=null){
                    T_DOC_RQ__c corrRecToBeUpdtd = new T_DOC_RQ__C();
                    corrRecToBeUpdtd.Id = eachCorrReq.Id;
                    corrRecToBeUpdtd.cde_lang_doc__c = casePreferredLangMap.get(eachCorrReq.idn_case__c);    
                    corrListToBeUpdtd.add(corrRecToBeUpdtd);
                }
                if(eachCorrReq.IDN_PROVR__c!=null ){
                    if(provrPreferredlangMap.containsKey(eachCorrReq.IDN_PROVR__c)){
                        T_DOC_RQ__c corrRecToBeUpdtd1 = new T_DOC_RQ__C();
                    	corrRecToBeUpdtd1.Id = eachCorrReq.Id;
                    	corrRecToBeUpdtd1.cde_lang_doc__c = provrPreferredlangMap.get(eachCorrReq.IDN_PROVR__c);    
                        corrListToBeUpdtd.add(corrRecToBeUpdtd1);
                    } else {
                        T_DOC_RQ__c corrRecToBeUpdtd2 = new T_DOC_RQ__C();
                    	corrRecToBeUpdtd2.Id = eachCorrReq.Id;
                    	corrRecToBeUpdtd2.cde_lang_doc__c = 'ENG';
                    	corrListToBeUpdtd.add(corrRecToBeUpdtd2);
                    }
                } 
            }
        }
        
        if(!corrListToBeUpdtd.isEmpty()){
             GenericDMLHandler.updateRecords(corrListToBeUpdtd,null);
        }
    }
}