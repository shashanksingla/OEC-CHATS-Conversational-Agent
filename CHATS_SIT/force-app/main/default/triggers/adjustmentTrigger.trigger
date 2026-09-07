/*************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           09/11/2017
*  @description    Adjustment Trigger
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 10-Dec-2017
*  * Author: Azharuddin Mohammad
*  * Description: Chat-680 - Event Based correspondence trigger -CR206
*************************************************************************/
trigger adjustmentTrigger on T_ADJMT__c (before insert,before update,before delete, after insert, after Update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('adjustmentTrigger')) {
        return; //rest of the lines will not be executed
    }
    public static final String adjmtTypeCalculation = '2';
    public static final String SATISFIED = '3';
    set<Id> adjmtList = new set<Id>(); 
    if(Trigger.isBefore){
        if(Trigger.isDelete) {
            adjustmentServices.deleteAllChildAdjustmentRecords(Trigger.old);
        }
         if(Trigger.isInsert){
            adjustmentServices.providerStatusCheck(Trigger.new, Trigger.oldMap);
           // adjustmentServices.duplicateAdjustmentCheck(trigger.new);
        }
        if(Trigger.isUpdate){
            adjustmentServices.providerStatusCheck(Trigger.new, Trigger.oldMap);
           // adjustmentServices.duplicateAdjustmentCheck(trigger.new);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([SELECT Id, IDN_EXTNL__c FROM T_ADJMT__c WHERE Id = :Trigger.newMap.keySet()], true);
        }
        //CHAT-680 
        if(Trigger.isUpdate){
            adjustmentServices.triggerCorspdCR206(Trigger.newMap, Trigger.oldMap);
            adjustmentServices.triggerCorspdCR209(Trigger.new, Trigger.oldMap);
            adjustmentServices.updateTaxInterceptFields(Trigger.new, Trigger.oldMap); // Added by Raina for CCCAP-7029
            adjustmentServices.updateManualClaimRecord(Trigger.new, Trigger.oldMap); // Added by Shashank for CCCAP-12974
        }
    }
}