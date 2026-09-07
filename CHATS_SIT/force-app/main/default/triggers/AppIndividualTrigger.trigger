/*********************************************************************************************
* * Version: 1.0                                                                             
*  * Date: 27-JAN-2020                                                                                                                
*  * Description: Initial version                                                 
*  * copying soundex value to TXT_SNDX__c field
*********************************************************************************************/
trigger AppIndividualTrigger on T_APPLN_INDIV__c (before insert, before delete){
    if(trigger.isBefore) {
        if(Trigger.isInsert){
            ApplicationIndividualServices.fillSoundexValue(trigger.new, trigger.oldMap);
        }     
    }    
}