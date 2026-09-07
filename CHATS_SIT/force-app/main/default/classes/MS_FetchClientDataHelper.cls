public inherited sharing class MS_FetchClientDataHelper {
    public static Id indivId{get;set;}
    public static Map<String,String> countyCodeVsName{get;set;}
    public static Map<Id,UFE_ResponseWrapper> caseDataMap{get;set;}
    private static boolean internalCallfromApp=false;
    // Search based on Email, provide all the application/case level information where individual with provided email is associated
    public static void getClientInfoByEmail(string searchEmailId){
        Map<Id,T_SBSD_Indiv__c> indivsToupdate 			= new Map<Id,T_SBSD_Indiv__c>();
        Map<Id,T_APPLN_CASE__c> appCaseToUpdate 		= new Map<Id,T_APPLN_CASE__c>();
        Map<String,String> listOfEligRunExtVsCaseIds 	= new Map<String,String>();
        Map<Id,Id>indivVsCaseId 						= new Map<Id,Id>();
        Set<Id> appQIdWithCases 						= new Set<Id>();
        Set<Id>clientIds 								= new Set<Id>();
        List<T_UFE_INDIV_EML__c> UFEEmailToInsert 		= new List<T_UFE_INDIV_EML__c>();
        
        
        //. Query :- to fetch all the individuals having provided email Address 
        for(T_SBSD_INDIV__c indiv:[SELECT Id,
                                   (SELECT Email_Information__c FROM Individual_E_mails__r where Effective_End_Date__c = NUll OR Effective_End_Date__c>=TODAY order by Effective_Begin_Date__c DESC limit 1),
                                   (SELECT Id,idn_case__c,idn_case__r.Name,idn_case__r.IDN_EXTNL__c FROM Case_Individual__r 
                                    where DTE_END_EFFV__c=NUll OR DTE_END_EFFV__c>=TODAY) 
                                   FROM t_sbsd_indiv__c 
                                   WHERE  Id IN (SELECT Individual__c FROM Individual_E_mail__c 
                                                 WHERE Email_Information__c=:searchEmailId and (Effective_End_Date__c = NUll OR Effective_End_Date__c>=TODAY))])
        {
            if(indiv.Individual_E_mails__r!=null && indiv.Individual_E_mails__r.size()>0 &&
               indiv.Individual_E_mails__r[0].Email_Information__c.toLowerCase() == searchEmailId.toLowerCase() && 
               indiv.Case_Individual__r!=null && !indiv.Case_Individual__r.isEmpty())
            {
                for(T_SBSD_CASE_INDIV__c caseIndiv: indiv.Case_Individual__r){                    
                    if(!caseDataMap.containsKey(caseIndiv.idn_case__c)){
                        UFE_ResponseWrapper rWrap 	= new UFE_ResponseWrapper();
                        rWrap.case_id 				= caseIndiv.idn_case__c; //Get Case SF ID
                        rWrap.user_facing_case_id = caseIndiv.idn_case__r.Name;
                        caseDataMap.put(caseIndiv.idn_case__c,rWrap );
                    }                    
                }                
            }
            
        }
        //. Query : to fetch all the case related information, 
        for(T_SBSD_Case__c chatsCase : [SELECT Id,DTE_REDET_CASE__c,CDE_COUNTY__r.Name,CDE_STATUS_WTLST__c,
                                        (SELECT Id,ExternalId from batchsit_t_eligty_run__r where cde_eligty_cfmd__c = 'CFM' order by dte_run_eligty__c desc),
                                        (SELECT Id,IDN_APPLN__c,IDN_APPLN__r.Name,IDN_Case__c,CDE_SOURCE__c,DTE_RCVD_APPLN__c,IDN_APPLN__r.CDE_COUNTY__c,IDN_APPLN__r.DTE_RCVD_APPLN__c,CDE_STATUS_APPLN__c,IDN_APPLN__r.CDE_INFO_EM__c,toLabel(CDE_REJECT_APPLN__c),CDE_REJECT_REFER__c,idn_appln__r.CDE_CBMS_REF_TYP__c FROM Application_Process_Queues__r),
                                        (Select Id,CDE_STATUS_CASE__c,CDE_MODE_CASE__c FROM T_SBSD_CASE10__r WHERE DTE_END_EFFV__c>=Today OR DTE_END_EFFV__c = null ORDER BY DTE_BEGIN_EFFV__c,createddate DESC NULLS FIRST Limit 1),
                                        (SELECT Id, IDN_EXTNL__c,idn_client__c,IDN_Case__c from CaseIndividuals__r) 
                                        FROM T_SBSD_Case__c 
                                        WHERE Id IN: caseDataMap.keyset()
                                       ])
        {
            UFE_ResponseWrapper rWrap 		= caseDataMap.get(chatsCase.Id);
            rWrap.home_county 			    = chatsCase.CDE_COUNTY__r.Name;
            rWrap.redetermination_date 		= chatsCase.DTE_REDET_CASE__c!=null ? chatsCase.DTE_REDET_CASE__c:null;
            rWrap.waitlist_status 			= chatsCase.CDE_STATUS_WTLST__c;
            if(chatsCase.batchsit_t_eligty_run__r!=null && chatsCase.batchsit_t_eligty_run__r.size()>0){
                listOfEligRunExtVsCaseIds.put(chatsCase.batchsit_t_eligty_run__r[0].ExternalId,chatsCase.Id);
            }
            //Get the Case Status Mode Details
            if(chatsCase.T_SBSD_CASE10__r!=null && !chatsCase.T_SBSD_CASE10__r.isEmpty()){
                rWrap.case_mode 	= chatsCase.T_SBSD_CASE10__r[0]?.CDE_MODE_CASE__c;
                rWrap.case_status 	= chatsCase.T_SBSD_CASE10__r[0]?.CDE_STATUS_CASE__c;                
            }
            //Get Application Case Details
            caseDataMap.put(chatsCase.Id,rWrap);
            if(chatsCase.Application_Process_Queues__r!=null && !chatsCase.Application_Process_Queues__r.isEmpty()){
                boolean firstPass = false;
                for(T_APPLN_PRCS_QUEUE__c appQ :chatsCase.Application_Process_Queues__r){
                    UFE_ResponseWrapper appQWrap 		= caseDataMap.containsKey(appQ.IDN_Case__c)?(UFE_ResponseWrapper)JSON.deserialize(JSON.serialize(caseDataMap.get(appQ.IDN_Case__c)),UFE_ResponseWrapper.class):new UFE_ResponseWrapper();
                    appQWrap.application_id 			= appQ?.IDN_APPLN__c;
                    appQWrap.user_facing_application_id = appQ?.IDN_APPLN__r.Name; 
                    appQWrap.submitted_date 			= appQ.DTE_RCVD_APPLN__c!=null ? appQ.DTE_RCVD_APPLN__c:null;
                    appQWrap.application_status 		= appQ?.CDE_STATUS_APPLN__c;
                    appQWrap.referral_type 				= appQ?.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
                    appQWrap.rejection_reason 			= appQ?.CDE_SOURCE__c == 'PK'?appQ?.CDE_REJECT_APPLN__c:appQ?.CDE_REJECT_REFER__c ;
                    if(firstPass==false){
                        caseDataMap.put(appQWrap.case_id,appQWrap);
                        firstPass = true;
                    }else{
                        caseDataMap.put(appQWrap.application_id,appQWrap);
                    }
                    appQIdWithCases.add(appQ.Id);
                    if(appQ?.IDN_APPLN__r.CDE_INFO_EM__c == searchEmailId){
                       appCaseToUpdate.put(appQWrap.application_id,new T_APPLN_CASE__c(Id=appQWrap.application_id,UFE_Request_Flag__c=true)); 
                    }
                }
            }
            //Get Case individual Data to cross check for Eligibile Individuals later
            if(chatsCase.CaseIndividuals__r!=null && !chatsCase.CaseIndividuals__r.isEmpty()){
                for(T_SBSD_CASE_INDIV__c caseIndiv : chatsCase.CaseIndividuals__r){
                    clientIds.add(caseIndiv.idn_client__c);
                    indivVsCaseId.put(caseIndiv.id,caseIndiv.IDN_Case__c);
                }
            }
        }
        system.debug('listOfEligRunExtVsCaseIds'+listOfEligRunExtVsCaseIds);
        //. Query to fetch Household Eligibility results
        for(batchsit_t_fcompsn_eligty__x houseElig : [SELECT Id,idn_eligty_fcompsn__c, cde_prog__c,idn_run_eligty__c,
                                                      (SELECT cde_status_eligty_family__c from batchsit_t_fcompsn_eligty_detail__r order by dte_begin_effv__c desc )
                                                      FROM batchsit_t_fcompsn_eligty__x 
                                                      WHERE idn_run_eligty__c In:listOfEligRunExtVsCaseIds.keyset() AND idn_eligty_fcompsn__c!=null
                                                     ])
        {
            Id CaseId= listOfEligRunExtVsCaseIds.get(houseElig.idn_run_eligty__c);
            UFE_ResponseWrapper rWrap = caseDataMap.get(CaseId);
            if(houseElig.batchsit_t_fcompsn_eligty_detail__r!=null && houseElig.batchsit_t_fcompsn_eligty_detail__r.size()>0){
                rWrap.eligibility_status = houseElig.batchsit_t_fcompsn_eligty_detail__r[0]?.cde_status_eligty_family__c;                
            }
            caseDataMap.put(CaseId,rWrap);
        }
        //. Query to fetch the Individual record and get the Email information from them, after cross checking that they are Eligible Adult from 3rd Query Results
        for(T_SBSD_INDIV__c indiv : [SELECT Id,(SELECT Id,IDN_EXTNL__c FROM Case_Individual__r),
                                     (SELECT Email_Information__c FROM Individual_E_mails__r where Effective_End_Date__c = NUll OR Effective_End_Date__c>=TODAY order by Effective_Begin_Date__c DESC limit 1) 
                                     FROM T_SBSD_INDIV__c WHERE Id IN:clientIds])
        {
            if(indiv.Individual_E_mails__r!=null && !indiv.Individual_E_mails__r.isEmpty()){
                string emailValue = indiv.Individual_E_mails__r[0]?.Email_Information__c.toLowerCase();                
                for(T_SBSD_CASE_INDIV__c caseIndiv : indiv.Case_Individual__r){
                    system.debug('emailValue '+emailValue +' casee Indiv Ext --'+caseIndiv.IDN_EXTNL__c);
                    Id caseId = indivVsCaseId.get(caseIndiv.Id);
                    if(caseId!=null && caseDataMap.containsKey(caseId)){
                        UFE_ResponseWrapper rWrap = caseDataMap.get(caseId);
                        if(emailValue!=null && !rWrap.parent_emails.contains(emailValue)){
                            rWrap.parent_emails.add(emailValue);
                        }
                        if(!rWrap.parent_emails.contains(searchEmailId.toLowerCase()))
                            rWrap.parent_emails.add(searchEmailId.toLowerCase());
                        caseDataMap.put(caseId,rWrap);
                    }
                    if(emailValue.toLowerCase() == searchEmailId.toLowerCase()){
                        indivId = indiv.id;
                    }
                }
            }
        }
        for(UFE_ResponseWrapper rWrap : caseDataMap.values()){
            if(indivId!=null){
                indivsToupdate.put(indivId,new T_SBSD_Indiv__c(Id=indivId,UFE_Request_Flag__c=true,Bypass_On__c=System.now()));
            }
        }
        // get the Application cases that are not processed yet
        for(T_APPLN_PRCS_QUEUE__c appQ : [SELECT IDN_APPLN__c,IDN_APPLN__r.Name,CDE_SOURCE__c,DTE_RCVD_APPLN__c,IDN_APPLN__r.CDE_COUNTY__c,IDN_APPLN__r.DTE_RCVD_APPLN__c,CDE_STATUS_APPLN__c,IDN_APPLN__r.CDE_INFO_EM__c,toLabel(CDE_REJECT_APPLN__c),CDE_REJECT_REFER__c,idn_appln__r.CDE_CBMS_REF_TYP__c 
                                          FROM T_APPLN_PRCS_QUEUE__c where IDN_APPLN__r.CDE_INFO_EM__c=:searchEmailId and Id Not IN :appQIdWithCases])
        {
            UFE_ResponseWrapper rWrap 		 = new UFE_ResponseWrapper();
            rWrap.application_id 			 = appQ?.IDN_APPLN__c;
            rWrap.user_facing_application_id = appQ?.IDN_APPLN__r.Name;
            rWrap.home_county  				 = countyCodeVsName.get(appQ.IDN_APPLN__r.CDE_COUNTY__c);
            rWrap.submitted_date 			 = appQ.DTE_RCVD_APPLN__c!=null ? appQ.DTE_RCVD_APPLN__c:null;
            rWrap.application_status 		 = appQ?.CDE_STATUS_APPLN__c;
            rWrap.referral_type 			 = appQ?.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
            rWrap.rejection_reason 			 = appQ?.CDE_SOURCE__c == 'PK'?appQ?.CDE_REJECT_APPLN__c:appQ?.CDE_REJECT_REFER__c;
            rWrap.parent_emails.add(searchEmailId.toLowerCase());
            appCaseToUpdate.put(rWrap.application_id,new T_APPLN_CASE__c(Id=rWrap.application_id,UFE_Request_Flag__c=true));
            caseDataMap.put(rWrap.application_id,rWrap);
        }
        if(!indivsToupdate.isEmpty()){
            GenericDMLHandler.updateRecords(indivsToupdate.values(), new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_INDIV__c'},'Method__c'=>'getClientInfoByEmail','Class__c'=>'MS_FetchClientDataHelper'});            
        }
        if(!appCaseToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(appCaseToUpdate.values(), new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_CASE__c'},'Method__c'=>'getClientInfoByEmail','Class__c'=>'MS_FetchClientDataHelper'});
        }
        // the Search Email was not found in the system, we will store in the system until matching Email is found at CHATS side.
        if (caseDataMap.isEmpty()) 
        {
            // Checkmarx CCCAP-12580
            // Check object-level create/update
            if (!Schema.sObjectType.T_UFE_INDIV_EML__c.isCreateable()) 
            {
                throw new AuraHandledException('Insufficient object-level create permission for T_UFE_INDIV_EML__c');
            }
            if (!Schema.sObjectType.T_UFE_INDIV_EML__c.isUpdateable()) 
            {
                throw new AuraHandledException('Insufficient object-level update permission for T_UFE_INDIV_EML__c');
            }
            // Check field-level create permission
            if (!Schema.sObjectType.T_UFE_INDIV_EML__c.fields.UFE_Email__c.isCreateable()) 
            {
                throw new AuraHandledException('Insufficient field-level create permission on UFE_Email__c');
            }
            // Prepare record(s) for upsert
            List<T_UFE_INDIV_EML__c> ufeEmailList = new List<T_UFE_INDIV_EML__c>
            {
                new T_UFE_INDIV_EML__c(UFE_Email__c = searchEmailId.toLowerCase())
            };
            // Strip any fields the user cannot create or update
            SObjectAccessDecision createDecision = Security.stripInaccessible(AccessType.CREATABLE, ufeEmailList);
            ufeEmailList = createDecision.getRecords();
            SObjectAccessDecision updateDecision = Security.stripInaccessible(AccessType.UPDATABLE, ufeEmailList);
            ufeEmailList = updateDecision.getRecords();
            // Perform upsert if still populated
            if (!ufeEmailList.isEmpty()) 
            {
                upsert ufeEmailList UFE_Email__c;
            }
        }
    }
    //Search based on Application Id to fetch specific case/app information by Id provided
    public static void getClientInfoByAppId(String identifier,String appOrCase){
        for(T_APPLN_PRCS_QUEUE__c appQ : [SELECT IDN_Case__c,IDN_CASE__r.Name,IDN_APPLN__r.Name,IDN_APPLN__c,CDE_SOURCE__c,DTE_RCVD_APPLN__c,IDN_APPLN__r.CDE_COUNTY__c,
                                          IDN_APPLN__r.DTE_RCVD_APPLN__c,CDE_STATUS_APPLN__c,IDN_APPLN__r.CDE_INFO_EM__c,
                                          toLabel(CDE_REJECT_APPLN__c),CDE_REJECT_REFER__c,idn_appln__r.CDE_CBMS_REF_TYP__c
                                          FROM T_APPLN_PRCS_QUEUE__c 
                                          where IDN_Appln__c=:identifier])
        {
            UFE_ResponseWrapper rWrap 		= new UFE_ResponseWrapper();
            rWrap.application_id 			= appQ?.IDN_APPLN__c;
            rWrap.user_facing_application_id = appQ?.IDN_APPLN__r.Name;
            rWrap.home_county  				= countyCodeVsName.get(appQ.IDN_APPLN__r.CDE_COUNTY__c);
            rWrap.submitted_date 			= appQ.DTE_RCVD_APPLN__c!=null ? appQ.DTE_RCVD_APPLN__c:null;
            rWrap.application_status 		= appQ?.CDE_STATUS_APPLN__c;
            rWrap.referral_type 			= appQ?.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
            rWrap.rejection_reason 			= appQ?.CDE_SOURCE__c == 'PK'?appQ?.CDE_REJECT_APPLN__c:appQ?.CDE_REJECT_REFER__c;
            rWrap.case_id					= appQ.IDN_CASE__c;
            rWrap.user_facing_case_id		= appQ.IDN_CASE__r.Name;
            if(appQ?.IDN_APPLN__r.CDE_INFO_EM__c!=null && !rWrap.parent_emails.contains(appQ?.IDN_APPLN__r.CDE_INFO_EM__c)){
                rWrap.parent_emails.add(appQ?.IDN_APPLN__r.CDE_INFO_EM__c);                
            }
            if(appQ.IDN_Case__c!=null){
                caseDataMap.put(appQ.IDN_Case__c,rWrap);
                internalCallfromApp = true;
                getClientInfoByCaseId(appQ.IDN_Case__c,'case');
            }else{
                caseDataMap.put(rWrap.application_id,rWrap);    
            }
            
        }
    }
    //Search based on Case Id to fetch specific case/app information by Id provided
    public static void getClientInfoByCaseId(String identifier,String appOrCase){
        string emailId = '';
        Map<String,String> listOfEligRunExtVsCaseIds 	= new Map<String,String>();
        Map<Id,Id>indivVsCaseId 						= new Map<Id,Id>();
        Set<Id> appQIdWithCases 						= new Set<Id>();
        Set<Id>clientIds 								= new Set<Id>();
        
        //. Query : to fetch all the case related information based on Provided Id identified
        for(T_SBSD_Case__c chatsCase : [SELECT Id,Name,DTE_REDET_CASE__c,CDE_COUNTY__r.Name,CDE_STATUS_WTLST__c,
                                        (SELECT Id,ExternalId from batchsit_t_eligty_run__r where cde_eligty_cfmd__c = 'CFM' order by dte_run_eligty__c desc),
                                        (SELECT Id,IDN_APPLN__c,CDE_SOURCE__c,DTE_RCVD_APPLN__c,IDN_APPLN__r.CDE_COUNTY__c,IDN_APPLN__r.DTE_RCVD_APPLN__c,CDE_STATUS_APPLN__c,IDN_APPLN__r.CDE_INFO_EM__c,toLabel(CDE_REJECT_APPLN__c),CDE_REJECT_REFER__c,idn_appln__r.CDE_CBMS_REF_TYP__c FROM Application_Process_Queues__r),
                                        (Select Id,CDE_STATUS_CASE__c,CDE_MODE_CASE__c FROM T_SBSD_CASE10__r WHERE DTE_END_EFFV__c>=Today OR DTE_END_EFFV__c = null ORDER BY DTE_BEGIN_EFFV__c,createddate DESC NULLS FIRST Limit 1),
                                        (SELECT Id, IDN_EXTNL__c,idn_client__c,IDN_Case__c from CaseIndividuals__r where (DTE_END_EFFV__c=NUll OR DTE_END_EFFV__c>=TODAY)) 
                                        FROM T_SBSD_Case__c 
                                        WHERE Id =:identifier])
        {
            UFE_ResponseWrapper rWrap 		= caseDataMap.containsKey(chatsCase.Id)?caseDataMap.get(chatsCase.Id):new UFE_ResponseWrapper();
            rWrap.case_id 					= chatsCase.Id;
            rWrap.user_facing_case_id		= chatsCase.Name;
            rWrap.home_county 				= chatsCase.CDE_COUNTY__r.Name;
            rWrap.redetermination_date 		= chatsCase.DTE_REDET_CASE__c!=null ? chatsCase.DTE_REDET_CASE__c:null;
            rWrap.waitlist_status 			= chatsCase.CDE_STATUS_WTLST__c;
            if(chatsCase.batchsit_t_eligty_run__r!=null && chatsCase.batchsit_t_eligty_run__r.size()>0){
                listOfEligRunExtVsCaseIds.put(chatsCase.batchsit_t_eligty_run__r[0].ExternalId,chatsCase.Id);
            }
            //Get the Case Status Mode Details
            if(chatsCase.T_SBSD_CASE10__r!=null && !chatsCase.T_SBSD_CASE10__r.isEmpty()){
                rWrap.case_mode 	= chatsCase.T_SBSD_CASE10__r[0]?.CDE_MODE_CASE__c;
                rWrap.case_status 	= chatsCase.T_SBSD_CASE10__r[0]?.CDE_STATUS_CASE__c;                
            }
            //Get Case individual Data to cross check for Eligibile Individuals later where BC Requested Status = true
            if(chatsCase.CaseIndividuals__r!=null && !chatsCase.CaseIndividuals__r.isEmpty()){
                for(T_SBSD_CASE_INDIV__c caseIndiv : chatsCase.CaseIndividuals__r){
                    clientIds.add(caseIndiv.idn_client__c);
                    indivVsCaseId.put(caseIndiv.id,caseIndiv.IDN_Case__c);
                }
            }
            caseDataMap.put(chatsCase.Id,rWrap);
        }
        //. Query to fetch Household Eligibility results
        for(batchsit_t_fcompsn_eligty__x houseElig : [SELECT Id,idn_eligty_fcompsn__c, cde_prog__c,idn_run_eligty__c,
                                                      (SELECT cde_status_eligty_family__c from batchsit_t_fcompsn_eligty_detail__r order by dte_begin_effv__c desc )
                                                      FROM batchsit_t_fcompsn_eligty__x 
                                                      WHERE idn_run_eligty__c In:listOfEligRunExtVsCaseIds.keyset() AND idn_eligty_fcompsn__c!=null
                                                     ])
        {
            Id CaseId= listOfEligRunExtVsCaseIds.get(houseElig.idn_run_eligty__c);
            UFE_ResponseWrapper rWrap = caseDataMap.get(CaseId);
            if(houseElig.batchsit_t_fcompsn_eligty_detail__r!=null && houseElig.batchsit_t_fcompsn_eligty_detail__r.size()>0){
                rWrap.eligibility_status = houseElig.batchsit_t_fcompsn_eligty_detail__r[0]?.cde_status_eligty_family__c;                
            }
            caseDataMap.put(CaseId,rWrap);
        }
        //.Query to fetch the Individual record and get the Email information from them, after cross checking that they are Eligible Adult from 3rd Query Results
        for(T_SBSD_INDIV__c indiv : [SELECT Id,(SELECT Id,IDN_EXTNL__c FROM Case_Individual__r),
                                     (SELECT Email_Information__c FROM Individual_E_mails__r where Effective_End_Date__c = NUll OR Effective_End_Date__c>=TODAY order by Effective_Begin_Date__c DESC limit 1) 
                                     FROM T_SBSD_INDIV__c WHERE Id IN:clientIds])
        {
            if(indiv.Individual_E_mails__r!=null && !indiv.Individual_E_mails__r.isEmpty()){
                string emailValue = indiv.Individual_E_mails__r[0]?.Email_Information__c;                
                for(T_SBSD_CASE_INDIV__c caseIndiv : indiv.Case_Individual__r){
                    Id caseId = indivVsCaseId.get(caseIndiv.Id);
                    if(caseId!=null && caseDataMap.containsKey(caseId)){
                        UFE_ResponseWrapper rWrap = caseDataMap.get(caseId);
                        if(emailValue!=null && !rWrap.parent_emails.contains(emailValue)){
                            rWrap.parent_emails.add(emailValue);
                        }
                        caseDataMap.put(caseId,rWrap);
                    }   
                }
            }
        }
        if(internalCallfromApp == false){
            boolean firstPass = false;
            for(T_APPLN_PRCS_QUEUE__c appQ : [SELECT IDN_CASE__c,IDN_CASE__r.CDE_COUNTY__r.Name ,IDN_APPLN__c,CDE_SOURCE__c,DTE_RCVD_APPLN__c,IDN_APPLN__r.Name,IDN_APPLN__r.CDE_COUNTY__c,IDN_APPLN__r.DTE_RCVD_APPLN__c,CDE_STATUS_APPLN__c,IDN_APPLN__r.CDE_INFO_EM__c,toLabel(CDE_REJECT_APPLN__c),CDE_REJECT_REFER__c,idn_appln__r.CDE_CBMS_REF_TYP__c 
                                              FROM T_APPLN_PRCS_QUEUE__c 
                                              WHERE IDN_Case__c=:caseDataMap.keyset()])
            {
                UFE_ResponseWrapper rWrap 			= caseDataMap.containsKey(appQ.IDN_Case__c)?(UFE_ResponseWrapper)JSON.deserialize(JSON.serialize(caseDataMap.get(appQ.IDN_Case__c)),UFE_ResponseWrapper.class):new UFE_ResponseWrapper();
                rWrap.application_id 				= appQ?.IDN_APPLN__c;
                rWrap.user_facing_application_id 	= appQ?.IDN_APPLN__r.Name;
                if(appQ.IDN_CASE__r.CDE_COUNTY__r.Name!=null){
                    rWrap.home_county  					= appQ.IDN_CASE__r.CDE_COUNTY__r.Name;
                }else{
                    rWrap.home_county  					= countyCodeVsName.get(appQ.IDN_APPLN__r.CDE_COUNTY__c);
                }
                rWrap.submitted_date 				= appQ.DTE_RCVD_APPLN__c!=null ? appQ.DTE_RCVD_APPLN__c:null;
                rWrap.application_status 			= appQ?.CDE_STATUS_APPLN__c;
                rWrap.referral_type 				= appQ?.IDN_APPLN__r.CDE_CBMS_REF_TYP__c;
                rWrap.rejection_reason 				= appQ?.CDE_SOURCE__c == 'PK'?appQ?.CDE_REJECT_APPLN__c:appQ?.CDE_REJECT_REFER__c;
                if(firstPass==false){
                    caseDataMap.put(rWrap.case_id,rWrap);
                    firstPass = true;
                }else{
                    caseDataMap.put(rWrap.application_id,rWrap);
                }
            }
        }
    }
}