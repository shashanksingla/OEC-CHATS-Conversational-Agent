/*****************************************************************************************
Class Name      - TaskTrigger
Test Class      - TaskTrigger_Test
Handler Class   - TaskServicesAPXCtrl
Description     - Primary trigger for Task standard object
Created Date    - March 4, 2021 (CHATS_1_32_0)

*  Modification Log:
*
*  * CCCAP-8475: Replaced 'validateCounty' with a bulkified method 'validateCountyBulk'.
*****************************************************************************************/
trigger TaskTrigger on Task (before update, after insert, after update) {
    if(TriggersOnOffServices.triggerStatus('TaskTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isBefore) {
        if(Trigger.isUpdate){
            TaskServicesAPXCtrl.validateOwnerUpdateRestriction(Trigger.New, Trigger.oldMap); //CCCAP-15359
        }
    }

    if(Trigger.isAfter) {
        if(Trigger.isUpdate){
            if(Trigger.New.size() > 1) {
                TaskServicesAPXCtrl.validateCountyBulk(Trigger.New, Trigger.oldMap);
            } else {
                Task t = Trigger.New[0];
                if(t.Status == 'Completed' && t.Status != Trigger.oldMap.get(t.Id).Status){
                    String message = TaskServicesAPXCtrl.validateCounty(t.Id);
                    if(String.isNotBlank(message)){
                        t.addError(message);
                    }
                }
            }
        }
        if(Trigger.isInsert){
            if(Trigger.New.size() > 1) {
                TaskServicesAPXCtrl.validateCountyBulk(Trigger.New, new Map<Id, Task>());
            } else {
                Task t = Trigger.New[0];
                if(t.Status == 'Completed'){
                    String message = TaskServicesAPXCtrl.validateCounty(t.Id);
                    if(String.isNotBlank(message)){
                        t.addError(message);
                    }
                }
            }
            //added for CCCAP-11593
            TaskServicesAPXCtrl.checkT227ForEmailNotification(Trigger.New);
        }
    }
    /* Commented out below code by Rishav for CCCAP-8475
     * It causes 'System.LimitException: Too many SOQL queries: 101'
    for(Task t : (List<Task>)Trigger.new){
        Map<id, Task> oldMap = Trigger.isInsert ? null : Trigger.oldMap;
        if(t.Status == 'Completed' && (oldMap == null || t.Status != oldMap.get(t.Id).Status)){
            String message = TaskServicesAPXCtrl.validateCounty(t.Id);
            if(String.isNotBlank(message)){
                t.addError(message);
            }
        }
    } */
}