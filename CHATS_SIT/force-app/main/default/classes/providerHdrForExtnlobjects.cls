public with sharing class providerHdrForExtnlobjects {
    @auraEnabled
    public static T_CHATS_PROVR_STATUS__c providerHeaderId(String extnlObjRecId, String extObjName){
         //Removed unused variable on 5/14/2018 BG  
        T_CHATS_PROVR_STATUS__c provrHdr = new T_CHATS_PROVR_STATUS__c();
        if((extnlObjRecId != null) && (extObjName == 'Provider Contact')) {
            provrHdr = [select Id, External_ID__c FROM T_CHATS_PROVR_STATUS__c WHERE External_ID__c IN (select IDN_PROVR__c FROM T_CHATS_PROVR_CNT_INFO_c__x WHERE Id =:extnlObjRecId) LIMIT 1];
        }else if((extnlObjRecId != null) && (extObjName == 'Provider Condition')) {
            provrHdr = [select Id, Program_Name__c FROM T_CHATS_PROVR_STATUS__c WHERE Program_Name__c IN (select IDN_PROVR__c FROM T_CHATS_PROVR_COND_c__x WHERE Id =:extnlObjRecId)  LIMIT 1];
        }else if((extnlObjRecId != null) && (extObjName == 'Provider Capacity')) {
            provrHdr = [select Id, Program_Name__c FROM T_CHATS_PROVR_STATUS__c WHERE Program_Name__c IN (select IDN_PROVR__c FROM T_CHATS_PROVR_CAPACITY_c__x WHERE Id =:extnlObjRecId) LIMIT 1];
        }
        return provrHdr;
    }
}