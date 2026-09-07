/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           14/07/2021                                                          
*  @description    IPV Disqualification Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 14-July-2021                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Initial version                                                 
*   
*  
*********************************************************************************************/
trigger IPVDisQualifycationApxTrigger on IPV_Information__c (after insert,after update) {
if(TriggersOnOffServices.triggerStatus('IPVDisQualifycationApxTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
             IPVDisQualifycationService.triggerCR110(Trigger.new,Trigger.old,false);
        } if(Trigger.isUpdate){
            IPVDisQualifycationService.triggerCR110(Trigger.new,Trigger.old,true);
        } 
           
            
        
    }
}