public class ViewCaseParentFeeApxCtrl {
    
    @AuraEnabled
    public static LightningServerResponse getParentFeeData(String caseId, String month, Integer year,String caseParentFeeAmt){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        Boolean isEditable = false, isDeletable = true,isAuthCopayEditable =true;
        //String profileName = [Select Name from Profile where Id =: UserInfo.getProfileId() Limit 1].Name; Replaced using custom permission CCCAP-14993
        Boolean isNotReadOnlyUser =true;
        Date todayDateVal = system.today();
        Integer currentMonth = todayDateVal.month();
        Integer todayYearVal = System.today().year();
        try{
            //Using Custom Permission CCCAP-14993
            if(FeatureManagement.checkPermission('Read_Only_User') || FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor')
            || FeatureManagement.checkPermission('Business_Office_Worker')|| FeatureManagement.checkPermission('Business_Office_Supervisor')|| FeatureManagement.checkPermission('Provider_Worker')|| FeatureManagement.checkPermission('Provider_Worker_Supervisor')){
                isNotReadOnlyUser=false;
            }
            
            List<T_SBSD_CASE__c> cases = [SELECT IDN_EXTNL__c,CLOSED_CASES_STATUS__c FROM T_SBSD_CASE__c WHERE Id=:caseId];
            if(!cases.isEmpty()){
                 if(cases[0].CLOSED_CASES_STATUS__c >0){
                    isNotReadOnlyUser=false;
                }
                objectData.put('isNotReadOnlyUser',isNotReadOnlyUser);
                HttpResponse response = ParentFeeFlowWSCaller.callSearchParentFeeWS(cases.get(0).IDN_EXTNL__c,month, year,null,caseParentFeeAmt);
                if(response.getStatusCode()==200){
                    System.debug(response.getBody());
                    Map<String,Object> caseParentFeeDetails = ParentFeeFlowIntegrator.getCaseParentFeeDetails(response.getBody());
                    if(caseParentFeeDetails.containsKey('caseCopayId') && caseParentFeeDetails.get('caseCopayId')!=null){
                        if(caseParentFeeDetails.containsKey('isDeletable')){
                            isDeletable  = (Boolean)caseParentFeeDetails.get('isDeletable');
                        }
                        objectData.put('caseParentFeeDetails',caseParentFeeDetails);
                        List<ParentFeeAllocationWrapper> caseParentFeeAllocations = ParentFeeFlowIntegrator.getCaseParentFeeAllocations(response.getBody());
                        //CCCAP-917 Start - hyperlink logic to Auth on view case parent fee screen
                        Set<String> authNames = new Set<String>();
                        Map<String,String> authNameToRecId = new Map<String,String>();
                        for(ParentFeeAllocationWrapper eachCaseParentFeeAllocation : caseParentFeeAllocations){
                            if(!string.isBlank(eachCaseParentFeeAllocation.authName)){
                                authNames.add(eachCaseParentFeeAllocation.authName);
                            }
                        }
                        for(T_AUTH__c eachAuth : [select Id , Name from T_AUTH__c where Name in :authNames]){
                            authNameToRecId.put(eachAuth.Name,eachAuth.Id);
                        }
                        if(!caseParentFeeAllocations.isEmpty()){
                            for(ParentFeeAllocationWrapper eachCaseParentFeeAllocation1 : caseParentFeeAllocations){
                            	if(!string.isBlank(eachCaseParentFeeAllocation1.authName) && authNameToRecId.containsKey(eachCaseParentFeeAllocation1.authName)){
                                	eachCaseParentFeeAllocation1.authRecId = authNameToRecId.get(eachCaseParentFeeAllocation1.authName);
                            	}
                        	}
                        }
                        system.debug('the new updated caseParentFeeAllocations ## '+caseParentFeeAllocations);
                        //CCCAP-917 End - hyperlink logic to Auth on view case parent fee screen
                        if(!caseParentFeeAllocations.isEmpty()){
                            isEditable = true;
                           /* for(ParentFeeAllocationWrapper authCopay:caseParentFeeAllocations){
                                if(authCopay.isEditable){
                                    isAuthCopayEditable = true;
                                    break;
                                }
                            }*/
                            if(todayYearVal>year || (todayYearVal == year && currentMonth>=Integer.valueOf(month)) || (FeatureManagement.checkPermission('Provider_Worker') || FeatureManagement.checkPermission('Provider_Worker_Supervisor')|| FeatureManagement.checkPermission('Business_Office_Supervisor')|| FeatureManagement.checkPermission('Business_Office_Worker')|| FeatureManagement.checkPermission('Fiscal_Worker')|| FeatureManagement.checkPermission('Fiscal_Worker_Supervisor')) ){// Replaced with custom permission CCCAP-14993
                                    isAuthCopayEditable = false;
                                } 
                            objectData.put('isAuthCopayEditable',isAuthCopayEditable);
                            objectData.put('caseParentFeeAllocations',caseParentFeeAllocations);
                            if(caseParentFeeDetails.containsKey('effectiveBeginDate')){
                                Date effectiveBeginDate = ParentFeeFlowIntegrator.convertDateJSONToDate((String)caseParentFeeDetails.get('effectiveBeginDate'));
                                Integer todayDate = System.today().day();
                                Integer todayMonth = System.today().month();
                                Integer todayYear = System.today().year();
                                if(todayYear>effectiveBeginDate.year() || (todayYear==effectiveBeginDate.year() && todayMonth>effectiveBeginDate.month()) || (todayYear==effectiveBeginDate.year() && todayMonth==effectiveBeginDate.month() && todayDate>effectiveBeginDate.day())){
                                    isEditable = false;
                                }                
                            }
                        }else{
                            objectData.put('title','No Data Found');
                            objectData.put('description','We could not find any active authorization and copay for the matched case parent fee.');
                        }
                    }else{
                        objectData.put('title','No Data Found');
                        objectData.put('description','We could not find any Case Parent Fee record for the selected month and year. Please select another month and year to see the Case Parent Fee Details.');
                    }
                }else{
     				objectData.put('xLog',getXLog('getParentFeeData',null,'Web Service', 'caseId:'+caseId+',month:'+month+',year:'+year, response.getBody()));
                    objectData.put('title','Something unexpected happened!!');
                    objectData.put('description',response.getBody());
                }                
            }else{
                objectData.put('title','No Case Found!!');
                objectData.put('description','This Case is no longer available in the system.');
            }
        }catch(Exception ex){
            isEditable = false;
            isDeletable = false;
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
     		objectData.put('xLog',getXLog('getParentFeeData',ex.getMessage(),ex.getTypeName(), 'caseId:'+caseId+',month:'+month+',year:'+year, null));
        }
        objectData.put('isEditable',isEditable);
        objectData.put('isDeletable',isDeletable);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse updateParentFeeData(String caseParentFeeAllocationsJSON,String month, Integer year){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        Date todayDateVal = system.today();
        Integer currentMonth = todayDateVal.month();
        Integer todayYearVal = System.today().year();
        Date effectiveDate;
        if(currentMonth == Integer.valueOf(month) && year == todayYearVal){
            effectiveDate = system.today();
        }else if((year == todayYearVal && currentMonth < Integer.valueOf(month))||(year > todayYearVal)){
            effectiveDate = Date.newInstance(year,Integer.valueOf(month),1);
        }
        try{
            List<ParentFeeAllocationWrapper> caseParentFeeAllocations = (List<ParentFeeAllocationWrapper>)JSON.deserialize(caseParentFeeAllocationsJSON, List<ParentFeeAllocationWrapper>.class);
            System.debug('caseParentFeeAllocations:'+caseParentFeeAllocations);
            
            if(!caseParentFeeAllocations.isEmpty()){
                List<ParentFeeAllocationWrapper> caseParentFeeAllocationsToBeUpdated = new List<ParentFeeAllocationWrapper>();
                for(ParentFeeAllocationWrapper caseParentFeeAllocation:caseParentFeeAllocations){
                    if(String.isNotEmpty(caseParentFeeAllocation.authCopayExternalId)){
                        caseParentFeeAllocationsToBeUpdated.add(caseParentFeeAllocation);
                    }
                }
                if(!caseParentFeeAllocationsToBeUpdated.isEmpty()){
                    String bodyForcallAuthAmountCreateParentFeeWS = ParentFeeFlowIntegrator.getBodyForUpdateParentFeeWS(effectiveDate,caseParentFeeAllocationsToBeUpdated);
                    HttpResponse response = ParentFeeFlowWSCaller.callUpdateParentFeeWS(bodyForcallAuthAmountCreateParentFeeWS);
                    if(response.getStatusCode()!=200){
       					objectData.put('xLog',getXLog('updateParentFeeData',null,'Web Service', bodyForcallAuthAmountCreateParentFeeWS, response.getBody()));
                        objectData.put('title','Something unexpected happened!!');
                        objectData.put('description',response.getBody());
                    }else{
                        System.debug(response.getBody());
                        List<Object> data = (List<Object>)JSON.deserializeUntyped(response.getBody());
                        String errorMessage = '';
                        for(Object dataForEachResult:data){
                            Map<String,Object> mapDataForEachResult= (Map<String,Object>)dataForEachResult;
                            if(mapDataForEachResult.containsKey('successInd') && mapDataForEachResult.get('successInd')!='Y' && mapDataForEachResult.containsKey('errMessage') && mapDataForEachResult.get('errMessage')!=null){
                                errorMessage+=mapDataForEachResult.get('errMessage')+',';
                            }
                        }
                        if(String.isNotEmpty(errorMessage)){
                            errorMessage = errorMessage.removeEnd(',');
          					objectData.put('xLog',getXLog('updateParentFeeData',null,'Web Service', bodyForcallAuthAmountCreateParentFeeWS, 'Update failed:'+errorMessage));
                            objectData.put('title','Update Failed');
                            objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessage);
                        }
                    }
                }
            }
        }catch(Exception ex){
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            System.debug(ex.getLineNumber()+':'+ex.getMessage());
          	objectData.put('xLog',getXLog('updateParentFeeData',ex.getMessage(),ex.getTypeName(), 'caseParentFeeAllocationsJSON:'+caseParentFeeAllocationsJSON, null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    
    @AuraEnabled
    public static LightningServerResponse deleteParentFeeData(String caseCopayExternalId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        try{
            HttpResponse response = ParentFeeFlowWSCaller.callDeleteParentFeeWS('{"caseCopayId":'+caseCopayExternalId+'}');
            System.debug(response.getBody());
            if(response.getStatusCode()!=200){
          		objectData.put('xLog',getXLog('deleteParentFeeData',null,'Web Service', '{"caseCopayId":'+caseCopayExternalId+'}', response.getBody()));
                objectData.put('title','Something unexpected happened!!');
                objectData.put('description',response.getBody());
            }else{
                Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
                if(data.containsKey('errorMessage') && data.get('errorMessage')!=null){
            		objectData.put('xLog',getXLog('deleteParentFeeData',null,'Web Service', '{"caseCopayId":"'+caseCopayExternalId+'"}', 'Delete failed:'+data.get('errorMessage')));
                    objectData.put('title','Delete Failed');
                    objectData.put('description','We are not able to process your request at this moment.<br/>'+data.get('errorMessage'));
                }
            }
        }catch(Exception ex){
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            System.debug(ex.getLineNumber()+':'+ex.getMessage());
            objectData.put('xLog',getXLog('deleteParentFeeData',ex.getMessage(),ex.getTypeName(), '{"caseCopayId":"'+caseCopayExternalId+'"}', null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    
    @AuraEnabled
    public static LightningServerResponse createParentFeeData(String caseParentFeeAllocationsJSON,String effectiveBeginDateJSON,  String month,Integer year){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
         String currentMonthIndicator;
        try{
            Date effectiveBeginDate = ParentFeeFlowIntegrator.convertDateJSONToDate(effectiveBeginDateJSON);
            if(system.today().month() == Integer.valueOf(month)){
                currentMonthIndicator ='Y';
            }else{
                currentMonthIndicator ='N';
            }
            List<ParentFeeAllocationWrapper> caseParentFeeAllocations = (List<ParentFeeAllocationWrapper>)JSON.deserialize(caseParentFeeAllocationsJSON, List<ParentFeeAllocationWrapper>.class);
            System.debug('caseParentFeeAllocations:'+caseParentFeeAllocations);
            if(!caseParentFeeAllocations.isEmpty()){
                List<ParentFeeAllocationWrapper> caseParentFeeAllocationsToBeCreated = new List<ParentFeeAllocationWrapper>();
                for(ParentFeeAllocationWrapper caseParentFeeAllocation:caseParentFeeAllocations){
                 //   if(String.isEmpty(caseParentFeeAllocation.authCopayExternalId)){
                        caseParentFeeAllocationsToBeCreated.add(caseParentFeeAllocation);
                  //  }
                }
                if(!caseParentFeeAllocationsToBeCreated.isEmpty()){
                    String bodyForcallAuthAmountCreateParentFeeWS = ParentFeeFlowIntegrator.getBodyForCreateParentFeeWS(effectiveBeginDate,caseParentFeeAllocationsToBeCreated,'Y',currentMonthIndicator,month,String.valueOf(year));
                    HttpResponse response = ParentFeeFlowWSCaller.callCreateParentFeeWS(bodyForcallAuthAmountCreateParentFeeWS);
                    if(response.getStatusCode()!=200){
                        objectData.put('xLog',getXLog('createParentFeeData',null,'Web Service', bodyForcallAuthAmountCreateParentFeeWS, response.getBody()));
                        objectData.put('title','Something unexpected happened!!');
                        objectData.put('description',response.getBody());
                    }else{
                        System.debug(response.getBody());
                        List<Object> data = (List<Object>)JSON.deserializeUntyped(response.getBody());
                        String errorMessage = '';
                        for(Object dataForEachResult:data){
                            Map<String,Object> mapDataForEachResult= (Map<String,Object>)dataForEachResult;
                            if(mapDataForEachResult.containsKey('successInd') && mapDataForEachResult.get('successInd')!='Y' && mapDataForEachResult.containsKey('errMessage') && mapDataForEachResult.get('errMessage')!=null){
                                errorMessage+=mapDataForEachResult.get('errMessage')+',';
                            }
                        }
                        if(String.isNotEmpty(errorMessage)){
                            errorMessage = errorMessage.removeEnd(',');
                            objectData.put('xLog',getXLog('createParentFeeData',null,'Web Service', bodyForcallAuthAmountCreateParentFeeWS, 'Create failed:'+errorMessage));
                            objectData.put('title','Update Failed');
                            objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessage);
                        }
                    }
                }
            }
        }catch(Exception ex){
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            System.debug(ex.getLineNumber()+':'+ex.getMessage());
            objectData.put('xLog',getXLog('createParentFeeData',ex.getMessage(),ex.getTypeName(), 'effectiveBeginDateJSON:'+effectiveBeginDateJSON+',caseParentFeeAllocationsJSON:'+caseParentFeeAllocationsJSON, null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    
    public static Exception_Log__c getXLog(String methodName,String exceptionMessage,String exceptionType, String request, String response){
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'ViewCaseParentFeeApxCtrl';
        xLog.Method__c = methodName;
        xLog.Exception_Message__c = exceptionMessage;
        xLog.Exception_Type__c = exceptionType;
        xLog.Request__c = request; 
        xLog.Response__c = response;
        return xLog;
    }
}