/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/03/2017                                                          
*  @description    Authorization Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 03-Nov-2017                                                             
*  * Author: Vineet Srivastava                                                      
*  * Description: Initial version                                                 
*   
*  * Version: 2.0                                                                             
*  * Date: 12-20-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Checks DTE_BEGIN_EFFV_AUTH__c before insert/update and throws below errors
*                Error1: Authorization_Begin_Date_cannot_be_before_the_Child_Eligibility_Begin_date
*                Error2: Authorization_Begin_Date_cannot_be_after_the_Child_Eligibility_End_date
*   
*  * Version: 3.0                                                                             
*  * Date: 1-19-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Copying Salesforce ID to External Id field
*   
*  * Version: 4.0                                                                             
*  * Date: 3-07-2018                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Checking inactive fiscal agreement records and Waitlisted waitList for authorization records before insert and update.
*  * Removed Deeply Nested If Statements during Code review changes BG 5/12/2018
*********************************************************************************************/
trigger AuthorizationTrigger on T_AUTH__c (before insert,before update,after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('AuthorizationTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(Trigger.isBefore){
    List<T_AUTH__c> fiscalActiveList = new List<T_AUTH__c>();
            if(Trigger.isUpdate){
                for(T_AUTH__c o:trigger.new)
                {
                    if( o.AMT_ACTV_AUTH__c != trigger.oldmap.get(o.Id).AMT_ACTV_AUTH__c ||
                       o.AMT_TRANSP_AUTH__c != trigger.oldmap.get(o.Id).AMT_TRANSP_AUTH__c ||
                       o.AMT_RGSTR_AUTH__c != trigger.oldmap.get(o.Id).AMT_RGSTR_AUTH__c ||
                       o.CDE_REL_PROVR__c != trigger.oldmap.get(o.Id).CDE_REL_PROVR__c ||
                       o.CDE_TYPE_VERIF__c != trigger.oldmap.get(o.Id).CDE_TYPE_VERIF__c ||
                       o.CDE_SOURCE_VRFYD_IMMU__c != trigger.oldmap.get(o.Id).CDE_SOURCE_VRFYD_IMMU__c ||
                       o.CDE_IMM__c != trigger.oldmap.get(o.Id).CDE_IMM__c 
                      )
                    {
                        fiscalActiveList.add(o);
                    }               
                }
                if(fiscalActiveList.size()>0) {
                    AuthorizationServices.fiscalActiveCheck(fiscalActiveList);
                }
                AuthorizationServices.handleUPKFieldsOnEnrollmentChange(Trigger.new, Trigger.oldMap); //CCCAP-15329
            }
        if(Trigger.isInsert){
            AuthorizationServices.duplicateCheck(Trigger.new);
            AuthorizationServices.handleUPKFieldsOnEnrollmentChange(Trigger.new, null); //CCCAP-15329
            //AuthorizationServices.waitListCheck(Trigger.new);
        }
        
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //copying salesforce Id to External Id
            CopySalesforceId.stampSalesforceIdToExternalId([select Id,IDN_EXTNL__c from T_AUTH__c where Id=:trigger.newMap.keySet()],true);
            AuthorizationServices.createChildEnrollmentRecord(Trigger.new);
            AuthorizationServices.markReverseRefOnAuthCase(Trigger.newMap); // added for CCCAP-10162 for CHATS Reverse mapping
        }
          if(Trigger.isUpdate){
            // Process all records in bulk using the new bulkified method , made bulkified for CCCAP-13427
            AuthorizationStatusController.terminateSCAssociationRecords(Trigger.new, Trigger.oldMap);
          }
        
    }
}