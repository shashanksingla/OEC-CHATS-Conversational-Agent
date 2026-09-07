/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           05/28/2018
*  @description    Handler class for Case Information
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 28-May-2018
*  * Author: Bharadwaj Gaddam
*  * Description: Initial version 
*********************************************************************************************/
/**
* @description Restricting user from creating not more than one Email Type
* @author Bharadwaj Gaddam 
* @date 05/28/2018  
* @param List<T_SBSD_CASE_INFO__c> trigger.new Case Information list
* @return void
*/
public with sharing class CaseInformationServices {

    public static final string EMAIL=Label.EM;

    public static void allowOnlyOneEmailType(List<T_SBSD_CASE_INFO__c> caseInfoNewList) {
        Set<Id> caseIdSet = new Set<Id>();
        for(T_SBSD_CASE_INFO__c caseInfoEach: caseInfoNewList) {
            if(caseInfoEach.CDE_TYPE_INFO_CASE__c==EMAIL && caseInfoEach.IDN_CASE__c!=null) {
                caseIdSet.add(caseInfoEach.IDN_CASE__c);
            }
        }
        Map<Id,T_SBSD_CASE__c> caseMap = new  Map<Id,T_SBSD_CASE__c>([Select Id,Is_Peak_Data__c,Is_CBMS_Data__c, (select Id,CDE_TYPE_INFO_CASE__c from T_SBSD_CASE13__r where CDE_TYPE_INFO_CASE__c=:EMAIL and Id NOT IN:caseInfoNewList Limit 1) from T_SBSD_CASE__c where Id IN:caseIdSet]);
        for(T_SBSD_CASE_INFO__c caseInfoEach: caseInfoNewList) {
            if(caseInfoEach.CDE_TYPE_INFO_CASE__c==EMAIL && caseInfoEach.IDN_CASE__c!=null) {
                if(caseMap.get(caseInfoEach.IDN_CASE__c)!=null) {
                    if(caseMap.get(caseInfoEach.IDN_CASE__c).T_SBSD_CASE13__r.size()>0 && caseMap.get(caseInfoEach.IDN_CASE__c).Is_Peak_Data__c && caseMap.get(caseInfoEach.IDN_CASE__c).Is_CBMS_Data__c) {
                        caseInfoEach.addError(Label.Please_update_the_existing_Email_record_for_that_case);                        
                    }
                }
            }
        }
    }
    
    public static void insertCaseIndivToATSOnEmailUpdate(list<T_SBSD_CASE_INFO__c> newCaseInfoList, Map<Id, T_SBSD_CASE_INFO__c> oldCaseInfoMap) {
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, T_SBSD_CASE_INDIV__c> casePrimaryTakerMap = new Map<Id, T_SBSD_CASE_INDIV__c>();
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        for(T_SBSD_CASE_INFO__c eachCaseinfo : newCaseInfoList) {
            if(eachCaseinfo.IDN_CASE__c != null){
                caseIdSet.add(eachCaseinfo.IDN_CASE__c);
            }
        }
        if(!caseIdSet.isEmpty()){
            for(T_SBSD_CASE_INDIV__c eachCaseIndiv : [SELECT IDN_CASE__c, IDN_CASE__r.Name, Name, IDN_CLIENT__r.Name FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c IN: caseIdSet AND IND_CRTKR__c = true]){
                casePrimaryTakerMap.put(eachCaseIndiv.IDN_CASE__c, eachCaseIndiv);
            }
        }
        for(T_SBSD_CASE_INFO__c eachCaseInfo1 : newCaseInfoList){
            if(trigger.isUpdate){
                system.debug('in Update');
                if(eachCaseInfo1.CDE_TYPE_INFO_CASE__c == 'EM' && eachCaseInfo1.TXT_VALUE_INFO_CASE__c != oldCaseInfoMap.get(eachCaseInfo1.Id).TXT_VALUE_INFO_CASE__c  && casePrimaryTakerMap.get(eachCaseInfo1.IDN_CASE__c) != null){
                    batchsit_t_pos_trans_queue_ats__x atsRecord1 = new batchsit_t_pos_trans_queue_ats__x();
                    atsRecord1.CDE_STATUS_TRANS__c= '1';
                    atsRecord1.CDE_TYPE_TRANS__c ='3';
                    atsRecord1.IDN_CASE__c = casePrimaryTakerMap.get(eachCaseInfo1.IDN_CASE__c).IDN_CASE__r.Name;
                    atsRecord1.IDN_CLIENT__c = casePrimaryTakerMap.get(eachCaseInfo1.IDN_CASE__c).IDN_CLIENT__r.Name;
                    atsRecord1.DTE_CHANGE_LAST__c = System.today();
                    lstATSRecords.add(atsRecord1);
                }
            } else if(trigger.isInsert){
                system.debug('In insert');
                if(eachCaseInfo1.CDE_TYPE_INFO_CASE__c == 'EM' && casePrimaryTakerMap.get(eachCaseInfo1.IDN_CASE__c) != null){
                    batchsit_t_pos_trans_queue_ats__x atsRecord2 = new batchsit_t_pos_trans_queue_ats__x();
                    atsRecord2.CDE_STATUS_TRANS__c= '1';
                    atsRecord2.CDE_TYPE_TRANS__c ='3';
                    atsRecord2.IDN_CASE__c = casePrimaryTakerMap.get(eachCaseInfo1.IDN_CASE__c).IDN_CASE__r.Name;
                    atsRecord2.IDN_CLIENT__c = casePrimaryTakerMap.get(eachCaseInfo1.IDN_CASE__c).IDN_CLIENT__r.Name;
                    atsRecord2.DTE_CHANGE_LAST__c = System.today();
                    lstATSRecords.add(atsRecord2);
                }
            }
        }
        ATSHandler.insertATSRecord(true, lstATSRecords);
    }
}