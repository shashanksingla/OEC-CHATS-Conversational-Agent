/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Appeal Trigger   
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Initial version
*********************************************************************************************/
trigger appealTrigger on T_APPEAL__c(after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('appealTrigger')) {
        return; //rest of the lines will not be executed
    }
	if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_APPEAL__c where Id=:trigger.newMap.keySet()],true);
        }
    
    }
}