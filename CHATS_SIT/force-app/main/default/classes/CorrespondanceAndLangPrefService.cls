/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/08/2017                                                          
*  @description    Handler class for Correspondance and Language Preference                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 08-Nov-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Populates IND_ACTIVE__c with false in previously active Correspondance and Language Preference record.
*  *
*  * Author: Azhar                                                   
*  * Description: Populates IND_ACTIVE__c with false in previously active Correspondance and Language Preference record based on Correspondence preference.
*  * 				there can be two active records once for mail , other for Email.                                                                                 
*********************************************************************************************/

public with sharing class CorrespondanceAndLangPrefService {
    
    public static void updateCorrespondanceAndLangPrefForActiveStatus(List<T_PROVR_PREF__c> lstNewCorresAndLangPref){
        Set<Id> providerIdSet = new Set<Id>();
        map<Id, T_PROVR_PREF__c> correspondencePreferenceMap = new map<Id, T_PROVR_PREF__c>();
        List<T_PROVR_PREF__c> lstCorresAndLangPrefUpdate = new List<T_PROVR_PREF__c>();
        for(T_PROVR_PREF__c newActiveCorresAndLangPref : lstNewCorresAndLangPref){
            //Updated below line and removed checking true condition 5/12/2018 BG
            if(newActiveCorresAndLangPref.IND_ACTIVE__c){
                providerIdSet.add(newActiveCorresAndLangPref.IDN_PROVR__c);
                correspondencePreferenceMap.put(newActiveCorresAndLangPref.IDN_PROVR__c, newActiveCorresAndLangPref);
            }
        }
        if(providerIdSet.size() > 0){
            List<T_PROVR_PREF__c> lstOldActiveCorresAndLangPref = [Select Id,IND_ACTIVE__c,CDE_PREF_CORR_PROVR__c,CDE_PREF_LANG_PROVR__c, IDN_PROVR__c 
                                                                   from T_PROVR_PREF__c where IND_ACTIVE__c = true and IDN_PROVR__c IN:correspondencePreferenceMap.keySet() and Id NOT IN:lstNewCorresAndLangPref];
            for(T_PROVR_PREF__c oldActiveCorresAndLangPref : lstOldActiveCorresAndLangPref){
            	if(oldActiveCorresAndLangPref.CDE_PREF_CORR_PROVR__c ==  correspondencePreferenceMap.get(oldActiveCorresAndLangPref.IDN_PROVR__c).CDE_PREF_CORR_PROVR__c) {
                    oldActiveCorresAndLangPref.IND_ACTIVE__c = false;
                    lstCorresAndLangPrefUpdate.add(oldActiveCorresAndLangPref);
            	}
            }
            if(lstCorresAndLangPrefUpdate.size() > 0)
            	processSaveResult(lstCorresAndLangPrefUpdate);
        }
    }
    
    public static void processSaveResult(List<T_PROVR_PREF__c> lstUpdatedInactiveCorresAndLangPref){
        List<Database.SaveResult> lstUpdatedCorresAndLangPrefRecords = Database.update(lstUpdatedInactiveCorresAndLangPref, false); 
        for(Integer i = 0; i < lstUpdatedCorresAndLangPrefRecords.size() ; i++){
            if(!lstUpdatedCorresAndLangPrefRecords.get(i).isSuccess()){
                List<Database.Error> lstError = lstUpdatedCorresAndLangPrefRecords.get(i).getErrors();
                String failedDML;
                for(Database.Error error : lstError){
                    failedDML = failedDML + '\n' + error.getMessage();
                }
                T_PROVR_PREF__c corresAndLangPref = lstUpdatedInactiveCorresAndLangPref.get(i);
                corresAndLangPref.addError('EXCEPTION : Unable to update status for Correspondence and Language record: ' +failedDML);
            }   
        }
    } 

}