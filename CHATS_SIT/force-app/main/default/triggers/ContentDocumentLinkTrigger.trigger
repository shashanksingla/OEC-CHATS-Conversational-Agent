trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, before delete) {
    
   // User u = [SELECT Profile.Name FROM User WHERE Id = :Userinfo.getUserId() limit 1];   Using Custom permission CCCAP-14993 
    String keyPrefix = T_CHATS_PROVR_STATUS__c.SObjectType.getDescribe().getKeyPrefix();    
    String entityId;
    //Replaced with custom permission CCCAP-14993
    if(Trigger.isInsert && (!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team'))){
        for(ContentDocumentLink cdl : trigger.new){
            entityId = cdl.LinkedEntityId;
            if(entityId.startsWith(keyPrefix)){                
                cdl.addError('You do not have permission to perform this action.');
            }
        }
    }
    if(Trigger.isDelete){
        for(ContentDocumentLink cdl : trigger.old){
            entityId = cdl.LinkedEntityId;
            if(entityId.startsWith(keyPrefix)){                
                cdl.addError('"Remove from Record" is not allowed for provider files.');
            }
        }
    }
}