public with sharing class CountyRatePlanApprovalAction {
    private static Map<Id,String> countyRatePlanIDwithAction = new Map<ID,String>();
    public static Boolean skipNullifying = false;
    private static string failError{get;set;}
    
    public class InputWrapper {
        public InputWrapper() {}
        @InvocableVariable(required=true)
        public Id recordId;
        
        @InvocableVariable(required=true)
        public String actionType; // 'Approve', 'Partial Approve', 'Reject'
        
        @InvocableVariable(required=true)
        public String comments;
    }
    
    public class OutputWrapper {
        @InvocableVariable
        public String message;
        @InvocableVariable
        public String messageType;//CCCAP-14224
    }
    @InvocableMethod(label='Handle Approval with Status' description='Handles Approve, Reject, and Partial Approve from Flow')
    public static List<OutputWrapper> handleApproval(List<InputWrapper> inputList) {
        List<T_COUNTY_RATE__C> upsertRecords = new list<T_COUNTY_RATE__C>();
        List<OutputWrapper> results = new List<OutputWrapper>();
        List<Approval.ProcessWorkitemRequest> appRequests = new List<Approval.ProcessWorkitemRequest>();
        // Track which inputs have valid workitems for proper output alignment
        Map<Integer, Boolean> inputHasWorkItem = new Map<Integer, Boolean>();
        // Map to track input index to appRequest index for result alignment
        List<Integer> appRequestToInputIndex = new List<Integer>();
        savepoint sp = database.setsavepoint();
        try{
            for (InputWrapper input : inputList){
                if(input.recordId != null){
                    countyRatePlanIDwithAction.put(input.recordId,input.actionType);
                }
            }
            Map<Id, ProcessInstanceWorkitem> recordToWorkItemMap = new Map<Id, ProcessInstanceWorkitem>();
            for(ProcessInstanceWorkitem workItem : [SELECT Id, ProcessInstance.TargetObjectId 
                                                    FROM ProcessInstanceWorkitem 
                                                    WHERE ProcessInstance.TargetObjectId in :countyRatePlanIDwithAction.keyset()]){
                                                        recordToWorkItemMap.put(workItem.ProcessInstance.TargetObjectId, workItem);
                                                    }
            // Initialize results list with one output per input
            for(Integer i = 0; i < inputList.size(); i++) {
                results.add(new OutputWrapper());
                inputHasWorkItem.put(i, false);
            }
            
            for (Integer i = 0; i < inputList.size(); i++) {
                InputWrapper input = inputList[i];
                ProcessInstanceWorkitem workItem = recordToWorkItemMap.get(input.recordId);
                if (workItem == null) {
                    results[i].message = 'No pending approval found for the record.';
                    results[i].messageType = 'error';
                    countyRatePlanIDwithAction.remove(input.recordId);
                    continue;
                }
                inputHasWorkItem.put(i, true);
                // Set action
                String action = input.actionType == 'Reject' ? 'Reject' : 'Approve';
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                req.setComments(input.comments);
                req.setAction(action);
                appRequests.add(req);
                appRequestToInputIndex.add(i);
                T_COUNTY_RATE__C crp = new T_COUNTY_RATE__C(Id=input.recordId,Is_being_approved_by_Flow__c=true);
                if (input.actionType == 'Conditionally Approve') {
                    crp.Is_Conditionally_Approved__c = true;
                    crp.DTE_END_EFFV_RATE__c = null;
                }else if(input.actionType == 'Approve'){
                    crp.Is_Conditionally_Approved__c = false;
                    crp.DTE_END_EFFV_RATE__c = null;
                }
                upsertRecords.add(crp);
            }
            if(!upsertRecords.isEmpty() && Schema.sObjectType.T_COUNTY_RATE__C.isUpdateable()&& 
               Schema.sObjectType.T_COUNTY_RATE__C.fields.Is_being_approved_by_Flow__c.isUpdateable()){
                update upsertRecords;
                List<Approval.ProcessResult> appResults = Approval.process(appRequests);
                for(Integer i=0;i<appResults.size();i++){
                    Approval.ProcessResult result = appResults[i];
                    Integer originalInputIndex = appRequestToInputIndex[i];
                    if(!result.isSuccess()){
                        database.rollback(sp);
                        countyRatePlanIDwithAction.remove(inputList[originalInputIndex].recordId);
                        String details ='';
                        if(result.getErrors() != null && !result.getErrors().isEmpty()){
                           details = 'Details: '+ result.getErrors()[0].getMessage();
                        }
                           results[originalInputIndex].message = 'Failed to process approval.'+details;
                        results[originalInputIndex].message = 'Failed to process approval.';
                        results[originalInputIndex].messageType = 'error';
                    }else{
                        results[originalInputIndex].message = 'County Rate Plan approval completed successfully.';
                        results[originalInputIndex].messageType = 'success';
                    }
                }
                Boolean isSuccessful=handleCRP_Updates();
                if(!isSuccessful){
                    database.rollback(sp);
                    // Update all successful results to show the error
                    for(Integer i = 0; i < results.size(); i++) {
                        if(results[i].messageType == 'success' || results[i].messageType == null) {
                            results[i].message = failError;
                            results[i].messageType = 'error';
                        }
                    }
                }
            }
            else if(upsertRecords.isEmpty()){
                // All inputs had no pending approval - results already populated
                // No additional action needed
            }
            else{
                database.rollback(sp);
                // Update all results to show permission error
                for(Integer i = 0; i < results.size(); i++) {
                    if(inputHasWorkItem.get(i) == true) {
                        results[i].message = 'Insufficient permissions to update County Rate Plan records.';
                        results[i].messageType = 'error';
                    }
                }
            }
        }catch(DMLException e){
            database.rollback(sp);
            // Update all results to show the exception error
            for(Integer i = 0; i < results.size(); i++) {
                results[i].message = 'Failed to process approval. Details: ' + e.getDmlMessage(0);
                results[i].messageType = 'error';
            }
        }catch(Exception Ex){
            database.rollback(sp);
            // Update all results to show the exception error
            for(Integer i = 0; i < results.size(); i++) {
                results[i].message = 'Failed to process approval. Details: ' + Ex.getMessage();
                results[i].messageType = 'error';
            }
        }
        return results;
    }
    private static Boolean handleCRP_Updates(){
        Boolean isSuccessful = true; //CCCAP-14224
        boolean isInsert=false;
        Map<Id,Date> lastSubmittedDate = new Map<Id,Date>();    
        List<T_COUNTY_RATE__C> upsertRecords = new list<T_COUNTY_RATE__C>();
        Set<Id> deleteFeedbacksForCounties = new Set<Id>();
        
        if(!countyRatePlanIDwithAction.isEmpty()){
            Map<String, Schema.SObjectField> fieldsMap = T_COUNTY_RATE__c.sObjectType.getDescribe().fields.getMap();
            set<Id> currentIdSet = countyRatePlanIDwithAction.keyset();
            String query = 'SELECT ';
            query += String.join(fieldsMap.keySet(), ', ');
            query+= ' ,( SELECT Id,DTE_BEGIN_EFFV_RATE__c,CDE_STATUS__c from CRP_Submissions__r order by createddate desc limit 1) ';
            query += ' FROM T_COUNTY_RATE__c WHERE Id IN :currentIdSet';
            
            for(processInstanceStep psp: [SELECT Id, ProcessInstance.TargetObjectId,CreatedDate FROM ProcessInstanceStep where 
                                          ProcessInstance.TargetObjectId IN: countyRatePlanIDwithAction.keyset() and stepStatus='Started' order by createddate desc]){
                                              if(!lastSubmittedDate.containsKey(psp.ProcessInstance.TargetObjectId)){
                                                  lastSubmittedDate.put(psp.ProcessInstance.TargetObjectId,Date.valueOf(psp.CreatedDate));
                                              }    
                                          }
            for(T_COUNTY_RATE__C recordToUpdate: Database.query(query)){
                String status;
                string actionType = countyRatePlanIDwithAction.get(recordToUpdate.Id);
                T_County_Rate__c childSubmissionRecord;
                if (actionType == 'Conditionally Approve') {
                    status = 'APV';
                    recordToUpdate.Is_being_approved_by_Flow__c = false;
                    recordToUpdate.Bypass_Validation_On__c = system.now();
                    upsertRecords.add(recordToUpdate);
                }else if(actionType == 'Approve'){
                    status = 'APV';
                    recordToUpdate.Is_being_approved_by_Flow__c = false;
                    recordToUpdate.Bypass_Validation_On__c = system.now();
                    upsertRecords.add(recordToUpdate);
                    deleteFeedbacksForCounties.add(recordToUpdate.IDN_COUNTY__c);
                }else if(actionType == 'Reject'){
                    status = 'NRV';
                    recordToUpdate.Bypass_Validation_On__c = system.now();
                    recordToUpdate.Is_being_approved_by_Flow__c = false;
                    upsertRecords.add(recordToUpdate);
                }
                if(status != null){
                    /* checking here to update the submission record with Approval decision if exist or insert submission record based on last submitted date*/
                    if(countyRatePlanIDwithAction.containsKey(recordToUpdate.Id) && recordToUpdate.CRP_Submissions__r!=null && !recordToUpdate.CRP_Submissions__r.isEmpty()){
                        childSubmissionRecord = recordToUpdate.CRP_Submissions__r[0];
                        childSubmissionRecord.DTE_BEGIN_EFFV_RATE__c = Date.today();
                        childSubmissionRecord.CDE_STATUS__c = status;
                        childSubmissionRecord.Is_Conditionally_Approved__c = recordToUpdate.Is_Conditionally_Approved__c;
                        upsertRecords.add(childSubmissionRecord);
                    }else if(lastSubmittedDate.containsKey(recordToUpdate.Id)){
                        childSubmissionRecord = (T_County_Rate__c)SubmissionInstance(recordToUpdate,Date.valueOf(lastSubmittedDate.get(recordToUpdate.Id)));
                        childSubmissionRecord.CDE_STATUS__c = status;
                        childSubmissionRecord.DTE_BEGIN_EFFV_RATE__c = Date.today();
                        childSubmissionRecord.Is_Conditionally_Approved__c = recordToUpdate.Is_Conditionally_Approved__c;
                        isInsert = true;
                        upsertRecords.add(childSubmissionRecord);
                    }
                }
            }
            if(!upsertRecords.isEmpty()){
                if(isInsert && 
                   (!Schema.sObjectType.T_COUNTY_RATE__C.isCreateable() &&
                    !Schema.sObjectType.T_COUNTY_RATE__C.fields.Is_being_approved_by_Flow__c.isCreateable() ||
                    !Schema.sObjectType.T_COUNTY_RATE__C.fields.Is_Conditionally_Approved__c.isCreateable() ||
                    !Schema.sObjectType.T_COUNTY_RATE__C.fields.DTE_END_EFFV_RATE__c.isCreateable() ||
                    !Schema.sObjectType.T_COUNTY_RATE__C.fields.DTE_BEGIN_EFFV_RATE__c.isCreateable() ||
                    !Schema.sObjectType.T_COUNTY_RATE__C.fields.CDE_STATUS__c.isCreateable())) {
                        isSuccessful = false;
                        failError = 'Insufficient field level permissions to create County Rate Plan records.';
                    }
                if(!Schema.sObjectType.T_COUNTY_RATE__C.isUpdateable() && 
                   !Schema.sObjectType.T_COUNTY_RATE__C.fields.is_being_approved_by_flow__c.isUpdateable() ||
                   !Schema.sObjectType.T_COUNTY_RATE__C.fields.Is_Conditionally_Approved__c.isUpdateable() ||
                   !Schema.sObjectType.T_COUNTY_RATE__C.fields.DTE_END_EFFV_RATE__c.isUpdateable() ||
                   !Schema.sObjectType.T_COUNTY_RATE__C.fields.DTE_BEGIN_EFFV_RATE__c.isUpdateable() ||
                   !Schema.sObjectType.T_COUNTY_RATE__C.fields.CDE_STATUS__c.isUpdateable()) {
                       isSuccessful = false;
                       failError = 'Insufficient field level permissions to update County Rate Plan records.';
                   }
                upsert upsertRecords;                    
            }
            if(isSuccessful && !deleteFeedbacksForCounties.isEmpty()){
                if(Schema.sObjectType.CP_CRP_Feedback__c.isDeletable()){
                    delete [select id from CP_CRP_Feedback__c where County__c IN:deleteFeedbacksForCounties and feedback_type__c IN ('CRP','CRP_Rate')];    
                }else{
                    isSuccessful = false;
                    failError = 'Insufficient permissions to delete County Rate Plan feedback records.';
                }
            }
        }
        return isSuccessful;
    }    
    public static T_COUNTY_RATE__c SubmissionInstance(T_COUNTY_RATE__c CRP,Date actionDate){
        T_COUNTY_RATE__c SubmissionInstance = CRP.clone(true, true, false, false);
        SubmissionInstance.IND_RATE_PLAN_TEMPLT__c=false;
        SubmissionInstance.Id = null;
        if(skipNullifying == false){
            SubmissionInstance.IDN_COUNTY__c =null;
            SubmissionInstance.County_Rate_Plan__c =CRP.Id;
            SubmissionInstance.Action_Date__c =actionDate;
            SubmissionInstance.CDE_STATUS__c ='SUB';
            SubmissionInstance.Is_being_approved_by_Flow__c = false;
        }
        return SubmissionInstance;
    }
}