/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/31/2022                                                          
*  @description    Adjustment  Cancellation Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 31-Oct-2022                                                             
*  * Author: Raina Yeole
*  * Description: CCCAP-7013
*********************************************************************************************/
trigger adjustmentCancellationTrigger on T_ADJMT_CANCEL__c (before insert,before update,before delete, after insert, after Update) {

    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            adjustmentCancellationService.validateCancellationNotes(trigger.new, trigger.newMap, trigger.old, trigger.OldMap);
        }
        
    }
}