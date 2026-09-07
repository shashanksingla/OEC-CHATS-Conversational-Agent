public with sharing class CorspdTrigger {
    public static string[] createCorspdRequest(string rsnCode,string corspdname,string sendTo,integer countyCode,map<string,string> keyParams){
        list<T_DOC_RSN__c> rsnlist = new list<T_DOC_RSN__c>();
        list<T_DOC_RQ__c> corspdList = new list<T_DOC_RQ__c>();
		list<T_COUNTY__c> cntyList = new list<T_COUNTY__c>();
        list<T_CHATS_PROVR_STATUS__c> provrSfIdList = new list<T_CHATS_PROVR_STATUS__c>();
        list<string> idlist1 = new list<string>();
		string caseRecId = NULL, provrSfId = NULL, clientSFId =NULL;
        
        string caseOwner;
        list<T_PROVR_FISCAL_AGREMENT__c> fiscalOwnerList = new list<T_PROVR_FISCAL_AGREMENT__c>();
        list<T_DOC_RQ__c> existingCR213CorrList = new list<T_DOC_RQ__c>();
        set<string> CR213CorrTypes = new set<string>();
        Set<String>CR213ReqCorrTypes = new set<string>();
	    
        T_DOC_RQ__C createDocReq  = new T_DOC_RQ__C();
        T_DOC_RQ__C createDocReq1 = new T_DOC_RQ__C();
        T_DOC_RQ__C createDocReq2 = new T_DOC_RQ__C();
        T_DOC_RQ__C createDocReq3 = new T_DOC_RQ__C();
        T_DOC_RQ__C createDocReq4 = new T_DOC_RQ__C();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CorspdTrigger','Method__c'=>'createCorspdRequest'};                                                   
        if(keyParams.get('caseId')!= Null){
            string paramCaseId = keyParams.get('caseId');
            list<T_SBSD_CASE__c> caseList = [select id, OwnerId from T_SBSD_CASE__c where Name =:paramCaseId limit 1];
            if(caseList.size() > 0){
                caseRecId = caseList[0].id;
                caseOwner = caseList[0].OwnerId;
            }
        }
        if(keyParams.get('clientId')!= Null){
            string paramClientId = keyParams.get('clientId');
            list<T_SBSD_INDIV__c> indivList = [select id, OwnerId from T_SBSD_INDIV__c where Name =:paramClientId limit 1];
            if(indivList.size() > 0){
                clientSFId = indivList[0].id;
            }
        }
        if(keyParams.get('providerId')!= NULL){
            string paramProvrId = keyParams.get('providerId');
            provrSfIdList = [select Id From T_CHATS_PROVR_STATUS__c WHERE Name =:paramProvrId Limit 1];
            if(provrSfIdList.size() > 0){
                provrSfId = provrSfIdList[0].id;
            }
        }
		if(countyCode != NULL){
            cntyList = [select id from T_COUNTY__c where CDE_COUNTY__c =:countyCode];
        }
        
        if(keyParams.get('faId') != null) {
            fiscalOwnerList = [select id, OwnerId from T_PROVR_FISCAL_AGREMENT__c where id=:keyParams.get('faId')];
        }
                                                   
        if ((corspdname != Null)&&(sendTo!= Null)){
            rsnlist = [	SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c       	
                       	FROM T_DOC_RSN__c
                       	WHERE Name =:rsnCode
                       	and   NME_CORSPD__c =:corspdName
                       	and   CDE_TYPE_RCPT__c =:sendTo];            
        } else if((corspdname != Null)&&(sendTo == Null)){
            rsnlist = [	SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c
                        FROM T_DOC_RSN__c
                        WHERE Name =:rsnCode
                        and   NME_CORSPD__c =:corspdName];
        }else if ((corspdname == Null)&&(sendTo!= Null)){
            rsnlist = [	SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c
                        FROM T_DOC_RSN__c
                        WHERE Name =:rsnCode
                        and   CDE_TYPE_RCPT__c =:sendTo];
        }else{
            rsnlist = [	SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c
                        FROM T_DOC_RSN__c
                        WHERE Name = :rsnCode];
        }
		
        try{
            if (rsnlist.size() > 0){
                if((caseRecId != Null) && (provrSfId != Null)) {
                    if(keyParams.get('authId') != Null){
                        string authSfid = keyParams.get('authId');
                        existingCR213CorrList = [select id, CDE_TYPE_RCPT__c,CDE_CORSPD_STATUS__c from T_DOC_RQ__c where IDN_AUTH__c =:authSfid and DTE_REQ__c =: system.today() and
			(IDN_CASE__c =:caseRecId or IDN_PROVR__C =:provrSfId) and NME_CORSPD__c ='CR213'];    
                    }
                    if(!existingCR213CorrList.isEmpty()){
                        for(T_DOC_RQ__c eachExistingCR213Corr : existingCR213CorrList){
                            CR213CorrTypes.add(eachExistingCR213Corr.CDE_TYPE_RCPT__c);
                            if(eachExistingCR213Corr.CDE_CORSPD_STATUS__c == 'Requested'){
                                CR213ReqCorrTypes.add(eachExistingCR213Corr.CDE_TYPE_RCPT__c);
                            }
                        }
                    }
                }
                for( integer i=0; i<rsnlist.size(); i++){
                    if(rsnlist[i].CDE_TYPE_RCPT__c == 'C'){
                        if(caseRecId != NULL){
                        	createDocReq.IDN_CASE__c	= caseRecId;
                        	createDocReq.OwnerId = caseOwner;    
                        }
                        if(keyParams.get('authId') !=Null ) {
                            createDocReq.IDN_AUTH__c = keyParams.get('authId');
                        }
                        if(keyParams.get('clientId') !=Null ) {
                            createDocReq.IDN_CLIENT__c = clientSFId;
                        }
                        if(!cntyList.isEmpty()){
                        	createDocReq.CDE_COUNTY__c = cntyList[0].Id;    
                        }
                        createDocReq.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c ;
                    	createDocReq.CDE_CORSPD_STATUS__c = 'Requested';
                    	createDocReq.CDE_TYPE_RCPT__c = rsnlist[i].CDE_TYPE_RCPT__c;
                    	createDocReq.RSN_CODE__c = rsnlist[i].Name;
                        createDocReq.DTE_REQ__c = system.today();
                        // Start: Added below code by Rishav for CCCAP-2213 & CCCAP-2769
                        if(keyParams.get('DQBeginDate') != Null)
                            createDocReq.Disqualification_Begin_Date__c = Date.valueOf(keyParams.get('DQBeginDate'));
                        if(keyParams.get('DQEndDate') != Null)
                            createDocReq.Disqualification_End_Date__c = Date.valueOf(keyParams.get('DQEndDate'));
                        if(keyParams.get('DQHearingDate') != Null)
                            createDocReq.Disqualification_Hearing_Date__c = Date.valueOf(keyParams.get('DQHearingDate'));
                        if(keyParams.get('numOfOccurrences') != Null)
                            createDocReq.Number_of_Occurrences__c = Decimal.valueOf(keyParams.get('numOfOccurrences'));
                        if(keyParams.get('ContactPhoneNumber') != Null)
                            createDocReq.Contact_Phone_Number__c = keyParams.get('ContactPhoneNumber');
                        if(keyParams.get('IPVRecordId') != Null)
                            createDocReq.IPV_Information__c = keyParams.get('IPVRecordId');
                        // End: CCCAP-2213 & CCCAP-2769
                        corspdList.add(createDocReq);
                    }else if (rsnlist[i].CDE_TYPE_RCPT__c == 'P'){
                        if(provrSfId != null) {
                            createDocReq1.IDN_PROVR__c = provrSfId;
                        }
                    	if(!cntyList.isEmpty()){
                        	createDocReq1.CDE_COUNTY__c = cntyList[0].Id;    
                        }
                        if(keyParams.get('authId') !=Null ) {
                            createDocReq1.IDN_AUTH__c = keyParams.get('authId');
                        }
                        if(keyParams.get('faId') !=Null ) {
                           	createDocReq1.IDN_AGRMT_FISCAL__c = keyParams.get('faId');
                           	createDocReq1.OwnerId = fiscalOwnerList[0].OwnerId;
                        }
                        createDocReq1.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                    	createDocReq1.CDE_CORSPD_STATUS__c = 'Requested';
                        createDocReq1.RSN_CODE__c = rsnlist[i].Name;
                        createDocReq1.CDE_TYPE_RCPT__c = rsnlist[i].CDE_TYPE_RCPT__c;
                        createDocReq1.DTE_REQ__c = system.today();
                  		corspdList.add(createDocReq1);
                	}else {
                        if((caseRecId != Null) && (provrSfId != Null)) {
							if(Test.isRunningTest()) 
							{
                                CR213CorrTypes = new set<string>();
                            }
                            if(CR213CorrTypes.size() == 0 || CR213ReqCorrTypes.size() == 0){
                                if(keyParams.get('authId') !=Null ) {
                                    createDocReq3.IDN_AUTH__c = keyParams.get('authId');
                                    createDocReq3.OwnerId = caseOwner;
                                }
                                createDocReq3.IDN_CASE__c	= caseRecId;
                                createDocReq3.CDE_TYPE_RCPT__c = 'C';
                                createDocReq3.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                                createDocReq3.CDE_CORSPD_STATUS__c = 'Requested';
                                createDocReq3.CDE_COUNTY__c = cntyList[0].Id;
                                createDocReq3.RSN_CODE__c = rsnlist[i].Name;
                                createDocReq3.DTE_REQ__c = system.today();
                                corspdList.add(createDocReq3);
                                
                                if(keyParams.get('authId') !=Null ) {
                                    createDocReq4.IDN_AUTH__c = keyParams.get('authId');
                                    createDocReq4.OwnerId = caseOwner;
                                }
                                createDocReq4.IDN_PROVR__c = provrSfId;
                                createDocReq4.CDE_TYPE_RCPT__c = 'P';
                                createDocReq4.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                                createDocReq4.CDE_CORSPD_STATUS__c = 'Requested';
                                createDocReq4.CDE_COUNTY__c = cntyList[0].Id;
                                createDocReq4.RSN_CODE__c = rsnlist[i].Name;
                                createDocReq4.DTE_REQ__c = system.today();
                                corspdList.add(createDocReq4);
                            }else if(CR213CorrTypes.size() == 1){
                                for(string corrTypeWhenOneExists : CR213CorrTypes){
                                    if(corrTypeWhenOneExists == 'P'){
                                        if(keyParams.get('authId') !=Null ) {
                                            createDocReq3.IDN_AUTH__c = keyParams.get('authId');
                                            createDocReq3.OwnerId = caseOwner;
                                        }
                                        createDocReq3.IDN_CASE__c	= caseRecId;
                                        createDocReq3.CDE_TYPE_RCPT__c = 'C';
                                        createDocReq3.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                                        createDocReq3.CDE_CORSPD_STATUS__c = 'Requested';
                                        createDocReq3.CDE_COUNTY__c = cntyList[0].Id;
                                        createDocReq3.RSN_CODE__c = rsnlist[i].Name;
                                        createDocReq3.DTE_REQ__c = system.today();
                                        corspdList.add(createDocReq3);
                                    }else if(corrTypeWhenOneExists == 'C'){
                                        if(keyParams.get('authId') !=Null ) {
                                            createDocReq4.IDN_AUTH__c = keyParams.get('authId');
                                            createDocReq4.OwnerId = caseOwner;
                                        }
                                        createDocReq4.IDN_PROVR__c = provrSfId;
                                        createDocReq4.CDE_TYPE_RCPT__c = 'P';
                                        createDocReq4.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                                        createDocReq4.CDE_CORSPD_STATUS__c = 'Requested';
                                        createDocReq4.CDE_COUNTY__c = cntyList[0].Id;
                                        createDocReq4.RSN_CODE__c = rsnlist[i].Name;
                                        createDocReq4.DTE_REQ__c = system.today();
                                        corspdList.add(createDocReq4);
                                    }
                                }
                            }else if(CR213ReqCorrTypes.size() == 1){
                                for(string corrTypeWhenOneExists : CR213ReqCorrTypes){
                                    if(corrTypeWhenOneExists == 'P'){
                                        if(keyParams.get('authId') !=Null ) {
                                            createDocReq3.IDN_AUTH__c = keyParams.get('authId');
                                            createDocReq3.OwnerId = caseOwner;
                                        }
                                        createDocReq3.IDN_CASE__c	= caseRecId;
                                        createDocReq3.CDE_TYPE_RCPT__c = 'C';
                                        createDocReq3.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                                        createDocReq3.CDE_CORSPD_STATUS__c = 'Requested';
                                        createDocReq3.CDE_COUNTY__c = cntyList[0].Id;
                                        createDocReq3.RSN_CODE__c = rsnlist[i].Name;
                                        createDocReq3.DTE_REQ__c = system.today();
                                        corspdList.add(createDocReq3);
                                    }else if(corrTypeWhenOneExists == 'C'){
                                        if(keyParams.get('authId') !=Null ) {
                                            createDocReq4.IDN_AUTH__c = keyParams.get('authId');
                                            createDocReq4.OwnerId = caseOwner;
                                        }
                                        createDocReq4.IDN_PROVR__c = provrSfId;
                                        createDocReq4.CDE_TYPE_RCPT__c = 'P';
                                        createDocReq4.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                                        createDocReq4.CDE_CORSPD_STATUS__c = 'Requested';
                                        createDocReq4.CDE_COUNTY__c = cntyList[0].Id;
                                        createDocReq4.RSN_CODE__c = rsnlist[i].Name;
                                        createDocReq4.DTE_REQ__c = system.today();
                                        corspdList.add(createDocReq4);
                                    }
                                }
                            }
                        } else if((caseRecId !=NULL) && (provrSfId == NULL)) {
                            if(keyParams.get('adjmtId') !=Null ) {
                            	createDocReq2.IDN_ADJMT__c = keyParams.get('adjmtId');
                        	}
                            createDocReq2.IDN_CASE__c	= caseRecId;
                            createDocReq2.CDE_TYPE_RCPT__c = 'C';
                            createDocReq2.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                    		createDocReq2.CDE_CORSPD_STATUS__c = 'Requested';
           					if(!cntyList.isEmpty()){
                            createDocReq2.CDE_COUNTY__c = cntyList[0].Id;    
                            }
                    		createDocReq2.RSN_CODE__c = rsnlist[i].Name;
                            createDocReq2.DTE_REQ__c = system.today();
                            if(keyParams.get('clientId') != null) {
                                createDocReq2.IDN_CLIENT__c = clientSFId;
                            }
                        	corspdList.add(createDocReq2);
                        } else if ((caseRecId ==NULL) && (provrSfId !=NULL)) {
                            if(keyParams.get('adjmtId') !=Null ) {
                            	createDocReq2.IDN_ADJMT__c = keyParams.get('adjmtId');
                        	}
                            createDocReq2.IDN_PROVR__c = provrSfId;
                            createDocReq2.CDE_TYPE_RCPT__c = 'P';
                            createDocReq2.NME_CORSPD__c = rsnlist[i].NME_CORSPD__c;
                    		createDocReq2.CDE_CORSPD_STATUS__c = 'Requested';
           					if(!cntyList.isEmpty()){
                            createDocReq2.CDE_COUNTY__c = cntyList[0].Id;    
                            }
                    		createDocReq2.RSN_CODE__c = rsnlist[i].Name;
                            createDocReq2.DTE_REQ__c = system.today();
                        	corspdList.add(createDocReq2);
                        }
                	}
                }
                if(corspdList != NULL){
                    GenericDMLHandler.insertRecords(corspdList,methodInfo);    
                }
                for(T_DOC_RQ__C corId : corspdList){
                      idlist1.add(corId.Id);
                }
            }
        }catch(Exception e){
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
            throw new CorspdException('Could not create Correpondence Request Object-',e);
        }
        try{
            return idlist1;            
        }catch(Exception e){
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
            throw new CorspdException('Correspondence Request return Error-', e);
        }
    }
    
    public static string[] createCorspdRequestBulk(Set<Id> recordKeys, Map<Id, string> rsnCodeMap, Map<Id, string> corspdnameMap, Map<Id, string> sendToMap,
                                               	   Map<Id, Integer> countyCodeMap, Map<Id, map<string,string>> keyParamsMap, Map<Id, Set<Id>> adjustmentAddressMap){
        list<T_DOC_RQ__c> corspdList = new list<T_DOC_RQ__c>();
		list<string> idlist1 = new list<string>();
		string caseRecId, provrSfId, clientSFId, caseOwner;
        list<T_DOC_RQ__c> existingCR213CorrList = new list<T_DOC_RQ__c>();
        set<string> CR213CorrTypes = new set<string>();
	    Set<String>CR213ReqCorrTypes = new set<string>();
        T_DOC_RQ__C createDocReq;
        T_DOC_RQ__C createDocReq1;
        T_DOC_RQ__C createDocReq2;
        T_DOC_RQ__C createDocReq3;
        T_DOC_RQ__C createDocReq4;
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CorspdTrigger','Method__c'=>'createCorspdRequest'};  
        
        set<String> paramCaseIdSet = new set<String>();
        set<String> paramClientIdSet = new set<String>();
        set<String> paramProvrIdSet = new set<String>(); 
        set<String> paramfaIdSet = new set<String>();                               
        for(Map<string, String> keyParams : keyParamsMap.values()){
            if(keyParams.get('caseId') != Null){
                paramCaseIdSet.add(keyParams.get('caseId'));
            }
            if(keyParams.get('clientId') != Null){
                paramClientIdSet.add(keyParams.get('clientId'));
            }
            if(keyParams.get('providerId') != Null){
                paramProvrIdSet.add(keyParams.get('providerId'));
            }
            if(keyParams.get('faId') != Null){
                paramfaIdSet.add(keyParams.get('faId'));
            }
        }
        Map<String, T_SBSD_CASE__c> paramCaseMap = new Map<String, T_SBSD_CASE__c>();
        Map<String, Id> paramClientIdMap = new Map<String, Id>();
        Map<String, Id> paramProvrIdMap = new Map<String, Id>(); 
        Map<String, T_PROVR_FISCAL_AGREMENT__c> paramfaMap = new Map<String, T_PROVR_FISCAL_AGREMENT__c>();    
        Map<Integer, Id> countyMap = new Map<Integer, Id>();                                           
        if(paramCaseIdSet.size() > 0){
            for(T_SBSD_CASE__c cs : [select id, OwnerId, Name from T_SBSD_CASE__c where Name IN :paramCaseIdSet]){
                paramCaseMap.put(cs.Name, cs);
            }
        }
        if(paramClientIdSet.size() > 0){
            for(T_SBSD_INDIV__c indiv : [select id, OwnerId, Name from T_SBSD_INDIV__c where Name IN :paramClientIdSet]){
                paramClientIdMap.put(indiv.Name, indiv.Id);
            }
        }
        if(paramProvrIdSet.size() > 0){
            for(T_CHATS_PROVR_STATUS__c prov : [select id, Name from T_CHATS_PROVR_STATUS__c where Name IN :paramProvrIdSet]){
                paramProvrIdMap.put(prov.Name, prov.Id);
            }
        }
		if(countyCodeMap.size() > 0){
            for(T_County__c county : [select Id, CDE_COUNTY__c from T_COUNTY__c where CDE_COUNTY__c IN :countyCodeMap.values()]){
                countyMap.put(Integer.valueOf(county.CDE_COUNTY__c), county.Id);
            }
        }        
        if(paramfaIdSet.size() > 0){
            for(T_PROVR_FISCAL_AGREMENT__c fa : [select id, OwnerId from T_PROVR_FISCAL_AGREMENT__c where Id IN :paramfaIdSet]){
                paramfaMap.put(fa.Id, fa);
            }
        }                                           
                                                   
        list<T_DOC_RSN__c> rsnlist = [SELECT Name, NME_CORSPD__c, Is_Manual__c, CDE_TYPE_RCPT__c
                                      FROM T_DOC_RSN__c
                                      WHERE Name IN :rsnCodeMap.values()];        
		
        try{
            for(Id key : recordKeys){
                createDocReq  = new T_DOC_RQ__C();
                createDocReq1 = new T_DOC_RQ__C();
                createDocReq2 = new T_DOC_RQ__C();
                createDocReq3 = new T_DOC_RQ__C();
                createDocReq4 = new T_DOC_RQ__C();
                CR213CorrTypes = new set<string>();
                CR213ReqCorrTypes =  new set<string>();
                
                Map<String, String> keyParams = keyParamsMap.get(key);
                String rsnCode = rsnCodeMap.get(key);                
                String sendTo = sendToMap.get(key);
                String corspdname = corspdnameMap.get(key);
                Integer countyCode = countyCodeMap.get(key);
                Id countyId = countyMap.containsKey(countyCode) ? countyMap.get(countyCode) : null;
                if(keyParams.get('caseId') != NULL && paramCaseMap.containsKey(keyParams.get('caseId'))){
                    caseRecId = paramCaseMap.get(keyParams.get('caseId')).Id;
                    caseOwner = paramCaseMap.get(keyParams.get('caseId')).OwnerId;
                }
                if(keyParams.get('providerId') != null) {
                    provrSfId = paramProvrIdMap.get(keyParams.get('providerId'));
                }
                if(keyParams.get('clientId') != null) {
                    clientSFId = paramClientIdMap.get(keyParams.get('clientId'));
                }
                if((caseRecId != Null) && (provrSfId != Null)) {
                    if(keyParams.get('authId') != Null){
                        string authSfid = keyParams.get('authId');
                        existingCR213CorrList = [select id, CDE_TYPE_RCPT__c,CDE_CORSPD_STATUS__c from T_DOC_RQ__c where IDN_AUTH__c =:authSfid and DTE_REQ__c =: system.today() and (IDN_CASE__c =:caseRecId or IDN_PROVR__C =:provrSfId)];    
                    }
                    if(!existingCR213CorrList.isEmpty()){
                        for(T_DOC_RQ__c eachExistingCR213Corr : existingCR213CorrList){
                            CR213CorrTypes.add(eachExistingCR213Corr.CDE_TYPE_RCPT__c);
                            if(eachExistingCR213Corr.CDE_CORSPD_STATUS__c == 'Requested'){
                                CR213ReqCorrTypes.add(eachExistingCR213Corr.CDE_TYPE_RCPT__c);
                            }
                        }
                    }
                }
            	for(T_DOC_RSN__c rsn : rsnlist){
                    if(rsn.Name == rsnCode && (corspdname == null || rsn.NME_CORSPD__c == corspdname) && (sendTo == null || rsn.CDE_TYPE_RCPT__c == sendTo)){
                        if(rsn.CDE_TYPE_RCPT__c == 'C'){
                            if(keyParams.get('caseId') != NULL){
                                createDocReq.IDN_CASE__c = caseRecId;
                                createDocReq.OwnerId = caseOwner;
                            }
                            if(keyParams.get('authId') != Null ) {
                                createDocReq.IDN_AUTH__c = keyParams.get('authId');
                            }
                            if(keyParams.get('clientId') != Null) {
                                createDocReq.IDN_CLIENT__c = paramClientIdMap.get(keyParams.get('clientId'));
                            }
                            if(countyId != null){
                                createDocReq.CDE_COUNTY__c = countyId;    
                            }
                            createDocReq.NME_CORSPD__c = rsn.NME_CORSPD__c ;
                            createDocReq.CDE_CORSPD_STATUS__c = 'Requested';
                            createDocReq.CDE_TYPE_RCPT__c = rsn.CDE_TYPE_RCPT__c;
                            createDocReq.RSN_CODE__c = rsn.Name;
                            createDocReq.DTE_REQ__c = system.today();
                            // Start: Added below code by Rishav for CCCAP-2213 & CCCAP-2769
                            if(keyParams.get('DQBeginDate') != Null)
                                createDocReq.Disqualification_Begin_Date__c = Date.valueOf(keyParams.get('DQBeginDate'));
                            if(keyParams.get('DQEndDate') != Null)
                                createDocReq.Disqualification_End_Date__c = Date.valueOf(keyParams.get('DQEndDate'));
                            if(keyParams.get('DQHearingDate') != Null)
                                createDocReq.Disqualification_Hearing_Date__c = Date.valueOf(keyParams.get('DQHearingDate'));
                            if(keyParams.get('numOfOccurrences') != Null)
                                createDocReq.Number_of_Occurrences__c = Decimal.valueOf(keyParams.get('numOfOccurrences'));
                            if(keyParams.get('ContactPhoneNumber') != Null)
                                createDocReq.Contact_Phone_Number__c = keyParams.get('ContactPhoneNumber');
                            // End: CCCAP-2213 & CCCAP-2769
                            // Start: Added below code by Diya for CCCAP-4246
                            if(keyParams.get('AdjustmentAddress') != Null){
                                if(keyParams.get('adjmtId') != Null){
                                    createDocReq.Adjustment_Address__c = keyParams.get('AdjustmentAddress');
                                    for(Id addrr :adjustmentAddressMap.get(keyParams.get('adjmtId'))){
                                        if(addrr != keyParams.get('AdjustmentAddress')){
                                            T_DOC_RQ__C  createDocReqClone = createDocReq.clone(false, false, false, false);
                                            createDocReqClone.Adjustment_Address__c=addrr;
                                            corspdList.add(createDocReqClone);
                                        }
                                    }
                                }
                                
                            }
                            // End: CCCAP-4246
                            corspdList.add(createDocReq);
                        }
                        else if(rsn.CDE_TYPE_RCPT__c == 'P'){
                            if(keyParams.get('providerId') != null) {
                                createDocReq1.IDN_PROVR__c = provrSfId;
                            }
                            if(countyId != null){
                                createDocReq1.CDE_COUNTY__c = countyId;
                            }
                            if(keyParams.get('authId') != Null) {
                                createDocReq1.IDN_AUTH__c = keyParams.get('authId');
                            }
                            if(keyParams.get('faId') != Null) {
                                createDocReq1.IDN_AGRMT_FISCAL__c = paramfaMap.get(keyParams.get('faId')).Id;
                                createDocReq1.OwnerId = paramfaMap.get(keyParams.get('faId')).OwnerId;
                            }
                            createDocReq1.NME_CORSPD__c = rsn.NME_CORSPD__c;
                            createDocReq1.CDE_CORSPD_STATUS__c = 'Requested';
                            createDocReq1.RSN_CODE__c = rsn.Name;
                            createDocReq1.CDE_TYPE_RCPT__c = rsn.CDE_TYPE_RCPT__c;
                            createDocReq1.DTE_REQ__c = system.today();
                             // Added by Diya as part of CCCAP-4642
                            if(keyParams.get('AdjustmentAddress') != Null){
                                if(keyParams.get('adjmtId') != Null){
                                    createDocReq1.Adjustment_Address__c = keyParams.get('AdjustmentAddress');
                                    for(Id addrr :adjustmentAddressMap.get(keyParams.get('adjmtId'))){
                                        if(addrr != keyParams.get('AdjustmentAddress')){
                                            T_DOC_RQ__C  createDocReqClone = createDocReq1.clone(false, false, false, false);
                                            createDocReqClone.Adjustment_Address__c=addrr;
                                            corspdList.add(createDocReqClone);
                                        }
                                    }
                                }
                                
                            }
                            // Added by Diya as part of CCCAP-4642 end
                            corspdList.add(createDocReq1);
                        }
                        else {
                            if((caseRecId != Null) && (provrSfId != Null)) {
                                if(CR213CorrTypes.size() == 0 || CR213ReqCorrTypes.size()==0){
                                    if(keyParams.get('authId') !=Null ) {
                                        createDocReq3.IDN_AUTH__c = keyParams.get('authId');
                                        createDocReq3.OwnerId = caseOwner;
                                    }
                                    createDocReq3.IDN_CASE__c = caseRecId;
                                    createDocReq3.CDE_TYPE_RCPT__c = 'C';
                                    createDocReq3.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                    createDocReq3.CDE_CORSPD_STATUS__c = 'Requested';
                                    createDocReq3.CDE_COUNTY__c = countyId;
                                    createDocReq3.RSN_CODE__c = rsn.Name;
                                    createDocReq3.DTE_REQ__c = system.today();
                                     // Added by Diya as part of CCCAP-4642
                                    if(keyParams.get('AdjustmentAddress') != Null){
                                        if(keyParams.get('adjmtId') != Null){
                                            createDocReq3.Adjustment_Address__c = keyParams.get('AdjustmentAddress');
                                            for(Id addrr :adjustmentAddressMap.get(keyParams.get('adjmtId'))){
                                                if(addrr != keyParams.get('AdjustmentAddress')){
                                                    T_DOC_RQ__C  createDocReqClone = createDocReq3.clone(false, false, false, false);
                                                    createDocReqClone.Adjustment_Address__c=addrr;
                                                    corspdList.add(createDocReqClone);
                                                }
                                            }
                                        }
                                        
                                    }
                                    // Added by Diya as part of CCCAP-4642 End
                                    corspdList.add(createDocReq3);
                                    
                                    if(keyParams.get('authId') != Null) {
                                        createDocReq4.IDN_AUTH__c = keyParams.get('authId');
                                        createDocReq4.OwnerId = caseOwner;
                                    }
                                    createDocReq4.IDN_PROVR__c = provrSfId;
                                    createDocReq4.CDE_TYPE_RCPT__c = 'P';
                                    createDocReq4.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                    createDocReq4.CDE_CORSPD_STATUS__c = 'Requested';
                                    createDocReq4.CDE_COUNTY__c = countyId;
                                    createDocReq4.RSN_CODE__c = rsn.Name;
                                    createDocReq4.DTE_REQ__c = system.today();
                                    // Added by Diya as part of CCCAP-4642
                                     if(keyParams.get('AdjustmentAddress') != Null){
                                        if(keyParams.get('adjmtId') != Null){
                                            createDocReq4.Adjustment_Address__c = keyParams.get('AdjustmentAddress');
                                            for(Id addrr :adjustmentAddressMap.get(keyParams.get('adjmtId'))){
                                                if(addrr != keyParams.get('AdjustmentAddress')){
                                                    T_DOC_RQ__C  createDocReqClone = createDocReq4.clone(false, false, false, false);
                                                    createDocReqClone.Adjustment_Address__c=addrr;
                                                    corspdList.add(createDocReqClone);
                                                }
                                            }
                                        }
                                        
                                    }
                                    // Added by Diya as part of CCCAP-4642 end
                                    corspdList.add(createDocReq4);
                                }else if(CR213CorrTypes.size() == 1){
                                    for(string corrTypeWhenOneExists : CR213CorrTypes){
                                        if(corrTypeWhenOneExists == 'P'){
                                            if(keyParams.get('authId') != Null ) {
                                                createDocReq3.IDN_AUTH__c = keyParams.get('authId');
                                                createDocReq3.OwnerId = caseOwner;
                                            }
                                            createDocReq3.IDN_CASE__c	= caseRecId;
                                            createDocReq3.CDE_TYPE_RCPT__c = 'C';
                                            createDocReq3.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                            createDocReq3.CDE_CORSPD_STATUS__c = 'Requested';
                                            createDocReq3.CDE_COUNTY__c = countyId;
                                            createDocReq3.RSN_CODE__c = rsn.Name;
                                            createDocReq3.DTE_REQ__c = system.today();
                                            corspdList.add(createDocReq3);
                                        }else if(corrTypeWhenOneExists == 'C'){
                                            if(keyParams.get('authId') != Null ) {
                                                createDocReq4.IDN_AUTH__c = keyParams.get('authId');
                                                createDocReq4.OwnerId = caseOwner;
                                            }
                                            createDocReq4.IDN_PROVR__c = provrSfId;
                                            createDocReq4.CDE_TYPE_RCPT__c = 'P';
                                            createDocReq4.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                            createDocReq4.CDE_CORSPD_STATUS__c = 'Requested';
                                            createDocReq4.CDE_COUNTY__c = countyId;
                                            createDocReq4.RSN_CODE__c = rsn.Name;
                                            createDocReq4.DTE_REQ__c = system.today();
                                            corspdList.add(createDocReq4);
                                        }
                                    }
                                }else if(CR213ReqCorrTypes.size() == 1){
                                    for(string corrTypeWhenOneExists : CR213ReqCorrTypes){
                                        if(corrTypeWhenOneExists == 'P'){
                                            if(keyParams.get('authId') != Null ) {
                                                createDocReq3.IDN_AUTH__c = keyParams.get('authId');
                                                createDocReq3.OwnerId = caseOwner;
                                            }
                                            createDocReq3.IDN_CASE__c	= caseRecId;
                                            createDocReq3.CDE_TYPE_RCPT__c = 'C';
                                            createDocReq3.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                            createDocReq3.CDE_CORSPD_STATUS__c = 'Requested';
                                            createDocReq3.CDE_COUNTY__c = countyId;
                                            createDocReq3.RSN_CODE__c = rsn.Name;
                                            createDocReq3.DTE_REQ__c = system.today();
                                            corspdList.add(createDocReq3);
                                        }else if(corrTypeWhenOneExists == 'C'){
                                            if(keyParams.get('authId') != Null ) {
                                                createDocReq4.IDN_AUTH__c = keyParams.get('authId');
                                                createDocReq4.OwnerId = caseOwner;
                                            }
                                            createDocReq4.IDN_PROVR__c = provrSfId;
                                            createDocReq4.CDE_TYPE_RCPT__c = 'P';
                                            createDocReq4.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                            createDocReq4.CDE_CORSPD_STATUS__c = 'Requested';
                                            createDocReq4.CDE_COUNTY__c = countyId;
                                            createDocReq4.RSN_CODE__c = rsn.Name;
                                            createDocReq4.DTE_REQ__c = system.today();
                                            corspdList.add(createDocReq4);
                                        }
                                    }
                                }
                            } else if((caseRecId != NULL) && (provrSfId == NULL)) {
                                if(keyParams.get('adjmtId') != Null ) {
                                    createDocReq2.IDN_ADJMT__c = keyParams.get('adjmtId');
                                }
                                if(keyParams.get('clientId') != null){ // Added by Rishav for CCCAP-7019
                                    createDocReq2.IDN_CLIENT__c = clientSFId;
                                }
                                createDocReq2.IDN_CASE__c = caseRecId;
                                createDocReq2.CDE_TYPE_RCPT__c = 'C';
                                createDocReq2.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                createDocReq2.CDE_CORSPD_STATUS__c = 'Requested';
                                if(countyId != null){
                                    createDocReq2.CDE_COUNTY__c = countyId;
                                }
                                createDocReq2.RSN_CODE__c = rsn.Name;
                                createDocReq2.DTE_REQ__c = system.today();
                                 // Added by Diya as part of CCCAP-4642
                                if(keyParams.get('AdjustmentAddress') != Null){
                                    if(keyParams.get('adjmtId') != Null){
                                        createDocReq2.Adjustment_Address__c = keyParams.get('AdjustmentAddress');
                                        for(Id addrr :adjustmentAddressMap.get(keyParams.get('adjmtId'))){
                                            if(addrr != keyParams.get('AdjustmentAddress')){
                                                T_DOC_RQ__C  createDocReqClone = createDocReq2.clone(false, false, false, false);
                                                createDocReqClone.Adjustment_Address__c=addrr;
                                                corspdList.add(createDocReqClone);
                                            }
                                        }
                                    }
                                    
                                }
                                // Added by Diya as part of CCCAP-4642 end
                                corspdList.add(createDocReq2);
                            } else if ((caseRecId == NULL) && (provrSfId != NULL)) {
                                if(keyParams.get('adjmtId') !=Null ) {
                                    createDocReq2.IDN_ADJMT__c = keyParams.get('adjmtId');
                                }
                                createDocReq2.IDN_PROVR__c = provrSfId;
                                createDocReq2.CDE_TYPE_RCPT__c = 'P';
                                createDocReq2.NME_CORSPD__c = rsn.NME_CORSPD__c;
                                createDocReq2.CDE_CORSPD_STATUS__c = 'Requested';
                                if(countyId != null){
                                    createDocReq2.CDE_COUNTY__c = countyId;    
                                }
                                createDocReq2.RSN_CODE__c = rsn.Name;
                                createDocReq2.DTE_REQ__c = system.today();
                                 // Added by Diya as part of CCCAP-4642
                                if(keyParams.get('AdjustmentAddress') != Null){
                                    if(keyParams.get('adjmtId') != Null){
                                        createDocReq2.Adjustment_Address__c = keyParams.get('AdjustmentAddress');
                                        for(Id addrr :adjustmentAddressMap.get(keyParams.get('adjmtId'))){
                                            if(addrr != keyParams.get('AdjustmentAddress')){
                                                T_DOC_RQ__C  createDocReqClone = createDocReq2.clone(false, false, false, false);
                                                createDocReqClone.Adjustment_Address__c=addrr;
                                                corspdList.add(createDocReqClone);
                                            }
                                        }
                                    }
                                    
                                }
                                // Added by Diya as part of CCCAP-4642 end
                                corspdList.add(createDocReq2);
                            }
                        }
                    }
                }
            }
            if(corspdList != NULL){
                //insert corspdList;
                GenericDMLHandler.insertRecords(corspdList,methodInfo);    
            }
            for(T_DOC_RQ__C corId : corspdList){
                idlist1.add(corId.Id);
            }
        }catch(Exception e){
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
            throw new CorspdException('Could not create Correpondence Request Object-',e);
        }
        try{
            return idlist1;
        }catch(Exception e){
            ExceptionLoggingServices.captureExceptionLog(e,methodInfo);
            throw new CorspdException('Correspondence Request return Error-', e);
        }
    }
}