public class providerReviewApexController implements IRequest {
    private static string screenMode{get;set;}
    private static string objectName{get;set;}
    private static string recordId{get;set;}
    private static string licenseType{get;set;}
    private static string providerTypeLabel{get;set;}
    private static String provId{get;set;} //added for CCCAP-13277
    private static String cntyId{get;set;} //added for CCCAP-13277
    private static String sampleM{get;set;} //added for CCCAP-13277
    private static string sampleY{get;set;} //added for CCCAP-13277
    
    public String jsonParam;
    private static Map<String, Object > requestObj;
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true,'',new Map<String,Object>());
        this.jsonParam = jsonParam;
        
        if(jsonParam!=null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        }
        if (methodName == 'checkEligibility') {
            response = checkEligibility(getMapValue('recordId'),getMapValue('screenMode'),(Boolean)requestObj.get('isDelete'),(Boolean)requestObj.get('fetchAllData'));
        }else if(methodName == 'handleSample_MY_Update'){
            response = handleSample_MY_Update(getMapValue('recordId'),getMapValue('providerId'),getMapValue('objectName'),getMapValue('sampleMonth'),getMapValue('sampleYear'),getMapValue('countyId'),getMapValue('FA_Id'));
        }else if(methodName == 'saveProviderReview'){
            response = saveProviderReview(getMapValue('providerReviewObj'),getMapValue('responsesRecords'),getMapValue('screenMode'),getMapValue('methodName'),(Boolean)requestObj.get('hasClaim'));
        }else if(methodName == 'deleteProviderReview'){
            response = deleteProviderReview(getMapValue('recordId'));
        }else if(methodName == 'deleteProviderReviewButton'){
            response = deleteProviderReviewButton(getMapValue('recordId'));
        }else if(methodName == 'checkRecordAccess'){
            response = checkRecordAccess(getMapValue('recordId'));
        }else if(methodName =='getVFBaseURL'){
            response = getVFBaseURL();
        }else if(methodName == 'sumbitForStateReversal'){
            response = sumbitForStateReversal(getMapValue('recordId'),getMapValue('taskComment'));
        }else if(methodName == 'submitToReviewee'){
            response = submitToReviewee(getMapValue('revieweeId'),getMapValue('recordId'));
        }
        return response;
    }
    @auraEnabled
    public static LightningServerResponse checkEligibility(String recordId, String screenMode,Boolean isDelete,Boolean fetchAllData){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        Boolean allowDeleteDraft = false;
        String message = '';
        Boolean isCountyMatch = false;
        Boolean isQueueMember = false;
        String lastReviewId;
        providerReviewApexController.recordId = recordId;
        try {
            providerReviewApexController.screenMode = screenMode;
            String accessLevel = 'reviewer'; // reviewee, reviewer, admin
            objectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            User u = [SELECT Id, Name, Owner_County__c, Common_County__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            objectData.put('reviewerName', UserInfo.getName());
            objectData.put('reviewerTitle',u.Profile.Name);
            
            if(objectName == 'T_PROVR_FISCAL_AGREMENT__c'){
                List<T_PROVR_FISCAL_AGREMENT__c> provFARecord = [SELECT Id,Name,CDE_COUNTY__c,CDE_COUNTY__r.Name,ID_SERVICE__c,ID_SERVICE__r.Name,ID_SERVICE__r.NAM_FACILITY__c, OwnerId,
                                                                 CDE_REASON_END_AGRMT__c,DTE_BEGIN_AGRMT__c,DTE_END_AGRMT__c
                                                                 FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id = :recordId Limit 1];
                objectData.put('screenMode', 'NEW');                
                objectData.put('parentFARecord', provFARecord[0]);
                objectData.put('isProviderOwner', provFARecord[0]?.OwnerId == UserInfo.getUserId() ? true : false);
                provId = provFARecord[0].ID_SERVICE__c; //added for CCCAP-13277
                cntyId = provFARecord[0].CDE_COUNTY__c; //added for CCCAP-13277
                Date dateBefore6Months = System.today().addMonths(-6);
                for(Provider_Review__c existingReview :[SELECT Id,Provider__c,Sample_Month__c,Sample_Year__c, createdDate,Review_Status__c,Attendance_Recorded__c FROM Provider_Review__c WHERE Provider_Fiscal_Agreement__c = :recordId 
                                                        ORDER BY createdDate DESC LIMIT 1]){
                                                            lastReviewId = existingReview.Id;
                                                            if(existingReview.Review_Status__c == '1'){
                                                                objectData.put('showDraftForm',true);
                                                                lastReviewId = existingReview.Id;
                                                                sampleM = existingReview.Sample_Month__c; //added for CCCAP-13277
                                                                sampleY = existingReview.Sample_Year__c; //added for CCCAP-13277
                                                            }else if(existingReview.createdDate.date() > dateBefore6Months){
                                                                objectData.put('showInitialForm',true); 
                                                            }
                                                        }
                isCountyMatch = checkCountyWithUserCounty(provFARecord[0].CDE_COUNTY__c, u);
                for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :((provFARecord[0].CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors')]){
                    if(gm.UserOrGroupId == u.Id){
                        isQueueMember = true;
                        accessLevel = 'reviewer';
                    }
                }
            }else if(objectName == 'Provider_Review__c'){
                objectData.put('showInitialForm', false);
                objectData.put('showFAOwnerForm', false);
                Provider_Review__c providerReviewRec = [SELECT Id,Provider__c,Sample_Month__c,Sample_Year__c, Review_Status__c,Attendance_Recorded__c,Provider_Fiscal_Agreement__c,Reviewee__c from Provider_Review__c WHERE Id=:recordId LIMIT 1];
                List<T_PROVR_FISCAL_AGREMENT__c> provFARecord = [SELECT Id,Name,CDE_COUNTY__c,CDE_COUNTY__r.Name,ID_SERVICE__c,ID_SERVICE__r.Name,ID_SERVICE__r.NAM_FACILITY__c, OwnerId,CDE_REASON_END_AGRMT__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id = :providerReviewRec.Provider_Fiscal_Agreement__c LIMIT 1];
                isCountyMatch = checkCountyWithUserCounty(provFARecord[0]?.CDE_COUNTY__c, u);
                provId = providerReviewRec.Provider__c; //added for CCCAP-13277
                cntyId = provFARecord[0].CDE_COUNTY__c; //added for CCCAP-13277
                sampleM = providerReviewRec.Sample_Month__c; //added for CCCAP-13277
                sampleY = providerReviewRec.Sample_Year__c; //added for CCCAP-13277
                if(isDelete == true){
                    objectData.put('parentFARecord', provFARecord[0].Id);
                }else{
                    objectData.put('parentFARecord', provFARecord[0]);
                }
                if(providerReviewRec.Review_Status__c == '1' && isDelete){
                    allowDeleteDraft = true;
                }
                for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :((provFARecord[0]?.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors')]){
                    if(gm.UserOrGroupId == u.Id){
                        isQueueMember = true;
                        accessLevel = 'reviewer';
                    }
                }
                if(UserInfo.getUserId() == providerReviewRec.Reviewee__c){
                    isQueueMember = true; // To provide access to Reviewee outside queue members
                    accessLevel = 'reviewee';
                }
            }
            //CCCAP-14993 Replacing profile by using custom permission
            if(FeatureManagement.checkPermission('System_Administrator')){
                accessLevel = 'admin';
            }
            //CCCAP-14993 Replacing profile by using custom permission
            if(!isCountyMatch && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                isSuccessful = false;
                message = 'The county of the Provider Agreement Fiscal does not match your assigned county(ies).';
            }
            //CCCAP-14993 Replacing profile by using custom permission
            if(!isQueueMember && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                isSuccessful = false;
                message = Label.CaseReview_Error_NoAccess;
            }
            
            objectData.put('accessLevel', accessLevel);
            objectData.put('lastReviewId', lastReviewId);
            objectData.put('objectName',objectName);
            if(isSuccessful && fetchAllData == true){
                Map<String, Schema.SObjectField> reviewRespfieldMap = Schema.SobjectType.Provider_Review_Response__c.fields.getMap();
                objectData.put('allCauseOptions', getPicklistOptions(reviewRespfieldMap.get('ProviderReview_Cause1__c').getDescribe()));
                return getInitOnValid(objectData,'init');                
            }
        } catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    public static LightningServerResponse getInitOnValid(Map<String,Object>objectData,string callingContext){
        String message='';
        Boolean isSuccessful = true;
        String caseType;
        Boolean claimFoundInMonth= false; //CCCAP-13277
        List<responseWrapper> responseWrapperList 	= new List<responseWrapper>();
        Map<String, String> errorsMap 			= new Map<String, String>();
        List<Schema.PicklistEntry> elementPicklistValues = Provider_Review_Response__c.ProviderReview_QuestionMain__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry pe : Review_Question__c.Error_Options__c.getDescribe().getPicklistValues()){
            errorsMap.put(pe.getValue(), pe.getLabel());
        }
        Schema.DescribeFieldResult NAReasonField = Review_Question__c.NA_Reason_Options__c.getDescribe();
        List<Schema.PicklistEntry> NAReasonPicklistValues = NAReasonField.getPicklistValues();
        Map<String, String> NAReasonMap = new Map<String, String>();
        for(Schema.PicklistEntry pe : NAReasonPicklistValues){
            NAReasonMap.put(pe.getValue(), pe.getLabel());
        }
        //CCCAP-13277
        if(sampleM!=null && sampleY!=null && provId!=null){
            Date sampleStartDate = Date.newInstance(Integer.valueOf(sampleY),Integer.valueOf(sampleM),1);
            Date sampleEndDate = sampleStartDate.addMonths(1).addDays(-1);
            List<T_ADJMT__c> adj = new List<T_ADJMT__c>([select id, CDE_STATUS_ADJMT__c, CDE_TYPE_ADJMT__c,DTE_END_ADJMT__c,DTE_START_ADJMT__c,CDE_COUNTY__c 
                                                         From T_ADJMT__c where IDN_PROVR__c=:provId AND CDE_COUNTY__c=:cntyId
                                                         AND CDE_STATUS_ADJMT__c IN ('2','4') AND CDE_TYPE_ADJMT__c = '1' 
                                                         AND DTE_START_ADJMT__c >=:sampleStartDate AND DTE_END_ADJMT__c<= :sampleEndDate ]);
            claimFoundInMonth = (!adj.isEmpty());
            objectData.put('claimFoundInMonth',claimFoundInMonth);
        }
        //end CCCAP-13277
        if(objectName == 'T_PROVR_FISCAL_AGREMENT__c' && callingContext == 'updateSample_MY'){
            for(Review_Question__c qn : [SELECT Id, Order__c, Element__c, Question__c, Review_Requirement__c, Error_Options__c, Hide_Errors_and_Causes__c,
                                         LicenseType__c,Does_the_Element_Apply_to_Case__c,NA_Reason_Options__c,Section__c
                                         FROM Review_Question__c 
                                         WHERE Review_Type__c = 'Provider' AND (LicenseType__c = :licenseType OR LicenseType__c = null) AND Active__c = true
                                         ORDER BY Order__c ASC])
            {
                String elementApplyToCase = qn.Does_the_Element_Apply_to_Case__c?'Y':null;
                List<Map<String, String>> NAReasonList = new List<Map<String, String>>();
                NAReasonList.add(new Map<String, String> {'value'=>'', 'label'=>'--None--'});
                if(!String.isBlank(qn.NA_Reason_Options__c)){
                    List<String> options = qn.NA_Reason_Options__c.split(';');
                    options.sort();
                    for(String option : options){
                        NAReasonList.add(new Map<String, String> {'value'=>option, 'label'=>NAReasonMap.get(option)});
                    }
                }
                Provider_Review_Response__c rsp = new Provider_Review_Response__c(Review_Question__c = qn.Id,Element_Apply_to_Case__c=elementApplyToCase,ProviderReview_QuestionMain__c='',Section__c=qn.Section__c); //Added Section__c for CCCAP-13277
                List<Map<String, String>> errorsList = new List<Map<String, String>>();
                if(!String.isBlank(qn.Error_Options__c)){
                    List<String> options = qn.Error_Options__c.split(';');
                    options.sort();
                    for(String option : options){
                        errorsList.add(new Map<String, String> {'value'=>option, 'label'=>errorsMap.get(option)});
                    }
                }
                List<Map<String, String>> elementOptionsList = new List<Map<String, String>>();
                for(Schema.PicklistEntry pe : elementPicklistValues){
                    if(pe.getValue() != 'NA' || !String.isBlank(qn.NA_Reason_Options__c)){
                        elementOptionsList.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
                    }
                }
                responseWrapper wrp = new responseWrapper();
                wrp.questionRec = qn;
                wrp.responseRec = rsp;
                wrp.errorOptions = errorsList;
                wrp.elementQuestionOptions = elementOptionsList;
                wrp.NAReasonOptions = NAReasonList;
                responseWrapperList.add(wrp);
                objectData.put('responseWrapperList', responseWrapperList);
            }
        }
        else if(objectName == 'Provider_Review__c')
        {
            List<Provider_Review__c> existingReview = new List<Provider_Review__c>();
            
            Map<Id, Provider_Review_Response__c> questionRespMap = new Map<Id, Provider_Review_Response__c>();
            Integer errorCount = 0;
            system.debug('screenMode '+screenMode );
            if(screenMode == 'VIEW'){ // VIEW
                objectData.put('screenMode', 'VIEW');
                existingReview = [SELECT Id, toLabel(Review_Status__c), Reviewer_Name__c, Reviewer_Title__c, toLabel(Improper_Payment__c), Improper_Payment_Amount__c, 
                                  createdDate, createdBy.Name, createdBy.Profile.Name, toLabel(License_Type__c),toLabel(CDE_TYPE_PROVR__c),toLabel(CDE_REASON_END_AGRMT__c),
                                  toLabel(Sample_Month__c), Sample_Year__c, IsSubmitted__c,toLabel(Quality_of_Rating__c),
                                  toLabel(Attendance_Tracking__c),toLabel(License_Status__c),toLabel(Recovery_Needed__c),Recovery_Amount__c,
                                  Fiscal_Agreement_Start_Date__c,Fiscal_Agreement_End_Date__c,Provider__c,Provider_Fiscal_Agreement__c,
                                  No_of_Children_in_care__c,toLabel(Attendance_Recorded__c)
                                  FROM Provider_Review__c WHERE Id = :recordId ORDER BY createdDate DESC LIMIT 1];
                
                for(Provider_Review_Response__c resp : [SELECT Id, toLabel(ProviderReview_QuestionMain__c), toLabel(ProviderReview_Error1__c), toLabel(ProviderReview_Cause1__c),
                                                        toLabel(ProviderReview_Error2__c), toLabel(ProviderReview_Cause2__c), toLabel(ProviderReview_Error3__c), toLabel(ProviderReview_Cause3__c),
                                                        toLabel(ProviderReview_Error4__c), toLabel(ProviderReview_Cause4__c), Observation_Details_Comments__c, toLabel(Action_Required__c),
                                                        Action_Taken__c, Action_Date__c, Provider_Review__c, Review_Question__c, toLabel(Causes_Payment_Error__c),
                                                        Element_Apply_to_Case__c,toLabel(ProviderReview_NA_Reason__c),Section__c
                                                        FROM Provider_Review_Response__c WHERE Provider_Review__c = :existingReview[0].Id]){
                                                            questionRespMap.put(resp.Review_Question__c, resp);
                                                        }
            } else { // EDIT
                objectData.put('screenMode', 'EDIT');
                existingReview = [SELECT Id, Review_Status__c, Reviewer_Name__c, Reviewer_Title__c, Improper_Payment__c, Improper_Payment_Amount__c, 
                                  createdDate, createdBy.Name, createdBy.Profile.Name, License_Type__c,CDE_TYPE_PROVR__c,CDE_REASON_END_AGRMT__c,
                                  Sample_Month__c, Sample_Year__c, IsSubmitted__c,Quality_of_Rating__c,
                                  Fiscal_Agreement_Start_Date__c,Fiscal_Agreement_End_Date__c,Provider__c,Provider_Fiscal_Agreement__c,
                                  Attendance_Tracking__c,License_Status__c,Recovery_Needed__c,Recovery_Amount__c,No_of_Children_in_care__c,Attendance_Recorded__c
                                  FROM Provider_Review__c WHERE Id = :recordId ORDER BY createdDate DESC LIMIT 1];
                
                for(Provider_Review_Response__c resp : [SELECT Id, ProviderReview_QuestionMain__c, ProviderReview_Error1__c, ProviderReview_Cause1__c,
                                                        ProviderReview_Error2__c, ProviderReview_Cause2__c, ProviderReview_Error3__c, ProviderReview_Cause3__c,
                                                        ProviderReview_Error4__c, ProviderReview_Cause4__c, Observation_Details_Comments__c, Action_Required__c,
                                                        Action_Taken__c, Action_Date__c, Provider_Review__c, Review_Question__c, Causes_Payment_Error__c,
                                                        Element_Apply_to_Case__c,ProviderReview_NA_Reason__c,Section__c
                                                        FROM Provider_Review_Response__c WHERE Provider_Review__c = :existingReview[0].Id]){
                                                            questionRespMap.put(resp.Review_Question__c, resp);
                                                            if(resp.ProviderReview_QuestionMain__c == 'NO'){
                                                                errorCount++;
                                                            }
                                                        }
                objectData.put('errorCount', errorCount);
            }
            // if callingContext is not init the licenseType will be initialized from other Method
            if(callingContext == 'init' && existingReview[0].CDE_TYPE_PROVR__c!=null){
                // this is the licenseType of existing Provider Review Record for View/Edit mode.
                getLicenseTypeOnProvType(existingReview[0].CDE_TYPE_PROVR__c);
            }
            objectData.put('licenseType', licenseType);
            objectData.put('providerTypeLabel', providerTypeLabel);
            objectData.put('providerReviewObj', existingReview[0]);
            objectData.put('reviewerName', existingReview[0].createdBy.Name);
            objectData.put('reviewerTitle', existingReview[0].createdBy.Profile.Name);
            if(String.isEmpty(licenseType)){
                GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'providerReviewApexController', Method__c = 'getInitOnValid', Exception_Message__c = 'License type to fetch review questions is Null', Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'getInitOnValid','Class__c'=>'providerReviewApexController'});
            }
            for(Review_Question__c qn : [SELECT Id, Order__c, Element__c, Question__c, Review_Requirement__c, Error_Options__c, Hide_Errors_and_Causes__c,LicenseType__c,Does_the_Element_Apply_to_Case__c,
                                         NA_Reason_Options__c,Section__c 
                                         FROM Review_Question__c 
                                         WHERE Review_Type__c = 'Provider' AND (LicenseType__c = :licenseType OR LicenseType__c = null) AND Active__c = true
                                         ORDER BY Order__c ASC]){
                                             if((screenMode == 'VIEW' && questionRespMap.containsKey(qn.Id)) || 
                                                ( screenMode!='VIEW' && questionRespMap.containsKey(qn.Id) && existingReview[0]?.IsSubmitted__c) ||
                                                ( screenMode!='VIEW' && existingReview[0]?.IsSubmitted__c!=true) ||
                                                ( screenMode!='VIEW' && existingReview[0]?.IsSubmitted__c && qn.Section__c == 'Attendance') ) // Added last condition to allow the attendance questions to be loaded even when there is no response after submission in edit screen, CCCAP-14431
                                             {
                                                 List<Map<String, String>> errorsList = new List<Map<String, String>>();
                                                 if(!String.isBlank(qn.Error_Options__c)){
                                                     List<String> options = qn.Error_Options__c.split(';');
                                                     options.sort();
                                                     for(String option : options){
                                                         errorsList.add(new Map<String, String> {'value'=>option, 'label'=>errorsMap.get(option)});
                                                     }
                                                 }
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
                                                 for(Schema.PicklistEntry pe : elementPicklistValues){
                                                     if(pe.getValue() != 'NA' || !String.isBlank(qn.NA_Reason_Options__c)){
                                                         elementOptionsList.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
                                                     }
                                                 }
                                                 responseWrapper wrp = new responseWrapper();
                                                 wrp.questionRec = qn;
                                                 if(questionRespMap.containsKey(qn.Id)){
                                                     wrp.responseRec = questionRespMap.get(qn.Id);
                                                 }
                                                 else{
                                                     Provider_Review_Response__c rsp = new Provider_Review_Response__c(Review_Question__c = qn.Id,Section__c=qn.Section__c); //added Section__c for CCCAP-13277
                                                     wrp.responseRec = rsp;
                                                 }
                                                 wrp.errorOptions = errorsList;
                                                 wrp.NAReasonOptions = NAReasonList;
                                                 wrp.elementQuestionOptions = elementOptionsList;
                                                 responseWrapperList.add(wrp);
                                             }
                                         }
            objectData.put('responseWrapperList', responseWrapperList);
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    @auraEnabled
    public static LightningServerResponse handleSample_MY_Update(String recordId,String providerId,String objectName, String sampleMonth, String sampleYear,String countyId,String FA_Id){
        String message='';
        provId = providerId; //added for CCCAP-13277
        cntyId = countyId; //added for CCCAP-13277
        sampleM = sampleMonth; //added for CCCAP-13277
        sampleY = sampleYear; //added for CCCAP-13277
        Boolean claimFoundInMonth= false; //CCCAP-13277
        Map<String, Object> objectData = new Map<String, Object>();
        List<responseWrapper> responseWrapperList = new List<responseWrapper>();
        Boolean isSuccessful = true;
        String CDE_TYPE_PROVR,CDE_TYPE_LICENSE,CDE_STATUS_PROVR,QUALITY_RATING;
        //CCCAP-13392
        Date todayDate = Date.Today();
        //End CCCAP-13392
        Date sampleStartDate = Date.newInstance(Integer.valueOf(sampleYear),Integer.valueOf(sampleMonth),1);
        Date sampleEndDate = sampleStartDate.addMonths(1).addDays(-1);
        List<T_CHATS_PROVR_STATUS__c> provs = new List<T_CHATS_PROVR_STATUS__c>([select id,CDE_TYPE_PROVR__c,CDE_TYPE_LICENSE__c ,CDE_STATUS_PROVR__c,TXT_CHATS_RATING__c,
                                                                                 createddate
                                                                                 FROM T_CHATS_PROVR_STATUS__c where id=:providerId]);
        List<T_PROVR_FISCAL_AGREMENT__c> FArecord = new List<T_PROVR_FISCAL_AGREMENT__c>([select id,DTE_BEGIN_AGRMT__c,DTE_END_AGRMT__c
                                                                                          FROM T_PROVR_FISCAL_AGREMENT__c where id=:FA_Id]);
        if(!provs.isEmpty() && !FArecord.isEmpty()){
            // New Comparison with as part of CCCAP-13392

            if (sampleStartDate.year() < FArecord[0].DTE_BEGIN_AGRMT__c.year() || 
                (sampleStartDate.year() == FArecord[0].DTE_BEGIN_AGRMT__c.year() && sampleStartDate.month() < FArecord[0].DTE_BEGIN_AGRMT__c.month()) || 
                (sampleStartDate.year() == FArecord[0].DTE_BEGIN_AGRMT__c.year() && sampleStartDate.month() == FArecord[0].DTE_BEGIN_AGRMT__c.month() && todayDate < FArecord[0].DTE_BEGIN_AGRMT__c )) {
                    isSuccessful = false;
                	message = 'The Sample Month and Year cannot be before the Fiscal Agreement Effective Begin Date.';
                }
            else if(provs[0].createddate<=sampleEndDate){
                Map<String,String> licenseWrapper = getLicenseDetailsBySampleMonthYear(providerId,sampleMonth,sampleYear);
                CDE_STATUS_PROVR = licenseWrapper.containsKey('CDE_STATUS_PROVR__c')?licenseWrapper.get('CDE_STATUS_PROVR__c'):(String)provs[0].get('CDE_STATUS_PROVR__c');
                CDE_TYPE_LICENSE = licenseWrapper.containsKey('CDE_TYPE_LICENSE__c')?licenseWrapper.get('CDE_TYPE_LICENSE__c'):(String)provs[0].get('CDE_TYPE_LICENSE__c');
                CDE_TYPE_PROVR = licenseWrapper.containsKey('CDE_TYPE_PROVR__c')?licenseWrapper.get('CDE_TYPE_PROVR__c'):(String)provs[0].get('CDE_TYPE_PROVR__c');
                QUALITY_RATING = licenseWrapper.containsKey('TXT_CHATS_RATING__c')?licenseWrapper.get('TXT_CHATS_RATING__c'):(String)provs[0].get('TXT_CHATS_RATING__c');
                objectData.put('CDE_STATUS_PROVR__c',CDE_STATUS_PROVR);
                objectData.put('CDE_TYPE_LICENSE__c',CDE_TYPE_LICENSE);
                objectData.put('CDE_TYPE_PROVR__c',CDE_TYPE_PROVR);
                objectData.put('TXT_CHATS_RATING__c',QUALITY_RATING);
            }
            if(isSuccessful==true){
                if(CDE_TYPE_PROVR!= null){
                    List<AggregateResult> aggrs = [select COUNT_DISTINCT(IDN_CLIENT__c) from T_AUTH__c where IDN_PROVR__c =:providerId and CDE_County__c =:countyId and DTE_BEGIN_EFFV_AUTH__c <=: sampleEndDate  and DTE_END_EFFV_AUTH__c >=: sampleStartDate];
                    objectData.put('childrenInCare',aggrs[0].get('expr0'));
                    
                    // this is the licenseType decided on selected Sample Month/Year
                    if(objectData.get('CDE_TYPE_PROVR__c')!=null){
                        getLicenseTypeOnProvType((String)objectData.get('CDE_TYPE_PROVR__c'));
                    }
                    objectData.put('licenseType',licenseType);
                    objectData.put('providerTypeLabel',providerTypeLabel);
                    providerReviewApexController.objectName = objectName;
                    providerReviewApexController.recordId = recordId;            
                    return getInitOnValid(objectData,'updateSample_MY');
                }else{
                    isSuccessful = false;
                    message = 'Provider Type does not exist for selected Sample Month/Year.';
                }
            }
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    public static LightningServerResponse deleteProviderReview(String recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Provider_Review__c lastDraftReview = [SELECT Id FROM Provider_Review__c WHERE Id = :recordId LIMIT 1];
            if(Schema.sObjectType.Provider_Review__c.isDeletable()){
                delete lastDraftReview;
            }else{
                isSuccessful = false;
                message = 'Insufficient object-level delete permission for Provider Review';
            }
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    public static LightningServerResponse deleteProviderReviewButton(String recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        LightningServerResponse lsr = checkEligibility(recordId,'EDIT', true,false);
        if(lsr.isSuccessful){
            String accessLevel = (String)(lsr.objectData).get('accessLevel');
            if(accessLevel == 'reviewer' || accessLevel == 'admin'){
                if(Schema.sObjectType.Provider_Review__c.isDeletable()){
                    Database.delete(recordId);
                    objectData.put('parentFARecord',(lsr.objectData).get('parentFARecord'));
                }else{
                    isSuccessful = false;
                    message = 'Insufficient object-level delete permission for Provider Review';
                }
            } else {
                isSuccessful = false;
                message = 'This record has restricted access. Please contact your supervisor if access is required.';
            }
        } else {
            isSuccessful = false;
            message = lsr.errorMessage;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    @AuraEnabled
    public static LightningServerResponse saveProviderReview(String providerReviewObj, String responsesRecords, String screenMode, String methodName, Boolean hasClaim){
        Map<String, Object> objectData = new Map<String, Object>();
        savepoint sp = database.setsavepoint();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Map<Id,Provider_Review_Response__c> responsesToBeDeleted = new Map<Id,Provider_Review_Response__c>();
            Provider_Review__c providerReview = (Provider_Review__c)JSON.deserialize(providerReviewObj, Provider_Review__c.class);
            List<Provider_Review_Response__c> responsesRecords1 = (List<Provider_Review_Response__c>)JSON.deserialize(responsesRecords, List<Provider_Review_Response__c>.class);
            List<Provider_Review_Response__c> respToUpsert = new List<Provider_Review_Response__c>();
            if(methodName == 'doSubmit' && Schema.sObjectType.Provider_Review__c.fields.IsSubmitted__c.isCreateable() && Schema.sObjectType.Provider_Review__c.fields.IsSubmitted__c.isUpdateable()){
                providerReview.IsSubmitted__c = true;
            }
            if(screenMode == 'NEW' && providerReview.Change_Indicator__c == null){
                providerReview.Change_Indicator__c = null;
            }
            //Added as part of CCCAP-14322
            if(screenMode == 'NEW' && providerReview.Attendance_Recorded__c == null){
                providerReview.Attendance_Recorded__c = null;
            }
            Database.upsert(providerReview);
            objectData.put('providerReviewObj', providerReview);
            responsesToBeDeleted = new Map<Id,Provider_Review_Response__c>([SELECT Id FROM Provider_Review_Response__c 
                                                                            WHERE Provider_Review__c = :providerReview.Id]);
            if(providerReview.CDE_TYPE_PROVR__c!=null){
                getLicenseTypeOnProvType(providerReview.CDE_TYPE_PROVR__c);                
            }
            
            if(String.isEmpty(licenseType)){
                GenericDMLHandler.insertRecords(new List<Exception_Log__c> {(new Exception_Log__c(Class__c = 'providerReviewApexController', Method__c = 'saveProviderReview', Exception_Message__c = 'License type is null after upsert of case review record', Exception_Type__c = 'Error'))}, new Map<String, Object>{'Method__c'=>'saveProviderReview','Class__c'=>'caseReviewApexController'});
            }
            //added for CCCAP-13277
            for(Provider_Review_Response__c resp : responsesRecords1){
                if(screenMode == 'NEW' && Schema.sObjectType.Provider_Review_Response__c.fields.Provider_Review__c.isCreateable() || resp.Provider_Review__c == null || providerReview.Change_Indicator__c=='N'){
                    resp.Provider_Review__c = providerReview.Id;
                }
                if(hasClaim == false && resp.Section__c == 'Claim'){
                    if(resp.id!=null){
                        responsesToBeDeleted.put(resp.Id,resp);
                    }
                }else if(providerReview.Attendance_Recorded__c == 'N' && resp.Section__c == 'Attendance'){
                    if(resp.id!=null){
                        responsesToBeDeleted.put(resp.Id,resp);
                    }
                }
                else{
                    if(resp.id!=null){
                        responsesToBeDeleted.remove(resp.Id);
                    }
                    respToUpsert.add(resp);                    
                }
            }
            for(Database.upsertResult saveResult:Database.upsert(respToUpsert,true)){
                if(!saveResult.isSuccess()){
                    isSuccessful = false;
                    message = saveResult.getErrors()[0].getMessage();
                }
            }
            if(!responsesToBeDeleted.isEmpty()){
                GenericDMLHandler.deleteRecords(responsesToBeDeleted.values(), new Map<String, Object>{'Method__c'=>'saveProviderReview Delete', 'Class__c'=>'caseReviewApexController'});
            }
            /* commented out as part of CCCAP-14322, deactivating T232
            if(methodName == 'doSubmit' && Schema.sObjectType.Task.fields.Subject.isCreateable() && Schema.sObjectType.Task.fields.Description.isCreateable() &&
               Schema.sObjectType.Task.fields.ActivityDate.isCreateable() && Schema.sObjectType.Task.fields.WhatId.isCreateable() && 
               Schema.sObjectType.Task.fields.OwnerId.isCreateable() && Schema.sObjectType.Task.isCreateable()){
                   T_PROVR_FISCAL_AGREMENT__c provFiscal = [SELECT Id,ID_SERVICE__c, CDE_COUNTY__r.Name FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id =: providerReview.Provider_Fiscal_Agreement__c LIMIT  1];
                   
                   Task t = new Task();
                   t.Subject = Label.Task_T232_Subject;
                   t.Description = (Label.Task_T232_Description).replace('{!countyName}', provFiscal?.CDE_COUNTY__r?.Name);
                   t.ActivityDate = System.today().addDays(5);
                   t.WhatId = provFiscal.ID_SERVICE__c;
                   t.OwnerId = User_and_Email_Settings__c.getInstance('T232 Assignee').Value__c;
                   GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'saveCaseReview 2', 'Class__c'=>'providerReviewApexController'});
               }*/
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        if(isSuccessful == false){
            database.rollback(sp);
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    public static LightningServerResponse checkRecordAccess(String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Boolean isCountyMatch = false;
            Boolean isQueueMember = false;
            // removing profile.name since using custom permission CCCAP-14993
            User u = [SELECT Id, Name, Owner_County__c, Common_County__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Provider_Review__c providerReviewRec = [SELECT Id, Reviewee__c, Provider_Fiscal_Agreement__c, Provider_Fiscal_Agreement__r.CDE_COUNTY__c, Provider_Fiscal_Agreement__r.CDE_COUNTY__r.Name,Attendance_Recorded__c FROM Provider_Review__c WHERE Id = :recordId LIMIT 1];
            objectData.put('parentFARecord', providerReviewRec.Provider_Fiscal_Agreement__c);
            isCountyMatch = checkCountyWithUserCounty(providerReviewRec.Provider_Fiscal_Agreement__r.CDE_COUNTY__c, u);
            for(GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :((providerReviewRec.Provider_Fiscal_Agreement__r.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors')]){
                if(gm.UserOrGroupId == u.Id){
                    isQueueMember = true;
                }
            }
            if(UserInfo.getUserId() == providerReviewRec.Reviewee__c){ // Added by Rishav for CCCAP-7895
                isQueueMember = true; // To provide access to Reviewee outside queue members
            }
            // Replacing profile by sing custom permission CCCAP-14993
            if(!isCountyMatch && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                isSuccessful = false;
                message = 'The county of the Provider Agreement Fiscal does not match your assigned county(ies).';
            }
            //Replacing profile.name using custom permission CCCAP-14993
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
    public static LightningServerResponse getVFBaseURL(){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            objectData.put('sfUrl',ContinuationController.getVFBaseURL());
        }catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }        
        return new LightningServerResponse(isSuccessful, message, objectData); 
    }
    @auraEnabled
    public static LightningServerResponse sumbitForStateReversal(String recordId, String taskComment){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            List<User> u = [SELECT Id, Name FROM User WHERE Id = :User_and_Email_Settings__c.getInstance('T121 Assignee').Value__c LIMIT 1];
            List<Provider_Review__c> pr = [SELECT Id, Name, Reviewee__c,Attendance_Recorded__c FROM Provider_Review__c WHERE Id = :recordId LIMIT 1];
            if(!u.isEmpty() && !pr.isEmpty()){
                // Replacing profile using custom permission CCCAP-14993
                if(UserInfo.getUserId() == pr[0].Reviewee__c && !FeatureManagement.checkPermission('System_Administrator')){
                    isSuccessful = false;
                    message = Label.Provider_Error_StateReversal;
                }
                if(isSuccessful && Schema.sObjectType.Task.isCreateable() && Schema.sObjectType.Task.fields.Description.isCreateable() &&
                   Schema.sObjectType.Task.fields.ActivityDate.isCreateable() && Schema.sObjectType.Task.fields.WhatId.isCreateable() && 
                   Schema.sObjectType.Task.fields.OwnerId.isCreateable() && Schema.sObjectType.Task.fields.Subject.isCreateable()){
                       objectData.put('userName', u[0].Name);
                       objectData.put('recordName', pr[0].Name);
                       Task t = new Task();
                       t.Subject = Label.Task_T234_Subject;
                       t.Description = taskComment;
                       t.ActivityDate = System.today().addDays(5);
                       t.WhatId = recordId;
                       t.OwnerId = u[0].Id;
                       GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'sumbitForStateReversal 1', 'Class__c'=>'providerReviewApexController'});
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
    public static LightningServerResponse submitToReviewee(String revieweeId, String recordId){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            Boolean isCountyMatch = false;
            Boolean isQueueMember = false;
            //CCCAP-14993 removing profile.name since using permission set
            List<User> u = [SELECT Id, Name, Owner_County__c, Common_County__c FROM User WHERE Id = :revieweeId LIMIT 1];
            List<Provider_Review__c> pr = [SELECT Id, Reviewee__c, Provider__c,Provider__r.Name,Provider_Fiscal_Agreement__r.CDE_COUNTY__c, Provider_Fiscal_Agreement__r.CDE_COUNTY__r.Name,Attendance_Recorded__c FROM Provider_Review__c WHERE Id = :recordId LIMIT 1];
            if(!u.isEmpty() && !pr.isEmpty()){
                isCountyMatch = checkCountyWithUserCounty(pr[0].Provider_Fiscal_Agreement__r.CDE_COUNTY__c, u[0]);
                String countyQueueName = Test.isRunningTest() ? 'Denver_Lead_Workers_Supervisors' : (pr[0].Provider_Fiscal_Agreement__r.CDE_COUNTY__r.Name).replace(' ', '_') + '_Lead_Workers_Supervisors';
                for(GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName = :countyQueueName]){
                    if(gm.UserOrGroupId == u[0].Id){
                        isQueueMember = true;
                    }
                }
                if(!isCountyMatch || !isQueueMember){
                    isSuccessful = false;
                    message = Label.ProvReview_Error_RevieweeCountyError;
                }
                // Start: Added by Rishav for CCCAP-7603
                //CCCAP-14993 Using custom permission instead of profile
                if(UserInfo.getUserId() == pr[0].Reviewee__c && !FeatureManagement.checkPermission('System_Administrator')){
                    isSuccessful = false;
                    message = Label.ProviderReview_Error_RevieweeError;
                }
                // End: CCCAP-7603
                if(isSuccessful && Schema.sObjectType.Task.isCreateable() && Schema.sObjectType.Task.fields.Description.isCreateable() &&
                   Schema.sObjectType.Task.fields.ActivityDate.isCreateable() && Schema.sObjectType.Task.fields.WhatId.isCreateable() && 
                   Schema.sObjectType.Task.fields.OwnerId.isCreateable() && Schema.sObjectType.Task.fields.Subject.isCreateable() &&
                   Schema.sObjectType.Provider_Review__c.fields.Reviewee__c.isUpdateable()){
                       objectData.put('userName', u[0].Name);
                       objectData.put('provNumber', pr[0].Provider__r.Name);
                       Task t = new Task();
                       t.Subject = Label.Task_T231_Subject;
                       t.Description = Label.Task_T231_Description;
                       t.ActivityDate = System.today().addDays(5);
                       t.WhatId = pr[0].Provider__c;
                       t.OwnerId = revieweeId;
                       GenericDMLHandler.insertRecords(new List<Task>{t}, new Map<String, Object>{'Method__c'=>'submitToReviewee 1', 'Class__c'=>'providerReviewApexController'});
                       pr[0].Reviewee__c = revieweeId;
                       GenericDMLHandler.updateRecords(new List<Provider_Review__c>{pr[0]}, new Map<String, Object>{'Method__c'=>'submitToReviewee 2', 'Class__c'=>'providerReviewApexController'});
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
    /*******************************************************************************************************************************
---------------------------------------------------Private Methods for Internal Use---------------------------------------------------
**********************************************************************************************************************************************/
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    private static void getLicenseTypeOnProvType(string providerType){
        for(PicklistValueInfo pvInfo : [select Id, Value, Label from PicklistValueInfo where EntityParticle.EntityDefinition.QualifiedApiName='T_CHATS_PROVR_STATUS__c' and isactive=true and EntityParticle.DeveloperName in('CDE_TYPE_PROVR')]){
            if(pvInfo.label.equalsIgnoreCase(providerType) || pvInfo.Value.equalsIgnoreCase(providerType)){
                licenseType = ((String)pvInfo.Label).containsIgnoreCase('exempt')?'Quality Exempt Provider':'Licensed';    
                providerTypeLabel = pvInfo.Label;
            }
        }
    }
    private static Boolean checkCountyWithUserCounty(Id countyId, User user){
        Boolean countyMatched = true;
        //Replacing profile references as part of CCCAP-14993
        List<PermissionSetAssignment> psa = [SELECT Id,AssigneeId,PermissionSet.Name FROM PermissionSetAssignment where AssigneeId=:User.Id and PermissionSet.name!='System_Administrator_PS' and PermissionSet.Name!='CCCAP_Program_Internal_Team'];
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
    private static List<Map<String, String>> getPicklistOptions(Schema.DescribeFieldResult fieldResult){
        List<Map<String, String>> optionsList = new List<Map<String, String>>();
        List<Schema.PicklistEntry> PicklistValues = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pe : PicklistValues){
            optionsList.add(new Map<String, String> {'value'=>pe.getValue(), 'label'=>pe.getLabel()});
        }
        return optionsList;
    }
    public static Map<String,String> getLicenseDetailsBySampleMonthYear(String providerId, String sampleMonth, String sampleYear){
        Map<String,String> response = new Map<String,String>();
        
        Date startDate = Date.newInstance(Integer.valueOf(sampleYear),Integer.valueOf(sampleMonth),1);
        Date endDate = startDate.addMonths(1).addDays(-1);
        Map<String,String> beforeSampleMonthMap = new Map<String,String>();
        Map<String,String> afterSampleMonthMap = new Map<String,String>();
        List<String> fieldsToCheck = new List<String>{'CDE_STATUS_PROVR__c','CDE_TYPE_LICENSE__c','CDE_TYPE_PROVR__c','TXT_CHATS_RATING__c'};
            for(T_CHATS_PROVR_STATUS__History provHis : [SELECT Id, IsDeleted, ParentId, CreatedById, CreatedDate, Field, DataType, OldValue, NewValue 
                                                         FROM T_CHATS_PROVR_STATUS__History 
                                                         WHERE ParentId =:providerId AND field IN :fieldsToCheck
                                                         ORDER BY createddate desc])
        {
            String field = provHis.field;
            String newValue = (String)provHis.NewValue;
            String oldValue = (String)provHis.oldValue;
            
            // history records within Sample month End date
            if(provHis.createdDate<=endDate ){
                // history records within Sample month
                if(provHis.createdDate >= startDate){
                    if(!response.containsKey(field)){	
                        response.put(field,newValue);                        
                    }    
                }// history records before Sample month
                else if(!beforeSampleMonthMap.containsKey(field)){
                    beforeSampleMonthMap.put(field,newValue);
                }
            }// history records after Sample month
            else{
                afterSampleMonthMap.put(field,OldValue);
            }
        }
        system.debug('before Sample Month '+beforeSampleMonthMap+' after Sample month '+afterSampleMonthMap+' within Sample Month'+response);
        for(String field : fieldsToCheck){
            if(!response.containsKey(field)){
                if(beforeSampleMonthMap.containsKey(field)){
                    response.put(field,beforeSampleMonthMap.get(field)); 
                }else if(afterSampleMonthMap.containsKey(field)){
                    response.put(field,afterSampleMonthMap.get(field));
                }
            }
        }
        return response;
    }
    public class responseWrapper {
        @AuraEnabled
        public Review_Question__c questionRec {get; set;}
        @AuraEnabled
        public Provider_Review_Response__c responseRec {get; set;}
        @AuraEnabled
        public List<Map<String, String>> errorOptions {get; set;}
        @AuraEnabled
        public List<Map<String, String>> elementQuestionOptions {get; set;}
        @AuraEnabled
        public List<Map<String, String>> NAReasonOptions {get; set;}
    }
}