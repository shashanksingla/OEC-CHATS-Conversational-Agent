trigger CorrespondenceRequestTrigger on T_DOC_RQ__c (after insert) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            CorrespondenceRequestServices.updLanguage(Trigger.new);
        }
    }
}