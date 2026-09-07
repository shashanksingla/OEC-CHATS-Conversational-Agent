/*************************************************************
Class Name      - caseReviewApexController
Test Class      - caseReviewApexController_Test
Description     - Common controller class for all Case Review components
Author          - Rishav Maji
Requirement     - Project 425, JIRA CCCAP-4771
Important Notes -
* Do not add 'WITH SECURITY_ENFORCED' in queries, it causes access insufficiency for non-admin users.
  Code needs to run in Admin privilege; security is taken care in code itself.
**************************************************************/
public with sharing class caseReviewApexController implements IRequest {
    private static String newProgram{get;set;}
    private static string caseTypeLabel{get;set;} //CCCAP-12378
    private static Boolean calledInternally = false;
    private static String staticSampleMonth{get;set;}
    private static String staticSampleYear{get;set;}
    public String jsonParam;
    private static Map<String, Object> requestObj;

    public class responseWrapper {
        @AuraEnabled
        public Review_Question__c questionRec {get; set;}
        @AuraEnabled
        public Case_Review_Response__c responseRec {get; set;}
        @AuraEnabled
        public List<Map<String, String>> NAReasonOptions {get; set;}
        @AuraEnabled
        public List<Map<String, String>> elementQuestionOptions {get; set;}
    }
    
    class CaseReviewWrapper {
        Decimal totalAmountPaid;
        Set<String> subPmtDltExtIds;
        CaseReviewWrapper(){}
        CaseReviewWrapper(Decimal totalAmountPaid, Set<String> subPmtDltExtIds){
            totalAmountPaid = totalAmountPaid;
            subPmtDltExtIds = subPmtDltExtIds;
        }
    }

    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }
        if (methodName == 'checkEligibility') {
            Boolean isDelete = requestObj.get('isDelete') != null ? (Boolean)requestObj.get('isDelete') : false;
            response = checkEligibility(getMapValue('recordId'), isDelete);
        } else if (methodName == 'deleteCaseReview') {
            response = deleteCaseReview(getMapValue('recordId'));
        } else if (methodName == 'resubmitLastReview') {
            response = resubmitLastReview(getMapValue('recordId'));
        } else if (methodName == 'getParentFeeSubsidyAmount') {
            response = getParentFeeSubsidyAmount(getMapValue('recordId'), getMapValue('sampleMonth'), getMapValue('sampleYear'), getMapValue('screenMode'));
        } else if (methodName == 'getInitData') {
            response = getInitData(getMapValue('recordId'), getMapValue('screenMode'));
        } else if (methodName == 'saveCaseReview') {
            Case_Review__c caseReviewObj = (Case_Review__c)JSON.deserialize(JSON.serialize(requestObj.get('caseReviewObj')), Case_Review__c.class);
            List<Object> responseWrapperList = (List<Object>)requestObj.get('responseWrapperList');
            response = saveCaseReview(caseReviewObj, responseWrapperList, getMapValue('screenMode'), getMapValue('methodName'));
        } else if (methodName == 'handleSampleMonthUpdates') {
            response = handleSampleMonthUpdates(getMapValue('recordId'), getMapValue('sampleMonth'), getMapValue('sampleYear'), getMapValue('screenMode'), getMapValue('caseId'));
        } else if (methodName == 'deleteCaseReviewButton') {
            response = deleteCaseReviewButton(getMapValue('recordId'));
        } else if (methodName == 'getVFBaseURL') {
            Map<String, Object> objectData = new Map<String, Object>();
            objectData.put('sfUrl', getVFBaseURL());
            response = new LightningServerResponse(true, '', objectData);
        } else if (methodName == 'checkRecordAccess') {
            response = checkRecordAccess(getMapValue('recordId'));
        } else if (methodName == 'submitToReviewee') {
            response = submitToReviewee(getMapValue('revieweeId'), getMapValue('recordId'));
        } else if (methodName == 'sumbitForStateReversal') {
            response = sumbitForStateReversal(getMapValue('recordId'), getMapValue('taskComment'));
        } else if (methodName == 'generateTaskComment') {
            response = generateTaskComment(getMapValue('recordId'));
        }
        return response;
    }

    private static String getMapValue(String fieldName){
        return (String)requestObj.get(fieldName);
    }

    @auraEnabled
    public static LightningServerResponse handleSampleMonthUpdates(String recordId, String sampleMonth, String sampleYear, String screenMode, String caseId){
        Map<String, Object> objectData = new Map<String, Object>();
       Boolean isSuccessful = true;
        string message;
        string caseType;
        try{
            if(screenMode!='VIEW'){
                try{
                    caseType = Test.isRunningTest() ? 'TF' : caseReviewApexController.getChildCareProgramBySampleMonthYear(caseId,sampleMonth,sampleYear);
                }
                catch(Exception e){
                    GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'caseReviewApexController', Method__c = 'getInitData', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'getInitData','Class__c'=>'caseReviewApexController'} , new list<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c'}); // Added field names parameter for CCCAP-8307
                }
                objectData.put('caseType', caseType);
                //CCCAP-12378
                if(caseType!=null){
                    getCaseTypeLabelOnCaseType(caseType); 
                    objectData.put('caseTypeLabel',caseTypeLabel);
                }
                //end CCCAP-12378
                if(caseType != 'LI' && caseType != 'TF'){
                    objectData.put('programNotExpected',true);
                    isSuccessful = false;
                    message = 'A review cannot be conducted on this program type.';
                }
               newProgram = caseType;
                staticSampleMonth = sampleMonth;
                staticSampleYear = sampleYear;
            }
            if(isSuccessful){
                calledInternally =true;
                return getInitData(recordId,screenMode); 
            }
        }catch(Exception e){
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
        //end CCCAP-12156
    public static Map<String,Object> getOneTimeData(Map<String, Object> objectData,String recordId, String screenMode){
        Boolean isSuccessful = true;
        String message = '';
        List<Map<String, String>> allCauseOptions = new List<Map<String, String>>();
        Schema.DescribeFieldResult causeField = Case_Review_Response__c.CaseReview_Cause1__c.getDescribe();
        List<Schema.PicklistEntry> causePicklistValues = causeField.getPicklistValues();
        for(Schema.PicklistEntry pe : causePicklistValues){
            allCauseOptions.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
        }
        objectData.put('allCauseOptions', allCauseOptions);
        
        List<Map<String, String>> allErrorOptions = new List<Map<String, String>>();
        Schema.DescribeFieldResult errorField = Case_Review_Response__c.CaseReview_Error1__c.getDescribe();
        List<Schema.PicklistEntry> errorPicklistValues = errorField.getPicklistValues();
        for(Schema.PicklistEntry pe : errorPicklistValues){
            allErrorOptions.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
        }
        objectData.put('allErrorOptions', allErrorOptions);
            
        return objectData;
    }
    @AuraEnabled
    public static LightningServerResponse getInitData(String recordId, String screenMode){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            String caseType;
            if(calledInternally == false){
                objectData = getOneTimeData(objectData,recordId,screenMode);
            }
            List<caseReviewApexController.responseWrapper> responseWrapperList = new List<caseReviewApexController.responseWrapper>();
            Schema.DescribeFieldResult NAReasonField = Review_Question__c.NA_Reason_Options__c.getDescribe();
            List<Schema.PicklistEntry> NAReasonPicklistValues = NAReasonField.getPicklistValues();
            Map<String, String> NAReasonMap = new Map<String, String>();
            for(Schema.PicklistEntry pe : NAReasonPicklistValues){
                NAReasonMap.put(pe.getValue(), pe.getLabel());
            }
            
            Schema.DescribeFieldResult elementField = Case_Review_Response__c.CaseReview_QuestionMain__c.getDescribe();
            List<Schema.PicklistEntry> elementPicklistValues = elementField.getPicklistValues();
            
            /* NEW / EDIT / VIEW flow logic below */
            String sobjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            objectData.put('sobjectName', sobjectName);
            if(sobjectName == 'T_SBSD_CASE__c'){ // NEW
                objectData.put('screenMode', 'NEW');
                User u = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                objectData.put('reviewerName', u.Name);
                objectData.put('reviewerTitle', u.Profile.Name);
                T_SBSD_CASE__c caseRecord = [SELECT Id, Name, NAM_PRIMARY_CARETAKER__c, CDE_COUNTY__r.Name, Program_Type__c, DTE_APPLN__c, DTE_REDET_CASE__c, OwnerId,
                                             (SELECT toLabel(CDE_STATUS_CASE__c), toLabel(CDE_MODE_CASE__c) 
                                              FROM T_SBSD_CASE10__r 
                                              WHERE DTE_END_EFFV__c >= Today OR DTE_END_EFFV__c = null 
                                              ORDER BY DTE_BEGIN_EFFV__c, createdDate DESC NULLS FIRST 
                                              LIMIT 1), (SELECT Sample_Month__c, Sample_Year__c FROM Case_Reviews__r)
                                             FROM T_SBSD_CASE__c WHERE Id = :recordId Limit 1];
                objectData.put('caseRecord', caseRecord);
                if(String.isNotBlank(staticSampleMonth) && String.isNotBlank(staticSampleYear)){ //CCCAP-15694
                    objectData.put('redetDateAsOfSampleMonth', getRedetDateAsOfSampleMonth(caseRecord.Id, Integer.valueOf(staticSampleMonth), Integer.valueOf(staticSampleYear)));
                }
                caseType= newProgram;
                objectData.put('caseType', caseType);
                //CCCAP-12378
            if(caseType!=null){
                getCaseTypeLabelOnCaseType(caseType); 
                objectData.put('caseTypeLabel',caseTypeLabel);
            }
                //end CCCAP-12378
                List<Case_Review__c> existingReview = [SELECT Id, createdDate, createdBy.Name, createdBy.Profile.Name, Program_Type__c, Closure_Date__c, Parent_Fee__c, IsSubmitted__c, Review_Status__c, Sample_Month__c,
                                                       Case__c, Reviewer_Name__c, Reviewer_Title__c, Recent_Eligibility_Detrm__c, Eligibility_Period_From__c, Eligibility_Period_To__c, Sample_Year__c,
                                                       Improper_Payment__c, Improper_Payment_Amount__c, Subsidy_Amount_Paid__c, Correct_Subsidy_Amount__c, Improper_Payment_Type__c
                                                       FROM Case_Review__c WHERE Case__c = :recordId ORDER BY createdDate DESC LIMIT 1];
                if(!existingReview.isEmpty()){
                    Date dateBefore6Months = System.today().addMonths(-6);
                    objectData.put('showInitialForm', existingReview[0].createdDate.date() > dateBefore6Months ? true : false);
                } else {
                    objectData.put('showInitialForm', false);
                }
                objectData.put('showCaseOwnerForm', caseRecord?.OwnerId == u?.Id ? true : false); // Added by Rishav for CCCAP-7603
                if(caseType!=null){
                    for(Review_Question__c qn : [SELECT Id, Order__c, Element__c, Question__c, Review_Requirement__c, NA_Reason_Options__c, Hide_Errors_and_Causes__c
                                                 FROM Review_Question__c 
                                                 WHERE Review_Type__c = 'Case' AND Case_Type__c = :caseType AND Active__c = true
                                                 ORDER BY Order__c ASC]){
                                                     Case_Review_Response__c rsp = new Case_Review_Response__c(Review_Question__c = qn.Id);
                                                     List<Map<String, String>> NAReasonList = new List<Map<String, String>>();
                                                     NAReasonList.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
                                                     if(!String.isBlank(qn.NA_Reason_Options__c)){
                                                         List<String> options = qn.NA_Reason_Options__c.split(';');
                                                         options.sort();
                                                         for(String option : options){
                                                             NAReasonList.add(new Map<String, String> {'value'=>option, 'label'=>NAReasonMap.get(option)});
                                                         }
                                                     }
                                                     List<Map<String, String>> elementOptionsList = new List<Map<String, String>>();
                                                     elementOptionsList.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
                                                     for(Schema.PicklistEntry pe : elementPicklistValues){
                                                         if(pe.getValue() != 'NA' || !String.isBlank(qn.NA_Reason_Options__c)){
                                                             elementOptionsList.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
                                                         }
                                                     }
                                                     caseReviewApexController.responseWrapper wrp = new caseReviewApexController.responseWrapper();
                                                     wrp.questionRec = qn;
                                                     wrp.responseRec = rsp;
                                                     wrp.NAReasonOptions = NAReasonList;
                                                     wrp.elementQuestionOptions = elementOptionsList;
                                                     responseWrapperList.add(wrp);
                                                 }
                    objectData.put('responseWrapperList', responseWrapperList);
                }
            } else {
                List<Case_Review__c> existingReview = new List<Case_Review__c>();
                Map<Id, Case_Review_Response__c> questionRespMap = new Map<Id, Case_Review_Response__c>();
                Integer errorCount = 0;
                if(screenMode == 'VIEW'){ // VIEW
                    objectData.put('screenMode', 'VIEW');
                    existingReview = [SELECT Id, toLabel(Review_Status__c), Reviewer_Name__c, Reviewer_Title__c, toLabel(Improper_Payment__c), Improper_Payment_Amount__c, Closure_Date__c, Case__c,
                                      Eligibility_Period_From__c, Eligibility_Period_To__c, toLabel(Recent_Eligibility_Detrm__c), createdDate, createdBy.Name, createdBy.Profile.Name,
                                      toLabel(Sample_Month__c), Sample_Year__c, Parent_Fee__c, Subsidy_Amount_Paid__c, IsSubmitted__c, Correct_Subsidy_Amount__c, toLabel(Improper_Payment_Type__c), Program_Type__c
                                      FROM Case_Review__c WHERE Id = :recordId ORDER BY createdDate DESC LIMIT 1];
                    for(Case_Review_Response__c resp : [SELECT Id, toLabel(CaseReview_QuestionMain__c), toLabel(CaseReview_Error1__c), toLabel(CaseReview_Cause1__c),
                                                        toLabel(CaseReview_Error2__c), toLabel(CaseReview_Cause2__c), toLabel(CaseReview_Error3__c), toLabel(CaseReview_Cause3__c),
                                                        toLabel(CaseReview_Error4__c), toLabel(CaseReview_Cause4__c), Observation_Details_Comments__c, toLabel(Action_Required__c),
                                                        Action_Taken__c, Action_Date__c, Case_Review__c, Review_Question__c, toLabel(CaseReview_NA_Reason__c), toLabel(Causes_Payment_Error__c)
                                                        FROM Case_Review_Response__c WHERE Case_Review__c = :existingReview[0].Id]){
                                                            questionRespMap.put(resp.Review_Question__c, resp);
                                                        }
                } else { // EDIT
                    objectData.put('screenMode', 'EDIT');
                    existingReview = [SELECT Id, createdDate, createdBy.Name, createdBy.Profile.Name, Closure_Date__c, Parent_Fee__c, IsSubmitted__c, Review_Status__c, Sample_Month__c,
                                      Case__c, Reviewer_Name__c, Reviewer_Title__c, Recent_Eligibility_Detrm__c, Eligibility_Period_From__c, Eligibility_Period_To__c, Sample_Year__c,
                                      Improper_Payment__c, Improper_Payment_Amount__c, Subsidy_Amount_Paid__c, Correct_Subsidy_Amount__c, Improper_Payment_Type__c, Program_Type__c
                                      FROM Case_Review__c WHERE Id = :recordId ORDER BY createdDate DESC LIMIT 1];
                    for(Case_Review_Response__c resp : [SELECT Id, CaseReview_QuestionMain__c, CaseReview_Error1__c, CaseReview_Cause1__c,
                                                        CaseReview_Error2__c, CaseReview_Cause2__c, CaseReview_Error3__c, CaseReview_Cause3__c,
                                                        CaseReview_Error4__c, CaseReview_Cause4__c, Observation_Details_Comments__c, Action_Required__c,
                                                        Action_Taken__c, Action_Date__c, Case_Review__c, Review_Question__c, CaseReview_NA_Reason__c, Causes_Payment_Error__c
                                                        FROM Case_Review_Response__c WHERE Case_Review__c = :existingReview[0].Id]){
                                                            questionRespMap.put(resp.Review_Question__c, resp);
                                                            if(resp.CaseReview_QuestionMain__c == 'NO'){
                                                                errorCount++;
                                                            }
                                                        }
                    objectData.put('errorCount', errorCount);
                }
                if(calledInternally == false){
                    objectData.put('showInitialForm', false);
                    objectData.put('showCaseOwnerForm', false); // Added by Rishav for CCCAP-7603
                    objectData.put('caseReviewObj', existingReview[0]);
                    objectData.put('reviewerName', existingReview[0].createdBy.Name);
                    objectData.put('reviewerTitle', existingReview[0].createdBy.Profile.Name);
                    T_SBSD_CASE__c caseRecord = [SELECT Id, Name, NAM_PRIMARY_CARETAKER__c, CDE_COUNTY__r.Name, DTE_APPLN__c, Program_Type__c, DTE_REDET_CASE__c,
                                                 (SELECT toLabel(CDE_STATUS_CASE__c), toLabel(CDE_MODE_CASE__c) 
                                                  FROM T_SBSD_CASE10__r 
                                                  WHERE DTE_END_EFFV__c >= Today OR DTE_END_EFFV__c = null 
                                                  ORDER BY DTE_BEGIN_EFFV__c, createdDate DESC NULLS FIRST 
                                                  LIMIT 1)
                                                 FROM T_SBSD_CASE__c WHERE Id = :existingReview[0].Case__c Limit 1];
                    objectData.put('caseRecord', caseRecord);
                }
                if(String.isNotBlank(staticSampleMonth) && String.isNotBlank(staticSampleYear) && existingReview[0]?.Case__c != null){ //CCCAP-15694
                    objectData.put('redetDateAsOfSampleMonth', getRedetDateAsOfSampleMonth(existingReview[0].Case__c, Integer.valueOf(staticSampleMonth), Integer.valueOf(staticSampleYear)));
                }
                caseType = newProgram!=null?newProgram : existingReview[0]?.Program_Type__c;
                objectData.put('caseType', caseType);
                //CCCAP-12378
                if(caseType!=null){ // added null check to avoid npe as part of CCCAP-14457
                    getCaseTypeLabelOnCaseType(caseType); 
                    objectData.put('caseTypeLabel',caseTypeLabel);}
                //end CCCAP-12378
                if(String.isEmpty(caseType)){
                    GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'caseReviewApexController', Method__c = 'getInitData', Exception_Message__c = 'Program type to fetch review questions is Null', Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'getInitData','Class__c'=>'caseReviewApexController'}, new list<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c'}); // Added field names parameter for CCCAP-8307
                }
                if(calledInternally == true && caseType!=null ){
                    for(Review_Question__c qn : [SELECT Id, Order__c, Element__c, Question__c, Review_Requirement__c, NA_Reason_Options__c, Hide_Errors_and_Causes__c 
                                                 FROM Review_Question__c 
                                                 WHERE Review_Type__c = 'Case' AND Case_Type__c = :caseType AND Active__c = true
                                                 ORDER BY Order__c ASC]){
                                                     List<Map<String, String>> NAReasonList = new List<Map<String, String>>();
                                                     NAReasonList.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
                                                     if(!String.isBlank(qn.NA_Reason_Options__c)){
                                                         List<String> options = qn.NA_Reason_Options__c.split(';');
                                                         options.sort();
                                                         for(String option : options){
                                                             NAReasonList.add(new Map<String, String> {'value'=>option, 'label'=>NAReasonMap.get(option)});
                                                         }
                                                     }
                                                     List<Map<String, String>> elementOptionsList = new List<Map<String, String>>();
                                                     elementOptionsList.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
                                                     for(Schema.PicklistEntry pe : elementPicklistValues){
                                                         if(pe.getValue() != 'NA' || !String.isBlank(qn.NA_Reason_Options__c)){
                                                             elementOptionsList.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
                                                         }
                                                     }
                                                     caseReviewApexController.responseWrapper wrp = new caseReviewApexController.responseWrapper();
                                                     wrp.questionRec = qn;
                                                     if(questionRespMap.containsKey(qn.Id)){
                                                         wrp.responseRec = questionRespMap.get(qn.Id);
                                                     }
                                                     else{
                                                         Case_Review_Response__c rsp = new Case_Review_Response__c(Review_Question__c = qn.Id);
                                                         wrp.responseRec = rsp;
                                                     }
                                                     wrp.NAReasonOptions = NAReasonList;
                                                     wrp.elementQuestionOptions = elementOptionsList;
                                                     responseWrapperList.add(wrp);
                                                 }
                    objectData.put('responseWrapperList', responseWrapperList);
                }
            }
        }catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse resubmitLastReview(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Case_Review__c existingReview = [SELECT Id, createdDate, createdBy.Name, createdBy.Profile.Name, Program_Type__c, Closure_Date__c, Parent_Fee__c, IsSubmitted__c, Review_Status__c, Sample_Month__c,
                                             Case__c, Reviewer_Name__c, Reviewer_Title__c, Recent_Eligibility_Detrm__c, Eligibility_Period_From__c, Eligibility_Period_To__c, Sample_Year__c,
                                             Improper_Payment__c, Improper_Payment_Amount__c, Subsidy_Amount_Paid__c, Correct_Subsidy_Amount__c, Improper_Payment_Type__c, Case__r.CDE_COUNTY__r.Name
                                             FROM Case_Review__c WHERE Case__c = :recordId ORDER BY createdDate DESC LIMIT 1];
            Case_Review__c newReview = existingReview.clone();
            list<String> fieldNames = new list<String>{'Program_Type__c', 'Closure_Date__c', 'Parent_Fee__c', 'IsSubmitted__c', 'Review_Status__c', 'Sample_Month__c',
                                             'Case__c', 'Reviewer_Name__c', 'Reviewer_Title__c', 'Recent_Eligibility_Detrm__c', 'Eligibility_Period_From__c', 'Eligibility_Period_To__c', 'Sample_Year__c',
                                             'Improper_Payment__c', 'Improper_Payment_Amount__c', 'Subsidy_Amount_Paid__c', 'Correct_Subsidy_Amount__c', 'Improper_Payment_Type__c', 'Case__r.CDE_COUNTY__r.Name', 'IsSubmitted__c','No_Change_Indicator__c' }; // Added for CCCAP-8307
            if(Schema.sObjectType.Case_Review__c.fields.IsSubmitted__c.isCreateable() && Case_Review__c.getSObjectType().getDescribe().isCreateable()){
                newReview.IsSubmitted__c = true;
                newReview.No_Change_Indicator__c ='N'; // added for CCCAP-11863 by Shashank
                GenericDMLHandler.insertRecords(new List<Case_Review__c>{newReview}, new Map<String, Object>{'Method__c'=>'resubmitLastReview 1', 'Class__c'=>'caseReviewApexController', 'byPassObjects'=>new Set<String>{'Case_Review__c'}}, fieldNames); // Added fieldNames and bypassobjects for CCCAP-8307
            }else{
                return new LightningServerResponse(false, Label.CaseReview_Error_NoAccess, objectData);
            }
            
            List<Case_Review_Response__c> newReviewRespList = new List<Case_Review_Response__c>();
            for(Case_Review_Response__c resp : [SELECT Id, CaseReview_QuestionMain__c, CaseReview_Error1__c, CaseReview_Cause1__c,
                                                CaseReview_Error2__c, CaseReview_Cause2__c, CaseReview_Error3__c, CaseReview_Cause3__c,
                                                CaseReview_Error4__c, CaseReview_Cause4__c, Observation_Details_Comments__c, Action_Required__c,
                                                Action_Taken__c, Action_Date__c, Case_Review__c, Review_Question__c, CaseReview_NA_Reason__c, Causes_Payment_Error__c 
                                                FROM Case_Review_Response__c WHERE Case_Review__c = :existingReview.Id]){
                                                    Case_Review_Response__c newResp = resp.clone();
                                                    newResp.Case_Review__c = newReview.Id;
                                                    newReviewRespList.add(newResp);
                                                }
            list<String> fieldLists = new list<String>{'CaseReview_QuestionMain__c', 'CaseReview_Error1__c', 'CaseReview_Cause1__c',
                                                'CaseReview_Error2__c', 'CaseReview_Cause2__c', 'CaseReview_Error3__c', 'CaseReview_Cause3__c',
                                                'CaseReview_Error4__c', 'CaseReview_Cause4__c', 'Observation_Details_Comments__c', 'Action_Required__c',
                                                'Action_Taken__c', 'Action_Date__c', 'Case_Review__c', 'Review_Question__c', 'CaseReview_NA_Reason__c', 'Causes_Payment_Error__c'};                                   
            GenericDMLHandler.insertRecords(newReviewRespList, new Map<String, Object>{'Method__c'=>'resubmitLastReview 2', 'Class__c'=>'caseReviewApexController'}, fieldLists); // Added fieldLists for CCCAP-8307
            /* Commenting for CCCAP-15747 deactivating T119
            if(Schema.sObjectType.Task.fields.Subject.isCreateable() && Schema.sObjectType.Task.fields.Description.isCreateable() &&
               Schema.sObjectType.Task.fields.ActivityDate.isCreateable() && Schema.sObjectType.Task.fields.WhatId.isCreateable() && 
               Schema.sObjectType.Task.fields.OwnerId.isCreateable() && Schema.sObjectType.Task.isCreateable()){
                   Task t = new Task();
                   t.Subject = Label.Task_T119_Subject;
                   t.Description = (Label.Task_T119_Description).replace('{!countyName}', existingReview.Case__r.CDE_COUNTY__r.Name); // Modified by Rishav for CCCAP-7603
                   t.ActivityDate = System.today().addDays(5);
                   t.WhatId = newReview.Case__c;
                   t.OwnerId = User_and_Email_Settings__c.getInstance('T119 Assignee').Value__c;
                   GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'resubmitLastReview 3', 'Class__c'=>'caseReviewApexController'});
               }*/
            objectData.put('caseReviewId', newReview.Id);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse saveCaseReview(Case_Review__c caseReviewObj, List<Object> responseWrapperList, String screenMode, String methodName){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            List<Case_Review_Response__c> respToUpsert = new List<Case_Review_Response__c>();
            if(methodName == 'doSubmit' && Schema.sObjectType.Case_Review__c.fields.IsSubmitted__c.isCreateable() && Schema.sObjectType.Case_Review__c.fields.IsSubmitted__c.isUpdateable()){
                caseReviewObj.IsSubmitted__c = true;
            }
            if(caseReviewObj.Program_Type__c == null){
                GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'caseReviewApexController', Method__c = 'saveCaseReview', Exception_Message__c = 'Program type is null before upsert of case review record', Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'saveCaseReview','Class__c'=>'caseReviewApexController'}, new list<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c'}); // Added field names parameter for CCCAP-8307
            }
            Database.upsert(caseReviewObj);
            objectData.put('caseReviewObj', caseReviewObj);
            if(screenMode == 'NEW'){
                List<Case_Review_Response__c> respToDelete = [SELECT Id FROM Case_Review_Response__c WHERE Case_Review__c = :caseReviewObj.Id];
                if(Schema.sObjectType.Case_Review_Response__c.isDeletable()){
                    GenericDMLHandler.deleteRecords(respToDelete, new Map<String, Object>{'Method__c'=>'saveCaseReview 1', 'Class__c'=>'caseReviewApexController'});
                }
            }
            String pgmType = caseReviewObj.Program_Type__c;
            if(String.isEmpty(pgmType)){
                GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'caseReviewApexController', Method__c = 'saveCaseReview', Exception_Message__c = 'Program type is null after upsert of case review record', Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'saveCaseReview','Class__c'=>'caseReviewApexController'}, new list<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c'}); // Added field names parameter for CCCAP-8307
            }
            List<Review_Question__c> currentQuestions= [SELECT Id, Order__c, Element__c, Question__c, Review_Requirement__c, NA_Reason_Options__c, Hide_Errors_and_Causes__c 
                                                 FROM Review_Question__c WHERE Review_Type__c = 'Case' AND Case_Type__c = :pgmType AND Active__c = true];
            Set<Id> resultIds = (new Map<Id,SObject>(currentQuestions)).keySet();
            List<Case_Review_Response__c> responsesToBeDeleted = [SELECT Id, CaseReview_QuestionMain__c, CaseReview_Error1__c, CaseReview_Cause1__c,
                                                    CaseReview_Error2__c, CaseReview_Cause2__c, CaseReview_Error3__c, CaseReview_Cause3__c,
                                                    CaseReview_Error4__c, CaseReview_Cause4__c, Observation_Details_Comments__c, Action_Required__c,
                                                    Action_Taken__c, Action_Date__c, Case_Review__c, Review_Question__c, CaseReview_NA_Reason__c, Causes_Payment_Error__c 
                                                    FROM Case_Review_Response__c WHERE Case_Review__c = :caseReviewObj.Id AND Review_Question__c not in :resultIds ];
            if(!responsesToBeDeleted.isEmpty()){
                if(Schema.sObjectType.Case_Review_Response__c.isDeletable()){
                    GenericDMLHandler.deleteRecords(responsesToBeDeleted, new Map<String, Object>{'Method__c'=>'saveCaseReview 3', 'Class__c'=>'caseReviewApexController'});
                }
            }
            for(Object responseWrapper : responseWrapperList){
                caseReviewApexController.responseWrapper wrp = (caseReviewApexController.responseWrapper)JSON.deserialize(JSON.serialize(responseWrapper), caseReviewApexController.responseWrapper.class);
                Case_Review_Response__c resp = wrp.responseRec;
                if(screenMode == 'NEW' && Schema.sObjectType.Case_Review_Response__c.fields.Case_Review__c.isCreateable() || resp.Case_Review__c == null){
                    resp.Case_Review__c = caseReviewObj.Id;
                }
                respToUpsert.add(resp);
            }
            Database.upsert(respToUpsert);
            /* Commenting for CCCAP-15747 deactivating T119
            if(methodName == 'doSubmit' && Schema.sObjectType.Task.fields.Subject.isCreateable() && Schema.sObjectType.Task.fields.Description.isCreateable() &&
               Schema.sObjectType.Task.fields.ActivityDate.isCreateable() && Schema.sObjectType.Task.fields.WhatId.isCreateable() && 
               Schema.sObjectType.Task.fields.OwnerId.isCreateable() && Schema.sObjectType.Task.isCreateable()){
                   T_SBSD_CASE__c caseRec = [SELECT Id, CDE_COUNTY__r.Name FROM T_SBSD_CASE__c WHERE Id =: caseReviewObj.Case__c LIMIT  1];
                   
                   Task t = new Task();
                   t.Subject = Label.Task_T119_Subject;
                   t.Description = (Label.Task_T119_Description).replace('{!countyName}', caseRec?.CDE_COUNTY__r?.Name); // Modified by Rishav for CCCAP-7603
                   t.ActivityDate = System.today().addDays(5);
                   t.WhatId = caseReviewObj.Case__c;
                   t.OwnerId = User_and_Email_Settings__c.getInstance('T119 Assignee').Value__c;
                   GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'saveCaseReview 2', 'Class__c'=>'caseReviewApexController'});
               }*/
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse submitToReviewee(String revieweeId, String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Boolean isCountyMatch = false;
            // Boolean isQueueMember = false;
            //Removing Profile.Name as part of CCCAP-14993
            List<User> u = [SELECT Id, Name, Owner_County__c, Common_County__c FROM User WHERE Id = :revieweeId LIMIT 1];
            List<Case_Review__c> cr = [SELECT Id, Reviewee__c, Case__c, Case__r.Name, Case__r.CDE_COUNTY__c, Case__r.CDE_COUNTY__r.Name FROM Case_Review__c WHERE Id = :recordId LIMIT 1];
            if(!u.isEmpty() && !cr.isEmpty()){
                isCountyMatch = checkCountyWithUserCounty(cr[0].Case__r.CDE_COUNTY__c, u[0]);
                /* Removed queue restriction for CCCAP-7895 by Rishav
                    String countyQueueName = Test.isRunningTest() ? 'Denver_Lead_Workers_Supervisors' : (cr[0].Case__r.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors';
                for(GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :countyQueueName]){
                    if(gm.UserOrGroupId == u[0].Id){
                        isQueueMember = true;
                    }
                }
                if(!isQueueMember && isSuccessful){
                    isSuccessful = false;
                    message = Label.CaseReview_Error_RevieweeError;
                }
                */
                if(!isCountyMatch){
                    isSuccessful = false;
                    message = Label.CaseReview_Error_RevieweeCountyError;
                }
                // Start: Added by Rishav for CCCAP-7603
                //Replacing using custom permission as part of CCCAP-14993
                if(UserInfo.getUserId() == cr[0].Reviewee__c && !FeatureManagement.checkPermission('System_Administrator') ){
                    isSuccessful = false;
                    message = Label.CaseReview_Error_RevieweeError;
                }
                // End: CCCAP-7603
                if(isSuccessful ){ // Removed access checks since checking from genericDMLHandler CCCAP-8307
                       objectData.put('userName', u[0].Name);
                       objectData.put('caseNumber', cr[0].Case__r.Name);
                       Task t = new Task();
                       t.Subject = Label.Task_T118_Subject;
                       t.Description = Label.Task_T118_Description;
                       t.ActivityDate = System.today().addDays(5);
                       t.WhatId = cr[0].Case__c;
                       t.OwnerId = revieweeId;
                       GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'submitToReviewee 1', 'Class__c'=>'caseReviewApexController'}, new List<String>{'Subject','Description','ActivityDate','WhatId','OwnerId'}); //  added field names as part of CCCAP-8307
                       cr[0].Reviewee__c = revieweeId;
                       //GenericDMLHandler.updateRecords(new List<Case_Review__c>{cr[0]}, new Map<String, Object>{'Method__c'=>'submitToReviewee 2', 'Class__c'=>'caseReviewApexController'});
                       GenericDMLHandler.updateRecords(new List<Case_Review__c>{cr[0]}, new Map<String, Object>{'Method__c'=>'submitToReviewee 2', 'Class__c'=>'caseReviewApexController'},new List<String>{'Reviewee__c'}); // CCCAP-8307
                   }
            }
            if(!isSuccessful && String.isBlank(message)) {
                message = Label.CaseReview_Error_ApexException;
            }
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse sumbitForStateReversal(String recordId, String taskComment){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            List<User> u = [SELECT Id, Name FROM User WHERE Id = :User_and_Email_Settings__c.getInstance('T121 Assignee').Value__c LIMIT 1];
            List<Case_Review__c> cr = [SELECT Id, Name, Reviewee__c, Case__c, Case__r.Name FROM Case_Review__c WHERE Id = :recordId LIMIT 1];
            if(!u.isEmpty() && !cr.isEmpty()){
                // Start: Added by Rishav for CCCAP-7603
                //Replacing using Custom Permission as part of CCCAP-14993
                if(UserInfo.getUserId() == cr[0].Reviewee__c && !FeatureManagement.checkPermission('System_Administrator') ){
                    isSuccessful = false;
                    message = Label.CaseReview_Error_StateReversal;
                }
                // End: CCCAP-7603
                if(isSuccessful ){ // Removed access checks since checking from genericDMLHandler CCCAP-8307
                       objectData.put('userName', u[0].Name);
                       objectData.put('recordName', cr[0].Name);
                       Task t = new Task();
                       t.Subject = Label.Task_T121_Subject;
                       t.Description = taskComment;
                       t.ActivityDate = System.today().addDays(5);
                       t.WhatId = recordId;
                       t.OwnerId = u[0].Id;
                       GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'sumbitForStateReversal 1', 'Class__c'=>'caseReviewApexController'}, new List<String>{'Subject','Description','ActivityDate','WhatId','OwnerId'}); //  added field names as part of CCCAP-8307   
                   }
                if(!isSuccessful && String.isBlank(message)) {
                    message = Label.CaseReview_Error_ApexException;
                }
            } else {
                isSuccessful = false;
                message = Label.CaseReview_Error_ApexException;
            }
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse checkEligibility(String recordId, Boolean isDelete){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            String accessLevel = 'reviewer'; // reviewee, reviewer, admin
            String sobjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            Boolean disableDraftCaseReview = false; // Added for CCCAP-9216
            Boolean disableSubmittedCaseReview = false;
            String caseType = '';
            Case_Review__c caseReviewRec;
            Id caseId = recordId;
            if(sobjectName == 'Case_Review__c'){
                caseReviewRec = [SELECT Id, Case__c,Program_Type__c,Reviewee__c, Review_Status__c, Case__r.CDE_COUNTY__c, Case__r.CDE_COUNTY__r.Name from Case_Review__c WHERE Id=:recordId LIMIT 1];
                caseId = caseReviewRec.Case__c;
            }
            T_SBSD_CASE__c caseRecord = [SELECT Id, Name, Program_Type__c,CDE_COUNTY__c, CDE_COUNTY__r.Name FROM T_SBSD_CASE__c WHERE Id = :caseId Limit 1];
            //Removing Profile.Name as part of CCCAP-14993
            User u = [SELECT Id, Name, Owner_County__c, Common_County__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if(sobjectName == 'Case_Review__c'){
                if(isDelete == true){
                    objectData.put('parentCase', caseRecord.Id);
                }
            }
            if(isSuccessful){
                isSuccessful = true;
                message = '';
                Boolean isCountyMatch = false;
                Boolean isQueueMember = false;
                Boolean showDraftForm = false;
                String lastDraftReviewId;
                if(sobjectName == 'T_SBSD_CASE__c'){ // NEW
                    isCountyMatch = checkCountyWithUserCounty(caseRecord.CDE_COUNTY__c, u);
                    for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :((caseRecord.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors')]){
                        if(gm.UserOrGroupId == u.Id){
                            isQueueMember = true;
                            accessLevel = 'reviewer';
                        }
                    }
                    // Start: Added by Rishav for CCCAP-7603
                    for(Case_Review__c lastReviewRecord : [SELECT Id, Review_Status__c FROM Case_Review__c WHERE Case__c = :recordId ORDER BY CreatedDate DESC LIMIT 1]){
                        if(lastReviewRecord.Review_Status__c == '1'){
                            showDraftForm = true;
                            lastDraftReviewId = lastReviewRecord.Id;
                        }
                    }
                    // End: CCCAP-7603
                } else { // EDIT
                    isCountyMatch = checkCountyWithUserCounty(caseReviewRec.Case__r.CDE_COUNTY__c, u);
                    for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :((caseReviewRec.Case__r.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors')]){
                        if(gm.UserOrGroupId == u.Id){// Modified by Rishav for CCCAP-7603
                            isQueueMember = true;
                            accessLevel = 'reviewer';
                        }
                    }
                    if(UserInfo.getUserId() == caseReviewRec.Reviewee__c){
                        isQueueMember = true; // To provide access to Reviewee outside queue members
                        accessLevel = 'reviewee';
                    }
                }
                //Replacing using Custom Permission as part of CCCAP-14993
                if(FeatureManagement.checkPermission('System_Administrator') ){
                    accessLevel = 'admin';
                }
                objectData.put('accessLevel', accessLevel);
                objectData.put('showDraftForm', showDraftForm); // Added by Rishav for CCCAP-7603
                objectData.put('lastDraftReviewId', lastDraftReviewId); // Added by Rishav for CCCAP-7603
                
                //Replacing using Custom permission as part of CCCAP-14993
                if(!isCountyMatch && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                    isSuccessful = false;
                    message = Label.CaseReview_Error_CountyMismatch;
                }
                //Replacing using Custom Permission as part of CCCAP-14993
                if(!isQueueMember && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                    isSuccessful = false;
                    message = Label.CaseReview_Error_NoAccess;
                }
            }
        } catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse checkRecordAccess(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Boolean isCountyMatch = false;
            Boolean isQueueMember = false;
            //Removing Profile as part of CCCAP-14993
            User u = [SELECT Id, Name, Owner_County__c, Common_County__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Case_Review__c caseReviewRec = [SELECT Id, Reviewee__c, Case__c, Case__r.CDE_COUNTY__c, Case__r.CDE_COUNTY__r.Name FROM Case_Review__c WHERE Id = :recordId LIMIT 1];
            objectData.put('caseId', caseReviewRec.Case__c);
            isCountyMatch = checkCountyWithUserCounty(caseReviewRec.Case__r.CDE_COUNTY__c, u);
            for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :((caseReviewRec.Case__r.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors')]){
                if(gm.UserOrGroupId == u.Id){
                    isQueueMember = true;
                }
            }
            if(UserInfo.getUserId() == caseReviewRec.Reviewee__c){ // Added by Rishav for CCCAP-7895
                isQueueMember = true; // To provide access to Reviewee outside queue members
            }
            //Replacing using Custom permission as part of CCCAP-14993
            if(!isCountyMatch && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                isSuccessful = false;
                message = Label.CaseReview_Error_CountyMismatch;
            }
            //Replacing using Custom permission as part of CCCAP-14993
            if(!isQueueMember && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                isSuccessful = false;
                message = Label.CaseReview_Error_NoAccess;
            }
        } catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static String getVFBaseURL(){
        return ContinuationController.getVFBaseURL();
    }
    
    public static Boolean checkCountyWithUserCounty(Id countyId, User user){
        Boolean countyMatched = true;
        //Replacing profile references as part of CCCAP-14993
        List<PermissionSetAssignment> psa = [SELECT Id,AssigneeId,PermissionSet.Name FROM PermissionSetAssignment where AssigneeId=:User.Id and  PermissionSet.name!='System_Administrator_PS' and PermissionSet.Name!='CCCAP_Program_Internal_Team'];
        if(!psa.isEmpty()) {
            countyMatched = false;
            List<T_COUNTY__c> counties = [SELECT CDE_COUNTY__c FROM T_COUNTY__c WHERE Id = :countyId];
            if(!counties.isEmpty()){
                String county = String.valueOf(counties.get(0).CDE_COUNTY__c);
                if(user.Owner_County__c == county || (String.isNotBlank(user.Common_County__c) && new Set<String>(user.Common_County__c.split(';')).contains(county))) {
                    countyMatched = true;
                }
            }
        }
        return countyMatched;
    }
    
    @AuraEnabled
    public static LightningServerResponse getParentFeeSubsidyAmount(String recordId, String sampleMonth, String sampleYear, String screenMode){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        CaseReviewWrapper caseReviewObj = new CaseReviewWrapper();
        try {
            // Logic for fetching Parent Fee
            Object parentFee;
		String caseExternalId;
        if(recordId != null){
            caseExternalId = [SELECT Id, IDN_EXTNL__c FROM T_SBSD_CASE__c WHERE Id = :recordId LIMIT 1].IDN_EXTNL__c;
        }
            Date sampleDate = Date.newInstance(Integer.valueOf(sampleYear), Integer.valueOf(sampleMonth), 1);
            List<batchsit_t_sbsd_case_copay__x> parentFeeList = QueryExternalObjects.query([SELECT ExternalId, dte_begin_effv__c, dte_end_effv__c, amt_copay_case_assesd__c 
                                                                                             FROM batchsit_t_sbsd_case_copay__x WHERE idn_case__c = :caseExternalId
                                                                                             AND dte_begin_effv__c <= :sampleDate AND (dte_end_effv__c >= :sampleDate OR dte_end_effv__c = null)  ORDER BY dte_begin_effv__c DESC]);
            if(!parentFeeList.isEmpty()){
                parentFee = parentFeeList[0];
            }
            objectData.put('parentFee', parentFee);
            
            // Logic for fetching Subsidy Amount
            Decimal subsidyAmount = 0.0;
            caseReviewObj = getAmtPaidAndAdjClaims(recordId, sampleMonth, sampleYear);
            if(caseReviewObj != null && caseReviewObj.subPmtDltExtIds != null){
                subsidyAmount += caseReviewObj.totalAmountPaid;
                subsidyAmount += getAdjClaims(recordId, sampleMonth, sampleYear, caseReviewObj.subPmtDltExtIds);
            }
            objectData.put('subsidyAmount', subsidyAmount);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    // Added by Diya for CCCAP-4771
    public static CaseReviewWrapper getAmtPaidAndAdjClaims(String recordId, String sampleMonth, String sampleYear){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        Decimal totalAmountPaid = 0.0;
        Set<String> subPmtDltExtIds = new Set<String>();
        CaseReviewWrapper caseReviewWrap = new CaseReviewWrapper();
        String caseExternalId;
        if(recordId != null){
            caseExternalId = [SELECT Id, IDN_EXTNL__c FROM T_SBSD_CASE__c WHERE Id = :recordId LIMIT 1].IDN_EXTNL__c;
        }
        try {
            HttpResponse response = HerokuService.getAmountPaidService(caseExternalId, sampleMonth, sampleYear);
            if(response.getStatusCode() != 200) {
                message = response.getBody();
                isSuccessful = false;
            } else {
                System.debug('[caseReviewApexController.getAmtPaidAndAdjClaims]--response.getBody()-->'+JSON.deserializeUntyped(response.getBody()));
                List<Object> caseReviewSubsidyModel = (List<Object>)JSON.deserializeUntyped(response.getBody());
                if(caseReviewSubsidyModel != null && !caseReviewSubsidyModel.isEmpty()){
                    for(Object caseReviewSubsidyDataObj : caseReviewSubsidyModel){
                        System.debug('[caseReviewApexController.getAmtPaidAndAdjClaims]--caseReviewSubsidyDataObj-->'+caseReviewSubsidyDataObj);
                        Map<String,Object> caseReviewData = (Map<String,Object>)caseReviewSubsidyDataObj;
                        List<Object> caseReviewSubsidyModel1 = (List<Object>)caseReviewData.get('caseReviewSubsidyDetail');
                        for(object obj : caseReviewSubsidyModel1){
                            Map<String, Object> caseReviewData1 = (Map<String, Object>)obj;
                            System.debug('[caseReviewApexController.getAmtPaidAndAdjClaims]--caseReviewData1-->'+caseReviewData1);
                            if(caseReviewData1.containsKey('amountPaid') && caseReviewData1.get('amountPaid') != null){
                                totalAmountPaid += Decimal.valueOf(String.valueOf(caseReviewData1.get('amountPaid')));
                            }
                            if((caseReviewData1.containsKey('subPaymentdetailsId') && caseReviewData1.get('subPaymentdetailsId') != null) &&
                               (caseReviewData1.containsKey('existingAdj') && caseReviewData1.get('existingAdj')!=null && caseReviewData1.get('existingAdj') =='Y')){
                                   subPmtDltExtIds.add(string.valueOf(caseReviewData1.get('subPaymentdetailsId')));
                               }
                        }
                    }
                }
            }
            System.debug('[caseReviewApexController.getAmtPaidAndAdjClaims]--subPmtDltExtIds-->'+subPmtDltExtIds);
            System.debug('[caseReviewApexController.getAmtPaidAndAdjClaims]--totalAmountPaid-->'+totalAmountPaid);
            caseReviewWrap.subPmtDltExtIds =  subPmtDltExtIds;
            caseReviewWrap.totalAmountPaid =  totalAmountPaid;
        } catch (Exception e) {
            message = e.getMessage();
            isSuccessful = false;
            System.debug('[caseReviewApexController.getAmtPaidAndAdjClaims]--Exception-->'+e.getMessage());
        }
        return caseReviewWrap;
    }
    
    // Added by Diya for CCCAP-4771
    public static Decimal getAdjClaims(String recordId, String sampleMonth, String sampleYear, Set<String> subPmtDtlIDSet) {
        Set<Id> clientIDSet = new Set<Id>();
        Set<Id> providerIDSet = new Set<Id>();
        Set<Id> authIDSet = new Set<Id>();
        Set<Id> adjIDSet = new Set<Id>();
        Decimal claimAmt = 0;
        Decimal nonAdjAmt = 0;
        String countyId;
        Date startDate = Date.newInstance(Integer.valueOf(sampleYear), Integer.valueOf(sampleMonth), 1);
        Date lastDayOfMonth = startDate.addDays(Date.daysInMonth(startDate.year(), startDate.month()) - 1);
        if(!String.isBlank(recordId)){
            for(T_AUTH__c auth :[SELECT Id, IDN_CASE__c, IDN_CLIENT__c, IDN_PROVR__c, DTE_BEGIN_EFFV_AUTH__c, CDE_COUNTY__c, IDN_EXTNL__c,
                                 DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE IDN_CASE__c = :recordId AND
                                 ((DTE_BEGIN_EFFV_AUTH__c <= :startDate AND DTE_END_EFFV_AUTH__c >= :startDate) OR
                                  (DTE_BEGIN_EFFV_AUTH__c <= :lastDayOfMonth AND DTE_END_EFFV_AUTH__c >= :lastDayOfMonth) OR 
                                  (DTE_BEGIN_EFFV_AUTH__c >= :startDate AND DTE_END_EFFV_AUTH__c <= :lastDayOfMonth))]){
                                      countyId = auth.CDE_COUNTY__c;
                                      clientIDSet.add(auth.IDN_CLIENT__c);
                                      providerIDSet.add(auth.IDN_PROVR__c);
                                      authIDSet.add(auth.IDN_EXTNL__c);
                                  }
            System.debug('[caseReviewApexController.getAdjClaims]--authIDSet='+authIDSet+', providerIDSet='+providerIDSet+', clientIDSet='+clientIDSet);
            System.debug('[caseReviewApexController.getAdjClaims]--countyId='+countyId+', subPmtDtlIDSet='+subPmtDtlIDSet);
            for(T_ADJMT__c adj : [SELECT Id, AMT_ADJMT__c, CDE_STATUS_ADJMT__c,
                                  (SELECT Id, DTE_CARE__c, AMT_DETAIL_ADJMT__c, AMT_PAID_RATE_ORIG__c, IDN_DETAIL_PMT_SUB__c FROM Adjustment3__r WHERE IDN_DETAIL_PMT_SUB__c IN :subPmtDtlIDSet),
                                  (SELECT Id, AMT_DETAIL_ADJMT__c, IDN_AUTH__c FROM Adjustment6__r WHERE IDN_AUTH__c in:authIDSet)
                                  FROM T_ADJMT__c 
                                  WHERE (IDN_PROVR__c IN :providerIDSet OR IDN_CASE__c = :recordId) AND
                                  CDE_COUNTY__c = :countyId AND CDE_STATUS_ADJMT__c = '4' AND CDE_TYPE_ADJMT__c = '1' AND 
                                  ((DTE_START_ADJMT__c <= :startDate AND DTE_END_ADJMT__c >= :startDate) OR
                                   (DTE_START_ADJMT__c <= :lastDayOfMonth AND DTE_END_ADJMT__c >= :lastDayOfMonth) OR 
                                   (DTE_START_ADJMT__c >= :startDate AND DTE_END_ADJMT__c <= :lastDayOfMonth))]){
                                       System.debug('[caseReviewApexController.getAdjClaims]--adj-->'+adj);
                                       adjIDSet.add(adj.Id);
                                       if(adj.Adjustment6__r != null && adj.Adjustment6__r.size() > 0){
                                           System.debug('[caseReviewApexController.getAdjClaims]--adj.Adjustment6__r-->'+adj.Adjustment6__r);
                                           for(T_NON_ADJMT_DETAIL__c  nonAdj : adj.Adjustment6__r){
                                               claimAmt += nonAdj.AMT_DETAIL_ADJMT__c;
                                           }
                                       }
                                       if(adj.Adjustment3__r != null && adj.Adjustment3__r.size() > 0){
                                           System.debug('[caseReviewApexController.getAdjClaims]--adj.Adjustment3__r-->'+adj.Adjustment3__r);
                                           for(T_ADJMT_DETAIL__c subAdj : adj.Adjustment3__r){
                                               if(subAdj.DTE_CARE__c >= startDate && subAdj.DTE_CARE__c <= lastDayOfMonth){
                                                   claimAmt += subAdj.AMT_DETAIL_ADJMT__c;
                                               }
                                           }
                                       }
                                   }
        }
        System.debug('[caseReviewApexController.getAdjClaims]--claimAmt-->'+claimAmt);
        return claimAmt;
    }
    
    // Added by Rishav for CCCAP-7603
    @AuraEnabled
    public static String generateTaskComment(String recordId) {
        String taskComment = '';
        try {
            Case_Review__c cr = [SELECT Id, Case__r.CDE_COUNTY__r.Name FROM Case_Review__c WHERE Id = :recordId LIMIT 1];
            taskComment = (Label.Task_T121_Description).replace('{!countyName}', cr?.Case__r?.CDE_COUNTY__r?.Name);
        } catch (Exception e) {
            GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'caseReviewApexController', Method__c = 'generateTaskComment', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'generateTaskComment','Class__c'=>'caseReviewApexController'}, new List<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c'}); // Added fieldnames as part of CCCAP-8307
        }
        return taskComment;
    }
    
    // Added by Rishav for CCCAP-7603
    @AuraEnabled
    public static LightningServerResponse deleteCaseReview(String recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Case_Review__c lastDraftReview = [SELECT Id FROM Case_Review__c WHERE Id = :recordId LIMIT 1];
            if(Schema.sObjectType.Case_Review__c.isDeletable()){
                Database.delete(lastDraftReview);
            }else{
                isSuccessful = false;
                message = 'Insufficient object-level delete permission for Case Review';
            }
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    // Added by Rishav for CCCAP-7603
    @AuraEnabled
    public static LightningServerResponse deleteCaseReviewButton(String recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        LightningServerResponse lsr = checkEligibility(recordId, true);
        if(lsr.isSuccessful){
            String accessLevel = (String)(lsr.objectData).get('accessLevel');
            if(accessLevel == 'reviewer' || accessLevel == 'admin'){
                if(Schema.sObjectType.Case_Review__c.isDeletable()){
                    Database.delete(recordId);
                    objectData.put('parentCase',(lsr.objectData).get('parentCase'));
                }else{
                    isSuccessful = false;
                    message = 'Insufficient object-level delete permission for Case Review';
                }
            } else {
                isSuccessful = false;
                message = Label.CaseReview_Error_NoAccess;
            }
        } else {
            isSuccessful = false;
            message = lsr.errorMessage;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }

    /* Added by Nikita for CCCAP-15192
    * Called from CaseReviewTrigger before delete */
    public static String validateCaseReviewDelete(String recordId) {
        try {
            LightningServerResponse lsr = checkEligibility(recordId, true);
            if(lsr.isSuccessful) {
                String accessLevel = (String)(lsr.objectData).get('accessLevel');
                if(accessLevel == 'reviewer' || accessLevel == 'admin') {
                    if(!Schema.sObjectType.Case_Review__c.isDeletable()) {
                        return 'Insufficient object-level delete permission for Case Review';
                    }
                    return null;
                } else {
                    return Label.CaseReview_Error_NoAccess;
                }
            } else {
                return lsr.errorMessage;
            }
        } catch(Exception e) {
            return e.getMessage();
        }
    }

    //CCCAP-12156
    @AuraEnabled
    public static String getChildCareProgramBySampleMonthYear(String caseId, String sampleMonth, String sampleYear){
        String childCareProg;
        List<batchsit_t_fcompsn_eligty__x> householdEligity = new List<batchsit_t_fcompsn_eligty__x>();
        List<batchsit_t_fcompsn_eligty_detail__x> eligDetail = new List<batchsit_t_fcompsn_eligty_detail__x>();
        String caseExternalId;
        List<batchsit_t_sbsd_case_copay__x> caseCopayRecord =new List<batchsit_t_sbsd_case_copay__x>();
        if(String.isNotBlank(caseId)){
            for(T_SBSD_CASE__c cse :[Select id,IDN_EXTNL__c from T_SBSD_CASE__c where id=:caseId]){
                caseExternalId =cse.IDN_EXTNL__c;
            }
        }
        system.debug('caseExternalId--'+caseExternalId);
        //List<String> monthList = new List<String>{'January', 'February', 'March', 'April', 'May', 'June','July', 'August', 'September', 'October', 'November', 'December'};
        Date startDate = Date.newInstance(Integer.valueOf(sampleYear),Integer.valueOf(sampleMonth),1);
        Date endDate = startDate.addMonths(1).addDays(-1);
        if(!String.isBlank(caseExternalId)){
            Set<String> eliRunIds = new Set<String>();
            for(batchsit_t_eligty_run__x eli : [Select Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c from batchsit_t_eligty_run__x where
                                                idn_case__c=:caseExternalId and cde_eligty_cfmd__c='CFM' and (dte_run_eligty__c <= :endDate) order by dte_run_eligty__c DESC, ExternalId DESC limit 1]){
                                                    eliRunIds.add(String.valueOf(eli.idn_run_eligty__c));
                                                    
                                                }
            system.debug('eliRunIds--'+eliRunIds);
            if(Test.isRunningTest()){
                eliRunIds.add('123');
            }
            if(eliRunIds.size()>0) {
                Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
                Set<Decimal> eligibilityHouseHoldIdSet = new Set<Decimal>();
                List<batchsit_t_fcompsn_eligty__x> unfilteredCaseEligibility = [SELECT Id, cde_prog__c, txt_values_comptd_xml__c, cde_reason_ovrd__c, txt_cmt_ovrd__c, ExternalId,
                                                                  idn_run_eligty__c, nbr_size_fcompsn__c, cnt_chldrn_rqng_care__c, amt_copay_ft__c, amt_copay_pt__c,
                                                                  amt_income_county_max__c, amt_income_annual__c, amt_grant_total_annual__c, amt_fpg_pctg__c, cde_income_result__c,
                                                                  amt_clg_county_new__c, amt_income_smi__c, amt_ddtn_total_annual__c, amt_income_gross_annual__c, idn_eligty_fcompsn__c, cde_reason_change_fcompsn__c
                                                                  FROM batchsit_t_fcompsn_eligty__x
                                                                  WHERE idn_run_eligty__c IN: eliRunIds AND idn_eligty_fcompsn__c!=null];
                for(batchsit_t_fcompsn_eligty__x fcompsnEligty:unfilteredCaseEligibility){
                if( fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
	                fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
                }
            }
                for(batchsit_t_fcompsn_eligty_detail__x fcomElig : [Select Id,idn_eligty_fcompsn__c,cde_status_eligty_family__c 
                                                                    from batchsit_t_fcompsn_eligty_detail__x 
                                                                    where idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet()  order by dte_begin_effv__c DESC ,idn_eligty_fcompsn__c DESC limit 1])
                {
                    eligibilityHouseHoldIdSet.add(decimal.valueOf(fcomElig.idn_eligty_fcompsn__c));
                }
                if(!eligibilityHouseHoldIdSet.isEmpty()){
                    householdEligity = [select id,ExternalId,idn_run_eligty__c,cde_prog__c,amt_copay_ft__c,amt_copay_pt__c,idn_eligty_fcompsn__c 
                                        from batchsit_t_fcompsn_eligty__x where idn_eligty_fcompsn__c IN :eligibilityHouseHoldIdSet order by idn_eligty_fcompsn__c LIMIT 1];
                    if(!householdEligity.isEmpty()){
                        system.debug('householdEligity--'+householdEligity[0]);
                      childCareProg = householdEligity[0].cde_prog__c;
                    }
                }
            }
        }
        return childCareProg;
    }
    //CCCAP-12378
    private static void getCaseTypeLabelOnCaseType(string caseType){
        caseTypeLabel= null;
        for(PicklistValueInfo ctInfo : [select Id, Value, Label from PicklistValueInfo where EntityParticle.EntityDefinition.QualifiedApiName='Case_Review__c' and isactive=true and EntityParticle.DeveloperName in('Program_Type')]){
            if(ctInfo.label.containsIgnoreCase(caseType) || ctInfo.Value.containsIgnoreCase(caseType)){
                caseTypeLabel = ctInfo.Label;
                break;
            }
        }
    }
      //end CCCAP-12378

    //CCCAP-15694
    private static Date getRedetDateAsOfSampleMonth(Id caseId, Integer sampleMonth, Integer sampleYear) {
        Date lastDayOfSampleMonth = Date.newInstance(sampleYear, sampleMonth, 1).addMonths(1).addDays(-1);
        List<T_SBSD_CASE__History> historyList = [SELECT NewValue, CreatedDate FROM T_SBSD_CASE__History WHERE ParentId = :caseId
            AND Field = 'DTE_REDET_CASE__c' AND CreatedDate <= :DateTime.newInstance(lastDayOfSampleMonth, Time.newInstance(23, 59, 59, 0))
            ORDER BY CreatedDate DESC LIMIT 1];
        if (!historyList.isEmpty() && historyList[0].NewValue != null) {
            return Date.valueOf(String.valueOf(historyList[0].NewValue));
        }
        return null;
    }

}