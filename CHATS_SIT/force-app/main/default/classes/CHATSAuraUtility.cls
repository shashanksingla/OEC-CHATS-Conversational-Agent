public with sharing class CHATSAuraUtility {
    
    @AuraEnabled
    public static Id fetchLoggedInUserId(){
        return UserInfo.getUserId();
    }
    
    @AuraEnabled
    public static LightningServerResponse fetchLoggedInProfileId(String caseCommentId){
        Boolean isSuccessful = true;
        String message = '';
        Map<String,Object> objectData = new Map<String,Object>();
        String profileName= [Select Name from Profile where Id =: UserInfo.getProfileId() Limit 1].Name;
        batchsit_t_sbsd_case_cmt__x caseCommentRec = new batchsit_t_sbsd_case_cmt__x();
        if(Test.isRunningTest()) {
            caseCommentRec = new batchsit_t_sbsd_case_cmt__x(id = caseCommentId, idn_case__c='12345');
        } else {
            caseCommentRec = [select id,createdbyid__c,idn_case__c from batchsit_t_sbsd_case_cmt__x where id=:caseCommentId limit 1 ];
        }
        if(caseCommentRec != null){
            T_SBSD_CASE__c caseRec = [Select id,Name from T_SBSD_CASE__c where IDN_EXTNL__c =:caseCommentRec.idn_case__c limit 1];
            objectData.put('caseRecordId',caseRec.id);
            objectData.put('caseName',caseRec.Name);
            
        }
        objectData.put('profileName',profileName);
        objectData.put('caseCommentRec',caseCommentRec);
        return new LightningServerResponse(isSuccessful,message, objectData);
    }
    
    @AuraEnabled
    public static String getSobjectName(Id recordId){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        return sObjName;
    }
    
    @AuraEnabled
    public static LightningServerResponse getCaseOrCaseCommentObjectAPI(Id recordId, string isNewCaseCommentFromCaseComment){
        Boolean isSuccessful = true;
        String message = '';
        String sObjName,caseRecordId;
        Map<String,Object> objectData = new Map<String,Object>();
        T_SBSD_CASE__c caseRec;
        if(Test.isRunningTest()) {
            if(recordId != null){
                sObjName = 'T_SBSD_CASE__c';
            } else {
                sObjName = 'batchsit_t_sbsd_case_cmt__x';
            }
        } else {
            sObjName = recordId.getSObjectType().getDescribe().getName();    
        }
        batchsit_t_sbsd_case_cmt__x caseCmtRecord ;
        if(sObjName=='batchsit_t_sbsd_case_cmt__x'){
            if(Test.isRunningTest()) {
                caseCmtRecord = new batchsit_t_sbsd_case_cmt__x(idn_case__c='12345');
            } else {
                caseCmtRecord =[select id,createdbyid__c,idn_case__c from batchsit_t_sbsd_case_cmt__x where id=:recordId limit 1 ];
            }
        }
        if(isNewCaseCommentFromCaseComment == 'true'){
            if(caseCmtRecord != null){
                caseRec = [Select id, Name, IDN_EXTNL__c, CDE_COUNTY__c, CDE_COUNTY__r.Name from T_SBSD_CASE__c where IDN_EXTNL__c =:caseCmtRecord.idn_case__c limit 1];
                objectData.put('caseRecordId',caseRec.id);
                objectData.put('caseExtnlId', caseRec.IDN_EXTNL__c);
            }
            objectData.put('sObjName', 'T_SBSD_CASE__c');
        } else {
            
            if(sObjName=='batchsit_t_sbsd_case_cmt__x'){
                if(caseCmtRecord != null){
                    caseRec = [Select id, CDE_COUNTY__c, CDE_COUNTY__r.Name from T_SBSD_CASE__c where IDN_EXTNL__c =:caseCmtRecord.idn_case__c limit 1];
                }
                
            }else{
                caseRec = [Select id, CDE_COUNTY__c, CDE_COUNTY__r.Name from T_SBSD_CASE__c where Id =:recordId limit 1];
                
            }
            
            objectData.put('sObjName', sObjName);
        }
        objectData.put('isValidCounty', true);
        if(caseRec != null){
            Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(caseRec.CDE_COUNTY__c);
            objectData.put('isValidCounty', countyMatched);
            objectData.put('countyName', caseRec.CDE_COUNTY__r.Name);
        }
        return new LightningServerResponse(isSuccessful,message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse checkOwnerCountyMatch(String recordId, String fieldName){
        Boolean isSuccessful = true;
        String message = '';
        Map<String,Object> objectData = new Map<String,Object>();
        List<T_SBSD_CASE__c> caseList = new List<T_SBSD_CASE__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CHATSAuraUtility','Method__c'=>'checkOwnerCountyMatch'};
            
            objectData.put('showWarning',true); 
        objectData.put('warningMessage','The county of the authorization does not match your assigned county(ies).');
        try{
            Id recId = (Id)recordId;
            if(String.isNotBlank(recordId)){
                String sObjName = recId.getSObjectType().getDescribe().getName();
                if(sObjName == 'T_SBSD_CASE__c'){
                    caseList =[SELECT id,IDN_EXTNL__c,DTE_REDET_CASE__c,CDE_COUNTY__c,IDN_PROVR__c,CLOSED_CASES_STATUS__c from T_SBSD_CASE__c where id=:recordId limit 1];
                    if(caseList.size()>0){
                        objectData.put('caseObj',caseList[0]);
                        if(caseList[0].CLOSED_CASES_STATUS__c >0){
                            objectData.put('isCaseClosed',true);
                        }
                    }
                }
            }
            String query = 'SELECT '+String.escapeSingleQuotes(fieldName)+' FROM '+recId.getSobjectType()+' WHERE Id=:recordId LIMIT 1';
            List<SObject> sObjects = Database.query(query);
            Id countyId = (Id)sObjects.get(0).get(fieldName);
            objectData.put('countyId',countyId);
            List<T_COUNTY__c> countyList = [Select Name from T_COUNTY__c where Id =:countyId limit 1];
            if(countyList.size() > 0){
                objectData.put('warningMessage','The authorization record belongs to '+countyList[0].Name+' county. This does not match your assigned county(ies).');
            }
            if(!sObjects.isEmpty() && sObjects.get(0).get(fieldName)!=null && !(CHATSUtility.checkCountyWithUserCounty((Id)sObjects.get(0).get(fieldName)))){
                objectData.put('showWarning',false);
            } 
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    //CCCAP-690
    @AuraEnabled
    public static LightningServerResponse careLevelOfferedByProvider(String authId,String recordId,String authBeginDate,String currentProviderId,String currentClientId, String hoursPerWeekDayStr){
        Boolean isSuccessful = true;
        String message = '';
        String caseCounty ;
        String clientExternalId;
        Id recId = (Id)recordId;
        Date beginDate1, firstDayofEndMonth, endDate1 , authBeginDateTemp;
        String countyId;
        Date nullDate;
        List<batchsit_t_sbsd_indiv_care_level__x> indcareLvl = new List<batchsit_t_sbsd_indiv_care_level__x>();
        
        List<batchsit_t_fiscal_rate__x> fiscalRateAmount = new List<batchsit_t_fiscal_rate__x>(); 
        List<T_SBSD_CASE__c> caseList = new List<T_SBSD_CASE__c>();
        List<T_SBSD_INDIV__c> indivList = new List<T_SBSD_INDIV__c>();
        Map<String,Object> objectData = new Map<String,Object>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CHATSAuraUtility','Method__c'=>'careLevelOfferedByProvider'};
        List<batchsit_t_auth_encmbr__x> hoursPerWeekDay =  new List<batchsit_t_auth_encmbr__x>();
        if(String.isNotEmpty(hoursPerWeekDayStr)){
            hoursPerWeekDay =(List<batchsit_t_auth_encmbr__x>)JSON.deserialize(hoursPerWeekDayStr, List<batchsit_t_auth_encmbr__x>.class);
        }
        objectData.put('showWarningCareLevel',false);
        objectData.put('warningMessageCareLevel',' The provider selected does not offer the care level required over the entire span of the authorization period. Select Yes if you would like to continue?');
        
        try{
            List<String> dateParts = new List<String>();
            if(currentClientId != null){
                indivList =[Select id,IDN_EXTNL__c from T_SBSD_INDIV__c where id =:currentClientId];
                if(indivList.size()>0){
                    clientExternalId =indivList[0].IDN_EXTNL__c;
                }
            }
            
            String queryStr = 'Select id,DTE_END_EFFV__c,IDN_AGRMT_FISCAL__c, IDN_AGRMT_FISCAL__r.CDE_TYPE_STATUS__c,IDN_AGRMT_FISCAL__r.ID_SERVICE__c,toLabel(CDE_RATE_TYPE__c) from T_FISCAL_SCH__c where';
            dateParts= authBeginDate.split('-');
            if(dateParts[2].length() >1){
                dateParts[2] = dateParts[2].substring(0,2);
            }
            beginDate1 = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
            authBeginDateTemp=beginDate1;
            caseList =[Select id,CDE_COUNTY__c, DTE_REDET_CASE__c from T_SBSD_CASE__c where id=:authId];
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
            Date authOneWeek = beginDate1.addDays(7);
           Set<String> rateTypeAuth = new Set<String>();
        if(hoursPerWeekDay!= null && hoursPerWeekDay.size()>0){
           while(authBeginDateTemp <= authOneWeek) {
               Date startOfWeek = authBeginDateTemp.toStartofWeek();
                    Integer dayOfWeek = startOfWeek.daysBetween(authBeginDateTemp);
                    batchsit_t_auth_encmbr__x hoursPerDay = hoursPerWeekDay.get(dayOfWeek);
               rateTypeAuth.add(String.valueOf(hoursPerDay.CDE_TYPE_UNIT_CARE__c));
               authBeginDateTemp = authBeginDateTemp.addDays(1);
           }
        }
            if(clientExternalId != null){
                indcareLvl = [Select id,cde_level_care__c,idn_sbsd_indiv_care_level__c,dte_end_effv__c,dte_begin_effv__c,idn_client__c from batchsit_t_sbsd_indiv_care_level__x where idn_client__c =:clientExternalId 
                              and ((dte_begin_effv__c <=:beginDate1 and (dte_end_effv__c=null OR dte_end_effv__c>=:beginDate1))
                                   OR (dte_begin_effv__c <=:endDate1 and (dte_end_effv__c=null OR dte_end_effv__c>=:endDate1))
                                   OR (dte_begin_effv__c>=:beginDate1 and dte_end_effv__c<=:endDate1)
                                  )];
            }
            if(countyId != null && countyId != ''){
                queryStr = queryStr+' IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =:countyId';
            }
            if(currentProviderId != null && currentProviderId !=''){
                queryStr = queryStr+' and IDN_AGRMT_FISCAL__r.ID_SERVICE__c =:currentProviderId';
            }
            queryStr = queryStr+' and IDN_AGRMT_FISCAL__r.DTE_BEGIN_AGRMT__c <=:beginDate1 AND (IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c >=:beginDate1 or IDN_AGRMT_FISCAL__r.DTE_END_AGRMT__c =:nullDate)';
            queryStr = queryStr+' and DTE_BEGIN_EFFV__c <=:beginDate1 AND (DTE_END_EFFV__c >=:beginDate1 OR DTE_END_EFFV__c =:nullDate)';
            
            List<T_FISCAL_SCH__c> fiscalSchList = new List<T_FISCAL_SCH__c>();
            fiscalSchList =Database.query(queryStr);
            system.debug('fiscalSchList--'+fiscalSchList);
            List<Id> idnFiscalSch = new List<Id>();
            for(T_FISCAL_SCH__c fis:fiscalSchList){
                idnFiscalSch.add(fis.id);
            }
            system.debug('idnFiscalSch--'+idnFiscalSch);
            List<FiscalRateWrapper> lstFiscalRateWrapper=HerokuService.fiscalRatefetch(idnFiscalSch);
            
            for(FiscalRateWrapper fiscalWrap : lstFiscalRateWrapper){
                batchsit_t_fiscal_rate__x fiscalRate = new batchsit_t_fiscal_rate__x();
                fiscalRate.cde_age_group__c = fiscalWrap.ageGroup;
                fiscalRate.cde_care_unit__c = fiscalWrap.careUnit;
                fiscalRate.amt_fa__c = fiscalWrap.fiscalRateAmount;
                fiscalRate.idn_fiscal_sch__c = fiscalWrap.idnFiscalSchedule;
                fiscalRate.amt_provr__c = fiscalWrap.providerRateAmount;
                fiscalRate.cde_rate_type__c = fiscalWrap.rateType;
                fiscalRateAmount.add(fiscalRate);
            }
            
            for(batchsit_t_sbsd_indiv_care_level__x indCareLevel:indcareLvl){
                for(batchsit_t_fiscal_rate__x rate:fiscalRateAmount){
                    if(rate.cde_age_group__c==indCareLevel.cde_level_care__c && rate.cde_care_unit__c=='3' && rate.amt_provr__c==0 && rateTypeAuth.contains(rate.cde_rate_type__c)){
                        objectData.put('showWarningCareLevel',true);
                    }
                }
            }
            
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getDataFromWebService(String endPoint, String method, String requestBody, List<String> requiredParams){
        Boolean isSuccessful = true;
        String message = '';
        Map<String,Object> objectData = new Map<String,Object>();
        Map<String,Object> methodReqInfo = new Map<String,Object>();
        methodReqInfo.put('Class__c','CHATSAuraUtility');    
        methodReqInfo.put('Method__c','getDataFromWebService');  
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(method);
        req.setBody(requestBody);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Http http = new Http();
        HttpResponse response = http.send(req);
        if (response.getStatusCode() != 200) {
            isSuccessful = false;
            message = 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody();
            ExceptionLoggingServices.captureExceptionLog(response, req, methodReqInfo);
        } else {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('data:'+data);
            if(data.get('success')!=null && data.get('success')=='successfull'){
                for(String requiredParam:requiredParams){
                    objectData.put(requiredParam, data.get(requiredParam));
                }
            }else{
                isSuccessful = false;
                message = String.valueOf(data.get('errorMessage'));
            }
        }
        return new LightningServerResponse(isSuccessful,message, objectData);
    }
    
}