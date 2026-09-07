/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/10/2018                                                          
*  @description    Adjustment Payment Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 01-10-2017                                                             
*  * Author: Bharadwaj Gaddam                                                     
*  * Description: Initial version                                                 
*  * CHAT-1057: Create Adjustment Payment Detail records for Adjustment Payments
*********************************************************************************************/
trigger AdjustmentPaymentTrigger on T_ADJMT_PMT__c (after insert,before insert,before update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('AdjustmentPaymentTrigger')) {
        return; //rest of the lines will not be executed
    }
    
    if(trigger.isBefore) {
        if(trigger.isInsert) {
            AdjustmentPaymentServices.checkAdjustmentStatusBeforeInsertAdjustmentPayment(trigger.new);
            // CCCAP-12549(To be run before createAdjustmentPaymentDetails)
            AdjustmentPaymentServices.createAdjustmentPaymentDetailsWithCDOR(trigger.new);
            AdjustmentPaymentServices.createAdjustmentPaymentDetails(trigger.new);
        }
    }
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_ADJMT_PMT__c where Id=:trigger.newMap.keySet()],true);
            // CCCAP-12549(To be run before createAdjustmentPaymentDetails)
            AdjustmentPaymentServices.createAdjustmentPaymentDetailsWithCDOR(trigger.new);
            //CHAT-1057
            AdjustmentPaymentServices.createAdjustmentPaymentDetails(trigger.new);
        }
    }

}