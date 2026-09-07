/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/07/2017                                                          
*  @description    County Rate Plan Trigger                             
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
*  * Description: CHAT-1051, Populate Effv End Date of previous record with new record begindate - 1 
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
trigger CountyRatePlanTrigger on T_COUNTY_RATE__c (before insert, before update, before delete,after insert,after update) {
    //Check trigger active on/off
    if(TriggersOnOffServices.triggerStatus('CountyRatePlanTrigger')) {
        return; //rest of the lines will not be executed
    }
    if(CountyRatePlanServices.templateRecordUpdate){
        if(Trigger.isAfter)
        	CountyRatePlanServices.templateRecordUpdate = false;
        return;  
    }
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            CountyRatePlanServices.validateBeforeDelete(Trigger.old);
        }
        if(Trigger.isUpdate){
            //CHAT-1051 - version2
            CountyRatePlanServices.effvEndDate(Trigger.new,Trigger.oldMap);
            countyRatePlanServices.validateEffectiveBeginEndDateOfExistingCountyRatePlans(Trigger.New, Trigger.oldMap);
        }
        if((Trigger.isInsert)|| (Trigger.isUpdate)){
            countyRatePlanServices.validateCountyRatePlanTemplate(Trigger.New);
            countyRatePlanServices.ristrictMultipleDraft(Trigger.New);
        }
        if(Trigger.isInsert){
            countyRatePlanServices.validateEffectiveBeginEndDateOfExistingCountyRatePlans(Trigger.New, null);
        }
    } else if(Trigger.isAfter){
         if(Trigger.isUpdate){
            CountyRatePlanServices.createCountyRateAmountRecords(CountyRatePlanServices.filterCountyRatePlanTemplateRecords(Trigger.new),Trigger.NewMap, Trigger.OldMap);
            CountyRatePlanServices.cloneRateTemplateRecord(CountyRatePlanServices.filterCountyRatePlans(Trigger.new),Trigger.NewMap, Trigger.OldMap);
            //Create County Rate Plan task on Rejection.
            CountyRatePlanServices.createTaskForApprovalProcessHandler(trigger.new,trigger.oldMap);
            //CHATS-3824
            CountyRatePlanServices.insertATSRecord(trigger.new);
            //Create County Rate Plan task on Submission.
            CountyRatePlanServices.createTasksforRolesAfterSubmission(trigger.new,trigger.oldMap);
            //CCCAP-1511: Update Temlate record on Approval
            CountyRatePlanServices.updateTemplateRecord(trigger.new,trigger.oldMap);
        }
    }
}