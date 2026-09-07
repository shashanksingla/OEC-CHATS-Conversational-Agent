public with sharing class AuthorizationNotesController implements IRequest {
    
    public String jsonParam;
    private static Map<String, Object> requestObj;
    
    /**
     * @description Process request method for generic utilities pattern
     * Routes all LWC method calls through a single entry point
     * @param methodName The method to execute
     * @param jsonParam JSON string containing parameters
     * @return Object Response from the method (typically LightningServerResponse)
     */
    public Object processRequest(String methodName, String jsonParam) {
        Object response = new LightningServerResponse(true, '', new Map<String, Object>());
        this.jsonParam = jsonParam;
        
        if (jsonParam != null) {
            requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);
        }
        
        if (methodName == 'getSobjectName') {
            response = getSobjectName(getMapValueAsId('recordId'));
        } else if (methodName == 'getAuthRecord') {
            response = getAuthRecord(getMapValueAsId('recordId'));
        } else if (methodName == 'getAuthorizationNotesStatus') {
            response = getAuthorizationNotesStatusResponse(
                getMapValue('authId'),
                getMapValueAsBoolean('isNew'),
                getMapValueAsBoolean('isAuthIdChange')
            );
        } else if (methodName == 'CR213Corr') {
            response = CR213CorrResponse(getMapValue('authId'));
        }
        
        return response;
    }
    
    /**
     * @description Helper method to get string value from request map
     * @param fieldName The field name to retrieve
     * @return String value from the map
     */
    private static String getMapValue(String fieldName) {
        if (requestObj == null || !requestObj.containsKey(fieldName)) {
            return null;
        }
        Object val = requestObj.get(fieldName);
        return val != null ? String.valueOf(val) : null;
    }
    
    /**
     * @description Helper method to get Id value from request map
     * @param fieldName The field name to retrieve
     * @return Id value from the map
     */
    private static Id getMapValueAsId(String fieldName) {
        String val = getMapValue(fieldName);
        if (String.isBlank(val)) {
            return null;
        }
        try {
            return Id.valueOf(val);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * @description Helper method to get Boolean value from request map
     * @param fieldName The field name to retrieve
     * @return Boolean value from the map
     */
    private static Boolean getMapValueAsBoolean(String fieldName) {
        if (requestObj == null || !requestObj.containsKey(fieldName)) {
            return false;
        }
        Object val = requestObj.get(fieldName);
        if (val == null) {
            return false;
        }
        if (val instanceof Boolean) {
            return (Boolean)val;
        }
        return Boolean.valueOf(String.valueOf(val));
    }
    
    // ==================== LWC Compatible Methods (return LightningServerResponse) ====================
    
    /**
     * @description Get Authorization record by ID - NEW method for LWC
     * @param recordId The authorization record ID
     * @return LightningServerResponse containing auth record data
     */
    @AuraEnabled
    public static LightningServerResponse getAuthRecord(Id recordId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            if (recordId == null) {
                return new LightningServerResponse(false, 'Record ID is required', objectData);
            }
            
            T_AUTH__c auth = [
                SELECT Id, Name, IDN_EXTNL__c, isFinishedFlow__c 
                FROM T_AUTH__c 
                WHERE Id = :recordId 
                WITH SECURITY_ENFORCED 
                LIMIT 1
            ];
            
            objectData.put('Id', auth.Id);
            objectData.put('Name', auth.Name);
            objectData.put('IDN_EXTNL__c', auth.IDN_EXTNL__c);
            objectData.put('isFinishedFlow__c', auth.isFinishedFlow__c);
            
            return new LightningServerResponse(isSuccessful, message, objectData);
        } catch (QueryException qe) {
            isSuccessful = false;
            message = 'Authorization record not found';
            return new LightningServerResponse(isSuccessful, message, objectData);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            return new LightningServerResponse(isSuccessful, message, objectData);
        }
    }
    
    /**
     * @description Get Authorization Notes Status - returns LightningServerResponse for LWC
     * @param authId The authorization ID
     * @param isNew Whether this is a new record
     * @param isAuthIdChange Whether the auth ID has changed
     * @return LightningServerResponse containing status data
     */
    public static LightningServerResponse getAuthorizationNotesStatusResponse(String authId, Boolean isNew, Boolean isAuthIdChange) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            authNoteWrapper wrapper = getAuthorizationNotesStatus(authId, isNew, isAuthIdChange);
            objectData.put('isUpdate', wrapper.isUpdate);
            objectData.put('authNote', wrapper.authNote);
            objectData.put('loggedInUserId', wrapper.loggedInUserId);
            objectData.put('auth', wrapper.auth);
            objectData.put('authId', wrapper.authId);
            objectData.put('isAuthFlowCompleted', wrapper.isAuthFlowCompleted);
            return new LightningServerResponse(isSuccessful, message, objectData);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            return new LightningServerResponse(isSuccessful, message, objectData);
        }
    }
    
    /**
     * @description Generate CR213 Correspondence - returns LightningServerResponse for LWC
     * @param authId The authorization ID
     * @return LightningServerResponse with success/failure status
     */
    public static LightningServerResponse CR213CorrResponse(String authId) {
        Map<String, Object> objectData = new Map<String, Object>();
        Boolean isSuccessful = true;
        String message = '';
        try {
            CR213Corr(authId);
            objectData.put('success', true);
            return new LightningServerResponse(isSuccessful, message, objectData);
        } catch (Exception e) {
            isSuccessful = false;
            message = e.getMessage();
            return new LightningServerResponse(isSuccessful, message, objectData);
        }
    }
    
    // ==================== Legacy AuraEnabled Methods (for backward compatibility) ====================
   
    // Get Authorization status records
    @AuraEnabled
    public static authNoteWrapper getAuthorizationNotesStatus(String authId, Boolean isNew, Boolean isAuthIdChange){
        //Removed unused variable on 5/13/2018 BG  
        Map<Id,batchsit_t_auth_notes__x> authNoteMap = new Map<Id,batchsit_t_auth_notes__x>();
        //Removed unused variable on 5/13/2018 BG  
        T_AUTH__c auth = new T_AUTH__c();
        if(authId != null){
            if(isAuthIdChange){
                auth = [SELECT id,Name,IDN_EXTNL__c,isFinishedFlow__c FROM T_AUTH__c WHERE Id = :authId WITH SECURITY_ENFORCED];
                authId = auth.IDN_EXTNL__c;
            }else{
                if(isNew){
                    auth = [SELECT id,Name,IDN_EXTNL__c,isFinishedFlow__c FROM T_AUTH__c WHERE Id = :authId  WITH SECURITY_ENFORCED];
                authId = auth.IDN_EXTNL__c;
                }else{
                    auth = [SELECT id,Name,IDN_EXTNL__c,isFinishedFlow__c FROM T_AUTH__c WHERE IDN_EXTNL__c = :authId  WITH SECURITY_ENFORCED];
                    authId = auth.IDN_EXTNL__c;
                }
            }
        }
       Boolean isAuthFlowCompleted =false;
        if(auth != null && auth.isFinishedFlow__c){
            isAuthFlowCompleted = true;
        }
        Boolean isUpdate = true;
        for(batchsit_t_auth_status__x stat : [select id,dte_begin_effv__c,cde_status_auth__c,
                                              idn_auth__c from batchsit_t_auth_status__x where idn_auth__c =:authId WITH SECURITY_ENFORCED order by dte_begin_effv__c desc limit 1]){
                if(stat.dte_begin_effv__c <= System.today() && stat.cde_status_auth__c == '4'){
                    isUpdate = false;
                }else{
                    isUpdate = true;
                }
        }
        authNoteWrapper wrap = new authNoteWrapper(isUpdate, null,fetchLoggedInUserId(), auth , authId,isAuthFlowCompleted );
        return wrap; 
    }

    @AuraEnabled
    public static Id fetchLoggedInUserId(){
        return CHATSAuraUtility.fetchLoggedInUserId();
    }

    @AuraEnabled
    public static LightningServerResponse getSobjectName(Id recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        String sObjName = CHATSAuraUtility.getSobjectName(recordId);
        List<batchsit_t_auth_notes__x> authNote = new List<batchsit_t_auth_notes__x>();
        if(sObjName !='T_AUTH__c'){
            authNote =[select id,idn_notes_auth__c,txt_notes__c,lastmodifieddate__c,lastmodifiedbyid__c,idn_auth__c,idn_auth__r.Id from batchsit_t_auth_notes__x where id=:recordId];
            objectData.put('authNote', authNote);
        }
        objectData.put('sObjName', sObjName);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    //Correspondence CR213 generation Logic
    @AuraEnabled
    public static void CR213Corr (String authId) {
        String CR213RsnCode = Label.CR0010;
        integer countyCode;
        T_AUTH__c auth = new T_AUTH__c();
        List<T_DOC_RQ__c> corrReq = new List<T_DOC_RQ__c>();
        List<T_DOC_RQ__c> updAlreadyExistingAuthCorrespondence = new List<T_DOC_RQ__c>();
        Map<string,string> keyParams = new Map<string, string>();
        /*corrReq = [select id from T_DOC_RQ__c where IDN_AUTH__c =:authId and DTE_REQ__c =: system.today()];
        if(!corrReq.isEmpty()){
            for(T_DOC_RQ__c eachCorrFoundForAuth : corrReq){
                T_DOC_RQ__C updAuthCorrRecrds = new T_DOC_RQ__c();
                updAuthCorrRecrds.Id = eachCorrFoundForAuth.Id;
                updAlreadyExistingAuthCorrespondence.add(updAuthCorrRecrds);
            }
            if(!Test.isRunningTest()){
        		GenericDMLHandler.updateRecords(updAlreadyExistingAuthCorrespondence, null);    
        	}
        } else {*/
        auth = [select Id, Name, IDN_CASE__r.Name, IDN_PROVR__r.Name, CDE_COUNTY__r.CDE_COUNTY__c, isFinishedFlow__c FROM T_AUTH__c WHERE Id =:authId WITH SECURITY_ENFORCED LIMIT 1];
        if(auth != Null && auth.isFinishedFlow__c == true) {
            keyParams.put('caseId', auth.IDN_CASE__r.Name);
            keyParams.put('providerId', auth.IDN_PROVR__r.Name);
            keyParams.put('authId', auth.Id);
            countyCode = integer.valueOf(auth.CDE_COUNTY__r.CDE_COUNTY__c);
            if(!Test.isRunningTest()) { 
                CorspdTrigger.createCorspdRequest(CR213RsnCode,NULL,NULL,countyCode,keyParams);
            }
        }
        //}
    }
    /* @AuraEnabled
    public static authEncumbWrapper  dailyRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap, List<batchsit_t_sbsd_indiv_care_level__x> careLevels){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
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
            EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
            authEncmbrsToBeInserted.add(anAuthEncmbr);
            lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
            startDate = startDate.addDays(1);
        }
        objectData.put('authEncmbrsToBeInserted',authEncmbrsToBeInserted);
        objectData.put('lstAuthEncmbrsToBeInserted',lstAuthEncmbrsToBeInserted);
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted,startDate,startDate);
    }*/

    @AuraEnabled
    public static authEncumbWrapper weeklyRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap, List<batchsit_t_sbsd_indiv_care_level__x> careLevels){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            Integer dayOfWeek = startOfWeek.daysBetween(startDate);
            if((authEncumWrap.Sun__c && dayOfWeek == 0) || (authEncumWrap.Mon__c && dayOfWeek == 1) ||
               (authEncumWrap.Tue__c && dayOfWeek == 2) || (authEncumWrap.Wed__c && dayOfWeek == 3) ||
               (authEncumWrap.Thur__c && dayOfWeek == 4) || (authEncumWrap.Fri__c && dayOfWeek == 5) ||
               (authEncumWrap.Sat__c && dayOfWeek == 6)){
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
                   EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                   authEncmbrsToBeInserted.add(anAuthEncmbr);
                   lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                   startDate = startDate.addDays(1); 
               }else{
                   batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                   batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                   anAuthEncmbr.IDN_AUTH__c = authRecId;
                   anAuthEncmbr.CDE_STATUS_ENCMBR__c = '2'; //Authorized
                   anAuthEncmbr.CNT_HOUR_CARE__c = 0;//hoursPerDay.CNT_HOUR_CARE__c;
                   anAuthEncmbr.CDE_TYPE_UNIT_CARE__c =hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                   anAuthEncmbr.DTE_CARE__c = startDate;
                   anAuthEncmbr.Cde_Level_Care__c ='7';
                   for(batchsit_t_sbsd_indiv_care_level__x aCareLevel: careLevels){
                       if(aCareLevel.dte_begin_effv__c <= startDate && (startDate <= aCareLevel.dte_end_effv__c || aCareLevel.dte_end_effv__c == null))
                       { 
                           anAuthEncmbr.cde_level_care__c = aCareLevel.cde_level_care__c;
                           break;
                       }
                   }
                   EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                   authEncmbrsToBeInserted.add(anAuthEncmbr);
                   lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                   startDate = startDate.addDays(1); 
               }
            
        }
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted,startDate,startDate);
    } 

    @AuraEnabled
    public static authEncumbWrapper monthlyRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap, List<batchsit_t_sbsd_indiv_care_level__x> careLevels){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
         List<String> daysOfMonthStrLst = (authEncumWrap.DaysOfMonth__c).split(';');
        List<Integer> dayOfMonthIntLst = new List<Integer>();
        for(String s : daysOfMonthStrLst){
            dayOfMonthIntLst.add(Integer.valueOf(s));
        }
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            Integer dayOfWeek = startOfWeek.daysBetween(startDate);
            Integer dayOfDate = startDate.day();
            if(dayOfMonthIntLst.contains(dayOfDate)){// authEncumWrap.RecurDay__c == dayOfDate)){
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
                EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                authEncmbrsToBeInserted.add(anAuthEncmbr);
                lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                startDate = startDate.addDays(1); 
            }else{
                batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                anAuthEncmbr.IDN_AUTH__c = authRecId;
                anAuthEncmbr.CDE_STATUS_ENCMBR__c = '2'; //Authorized
                anAuthEncmbr.CNT_HOUR_CARE__c =0;// hoursPerDay.CNT_HOUR_CARE__c;
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
                EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                authEncmbrsToBeInserted.add(anAuthEncmbr);
                lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                startDate = startDate.addDays(1); 
            }
            
        }
        objectData.put('authEncmbrsToBeInserted',authEncmbrsToBeInserted);
        objectData.put('lstAuthEncmbrsToBeInserted',lstAuthEncmbrsToBeInserted);
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted,startDate,startDate);
    }

    @AuraEnabled
    public static authEncumbWrapper everyOtherWeekRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap, List<batchsit_t_sbsd_indiv_care_level__x> careLevels){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
        Date dateSun,dateMon,dateTue,dateWed,dateThru,dateFri,dateSat;
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            //startOfWeek = startOfWeek.addDays(1);
            Date endOfWeek = getEndDateOfWeek(startDate);
            while(startDate <= endOfWeek && startDate <= endDate){
                Integer dayOfWeek = startOfWeek.daysBetween(startDate);
                if((authEncumWrap.Sun__c && dayOfWeek == 0) || (authEncumWrap.Mon__c && dayOfWeek == 1) ||
                   (authEncumWrap.Tue__c && dayOfWeek == 2) || (authEncumWrap.Wed__c && dayOfWeek == 3) ||
                   (authEncumWrap.Thur__c && dayOfWeek == 4) || (authEncumWrap.Fri__c && dayOfWeek == 5) ||
                   (authEncumWrap.Sat__c && dayOfWeek == 6)){
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
                       EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                       authEncmbrsToBeInserted.add(anAuthEncmbr);
                       lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                       startDate = startDate.addDays(1); 
                   }else{
                       batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                       batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                       anAuthEncmbr.IDN_AUTH__c = authRecId;
                       anAuthEncmbr.CDE_STATUS_ENCMBR__c = '2'; //Authorized
                       anAuthEncmbr.CNT_HOUR_CARE__c =0;// hoursPerDay.CNT_HOUR_CARE__c;
                       anAuthEncmbr.CDE_TYPE_UNIT_CARE__c =hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                       anAuthEncmbr.DTE_CARE__c = startDate;
                       anAuthEncmbr.Cde_Level_Care__c ='7';
                       for(batchsit_t_sbsd_indiv_care_level__x aCareLevel: careLevels){
                           if(aCareLevel.dte_begin_effv__c <= startDate && (startDate <= aCareLevel.dte_end_effv__c || aCareLevel.dte_end_effv__c == null))
                           { 
                               anAuthEncmbr.cde_level_care__c = aCareLevel.cde_level_care__c;
                               break;
                           }
                       }
                       EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                       authEncmbrsToBeInserted.add(anAuthEncmbr);
                       lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                       startDate = startDate.addDays(1); 
                   } 
            }
            AuthorizationNotesController.authEncumbWrapper wrap =clearAuthEncumbranceRecords(authRecId,startDate,startDate.addDays(7),endDate,null,careLevels,hoursPerWeekDay);
            authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
            lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
            startDate =startDate.addDays(7);
            
        }
        objectData.put('authEncmbrsToBeInserted',authEncmbrsToBeInserted);
        objectData.put('lstAuthEncmbrsToBeInserted',lstAuthEncmbrsToBeInserted);
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted,startDate,startDate);
    }

    @AuraEnabled
    public static void createAuthSchRecurr(List<Auth_Schedule_Recurrence__c> authRecurrRecordsList, string authId) {
        List<Auth_Schedule_Recurrence__c> authSchRecurrListToUpsert = new List<Auth_Schedule_Recurrence__c>();
        for(Auth_Schedule_Recurrence__c auth:authRecurrRecordsList){
            if(String.isBlank(auth.IDN_AUTH__c)){
                auth.IDN_AUTH__c=authId;
                authSchRecurrListToUpsert.add(auth);
            }
        }
        if(authSchRecurrListToUpsert.size()>0){
            GenericDMLHandler.insertRecords(authSchRecurrListToUpsert, null); 
        }
    }

    @AuraEnabled
    public static authEncumbWrapper updateWeeklyRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap,Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authStartDate; // authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            Integer dayOfWeek = startOfWeek.daysBetween(startDate);
            if((authEncumWrap.Sun__c && dayOfWeek == 0) || (authEncumWrap.Mon__c && dayOfWeek == 1) ||
               (authEncumWrap.Tue__c && dayOfWeek == 2) || (authEncumWrap.Wed__c && dayOfWeek == 3) ||
               (authEncumWrap.Thur__c && dayOfWeek == 4) || (authEncumWrap.Fri__c && dayOfWeek == 5) ||
               (authEncumWrap.Sat__c && dayOfWeek == 6)){
                   batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                   // batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                   String startDateStr = String.valueOf(startDate);
                   batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                   if(anAuthEncmbr != null){
                       if(hoursPerDay.CDE_TYPE_UNIT_CARE__c != '--None--' && hoursPerDay.CNT_HOUR_CARE__c != null){
                           anAuthEncmbr.IDN_AUTH__c = authRecId;
                           anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                           anAuthEncmbr.CNT_HOUR_CARE__c = hoursPerDay.CNT_HOUR_CARE__c;
                           anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                           anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                           
                           EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                           authEncmbrsToBeInserted.add(anAuthEncmbr);
                           lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                       }
                   }
                   startDate = startDate.addDays(1); 
               }else{
                   batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                   String startDateStr = String.valueOf(startDate);
                   batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                   if(anAuthEncmbr != null){
                       anAuthEncmbr.IDN_AUTH__c = authRecId;
                       anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                       anAuthEncmbr.CNT_HOUR_CARE__c =0;// hoursPerDay.CNT_HOUR_CARE__c;
                       anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                       anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                       
                       EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                       authEncmbrsToBeInserted.add(anAuthEncmbr);
                       lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                   }
                   startDate = startDate.addDays(1); 
               }
        }
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted);
    }

    @AuraEnabled
    public static authEncumbWrapper updateMonthlyRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap, Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authStartDate;// authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
        List<String> daysOfMonthStrLst = (authEncumWrap.DaysOfMonth__c).split(';');
        List<Integer> dayOfMonthIntLst = new List<Integer>();
        for(String s : daysOfMonthStrLst){
            dayOfMonthIntLst.add(Integer.valueOf(s));
        }
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            Integer dayOfWeek = startOfWeek.daysBetween(startDate);
            Integer dayOfDate = startDate.day();
            if(dayOfMonthIntLst.contains(dayOfDate)){
                batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                // batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                String startDateStr = String.valueOf(startDate);
                batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                if(anAuthEncmbr != null){
                    if(hoursPerDay.CDE_TYPE_UNIT_CARE__c != '--None--' && hoursPerDay.CNT_HOUR_CARE__c != null){
                        anAuthEncmbr.IDN_AUTH__c = authRecId;
                        anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                        anAuthEncmbr.CNT_HOUR_CARE__c = hoursPerDay.CNT_HOUR_CARE__c;
                        anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                        anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                        
                        EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                        authEncmbrsToBeInserted.add(anAuthEncmbr);
                        lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                    }
                }
                startDate = startDate.addDays(1); 
            }else{
                batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                String startDateStr = String.valueOf(startDate);
                batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                if(anAuthEncmbr != null){
                    anAuthEncmbr.IDN_AUTH__c = authRecId;
                    anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                    anAuthEncmbr.CNT_HOUR_CARE__c = 0;
                    anAuthEncmbr.CDE_TYPE_UNIT_CARE__c =hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                    anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                    
                    EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                    authEncmbrsToBeInserted.add(anAuthEncmbr);
                    lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                }
                startDate = startDate.addDays(1); 
            }
        }
        objectData.put('authEncmbrsToBeInserted',authEncmbrsToBeInserted);
        objectData.put('lstAuthEncmbrsToBeInserted',lstAuthEncmbrsToBeInserted);
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted);
    }

    @AuraEnabled
    public static authEncumbWrapper updateEveryOtherWeekRecurrence(String authRecId,Date authStartDate,Date authEndDate,List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Auth_Schedule_Recurrence__c authEncumWrap,  Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> dailyEncumbToInsert = new List<batchsit_t_auth_encmbr__x>();
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        Date startDate = authEncumWrap.DTE_Begin_Date__c;
        Date endDate = authEncumWrap.DTE_End_Date__c;
        Date dateSun,dateMon,dateTue,dateWed,dateThru,dateFri,dateSat;
        if(startDate !=authStartDate && startDate< authStartDate){
            Date startOfWeekTemp = startDate.toStartofWeek();
             Date endOfWeekTemp = getEndDateOfWeek(authStartDate);
            Integer weeks = startOfWeekTemp.daysBetween(endOfWeekTemp)/7;
            if(weeks/2 == 0){
                endOfWeekTemp = endOfWeekTemp.addDays(1);
                startDate =endOfWeekTemp;
            }else{
                startDate =authStartDate;
            }            
        }
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            //startOfWeek = startOfWeek.addDays(1);
            Date endOfWeek = getEndDateOfWeek(startDate);
            while( startDate <=endOfWeek && startDate <= endDate){
                Integer dayOfWeek = startOfWeek.daysBetween(startDate);
                if((authEncumWrap.Sun__c && dayOfWeek == 0) || (authEncumWrap.Mon__c && dayOfWeek == 1) ||
                   (authEncumWrap.Tue__c && dayOfWeek == 2) || (authEncumWrap.Wed__c && dayOfWeek == 3) ||
                   (authEncumWrap.Thur__c && dayOfWeek == 4) || (authEncumWrap.Fri__c && dayOfWeek == 5) ||
                   (authEncumWrap.Sat__c && dayOfWeek == 6)){
                       batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                       String startDateStr = String.valueOf(startDate);
                       batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                       if(anAuthEncmbr != null){
                           if(hoursPerDay.CDE_TYPE_UNIT_CARE__c != '--None--' && hoursPerDay.CNT_HOUR_CARE__c != null){
                               anAuthEncmbr.IDN_AUTH__c = authRecId;
                               anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                               anAuthEncmbr.CNT_HOUR_CARE__c = hoursPerDay.CNT_HOUR_CARE__c;
                               anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                               anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                               
                               EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                               authEncmbrsToBeInserted.add(anAuthEncmbr);
                               lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                           }
                       }
                       startDate = startDate.addDays(1); 
                   }else{
                       batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                       String startDateStr = String.valueOf(startDate);
                       batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                       if(anAuthEncmbr != null){
                           anAuthEncmbr.IDN_AUTH__c = authRecId;
                           anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                           anAuthEncmbr.CNT_HOUR_CARE__c = 0;
                           anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                           anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                           
                           EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                           authEncmbrsToBeInserted.add(anAuthEncmbr);
                           lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                       }
                       startDate = startDate.addDays(1); 
                   } 
            }
            
            AuthorizationNotesController.authEncumbWrapper wrap =clearAuthEncumbranceRecords(authRecId,startDate,startDate.addDays(7),endDate,careDateToAuthEncmbr2,null,hoursPerWeekDay);
            authEncmbrsToBeInserted.addAll(wrap.authEncmbrsToBeInserted);
            lstAuthEncmbrsToBeInserted.addAll(wrap.lstAuthEncmbrsToBeInserted);
            startDate =startDate.addDays(7);
        }
        objectData.put('authEncmbrsToBeInserted',authEncmbrsToBeInserted);
        objectData.put('lstAuthEncmbrsToBeInserted',lstAuthEncmbrsToBeInserted);
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted);
    }
    
    public static authEncumbWrapper clearAuthEncumbranceRecords(String authRecId,Date startDate,Date endDate, Date recurrEndDate, Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2,List<batchsit_t_sbsd_indiv_care_level__x> careLevels, List<batchsit_t_auth_encmbr__x> hoursPerWeekDay){
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();
        while(startDate<endDate && startDate<=recurrEndDate){
            String startDateStr = String.valueOf(startDate);
            Date startOfWeek = startDate.toStartofWeek();
            Integer dayOfWeek = startOfWeek.daysBetween(startDate);
            if(careDateToAuthEncmbr2 != null){
                 batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                if(anAuthEncmbr != null){
                    anAuthEncmbr.IDN_AUTH__c = authRecId;
                    anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                    anAuthEncmbr.CNT_HOUR_CARE__c = 0;
                    anAuthEncmbr.CDE_TYPE_UNIT_CARE__c =  hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                    anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                    EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                    authEncmbrsToBeInserted.add(anAuthEncmbr);
                    lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                }
            }else{
                 batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
                batchsit_t_auth_encmbr__x anAuthEncmbr = new batchsit_t_auth_encmbr__x();
                anAuthEncmbr.IDN_AUTH__c = authRecId;
                anAuthEncmbr.CDE_STATUS_ENCMBR__c = '2'; //Authorized
                anAuthEncmbr.CNT_HOUR_CARE__c =0;// hoursPerDay.CNT_HOUR_CARE__c;
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
                EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                authEncmbrsToBeInserted.add(anAuthEncmbr);
                lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
            }
            startDate = startDate.addDays(1); 
        }
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted);
    }

     public static authEncumbWrapper createScheduleRecords(String authRecId,Date startDate,Date endDate, List<batchsit_t_auth_encmbr__x> hoursPerWeekDay,Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbr2, List<batchsit_t_sbsd_indiv_care_level__x> careLevels){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        Map<String, batchsit_t_auth_encmbr__x> careDateToAuthEncmbrId = new Map<String, batchsit_t_auth_encmbr__x>();		   
        while(startDate <= endDate) {
            Date startOfWeek = startDate.toStartofWeek();
            Integer dayOfWeek = startOfWeek.daysBetween(startDate);
            
            batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
            if(careDateToAuthEncmbr2 != null){
                String startDateStr = String.valueOf(startDate);
                batchsit_t_auth_encmbr__x anAuthEncmbr = careDateToAuthEncmbr2.get(startDateStr);
                if(anAuthEncmbr != null){
                    anAuthEncmbr.IDN_AUTH__c = authRecId;
                    anAuthEncmbr.CDE_STATUS_ENCMBR__c = anAuthEncmbr.CDE_STATUS_ENCMBR__c; //Authorized
                    anAuthEncmbr.CNT_HOUR_CARE__c = hoursPerDay.CNT_HOUR_CARE__c;
                    anAuthEncmbr.CDE_TYPE_UNIT_CARE__c = hoursPerDay.CDE_TYPE_UNIT_CARE__c;
                    anAuthEncmbr.ExternalId = anAuthEncmbr.ExternalId;
                    EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                    authEncmbrsToBeInserted.add(anAuthEncmbr);
                    lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
                } 
            }else{
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
                EncumberenceWrapper encumberenceWrapRec = AuthorizationFlowApxCtrl.getEncumberenceWrapper(anAuthEncmbr);
                authEncmbrsToBeInserted.add(anAuthEncmbr);
                lstAuthEncmbrsToBeInserted.add(encumberenceWrapRec);
            }
            
            startDate = startDate.addDays(1);
        }
        objectData.put('authEncmbrsToBeInserted',authEncmbrsToBeInserted);
        objectData.put('lstAuthEncmbrsToBeInserted',lstAuthEncmbrsToBeInserted);
        return new authEncumbWrapper(authEncmbrsToBeInserted,lstAuthEncmbrsToBeInserted,startDate,startDate);
    }
    
    public static Date getEndDateOfWeek (Date startDate){
        Date endDate;
        Date startOfWeek = startDate.toStartofWeek();
        return startOfWeek.addDays(6);
    }
    // ==================== Wrapper Classes ====================
    public class authNoteWrapper {
        @AuraEnabled public Boolean isUpdate;
        @AuraEnabled public batchsit_t_auth_notes__x authNote;
        @AuraEnabled public T_AUTH__c auth;
        @AuraEnabled public Id loggedInUserId;
        @AuraEnabled public String authId;
       @AuraEnabled public Boolean isAuthFlowCompleted;
        public authNoteWrapper(Boolean isUpdate,batchsit_t_auth_notes__x authNote,String loggedInUserId, T_AUTH__c auth, String authId,Boolean isAuthFlowCompleted){
            this.isUpdate = isUpdate;
            this.authNote = authNote;
            this.loggedInUserId = loggedInUserId;
            this.auth = auth;
            this.authId = authId;
           this.isAuthFlowCompleted = isAuthFlowCompleted;
        }
    }

    public class authEncumbWrapper {
        @AuraEnabled public List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted = new List<batchsit_t_auth_encmbr__x>();
        @AuraEnabled public List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted = new List<EncumberenceWrapper>();
        @AuraEnabled public Date endDate;
        @AuraEnabled public Date startDate;
        
        public authEncumbWrapper(List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted ,List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted){
            this.authEncmbrsToBeInserted = authEncmbrsToBeInserted;
            this.lstAuthEncmbrsToBeInserted = lstAuthEncmbrsToBeInserted;
        }

        public authEncumbWrapper(List<batchsit_t_auth_encmbr__x> authEncmbrsToBeInserted ,List<EncumberenceWrapper> lstAuthEncmbrsToBeInserted,Date startDate,Date endDate){
            this.authEncmbrsToBeInserted = authEncmbrsToBeInserted;
            this.lstAuthEncmbrsToBeInserted = lstAuthEncmbrsToBeInserted;
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}