/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/25/2022                                                          
*  @description    On Child Enrollment record update create T557 AND T556 task                       
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 25-Oct-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version  
*********************************************************************************************/


trigger ChildEnrollmentTrigger on T_CHATS_CHILD_ENROLLMENT__c (after insert,after update) {
if(TriggersOnOffServices.triggerStatus('ChildEnrollmentTrigger')) {
        return; //rest of the lines will not be executed
    }
    /* commented out for CCCAP-15890 by Shashank on 08/18/26
    if(Trigger.isInsert){
     ChildEnrollmentServices.upsertEnrollRecord(Trigger.new);
    }*/
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            ChildEnrollmentServices.createT556Tasks(Trigger.new,trigger.oldMap);
            ChildEnrollmentServices.createT557Tasks(Trigger.new,trigger.oldMap);
        }
         if(Trigger.isInsert){
            CopySalesforceId.stampSalesforceIdToExternalId(
                [SELECT Id, IDN_EXTNL__c FROM T_CHATS_CHILD_ENROLLMENT__c WHERE Id = :Trigger.newMap.keySet()],
                true
            );
            List<T_CHATS_CHILD_ENROLLMENT__c> enrollsForATS = new List<T_CHATS_CHILD_ENROLLMENT__c>();
            for (T_CHATS_CHILD_ENROLLMENT__c enroll : Trigger.new) {
                if (String.isBlank(enroll.Source__c)) {
                    enrollsForATS.add(enroll);
                }
            }
            if (!enrollsForATS.isEmpty()) {
                ChildEnrollmentServices.insertATSRecords(enrollsForATS);
            }
        }
    }
}