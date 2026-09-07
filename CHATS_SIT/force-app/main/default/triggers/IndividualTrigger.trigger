/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/8/2018                                                          
*  @description    Individual Search Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 8-JAN-2018                                                             
*  * Author: Nikunj Doshi                                                   
*  * Description: Initial version                                                 
*  * copying soundex value to TXT_SNDX__c field
*                                                                                      
*  * Version: 2.0                                                                             
*  * Date: 19-Jan-2018                                                           
*  * Author: Bharadwaj Gaddam                                               
*  * Description: copying salesforce Id to External Id                                                  

*  * Version: 3.0                                                                             
*  * Date: 2-Feb-2018                                                           
*  * Author: Shubham Jain
*  * Description: Task Creation: T101 - SIDMOD Updated Client DOB

*  * Version: 4.0                                                                             
*  * Date: 6-Mar-2018                                                           
*  * Author: Shubham Jain
*  * Description: Added call to fillIND_NOTIFY_SIDMOD method.

*  * Version: 5.0                                                                             
*  * Date: 13-Jun-2018                                                           
*  * Author: Shubham Jain
*  * Description: Added new method to delete child records for individuals.

*  * Version: 6.0                                                                             
*  * Date: 10-Oct-2018                                                           
*  * Author: Bharadwaj Gaddam
*  * Description: Added new method to update Primary Caretaker Name on Case.

*  * Version: 7.0                                                                             
*  * Description: Added validation to prevent How Verified field updates when none of related Case Individual records have Child status.

*********************************************************************************************/

trigger IndividualTrigger on T_SBSD_INDIV__c (before insert, before update,after insert, after update, before delete) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('IndividualTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(trigger.isBefore) {
        if(Trigger.isDelete){
            IndividualServices.createIDXRStagingRecords(trigger.old); //added for CCCAP-11512
            IndividualServices.deleteChildRecords(trigger.old);
        }else{
            IndividualServices.fillSoundexValue(trigger.new, trigger.oldMap);
            IndividualServices.fillIND_NOTIFY_SIDMOD(trigger.new, trigger.oldMap);
            
            if(Trigger.isUpdate){
                //CHATS-6436 Prod Fix to skip data validation for Batch User 
                if(!(Userinfo.getUserId().contains(Label.Batch_User_Id))) {
                    IndividualServices.validateSourceVerifiedCitizenship(trigger.new,Trigger.oldMap);
                }
                IndividualServices.validateReadOnlyFieldsForClearedIndividuals(trigger.new, trigger.oldMap);
                IndividualServices.validateHowVerifiedFieldsForChildStatus(trigger.new); //CCCAP-14038
            }
        }
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id   
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_SBSD_INDIV__c where Id=:trigger.newMap.keySet()],true);
        }
        if(Trigger.isUpdate) { 
            //Task Creation: T101 - SIDMOD Updated Client DOB
            IndividualServices.createTaskT101(IndividualServices.filterCases(IndividualServices.filterIndividualsForDateChanges(trigger.new, trigger.oldMap,'DobChange')));
            //Task Creation: T501 - SIDMOD Updated Client Date of Death
            IndividualServices.createTaskT501(IndividualServices.filterCases(IndividualServices.filterIndividualsForDateChanges(trigger.new, trigger.oldMap,'DoDeathChange')));
            //Task Creation: T502 - SIDMOD Updated Client Date of Death, On Case with active recovery
            IndividualServices.createTaskT502(IndividualServices.filterActiveRecoveryCases(IndividualServices.filterIndividualsForDateChanges(trigger.new, trigger.oldMap,'DoDeathChange')));
            //Update Primary Caretaker on Case
            IndividualServices.updatePrimCaretakerOnCase(trigger.new, trigger.oldMap);
            //CHATS-7297 : send Individual record to ATS when State ID is updated.
            //IndividualServices.sendIndivToATSOnStateIDUpdate(trigger.new, trigger.oldMap);
            IndividualServices.updateDOBChangeIndicator(IndividualServices.filterIndividualsForDateChanges(trigger.new, trigger.oldMap,'DobChange'));
        }
    }
}