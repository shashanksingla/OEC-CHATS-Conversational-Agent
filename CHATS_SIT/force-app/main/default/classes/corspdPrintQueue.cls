/*
* PROD_RELEASE_10_7
*/
public with sharing class corspdPrintQueue implements IRequest{
	public static final String DELETED = 'Deleted';
    public String jsonParam;
    private static Map<String, Object > requestObj;
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
        requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }      
        if (methodName == 'processCorspdSearch') {
            response = processCorspdSearch(getMapValue('corspdStatus'),getMapValue('countyName'),getMapValue('caseId'),(integer)requestObj.get('providerId'),getMapValue('dateRequested'),getMapValue('dateRequestedEndRange'),
            (integer)requestObj.get('correspondenceId'),getMapValue('correspondenceType'),getMapValue('correspondenceRecipientType'),getMapValue('requestedBy'),
            getMapValue('datePrintedBeginDate'),getMapValue('datePrintedEndDate'),getMapValue('screen'),getMapValue('suppressIndicator'));
        } else if(methodName == 'corspdSuppressOrDeleteAction'){
            List<Object> objList = (List<Object>)requestObj.get('lstCorspdId');
            List<String> corspdIds = new List<String>();
            for(Object obj : objList){
                corspdIds.add((String)obj);
            }
            response = corspdSuppressOrDeleteAction(corspdIds,getMapValue('operation'));
        }
        else if(methodName == 'addPrintedDateToCorspdDate'){
            response = addPrintedDateToCorspdDate(getMapValue('lstCorspdId'),getMapValue('alreadygenUrl'),getMapValue('fileName'));
        }
        else if (methodName == 'processCorspdQueueToView') {
            response = processCorspdQueueToView(getMapValue('corspdId'));
        } 
        else if (methodName == 'processCorspdPrint'){            
            List<Object> objList = (List<Object>)requestObj.get('lstCorspdId');
            List<String> corspdIds = new List<String>();
            for(Object obj : objList){
                corspdIds.add((String)obj);
            }
            response = processCorspdPrint(corspdIds);
        }
        else if(methodName == 'fetchUserdata'){
            response = fetchUserdata();
        } else if(methodName == 'fetchUserCounties'){
            response = fetchUserCounties();
        } else if(methodName == 'getFileName'){
            response = getFileName(getMapValue('corspdId'));
        }
        return response;
    }
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }

    @auraEnabled
    public static corspdReturnPacket processCorspdSearch(string corspdStatus, String countyName, string caseId, integer providerId, string dateRequested, string dateRequestedEndRange, 
                                                         integer correspondenceId,string correspondenceType, string correspondenceRecipientType, string requestedBy, 
                                                         string datePrintedBeginDate, string datePrintedEndDate, string screen,string suppressIndicator){
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        corspdReturnPacket corspdRtrnPackFromPrinted = new corspdReturnPacket();
        corspdReturnPacket corspdRtrnPackFromPrintQueue = new corspdReturnPacket();
        list<corspdError> errorList = new list<corspdError>();
        list<T_DOC_RQ__c> corspdGenerationSearchList;
        list<T_PRNT_DTL__x> printedCorspdSearchList;
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdSearch'};
        
        try{
            if(screen == 'CorrespondenceGeneration') {
                corspdRtrnPackFromPrintQueue = getCorspdGenerationDetails(corspdStatus,countyName,caseId,providerId,dateRequested, dateRequestedEndRange, correspondenceType,correspondenceId, correspondenceRecipientType, requestedBy);
                corspdRtrnPack.payload = corspdRtrnPackFromPrintQueue.payload;
                corspdRtrnPack.corspdSearchListCount = corspdRtrnPackFromPrintQueue.corspdSearchListCount;
                errorList = corspdRtrnPackFromPrintQueue.errorMessage;
            } else if (screen == 'PrintedCorrespondence') {
                if(Test.isRunningTest()){
                    //Test.setMock(HttpCalloutMock.class, new corspdPrintQueueMockTest());
                    //corspdRtrnPackFromPrinted = corspdPrintQueue.getPrintedCorspdDetails('REL', NULL, NULL, NULL, NULL, 1234567);
                    corspdRtrnPackFromPrinted = new corspdReturnPacket();
                    
                }else { 
                    corspdRtrnPackFromPrinted = getPrintedCorspdDetails(corspdStatus,countyName,caseId,providerId,dateRequested,dateRequestedEndRange,correspondenceId,correspondenceType,correspondenceRecipientType, requestedBy, datePrintedBeginDate, datePrintedEndDate,suppressIndicator);
                }
                
                corspdRtrnPack.payload = corspdRtrnPackFromPrinted.payload;
                //corspdRtrnPack.corspdSearchListCount = corspdRtrnPackFromPrinted.corspdSearchListCount ;
                corspdRtrnPack.targetUrl = Label.correspondenceTargetPdfServlet;
                corspdRtrnPack.corspdPathInAws = Label.correspondencePathInAws;
            }
            
        }catch( CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in Method-get correspondence details : - ' + e.getMessage();
            errorList.add(errorObj);       
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);                                  
        }                                          
        if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;            
        }else{
            corspdRtrnPack.returnStatus = 'Success';
            
        }                                          
        return corspdRtrnPack;                                          
    }
    
    public static corspdReturnPacket getCorspdGenerationDetails(string corspdStatus, string countyName, string caseId, integer providerId, string dateRequested, string dateRequestedEndRange, string correspondenceType, integer correspondenceId, string correspondenceRecipientType, string requestedBy){
        list<T_DOC_RQ__c> searchResult = new list<T_DOC_RQ__c>();
        corspdReturnPacket corspdRtrnPackPrintQueueDetails = new corspdReturnPacket();
        String soql, soqlSelect, soqlOrderBy, soqlcount;
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'getCorspdGenerationDetails'};
	    
        Map<String,Object> countyDetails = fetchUserCounties();
        String allUserCounties = (String)countyDetails.get('allUserCounties');
        Boolean adminUser = (Boolean)countyDetails.get('adminUser');
        Set<id> countyIdSet = (set<id>)countyDetails.get('countyIdSet');
        List<corspdError> errorList = new List<corspdError>();
        
        try{
            soqlSelect = 'select id,IDN_CASE__r.Name, IDN_PROVR__r.Name, toLabel(NME_CORSPD__c), CDE_CORSPD_STATUS__c,Name, DTE_REQ__c, CDE_COUNTY__r.Name, Owner.Name,  Requested_By__c, IDN_CASE_F__c, IDN_COUNTY_F__c, IDN_PROVR_F__c from T_DOC_RQ__c where ';
            soqlcount = 'select count() from T_DOC_RQ__c where ';
            soql = 'id != null';
            string input_corspdStatus, input_correspondenceId,provrId;
            string dateRequestedBeginMonth, dateRequestedBeginDay, dateRequestedEndMonth, dateRequestedEndDay;
            integer year, month, day, yearEnd, monthEnd, dayEnd;
            date dtRqstd,dtRqstdEnd;
            
            if((correspondenceType != Null) && (correspondenceType != ' ') && (correspondenceType != '')){
                soql += ' AND NME_CORSPD__c LIKE ';
                soql += '\'%'+String.escapeSingleQuotes(correspondenceType)+'%\'';
            }
            if((corspdStatus != null) && (corspdStatus != ' ') && (corspdStatus != '')){
                input_corspdStatus = String.escapeSingleQuotes(corspdStatus);
                soql += ' AND CDE_CORSPD_STATUS__c LIKE ';
                soql += '\'%'+input_corspdStatus+'%\'';
            } else {
                soql += ' AND CDE_CORSPD_STATUS__c != \'Pending\''; // Added by Rishav for CCCAP-7800
            }
            if((countyName != null) && (countyName != ' ')  && (countyName != '')){
                soql += ' AND CDE_COUNTY__c =: countyName ';
            }
            if(caseId != null && (caseId != '') && (caseId != ' ')){
                soql += ' AND IDN_CASE__c in ';
                soql += ' (select id from T_SBSD_CASE__c where Name =: caseId)';
                if(!adminUser){
                    for(T_SBSD_CASE__c cs : [SELECT CDE_County__c, CDE_County__r.Name FROM T_SBSD_CASE__c where Name =: caseId]){
                        if(!allUserCounties.contains(cs.CDE_County__r.Name)){
                            corspdError error = new corspdError();
                            error.errorMsg = 'The case '+caseId+' belongs to '+cs.CDE_County__r.Name+' county. This does not match your assigned county(ies).';                            
                            errorList.add(error);
                        }
                    }
                }
            }
            System.debug('Provider Id: '+providerId);
            if (providerId != null && String.valueOf(providerId) != ''){
                provrId = String.valueOf(providerId);
                soql += ' AND IDN_PROVR__c IN ';
                soql += '(select id from T_CHATS_PROVR_STATUS__c where Name =: provrId)';
                
                if(!adminUser){
                    Boolean countyMatched = false;
                    for(T_PROVR_FISCAL_AGREMENT__c cs : [SELECT CDE_COUNTY__c, CDE_COUNTY__r.Name FROM T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__r.Name =: provrId]){
                        if(allUserCounties.contains(cs.CDE_COUNTY__r.Name)){
                            countyMatched = true;
                        }
                    }
                    if(!countyMatched){
                        corspdError error = new corspdError();
                        error.errorMsg = 'The provider '+provrId+' does not have a Fiscal Agreement with your assigned county(ies).';                        
                        errorList.add(error);
                    }
                }
            }
            if ( correspondenceId != null && String.valueOf(correspondenceId) != ''){
                input_correspondenceId = string.valueOf(correspondenceId);
                soql += ' AND Name LIKE ';
                soql += '\'%'+input_correspondenceId+'%\'';                
            }
            if(correspondenceRecipientType != null && (correspondenceRecipientType != '') && (correspondenceRecipientType != ' ')){
                soql += ' AND CDE_TYPE_RCPT__c =: correspondenceRecipientType ';
            }
            if(!string.isEmpty(requestedBy)) {
                User cUser = [SELECT Id, LastName, FirstName, Name, toLabel(Owner_County__c), toLabel(Common_County__c)  
                                      FROM User where Id =:requestedBy];
                string userReqstd = cUser.FirstName + ' ' +cUser.LastName;
                soql += ' AND Requested_By__c =: userReqstd';
                
                if(!adminUser){
                    Boolean countyMatched = false;
                    if(cUser.Owner_County__c != null && allUserCounties.contains(cUser.Owner_County__c)){
                        countyMatched = true;
                    }
                    if(!countyMatched && cUser.Common_County__c != null){
                    Set<String> commonCountyValues = new Set<String>(cUser.Common_County__c.split(';'));                                               
                    commonCountyValues.retainAll(new Set<String>(allUserCounties.split(';')));
                    if(!commonCountyValues.isEmpty()){
                        countyMatched = true;
                        }
                    }
                    if(!countyMatched){
                        corspdError error = new corspdError();
                        error.errorMsg = userReqstd+' (User Requested) does not belong to your assigned county(ies).';                        
                        errorList.add(error);
                    }
                }                
            }
                
            if(dateRequested!= null && dateRequestedEndRange != null){
                    dtRqstd = date.valueOf(dateRequested); 
                    dtRqstdEnd = date.valueOf(dateRequestedEndRange); 
                    year = dtRqstd.year();
                    month = dtRqstd.month(); if(month < 10) dateRequestedBeginMonth = '0'+month; else dateRequestedBeginMonth = string.valueOf(month);
                    day = dtRqstd.day(); if (day < 10) dateRequestedBeginDay = '0'+day; else dateRequestedBeginDay = string.valueOf(day);
                    yearEnd = dtRqstdEnd.year();
                    monthEnd = dtRqstdEnd.month(); if(monthEnd < 10) dateRequestedEndMonth = '0'+monthEnd; else dateRequestedEndMonth = string.valueOf(monthEnd);
                    dayEnd = dtRqstdEnd.day(); if (dayEnd < 10) dateRequestedEndDay = '0'+dayEnd; else dateRequestedEndDay = string.valueOf(dayEnd);
                    soql += ' AND DTE_REQ__c >= '+year+'-'+dateRequestedBeginMonth+'-'+dateRequestedBeginDay+' AND DTE_REQ__c <= '+yearEnd+'-'+dateRequestedEndMonth+'-'+dateRequestedEndDay;
            } else if ( dateRequested != null && dateRequestedEndRange == null){
                    dtRqstd = date.valueOf(dateRequested);   
                    year = dtRqstd.year();
                    month = dtRqstd.month();
                    day = dtRqstd.day();
                    if((day < 10) && (month < 10)){
                        soql += ' AND DTE_REQ__c >= '+year+'-0'+month+'-0'+day;
                    }else if(month < 10){
                        soql += ' AND DTE_REQ__c >= '+year+'-0'+month+'-'+day;
                    }else if(day < 10){
                        soql += ' AND DTE_REQ__c >= '+year+'-'+month+'-0'+day;
                    }else{
                        soql += ' AND DTE_REQ__c >= '+year+'-'+month+'-'+day;
                    }
            } else if (dateRequested == null && dateRequestedEndRange != null){
                    dtRqstdEnd = date.valueOf(dateRequestedEndRange);
                    yearEnd = dtRqstdEnd.year();
                    monthEnd = dtRqstdEnd.month(); if(monthEnd < 10) dateRequestedEndMonth = '0'+monthEnd; else dateRequestedEndMonth = string.valueOf(monthEnd);
                    dayEnd = dtRqstdEnd.day(); if (dayEnd < 10) dateRequestedEndDay = '0'+dayEnd; else dateRequestedEndDay = string.valueOf(dayEnd);
                    soql += ' AND DTE_REQ__c <= '+yearEnd+'-'+dateRequestedEndMonth+'-'+dateRequestedEndDay;
            }
            if(!adminUser){
                soql += ' AND CDE_COUNTY__c IN :countyIdSet';
            }
            corspdRtrnPackPrintQueueDetails.errorMessage = errorList;
            if(errorList.size() == 0){
                soqlOrderBy = ' ORDER BY DTE_REQ__c desc LIMIT 500';
                system.debug(soqlSelect + soql + soqlOrderBy);
                searchResult = Database.query(soqlSelect + soql + soqlOrderBy);
                if (searchResult.size() > 0) {
                    corspdRtrnPackPrintQueueDetails.payload = searchResult;
                }
                system.debug('The search Result1 entries -'+searchResult.size());
                corspdRtrnPackPrintQueueDetails.corspdSearchListCount = Database.countQuery(soqlcount + soql);
            }
        }catch(exception e){
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
            throw new corspdException('Error fetching data from Correspondence Request Table', e );
        }
        return corspdRtrnPackPrintQueueDetails;
    }
    
    public static corspdReturnPacket getPrintedCorspdDetails(string corspdStatus, string countyName, string caseId, integer providerId, string dateRequested, string dateRequestedEndRange, 
                                                             integer correspondenceId, string correspondenceType, string correspondenceRecipientType, string requestedBy, string datePrintedBeginDate, string datePrintedEndDate,string suppressIndicator){
        list<T_PRNT_DTL__x> searchResult = new list<T_PRNT_DTL__x>();
        list<corspdError> errorList = new list<corspdError>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'getPrintedCorspdDetails'};
        string userRequested;
        corspdReturnPacket corspdRtrnPackPrintedDetails = new corspdReturnPacket();
        
            JSONGenerator generator = JSON.createGenerator(true);
            generator.writeStartObject();
            if ((countyName != null) && (countyName != ' ') && (countyName != '')){ 
                generator.writeObjectField('countyName',countyName); } else { generator.writeNullField('countyName') ; } 
        
            if (caseId != null && caseId !='' && caseId !=' '){ 
                T_SBSD_CASE__c caseRecord = [select Id From T_SBSD_CASE__C where Name =:caseId];
                String caseSfid = caseRecord.Id;
                generator.writeObjectField('caseId',caseSfid); } else { generator.writeNullField('caseId') ;}
        
            if (providerId != null && String.valueOf(providerId) !=''){ 
                String provrId = string.valueOf(providerId);
                T_CHATS_PROVR_STATUS__c provrRecord = [select Id From T_CHATS_PROVR_STATUS__c where Name =:provrId];
                String provrSfid = provrRecord.Id;
                generator.writeObjectField('providerId',provrSfid); } else { generator.writeNullField('providerId') ; }
        
            if ( correspondenceId != null && String.valueOf(correspondenceId) !=''){ 
                String strCorrId = string.valueOf(correspondenceId);
                generator.writeObjectField('correspondenceId', strCorrId);} else { generator.writeNullField('correspondenceId') ; }
        	if ( suppressIndicator != null && (suppressIndicator != ' ') && (suppressIndicator != '')){ 
                String suppressIndctor = string.valueOf(suppressIndicator);
                generator.writeObjectField('suppressIndicator', suppressIndctor);} else { generator.writeNullField('suppressIndicator') ; }
        
            if ( dateRequested != null){ generator.writeObjectField('dateRequested',dateRequested ); } else { generator.writeNullField('dateRequested') ; }
	    if ( dateRequestedEndRange != null){ generator.writeObjectField('dateRequestedEndRange',dateRequestedEndRange ); } else { generator.writeNullField('dateRequestedEndRange') ; }
            if ( datePrintedBeginDate != null){ generator.writeObjectField('datePrintedBeginDate',datePrintedBeginDate ); } else { generator.writeNullField('datePrintedBeginDate') ; }
            if ( datePrintedEndDate != null){ generator.writeObjectField('datePrintedEndDate',datePrintedEndDate ); } else { generator.writeNullField('datePrintedEndDate') ; }
	    if ((correspondenceType != Null) && (correspondenceType != ' ') && (correspondenceType != '')){ generator.writeObjectField('correspondenceType', correspondenceType);} else { generator.writeNullField('correspondenceType');}
            if ((correspondenceRecipientType != Null) && (correspondenceRecipientType != ' ') && (correspondenceRecipientType != '')){ generator.writeObjectField('correspondenceRecipientType', correspondenceRecipientType);} else { generator.writeNullField('correspondenceRecipientType');}
            if(!string.isEmpty(requestedBy)){
            	User getUserInfo = [SELECT Id,LastName,FirstName,Name FROM User where Id =:requestedBy];
            	userRequested = getUserInfo.FirstName + ' ' +getUserInfo.LastName;
            }
	    if (userRequested != null){ generator.writeObjectField('userRequested', userRequested);} else { generator.writeNullField('userRequested');}
            
	    generator.writeEndObject();
            String JSONString = generator.getAsString();
        try{
            
            Httprequest httpRequest = new Httprequest();
            Http http = new Http();
            HttpRequest.setHeader('Content-type', 'application/json');
            HttpRequest.setHeader('Accept', 'application/json');
            String sUrl = Label.printedCorrespondenceSearch;
            httpRequest.setEndpoint(sUrl); 
            httpRequest.setMethod('POST');
            httpRequest.setBody(JSONString);
            httpRequest.setTimeout(120000);
            Httpresponse httpResponse = http.send(httpRequest);
            
            if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){
                system.debug('Return status code -->' + httpResponse.getStatusCode());
                system.debug('httpResponse.getBody--'+httpResponse.getBody());
                if(httpResponse.getBody() != ''){
                    corspdRtrnPackPrintedDetails.payload = JSON.deserializeUntyped(httpResponse.getBody());     
                } 
            } else {
                system.debug('Return status code -->' + httpResponse.getStatusCode());
                system.debug('Return status  -->' + httpResponse.getStatus());
                CorspdError errorObj = new CorspdError();
                String responseJSON = httpResponse.getBody();
                errorObj.errorMsg = 'Webservice access exception--'+responseJSON;
                errorList.add(errorObj);
                ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodInfo);
            }
            
        } catch( CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in accessing webservice for Printed Correspondences : - ' + e.getMessage();
            errorList.add(errorObj);    
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);                                     
        }
        if(errorList.size() > 0){
            corspdRtrnPackPrintedDetails.returnStatus = 'Failure';
            corspdRtrnPackPrintedDetails.errorMessage = errorList;            
        }else{
            corspdRtrnPackPrintedDetails.returnStatus = 'Success';
        }
        return corspdRtrnPackPrintedDetails;
    }
    
    @auraEnabled
    public static corspdReturnPacket processCorspdDelete(List<String> lstCorspdId, List<T_DOC_RQ__c> listSearchResults){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdDelete'};
    	corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        list<corspdError> errorList = new list<corspdError>();
        list<T_DOC_RQ__c> corrListtoBeUpdtd = new list<T_DOC_RQ__c>();
        list<T_DOC_RQ__c> updatedCorrList = new list<T_DOC_RQ__c>();
        
        integer countOfRecordsInGenerated = [select count() from T_DOC_RQ__c where id In:lstCorspdId AND CDE_CORSPD_STATUS__c = 'Generated'];
        
        try{
            if(countOfRecordsInGenerated > 0){
                corspdRtrnPack.CountOfGeneratedRecordsInDelete = countOfRecordsInGenerated;
            }else {
                //Database.DeleteResult[] DR_Dels = Database.delete(lstCorspdId, true);
            	//update the status to Deleted instead of delelting the record from T_DOC_rq__c 
            	corrListtoBeUpdtd = [select id, CDE_CORSPD_STATUS__c from T_DOC_RQ__c where id in:lstCorspdId];
                if(corrListtoBeUpdtd != Null){
                    for(T_DOC_RQ__c eachCorrToBeDeleted : corrListtoBeUpdtd){
                        eachCorrToBeDeleted.CDE_CORSPD_STATUS__c = DELETED;
                        updatedCorrList.add(eachCorrToBeDeleted);
                    }
                    GenericDMLHandler.updateRecords(updatedCorrList,null);
                }
                
            	Integer j = 0;
            	while (j < listSearchResults.size()) {
                	if(  lstCorspdId.contains(listSearchResults.get(j).Id)) {
                    	listSearchResults.remove(j);
                	} else {
                    	j++;
                	}
            	}
            }
        }catch( CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in Method - correspondence list Delete  : - ' + e.getMessage();
            errorList.add(errorObj);   
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);                                      
        }                 
        if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;            
        }else{
            corspdRtrnPack.returnStatus = 'Success';
            corspdRtrnPack.payload = listSearchResults;
        }
        return corspdRtrnPack;        
    }
 @auraEnabled
    public static corspdReturnPacket corspdSuppressOrDeleteAction(List<String> lstCorspdId,String operation){
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        list<corspdError> errorList = new list<corspdError>();
        Map<String,T_Missing_Information_tracker__c> mitToUpdate = new Map<String,T_Missing_Information_tracker__c>();
        List<T_Missing_Information_tracker__c> mitUpdates = new List<T_Missing_Information_tracker__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdSuppress'};
        System.debug('processCorspdSuppress has been called');
        System.debug('processCorspdSuppress has been called'+lstCorspdId+ ' '+operation);
        for(T_Missing_Information_tracker__c mit :[select Id,Name,idn_corr_nam__c from T_Missing_Information_tracker__c 
                                                 WHERE idn_corr_nam__c IN:lstCorspdId]){
                                                     mitToUpdate.put(mit.idn_corr_nam__c,mit); 
                                                 }
        
        try{
            system.debug('processCorspdSuppress--');
            Httprequest httpRequest = new Httprequest();
            Http http = new Http();
            httpRequest.setHeader('Content-type', 'application/json');
            httpRequest.setHeader('Accept', 'application/json');
            String sUrl =Label.corspdSuppressOrDeleteAction;
            String corspdParams;
            String JSONStr;
            JSONGenerator generator = JSON.createGenerator(true);
            if(lstCorspdId.size() > 0 ) {
                	//generator.writeStartArray();
                    generator.writeStartObject();
                    generator.writeObjectField('corspdIds',lstCorspdId);
                    generator.writeObjectField('operation',operation);
                    
                    generator.writeEndObject();
               
                //generator.writeEndArray();
            }
            String JSONString = generator.getAsString();
            System.debug('#JSONString: '+JSONString);
            if(String.isNotEmpty(JSONString)){
                System.debug('#JSONString: '+JSONString);
                
                httpRequest.setEndpoint(sUrl); 
                httpRequest.setMethod('POST');
                httpRequest.setBody(JSONString);
                httpRequest.setTimeout(120000);
                system.debug('Endpoint -->' + sUrl );
                Httpresponse httpResponse = http.send(httpRequest);
                
                if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){
                    system.debug('c' + httpResponse);
                    system.debug('Return status code -->' + httpResponse.getStatusCode());
                    system.debug('httpResponse.getBody--'+httpResponse.getBody());
                    String responseJSON = httpResponse.getBody();
                    system.debug('Body --->'+httpResponse.getBody());
                    if(httpResponse.getBody() != ''){
                        //corspdRtrnPack.payload = JSON.deserializeUntyped(httpResponse.getBody());
                       // String responseJSON = httpResponse.getBody();
                    corspdRtrnPack.payload = JSON.deserializeUntyped(responseJSON);
                    system.debug('payload:'+corspdRtrnPack.payload);
                    }
                    for(string corid: lstCorspdId){
                        if(mitToUpdate.containsKey(corid) && new List<String>{'SUPPRESS','UNSUPPRESS'}.contains(operation)){
                            T_Missing_Information_tracker__c mit = mitToUpdate.get(corid);
                            mit.Suppressed__c = operation =='SUPPRESS'?'Yes':'No';
                            mitUpdates.add(mit);
                        }
                    }
                    if(!mitUpdates.isEmpty()){
                        GenericDMLHandler.updateRecords(mitUpdates, new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'corspdSuppressOrDeleteAction'});
                    }
                }else {
                    CorspdError errorObj = new CorspdError();
                    String responseJSON = httpResponse.getBody().remove('{').remove('}');
                    errorObj.errorMsg = Label.Correspondence_TimeOut_Exception;//'Webservice access exception--'+responseJSON;
                    errorList.add(errorObj);
                    ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodInfo);
                }
            }else{
                CorspdError errorObj = new CorspdError();
                errorObj.errorMsg = Label.Corpsd_No_Longer_Exist_Error;
                errorList.add(errorObj);
                corspdRtrnPack.returnStatus = 'Failure';
                corspdRtrnPack.errorMessage = errorList;            
            }
            
        }catch(CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in Method - correspondence list to Print :' + e.getMessage();
            errorList.add(errorObj);      
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo); 
        }
         if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;            
        }else{
            system.debug('returnStatus');
            corspdRtrnPack.returnStatus = 'Success';
            //corspdRtrnPack.targetUrl = Label.correspondenceTargetPdfServlet;
        }
        system.debug('corspdRtrnPack: '+corspdRtrnPack);
        return corspdRtrnPack; 
    }
    @auraEnabled
    public static corspdReturnPacket addPrintedDateToCorspdDate(String lstCorspdId,String alreadygenUrl,String fileName){
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        list<corspdError> errorList = new list<corspdError>();
       
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdSuppress'};
        System.debug('processCorspdSuppress has been called');
        System.debug('processCorspdSuppress has been called'+lstCorspdId+ ' '+alreadygenUrl+' '+fileName);
       //url,corspdId,userId,reqDate,language,corspdSfid,fileName
		T_DOC_RQ__c getCorspdSFId = new T_DOC_RQ__c();
          if(lstCorspdId != null){
                getCorspdSFId = [select Id, Name,isPrinted__c ,CreatedById, DTE_REQ__c, CDE_CORSPD_STATUS__c, cde_lang_doc__c from T_DOC_RQ__c WHERE Name =:lstCorspdId LIMIT 1];
            }
        try{
            system.debug('addPrintedDateToCorspdDate--');
            Httprequest httpRequest = new Httprequest();
            Http http = new Http();
            httpRequest.setHeader('Content-type', 'application/json');
            httpRequest.setHeader('Accept', 'application/json');
            String sUrl = Label.addPrintedDateToCorspdDate;
            String corspdParams;
            String JSONStr;
            JSONGenerator generator = JSON.createGenerator(true);
            if(lstCorspdId!=null || lstCorspdId!='') {
                	//generator.writeStartArray();
                    generator.writeStartObject();
                	generator.writeObjectField('url',alreadygenUrl);//need to check
                	generator.writeObjectField('corspdId',lstCorspdId);
                	generator.writeObjectField('userId',getCorspdSFId.CreatedById);//need to check
               		generator.writeObjectField('reqDate',getCorspdSFId.DTE_REQ__c);
                    	if(getCorspdSFId.cde_lang_doc__c != null){
                    	    generator.writeObjectField('language',getCorspdSFId.cde_lang_doc__c);	
                	}
                    generator.writeObjectField('corspdSfid',getCorspdSFId.Id);
                	generator.writeObjectField('fileName',fileName);//need to check
                    generator.writeEndObject();
               
                //generator.writeEndArray();
            }
            String JSONString = generator.getAsString();
            System.debug('#JSONString: '+JSONString);
            if(String.isNotEmpty(JSONString)){
                System.debug('#JSONString: '+JSONString);
                
                httpRequest.setEndpoint(sUrl); 
                httpRequest.setMethod('POST');
                httpRequest.setBody(JSONString);
                httpRequest.setTimeout(120000);
                system.debug('Endpoint -->' + sUrl );
                Httpresponse httpResponse = http.send(httpRequest);
                
                if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){
                    system.debug('c' + httpResponse);
                    system.debug('Return status code -->' + httpResponse.getStatusCode());
                    system.debug('httpResponse.getBody--'+httpResponse.getBody());
                    String responseJSON = httpResponse.getBody();
                    system.debug('Body --->'+httpResponse.getBody());
                    if(httpResponse.getBody() != ''){
                        //corspdRtrnPack.payload = JSON.deserializeUntyped(httpResponse.getBody());
                       // String responseJSON = httpResponse.getBody();
                    corspdRtrnPack.payload = JSON.deserializeUntyped(responseJSON);
                    system.debug('payload:'+corspdRtrnPack.payload);
                    }
                }else {
                    CorspdError errorObj = new CorspdError();
                    String responseJSON = httpResponse.getBody().remove('{').remove('}');
                    errorObj.errorMsg = Label.Correspondence_TimeOut_Exception;//'Webservice access exception--'+responseJSON;
                    errorList.add(errorObj);
                    ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodInfo);
                }
            }else{
                CorspdError errorObj = new CorspdError();
                errorObj.errorMsg = Label.Corpsd_No_Longer_Exist_Error;
                errorList.add(errorObj);
                corspdRtrnPack.returnStatus = 'Failure';
                corspdRtrnPack.errorMessage = errorList;            
            }
            
        }catch(CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in Method - correspondence list to Print :' + e.getMessage();
            errorList.add(errorObj);      
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo); 
        }
         if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;            
        }else{
            system.debug('returnStatus');
            corspdRtrnPack.returnStatus = 'Success';
            //corspdRtrnPack.targetUrl = Label.correspondenceTargetPdfServlet;
        }
        system.debug('corspdRtrnPack: '+corspdRtrnPack);
        return corspdRtrnPack; 
    }
    @auraEnabled
    public static corspdReturnPacket processCorspdPrint(List<String> lstCorspdId){
        system.debug('The List -->'+lstCorspdId);
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        list<corspdError> errorList = new list<corspdError>();
        List<T_DOC_RQ__c> lstCorspdSFId = new List<T_DOC_RQ__c>();
        List<T_Missing_Information_tracker__c> mits = new List<T_Missing_Information_tracker__c>(); 
        Set<String> corrNames = new Set<String>();
        List<T_DOC_RQ__c> lstCorspdDetailsToAssemble = new List<T_DOC_RQ__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdPrint'};
     	
        integer countOfRecordsInReqstdOrFailed = [select count() from T_DOC_RQ__c where id In:lstCorspdId AND (CDE_CORSPD_STATUS__c = 'Requested' OR CDE_CORSPD_STATUS__c = 'Failed' OR CDE_CORSPD_STATUS__c = 'Deleted')];
        if(lstCorspdId != Null){
            lstCorspdDetailsToAssemble = [select Id,Name,isPrinted__c, CreatedById, DTE_REQ__c,NME_CORSPD__c, cde_lang_doc__c from T_DOC_RQ__c where id In:lstCorspdId];
        }
        
        try{
            if(countOfRecordsInReqstdOrFailed > 0 ) {
                corspdRtrnPack.CountOfRequestedRecordsInPrint = countOfRecordsInReqstdOrFailed;
            }else {
                system.debug('The assemble reached');
                system.debug('lstCorspdDetailsToAssemble--'+lstCorspdDetailsToAssemble);
                Httprequest httpRequest = new Httprequest();
            	Http http = new Http();
            	httpRequest.setHeader('Content-type', 'application/json');
            	httpRequest.setHeader('Accept', 'application/json');
            	String sUrl = Label.correspondenceAssembleUrl;
            	String corspdParams;
	            String JSONStr;
    	        JSONGenerator generator = JSON.createGenerator(true);
        	    if(lstCorspdDetailsToAssemble.size() > 0 ) {
            	    generator.writeStartArray();
                    for(integer i = 0; i < lstCorspdDetailsToAssemble.size(); i++) {
                        if(lstCorspdDetailsToAssemble[i].NME_CORSPD__c=='CR107'){
                            corrNames.add(lstCorspdDetailsToAssemble[i].Name);
                        }
                    	generator.writeStartObject();
                    	generator.writeObjectField('corspdId',lstCorspdDetailsToAssemble[i].Name);
                        generator.writeObjectField('createdById',lstCorspdDetailsToAssemble[i].CreatedById);
                        generator.writeObjectField('dateRequested',lstCorspdDetailsToAssemble[i].DTE_REQ__c);
                    	generator.writeObjectField('corspdSFID',lstCorspdDetailsToAssemble[i].Id);
                    	if(lstCorspdDetailsToAssemble[i].cde_lang_doc__c != null){
                        	generator.writeObjectField('language',lstCorspdDetailsToAssemble[i].cde_lang_doc__c);    
                        }
                        if(lstCorspdDetailsToAssemble[i].isPrinted__c=='Yes'){
                            generator.writeObjectField('isPrinted',true);
                        }else{
                            generator.writeObjectField('isPrinted',false);
                        }
                        //generator.writeObjectField('userId',UserInfo.getUserId());
                    	generator.writeEndObject();
                	}
                	generator.writeEndArray();
            	}
            	String JSONString = generator.getAsString();
            	System.debug('#JSONString: '+JSONString);
                    
                if(String.isNotEmpty(JSONString)){
                    System.debug('#JSONString: '+JSONString);
                    
                    httpRequest.setEndpoint(sUrl); 
                    httpRequest.setMethod('POST');
                    httpRequest.setBody(JSONString);
                    httpRequest.setTimeout(120000);
                    system.debug('Endpoint -->' + sUrl );
                    Httpresponse httpResponse = http.send(httpRequest);
                    
                    if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){
                        //CCCAP-11835
                        List<T_Missing_Information_tracker__c> tempMits = [SELECT Id
                                                                           FROM T_Missing_Information_tracker__c 
                                                                           WHERE idn_corr_nam__c IN :corrNames 
                                                                           AND dte_prntd__c = NULL];
                        
                        for (T_Missing_Information_tracker__c record : tempMits) {
                            record.dte_prntd__c = System.today();
                            mits.add(record);
                        }                      
                        if (!mits.isEmpty()) {
                            GenericDMLHandler.updateRecords(mits, methodInfo, new List<String>{'dte_prntd__c'});
                        }
                        //end CCCAP-11835
                        system.debug('c' + httpResponse);
                        system.debug('Return status code -->' + httpResponse.getStatusCode());
                        system.debug('httpResponse.getBody--'+httpResponse.getBody());
                        String responseJSON = httpResponse.getBody();
                        system.debug('Body --->'+httpResponse.getBody());
                        if(httpResponse.getBody() != ''){
                            corspdRtrnPack.payload = JSON.deserializeUntyped(httpResponse.getBody());     
                        }
                    }else {
                        CorspdError errorObj = new CorspdError();
                        String responseJSON = httpResponse.getBody().remove('{').remove('}');
                        errorObj.errorMsg = Label.Correspondence_TimeOut_Exception;//'Webservice access exception--'+responseJSON;
                        errorList.add(errorObj);
                        ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodInfo);
                    }
                }else{
                    CorspdError errorObj = new CorspdError();
                    errorObj.errorMsg = Label.Corpsd_No_Longer_Exist_Error;
                    errorList.add(errorObj);
                    corspdRtrnPack.returnStatus = 'Failure';
                    corspdRtrnPack.errorMessage = errorList;            
                }
        	}
        }catch( CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in Method - correspondence list to Print :' + e.getMessage();
            errorList.add(errorObj);      
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);                                   
        }
        if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;            
        }else{
            corspdRtrnPack.returnStatus = 'Success';
            corspdRtrnPack.targetUrl = Label.correspondenceTargetPdfServlet;
        }
        return corspdRtrnPack; 
    }
   
    @auraEnabled
    public static corspdReturnPacket processCorspdQueueToView(String corspdId){
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        
        T_DOC_RQ__c getCorspdSFId = new T_DOC_RQ__c();
        List<T_Missing_Information_tracker__c> mits = new List<T_Missing_Information_tracker__c>();
        list<corspdError> errorList = new list<corspdError>();
        JSONGenerator generator = JSON.createGenerator(true);
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdQueueToView'};
            
            if(corspdId != null){
                getCorspdSFId = [select Id,Name,isPrinted__c, CreatedById, DTE_REQ__c, CDE_CORSPD_STATUS__c, cde_lang_doc__c from T_DOC_RQ__c WHERE Name =:corspdId LIMIT 1];
                mits = [select Id,Name,dte_prntd__c from T_Missing_Information_tracker__c WHERE idn_corr_nam__c =:corspdId and dte_prntd__c = null LIMIT 1];
            }
        try{
            
            if(getCorspdSFId.CDE_CORSPD_STATUS__c == 'Generated'){
                corspdRtrnPack.CorrespondenceAlreadyGenerated = true;
                if(getCorspdSFId.cde_lang_doc__c !=null){
                	corspdRtrnPack.CorrespondenceFileName = getCorspdSFId.Name+'_'+getCorspdSFId.cde_lang_doc__c+'.pdf';    
                } else {
                	corspdRtrnPack.CorrespondenceFileName = getCorspdSFId.Name+'.pdf';    
                }  
                if(getCorspdSFId.DTE_REQ__c != null){
                    corspdRtrnPack.dateRequested=getCorspdSFId.DTE_REQ__c.format();
                }
                if(getCorspdSFId.isPrinted__c!=null){
                    corspdRtrnPack.isPrinted=getCorspdSFId.isPrinted__c;
                }
                if(!mits.isEmpty()){
                    mits[0].dte_prntd__c = Date.today();
                    GenericDMLHandler.updateRecords(mits, methodInfo);
                }
            } else {
                Httprequest httpRequest = new Httprequest();
                Http http = new Http();
                httpRequest.setHeader('Content-type', 'application/json');
                httpRequest.setHeader('Accept', 'application/json');
                String sUrl = Label.correspondenceGenerateUrl;
                String corspdParams;
                if(String.isNotBlank(getCorspdSFId.Id)){
                    corspdParams = 'corspdId='+ EncodingUtil.urlEncode(getCorspdSFId.Id,'UTF-8');
                }
                
                String userId = UserInfo.getUserId(); 
                corspdParams += '&userId='+EncodingUtil.urlEncode(userId,'UTF-8');
                
                generator.writeStartObject();
                generator.writeObjectField('corspdId',getCorspdSFId.Id);
                generator.writeObjectField('userId',userId);
                generator.writeObjectField('isBatch',false);
                generator.writeEndObject();
				String JSONString = generator.getAsString();
                //httpRequest.setEndpoint(sUrl + corspdParams);
                httpRequest.setEndpoint(sUrl);
                httpRequest.setBody(JSONString);
                httpRequest.setMethod('POST');
                httpRequest.setTimeout(120000);
                system.debug('Endpoint -->' + sUrl + corspdParams);
                Httpresponse httpResponse = http.send(httpRequest);
                
                system.debug('Return status code -->' + httpResponse.getStatusCode());
                system.debug('Return status  -->' + httpResponse.getStatus());
                system.debug('httpResponse.getBody--'+httpResponse.getBody());
                if(httpresponse !=NULL && httpResponse.getStatusCode() == 200){
                    system.debug('c' + httpResponse);
                    system.debug('Return status code -->' +httpResponse.getStatusCode());
                    system.debug('httpResponse.getBody--'+httpResponse.getBody());
                    String responseJSON = httpResponse.getBody();
                    corspdRtrnPack.payload = JSON.deserializeUntyped(responseJSON);
                    system.debug('payload:'+corspdRtrnPack.payload);
                    if(!mits.isEmpty()){
                        mits[0].dte_prntd__c = Date.today();
                        GenericDMLHandler.updateRecords(mits, methodInfo);
                    }
                } else if(httpresponse !=NULL && ((httpResponse.getStatusCode() == 200 && httpResponse.getBody()==null) || httpResponse.getStatusCode() == 503 || httpResponse.getStatusCode() == 400)){
                    CorspdError errorObj = new CorspdError();
                    errorObj.errorMsg = 'RETRY';//'Webservice access exception--'+responseJSON;
                    errorList.add(errorObj);
                }
                else {
                    CorspdError errorObj = new CorspdError();
                    String responseJSON = httpResponse.getBody().remove('{').remove('}');
                    errorObj.errorMsg = 'Webservice access exception--'+responseJSON;
                    errorList.add(errorObj);
                    ExceptionLoggingServices.captureExceptionLog(httpResponse, httpRequest, methodInfo);
                }
            }
        }catch(Exception e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in accessing server ' +e.getMessage();
            errorList.add(errorObj); 
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
        }	
        system.debug(errorList.size());
        system.debug(errorList);
        if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;
        }else{
            corspdRtrnPack.returnStatus = 'Success';
            corspdRtrnPack.targetUrl = Label.correspondenceTargetPdfServlet;
        }
        return corspdRtrnPack; 
    }
    
    @auraEnabled
    public static corspdReturnPacket getFileName (String corspdId) {
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
        T_PRNT_DTL__x[] prntdCorspdRcrd = [select idn_corr_nam__c, cde_lang_doc__c FROM T_PRNT_DTL__x WHERE idn_corr_nam__c =: corspdId LIMIT 1];
        List<T_Missing_Information_tracker__c> mits = new List<T_Missing_Information_tracker__c>();
        mits = [select Id,Name,dte_prntd__c from T_Missing_Information_tracker__c WHERE idn_corr_nam__c =:corspdId and dte_prntd__c = null LIMIT 1];
        if(prntdCorspdRcrd != NULL){
            corspdRtrnPack.payload = prntdCorspdRcrd;
        }
        if(!mits.isEmpty()){
            mits[0].dte_prntd__c = Date.today();
            GenericDMLHandler.updateRecords(mits, new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'getFileName'});
        }
        system.debug('The printed Correspondence record--'+corspdRtrnPack.payload);
        return corspdRtrnPack;
    }
    
    @AuraEnabled
    public static LightningServerResponse fetchUserdata(){
        Boolean isSuccessful = true;
        String message = '';
        Map<String,Object> objectData = new Map<String,Object>();
        //CCCAP-14993 checking for read only user in the UI
        //List<Profile> profiles = [select Name from profile where id = :Userinfo.getProfileId()];
        objectData.put('userProfileName', FeatureManagement.checkPermission('Read_Only_User'));
        objectData.put('userName', Userinfo.getUserName());
        return new LightningServerResponse(isSuccessful,message, objectData);
    }
    
    @AuraEnabled
    public static Map<String, Object> fetchUserCounties(){
        list<Integer> userCounties = new list<Integer>();
        set<Id> userCountyIDs = new set<Id>();
        User user = [SELECT Profile.Name, Owner_County__c, Common_County__c 
                       FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if(user.Owner_County__c != null)
        	userCounties.add(Integer.valueOf(user.Owner_County__c));
        if(user.Common_County__c != null){
            List<String> commonCountyValues = user.Common_County__c.split(';');
            for(String countyValue : commonCountyValues){
                if(String.isNotBlank(countyValue)){
                    userCounties.add(Integer.valueOf(countyValue));
                }
            }
        }
        List<T_COUNTY__c> counties = [SELECT Name FROM T_COUNTY__c WHERE CDE_COUNTY__c IN :userCounties];
        
        Map<String, Object> responseMap = new Map<String, Object>();
        string allUserCounties = '';
        for(T_COUNTY__c county : counties){
            allUserCounties += county.Name+';'; 
            userCountyIDs.add(county.Id);
        }
        responseMap.put('allUserCounties', allUserCounties);
        responseMap.put('countyIdSet',userCountyIDs);
        //CCCAP-14933 replacing using custom permission
        responseMap.put('adminUser', (FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')));
        return responseMap;
    }
}