public with sharing class AuthorizationFlowApxCtrl implements IRequest{ 

    public static String EXEMPT = System.Label.Exempt_Provider_Type; // Added by Rishav for CCCAP-2618
    public String jsonParam;
    private static Map<String, Object> requestObj;

    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }
        
        if (methodName == 'checkOwnerCountyMatch') {
            response = checkOwnerCountyMatch(getMapValue('recordId'), getMapValue('fieldName'));
        } else if (methodName == 'getScheduleRecurrences') {
            response = getScheduleRecurrences(getMapValue('recordId'));
        } else if (methodName == 'isCaseEligible') {
            response = isCaseEligible(getMapValue('caseRecId'), getMapValue('individualRecId'), 
                                    (T_Auth__c)JSON.deserialize(JSON.serialize(requestObj.get('newAuthorizations')), T_Auth__c.class));
        } else if (methodName == 'careLevelOfferedByProvider') {
            response = careLevelOfferedByProvider(getMapValue('authId'), getMapValue('recordId'), 
                                                getMapValue('currentBeginDate'), getMapValue('currentProviderId'), getMapValue('currentClientId'),getMapValue('hoursPerWeekDayStr'));
        } else if (methodName == 'getAuthorizationNotesStatusValidation') {
            response = getAuthorizationNotesStatusValidation(getMapValue('authId'), 
                                                           (T_Auth__c)JSON.deserialize(JSON.serialize(requestObj.get('authNew')), T_Auth__c.class));
        } else if (methodName == 'getChildStateOptions') {
            List<PicklistOption> options = getChildStateOptions(getMapValue('recordId'));
            Map<String, Object> objectData = new Map<String, Object>();
            objectData.put('childStateOptions', options);
            response = new LightningServerResponse(true, '', objectData);
        } else if (methodName == 'getRateTypeOptions') {
            Boolean isCreate = requestObj.get('isCreate') != null ? (Boolean)requestObj.get('isCreate') : true;
            List<PicklistOption> options = getRateTypeOptions(getMapValue('authId'), isCreate, getMapValue('providerId'), 
                                                             getMapValue('beginDate'), getMapValue('clientId'));
            Map<String, Object> objectData = new Map<String, Object>();
            objectData.put('rateTypeOptions', options);
            response = new LightningServerResponse(true, '', objectData);
        } else if (methodName == 'checkChildProgram') {
            Boolean result = checkChildProgram(getMapValue('recordId'));
            Map<String, Object> objectData = new Map<String, Object>();
            objectData.put('isChildProgram', result);
            response = new LightningServerResponse(true, '', objectData);
        } else if (methodName == 'createAuthEncmbrRecords') {
            response = createAuthEncmbrRecords(getMapValue('authRecId'), getMapValue('hoursPerWeekDayStr'), getMapValue('hoursPerWeekDayRecurrStr'));
        } else if (methodName == 'updateAuthEncmbrRecordsBasedOnPatterns') {
            Boolean isUpdate = requestObj.get('isUpdate') != null ? (Boolean)requestObj.get('isUpdate') : true;
            response = updateAuthEncmbrRecordsBasedOnPatterns(getMapValue('authRecId'), getMapValue('hoursPerWeekDayStr'), 
                                                            isUpdate, getMapValue('hoursPerWeekDayRecurrStr'), getMapValue('currentMode'));
        } else if (methodName == 'validateProviders') {
            response = validateProviders(getMapValue('providerId'), getMapValue('beginDate'), 
                                       (T_SBSD_CASE__c)JSON.deserialize(JSON.serialize(requestObj.get('caseObj')), T_SBSD_CASE__c.class));
        } else if (methodName == 'fetchSCAssociations') {
            Date authBeginDate = getMapValue('authBeginDate')!=null ? Date.valueOf(getMapValue('authBeginDate')) : null;
            response = fetchSCAssociations(getMapValue('SCId'), getMapValue('providerId'), 
                                         (T_SBSD_CASE__c)JSON.deserialize(JSON.serialize(requestObj.get('caseObj')), T_SBSD_CASE__c.class), 
                                         authBeginDate);
        } else if (methodName == 'disabilityCheck') {
            response = disabilityCheck(getMapValue('individualRecId'), getMapValue('currentBeginDate'));
        } else if (methodName == 'checkCountyIndicator') {
            response = checkCountyIndicator(getMapValue('recordId'), getMapValue('beginDate'));
        } else if (methodName == 'executeTransportationFeeLogic') {
            response = executeTransportationFeeLogic(getMapValue('beginDate'), getMapValue('providerId'), getMapValue('caseCountyId'));
        } else if (methodName == 'fetchProviderClosureRecs') {
            response = fetchProviderClosureRecs(getMapValue('provRecId'), getMapValue('countyId'));
        } else if (methodName == 'callUpdate') {
            List<batchsit_t_auth_encmbr__x> lstAuthEncumbRec = convertToAuthEncumbrList(requestObj.get('lstAuthEncumbRec'));
            response = callUpdate(lstAuthEncumbRec);
        } else if (methodName == 'deleteSchedule') {
            response = deleteSchedule(getMapValue('recordId'));
        } else if(methodName == 'queryPopulateSCAssRecord'){
            response = queryPopulateSCAssRecord(getMapValue('scAssId'));
        } else if(methodName == 'upsertAuthStatus'){
            Boolean isNew = requestObj.get('isNew') != null ? (Boolean)requestObj.get('isNew') : true;
            AuthorizationStatusController.AuthStatusWrapper wrapper = AuthorizationStatusController.convertToAuthStatusWrapper(requestObj.get('authStatus'));
            batchsit_t_auth_status__x authStatus = wrapper.toExternalObject();
            response = upsertAuthStatus(authStatus, isNew);
        } else if(methodName == 'validateIfBelowSchoolAge'){
            List<batchsit_t_auth_encmbr__x> hoursPerWeekDay = 
                (List<batchsit_t_auth_encmbr__x>)JSON.deserialize(JSON.serialize(requestObj.get('hoursPerWeekDay')), List<batchsit_t_auth_encmbr__x>.class);
            response = validateIfBelowSchoolAge(getMapValue('authBeginDate'), getMapValue('clientId'), hoursPerWeekDay);
        } else if (methodName == 'finishAuthorization') {
            response = finishAuthorization(getMapValue('authId'));
        } else if (methodName == 'createSCAssociationRecord') {
            response = createSCAssociationRecord(getMapValue('authId'), getMapValue('scAssRec'), getMapValue('scAssRecOldValue'));
        } else if( methodName == 'setAuthorizationFlag'){
            Boolean isCreate = requestObj.get('isCreate') != null ? (Boolean)requestObj.get('isCreate') : true;
            Boolean isCreateCorrp = requestObj.get('isCreateCorrp') != null ? (Boolean)requestObj.get('isCreateCorrp') : false;
            Boolean createTaskT122 = requestObj.get('createTaskT122') != null ? (Boolean)requestObj.get('createTaskT122') : false;
            response = setAuthorizationFlag(getMapValue('authId'), isCreate, isCreateCorrp, createTaskT122);
        } else if(methodName == 'getSelectedScheduleRecurrence'){
            response = getSelectedScheduleRecurrence(getMapValue('recordId'));
        } else if(methodName == 'trackProviderRecordView'){
            trackProviderRecordView(getMapValue('recordId'));
            response = new LightningServerResponse(true, '', new Map<String, Object>());
        } else if (methodName == 'getLatestUPKInfo') {
            response = getLatestUPKInfo(getMapValue('clientId'), getMapValue('providerId'));
        } else if (methodName == 'getClientDetails') {
            response = getClientDetails(getMapValue('clientId'));
        } else if (methodName == 'CR215CorrBulk') {
            String authIdParam = getMapValue('authId');
            if (String.isNotBlank(authIdParam)) {
                CR215CorrBulk(new Set<Id>{authIdParam}, false);
            }
            response = new LightningServerResponse(true, 'CR215 correspondence triggered', null);
        } else if (methodName == 'getLatestAuthDetails') {
            response = getLatestAuthDetails(getMapValue('authId'));
        }
        
        return response;
    }
    
    private static String getMapValue(String fieldName){
        return (String)requestObj.get(fieldName);
    }

    @AuraEnabled
    public static LightningServerResponse getLatestAuthDetails(String authId) {
        Map<String, Object> objectData = new Map<String, Object>();
        try {
            T_AUTH__c auth = [SELECT Id, UPK_Last_Updated_date__c FROM T_AUTH__c WHERE Id = :authId LIMIT 1];
            objectData.put('UPK_Last_Updated_date__c', String.valueOf(auth.UPK_Last_Updated_date__c));
            return new LightningServerResponse(true, 'Success', objectData);
        } catch (Exception e) {
            return new LightningServerResponse(false, e.getMessage(), objectData);
        }
    }

    @AuraEnabled
    public static LightningServerResponse deleteSchedule(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<Id> recordIdsToBeDeleted = new List<Id>();
        if(String.isNotBlank(recordId)){
            recordIdsToBeDeleted.add(recordId);
            GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Method__c'=>'deleteSchedule','Class__c'=>'AuthorizationFlowApxCtrl'});
        }
        return new LightningServerResponse(isSuccessful,'Authorization Recurrence has been deleted successfully',objectData);
    }

    @AuraEnabled
    public static LightningServerResponse getScheduleRecurrences(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        if(String.isNotBlank(recordId)){
            List<Auth_Schedule_Recurrence__c> recurrenceList = new List<Auth_Schedule_Recurrence__c>();
            recurrenceList = [SELECT id,IDN_AUTH__c,DTE_Begin_Date__c,DTE_End_Date__c,Fri__c,Mon__c,RecurDay__c,Recur_Type__c,Sat__c,
                              Sun__c,Thur__c,Tue__c,Wed__c,WeekDays__c,DaysOfMonth__c FROM Auth_Schedule_Recurrence__c WHERE IDN_AUTH__c=:recordId];
            if(recurrenceList.size()>0){
                objectData.put('recurrenceList',recurrenceList);
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData); 
    }

    @AuraEnabled
    public static LightningServerResponse getSelectedScheduleRecurrence(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        if(String.isNotBlank(recordId)){
            List<Auth_Schedule_Recurrence__c> recurrenceList = new List<Auth_Schedule_Recurrence__c>();
            recurrenceList = [SELECT id,Name,IDN_AUTH__c,DTE_Begin_Date__c,DTE_End_Date__c,Fri__c,Mon__c,RecurDay__c,Recur_Type__c,Sat__c,
                              Sun__c,Thur__c,Tue__c,Wed__c,WeekDays__c,DaysOfMonth__c FROM Auth_Schedule_Recurrence__c WHERE id=:recordId];
            if(recurrenceList.size()>0){
                objectData.put('authSchRecurrObj',recurrenceList[0]);
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }

    @AuraEnabled
    public static Boolean checkChildProgram(String recordId){
        Boolean isChildProgram =false;
        if(String.isNotBlank(recordId)){
            T_SBSD_CASE__c caseRec = [SELECT Id, Program_Type__c FROM T_SBSD_CASE__c WHERE Id=:recordId LIMIT 1];
            String pgmType = caseRec.Program_Type__c != null ? caseRec.Program_Type__c : CaseHeaderApxCtrl.getChildCareProgram(recordId);
            if(pgmType == 'CW'){
                isChildProgram= true;
            }else{
                isChildProgram = false;
            }
        }
        return isChildProgram;
    }

    @AuraEnabled
    public static LightningServerResponse disabilityCheck(String childId, String beginDate){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        String caseCounty;
        beginDate = beginDate.contains('T') ? beginDate.substringBefore('T') : beginDate; // Added by Rishav to avoid 'System.TypeException: Invalid integer: 01T00:00:00'.
        List<String> dateParts = beginDate.split('-');
        Date authBeginDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
        List<T_INDIV_DSBLTY__c> disabilityList = new List<T_INDIV_DSBLTY__c>();
        if(String.isNotBlank(childId) && String.isNotBlank(beginDate)){
            for(T_INDIV_DSBLTY__c  dis : [SELECT Id FROM T_INDIV_DSBLTY__c WHERE IDN_CLIENT__c =:childId AND DTE_BEGIN_EFFV__c <=: authBeginDate AND (DTE_END_EFFV__c >=: authBeginDate OR DTE_END_EFFV__c = null)]){
                objectData.put('isChildDisable', true);
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }

    @AuraEnabled
    public static LightningServerResponse checkCountyIndicator(String recordId,String beginDate){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        String caseCounty ;
        Id recId = (Id)recordId;
        Boolean showContractToIndicator = false;
        Boolean showDropInDaysIndicator = false;
        Integer numberOfDaysDrop =0;
        Boolean protectiveServiceIndicator = false;
        List<String> dateParts = new List<String>();
        beginDate = beginDate.contains('T') ? beginDate.substringBefore('T') : beginDate; // Added by Rishav to avoid 'System.TypeException: Invalid integer: 01T00:00:00'.
        dateParts= beginDate.split('-');
        Date todayDate =  system.today();
        Date dropInDaysAuthDate ;
        Date authBeginDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
         if(todayDate > authBeginDate){
            dropInDaysAuthDate = todayDate;
        }else{
            dropInDaysAuthDate = authBeginDate;
        }
        List<T_SBSD_CASE__c> caseList = new List<T_SBSD_CASE__c>();
        if(String.isNotBlank(recordId)){
            String sObjName = recId.getSObjectType().getDescribe().getName();
            if(sObjName == 'T_SBSD_CASE__c'){
                caseList = [SELECT id, IDN_EXTNL__c, DTE_REDET_CASE__c, CDE_COUNTY__c, IDN_PROVR__c FROM T_SBSD_CASE__c WHERE Id =: recordId WITH SECURITY_ENFORCED LIMIT 1];
                if(caseList.size()>0){
                    caseCounty =caseList[0].CDE_COUNTY__c;
                    for(T_COUNTY_RATE__c rate:[SELECT id,CFS_Q1__c,CDE_STATUS__c FROM T_COUNTY_RATE__c WHERE DTE_BEGIN_EFFV_RATE__c <=: authBeginDate AND (DTE_END_EFFV_RATE__c >=: authBeginDate OR DTE_END_EFFV_RATE__c = null) AND
                                               IDN_COUNTY__c =:caseCounty AND CDE_STATUS__c='APV' AND CFS_Q1__c = 'Y' WITH SECURITY_ENFORCED LIMIT 1]){
                                                   showContractToIndicator = true;
                                               }
                     for(T_COUNTY_RATE__c rate:[SELECT id,CFS_Q1__c,CDE_STATUS__c,PAYMENT_Q14__c,PAYMENT_Q14_1__c FROM T_COUNTY_RATE__c WHERE DTE_BEGIN_EFFV_RATE__c <=: dropInDaysAuthDate AND (DTE_END_EFFV_RATE__c >=: dropInDaysAuthDate OR DTE_END_EFFV_RATE__c = null) AND
                                               IDN_COUNTY__c =:caseCounty AND CDE_STATUS__c='APV' AND PAYMENT_Q14_3__c = 'Y' AND IND_RATE_PLAN_TEMPLT__c =: false WITH SECURITY_ENFORCED LIMIT 1]){
                                                   showDropInDaysIndicator = true;
                                                   numberOfDaysDrop =Integer.valueOf(rate.PAYMENT_Q14_1__c);
                                               }
                    for(T_COUNTY_PLAN__c rate:[SELECT id,ELIGIBILITY_Q11__c,CDE_STATUS__c FROM T_COUNTY_PLAN__c WHERE DTE_BEGIN_EFFEV__c <=: authBeginDate AND (DTE_END_EFFEV__c >=: authBeginDate OR DTE_END_EFFEV__c = null) AND
                                               CDE_COUNTY__c =:caseCounty  AND CDE_STATUS__c='APV' AND ELIGIBILITY_Q11__c = 'Y' WITH SECURITY_ENFORCED LIMIT 1]){
                                                   protectiveServiceIndicator = true;
                                               }
                }
            }else{
              for(T_COUNTY_RATE__c rate:[SELECT id,CFS_Q1__c,CDE_STATUS__c,PAYMENT_Q14__c,PAYMENT_Q14_1__c FROM T_COUNTY_RATE__c WHERE DTE_BEGIN_EFFV_RATE__c <=: dropInDaysAuthDate AND (DTE_END_EFFV_RATE__c >=: dropInDaysAuthDate OR DTE_END_EFFV_RATE__c = null) AND
                                               IDN_COUNTY__c =:recordId AND CDE_STATUS__c='APV' AND PAYMENT_Q14_3__c = 'Y' AND IND_RATE_PLAN_TEMPLT__c =:false WITH SECURITY_ENFORCED LIMIT 1]){
                                                   showDropInDaysIndicator = true;
                                                   numberOfDaysDrop =Integer.valueOf(rate.PAYMENT_Q14_1__c);
                                               }
            }
        }
        objectData.put('protectiveServiceIndicator',protectiveServiceIndicator);
        objectData.put('showContractToIndicator',showContractToIndicator);
        objectData.put('showDropInDaysIndicator',showDropInDaysIndicator);
        objectData.put('numberOfDaysDrop',numberOfDaysDrop);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    // Start: Added by Rishav for CCCAP-2618
    @AuraEnabled
    public static LightningServerResponse executeTransportationFeeLogic(String beginDate, String providerId, String caseCountyId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean showTransFeeRestriction = false;
        String transFeeRestrictionValue = null;
        Date nullDate;
        beginDate = beginDate.contains('T') ? beginDate.substringBefore('T') : beginDate; // Added by Rishav to avoid 'System.TypeException: Invalid integer: 01T00:00:00'.
        List<String> dateParts = beginDate.split('-');
        Date authBeginDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
        List<T_FISCAL_RAT_FEES__c> artFees = [SELECT Id, AMT_TRANS_PROVR__c FROM T_FISCAL_RAT_FEES__c
                                              WHERE IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c <=: authBeginDate 
                                              AND IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c <=: authBeginDate AND (IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c >=: authBeginDate OR IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c =: nullDate)
                                              AND IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c <=: authBeginDate AND (IDN_FISCAL_SCH__r.DTE_END_EFFV__c >=: authBeginDate OR IDN_FISCAL_SCH__r.DTE_END_EFFV__c =: nullDate)
                                              AND IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.ID_SERVICE__c =: providerId AND IDN_FISCAL_SCH__r.IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =: caseCountyId WITH SECURITY_ENFORCED LIMIT 1];
        List<T_COUNTY_RATE__c> countyRatePlan = [SELECT Id, Name, PAYMENT_Q11_2__c, PAYMENT_Q11_3__c 
                                                 FROM T_COUNTY_RATE__c 
                                                 WHERE DTE_BEGIN_EFFV_RATE__c <=: authBeginDate AND (DTE_END_EFFV_RATE__c >=: authBeginDate OR DTE_END_EFFV_RATE__c =: nullDate) AND IDN_COUNTY__c =:caseCountyId AND CDE_STATUS__c='APV' WITH SECURITY_ENFORCED LIMIT 1];
        if(countyRatePlan.size() > 0 && artFees.Size() > 0) {
            if(artFees[0].AMT_TRANS_PROVR__c > 0 && countyRatePlan[0].PAYMENT_Q11_3__c == 'Y') {
                if(countyRatePlan[0].PAYMENT_Q11_2__c == 'ALL') {
                    showTransFeeRestriction = true;
                    transFeeRestrictionValue = 'Y';
                } else if(countyRatePlan[0].PAYMENT_Q11_2__c == 'SCHOOL-AGE') {
                    showTransFeeRestriction = true;
                    transFeeRestrictionValue = 'N';
                } else {
                    showTransFeeRestriction = false;
                    transFeeRestrictionValue = null;
                }
            }
        }
        objectData.put('showTransFeeRestriction', showTransFeeRestriction);
        objectData.put('transFeeRestrictionValue', transFeeRestrictionValue);
        return new LightningServerResponse(true, '', objectData);
    }
    // End: CCCAP-2618
    
    @AuraEnabled
    public static LightningServerResponse deleteAuthorizationRecord(String authId) { 
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        if(!String.isBlank(authId)){
            List<T_AUTH__c> authRecordList = [SELECT id,IDN_CASE__r.Id,IDN_CASE__c FROM T_AUTH__c WHERE id=:authId WITH SECURITY_ENFORCED];
            if(authRecordList.size()>0){
                    isSuccessful = true;
                    message ='Authorization deleted Successfully.';
                    objectData.put('redirect',true);
                    objectData.put('recordId',authRecordList[0].IDN_CASE__r.Id);
                    objectData.put('eventParams','{"recordId": "'+authRecordList[0].IDN_CASE__r.Id+'"}');
                    List<Id> recordIdsToBeDeleted = new List<Id>();
                for(T_AUTH__c sobj:authRecordList){
                    recordIdsToBeDeleted.add(sobj.Id);
                }
                GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(recordIdsToBeDeleted);
                GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Method__c'=>'deleteAuthorizationRecord','Class__c'=>'AuthorizationFlowApxCtrl'});
                // GenericWithoutSharingDMLOperations.deleteRecords(authRecordList, new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'deleteAuthorizationRecord'}); //Database.delete(authRecordList[0]);
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }

    @AuraEnabled
    public static LightningServerResponse checkOwnerCountyMatch(String recordId, String fieldName){
        return CHATSAuraUtility.checkOwnerCountyMatch(recordId,fieldName);
    }

    //CCCAP-690
    @AuraEnabled
    public static LightningServerResponse careLevelOfferedByProvider(String authId, String recordId, String currentBeginDate, String currentProviderId, String currentClientId, String hoursPerWeekDayStr){
        return CHATSAuraUtility.careLevelOfferedByProvider(authId, recordId, currentBeginDate, currentProviderId, currentClientId,hoursPerWeekDayStr);
    }
    
    // Added by Rishav for CCCAP-6983
    @AuraEnabled
    public static LightningServerResponse validateIfBelowSchoolAge(String authBeginDate, String clientId, List<batchsit_t_auth_encmbr__x> hoursPerWeekDay){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        Boolean isSchoolAgeRateTypeSelected = false;
	string indivExternalId;    
        try {
            for(batchsit_t_auth_encmbr__x weekDay : hoursPerWeekDay){
                String weekDayString = (JSON.serialize(hoursPerWeekDay)).toLowerCase();
                if(weekDayString.contains('"cde_type_unit_care__c":"13"') || weekDayString.contains('"cde_type_unit_care__c":"19"') || weekDayString.contains('"cde_type_unit_care__c":"25"')){
                    isSchoolAgeRateTypeSelected = true;
                }
            }
	    //Hotfix after Dec Release CHATS_1_51_0 -- CCCAP-7674 -- Start
            for (T_SBSD_INDIV__c indivRec : [select Id, IDN_EXTNL__c, Name FROM T_SBSD_INDIV__c WHERE Id =:clientId]){
                if(indivRec.IDN_EXTNL__c != null){
                    indivExternalId = indivRec.IDN_EXTNL__c;   // use the indivExternalID in query below to get the Carelevel Records 
                }
            }
            //Hotfix after Dec Release CHATS_1_51_0 -- CCCAP-7674 -- End
            List<batchsit_t_sbsd_indiv_care_level__x> careLevelList = QueryExternalObjects.query([SELECT Id, dte_begin_effv__c FROM batchsit_t_sbsd_indiv_care_level__x WHERE idn_client__c =: indivExternalId AND cde_level_care__c = '8']); // 8 = School Age (R00710.glovalValueSet)
            batchsit_t_sbsd_indiv_care_level__x careLevel = careLevelList[0];
            Date authStart = Date.valueOf(authBeginDate); 
            Date schoolAgeStart = Date.valueOf(careLevel.dte_begin_effv__c);
            if(isSchoolAgeRateTypeSelected && authStart < schoolAgeStart){
                objectData.put('showWarningBelowSchoolAge', true);
                objectData.put('warningMessageBelowSchoolAge', System.Label.auth_error_belowSchoolAge);
            }
        } catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            throw e;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }


    @AuraEnabled
    public static LightningServerResponse upsertAuthStatus(batchsit_t_auth_status__x authStatus, Boolean isNew){
        batchsit_t_auth_status__x stat = new batchsit_t_auth_status__x();
        Map<String, Boolean> objectData = new map<String, Boolean>();
        String authId ='';
        if(authStatus != null){
            if(authStatus.idn_auth__c != null){
                T_AUTH__c auth = new T_AUTH__c();
                auth = [SELECT Id, Name,CreatedById,IDN_EXTNL__c,DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id =:authStatus.idn_auth__c WITH SECURITY_ENFORCED];
                stat.idn_auth__c =auth.IDN_EXTNL__c;
                stat.cde_status_auth__c ='2';
                stat.createdbyid__c = auth.CreatedById;
                stat.lastmodifiedbyid__c =auth.CreatedById;
                stat.dte_begin_effv__c = authStatus.dte_begin_effv__c;
                stat.dte_end_effv__c = auth.DTE_END_EFFV_AUTH__c;
                stat.createddate__c = System.now();
                stat.lastmodifieddate__c = System.now();
                authId = auth.Id;
            }
        }
        if(!Test.isRunningTest()){
            return AuthorizationStatusController.upsertAuthStatus(stat,isNew,false,authId,false);
        }else{
            return new LightningServerResponse(true,'null',objectData);
        }
    }

    @AuraEnabled
    public static LightningServerResponse getAuthorizationNotesStatusValidation(String authId,T_AUTH__c authNew){
        Map<String, Boolean> objectData = new map<String, Boolean>();
        List<AuthStatusPckt> authStatusList = new List<AuthStatusPckt>();
        Boolean isSuccessful = false;
        Boolean isAuthStatus = false;
        String message;
        Set<Id> authIds = new Set<Id>();
        T_AUTH__c auth = new T_AUTH__c();
        if(authId != null){
             auth = [SELECT id,Name,IDN_EXTNL__c,CDE_IMM__c,CDE_TYPE_VERIF__c,CDE_SOURCE_VRFYD_IMMU__c,AMT_ACTV_AUTH__c,AMT_TRANSP_AUTH__c,AMT_RGSTR_AUTH__c,CDE_REL_PROVR__c, CDE_PROV_DIFF_RESI__c, CDE_PRO_REL_CHLD__c,
             IDN_SLOT_CONTRACT__c, DTE_BEGIN_SLOT__c, Protective_Services_Indicator__c, Number_of_Drop_in_Days__c, CDE_TRANS_FEE__c, CDE_CHILD_ENROLLED_IN_UPK__c, Is_UPK_Stacked__c FROM T_AUTH__c WHERE Id = :authId WITH SECURITY_ENFORCED]; 
        }
        if(authNew != null){
            if(Test.isRunningTest()){
                //commented for CCCAP-9439
                //batchsit_t_auth_status__x statBtch = new batchsit_t_auth_status__x(idn_auth__c =authId,dte_begin_effv__c =System.today(),cde_status_auth__c = '4');
              	authStatusList.add(new AuthStatusPckt(authId,Date.today(),'4','')); // authStatusList.add(statBtch);
            } else {
                //commented for CCCAP-9439
                //authStatusList=[SELECT id, dte_begin_effv__c, cde_status_auth__c, idn_auth__c FROM batchsit_t_auth_status__x WHERE idn_auth__c =:auth.IDN_EXTNL__c WITH SECURITY_ENFORCED ORDER BY ExternalId Desc LIMIT 1];
                requestParams req = new requestParams(auth.IDN_EXTNL__c,'idn_status_auth','desc','1');
                LightningServerResponse res = hitAuthStatusWebService(req);
                if(res.isSuccessful){
                    authStatusList  = (List<AuthStatusPckt>)res.objectData.get('authstatuses');
                }else{
                    return res;
                }
            }
            for(AuthStatusPckt stat : authStatusList){
                isAuthStatus = true;
                if(stat.dteBeginEffv <= System.today() && stat.cdeStatusAuth == '4'){
                    objectData.put('AuthTerminated', true);
                    if((authNew.AMT_ACTV_AUTH__c != auth.AMT_ACTV_AUTH__c) ||
                       (authNew.CDE_IMM__c != auth.CDE_IMM__c) ||
                       (authNew.CDE_TYPE_VERIF__c != auth.CDE_TYPE_VERIF__c) ||
                       (authNew.CDE_SOURCE_VRFYD_IMMU__c != auth.CDE_SOURCE_VRFYD_IMMU__c) ||
                       (authNew.AMT_TRANSP_AUTH__c != auth.AMT_TRANSP_AUTH__c) ||
                       (authNew.AMT_RGSTR_AUTH__c != auth.AMT_RGSTR_AUTH__c) ||
                       (authNew.CDE_REL_PROVR__c != auth.CDE_REL_PROVR__c) ||
                       (authNew.CDE_PRO_REL_CHLD__c != auth.CDE_PRO_REL_CHLD__c) ||
                       (authNew.CDE_PROV_DIFF_RESI__c != auth.CDE_PROV_DIFF_RESI__c) ||
                       (authNew.IDN_SLOT_CONTRACT__c != auth.IDN_SLOT_CONTRACT__c) ||
                       (authNew.DTE_BEGIN_SLOT__c != auth.DTE_BEGIN_SLOT__c) ||
                       (authNew.Protective_Services_Indicator__c != auth.Protective_Services_Indicator__c) ||
                       (authNew.Number_of_Drop_in_Days__c != auth.Number_of_Drop_in_Days__c) ||
                       (authNew.CDE_TRANS_FEE__c != auth.CDE_TRANS_FEE__c) || //modified for CCCAP-15084
                       (authNew.CDE_CHILD_ENROLLED_IN_UPK__c != auth.CDE_CHILD_ENROLLED_IN_UPK__c) || //CCCAP-15329
                       (authNew.Is_UPK_Stacked__c != auth.Is_UPK_Stacked__c)){ 
                        objectData.put('UpdateAuthorization', true);
                        isSuccessful = false;
                        break;
                    }
                    isSuccessful = true;
                }else{
                    isSuccessful = true;
                } 
            } 
        }
        if(!isAuthStatus){
            isSuccessful = true;
        }
        return new LightningServerResponse(isSuccessful,'Validation check',objectData); 
    }
    @AuraEnabled
    public static List<PicklistOption> getRateTypeOptions(String authId, Boolean isCreate, String providerId,String beginDate, String clientId){
        List<PicklistOption> rateTypeOptions = new List<PicklistOption>();
        List<batchsit_t_sbsd_indiv_care_level__x> indcareLvl = new List<batchsit_t_sbsd_indiv_care_level__x>();
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        List<T_SBSD_CASE__c> caseList = new List<T_SBSD_CASE__c>();
        List<T_PROVR_FISCAL_AGREMENT__c> provFiscalAgree = new List<T_PROVR_FISCAL_AGREMENT__c>();
        List<T_SBSD_INDIV__c> indivList = new List<T_SBSD_INDIV__c>();
        Date todayDay = System.today();
        String SA= '8';
        String clientExternalId;
        String countyId;
        Date nullDate;
        Date beginDate1, firstDayofEndMonth, endDate1;
        Set<String> rateTypeSet = new Set<String>();
        Map<String,String> rateOptionMap = new Map<String,String>();
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = T_FISCAL_SCH__c.CDE_RATE_TYPE__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            rateOptionMap.put(f.getLabel(), f.getValue());
        }  
 		// Getting values FROM rate type custom label
        Set<String> inActiveRateTypeSet = new Set<String>();
        for(String inActiveRateTypeObj: System.Label.Inactive_Rate_Type.split(';')){
            inActiveRateTypeSet.add(inActiveRateTypeObj);
        } 
 
         
        List<String> dateParts = new List<String>();
       
        if(authId != null){
            if(clientId != null && isCreate){
                indivList =[SELECT id,IDN_EXTNL__c FROM T_SBSD_INDIV__c WHERE id =:clientId];
                if(indivList.size()>0){
                    clientExternalId =indivList[0].IDN_EXTNL__c;
                }
            }
            String queryStr = 'Select id,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c,IDN_AGRMT_FISCAL__r.ID_SERVICE__c,toLabel(CDE_RATE_TYPE__c) FROM T_FISCAL_SCH__c where';
            if(isCreate){
                beginDate = beginDate.contains('T') ? beginDate.substringBefore('T') : beginDate; // Added by Rishav to avoid 'System.TypeException: Invalid integer: 01T00:00:00'.
                dateParts= beginDate.split('-');
                beginDate1 = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                caseList =[SELECT id,CDE_COUNTY__c, DTE_REDET_CASE__c FROM T_SBSD_CASE__c WHERE id=:authId];
                countyId =caseList[0].CDE_COUNTY__c;
                if(caseList[0].DTE_REDET_CASE__c != null){
                	firstDayofEndMonth = caseList[0].DTE_REDET_CASE__c.toStartOfMonth();
                    endDate1 = firstDayofEndMonth.addDays(Date.daysInMonth(firstDayofEndMonth.year(), firstDayofEndMonth.month()) - 1);
                }else {
                    if(Date.isLeapYear(beginDate1.year())){
                        endDate1 = beginDate1.addDays(366);
                    } else {
                        endDate1 = beginDate1.addDays(365);
                    }    
                } 
            }else{
                authList = [SELECT id,IDN_PROVR__c,CDE_COUNTY__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CLIENT__c,IDN_CLIENT__r.IDN_EXTNL__c FROM T_AUTH__c WHERE id=:authId];
                clientExternalId =authList[0].IDN_CLIENT__r.IDN_EXTNL__c;
                countyId =authList[0].CDE_COUNTY__c;
                providerId =authList[0].IDN_PROVR__c;
                beginDate1 = authList[0].DTE_BEGIN_EFFV_AUTH__c;
                endDate1 = authList[0].DTE_END_EFFV_AUTH__c;
            }
            if(clientExternalId != null){
                indcareLvl = [SELECT id,cde_level_care__c,idn_sbsd_indiv_care_level__c,dte_begin_effv__c,idn_client__c FROM batchsit_t_sbsd_indiv_care_level__x WHERE idn_client__c =:clientExternalId AND cde_level_care__c =:SA AND dte_begin_effv__c <=:endDate1];
            }
            if(countyId != null && countyId != ''){
                queryStr = queryStr+' IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =:countyId';
            }
            if(isCreate){
                if(providerId != null && providerId !=''){
                    queryStr = queryStr+' AND IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:providerId';
                }
                queryStr = queryStr+' AND IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c <=:beginDate1 AND (IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c >=:beginDate1 OR IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c =:nullDate)';
                queryStr = queryStr+' AND DTE_BEGIN_EFFV__c <=:beginDate1 AND (DTE_END_EFFV__c >=:beginDate1 OR DTE_END_EFFV__c =:nullDate)';
            }else{
                if(providerId != null && providerId !=''){
                    queryStr = queryStr+' AND IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:providerId';
                }
                queryStr = queryStr+' AND IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c <=:todayDay AND (IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c >=:todayDay OR IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c =:nullDate)';
                queryStr = queryStr+' AND DTE_BEGIN_EFFV__c <=:todayDay AND (DTE_END_EFFV__c >=:todayDay OR DTE_END_EFFV__c =:nullDate)';
                
            }
            Set<String> rateSet = new Set<String>();
            List<T_FISCAL_SCH__c> fiscalSchList = new List<T_FISCAL_SCH__c>();
            if(Test.isRunningTest()){
                T_FISCAL_SCH__c fis = new T_FISCAL_SCH__c(CDE_RATE_TYPE__c ='Before School;Regular');
                fiscalSchList.add(fis);
            }else{
                fiscalSchList =Database.query(queryStr);
            }
            for(T_FISCAL_SCH__c fiscalSch : fiscalSchList){
                if(fiscalSch.CDE_RATE_TYPE__c != null){
                    if((indcareLvl.size() >0)){
                        string rtType1 = fiscalSch.CDE_RATE_TYPE__c;
                        for(String s : rtType1.split(';')){
                            rateSet.add(s);
                        }
                    }else{
                        string rtType = fiscalSch.CDE_RATE_TYPE__c;
                        for(String s : rtType.split(';')){
                            if(s !='Before School' && s !='B AND A School' && s != 'After School'){
                                rateSet.add(s);
                            }
                        }
                    }
                }
            }
			if(rateSet.size()>0){
			                for(String rate :rateSet){
			                    if(rateOptionMap.containsKey(rate)){
			                        if(!inActiveRateTypeSet.contains(rateOptionMap.get(rate))){
			                            rateTypeOptions.add(new PicklistOption(
			                                rate,
			                                rateOptionMap.get(rate)
			                            )); 
			                        }
			                    }
			                }
			            } 
		}
        return rateTypeOptions;
    }
     @auraEnabled
    public static List<PicklistOption> getChildStateOptions(Id caseId){
        List<PicklistOption> options = new List<PicklistOption>();
        List<batchsit_t_indiv_eligty_detail__x> indivEligDetailList = new List<batchsit_t_indiv_eligty_detail__x>();
        Date todayDate = System.today();
        List<String> dateParts = new List<String>();
       /* if(String.isNotBlank(beginDate)){
            dateParts= beginDate.split('-');
            todayDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
        }*/
        Date nullDate ;
        Map<Id,List<T_SBSD_CASE_WTLST__c>> caseWaitMap = new Map<Id,List<T_SBSD_CASE_WTLST__c>>();
        Map<String,T_SBSD_CASE_INDIV__c> caseInvdivMap = new Map<String,T_SBSD_CASE_INDIV__c>();
        Map<String,List<batchsit_t_indiv_eligty_detail__x>> elibilityDtlMap = new Map<String,List<batchsit_t_indiv_eligty_detail__x>>();
        for(T_SBSD_CASE_WTLST__c wait : [SELECT id,IDN_CASE__c,CDE_STATUS_WTLST__c FROM T_SBSD_CASE_WTLST__c WHERE IDN_CASE__c =:caseId AND CDE_STATUS_WTLST__c = 'RFS' WITH SECURITY_ENFORCED]){
            if(!caseWaitMap.containsKey(wait.IDN_CASE__c)){
                List<T_SBSD_CASE_WTLST__c> waitLst = new List<T_SBSD_CASE_WTLST__c>();
                waitLst.add(wait);
                caseWaitMap.put(wait.IDN_CASE__c, waitLst);
            }else{
                List<T_SBSD_CASE_WTLST__c> waitLst1 = caseWaitMap.get(wait.IDN_CASE__c);
                waitLst1.add(wait);
                caseWaitMap.put(wait.IDN_CASE__c, waitLst1);
            }
        }
        for(T_SBSD_CASE_INDIV__c caseIndiv: [SELECT IDN_CLIENT__c,IDN_EXTNL__c,IDN_CASE__c, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c, IDN_CLIENT__r.IDN_STATE__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c =:caseId AND DTE_BEGIN_EFFV__c <=:todayDate AND (DTE_END_EFFV__c >=: todayDate OR DTE_END_EFFV__c =:nullDate) WITH SECURITY_ENFORCED]){
            caseInvdivMap.put(caseIndiv.IDN_EXTNL__c, caseIndiv);
        }
        if(Test.isRunningTest()){
            List<String> caseInvKeyList =new List<String>();
            caseInvKeyList.addAll(caseInvdivMap.keySet());
            batchsit_t_indiv_eligty_detail__x eliDtl = new batchsit_t_indiv_eligty_detail__x(cde_status_detail_eligty_indiv__c='EC',idn_indiv_fcompsn__c=null);
            indivEligDetailList.add(eliDtl);
            elibilityDtlMap.put(caseInvKeyList[0],indivEligDetailList);
        }else{
          indivEligDetailList = [SELECT id, ExternalId, cde_status_detail_eligty_indiv__c, idn_indiv_fcompsn__r.idn_case_indiv__c, idn_indiv_fcompsn__c
          FROM batchsit_t_indiv_eligty_detail__x 
          WHERE idn_indiv_fcompsn__r.idn_case_indiv__c IN:caseInvdivMap.keySet() AND cde_status_detail_eligty_indiv__c ='EC' WITH SECURITY_ENFORCED];
        }
        for(batchsit_t_indiv_eligty_detail__x elibDlt: indivEligDetailList){
                                                            if(!elibilityDtlMap.containsKey(elibDlt.idn_indiv_fcompsn__r.idn_case_indiv__c)){
                                                                List<batchsit_t_indiv_eligty_detail__x> lst = new List<batchsit_t_indiv_eligty_detail__x>();
                                                                lst.add(elibDlt);
                                                                elibilityDtlMap.put(elibDlt.idn_indiv_fcompsn__r.idn_case_indiv__c, lst);
                                                            }else{
                                                                List<batchsit_t_indiv_eligty_detail__x> lst2 = elibilityDtlMap.get(elibDlt.idn_indiv_fcompsn__r.idn_case_indiv__c);
                                                                lst2.add(elibDlt);
                                                                elibilityDtlMap.put(elibDlt.idn_indiv_fcompsn__r.idn_case_indiv__c, lst2);
                                                            }
                                                            
                                                        }
        for(T_SBSD_CASE_INDIV__c caseIndiv: caseInvdivMap.values()){
            if(elibilityDtlMap.containsKey(caseIndiv.IDN_EXTNL__c)){
                List<batchsit_t_indiv_eligty_detail__x> indivElig = elibilityDtlMap.get(caseIndiv.IDN_EXTNL__c);
                if(!indivElig.isEmpty()){
                    options.add(new PicklistOption(
                        caseIndiv.IDN_CLIENT__r.NAM_FIRST__c +' '+ caseIndiv.IDN_CLIENT__r.NAM_LAST__c + ' / ' 
                        + caseIndiv.IDN_CLIENT__r.IDN_STATE__c,
                        caseIndiv.IDN_CLIENT__c                 
                    ));
                }
            } 
        }
        return options;
    }
    
    @AuraEnabled
    public static LightningServerResponse getAuthEncmbrRecords(String authRecId){
        try{
            Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr = new Map<String, batchsit_t_auth_encmbr__x>();
            List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
            if(!Test.isRunningTest()){
                           fetchedEncumberence = HerokuService.authEncumbrancefetch(authRecId);
            }else{
                fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =system.today(),idn_auth__c =authRecId,cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId=authRecId));
            }
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence){
                Date careDate = anAuthEncmbr.DTE_CARE__c;
                careDateToAuthEncmbr.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(), anAuthEncmbr);
            }
            return new LightningServerResponse(true, 'Encmbrs fetched', new Map<String, object>{'careDateToAuthEncmbr' => careDateToAuthEncmbr});
        } catch(Exception ex) {
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }

    @AuraEnabled
    public static LightningServerResponse createAuthEncmbrRecords(String authRecId, String hoursPerWeekDayStr,String hoursPerWeekDayRecurrStr){
        try{
            List<batchsit_t_auth_encmbr__x> hoursPerWeekDay = 
                (List<batchsit_t_auth_encmbr__x>)JSON.deserialize(hoursPerWeekDayStr, List<batchsit_t_auth_encmbr__x>.class);
            List<Auth_Schedule_Recurrence__c> authEncumWrap = 
                (List<Auth_Schedule_Recurrence__c>)JSON.deserialize(hoursPerWeekDayRecurrStr, List<Auth_Schedule_Recurrence__c>.class);
            T_AUTH__c authRec = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_PROVR__c, IDN_PROVR__r.CDE_TYPE_PROVR__c, CDE_COUNTY__c,
                                 IDN_CASE__c, IDN_CLIENT__c, IDN_CLIENT__r.IDN_EXTNL__c, IDN_CLIENT__r.DTE_DOB__c, Protective_Services_Indicator__c 
                                 FROM T_AUTH__c WHERE id =:authRecId WITH SECURITY_ENFORCED];
            
            Date startDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
            Date endDate = authRec.DTE_END_EFFV_AUTH__c;
            Date dob36Months = authRec.IDN_CLIENT__r.DTE_DOB__c.addYears(3);
            Boolean isProviderExempt = false;
            if(EXEMPT.contains(authRec.IDN_PROVR__r.CDE_TYPE_PROVR__c)){
                isProviderExempt = true;
            }
            T_SBSD_CASE__c caseRec = [SELECT Id, Program_Type__c FROM T_SBSD_CASE__c WHERE Id=:authRec.IDN_CASE__c LIMIT 1];
            String prgType = caseRec.Program_Type__c != null ? caseRec.Program_Type__c : CaseHeaderApxCtrl.getChildCareProgram(authRec.IDN_CASE__c);

            List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
            List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
            Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
            List<batchsit_t_sbsd_indiv_care_level__x> careLevels = [SELECT cde_level_care__c, dte_begin_effv__c, dte_end_effv__c
            FROM batchsit_t_sbsd_indiv_care_level__x
            WHERE idn_client__c =: authRec.IDN_CLIENT__r.IDN_EXTNL__c
            WITH SECURITY_ENFORCED ORDER BY dte_begin_effv__c asc];
            Date startDateSch = startDate;
            Date endDateSch;// = endDate;
            Map<Date,Date> authSheduleMap = new Map<Date,Date>();
            String pmtEnrollBegin = System.Label.Payment_by_Enrollment_Begin_Date;
            String pmtEnrollEnd = System.Label.Payment_by_Enrollment_End_Date;
            Date pmtEnrollBeginDate = Date.valueOf(pmtEnrollBegin);
            Date pmtEnrollEndDate = pmtEnrollEnd!='null' ? Date.valueOf(pmtEnrollEnd) : null;
            if(authEncumWrap != null && authEncumWrap.size()>0){
                for(Auth_Schedule_Recurrence__c encumbWrap :authEncumWrap){
                    if(encumbWrap.DTE_Begin_Date__c !=startDateSch && encumbWrap.DTE_Begin_Date__c >=startDateSch){
                        endDateSch = (encumbWrap.DTE_Begin_Date__c).addDays(-1);
                        authSheduleMap.put(startDateSch,endDateSch);
                        AuthorizationNotesController.authEncumbWrapper wrap1=  AuthorizationNotesController.createScheduleRecords(authRecId,startDateSch,endDateSch,hoursPerWeekDay,null,careLevels);
                        authEncmbrsToBeInserted.addAll(wrap1.authEncmbrsToBeInserted);
                        lstAuthEncmbrsToBeInserted.addAll(wrap1.lstAuthEncmbrsToBeInserted);
                        startDateSch = encumbWrap.DTE_Begin_Date__c;
                        endDateSch = (encumbWrap.DTE_End_Date__c);
                    } 
                    if(encumbWrap.DTE_Begin_Date__c ==startDateSch){
                        if(encumbWrap.Recur_Type__c =='Daily'){
                           /* AuthorizationNotesController.authEncumbWrapper wrap=  AuthorizationNotesController.dailyRecurrence(authRecId,startDate,endDate,hoursPerWeekDay,encumbWrap,careLevels);
                            authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                            lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                            startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);*/
                        }else if(encumbWrap.Recur_Type__c =='Daily/Weekly'){
                            AuthorizationNotesController.authEncumbWrapper wrap =AuthorizationNotesController.weeklyRecurrence(authRecId,startDate,endDate,hoursPerWeekDay,encumbWrap,careLevels);
                            authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                            lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                            startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                        }else if(encumbWrap.Recur_Type__c =='Monthly'){
                            AuthorizationNotesController.authEncumbWrapper wrap = AuthorizationNotesController.monthlyRecurrence(authRecId,startDate,endDate,hoursPerWeekDay,encumbWrap,careLevels);
                            authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                            lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                            startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                        }else if(encumbWrap.Recur_Type__c =='Every Other Week'){
                            AuthorizationNotesController.authEncumbWrapper wrap = AuthorizationNotesController.everyOtherWeekRecurrence(authRecId,startDate,endDate,hoursPerWeekDay,encumbWrap,careLevels);
                            authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                            lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                            startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                        } 
                        authSheduleMap.put(encumbWrap.DTE_Begin_Date__c,encumbWrap.DTE_End_Date__c);
                    }
                }
                if(endDateSch !=endDate){
                  //  endDateSch =endDateSch.addDays(1);
                    AuthorizationNotesController.authEncumbWrapper wrap1=  AuthorizationNotesController.createScheduleRecords(authRecId,endDateSch,endDate,hoursPerWeekDay,null,careLevels);
                    
                    
                    authEncmbrsToBeInserted.addAll(wrap1.authEncmbrsToBeInserted);
                    lstAuthEncmbrsToBeInserted.addAll(wrap1.lstAuthEncmbrsToBeInserted);
                    authSheduleMap.put(endDateSch,endDate);
                }
            }else{
                while(startDate <= endDate) {
                    Date startOfWeek = startDate.toStartofWeek();
                    Integer dayOfWeek = startOfWeek.daysBetween(startDate);
                    batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                    batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                    if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.IDN_AUTH__c.isCreateable()){
                        anAuthEncmbr.IDN_AUTH__c = authRecId;
                    }
                    if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.CDE_STATUS_ENCMBR__c.isCreateable()){
                        anAuthEncmbr.CDE_STATUS_ENCMBR__c = '2'; //Authorized
                    }
                    if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.CNT_HOUR_CARE__c.isCreateable()){
                        anAuthEncmbr.CNT_HOUR_CARE__c = hoursPerDay.CNT_HOUR_CARE__c;
                    }
                    if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.CDE_TYPE_UNIT_CARE__c.isCreateable()){
                        anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                    }
                    if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.DTE_CARE__c.isCreateable()){
                        anAuthEncmbr.DTE_CARE__c = startDate;
                    }
                    if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.cde_level_care__c.isCreateable()){
                        anAuthEncmbr.cde_level_care__c ='7';
                    }
                    for(batchsit_t_sbsd_indiv_care_level__x aCareLevel: careLevels){
                        if(aCareLevel.dte_begin_effv__c <= startDate && (startDate <= aCareLevel.dte_end_effv__c || aCareLevel.dte_end_effv__c == null) && Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.cde_level_care__c.isCreateable()){ 
                            anAuthEncmbr.cde_level_care__c = aCareLevel.cde_level_care__c;
                            break;
                        }
                    }
                    EncumberenceWrapper encumberenceWrapRec = getEncumberenceWrapper(anAuthEncmbr);
                    authEncmbrsToBeInserted.add(anAuthEncmbr);
                    lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                    startDate = startDate.addDays(1);
                }
            }
            Set<Date> provClosureDates = new Set<Date>();
            for(T_PROVR_CLOSURE__c provClosureRec : [SELECT Id, IDN_PROVIDER__c, DTE_BEGIN_CLOSURE__c FROM T_PROVR_CLOSURE__c 
                                                      WHERE IDN_PROVIDER__c =:authRec.IDN_PROVR__c AND IND_ACTIVE__c = true
                                                        AND CDE_COUNTY__c =:authRec.CDE_COUNTY__c WITH SECURITY_ENFORCED]){
                provClosureDates.add(provClosureRec.DTE_BEGIN_CLOSURE__c);
            }

            //added for CCCAP-14174
            Boolean isFieldCreatable = Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.ind_0_36_months__c.isCreateable();
            Boolean isValidProviderandAuth = (isProviderExempt == false && (prgType != 'CW' || authRec.Protective_Services_Indicator__c)) ? true : false;
            if(isFieldCreatable){
                for(batchsit_t_auth_encmbr__x encumb : authEncmbrsToBeInserted){                
                    if(isValidProviderandAuth && encumb.DTE_CARE__c >= pmtEnrollBeginDate && (pmtEnrollEndDate == null || encumb.DTE_CARE__c <= pmtEnrollEndDate) && encumb.DTE_CARE__c < dob36Months){
                        encumb.ind_0_36_months__c = 'Y';
                    } else{
                        encumb.ind_0_36_months__c = 'N';
                    }
                }    
            }
                        
            List<T_AUTH_ENCUMBR__c> recToInsert = new List<T_AUTH_ENCUMBR__c>();
            for(EncumberenceWrapper ew : lstAuthEncmbrsToBeInserted){
                //added for CCCAP-14174
                if(isFieldCreatable){
                    if(isValidProviderandAuth && Date.valueOf(ew.dte_Care) >= pmtEnrollBeginDate && (pmtEnrollEndDate == null || Date.valueOf(ew.dte_Care) <= pmtEnrollEndDate) && Date.valueOf(ew.dte_Care) < dob36Months){
                        ew.ind_0_36_months = 'Y';
                    } else{
                        ew.ind_0_36_months = 'N';
                    }
                }
                Date dt = Date.valueOf(ew.dte_Care);                
                if(provClosureDates.contains(dt)){
                    T_AUTH_ENCUMBR__c indiObj = new T_AUTH_ENCUMBR__c();
                    if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.cde_status_encmbr__c.isCreateable()){
                        indiObj.cde_status_encmbr__c = ew.cde_Status_Encmbr;
                    }
                    if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.cnt_hour_care__c.isCreateable()){
                        indiObj.cnt_hour_care__c = Integer.valueof(ew.cnt_Hour_Care);
                    }
                    if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.dte_care__c.isCreateable()){
                        indiObj.dte_care__c = Date.valueof(ew.dte_Care);
                    }
                    if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.IDN_AUTH__c.isCreateable()){
                        indiObj.IDN_AUTH__c = ew.idn_Auth;
                    }
                    //added for CCCAP-14174
                    if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.ind_0_36_months__c.isCreateable()){
                        indiObj.ind_0_36_months__c = ew.ind_0_36_months;
                    }
                    recToInsert.add(indiObj);
                    ew.cde_Status_Encmbr = '5';
                    ew.cnt_Hour_Care = '0';
                }
            }
            List<String> authEncmbrsExtIds = new List<String>();
            WebserviceResponse webServiceWrap = new WebserviceResponse();
            if(Test.isRunningTest()){
                webServiceWrap.isSuccess = true;
                for(integer i=0; i<authEncmbrsToBeInserted.size(); i++){
                    webServiceWrap.lstInsertedExtIds = new List<String>{'12345'};
                    webServiceWrap.mapCareDateToExtId = new Map<date, string>{system.today().addDays(30) => '12345'};
                }
            }else{
                webServiceWrap = HerokuService.authEncumbranceCreate(lstAuthEncmbrsToBeInserted);
            }
            if(webServiceWrap != null){
                authEncmbrsExtIds = webServiceWrap.lstInsertedExtIds;
            }
            if( webServiceWrap != null && (!webServiceWrap.isSuccess)){
                Map<String,Object> objectData = new Map<String,Object>();
                objectData.put('NO Data Found','No Data Found');
                if(webServiceWrap.statusCode != null){
                    objectData.put('xLog',getXLog('createAuthEncmbrRecords',webServiceWrap.message,'Custom Exception FROM Service',String.valueOf(webServiceWrap.req) , String.valueOf(webServiceWrap.resp),'Success'));
                }
                return new LightningServerResponse(false, 'The process of creating Encumbrance records are taking more time, please wait AND click Next.',objectData);   
            } else {
                // Creating auth schedule recurrence records
                AuthorizationNotesController.createAuthSchRecurr(authEncumWrap,authRecId);
                // End
                Map<String,Object> objectData = new Map<String,Object>();
                if(authEncmbrsExtIds != null){
                    for(integer i=0; i<authEncmbrsExtIds.size(); i++ ){
                        authEncmbrsToBeInserted.get(i).idn_encmbr_auth__c= Integer.valueOf(authEncmbrsExtIds.get(i));
                        authEncmbrsToBeInserted.get(i).ExternalId = authEncmbrsExtIds.get(i);
                    }
                    for(batchsit_t_auth_encmbr__x anAuthEncmbr: authEncmbrsToBeInserted){
                        Date careDate = anAuthEncmbr.DTE_CARE__c;              
                        careDateToAuthEncmbrId.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(),anAuthEncmbr);
                    }
                    objectData.put('xLog',getXLog('createAuthEncmbrRecords',null,'Web Service',String.valueOf(webServiceWrap.req) , String.valueOf(webServiceWrap.resp),'Success'));
                    objectData.put('careDateToAuthEncmbr',careDateToAuthEncmbrId);
                }
             GenericDMLHandler.insertRecords(recToInsert,false,new Map<String,Object>{'Method__c'=>'createAuthEncmbrRecords','Class__c'=>'AuthorizationFlowApxCtrl'},new List<String>{'IDN_AUTH__c','dte_care__c','cnt_hour_care__c','cde_status_encmbr__c'});

		//Database.insert(recToInsert,false);

                return new LightningServerResponse(true, 'Encmbrs inserted successfully',objectData);
            }
            
        }
        catch(Exception ex){
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }
    
    @future
    public static void insertAuthEncumSF(Set<Date> provClosureDates,Map<date,String> dtVsStatus,Map<date,String> dtVshour,Map<date,String> dtVsauth) {
        List<T_AUTH_ENCUMBR__c> recToInsert=new List<T_AUTH_ENCUMBR__c>();
        for(Date indiS : provClosureDates){
            T_AUTH_ENCUMBR__c indiObj=new T_AUTH_ENCUMBR__c();
            indiObj.cde_status_encmbr__c=dtVsStatus.get(indiS);
            indiObj.cnt_hour_care__c=Integer.valueOf(dtVshour.get(indiS));
            indiObj.dte_care__c=indiS;
            indiObj.IDN_AUTH__c=dtVsauth.get(indiS);
            recToInsert.add(indiObj);
        }
        //Database.insert(recToInsert,false);
        GenericDMLHandler.insertRecords(recToInsert,false,new Map<String,Object>{'Method__c'=>'insertAuthEncumSF','Class__c'=>'AuthorizationFlowApxCtrl'});
    }

    /* @auraEnabled
public static LightningServerResponse createAuthEncmbrRecurrRecords(String authRecId, String hoursPerWeekDayStr, List<Auth_Schedule_Recurrence__c> authEncumWrap){
try{
List<batchsit_t_auth_encmbr__x> hoursPerWeekDay = 
(List<batchsit_t_auth_encmbr__x>)JSON.deserialize(hoursPerWeekDayStr, List<batchsit_t_auth_encmbr__x>.class);
T_AUTH__c authRec = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CLIENT__c,IDN_CLIENT__r.IDN_EXTNL__c FROM T_AUTH__c
WHERE id =:authRecId WITH SECURITY_ENFORCED];
if(authEncumWrap != null && authEncumWrap.size()>0){
for(Auth_Schedule_Recurrence__c encumbWrap :authEncumWrap){
if(encumbWrap.Recur_Type__c =='Daily'){
}else if(encumbWrap.Recur_Type__c =='Weekly'){

}else if(encumbWrap.Recur_Type__c =='Monthly'){

}else if(encumbWrap.Recur_Type__c =='Yearly'){

}  
}
}
Date startDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
Date endDate = authRec.DTE_END_EFFV_AUTH__c;
List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
List<batchsit_t_sbsd_indiv_care_level__x> careLevels = [SELECT cde_level_care__c, dte_begin_effv__c, dte_end_effv__c 
FROM batchsit_t_sbsd_indiv_care_level__x 
WHERE idn_client__c =: authRec.IDN_CLIENT__r.IDN_EXTNL__c WITH SECURITY_ENFORCED ORDER BY dte_begin_effv__c ASC];
while(startDate <= endDate) {
Date startOfWeek = startDate.toStartofWeek();
Integer dayOfWeek = startOfWeek.daysBetween(startDate);

batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
anAuthEncmbr.IDN_AUTH__c = authRecId;
anAuthEncmbr.CDE_STATUS_ENCMBR__c = '2'; //Authorized
anAuthEncmbr.CNT_HOUR_CARE__c = hoursPerDay.CNT_HOUR_CARE__c;
anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
anAuthEncmbr.DTE_CARE__c = startDate;
anAuthEncmbr.Cde_Level_Care__c ='7';
for(batchsit_t_sbsd_indiv_care_level__x aCareLevel: careLevels){
if(aCareLevel.dte_begin_effv__c <= startDate && (startDate <= aCareLevel.dte_end_effv__c || aCareLevel.dte_end_effv__c == null))
{ 
anAuthEncmbr.cde_level_care__c = aCareLevel.cde_level_care__c;
break;
}
}
EncumberenceWrapper encumberenceWrapRec = getEncumberenceWrapper(anAuthEncmbr);
authEncmbrsToBeInserted.add(anAuthEncmbr);
lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
startDate = startDate.addDays(1);
}
List<String> authEncmbrsExtIds =new List<String>();
WebserviceResponse webServiceWrap = new WebserviceResponse();
if(Test.isRunningTest()){
for(integer i=0; i<authEncmbrsToBeInserted.size(); i++ ) {
authEncmbrsExtIds.add('12345');
}
}else{
webServiceWrap =HerokuService.authEncumbranceCreate(lstAuthEncmbrsToBeInserted);
}
if(webServiceWrap != null){
authEncmbrsExtIds = webServiceWrap.lstInsertedExtIds;
}
if( webServiceWrap != null && (!webServiceWrap.isSuccess)){
Map<String,Object> objectData = new Map<String,Object>();
objectData.put('NO Data Found','No Data Found');
if(webServiceWrap.statusCode != null){
objectData.put('xLog',getXLog('createAuthEncmbrRecords',webServiceWrap.message,'Custom Exception FROM Service',String.valueOf(webServiceWrap.req) , String.valueOf(webServiceWrap.resp),'Success'));
}
return new LightningServerResponse(false, 'The process of creating Encumbrance records are taking more time, please wait AND click Next.',objectData);   
} else {
Map<String,Object> objectData = new Map<String,Object>();
if(authEncmbrsExtIds != null){
for(integer i=0; i<authEncmbrsExtIds.size(); i++ ){
authEncmbrsToBeInserted.get(i).idn_encmbr_auth__c= Integer.valueOf(authEncmbrsExtIds.get(i));
authEncmbrsToBeInserted.get(i).ExternalId = authEncmbrsExtIds.get(i);
}
for(batchsit_t_auth_encmbr__x anAuthEncmbr: authEncmbrsToBeInserted){
Date careDate = anAuthEncmbr.DTE_CARE__c;              
careDateToAuthEncmbrId.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(),anAuthEncmbr);
}
objectData.put('xLog',getXLog('createAuthEncmbrRecords',null,'Web Service',String.valueOf(webServiceWrap.req) , String.valueOf(webServiceWrap.resp),'Success'));
objectData.put('careDateToAuthEncmbr',careDateToAuthEncmbrId);
}
return new LightningServerResponse(true, 'Encmbrs inserted successfully',objectData);
}

}
catch(Exception ex){
return new LightningServerResponse(false, ex.getMessage(), null);
}
}*/
    
    @AuraEnabled
    public static LightningServerResponse isCaseEligible(String caseRecId,String individualRecId ,T_Auth__c newAuthorizations){
        Boolean isSuccessful = true;
        String message;
        Map<string,Object> objectData = new Map<String,object>();
        try{
            String caseExternalId;
            String indivRecId;
            Date todayDate = System.today();
            Date nullDate;
            List<T_SBSD_CASE_INDIV__c> indivCase = new List <T_SBSD_CASE_INDIV__c>();
            indivCase = [SELECT id, IDN_CLIENT__c,IDN_CASE__r.IDN_EXTNL__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c =:caseRecId AND IDN_CLIENT__c =:individualRecId WITH SECURITY_ENFORCED];
            if(indivCase.size()>0){
                caseExternalId =indivCase[0].IDN_CASE__r.IDN_EXTNL__c;
            }
            List<T_SBSD_CASE_WTLST__c> caseWaitList= [SELECT Id FROM T_SBSD_CASE_WTLST__c WHERE IDN_CASE__c=:caseRecId AND CDE_STATUS_WTLST__c IN('WLT','REM','ENF') AND
                                                      DTE_BEGIN_EFFV_WTLST__c<=TODAY AND (DTE_END_EFFV_WTLST__c >=TODAY OR DTE_END_EFFV_WTLST__c = NULL) WITH SECURITY_ENFORCED LIMIT 1];
            if(caseWaitList.size()>0) {
                isSuccessful = false;
                message = Label.HouseholdWaitlist;
                objectData = null;
                //return new LightningServerResponse(false, Label.HouseholdWaitlist, null);
            }
            else {
                Set<Decimal> eliRunIds = new Set<Decimal>();
                List<batchsit_t_eligty_run__x> eligtyRunRec = new  List<batchsit_t_eligty_run__x>();
                if(Test.isRunningTest()){
                    batchsit_t_eligty_run__x eliRunTest = new batchsit_t_eligty_run__x(cde_eligty_cfmd__c='CFM',idn_case__c=caseRecId,idn_run_eligty__c=12345);
                    eligtyRunRec.add(eliRunTest);
                    eliRunIds.add(12345);
                }else{
                    for(batchsit_t_eligty_run__x eli : [SELECT Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c FROM batchsit_t_eligty_run__x WHERE idn_case__c=:caseExternalId AND cde_eligty_cfmd__c='CFM'  WITH SECURITY_ENFORCED ORDER BY ExternalId DESC LIMIT 1]){
                        eligtyRunRec.add(eli);
                        eliRunIds.add(eli.idn_run_eligty__c);
                    }
                }
                if(eligtyRunRec.size()>0) {
                    Boolean isCaseIneligible = false;
                    String eligibilityHouseHoldId = '';
                    List<batchsit_t_fcompsn_eligty_detail__x> fcompsnEligtyDetailRec = new List<batchsit_t_fcompsn_eligty_detail__x>();
                    if(Test.isRunningTest()){
                        isCaseIneligible = true;
                        eligibilityHouseHoldId ='123456';
                    } else {
                            for(batchsit_t_fcompsn_eligty_detail__x fcomElig : [SELECT Id,idn_eligty_fcompsn__c,cde_status_eligty_family__c,idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c FROM batchsit_t_fcompsn_eligty_detail__x WHERE dte_begin_effv__c <=: newAuthorizations.DTE_BEGIN_EFFV_AUTH__c AND 
                                                                                (dte_end_effv__c >=: newAuthorizations.DTE_BEGIN_EFFV_AUTH__c OR dte_end_effv__c =: nullDate) AND
                                                                                idn_eligty_fcompsn__r.idn_run_eligty__r.idn_run_eligty__c IN: eliRunIds WITH SECURITY_ENFORCED ORDER BY dte_begin_effv__c DESC ,idn_eligty_fcompsn__c DESC])
                            {
                                if(eligtyRunRec.size()>0 && eligtyRunRec[0].dte_run_eligty__c<=Date.newInstance(2018,8,31) || fcomElig.idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c!='NCT' || fcomElig.idn_eligty_fcompsn__r.cde_reason_change_fcompsn__c==null){
                                    if(fcomElig.cde_status_eligty_family__c == 'INE'){
                                        isCaseIneligible = true;
                                    }else{
                                        eligibilityHouseHoldId = fcomElig.idn_eligty_fcompsn__c;
                                    }
                                }
                            } 
                        }
                    if(!String.isBlank(eligibilityHouseHoldId)){
                    if(isCaseIneligible) {
                        indivRecId =indivCase[0].IDN_CLIENT__c;
                        isSuccessful = false;
                        message = Label.HouseholdIneligible;
                        objectData = null;
                        //return new LightningServerResponse(false, Label.HouseholdIneligible, null);
                    } else {
                        if(indivCase.size()>0){
                            indivRecId =indivCase[0].IDN_CLIENT__c;
                            LightningserverResponse lsr = isIndividualEligible(caseRecId,indivRecId,eligibilityHouseHoldId,newAuthorizations);
                            isSuccessful = lsr.isSuccessful;
                            message = lsr.successMessage!=null ?lsr.successMessage: lsr.errorMessage;
                            objectData = lsr.objectData;
                            //return  isIndividualEligible(caseRecId,indivRecId,eligibilityHouseHoldId,newAuthorizations);
                        }
                        //return new LightningServerResponse(true, null, null);
                    }
                    }else{ 
                        isSuccessful = false;
                        message = Label.HouseholdIneligible;
                        objectData = null;
                        //     return new LightningServerResponse(false, Label.HouseholdIneligible, null);
                    }
                } else {
                    isSuccessful = false;
                    message = Label.HouseholdIneligible;
                    objectData = null;                 
                    //   return new LightningServerResponse(false, Label.HouseholdIneligible, null);
                }
                
                //return new LightningServerResponse(true, null, null); 
            }
        }
        catch(Exception ex){
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','AuthorizationFlowApxCtrl' );
            exceptionMap.put('Method__c','isCaseEligible');
            ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
            isSuccessful = false;
            message = ex.getMessage();
            objectData = null;                 
            //return new LightningServerResponse(false, ex.getMessage(), null);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }

   /**
     * validateProviders This method is used to check if Authorization is created with valid provider
     * @param  {String} providerId 
     * @param  {String} beginDate 
     * @param  {T_SBSD_CASE__c} caseObj
     * @return the LightningServerResponse to Lightning component
     */
    @AuraEnabled
    public static LightningServerResponse validateProviders(String providerId, String beginDate,T_SBSD_CASE__c caseObj){
        Map<String, Boolean> objectData = new map<String, Boolean>();
        Boolean isSuccessful = false;
        Boolean isReqProviderLocation = false;
        Date todayDate = System.today();
        beginDate = beginDate.contains('T') ? beginDate.substringBefore('T') : beginDate; // Added by Rishav to avoid 'System.TypeException: Invalid integer: 01T00:00:00'.
        List<String> dateParts = beginDate.split('-');
        Set<String> statusSet = new Set<String> {'Closed'};
        Date beginDate1 = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
        Boolean isProviderExempt = false; // Added by Rishav for CCCAP-2618
        //Added fix for CHATS-5384, CHATS-5547 AND code optimization on 06/20/2018
        if(String.isNotBlank(providerId) && String.isNotBlank(beginDate)){
            for(T_PROVR_FISCAL_AGREMENT__c prov : [SELECT Id, ID_SERVICE__c,CDE_COUNTY__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, ID_SERVICE__r.CDE_COUNTY_OWNER__c,ID_SERVICE__r.CDE_STATUS_PROVR__c,
                                                   ID_SERVICE__r.DTE_END_EFFV__c,ID_SERVICE__r.DTE_BEGIN_EFFV__c,ID_SERVICE__r.CDE_TYPE_PROVR__c,(SELECT Id,Name,DTE_BEGIN_EFFV__c FROM Rate_Schedules__r) 
                                                   FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c =:providerId AND ID_SERVICE__r.CDE_STATUS_PROVR__c NOT IN: statusSet  AND CDE_TYPE_STATUS__c IN ('OPN','FIN','CLS') AND 
                                                   DTE_BEGIN_AGRMT__c <= :beginDate1 AND (DTE_END_AGRMT__c >=: beginDate1 OR DTE_END_AGRMT__c = null) WITH SECURITY_ENFORCED]){
                                                       if(prov.ID_SERVICE__r.CDE_TYPE_PROVR__c == 'EFACH'){
                                                           isReqProviderLocation = true;
                                                       }
                                                       // Added below 'if' by Rishav for CCCAP-2618
                                                       if(EXEMPT.contains(prov.ID_SERVICE__r.CDE_TYPE_PROVR__c)){
                                                           isProviderExempt = true;
                                                       }
                                                       if(prov.ID_SERVICE__r.CDE_STATUS_PROVR__c == 'Pending' && prov.ID_SERVICE__r.DTE_BEGIN_EFFV__c != NULL){
                                                          if(prov.CDE_COUNTY__c == caseObj.CDE_COUNTY__c  && !prov.Rate_Schedules__r.isEmpty()){
                                                           for(T_FISCAL_SCH__c  rateSch : prov.Rate_Schedules__r){
                                                               if(rateSch.DTE_BEGIN_EFFV__c <=  beginDate1){
                                                                   isSuccessful = true;
                                                                   break;
                                                               }
                                                           }
                                                       } 
                                                       }else if(prov.ID_SERVICE__r.CDE_STATUS_PROVR__c != 'Pending'){
                                                          if(prov.CDE_COUNTY__c == caseObj.CDE_COUNTY__c  && !prov.Rate_Schedules__r.isEmpty()){
                                                           for(T_FISCAL_SCH__c  rateSch : prov.Rate_Schedules__r){
                                                               if(rateSch.DTE_BEGIN_EFFV__c <=  beginDate1){
                                                                   isSuccessful = true;
                                                                   break;
                                                               }
                                                           }
                                                       }  
                                                       }
                                                       
                                                   }
            objectData.put('validProvider', isSuccessful);
            objectData.put('isReqProviderLocation', isReqProviderLocation);
            objectData.put('isProviderExempt', isProviderExempt); // Added by Rishav for CCCAP-2618
        }
        return new LightningServerResponse(isSuccessful,'Validation check',objectData);
    }

    //CCCAP-15452 - replicates the behavior of force:recordData in Aura component to mark a provider record as recently viewed
    @AuraEnabled
    public static void trackProviderRecordView(Id recordId) {
        if (String.isNotBlank(recordId)) {
            List<T_CHATS_PROVR_STATUS__c> records = [
                SELECT Id FROM T_CHATS_PROVR_STATUS__c 
                WHERE Id = :recordId 
                WITH SECURITY_ENFORCED
                FOR VIEW
            ];
        }
    }
    
    @AuraEnabled
    public static LightningServerResponse fetchSCAssociations(String SCId, String providerId, T_SBSD_CASE__c caseObj, Date authBeginDate){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        Boolean isCountyRateSCQ;
        
        Date effectiveDate = system.today();
        effectiveDate = authBeginDate != null && authBeginDate > effectiveDate ? authBeginDate : effectiveDate;
        List<T_COUNTY_RATE__c> effectiveCountyRatePlan = [SELECT Id, CFS_Q1__c, CFS_Q1_2__c 
                                                              FROM T_COUNTY_RATE__c 
                                                              WHERE IDN_COUNTY__c = :caseObj.CDE_COUNTY__c
                                                              AND DTE_BEGIN_EFFV_RATE__c<=:effectiveDate 
                                                              AND (DTE_END_EFFV_RATE__c>=:effectiveDate OR DTE_END_EFFV_RATE__c=null)
                                                              AND CDE_STATUS__c = 'APV'
                                                              AND IND_RATE_PLAN_TEMPLT__c = false WITH SECURITY_ENFORCED];
        
        if(!effectiveCountyRatePlan.isEmpty() && effectiveCountyRatePlan[0].CFS_Q1__c == 'Y'){
            List<T_SLOT_CONTRACT__c> slotContRecs = [SELECT Id, Name, IDN_PROVIDER__c, CDE_COUNTY__c, CDE_CARE_LEVEL__c, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IDN_AUTH__c FROM T_SLOT_CONTRACT__c 
                                                     WHERE IDN_PROVIDER__c = :providerId AND CDE_COUNTY__c = :caseObj.CDE_COUNTY__c AND ((IND_AVAILABLE__c = true AND DTE_END_SLOT__c >= TODAY) OR Id = :SCId) WITH SECURITY_ENFORCED];
            if(slotContRecs!=null){
                List<PicklistOption> options = new List<PicklistOption>();
                objectData.put('slotContractOptions', options);
                for(T_SLOT_CONTRACT__c sc : slotContRecs){
                    options.add(new PicklistOption(sc.Name, sc.Id));
                }
                isSuccessful = true;
            }
        }
        return new LightningServerResponse(isSuccessful, null, objectData);
    }

    @AuraEnabled
    public static LightningServerResponse fetchProviderClosureRecs(String provRecId, String countyId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        String keyStr;
        String monthStr;
        String dayStr;
        Date startDate;
        List<String> provClosRecdates = new List<String>();
        List<T_PROVR_CLOSURE__c> provClosureRecs = [SELECT Id, IDN_PROVIDER__c, DTE_BEGIN_CLOSURE__c FROM T_PROVR_CLOSURE__c 
                                                    WHERE IDN_PROVIDER__c =:provRecId AND IND_ACTIVE__c = true AND CDE_COUNTY__C =:countyId WITH SECURITY_ENFORCED];
        if(provClosureRecs.size() > 0){
            for(T_PROVR_CLOSURE__c prvClosRec: provClosureRecs){
                startDate = prvClosRec.DTE_BEGIN_CLOSURE__c;
                monthStr = String.valueOf(startDate.month());
                dayStr = String.valueOf(startDate.day());
                keyStr = startDate.year()+'-'+monthStr+'-'+dayStr;
                provClosRecdates.add(keyStr);
            }
            isSuccessful = true;
        }
        objectData.put('provClosDates', provClosRecdates);
        return new LightningServerResponse(isSuccessful, null, objectData);   
    }

    @AuraEnabled
    public static LightningServerResponse queryPopulateSCAssRecord(String scAssId){
        Map<String, String> objectData = new map<String, String>();
        Boolean isSuccessful = true;
        String keyStr;
        String keyStrone;
        String scAssCareLvl;
        String scAssDesc;
        T_SLOT_CONTRACT__c slotContAssociaRec;
        for(T_SLOT_CONTRACT__c sc : [SELECT Id, Name, toLabel(CDE_CARE_LEVEL__c), DTE_BEGIN_SLOT__c, 
                                     DTE_END_SLOT__c, IDN_AUTH__c, SLOT_CONTRACT_DESCRIPTION__c FROM T_SLOT_CONTRACT__c WHERE Id = :scAssId WITH SECURITY_ENFORCED]){
            slotContAssociaRec = sc;
        }
        if(slotContAssociaRec != null){       
            Date scAssRecBgnDte = slotContAssociaRec.DTE_BEGIN_SLOT__c;
            String monthStr = String.valueOf(scAssRecBgnDte.month());
            String dayStr = String.valueOf(scAssRecBgnDte.day());
            if(scAssRecBgnDte.month()<10){
                monthStr = '0'+monthStr;
            }
            if(scAssRecBgnDte.day()<10){
                dayStr = '0'+dayStr;
            }
            keyStr = scAssRecBgnDte.year()+'-'+monthStr+'-'+dayStr;
            Date scAssRecEndDte = slotContAssociaRec.DTE_END_SLOT__c;
            String monthStrone = String.valueOf(scAssRecEndDte.month());
            String dayStrone = String.valueOf(scAssRecEndDte.day());
            if(scAssRecEndDte.month()<10){
                monthStrone = '0'+monthStrone;
            }
            if(scAssRecEndDte.day()<10){
                dayStrone = '0'+dayStrone;
            }
            keyStrone = scAssRecEndDte.year()+'-'+monthStrone+'-'+dayStrone;
            
            scAssCareLvl=slotContAssociaRec.CDE_CARE_LEVEL__c;
            scAssDesc=slotContAssociaRec.SLOT_CONTRACT_DESCRIPTION__c;
        } else {
            keyStr = null;
            keyStrone = null;
            scAssCareLvl = null;
            scAssDesc=null;
        }
        objectData.put('scAssRecBgnDte',keyStr);
        objectData.put('scAssRecEndDte',keyStrone);
        objectData.put('scAssCareLvl',scAssCareLvl);
        objectData.put('scAssDesc',scAssDesc);
                
        return new LightningServerResponse(isSuccessful,'Success',objectData);        
    }
    
    @auraEnabled
    public static LightningServerResponse isIndividualEligible(String caseRecId,String indivRecId,String houseHoldElgId,T_Auth__c newAuthorizations){
        try{
        	Map<String, Object> objectData = new map<String, Object>();
            Date todayDate = System.today();
            Date nullDate;
            if(!String.isBlank(houseHoldElgId)) {
                List<batchsit_t_fcompsn_indiv_eligty__x> fcompsnIndivEligtyRec = new List<batchsit_t_fcompsn_indiv_eligty__x>();
                Set<Decimal> indivElgIds = new Set<Decimal>();
                if(Test.isRunningTest()){
                    indivElgIds.add(12345);
                }
                for(batchsit_t_fcompsn_indiv_eligty__x elg :[SELECT Id,idn_indiv_fcompsn__c FROM batchsit_t_fcompsn_indiv_eligty__x WHERE idn_case_indiv__r.idn_case__r.Id =:caseRecId AND
                                                             idn_case_indiv__r.IDN_CLIENT__c=:indivRecId AND 
                                                             idn_eligty_fcompsn__c=:houseHoldElgId WITH SECURITY_ENFORCED]){
                                                                indivElgIds.add(elg.idn_indiv_fcompsn__c);
                                                                }
                if(indivElgIds.size()>0) {
                    Boolean isRecordsReturned = false;
                    for(batchsit_t_indiv_eligty_detail__x indivEligityEach :[SELECT Id, idn_indiv_fcompsn__r.idn_indiv_fcompsn__c, dte_begin_effv__c, cde_status_detail_eligty_indiv__c, cde_reason_change_eligty__c, dte_end_effv__c
                                                                            FROM batchsit_t_indiv_eligty_detail__x WHERE idn_indiv_fcompsn__r.idn_indiv_fcompsn__c IN:indivElgIds AND
                                                                            dte_begin_effv__c <=: newAuthorizations.DTE_BEGIN_EFFV_AUTH__c AND (dte_end_effv__c >= :newAuthorizations.DTE_BEGIN_EFFV_AUTH__c OR dte_end_effv__c =: nullDate) WITH SECURITY_ENFORCED]){
                                                                                isRecordsReturned = true;
                                                                                if(indivEligityEach.cde_status_detail_eligty_indiv__c !='EC'){
                                                                                    return new LightningServerResponse(false, Label.IneligibleChild, null);
                                                                                 }
                                                                                 if(indivEligityEach.cde_status_detail_eligty_indiv__c =='EC'){
                                                                                     if(newAuthorizations != null){
                                                                                        if(newAuthorizations.DTE_BEGIN_EFFV_AUTH__c<indivEligityEach.dte_begin_effv__c) {
                                                                                            return new LightningServerResponse(false, Label.Authorization_Begin_Date_cannot_be_before_the_Child_Eligibility_Begin_date, null);
                                                                                        }
                                                                                        if(indivEligityEach.dte_end_effv__c != null){
                                                                                            if(newAuthorizations.DTE_BEGIN_EFFV_AUTH__c>indivEligityEach.dte_end_effv__c) {
                                                                                                return new LightningServerResponse(false, Label.Authorization_Begin_Date_cannot_be_after_the_Child_Eligibility_End_date, null);
                                                                                            }
                                                                                        }
                                                                                         if(indivEligityEach.cde_status_detail_eligty_indiv__c =='EC'){
                                                                                             objectData.put('Enddate',indivEligityEach.dte_end_effv__c);
                                                                                         } 
                                                                                     }
                                                                                 }
                                                                                 
                                                                             }
                    if(isRecordsReturned){
                        return new LightningServerResponse(true, null, objectData);
                    } else {
                         return new LightningServerResponse(false, Label.IneligibleChild, null);
                    }
                } else {
                    return new LightningServerResponse(false, Label.IneligibleChildMsg, null);
                }
            } else {
                return new LightningServerResponse(true, null, objectData);
            }
        } catch(Exception ex) {
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','AuthorizationFlowApxCtrl' );
            exceptionMap.put('Method__c','isIndividualEligible');
            ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }

    public static EncumberenceWrapper getEncumberenceWrapper(batchsit_t_auth_encmbr__x encumberenceRec) {
        EncumberenceWrapper encumberence= new EncumberenceWrapper();
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.cde_level_care__c.isCreateable()){
            encumberence.cde_Level_Care = encumberenceRec.cde_level_care__c;
        }
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.cde_Status_Encmbr__c.isCreateable()){
            encumberence.cde_Status_Encmbr = encumberenceRec.cde_Status_Encmbr__c;
        }
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.cde_Type_Unit_Care__c.isCreateable()){
            encumberence.cde_Type_Unit_Care = encumberenceRec.cde_Type_Unit_Care__c;
        }
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.cnt_Hour_Care__c.isCreateable()){
            encumberence.cnt_Hour_Care = String.valueOf(encumberenceRec.cnt_Hour_Care__c);
        }
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.idn_Auth__c.isCreateable()){
            encumberence.idn_Auth = encumberenceRec.idn_Auth__c;
        }
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.dte_Care__c.isCreateable()){
            encumberence.dte_Care = String.valueOf(encumberenceRec.dte_Care__c);
        }
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.nbr_Seq_Hist__c.isCreateable()){
            encumberence.nbr_Seq_Hist =  encumberenceRec.nbr_Seq_Hist__c!= null ? String.valueOf(encumberenceRec.nbr_Seq_Hist__c): '0';
        }
        //added for CCCAP-14174
        if(Schema.sObjectType.batchsit_t_auth_encmbr__x.fields.ind_0_36_months__c.isCreateable()){
            encumberence.ind_0_36_months = encumberenceRec.ind_0_36_months__c;
        }
        encumberence.cnt_Hour_Attnd_Actual = '0';
        encumberence.createdbyid = Userinfo.getUserId();
        encumberence.createddate = String.valueOf(system.now().format('yyyy-MM-dd HH:mm:ss'));
        encumberence.lastmodifieddate = String.valueOf(system.now().format('yyyy-MM-dd HH:mm:ss')) ;
        encumberence.lastmodifiedbyid = Userinfo.getUserId();
        return encumberence;
    }

    // Added By Diya
    @auraEnabled
    /*  public static LightningServerResponse updateAuthEncmbrRecords(String authRecId, String hoursPerWeekDayStr, Boolean isUpdate){
        Map<String, Boolean> objectData = new map<String, Boolean>();
        Boolean isSuccessful = true;
        String message;
        String isErrorWebservice = '';
        List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2 = new Map<String, batchsit_t_auth_encmbr__x>();
        try{
        	T_AUTH__c authRec = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CLIENT__c FROM T_AUTH__c
                                 WHERE id =:authRecId WITH SECURITY_ENFORCED];
            // Extra
            if(!Test.isRunningTest()){
            	if(authRec != null){
                           fetchedEncumberence = HerokuService.authEncumbrancefetch(authRec.IDN_EXTNL__c);
            	}
            }else{
                fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =system.today(),idn_auth__c =authRecId,cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId=authRecId));
            }
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence ){
                Date careDate = anAuthEncmbr.dte_care__c;
                String monthStr = String.valueOf(careDate.month());
                String dayStr = String.valueOf(careDate.day());
                if(careDate.month()<10){
                    monthStr = '0'+monthStr;
                }
                if(careDate.day()<10){
                    dayStr = '0'+dayStr;
                }
                careDateToAuthEncmbr2.put(careDate.year()+'-'+monthStr+'-'+dayStr,
                                          anAuthEncmbr);                
            }
            // end
            Map<String, Object> careDateToAuthEncmbr1 = new Map<String, Object>();
            Object careDateToAuthEncmbr ;
           // LightningServerResponse resLight = getAuthEncmbrRecords(authRecId);
           // if(resLight!= null){
           //     careDateToAuthEncmbr1 = resLight.objectData;
                //careDateToAuthEncmbr = (batchsit_t_auth_encmbr__x)careDateToAuthEncmbr1.get('careDateToAuthEncmbr');
                // careDateToAuthEncmbr2 = (Map<String, batchsit_t_auth_encmbr__x>) JSON.deserializeUntyped(JSON.serialize(careDateToAuthEncmbr));
          //  }
            List<batchsit_t_auth_encmbr__x> hoursPerWeekDay = 
                (List<batchsit_t_auth_encmbr__x>)JSON.deserialize(hoursPerWeekDayStr, List<batchsit_t_auth_encmbr__x>.class);
            
            Date startDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
            DateTime dT = System.now();
            Date todayDate =dT.dateGmt();
            if(startDate < todayDate){
            	startDate = todayDate;
                startDate = startDate.addDays(1);
            }
            Date endDate = authRec.DTE_END_EFFV_AUTH__c;
            List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
            List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
            Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
            /* List<batchsit_t_sbsd_indiv_care_level__x> careLevels = 
[SELECT cde_level_care__c, dte_begin_effv__c, dte_end_effv__c 
from batchsit_t_sbsd_indiv_care_level__x
where idn_client__c =: authRec.idn_client__c WITH SECURITY_ENFORCED
order by dte_begin_effv__c asc]; */
           /*  if(careDateToAuthEncmbr2.size()>0){
            while(startDate <= endDate) {
                Date startOfWeek = startDate.toStartofWeek();
                Integer dayOfWeek = startOfWeek.daysBetween(startDate);
                
                batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                String startDateStr = String.valueOf(startDate);
                batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                if(anAuthEncmbr != null){
                 if(hoursPerDay.CDE_TYPE_UNIT_CARE__c != '--None--' && hoursPerDay.CNT_HOUR_CARE__c != null){
                anAuthEncmbr.idn_auth__c = anAuthEncmbr.idn_auth__c;
                anAuthEncmbr.cde_status_encmbr__c = '2'; //Authorized
                anAuthEncmbr.cnt_hour_care__c = hoursPerDay.CNT_HOUR_CARE__c;
                anAuthEncmbr.cde_type_unit_care__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                    authEncmbrsToBeInserted.add(anAuthEncmbr);
                }
                }
                startDate = startDate.addDays(1);
            }
        }else{
                    isErrorWebservice = 'No encumbrance records returned FROM web service';
                }
		if(Test.isRunningTest()){
                batchsit_t_auth_encmbr__x en = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth(),cnt_hour_care__c =5);
                batchsit_t_auth_encmbr__x en1 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+1,cnt_hour_care__c =10);
                batchsit_t_auth_encmbr__x en2 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+2,cnt_hour_care__c =17);
                batchsit_t_auth_encmbr__x en3 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+4,cnt_hour_care__c =0);
                batchsit_t_auth_encmbr__x en4 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+5,cnt_hour_care__c =22);
                authEncmbrsToBeInserted.add(en);
                authEncmbrsToBeInserted.add(en1);
                authEncmbrsToBeInserted.add(en2);
                authEncmbrsToBeInserted.add(en3);
                authEncmbrsToBeInserted.add(en4);
                isUpdate=true;
            }
            if(authEncmbrsToBeInserted.size() >0){
                if(isUpdate){
                    String dataBody = encumbJsonString(authEncmbrsToBeInserted);
                    if(!String.isEmpty(dataBody)){
                        if(!Test.isRunningTest()){
                            IndividualCareLvlApexCtrl.authEncumbranceUpdate(dataBody);
                        }
                    }
                }
            }
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: authEncmbrsToBeInserted){
                Date careDate = anAuthEncmbr.dte_care__c;
                String monthStr = String.valueOf(careDate.month());
                String dayStr = String.valueOf(careDate.day());
                if(careDate.month()<10){
                    monthStr = '0'+monthStr;
                }
                if(careDate.day()<10){
                    dayStr = '0'+dayStr;
                }
                String keyStr = careDate.year()+'-'+monthStr+'-'+dayStr;
                careDateToAuthEncmbr2.put(keyStr, anAuthEncmbr);
                
                // careDateToAuthEncmbrId.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(),anAuthEncmbr);
            }
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence ){
                Date careDate = anAuthEncmbr.dte_care__c;
                String monthStr = String.valueOf(careDate.month());
                String dayStr = String.valueOf(careDate.day());
                if(careDate.month()<10){
                    monthStr = '0'+monthStr;
                }
                if(careDate.day()<10){
                    dayStr = '0'+dayStr;
                }
                String keyStr = careDate.year()+'-'+monthStr+'-'+dayStr;
                batchsit_t_auth_encmbr__x anAuthEncmbrUpdated = careDateToAuthEncmbr2.get(keyStr);
                careDateToAuthEncmbrId.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(),anAuthEncmbrUpdated); 
            }
            return new LightningServerResponse(true, isErrorWebservice,
                                               new Map<String, object>{'careDateToAuthEncmbr' => careDateToAuthEncmbrId});
        }
        catch(Exception ex){
            String message1 = ex.getMessage();
            if(fetchedEncumberence == null || fetchedEncumberence.size() <=0 ){
                message1 = 'Problem in connecting with external system.';
            }
            return new LightningServerResponse(false, message1, null);
        }
        return new LightningServerResponse(isSuccessful,'Validation check',objectData);
    }*/

    public static String encumbJsonString(List<batchsit_t_auth_encmbr__x> encumbList){
        JSONGenerator gen = JSON.createGenerator(true);
        Id userId= UserInfo.getUserId();
        String nowDate = String.valueOf(system.now());
        gen.writeStartArray();
        for(batchsit_t_auth_encmbr__x encum :encumbList){
            gen.writeStartObject();
            if(encum.idn_Auth__c!=null){
                gen.writeStringField('idn_Auth', encum.idn_Auth__c);
            }
            if(encum.ExternalId!=null){
                gen.writeStringField('idn_Encmbr_Auth',encum.ExternalId);
            }
            if(encum.idn_encmbr_auth__c!=null){
                gen.writeStringField('idn_Encmbr_Auth',String.valueOf(encum.idn_encmbr_auth__c));
            }
            gen.writeStringField('lastmodifieddate',nowDate);
            gen.writeStringField('lastmodifiedbyid',userId);
            // gen.writeStringField('cde_Level_Care',encum.cde_level_care__c);
            if(encum.cnt_hour_care__c != null){
                gen.writeStringField('cnt_Hour_Care',String.valueOf(encum.cnt_hour_care__c));
            }
            if(encum.cde_type_unit_care__c != null){
                gen.writeStringField('cde_Type_Unit_Care',encum.cde_type_unit_care__c);
            }
            gen.writeEndObject();
        }
        gen.writeEndArray();
        String encumbStr = gen.getAsString();
        return encumbStr;
    }
 
     //Logic to update auth encumbrance based on recurrence patterns
    @auraEnabled
    public static LightningServerResponse updateAuthEncmbrRecordsBasedOnPatterns(String authRecId, String hoursPerWeekDayStr, Boolean isUpdate,String hoursPerWeekDayRecurrStr,String currentMode){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message ='Validation check';
        String isErrorWebservice = '';
        List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2 = new Map<String, batchsit_t_auth_encmbr__x>();
        try{
            T_AUTH__c authRec = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CLIENT__c,
                                IDN_CASE__r.Program_Type__c, IDN_CASE__r.CHATS_Reverse_Refer_Mode__c,
                                 Auth_Reverse_Refer_Track__c //added for CCCAP-10162 for CHATS reverse Referral
                                 FROM T_AUTH__c
                                 WHERE id =:authRecId WITH SECURITY_ENFORCED];
            // Extra
            if(!Test.isRunningTest()){
                if(authRec != null){
                    fetchedEncumberence = HerokuService.authEncumbrancefetch(authRec.IDN_EXTNL__c);
                }
            }else{
                fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =system.today(),idn_auth__c =authRecId,cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId=authRecId));
            }
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence ){
                Date careDate = anAuthEncmbr.dte_care__c;
                String monthStr = String.valueOf(careDate.month());
                String dayStr = String.valueOf(careDate.day());
                if(careDate.month()<10){
                    monthStr = '0'+monthStr;
                }
                if(careDate.day()<10){
                    dayStr = '0'+dayStr;
                }
                careDateToAuthEncmbr2.put(careDate.year()+'-'+monthStr+'-'+dayStr,
                                          anAuthEncmbr);                
            }
            // end
            Map<String, Object> careDateToAuthEncmbr1 = new Map<String, Object>();
            Object careDateToAuthEncmbr ;
            
            List<batchsit_t_auth_encmbr__x> hoursPerWeekDay = 
                (List<batchsit_t_auth_encmbr__x>)JSON.deserialize(hoursPerWeekDayStr, List<batchsit_t_auth_encmbr__x>.class);
            List<Auth_Schedule_Recurrence__c> authEncumWrap = 
                (List<Auth_Schedule_Recurrence__c>)JSON.deserialize(hoursPerWeekDayRecurrStr, List<Auth_Schedule_Recurrence__c>.class);
            
            
            Date startDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
            DateTime dT = System.now();
            Date todayDate =dT.dateGmt();
            if(startDate < todayDate){
                startDate = todayDate;
                startDate = startDate.addDays(1);
            }
            Date endDate = authRec.DTE_END_EFFV_AUTH__c;
            List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
            List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
            Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
            Date startDateSch = startDate;
            Date endDateSch;// = endDate;
            if(authEncumWrap != null && authEncumWrap.size()>0 && isUpdate){
                for(Auth_Schedule_Recurrence__c encumbWrap :authEncumWrap){
                     Boolean existingMidPattern =false;
                    if(( encumbWrap.DTE_Begin_Date__c < startDateSch && encumbWrap.DTE_End_Date__c >startDateSch )){
                        existingMidPattern= true;
                        }
                    if((encumbWrap.DTE_Begin_Date__c !=startDateSch && encumbWrap.DTE_Begin_Date__c >=startDateSch) && (!existingMidPattern)){
                           endDateSch = (encumbWrap.DTE_Begin_Date__c).addDays(-1);
                        AuthorizationNotesController.authEncumbWrapper wrap1=  AuthorizationNotesController.createScheduleRecords(authRecId,startDateSch,endDateSch,hoursPerWeekDay,careDateToAuthEncmbr2,null);
                        authEncmbrsToBeInserted.addAll(wrap1.authEncmbrsToBeInserted);
                        lstAuthEncmbrsToBeInserted.addAll(wrap1.lstAuthEncmbrsToBeInserted);
                        startDateSch = encumbWrap.DTE_Begin_Date__c;
                        endDateSch = (encumbWrap.DTE_End_Date__c);
                    }
                    if(encumbWrap.DTE_Begin_Date__c ==startDateSch|| existingMidPattern){
                         if(encumbWrap.Recur_Type__c =='Daily'){
                        /*   AuthorizationNotesController.authEncumbWrapper wrap=  AuthorizationNotesController.dailyRecurrence(authRecId,startDate,endDate,hoursPerWeekDay,encumbWrap,careLevels);

authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);*/
                    }else if(encumbWrap.Recur_Type__c =='Daily/Weekly'){
                        AuthorizationNotesController.authEncumbWrapper wrap =AuthorizationNotesController.updateWeeklyRecurrence(authRecId,startDateSch,endDate,hoursPerWeekDay,encumbWrap,careDateToAuthEncmbr2);
                        authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                        lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                        startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                    }else if(encumbWrap.Recur_Type__c =='Monthly'){
                        AuthorizationNotesController.authEncumbWrapper wrap = AuthorizationNotesController.updateMonthlyRecurrence(authRecId,startDateSch,endDate,hoursPerWeekDay,encumbWrap,careDateToAuthEncmbr2);
                        authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                        lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                        startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                    }else if(encumbWrap.Recur_Type__c =='Every Other Week'){
                        AuthorizationNotesController.authEncumbWrapper wrap = AuthorizationNotesController.updateEveryOtherWeekRecurrence(authRecId,startDateSch,endDate,hoursPerWeekDay,encumbWrap,careDateToAuthEncmbr2);
                        authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
                        lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
                        startDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                            endDateSch = (encumbWrap.DTE_End_Date__c).addDays(1);
                    }
                    }
                     
                }
                if(endDateSch !=endDate){
                  //  endDateSch =endDateSch.addDays(1);
                    AuthorizationNotesController.authEncumbWrapper wrap1=  AuthorizationNotesController.createScheduleRecords(authRecId,endDateSch,endDate,hoursPerWeekDay,careDateToAuthEncmbr2,null);
                    
                    
                    authEncmbrsToBeInserted.addAll(wrap1.authEncmbrsToBeInserted);
                    lstAuthEncmbrsToBeInserted.addAll(wrap1.lstAuthEncmbrsToBeInserted);
                }
            }else{
                if(careDateToAuthEncmbr2.size()>0){
                    while(startDate <= endDate) {
                        Date startOfWeek = startDate.toStartofWeek();
                        Integer dayOfWeek = startOfWeek.daysBetween(startDate);
                        
                        batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                        String startDateStr = String.valueOf(startDate);
                        batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                        if(anAuthEncmbr != null){
                            if(hoursPerDay.CDE_TYPE_UNIT_CARE__c != '--None--' && hoursPerDay.CNT_HOUR_CARE__c != null){
                                anAuthEncmbr.idn_auth__c = anAuthEncmbr.idn_auth__c;
                                anAuthEncmbr.cde_status_encmbr__c = anAuthEncmbr.cde_status_encmbr__c; //Authorized
                                anAuthEncmbr.cnt_hour_care__c = hoursPerDay.CNT_HOUR_CARE__c;
                                anAuthEncmbr.cde_type_unit_care__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                                anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                                authEncmbrsToBeInserted.add(anAuthEncmbr);
                            }
                        }
                        startDate = startDate.addDays(1);
                    }
                }else{
                    isErrorWebservice = 'No encumbrance records returned FROM web service';
                } 
            }
            
            if(Test.isRunningTest()){
                batchsit_t_auth_encmbr__x en = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth(),cnt_hour_care__c =5);
                batchsit_t_auth_encmbr__x en1 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+1,cnt_hour_care__c =10);
                batchsit_t_auth_encmbr__x en2 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+2,cnt_hour_care__c =17);
                batchsit_t_auth_encmbr__x en3 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+4,cnt_hour_care__c =0);
                batchsit_t_auth_encmbr__x en4 = new batchsit_t_auth_encmbr__x(dte_care__c =System.today().addMonths(2).toStartofMonth()+5,cnt_hour_care__c =22);
                authEncmbrsToBeInserted.add(en);
                authEncmbrsToBeInserted.add(en1);
                authEncmbrsToBeInserted.add(en2);
                authEncmbrsToBeInserted.add(en3);
                authEncmbrsToBeInserted.add(en4);
                isUpdate=true;
            }
            if(authEncmbrsToBeInserted.size() >0){
                if(isUpdate){
                    //Change as part of CCCAP-6778 Diya
                    for (Integer i = authEncmbrsToBeInserted.size() - 1; i >= 0 ; --i) {
                        if (authEncmbrsToBeInserted.get(i).cde_status_encmbr__c =='5' ) {
                            authEncmbrsToBeInserted.remove(i); 
                        }
                    }
                    String dataBody = encumbJsonString(authEncmbrsToBeInserted);
                    if(!String.isEmpty(dataBody)){
                        if(!Test.isRunningTest()){
                            IndividualCareLvlApexCtrl.authEncumbranceUpdate(dataBody);
                        }
                    }
                }
            }
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: authEncmbrsToBeInserted){
                Date careDate = anAuthEncmbr.dte_care__c;
                String monthStr = String.valueOf(careDate.month());
                String dayStr = String.valueOf(careDate.day());
                if(careDate.month()<10){
                    monthStr = '0'+monthStr;
                }
                if(careDate.day()<10){
                    dayStr = '0'+dayStr;
                }
                String keyStr = careDate.year()+'-'+monthStr+'-'+dayStr;
                careDateToAuthEncmbr2.put(keyStr, anAuthEncmbr);
                
                // careDateToAuthEncmbrId.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(),anAuthEncmbr);
            }
            AuthorizationNotesController.createAuthSchRecurr(authEncumWrap,authRecId);
            for(batchsit_t_auth_encmbr__x anAuthEncmbr: fetchedEncumberence ){
                Date careDate = anAuthEncmbr.dte_care__c;
                String monthStr = String.valueOf(careDate.month());
                String dayStr = String.valueOf(careDate.day());
                if(careDate.month()<10){
                    monthStr = '0'+monthStr;
                }
                if(careDate.day()<10){
                    dayStr = '0'+dayStr;
                }
                String keyStr = careDate.year()+'-'+monthStr+'-'+dayStr;
                batchsit_t_auth_encmbr__x anAuthEncmbrUpdated = careDateToAuthEncmbr2.get(keyStr);
                careDateToAuthEncmbrId.put(careDate.year()+'-'+careDate.month()+'-'+careDate.day(),anAuthEncmbrUpdated); 
                
                
                
            }
            // added for CCCAP-10162 for CHATS reverse Referral
            if(currentMode !='viewAuth'&&
                (authRec.IDN_CASE__r.Program_Type__c=='LI' || authRec.IDN_CASE__r.Program_Type__c=='TF')
            )
            {
                List<T_SBSD_Case__c> cases = new List<T_SBSD_Case__c>(); 
                if(authRec.Auth_Reverse_Refer_Track__c== false){
                    List<T_AUTH__c> auths = new List<T_AUTH__c>(); 
                    authRec.Auth_Reverse_Refer_Track__c = true;
                    auths.add(authRec);
                    GenericDMLhandler.updateRecords(auths, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_AUTH__c'},'Class__c'=>'AuthorizationFlowApxCtrl','Method__c'=>'updateAuthEncmbrRecordsBasedOnPatterns'});
                }
                T_SBSD_Case__c cs = new T_SBSD_Case__c(Id=authRec.IDN_CASE__c,Case_Reverse_Refer_Track__c =true);
                string revReferMode ='';
                if(authRec.IDN_CASE__r.CHATS_Reverse_Refer_Mode__c!=null){
                    if(!authRec.IDN_CASE__r.CHATS_Reverse_Refer_Mode__c.contains('Auth Schedules Update')){
                        revReferMode = authRec.IDN_CASE__r.CHATS_Reverse_Refer_Mode__c+';Auth Schedules Update';
                    }
                }else{
                    revReferMode ='Auth Schedules Update';
                }
                cs.CHATS_Reverse_Refer_Mode__c =  revReferMode;
                cases.add(cs);
                GenericDMLhandler.updateRecords(cases, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_Case__c'},'Class__c'=>'AuthorizationFlowApxCtrl','Method__c'=>'updateAuthEncmbrRecordsBasedOnPatterns'}, new List<String>{'Case_Reverse_Refer_Track__c','CHATS_Reverse_Refer_Mode__c'});
            }
            message = isErrorWebservice;
            objectData.put('careDateToAuthEncmbr' ,careDateToAuthEncmbrId);
            //return new LightningServerResponse(true, isErrorWebservice,new Map<String, object>{'careDateToAuthEncmbr' => careDateToAuthEncmbrId});
        }
        catch(Exception ex){
            message = ex.getMessage();
            if(fetchedEncumberence == null || fetchedEncumberence.size() <=0 ){
                message = 'Problem in connecting with external system.';
            }
            isSuccessful = false;
            objectData = null;
            //return new LightningServerResponse(false, message1, null);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    //end
    @auraEnabled
    public static LightningServerResponse callUpdate(List<batchsit_t_auth_encmbr__x> lstAuthEncumbRec){
        
        String jSonEncumb = encumbJsonString(lstAuthEncumbRec);
                
        Map<String, String> updateResponse = new Map<String, String>();
        if(!Test.isRunningTest()){
        updateResponse =HerokuService.authEncumbranceUpdate(jSonEncumb);
        }
        if (updateResponse.get('successInd')=='Y'){        
            return new LightningServerResponse(true,'Update Success',null);
        }
        else{
            return new LightningServerResponse(false,(String)updateResponse.get('errorMessage'),null);
        }
    }
    
    //CCCAP-15329 - Generates CR215 correspondence for authorizations (bulkified)
    public static void CR215CorrBulk(Set<Id> authIds, Boolean isFromFlow) {
        if (authIds == null || authIds.isEmpty()) {
            return;
        }
        String CR215RsnCode = 'CR0028';
        Set<Id> authsWithExistingCR215 = new Set<Id>();
        for (T_DOC_RQ__c existingCorspd : [SELECT IDN_AUTH__c FROM T_DOC_RQ__c WHERE NME_CORSPD__c = 'CR215' AND CDE_CORSPD_STATUS__c = 'Requested'
                                            AND IDN_AUTH__c IN :authIds]) {
            authsWithExistingCR215.add(existingCorspd.IDN_AUTH__c);
        }
        List<T_AUTH__c> auths = [SELECT Id, Name, IDN_CASE__r.Name, IDN_PROVR__r.Name, IDN_PROVR__r.CDE_ATS_WAIVER__c,
                                IDN_PROVR__r.CDE_ELV_WAIVER__c, CDE_COUNTY__r.CDE_COUNTY__c, isFinishedFlow__c, CDE_CHILD_ENROLLED_IN_UPK__c,
                                Is_UPK_Stacked__c FROM T_AUTH__c WHERE Id IN :authIds ];
        for (T_AUTH__c auth : auths) {
            if (authsWithExistingCR215.contains(auth.Id)) {
                continue;
            }
            if(isFromFlow || (!isFromFlow && (auth.IDN_PROVR__r.CDE_ATS_WAIVER__c == true || auth.IDN_PROVR__r.CDE_ELV_WAIVER__c == true))){
                Map<String, String> keyParams = new Map<String, String>();
                keyParams.put('caseId', auth.IDN_CASE__r.Name);
                keyParams.put('providerId', auth.IDN_PROVR__r.Name);
                keyParams.put('authId', auth.Id);
                Integer countyCode = Integer.valueOf(auth.CDE_COUNTY__r.CDE_COUNTY__c);
                if (!Test.isRunningTest()) {
                    CorspdTrigger.createCorspdRequest(CR215RsnCode, null, null, countyCode, keyParams);
                }
            }
        }
    }

    //CCCAP-15329 - Generates CR215 correspondence from flow scheduled path
    @InvocableMethod(label='Create CR215 Correspondence' 
                     description='Creates CR215 for the given authorization IDs' 
                     category='Authorization')
    public static void createCR215CorrespondenceInvocable(List<Id> authIds) {
        if (authIds == null || authIds.isEmpty()) {
            return;
        }
        
        Set<Id> authIdSet = new Set<Id>(authIds);
        CR215CorrBulk(authIdSet, true);
    }
    
     @auraEnabled
    public static LightningServerResponse setAuthorizationFlag(String authId,Boolean isCreate,Boolean isCreateCorrp,Boolean createTaskT122){
    	Boolean isInsert = false;
	    Boolean isInsertAuth = false;
        T_AUTH__c auth = new T_AUTH__c();
        List<T_AUTH__c> AuthNameList =  new List<T_AUTH__c>();
        try{
            for(T_AUTH__c authRec :[SELECT Id, Name, IDN_PROVR__c, IDN_CASE__c, IDN_CASE__r.CDE_COUNTY__c, isFinishedFlow__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE Id =: authId WITH SECURITY_ENFORCED]) {
                if(authRec != null){
                    if(!authRec.isFinishedFlow__c  && Schema.sObjectType.T_AUTH__c.fields.isFinishedFlow__c.isUpdateable()){
                        isInsertAuth = true;
                    }
                    authRec.isFinishedFlow__c = true;
                    auth = authRec;
                    isInsert = true;
                }
            }
            if(auth != null){
                GenericDMLHandler.updateRecords(new List<SObject>{auth}, new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'AuthorizationFlowApxCtrl'},new List<String>{'isFinishedFlow__c'});
                T_AUTH__c authUpdated = [SELECT Id, Name, IDN_PROVR__c, IDN_CASE__c, IDN_CASE__r.Name, IDN_CLIENT__c, IDN_CASE__r.CDE_COUNTY__c, IDN_CASE__r.CDE_COUNTY__r.Name, isFinishedFlow__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE Id =:authId WITH SECURITY_ENFORCED];
                if(authUpdated != null && authUpdated.isFinishedFlow__c){
                    AuthNameList.add(authUpdated);
                    if(isCreate){
                        AuthorizationNotesController.CR213Corr(auth.Id);
                        AuthorizationStatusController.insertATSRecords(AuthNameList);
                        if(Schema.sObjectType.Exception_Log__c.isCreateable()) {
                            Exception_Log__c xLog = new Exception_Log__c();
                            xLog.Class__c = 'AuthorizationFlowApxCtrl';
                            xLog.Method__c = 'setAuthorizationFlag';
                            xLog.Exception_Message__c = 'Authorization flow complete flag is set';
                            xLog.Exception_Type__c = 'Success';
                            xLog.Record_ID__c = auth.Id;
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog},false,new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'AuthorizationFlowApxCtrl'},new List<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c','Record_ID__c'});
                        }
                        createT110Task(authUpdated);
                    } else {
                        if(isInsertAuth){
                            AuthorizationNotesController.CR213Corr(auth.Id);
                            AuthorizationStatusController.insertATSRecords(AuthNameList);
                        }else if(isCreateCorrp && (!isInsertAuth)){
                            AuthorizationNotesController.CR213Corr(auth.Id);
                            AuthorizationStatusController.insertATSRecords(AuthNameList);
                        }else{
                            AuthorizationStatusController.insertATSRecords(AuthNameList);
                        }
                        if(Schema.sObjectType.Exception_Log__c.isCreateable()) {
                            Exception_Log__c xLog = new Exception_Log__c();
                            xLog.Class__c = 'AuthorizationFlowApxCtrl';
                            xLog.Method__c = 'setAuthorizationFlag';
                            xLog.Exception_Message__c = 'Authorization Edit flow';
                            xLog.Exception_Type__c = 'Success';
                            xLog.Record_ID__c = auth.Id;
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog},false,new Map<String,Object>{'Method__c'=>'setAuthorizationFlag','Class__c'=>'AuthorizationFlowApxCtrl'},new List<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c','Record_ID__c'});
                        }
                    }
                    // CCCAP-15329: Create Task T122 if UPK enrolled value changed
                    if (createTaskT122 != null && createTaskT122) {
                        AuthorizationServices.createTaskT122(new Set<Id>{authId});
                    }
                }
		    /*  AuthNameList.add(auth);
                if(isCreateCorrp && !isCreate){
                     AuthorizationNotesController.CR213Corr(auth.Id);
                }
                if(AuthNameList.size()>0 && isCreate){
                    AuthorizationStatusController.insertATSRecords(AuthNameList);
                    AuthorizationNotesController.CR213Corr(auth.Id);
		    AuthorizationStatusController.insertATSRecords(AuthNameList);
                    
                    //logging Succcess exception.
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'AuthorizationFlowApxCtrl';
                    xLog.Method__c = 'setAuthorizationFlag';
                    xLog.Exception_Message__c = 'Authorization flow complete flag is set for '+auth.Id;
                    xLog.Exception_Type__c = 'Success';
                    insert xLog;
                }else{
                    //logging Edit flow Succcess exception.
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'AuthorizationFlowApxCtrl';
                    xLog.Method__c = 'setAuthorizationFlag';
                    xLog.Exception_Message__c = 'Authorization Edit flow for auth'+auth.Id;
                    xLog.Exception_Type__c = 'Success';
                    xLog.Record_ID__c = auth.Id;
                    insert xLog;
                }
		     if(!(isCreate) && isInsertAuth && AuthNameList.size()>0){
		    AuthorizationNotesController.CR213Corr(auth.Id);
                }
                if(!(isCreate) && isInsert && AuthNameList.size()>0){
                    AuthorizationStatusController.insertATSRecords(AuthNameList);
                }*/
            }
            return new LightningServerResponse(true,'Update Success',null);
        } catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AuthorizationFlowApxCtrl','Method__c'=>'setAuthorizationFlag'});   
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }
    
    @auraEnabled
    public static LightningServerResponse createSCAssociationRecord(String authId, String scAssRec, String scAssRecOldValue){
        Map<String, String> objectData = new map<String, String>();
        List<T_SLOT_CONTRACT__c> scRecToCreate =  new List<T_SLOT_CONTRACT__c>();
        List<T_SLOT_CONTRACT__c> scRecToUpdate =  new List<T_SLOT_CONTRACT__c>();
        Date dt = system.today();
        try{
            T_AUTH__c authRec = [SELECT Id, IDN_SLOT_CONTRACT__c, DTE_BEGIN_EFFV_AUTH__c, DTE_BEGIN_SLOT__c, DTE_REMOVAL_SLOT__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id =:authId WITH SECURITY_ENFORCED];
            T_SLOT_CONTRACT__c scRec;
            for(T_SLOT_CONTRACT__c rec : [SELECT Id, IDN_ADDENDUM__c, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IND_AVAILABLE__c, IDN_AUTH__c, IND_OCCUPIED__c, 
                                        	SLOT_CONTRACT_DESCRIPTION__c, IDN_PROVIDER__c, CDE_COUNTY__c, CNT_DAYS_OF_MONTH__c, CNT_DAYS_OF_WEEK__c,
                                        	CDE_CARE_UNIT__c, CDE_CARE_LEVEL__c, CDE_RATE_TYPE__c, CDE_PRG_TYPE__c, IND_FUTURE_VACANT__c
                                          FROM T_SLOT_CONTRACT__c WHERE Id =:scAssRec WITH SECURITY_ENFORCED]){
                scRec = rec;
            }
            T_SLOT_CONTRACT__c scAssRecOldValueRec;
            for(T_SLOT_CONTRACT__c rec : [SELECT Id, IDN_ADDENDUM__c, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IND_AVAILABLE__c, IDN_AUTH__c, IND_OCCUPIED__c, 
                                            SLOT_CONTRACT_DESCRIPTION__c, IDN_PROVIDER__c, CDE_COUNTY__c, CNT_DAYS_OF_MONTH__c, CNT_DAYS_OF_WEEK__c,
                                            CDE_CARE_UNIT__c, CDE_CARE_LEVEL__c, CDE_RATE_TYPE__c, CDE_PRG_TYPE__c, IND_FUTURE_VACANT__c 
                                            FROM T_SLOT_CONTRACT__c WHERE Id =:scAssRecOldValue WITH SECURITY_ENFORCED]){
                scAssRecOldValueRec = rec;
            }
            if(scRec != null) {
            	//Scenario 10c(when Authorization Slot Begin Date is same as Auth begin date)
                if(authRec.DTE_BEGIN_SLOT__c != null && scRec.DTE_BEGIN_SLOT__c == authRec.DTE_BEGIN_SLOT__c 
                   && (authRec.DTE_END_EFFV_AUTH__c == null || scRec.DTE_END_SLOT__c <= authRec.DTE_END_EFFV_AUTH__c)
                   && Schema.sObjectType.T_SLOT_CONTRACT__c.fields.IDN_AUTH__c.isCreateable() && Schema.sObjectType.T_SLOT_CONTRACT__c.fields.IDN_AUTH__c.isUpdateable()){
                    scRec.IDN_AUTH__c = authRec.Id;
                    scRecToUpdate.add(scRec);
                }
            	//When Authorization end date is less than Slot End Date
                if(authRec.DTE_BEGIN_SLOT__c != null && scRec.DTE_BEGIN_SLOT__c == authRec.DTE_BEGIN_SLOT__c 
                   		&& scRec.DTE_END_SLOT__c > authRec.DTE_END_EFFV_AUTH__c){
                    T_SLOT_CONTRACT__c newScRec = scRec.clone();
                    if(Schema.sObjectType.T_SLOT_CONTRACT__c.fields.DTE_BEGIN_SLOT__c.isCreateable()){
                        newScRec.DTE_BEGIN_SLOT__c = authRec.DTE_END_EFFV_AUTH__c.addDays(1);
                    }
                    if(Schema.sObjectType.T_SLOT_CONTRACT__c.fields.DTE_END_SLOT__c.isCreateable()){
                        newScRec.DTE_END_SLOT__c = scRec.DTE_END_SLOT__c;
                    }
                    newScRec.IDN_AUTH__c = null;
                    scRecToCreate.add(newScRec);
                    if(Schema.sObjectType.T_SLOT_CONTRACT__c.fields.IDN_AUTH__c.isUpdateable()){
                        scRec.IDN_AUTH__c = authRec.Id;
                    }
                    if(Schema.sObjectType.T_SLOT_CONTRACT__c.fields.DTE_END_SLOT__c.isUpdateable()){
                        scRec.DTE_END_SLOT__c = authRec.DTE_END_EFFV_AUTH__c;
                    }
                    scRecToUpdate.add(scRec);
                }
                //Scenario 10a, 10b OR 11a (when Authorization Slot Begin Date is greater than Slot Contract begin date)
                else if(authRec.DTE_BEGIN_SLOT__c != null && authRec.DTE_BEGIN_SLOT__c != scRec.DTE_BEGIN_SLOT__c 
                        && authRec.DTE_BEGIN_SLOT__c > scRec.DTE_BEGIN_SLOT__c){
                    T_SLOT_CONTRACT__c newScRecOne = scRec.clone();
                    newScRecOne.DTE_BEGIN_SLOT__c = authRec.DTE_BEGIN_SLOT__c;
                    newScRecOne.DTE_END_SLOT__c = scRec.DTE_END_SLOT__c;
                    newScRecOne.IDN_AUTH__c = authRec.Id;
                    scRec.DTE_END_SLOT__c = authRec.DTE_BEGIN_SLOT__c.addDays(-1);
                    if(scRec != Null && scAssRecOldValueRec != Null && scRec.Id == scAssRecOldValueRec.Id) {
                        scRec.IDN_AUTH__c = Null;
                    }
                    scRecToUpdate.add(scRec);
                    if(newScRecOne.DTE_END_SLOT__c > authRec.DTE_END_EFFV_AUTH__c){
                        T_SLOT_CONTRACT__c newScRec = scRec.clone();
                        newScRec.DTE_BEGIN_SLOT__c = authRec.DTE_END_EFFV_AUTH__c.addDays(1);
                        newScRec.DTE_END_SLOT__c = newScRecOne.DTE_END_SLOT__c;
                        newScRec.IDN_AUTH__c = null;
                        scRecToCreate.add(newScRec);
                        newScRecOne.DTE_END_SLOT__c = authRec.DTE_END_EFFV_AUTH__c;
                    }
                    scRecToCreate.add(newScRecOne);
                }
            }
            //Scenario 11b(while editing, when slot contract association record is replaced with a new one)
            if(scRec != null && scAssRecOldValueRec != null && scAssRecOldValueRec.Id != scRec.Id){                   
                if(authRec.DTE_BEGIN_SLOT__c <= scAssRecOldValueRec.DTE_END_SLOT__c && authRec.DTE_BEGIN_SLOT__c > scAssRecOldValueRec.DTE_BEGIN_SLOT__c){
                    T_SLOT_CONTRACT__c newScRecTwo = scAssRecOldValueRec.clone();
                    newScRecTwo.DTE_BEGIN_SLOT__c = authRec.DTE_BEGIN_SLOT__c;
                    newScRecTwo.DTE_END_SLOT__c = scAssRecOldValueRec.DTE_END_SLOT__c;
                    newScRecTwo.IDN_AUTH__c = null;
                    scRecToCreate.add(newScRecTwo);
                    scAssRecOldValueRec.DTE_END_SLOT__c = newScRecTwo.DTE_BEGIN_SLOT__c.addDays(-1);
                    scRecToUpdate.add(scAssRecOldValueRec);
                }
            }
            //Scenario 11c (while editing, when slot contract association record is replaced with no record 
            //but with Auth slot begin date)
            else if(scRec == null && scAssRecOldValue != null){
                Boolean withoutSlotDate = false;
                if(authRec.DTE_BEGIN_SLOT__c == null){
                    authRec.DTE_BEGIN_SLOT__c = Date.Today();
                    withoutSlotDate = true;
                }
                if(authRec.DTE_BEGIN_SLOT__c != null && authRec.DTE_BEGIN_SLOT__c > scAssRecOldValueRec.DTE_BEGIN_SLOT__c && authRec.DTE_BEGIN_SLOT__c <= scAssRecOldValueRec.DTE_END_SLOT__c){
                    T_SLOT_CONTRACT__c newScRecTwo = scAssRecOldValueRec.clone();
                    newScRecTwo.DTE_BEGIN_SLOT__c = authRec.DTE_BEGIN_SLOT__c;
                    newScRecTwo.DTE_END_SLOT__c = scAssRecOldValueRec.DTE_END_SLOT__c;
                    newScRecTwo.IDN_AUTH__c = null;
                    scRecToCreate.add(newScRecTwo);
                    scAssRecOldValueRec.DTE_END_SLOT__c = newScRecTwo.DTE_BEGIN_SLOT__c.addDays(-1);
                    scRecToUpdate.add(scAssRecOldValueRec);
                    if(Schema.sObjectType.T_AUTH__c.fields.DTE_REMOVAL_SLOT__c.isUpdateable()){
                        authRec.DTE_REMOVAL_SLOT__c = authRec.DTE_BEGIN_SLOT__c;
                    }
                    if(Schema.sObjectType.T_AUTH__c.fields.DTE_BEGIN_SLOT__c.isUpdateable()){
                        authRec.DTE_BEGIN_SLOT__c = null;
                    }
                } else if(scRec == null && scAssRecOldValue != null && authRec.DTE_BEGIN_SLOT__c != null && 
                        ((!withoutSlotDate && authRec.DTE_BEGIN_SLOT__c <= scAssRecOldValueRec.DTE_BEGIN_SLOT__c) || (authRec.DTE_BEGIN_SLOT__c == scAssRecOldValueRec.DTE_BEGIN_SLOT__c))){          
                    scAssRecOldValueRec.IDN_AUTH__c = null;
                    scRecToUpdate.add(scAssRecOldValueRec);
                    authRec.DTE_REMOVAL_SLOT__c = authRec.DTE_BEGIN_SLOT__c;
                    authRec.DTE_BEGIN_SLOT__c = null;
                }
            }
            if(!scRecToCreate.isEmpty()){
                GenericDMLHandler.insertRecords(scRecToCreate, null); 
            }
            if(!scRecToUpdate.isEmpty()){
                GenericDMLHandler.updateRecords(scRecToUpdate, null); 
            }
            for(T_SLOT_CONTRACT__c sc : [SELECT Id, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IDN_AUTH__c FROM T_SLOT_CONTRACT__c 
                                        WHERE IDN_AUTH__c = :authRec.Id AND DTE_BEGIN_SLOT__c = :authRec.DTE_BEGIN_SLOT__c WITH SECURITY_ENFORCED]){
                if(Schema.sObjectType.T_AUTH__c.fields.DTE_REMOVAL_SLOT__c.isUpdateable()){
                    authRec.IDN_SLOT_CONTRACT__c = sc.Id;
                }
            }
            GenericDMLHandler.updateRecords(new List<T_AUTH__c>{authRec}, null, new List<String>{'IDN_SLOT_CONTRACT__c','DTE_REMOVAL_SLOT__c','DTE_BEGIN_SLOT__c'});
            objectData.put('SlotContractId',authRec.IDN_SLOT_CONTRACT__c);
            return new LightningServerResponse(true,'Success',objectData);
        } catch(Exception ex){
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AuthorizationFlowApxCtrl','Method__c'=>'createSCAssociationRecord'});   
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }

    @AuraEnabled
    public static LightningServerResponse finishAuthorization(String authId){
        String countyId ;
        Set<Id> setProviderIds= new Set<Id>();
        T_AUTH__c auth = new T_AUTH__c();
        for(T_AUTH__c authRec :[SELECT Id, IDN_PROVR__c,IDN_CASE__c,IDN_CASE__r.CDE_COUNTY__c FROM T_AUTH__c WHERE Id =:authId WITH SECURITY_ENFORCED]){
            auth =authRec;
            countyId=authRec.IDN_CASE__r.CDE_COUNTY__c;
            setProviderIds.add(authRec.IDN_PROVR__c);
        }
        String isQualityRating ='N';
        boolean indQuality= false;
        for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement : [SELECT Id, (Select TXT_CHATS_RATING__c FROM Rate_Schedules__r ORDER BY  CreatedDate DESC LIMIT 1 ) FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c in :setProviderIds AND DTE_BEGIN_AGRMT__c<= today AND (DTE_END_AGRMT__c >= today OR DTE_END_AGRMT__c=null) AND CDE_COUNTY__c=:countyId WITH SECURITY_ENFORCED]){
            if(fiscalAgreement.Rate_Schedules__r != null){
                if(fiscalAgreement.Rate_Schedules__r.get(0)!= null && 
                (fiscalAgreement.Rate_Schedules__r.get(0).TXT_CHATS_RATING__c=='Level 3'
                    ||fiscalAgreement.Rate_Schedules__r.get(0).TXT_CHATS_RATING__c=='Level 4'
                    ||fiscalAgreement.Rate_Schedules__r.get(0).TXT_CHATS_RATING__c=='Level 5')){
                        indQuality=true;
                        isQualityRating ='Y';
                        break;
                    }
            }
        }
        if(!Test.isRunningTest()){
           // AuthorizationStatusController.getAuthWeight( auth, true,  isQualityRating);
        }
        return new LightningServerResponse(true,'Update Success',null);
    }

    public static Exception_Log__c getXLog(String methodName,String exceptionMessage,String exceptionType, String request, String response, String logType){
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'AuthorizationFlowApxCtrl';
        xLog.Method__c = methodName;
        xLog.Exception_Message__c = exceptionMessage;
        xLog.Exception_Type__c = exceptionType;
        xLog.Request__c = request; 
        xLog.Response__c = response;
        xLog.Log_Type__c = logType;
        return xLog;
    }

    public static void createT110Task(T_Auth__c auth){
        Boolean isJointCustody = false;
        List<Id> lstCaseIds = new List<Id>();
        Map<Id, T_SBSD_CASE_INDIV__c> CaseToCaseIndivMap = new Map<Id, T_SBSD_CASE_INDIV__c>();
        Set<Id> setCaseIds = new Set<Id>();
        List<task> lstTaskToInsert = new List<Task>();
        for (T_INDIV_CUST__c custody:[SELECT id, Name, IDN_CLIENT__c FROM T_INDIV_CUST__c WHERE IDN_CLIENT__c =: auth.IDN_CLIENT__c AND DTE_BEGIN_EFFV__c <=:system.today() AND (DTE_END_EFFV__c =null OR DTE_END_EFFV__c >: system.today()) WITH SECURITY_ENFORCED]){
            isJointCustody = true;
        }
        if(isJointCustody){
            for (T_SBSD_CASE_INDIV__c caseIndivRec :[SELECT Id, Name, IDN_CLIENT__c,IDN_CASE__c, IDN_CASE__r.OwnerId   FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c=:auth.IDN_CLIENT__c WITH SECURITY_ENFORCED]){
                CaseToCaseIndivMap.put(caseIndivRec.IDN_CASE__c, caseIndivRec);
            }
            for (T_SBSD_CASE__c caseRec : [SELECT Id,Name,CDE_COUNTY__R.NAME,OWNER.NAME,OwnerId,
                                           (SELECT IDN_CLIENT__r.NAM_FIRST__c,IDN_CLIENT__r.NAM_LAST__c FROM CaseIndividuals__r WHERE IND_CRTKR__c=true 
                                            AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY) Limit 1),
                                           (SELECT CDE_STATUS_CASE__c,toLabel(CDE_MODE_CASE__c), DTE_BEGIN_EFFV__c FROM T_SBSD_CASE10__r WHERE DTE_END_EFFV__c>=Today OR DTE_END_EFFV__c = null ORDER BY DTE_BEGIN_EFFV__c, createddate Desc NULLS FIRST Limit 1)
                                           FROM T_SBSD_CASE__c WHERE Id in:CaseToCaseIndivMap.keyset() AND Id !=:auth.IDN_CASE__c WITH SECURITY_ENFORCED]){
                                              if(caseRec.T_SBSD_CASE10__r.size()>0 && caseRec.T_SBSD_CASE10__r[0].CDE_STATUS_CASE__c =='OPN'){
                                                   Task taskRec = new Task();
                                                   taskRec.WhatId = caseRec.Id;
                                                   taskRec.Subject = Label.t110Subject;
                                                   taskRec.Status = 'New';
                                                   taskRec.Description = 'For case Individual '+ caseToCaseIndivMap.get(caseRec.Id).Name
                                                       +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_CASE_INDIV__c/'+caseToCaseIndivMap.get(caseRec.Id).Id
                                                       +'/view ), '+ auth.Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_AUTH__c/'+auth.Id
                                                       +'/view )'+
                                                       ' has been created for '+ auth.IDN_CASE__r.Name + '('+URL.getOrgDomainUrl().toExternalForm()+'/lightning/r/T_SBSD_CASE__c/'
                                                       + auth.IDN_CASE__c
                                                       +'/view ) in '+auth.IDN_CASE__r.CDE_COUNTY__r.name
                                                       +'. Please verify the schedules of care for your county.';
                                                   taskRec.OwnerId = caseRec.OwnerId;
                                                   taskRec.ActivityDate = system.today().addDays(10);
                                                   lstTaskToInsert.add(taskRec);
                                               }
                                           }
            if(!lstTaskToInsert.isEmpty()){
                GenericDMLHandler.insertRecords(lstTaskToInsert, null, new List<String>{'WhatId','Subject','Status','Description','OwnerId','ActivityDate'}); 
            }
        }
    }
    /*
    added this method for CCCAP-9439
    purpose is to invoke webservice for querying 
    Authorization Status Records(batchsit_t_auth_status__x)
    */
    public static LightningServerResponse hitAuthStatusWebService(requestParams req){
        Map<String, Object> objectData = new map<String, Object>();
        LightningServerResponse resp;
        List<AuthStatusPckt> authWrappers = new List<AuthStatusPckt>();
        Integer responsecode;
        try{
            Httprequest httpRequest = new Httprequest();
            Http http = new Http();
            HttpRequest.setHeader('Content-type', 'application/json;charset=UTF-8');
            HttpRequest.setHeader('Accept', 'application/json');
            httpRequest.setEndpoint(System.label.GetAuthStatusRecords);
            httpRequest.setMethod('POST');
            httpRequest.setTimeout(120000);
            String requestBody =  JSON.serialize(req);
            httpRequest.setBody(requestBody);
            Httpresponse response = http.send(httpRequest);
            responsecode		=	response.getStatusCode();
            string responseBody = response.getBody();
            Map<String, Object> listJson = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            if(response !=NULL && response.getStatusCode() == 200){
                if(listJson.get('success') == 'success'){
                    authWrappers= (List<AuthStatusPckt>) JSON.deserialize(JSON.serialize(listJson.get('authStatusList')),List<AuthStatusPckt>.class);
	                objectData.put('authstatuses',authWrappers);
	                resp = new LightningServerResponse(true,'success',objectData);
                }else{
                    resp = new LightningServerResponse(false,(string)listJson.get('errorMessage'),objectData);                
                }
            }else if(response !=NULL && response.getStatusCode() != 200){
                ExceptionLoggingServices.captureExceptionLog(response, httpRequest, new Map<String,Object>{'Class__c'=>'AuthorizationFlowApxCtrl','Method__c'=>'hitAuthStatusWebService'});                
                resp = new LightningServerResponse(false,(string)listJson.get('error'),objectData);
            }
        }catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AuthorizationFlowApxCtrl','Method__c'=>'hitAuthStatusWebService'});
            resp = new LightningServerResponse(false,'error',objectData);
        }        
        return resp;
    }
    public class requestParams {
        public string authId;
        public String orderby;
        public String order;
        public String limitoffset;
        public requestParams(string authId,String orderby,String order,String limitoffset){
            this.authId=authId;
            this.orderby = orderby;
            this.order = order;
            this.limitoffset = limitoffset;
        }
    }

    public static List<batchsit_t_auth_encmbr__x> convertToAuthEncumbrList(Object authEncumbrListObj) {
        List<batchsit_t_auth_encmbr__x> result = new List<batchsit_t_auth_encmbr__x>();
        if (authEncumbrListObj == null) {
            return result;
        }        
        List<Object> dataList = (List<Object>) authEncumbrListObj;
        for (Object item : dataList) {
            AuthEncumbrWrapper wrapper = convertToAuthEncumbrWrapper(item);
            result.add(wrapper.toExternalObject());
        }
        return result;
    }

    public static AuthEncumbrWrapper convertToAuthEncumbrWrapper(Object authEncumbrObj) {
        AuthEncumbrWrapper wrapper = new AuthEncumbrWrapper();
        if (authEncumbrObj == null) {
            return wrapper;
        }        
        Map<String, Object> authEncumbrMap = (Map<String, Object>) authEncumbrObj;
        wrapper.externalId = authEncumbrMap.get('ExternalId') != null ? String.valueOf(authEncumbrMap.get('ExternalId')) : null;
        wrapper.idnAuth = authEncumbrMap.get('idn_auth__c') != null ? String.valueOf(authEncumbrMap.get('idn_auth__c')) : null;
        wrapper.idnEncmbrAuth = authEncumbrMap.get('idn_encmbr_auth__c') != null ? String.valueOf(authEncumbrMap.get('idn_encmbr_auth__c')) : null;
        wrapper.cdeLevelCare = authEncumbrMap.get('cde_level_care__c') != null ? String.valueOf(authEncumbrMap.get('cde_level_care__c')) : null;
        wrapper.cdeStatusEncmbr = authEncumbrMap.get('cde_status_encmbr__c') != null ? String.valueOf(authEncumbrMap.get('cde_status_encmbr__c')) : null;
        wrapper.cdeTypeUnitCare = authEncumbrMap.get('cde_type_unit_care__c') != null ? String.valueOf(authEncumbrMap.get('cde_type_unit_care__c')) : null;
        wrapper.cntHourCare = authEncumbrMap.get('cnt_hour_care__c') != null ? String.valueOf(authEncumbrMap.get('cnt_hour_care__c')) : null;
        wrapper.dteCare = authEncumbrMap.get('dte_care__c') != null ? String.valueOf(authEncumbrMap.get('dte_care__c')) : null;
        wrapper.ind036Months = authEncumbrMap.get('ind_0_36_months__c') != null ? String.valueOf(authEncumbrMap.get('ind_0_36_months__c')) : null;
        return wrapper;
    }

    
    //added for CCCAP-15329
    @AuraEnabled
    public static T_UPK_INDIV_AUTH_INFO__c getLatestUPKInfo(String clientId, String providerId) {
        if (String.isBlank(clientId) || String.isBlank(providerId)) {
            return null;
        }
        Date cutoffDate = CHATSUtility.getUPKCutoffDate();
        List<T_UPK_INDIV_AUTH_INFO__c> upkRecords = [SELECT Id, Is_the_child_dually_enrolled_in_UPK__c, UPK_Stacking_Hours__c, 
            UPK_Enrollment_Start_Date__c, IDN_CLIENT__c, IDN_PROVR__c, CreatedDate FROM T_UPK_INDIV_AUTH_INFO__c
            WHERE IDN_CLIENT__c = :clientId AND IDN_PROVR__c = :providerId AND CreatedDate >= :cutoffDate ORDER BY CreatedDate DESC LIMIT 1];
        return upkRecords.isEmpty() ? null : upkRecords[0];
    }

    //added for CCCAP-15329
    public static T_SBSD_INDIV__c getClientDetails(String clientId) {
        if (String.isBlank(clientId)) {
            return null;
        }        
        List<T_SBSD_INDIV__c> individuals = [SELECT Id, Name, Age__c FROM T_SBSD_INDIV__c WHERE Id = :clientId LIMIT 1];
        if (individuals.isEmpty()) {
            return null;
        }
        T_SBSD_INDIV__c individual = individuals[0];
        return individual;
    }

    public class AuthEncumbrWrapper {
        @AuraEnabled public String externalId;
        @AuraEnabled public String idnAuth;
        @AuraEnabled public String idnEncmbrAuth;
        @AuraEnabled public String cdeLevelCare;
        @AuraEnabled public String cdeStatusEncmbr;
        @AuraEnabled public String cdeTypeUnitCare;
        @AuraEnabled public String cntHourCare;
        @AuraEnabled public String dteCare;
        @AuraEnabled public String ind036Months;

        public AuthEncumbrWrapper() {}
        public batchsit_t_auth_encmbr__x toExternalObject() {
            batchsit_t_auth_encmbr__x extObj = new batchsit_t_auth_encmbr__x();
            extObj.ExternalId = this.externalId;
            extObj.idn_auth__c = this.idnAuth;
            if (String.isNotBlank(this.idnEncmbrAuth)) {
                extObj.idn_encmbr_auth__c = Decimal.valueOf(this.idnEncmbrAuth).longValue();
            }
            extObj.cde_level_care__c = this.cdeLevelCare;
            extObj.cde_status_encmbr__c = this.cdeStatusEncmbr;
            extObj.cde_type_unit_care__c = this.cdeTypeUnitCare;
            if (String.isNotBlank(this.cntHourCare)) {
                extObj.cnt_hour_care__c = Decimal.valueOf(this.cntHourCare);
            }
            if (String.isNotBlank(this.dteCare)) {
                extObj.dte_care__c = Date.valueOf(this.dteCare.substringBefore(' ').substringBefore('T'));
            }
            extObj.ind_0_36_months__c = this.ind036Months;
            return extObj;
        }
    }
}