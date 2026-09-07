trigger IndividualEmailTrigger on Individual_E_mail__c (before insert, after insert, before update, after update, before delete, after delete) 
{
// Trigger On and Off service
 if(TriggersOnOffServices.triggerStatus('IndividualEmailTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isBefore &&  Trigger.isInsert) {
        IndividualEmailTrigger_Helper.updateEndDate(Trigger.New);
    }
    
    if(Trigger.isAfter &&  Trigger.isInsert) {
        IndividualEmailTrigger_Helper.updateCaseEmailBulk(Trigger.newMap,Trigger.oldMap);
    }
    if(Trigger.isBefore &&  Trigger.isUpdate) {
        
    }
    if(Trigger.isAfter &&  Trigger.isUpdate) {
        
      IndividualEmailTrigger_Helper.updateCaseEmailBulk(Trigger.newMap,Trigger.oldMap);  
    }
     if(Trigger.isBefore &&  Trigger.isDelete) {
        
    }
    if(Trigger.isAfter &&  Trigger.isDelete) {
        
    }
    
}