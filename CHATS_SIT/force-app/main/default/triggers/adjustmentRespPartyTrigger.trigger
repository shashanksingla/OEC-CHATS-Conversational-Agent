/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Responsible Parties Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Initial version
*********************************************************************************************/
trigger adjustmentRespPartyTrigger on T_ADJMT_RESPBL_PARTY__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('adjustmentRespPartyTrigger')) {
        return; //rest of the lines will not be executed
    }
	if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_ADJMT_RESPBL_PARTY__c where Id=:trigger.newMap.keySet()],true);
        }
    
    }
}