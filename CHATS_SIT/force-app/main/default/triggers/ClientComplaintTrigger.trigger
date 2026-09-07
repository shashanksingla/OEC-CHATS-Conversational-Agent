/*Trigger Name    - ClientComplaintTrigger
Handler Class   - ClientComplaintTriggerHandler
Test Class      - ClientComplaintTriggerHandler_Test
Object          - Client_Complaint__c
Description     - Primary trigger for Client Complaint object
*****************************************************************************************/

trigger ClientComplaintTrigger on Client_Complaint__c (after insert, after update) {
    if (TriggersOnOffServices.triggerStatus('ClientComplaintTrigger')) {
        return;
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ClientComplaintTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}