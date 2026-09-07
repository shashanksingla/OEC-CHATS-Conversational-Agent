/************************************************************************
*  @author         Deloitte Consulting LLP.
*  @date           10/31/2017
*  @description    Handler class for County Plan Approval Task creation
*  Modification Log:
*
*  * Version: 1.0
*  * Date: 31-Oct-2017
*  * Author: Shubham Khandelwal
*  * Description: Initial version
************************************************************************/
public with sharing class CountyApprovalProcessService {
    
    public static final String ACTION = Label.ACTION;
    public static final String COUNTY_PLAN_TASK_SUBJECT = Label.COUNTY_PLAN_TASK_SUBJECT;
    public static final String COUNTY_PLAN_TASK_DESCRIPTION = Label.County_Plan_Reject_Task_Comments;
    public static final String COUNTY_RATE_PLAN_TASK_SUBJECT = Label.COUNTY_RATE_PLAN_TASK_SUBJECT;
    public static final String COUNTY_RATE_PLAN_TASK_DESCRIPTION = Label.County_Rate_Plan_Reject_Task_Comments;
    public static final String REJECTED = Label.Rejected;
    
    /* 
    Description: Create Task for Submitter of Rejected County plan
    Author: Shubham Khandelwal
    Date: 11/06/2017
    Params: Map<Id,T_COUNTY_PLAN__c>
    Returns: List<Task>
    */
    public static List<Task> createTaskForRejectedCountyPlan(Map<Id,T_COUNTY_PLAN__c> mapFilteredRejectedCountyPlans){
        List<ProcessInstance> lstApprovalProcesses = [SELECT CompletedDate,CreatedById,CreatedDate,
                                                      ElapsedTimeInDays,ElapsedTimeInHours,ElapsedTimeInMinutes,
                                                      Id,IsDeleted,LastActorId,LastModifiedById,
                                                      LastModifiedDate,ProcessDefinitionId,Status,SubmittedById,SystemModstamp,
                                                      TargetObjectId FROM ProcessInstance WHERE CompletedDate = TODAY  
                                                      AND TargetObjectId IN :mapFilteredRejectedCountyPlans.keySet() AND Status =:REJECTED WITH SECURITY_ENFORCED];
        List<Task> lstTaskToInsert = createTaskForRejectedApprovalProcesses(lstApprovalProcesses ,COUNTY_PLAN_TASK_SUBJECT,COUNTY_PLAN_TASK_DESCRIPTION);
        return lstTaskToInsert;
    }
    
    /* 
    Description: Create Task for Submitter of Rejected County plan
    Author: Shubham Khandelwal
    Date: 11/08/2017
    Params: Map<Id, T_COUNTY_PLAN__c>
    Returns: List<Task>
    */
    public static List<Task> createTaskForRejectedCountyRatePlan(Map<Id,T_COUNTY_RATE__c> mapFilteredRejectedCountyRatePlans){
        List<ProcessInstance> lstApprovalProcesses = [SELECT CompletedDate,CreatedById,CreatedDate,
                                                      ElapsedTimeInDays,ElapsedTimeInHours,ElapsedTimeInMinutes,
                                                      Id,IsDeleted,LastActorId,LastModifiedById,
                                                      LastModifiedDate,ProcessDefinitionId,Status,SubmittedById,SystemModstamp,
                                                      TargetObjectId FROM ProcessInstance WHERE CompletedDate = TODAY  
                                                      AND TargetObjectId IN :mapFilteredRejectedCountyRatePlans.keySet() AND Status =:REJECTED WITH SECURITY_ENFORCED];
        List<Task> lstTaskToInsert = createTaskForRejectedApprovalProcesses(lstApprovalProcesses,COUNTY_RATE_PLAN_TASK_SUBJECT ,COUNTY_RATE_PLAN_TASK_DESCRIPTION);
        return lstTaskToInsert;
    }
    
    /* 
    Description: Create Task for Process Instances
    Author: Shubham Khandelwal
    Date: 11/08/2017
    Params: List<ProcessInstance>, String taskSubject, String taskDescription
    Returns: List<Task>
    */
    public static List<Task> createTaskForRejectedApprovalProcesses(List<ProcessInstance> lstRejectedApprovalProcesses , String taskSubject, String taskDescription){
        List<Task> lstTaskToCreate = new List<Task>();
        Task rejectedTask;
        for(ProcessInstance approvalProcessInstance : lstRejectedApprovalProcesses){
            rejectedTask = new Task();
            rejectedTask.WhatId = approvalProcessInstance.TargetObjectId;
            rejectedTask.OwnerId = approvalProcessInstance.SubmittedById;
            rejectedTask.Description = taskDescription;
            rejectedTask.Status = System.Label.NOT_STARTED;
            rejectedTask.Subject = taskSubject;
            rejectedTask.ActivityDate = System.today() + 2;
            lstTaskToCreate.add(rejectedTask);
        }
        return lstTaskToCreate;
    }
}