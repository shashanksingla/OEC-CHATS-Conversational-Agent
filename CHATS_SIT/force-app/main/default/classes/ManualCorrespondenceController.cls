public with sharing class ManualCorrespondenceController implements IRequest{
    public String jsonParam;
    private static Map<String, Object > requestObj;
    public Object processRequest(String methodName, String jsonParam) {
        Object response = null;
        this.jsonParam = jsonParam;
        if(this.jsonParam != null){
        requestObj = (Map<String, Object>)JSON.deserializeUntyped(jsonParam);  
        }      
        if (methodName == 'performdisable') {
            response = performdisable(getMapValue('correspondenceType'));
        }
        else if(methodName== 'validateCounty'){
            response = validateCounty(getMapValue('county'));
        }
        else if(methodName == 'validateCase'){
            response = validateCase(getMapValue('caseId'));
        }
        else if(methodName == 'validateProvider'){
            response = validateProvider((integer)requestObj.get('providerId'));
        }
        else if(methodName == 'validateChild'){
            response = validateChild(getMapValue('client'));
        }
        else if(methodName == 'validateAdjustment'){
            response = validateAdjustment((integer)requestObj.get('adjustment'));
        }
        else if(methodName == 'validateAdjtmtCaseProv') {
            response = validateAdjtmtCaseProv((integer)requestObj.get('caseId'),(integer)requestObj.get('providerId'),(integer)requestObj.get('adjustment'));
        }
        else if(methodName == 'validateCaseClientAssociation') {
            response = validateCaseClientAssociation(getMapValue('caseId'),getMapValue('client'));
        }
        else if(methodName == 'processManualCorspd'){
            response = processManualCorspd(getMapValue('corspdName'), getMapValue('caseId'), (integer)requestObj.get('providerId'), getMapValue('countyCode'), 
            getMapValue('cr107Checklist'), getMapValue('cr107Other'), getMapValue('cr702Checklist'), getMapValue('cr702Text'), 
            getMapValue('dteOfDeadline'), getMapValue('clientId'), getMapValue('adjustmentId'), getMapValue('cr212checklist'),
            getMapValue('DQBeginDate'), getMapValue('DQEndDate'), getMapValue('DQHearingDate'), getMapValue('numOfOccurrences'), getMapValue('ContactPhoneNumber'));
        }
        else if(methodName== 'getManualCorspdDetails'){
            response = getManualCorspdDetails(getMapValue('corrSfid'),getMapValue('provdrId'),getMapValue('casId'));
        }
        else if(methodName=='processManualCorspdPrint'){
            response = processManualCorspdPrint(getMapValue('corrSfid'));
        }
        return response;
    }
    
    private static String getMapValue(string fieldName){
        return (String)requestObj.get(fieldName);
    }
    @AuraEnabled
    public static LightningServerResponse processManualCorspd(string corspdName, string caseId, integer providerId, string countyCode, 
                                             string cr107Checklist, string cr107Other, string cr702Checklist, string cr702Text, 
                                             string dteOfDeadline, string clientId, String adjustmentId, string cr212checklist,
                                             String DQBeginDate, String DQEndDate, String DQHearingDate, String numOfOccurrences, String ContactPhoneNumber) {
                                                 return processManualCorspd1(null, corspdName ,caseId, providerId, countyCode, cr107Checklist, cr107Other, cr702Checklist, cr702Text, dteOfDeadline, clientId, adjustmentId, cr212checklist, DQBeginDate, DQEndDate, DQHearingDate, numOfOccurrences, ContactPhoneNumber);
                                             }
    
    
    @AuraEnabled
    public static LightningServerResponse processManualCorspd1(string corspdId, string corspdName, string caseId, integer providerId, string countyCode,
                                              string cr107Checklist, string cr107Other, string cr702Checklist, string cr702Text, 
                                              string dteOfDeadline, string clientId, string adjustmentId, string cr212checklist,
                                              String DQBeginDate, String DQEndDate, String DQHearingDate, String numOfOccurrences, String ContactPhoneNumber) 
    {
        boolean isSuccessful = true;
        String errorMessage='';
        Map<String,object> objectData = new Map<String,Object>();
        //CCCAP-15040 issue 1
        //Replaced with Custom Permission as part of CCCAP-14993
        if(!FeatureManagement.checkPermission('Eligibility_Worker') && !FeatureManagement.checkPermission('Eligibility_Worker_Supervisor') && !FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('Universal_User') && corspdName!='CR702' ){
            	isSuccessful = false;
            	errorMessage = 'Error! This record has restricted access. Please contact your supervisor if access is required.';   
                // end CCCAP-15040    
        }else{
        try
        {
                                                  string rsnCode, sendTo, corspdItem;
                                                  integer cntyCode;
                                                  list<corspdError> errorList = new list<corspdError>();
                                                  T_COUNTY__c countyRec = new T_COUNTY__c();
                                                  list<string> corspdIDlist1 = new list<String>();
                                                  corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
                                                  T_SBSD_CASE__C countySfidFromCase = new T_SBSD_CASE__C();
                                                  list<T_PROVR_FISCAL_AGREMENT__c> fiscalAgrmntId = new list<T_PROVR_FISCAL_AGREMENT__c>();  
                                                  Date nullDate;
                                                  
                                                  list<T_DOC_RSN__C>  rsnlist = [SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c FROM T_DOC_RSN__c WHERE NME_CORSPD__c =:corspdName AND Is_Manual__c = true LIMIT 1];
                                                  if ( rsnlist.size() == 0 ) {
                                                      AuraHandledException e = new AuraHandledException('No Records Found');
                                                      e.setMessage('No Records Found');
                                                      throw e;
                                                  } else {
                                                      rsnCode = rsnlist[0].Name;
                                                      sendTo  = rsnlist[0].CDE_TYPE_RCPT__c;
                                                  }
                                                  
                                                  Map<string, string> keyParams = new Map<string, string>();
                                                  if(sendTo == 'C') {
                                                      keyParams.put('caseId',caseId);
                                                      keyParams.put('clientId',clientId);
                                                      if(Test.isRunningTest()) {
                                                          countySfidFromCase = null;
                                                      } else {
                                                          countySfidFromCase = [select Id, CDE_COUNTY__r.CDE_COUNTY__C from T_SBSD_CASE__C where Name =:caseId];
                                                      }
                                                  } else if (sendTo == 'P') {
                                                      keyParams.put('providerId',string.valueof(providerId));
                                                  } else {
                                                      keyParams.put('caseId',caseId);
                                                      keyParams.put('providerId',string.valueOf(providerId));   
                                                      list<T_ADJMT__c> adjId = [select id, OwnerId from T_ADJMT__c where Name =:adjustmentId];
                                                      if(!adjId.isEmpty()) {
                                                          keyParams.put('adjmtId',string.valueOf(adjId[0].Id));
                                                      }
                                                      if(corspdName == 'CR207' && !String.isBlank(clientId)){
                                                          keyParams.put('clientId', clientId);
                                                      }
                                                  }
                                                  
                                                  if((countyCode != null) && (countyCode != ' ')  && (countyCode != '')) {
                                                      countyRec = [select Id, CDE_COUNTY__c FROM T_COUNTY__c WHERE Id =:countyCode LIMIT 1];
                                                  }
                                                  
                                                  if(countyRec != Null) {
                                                      cntyCode = integer.valueOf(countyRec.CDE_COUNTY__c);
                                                  }
                                                  
                                                  if(countySfidFromCase != null && cntyCode == null) {
                                                      cntyCode = integer.valueOf(countySfidFromCase.CDE_COUNTY__r.CDE_COUNTY__c);
                                                  }
                                                  
                                                  //passing fiscal Agreement owner while creating CR702 record -start
                                                  if(sendTo == 'P' && cntyCode != null) {
                                                      fiscalAgrmntId = [select Id from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__r.Name =:string.valueof(providerId) and CDE_COUNTY__r.CDE_COUNTY__c =:cntyCode and DTE_BEGIN_AGRMT__c <=:system.today() AND (DTE_END_AGRMT__c >=:system.today() OR DTE_END_AGRMT__c =:nullDate) ];
                                                      if(fiscalAgrmntId != null && fiscalAgrmntId.size()>0){
                                                          keyParams.put('faId',fiscalAgrmntId[0].Id);
                                                      }
                                                  }
                                                  //passing fiscal Agreement owner while creating CR702 record - end  
                                                  
                                                  // Start: Added below code by Rishav for CCCAP-2213 & CCCAP-2769
                                                  if(String.isNotBlank(DQBeginDate)){
                                                      keyParams.put('DQBeginDate',DQBeginDate);
                                                  }
                                                  if(String.isNotBlank(DQEndDate)){
                                                      keyParams.put('DQEndDate',DQEndDate);
                                                  }
                                                  if(String.isNotBlank(DQHearingDate)){
                                                      keyParams.put('DQHearingDate',DQHearingDate);
                                                  }
                                                  if(String.isNotBlank(numOfOccurrences)){
                                                      keyParams.put('numOfOccurrences',numOfOccurrences);
                                                  }
                                                  if(String.isNotBlank(ContactPhoneNumber)){
                                                      keyParams.put('ContactPhoneNumber',ContactPhoneNumber);
                                                  }
                                                  // End: CCCAP-2213 & CCCAP-2769
                                                  
                                                  if(corspdId == null) {
                                                          corspdIDlist1 = CorspdTrigger.createCorspdRequest(rsnCode,corspdName,sendTo,cntyCode,keyParams);
            }
                                                  if(corspdIDlist1.size() > 0) {
                                                      corspdItem =  corspdIDlist1[0];
                                                      objectData.put('corrId',corspdItem); // added for fix
                                                  }
                                                  
                                                      //insert manual correspondence in child object
                                                      // Added 'CR110' by Rishav for CCCAP-2213
                                                      if(corspdName !='CR114'  && corspdName !='CR108' && corspdName!='CR207' &&  corspdName!='CR110') {
                                                          insertChecklistObject(corspdItem, corspdName ,caseId, providerId, countyCode, cr107Checklist, cr107Other, cr702Checklist, cr702Text, dteOfDeadline,cr212checklist);
                                                      } 
                                                      if(corspdName =='CR107') {
                                                        insertMITRecords(corspdItem, corspdName, cr107Checklist);
                                                    } 
                                                      //get Manual Correspondence details
                                                      //corspdRtrnPack.payload = getManualCorspdDetails(corspdItem);
        }catch( CorspdException e) {
            isSuccessful = false;
            errorMessage = e.getMessage();
            objectData = new Map<String,Object>();
        }catch(exception ex){
            isSuccessful = false;
            errorMessage = ex.getMessage();
            objectData = new Map<String,Object>();
        }
        }
        return new LightningServerResponse(isSuccessful,errorMessage,objectData);//corspdItem;
                                              }
    
    @AuraEnabled
    public static object getManualCorspdDetails(string corrSfid,string provdrId,string casId) {
    	Map<String,String> M= new Map<String,String>{'ƒ'=>'&#131;','Š'=>'&#138;','Œ'=>'&#140;','Ž'=>'&#142;','š'=>'&#154;','œ'=>'&#156;','ž'=>'&#158;','Ÿ'=>'&#159;','À'=>'&#192;','Á'=>'&#193;','Â'=>'&#19;','Ã'=>'&#195;','Ä'=>'&#196;','Å'=>'&#197;','Æ'=>'&#198;','Ç'=>'&#199;','È'=>'&#200;','É'=>'&#201;','Ê'=>'&#202;','Ë'=>'&#203;','Ì'=>'&#204;','Í'=>'&#05;','Î'=>'&#206;','Ï'=>'&#207;','Ð'=>'&#208;','Ñ'=>'&#209;','Ò'=>'&#210;','Ó'=>'&#211;','Ô'=>'&#212;','Õ'=>'&#213;','Ö'=>'&#214;','Ø'=>'&#216;','Ù'=>'#217;','Ú'=>'&#218;','Û'=>'&#219;','Ü'=>'&#220;','Ý'=>'&#221;','Þ'=>'&#222;','ß'=>'&#223;','à'=>'&#224;','á'=>'&#225;','â'=>'&#226;','ã'=>'&#227;','ä'=>'&#228;','å'=>'&#229;','æ'=>'&#230;','ç'=>'&#231;','è'=>'&#232;','é'=>'&#233;','ê'=>'&#234;','ë'=>'&#235;','ì'=>'&#236;','í'=>'&#237;','î'=>'&#238;','ï'=>'&#239;','ð'=>'&#240;','ñ'=>'&#241;','ò'=>'&#242;','ó'=>'&#243;','ô'=>'&#244;','õ'=>'&#245;','ö'=>'&#246;','ø'=>'&#248;','ù'=>'&#249;','ú'=>'&#250;','û'=>'&#251;','ü'=>'&#252;','ý'=>'&#253;','þ'=>'&#254;','ÿ'=>'&#255;'};
        string corspdName, caseId, corrId, cntySfid, responseJSON, corrLang, xmlData,clientId;
        integer providerId;
        object responseObj;
        string adjustmentId;
        boolean isCase;
    	boolean isProvider;
        //Removed unused variable on 5/14/2018 BG  
        list<T_DOC_RQ__c> corspdList;
        try{
            corspdList = [select Name,IDN_ADJMT__c, IDN_CASE__r.Name,IDN_CLIENT__c,IDN_CLIENT__r.Name, NME_CORSPD__c, CDE_CORSPD_STATUS__c, CDE_COUNTY__c, CDE_COUNTY__r.Name, DTE_REQ__c, IDN_PROVR__r.Name, RSN_CODE__c, CDE_TYPE_RCPT__c, cde_lang_doc__c,IDN_CASE__c,createdbyId,createddate from T_DOC_RQ__c where id = :corrSfid];
        }catch(exception e){
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'getManualCorspdDetails'});
            throw new corspdException ('Error fetching data from Correspondence Request Table',e);
        }
        
        try{
            if(corspdList.size() > 0){
                if(corspdList[0].NME_CORSPD__c != null) {
                    corspdName= corspdList[0].NME_CORSPD__c;    
                }
                if(corspdList[0].IDN_CASE__r.Name != null) {
                    caseId    = corspdList[0].IDN_CASE__r.Name;    
                }
                if(corspdList[0].IDN_CLIENT__r.Name != null) {
                    clientId = corspdList[0].IDN_CLIENT__c;    
                }
                if(corspdList[0].IDN_PROVR__r.Name != null) {
                    system.debug(corspdList[0].IDN_PROVR__r.Name);
                    providerId = integer.valueof(corspdList[0].IDN_PROVR__r.Name);    
                }
                if(corspdList[0].Name != null) {
                    corrId = corspdList[0].Name ;
                }
                if(corspdList[0].CDE_COUNTY__c != null) {
                    cntySfid = corspdList[0].CDE_COUNTY__c ;
                }
                if(corspdList[0].cde_lang_doc__c != null) {
                    corrLang = corspdList[0].cde_lang_doc__c;
                }
                if(corspdList[0].IDN_ADJMT__c != null) {
                    adjustmentId = corspdList[0].IDN_ADJMT__c;
                }
            }
        } catch(exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'getManualCorspdDetails'});
            throw new corspdException('Error Assigning Data', e);
        }
        
        AbstractCorspdDataLoader corspdData ;
        try {
        	if(provdrId!=null) {
                isProvider=true;
            }
            if(casId!=null) {
                isCase=true;
            } 
            
            if(corspdName == 'CR107') {
                corspdData = new CR107DataLoader(corspdName, caseId, providerId, corrId, corrLang);
            } else if(corspdName == 'CR702') {
                corspdData = new CR702DataLoader(corspdName, caseId, providerId, corrId,cntySfid, corrLang);
            } else if(corspdName == 'CR109') {
                corspdData = new CR109DataLoader(corspdName, caseId, providerId, corrId);
            } else if(corspdName == 'CR114') {
                corspdData = new CR114DataLoader(corspdName, caseId, providerId, corrId, corrLang,clientId);
            } else if(corspdName == 'CR108') {
                corspdData = new CR108DataLoader(corspdName, caseId, providerId, corrId,corrLang);
            } else if(corspdName == 'CR207') {
                corspdData = new CR207DataLoader(corspdName, caseId, providerId, corrId, cntySfid, adjustmentId, isCase, isProvider, clientId);
            } else if(corspdName == 'CR212') {
                corspdData = new CR212DataLoader(corspdName, caseId, providerId, corrId, corrLang);
            } else if(corspdName == 'CR110') { // Added this else if by Rishav for CCCAP-2213
                corspdData = new CR110DataLoader(corspdName, caseId, providerId, corrId, corrLang, clientId);
            }
        } catch(exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'getManualCorspdDetails'});
            throw new CorspdException('Abstract object load failed-'+e.getmessage(),e);
        }
        try {
        	if(Test.isRunningTest()){
                xmlData ='<?xml version=\"1.0\" encoding="US-ASCII"?><Correspondence><County><CName></CName><Address><CLine_1></CLine_1><CLine_2></CLine_2><CCity></CCity><CState></CState><CZip></CZip></Address></County><Provider><PrName>CITY OF GRAND JUNCTION P &amp; R / ORCHARD MESA</PrName><ProviderType>SACC</ProviderType><PrAddress><PrLine_1> </PrLine_1><PrLine_2></PrLine_2><PrCity> </PrCity><PrState> </PrState><PrZip> </PrZip></PrAddress></Provider><KeyParameter><CorrespondenceId>3287</CorrespondenceId><CreationDate>2/22/2019</CreationDate><ProviderId>1559488</ProviderId></KeyParameter><Payload><DateOfDeadline></DateOfDeadline><ProviderSpecialist></ProviderSpecialist><ProviderSpecialistPhoneNumber></ProviderSpecialistPhoneNumber><CountyPhone></CountyPhone><Owner></Owner><OwnerPhnNumber></OwnerPhnNumber></Payload><ManualCorrespondence><CheckList_List><CheckList>Información del encargado del cuidado infantil</CheckList></CheckList_List><CR702_Text> </CR702_Text><M_DateOfDeadline> 02-23-2019</M_DateOfDeadline></ManualCorrespondence></Correspondence>';
            } else {
            	xmlData = corspdData.getxmldata();	
            }
             
            System.debug('xmlData = '+ xmlData);
            Httprequest request = new Httprequest();
            Http http = new Http();
            
            String fileName = corrId;
            if((string.isNotEmpty(corrLang)) && (corrLang == 'SPN')){
                fileName = fileName + '_SPN';
                corspdName = corspdName + '_SPN';
	        } else {
    	        fileName = fileName + '_ENG';
        	}
        	
        	for (String key: M.keyset())//iterate over keyset
  				{
    				xmlData = xmlData.replace(key,M.get(key));//Get CORR Value
  				}
            //String url = 'https://devaem.colorado-cdhs-chats.com/correspondenceEngine/renderLetterServlet?fileName=2179.pdf&path=correspondence/request&letterName=CR107&dataXml=<?xml%20version="1.0"%20encoding="UTF-8"%20standalone="yes"?>%20<Correspondence>%20<County>%20<CName>Denver%20County%20Department%20of%20Human%20Services</CName>%20<Address>%20<CCity>Denver</CCity>%20<CLine_1>3257%20S%20Parker%20Road</CLine_1>%20<CState>CO</CState>%20<CZip>80014-0000</CZip>%20</Address>%20</County>%20<KeyParameter>%20<CorrespondenceId>2179</CorrespondenceId>%20<CaseNumber>160000021</CaseNumber>%20<CreationDate>08/06/2018</CreationDate>%20</KeyParameter>%20<Payload>%20<ClientIntroductionSentence>false</ClientIntroductionSentence>%20<Owner>Ranjan%20Poojary</Owner>%20<ProviderIntroductionSentence>false</ProviderIntroductionSentence>%20</Payload>%20<ManualCorrespondence>%20<CheckList_List>%20<CheckList>Child%20Care%20information.%20(Provider%20name,%20phone%20number,%20start%20date,%20and%20license%20number%20if%20known).%20</CheckList>%20</CheckList_List>%20</ManualCorrespondence>%20</Correspondence>';                
            String encodedXMLData = EncodingUtil.urlEncode(xmlData , 'US-ASCII');
            encodedXMLData = encodedXMLData.replace('%E2%80%99', '\'');
            String url = Label.correspondenceAEMServerUrl ;//+ 'fileName='+fileName+'.pdf&path=correspondence/request&letterName='+corspdName+'&dataXml='+encodedXMLData;
            system.debug('The url for aem Server--'+url);
            request.setEndpoint(url);
            
            //changing to POST - passing parameters as string
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded; charset=ASCII; file.encoding=ASCII');
            system.debug('the Encoded XML data--'+ encodedXMLData);
			string bodyString1 = 'fileName='+fileName+'.pdf&path=correspondence/request&letterName='+corspdName+'&dataXml='+encodedXMLData;
            system.debug('the body in manual corr generation: '+bodyString1);
            request.setBody(bodyString1);
            request.setTimeout(120000);
            String myBase64String = EncodingUtil.base64Encode(Blob.valueOf(Label.AEMAuthenticationCredentials));
            request.setHeader('Authorization', 'Basic '+ myBase64String);
            request.setMethod('POST');
            HttpResponse response = http.send(request);
            if (response <> null && response.getStatusCode() == 200) {
                responseJSON = response.getBody();
                system.debug('The string response--'+response.getBody());
                string respString = response.getBody();
                string newJSONStr = respString.replace('<?xml version="1.0" encoding="US-ASCII"?>', '') ;
                string newJSONStr1 = newJSONStr.replace('{"ErrorCode"  : "" , "ErrorMessage" : ""}', '') ;
                responseObj = JSON.deserializeUntyped(newJSONStr1);
            }  else { 
                system.debug('Res Code ' + response.getStatusCode() +', The string response--'+response.getBody());
            }
             
        }catch (exception e){
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'getManualCorspdDetails'});
            throw new CorspdException('XMLdata  Fetch Failed -' + e.getmessage(),e);            
        }
        system.debug('responseObj--'+responseObj);
        return responseObj;
    } 
    
    @AuraEnabled
    public static string performdisable(string corspdName){
        list<T_DOC_RSN__C>  rsnlist = [SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c FROM T_DOC_RSN__c WHERE NME_CORSPD__c =:corspdName AND Is_Manual__c = true LIMIT 1];
        if ( rsnlist.size() == 0 ) {
            AuraHandledException e = new AuraHandledException('No Records Found');
            e.setMessage('No Records Found');
            throw e;
        }
        return rsnlist[0].CDE_TYPE_RCPT__c;
    }
    
    public static String validateInput(string corspdName ,string caseId, integer providerId){
        string sendTo = performdisable(corspdName); 
        return sendTo;
    }
    
    public static void insertChecklistObject (String corspdItem, string corspdName ,string caseId, integer providerId, string countyCode, string cr107Checklist ,string cr107Other, string cr702Checklist, string cr702Text, string dteOfDeadline,string cr212checklist){
        T_DOC_RQ__c corr = [select id, Name from T_DOC_RQ__c where Id =:corspdItem LIMIT 1];
        T_MNL_CORR_CHKLST__c manCorrRecord = new T_MNL_CORR_CHKLST__c(	IDN_CASE__c = caseId,
                                                                      IDN_CORR__c = corr.Name,
                                                                      CR107_Checklist__c = cr107Checklist,
                                                                      CR107_Checklist_SPN__c = cr107Checklist,
                                                                      CR107_OTHER_TEXT__c = cr107Other,
                                                                      CR702_Checklist__c = cr702Checklist,
                                                                      CR702_Checklist_SPN__c = cr702Checklist,
                                                                      CR702_TEXT__c = cr702Text,
                                                                      CR212_Checklist__c = cr212checklist,
                                                                      CR212_Checklist_SPN__c = cr212checklist);
        if(providerId != null) manCorrRecord.IDN_PROVR__c = string.valueOf(providerId);
        if(dteOfDeadline != null && dteOfDeadline != '') manCorrRecord.DTE_DEADLINE__c = date.valueOf(dteOfDeadline);
        System.debug('manCorrRecord:'+manCorrRecord);
        List<String> fieldNames = new List<String>{'IDN_CASE__c','IDN_CORR__c','CR107_Checklist__c','CR107_Checklist_SPN__c','CR107_OTHER_TEXT__c','CR702_Checklist__c','CR702_Checklist_SPN__c','CR702_TEXT__c','CR212_Checklist__c','CR212_Checklist_SPN__c','IDN_PROVR__c','DTE_DEADLINE__c'};
        // SS: Added additional paramter of fieldNames for Checkmarx CCCAP-8861
        GenericDMLHandler.insertRecords(new List<Sobject>{manCorrRecord}, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'insertChecklistObject'},fieldNames );
        //insert manCorrRecord;
    }
    public static void insertMITRecords (String corspdItem, string corspdName, string cr107Checklist){
        List<T_SBSD_CASE__C> caseToUpdate = new List<T_SBSD_CASE__C>();
        List<T_Missing_Information_tracker__c> mits = new List<T_Missing_Information_tracker__c>();
        T_DOC_RQ__c corr = [select id,createddate,createdbyId,IDN_Case__c,Name from T_DOC_RQ__c where Id =:corspdItem LIMIT 1];
        T_Missing_Information_tracker__c mit 	= new T_Missing_Information_tracker__c();
        mit.idn_case__c 					= corr.IDN_Case__c;
        mit.idn_corr_nam__c 				= corr.Name;
        mit.dte_reqstd__c 					= Date.valueOf(corr?.createddate);
        mit.idn_user_reqstd__c 				= corr?.createdbyId;
        mit.Suppressed__c					= 'No';
        mit.Missing_Verifications__c        = cr107Checklist;
        mits.add(mit);
        // Updating case
         T_SBSD_CASE__C cse = new T_SBSD_CASE__C();
        cse.Id =corr.IDN_Case__c;
        cse.IND_MissingInfo_Status__c ='NA';
        caseToUpdate.add(cse);
        //end
        if(!mits.isEmpty())
        {
            // GenericDMLHandler.insertRecords(mits, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'insertMITRecords'});
            GenericDMLHandler.insertRecords(mits, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'insertMITRecords'},new List<String>{'idn_corr_nam__c', 'dte_reqstd__c', 'idn_user_reqstd__c', 'Suppressed__c', 'Missing_Verifications__c'});
        }
        if(!caseToUpdate.isEmpty())
        {
            // GenericDMLHandler.updateRecords(caseToUpdate, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'insertMITRecords'});
            GenericDMLHandler.updateRecords(caseToUpdate, new Map<String,Object>{'Class__c'=>'ManualCorrespondenceController','Method__c'=>'insertMITRecords'},new List<String>{'IND_MissingInfo_Status__c'});
        }
    }
    @AuraEnabled
    public static string validateCase (string caseId) {
        string rtrnmessage;
        List<T_SBSD_CASE__C> validateCase = new List<T_SBSD_CASE__C>();
        validateCase = [select Id, CDE_County__c from T_SBSD_CASE__c where Name =: caseId];
        system.debug('the Case Validate-->'+validateCase.size());
        if(validateCase.size() == 1){
            Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(validateCase[0].CDE_County__c);
            if(countyMatched){
            	rtrnmessage = 'ValidCase';
            } else {
                rtrnmessage = 'InvalidCaseCounty';
            }
        } else {
            rtrnmessage = 'InvalidCase';
        }
        return rtrnmessage;
    }
    
	@AuraEnabled
    public static string validateAdjustment (integer adjustmentId) {
        string rtrnmessage;
        string returnValidateadjAndPro;
        List<T_ADJMT__c> validateProvider = new List<T_ADJMT__c>();
        List<T_ADJMT__c> validateadjAndPro = new List<T_ADJMT__c>();
        List<T_ADJMT__c> validateadjAndCase = new List<T_ADJMT__c>();
        validateProvider = [select Id, CDE_County__c from T_ADJMT__c where Name =: string.valueOf(adjustmentId) AND CDE_STATUS_ADJMT__c='2' AND CDE_TYPE_ADJMT__c='2'];
        if(validateProvider.size() == 1){
            Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(validateProvider[0].CDE_County__c);
            if(countyMatched){
                rtrnmessage = 'ValidAdjustment';
            } else {
                rtrnmessage = 'InvalidAdjustmentCounty';
            }
        } else {
            System.debug('validateAdjustment:302 ');
            rtrnmessage = 'InvalidAdjustment';
        }
        return rtrnmessage;
    }
    
    @AuraEnabled
    public static string validateAdjtmtCaseProv (integer adjustmentId,integer providerId,integer caseId) {
        string rtrnmessage;
        string returnValidateadjAndPro;
        string validateProvAndCase;
        List<T_ADJMT__c> validateProvider = new List<T_ADJMT__c>();
        List<T_ADJMT__c> validateadjAndPro = new List<T_ADJMT__c>();
        List<T_ADJMT__c> validateadjAndCase = new List<T_ADJMT__c>();
        if(providerId!=null){            
            validateadjAndPro=[select Id, CDE_County__c from T_ADJMT__c where name =: string.valueOf(adjustmentId) AND IDN_PROVR__r.Name=: string.valueOf(providerId)];
            if(validateadjAndPro.size() == 1){
                Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(validateadjAndPro[0].CDE_County__c);
                if(countyMatched){
                    rtrnmessage = 'validProvAndCase';
                } else {
                    rtrnmessage = 'InvalidProvAndCaseCounty';
                }
            } else {
                rtrnmessage = 'InvalidvalidProvAndCase';
            }
        }else if(caseId!=null){
            validateadjAndCase=[select Id, CDE_County__c from T_ADJMT__c where name =: string.valueOf(adjustmentId) AND IDN_CASE__r.Name =: string.valueOf(caseId)];            
            if(validateadjAndCase.size() == 1){
                Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(validateadjAndCase[0].CDE_County__c);
                if(countyMatched){
                    rtrnmessage = 'validProvAndCase';
                }else {
                    rtrnmessage = 'InvalidProvAndCaseCounty';
                }
            } else  {
                rtrnmessage = 'InvalidvalidProvAndCase';
            }
        }else{
             rtrnmessage = 'InvalidvalidProvAndCase';
        } 
        return rtrnmessage;
    }
    
    @AuraEnabled
    public static string validateProvider (integer providerId) {
        string rtrnmessage;
        List<T_CHATS_PROVR_STATUS__C> validateProvider = new List<T_CHATS_PROVR_STATUS__C>();
        validateProvider = [select Id, CDE_COUNTY_OWNER__c from T_CHATS_PROVR_STATUS__C where Name =: string.valueOf(providerId)];
        if(validateProvider.size() == 1){
            Boolean countyMatched = CHATSUtility.checkCountyforProvider(validateProvider[0].Id);
            if(countyMatched){
                rtrnmessage = 'ValidProvider';
            } else {
                rtrnmessage = 'InvalidProviderCounty';
            }
        } else {
            rtrnmessage = 'InvalidProvider';
        }
        return rtrnmessage;
    }
    
    // Added by Rishav for CCCAP-4245
    @AuraEnabled
    public static Boolean validateCaseClientAssociation(String caseId, String clientId) {
        List<T_SBSD_CASE_INDIV__c> caseIndivList = [SELECT Id FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__r.Name =:caseId AND IDN_CLIENT__r.Name =: clientId];
        return caseIndivList.isEmpty();
    }
    
    @AuraEnabled
    public static string validateChild (string clientId) {
        string rtrnmessage;
        List<T_SBSD_INDIV__c> validateChild = new List<T_SBSD_INDIV__c>();
        validateChild = [select Id from T_SBSD_INDIV__c where Name =: clientId];
        system.debug('the Case Validate-->'+validateChild.size());
        if(validateChild.size() == 1){
            rtrnmessage = 'ValidChild';
        } else {
            rtrnmessage = 'InvalidChild';
        }
        return rtrnmessage;
    }
    
    @AuraEnabled
    public static Map<String, Object> validateCounty(string county) { 
        Map<String, Object> responseMap = new Map<String, Object>();
        Boolean countyMatched = true;
        system.debug('county'+county);
        if(String.isNotBlank(county)){
            countyMatched = CHATSUtility.checkCountyWithUserCounty(county);
            List<T_COUNTY__c> counties = [SELECT Name FROM T_COUNTY__c WHERE Id = :county];
            responseMap.put('countyName', counties[0].Name);
        }        
        responseMap.put('isValid', countyMatched);
        return responseMap; 
    }
    
    @AuraEnabled
    public static corspdReturnPacket processManualCorspdPrint(String corrSfid){
        corspdReturnPacket corspdRtrnPack = new corspdReturnPacket();
         
        list<corspdError> errorList = new list<corspdError>();
        List<T_DOC_RQ__c> lstCorspdSFId = new List<T_DOC_RQ__c>();
        List<T_Missing_Information_tracker__c> mits = new List<T_Missing_Information_tracker__c>(); 
        Set<String> corrNames = new Set<String>();
        List<T_DOC_RQ__c> lstCorspdDetailsToAssemble = new List<T_DOC_RQ__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'corspdPrintQueue','Method__c'=>'processCorspdPrint'};
     	 if(corrSfid != Null){
            lstCorspdDetailsToAssemble = [select Id,Name,isPrinted__c, CreatedById, DTE_REQ__c,NME_CORSPD__c, cde_lang_doc__c from T_DOC_RQ__c where id =:corrSfid];
        }
        try{
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
                            generator.writeObjectField('isPrinted',false);
                        }else{
                            generator.writeObjectField('isPrinted',false);
                        }
                        
                    	generator.writeEndObject();
                	}
                	generator.writeEndArray();
            	}
            	String JSONString = generator.getAsString();
            	
                    
                if(String.isNotEmpty(JSONString)){
                   
                    
                    httpRequest.setEndpoint(sUrl); 
                    httpRequest.setMethod('POST');
                    httpRequest.setBody(JSONString);
                    httpRequest.setTimeout(120000);
                   
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
                            GenericDMLHandler.updateRecords(mits, methodInfo);
                        }
                        //end CCCAP-11835
                        String responseJSON = httpResponse.getBody();
                        system.debug('Body --->'+httpResponse.getBody());
                        if(httpResponse.getBody() != ''){
                            corspdRtrnPack.payload = JSON.deserializeUntyped(httpResponse.getBody());     
                        }
                    }else {System.debug('line 368 else');
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
        }catch( CorspdException e){
            CorspdError errorObj = new CorspdError();
            errorObj.errorMsg = 'Error in Method - correspondence list to Print :' + e.getMessage();
            errorList.add(errorObj);      
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);                                   
        }if(errorList.size() > 0){
            corspdRtrnPack.returnStatus = 'Failure';
            corspdRtrnPack.errorMessage = errorList;            
        }else{
            corspdRtrnPack.returnStatus = 'Success';
        }
        return corspdRtrnPack;
    }
}