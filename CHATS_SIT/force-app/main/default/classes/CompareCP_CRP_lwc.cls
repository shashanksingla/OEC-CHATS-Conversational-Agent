public with sharing class CompareCP_CRP_lwc implements IRequest {
    public String jsonParam;
    private static Map<String, Object > requestObj;
    
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true,'',new Map<String,Object>());
        this.jsonParam = jsonParam;
        
        if(jsonParam!=null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        }
        if (methodName == 'getAllData') { //called from compareCountyRatePlan_lwc,compareCountyPlan_lwc
            response = getAllData(getMapValue('recordId'),(Boolean)requestObj.get('isCPFlow'));
        }else if(methodName == 'saveFeedbacks'){ //called from compareCountyRatePlan_lwc,compareCountyPlan_lwc
            response = saveFeedbacks(getMapValue('recordId'),(String)requestObj.get('feedbacks'));
        }else if( methodname == 'getFeedbacks'){ // called from feedbackModal
            response = getFeedbacks(getMapValue('recordId'),Boolean.valueOf(requestObj.get('isCPFlow')));
        }else if(methodname == 'initLoad'){ // called from CP_CRP_Feedback
            response = initLoad(getMapValue('recordId'), Boolean.valueOf(requestObj.get('isCPFlow')));
        }
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    
    
    public static LightningServerResponse getAllData(string recordId,Boolean isCPFlow){
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        List<Sobject> cp_CRPRows = new List<Sobject>();
        List<T_COUNTY_RATE_AMT__c> exemptRateList = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> homeRateList = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> centerRateList = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> ApprovedExemptRateList = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> ApprovedHomeRateList = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> ApprovedCenterRateList = new List<T_COUNTY_RATE_AMT__c>();
        String countyId;
        if(recordId!=null){
            string general_Query;
            string Approved_cp_CRPQuery;
            List<String> feedbackTypes = (isCPFlow ? new list<String>{'CP'}:new list<String>{'CRP','CRP_Rate'});
            if(isCPFlow == true){
                general_Query = getSobjectQuery('T_COUNTY_PLAN__c');
                Approved_cp_CRPQuery = general_Query;
                general_Query+= ' WHERE Id =: recordId or County_Plan__c =:recordId order by Createddate asc,Action_Date__c ASC';
                Approved_cp_CRPQuery+= ' WHERE CDE_COUNTY__c=:countyId AND CDE_STATUS__c='+'\'APV\' AND DTE_BEGIN_EFFEV__c !=NULL AND (DTE_END_EFFEV__c=NULL OR DTE_END_EFFEV__c>= today) AND IND_COUNTY_PLAN_TEMPLT__c=FALSE AND ID!=:recordId  ORDER BY DTE_BEGIN_EFFEV__c DESC LIMIT 1';
                cp_CRPRows = Database.query(general_Query);
                if(!cp_CRPRows.isEmpty()){
                    countyId = (String)cp_CRPRows[0]?.get('CDE_COUNTY__c');
                }
                
            }else{
                general_Query = getSobjectQuery('T_COUNTY_RATE__c');
                Approved_cp_CRPQuery = general_Query; 
                general_Query+= ' WHERE Id =: recordId or County_Rate_Plan__c =:recordId order by createddate asc,Action_Date__c ASC';
                Approved_cp_CRPQuery+= ' WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c='+'\'APV\' AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE AND ID!=:recordId ORDER BY DTE_BEGIN_EFFV_RATE__c DESC LIMIT 1';
                cp_CRPRows = Database.query(general_Query);
                countyId = (String)cp_CRPRows[0]?.get('IDN_COUNTY__c');
            }
            List<Sobject> approvedRecord = Database.Query(Approved_cp_CRPQuery);
            if(approvedRecord!=null && approvedRecord.size()>0){
                objectData.put('approvedRecord',approvedRecord);
            }
            if(isCPFlow == true){
                objectData.put('cntyPlanRecs',cp_CRPRows);
            }else{
                objectData.put('cntyRatePlanRecs',cp_CRPRows);
                for(T_COUNTY_RATE_AMT__c cntr: [SELECT toLabel(CDE_RATE_TYPE__c) , toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c),CDE_TIER__c,  NBR_AMOUNT__c, CDE_PROVR_TYPE__c
                                                FROM T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c =:recordId 
                                                ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c , CDE_TIER__c]){
                                                    if(cntr.CDE_PROVR_TYPE__c =='EXE' && (cntr.CDE_AGE_GROUP__c == '36 - School Age' || cntr.CDE_AGE_GROUP__c == 'School Age')){
                                                        exemptRateList.add(cntr);
                                                    }else if(cntr.CDE_PROVR_TYPE__c =='HOM'){
                                                        homeRateList.add(cntr);
                                                    }else if(cntr.CDE_PROVR_TYPE__c =='CEN'){
                                                        centerRateList.add(cntr);
                                                    }  
                                                }
                if(!approvedRecord.isEmpty()){
                    for(T_COUNTY_RATE_AMT__c apprvCntr: [SELECT toLabel(CDE_RATE_TYPE__c) , toLabel(CDE_AGE_GROUP__c), toLabel(CDE_UNIT__c),CDE_TIER__c,  NBR_AMOUNT__c, CDE_PROVR_TYPE__c
                                                         FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c =:approvedRecord[0]?.Id 
                                                         ORDER BY  CDE_RATE_TYPE__c, CDE_AGE_GROUP__c , CDE_TIER__c]){                                                 
                                                             if(apprvCntr.CDE_PROVR_TYPE__c =='EXE' && (apprvCntr.CDE_AGE_GROUP__c == '36 - School Age' || apprvCntr.CDE_AGE_GROUP__c == 'School Age')){
                                                                 ApprovedExemptRateList.add(apprvCntr);
                                                             }else if(apprvCntr.CDE_PROVR_TYPE__c =='HOM'){
                                                                 ApprovedHomeRateList.add(apprvCntr);
                                                             }else if(apprvCntr.CDE_PROVR_TYPE__c =='CEN'){
                                                                 ApprovedCenterRateList.add(apprvCntr);
                                                             }  
                                                         }
                }
                
                objectData.put('ApprovedExemptRateList',ApprovedExemptRateList);
                objectData.put('ApprovedHomeRateList',ApprovedHomeRateList);
                objectData.put('ApprovedCenterRateList',ApprovedCenterRateList);
                objectData.put('exemptRateList',exemptRateList);
                objectData.put('homeRateList',homeRateList);
                objectData.put('centerRateList',centerRateList);
            }
            objectData.put('countyId',countyId);
            List<CP_CRP_Feedback__c> existingFeedbacks = [select id ,Feedback__c,Identifier__c,County__c,Section__c,feedback_type__c from CP_CRP_Feedback__c 
                                                          where County__c=:countyId and feedback_type__c IN:feedbackTypes order by feedback_type__c, Section__c asc];
            
            objectData.put('existingFeedbacks',existingFeedbacks);
            
            
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    public static lightningserverresponse getFeedbacks(string recordId,Boolean isCPFlow){
        Map<String,Object> objectData = new Map<String,Object>();
        string lastSubQuery;
        string approvedQuery;
        String countyId;
        List<String> feedbackTypes = (isCPFlow ? new list<String>{'CP'}:new list<String>{'CRP','CRP_Rate'});
        List<Sobject> lastSubmittedFeedback= new List<Sobject>();
        if(isCPFlow){
            countyId = [select Id,CDE_COUNTY__C from T_COUNTY_PLAN__C where Id=:recordId limit 1]?.CDE_COUNTY__C;
            lastSubQuery = getSobjectQuery('T_COUNTY_PLAN__c');
            approvedQuery = lastSubQuery;
            lastSubQuery+= ' WHERE County_Plan__c =:recordId order by Action_Date__c desc,createddate desc  limit 1';
            approvedQuery+= ' WHERE CDE_COUNTY__c=:countyId AND CDE_STATUS__c='+'\'APV\' AND DTE_BEGIN_EFFEV__c !=NULL AND (DTE_END_EFFEV__c=NULL OR DTE_END_EFFEV__c>= today) AND IND_COUNTY_PLAN_TEMPLT__c=FALSE AND ID!=:recordId  ORDER BY DTE_BEGIN_EFFEV__c DESC LIMIT 1';
            lastSubmittedFeedback = database.query(lastSubQuery);
        }else{
            countyId = [select Id,IDN_COUNTY__C from T_COUNTY_RATE__C where Id=:recordId limit 1]?.IDN_COUNTY__C;
            lastSubQuery = getSobjectQuery('T_COUNTY_RATE__c');
            approvedQuery = lastSubQuery;
            lastSubQuery+= ' WHERE County_Rate_Plan__c =:recordId order by Action_Date__c desc,createddate desc limit 1';
            approvedQuery+= ' WHERE IDN_COUNTY__c=:countyId AND CDE_STATUS__c='+'\'APV\' AND DTE_BEGIN_EFFV_RATE__c !=NULL AND (DTE_END_EFFV_RATE__c=NULL OR DTE_END_EFFV_RATE__c>= today) AND IND_RATE_PLAN_TEMPLT__c=FALSE AND ID!=:recordId ORDER BY DTE_BEGIN_EFFV_RATE__c DESC LIMIT 1';
            lastSubmittedFeedback = database.query(lastSubQuery);
        }
        if(countyId!=null){
            List<CP_CRP_Feedback__c> existingFeedbacks = [select id ,Feedback__c,Identifier__c,County__c,Section__c,feedback_type__c from CP_CRP_Feedback__c 
                                                          where County__c=:countyId and feedback_type__c IN:feedbackTypes order by feedback_type__c asc, Section__c asc,name asc];
            objectData.put('existingFeedbacks',existingFeedbacks);
        }        
        system.debug('lastSubQuery => '+lastSubQuery);
        if(lastSubmittedFeedback.isEmpty()){
            lastSubmittedFeedback = database.query(approvedQuery);
        }
        if(!lastSubmittedFeedback.isEmpty()){
            objectData.put('lastSubmittedFeedback',lastSubmittedFeedback!=null?lastSubmittedFeedback[0]:null);   
        }     
        return new LightningServerResponse(true, '', objectData);        
    }
    public static LightningServerResponse initLoad(string recordId,Boolean isCPFlow){
        Map<String, Object> objectData = new Map<String, Object>();
        savepoint sp = database.setsavepoint();
        Boolean isSuccessful = true;
        String message = '';
        Date beginDate;
        if(isCPFlow){
            beginDate = [select id,DTE_BEGIN_EFFEV__c from T_COUNTY_PLAN__c where id=:recordId]?.DTE_BEGIN_EFFEV__c;
        }else{
            beginDate = [select id,DTE_BEGIN_EFFV_RATE__c from T_COUNTY_RATE__c where id=:recordId]?.DTE_BEGIN_EFFV_RATE__c;
        }
        objectData.put('isFeedbackVisible',IsDateAfter_15June2025(beginDate));
        Id currentUserRoleId = UserInfo.getUserRoleId();
        List<User> users = new list<User>([Select Id from User where UserRoleId =:currentUserRoleId and UserRole.Name IN(:Label.County_Plan_Approver,:Label.Template_Administrator)]);
        Boolean isApprover = !users.isEmpty();
        objectData.put('isApprover',isApprover);
        return new LightningServerResponse(isSuccessful, message, objectData);        
    }
    public static LightningServerResponse saveFeedbacks(string recordId,String feedbacks){
        Map<String, Object> objectData = new Map<String, Object>();
        savepoint sp = database.setsavepoint();
        Boolean isSuccessful = true;
        String message = '';
        system.debug('feedbacks'+feedbacks);
        List<CP_CRP_Feedback__c> feedbacksReceived = (List<CP_CRP_Feedback__c>)JSON.deserialize(feedbacks,List<CP_CRP_Feedback__c>.class);
        try{
            Upsert feedbacksReceived;
            List<CP_CRP_Feedback__c> existingFeedbacks = [select id ,Feedback__c,Identifier__c,County__c,Section__c,feedback_type__c from CP_CRP_Feedback__c 
                                                          where Id IN:feedbacksReceived order by feedback_type__c, Section__c asc];        
            objectData.put('existingFeedbacks',feedbacksReceived);
        }catch(Exception ex){
            database.rollback(sp);
            isSuccessful = false;
            system.debug('ex'+ex.getStackTraceString());
            message = ex.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    private static String getSobjectQuery(String objectName){
        String dynamicQuery = 'SELECT ';
        SObjectType sObjectNameType = Schema.getGlobalDescribe().get(objectName);
        List<String> skipFields = new List<String>{'connectionsentid','connectionreceivedid','isdeleted','lastactivitydate','lastreferenceddate'};
            Map<String,Schema.SObjectField> sObjectFields = sObjectNameType.getDescribe().fields.getMap();
        for(String fieldName: sObjectFields.keyset())
        {
            if(skipFields.contains(fieldName))
                continue;
            DescribeFieldResult  field = sObjectFields.get(fieldName).getDescribe();
            if(String.valueOf(field.getType()).containsIgnoreCase('picklist')){
                dynamicQuery += ' toLabel('+fieldName+'),';
            }else if(String.valueOf(field.getType()).containsIgnoreCase('reference')){
                String relationshipName = field.getRelationshipName();
                if (!String.isEmpty(relationshipName)) {
                    dynamicQuery += fieldName + ', ' + relationshipName + '.Name, ';
                } else {
                    dynamicQuery += fieldName + ', ';
                }
            }else{
                dynamicQuery +=  fieldName+',';
            }
        }
        dynamicQuery = dynamicQuery.removeEnd(',');
        dynamicQuery += ' FROM '+objectName+' ';
        system.debug('dynamicQuery'+dynamicQuery);
        return dynamicQuery;
    }
    public static boolean IsDateAfter_15June2025(Date beginDate){
        boolean isDateAfter_15June2025=false;
        Date todayDate= date.today();
        DateTime dt = (DateTime)JSON.deserialize('"' + Label.CP_CRP_New_Changes_Date + '"', DateTime.class);
        Date changesDate =  date.newinstance(dt.year(), dt.month(), dt.day());
        if ( beginDate >= changesDate){
            isDateAfter_15June2025 = true;
        }
        return isDateAfter_15June2025;
    }
}