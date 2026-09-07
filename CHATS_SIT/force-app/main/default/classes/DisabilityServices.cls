/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/26/2017                                                          
*  @description    Handler class for DisabilityTrigger
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 17-Nov-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: CHAT-379
*  * 1. Populate T_INDIV_DSBLTY.IND_REQMT_WORK_MEET_ABLE with 'N' if Client is not the primary caretaker AND is having age 13-19(includes 13 but excludes 19) and does not have a relationship of mother, father, spouse, common law husband, common law wife, husband, wife, live-in companion else 'Y'.
*  * 2. Enforce required validation for T_INDIV_DSBLTY.CDE_LENGTH_DSBLTY if individual is 19 or older AND/OR is the primary caretaker OR is younger than 19 and has a relationship of mother, father, spouse, common law husband, common law wife, husband, wife, live-in companion.
*  *
*  * Version: 2.0                                                                             
*  * Date: 01-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * JIRA Ticket: CHAT-1197, CHAT-1198
*  * Version: 3.0                                                                             
*  * Date: 29-05-2018                                                             
*  * Author: Shubham Jain
*  * Added With Sharing as this class throws validation errors or updates records in before trigger context
*********************************************************************************************/
public with sharing class DisabilityServices {
    public static void updateFields(List<T_INDIV_DSBLTY__c> indivDisabilities){
        Map<Id,String> indivIdToIndivMeetWorkReq = new Map<Id,String>();
        Map<Id,Boolean> indivIdToIncapacitationLengthRequired = new Map<Id,Boolean>();
        Map<String, Boolean> indivToIsPeakData = new Map<String, Boolean>();
        //Removed unused variable on 5/13/2018 BG  
        // Collecting all the Individual Ids in the form of map with Individual Id as key & default value for IND_REQMT_WORK_MEET_ABLE__c as value
        for(T_INDIV_DSBLTY__c indivDisability:indivDisabilities){
            if(String.isNotEmpty(indivDisability.IDN_CLIENT__c)){
                indivIdToIndivMeetWorkReq.put(indivDisability.IDN_CLIENT__c, 'Y');
                indivIdToIncapacitationLengthRequired.put(indivDisability.IDN_CLIENT__c, false);
            }
        }   
        
        Set<String> indivIdsWhereHowVerifiedRequired = new Set<String>();
        
        for(T_SBSD_INDIV__c individual:[SELECT Id, Age__c, Is_Peak_Data__c, Has_Allowed_Relationship__c, Is_Primary_Parent_Caretaker__c FROM T_SBSD_INDIV__c WHERE Id IN :indivIdToIndivMeetWorkReq.keySet()]){
            indivToIsPeakData.put(individual.Id, individual.Is_Peak_Data__c);
            if(!individual.Is_Primary_Parent_Caretaker__c && individual.Age__c< Integer.valueOf(Label.Teen_Parent_Age_Limit)  && !individual.Has_Allowed_Relationship__c){
                indivIdToIndivMeetWorkReq.put(individual.Id, 'N');
            } 
            if(individual.Age__c>18 || individual.Is_Primary_Parent_Caretaker__c || (individual.Age__c<Integer.valueOf(Label.Teen_Parent_Age_Limit)  && individual.Has_Allowed_Relationship__c)){
                indivIdToIncapacitationLengthRequired.put(individual.Id, true);
            }
            if(!individual.Is_Primary_Parent_Caretaker__c && individual.Age__c<Integer.valueOf(Label.Teen_Parent_Age_Limit)  && individual.Age__c>=13 && !individual.Has_Allowed_Relationship__c){
                indivIdsWhereHowVerifiedRequired.add(individual.Id);
            }
        }
        
        
        // Populating IND_REQMT_WORK_MEET_ABLE__c and showing required error for CDE_LENGTH_DSBLTY__c if empty
        for(T_INDIV_DSBLTY__c indivDisability:indivDisabilities){
            if(String.isNotEmpty(indivDisability.IDN_CLIENT__c)){
                indivDisability.IND_REQMT_WORK_MEET_ABLE__c = indivIdToIndivMeetWorkReq.get(indivDisability.IDN_CLIENT__c);
                if(indivIdToIncapacitationLengthRequired.get(indivDisability.IDN_CLIENT__c) && String.isEmpty(indivDisability.CDE_LENGTH_DSBLTY__c) && !indivToIsPeakData.get(indivDisability.IDN_CLIENT__c)){
                    indivDisability.addError('Please provide Incapacitation Length');
                }
            }
            //Start: CHAT-1197,1198
            if(indivDisability.IND_REQMT_WORK_MEET_ABLE__c=='Y' && String.isEmpty(indivDisability.IND_CC_GIVE_ABLE__c) && !indivToIsPeakData.get(indivDisability.IDN_CLIENT__c)){
                indivDisability.IND_CC_GIVE_ABLE__c.addError('Please provide: Able to Take care of Children?');                    
            }
            system.debug(indivDisability);
            system.debug(indivIdsWhereHowVerifiedRequired);
            if(indivIdsWhereHowVerifiedRequired.contains(indivDisability.IDN_CLIENT__c) && String.isEmpty(indivDisability.CDE_SOURCE_DSBLTY_CHILD__c) && !indivToIsPeakData.get(indivDisability.IDN_CLIENT__c)){
                indivDisability.CDE_SOURCE_DSBLTY_CHILD__c.addError('Please provide: How Verified');                    
            }
            //End: CHAT-1197,1198
        }
        
    }
}