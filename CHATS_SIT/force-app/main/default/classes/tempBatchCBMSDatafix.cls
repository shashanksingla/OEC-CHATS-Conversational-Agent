global with sharing class tempBatchCBMSDatafix implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        
        return Database.getQueryLocator('Select  id ,IDN_APPLN__c,IDN_APPLN__r.IDN_CBMS_REF__c,IDN_APPLN__r.CDE_CBMS_REF_TYP__c, name,IDN_CASE__c  from T_APPLN_PRCS_QUEUE__c where IDN_APPLN__r.WORK_SPECIALIST__c=\'Conversion user\'');   
        
    }
    
    
    global void execute(Database.BatchableContext BC, List<T_APPLN_PRCS_QUEUE__c> scope){
        for(T_APPLN_PRCS_QUEUE__c appProcessQueue : scope){
            List<T_SBSD_CASE__c> caseRec = [SELECT ID,NAME,CDE_COUNTY__c,PRIOR_COUNTY__c FROM T_SBSD_CASE__c WHERE ID =:appProcessQueue.IDN_CASE__c];
            List<T_CBMS_ADDNL_INFO__c> tanfLst = [SELECT ID,NAME,IDN_CASE_CHATS__c,DTE_BEGIN_EFFEV__c,AMT_TANF_INCOME_HH_GROSS__c FROM T_CBMS_ADDNL_INFO__c WHERE IDN_CASE_CHATS__c=:appProcessQueue.IDN_CASE__c];
            APXPolicyRecordsServices.createRefData(appProcessQueue.IDN_APPLN__r.IDN_CBMS_REF__c ,appProcessQueue.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,new List<SObject>{caseRec[0]});
            if(tanfLst != null && tanfLst.size() >0){
            	APXPolicyRecordsServices.createRefData(appProcessQueue.IDN_APPLN__r.IDN_CBMS_REF__c ,appProcessQueue.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,new List<SObject>{tanfLst[0]});    
            }
            List<T_APPLN_CHILD_CARE__c> chilCareList = new List<T_APPLN_CHILD_CARE__c>();
            List<T_APPLN_INDIV__c> listApplnIndivAndAllChilds = new List<T_APPLN_INDIV__c>();
            listApplnIndivAndAllChilds = [select Id, Name, IDN_STATE__c, IND_CTZN__c,IDN_APPLN__c,
                                          (SELECT id,CHILD_NAME__c,IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,CNT_HOUR_ON_FRI__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_APPLN__c,
                                           CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_CBMS_REF__c,
                                           CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,IDN_CBMS_PROVR__c,IDN_INDIVIDUAL__c,NAM_FACILITY__c,IND_NEED_CHILD_CARE__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c FROM Application_Child_Cares__r)
                                          from T_APPLN_INDIV__c
                                          where IDN_APPLN__c =:appProcessQueue.IDN_APPLN__c];
            for(T_APPLN_INDIV__c eachApplnIndividual : listApplnIndivAndAllChilds){
                if(eachApplnIndividual.Application_Child_Cares__r != null && eachApplnIndividual.Application_Child_Cares__r.size()>0){
                    chilCareList.addAll(eachApplnIndividual.Application_Child_Cares__r);
                }
            }
            if(chilCareList.size() > 0){
            ChildCareLastUpdatedServices.updateRefInfo(new List<T_APPLN_CHILD_CARE__c>(),new Map<Id, T_APPLN_CHILD_CARE__c>(),chilCareList);
            }    
        } 
    }
    
    global void finish(Database.BatchableContext BC){
        
        
    }
}