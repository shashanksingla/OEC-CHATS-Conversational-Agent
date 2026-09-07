/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/07/2017                                                          
*  @description    County Plan Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-Sept-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Initial version                                                 
*   
*  * Version: 2.0                                                                             
*  * Date: 08-Dec-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: CHAT-1027  No end date until a new plan is created. Then set the end date to be 1 day before the Effective Begin Date of the new plan, when the plan is approved.
*  * 
*  * Version: 3.0                                                                             
*  * Date: 13-Feb-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: CHAT-2865, user should not be able to create multiple template with same name.
*  * if a template exists with same name and Template Indicator as checked, then user should not be able to create new county Rate plan for that county
*  * 
*  * Version: 4.0                                                                             
*  * Date: 05-30-2018                                                             
*  * Author: Gaurav Trivedi
*  * Description: Ristrict multiple county plans of Draft type for one county. Added ristrictMultipleDraft method as a part of CHATS-4910 bug fix
*********************************************************************************************/
trigger CountyPlanTrigger on T_COUNTY_PLAN__c (before insert, before update, before delete, after insert, after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CountyPlanTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(CountyPlanServices.templateRecordUpdate ){
        CountyPlanServices.templateRecordUpdate = false;
      return;  
    }
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            CountyPlanServices.validateBeforeDelete(Trigger.old);
        }
        //CHAT-1027 : Event Based Trigger
        if(Trigger.isUpdate){
            CountyPlanServices.effvEndDate(Trigger.new,Trigger.oldMap);
            CountyPlanServices.validateEffectiveBeginEndDateOfExistingCountyPlans(Trigger.New, Trigger.oldMap);
        }
        if((Trigger.isInsert)|| (Trigger.isUpdate)){
            CountyPlanServices.validateCountyPlanTemplate(Trigger.New); 
            CountyPlanServices.ristrictMultipleDraft(Trigger.New);   
        }
        if(Trigger.isInsert){
            CountyPlanServices.validateEffectiveBeginEndDateOfExistingCountyPlans(Trigger.New, null);
        }
     }else if(Trigger.isAfter){
        if(Trigger.isUpdate){
            CountyPlanServices.createTaskForApprovalProcessHandler(trigger.new,trigger.oldMap);
             //Create County Plan task on Submission.
            CountyPlanServices.createTasksforRolesAfterSubmission(trigger.new,trigger.oldMap);
            //CCCAP-1511- Update template record on Approval(Always to be called at the last)
            CountyPlanServices.updateTemplateRecord(trigger.new,trigger.oldMap);
        }
    }
}