/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           03-05-2024
*  @description    Reverse Referral Interface Trigger
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 03-05-2024
*  * Author: Shashank Singla
*  * Description: Initial version                                                 
*  * CCCAP-10162: Reverse Referral Interface Trigger to update External Id
*********************************************************************************************/
trigger ReverseRefInterfaceTrigger on Reverse_Referral_Interface_Report__c (before insert,after Insert) {
    if(TriggersOnOffServices.triggerStatus('ReverseRefInterfaceTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from Reverse_Referral_Interface_Report__c where Id=:trigger.newMap.keySet()],true);
        }
        
    }
}