public without sharing class IndividualEmailTrigger_Helper{
    
    public static void updateEndDate(List<Individual_E_mail__c> triggerNewList){
        List<Individual_E_mail__c>emailInfoToUpdate = new List<Individual_E_mail__c>();
        Set<Id> indivIdSet = new Set<Id>();
        Map<Id,Individual_E_mail__c> emailInfoMap = new Map<Id,Individual_E_mail__c>();
        Map<Id,Individual_E_mail__c> latestEmailInfoMap = new Map<Id,Individual_E_mail__c>();
        for(Individual_E_mail__c ie : triggerNewList){
            if(ie.Effective_Begin_Date__c == Null){
                ie.Effective_Begin_Date__c = System.today();
            }
            if(ie.Individual__c!=null){
    	        indivIdSet.add(ie.Individual__c);
	            emailInfoMap.put(ie.Individual__c,ie);        
            }
        }
        List<Individual_E_mail__c>ielist=[Select Id,Effective_End_Date__c,Effective_Begin_Date__c,Individual__c from Individual_E_mail__c where Individual__c =: indivIdSet AND (Effective_End_Date__c=Null OR Effective_End_Date__c >= TODAY) order by Effective_Begin_Date__c DESC ];
        for(Individual_E_mail__c emailObj:ielist){
            if(latestEmailInfoMap.containsKey(emailObj.Individual__c)){
                if(latestEmailInfoMap.get(emailObj.Individual__c).Effective_Begin_Date__c < emailObj.Effective_Begin_Date__c){
                    latestEmailInfoMap.put(emailObj.Individual__c, emailObj);
                }
                
            } else {
                latestEmailInfoMap.put(emailObj.Individual__c, emailObj);
            }  
        }
        for(Individual_E_mail__c emailObj:latestEmailInfoMap.values()){
            if(emailInfoMap.containsKey(emailObj.Individual__c)){
                Individual_E_mail__c temp = emailInfoMap.get(emailObj.Individual__c);
                if(temp.Effective_Begin_Date__c!= null){
                    emailObj.Effective_End_Date__c = (temp.Effective_Begin_Date__c).addDays(-1);
                    emailInfoToUpdate.add(emailObj);
                }
            }
        }
        system.debug('emailInfoToUpdate--'+emailInfoToUpdate);
        if(emailInfoToUpdate != null && emailInfoToUpdate.size()>0){
            GenericDMLHandler.updateRecords(emailInfoToUpdate, new Map<String,Object>{'Method__c'=>'updateCaseEmailBulk','Class__c'=>'IndividualEmailTrigger_Helper'});   
        }
    }
    
    public static void updateCaseEmailBulk(Map<Id, Individual_E_mail__c> triggerNewMap,Map<Id, Individual_E_mail__c> triggerOldMap){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'IndividualEmailTrigger_Helper','Method__c'=>'updateCaseEmailBulk'};  
            Map<String, String> caseIndivEmailMap = new Map<String, String>();
        Map<String, String> indivEmailMap = new Map<String, String>();
        List<String> caseIdList = new List<String>();
        List<T_SBSD_CASE_INFO__c> caseToinsert = new List<T_SBSD_CASE_INFO__c>();
        List<T_SBSD_CASE_INFO__c> caseToupdate = new List<T_SBSD_CASE_INFO__c>();
        Map<String,Id> mailVsUFeMap	= new Map<String,Id>();
        Map<String,Id> mailVsAppCaseMap	= new Map<String,Id>();
        List<batchsit_t_pos_trans_queue_ats__x>lstATSRecords=new List<batchsit_t_pos_trans_queue_ats__x>();
        Map<Id,String> indivEmailIdsVsEmail = new Map<Id,String>();
        /*added for RAPID-UFE by Shashank*/
        Map<Id,UFEChangeInterface__e> caseVsPE_Event 		= new Map<Id,UFEChangeInterface__e>();
        Map<Id,T_SBSD_INDIV__c> indivsToUpdate 				= new Map<Id,T_SBSD_INDIV__c>();
        Map<Id,T_UFE_INDIV_EML__c> UFEEmailToDel 			= new Map<Id,T_UFE_INDIV_EML__c>();
        List<UFEChangeInterface__e> ufeInfoUpdateEventList	= new List<UFEChangeInterface__e>();
        String ufechangeMode;
        Savepoint sp;
        try {
            Date todayDate = system.today();
            for(Individual_E_mail__c indivEmailRecord : triggerNewMap.values()){
                if(indivEmailRecord.Email_Information__c !=null && indivEmailRecord.Email_Information__c != ''){
                    if(indivEmailRecord.Effective_Begin_Date__c <=todayDate && (indivEmailRecord.Effective_End_Date__c == null || indivEmailRecord.Effective_End_Date__c >=todayDate)){
                        indivEmailMap.put(indivEmailRecord.Individual__c, indivEmailRecord.Email_Information__c); // Email Active Only.
                    }
                    indivEmailIdsVsEmail.put(indivEmailRecord.Individual__c,indivEmailRecord.Email_Information__c); // Email Irrespective of Active/Inactive.
                    //added for RAPID-UFE by Shashank
                    if(trigger.isInsert){
                        ufechangeMode='emailInsert';
                    }else if(Trigger.isUpdate){
                        if(indivEmailRecord.Email_Information__c!=triggerOldMap.get(indivEmailRecord.Id).Email_Information__c){
                            ufechangeMode = 'emailUpdate';
                        }else if(indivEmailRecord.Effective_End_Date__c!=triggerOldMap.get(indivEmailRecord.Id).Effective_End_Date__c 
                                && indivEmailRecord.Effective_End_Date__c< Date.today()){
                                    ufechangeMode = 'endDateUpdate';
                                }
                    }
                }
            }
            // check if Email is present in T_UFE_INDIV_EML__c or not
            if(ufechangeMode == 'emailInsert' || ufechangeMode == 'emailUpdate'){
                for(T_UFE_INDIV_EML__c ufeEmail : [select id,UFE_Email__c from T_UFE_INDIV_EML__c where UFE_Email__c in:indivEmailMap.values()]){
                    mailVsUFeMap.put(ufeEmail.UFE_Email__c.toLowerCase(),ufeEmail.Id);
                }
                for(T_APPLN_CASE__c appCase : [SELECT id,CDE_INFO_EM__c FROM T_APPLN_CASE__c 
                                               WHERE CDE_INFO_EM__c in :indivEmailMap.values() AND UFE_Request_Flag__c=true]){
                                                   mailVsAppCaseMap.put(appCase.CDE_INFO_EM__c.toLowerCase(),appCase.Id);
                                               }
            }
            List<Individual_E_mail__c> ielist = [SELECT Id, Effective_End_Date__c, Effective_Begin_Date__c, Individual__c, Email_Information__c FROM Individual_E_mail__c 
                                                 WHERE Id NOT IN:triggerNewMap.keySet() AND Individual__c IN: indivEmailIdsVsEmail.keySet() AND (Effective_End_Date__c=Null OR Effective_End_Date__c >= TODAY) ORDER BY Effective_Begin_Date__c DESC];
            for(Individual_E_mail__c indivEmailRecord : ielist){
                if(indivEmailMap.containsKey(indivEmailRecord.Individual__c)){
                    if(indivEmailRecord.Effective_Begin_Date__c <= todayDate && (indivEmailRecord.Effective_End_Date__c == null || indivEmailRecord.Effective_End_Date__c >= todayDate)){
                        indivEmailMap.put(indivEmailRecord.Individual__c, indivEmailRecord.Email_Information__c);
                    }
                }
            }
            for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id, IDN_CASE__c,IDN_CASE__r.Name, IDN_CLIENT__c,IDN_CLIENT__r.UFE_Request_Flag__c,IDN_CLIENT__r.Name,IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN : indivEmailIdsVsEmail.keySet()])
            {
                //making sure below operation only happens for Active Email Ids.
                if(indivEmailMap.containsKey(caseIndiv.IDN_CLIENT__c)){
                    if(caseIndiv.IND_CRTKR__c== true){
                        caseIndivEmailMap.put(caseIndiv.IDN_CASE__c, indivEmailMap.get(caseIndiv.IDN_CLIENT__c));
                        caseIdList.add(caseIndiv.IDN_CASE__c);
                    }
                    batchsit_t_pos_trans_queue_ats__x atsRecord2 = new batchsit_t_pos_trans_queue_ats__x();
                    atsRecord2.CDE_STATUS_TRANS__c= '1';
                    atsRecord2.CDE_TYPE_TRANS__c ='3';
                    atsRecord2.IDN_CASE__c =caseIndiv.IDN_CASE__r.Name;
                    
                    atsRecord2.IDN_CLIENT__c =caseIndiv.IDN_CLIENT__r.Name;
                    atsRecord2.DTE_CHANGE_LAST__c = system.today();
                    lstATSRecords.add(atsRecord2);
                    ATSHandler.isType3Inserted = true;
                    
                    batchsit_t_pos_trans_queue_ats__x atsRecord3 = new batchsit_t_pos_trans_queue_ats__x();
                    atsRecord3.CDE_STATUS_TRANS__c= '1';
                    atsRecord3.CDE_TYPE_TRANS__c ='2';
                    atsRecord3.IDN_CLIENT__c =caseIndiv.IDN_CLIENT__r.Name;
                    atsRecord3.DTE_CHANGE_LAST__c = system.today();
                    lstATSRecords.add(atsRecord3);
                    ATSHandler.isType2Inserted = true;
                }
                //added for UFE by Shashank
                if(ufechangeMode!=null){
                    string currentEmail = indivEmailIdsVsEmail.get(caseIndiv.IDN_CLIENT__c)!=null? indivEmailIdsVsEmail.get(caseIndiv.IDN_CLIENT__c).toLowerCase():  '';
                    /* Create/Update -> Email found on T_UFE_INDIV_EML__c, 
						=> Delete the entry from T_UFE_INDIV_EML__c,Set UFE_Request_Flag__c = true on individual and Publish Platform Event to Inform Bridgecare*/
                    if(mailVsUFeMap.containsKey(currentEmail)){
                        id ufeEmail_Id = mailVsUFeMap.get(currentEmail);
                        caseVsPE_Event.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case'));
                        UFEEmailToDel.put(ufeEmail_Id,new T_UFE_INDIV_EML__c(Id=ufeEmail_Id));
                        indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=true,Bypass_On__c=System.now()));
                    }
                    /* Create/Update -> Email found on T_APPLN_CASE__c and UFE_Request_Flag__c =true , 
						=> Set UFE_Request_Flag__c = true on individual and Publish Platform Event to Inform Bridgecare*/
                    else if(mailVsAppCaseMap.containsKey(currentEmail)){
                        caseVsPE_Event.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case'));
                        indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=true,Bypass_On__c=System.now()));
                    }
                    /*  Updating Email, New Email Not Found on T_UFE_INDIV_EML__c and UFE_Request_Flag__c =true on Individual then
						=> Set UFE_Request_Flag__c =False on individual.*/
                    else if(caseIndiv.IDN_CLIENT__r.UFE_Request_Flag__c == true && ufechangeMode == 'emailUpdate'){
                        indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=false,Bypass_On__c=System.now()));
                    }
                    // Updating End Date and UFE_Request_Flag__c = true on Individual => Publish Platform Event to Inform Bridgecare					
                    else if(caseIndiv.IDN_CLIENT__r.UFE_Request_Flag__c == true && ufechangeMode == 'endDateUpdate'){
                        indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=false,Bypass_On__c=System.now()));
                        caseVsPE_Event.put(caseIndiv.IDN_CASE__c,new UFEChangeInterface__e(IdNumber__c=caseIndiv.IDN_CASE__c,Type__c='case'));
                    }else if(caseIndiv.IDN_CLIENT__r.UFE_Request_Flag__c == true){
                        indivsToUpdate.put(caseIndiv.IDN_CLIENT__c,new T_SBSD_Indiv__c(Id=caseIndiv.IDN_CLIENT__c,UFE_Request_Flag__c=false,Bypass_On__c=System.now()));
                    }
                }
            }
            if(!caseIdList.isEmpty()){
                List<T_SBSD_CASE__c> caserecords = [SELECT Id,(Select Id, CDE_TYPE_INFO_CASE__c FROM T_SBSD_CASE13__r WHERE CDE_TYPE_INFO_CASE__c='EM')  
                                                    FROM T_SBSD_CASE__c WHERE Id IN :caseIdList];
                for(T_SBSD_CASE__c caserec:caserecords){
                    if(!caserec.T_SBSD_CASE13__r.isEmpty()) {
                        T_SBSD_CASE_INFO__c caseinforecone=caserec.T_SBSD_CASE13__r[0];
                        caseinforecone.TXT_VALUE_INFO_CASE__c=caseIndivEmailMap.get(caserec.Id);
                        caseToupdate.add(caseinforecone);   
                    } else { //Added for Hotfix CCCAP-3305
                        T_SBSD_CASE_INFO__c caseinforec=new T_SBSD_CASE_INFO__c ();
                        caseinforec.IDN_CASE__c=caserec.Id;
                        caseinforec.CDE_TYPE_INFO_CASE__c='EM';
                        caseinforec.TXT_VALUE_INFO_CASE__c=caseIndivEmailMap.get(caserec.Id);
                        caseToinsert.add(caseinforec);
                    }
                }
            }
            //Added for Hotfix CCCAP-3305
            // Setting Savepoint
            sp = Database.setSavepoint();
            if(!caseToinsert.isEmpty()){
                GenericDMLHandler.insertRecords(caseToinsert, new Map<String,Object>{'Method__c'=>'updateCaseEmailBulk','Class__c'=>'IndividualEmailTrigger_Helper'});
            }
            if(!lstATSRecords.isEmpty()){
                //GenericDMLHandler.insertRecords(lstATSRecords, new Map<String,Object>{'Method__c'=>'updateCaseEmailBulk','Class__c'=>'IndividualEmailTrigger_Helper'});
                ATSHandler.insertATSRecord(true, lstATSRecords);
            }
            if(!caseToupdate.isEmpty()){
                GenericDMLHandler.updateRecords(caseToupdate, new Map<String,Object>{'Method__c'=>'updateCaseEmailBulk','Class__c'=>'IndividualEmailTrigger_Helper'});   
            }
            //added for RAPID-UFE by Shashank
            if(!caseVsPE_Event.isEmpty()){
                Eventbus.publish(caseVsPE_Event.values());
            }
            if(!indivsToUpdate.isEmpty()){
                GenericDMLHandler.updateRecords(indivsToUpdate.values(), new Map<String,Object>{'Method__c'=>'updateCaseEmailBulk','Class__c'=>'IndividualEmailTrigger_Helper'});   
            }
            if(!UFEEmailToDel.isEmpty()){
                delete UFEEmailToDel.values();
            }
        }catch (Exception e) {
            Database.rollback(sp);
            ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
        }
    }
}