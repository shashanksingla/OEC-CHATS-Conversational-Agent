/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           2/7/2018                                                          
*  @description    Handler class for Fiscal Agreement Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 7-Feb-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version  
*                CHAT-491 : Populating TXT_CHATS_RATING__c in T_FISCAL_SCH__c from T_CHATS_PROVR_STATUS.TXT_CHATS_RATING__c field.
*                CHAT-695 : Create a Task when Fiscal Agreement Quality Rating is Changed.
*********************************************************************************************/
trigger RateScheduleTrigger on T_FISCAL_SCH__c (before insert, after insert, before update,before delete,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('RateScheduleTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(trigger.isBefore) {
        if(trigger.isInsert) {
            //CHAT-491
            RateScheduleServices.updateQualityRating(trigger.new);
            RateScheduleServices.validateEffectiveBeginEndDateOfExistingRateSchedules(trigger.new, null);
        }
        if(trigger.isUpdate){
            RateScheduleServices.validateEffectiveBeginEndDateOfExistingRateSchedules(trigger.new, trigger.oldMap);
        }
    
        if(trigger.isDelete){
             RateScheduleServices.updateEnddateonExistingFiscalRate(trigger.old);
             RateScheduleServices.deleteRateScheduleChildRecords(trigger.old);
         }
    }  
    
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            //CHAT-695
            RateScheduleServices.createTaskforAuthOwner(trigger.new,trigger.newMap.keySet());
            RateScheduleServices.updateEnddateonFiscalAgreement(trigger.new,null);
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_FISCAL_SCH__c where Id=:trigger.newMap.keySet()],true);
            RateScheduleServices.insertATSRecord(Trigger.new);
        }
         if(trigger.isUpdate){
            RateScheduleServices.insertATSRecord(Trigger.new);
             RateScheduleServices.updateEnddateonFiscalAgreement(trigger.new,Trigger.oldMap);
        }
    
    }
}