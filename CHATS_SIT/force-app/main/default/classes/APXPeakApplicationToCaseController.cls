public with sharing class APXPeakApplicationToCaseController {
    public static string OVERRIDECLIENTCLEARANCE = 'Override_Service';
    
    @AuraEnabled
    public static LightningServerResponse getIndivInfo(String indivId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<T_SBSD_INDIV_INFO__c> indivInfo = [SELECT Id, CDE_TYPE_INFO_INDIV__c,CDE_VALUE_INFO_INDIV__c  FROM T_SBSD_INDIV_INFO__c WHERE IDN_CLIENT__c =:indivId and CDE_TYPE_INFO_INDIV__c='CS'];
        if(!indivInfo.isEmpty()){
            
            objectData.put('indivInfoRecOld',indivInfo[0]);
        }
        return new LightningServerResponse(isSuccessful,null,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse checkIfAppHasPrimaryCaretaker(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, IDN_APPLN__c, County_Name__r.Name FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId];
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
        List<T_SBSD_INDIV__c> existingIndividuals = [SELECT Id FROM T_SBSD_INDIV__c WHERE IDN_STATE__c = :stateId];
        if(existingIndividuals.isEmpty()){
            objectData.put('stateIdExisting',false);
        }else{
            objectData.put('stateIdExisting',true);
            objectData.put('existingIndividualId',existingIndividuals[0].Id);
        }
        return new LightningServerResponse(true,null,objectData);
    } 
    
    public static LightningServerResponse checkCountyMatch(String appProcessQueueId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        //Removed unused variable on 5/13/2018 BG         
        String message;
        String showConfirmMessage=Label.showConfirmMessage;
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueue = [SELECT Id, County_Name__c,CDE_SOURCE__c,IDN_APPLN__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId];
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
                if(appProcessQueue[0].CDE_SOURCE__c == 'PK'){
                    LightningServerResponse lsr = checkIfPrimaryCareTakersExist(appProcessQueueId,appProcessQueue[0].IDN_APPLN__c);
                    if(!lsr.isSuccessful){
                        isSuccessful = false;
                        message = lsr.errorMessage;
                    }
                }
            }catch(Exception ex){
                System.debug(ex.getMessage());
                objectData.put(showConfirmMessage,true);
                isSuccessful = false;
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'checkCountyMatch'});             
            }
        }        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    public static LightningServerResponse checkIfPrimaryCareTakersExist(String recordId,String applnId){
        String message;
        Boolean isSuccessful =true;
        Boolean doesCaretakerExist = false;
        List<T_APPLN_INDIV__c> applicationIndividuals = [SELECT Id,DTE_DOB__c,CDE_GENDER__c,IND_CRTKR_PRIM__c,
                                                        (SELECT id, CDE_TYPE_REL_INDIV__c FROM Application_Relationships__r) 
                                                        FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :applnId];
        Integer Age;
        List<String> PEAK_teenParentTypes = new List<String>{'DA','FA','HU','WI'};
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                if(applnIndiv.DTE_DOB__c!=null){
                    Age  = (System.today().year() - applnIndiv.DTE_DOB__c.year()) - 
                        (System.today().month()<applnIndiv.DTE_DOB__c.month() || (System.today().month()==applnIndiv.DTE_DOB__c.month() 
                                                                                  && System.today().day()<applnIndiv.DTE_DOB__c.day())?1:0);
                    if(applnIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code){
                        if(Age>18){
                            doesCaretakerExist = applnIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code;
                        }else if(Age<=18){
                            for(T_APPLN_REL__c applnRel:applnIndiv.Application_Relationships__r){
                                doesCaretakerExist = doesCaretakerExist || PEAK_teenParentTypes.contains(applnRel.CDE_TYPE_REL_INDIV__c);
                            }
                        }
                    }
                }
            }
        if(applicationIndividuals!=null && applicationIndividuals.size()==1 && age!=null && age<18){
            message = 'There is only one individual in the application whose age is under 18 years old. Please process this as a paper application by rejecting the application and selecting \'processed as paper\' for the rejection reason and manually entering the information into CHATS';
            isSuccessful = false;
        }
        return new LightningServerResponse(isSuccessful,message,new map<String, Object>());
    }
    @AuraEnabled
    public static LightningServerResponse getIndividualDetails(String recordId){
        List<T_SBSD_INDIV__c> individuals = [SELECT Id, NAM_LAST__c, NAM_FIRST__c, NAM_MI__c, DTE_DOB__c, NBR_SSN__c , toLabel(CDE_GENDER__c) , IDN_STATE__c FROM T_SBSD_INDIV__c WHERE  Id=:recordId];
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
        String applnStatusNew = 'NEW';  // CCCAP-9409 Status will change to PENDING only when application is NEW
        String message;
	Boolean hasPrimaryCaretaker = false;
    try{
        T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, IDN_APPLN__c, CDE_COUNTY__c, CDE_STATUS_APPLN__c, DTE_RCVD_APPLN__c, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:appProcessQueueId];
        List<T_APPLN_INDIV__c> applicationIndividuals = [SELECT Id,NAM_LAST__c,NAM_FIRST__c,
                                                         NAM_MI__c,DTE_DOB__c,
                                                         NBR_SSN__c,CDE_GENDER__c,
                                                         IND_CRTKR_PRIM__c,IDN_STATE__c, 
                                                         IDN_SEQ_INDIV__c,
                                                         (SELECT id, CDE_TYPE_REL_INDIV__c, IDN_SEQ_INDIV_RELTD__c
                                                          FROM Application_Relationships__r) 
                                                         FROM T_APPLN_INDIV__c WHERE IDN_APPLN__c = :appProcessQueue.IDN_APPLN__c];
        Map<Decimal,T_APPLN_INDIV__c> mapIndivSequenceToIndividual = new Map<Decimal,T_APPLN_INDIV__c>();
        Map<Decimal,String> mapIndivSequenceToRelationship = new Map<Decimal,String>();
        String peakRefTable;
        String relationshipType;
        for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
            mapIndivSequenceToIndividual.put(applnIndiv.IDN_SEQ_INDIV__c, applnIndiv);
        }            
        ConversionPicklistMappingUtility.getPicklistMappingsForPEAKRefTable();
        List<String> PEAK_teenParentTypes = new List<String>{'DA','FA','HU','WI'};
            for(T_APPLN_INDIV__c applnIndiv:applicationIndividuals){
                if(applnIndiv.DTE_DOB__c!=null){
                    if(applnIndiv.IND_CRTKR_PRIM__c==Label.Yes_API_Code){
                        hasPrimaryCaretaker = true;
                        for(T_APPLN_REL__c applnRel:applnIndiv.Application_Relationships__r){
                            peakRefTable = 'TREL';
                            if(mapIndivSequenceToIndividual.containsKey(applnRel.IDN_SEQ_INDIV_RELTD__c)){
                                peakRefTable+=mapIndivSequenceToIndividual.get(applnRel.IDN_SEQ_INDIV_RELTD__c).CDE_GENDER__c=='M'?'_M':(mapIndivSequenceToIndividual.get(applnRel.IDN_SEQ_INDIV_RELTD__c).CDE_GENDER__c=='F'?'_F':'');
                                    relationshipType = ConversionPicklistMappingUtility.translatePEAKToCHATSData(peakRefTable, applnRel.CDE_TYPE_REL_INDIV__c);
                                mapIndivSequenceToRelationship.put(applnRel.IDN_SEQ_INDIV_RELTD__c,relationshipType);
                            }
                        }
                    }
                }
            }
        
        objectData.put('hasPrimaryCaretaker',hasPrimaryCaretaker);

            //exception logging to capture when applications are moving from Processed to Pending
            // CCCAP-9409 Exception logging , if the INIT method is called for already Processed Application
            if(appProcessQueue.CDE_STATUS_APPLN__c != applnStatusNew && appProcessQueue.CDE_STATUS_APPLN__c != pending){
                Exception_Log__c xLog = new Exception_Log__c();
		xLog.Class__c = 'APXPeakApplicationToCaseController';
		xLog.Method__c = 'getInitData';
		xLog.Exception_Message__c = 'The Application is already Processed or Rejected';
		ExceptionLoggingServices.captureExceptionLog(xLog);
            }
            if(appProcessQueue.CDE_STATUS_APPLN__c == applnStatusNew){
                appProcessQueue.CDE_STATUS_APPLN__c=pending;
                GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'getInitData','Class__c'=>'APXPeakApplicationToCaseController'}, new List<String>{'CDE_STATUS_APPLN__c'}); // Added CDE_STATUS_APPLN__c as part of CCCAP-8307
            }
            
            if(applicationIndividuals.isEmpty()){
                message = Label.No_Records_Found;
                isSuccessful = false;
            }else{
                objectData.put('mapIndivSequenceToRelationship',mapIndivSequenceToRelationship);
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
                                ];
            message = Label.Case_Details_Found_Successfully;
            objectData.put('lstCaseIndividual',lstCaseIndividual);
            Set<Id> setCaseId = new Set<Id>();
            for(T_SBSD_CASE_INDIV__c caseIndivdual:lstCaseIndividual){
                setCaseId.add(caseIndivdual.IDN_CASE__c);
            }
            for(T_SBSD_CASE_STATUS_MODE__c caseStatusMode:[SELECT toLabel(CDE_STATUS_CASE__c),IDN_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:setCaseId AND DTE_BEGIN_EFFV__c <= TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY) ORDER BY DTE_BEGIN_EFFV__c ASC]){
                mapCaseIdCaseStatus.put(caseStatusMode.IDN_CASE__c,caseStatusMode.CDE_STATUS_CASE__c);
            }
            objectData.put('mapCaseIdCaseStatus',mapCaseIdCaseStatus);
        }
        isSuccessful = true;
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
        List<T_SBSD_INDIV__c> lstMatchedCHATSIndividuals= [SELECT Id,Name, NAM_LAST__c,NAM_FIRST__c,NAM_MI__c,DTE_DOB__c,NBR_SSN__c,toLabel(CDE_GENDER__c),IDN_STATE__c FROM T_SBSD_INDIV__c WHERE (NBR_SSN__c = :ssn OR DTE_DOB__c=:Date.valueOf(dob)) AND TXT_SNDX__c Like :soundexValue AND IDN_STATE__c!=null AND IDN_STATE__c!=:Label.SIDMOD_STATE_ID_REQUIRED];
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
                for(T_SBSD_CASE_INDIV__c caseIndividual:[SELECT IDN_CASE__c, INDIVIDUAL_STATUS__c, IND_CRTKR__c, IDN_CLIENT__c, DTE_BEGIN_EFFV__c,IDN_EXTNL__c  FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:stateIdToRecordId.values()]){
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
                for(T_SBSD_INDIV__c existingIndividual:[SELECT Id, IDN_STATE__c, (SELECT id, IDN_CASE__c,DTE_END_EFFV__c FROM Case_Individual__r) FROM T_SBSD_INDIV__c WHERE IDN_STATE__c IN:stateIdToRecordId.keySet()]){
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
                        GenericDMLHandler.updateRecords(individualsToBeUpdated, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_INDIV__c'},'Method__c'=>'updateRecords','Class__c'=>'APXPeakApplicationToCaseController'}, new List<String>{'CDE_GENDER__c','IDN_STATE__c'}); // Added CDE_GENDER__c and IDN_STATE__c as part of CCCAP-8307                     
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
            for(T_SBSD_INDIV__C eachIndiv : [select Id, Name from T_SBSD_INDIV__C where Id =:indivId]){
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
            
	    for(T_SBSD_CASE_INDIV__c eachCaseIndivForIndivUpdate : [select Id, IDN_CASE__r.Name, IDN_CLIENT__r.Name FROM T_SBSD_CASE_INDIV__c where IDN_CLIENT__c=:indivId]){
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
        List<UFEChangeInterface__e> ufeInfoUpdateEventList= new List<UFEChangeInterface__e>();
        Boolean isSuccessful = true;
        String message;
        try{
            if(appProcessQueue!=null){
                Boolean isBCRequested = [select idn_appln__r.UFE_Request_Flag__c from T_APPLN_PRCS_QUEUE__c where id =:appProcessQueue.Id]?.idn_appln__r?.UFE_Request_Flag__c;
                if(String.isNotEmpty(appProcessQueue.IDN_CASE__c)){
                    //update the T_APPLN_PRCS_QUEUE
                    //CDE_SOURCE = 'PEAK', IDN_CASE = IDN_CASE from the selected row, NUM_APPLN = PEAK Application Number; redirect to selected case
                    appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                    appProcessQueue.PEAK_bypass_CaseID_Validation__c = true; // Added for CCCAP-3237, CCCAP-4549 by Rishav
		    if(!Test.isRunningTest()){
                        GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new List<String>{'CDE_STATUS_APPLN__c','PEAK_bypass_CaseID_Validation__c'}); // Added CDE_STATUS_APPLN__c and PEAK_bypass_CaseID_Validation__c as part of CCCAP-8307
		    }	    
                    objectData.put('caseId',appProcessQueue.IDN_CASE__c);
                    message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue.Id;
                }else{
                    LightningServerResponse lsr = ConvertPeakDataToCHATS.convertData(appProcessQueue, individualIds);
                    System.debug('lsr in APX:'+lsr);
                    if(lsr.isSuccessful){
                        T_SBSD_CASE__c caseRec = (T_SBSD_CASE__c)lsr.objectData.get('caseRec'); 
                        appProcessQueue.IDN_CASE__c = caseRec.Id;
                        appProcessQueue.CDE_STATUS_APPLN__c = 'PRC';
                        appProcessQueue.PEAK_bypass_CaseID_Validation__c = true; // Added for CCCAP-3237 by Rishav
			if(!Test.isRunningTest()){    
                            GenericDMLHandler.updateRecords(new List<SObject>{appProcessQueue}, new Map<String,Object>{'Method__c'=>'handleCaseSelection','Class__c'=>'APXPeakApplicationToCaseController'}, new List<String>{'IDN_CASE__c','CDE_STATUS_APPLN__c','PEAK_bypass_CaseID_Validation__c'}); // Added IDN_CASE__c, CDE_STATUS_APPLN__c and PEAK_bypass_CaseID_Validation__c as part of CCCAP-8307
			}
                        objectData.put('caseId',appProcessQueue.IDN_CASE__c);
                        message = Label.Application_process_queue_record_has_been_successfully_updated+appProcessQueue.Id;
                        isSuccessful = true;
                    }else{
                        Database.rollback(sp);
                        return new LightningServerResponse(lsr.isSuccessful,lsr.errorMessage,lsr.objectData);
                    }
                }
                if(isBCRequested == true && isSuccessful==true){
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
    public static LightningServerResponse setPeakDataFlagToFalse(String caseId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        List<SObject> recordsTobeUpdated = new List<SObject>();
        recordsTobeUpdated.add(new T_SBSD_CASE__c(Id = caseId, Is_Peak_Data__c = false));
        Set<Id> caseIndivIds = new Set<Id>();
        for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = :caseId AND IDN_CLIENT__r.Is_Peak_Data__c=true]){
            /*CCCAP-14243 - Setting the bypass field when updating 'Is_Peak_Data__c' from true back to false.
            This prevents validations (that are skipped when 'Is_Peak_Data__c' is true) from firing during the update.*/
	        recordsTobeUpdated.add(new T_SBSD_INDIV__c(Id = caseIndiv.IDN_CLIENT__c, Is_Peak_Data__c = false, Bypass_On__c = System.now()));
            caseIndivIds.add(caseIndiv.Id);
        }
        if(!recordsTobeUpdated.isEmpty()){
            try{
                List<T_INDIV_CAT_RQ__c> childCareRequests = [SELECT Id,IDN_CASE_INDIV__c FROM T_INDIV_CAT_RQ__c WHERE IDN_CASE_INDIV__c IN: caseIndivIds];
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
	            GenericDMLHandler.updateRecords(recordsTobeUpdated, new Map<String,Object>{'Method__c'=>'setPeakDataFlagToFalse','Class__c'=>'APXPeakApplicationToCaseController'}, new List<String>{'Is_Peak_Data__c','Bypass_On__c'}); // Added Is_Peak_Data__c and Bypass_On__c as part of CCCAP-8307
            }catch(Exception ex){
				isSuccessful = false;
                message = ex.getMessage();
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'setPeakDataFlagToFalse'}); 
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @auraEnabled
    public static LightningServerResponse overrideClientClearance(String fName, String lName, String MI, String dob, String ssn, String gndr){
        Map<String, Object> objectData = new map<String, Object>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'APXPeakApplicationToCaseController','Method__c'=>'overrideClientClearance'};
        List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
        boolean isSuccess = false;
        string message;
        string gender = '' ;
            serviceMetaData = [SELECT id, AuthId__c, AuthToken__c, EndPoint__c, isActive__c, ServiceType__c, MasterLabel, DeveloperName FROM WebServiceConfiguration__mdt WHERE isActive__c = true AND DeveloperName = :OVERRIDECLIENTCLEARANCE LIMIT 1];
            if (!serviceMetaData.isEmpty()) {
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('POST');
                request.setHeader('Content-Type', 'Application/json');
                request.setTimeout(30000);
                if(String.isNotBlank(gndr)){
                    if(gndr == '1'){
                        gender = 'M';
                    } else if (gndr == '2'){
                        gender = 'F';
                    } else if (gndr == '3'){
                        gender = 'U';
                    } else if (gndr == '4'){
                        gender = 'X';
                    }
                }
                string endpoint = (serviceMetaData[0].EndPoint__c);
                request.setEndpoint(endpoint);
                //start - SIDMOD MODERNization Changes
                SIDMODRequestWrapper bodySidmod = new SIDMODRequestWrapper();
                SIDMODRequestWrapper.cls_person person = new SIDMODRequestWrapper.cls_person();
                person.firstName = fName!=null ? fName :null;
                person.middleName = MI!=null ? MI :null;
                person.lastName = lName!=null ? lName :null;
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
                        objectData.put('retrunMessage', resMap.get('errorMessage')); //retrunMessage
                        objectData.put('returnCode', resMap.get('statusCode')); //returnCode
                        objectData.put('errorMsg', resMap.get('errorMessage')); //errorMsg
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
                        throw new customException (string.valueOf(resMap.get('errorMessage'))); // errorMsg
                } else{
                    ExceptionLoggingServices.captureExceptionLog(response, request, methodInfo);
                    throw new customException ('The Override Service Request has failed, Please contact your Administrator.');
                } 
                
            }
        return new LightningServerResponse(isSuccess,message,objectData);
    }

    @auraEnabled
    public static LightningServerResponse getIPVDisqualification(Id individualId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful= false;
        Set<String> clientNames = new Set<String>();
        String message;
        
        for(IPV_Information__c ipvRec : [Select id ,Individual_Id__c, Individual_Id__r.NAM_FIRST__c, Individual_Id__r.NAM_LAST__c from IPV_Information__c where Individual_Id__c = :individualId AND Disqualification_Begin_Date__c <=TODAY AND (Disqualification_End_Date__c = null OR Disqualification_End_Date__c>TODAY)  AND Reversal_Created__c = false])
        {
            if(ipvRec.Individual_Id__r.NAM_FIRST__c !=null && ipvRec.Individual_Id__r.NAM_FIRST__c!=''){
                clientNames.add(ipvRec.Individual_Id__r.NAM_FIRST__c +' '+ ipvRec.Individual_Id__r.NAM_LAST__c);
            }else{
                clientNames.add(ipvRec.Individual_Id__r.NAM_LAST__c);
            }
        }
        if(clientNames.size()>0){
            List<String> lstClientNames = new List<String>(clientNames);
            isSuccessful = true;
            String warningMsg;
            warningMsg = lstClientNames[0]+' '+ Label.IPV_ACTIVE_DISQUALIFICATION_SINGLE; 
            objectData.put('warningMsg',warningMsg);
            objectData.put('ipvDisqualification', true);
        }
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }	
    // added for CCCAP-10315 for SIDMOD Notify Feature
    @auraEnabled
    public static LightningServerResponse notifySIDMOD(String stateId,Id indivId,Boolean isAppIndividual){
        return sidmodIntegrationWebservices.notifySIDMOD(stateId,indivId,isAppIndividual);
    }
    public class customException extends Exception {}
}