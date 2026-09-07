/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/7/2017                                                          
*  @description    Primary Activity Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 7-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                    
*  * Description: Initial version 
*                1. checks individual and case for an existing Primary Activity with no enddate if it exists then trigger will not allow new Primary Activity in the system
*                2. checks individual and case for an existing Primary Activity with type as GED or POS if it exists then trigger will not allow new Primary Activity with same types
*                3. checks individual for an existing Primary Activity with type as JS and utilized weeks defined in the county plan for that year then trigger will not allow new Primary Activity with same type
*                4. checks individual and case for an existing Primary Activity with no enddate if it existen the trigger will not allow other Primary Activity to update with empty enddate
*                5. checks individual and case for an existing Primary Activity with begin date and end date if it exists then trigger will not allow new/upadte Primary Activity with begin date falls on or between existing Primary activity begin date and end date
*                
*                   
*  * Version: 2.0                                                                             
*  * Date: 5-JAN-2018                                                             
*  * Author: Bharadwaj Gaddam                                                    
*  * Description: creates Primary Activity Counter records for new Primary Activity records                                                                                
*********************************************************************************************
*  * Version: 2.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Diya Chaudhary                                                     
*  * Description: Copying Salesforce ID to External Id field 
*********************************************************************************************/

trigger PrimaryActivityTrigger on T_PRIM_ACTV__c (before insert,before update,after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('PrimaryActivityTrigger')) {
        return; //rest of the lines will not be executed
    }
           
     if(Trigger.isBefore){
          Map<string,T_PRIM_ACTV__c> primActivIndivMap=PrimaryActivityServices.primaryActivityIndividualMap(Trigger.new);
          if(Trigger.isInsert){
            PrimaryActivityServices.primActBeforeInsertCheckBeginDate(primActivIndivMap);
            PrimaryActivityServices.primActBeforeInsertCheckNullEnddate(primActivIndivMap);
            PrimaryActivityServices.primActBeforeInsertCheckType(primActivIndivMap);
            //PrimaryActivityServices.primActBeforeInsertCheckJobsearchUtilize(primActivIndivMap);            
        }
        if(Trigger.isUpdate) {
            PrimaryActivityServices.primActBeforeUpdateCheckNullEnddate(primActivIndivMap,Trigger.newMap.keySet()); 
            PrimaryActivityServices.primActBeforeUpdateCheckBeginDate(primActivIndivMap,Trigger.newMap.keySet()); 
        
        }
        
    }   
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //CHAT-1129
            PrimaryActivityServices.createPrimaryActivityCounter(Trigger.New);
            
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_PRIM_ACTV__c where Id=:trigger.newMap.keySet()],true);
        }
        
        //CHATS-5148 Defect Fix to update Eligiblity Date Changed on Case
        CaseLastUpdatedServices.updateCaseLastChangeFromCaseIds(
            CaseLastUpdatedServices.pluckIds(trigger.new, 'IDN_CASE__c')
        );
    }
}