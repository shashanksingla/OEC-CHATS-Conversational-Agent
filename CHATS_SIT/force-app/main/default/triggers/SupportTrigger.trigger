/*************************************************************
Class Name      - SupportTrigger
Test Class      - SupportTrigger_Test
Handler Class   - SupportServices
Description     - Main trigger for Support (CHATS_Support__c) object
Author          - Rishav Maji
Requirement     - Project 407 : CCCAP-6416
**************************************************************/
trigger SupportTrigger on CHATS_Support__c (before insert, before update, before delete, after insert, after update) {
    if(TriggersOnOffServices.triggerStatus('supportTrigger')) { // Check trigger active/inactive
        return; // rest of the lines will not be executed
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isUpdate){
            SupportServices.sendEmailAndBellNotification(Trigger.oldMap, Trigger.newMap);
        }
    }
}