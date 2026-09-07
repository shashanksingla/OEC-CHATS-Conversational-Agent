/*******************************************************
*  @author         Deloitte Consulting LLP.
*  @date           02/17/2018
*  @description    Adjustment Payment Detail Trigger
*  * Version: 1.0
*  * Date: 02/17/2018
*  * Author: Diya Chaudhary
*  * Description: Initial version
*******************************************************/
trigger adjustmentPaymentDetailTrigger on T_ADJMT_PMT_DETAIL__c (after insert, after update, after delete) {
    
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('adjustmentPaymentDetailTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([SELECT Id, IDN_EXTNL__c FROM T_ADJMT_PMT_DETAIL__c WHERE Id = :trigger.newMap.keySet()], true);
            adjustmentPaymentDetailUpdate.adjPayDetCheck(trigger.new);
        }
        if(Trigger.isUpdate){
            adjustmentPaymentDetailUpdate.adjPayDetCheck(trigger.new);
        }
        if(Trigger.isDelete){ //added for CCCAP-14525
            adjustmentPaymentDetailUpdate.adjPayDetCheck(trigger.old);
        }
    }
}