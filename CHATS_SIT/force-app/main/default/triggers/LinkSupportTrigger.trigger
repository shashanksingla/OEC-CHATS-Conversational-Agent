trigger LinkSupportTrigger on Linked_To__c (before insert) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            LinkSupportServices.avoidDuplication(Trigger.new);  
        }
    } 
}