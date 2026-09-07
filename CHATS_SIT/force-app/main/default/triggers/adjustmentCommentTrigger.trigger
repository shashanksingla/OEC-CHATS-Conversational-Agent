/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Note Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field
*********************************************************************************************/
trigger adjustmentCommentTrigger on T_ADJMT_CMT__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('adjustmentCommentTrigger')) {
        return; //rest of the lines will not be executed
    }
	if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_ADJMT_CMT__c where Id=:trigger.newMap.keySet()],true);
        }
    
    }
}