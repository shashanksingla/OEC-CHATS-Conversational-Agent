/*********************************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           07/04/2023
*  @description    Tax Intercept Trigger
*  * Version: 1.0
*  * Date: 07/04/2023
*  * Author: Shashank S.
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger TaxInterceptTrigger on Tax_Intercept__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('TaxInterceptTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from Tax_Intercept__c where Id=:trigger.newMap.keySet()],true);
        }
        
    }
}