/*************************************************************
Class Name      - SupportCommentTrigger
Test Class      - SupportCommentTrigger_Test
Handler Class   - SupportServices
Description     - Main trigger for Support Comment(CHATS_Support_Comment__c) object
Author          - Diya Chaudhary
Requirement     - HDT -281347 : CCCAP-12724
**************************************************************/
trigger SupportCommentTrigger on CHATS_Support_Comment__c (after insert, after update) {
    if(TriggersOnOffServices.triggerStatus('supportCommentTrigger')) { // Check trigger active/inactive
        return; // rest of the lines will not be executed
    }
     if(Trigger.isAfter) {
        if(Trigger.isUpdate || Trigger.isInsert){
            SupportServices.sendBellNotificationSupportComment(Trigger.oldMap, Trigger.newMap);
        }
    }
}