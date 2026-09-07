public with sharing class AuthorizationStatusController implements IRequest {
    
    @TestVisible private static List <batchsit_t_auth_status__x> mockedRequests = new List <batchsit_t_auth_status__x>();
    
    public String jsonParam;
    private static Map<String, Object> requestObj;
    
    /**
     * @description Process request method for generic utilities pattern
     * @param methodName The method to execute
     * @param jsonParam JSON string containing parameters
     * @return Object Response from the method
     */
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true, '', new Map<String, Object>());
        this.jsonParam = jsonParam;
        
        if (jsonParam != null) {
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        }
        
        if (methodName == 'checkOwnerCountyMatch') {
            response = checkOwnerCountyMatch(getMapValue('recordId'), getMapValue('fieldName'));
        } else if (methodName == 'doGetInitData') {
            response = doGetInitData();
        } else if (methodName == 'upsertAuthStatus') {
            AuthStatusWrapper wrapper = convertToAuthStatusWrapper(requestObj.get('authStatus'));
            batchsit_t_auth_status__x authStatus = wrapper.toExternalObject();
            response = upsertAuthStatus(
                authStatus,
                (Boolean)requestObj.get('isNew'),
                (Boolean)requestObj.get('isAuthIdChange'),
                getMapValue('authorizationId'),
                (Boolean)requestObj.get('isBatchInsert')
            );
        } else if (methodName == 'updateAuthStatus') {
            AuthStatusWrapper wrapper = convertToAuthStatusWrapper(requestObj.get('authStatus'));
            batchsit_t_auth_status__x authStatus = wrapper.toExternalObject();
            response = updateAuthStatus(
                authStatus,
                (Boolean)requestObj.get('isNew'),
                (Boolean)requestObj.get('isAuthIdChange'),
                getMapValue('authorizationId')
            );
        } else if (methodName == 'authEncumbDelete') {
            response = authEncumbDeleteResponse(getMapValue('recordId'));
        } else if (methodName == 'authorizationCopayDelete') {
            response = authorizationCopayDeleteResponse(getMapValue('recordId'));
        } else if (methodName == 'getAuthWeight') {
            response = getAuthWeightResponse(
                getMapValue('caseId'),
                (Boolean)requestObj.get('isFinish'),
                getMapValue('isQualityRating'),
                getMapValue('effectiveDateStr')
            );
        }
        
        return response;
    }
    /**
     * @description Helper method to convert Map<String, Object> to AuthStatusWrapper
     * Handles the conversion from untyped JSON deserialization to typed wrapper
     * @param authStatusObj The untyped object from JSON deserialization
     * @return AuthStatusWrapper populated with values from the map
     */
    public static AuthStatusWrapper convertToAuthStatusWrapper(Object authStatusObj) {
        AuthStatusWrapper wrapper = new AuthStatusWrapper();
        if (authStatusObj == null) {
            return wrapper;
        }
        
        Map<String, Object> authStatusMap = (Map<String, Object>)authStatusObj;
        
        wrapper.dteEndEffv = authStatusMap.get('dteEndEffv') != null ? String.valueOf(authStatusMap.get('dteEndEffv')) : null;
        wrapper.dteBeginEffv = authStatusMap.get('dteBeginEffv') != null ? String.valueOf(authStatusMap.get('dteBeginEffv')) : null;
        wrapper.cdeStatusAuth = authStatusMap.get('cdeStatusAuth') != null ? String.valueOf(authStatusMap.get('cdeStatusAuth')) : null;
        wrapper.cdeReasonChangeAuth = authStatusMap.get('cdeReasonChangeAuth') != null ? String.valueOf(authStatusMap.get('cdeReasonChangeAuth')) : null;
        wrapper.idnAuth = authStatusMap.get('idnAuth') != null ? String.valueOf(authStatusMap.get('idnAuth')) : null;
        wrapper.createdById = authStatusMap.get('createdById') != null ? String.valueOf(authStatusMap.get('createdById')) : null;
        wrapper.createdDate = authStatusMap.get('createdDate') != null ? String.valueOf(authStatusMap.get('createdDate')) : null;
        wrapper.lastModifiedById = authStatusMap.get('lastModifiedById') != null ? String.valueOf(authStatusMap.get('lastModifiedById')) : null;
        wrapper.lastModifiedDate = authStatusMap.get('lastModifiedDate') != null ? String.valueOf(authStatusMap.get('lastModifiedDate')) : null;
        wrapper.idnStatusAuth = authStatusMap.get('idnStatusAuth') != null ? String.valueOf(authStatusMap.get('idnStatusAuth')) : null;
        
        return wrapper;
    }
    /**
     * @description Helper method to get string value from request map
     * @param fieldName The field name to retrieve
     * @return String value from the map
     */
    private static String getMapValue(String fieldName) {
        return (String)requestObj.get(fieldName);
    }
    
    public static LightningServerResponse getExternalObjectDatafromAPI(String AuthId) {
        //changed method structure from Query to API service for CCCAP-9439
        AuthorizationFlowApxCtrl.requestParams req = new AuthorizationFlowApxCtrl.requestParams(AuthId, null, null, null);
        LightningServerResponse res = AuthorizationFlowApxCtrl.hitAuthStatusWebService(req);
        return res;
    }
    
    /**
     * @description Check owner county match - supports both direct call and processRequest
     */
    @AuraEnabled
    public static LightningServerResponse checkOwnerCountyMatch(String recordId, String fieldName) {
        Map<String, Object> objectData = new Map<String, Object>();
        LightningServerResponse responseAuthStatus = new LightningServerResponse(true, 'success', objectData);
        Boolean isSuccessful = true;
        String message = '';
        Boolean createProcess = true;
        try{
            T_AUTH__c auth = new T_AUTH__c();
            auth = [SELECT id, Name, isFinishedFlow__c, IDN_EXTNL__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id = :recordId];
            List<batchsit_t_auth_status__x> authStatusLst = [
                SELECT Id, idn_auth__c, cde_status_auth__c, dte_begin_effv__c, cde_reason_change_auth__c
                FROM batchsit_t_auth_status__x
                WHERE cde_status_auth__c = '4' AND idn_auth__c = :auth.IDN_EXTNL__c 
                ORDER BY createddate__c DESC LIMIT 1
            ];
            if (authStatusLst.size() > 0) {
                createProcess = false;
            }
            Boolean isAuthFlowCompleted = false;
            if (auth != null) {
                isAuthFlowCompleted = auth.isFinishedFlow__c;
            }
            responseAuthStatus = CHATSAuraUtility.checkOwnerCountyMatch(recordId, fieldName);
            isSuccessful = responseAuthStatus.isSuccessful;
            objectData = responseAuthStatus.objectData;
            objectData.put('createProcess', createProcess);
            objectData.put('isAuthFlowCompleted', isAuthFlowCompleted);
        }catch(Exception e) {
            isSuccessful = false;
            objectData = new Map<String, Object>();
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    /**
     * @description Fetch logged in user ID - legacy AuraEnabled method
     */
    @AuraEnabled
    public static Id fetchLoggedInUserId() {
        return CHATSAuraUtility.fetchLoggedInUserId();
    }

    @AuraEnabled
    public static LightningServerResponse doGetInitData() {
        Map<String, Object> objectData = new Map<String, Object>();
        String message;
        // Getting Status Change Reason Options
        List<PicklistOption> changeReasonOptions = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult = Field_Utility__c.R00687__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            changeReasonOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
        }
        if (!changeReasonOptions.isEmpty()) {
            objectData.put('changeReasonOptions', changeReasonOptions);
            message = '';
        }
        // Getting Authorization Status Options
        List<PicklistOption> authStatusOptions = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult1 = Field_Utility__c.R00686__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
        for (Schema.PicklistEntry f : ple1) {
            authStatusOptions.add(new PicklistOption(f.getLabel(), f.getValue()));
        }
        if (!authStatusOptions.isEmpty()) {
            objectData.put('authStatusOptions', authStatusOptions);
            message = '';
        }
        return new LightningServerResponse(true, message, objectData);
    }
    
    public static LightningServerResponse checkAuthStatusValidation(batchsit_t_auth_status__x authStatus, Boolean isNew, String authId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        try {
            if (authStatus != null) {
                if (authStatus.cde_status_auth__c == '2' || authStatus.cde_status_auth__c == '4') {
                    if (authStatus.cde_status_auth__c == '4') {
                        if (authStatus.dte_begin_effv__c <= System.today()) {
                            objectData.put('EffectiveBeginInvalid', true);
                            isSuccessful = false;
                        } else if (authStatus.dte_begin_effv__c < System.today() + 16) {
                            if (!isNew) {
                                if (authStatus.cde_reason_change_auth__c != '10') {
                                    objectData.put('InvalidChangeReason', true);
                                    isSuccessful = false;
                                }
                            }
                        }
                    }
                    List<AuthStatusPckt> authStatusList = new List<AuthStatusPckt>();
                    LightningServerResponse res = getExternalObjectDatafromAPI(authId);
                    if (res.isSuccessful) {
                        authStatusList = (List<AuthStatusPckt>)res.objectData.get('authstatuses');
                    } else {
                        return res;
                    }
                    
                    if (authStatusList != null && authStatusList.size() > 0) {
                        for (AuthStatusPckt prevAuthStatus : authStatusList) {
                            if (prevAuthStatus.cdeStatusAuth == '2' && authStatus.cde_status_auth__c == '2') {
                                objectData.put('Authorized', true);
                                isSuccessful = false;
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            isSuccessful = false;
            String message = ex.getMessage();
            String onlyError = message.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Class__c' => 'AuthorizationStatusController', 'Method__c' => 'checkAuthStatusValidation'});
        }
        return new LightningServerResponse(isSuccessful, 'Validation check', objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse upsertAuthStatus(batchsit_t_auth_status__x authStatus, Boolean isNew, Boolean isAuthIdChange, String authorizationId, Boolean isBatchInsert) {
        Map<String, Object> objectData = new Map<String, Object>();
        Map<String, Object> objectData1 = new Map<String, Object>();
        Map<String, Object> methodReqInfo = new Map<String, Object>();
        methodReqInfo.put('Class__c', 'AuthorizationStatusController');
        methodReqInfo.put('Method__c', 'upsertAuthStatus');
        List<T_AUTH__c> authNameList = new List<T_AUTH__c>();
        Boolean isSuccessful = true;
        String message1 = '';
        String authId = '';
        HttpRequest request;
        HttpResponse response;
        Boolean isAuthUpdate = false;
        LightningServerResponse responseAuthStatus = new LightningServerResponse(true, 'success', objectData);
        T_AUTH__c auth = new T_AUTH__c();
        if (authStatus != null) {
            if (authStatus.idn_auth__c != null) {
                if (isAuthIdChange) {
                    auth = [SELECT id, Name, isFinishedFlow__c, IDN_EXTNL__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE Id = :authStatus.idn_auth__c];
                    authId = auth.IDN_EXTNL__c;
                    authNameList.add(auth);
                } else {
                    auth = [SELECT id, Name, isFinishedFlow__c, IDN_EXTNL__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE IDN_EXTNL__c = :authStatus.idn_auth__c];
                    authId = authStatus.idn_auth__c;
                    authNameList.add(auth);
                }
            }
            String isAuthFirstTermination = 'false';
            if (authStatus.cde_status_auth__c == '4') {
                isAuthFirstTermination = 'true';
            }
            responseAuthStatus = checkAuthStatusValidation(authStatus, isNew, authId);
            isSuccessful = responseAuthStatus.isSuccessful;
            objectData1 = responseAuthStatus.objectData;
            if (isBatchInsert) {
                isSuccessful = true;
            } else {
                responseAuthStatus = checkAuthStatusValidation(authStatus, isNew, authId);
                isSuccessful = responseAuthStatus.isSuccessful;
                objectData1 = responseAuthStatus.objectData;
            }
            String jsonStr;
            if (isSuccessful) {
                try {
                    Http http = new Http();
                    request = new HttpRequest();
                    request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                    request.setMethod('POST');
                    
                    jsonStr = '{"cde_Status_Auth":"' + authStatus.cde_status_auth__c + '","dte_Begin_Effv":"' + authStatus.dte_begin_effv__c;
                    if (authStatus.cde_reason_change_auth__c != null) {
                        jsonStr = jsonStr + '","cde_Reason_Change_Auth":"' + authStatus.cde_reason_change_auth__c;
                    }
                    if (authStatus.dte_end_effv__c != null) {
                        jsonStr = jsonStr + '","dte_End_Effv":"' + authStatus.dte_end_effv__c;
                    }
                    jsonStr = jsonStr + '","isBatchInsert":"' + isBatchInsert;
                    request.setEndpoint(System.Label.AuthStatusCreate);
                    jsonStr = jsonStr + '","idn_status_auth":"' + authStatus.idn_status_auth__c;
                    if (isAuthFirstTermination == 'true') {
                        jsonStr = jsonStr + '","isAuthFirstTermination":"' + isAuthFirstTermination;
                    }
                    jsonStr = jsonStr + '","idn_Auth":"' + authId + '","createdbyid":"' + authStatus.createdbyid__c + '","createddate":"' + authStatus.createddate__c + '","lastmodifiedbyid":"' + authStatus.lastmodifiedbyid__c + '","lastmodifieddate":"' + authStatus.lastmodifieddate__c + '"}';
                    request.setBody(jsonStr);
                    Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
                    request.setTimeout(timeOutVal);
                    response = http.send(request);
                    // Parse the JSON response
                    if (response.getStatusCode() != 200) {
                        objectData1.put('xLog', getXLog('upsertAuthStatus', null, 'Web Service', jsonStr, response.getBody(), 'Failure'));
                        ExceptionLoggingServices.captureExceptionLog(response, request, methodReqInfo);
                    } else {
                        if (!isBatchInsert) {
                            if (auth != null) {
                                if (auth.isFinishedFlow__c && authStatus.cde_status_auth__c == '4') {
                                    insertATSRecords(authNameList);
                                }
                            }
                        }
                        JSONParser parser = JSON.createParser(response.getBody());
                        while (parser.nextToken() != null) {
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'success')) {
                                parser.nextToken();
                                if (parser.getText() == 'Success') {
                                    if (authStatus.cde_status_auth__c == '4') {
                                        if (!isNew) {
                                            isAuthUpdate = true;
                                        }
                                    }
                                }
                                if (parser.getText() == 'Unsucessful') {
                                    objectData1.put('HerokuValidFail', true);
                                    isSuccessful = false;
                                }
                            }
                            if (parser.getText() == 'errorMessage') {
                                parser.nextToken();
                                message1 = parser.getText();
                            }
                        }
                        // Updating Authorization record
                        if (isAuthUpdate) {
                            auth = [SELECT id, Name, IDN_EXTNL__c, DTE_BEGIN_EFFV_AUTH__c, IDN_SLOT_CONTRACT__c, DTE_END_EFFV_AUTH__c, IDN_CASE__c, CDE_CHILD_ENROLLED_IN_UPK__c FROM T_AUTH__c WHERE Id = :authorizationId];
                            auth.DTE_END_EFFV_AUTH__c = authStatus.dte_begin_effv__c.addDays(-1);
                            List<T_AUTH__c> authUpdateList = new List<T_AUTH__c>();
                            authUpdateList.add(auth);
                            GenericDMLHandler.updateRecords(authUpdateList, new Map<String, Object>{'Method__c' => 'upsertAuthStatus', 'Class__c' => 'AuthorizationStatusController'}, new List<String>{'DTE_END_EFFV_AUTH__c', 'CDE_CHILD_ENROLLED_IN_UPK__c'});
                            Exception_Log__c xLog = new Exception_Log__c();
                            xLog.Class__c = 'AuthorizationStatusController';
                            xLog.Method__c = 'upsertAuthStatus';
                            xLog.Exception_Message__c = 'Authorization updated with end date on status creation ' + auth.Id + ' end date --- ' + auth.DTE_END_EFFV_AUTH__c;
                            xLog.Exception_Type__c = 'Success';
                            GenericDMLHandler.insertRecords(new List<SObject>{xLog}, false, new Map<String, Object>{'Method__c' => 'upsertAuthStatus', 'Class__c' => 'AuthorizationStatusController'}, new List<String>{'Class__c','Method__c','Exception_Message__c','Exception_Type__c'});
                        }
                        if (String.isNotBlank(message1) && message1 != 'null') {
                            objectData1.put('xLog', getXLog('upsertAuthStatus', message1, 'Web Service Validation Error', jsonStr, response.getBody(), 'Failure'));
                        } else {
                            objectData1.put('xLog', getXLog('upsertAuthStatus', null, 'Web Service', jsonStr, response.getBody(), 'Success'));
                        }
                    }
                } catch (Exception ex) {
                    isSuccessful = false;
                    String message = ex.getMessage();
                    String onlyError = message.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
                    if (String.isNotEmpty(onlyError)) {
                        message1 = onlyError;
                    }
                    objectData1.put('xLog', getXLog('upsertAuthStatus', ex.getMessage(), ex.getTypeName(), jsonStr, null, 'Failure'));
                    ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String, Object>{'Class__c' => 'AuthorizationStatusController', 'Method__c' => 'upsertAuthStatus'});
                }
            }
        }
        ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String, Object>{'Class__c' => 'AuthorizationStatusController isSuccessful', 'Method__c' => 'upsertAuthStatus ' + isSuccessful});
        return new LightningServerResponse(isSuccessful, message1, objectData1);
    }
    
    @AuraEnabled
    public static LightningServerResponse updateAuthStatus(batchsit_t_auth_status__x authStatus, Boolean isNew, Boolean isAuthIdChange, String authorizationId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Map<String, Object> objectData1 = new Map<String, Object>();
        Map<String, Object> methodReqInfo = new Map<String, Object>();
        methodReqInfo.put('Class__c', 'AuthorizationStatusController');
        methodReqInfo.put('Method__c', 'updateAuthStatus');
        List<T_AUTH__c> authNameList = new List<T_AUTH__c>();
        Boolean isSuccessful = true;
        String message1 = '';
        String authId = '';
        HttpRequest request;
        HttpResponse response;
        Boolean isAuthUpdate = false;
        LightningServerResponse responseAuthStatus = new LightningServerResponse(true, 'success', objectData);
        T_AUTH__c auth = new T_AUTH__c();
        if (authStatus != null) {
            if (authStatus.idn_auth__c != null) {
                if (isAuthIdChange) {
                    auth = [SELECT id, Name, isFinishedFlow__c, IDN_EXTNL__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE Id = :authStatus.idn_auth__c];
                    authId = auth.IDN_EXTNL__c;
                    authNameList.add(auth);
                } else {
                    auth = [SELECT id, Name, isFinishedFlow__c, IDN_EXTNL__c, Number_of_Drop_in_Days__c FROM T_AUTH__c WHERE IDN_EXTNL__c = :authStatus.idn_auth__c];
                    authId = authStatus.idn_auth__c;
                    authNameList.add(auth);
                }
            }
            responseAuthStatus = checkAuthStatusValidation(authStatus, isNew, authId);
            isSuccessful = responseAuthStatus.isSuccessful;
            objectData1 = responseAuthStatus.objectData;
            
            String jsonStr;
            if (isSuccessful) {
                T_AUTH__c authRec = [SELECT id, Name, isFinishedFlow__c, IDN_EXTNL__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id = :authorizationId];
                List<batchsit_t_auth_status__x> authStatusLst = [
                    SELECT Id, idn_auth__c, idn_status_auth__c, cde_status_auth__c, dte_begin_effv__c, cde_reason_change_auth__c, lastmodifiedbyid__c, lastmodifieddate__c
                    FROM batchsit_t_auth_status__x
                    WHERE cde_status_auth__c = '4' AND idn_auth__c = :authRec.IDN_EXTNL__c LIMIT 1
                ];
                if (authStatusLst.size() > 0) {
                    try {
                        Http http = new Http();
                        request = new HttpRequest();
                        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                        request.setMethod('POST');
                        request.setEndpoint(System.Label.AuthStatusUpdate);
                        
                        jsonStr = '{"dte_Begin_Effv":"' + authStatus.dte_begin_effv__c;
                        if (authStatus.cde_reason_change_auth__c == null) {
                            jsonStr = jsonStr + '","cde_Reason_Change_Auth":"' + ' ';
                        } else {
                            jsonStr = jsonStr + '","cde_Reason_Change_Auth":"' + authStatus.cde_reason_change_auth__c;
                        }
                        jsonStr = jsonStr + '","idn_Auth":"' + authStatus.idn_auth__c + '","lastmodifiedbyid":"' + authStatus.lastmodifiedbyid__c + '","lastmodifieddate":"' + authStatus.lastmodifieddate__c + '","cde_Status_Auth":"' + authStatus.cde_status_auth__c + '","idn_status_auth":"' + authStatusLst[0].idn_status_auth__c;
                        jsonStr = jsonStr + '","isBatchInsert":"false"}';
                        request.setBody(jsonStr);
                        
                        if (!Test.isRunningTest()) {
                            Integer timeOutVal = Integer.valueOf(System.Label.WebServiceTimeOut);
                            request.setTimeout(timeOutVal);
                            response = http.send(request);
                            
                            if (response.getStatusCode() != 200) {
                                objectData1.put('xLog', getXLog('updateAuthStatus', null, 'Web Service', jsonStr, response.getBody(), 'Failure'));
                            } else {
                                if (auth != null) {
                                    if (auth.isFinishedFlow__c && authStatus.cde_status_auth__c == '4') {
                                        insertATSRecords(authNameList);
                                    }
                                }
                                if (authStatus.cde_status_auth__c == '4') {
                                    if (!isNew) {
                                        isAuthUpdate = true;
                                    }
                                }
                                
                                // Updating Authorization record
                                if (isAuthUpdate) {
                                    auth = [SELECT id, Name, IDN_EXTNL__c, DTE_BEGIN_EFFV_AUTH__c, IDN_SLOT_CONTRACT__c, DTE_END_EFFV_AUTH__c, IDN_CASE__c FROM T_AUTH__c WHERE Id = :authorizationId];
                                    auth.DTE_END_EFFV_AUTH__c = authStatus.dte_begin_effv__c.addDays(-1);
                                    List<T_AUTH__c> authUpdateList = new List<T_AUTH__c>();
                                    authUpdateList.add(auth);
                                    GenericDMLHandler.updateRecords(authUpdateList, new Map<String, Object>{'Method__c' => 'updateAuthStatus', 'Class__c' => 'AuthorizationStatusController'});
                                }
                            }
                        }
                        
                    } catch (Exception ex) {
                        isSuccessful = false;
                        String message = ex.getMessage();
                        String onlyError = message.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
                        if (String.isNotEmpty(onlyError)) {
                            message1 = onlyError;
                        }
                        objectData1.put('xLog', getXLog('updateAuthStatus', ex.getMessage(), ex.getTypeName(), jsonStr, null, 'Failure'));
                        ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String, Object>{'Class__c' => 'AuthorizationStatusController', 'Method__c' => 'updateAuthStatus'});
                    }
                }
            }
        }
        return new LightningServerResponse(isSuccessful, message1, objectData1);
    }
    
    /**
     * @description helper method that handles the actual processing of slot contract terminations
     * @param authToSlotMap Map of Authorization Id to Slot Contract Id
     * @return LightningServerResponse with success/failure status, made bulkified for CCCAP-13427
     */
    @AuraEnabled
    public static LightningServerResponse terminateSCAssociationRecords(List<T_AUTH__c> newRecords, Map<Id, T_AUTH__c> oldMap) {
                // Build map of auth IDs to slot contract IDs for records where DTE_END_EFFV_AUTH__c has changed
        List<T_SLOT_CONTRACT__c> scRecToCreate = new List<T_SLOT_CONTRACT__c>();
        List<T_SLOT_CONTRACT__c> scRecToUpdate = new List<T_SLOT_CONTRACT__c>();
        Map<Id, String> authToSlotMap = new Map<Id, String>();
        try {
            for (T_AUTH__c newRec : newRecords) {
                if (oldMap != null && oldMap.containsKey(newRec.Id) &&
                    newRec.DTE_END_EFFV_AUTH__c != oldMap.get(newRec.Id).DTE_END_EFFV_AUTH__c) {
                    authToSlotMap.put(newRec.Id, newRec.IDN_SLOT_CONTRACT__c);
                }
            }
            
            // Exit early if map is empty
            if (authToSlotMap == null || authToSlotMap.isEmpty()) {
                return new LightningServerResponse(true, 'No records to process', null);
            }
            
            // Query all authorization records at once
            Map<Id, T_AUTH__c> authRecsMap = new Map<Id, T_AUTH__c>([
                SELECT Id, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, DTE_BEGIN_SLOT__c, IDN_SLOT_CONTRACT__c
                FROM T_AUTH__c
                WHERE Id IN :authToSlotMap.keySet()
            ]);
            
            // Get all slot contract IDs
            Set<String> slotContractIds = new Set<String>(authToSlotMap.values());
            
            // Query all slot contract records at once
            Map<Id, T_SLOT_CONTRACT__c> slotContractMap = new Map<Id, T_SLOT_CONTRACT__c>();
            for (T_SLOT_CONTRACT__c rec : [
                SELECT Id, IDN_ADDENDUM__c, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IND_AVAILABLE__c,
                       IDN_AUTH__c, IND_OCCUPIED__c, SLOT_CONTRACT_DESCRIPTION__c, IDN_PROVIDER__c,
                       CDE_COUNTY__c, CNT_DAYS_OF_MONTH__c, CNT_DAYS_OF_WEEK__c, CDE_CARE_UNIT__c,
                       CDE_CARE_LEVEL__c, CDE_RATE_TYPE__c, CDE_PRG_TYPE__c, IND_FUTURE_VACANT__c
                FROM T_SLOT_CONTRACT__c
                WHERE Id IN :slotContractIds
            ]) {
                slotContractMap.put(rec.Id, rec);
            }
            
            // Process each record
            for (Id authRecId : authToSlotMap.keySet()) {
                String slotContractId = authToSlotMap.get(authRecId);
                T_AUTH__c authRec = authRecsMap.get(authRecId);
                T_SLOT_CONTRACT__c scAssRecOldValueRec = slotContractMap.get(slotContractId);
                
                // Skip if either record is not found
                if (authRec == null || scAssRecOldValueRec == null) {
                    continue;
                }
                
                //Scenario 12a && 12b(when we are terminating the auth record)
                if (scAssRecOldValueRec.DTE_END_SLOT__c > authRec.DTE_END_EFFV_AUTH__c &&
                    authRec.DTE_END_EFFV_AUTH__c <= scAssRecOldValueRec.DTE_BEGIN_SLOT__c) {
                    scAssRecOldValueRec.IDN_AUTH__c = null;
                    scRecToUpdate.add(scAssRecOldValueRec);
                } else if (scAssRecOldValueRec.DTE_END_SLOT__c > authRec.DTE_END_EFFV_AUTH__c &&
                           authRec.DTE_END_EFFV_AUTH__c > scAssRecOldValueRec.DTE_BEGIN_SLOT__c) {
                    T_SLOT_CONTRACT__c newScRecTwo = scAssRecOldValueRec.clone();
                    newScRecTwo.DTE_BEGIN_SLOT__c = authRec.DTE_END_EFFV_AUTH__c.addDays(1);
                    newScRecTwo.DTE_END_SLOT__c = scAssRecOldValueRec.DTE_END_SLOT__c;
                    newScRecTwo.IDN_AUTH__c = null;
                    scRecToCreate.add(newScRecTwo);
                    scAssRecOldValueRec.DTE_END_SLOT__c = authRec.DTE_END_EFFV_AUTH__c;
                    scRecToUpdate.add(scAssRecOldValueRec);
                }
            }
            
            // Perform DML operations in bulk
            if (!scRecToCreate.isEmpty()) {
                GenericDMLHandler.insertRecords(
                    scRecToCreate,
                    new Map<String,Object>{'Method__c'=>'terminateSCAssociationRecords','Class__c'=>'AuthorizationStatusController'},
                    new List<String>{'DTE_BEGIN_SLOT__c','DTE_END_SLOT__c','IDN_AUTH__c','IDN_ADDENDUM__c','IND_AVAILABLE__c','IND_OCCUPIED__c','SLOT_CONTRACT_DESCRIPTION__c','IDN_PROVIDER__c','CDE_COUNTY__c','CNT_DAYS_OF_MONTH__c','CNT_DAYS_OF_WEEK__c','CDE_CARE_UNIT__c','CDE_CARE_LEVEL__c','CDE_RATE_TYPE__c','CDE_PRG_TYPE__c','IND_FUTURE_VACANT__c'}
                );
            }
            if (!scRecToUpdate.isEmpty()) {
                GenericDMLHandler.updateRecords(
                    scRecToUpdate,
                    new Map<String,Object>{'Method__c'=>'terminateSCAssociationRecords','Class__c'=>'AuthorizationStatusController'},
                    new List<String>{'IDN_AUTH__c','DTE_END_SLOT__c'}
                );
            }
            return new LightningServerResponse(true, 'Success', null);
        } catch (Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Class__c' => 'AuthorizationFlowApxCtrl', 'Method__c' => 'createSCAssociationRecord'});
            return new LightningServerResponse(false, ex.getMessage(), null);
        }
    }
    
    /**
     * @description Delete auth encumbrance - legacy AuraEnabled method
     */
    @AuraEnabled
    public static void authEncumbDelete(String recordId) {
        T_AUTH__c auth = new T_AUTH__c();
        auth = [SELECT id, Name, isFinishedFlow__c, LastModifiedById, IDN_EXTNL__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id = :recordId];
        HerokuService.authEncumbranceDelete(auth.IDN_EXTNL__c, auth.DTE_END_EFFV_AUTH__c);
    }
    
    /**
     * @description Delete auth encumbrance - returns LightningServerResponse for processRequest
     */
    public static LightningServerResponse authEncumbDeleteResponse(String recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            T_AUTH__c auth = [SELECT id, Name, isFinishedFlow__c, LastModifiedById, IDN_EXTNL__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id = :recordId];
            HerokuService.authEncumbranceDelete(auth.IDN_EXTNL__c, auth.DTE_END_EFFV_AUTH__c);
            objectData.put('success', true);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    /**
     * @description Delete authorization copay - legacy AuraEnabled method
     */
    @AuraEnabled
    public static void authorizationCopayDelete(String recordId) {
        T_AUTH__c auth = new T_AUTH__c();
        auth = [SELECT id, Name, isFinishedFlow__c, LastModifiedById, IDN_EXTNL__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id = :recordId];
        HerokuService.authCopayDelete(auth.IDN_EXTNL__c, auth.DTE_END_EFFV_AUTH__c, auth.LastModifiedById);
    }
    
    /**
     * @description Delete authorization copay - returns LightningServerResponse for processRequest
     */
    public static LightningServerResponse authorizationCopayDeleteResponse(String recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            T_AUTH__c auth = [SELECT id, Name, isFinishedFlow__c, LastModifiedById, IDN_EXTNL__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c WHERE Id = :recordId];
            HerokuService.authCopayDelete(auth.IDN_EXTNL__c, auth.DTE_END_EFFV_AUTH__c, auth.LastModifiedById);
            objectData.put('success', true);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static void updateCopayRecords(Decimal aggregateWeight, String caseId, Boolean isFinish, String isQualityRating) {
        Date todayDate = System.today();
        String recommendedCopayUnit;
        if (aggregateWeight >= 13) {
            recommendedCopayUnit = 'FT';
        } else if (aggregateWeight >= 0 && aggregateWeight < 13) {
            recommendedCopayUnit = 'PT';
        }
        List<batchsit_t_sbsd_case_copay__x> caseCopayRecord = [
            SELECT Id, idn_case__c, idn_sbsd_case_copay__c, amt_copay_case_assesd__c,
                   amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c,
                   cde_rec_copay__c, dte_begin_effv__c, dte_end_effv__c, nbr_seq_hist__c, amt_copay_case_ft_qlty__c,
                   amt_copay_case_pt_qlty__c, ind_qlty__c
            FROM batchsit_t_sbsd_case_copay__x
            WHERE idn_case__c = :caseId AND ((dte_begin_effv__c <= :todayDate AND (dte_end_effv__c > :todayDate OR dte_end_effv__c = :null)) OR
                                             (dte_begin_effv__c > :todayDate AND (dte_end_effv__c > :todayDate OR dte_end_effv__c = :null)))
        ];
        for (batchsit_t_sbsd_case_copay__x caseCopayRec : caseCopayRecord) {
            if (isFinish) {
                caseCopayRec.ind_qlty__c = isQualityRating;
            }
            caseCopayRec.cde_rec_copay__c = recommendedCopayUnit;
            if (!Test.isRunningTest()) {
                HerokuService.caseCopyUpdate(String.valueOf(caseCopayRec.amt_copay_case_assesd__c), String.valueOf(caseCopayRec.amt_copay_case_ft__c),
                                             String.valueOf(caseCopayRec.amt_copay_case_pt__c), String.valueOf(caseCopayRec.cde_reason_ovrd__c),
                                             String.valueOf(caseCopayRec.cde_rec_copay__c),
                                             String.valueOf(caseCopayRec.dte_begin_effv__c),
                                             '',
                                             String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c),
                                             String.valueOf(caseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(caseCopayRec.amt_copay_case_pt_qlty__c),
                                             String.valueOf(caseCopayRec.ind_qlty__c), String.valueOf(caseCopayRec.idn_sbsd_case_copay__c));
            }
        }
    }
    
    /**
     * @description Get Auth Weight - legacy AuraEnabled method
     */
    @AuraEnabled
    public static String getAuthWeight(String caseId, Boolean isFinish, String isQualityRating, String effectiveDateStr) {
        Decimal aggregateWeight = 0;
        Boolean isAuth = false;
        String caseIdExternal;
        Decimal maxWt = 0;
        Decimal aggregateWeight1 = 0;
        Map<Id, Decimal> authChildWeightMap = new Map<Id, Decimal>();
        String recommendedCopayUnit = 'NA';
        List<String> dateParts = new List<String>();
        Date careParentFeeEffectiveDate;
        Date lastDayofcareParentFeeBeginDate;
        if (effectiveDateStr != null) {
            dateParts = effectiveDateStr.split('-');
            careParentFeeEffectiveDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
            lastDayofcareParentFeeBeginDate = careParentFeeEffectiveDate.addMonths(1).toStartOfMonth().addDays(-1);
        }

        for (T_AUTH__c authObj : [SELECT id, Name, IDN_EXTNL__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c, IDN_CASE__c, IDN_CASE__r.IDN_EXTNL__c, IDN_CLIENT__c FROM T_AUTH__c WHERE IDN_CASE__c = :caseId AND (DTE_BEGIN_EFFV_AUTH__c <= :lastDayofcareParentFeeBeginDate AND DTE_END_EFFV_AUTH__c >= :careParentFeeEffectiveDate)]) {
            aggregateWeight1 = calculateAuthWeight(authObj, careParentFeeEffectiveDate);
            if (authChildWeightMap.containsKey(authObj.IDN_CLIENT__c)) {
                Decimal aggregateWeight2 = authChildWeightMap.get(authObj.IDN_CLIENT__c);
                aggregateWeight2 += aggregateWeight1;
                authChildWeightMap.put(authObj.IDN_CLIENT__c, aggregateWeight2);
            } else {
                Decimal aggregateWeight3 = 0;
                aggregateWeight3 += aggregateWeight1;
                authChildWeightMap.put(authObj.IDN_CLIENT__c, aggregateWeight3);
            }
            isAuth = true;
            caseIdExternal = authObj.IDN_CASE__r.IDN_EXTNL__c;
        }
        if (isAuth) {
            for (Decimal wt : authChildWeightMap.values()) {
                if (wt > maxWt) {
                    maxWt = wt;
                }
            }
            aggregateWeight = maxWt;
            if (aggregateWeight >= 13) {
                recommendedCopayUnit = 'FT';
            } else if (aggregateWeight > 0 && aggregateWeight < 13) {
                recommendedCopayUnit = 'PT';
            }
        }
        return recommendedCopayUnit;
    }
    
    /**
     * @description Get Auth Weight - returns LightningServerResponse for processRequest
     */
    public static LightningServerResponse getAuthWeightResponse(String caseId, Boolean isFinish, String isQualityRating, String effectiveDateStr) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            String result = getAuthWeight(caseId, isFinish, isQualityRating, effectiveDateStr);
            objectData.put('recommendedCopayUnit', result);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static Decimal calculateAuthWeight(T_AUTH__c auth, Date scheduleBeginDate) {
        Date scheduleEndDate;
        Decimal weight = 0;
        Date todayDate = System.today();
        List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2 = new Map<String, batchsit_t_auth_encmbr__x>();
        if (auth != null && auth.Id != null) {
            if (scheduleBeginDate < auth.DTE_BEGIN_EFFV_AUTH__c) {
                scheduleBeginDate = auth.DTE_BEGIN_EFFV_AUTH__c;
            }
            Date lastDayofBeginDate = scheduleBeginDate.addMonths(1).toStartOfMonth().addDays(-1);
            if (auth.DTE_END_EFFV_AUTH__c != null) {
                if (lastDayofBeginDate < auth.DTE_END_EFFV_AUTH__c) {
                    scheduleEndDate = lastDayofBeginDate;
                } else {
                    scheduleEndDate = auth.DTE_END_EFFV_AUTH__c;
                }
            } else {
                scheduleEndDate = lastDayofBeginDate;
            }
            if (!Test.isRunningTest()) {
                fetchedEncumberence = HerokuService.authEncumbrancefetch(auth.Id);
            } else {
                batchsit_t_auth_encmbr__x en = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(2).toStartofMonth(), cnt_hour_care__c = 5);
                batchsit_t_auth_encmbr__x en1 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(2).toStartofMonth() + 1, cnt_hour_care__c = 10);
                batchsit_t_auth_encmbr__x en2 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(2).toStartofMonth() + 2, cnt_hour_care__c = 17);
                batchsit_t_auth_encmbr__x en3 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(2).toStartofMonth() + 4, cnt_hour_care__c = 0);
                batchsit_t_auth_encmbr__x en4 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(2).toStartofMonth() + 5, cnt_hour_care__c = 22);
                batchsit_t_auth_encmbr__x en9 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(2).toStartofMonth() + 1, cnt_hour_care__c = 22);
                batchsit_t_auth_encmbr__x en5 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(1).toStartofMonth() + 2, cnt_hour_care__c = 6);
                batchsit_t_auth_encmbr__x en6 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(1).toStartofMonth() + 3, cnt_hour_care__c = 22);
                batchsit_t_auth_encmbr__x en7 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(1).toStartofMonth() + 4, cnt_hour_care__c = 2);
                batchsit_t_auth_encmbr__x en8 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(1).toStartofMonth() + 5, cnt_hour_care__c = 12);
                batchsit_t_auth_encmbr__x en10 = new batchsit_t_auth_encmbr__x(dte_care__c = System.today().addMonths(1).toStartofMonth() + 6, cnt_hour_care__c = 0);
                fetchedEncumberence.add(en);
                fetchedEncumberence.add(en1);
                fetchedEncumberence.add(en2);
                fetchedEncumberence.add(en3);
                fetchedEncumberence.add(en4);
                fetchedEncumberence.add(en5);
                fetchedEncumberence.add(en6);
                fetchedEncumberence.add(en7);
                fetchedEncumberence.add(en8);
                fetchedEncumberence.add(en9);
                fetchedEncumberence.add(en10);
            }
            Date careDate;
            String monthStr;
            String dayStr;
            for (batchsit_t_auth_encmbr__x anAuthEncmbr1 : fetchedEncumberence) {
                careDate = anAuthEncmbr1.dte_care__c;
                monthStr = String.valueOf(careDate.month());
                dayStr = String.valueOf(careDate.day());
                if (careDate.month() < 10) {
                    monthStr = '0' + monthStr;
                }
                if (careDate.day() < 10) {
                    dayStr = '0' + dayStr;
                }
                careDateToAuthEncmbr2.put(careDate.year() + '-' + monthStr + '-' + dayStr, anAuthEncmbr1);
            }
            String startDateStr;
            while (scheduleBeginDate <= scheduleEndDate) {
                startDateStr = String.valueOf(scheduleBeginDate);
                if (!careDateToAuthEncmbr2.isEmpty() && careDateToAuthEncmbr2.size() > 0) {
                    batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                    if (anAuthEncmbr != null) {
                        if (anAuthEncmbr.cnt_hour_care__c == 0) {
                            weight += 0;
                        } else if (anAuthEncmbr.cnt_hour_care__c > 0 && anAuthEncmbr.cnt_hour_care__c <= 5) {
                            weight += 0.55;
                        } else if (anAuthEncmbr.cnt_hour_care__c > 5 && anAuthEncmbr.cnt_hour_care__c <= 12) {
                            weight += 1;
                        } else if (anAuthEncmbr.cnt_hour_care__c > 12 && anAuthEncmbr.cnt_hour_care__c <= 17) {
                            weight += 1.55;
                        } else if (anAuthEncmbr.cnt_hour_care__c > 17) {
                            weight += 2;
                        }
                    }
                }
                scheduleBeginDate = scheduleBeginDate.addDays(1);
            }
        }
        return weight;
    }
    
    public static void insertATSRecords(List<T_AUTH__c> authIdList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
        batchsit_t_pos_trans_queue_ats__x atsRecord2 = new batchsit_t_pos_trans_queue_ats__x();
        for (T_AUTH__c authObj : authIdList) {
            atsRecord = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord.CDE_STATUS_TRANS__c = '1';
            atsRecord.CDE_TYPE_TRANS__c = '6';
            atsRecord.auth_drop_in_days__c = authObj.Number_of_Drop_in_Days__c;
            if (authObj != null) {
                atsRecord.IDN_AUTH__c = authObj.Name;
            }
            atsRecord.DTE_CHANGE_LAST__c = System.today();
            lstATSRecords.add(atsRecord);
            atsRecord2 = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord2.CDE_STATUS_TRANS__c = '1';
            atsRecord2.CDE_TYPE_TRANS__c = '7';
            atsRecord2.auth_drop_in_days__c = authObj.Number_of_Drop_in_Days__c;
            if (authObj != null) {
                atsRecord2.IDN_AUTH__c = authObj.Name;
            }
            atsRecord2.DTE_CHANGE_LAST__c = System.today();
            lstATSRecords.add(atsRecord2);
        }
        ATSHandler.insertATSRecord(true, lstATSRecords);
    }
    
    // Below code to replace Auth Termination process builder Job and call below method from AuthorizationBatch Apex
    // Below code added as part of Jira ticket CHATS-6981
    public static void authTerminate(Set<Id> authId) {
        List<T_AUTH__c> updateAuthorization = new List<T_AUTH__c>();
        for (T_AUTH__c auth : [SELECT Id, CDE_CHILD_ENROLLED_IN_UPK__c, Authorization_Status__c FROM T_AUTH__c WHERE Id IN :authId]) {
            auth.Authorization_Status__c = '4';
            auth.CDE_CHILD_ENROLLED_IN_UPK__c = 'Not Applicable'; //CCCAP-15329
            updateAuthorization.add(auth);
        }
        if (updateAuthorization.size() > 0) {
            GenericDMLHandler.updateRecords(updateAuthorization, new Map<String, Object>{'Method__c' => 'authTerminate', 'Class__c' => 'AuthorizationStatusController'});
        }
    }
    /**
     * @description Wrapper class for Auth Status data transfer from LWC
     * Decouples LWC from external object structure
     */
    public class AuthStatusWrapper {
        @AuraEnabled public String dteEndEffv;
        @AuraEnabled public String dteBeginEffv;
        @AuraEnabled public String cdeStatusAuth;
        @AuraEnabled public String cdeReasonChangeAuth;
        @AuraEnabled public String idnAuth;
        @AuraEnabled public String createdById;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String lastModifiedById;
        @AuraEnabled public String lastModifiedDate;
        @AuraEnabled public String idnStatusAuth;

        public AuthStatusWrapper() {
            this.cdeStatusAuth = '4'; // Default to Terminated status
        }
        
        /**
         * @description Convert wrapper to external object
         * @return batchsit_t_auth_status__x External object populated with wrapper data
         */
        public batchsit_t_auth_status__x toExternalObject() {
            batchsit_t_auth_status__x extObj = new batchsit_t_auth_status__x();
            extObj.dte_end_effv__c = String.isNotBlank(this.dteEndEffv) ? Date.valueOf(this.dteEndEffv) : null;
            extObj.dte_begin_effv__c = String.isNotBlank(this.dteBeginEffv) ? Date.valueOf(this.dteBeginEffv) : null;
            extObj.cde_status_auth__c = this.cdeStatusAuth;
            extObj.cde_reason_change_auth__c = this.cdeReasonChangeAuth;
            extObj.idn_auth__c = this.idnAuth;
            extObj.createdbyid__c = this.createdById;
            extObj.createddate__c = String.isNotBlank(this.createdDate) ? Datetime.valueOf(this.createdDate.replace('T', ' ').replace('Z', '')) : null;
            extObj.lastmodifiedbyid__c = this.lastModifiedById;
            extObj.lastmodifieddate__c = String.isNotBlank(this.lastModifiedDate) ? Datetime.valueOf(this.lastModifiedDate.replace('T', ' ').replace('Z', '')) : null;
            if(this.idnStatusAuth!='' && this.idnStatusAuth!=null){
                extObj.idn_status_auth__c = decimal.valueOf(this.idnStatusAuth);
            }
            return extObj;
        }
    }
    
    public static Exception_Log__c getXLog(String methodName, String exceptionMessage, String exceptionType, String request, String response, String logType) {
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'AuthorizationStatusController';
        xLog.Method__c = methodName;
        xLog.Exception_Message__c = exceptionMessage;
        xLog.Exception_Type__c = exceptionType;
        xLog.Request__c = request;
        xLog.Response__c = response;
        xLog.Log_Type__c = logType;
        return xLog;
    }
}