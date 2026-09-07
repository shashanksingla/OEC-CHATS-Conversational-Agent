/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           09/07/2017                                                          
*  @description    Handler class for County Plan Trigger                             
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
*  * Description: CHAT-1027  
*  
*  * Version: 3.0                                                                             
*  * Date: 13-Feb-2017                                                             
*  * Author: Azharuddin Mohammad
*  * Description: CHAT-2865, user should not be able to create multiple template with same name.
*  * if a template exists with same name and Template Indicator as checked, then user should not be able to create new county Rate plan for that county
*  
*  * Version: 4.0                                                                             
*  * Date: 05-30-2018                                                             
*  * Author: Gaurav Trivedi
*  * Description: Ristrict multiple county plans of Draft type for one county. Added as a part of CHATS-4910 bug fix
*********************************************************************************************/
public with sharing class CountyPlanServices {
    
    public static final String DRAFT = 'PEN';
    public static final String APPROVED = 'APV';
    public static final String NEED_REVISION = 'NRV';
    public static final String SUBMITTED = 'SUB';
    public static final String INPROGRESS= 'In Progress';
    public static final String NORMAL= 'Normal';
    public static boolean templateRecordUpdate= false;
    
       
    /**
    * @description Validate county plan status before deletion
    * @author Shubham Khandelwal
    * @date 09/07/2017
    * @param List<T_COUNTY_PLAN__c> trigger.old county plan list
    * @return void
    */
    public static void validateBeforeDelete(List<T_COUNTY_PLAN__c> oldCountyPlans){
        
        for(T_COUNTY_PLAN__c aCountyplan: oldCountyPlans){
            
            if(aCountyplan.CDE_STATUS__c != DRAFT && aCountyplan.County_Plan__c ==null ){
                aCountyplan.addError(Label.County_Plan_Delete_ErrorMessage);
            }
        }
    } 
    
    public static void createTaskForApprovalProcessHandler(List<T_COUNTY_PLAN__c> lstNewCountyPlans,Map<Id,T_COUNTY_PLAN__c> mapOldCountyPlans){
        Map<Id,T_COUNTY_PLAN__c> mapFilteredRejectedCountyPlans = new Map<Id,T_COUNTY_PLAN__c>();
        for(T_COUNTY_PLAN__c aCountyPlan : lstNewCountyPlans){
            if(aCountyplan.County_Plan__c == null && aCountyplan.CDE_STATUS__c != mapOldCountyPlans.get(aCountyplan.Id).CDE_STATUS__c && aCountyplan.CDE_STATUS__c == NEED_REVISION){
                mapFilteredRejectedCountyPlans.put(aCountyPlan.id,aCountyPlan);
            }
        }
        insertTasks(CountyApprovalProcessService.createTaskForRejectedCountyPlan(mapFilteredRejectedCountyPlans), mapFilteredRejectedCountyPlans);
    }
    
    public static void insertTasks(List<Task> lstCreatedTask, Map<Id,T_COUNTY_PLAN__c> mapFilteredRejectedCountyPlans){
        List<Database.SaveResult> inserTaskList = Database.insert(lstCreatedTask, false); 
        System.debug(inserTaskList);
        for(Integer i=0; i < inserTaskList.size() ; i++){
            if(!inserTaskList.get(i).isSuccess()){
                List<Database.Error> lstError = inserTaskList.get(i).getErrors();
                String failedDML;
                for(Database.Error error : lstError){
                    failedDML = failedDML + '\n' + error.getMessage();
                }
                Task failedTask = lstCreatedTask.get(i);
                T_COUNTY_PLAN__c countyRatePlan = mapFilteredRejectedCountyPlans.get(failedTask.WhatId);
                countyRatePlan.id.addError('Unable to create task for this County Plan Request : ' +failedDML);
            }
        }
    }
    
    
    /**
    * @description To check if the county rate exists with approved status, then the end date is populated with new plan begin date - 1.
    * @author Azharuddin Mohammad
    * @date 08-Dec-2017
    * @param List<List<T_COUNTY_PLAN__c> newCountyPlanList - county plan list
    * @return void
    */
    public static void effvEndDate(List<T_COUNTY_PLAN__c> newCountyPlanList,Map<Id,T_COUNTY_PLAN__c>oldCountyMap){
        Set<Id> countyPlanIds = new Set<Id>();
        Map<Id, T_COUNTY_PLAN__c> newCountyPlanRecords = new Map<Id, T_COUNTY_PLAN__c>();
        Map<Id, T_COUNTY_PLAN__c> oldCountyPlanRecords = new Map<Id, T_COUNTY_PLAN__c>();
        for(T_COUNTY_PLAN__c eachCountyPlan: newCountyPlanList){
            //added for CCCAP-13170
            if(!test.isRunningTest() && eachCountyPlan.CDE_STATUS__c!=oldCountyMap.get(eachCountyPlan.Id).CDE_STATUS__c && 
               (eachCountyPlan.CDE_STATUS__c == 'APV' ||  eachCountyPlan.CDE_STATUS__c =='NRV') 
               && eachCountyPlan.CDE_COUNTY__c != NULL && eachCountyPlan.Is_being_approved_by_Flow__c == false){
                   eachCountyPlan.addError('Please use the Approve or Reject County Plan button to take the approval action.');
                   continue;
               }
            if(eachCountyPlan.CDE_STATUS__c!=oldCountyMap.get(eachCountyPlan.Id).CDE_STATUS__c && eachCountyPlan.CDE_STATUS__c == 'APV' && eachCountyPlan.CDE_COUNTY__c != NULL && eachCountyPlan.DTE_BEGIN_EFFEV__c !=NULL && !eachCountyPlan.IND_COUNTY_PLAN_TEMPLT__c && eachCountyPlan.County_Plan__c==null){
                newCountyPlanRecords.put(eachCountyPlan.CDE_COUNTY__c , eachCountyPlan);
            }
            if(eachCountyPlan.Id !=NULL){
                countyPlanIds.add(eachCountyPlan.Id);
            }
        }
        
        for(T_COUNTY_PLAN__c oldCountyPlanRec: [select Id, CDE_COUNTY__c, DTE_END_EFFEV__c FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c IN:newCountyPlanRecords.keySet() AND CDE_STATUS__c = 'APV' AND Id NOT IN:countyPlanIds AND DTE_END_EFFEV__c = NULL AND IND_COUNTY_PLAN_TEMPLT__c= false]){
            if(newCountyPlanRecords.get(oldCountyPlanRec.CDE_COUNTY__c) != NULL){
                oldCountyPlanRec.DTE_END_EFFEV__c = newCountyPlanRecords.get(oldCountyPlanRec.CDE_COUNTY__c).DTE_BEGIN_EFFEV__c - 1;
                oldCountyPlanRecords.put(oldCountyPlanRec.Id, oldCountyPlanRec);
            }
        }
        if(oldCountyPlanRecords != NULL){
            update oldCountyPlanRecords.values();
        }
    }
    
    public static void validateCountyPlanTemplate(List<T_COUNTY_PLAN__c> newCountyPlanList) {
        map<Id, T_COUNTY_PLAN__c> countyTemplateMap = new map<Id, T_COUNTY_PLAN__c>();
        List<T_COUNTY_PLAN__c> newCheckedtemplatesList = new list<T_COUNTY_PLAN__c>();
        set<string> newPlanTemplates = new set<string>();
        Map<string, T_COUNTY_PLAN__c> prvPlanTemplates = new Map<string, T_COUNTY_PLAN__c>();
        if(!newCountyPlanList.isEmpty()){
            for(T_COUNTY_PLAN__c eachCountyPlan: newCountyPlanList){
                if( eachCountyPlan.County_Plan__c== null && eachCountyPlan.IND_COUNTY_PLAN_TEMPLT__c && eachCountyPlan.CDE_COUNTY_PLAN_TEMPLT__c !=null) {
                    newPlanTemplates.add(eachCountyPlan.CDE_COUNTY_PLAN_TEMPLT__c);
                    newCheckedtemplatesList.add(eachCountyPlan);
                }
            }    
        }
        if(!newPlanTemplates.isEmpty()){
            for(T_COUNTY_PLAN__c eachPrvTemplateCheck : [select Id, CDE_COUNTY_PLAN_TEMPLT__c, IND_COUNTY_PLAN_TEMPLT__c, CDE_COUNTY__c FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY_PLAN_TEMPLT__c IN:newPlanTemplates AND IND_COUNTY_PLAN_TEMPLT__c =:true ]){
                if(eachPrvTemplateCheck.CDE_COUNTY_PLAN_TEMPLT__c != null) {
                    prvPlanTemplates.put(eachPrvTemplateCheck.CDE_COUNTY_PLAN_TEMPLT__c,eachPrvTemplateCheck );
                }
            }
        }
        if(prvPlanTemplates != null) {
            for(T_COUNTY_PLAN__c eachSatisfiedTemplates : newCheckedtemplatesList) {
                if((eachSatisfiedTemplates !=null) && (prvPlanTemplates.keySet().contains(eachSatisfiedTemplates.CDE_COUNTY_PLAN_TEMPLT__c))
                  && prvPlanTemplates.get(eachSatisfiedTemplates.CDE_COUNTY_PLAN_TEMPLT__c).Id != eachSatisfiedTemplates.Id 
                  && prvPlanTemplates.get(eachSatisfiedTemplates.CDE_COUNTY_PLAN_TEMPLT__c).CDE_COUNTY__c == eachSatisfiedTemplates.CDE_COUNTY__c){
                    T_COUNTY_PLAN__c errorTemplate = new T_COUNTY_PLAN__c();
                    errorTemplate = eachSatisfiedTemplates;
                    errorTemplate.addError('Template already exists for the County');
                }
            }
        }
    }
    
    public static void validateEffectiveBeginEndDateOfExistingCountyPlans(List<T_COUNTY_PLAN__c> newCountyPlanList, Map<Id, T_COUNTY_PLAN__c> oldMap){
        Set<Id> countyIdSet = new Set<Id>();
        Set<Id> newCountyPlanIdForEdit = new Set<Id>();
        Map<Id, List<T_COUNTY_PLAN__c>> countyIdToExistingCountyPlansMap = new Map<Id, List<T_COUNTY_PLAN__c>>();
        
        if(!newCountyPlanList.isEmpty()){
            for(T_COUNTY_PLAN__c eachCountyPlan: newCountyPlanList){
                if(eachCountyPlan.CDE_COUNTY__c != null){
                    if(oldMap ==  null){
                        countyIdSet.add(eachCountyPlan.CDE_COUNTY__c);
                    }
                    else if(oldMap !=  null && oldMap.containskey(eachCountyPlan.Id) && eachCountyPlan.DTE_BEGIN_EFFEV__c != oldMap.get(eachCountyPlan.Id).DTE_BEGIN_EFFEV__c){
                        countyIdSet.add(eachCountyPlan.CDE_COUNTY__c);
                        newCountyPlanIdForEdit.add(eachCountyPlan.Id);
                    }
                }
            }
        }
        
        if(!countyIdSet.isEmpty()){
            List<T_COUNTY_PLAN__c> existingCountyPlans = [SELECT Id, Name, DTE_BEGIN_EFFEV__c, DTE_END_EFFEV__c, CDE_COUNTY__c FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c in :countyIdSet AND IND_COUNTY_PLAN_TEMPLT__c= false];
            if(!existingCountyPlans.isEmpty()){
                for(T_COUNTY_PLAN__c eachCountyPlan : existingCountyPlans){
                    if(!newCountyPlanIdForEdit.contains(eachCountyPlan.Id)){
                        if(countyIdToExistingCountyPlansMap.containsKey(eachCountyPlan.CDE_COUNTY__c)){
                            List<T_COUNTY_PLAN__c> tempCountyPlanList = countyIdToExistingCountyPlansMap.get(eachCountyPlan.CDE_COUNTY__c);
                            tempCountyPlanList.add(eachCountyPlan);
                            countyIdToExistingCountyPlansMap.put(eachCountyPlan.CDE_COUNTY__c, tempCountyPlanList);
                        }
                        else{
                            countyIdToExistingCountyPlansMap.put(eachCountyPlan.CDE_COUNTY__c, new List<T_COUNTY_PLAN__c>{eachCountyPlan});
                        }
                    }
                }
            }
        }
        
        if(!countyIdToExistingCountyPlansMap.isEmpty()){
            for(T_COUNTY_PLAN__c newCountyPlan : newCountyPlanList){
                if(newCountyPlan.CDE_COUNTY__c != null && countyIdToExistingCountyPlansMap.containsKey(newCountyPlan.CDE_COUNTY__c)){
                    for(T_COUNTY_PLAN__c existingCountyPlan : countyIdToExistingCountyPlansMap.get(newCountyPlan.CDE_COUNTY__c)){
                        if(existingCountyPlan.DTE_END_EFFEV__c != null && (newCountyPlan.DTE_BEGIN_EFFEV__c <= existingCountyPlan.DTE_BEGIN_EFFEV__c || newCountyPlan.DTE_BEGIN_EFFEV__c <= existingCountyPlan.DTE_END_EFFEV__c)){
                            newCountyPlan.addError('New County Plan can not be created prior to existing County Plan.');
                        }
                        else if(existingCountyPlan.DTE_END_EFFEV__c == null && newCountyPlan.DTE_BEGIN_EFFEV__c <= existingCountyPlan.DTE_BEGIN_EFFEV__c){
                            newCountyPlan.addError('New County Plan can not be created prior to existing County Plan.');
                        }
                    }
                }
            }
        }
    }
    public static LightningServerResponse submitForApproval(String recordId){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CountyPlanServices','Method__c'=>'submitForApproval'};
            Boolean isSuccess;
        System.savePoint sp = Database.setSavePoint();
        String message;
        Boolean isValidNote =false;
        List<T_COUNTY_PLAN_NOTES__c> CountyPlanNotes=[Select Id,Name,IDN_COUNTY_PLAN__c,IDN_COUNTY_PLAN__r.Id from T_COUNTY_PLAN_NOTES__c where IDN_COUNTY_PLAN__r.Id=:recordId];
        if(CountyPlanNotes.size()>0){ 
            try{
                Map<String, Schema.SObjectField> fieldsMap = T_COUNTY_PLAN__c.sObjectType.getDescribe().fields.getMap();
                String query = 'SELECT ';
                query += String.join(fieldsMap.keySet(), ', ');
                query += ' FROM T_COUNTY_PLAN__c WHERE Id = :recordId';                
                T_COUNTY_PLAN__c countyPlan = Database.query(query);
                
                if(countyPlan.Flow_Completed__c){
                    // added submission insertion logic for CCCAP-13170
                    T_COUNTY_Plan__c submissionCP = CountyPlanApprovalAction.SubmissionInstance(countyPlan,Date.Today());
                    submissionCP.DTE_BEGIN_EFFEV__c = null;
                    Insert submissionCP;
                    //CCCAP-13170 changes end
                    Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
                    req1.setComments('Submitting request for approval.');
                    req1.setObjectId(recordId);
                    req1.setSubmitterId(UserInfo.getUserId());
                    req1.setProcessDefinitionNameOrId('County_Plan_Approval_Process');
                    // Submit the approval request for the account
                    Approval.ProcessResult result = Approval.process(req1);
                    // Verify the result
                    System.assert(result.isSuccess());
                    isSuccess=true;
                    message= Label.SubmitForApprovalSuccess;
                }
                else{
                    isSuccess=false;
                    message= Label.ComleteFlowForAproval;
                }
            }
            catch(DMLException e){
                isSuccess=false;
                database.rollback(sp);
                message=String.valueOf(e.getDmlMessage(0));
                ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
            }
        }else{
            isSuccess=false;
            message=System.Label.CountyPlanNoteErrorMsg;
        }
        
        return new LightningServerResponse(isSuccess, message, null);
    }

    /**
    * @description Ristrict multiple county plans of Draft type for one county. Added as a part of CHATS-4910 bug fix
    * @author Gaurav Trivedi
    * @date 05-30-2018
    * @param List<T_COUNTY_PLAN__c> trigger.new county plan list
    * @return void
    */
    public static void ristrictMultipleDraft(List<T_COUNTY_PLAN__c> newCountyList){
        Boolean throwError = false;
        Set<Id> countyIdSet = new Set<Id>();
        for(T_COUNTY_PLAN__c countyPlan : newCountyList){
            countyIdSet.add(countyPlan.CDE_COUNTY__c);
        }
        if(!countyIdSet.isEmpty()){
            List<AggregateResult> draftCountyPlan = [SELECT Count(Id), CDE_COUNTY__c FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c <> null AND CDE_COUNTY__c IN : countyIdSet AND CDE_STATUS__c = : DRAFT AND IND_COUNTY_PLAN_TEMPLT__c= false GROUP BY CDE_COUNTY__c];
            if(!draftCountyPlan.isEmpty()){
                for(AggregateResult draftCounty: draftCountyPlan){
                    if((Integer.valueOf(draftCounty.get('expr0')) > 1 && trigger.isUpdate) || trigger.isInsert){
                        throwError = true;
                    }
                        
                }
                if(throwError){
                    for(T_COUNTY_PLAN__c countyPlan : newCountyList){
                        if(countyPlan.County_Plan__c==null && !countyPlan.IND_COUNTY_PLAN_TEMPLT__c){
                            countyPlan.addError('You can not add multiple draft version of County Plan');
                        }
                    }
                }
            }
        }
    }
    
/* @description Assign County Plan submitted task to County Plan Approver and Template Admin role uers. Added as a part of CHATS-5387 bug fix
* @author Bharadwaj Gaddam
* @date 06-25-2018
* @param List<T_COUNTY_PLAN__c> trigger.new county plan list and Map<Id,T_COUNTY_PLAN__c> Trigger.oldMap old Map
* @return void
*/       
    
    public static void createTasksforRolesAfterSubmission(List<T_COUNTY_PLAN__c> countyPlanNewList,Map<Id,T_COUNTY_PLAN__c> countyPlanOldMap) {
        Set<Id> countyPlanIdSet = new Set<Id>();
        List<Task> tasklist = new List<Task>();
        Date duedate=System.Today().addDays(5);
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CountyPlanServices','Method__c'=>'createTasksforRolesAfterSubmission'};
        
        for(T_COUNTY_PLAN__c countyPlanEach:countyPlanNewList) {
            if(countyPlanEach.CDE_STATUS__c != countyPlanOldMap.get(countyPlanEach.Id).CDE_STATUS__c && countyPlanEach.CDE_STATUS__c == SUBMITTED) {
                countyPlanIdSet.add(countyPlanEach.Id);            
            }
        }
        if(countyPlanIdSet.size()>0) {
            for(User userEach:[Select Id from User where UserRole.Name IN(:Label.County_Plan_Approver,:Label.Template_Administrator)]) {
                for(Id countyPlanId:countyPlanIdSet) {
                    tasklist.add(new Task(OwnerId=userEach.Id,WhatId=countyPlanId,Subject=Label.Approve_County_Plan,
                    Description=Label.County_has_submitted_a_County_Plan_for_Approval,ActivityDate=duedate,
                    Status=INPROGRESS,Priority=NORMAL));
                }
            }        
        }
        
        if(tasklist.size()>0) {
            //Database.DMLOptions dm = new Database.DMLOptions();
            //dm.EmailHeader.triggerUserEmail=true;
            //dm.optAllOrNone = false;
            //GenericDMLHandler.insertRecordsWithEmailTrigger(tasklist,dm,methodInfo);
            GenericDMLHandler.insertRecords(tasklist,false,methodInfo);     
        }
        
    }
    public static void updateTemplateRecord(List<T_COUNTY_PLAN__c> countyPlanNewList,Map<Id,T_COUNTY_PLAN__c> countyPlanOldMap) {
        List<T_COUNTY_PLAN__c> lstApprovedCountyPlans = new List<T_COUNTY_PLAN__c>();
        Set<String> setCounty = new Set<String>();
        for(T_COUNTY_PLAN__c countyPlan : countyPlanNewList){
            if(countyPlan.County_Plan__c == null && countyPlan.CDE_STATUS__c == APPROVED && 
               countyPlan.CDE_STATUS__c != countyPlanOldMap.get(countyPlan.Id).CDE_STATUS__c){
                lstApprovedCountyPlans.add(countyPlan);
                setCounty.add(countyPlan.CDE_COUNTY__c);
            }
        }
        if(!lstApprovedCountyPlans.isEmpty()){
            Map<String,T_COUNTY_PLAN__c> mapCountyPlanTemplates = new Map<String,T_COUNTY_PLAN__c>();
            for(T_COUNTY_PLAN__c countyPlan :[Select Id,CDE_COUNTY__c,IND_COUNTY_PLAN_TEMPLT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_COUNTY_PLAN__c where CDE_COUNTY__c in:setCounty AND IND_COUNTY_PLAN_TEMPLT__c = true ] ){
                mapCountyPlanTemplates.put(countyPlan.CDE_COUNTY__c,countyPlan);
            }
            List<T_COUNTY_PLAN__c> lstTemplatetoUpdate = new List<T_COUNTY_PLAN__c>();
            List<T_COUNTY_PLAN__c> lstTemplatetoInsert = new List<T_COUNTY_PLAN__c>();
            for(T_COUNTY_PLAN__c countyPlan : lstApprovedCountyPlans){
                T_COUNTY_PLAN__c countyPlanClone = countyPlan.clone();
                if(mapCountyPlanTemplates.containsKey(countyPlan.CDE_COUNTY__c)){
                    countyPlanClone.Id = mapCountyPlanTemplates.get(countyPlan.CDE_COUNTY__c).Id;
                    countyPlanClone.IND_COUNTY_PLAN_TEMPLT__c = mapCountyPlanTemplates.get(countyPlan.CDE_COUNTY__c).IND_COUNTY_PLAN_TEMPLT__c;
                    countyPlanClone.DTE_BEGIN_EFFEV__c = mapCountyPlanTemplates.get(countyPlan.CDE_COUNTY__c).DTE_BEGIN_EFFEV__c;
                    countyPlanClone.DTE_END_EFFEV__c = mapCountyPlanTemplates.get(countyPlan.CDE_COUNTY__c).DTE_END_EFFEV__c;
                    countyPlanClone.CDE_STATUS__c = APPROVED;
                    countyPlanClone.Is_Conditionally_Approved__c = false;
                    lstTemplatetoUpdate.add(countyPlanClone);
                }
                else{
                    countyPlanClone.DTE_BEGIN_EFFEV__c = null;
                    countyPlanClone.DTE_END_EFFEV__c = null;
                    countyPlanClone.CDE_STATUS__c = APPROVED;
                    countyPlanClone.IND_COUNTY_PLAN_TEMPLT__c= true;
                    countyPlanClone.Is_Conditionally_Approved__c = false;
                    lstTemplatetoInsert.add(countyPlanClone);
                }
            }
        if(!lstTemplatetoUpdate.isEmpty()){
            templateRecordUpdate = true; 
                try{
        GenericDMLHandler.updateRecords(lstTemplatetoUpdate,new Map<String,Object>{'Class__c'=>'CountyPlanServices','Method__c'=>'updateTemplateRecord'});
        }
        catch(Exception e){
            for(T_COUNTY_PLAN__c countyPlan : lstApprovedCountyPlans){
            countyPlan.addError('Template Records can be modified/checked by Template Administrators only');
            }
        } 
                 
            }
            if(!lstTemplatetoInsert.isEmpty()){
                templateRecordUpdate = true; 
                GenericDMLHandler.insertRecords(lstTemplatetoInsert,new Map<String,Object>{'Class__c'=>'CountyPlanServices','Method__c'=>'updateTemplateRecord'}); 
            }
        }
    }
    //added by Nikita for CCCAP-13170
    @AuraEnabled
    public static LightningServerResponse checkIfNewChanges(String recordId, Boolean isNewComponent){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        T_COUNTY_PLAN__c countyPlanRec = [SELECT Id, DTE_BEGIN_EFFEV__c FROM T_COUNTY_PLAN__c WHERE Id=:recordId LIMIT 1];
        if(countyPlanRec != null){
            Boolean isbeginAfter = CompareCP_CRP_lwc.IsDateAfter_15June2025(countyPlanRec.DTE_BEGIN_EFFEV__c);
            objectData.put('showButton',(isNewComponent && isbeginAfter) || (!isNewComponent && !isbeginAfter));
            isSuccessful = true;
        }
        return new LightningServerResponse(isSuccessful,'Done',objectData);
    }
}