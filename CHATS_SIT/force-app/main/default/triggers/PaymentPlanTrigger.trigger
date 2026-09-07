/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           11/22/2017
*  @description    Payment Plan Trigger

*  Modification Log:
*  * Version: 1.0
*  * Date: 11-Nov-2017
*  * Author: Bharadwaj Gaddam
*  * Description: Initial version
*  * Deactivates Previous Payment Plan
*  * Version: 2.0
*  * Date: 02/17/2018
*  * Author: Diya Chaudhary
*  * Description: Copying Salesforce ID to External Id field
*  * Version: 3.0
*  * Date: 10/19/2020
*  * Author: Diya Chaudhary
*  * Description: Adding validation for the logged user county vs active payment plan county on provider.
*********************************************************************************************/
trigger PaymentPlanTrigger on T_PMT_PLAN__c (before insert,after insert,before update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('PaymentPlanTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            // Replacing 'deactivatePreviousPlan' with 'deactivatePreviousPlanPerCounty' by Rishav for CCCAP-5785
            // PaymentPlanServices.deactivatePreviousPlan(Trigger.new); // Deactivates Previous Payment Plan
            PaymentPlanServices.deactivatePreviousPlanPerCounty(Trigger.new);
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_PMT_PLAN__c where Id=:trigger.newMap.keySet()],true);
        }
    }
    // CCCAP-2011
    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            // Disabled 'countyCheck' by Rishav for CCCAP-5785
            // PaymentPlanServices.countyCheck(Trigger.new,Trigger.isUpdate);
        }
        if(Trigger.isUpdate){
            // Replacing 'activePaymentPlanCheck' with 'activePaymentPlanPerCountyCheck' by Rishav for CCCAP-5785
            // PaymentPlanServices.activePaymentPlanCheck(Trigger.new);
            PaymentPlanServices.activePaymentPlanPerCountyCheck(Trigger.new);
        }
    }
}