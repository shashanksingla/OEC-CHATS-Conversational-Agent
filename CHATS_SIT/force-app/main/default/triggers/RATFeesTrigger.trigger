/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/25/2017                                                          
*  @description    RAT FEES Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-Dec-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  * CHAT- 685: RAT FEES schedule completion - Event Based Trigger
*********************************************************************************************/
trigger RATFeesTrigger on T_FISCAL_RAT_FEES__c (after insert) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('RATFeesTrigger')) {
        return; //rest of the lines will not be executed
    }
    //CHAT-685 - RAT FEES schedule completion
    if(Trigger.isAfter){
        if(Trigger.isInsert){
    		RATFeesServices.triggerCorspdCR707(Trigger.new);
    	}
    }
}