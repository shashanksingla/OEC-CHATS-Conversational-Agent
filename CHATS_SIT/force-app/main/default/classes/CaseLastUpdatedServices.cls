//Modified for Changes for CCCAP-995
public with sharing class CaseLastUpdatedServices {
    public static Boolean disableTrigger = false; // added for CCCAP-14909
    public static Boolean isPeakApplicationContext= false;
    public static Boolean checkIfTriggerExecuted = true;

    public static List<T_SBSD_CASE__c> updateCaseLastChangeFromIndividualIds(Set<Id> individualIds){
        if(individualIds.isEmpty() || isPeakApplicationContext){
            return new List<T_SBSD_CASE__c>();
        }else{
            Set<Id> caseIdsToBeUpdated = new Set<Id>();
            for(T_SBSD_CASE_INDIV__c caseIndividual:[SELECT IDN_CASE__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:individualIds AND 
                                                     (IDN_CASE__r.DTE_CHGD_LAST_DATA_ELIGTY__c!=TODAY OR IDN_CASE__r.IND_CHGD_DATA_ELIGTY__c!=true) WITH SECURITY_ENFORCED]){
                                                         caseIdsToBeUpdated.add(caseIndividual.IDN_CASE__c);
                                                     }
            return updateCaseLastChangeFromCaseIds(caseIdsToBeUpdated);
        }
    }
    
    public static List<T_SBSD_CASE__c> updateCaseLastChangeFromCaseIds(Set<Id> caseIds){        
        List<T_SBSD_CASE__c> casesToBeUpdated = new List<T_SBSD_CASE__c>(); 
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CaseLastUpdatedServices','Method__c'=>'updateCaseLastChangeFromCaseIds'};  
        for(Id caseId: caseIds){
            casesToBeUpdated.add(new T_SBSD_CASE__c(Id = caseId,
                                                    DTE_CHGD_LAST_DATA_ELIGTY__c = System.today(),
                                                    IND_CHGD_DATA_ELIGTY__c = true
                                                   ));
        }
        System.debug('###casesToBeUpdated###'+casesToBeUpdated);
        if(!casesToBeUpdated.isEmpty()){
            try{
                CaseLastUpdatedServices.disableTrigger = true; // added for CCCAP-14909
                GenericDMLHandler.updateRecords(casesToBeUpdated,methodInfo);
                CaseLastUpdatedServices.disableTrigger = false; // added for CCCAP-14909
            }catch(Exception ex) {
                system.debug('error '+ex.getMessage());
                ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
            }
        }
        return casesToBeUpdated;
    }
    
    public static Set<Id> pluckIds(List<SObject> sobjects, String fieldName){
        Set<Id> pluckedIds = new Set<Id>();
        for(SObject aSob: sobjects){
            if(aSob.get(fieldName)!=null) {
                pluckedIds.add((Id)aSob.get(fieldName));
            }
        }
        return pluckedIds;
    }
    
    public static Set<Id> getIndividualsFromRelationship(String relationship, String objectName, List<SObject> sObs){
        Set<Id> individualIds = new Set<Id>();
        List<String> relationships;
        if(!sObs.isEmpty() && !isPeakApplicationContext){
            for(SObject sOb:Database.query('SELECT '+relationship+' FROM '+ objectName+' WHERE Id IN :sObs')){
                System.debug(relationship);
                relationships = new List<String>();
                relationships = relationship.split('\\.');
                System.debug(relationships);
                //Removed unused variable on 5/13/2018 BG  
                individualIds.add((Id)getFieldValue(sOb,relationship));
            }
        }
        return individualIds;
    }
    
    public static Object getFieldValue(SObject o,String field){
        if(o == null){
            return null;
        }
        if(field.contains('.')){
            String nextField = field.substringAfter('.');
            String relation = field.substringBefore('.');
            return getFieldValue((SObject)o.getSObject(relation),nextField);
        }else{
            return o.get(field);
        }
    }
    
    public static set<Id> getCaseIds(set<Id> caseIds) {
        set<Id> filteredCaseIds = new set<Id>();
        if(!caseIds.isEmpty() && !isPeakApplicationContext){
            for(T_SBSD_CASE__c eachCase: [Select Id from T_SBSD_CASE__c where Id IN:caseIds AND (DTE_CHGD_LAST_DATA_ELIGTY__c!=TODAY OR IND_CHGD_DATA_ELIGTY__c!=true) WITH SECURITY_ENFORCED]) {
                filteredCaseIds.add(eachCase.Id);
            }
        }
        return filteredCaseIds;
    }
    
    public static set<Id> filterCaseIds(List<T_SBSD_CASE__c> caseNewList, Map<Id, T_SBSD_CASE__c> caseOldMap) {
        set<Id> caseIds = new set<Id>();
        for(T_SBSD_CASE__c eachCase:caseNewList) {
            if(!(!eachCase.IND_CHGD_DATA_ELIGTY__c && caseOldMap.get(eachCase.Id).IND_CHGD_DATA_ELIGTY__c)){
                caseIds.add(eachCase.Id);
            }
        }
        return caseIds;
    }
    
    /**    
	* @description Update Case Name field with below logic and Insert Record in ATS Object
	*  Case Name = County Code(2 digit number) + Unique Autonumber(7 Digit) // All together 9 digit Case number. CHATS-3939 and CHATS 3937.
	* @author  Vineet Srivastava and Ranjan Poojary
	* @date 4/12/2018   
	* @param set<Id> recordIds trigger.new Case Id,
	* @return void
	*/  
    public static void updateCaseNameField(set<Id> recordIds) {
        List<T_SBSD_CASE__c> updateNameField = new List<T_SBSD_CASE__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CaseLastUpdatedServices','Method__c'=>'updateCaseNameField'};  
        try {
            for(T_SBSD_CASE__c caseRec : [Select CDE_COUNTY__r.CDE_COUNTY__c,AutoNumber__c,Name,Id from T_SBSD_CASE__c where Id in :recordIds WITH SECURITY_ENFORCED]){
                caseRec.Name =  caseRec.CDE_COUNTY__r.CDE_COUNTY__c+caseRec.AutoNumber__c;              
                updateNameField.add(caseRec);
            }
            if(!updateNameField.isEmpty()){
                System.debug(updateNameField);
                CaseLastUpdatedServices.disableTrigger = true; // added for CCCAP-14909
                GenericDMLHandler.updateRecords(updateNameField,methodInfo);
                CaseLastUpdatedServices.disableTrigger = false; // added for CCCAP-14909
            }
        } catch(Exception ex) {
            system.debug('Exception: '+ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);        
        }
    }

    //CCCAP-4748
    public static void updateLastRedeterminationDate(List<T_SBSD_CASE__c> caseList, Map<Id, T_SBSD_CASE__c> oldMap){
        for(T_SBSD_CASE__c cs : caseList){
            if(cs.DTE_REDET_CASE__c != oldMap.get(cs.Id).DTE_REDET_CASE__c && oldMap.get(cs.Id).DTE_REDET_CASE__c != null){
                cs.DTE_REDET_LAST__c = oldMap.get(cs.Id).DTE_REDET_CASE__c;
            }
        }
    }
    
    /**
	* @description : Restrict user to create duplicate Employment Verification record for the same Employment
	* @author Bharadwaj Gaddam
	* @date 12-Sep-2018    
	* @param List<T_INDIV_EMPLMT_VERIF__c> Trigger.new list of new Employment Verification records
	* @return void
	*/
    public static void duplicateEmploymentVerificationCheck(List<T_INDIV_EMPLMT_VERIF__c> empVerifList) {
        Map<Id,Id> emplAndEmplVerifMap = new Map<Id,Id>();
        set<Id> employmentIdSet = new set<Id>();
        for(T_INDIV_EMPLMT_VERIF__c empVerfEach:empVerifList) {
            if(empVerfEach.IDN_EMPLMT_INDIV__c != null) {
                //collecting all Employment Ids
                employmentIdSet.add(empVerfEach.IDN_EMPLMT_INDIV__c);
            }
        }
        //query returns existing Employment Verification records associated with the Employment
        for(T_INDIV_EMPLMT_VERIF__c existingEmpVerf:[select Id,IDN_EMPLMT_INDIV__c from T_INDIV_EMPLMT_VERIF__c where IDN_EMPLMT_INDIV__c IN:employmentIdSet WITH SECURITY_ENFORCED]) {
            if(existingEmpVerf.IDN_EMPLMT_INDIV__c != null) {
                //map with Employment Id as key and Emp Verif Id as value
                emplAndEmplVerifMap.put(existingEmpVerf.IDN_EMPLMT_INDIV__c, existingEmpVerf.Id);
            }
        }
        
        //this iteration is to check if the Employment has atleast one Verification record and throw error
        for(T_INDIV_EMPLMT_VERIF__c empVerfEach2:empVerifList) { 
            if(empVerfEach2.IDN_EMPLMT_INDIV__c != null) {
                if(emplAndEmplVerifMap.get(empVerfEach2.IDN_EMPLMT_INDIV__c) !=null) {
                    empVerfEach2.IDN_EMPLMT_INDIV__c.addError(Label.Employment_Verification_already_exists_for_this_Employment);
                }
                
            }
        
        }
    }
    
    public static void updateCWDetailEndDate(List<T_CW_ADDNL_INFO__c> newCWDetailList, Boolean triggerContext){
        List<T_CW_ADDNL_INFO__c> oldCWDetailList = new List<T_CW_ADDNL_INFO__c>();
        Set<Id>cwDetailID = new Set<Id>();
        Set<Id>caseIds = new Set<Id>();
        Set<Id>clientIds = new Set<Id>();
        Map<Id, List<T_CW_ADDNL_INFO__c>> oldCWDetailMap = new Map<Id, List<T_CW_ADDNL_INFO__c>>();
        Map<Id, List<T_CW_ADDNL_INFO__c>> oldCWDetailClientMap = new Map<Id, List<T_CW_ADDNL_INFO__c>>();
        Map<String,T_CW_ADDNL_INFO__c> newCWDetailMap = new Map<String,T_CW_ADDNL_INFO__c>();
        Map<Id,T_SBSD_CASE__c> caseMap = new Map<Id,T_SBSD_CASE__c>();
        Map<Id,T_SBSD_INDIV__c> individualMap = new Map<Id,T_SBSD_INDIV__c>();
        
        for(T_CW_ADDNL_INFO__c cwDetail : newCWDetailList){
            if(cwDetail.IDN_CASE_CHATS__c != null) {
                newCWDetailMap.put(cwDetail.IDN_CASE_CHATS__c, cwDetail);
                if(!triggerContext){
                    cwDetailID.add(cwDetail.id);  
                }
                caseIds.add(cwDetail.IDN_CASE_CHATS__c);  
            }else if(cwDetail.IDN_CLIENT__c != null){
                newCWDetailMap.put(cwDetail.IDN_CLIENT__c, cwDetail);
                if(!triggerContext){
                    cwDetailID.add(cwDetail.id);  
                }
                clientIds.add(cwDetail.IDN_CLIENT__c);
            }
        }
        
        Set<Id> caseWithBlankCWEndDate = new Set<Id>();
        for(T_CW_ADDNL_INFO__c cwDet :[SELECT id,IDN_CASE_CHATS__c,IDN_CLIENT__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CW_ADDNL_INFO__c where (IDN_CASE_CHATS__c IN:caseIds or IDN_CLIENT__c IN:clientIds) AND ID NOT IN:cwDetailID WITH SECURITY_ENFORCED]){
                if(cwDet.IDN_CASE_CHATS__c != null) {
                    if(oldCWDetailMap.containsKey(cwDet.IDN_CASE_CHATS__c)){
                        oldCWDetailMap.get(cwDet.IDN_CASE_CHATS__c).add(cwDet); 
                    }else{
                        oldCWDetailMap.put(cwDet.IDN_CASE_CHATS__c,new List<T_CW_ADDNL_INFO__c>{cwDet});
                    }
                    if(cwDet.DTE_END_EFFEV__c == null && cwDet.DTE_BEGIN_EFFEV__c != null){
                        caseWithBlankCWEndDate.add(cwDet.IDN_CASE_CHATS__c);
                        if(cwDet.IDN_CLIENT__c != null) {
                            caseWithBlankCWEndDate.add(cwDet.IDN_CLIENT__c);
                        }
                    }
                }
                else if(cwDet.IDN_CLIENT__c != null) {
                    if(oldCWDetailClientMap.containsKey(cwDet.IDN_CLIENT__c)){
                        oldCWDetailClientMap.get(cwDet.IDN_CLIENT__c).add(cwDet); 
                    }else{
                        oldCWDetailClientMap.put(cwDet.IDN_CLIENT__c,new List<T_CW_ADDNL_INFO__c>{cwDet});
                    }
                    if(cwDet.DTE_END_EFFEV__c == null && cwDet.DTE_BEGIN_EFFEV__c != null){
                        caseWithBlankCWEndDate.add(cwDet.IDN_CLIENT__c);
                    }
                }      
        }
        
        for(T_CW_ADDNL_INFO__c cwDetail : newCWDetailList){
            if(cwDetail.DTE_BEGIN_EFFEV__c != null && cwDetail.DTE_END_EFFEV__c != null && cwDetail.DTE_END_EFFEV__c < cwDetail.DTE_BEGIN_EFFEV__c){
                cwDetail.addError('Effective End Date must be equal to or greater than the Effective Begin Date.');   
            }
            else if(caseWithBlankCWEndDate != null && caseWithBlankCWEndDate.size()>0 ) {
                    if( (cwDetail.IDN_CASE_CHATS__c != null && cwDetail.IDN_CLIENT__c != null
                        	&&  caseWithBlankCWEndDate.contains(cwDetail.IDN_CASE_CHATS__c) && caseWithBlankCWEndDate.contains(cwDetail.IDN_CLIENT__c))
                        || (cwDetail.IDN_CASE_CHATS__c == null && cwDetail.IDN_CLIENT__c != null
                           	&& caseWithBlankCWEndDate.contains(cwDetail.IDN_CLIENT__c))){
                		cwDetail.addError('Record cannot be created or updated as End Date of existing record is null'); 
                   	}
            }
            else if(cwDetail.IDN_CASE_CHATS__c != null && cwDetail.IDN_CLIENT__c != null) {
                if(oldCWDetailMap != null && oldCWDetailMap.KeySet().size()>0){
                    if(oldCWDetailMap.containsKey(cwDetail.IDN_CASE_CHATS__c)){
                        for(T_CW_ADDNL_INFO__c oldcwDetail : oldCWDetailMap.get(cwDetail.IDN_CASE_CHATS__c)){
                            if(oldcwDetail.DTE_BEGIN_EFFEV__c != null){
                                if(((oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_BEGIN_EFFEV__c) 
                                    && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_END_EFFEV__c)
                                    && oldcwDetail.DTE_END_EFFEV__c != null
                                   	&& oldcwDetail.IDN_CASE_CHATS__c == cwDetail.IDN_CASE_CHATS__c
                                    && oldcwDetail.IDN_CLIENT__c == cwDetail.IDN_CLIENT__c)
                                   || ((oldcwDetail.DTE_BEGIN_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c) 
                                       && (oldcwDetail.DTE_END_EFFEV__c <= cwDetail.DTE_END_EFFEV__c) 
                                       && oldcwDetail.DTE_END_EFFEV__c != null
                                       && oldcwDetail.IDN_CASE_CHATS__c == cwDetail.IDN_CASE_CHATS__c
                                       && oldcwDetail.IDN_CLIENT__c == cwDetail.IDN_CLIENT__c)
                                   || ((oldcwDetail.DTE_BEGIN_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c) 
                                       && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_END_EFFEV__c)
                                       && (oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_END_EFFEV__c)
                                       && oldcwDetail.DTE_END_EFFEV__c != null
                                       && oldcwDetail.IDN_CASE_CHATS__c == cwDetail.IDN_CASE_CHATS__c
                                       && oldcwDetail.IDN_CLIENT__c == cwDetail.IDN_CLIENT__c)
                                   || ((oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_BEGIN_EFFEV__c) 
                                       && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c)
                                       && oldcwDetail.DTE_END_EFFEV__c != null
                                       && oldcwDetail.IDN_CASE_CHATS__c == cwDetail.IDN_CASE_CHATS__c
                                       && oldcwDetail.IDN_CLIENT__c == cwDetail.IDN_CLIENT__c)) {
                                           cwDetail.addError('Record begin date or end date cannot overlap existing record begin or end date.');    
                                       }
                            }
                        } 
                    }
                }
            }
            else if(cwDetail.IDN_CLIENT__c != null) {
                if(oldCWDetailClientMap != null && oldCWDetailClientMap.KeySet().size()>0){
                    if(oldCWDetailClientMap.containsKey(cwDetail.IDN_CLIENT__c)){
                        for(T_CW_ADDNL_INFO__c oldcwDetail : oldCWDetailClientMap.get(cwDetail.IDN_CLIENT__c)){
                        	if(oldcwDetail.DTE_BEGIN_EFFEV__c != null){
                            if(((oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_BEGIN_EFFEV__c) 
                                && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_END_EFFEV__c)
                                && oldcwDetail.DTE_END_EFFEV__c != null)
                               || ((oldcwDetail.DTE_BEGIN_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldcwDetail.DTE_END_EFFEV__c <= cwDetail.DTE_END_EFFEV__c) 
                                   && oldcwDetail.DTE_END_EFFEV__c != null)
                               || ((oldcwDetail.DTE_BEGIN_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_END_EFFEV__c)
                                   && (oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_END_EFFEV__c)
                                   && oldcwDetail.DTE_END_EFFEV__c != null)
                               || ((oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c)
                                   && oldcwDetail.DTE_END_EFFEV__c != null)) {
                                  cwDetail.addError('Record begin date or end date cannot overlap existing record begin or end date.');    
                              }
                        	}
                        }
                    }
                }
            }
            else if(cwDetail.IDN_CASE_CHATS__c != null) {  // there is never a scenario with case != null and Individaul as Null
                if(oldCWDetailMap != null && oldCWDetailMap.KeySet().size()>0){
                    if(oldCWDetailMap.containsKey(cwDetail.IDN_CASE_CHATS__c)){
                        for(T_CW_ADDNL_INFO__c oldcwDetail : oldCWDetailMap.get(cwDetail.IDN_CASE_CHATS__c)){
                        	if(oldcwDetail.DTE_BEGIN_EFFEV__c != null){
                            if(((oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_BEGIN_EFFEV__c) 
                                && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_END_EFFEV__c)
                                && oldcwDetail.DTE_END_EFFEV__c != null)
                               || ((oldcwDetail.DTE_BEGIN_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldcwDetail.DTE_END_EFFEV__c <= cwDetail.DTE_END_EFFEV__c) 
                                   && oldcwDetail.DTE_END_EFFEV__c != null)
                               || ((oldcwDetail.DTE_BEGIN_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_END_EFFEV__c)
                                   && (oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_END_EFFEV__c)
                                   && oldcwDetail.DTE_END_EFFEV__c != null)
                               || ((oldcwDetail.DTE_BEGIN_EFFEV__c <= cwDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldcwDetail.DTE_END_EFFEV__c >= cwDetail.DTE_BEGIN_EFFEV__c)
                                   && oldcwDetail.DTE_END_EFFEV__c != null)) {
                                  cwDetail.addError('Record begin date or end date cannot overlap existing record begin or end date.');    
                              }
                        	}
                        } 
                    }
                }
            }
        }         
    }
    
    public static void updateTANFDetailEndDate(List<T_CBMS_ADDNL_INFO__c> newTANFDetailList, Boolean triggerContext){
        
        List<T_CBMS_ADDNL_INFO__c> oldTANFDetailList = new List<T_CBMS_ADDNL_INFO__c>();
        Set<Id>tanfDetailID = new Set<Id>();
        Set<Id>caseIds = new Set<Id>();
        Map<Id, List<T_CBMS_ADDNL_INFO__c>> oldTANFDetailMap = new Map<Id, List<T_CBMS_ADDNL_INFO__c>>();
        Map<String,T_CBMS_ADDNL_INFO__c> newTANFDetailMap = new Map<String,T_CBMS_ADDNL_INFO__c>();
        Map<Id,T_SBSD_CASE__c> caseMap = new Map<Id,T_SBSD_CASE__c>();
        
        for(T_CBMS_ADDNL_INFO__c tanfDetail : newTANFDetailList){
            newTANFDetailMap.put(tanfDetail.IDN_CASE_CHATS__c, tanfDetail);
            if(!triggerContext){
                tanfDetailID.add(tanfDetail.id);  
            }
            caseIds.add(tanfDetail.IDN_CASE_CHATS__c);
        }
        
        
        Set<Id> caseWithBlankTANFEndDate = new Set<Id>();
        for(T_CBMS_ADDNL_INFO__c tanfDet :[SELECT id,IDN_CASE_CHATS__c,DTE_BEGIN_EFFEV__c,DTE_END_EFFEV__c from T_CBMS_ADDNL_INFO__c where IDN_CASE_CHATS__c IN:caseIds AND ID NOT IN:tanfDetailID WITH SECURITY_ENFORCED]){
            if(oldTANFDetailMap.containsKey(tanfDet.IDN_CASE_CHATS__c)){
                oldTANFDetailMap.get(tanfDet.IDN_CASE_CHATS__c).add(tanfDet); 
            }else{
                oldTANFDetailMap.put(tanfDet.IDN_CASE_CHATS__c,new List<T_CBMS_ADDNL_INFO__c>{tanfDet});
            }
            if(tanfDet.DTE_END_EFFEV__c == null &&  tanfDet.DTE_BEGIN_EFFEV__c != null){
                caseWithBlankTANFEndDate.add(tanfDet.IDN_CASE_CHATS__c);
            }
            
        }
        
        
        for(T_CBMS_ADDNL_INFO__c tanfDetail : newTANFDetailList){
            
            if(tanfDetail.DTE_BEGIN_EFFEV__c != null && tanfDetail.DTE_END_EFFEV__c != null && tanfDetail.DTE_END_EFFEV__c < tanfDetail.DTE_BEGIN_EFFEV__c){
                tanfDetail.addError('Effective End Date must be equal to or greater than the Effective Begin Date.');   
            }
            else if(caseWithBlankTANFEndDate != null && caseWithBlankTANFEndDate.size()>0 && caseWithBlankTANFEndDate.contains(tanfDetail.IDN_CASE_CHATS__c)){
                tanfDetail.addError('Record cannot be created or updated as End Date of existing record is null'); 
            }
            else if(tanfDetail.IDN_CASE_CHATS__c != null) {
                if(oldTANFDetailMap != null && oldTANFDetailMap.KeySet().size()>0){
                    if(oldTANFDetailMap.containsKey(tanfDetail.IDN_CASE_CHATS__c)){
                        for(T_CBMS_ADDNL_INFO__c oldtanfDetail : oldTANFDetailMap.get(tanfDetail.IDN_CASE_CHATS__c)){
                            if(oldtanfDetail.DTE_BEGIN_EFFEV__c != null){
                            if(((oldtanfDetail.DTE_BEGIN_EFFEV__c <= tanfDetail.DTE_BEGIN_EFFEV__c) 
                                && (oldtanfDetail.DTE_END_EFFEV__c >= tanfDetail.DTE_END_EFFEV__c)
                                && oldtanfDetail.DTE_END_EFFEV__c != null)
                               || ((oldtanfDetail.DTE_BEGIN_EFFEV__c >= tanfDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldtanfDetail.DTE_END_EFFEV__c <= tanfDetail.DTE_END_EFFEV__c) 
                                   && oldtanfDetail.DTE_END_EFFEV__c != null)
                               || ((oldtanfDetail.DTE_BEGIN_EFFEV__c >= tanfDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldtanfDetail.DTE_END_EFFEV__c >= tanfDetail.DTE_END_EFFEV__c)
                                   && (oldtanfDetail.DTE_BEGIN_EFFEV__c <= tanfDetail.DTE_END_EFFEV__c)
                                   && oldtanfDetail.DTE_END_EFFEV__c != null)
                               || ((oldtanfDetail.DTE_BEGIN_EFFEV__c <= tanfDetail.DTE_BEGIN_EFFEV__c) 
                                   && (oldtanfDetail.DTE_END_EFFEV__c >= tanfDetail.DTE_BEGIN_EFFEV__c)
                                   && oldtanfDetail.DTE_END_EFFEV__c != null)) {
                                  tanfDetail.addError('Record begin date or end date cannot overlap existing record begin or end date.');    
                              }
                            }
                        }
                        
                    }
                }
            }
        }
        
        
    }
    
    //Changes for CCCAP-995
    //Changes for CCCAP-1884
    public static void updateEmpInfoOnParentObject(List<T_INDIV_EMPLMT_INFO__c> newEmpInfoList){
        Map<String,T_INDIV_EMPLMT_INFO__c> oldFutureEmpInfoMap = new Map<String,T_INDIV_EMPLMT_INFO__c>();
        Set<Id> empIds = new Set<Id>();
        Set<Id> empInfoIds = new Set<Id>();
        Map<String,T_INDIV_EMPLMT_INFO__c> oldEmpInfoMap = new Map<String,T_INDIV_EMPLMT_INFO__c>();
        Map<String,T_INDIV_EMPLMT_INFO__c> newEmpInfoMap = new Map<String,T_INDIV_EMPLMT_INFO__c>();
        List<T_SBSD_INDIV_EMPLMT__c> empListToBeUpdated = new List<T_SBSD_INDIV_EMPLMT__c>();
        Date todayDate = system.today();
        for(T_INDIV_EMPLMT_INFO__c obj:newEmpInfoList){
            empIds.add(obj.IDN_EMPLMT_INDIV__c);
            empInfoIds.add(obj.id);
            //if(obj.DTE_BEGIN_EFFV__c <= todayDate && (obj.DTE_END_EFFV__c >=todayDate ||  obj.DTE_END_EFFV__c == null)){
                newEmpInfoMap.put(obj.IDN_EMPLMT_INDIV__c,obj);
           // }
        }
        for(T_INDIV_EMPLMT_INFO__c empInfo:[SELECT id,IDN_EMPLMT_INDIV__c,DTE_BEGIN_EFFV__c,CDE_TYPE_INFO_EMPLMT__c,CDE_TYPE_VERIF__c,
                                         DTE_END_EFFV__c from T_INDIV_EMPLMT_INFO__c where IDN_EMPLMT_INDIV__c IN:empIds and ID NOT IN :empInfoIds and
                                         DTE_BEGIN_EFFV__c <:todayDate AND (DTE_END_EFFV__c >=:todayDate or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED]){
                                            // if(!newEmpInfoMap.containsKey(empInfo.IDN_EMPLMT_INDIV__c)){
                                                oldEmpInfoMap.put(empInfo.IDN_EMPLMT_INDIV__c,empInfo);
                                            // }
            
        }
        if(!(oldEmpInfoMap.size()>0)){
            for(T_INDIV_EMPLMT_INFO__c csAdd:[SELECT id,IDN_EMPLMT_INDIV__c,DTE_BEGIN_EFFV__c,CDE_TYPE_VERIF__c,CDE_TYPE_INFO_EMPLMT__c,
                                          DTE_END_EFFV__c from T_INDIV_EMPLMT_INFO__c where IDN_EMPLMT_INDIV__c IN:empIds and ID NOT IN :empInfoIds and
                                             DTE_BEGIN_EFFV__c >=:todayDate AND (DTE_END_EFFV__c >=:todayDate or DTE_END_EFFV__c =null ) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c DESC]){
                                                 
                                                 if(oldFutureEmpInfoMap.containsKey(csAdd.IDN_EMPLMT_INDIV__c)){
                                                     T_INDIV_EMPLMT_INFO__c temp = oldFutureEmpInfoMap.get(csAdd.IDN_EMPLMT_INDIV__c);
                                                     if(temp.DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                                                         oldFutureEmpInfoMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
                                                     }
                                                 }else{
                                                     oldFutureEmpInfoMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
                                                 }
                                                 
                                             }
        }
        for(T_SBSD_INDIV_EMPLMT__c empObj:[SELECT Id,CDE_TYPE_INFO_EMPLMT__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_SBSD_INDIV_EMPLMT__c WHERE Id IN:empIds WITH SECURITY_ENFORCED]){
            
            if(oldEmpInfoMap.containsKey(empObj.Id)){
                system.debug('empObj-if-'+empObj);
                T_INDIV_EMPLMT_INFO__c obj = oldEmpInfoMap.get(empObj.Id);
                empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                empObj.CDE_TYPE_INFO_EMPLMT__c = obj.CDE_TYPE_INFO_EMPLMT__c;
                empListToBeUpdated.add(empObj);
            } else if(newEmpInfoMap.containsKey(empObj.Id)){
                system.debug('empObj-else if-'+empObj);
                T_INDIV_EMPLMT_INFO__c obj = newEmpInfoMap.get(empObj.Id);
                if(oldFutureEmpInfoMap.containsKey(empObj.Id) ){
                    T_INDIV_EMPLMT_INFO__c objOld = oldFutureEmpInfoMap.get(empObj.Id);
                    if(objOld.DTE_BEGIN_EFFV__c <obj.DTE_BEGIN_EFFV__c){
                        empObj.DTE_BEGIN_EFFV_INFO__c = objOld.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = objOld.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_EMPLMT__c = objOld.CDE_TYPE_INFO_EMPLMT__c;
                        empListToBeUpdated.add(empObj); 
                    }else{
                        empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_EMPLMT__c = obj.CDE_TYPE_INFO_EMPLMT__c;
                        empListToBeUpdated.add(empObj); 
                    }
                    
                }else{
                    empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                    empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                    empObj.CDE_TYPE_INFO_EMPLMT__c = obj.CDE_TYPE_INFO_EMPLMT__c;
                    empListToBeUpdated.add(empObj);  
                }
            }             
        }
        if(empListToBeUpdated.size()>0){
            GenericDMLHandler.updateRecords(empListToBeUpdated, new Map<String,Object>{'Method__c'=>'updateTeenInfoOnParentObject','Class__c'=>'CaseLastUpdatedServices'});
        }
    }
    
    public static void updateTeenEduInfoOnParentObject(List<T_INDIV_EDUC_INFO__c> newEmpInfoList){
        Set<Id> empIds = new Set<Id>();
        Set<Id> empInfoIds = new Set<Id>();
        Map<String,T_INDIV_EDUC_INFO__c> oldEmpInfoMap = new Map<String,T_INDIV_EDUC_INFO__c>();
        Map<String,T_INDIV_EDUC_INFO__c> oldFutureEmpInfoMap = new Map<String,T_INDIV_EDUC_INFO__c>();
        Map<String,T_INDIV_EDUC_INFO__c> newEmpInfoMap = new Map<String,T_INDIV_EDUC_INFO__c>();
        List<T_INDIV_EDUC__c> empListToBeUpdated = new List<T_INDIV_EDUC__c>();
        Date todayDate = system.today();
        for(T_INDIV_EDUC_INFO__c obj:newEmpInfoList){
            empIds.add(obj.IDN_EDUC_INDIV__c);
            empInfoIds.add(obj.id);
           // if(obj.DTE_BEGIN_EFFV__c <= todayDate && (obj.DTE_END_EFFV__c >=todayDate ||  obj.DTE_END_EFFV__c == null)){
                newEmpInfoMap.put(obj.IDN_EDUC_INDIV__c,obj);
           // }
        }
        system.debug('empIds--'+empIds);
        system.debug('empInfoIds--'+empInfoIds);
        system.debug('newEmpInfoMap--'+newEmpInfoMap);
        for(T_INDIV_EDUC_INFO__c empInfo:[SELECT id,IDN_EDUC_INDIV__c,DTE_BEGIN_EFFV__c,CDE_TYPE_INFO_EDUC__c,
                                          DTE_END_EFFV__c from T_INDIV_EDUC_INFO__c where IDN_EDUC_INDIV__c IN:empIds and ID NOT IN :empInfoIds and
                                          DTE_BEGIN_EFFV__c <=:todayDate AND (DTE_END_EFFV__c >=:todayDate or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED]){
                                             // if(!newEmpInfoMap.containsKey(empInfo.IDN_EDUC_INDIV__c)){
                                                  oldEmpInfoMap.put(empInfo.IDN_EDUC_INDIV__c,empInfo);
                                            //  }
                                              
                                          }
        if(!(oldEmpInfoMap.size()>0)){
            for(T_INDIV_EDUC_INFO__c csAdd:[SELECT id,IDN_EDUC_INDIV__c,DTE_BEGIN_EFFV__c,CDE_TYPE_INFO_EDUC__c,
                                          DTE_END_EFFV__c from T_INDIV_EDUC_INFO__c where IDN_EDUC_INDIV__c IN:empIds and ID NOT IN :empInfoIds and
                                             DTE_BEGIN_EFFV__c >=:todayDate AND (DTE_END_EFFV__c >=:todayDate or DTE_END_EFFV__c =null ) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c DESC]){
                                                 
                                                 if(oldFutureEmpInfoMap.containsKey(csAdd.IDN_EDUC_INDIV__c)){
                                                     T_INDIV_EDUC_INFO__c temp = oldFutureEmpInfoMap.get(csAdd.IDN_EDUC_INDIV__c);
                                                     if(temp.DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                                                         oldFutureEmpInfoMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
                                                     }
                                                 }else{
                                                     oldFutureEmpInfoMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
                                                 }
                                                 
                                             }
        }
        system.debug('newEmpInfoMap--'+newEmpInfoMap);
        for(T_INDIV_EDUC__c empObj:[SELECT Id,CDE_TYPE_INFO_EDUC__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_INDIV_EDUC__c WHERE Id IN:empIds WITH SECURITY_ENFORCED]){
            system.debug('empObj--'+empObj);
            if(oldEmpInfoMap.containsKey(empObj.Id)){
                system.debug('empObj-if-'+empObj);
                T_INDIV_EDUC_INFO__c obj = oldEmpInfoMap.get(empObj.Id);
                empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                empObj.CDE_TYPE_INFO_EDUC__c = obj.CDE_TYPE_INFO_EDUC__c;
                empListToBeUpdated.add(empObj);
            } else if(newEmpInfoMap.containsKey(empObj.Id)){
                system.debug('empObj-else if-'+empObj);
                T_INDIV_EDUC_INFO__c obj = newEmpInfoMap.get(empObj.Id);
                if(oldFutureEmpInfoMap.containsKey(empObj.Id) ){
                    T_INDIV_EDUC_INFO__c objOld = oldFutureEmpInfoMap.get(empObj.Id);
                    if(objOld.DTE_BEGIN_EFFV__c <obj.DTE_BEGIN_EFFV__c){
                        empObj.DTE_BEGIN_EFFV_INFO__c = objOld.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = objOld.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_EDUC__c = objOld.CDE_TYPE_INFO_EDUC__c;
                        empListToBeUpdated.add(empObj); 
                    }else{
                        empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_EDUC__c = obj.CDE_TYPE_INFO_EDUC__c;
                        empListToBeUpdated.add(empObj); 
                    }
                    
                }else{
                    empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                    empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                    empObj.CDE_TYPE_INFO_EDUC__c = obj.CDE_TYPE_INFO_EDUC__c;
                    empListToBeUpdated.add(empObj);  
                }
            }  
            
            
        }
        system.debug('empListToBeUpdated--'+empListToBeUpdated);
        if(empListToBeUpdated.size()>0){
            GenericDMLHandler.updateRecords(empListToBeUpdated, new Map<String,Object>{'Method__c'=>'updateParentEduInfoOnParentObject','Class__c'=>'CaseLastUpdatedServices'});
        }
    }
    
    public static void updateParentTrainignBreak(List<T_INDIV_TRAIN_INFO__c> newEmpInfoList){
        Set<Id> empIds = new Set<Id>();
        Set<Id> empInfoIds = new Set<Id>();
        Map<String,T_INDIV_TRAIN_INFO__c> oldEmpInfoMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
        Map<String,T_INDIV_TRAIN_INFO__c> oldFutureEmpInfoMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
        Map<String,T_INDIV_TRAIN_INFO__c> newEmpInfoMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
        List<T_INDIV_TRAIN__c> empListToBeUpdated = new List<T_INDIV_TRAIN__c>();
        Date todayDate = system.today();
        
        for(T_INDIV_TRAIN_INFO__c obj:newEmpInfoList){
            empIds.add(obj.IDN_TRAIN_INDIV__c);
            empInfoIds.add(obj.id);
            //if(obj.DTE_BEGIN_EFFV__c <= todayDate && (obj.DTE_END_EFFV__c >=todayDate ||  obj.DTE_END_EFFV__c == null)){
            newEmpInfoMap.put(obj.IDN_TRAIN_INDIV__c,obj);
            // }
        }
        for(T_INDIV_TRAIN_INFO__c empInfo:[SELECT id,IDN_TRAIN_INDIV__c,DTE_BEGIN_EFFV__c,CDE_TYPE_INFO_TRAIN__c,
                                           DTE_END_EFFV__c from T_INDIV_TRAIN_INFO__c where IDN_TRAIN_INDIV__c IN:empIds and ID NOT IN :empInfoIds and
                                           DTE_BEGIN_EFFV__c <=:todayDate AND (DTE_END_EFFV__c >=:todayDate or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED]){
                                               // if(!newEmpInfoMap.containsKey(empInfo.IDN_TRAIN_INDIV__c)){
                                               oldEmpInfoMap.put(empInfo.IDN_TRAIN_INDIV__c,empInfo);
                                               //  }
                                               
                                           }
        if(!(oldEmpInfoMap.size()>0)){
            for(T_INDIV_TRAIN_INFO__c csAdd:[SELECT id,IDN_TRAIN_INDIV__c,DTE_BEGIN_EFFV__c,CDE_TYPE_INFO_TRAIN__c,
                                             DTE_END_EFFV__c from T_INDIV_TRAIN_INFO__c where IDN_TRAIN_INDIV__c IN:empIds and ID NOT IN :empInfoIds and
                                             DTE_BEGIN_EFFV__c >=:todayDate AND (DTE_END_EFFV__c >=:todayDate or DTE_END_EFFV__c =null ) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c DESC ]){
                                                 
                                                 if(oldFutureEmpInfoMap.containsKey(csAdd.IDN_TRAIN_INDIV__c)){
                                                     T_INDIV_TRAIN_INFO__c temp = oldFutureEmpInfoMap.get(csAdd.IDN_TRAIN_INDIV__c);
                                                     if(temp.DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                                                         oldFutureEmpInfoMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
                                                     }
                                                 }else{
                                                     oldFutureEmpInfoMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
                                                 }
                                                 
                                             }
        }
        
        for(T_INDIV_TRAIN__c empObj:[SELECT Id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_INDIV_TRAIN__c WHERE Id IN:empIds WITH SECURITY_ENFORCED]){
            
            if(oldEmpInfoMap.containsKey(empObj.Id)){
                T_INDIV_TRAIN_INFO__c obj = oldEmpInfoMap.get(empObj.Id);
                empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                empObj.CDE_TYPE_INFO_TRAIN__c = obj.CDE_TYPE_INFO_TRAIN__c;
                empListToBeUpdated.add(empObj);
            } else if(newEmpInfoMap.containsKey(empObj.Id)){
                T_INDIV_TRAIN_INFO__c obj = newEmpInfoMap.get(empObj.Id);
                if(oldFutureEmpInfoMap.containsKey(empObj.Id) ){
                    T_INDIV_TRAIN_INFO__c objOld = oldFutureEmpInfoMap.get(empObj.Id);
                    if(objOld.DTE_BEGIN_EFFV__c <obj.DTE_BEGIN_EFFV__c){
                        empObj.DTE_BEGIN_EFFV_INFO__c = objOld.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = objOld.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_TRAIN__c = objOld.CDE_TYPE_INFO_TRAIN__c;
                        empListToBeUpdated.add(empObj); 
                    }else{
                        empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_TRAIN__c = obj.CDE_TYPE_INFO_TRAIN__c;
                        empListToBeUpdated.add(empObj); 
                    }
                    
                }else{
                    empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                    empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                    empObj.CDE_TYPE_INFO_TRAIN__c = obj.CDE_TYPE_INFO_TRAIN__c;
                    empListToBeUpdated.add(empObj);  
                }
            }              
        }
        if(empListToBeUpdated.size()>0){
            GenericDMLHandler.updateRecords(empListToBeUpdated, new Map<String,Object>{'Method__c'=>'updateIndivTrainignBreak','Class__c'=>'CaseLastUpdatedServices'});
        }
    }
    
    // After Delete
    public static void updateParentTrainingTmpBrkAfterDlt(List<T_INDIV_TRAIN_INFO__c> oldTempBrkList){
        List<T_INDIV_TRAIN__c> oldTempBrktList = new List<T_INDIV_TRAIN__c>();
        Set<String>TempBrkIds = new Set<String>();
        Set<String> oldParentTrainingInfoIds = new Set<String>();
        Set<String>parentTrainingIds = new Set<String>();
        Date todayDate = system.today();
        Map<String,T_INDIV_TRAIN_INFO__c> newTempBrkMap = new Map<String,T_INDIV_TRAIN_INFO__c>(); 
        Map<String,T_INDIV_TRAIN_INFO__c> latestTempBrkMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
        Map<String,T_INDIV_TRAIN_INFO__c> oldLatestTempBrkMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
        for(T_INDIV_TRAIN_INFO__c csAddr : oldTempBrkList){
           // if(csAddr.DTE_BEGIN_EFFV__c <= todayDate && (csAddr.DTE_END_EFFV__c >=todayDate ||  csAddr.DTE_END_EFFV__c == null)){
                oldParentTrainingInfoIds.add(csAddr.IDN_TRAIN_INDIV__c);
                newTempBrkMap.put(csAddr.IDN_TRAIN_INDIV__c,csAddr);
          //  }
        }
        system.debug('oldParentTrainingInfoIds--'+oldParentTrainingInfoIds);
        for(T_INDIV_TRAIN_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_TRAIN_INDIV__c from T_INDIV_TRAIN_INFO__c where IDN_TRAIN_INDIV__c IN:oldParentTrainingInfoIds and (DTE_END_EFFV__c >=TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(latestTempBrkMap.containsKey(csAdd.IDN_TRAIN_INDIV__c)){
                T_INDIV_TRAIN_INFO__c temp = latestTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                    latestTempBrkMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
                }
            }else{
                latestTempBrkMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
            }
            
        }
        for(T_INDIV_TRAIN_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_TRAIN_INDIV__c from T_INDIV_TRAIN_INFO__c where IDN_TRAIN_INDIV__c IN:oldParentTrainingInfoIds  and (DTE_END_EFFV__c <=TODAY ) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(oldLatestTempBrkMap.containsKey(csAdd.IDN_TRAIN_INDIV__c)){
                T_INDIV_TRAIN_INFO__c temp = oldLatestTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c <csAdd.DTE_BEGIN_EFFV__c){
                    oldLatestTempBrkMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
                }
            }else{
                oldLatestTempBrkMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
            }
            
        }
        system.debug('oldLatestTempBrkMap--'+oldLatestTempBrkMap);
        for(T_INDIV_TRAIN__c empObj:[SELECT Id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_INDIV_TRAIN__c WHERE Id IN:oldParentTrainingInfoIds WITH SECURITY_ENFORCED]){
           T_INDIV_TRAIN_INFO__c objTemp = newTempBrkMap.get(empObj.Id);
            if(empObj.DTE_BEGIN_EFFV_INFO__c == objTemp.DTE_BEGIN_EFFV__c){
                if(latestTempBrkMap.containsKey(empObj.Id)){
                    T_INDIV_TRAIN_INFO__c obj = latestTempBrkMap.get(empObj.Id);
                    empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                    empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                    empObj.CDE_TYPE_INFO_TRAIN__c = obj.CDE_TYPE_INFO_TRAIN__c;
                    oldTempBrktList.add(empObj);
                }else{
                    if(oldLatestTempBrkMap.containsKey(empObj.Id)){
                        T_INDIV_TRAIN_INFO__c obj = oldLatestTempBrkMap.get(empObj.Id);
                        empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_TRAIN__c = obj.CDE_TYPE_INFO_TRAIN__c;
                        oldTempBrktList.add(empObj);
                    }else{
                        empObj.DTE_BEGIN_EFFV_INFO__c = null;
                        empObj.DTE_END_EFFV_INFO__c = null;
                        empObj.CDE_TYPE_INFO_TRAIN__c = '';
                        oldTempBrktList.add(empObj);  
                    }
                }   
            }
        }
        system.debug('oldTempBrktList--'+oldTempBrktList);
        if(oldTempBrktList.size()>0){ 
            GenericDMLHandler.updateRecords(oldTempBrktList,new Map<String,Object>{'Method__c'=>'updateParentTrainingTmpBrkafterDlt','Class__c'=>'caseAddressServices'}); 
        }
        
    }
    // end
    
    // After Delete
    public static void updateEmpTmpBrkAfterDlt(List<T_INDIV_EMPLMT_INFO__c> oldTempBrkList){
        List<T_SBSD_INDIV_EMPLMT__c> oldTempBrktList = new List<T_SBSD_INDIV_EMPLMT__c>();
        Set<String>TempBrkIds = new Set<String>();
        Set<String> oldParentTrainingInfoIds = new Set<String>();
        Set<String>parentTrainingIds = new Set<String>();
        Date todayDate = system.today();
        Map<String,T_INDIV_EMPLMT_INFO__c> newTempBrkMap = new Map<String,T_INDIV_EMPLMT_INFO__c>(); 
        Map<String,T_INDIV_EMPLMT_INFO__c> latestTempBrkMap = new Map<String,T_INDIV_EMPLMT_INFO__c>(); 
        Map<String,T_INDIV_EMPLMT_INFO__c> oldLatestTempBrkMap = new Map<String,T_INDIV_EMPLMT_INFO__c>(); 
        for(T_INDIV_EMPLMT_INFO__c csAddr : oldTempBrkList){
            //if(csAddr.DTE_BEGIN_EFFV__c <= todayDate && (csAddr.DTE_END_EFFV__c >=todayDate ||  csAddr.DTE_END_EFFV__c == null)){
            oldParentTrainingInfoIds.add(csAddr.IDN_EMPLMT_INDIV__c);
            newTempBrkMap.put(csAddr.IDN_EMPLMT_INDIV__c,csAddr);
            // }
        }
        system.debug('oldParentTrainingInfoIds--'+oldParentTrainingInfoIds);
        for(T_INDIV_EMPLMT_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EMPLMT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EMPLMT_INDIV__c from T_INDIV_EMPLMT_INFO__c where IDN_EMPLMT_INDIV__c IN:oldParentTrainingInfoIds  and (DTE_END_EFFV__c >=TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(latestTempBrkMap.containsKey(csAdd.IDN_EMPLMT_INDIV__c)){
                T_INDIV_EMPLMT_INFO__c temp = latestTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                    latestTempBrkMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
                }
            }else{
                latestTempBrkMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
            }
            
        }
        for(T_INDIV_EMPLMT_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EMPLMT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EMPLMT_INDIV__c from T_INDIV_EMPLMT_INFO__c where IDN_EMPLMT_INDIV__c IN:oldParentTrainingInfoIds and (DTE_END_EFFV__c <=TODAY ) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(oldLatestTempBrkMap.containsKey(csAdd.IDN_EMPLMT_INDIV__c)){
                T_INDIV_EMPLMT_INFO__c temp = oldLatestTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c <csAdd.DTE_BEGIN_EFFV__c){
                    oldLatestTempBrkMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
                }
            }else{
                oldLatestTempBrkMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
            }
            
        }
        system.debug('oldLatestTempBrkMap--'+oldLatestTempBrkMap);
        for(T_SBSD_INDIV_EMPLMT__c empObj:[SELECT Id,CDE_TYPE_INFO_EMPLMT__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_SBSD_INDIV_EMPLMT__c WHERE Id IN:oldParentTrainingInfoIds WITH SECURITY_ENFORCED]){
            T_INDIV_EMPLMT_INFO__c objTemp = newTempBrkMap.get(empObj.Id);
            if(empObj.DTE_BEGIN_EFFV_INFO__c == objTemp.DTE_BEGIN_EFFV__c){
                if(latestTempBrkMap.containsKey(empObj.Id)){
                    T_INDIV_EMPLMT_INFO__c obj = latestTempBrkMap.get(empObj.Id);
                    empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                    empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                    empObj.CDE_TYPE_INFO_EMPLMT__c = obj.CDE_TYPE_INFO_EMPLMT__c;
                    oldTempBrktList.add(empObj);  
                }else{
                    if(oldLatestTempBrkMap.containsKey(empObj.Id)){
                        T_INDIV_EMPLMT_INFO__c obj = oldLatestTempBrkMap.get(empObj.Id);
                        empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_EMPLMT__c = obj.CDE_TYPE_INFO_EMPLMT__c;
                        oldTempBrktList.add(empObj);  
                    }else{
                        empObj.DTE_BEGIN_EFFV_INFO__c = null;
                        empObj.DTE_END_EFFV_INFO__c = null;
                        empObj.CDE_TYPE_INFO_EMPLMT__c = '';
                        oldTempBrktList.add(empObj); 
                    } 
                }
            }              
        }
        system.debug('oldTempBrktList--'+oldTempBrktList);
        if(oldTempBrktList.size()>0){ 
            GenericDMLHandler.updateRecords(oldTempBrktList,new Map<String,Object>{'Method__c'=>'updateParentTrainingTmpBrkafterDlt','Class__c'=>'caseAddressServices'}); 
        }
        
    }
    // end
    
    // After Delete
    public static void updateTeenEduBrkAfterDlt(List<T_INDIV_EDUC_INFO__c> oldTempBrkList){
        List<T_INDIV_EDUC__c> oldTempBrktList = new List<T_INDIV_EDUC__c>();
        Set<String>TempBrkIds = new Set<String>();
        Set<String> oldParentTrainingInfoIds = new Set<String>();
        Set<String>parentTrainingIds = new Set<String>();
        Date todayDate = system.today();
        Map<String,T_INDIV_EDUC_INFO__c> newTempBrkMap = new Map<String,T_INDIV_EDUC_INFO__c>(); 
        Map<String,T_INDIV_EDUC_INFO__c> latestTempBrkMap = new Map<String,T_INDIV_EDUC_INFO__c>();
        Map<String,T_INDIV_EDUC_INFO__c> oldLatestTempBrkMap = new Map<String,T_INDIV_EDUC_INFO__c>();
        for(T_INDIV_EDUC_INFO__c csAddr : oldTempBrkList){
          //  if(csAddr.DTE_BEGIN_EFFV__c <= todayDate && (csAddr.DTE_END_EFFV__c >=todayDate ||  csAddr.DTE_END_EFFV__c == null)){
                oldParentTrainingInfoIds.add(csAddr.IDN_EDUC_INDIV__c);
                newTempBrkMap.put(csAddr.IDN_EDUC_INDIV__c,csAddr);
           // }
        }
        system.debug('oldParentTrainingInfoIds--'+oldParentTrainingInfoIds);
        for(T_INDIV_EDUC_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EDUC__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EDUC_INDIV__c from T_INDIV_EDUC_INFO__c where IDN_EDUC_INDIV__c IN:oldParentTrainingInfoIds  and (DTE_END_EFFV__c >=TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(latestTempBrkMap.containsKey(csAdd.IDN_EDUC_INDIV__c)){
                T_INDIV_EDUC_INFO__c temp = latestTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                    latestTempBrkMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
                }
            }else{
                latestTempBrkMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
            }
            
        }
        for(T_INDIV_EDUC_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EDUC__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EDUC_INDIV__c from T_INDIV_EDUC_INFO__c where IDN_EDUC_INDIV__c IN:oldParentTrainingInfoIds  and (DTE_END_EFFV__c <=TODAY ) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(oldLatestTempBrkMap.containsKey(csAdd.IDN_EDUC_INDIV__c)){
                T_INDIV_EDUC_INFO__c temp = oldLatestTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c <csAdd.DTE_BEGIN_EFFV__c){
                    oldLatestTempBrkMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
                }
            }else{
                oldLatestTempBrkMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
            }
            
        }
        system.debug('oldLatestTempBrkMap--'+oldLatestTempBrkMap);
        for(T_INDIV_EDUC__c empObj:[SELECT Id,CDE_TYPE_INFO_EDUC__c,DTE_BEGIN_EFFV_INFO__c,DTE_END_EFFV_INFO__c FROM T_INDIV_EDUC__c WHERE Id IN:oldParentTrainingInfoIds WITH SECURITY_ENFORCED]){
            
            T_INDIV_EDUC_INFO__c objTemp = newTempBrkMap.get(empObj.Id);
            if(empObj.DTE_BEGIN_EFFV_INFO__c == objTemp.DTE_BEGIN_EFFV__c){
                if(latestTempBrkMap.containsKey(empObj.Id)){
                    T_INDIV_EDUC_INFO__c obj = latestTempBrkMap.get(empObj.Id);
                    empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                    empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                    empObj.CDE_TYPE_INFO_EDUC__c = obj.CDE_TYPE_INFO_EDUC__c;
                    oldTempBrktList.add(empObj);
                }else{
                    if(oldLatestTempBrkMap.containsKey(empObj.Id)){
                        T_INDIV_EDUC_INFO__c obj = oldLatestTempBrkMap.get(empObj.Id);
                        empObj.DTE_BEGIN_EFFV_INFO__c = obj.DTE_BEGIN_EFFV__c;
                        empObj.DTE_END_EFFV_INFO__c = obj.DTE_END_EFFV__c;
                        empObj.CDE_TYPE_INFO_EDUC__c = obj.CDE_TYPE_INFO_EDUC__c;
                        oldTempBrktList.add(empObj);
                    }else{
                        empObj.DTE_BEGIN_EFFV_INFO__c = null;
                        empObj.DTE_END_EFFV_INFO__c = null;
                        empObj.CDE_TYPE_INFO_EDUC__c = '';
                        oldTempBrktList.add(empObj);   
                    }   
                }
            }             
        }
        system.debug('oldTempBrktList--'+oldTempBrktList);
        if(oldTempBrktList.size()>0){ 
            GenericDMLHandler.updateRecords(oldTempBrktList,new Map<String,Object>{'Method__c'=>'updateParentTrainingTmpBrkafterDlt','Class__c'=>'caseAddressServices'}); 
        }
        
    }
    // end
    
    public static void updateTeenParentTmpBrkEndDate(List<T_INDIV_EDUC_INFO__c> newTempBrkList,map<Id, T_INDIV_EDUC_INFO__c> oldMapTempBrk){
        List<T_INDIV_EDUC_INFO__c> oldTempBrktList = new List<T_INDIV_EDUC_INFO__c>();
        Map<String,T_INDIV_EDUC_INFO__c> oldFutureEmpInfoMap = new Map<String,T_INDIV_EDUC_INFO__c>();
        Set<String>TempBrkIds = new Set<String>();
        Set<String>teenParentIds = new Set<String>();
        Map<String,T_INDIV_EDUC_INFO__c> newTempBrkMap = new Map<String,T_INDIV_EDUC_INFO__c>();       
        for(T_INDIV_EDUC_INFO__c csAddr : newTempBrkList){
            if(csAddr.DTE_BEGIN_EFFV__c > csAddr.DTE_END_EFFV__c){
                csAddr.addError('End date can not be less than begin date.');
            }
            newTempBrkMap.put(csAddr.IDN_EDUC_INDIV__c, csAddr);
            if(csAddr.id != null){
                TempBrkIds.add(csAddr.id);
                
            }
            teenParentIds.add(csAddr.IDN_EDUC_INDIV__c);
        }
        for(T_INDIV_EDUC_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EDUC__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EDUC_INDIV__c from T_INDIV_EDUC_INFO__c where IDN_EDUC_INDIV__c IN:teenParentIds and id NOT IN:TempBrkIds and (DTE_END_EFFV__c > TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED]){
            
            if(oldFutureEmpInfoMap.containsKey(csAdd.IDN_EDUC_INDIV__c)){
                T_INDIV_EDUC_INFO__c temp = oldFutureEmpInfoMap.get(csAdd.IDN_EDUC_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c <csAdd.DTE_BEGIN_EFFV__c){
                    oldFutureEmpInfoMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
                }
            }else{
                oldFutureEmpInfoMap.put(csAdd.IDN_EDUC_INDIV__c, csAdd);
            }
            
        }
        system.debug('TempBrkIds--'+TempBrkIds);
        system.debug('teenParentIds--'+teenParentIds);
        for(T_INDIV_EDUC_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EDUC__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EDUC_INDIV__c from T_INDIV_EDUC_INFO__c where IDN_EDUC_INDIV__c IN:teenParentIds and id NOT IN:TempBrkIds and (DTE_END_EFFV__c > TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            system.debug('csAdd--'+csAdd);
            system.debug('csAdd--'+csAdd.DTE_BEGIN_EFFV__c);
            system.debug('newTempBrkMap--'+newTempBrkMap);
            if(newTempBrkMap.containsKey(csAdd.IDN_EDUC_INDIV__c)){
                T_INDIV_EDUC_INFO__c  newObj=newTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c);                
                
                if(oldMapTempBrk!= null && oldMapTempBrk.containsKey(newObj.Id)){
                    if(oldMapTempBrk.get(newObj.id).DTE_BEGIN_EFFV__c != newObj.DTE_BEGIN_EFFV__c || (oldMapTempBrk.get(newObj.id).DTE_END_EFFV__c != newObj.DTE_END_EFFV__c)){
                        if((newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c) && (newObj.DTE_END_EFFV__c <=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c || newObj.DTE_END_EFFV__c ==null))){
                               newTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c).addError('Begin date can not be less than currenlty effective Teen Education Temporary Break begin date.');
                           }
                    }  
                }else {
                    if((newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c ) && (newObj.DTE_END_EFFV__c <=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c || newObj.DTE_END_EFFV__c ==null))){
                           newTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c).addError('Begin date can not be less than currenlty effective Teen Education Temporary Break begin date.');
                       }
                }
            }
        }
        for(T_INDIV_EDUC_INFO__c csAdd :oldFutureEmpInfoMap.values()){
            if(newTempBrkMap.containsKey(csAdd.IDN_EDUC_INDIV__c)){
                T_INDIV_EDUC_INFO__c  newObj=newTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c); 
                system.debug('oldMapTempBrk--'+oldMapTempBrk);
                if(oldMapTempBrk== null){
                    if(newTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c).DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c && csAdd.DTE_END_EFFV__c == null){
                        csAdd.DTE_END_EFFV__c =(newTempBrkMap.get(csAdd.IDN_EDUC_INDIV__c).DTE_BEGIN_EFFV__c).addDays(-1);
                        oldTempBrktList.add(csAdd);
                    }
                }
            }
        }
        if(oldTempBrktList.size()>0){
            GenericDMLHandler.updateRecords(oldTempBrktList,new Map<String,Object>{'Method__c'=>'deleteCasePhoneEndDate','Class__c'=>'caseAddressServices'}); 
        }
        
    }
    
    public static void updateParentTrainingTmpBrkEndDate(List<T_INDIV_TRAIN_INFO__c> newTempBrkList,map<Id, T_INDIV_TRAIN_INFO__c> oldMapTempBrk){
        List<T_INDIV_TRAIN_INFO__c> oldTempBrktList = new List<T_INDIV_TRAIN_INFO__c>();
        Map<String,T_INDIV_TRAIN_INFO__c> oldFutureEmpInfoMap = new Map<String,T_INDIV_TRAIN_INFO__c>();
        Set<String>TempBrkIds = new Set<String>();
        Set<String>parentTrainingIds = new Set<String>();
        Map<String,T_INDIV_TRAIN_INFO__c> newTempBrkMap = new Map<String,T_INDIV_TRAIN_INFO__c>();       
        for(T_INDIV_TRAIN_INFO__c csAddr : newTempBrkList){
            if(csAddr.DTE_BEGIN_EFFV__c > csAddr.DTE_END_EFFV__c){
                csAddr.addError('End date can not be less than begin date.');
            }
            newTempBrkMap.put(csAddr.IDN_TRAIN_INDIV__c, csAddr);
            
            TempBrkIds.add(csAddr.id);
            parentTrainingIds.add(csAddr.IDN_TRAIN_INDIV__c);
        }
        for(T_INDIV_TRAIN_INFO__c csAdd:[SELECT id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_TRAIN_INDIV__c from T_INDIV_TRAIN_INFO__c where IDN_TRAIN_INDIV__c IN:parentTrainingIds and id NOT IN:TempBrkIds and (DTE_END_EFFV__c >TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            
            if(oldFutureEmpInfoMap.containsKey(csAdd.IDN_TRAIN_INDIV__c)){
                T_INDIV_TRAIN_INFO__c temp = oldFutureEmpInfoMap.get(csAdd.IDN_TRAIN_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c <csAdd.DTE_BEGIN_EFFV__c){
                    oldFutureEmpInfoMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
                }
            }else{
                oldFutureEmpInfoMap.put(csAdd.IDN_TRAIN_INDIV__c, csAdd);
            }
            
        }
        for(T_INDIV_TRAIN_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_TRAIN__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_TRAIN_INDIV__c from T_INDIV_TRAIN_INFO__c where IDN_TRAIN_INDIV__c IN:parentTrainingIds and id NOT IN:TempBrkIds and (DTE_END_EFFV__c >TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(newTempBrkMap.containsKey(csAdd.IDN_TRAIN_INDIV__c)){
                T_INDIV_TRAIN_INFO__c  newObj=newTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c);                
                
                if(oldMapTempBrk!= null && oldMapTempBrk.containsKey(newObj.Id)){
                    if(oldMapTempBrk.get(newObj.id).DTE_BEGIN_EFFV__c != newObj.DTE_BEGIN_EFFV__c || (oldMapTempBrk.get(newObj.id).DTE_END_EFFV__c != newObj.DTE_END_EFFV__c)){
                        if((newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c) && (newObj.DTE_END_EFFV__c <=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c || newObj.DTE_END_EFFV__c ==null))){
                               newTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c).addError('Begin date can not be less than currenlty effective Parent Training Temporary Break begin date.');
                           }
                    }  
                }else {
                    if((newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c ) && (newObj.DTE_END_EFFV__c <=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c || newObj.DTE_END_EFFV__c ==null))){
                           newTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c).addError('Begin date can not be less than currenlty effective Parent Training Temporary Break begin date.');
                       }
                }
            }
        }
        for(T_INDIV_TRAIN_INFO__c csAdd :oldFutureEmpInfoMap.values()){
            if(newTempBrkMap.containsKey(csAdd.IDN_TRAIN_INDIV__c)){
                T_INDIV_TRAIN_INFO__c  newObj=newTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c); 
                if(oldMapTempBrk== null){
                    if(newTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c).DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                        csAdd.DTE_END_EFFV__c =(newTempBrkMap.get(csAdd.IDN_TRAIN_INDIV__c).DTE_BEGIN_EFFV__c).addDays(-1);
                        oldTempBrktList.add(csAdd);
                    }
                }
            }
        }
        if(oldTempBrktList.size()>0){
            GenericDMLHandler.updateRecords(oldTempBrktList,new Map<String,Object>{'Method__c'=>'deleteCasePhoneEndDate','Class__c'=>'caseAddressServices'}); 
        }
        
    }
    
    public static void updateEmpInfoTmpBrkEndDate(List<T_INDIV_EMPLMT_INFO__c> newTempBrkList,map<Id, T_INDIV_EMPLMT_INFO__c> oldMapTempBrk){
        List<T_INDIV_EMPLMT_INFO__c> oldTempBrktList = new List<T_INDIV_EMPLMT_INFO__c>();
        Map<String,T_INDIV_EMPLMT_INFO__c> oldFutureEmpInfoMap = new Map<String,T_INDIV_EMPLMT_INFO__c>();
        Set<String>TempBrkIds = new Set<String>();
        Set<String>parentTrainingIds = new Set<String>();
        Map<String,T_INDIV_EMPLMT_INFO__c> newTempBrkMap = new Map<String,T_INDIV_EMPLMT_INFO__c>();       
        for(T_INDIV_EMPLMT_INFO__c csAddr : newTempBrkList){
            if(csAddr.DTE_BEGIN_EFFV__c > csAddr.DTE_END_EFFV__c){
                csAddr.addError('End date can not be less than begin date.');
            }
            newTempBrkMap.put(csAddr.IDN_EMPLMT_INDIV__c, csAddr);
            
            TempBrkIds.add(csAddr.id);
            parentTrainingIds.add(csAddr.IDN_EMPLMT_INDIV__c);
        }
        for(T_INDIV_EMPLMT_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EMPLMT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EMPLMT_INDIV__c from T_INDIV_EMPLMT_INFO__c where IDN_EMPLMT_INDIV__c IN:parentTrainingIds and id NOT IN:TempBrkIds and (DTE_END_EFFV__c >TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            
            if(oldFutureEmpInfoMap.containsKey(csAdd.IDN_EMPLMT_INDIV__c)){
                T_INDIV_EMPLMT_INFO__c temp = oldFutureEmpInfoMap.get(csAdd.IDN_EMPLMT_INDIV__c);
                if(temp.DTE_BEGIN_EFFV__c <csAdd.DTE_BEGIN_EFFV__c){
                    oldFutureEmpInfoMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
                }
            }else{
                oldFutureEmpInfoMap.put(csAdd.IDN_EMPLMT_INDIV__c, csAdd);
            }
            
        }
        for(T_INDIV_EMPLMT_INFO__c csAdd :[SELECT id,CDE_TYPE_INFO_EMPLMT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_EMPLMT_INDIV__c from T_INDIV_EMPLMT_INFO__c where IDN_EMPLMT_INDIV__c IN:parentTrainingIds and id NOT IN:TempBrkIds and (DTE_END_EFFV__c >TODAY or DTE_END_EFFV__c =null) WITH SECURITY_ENFORCED order by DTE_BEGIN_EFFV__c]){
            if(newTempBrkMap.containsKey(csAdd.IDN_EMPLMT_INDIV__c)){
                T_INDIV_EMPLMT_INFO__c  newObj=newTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c);                
                
                if(oldMapTempBrk!= null && oldMapTempBrk.containsKey(newObj.Id)){
                    if(oldMapTempBrk.get(newObj.id).DTE_BEGIN_EFFV__c != newObj.DTE_BEGIN_EFFV__c || (oldMapTempBrk.get(newObj.id).DTE_END_EFFV__c != newObj.DTE_END_EFFV__c)){
                        if((newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c) && (newObj.DTE_END_EFFV__c <=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                           (newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c || newObj.DTE_END_EFFV__c ==null))){
                               newTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c).addError('Begin date can not be less than currenlty effective Employment Temporary Break begin date.');
                           }
                    }  
                }else {
                    if((newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c ) && (newObj.DTE_END_EFFV__c <=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c && newObj.DTE_BEGIN_EFFV__c  <= csAdd.DTE_END_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_END_EFFV__c || newObj.DTE_END_EFFV__c ==null)) ||
                       (newObj.DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c && (newObj.DTE_END_EFFV__c >=csAdd.DTE_BEGIN_EFFV__c || newObj.DTE_END_EFFV__c ==null))){
                           newTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c).addError('Begin date can not be less than currenlty effective Employment Temporary Break begin date.');
                       }
                }
            }
        }
        for(T_INDIV_EMPLMT_INFO__c csAdd :oldFutureEmpInfoMap.values()){
            if(newTempBrkMap.containsKey(csAdd.IDN_EMPLMT_INDIV__c)){
                T_INDIV_EMPLMT_INFO__c  newObj=newTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c); 
                if(oldMapTempBrk== null){
                    if(newTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c).DTE_BEGIN_EFFV__c >csAdd.DTE_BEGIN_EFFV__c){
                        csAdd.DTE_END_EFFV__c =(newTempBrkMap.get(csAdd.IDN_EMPLMT_INDIV__c).DTE_BEGIN_EFFV__c).addDays(-1);
                        oldTempBrktList.add(csAdd);
                    }
                }
            }
        }
        if(oldTempBrktList.size()>0){
            GenericDMLHandler.updateRecords(oldTempBrktList,new Map<String,Object>{'Method__c'=>'deleteCasePhoneEndDate','Class__c'=>'caseAddressServices'}); 
        }
        
    }
    //Ends Changes for CCCAP-1884
    //Changes for CCCAP-995 ENDS
    
    /*************************************************************
	Method Name	    - resetBypassValidationFlag()
	Called From     - CaseTrigger
	Description     - updates 'Bypass_CaseName_ValidationRule__c' field to FALSE
	Author          - Rishav Maji
	Created Date    - 2-Feb-2021
	JIRA Ticket     - CCCAP-2720
	**************************************************************/
    public static void resetBypassValidationFlag(set<Id> recordIds){
        List<T_SBSD_CASE__c> caseToUpdate = new List<T_SBSD_CASE__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CaseLastUpdatedServices','Method__c'=>'resetBypassValidationFlag'};  
            try {
                for(T_SBSD_CASE__c caseRec : [SELECT Id, Bypass_CaseName_ValidationRule__c FROM T_SBSD_CASE__c WHERE Id in :recordIds AND Bypass_CaseName_ValidationRule__c = TRUE WITH SECURITY_ENFORCED LIMIT 10000]){
                    caseRec.Bypass_CaseName_ValidationRule__c = FALSE;
                    caseToUpdate.add(caseRec);
                }
                if(!caseToUpdate.isEmpty()){
                    System.debug('[CaseLastUpdatedServices.resetBypassValidationFlag]--caseToUpdate--> '+caseToUpdate);
                    CaseLastUpdatedServices.disableTrigger = true; // added for CCCAP-14909
                    GenericDMLHandler.updateRecords(caseToUpdate, methodInfo);
                    CaseLastUpdatedServices.disableTrigger = false; // added for CCCAP-14909
                }
            } catch(Exception e) {
                System.debug('[CaseLastUpdatedServices.resetBypassValidationFlag]--Exception--> '+e.getMessage());
                ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
            }
    }
    public static void updateRefInfo(Map<Id, SObject> caseOldMap) {
        set<Id> caseIds = new set<Id>();
        List<Referral_Information__c>  selectedReferralsToUpdated = new List<Referral_Information__c>();
          List<Referral_Information__c>  selectedReferrals =[SELECT id,Field_Name__c,New_Value__c,Object_API_Name__c,Field_API_Name__c,Old_Value__c,Referral_Id__c,Referral_Type__c,Section_Name__c,isEditable__c,SF_Record_Id__c from Referral_Information__c where SF_Record_Id__c IN:caseOldMap.keySet() WITH SECURITY_ENFORCED];
        for(Referral_Information__c ref:selectedReferrals) {
            SObject eachCase = caseOldMap.get(ref.SF_Record_Id__c);
                String fieldApiName =ref.Field_API_Name__c;
                if(fieldApiName =='NET_EARNED_INCOME__c'){
                    fieldApiName ='AMT_TANF_INCOME_HH_GROSS__c';
                }
                ref.Old_Value__c = String.valueOf(eachCase.get(fieldApiName));
                selectedReferralsToUpdated.add(ref);
        }
        system.debug('selectedReferralsToUpdated---'+selectedReferralsToUpdated);
        if(selectedReferralsToUpdated != null && selectedReferralsToUpdated.size()>0){
            APXPolicyRecordsServices.updateLstSObject(selectedReferralsToUpdated);
        }
    }
    // CCCAP-4430 CHANGES
     public static void updateTANFDetailFrequency(List<T_CBMS_ADDNL_INFO__c> newTANFDetailList){
        Map<Id,T_CBMS_ADDNL_INFO__c> tanfInfoMap  = new Map<Id,T_CBMS_ADDNL_INFO__c>();
        for(T_CBMS_ADDNL_INFO__c tanf:[SELECT Id,DTE_BEGIN_EFFEV__c,AMT_TANF_INCOME_HH_GROSS__c,IDN_CASE_CHATS__c,IDN_CASE_CHATS__r.IDN_CBMS_REF__c from T_CBMS_ADDNL_INFO__c where ID IN:newTANFDetailList WITH SECURITY_ENFORCED]){
            tanfInfoMap.put(tanf.id,tanf);
        }
        for(T_CBMS_ADDNL_INFO__c cb :newTANFDetailList){
           T_CBMS_ADDNL_INFO__c tanfObj  = tanfInfoMap.get(cb.id);
            if(String.isBlank(cb.CDE_FREQ_INCOME__c) && (String.isNotBlank(tanfObj.IDN_CASE_CHATS__r.IDN_CBMS_REF__c)) && (cb.AMT_TANF_INCOME_HH_GROSS__c !=null)){
                cb.CDE_FREQ_INCOME__c = 'MON';
            }
            
        }
    }
    // CCCAP-4430 CHANGES ENDS
}