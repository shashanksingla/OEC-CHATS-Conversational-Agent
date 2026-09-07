/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/14/2017                                                          
*  @description    Provider Trigger                           
*  Modification Log:                                                                             
*                                                                                                                              
*  * Version: 1.0                                                                             
*  * Date: 14-DEC-2017                                                           
*  * Author: Bharadwaj Gaddam                                                 
*  * Description:CHAT-905 updates CDE_TYPE_FACILITY__c on Fiscal Agreements                                                 
*  *    
*  * Version: 2.0                                                                             
*  * Date: 01-FEB-2018                                                           
*  * Author: Azharuddin Mohammad                                                 
*  * Description: 
*  *    CHAT-554: if the Provider is Closed within Trails, close Fiscal Agreements in CHATS and notify the case worker (creating Task record) so that all authorizations can be closed. 
*  *    CHAT-558: if the Quality Rating is changed for Provider in OEC then owner of each fiscal agreement is notified of the update in Provider .
*  *
*  * Version: 3.0
*  * Date: July 11, 2018
*  * Author: Gaurav Trivedi
*  * Description: CHATS-5640- OEC - Update OEC integration and trigger logic to populate "Level 1" for blank Quality rating values
*********************************************************************************************/
trigger ProviderTrigger on T_CHATS_PROVR_STATUS__c (after update,after insert, before insert, before update ) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('ProviderTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            //CHAT-905 : updates CDE_TYPE_FACILITY__c on Fiscal Agreements
            ProviderServices.updateFacilityTypeonFiscalAgreements(Trigger.NewMap,Trigger.OldMap);
            //CHAT-554; CHAT-558
            ProviderServices.provrUpdtsFromTrialsAndOEC(Trigger.NewMap, Trigger.OldMap);
            //CCCAP-3468
            ProviderServices.taskT116Creation(Trigger.New, Trigger.OldMap);
            ProviderServices.QEProvrCloseActiveFA(Trigger.newMap, Trigger.oldMap); // Added by Rishav for CCCAP-4768
        }
        if((Trigger.isInsert) || (Trigger.isUpdate)) {
            ProviderServices.updQualityRatingObject(Trigger.NewMap, Trigger.OldMap);
        }
    }
    if(Trigger.isBefore){
        if((Trigger.isInsert || Trigger.isUpdate)){
            //START CHATS-5640
            ProviderServices.setDefaultValue(Trigger.New);
            //END CHATS-5640
        }
    }
}