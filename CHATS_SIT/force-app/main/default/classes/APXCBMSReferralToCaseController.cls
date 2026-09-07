public with sharing class APXCBMSReferralToCaseController {
    public static string OVERRIDECLIENTCLEARANCE = 'Override_Service';
    
    @AuraEnabled
    public static LightningServerResponse getInitDataChangeRef(String appProcessQueueId,String appProcessQueueIdNewRef){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String pending=Label.PEN;
        String message;
        Boolean hasPrimaryCaretaker = false;
        try{
            T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c,CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
            T_APPLN_PRCS_QUEUE__c appProcessQueueOld = [SELECT Id, IDN_APPLN__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueIdNewRef WITH SECURITY_ENFORCED];
            List<T_APPLN_INDIV__c> applicationIndividuals = [SELECT Id,NAM_LAST__c,NAM_FIRST__c,IDN_EXTNL__c,
                                                             NAM_MI__c,DTE_DOB__c,
                                                             NBR_SSN__c,CDE_GENDER__c,
                                                             IND_CRTKR_PRIM__c,IDN_STATE__c, 
                                                             IDN_SEQ_INDIV__c,
                                                             (SELECT id, CDE_TYPE_REL_INDIV__c, IDN_SEQ_INDIV_RELTD__c
                                                              FROM Application_Relationships__r) 
                                                             FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c WITH SECURITY_ENFORCED];
            List<T_APPLN_INDIV__c> applicationIndividualsOld = [SELECT Id,NAM_LAST__c,NAM_FIRST__c,IDN_EXTNL__c,
                                                                NAM_MI__c,DTE_DOB__c,
                                                                NBR_SSN__c,CDE_GENDER__c,
                                                                IND_CRTKR_PRIM__c,IDN_STATE__c, 
                                                                IDN_SEQ_INDIV__c,
                                                                (SELECT id, CDE_TYPE_REL_INDIV__c, IDN_SEQ_INDIV_RELTD__c
                                                                 FROM Application_Relationships__r) 
                                                                FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueueOld.IDN_APPLN__c and IND_CRTKR_PRIM__c='Y' WITH SECURITY_ENFORCED];
            Map<String,T_APPLN_INDIV__c> mapIndivSequenceToIndividual = new Map<String,T_APPLN_INDIV__c>();
            Map<String,String> mapIndivToRelationship = new Map<String,String>();
            String peakRefTable;
            String relationshipType;
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                mapIndivSequenceToIndividual.put(applnIndiv.IDN_EXTNL__c, applnIndiv);
            }
            ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
            List<String> CBMS_teenParentTypes = new List<String>{'MO','FA','HU','WI'};
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                if(applnIndiv.DTE_DOB__c!=null){
                    if(applnIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code){
                        hasPrimaryCaretaker = true;
                    }
                    for(T_APPLN_REL__c applnRel:applnIndiv.Application_Relationships__r){
                        peakRefTable = 'CBMS_REL';
                        if(applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                            peakRefTable+=applnIndiv.CDE_GENDER__c=='M'?'_M':(applnIndiv.CDE_GENDER__c=='F'?'_F':'');
                            relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                            mapIndivToRelationship.put(applnIndiv.IDN_EXTNL__c,relationshipType);
                        }
                    }
                }
            }
            objectData.put('hasPrimaryCaretaker',hasPrimaryCaretaker);
            
            if(appProcessQueue.CDE_STATUS_APPLN__c!=pending){
                appProcessQueue.CDE_STATUS_APPLN__c=pending;
                GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'getInitData','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
            }
            
            if(applicationIndividuals.isEmpty()){
                message = Label.No_Records_Found;
                isSuccessful = false;
            }else{
                objectData.put('mapIndivToRelationship',mapIndivToRelationship);
                objectData.put('applicationIndividuals',applicationIndividuals);
                objectData.put('applicationIndividualsOld',applicationIndividualsOld);
                objectData.put('appProcessQueueOld',appProcessQueueOld);
                objectData.put('appProcessQueue',appProcessQueue);
                isSuccessful = true;
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'getInitData'});             
            
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }  
    @AuraEnabled
    public static LightningServerResponse getAppAndRelatedChildDataChange(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        try{
            if(appProcessQueueId!=null){
                T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];

                //update the T_APPLN_PRCS_QUEUE                    
                //CDE_SOURCE = 'PEAK', IDN_CASE = IDN_CASE from the selected row, NUM_APPLN = PEAK Application Number; redirect to selected case
                appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'getAppAndRelatedChildDataChange','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
            }else{
                isSuccessful = false;
                message = Label.appProcessQueue_should_not_be_blank;
            }
        }catch(DMLException ex){
            isSuccessful = false;
            message = ex.getDMLMessage(0);
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'getAppAndRelatedChildDataChange'});             
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'getAppAndRelatedChildDataChange'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse handleRefCaseSelection(T_APPLN_PRCS_QUEUE__c appProcessQueue, List<String> individualIds,Id primaryCaretakerId){
        Savepoint sp = Database.setSavepoint();
        System.debug('appProcessQueue:'+appProcessQueue);
        Map<String, Object> objectData = new map<String, Object>();
        // added for UFE by Shashank 08/13/24
        List<UFEChangeInterface__e> ufeInfoUpdateEventList= new List<UFEChangeInterface__e>();
        Boolean isSuccessful = true;
        String message;
        try{
            if(appProcessQueue!=null){
                // added for UFE by Shashank 08/13/24
                Boolean isBCRequested = [select idn_appln__r.UFE_Request_Flag__c from T_APPLN_PRCS_QUEUE__c where id =:appProcessQueue.Id]?.idn_appln__r?.UFE_Request_Flag__c;
                if(String.isNotEmpty(appProcessQueue.IDN_CASE__c)){
                    List<T_SBSD_CASE__c> cseList= [Select id,IDN_CBMS_REF__c,CDE_CBMS_REF_TYP__c,DTE_APPLN__c from T_SBSD_CASE__c where id=:appProcessQueue.IDN_CASE__c WITH SECURITY_ENFORCED];
                    T_APPLN_PRCS_QUEUE__c appProcessQueue1 = [SELECT Id, IDN_APPLN__c, IDN_APPLN__r.NET_EARNED_INCOME__c, IDN_APPLN__r.CDE_CBMS_REF_TYP__c, IDN_APPLN__r.IDN_CBMS_REF__c,IDN_APPLN__r.UFE_Request_Flag__c, CDE_STATUS_APPLN__c, IDN_CASE__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueue.Id WITH SECURITY_ENFORCED]; 

					
LightningServerResponse lsr = ConvertCBMSDataToCHATS.converChangeReftData(cseList[0],appProcessQueue, individualIds,primaryCaretakerId);
                    //update the T_APPLN_PRCS_QUEUE                    
                    //CDE_SOURCE = 'PEAK', IDN_CASE = IDN_CASE from the selected row, NUM_APPLN = PEAK Application Number; redirect to selected case
                    appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                    GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
                    objectData.put('caseId',appProcessQueue.IDN_CASE__c);
                    cseList[0].IDN_CBMS_REF__c = appProcessQueue1.IDN_APPLN__r.IDN_CBMS_REF__c;
                    cseList[0].CDE_CBMS_REF_TYP__c = appProcessQueue1.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
                GenericDMLHandler.updateRecords(cseList, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'IDN_CBMS_REF__c','CDE_CBMS_REF_TYP__c'}); // Added IDN_CBMS_REF__c and CDE_CBMS_REF_TYP__c as part of CCCAP-8307
                    message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue.Id;
                    // added for UFE by Shashank 08/13/24
                    if(isBCRequested == true){
                        ufeInfoUpdateEventList.add(new UFEChangeInterface__e(IdNumber__c=appProcessQueue.IDN_CASE__c,Type__c='case'));
                        Eventbus.publish(ufeInfoUpdateEventList);                    
                    }
                }
            }else{
                isSuccessful = false;
                message = Label.appProcessQueue_should_not_be_blank;
                Database.rollback(sp);
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'handleCaseSelection'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
   
    @AuraEnabled
    public static LightningServerResponse checkIfAppHasPrimaryCaretaker(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c, County_Name__r.Name FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
        if(!appProcessQueue.isEmpty()){
            if([SELECT count() from T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.get(0).IDN_APPLN__c AND IND_CRTKR_PRIM__c='Y']==0){
                objectData.put('hasPrimaryCaretaker',false);
            }else{
                objectData.put('hasPrimaryCaretaker',true);
            }
            objectData.put('countyName',appProcessQueue[0].County_Name__r.Name);
        }else{
            message =  'This application doesn\'t exist';
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful,null,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse checkStateIdExisting(String stateId){
        Map<String, Object> objectData = new map<String, Object>();
        List<T_SBSD_INDIV__c> existingIndividuals = [SELECT Id FROM T_SBSD_INDIV__c WHERE IDN_STATE__c = :stateId WITH SECURITY_ENFORCED];
        if(existingIndividuals.isEmpty()){
            objectData.put('stateIdExisting',false);
        }else{
            objectData.put('stateIdExisting',true);
        }
        return new LightningServerResponse(true,null,objectData);
    } 
    
    public static LightningServerResponse checkCountyMatch(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        //Removed unused variable on 5/13/2018 BG         
        String message;
        String showConfirmMessage=Label.showConfirmMessage;
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, County_Name__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
        if(appProcessQueue.isEmpty()){
            objectData.put(showConfirmMessage,false);
        }else{
            try{
                Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(appProcessQueue.get(0).County_Name__c);
                if(!countyMatched){
                    objectData.put(showConfirmMessage,true);
                }else{
                    objectData.put(showConfirmMessage,false);
                }
            }catch(Exception ex){
                System.debug(ex.getMessage());
                objectData.put(showConfirmMessage,true);
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'checkCountyMatch'});             
            }
        }        
        return new LightningServerResponse(true,message,objectData);
    }  
    
    @AuraEnabled
    public static LightningServerResponse getIndividualDetails(String recordId){
        List<T_SBSD_INDIV__c> individuals = [SELECT Id, NAM_LAST__c, NAM_FIRST__c, NAM_MI__c, DTE_DOB__c, NBR_SSN__c , toLabel(CDE_GENDER__c) , IDN_STATE__c FROM T_SBSD_INDIV__c WHERE Id=:recordId WITH SECURITY_ENFORCED];
        if(!individuals.isEmpty()){
            try{
                LightningServerResponse lsr = findIndividualMatches(individuals.get(0).NAM_FIRST__c, individuals.get(0).NAM_LAST__c, individuals.get(0).NAM_MI__c, String.valueOf(individuals.get(0).DTE_DOB__c),individuals.get(0).NBR_SSN__c,individuals.get(0).CDE_GENDER__c);
                lsr.objectData.put('individual',individuals.get(0));
                return lsr;
            }catch(Exception e){
                Map<String,Object> exceptionMap = new Map<String,Object>();
                exceptionMap.put('Class__c','APXPeakApplicationToCaseController');    
                exceptionMap.put('Method__c','getIndividualDetails');            
                ExceptionLoggingServices.captureExceptionLog(e, exceptionMap);
            }
        }
        return new LightningServerResponse(false,Label.Record_not_found,null);
    }    
    
    @AuraEnabled
    public static LightningServerResponse getInitData(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String pending=Label.PEN;
        String message;
        Boolean hasPrimaryCaretaker = false;
        try{
            T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
            List<T_APPLN_INDIV__c> applicationIndividuals = [SELECT Id,NAM_LAST__c,NAM_FIRST__c,IDN_EXTNL__c,
                                                             NAM_MI__c,DTE_DOB__c,
                                                             NBR_SSN__c,CDE_GENDER__c,
                                                             IND_CRTKR_PRIM__c,IDN_STATE__c, 
                                                             IDN_SEQ_INDIV__c,
                                                             (SELECT id, CDE_TYPE_REL_INDIV__c, IDN_SEQ_INDIV_RELTD__c
                                                              FROM Application_Relationships__r) 
                                                             FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c WITH SECURITY_ENFORCED];
            Map<String,T_APPLN_INDIV__c> mapIndivSequenceToIndividual = new Map<String,T_APPLN_INDIV__c>();
            Map<String,String> mapIndivToRelationship = new Map<String,String>();
            String peakRefTable;
            String relationshipType;
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                mapIndivSequenceToIndividual.put(applnIndiv.IDN_EXTNL__c, applnIndiv);
            }
            ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
            List<String> CBMS_teenParentTypes = new List<String>{'MO','FA','HU','WI'};
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                if(applnIndiv.DTE_DOB__c!=null){
                    if(applnIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code){                        
                        hasPrimaryCaretaker = true;
                    }
                    for(T_APPLN_REL__c applnRel:applnIndiv.Application_Relationships__r){
                        peakRefTable = 'CBMS_REL';
                        if(applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                            peakRefTable+=applnIndiv.CDE_GENDER__c=='M'?'_M':(applnIndiv.CDE_GENDER__c=='F'?'_F':'');
                                relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                            mapIndivToRelationship.put(applnIndiv.IDN_EXTNL__c,relationshipType);
                        }
                    }
                }
            }
            objectData.put('hasPrimaryCaretaker',hasPrimaryCaretaker);
            if(appProcessQueue.CDE_STATUS_APPLN__c!=pending){
                appProcessQueue.CDE_STATUS_APPLN__c=pending;
                GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'getInitData','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
            }
            
            if(applicationIndividuals.isEmpty()){
                message = Label.No_Records_Found;
                isSuccessful = false;
            }else{
                objectData.put('mapIndivToRelationship',mapIndivToRelationship);
                objectData.put('applicationIndividuals',applicationIndividuals);
                objectData.put('appProcessQueue',appProcessQueue);
                isSuccessful = true;
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'getInitData'});             
            
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    
    @AuraEnabled
    public static LightningServerResponse getCaseSelectionData(String appProcessQueueId){
        LightningServerResponse resp;
        Boolean isSuccessful;
        String message;
        Boolean hasOtherIndividuals = false;
        List<T_APPLN_INDIV__c> appIndividuals = new List<T_APPLN_INDIV__c>();
        try{
            T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
            T_APPLN_CASE__c appProcessCase = [select Id, IDN_CBMS_REF__c, CBMS_CASE_NUM__c, CDE_CBMS_REF_TYP__c from T_APPLN_CASE__c where Id =: appProcessQueue.IDN_APPLN__c WITH SECURITY_ENFORCED];
            List<T_APPLN_INDIV__c> applicationIndividuals = [SELECT Id,NAM_LAST__c,NAM_FIRST__c,IDN_EXTNL__c,
                                                             NAM_MI__c,DTE_DOB__c,
                                                             NBR_SSN__c,CDE_GENDER__c,
                                                             IND_CRTKR_PRIM__c,IDN_STATE__c, 
                                                             IDN_SEQ_INDIV__c,
                                                             (SELECT id, CDE_TYPE_REL_INDIV__c, IDN_SEQ_INDIV_RELTD__c
                                                              FROM Application_Relationships__r) 
                                                             FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c WITH SECURITY_ENFORCED];
            List<String> stateIds = new List<String>();
            Map<String,String> mapIndivToRelationship = new Map<String,String>();
            String peakRefTable;
            String relationshipType;
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                if(applnIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code){
                    stateIds.add(applnIndiv.IDN_STATE__c);
                } else {
                    hasOtherIndividuals = true;
                    appIndividuals.add(applnIndiv);
                    for(T_APPLN_REL__c applnRel:applnIndiv.Application_Relationships__r){
                        peakRefTable = 'CBMS_REL';
                        if(applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                            peakRefTable+=applnIndiv.CDE_GENDER__c=='M'?'_M':(applnIndiv.CDE_GENDER__c=='F'?'_F':'');
                                relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                            mapIndivToRelationship.put(applnIndiv.IDN_EXTNL__c,relationshipType);
                        }
                    }
                }
            }
            resp = findCaseAndPrimaryCaretakerDetails(stateIds);
            resp.objectData.put('hasOtherIndividuals', hasOtherIndividuals);
            resp.objectData.put('applicationIndividuals', appIndividuals);
            resp.objectData.put('referralTypeCheck', appProcessCase.CDE_CBMS_REF_TYP__c);
            resp.objectData.put('mapIndivToRelationship', mapIndivToRelationship);
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            resp = new LightningServerResponse(isSuccessful,message,new map<String, Object>());
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'getCaseSelectionData'});                         
        }
        return resp;
    }
    
    @AuraEnabled
    public static LightningServerResponse findCaseAndPrimaryCaretakerDetails(List<String> stateId){
        System.debug('stateId:'+stateId);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<T_SBSD_CASE_INDIV__c> lstCaseIndividual = new List<T_SBSD_CASE_INDIV__c>();
        Map<Id,String> mapCaseIdCaseStatus = new Map<Id,String>();
        if(stateId.size()!=0){
            lstCaseIndividual = [SELECT Id,IDN_CASE__c,IDN_CASE__r.Name,
                                 IDN_CLIENT__r.IDN_STATE__c,
                                 IDN_CLIENT__r.NAM_FIRST__c,
                                 IDN_CLIENT__r.NAM_LAST__c,
                                 IDN_CLIENT__r.DTE_DOB__c,
                                 IDN_CLIENT__r.NBR_SSN__c FROM T_SBSD_CASE_INDIV__c
                                 WHERE IDN_CLIENT__r.IDN_STATE__c IN:stateId AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                                WITH SECURITY_ENFORCED];
            message = Label.Case_Details_Found_Successfully;
            objectData.put('lstCaseIndividual',lstCaseIndividual);
            Set<Id> setCaseId = new Set<Id>();
            for(T_SBSD_CASE_INDIV__c caseIndivdual:lstCaseIndividual){
                setCaseId.add(caseIndivdual.IDN_CASE__c);
            }
            for(T_SBSD_CASE_STATUS_MODE__c caseStatusMode:[SELECT toLabel(CDE_STATUS_CASE__c),IDN_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:setCaseId AND DTE_BEGIN_EFFV__c <= TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY) WITH SECURITY_ENFORCED ORDER BY DTE_BEGIN_EFFV__c ASC]){
                mapCaseIdCaseStatus.put(caseStatusMode.IDN_CASE__c,caseStatusMode.CDE_STATUS_CASE__c);
            }
            objectData.put('mapCaseIdCaseStatus',mapCaseIdCaseStatus);
        }
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }

        @AuraEnabled
    public static LightningServerResponse handleReferralCaseSelection(Id appProcessQueueId, Id selectedCaseId, List<String> individualIds){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'APXCBMSReferralToCaseController','Method__c'=>'handleReferralCaseSelection'};
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> objectData = new map<String, Object>();
        // added for UFE by Shashank 08/13/24
        List<UFEChangeInterface__e> ufeInfoUpdateEventList= new List<UFEChangeInterface__e>();
        ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
        List<String> additionalAdultRels = new List<String>{'H', 'CLH', 'CLW', 'LIC', 'SO', 'W', 'X'}; //added for CCCAP-13633
        Boolean isSuccessful = true;
        String message;
        try{
            if(String.isNotEmpty(selectedCaseId)){
                T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c, IDN_APPLN__r.NET_EARNED_INCOME__c, IDN_APPLN__r.CDE_CBMS_REF_TYP__c, IDN_APPLN__r.IDN_CBMS_REF__c,IDN_APPLN__r.UFE_Request_Flag__c, CDE_STATUS_APPLN__c, IDN_CASE__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];                            
                List<T_SBSD_CASE__c> cseList = [Select id, CDE_CBMS_REF_TYP__c,DTE_APPLN__c from T_SBSD_CASE__c where id=:selectedCaseId];
                Boolean isBCRequested = appProcessQueue?.IDN_APPLN__r?.UFE_Request_Flag__c;  // added for UFE by Shashank 08/13/24
                appProcessQueue.IDN_CASE__c = selectedCaseId;
                appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'IDN_CASE__c','CDE_STATUS_APPLN__c'}); // Added IDN_CASE__c and CDE_STATUS_APPLN__c as part of CCCAP-8307
                objectData.put('caseId', appProcessQueue.IDN_CASE__c);

                //added for CCCAP-11083
                cseList[0].IDN_CBMS_REF__c = appProcessQueue.IDN_APPLN__r.IDN_CBMS_REF__c;
                GenericDMLHandler.updateRecords(cseList, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'IDN_CBMS_REF__c'}); // Added IDN_CBMS_REF__c as part of CCCAP-8307
                
                List<T_CBMS_ADDNL_INFO__c> tanfLst = [SELECT Id,DTE_BEGIN_EFFEV__c,CDE_FREQ_INCOME__c,AMT_TANF_INCOME_HH_GROSS__c,NME_CO_WORKER__c from T_CBMS_ADDNL_INFO__c where IDN_CASE_CHATS__c=:selectedCaseId   WITH SECURITY_ENFORCED order by createdDate DESC];                 
                // CCCAP-4430 CHANGES
                if(appProcessQueue.IDN_APPLN__r.NET_EARNED_INCOME__c != null){
                    if(tanfLst!= null && tanfLst.size()>0){
                        tanfLst[0].AMT_TANF_INCOME_HH_GROSS__c = appProcessQueue.IDN_APPLN__r.NET_EARNED_INCOME__c;
                        if(String.isBlank(tanfLst[0].CDE_FREQ_INCOME__c)){
                            tanfLst[0].CDE_FREQ_INCOME__c ='MON';
                        }
                        // CCCAP-4430 CHANGES ENDS
                    }
                    update tanfLst[0];
                }
                
                if(individualIds != null && !individualIds.isEmpty()){
                    set<string> existingCaseIndivs = new set<string>();
                    for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id,IDN_CASE__c,IDN_CLIENT__r.IDN_STATE__c 
                                                          FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :selectedCaseId WITH SECURITY_ENFORCED]){
                        existingCaseIndivs.add(caseIndiv.IDN_CLIENT__r.IDN_STATE__c);
                    }
                    
                    system.debug('existingCaseIndivs: '+existingCaseIndivs);
                    List<T_APPLN_INDIV__c> lstApplnIndiv = [SELECT Id, CDE_GENDER__c,CBMS_DENIAL_REASON__c,CDE_SOURCE_VRFYD_CITIZEN__c,CDE_VRFYD_CITIZEN__c,IDN_CBMS_CLIENT__c,IND_IPV__c,ROADMAP_CORR_ID__c,
                                                    CDE_LEVEL_GRADE_HGHST__c,
                                                    CDE_STATUS_MAR__c,
                                                    DTE_Death__c,// added for SIDMOD CCCAP-7695 by Shashank
                                                    IND_NOTIF_SIDMOD__c, // added for SIDMOD CCCAP-10315 by Shashank
                                                    DTE_DOB__c,
                                                    IDN_STATE__c,
                                                    NAM_FIRST__c,
                                                    NAM_LAST__c,
                                                    NAM_MI__c,
                                                    NBR_SSN__c,
                                                    CDE_INFO_CS__c,
                                                    IND_CTZN__c,
                                                    CDE_STATUS_MIL__c,
                                                    IND_CRTKR_PRIM__c,
                                                    IDN_SEQ_INDIV__c,
                                                    ( SELECT Id,
                                                     ADR_CITY__c,
                                                     ADR_LINE_1__c,
                                                     ADR_LINE_2__c,
                                                     ADR_STATE__c,
                                                     ADR_ZIP_EXTN__c,
                                                     ADR_ZIP_MAIN__c,
                                                     CDE_TYPE_ADR__c,
                                                     ADR_NAM__c
                                                     FROM Application_Addresses__r
                                                    ),
                                                    (SELECT CDE_RACE__c,CDE_ETNCTY__c FROM Application_Race_Information__r),
                                                    (SELECT id,CDE_TYPE_ACTV__c,DTE_BEGIN_ACTV_PRIM__c,DTE_END_ACTV_PRIM__c,External_ID__c,IDN_INDIVIDUAL__c FROM Application_Activities__r),
                                                    (SELECT id,IDN_INDIVIDUAL__c,IND_NEED_CHILD_CARE__c,NAM_FACILITY__c,DTE_BEGIN_EFFV__c,DTE_BEGIN_CARE__c,DTE_END_CARE__c FROM Application_Child_Cares__r),
                                                    (SELECT DTE_BEGIN_EFFV__c FROM Application_Job_Search__r),
                                                    (SELECT Id, CDE_TYPE_REL_INDIV__c, IDN_APPLN_REL__c, IDN_SEQ_INDIV_RELTD__c
                                                     FROM Application_Relationships__r
                                                    )
                                                    FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c AND Id IN:individualIds WITH SECURITY_ENFORCED];
                    //added for CCCAP-13633
                    Map<String,String> mapIndivToRelationship = new Map<String,String>();
                    String relationshipType, peakRefTable, gender;
                    for(T_APPLN_INDIV__c appIndiv:lstApplnIndiv){
                        for(T_APPLN_REL__c applnRel:appIndiv.Application_Relationships__r){
                            if(applnRel.CDE_TYPE_REL_INDIV__c !='SE'){
                                gender = appIndiv.CDE_GENDER__c;
                                peakRefTable = 'CBMS_REL';
                                peakRefTable += (gender=='M' || gender == 'F') ? ('_'+gender) : '';
                                relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                                mapIndivToRelationship.put(appIndiv.IDN_STATE__c, relationshipType);
                            }  
                        }
                    }
                    map<string, T_APPLN_INDIV__c> newAppIndivMap = new map<string, T_APPLN_INDIV__c>();
                    for(T_APPLN_INDIV__c appIndiv : lstApplnIndiv){
                        if(!existingCaseIndivs.contains(appIndiv.IDN_STATE__c)){
                            newAppIndivMap.put(appIndiv.IDN_STATE__c, appIndiv);
                        }
                    }
                    system.debug('newAppIndivMap: '+newAppIndivMap);
                    
                    Map<String, T_SBSD_INDIV__c> mapExistingIndiv = new Map<String, T_SBSD_INDIV__c>();
                    if(!newAppIndivMap.isEmpty()){
                        List<sObject> lstCaseChildRecords = new List<sObject>();
                        List<T_SBSD_CASE_INDIV__c> listCaseIndividual = new List<T_SBSD_CASE_INDIV__c>();
                        List<T_SBSD_INDIV_INFO__c> listIndividualInformation = new List<T_SBSD_INDIV_INFO__c>();
                        for(T_SBSD_INDIV__c indiv : [SELECT Id, IDN_STATE__c FROM T_SBSD_INDIV__c Where IDN_STATE__c IN :newAppIndivMap.keySet() WITH SECURITY_ENFORCED]){
                            T_SBSD_CASE_INDIV__c cIndiv = new T_SBSD_CASE_INDIV__c();
                            cIndiv.IDN_CLIENT__c = indiv.Id;
                            cIndiv.IDN_CASE__c = selectedCaseId;
                            if(Schema.sObjectType.T_SBSD_CASE_INDIV__c.fields.DTE_BEGIN_EFFV__c.isCreateable())
                                cIndiv.DTE_BEGIN_EFFV__c = cseList[0].DTE_APPLN__c;
                            if(Schema.sObjectType.T_SBSD_CASE_INDIV__c.fields.IND_CRTKR__c.isCreateable())
                                cIndiv.IND_CRTKR__c = newAppIndivMap.get(indiv.IDN_STATE__c).IND_CRTKR_PRIM__c=='Y'?true:false;
                            if(Schema.sObjectType.T_SBSD_CASE_INDIV__c.fields.INDIVIDUAL_STATUS__c.isCreateable())
                            cIndiv.INDIVIDUAL_STATUS__c = cIndiv.IND_CRTKR__c == true ?'PC':(mapIndivToRelationship.containsKey(indiv.IDN_STATE__c) && additionalAdultRels.contains(mapIndivToRelationship.get(indiv.IDN_STATE__c)) ? 'AC' : 'Child');
                            listCaseIndividual.add(cIndiv);
                            mapExistingIndiv.put(indiv.IDN_STATE__c, indiv);
                        }
                        
                        List<T_APPLN_INDIV__c> lstApplnIndivToBeConverted = new List<T_APPLN_INDIV__c>();
                        for(T_APPLN_INDIV__c appIndiv : lstApplnIndiv){
                            if(newAppIndivMap.containsKey(appIndiv.IDN_STATE__c) && !mapExistingIndiv.containsKey(appIndiv.IDN_STATE__c)){
                                System.debug('appIndiv not found in existing list:'+appIndiv);
                                if(String.isNotEmpty(appIndiv.NAM_MI__c)){
                                    appIndiv.NAM_MI__c =  appIndiv.NAM_MI__c.subString(0,1);
                                }
                                lstApplnIndivToBeConverted.add(appIndiv);
                            }
                        }
                        system.debug('lstApplnIndivToBeConverted: '+lstApplnIndivToBeConverted);
                        
                        Map<String,T_SBSD_INDIV__c> mapIndividual = new Map<String,T_SBSD_INDIV__c>();
                        set<String> roadmapCorrIdSet = new Set<String>();
                        Map<String,T_SBSD_ROADMAP_CORR_ID__c> mapindivStateIdToRoadmapCorr = new Map<String,T_SBSD_ROADMAP_CORR_ID__c>();
                        List<T_SBSD_ROADMAP_CORR_ID__c> lstOfexistingRoadmapIds = new List<T_SBSD_ROADMAP_CORR_ID__c>();
                        Map<String,String> mapOfExstngRoadmapIds = new Map<String,String>();
                        
                        if(!lstApplnIndivToBeConverted.isEmpty()){
                            for(SObject sOb : APXPolicyRecordsServices.createPolicyRecords(lstApplnIndivToBeConverted, false)){
                                if(sOb.getSObjectType() == Schema.T_SBSD_INDIV__c.getSObjectType()){
                                    sOb.put('Is_CBMS_Data__c',true);
                                    sOb.put('IND_CDE_TYPE_VERIF_DOB__c','V');
                                    sOb.put('CDE_SOURCE_VRFYD_DOB__c','TF');
                                    sOb.put('CDE_VRFYD_IDNTY__c','V');
                                    sOb.put('CDE_SOURCE_VRFYD_IDNTY__c','TF');
                                    // CBMS Case is required for Roadmap Correspondence PDF request
                                    if(String.isBlank(appProcessQueue.IDN_APPLN__r.IDN_CBMS_REF__c)) {
                                        sOb.put('CBMS_CASE_NUM__c', appProcessQueue.IDN_APPLN__r.IDN_CBMS_REF__c);
                                    }
                                    mapIndividual.put(String.valueOf(sOb.get('IDN_STATE__c')),(T_SBSD_INDIV__c)sOb);
                                }
                            }                    
                            
                            for(T_APPLN_INDIV__c applnIndiv : lstApplnIndivToBeConverted){
                                T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                                String raceType = '';
                                String ethnicityType = '';
                                // Ethnicity logic needs to be added like RACE
                                System.debug('###raceType:'+applnIndiv.Application_Race_Information__r);
                                for(T_APPLN_INDIV_RACE__c indivRace : applnIndiv.Application_Race_Information__r){
                                    System.debug('RaceValue:'+ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c));
                                    if(String.isNotEmpty(indivRace.CDE_RACE__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c) != null){
                                        raceType += ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', indivRace.CDE_RACE__c)+';';
                                    }
                                    if(String.isNotEmpty(indivRace.CDE_ETNCTY__c)  && ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE_E', indivRace.CDE_ETNCTY__c)!=null){
                                        ethnicityType = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE_E', indivRace.CDE_ETNCTY__c);
                                    }
                                }
                                if(String.isNotEmpty(raceType) && Schema.sObjectType.T_SBSD_INDIV__c.fields.CDE_RACE__c.isCreateable()){
                                    individual.CDE_RACE__c = raceType;
                                }
                                if(String.isNotEmpty(ethnicityType) && Schema.sObjectType.T_SBSD_INDIV__c.fields.CDE_ETNCTY__c.isCreateable()){
                                    individual.CDE_ETNCTY__c = ethnicityType;
                                }
                                if(Schema.sObjectType.T_SBSD_INDIV__c.fields.CDE_SOURCE_VRFYD_CITIZEN__c.isCreateable())
                                    individual.CDE_SOURCE_VRFYD_CITIZEN__c = 'TF';
                                mapIndividual.put(applnIndiv.IDN_STATE__c,individual);
                                roadmapCorrIdSet.add(applnIndiv.ROADMAP_CORR_ID__c);
                            }
                            GenericDMLHandler.insertRecords(mapIndividual.values(), methodInfo);
                            
                            if(roadmapCorrIdSet != null){
                                lstOfexistingRoadmapIds = [select Id, INDIVIDUAL__c, INDIVIDUAL__r.IDN_STATE__c, ROADMAP_CORR_ID__c	 FROM T_SBSD_ROADMAP_CORR_ID__c where ROADMAP_CORR_ID__c IN:roadmapCorrIdSet WITH SECURITY_ENFORCED];
                                if(lstOfexistingRoadmapIds != null){
                                    for(T_SBSD_ROADMAP_CORR_ID__c eachExstngRoadmapId : lstOfexistingRoadmapIds){
                                        mapOfExstngRoadmapIds.put(eachExstngRoadmapId.INDIVIDUAL__r.IDN_STATE__c, eachExstngRoadmapId.ROADMAP_CORR_ID__c);
                                    }
                                }
                            }
                            
                            for(T_APPLN_INDIV__c applnIndiv : lstApplnIndivToBeConverted){
                                if(mapIndividual.containsKey(applnIndiv.IDN_STATE__c)){
                                    T_SBSD_INDIV__c individual = mapIndividual.get(applnIndiv.IDN_STATE__c);
                                    System.debug('individual:'+individual);
                                    System.debug('Milatry Status'+applnIndiv.CDE_STATUS_MIL__c);
                                    System.debug('Converted status:'+ConversionPicklistMappingUtility.translatePEAKToCHATSData('TMLT', applnIndiv.CDE_STATUS_MIL__c));
                                    lstCaseChildRecords.add(new T_SBSD_INDIV_MIL__c(IDN_CLIENT__c = individual.Id,CDE_STATUS_MIL__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TMLT', applnIndiv.CDE_STATUS_MIL__c)));
                                    if(applnIndiv.ROADMAP_CORR_ID__c != null ){
                                        if(mapOfExstngRoadmapIds.containsKey(applnIndiv.IDN_STATE__c) && mapOfExstngRoadmapIds.get(applnIndiv.IDN_STATE__c) == applnIndiv.ROADMAP_CORR_ID__c){
                                            
                                        } else {
                                            T_SBSD_ROADMAP_CORR_ID__c chatsIndivRoadmapCorr = new T_SBSD_ROADMAP_CORR_ID__c(APPLICATION_PROCESS_QUEUE__c = appProcessQueue.Id,  IDN_CASE__c = selectedCaseId, 
                                                                                                                            CBMS_CASE_NUM__c = appProcessQueue.IDN_APPLN__r.CBMS_CASE_NUM__c, DATE_RECEIVED__c = appProcessQueue.DTE_RCVD_APPLN__c,
                                                                                                                            INDIVIDUAL__c = individual.Id, ROADMAP_CORR_ID__c = applnIndiv.ROADMAP_CORR_ID__c);
                                            mapindivStateIdToRoadmapCorr.put(applnIndiv.IDN_STATE__c, chatsIndivRoadmapCorr);
                                        }
                                    }
                                    
                                    for(T_APPLN_JOB_SEARCH__c applnJobSearch : applnIndiv.Application_Job_Search__r){
                                        lstCaseChildRecords.add(new T_JOB_SEARCH__c(IDN_CLIENT__c = individual.Id,DTE_BEGIN_EFFV__c = applnJobSearch.DTE_BEGIN_EFFV__c, Ignore__c = true));
                                    }
                                    for(T_APPLN_ACTIVITY__c applnActivity : applnIndiv.Application_Activities__r){
                                        String activityType = ConversionPicklistMappingUtility.translatePEAKToCHATSData('TRAE', applnActivity.CDE_TYPE_ACTV__c);
                                        lstCaseChildRecords.add(new T_PRIM_ACTV__c(IDN_CLIENT__c = individual.Id,IDN_CASE__c = selectedCaseId,DTE_BEGIN_ACTV_PRIM__c = applnActivity.DTE_BEGIN_ACTV_PRIM__c, DTE_END_ACTV_PRIM__c = applnActivity.DTE_END_ACTV_PRIM__c,CDE_TYPE_ACTV__c=activityType,Is_CBMS_Data__c =true));
                                    }
                                    
                                    T_SBSD_CASE_INDIV__c caseIndividual = new T_SBSD_CASE_INDIV__c(IDN_CASE__c = selectedCaseId, IDN_CLIENT__c = individual.Id, IND_CRTKR__c = applnIndiv.IND_CRTKR_PRIM__c=='Y'?true:false, DTE_BEGIN_EFFV__c = cseList[0].DTE_APPLN__c);
                                    caseIndividual.INDIVIDUAL_STATUS__c = caseIndividual.IND_CRTKR__c == true ? 'PC':( mapIndivToRelationship.containsKey(applnIndiv.IDN_STATE__c) && additionalAdultRels.contains(mapIndivToRelationship.get(applnIndiv.IDN_STATE__c)) ? 'AC' : 'Child');
                                    listCaseIndividual.add(caseIndividual);
                                    
                                    T_SBSD_INDIV_INFO__c indivInfo = new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = individual.Id,CDE_TYPE_INFO_INDIV__c = 'CS', CDE_VALUE_INFO_INDIV__c = (caseIndividual.INDIVIDUAL_STATUS__c =='PC' || caseIndividual.INDIVIDUAL_STATUS__c == 'AC') ? 'N/A-adult caretaker' : (applnIndiv.IND_CTZN__c=='Y'?'CZN':applnIndiv.IND_CTZN__c=='N'?'NCZ':null));
                                    listIndividualInformation.add(indivInfo);
                                }
                            }
                        }
                        System.debug('####lstCaseChildRecords'+lstCaseChildRecords);
                        if(!lstCaseChildRecords.isEmpty()){
                            // To avoid System.TypeException: Cannot have more than 10 chunks in a single operation.
                            lstCaseChildRecords.sort();
                            GenericDMLHandler.insertRecords(lstCaseChildRecords, methodInfo);
                            APXPolicyRecordsServices.createRefData(appProcessQueue.IDN_APPLN__r.IDN_CBMS_REF__c, appProcessQueue.IDN_APPLN__r.CDE_CBMS_REF_TYP__c, lstCaseChildRecords);                           
                        }
                        if(!listCaseIndividual.isEmpty()){
                            GenericDMLHandler.insertRecords(listCaseIndividual, methodInfo);
                        }
                        if(!listIndividualInformation.isEmpty()){
                            GenericDMLHandler.insertRecords(listIndividualInformation, methodInfo);
                        }
                        if(!mapindivStateIdToRoadmapCorr.isEmpty()){
                            GenericDMLHandler.insertRecords(mapindivStateIdToRoadmapCorr.values(), methodInfo);
                        }
                        // added for UFE by Shashank 08/13/24
                         if(isBCRequested == true){
                            ufeInfoUpdateEventList.add(new UFEChangeInterface__e(IdNumber__c=appProcessQueue.IDN_CASE__c,Type__c='case'));
                            Eventbus.publish(ufeInfoUpdateEventList);                    
                        }
                    }
                }
                message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue.Id;    
                                                 
            }else{
                isSuccessful = false;
                message = Label.appProcessQueue_should_not_be_blank;
                Database.rollback(sp);
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse findIndividualMatches(String fName, String lName, String MI, String dob,String ssn,String gndr){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        System.debug('fname:'+fName);
        System.debug('lName:'+lName);
        system.debug(dob);
        system.debug(ssn);
        system.debug(gndr);
        //String soundexString = SoundexUtil.toSoundex(fName + '_' + lName);
        //String soundexString = (lName !=null ? SoundexUtil.toSoundex(lName).RightPad(6,'0') : '')+SoundexUtil.toSoundex(fName); // as per CHATS-2950
        String soundexValue = '';
        Boolean fnLnProvided = false;
        if((lName!=null && lName !='') && (fName != null && fName != '')){
            soundexValue = (lName !=null? SoundexUtil.toSoundex(lName).RightPad(6,'0'):'')+SoundexUtil.toSoundex(fName); 
            fnLnProvided = true;
        } else if((lName !=null && lName != '') && (fName == null || fName == '')){
            system.debug('soundexValue is:'+soundexValue);
            system.debug('FirstName is:'+fName);
            soundexValue =(lName !=null? SoundexUtil.toSoundex(lName).RightPad(6,'0'):'');
            fnLnProvided = false;
        } else if((lName ==null || lName == '') && (fName != null && fName != '')){
            system.debug('soundexValue is:'+soundexValue);
            system.debug('FirstName is:'+fName);
            soundexValue =SoundexUtil.toSoundex(fName);
            fnLnProvided = false;
        }
        if(soundexValue!=null && soundexValue!=''){
            soundexValue = soundexValue.replace('0', '_');
        }
        
        
        System.debug('soundexString:'+soundexValue);
        soundexValue = '%'+soundexValue+'%';
        List<T_SBSD_INDIV__c> lstMatchedCHATSIndividuals= [SELECT Id,Name, NAM_LAST__c,NAM_FIRST__c,NAM_MI__c,DTE_DOB__c,NBR_SSN__c,toLabel(CDE_GENDER__c),IDN_STATE__c FROM T_SBSD_INDIV__c WHERE (NBR_SSN__c = :ssn OR DTE_DOB__c=:Date.valueOf(dob)) AND TXT_SNDX__c Like :soundexValue AND IDN_STATE__c!=null AND IDN_STATE__c!=:Label.SIDMOD_STATE_ID_REQUIRED WITH SECURITY_ENFORCED];
        if(lstMatchedCHATSIndividuals.isEmpty()){
            message = Label.No_CHATS_Matched_Individual_Records_Found_for_dob+dob+',ssn:'+ssn;
        }else{
            objectData.put('lstMatchedCHATSIndividuals',lstMatchedCHATSIndividuals);
            message = Label.CHATS_Matched_Individual_Records_Found;
        }
        
        // Logic for fetching SIDMOD individuals
        List<object> lstMatchedSIDMODIndividuals = sidmodIntegrationWebservices.assignStateId(fName,lName,MI,dob,ssn,gndr);//sidmodIntegrationWebservices.GetClientClearance(fName,lName,MI,dob,ssn,gndr);
        system.debug('lstMatchedSIDMODIndividuals-->'+lstMatchedSIDMODIndividuals);
        //List<object> lstMatchedSIDMODIndividuals = new List<object>();
        if(lstMatchedSIDMODIndividuals.isEmpty()){
            //message = Label.No_SIDMOD_Matched_Individual_Records_Found;
            if(String.isNotEmpty(sidmodIntegrationWebservices.errorMessage)){
                //objectData.put('sidmodMessage',sidmodIntegrationWebservices.errorMessage);
                message = sidmodIntegrationWebservices.errorMessage;
            }
        }else{
            objectData.put('lstSIDMODMatchedIndividuals',lstMatchedSIDMODIndividuals);
            message = Label.SIDMOD_Matched_Individual_Records_Found;
        }
        if(sidmodIntegrationWebservices.errorMessage != Null){
            isSuccessful = false;    
        } else {
            isSuccessful = true;    
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse updateRecords(List<SObject> lstSObject){
        System.debug('lstSObject To Be Updated:'+lstSObject);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String, String> stateIdToRecordId = new Map<String, String>();
            Map<id, SObject> recordIdToRecord = new Map<Id, SObject>();
            
            List<SObject> recordsToBeUpdated = new List<SObject>();
            List<SObject> individualsHavingStateIds = new List<SObject>();
            
            for(SObject sOb:lstSObject){
                Id sObId = (Id)sOb.get('Id');
                if(String.valueOf(sObId.getSObjectType())=='T_APPLN_INDIV__c' || (String.valueOf(sObId.getSObjectType())=='T_SBSD_INDIV__c' && sOb.get('IDN_STATE__c')!=null && String.valueOf(sOb.get('IDN_STATE__c'))==Label.SIDMOD_STATE_ID_REQUIRED)){
                    recordsToBeUpdated.add(sOb);
                }else if(String.valueOf(sObId.getSObjectType())=='T_SBSD_INDIV__c' && sOb.get('IDN_STATE__c')!=null && String.valueOf(sOb.get('IDN_STATE__c'))!=Label.SIDMOD_STATE_ID_REQUIRED){
                    stateIdToRecordId.put((String)sOb.get('IDN_STATE__c'),(String)sOb.get('Id'));
                    recordIdToRecord.put((String)sOb.get('Id'),(T_SBSD_INDIV__c)sOb);
                    individualsHavingStateIds.add(sOb);
                } 
            }
            System.debug('recordIdToRecord:'+recordIdToRecord);
            System.debug('stateIdToRecordId:'+stateIdToRecordId);
            System.debug('recordsToBeUpdated:'+recordsToBeUpdated);
            
            if(!recordsToBeUpdated.isEmpty()){
                JunkRecordServices.deleteJunkRecordsByRecords(recordsToBeUpdated, false);         
                GenericDMLHandler.updateRecords(recordsToBeUpdated, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'},'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'});                        
                objectData.put('idToBeRedirected', recordsToBeUpdated.get(0).Id);
                isSuccessful = true;
            }else{
                Map<String,List<T_SBSD_CASE_INDIV__c>> newIndividualIdToCaseIndividual = new Map<String,List<T_SBSD_CASE_INDIV__c>>();
                //querying case individual records which got created as part of flow:-
                for(T_SBSD_CASE_INDIV__c caseIndividual:[SELECT IDN_CASE__c, INDIVIDUAL_STATUS__c, IND_CRTKR__c, IDN_CLIENT__c, DTE_BEGIN_EFFV__c,IDN_EXTNL__c  FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:stateIdToRecordId.values() WITH SECURITY_ENFORCED]){
                    List<T_SBSD_CASE_INDIV__c> existingCaseIndividuals;
                    if(newIndividualIdToCaseIndividual.containskey(caseIndividual.IDN_CLIENT__c)){
                        existingCaseIndividuals = newIndividualIdToCaseIndividual.get(caseIndividual.IDN_CLIENT__c);
                    }else{
                        existingCaseIndividuals = new List<T_SBSD_CASE_INDIV__c>();
                    }
                    existingCaseIndividuals.add(caseIndividual);
                    newIndividualIdToCaseIndividual.put(caseIndividual.IDN_CLIENT__c, existingCaseIndividuals);
                }
                System.debug('newIndividualIdToCaseIndividual:'+newIndividualIdToCaseIndividual);
                List<SObject> newRecordsToBeCreated = new List<SObject>();
                Set<Id> individualIdsToBeDeleted = new Set<Id>();
                
                //Querying existing individuals whose state id being used in clearing individual
                Boolean showExistingIndividualError = false;
                Map<String, String> newRecordIdToExistingRecordId = new Map<String, String>();
                for(T_SBSD_INDIV__c existingIndividual:[SELECT Id, IDN_STATE__c, (SELECT id, IDN_CASE__c,DTE_END_EFFV__c FROM Case_Individual__r) FROM T_SBSD_INDIV__c WHERE IDN_STATE__c IN:stateIdToRecordId.keySet() WITH SECURITY_ENFORCED]){
                    newRecordIdToExistingRecordId.put(stateIdToRecordId.get(existingIndividual.IDN_STATE__c), existingIndividual.Id);                    
                    individualIdsToBeDeleted.add(stateIdToRecordId.get(existingIndividual.IDN_STATE__c));
                    if(newIndividualIdToCaseIndividual.containsKey(stateIdToRecordId.get(existingIndividual.IDN_STATE__c))){
                        for(T_SBSD_CASE_INDIV__c caseIndiv:newIndividualIdToCaseIndividual.get(stateIdToRecordId.get(existingIndividual.IDN_STATE__c))){
                            T_SBSD_CASE_INDIV__c clonedCaseIndividual = caseIndiv.clone(false, true, false, false);
                            for(T_SBSD_CASE_INDIV__c existingCaseIndivForExistingIndividual:existingIndividual.Case_Individual__r){
                                if(existingCaseIndivForExistingIndividual.IDN_CASE__c == clonedCaseIndividual.IDN_CASE__c && (existingCaseIndivForExistingIndividual.DTE_END_EFFV__c==null || existingCaseIndivForExistingIndividual.DTE_END_EFFV__c>clonedCaseIndividual.DTE_BEGIN_EFFV__c)){
                                    showExistingIndividualError =  true;
                                    break;
                                }
                            }
                            if(showExistingIndividualError){
                                break;
                            }else{
                                clonedCaseIndividual.IDN_CLIENT__c = existingIndividual.Id;
                                newRecordsToBeCreated.add(clonedCaseIndividual);
                            }
                        }
                    }
                }
                if(showExistingIndividualError){
                    message = Label.INDIVIDUAL_ALREADY_EXISTS_ON_CASE;
                    isSuccessful = false;
                }else{
                    List<T_SBSD_INDIV__c> individualsToBeUpdated = new List<T_SBSD_INDIV__c>();
                    for(String stateId:stateIdToRecordId.keyset()){
                        if(!individualIdsToBeDeleted.contains(stateIdToRecordId.get(stateId))){
                            if(recordIdToRecord.containsKey(stateIdToRecordId.get(stateId))){
                                T_SBSD_INDIV__c individual = (T_SBSD_INDIV__c)recordIdToRecord.get(stateIdToRecordId.get(stateId));
                                individual.CDE_GENDER__c = individual.CDE_GENDER__c=='M'?'1':individual.CDE_GENDER__c=='F'?'2':individual.CDE_GENDER__c=='U'?'3':'4';
                                individual.IDN_STATE__c = stateId;
                                individualsToBeUpdated.add(individual);
                            }
                        }
                    }
                    
                    System.debug('individualsToBeUpdated:'+individualsToBeUpdated);
                    if(!individualsToBeUpdated.isEmpty()){
                        JunkRecordServices.deleteJunkRecordsByRecords(individualsToBeUpdated, false);         
                        GenericDMLHandler.updateRecords(individualsToBeUpdated, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'},'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'IDN_STATE__c','CDE_GENDER__c'}); // Added IDN_STATE__c , CDE_GENDER__c as part of CCCAP-8307                        
                        objectData.put('idToBeRedirected', individualsToBeUpdated.get(0).Id);
                    }
                    
                    System.debug('individualIdsToBeDeleted:'+individualIdsToBeDeleted);
                    if(!individualIdsToBeDeleted.isEmpty()){
                        List<Id> individualIdsToBeDeletedList = new List<Id>();
                        individualIdsToBeDeletedList.addAll(individualIdsToBeDeleted);
                        GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(individualIdsToBeDeletedList);
                        GenericWithoutSharingDMLOperations.deleteRecords(new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'}); 
                        objectData.put('idToBeRedirected', newRecordIdToExistingRecordId.get(individualIdsToBeDeletedList.get(0)));
                    }
                    
                    System.debug('newRecordsToBeCreated:'+newRecordsToBeCreated);
                    if(!newRecordsToBeCreated.isEmpty()){
                        GenericDMLHandler.insertRecords(newRecordsToBeCreated, new Map<String,Object>{'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'});                                        
                        if(newRecordsToBeCreated.get(0).get('IDN_CLIENT__c')!=null){
                            objectData.put('idToBeRedirected', newRecordsToBeCreated.get(0).get('IDN_CLIENT__c'));    
                        }
                    }
                    
                    message = Label.Record_has_been_successfully_created_deleted;
                    isSuccessful = true;
                }
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getMessage();
            String onlyError = message.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': []');
            if(String.isNotEmpty(onlyError)){
                message = onlyError;
            }
            if(message.containsIgnoreCase('ENTITY_IS_DELETED')){
                message = 'You have already completed the process to clear this individual, please navigate back to your case and check the Case Individual related list.';
            }
            Database.rollback(sp);
            if(!ex.getMessage().containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'updateRecords'});             
            }
        }
        system.debug('object data--'+objectData);
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse insertATSRecordForCaseIndividual(String caseId, String indivId){
        System.debug('inside insertATSRecordForCaseIndividual');
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        Map<string, string> indivIdtoNameMap = new Map<string, string>();
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        
        if(string.isNotEmpty(caseId) && string.isNotEmpty(indivId)){
            try{
                caseIndividualServices.insertATSRecord(new List<T_SBSD_CASE_INDIV__c>{new T_SBSD_CASE_INDIV__c(IDN_CASE__c = caseId, IDN_CLIENT__c = indivId)});
            }catch(Exception ex){
                isSuccessful = false;
                message = ex.getMessage();
            }
        } else {
            for(T_SBSD_INDIV__C eachIndiv : [select Id, Name from T_SBSD_INDIV__C where Id =:indivId WITH SECURITY_ENFORCED]){
                indivIdtoNameMap.put(eachIndiv.Id, eachIndiv.Name);
            }
            System.debug('Creating ATS record type 2(Indiv Update) for:'+indivId);
            batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord.CDE_STATUS_TRANS__c= '1';
            atsRecord.CDE_TYPE_TRANS__c ='2';
            if(string.isNotEmpty(indivId)){
                atsRecord.IDN_CLIENT__c = indivIdtoNameMap.get(indivId);
            }
            atsRecord.DTE_CHANGE_LAST__c = system.today();
            lstATSRecords.add(atsRecord);
            
            for(T_SBSD_CASE_INDIV__c eachCaseIndivForIndivUpdate : [select Id, IDN_CASE__r.Name, IDN_CLIENT__r.Name FROM T_SBSD_CASE_INDIV__c where IDN_CLIENT__c=:indivId WITH SECURITY_ENFORCED]){
                if(string.isNotEmpty(eachCaseIndivForIndivUpdate.IDN_CASE__r.Name) && string.isNotEmpty(eachCaseIndivForIndivUpdate.IDN_CLIENT__r.Name)){
                    System.debug('Creating ATS record type 3(Indiv Update) for:'+indivId);
                    batchsit_t_pos_trans_queue_ats__x atsRecord1 = new batchsit_t_pos_trans_queue_ats__x();
                    atsRecord1.CDE_STATUS_TRANS__c= '1';
                    atsRecord1.CDE_TYPE_TRANS__c ='3';
                    atsRecord1.IDN_CASE__c = eachCaseIndivForIndivUpdate.IDN_CASE__r.Name;
                    atsRecord1.IDN_CLIENT__c = eachCaseIndivForIndivUpdate.IDN_CLIENT__r.Name;
                    atsRecord1.DTE_CHANGE_LAST__c = system.today();
                    lstATSRecords.add(atsRecord1);    
                }
            }
            
            if(!lstATSRecords.isEmpty()){
                ATSHandler.insertATSRecord(true, lstATSRecords);        
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse handleCaseSelection(T_APPLN_PRCS_QUEUE__c appProcessQueue, List<String> individualIds){
        Savepoint sp = Database.setSavepoint();
        System.debug('appProcessQueue:'+appProcessQueue);
        Map<String, Object> objectData = new map<String, Object>();
        // added for UFE by Shashank 08/13/24
        List<UFEChangeInterface__e> ufeInfoUpdateEventList= new List<UFEChangeInterface__e>(); // added for UFE by Shashank 08/13/24
        Boolean isSuccessful = true;
        String message;
        try{
            if(appProcessQueue!=null){
                Boolean isBCRequested = [select idn_appln__r.UFE_Request_Flag__c from T_APPLN_PRCS_QUEUE__c where id =:appProcessQueue.Id]?.idn_appln__r?.UFE_Request_Flag__c;
                T_APPLN_PRCS_QUEUE__c appProcessQueue1 = [SELECT Id, IDN_APPLN__c, IDN_APPLN__r.NET_EARNED_INCOME__c, IDN_APPLN__r.CDE_CBMS_REF_TYP__c, IDN_APPLN__r.IDN_CBMS_REF__c,IDN_APPLN__r.UFE_Request_Flag__c, CDE_STATUS_APPLN__c, IDN_CASE__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueue.Id WITH SECURITY_ENFORCED];                                
                if(String.isNotEmpty(appProcessQueue.IDN_CASE__c)){
                    //update the T_APPLN_PRCS_QUEUE                    
                    //CDE_SOURCE = 'PEAK', IDN_CASE = IDN_CASE from the selected row, NUM_APPLN = PEAK Application Number; redirect to selected case
                    appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                    GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
                    objectData.put('caseId',appProcessQueue.IDN_CASE__c);
                    List<T_SBSD_CASE__c> cseList = [Select id, CDE_CBMS_REF_TYP__c,IDN_CBMS_REF__c,DTE_APPLN__c from T_SBSD_CASE__c where id=:appProcessQueue.IDN_CASE__c];
                    cseList[0].IDN_CBMS_REF__c = appProcessQueue1.IDN_APPLN__r.IDN_CBMS_REF__c;
                    cseList[0].CDE_CBMS_REF_TYP__c = appProcessQueue1.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
                GenericDMLHandler.updateRecords(cseList, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'IDN_CBMS_REF__c','CDE_CBMS_REF_TYP__c'}); // Added IDN_CBMS_REF__c, CDE_CBMS_REF_TYP__c as part of CCCAP-8307
                    message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue.Id;
                }else{
                    LightningServerResponse lsr = ConvertCBMSDataToCHATS.convertData(appProcessQueue, individualIds);
                    System.debug('lsr in APX:'+lsr);
                    if(lsr.isSuccessful){
                        T_SBSD_CASE__c caseRec = (T_SBSD_CASE__c)lsr.objectData.get('caseRec'); 
                        appProcessQueue.IDN_CASE__c = caseRec.Id;
                      //  appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                       // GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'});
                        objectData.put('caseId',caseRec.Id);
                        List<T_SBSD_CASE__c> cseList = [Select id, CDE_CBMS_REF_TYP__c,IDN_CBMS_REF__c,DTE_APPLN__c from T_SBSD_CASE__c where id=:appProcessQueue.IDN_CASE__c];
                    cseList[0].IDN_CBMS_REF__c = appProcessQueue1.IDN_APPLN__r.IDN_CBMS_REF__c;
                        cseList[0].CDE_CBMS_REF_TYP__c = appProcessQueue1.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
                GenericDMLHandler.updateRecords(cseList, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'IDN_CBMS_REF__c','CDE_CBMS_REF_TYP__c'}); // Added IDN_CBMS_REF__c, CDE_CBMS_REF_TYP__c as part of CCCAP-8307                
objectData.put('caseId',caseRec.Id);
                        message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue.Id;
                        isSuccessful = true;
                        
                    }else{
                        Database.rollback(sp);
                        isSuccessful = false;
                        return new LightningServerResponse(lsr.isSuccessful,lsr.errorMessage,lsr.objectData);
                    }
                }
                // added for UFE by Shashank 08/13/24
                if(isBCRequested == true && isSuccessful == true){
                    ufeInfoUpdateEventList.add(new UFEChangeInterface__e(IdNumber__c=appProcessQueue.IDN_CASE__c,Type__c='case'));
                    Eventbus.publish(ufeInfoUpdateEventList);                    
                }
            }else{
                isSuccessful = false;
                message = Label.appProcessQueue_should_not_be_blank;
                Database.rollback(sp);
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'handleCaseSelection'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse assignStateId(String fName, String lName, String MI, String dob, String ssn, String gndr){    
        List<sidmodResponseWrapper> respSidmodlst = new List<sidmodResponseWrapper>();
        List<Object> responseList = new List<object>(); 
        Map<String, Object> objectData = new map<String, Object>();
        respSidmodlst = (List<sidmodResponseWrapper>)sidmodIntegrationWebservices.assignStateId(fName,lName,MI,dob,ssn,gndr);
        Boolean isSuccessful;
        String message;
        if(respSidmodlst.isEmpty()){
            message = sidmodIntegrationWebservices.errorMessage!=null?sidmodIntegrationWebservices.errorMessage :'No State Id assigned';
        }else{
            objectData.put('respSidmodlst',respSidmodlst);
            message = 'New State Id assigned';
        }
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse overrideClientClearance(String fName, String lName, String MI, String dob, String ssn, String gndr){
        Map<String, Object> objectData = new map<String, Object>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'overrideClientClearance'};
            List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
        boolean isSuccess = false;
        String message;
        string gender = '' ;
        try{
            serviceMetaData = [SELECT id, AuthId__c, AuthToken__c, EndPoint__c, isActive__c, ServiceType__c, MasterLabel, DeveloperName FROM WebServiceConfiguration__mdt WHERE isActive__c = true AND DeveloperName = :OVERRIDECLIENTCLEARANCE LIMIT 1];
            if (!serviceMetaData.isEmpty()) {
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('POST');
                request.setHeader('Content-Type', 'Application/json');
                request.setTimeout(30000);
                if(gndr == '1'){
                    gender = 'M';
                } else if (gndr == '2'){
                    gender = 'F';
                } else if (gndr == '3'){
                    gender = 'U';
                } else if (gndr == '4'){
                    gender = 'X';
                }
                string endpoint = (serviceMetaData[0].EndPoint__c);
                request.setEndpoint(endpoint);
                //start - SIDMOD MODERNization Changes
                SIDMODRequestWrapper bodySidmod = new SIDMODRequestWrapper();
                SIDMODRequestWrapper.cls_person person = new SIDMODRequestWrapper.cls_person();
                person.firstName = fName!=null ? fName : null;
                person.middleName = MI!=null ? MI :null;
                person.lastName = lName!=null ? lName : null;
                person.dateOfBirth = dob;
                person.sex = gender!=null ? gender :null;
                person.ssn = ssn!=null ? ssn :null;
                bodySidmod.person = person;
                String requestBody =  JSON.serialize(bodySidmod,true);
                system.debug('requestBody'+requestBody);
                request.setBody(requestBody);
                //end - SIDMOD MODERNization Changes
                
                HttpResponse response = http.send(request);
                if (response <> null && response.getStatusCode() == 200) {
                    String responseJSON = response.getBody();
                    map<string,object> resMap =(map<string, object>) JSON.deserializeUntyped(responseJSON);
                    if(resMap.get('statusCode') != Null) { //returnCode
                        objectData.put('retrunMessage', resMap.get('errorMessage'));
                        objectData.put('statusCode', resMap.get('returnCode')); //returnCode
                        objectData.put('errorMsg', resMap.get('errorMessage')); // errorMsg
                        if(resMap.get('statusCode') == '202'){ //'00000000' == resMap.get('returnCode')){
                            isSuccess = true;
                            message = 'Success :'+string.valueOf(resMap.get('retrunMessage'));
                        } else {
                            isSuccess = false;
                            if(string.valueOf(resMap.get('errorMessage')) != null){
                                message = 'Failure :'+string.valueOf(resMap.get('errorMessage'));    
                            }
                        }
                    } else
                        throw new customException (string.valueOf(resMap.get('errorMessage'))); //errorMsg
                } else{
                    ExceptionLoggingServices.captureExceptionLog(response, request, methodInfo);
                    throw new customException ('The Override Service Request has failed, Please contact your Administrator.');
                } 
            }
        } Catch (exception e){
            Map<String,Object> methodReqInfo = new Map<String,Object>();
            methodReqInfo.put('Class__c','APXPeakApplicationToCaseController');    
            methodReqInfo.put('Method__c','overrideClientClearance');
            message = e.getMessage();
            objectData.put('errorMsg', message);
            ExceptionLoggingServices.captureExceptionLog(e, methodReqInfo);
        }
        return new LightningServerResponse(isSuccess,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse setPeakDataFlagToFalse(String caseId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        List<SObject> recordsTobeUpdated = new List<SObject>();
        recordsTobeUpdated.add(new T_SBSD_CASE__c(Id = caseId, Is_CBMS_Data__c = false));
        Set<Id> caseIndivIds = new Set<Id>();
        for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :caseId AND IDN_CLIENT__r.Is_CBMS_Data__c=true WITH SECURITY_ENFORCED]){
            /*CCCAP-14243 - Setting the bypass field when updating 'Is_CBMS_Data__c' from true back to false.
            This prevents validations (that are skipped when 'Is_CBMS_Data__c' is true) from firing during the update.*/
            recordsTobeUpdated.add(new T_SBSD_INDIV__c(Id = caseIndiv.IDN_CLIENT__c, Is_CBMS_Data__c = false, Bypass_On__c = System.now()));
            caseIndivIds.add(caseIndiv.Id);
        }
        if(!recordsTobeUpdated.isEmpty()){
            try{
                List<T_INDIV_CAT_RQ__c> childCareRequests = [SELECT Id,IDN_CASE_INDIV__c FROM T_INDIV_CAT_RQ__c WHERE IDN_CASE_INDIV__c IN: caseIndivIds WITH SECURITY_ENFORCED];
                if(childCareRequests!=null && !childCareRequests.isEmpty()){
                    IndividulCareLevelServices.doMethod(childCareRequests);
                } else {
                    //logging Succcess exception.
                    Exception_Log__c xLog = new Exception_Log__c();
                    xLog.Class__c = 'APXPeakApplicationToCaseController';
                    xLog.Method__c = 'setPeakDataFlagToFalse';
                    xLog.Exception_Message__c = Label.No_Child_Care_Requests_found_for_CaseIndividuals;
                    ExceptionLoggingServices.captureExceptionLog(xLog);
                }
                GenericDMLHandler.updateRecords(recordsTobeUpdated, new Map<String,Object>{'Method__c'=>'setPeakDataFlagToFalse','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'Is_CBMS_Data__c','Bypass_On__c'}); // Added Is_CBMS_Data__c, Bypass_On__c as part of CCCAP-8307
            }catch(Exception ex){
                isSuccessful = false;
                message = ex.getMessage();
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'setPeakDataFlagToFalse'}); 
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getAppAndRelatedChildData(String appProcessQueueId){
        Boolean isNewIndivAdded = false;
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        String referralId;
        Boolean isCaseInfoEditable = false;
        String appCaseId;
        Boolean isNewIndivReceived = false;
        Boolean isChildCareEditable = false;
        List<Referral_Information__c> caseRefInfo = new List<Referral_Information__c>();
        List<Referral_Information__c> childCareRefInfo = new List<Referral_Information__c>();
        List<Referral_Information__c> incomeRefList = new List<Referral_Information__c>();
        String oldCounty, newCounty, referralType;
        Map<Id, String> countyCodeMap = new Map<Id, String>();
        List<T_AUTH__c> activeAuthList = new List<T_AUTH__c>();
        
        System.debug('appProcessQueueId--'+appProcessQueueId);
        for(T_County__c county : [SELECT Id, Name, CDE_COUNTY__c, (SELECT Id, ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP__c, ADR_ZIP_EXTN__c, Record_Type_Name__c FROM County3__r WHERE Record_Type_Name__c IN ('Mailing', 'Main_Location')) FROM T_County__c WITH SECURITY_ENFORCED]){
            countyCodeMap.put(county.id, String.valueOf(county.Name));
        }
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate, IDN_APPLN__c, IDN_CASE__c, County_Name__r.Name,IDN_APPLN__r.CBMS_REF_REASON__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id = :appProcessQueueId WITH SECURITY_ENFORCED];
        System.debug('after --compareRefData');
        List<T_APPLN_CASE__c> lstApplnCase =  [SELECT Id, CBMS_CASE_NUM__c, IND_CW_PGM__c, IDN_CBMS_REF__c, CBMS_REF_REASON__c, IND_INTER_COUNTY_TRANSFER__c,
                                               NET_EARNED_INCOME__c, PAYMENT_MONTH__c, PRI_METHOD_OF_CON__c, PRIOR_COUNTY__c, WORK_SPECIALIST__c, CDE_CBMS_REF_TYP__c,
                                               ADR_CITY_PROVR__c, ADR_LINE_1_PROVR__c, ADR_STATE_PROVR__c, ADR_ZIP_PROVR__c, CDE_COUNTY__c, CASE_CLOSURE_REASON__c                                               
                                               FROM T_APPLN_CASE__c WHERE Id =: appProcessQueue[0].IDN_APPLN__c WITH SECURITY_ENFORCED]; 
        referralId = lstApplnCase[0].IDN_CBMS_REF__c;
        referralType = lstApplnCase[0].CDE_CBMS_REF_TYP__c;
        objectData.put('referralType', referralType);
        objectData.put('referralId', referralId);
        // added INC for Application consideration for CCCAP-14326 by Shashank.
        for(T_APPLN_PRCS_QUEUE__c appQueue : [SELECT Id, IDN_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE IDN_APPLN__r.IDN_CBMS_REF__c = :referralId AND id != :appProcessQueueId AND CreatedDate <= :appProcessQueue[0].CreatedDate AND CDE_STATUS_APPLN__c  NOT IN ('PRC','REJ','INC')]){
            objectData.put('existingRefUnPrc', true);
        }
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueueOld = [SELECT Id, CDE_STATUS_APPLN__c, IDN_APPLN__c, IDN_CASE__c, IDN_CASE__r.Id, IDN_APPLN__r.IDN_CBMS_REF__c, County_Name__r.Name FROM T_APPLN_PRCS_QUEUE__c WHERE IDN_CASE__r.IDN_CBMS_REF__c = :referralId]; 
        objectData.put('caseId', appProcessQueueOld[0].IDN_CASE__c);
        objectData.put('recordIdOld', appProcessQueueOld[0].Id);
        if(lstApplnCase != null && lstApplnCase.size() > 0){
            appCaseId = lstApplnCase[0].Id;
            objectData.put('appCaseId', appCaseId);
        }
        isNewIndivAdded = compareRefData(appProcessQueue[0], referralId,lstApplnCase, appProcessQueue[0].IDN_CASE__c);
        for(Referral_Information__c ref : [SELECT Id, Field_Name__c, Field_API_Name__c, CBMS_Object_Name__c, New_Value__c, Object_API_Name__c, Old_Value__c, Referral_Id__c, Referral_Type__c, Section_Name__c, isEditable__c, SF_Record_Id__c FROM Referral_Information__c WHERE Referral_Id__c = :referralId WITH SECURITY_ENFORCED order by SF_Record_Id__c asc,Field_API_Name__c asc]){
            system.debug('ref---'+ref);
            if((ref.Object_API_Name__c == 'T_SBSD_CASE_INFO__c' || ref.Object_API_Name__c == 'T_SBSD_CASE__c' || ref.Object_API_Name__c == 'T_CBMS_ADDNL_INFO__c') && (ref.New_Value__c != ref.Old_Value__c) && (ref.New_Value__c != '') && (ref.New_Value__c != null)){
                if(ref.isEditable__c) {
                    isCaseInfoEditable = true;
                }
                if(ref.Field_API_Name__c == 'NET_EARNED_INCOME__c') {
                    incomeRefList.add(ref);
                } else if(ref.Field_API_Name__c == 'CDE_COUNTY__c') {
                    objectData.put('oldCounty', countyCodeMap.get(ref.Old_Value__c));
                    objectData.put('newCounty', countyCodeMap.get(ref.New_Value__c));
                    caseRefInfo.add(ref);
                }
            } 
            if((ref.CBMS_Object_Name__c == 'T_APPLN_CHILD_CARE__c' || ref.Object_API_Name__c == 'T_APPLN_CHILD_CARE__c')){
                if((ref.New_Value__c != ref.Old_Value__c && ref.New_Value__c != '' && ref.New_Value__c != null)
                  || (ref.Field_API_Name__c == 'CHILD_NAME__c') || (ref.Field_API_Name__c == 'IDN_CBMS_PROVR__c')){
                if(ref.isEditable__c){
                    isChildCareEditable = true;
                }
                if((ref.New_Value__c == null || ref.New_Value__c == '')){
                    isNewIndivReceived = true;
                }
                childCareRefInfo.add(ref);   
                }
            }
        }
        // Start: Added by Rishav for CCCAP-7696
        Date todayDate = System.today();
        activeAuthList = [SELECT Id, Name, Child_Name__c FROM T_AUTH__c
                          WHERE IDN_CASE__c = :appProcessQueueOld[0].IDN_CASE__c AND DTE_BEGIN_EFFV_AUTH__c <=:todayDate AND (DTE_END_EFFV_AUTH__c >= :todayDate OR DTE_END_EFFV_AUTH__c = null)];
        if(activeAuthList != null && activeAuthList.size() > 0){
            objectData.put('activeAuthList', activeAuthList);
        }
        // End: CCCAP-7696
        if(caseRefInfo != null && caseRefInfo.size()>0){
            objectData.put('caseRefInfo', caseRefInfo);
        }
        if(childCareRefInfo != null && childCareRefInfo.size()>0){
            objectData.put('childCareRefList', childCareRefInfo);
        }
        if(incomeRefList != null && incomeRefList.size()>0){
            objectData.put('incomeRefList', incomeRefList);
        }
        objectData.put('isNewIndivReceived', isNewIndivAdded);
        objectData.put('appProcessQueue', appProcessQueue);
        objectData.put('isCaseInfoEditable', isCaseInfoEditable);
        objectData.put('isChildCareEditable', isChildCareEditable);
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse getAppAndRelatedLowIncomeData(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        String referralId;
        String appCaseId;
        String pending=Label.PEN;
        
        List<string> allIndividualsList = new List<String>();
        List<T_APPLN_INDIV__c> lstApplnIndivs = new List<T_APPLN_INDIV__c>();
        
        List<T_APPLN_ACTIVITY__c> activityLIRefInfo = new List<T_APPLN_ACTIVITY__c>();
        List<T_APPLN_OTHER_INCOME__c> incomeTypesLIRefInfo = new List<T_APPLN_OTHER_INCOME__c>();
        List<T_APPLN_EMPLMT__c> employmentLIRefInfo = new List<T_APPLN_EMPLMT__c>();
        List<T_APPLN_SELF_EMPLMT__c> selfEmploymentLIRefInfo = new List<T_APPLN_SELF_EMPLMT__c>();
        List<Sobject> emplIncomeLIInfo = new List<Sobject>();
        List<Sobject> emplPaystubLIInfo = new List<Sobject>();
        map<string,string> mapOfCBMSActvCodeTOCHATSActvType = new map<string,string>();
        set<string> actvCodesSetForIndividual = new set<string>();
        
        //Get all the picklist translation mappings
        ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
        
        system.debug('appProcessQueueId--'+appProcessQueueId);
        T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c,IDN_CASE__c, County_Name__r.Name, CDE_STATUS_APPLN__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
        objectData.put('caseId',appProcessQueue.IDN_CASE__c);
        List<T_APPLN_CASE__c> lstApplnCase = [SELECT Id,CBMS_CASE_NUM__c,IND_CW_PGM__c,IDN_CBMS_REF__c, CBMS_REF_REASON__c,CDE_CBMS_REF_TYP__c,
                                              (SELECT Id, IDN_APPLN__c FROM Application_case_16__r)
                                              FROM T_APPLN_CASE__c WHERE Id =: appProcessQueue.IDN_APPLN__c WITH SECURITY_ENFORCED]; 
        
        if(appProcessQueue.CDE_STATUS_APPLN__c != pending){
            appProcessQueue.CDE_STATUS_APPLN__c=pending;
            GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'getAppAndRelatedLowIncomeData','Class__c'=>'APXCBMSReferralToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
        }
        
        if(lstApplnCase != null && lstApplnCase.size()>0){
            referralId = lstApplnCase[0].IDN_CBMS_REF__c;
            appCaseId = lstApplnCase[0].Id;
            objectData.put('appCaseId',appCaseId);
            if(lstApplnCase[0].CBMS_REF_REASON__c != null){
                objectData.put('closureReason',lstApplnCase[0].CBMS_REF_REASON__c);
            } else {
                objectData.put('closureReason','');
            }
            if(lstApplnCase[0].CDE_CBMS_REF_TYP__c != null){
                objectData.put('referralType',lstApplnCase[0].CDE_CBMS_REF_TYP__c);
            }
            
            if(lstApplnCase.get(0).Application_case_16__r != null){
                for(T_APPLN_INDIV__c eachApplnIndiv : lstApplnCase.get(0).Application_case_16__r){
                    allIndividualsList.add(eachApplnIndiv.Id);
                }
            }
            
        }
        
        if(allIndividualsList != null && allIndividualsList.size()>0){
            lstApplnIndivs = [SELECT Id, IDN_APPLN__c,
                              (SELECT 	Id, CDE_TYPE_ACTV__C, DTE_BEGIN_ACTV_PRIM__C, DTE_END_ACTV_PRIM__C FROM Application_Activities__r),
                              (SELECT	Id, CDE_CBMS_SOURCE_INCOME__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, CDE_FREQ_INCOME__c, CDE_TYPE_VERIF__C, AMT_INCOME_OTHER_GROSS__c, CNT_HOURS_WORKED__c FROM Application_Other_Income__r),
                              (SELECT 	Id, NAM_BUSNS__c, ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c, NBR_PHONE__c, DTE_BEGIN_EMP__c, DTE_END_EMP__c, 
                               CDE_FREQ_INCOME__c, DTE_BEGIN_EFFV_INCOME__c, DTE_END_EFFV_INCOME__c, AMT_INCOME_MONTH_ESTMD__c, CNT_WEEK_PER_HOURS_ESTMD__c, INCOME_FREQUENCY__c, TOTAL_WEEKLY_HOURS_WORKED__C, DTE_PAY__C, CDE_TYPE_VERIF__C FROM Application_Employments__r),
                              (SELECT 	Id, NAM_BUSNS__c, ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c, NBR_PHONE__c, DTE_BEGIN_EMP__c, DTE_END_EMP__c, 
                               CDE_FREQ_INCOME__c, DTE_BEGIN_EFFV_INCOME__c, DTE_END_EFFV_INCOME__c, AMT_INCOME_MONTH_ESTMD__c, CNT_WEEK_PER_HOURS_ESTMD__c, INCOME_FREQUENCY__c, TOTAL_WEEKLY_HOURS_WORKED__C, DTE_PAY__C, CDE_TYPE_VERIF__C FROM Application_Self_Employments__r)
                              
                              FROM T_APPLN_INDIV__c where Id IN: allIndividualsList WITH SECURITY_ENFORCED];
            
        }
        
        for(Conversion_Picklist_Mapping__mdt mapping:[SELECT MasterLabel ,PEAK_Data__c, CHATS_Picklist_Mapping__c FROM Conversion_Picklist_Mapping__mdt where MasterLabel = 'CBMS_ACTV_TYP' WITH SECURITY_ENFORCED]){
            mapOfCBMSActvCodeTOCHATSActvType.put(mapping.PEAK_Data__c, mapping.CHATS_Picklist_Mapping__c);
        }
        
        if(allIndividualsList.isEmpty()){
            //message = Label.No_Records_Found;
            //isSuccessful = false;
            objectData.put('noDataMessage',true);
        }else {
            for(T_APPLN_INDIV__c eachApplnIndiv : lstApplnIndivs){
                actvCodesSetForIndividual.clear();
                if(eachApplnIndiv.Application_Activities__r != null && eachApplnIndiv.Application_Activities__r.size()> 0){
                    for(T_APPLN_ACTIVITY__c eachApplnActivity :eachApplnIndiv.Application_Activities__r){
                        String peakData = String.valueOf(Integer.valueOf(eachApplnActivity.CDE_TYPE_ACTV__C));
                        if(mapOfCBMSActvCodeTOCHATSActvType.containsKey(peakData)){
                            actvCodesSetForIndividual.add(mapOfCBMSActvCodeTOCHATSActvType.get(peakData));
                        }
                    }
                    
                    for(T_APPLN_ACTIVITY__c eachActivity : eachApplnIndiv.Application_Activities__r){
                        
                        if(eachActivity.CDE_TYPE_ACTV__c != null){
                            String peakData1 = String.valueOf(Integer.valueOf(eachActivity.CDE_TYPE_ACTV__c));
                            if(mapOfCBMSActvCodeTOCHATSActvType.containsKey(peakData1)){
                                //eachActivity.CDE_TYPE_ACTV__c = ConversionPicklistMappingUtility.translatePEAKToCHATSData('CBMS_ACTV_TYP',peakData1);
                            } else if (actvCodesSetForIndividual.contains('EMP')){
                                eachActivity.CDE_TYPE_ACTV__c = '51';
                            } else if(actvCodesSetForIndividual.contains('GED')){
                                eachActivity.CDE_TYPE_ACTV__c = '59';
                            } else {
                                eachActivity.CDE_TYPE_ACTV__c = '15';
                            }
                        }
                        activityLIRefInfo.add(eachActivity);
                    }
                }
                
                if(eachApplnIndiv.Application_Other_Income__r != null && eachApplnIndiv.Application_Other_Income__r.size()> 0){
                    for(T_APPLN_OTHER_INCOME__c eachOtherIncome : eachApplnIndiv.Application_Other_Income__r){
                        incomeTypesLIRefInfo.add(eachOtherIncome);
                    }
                }
                
                if(eachApplnIndiv.Application_Employments__r != null && eachApplnIndiv.Application_Employments__r.size()> 0){
                    for(T_APPLN_EMPLMT__c eachApplnEmpl : eachApplnIndiv.Application_Employments__r){
                        employmentLIRefInfo.add(eachApplnEmpl);
                        emplIncomeLIInfo.add(eachApplnEmpl);
                        emplPaystubLIInfo.add(eachApplnEmpl);
                        
                    }
                }
                
                if(eachApplnIndiv.Application_Self_Employments__r != null && eachApplnIndiv.Application_Self_Employments__r.size()> 0){
                    for(T_APPLN_SELF_EMPLMT__c eachApplnSelfEmpl : eachApplnIndiv.Application_Self_Employments__r){
                        selfEmploymentLIRefInfo.add(eachApplnSelfEmpl);
                        emplIncomeLIInfo.add(eachApplnSelfEmpl);
                        emplPaystubLIInfo.add(eachApplnSelfEmpl);
                    }
                }
                
            }
            
            
            if(activityLIRefInfo != null && activityLIRefInfo.size()>0){
                objectData.put('activityLIRefInfo',activityLIRefInfo);
            }
            if(incomeTypesLIRefInfo != null && incomeTypesLIRefInfo.size()>0){
                objectData.put('incomeTypesLIRefInfo',incomeTypesLIRefInfo);
            }
            if(employmentLIRefInfo != null && employmentLIRefInfo.size()>0){
                objectData.put('employmentLIRefInfo',employmentLIRefInfo);
            }
            if(selfEmploymentLIRefInfo != null && selfEmploymentLIRefInfo.size()>0){
                objectData.put('selfEmploymentLIRefInfo',selfEmploymentLIRefInfo);
            }
            if(emplIncomeLIInfo != null && emplIncomeLIInfo.size()>0){
                objectData.put('emplIncomeLIInfo',emplIncomeLIInfo);
            }
            if(emplPaystubLIInfo != null && emplPaystubLIInfo.size()>0){
                objectData.put('emplPaystubLIInfo',emplPaystubLIInfo);
            }
            
            if((activityLIRefInfo == null) && (incomeTypesLIRefInfo == null) && (employmentLIRefInfo == null) && (selfEmploymentLIRefInfo == null) && (emplIncomeLIInfo == null) && (emplPaystubLIInfo == null)){
                objectData.put('noDataMessage',true);
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse processTransitionOnFinish(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        String referralId;
        
        List<string> allIndividualsList = new List<String>();
        T_SBSD_CASE__c refTypeUpdToCase = new T_SBSD_CASE__c();
        List<T_CBMS_ADDNL_INFO__c> tanfDetailsToBeUpdated = new  List<T_CBMS_ADDNL_INFO__c>();
        system.debug('appProcessQueueId--'+appProcessQueueId);
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c,IDN_APPLN__r.HouseHold_Gross_Income__c,IDN_CASE__c, County_Name__r.Name FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId WITH SECURITY_ENFORCED];
        if(appProcessQueue[0].IDN_CASE__c != null){
            refTypeUpdToCase = [SELECT Id, Name, CDE_CBMS_REF_TYP__c FROM T_SBSD_CASE__c where Id =: appProcessQueue[0].IDN_CASE__c WITH SECURITY_ENFORCED];
            tanfDetailsToBeUpdated  = [SELECT Id,DTE_BEGIN_EFFEV__c,CDE_FREQ_INCOME__c,AMT_TANF_INCOME_HH_GROSS__c,NME_CO_WORKER__c from T_CBMS_ADDNL_INFO__c where IDN_CASE_CHATS__c=:appProcessQueue[0].IDN_CASE__c   WITH SECURITY_ENFORCED order by lastmodifiedDate DESC];                 
                // CCCAP-11071 CHANGES
                if(appProcessQueue[0].IDN_APPLN__r.HouseHold_Gross_Income__c != null){
                    if(tanfDetailsToBeUpdated!= null && tanfDetailsToBeUpdated.size()>0){
                        tanfDetailsToBeUpdated[0].AMT_TANF_INCOME_HH_GROSS__c = appProcessQueue[0].IDN_APPLN__r.HouseHold_Gross_Income__c;
                        if(String.isBlank(tanfDetailsToBeUpdated[0].CDE_FREQ_INCOME__c)){
                            tanfDetailsToBeUpdated[0].CDE_FREQ_INCOME__c ='MON';
                        }
                        // CCCAP-11071 CHANGES ENDS
                    }
                    GenericDMLHandler.updateRecords(new List<SObject>{tanfDetailsToBeUpdated[0]}, new Map<String,Object>{'Method__c'=>'processTransitionOnFinish','Class__c'=>'APXCBMSReferralToCaseController'}, new list<String>{'AMT_TANF_INCOME_HH_GROSS__c','CDE_FREQ_INCOME__c'}); // Added AMT_TANF_INCOME_HH_GROSS__c, CDE_FREQ_INCOME__c as part of CCCAP-8307
                }
        }
        objectData.put('caseId',appProcessQueue[0].IDN_CASE__c);
        List<T_APPLN_CASE__c> lstApplnCase = [SELECT Id,CBMS_CASE_NUM__c,IND_CW_PGM__c,IDN_CBMS_REF__c, CASE_CLOSURE_REASON__c,CDE_CBMS_REF_TYP__c,
                                              (SELECT Id, IDN_APPLN__c FROM Application_case_16__r)
                                              FROM T_APPLN_CASE__c WHERE Id =: appProcessQueue[0].IDN_APPLN__c WITH SECURITY_ENFORCED]; 
        
        if(lstApplnCase != null && lstApplnCase.size()>0){
            referralId = lstApplnCase[0].IDN_CBMS_REF__c;
            if(lstApplnCase.get(0).Application_case_16__r != null){
                for(T_APPLN_INDIV__c eachApplnIndiv : lstApplnCase.get(0).Application_case_16__r){
                    allIndividualsList.add(eachApplnIndiv.Id);
                }
            }
            
        }
        
        LightningServerResponse lsr = ConvertCBMSDataToCHATS.convertRefDataForTransition(appProcessQueueId, allIndividualsList);
        if(lsr.isSuccessful){
            appProcessQueue[0].CDE_STATUS_APPLN__c = 'PRC';
            GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue[0]}, new Map<String,Object>{'Method__c'=>'processTransitionOnFinish','Class__c'=>'APXCBMSReferralToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
            if(lstApplnCase!=null && lstApplnCase.size()>0 &&  appProcessQueue[0].IDN_CASE__c != null){
                refTypeUpdToCase.CDE_CBMS_REF_TYP__c = lstApplnCase.get(0).CDE_CBMS_REF_TYP__c;
                GenericDMLHandler.updateRecords(new List<SObject>{refTypeUpdToCase}, new Map<String,Object>{'Method__c'=>'processTransitionOnFinish','Class__c'=>'APXCBMSReferralToCaseController'}, new list<String>{'CDE_CBMS_REF_TYP__c'}); // Added CDE_CBMS_REF_TYP__c as part of CCCAP-8307
            } 
            message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue[0].Id;
            isSuccessful = true;
            
        }else{
            return new LightningServerResponse(lsr.isSuccessful,lsr.errorMessage,lsr.objectData);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
   public static Boolean compareRefData(T_APPLN_PRCS_QUEUE__c appProcessQueue, String referralId ,List<T_APPLN_CASE__c> lstApplnCase, String caseId){
        Boolean isNewIndivAdded=false;
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message = 'Error: ';
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ConvertPeakDataToCHATS','Method__c'=>'convertData'};
            List<Referral_Information__c> refrenceInfoLst = new List<Referral_Information__c>();
        //Get all the picklist translation mappings
        ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
        //Logic to clone T_APPLN records to T_SBSD records  
        Map<String,List<Referral_Information__c>> refInfoMap = new Map<String,List<Referral_Information__c>>();
        Map<String,T_APPLN_INDIV__c> appIndivMap = new Map<String,T_APPLN_INDIV__c>();
        List<SObject> lstSObjectToBeInserted = new List<SObject>();
        List<T_SBSD_INDIV__c> lstIndiv = new List<T_SBSD_INDIV__c>();
        List<T_APPLN_INDIV__c> lstApplnIndiv = new List<T_APPLN_INDIV__c>();
        List<T_APPLN_CHILD_Care__c> childCares = new List<T_APPLN_CHILD_Care__c>();
        for(T_APPLN_INDIV__c lstApplnIndi : [SELECT Id, CDE_GENDER__c,CBMS_DENIAL_REASON__c,CDE_SOURCE_VRFYD_CITIZEN__c,CDE_VRFYD_CITIZEN__c,IDN_CBMS_CLIENT__c,IND_IPV__c,ROADMAP_CORR_ID__c,
                                                CDE_LEVEL_GRADE_HGHST__c,
                                                CDE_STATUS_MAR__c,
                                                DTE_DOB__c,
                                                IDN_STATE__c,
                                                NAM_FIRST__c,
                                                NAM_LAST__c,
                                                NAM_MI__c,
                                                NBR_SSN__c,
                                                CDE_INFO_CS__c,
                                                IND_CTZN__c,
                                                CDE_STATUS_MIL__c,
                                                IND_CRTKR_PRIM__c,
                                                IDN_SEQ_INDIV__c,
                                                (SELECT id,CHILD_NAME__c,IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_CLIENT__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.CDE_CBMS_REF_TYP__c,CNT_HOUR_ON_FRI__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_APPLN__c,
                                                     CNT_HOUR_ON_MON__c,CNT_HOUR_ON_SAT__c,CNT_HOUR_ON_SUN__c,CNT_HOUR_ON_THU__c,IDN_INDIVIDUAL__r.IDN_APPLN__r.IDN_CBMS_REF__c,
                                                     CNT_HOUR_ON_TUE__c,CNT_HOUR_ON_WED__c,IDN_CBMS_PROVR__c,IDN_INDIVIDUAL__c,NAM_FACILITY__c,IND_NEED_CHILD_CARE__c,DTE_BEGIN_EFFV__c,DTE_END_CARE__c,DTE_BEGIN_CARE__c,
                                              DTE_WITH_LAST_PROVIDER__c,IND_PROVIDER_CHANGE__c,IND_SCHOOL_AGE_CARE__c FROM Application_Child_Cares__r)
                                             FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c WITH SECURITY_ENFORCED]){
                                                 lstApplnIndiv.add(lstApplnIndi);
                                                 if(!lstApplnIndi.Application_Child_Cares__r.isEmpty())
                                                     childCares.addAll(lstApplnIndi.Application_Child_Cares__r);
                                             }
        APXPolicyRecordsServices.updateRefData(lstApplnCase[0].IDN_CBMS_REF__c ,lstApplnCase);
        APXPolicyRecordsServices.updateRefData(lstApplnCase[0].IDN_CBMS_REF__c ,childCares);
        Set<String> setDOB_SSN = new Set<String>();
        Map<String, String> mapStateIdWithPrimaryCaretaker = new Map<String, String>();
        Map<String,T_SBSD_CASE_INDIV__c> mapCaseIndividual = new Map<String,T_SBSD_CASE_INDIV__c>();
        List<T_APPLN_CHILD_CARE__c> childCareList = new List<T_APPLN_CHILD_CARE__c>();
        for(T_SBSD_CASE_INDIV__c caseIndiv :[Select id,IDN_STATE__c from T_SBSD_CASE_INDIV__c where IDN_CASE__c=:caseId]){
            mapCaseIndividual.put(caseIndiv.IDN_STATE__c,caseIndiv);
        }
       /*  for(Referral_Information__c ref: [SELECT id,IDN_CLIENT__c,Field_Name__c,Field_API_Name__c,CBMS_Object_Name__c,New_Value__c,Object_API_Name__c,Old_Value__c,Referral_Id__c,Referral_Type__c,Section_Name__c,isEditable__c,SF_Record_Id__c from Referral_Information__c where Referral_Id__c=:referralId]){
             if(ref.IDN_CLIENT__c != null){
                 if(refInfoMap.containsKey(ref.IDN_CLIENT__c)){
                     List<Referral_Information__c> refList = refInfoMap.get(ref.IDN_CLIENT__c);
                     refList.add(ref);
                     refInfoMap.put(ref.IDN_CLIENT__c,refList);
                 }   else{
                     List<Referral_Information__c> refList = new List<Referral_Information__c>();
                     refList.add(ref);
                     refInfoMap.put(ref.IDN_CLIENT__c,refList);
                 }
             }
         }*/
         for(T_APPLN_INDIV__c indiv :lstApplnIndiv){
            if(!mapCaseIndividual.containsKey(indiv.IDN_STATE__c) && indiv.IND_CRTKR_PRIM__c !='Y'){
                isNewIndivAdded=true;
            }
        }
      
        return isNewIndivAdded;
    }
    @AuraEnabled
    public static LightningServerResponse updateCHATSObjsInfo( List<String> selectedReferralIds){
        List<SObject> lstSObject = new List<SObject>();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        String referralId;
        List<Referral_Information__c> selectedReferrals = new List<Referral_Information__c>();
        List<Referral_Information__c> selectedReferralsToBeUpdated = new List<Referral_Information__c>();
        system.debug('selectedReferralIds--'+selectedReferralIds);
        Map<String,Id> countyCodeMap= new Map<String,Id>();
        if(selectedReferralIds!= null && selectedReferralIds.size()>0){
            selectedReferrals =[SELECT id,Field_Name__c,New_Value__c,Object_API_Name__c,Field_API_Name__c,Old_Value__c,Referral_Id__c,Referral_Type__c,Section_Name__c,isEditable__c,SF_Record_Id__c from Referral_Information__c where Id IN:selectedReferralIds WITH SECURITY_ENFORCED];
        }
      /*  for(T_County__c county:[SELECT Id,CDE_COUNTY__c,(SELECT Id,ADR_LINE_1__c,ADR_LINE_2__c,ADR_CITY__c,ADR_STATE__c,ADR_ZIP__c,ADR_ZIP_EXTN__c, Record_Type_Name__c FROM County3__r WHERE Record_Type_Name__c IN ('Mailing','Main_Location')) FROM T_County__c]){
            countyCodeMap.put(String.valueOf(county.CDE_COUNTY__c), county.id);  
        }*/
        if(Schema.sObjectType.Referral_Information__c.fields.Old_Value__c.isUpdateable()
                && Schema.sObjectType.Referral_Information__c.fields.Old_Value__c.isCreateable()){
            for(Referral_Information__c ref : selectedReferrals){
                ref.Old_Value__c = ref.New_Value__c;
                selectedReferralsToBeUpdated.add(ref);
            }
        }
        List<Referral_Information__c> caseRefInfo = new List<Referral_Information__c>();
        Map<Id,Map<String,String>> refObjMap = new Map<Id,Map<String,String>>();
        system.debug('selectedReferrals--'+selectedReferrals);
        for(Referral_Information__c ref:selectedReferrals){
            if(refObjMap.containsKey(ref.SF_Record_Id__c)){
                Map<String,String> refMap = refObjMap.get(ref.SF_Record_Id__c);
                system.debug('refMap 1--'+refMap);
                if(!refMap.containsKey(ref.Field_API_Name__c)){
                    system.debug('refMap-2-'+refMap);
                    refMap.put(ref.Field_API_Name__c,ref.New_Value__c);
                    refObjMap.put(ref.SF_Record_Id__c,refMap);
                    system.debug('refMap-3-'+refMap);
                }
            }else{
                Map<String,String> refMap1 = new Map<String,String>();
                refMap1.put(ref.Field_API_Name__c,ref.New_Value__c);
                refObjMap.put(ref.SF_Record_Id__c,refMap1);
                system.debug('refMap-4-'+refMap1);
            }
        }
        for(Id sfRec:refObjMap.keySet()){
            String sObjName = sfRec.getSObjectType().getDescribe().getName();
            SObject targetSObject = Schema.getGlobalDescribe().get(sObjName).newSObject() ;
            targetSObject.put('Id', sfRec);
            system.debug('Id--'+sfRec);
            Map<String,String> fieldsMap= refObjMap.get(sfRec);
            system.debug('fieldsMap---'+fieldsMap);
            for(String val :fieldsMap.keySet()){
                Object fieldValue;
              /*  if(val=='CDE_COUNTY__c'){
                    fieldValue = countyCodeMap.get(fieldsMap.get(val)) ; 
                }else */if(fieldsMap.get(val) != null && val !='CDE_COUNTY__c'){
                    if(val=='NET_EARNED_INCOME__c'){
                        val ='AMT_TANF_INCOME_HH_GROSS__c';
                        Schema.SObjectField field = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().get(val);
                        Schema.DisplayType fieldType = field.getDescribe().getType();
                        fieldValue = APXPolicyRecordsServices.getTypeCastedValue(String.valueOf(fieldType),String.valueOf(fieldsMap.get('NET_EARNED_INCOME__c')));
                    }else{
                        Schema.SObjectField field = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().get(val);
                        Schema.DisplayType fieldType = field.getDescribe().getType();
                        fieldValue = APXPolicyRecordsServices.getTypeCastedValue(String.valueOf(fieldType),String.valueOf(fieldsMap.get(val)));
                    }                   
                }
                
                targetSObject.put(val, fieldValue);
                system.debug('val---'+fieldValue);
                system.debug('fieldsMap.get(val)---'+fieldsMap.get(val));                
            }
            lstSObject.add(targetSObject);
        }
        system.debug('lstSObject---'+lstSObject);
        system.debug('lstSObject--size-'+lstSObject.size());
       
        if(lstSObject.size()>0){
            APXPolicyRecordsServices.updateLstSObject(lstSObject);
            APXPolicyRecordsServices.updateLstSObject(selectedReferralsToBeUpdated);
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse createTask( String caseId,String appProcId ){
        List<SObject> lstSObject = new List<SObject>();
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        String referralId;
        try{
            List<task> lstTaskToInsert = new List<Task>();
            Date nextOneMonth = system.today().addMonths(1);
            Integer daysToBeAdded = 1;
            set<Date> holidays = new set<Date>();
            for(T_YEAR_HOL__c holiday:[SELECT DTE_HOL__c FROM T_YEAR_HOL__c WHERE DTE_HOL__c>=TODAY AND DTE_HOL__c<=:nextOneMonth WITH SECURITY_ENFORCED]){
                holidays.add(holiday.DTE_HOL__c);
            }
            Date dueDate = ConvertPeakDataToCHATS.getNextBusinessDay(system.today().addDays(daysToBeAdded), holidays);
            if(String.isNotBlank(caseId)){
                for(T_SBSD_CASE__c caseRec :[Select id,OwnerId,(Select id,name from Application_Process_Queues__r) from T_SBSD_CASE__c where id=:caseId WITH SECURITY_ENFORCED]){
                    if(caseRec.Application_Process_Queues__r.size()>0){
                        Task taskRec = new Task();
                        taskRec.WhatId = caseRec.Id;
                        taskRec.Subject = Label.T114Subject;
                        taskRec.Status = 'New';
                        taskRec.Description = 'TANF Referral Application  '+ caseRec.Application_Process_Queues__r[0].Name   +
                            ' is having a county change. Please review the referral application and take necessary action.';
                        taskRec.OwnerId = caseRec.OwnerId;
                        taskRec.ActivityDate = dueDate;
                        lstTaskToInsert.add(taskRec);
                    }
                    
                }
            }
            if(!lstTaskToInsert.isEmpty()){
                GenericDMLHandler.insertRecords(lstTaskToInsert, null); 
            }
        }catch(Exception ex){
            message = ex.getMessage();
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse updateApplProcessQueue(T_APPLN_PRCS_QUEUE__c appProcessQueueRec, String caseId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        try{
            if(appProcessQueueRec!=null){
              //  T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c,IDN_CASE__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId];
                
                //update the T_APPLN_PRCS_QUEUE                    
                //CDE_SOURCE = 'PEAK', IDN_CASE = IDN_CASE from the selected row, NUM_APPLN = PEAK Application Number; redirect to selected case
                appProcessQueueRec.CDE_STATUS_APPLN__c = 'PRC';
                appProcessQueueRec.IDN_CASE__c = caseId;
                GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueueRec}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new list<String>{'CDE_STATUS_APPLN__c','IDN_CASE__c'}); // Added CDE_STATUS_APPLN__c and IDN_CASE__c as part of CCCAP-8307
            }else{
                isSuccessful = false;
                message = Label.appProcessQueue_should_not_be_blank;
            }
        }catch(Exception ex){
            isSuccessful = false;
            message = ex.getLineNumber()+Label.Colon+ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'handleCaseSelection'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    // added for CCCAP-10315 for SIDMOD Notify Feature
    @auraEnabled
    public static LightningServerResponse notifySIDMOD(String stateId,Id indivId,Boolean isAppIndividual){
        return sidmodIntegrationWebservices.notifySIDMOD(stateId,indivId,isAppIndividual);
    }
    public class customException extends Exception {}
}