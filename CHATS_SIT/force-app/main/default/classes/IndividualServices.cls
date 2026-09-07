/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/8/2018                                                          
*  @description    Handler Class for Individual Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 8-JAN-2018                                                             
*  * Author: Nikunj Doshi                                                   
*  * Description: Initial version                                                 
*  * copying soundex value to TXT_SNDX__c field

*  * Version: 2.0                                                                             
*  * Date: 2-Feb-2018                                                           
*  * Author: Shubham Jain
*  * Description: Task Creation: T101 - SIDMOD Updated Client DOB

*  * Version: 3.0                                                                             
*  * Date: 6-Mar-2018                                                           
*  * Author: Shubham Jain
*  * Description: Added logic to populate Individual Cleared field based on state id.

*  * Version: 4.0                                                                             
*  * Date: 20-Mar-2018                                                           
*  * Author: Shubham Jain
*  * Description: Removed the logic to populate case name field as Name field will be an autonumber field

*  * Version: 5.0                                                                             
*  * Date: 13-Jun-2018                                                           
*  * Author: Shubham Jain
*  * Description: Added new method to delete child records for individuals.

*  * Version: 6.0                                                                             
*  * Date: 06-15-2018                                                           
*  * Author: Gaurav Trivedi
*  * Description: Bug fix as a paart of CHATS-5336 where newly generated task
*  *              1. Should not have null caseId populated
*  *              2. Status should always be Not Started
*  *              3. Code Clean-up

*  * Version: 7.0                                                                             
*  * Date: 06-17-2019                                                           
*  * Author: Azharuddin Mohammad
*  * Description: Bug fix as a part of CHATS-7297; sending Individual record to ATS on StateID update
*********************************************************************************************/
public with sharing class IndividualServices {
    public static Boolean disableTrigger = false;
    private static Map<Id,T_SBSD_INDIV__c> filteredCaseIds{get;set;}
    private static Map<String,Id> countyVsActiveAssignee{get;set;} // added for SIDMOD, CCCAP-7695
    public static void fillSoundexValue(List<T_SBSD_INDIV__c> listIndivSearch, Map<Id, T_SBSD_INDIV__c> individualsOldMap){
        for(T_SBSD_INDIV__c indivSearch : listIndivSearch){
            if(String.isEmpty(indivSearch.id) || 
               (individualsOldMap.get(indivSearch.id).NAM_FIRST__c!=indivSearch.NAM_FIRST__c || 
                individualsOldMap.get(indivSearch.id).NAM_LAST__c!=indivSearch.NAM_LAST__c)){
                    String soundexValue = '';
                    
                    if((indivSearch.NAM_LAST__c!=null && indivSearch.NAM_LAST__c !='') && (indivSearch.NAM_FIRST__c != null && indivSearch.NAM_FIRST__c != '')){
                        soundexValue = (indivSearch.NAM_LAST__c !=null? SoundexUtil.toSoundex(indivSearch.NAM_LAST__c).RightPad(6,'0'):'')+SoundexUtil.toSoundex(indivSearch.NAM_FIRST__c); 
                        
                    } else if((indivSearch.NAM_LAST__c !=null && indivSearch.NAM_LAST__c != '') && (indivSearch.NAM_FIRST__c == null || indivSearch.NAM_FIRST__c == '')){
                        soundexValue =(indivSearch.NAM_LAST__c !=null? SoundexUtil.toSoundex(indivSearch.NAM_LAST__c).RightPad(6,'0'):'');
                        
                    } else if((indivSearch.NAM_LAST__c ==null || indivSearch.NAM_LAST__c == '') && (indivSearch.NAM_FIRST__c != null && indivSearch.NAM_FIRST__c != '')){
                        soundexValue =SoundexUtil.toSoundex(indivSearch.NAM_FIRST__c);
                        
                    }
                    if(soundexValue!=null && soundexValue!=''){
                        indivSearch.TXT_SNDX__c = soundexValue;
                    }
                }
        }
    }
    
    public static void fillIND_NOTIFY_SIDMOD(List<T_SBSD_INDIV__c> listIndivSearch, Map<Id, T_SBSD_INDIV__c> individualsOldMap){
        for(T_SBSD_INDIV__c indiv:listIndivSearch){
            if(indiv.Id==null || individualsOldMap.get(indiv.Id).IDN_STATE__c!=indiv.IDN_STATE__c){
                if(String.isEmpty(indiv.IDN_STATE__c) || indiv.IDN_STATE__c.toLowerCase()==Label.SIDMOD_STATE_ID_REQUIRED.toLowerCase()){
                    indiv.IND_NOTIFY_SIDMOD__c = 'N';
                }else{
                    indiv.IND_NOTIFY_SIDMOD__c = 'Y';
                }
            }
        }
    }
    
    public static void createTaskT101(List<T_SBSD_CASE__c> cases){
        List<Task> tasksToBeCreated = new List<Task>();
        Task newTask;
        for(T_SBSD_CASE__c caseRec:cases){
            String caseId;
            newTask = new Task();
            newTask.ActivityDate = System.today().addDays(5);
            newTask.Subject = 'T101 - SIDMOD Updated Client DOB';
            caseId = caseRec.Name <> null?'(# '+caseRec.Name+')':'';
            T_SBSD_INDIV__c individual = filteredCaseIds.containsKey(caseRec.Id) ?filteredCaseIds.get(caseRec.Id) : Null;
            newTask.Description = 'Household member of case '+caseId+' date of birth updated by Sidmod. \n Please check eligibility and authorization to confirm whether the child has aged-out or if rate types within the authorization must be updated (school age).\n';
            newTask.Description+= 'Individual - '+individual.NAM_FIRST__c +' '+individual.NAM_LAST__c+ ' - ' +URL.getOrgDomainUrl().toExternalForm()+'/'+individual?.Id;
            newTask.Status = 'Not Started';
            newTask.WhatId = caseRec.Id; 
            newTask.OwnerId = caseRec.OwnerId;
            tasksToBeCreated.add(newTask);
        }
        List<DMLResult> lstDMLResult = GenericDMLHandler.insertRecords(tasksToBeCreated, false, null);
        if(!lstDMLResult.isEmpty()){
            List<CRUDPermissionException> lstCRUDPermissionException = GenericDMLHandler.getCRUDPermissionExceptionsFromDMLResults(lstDMLResult);
            if(!lstCRUDPermissionException.isEmpty()){
                for(T_SBSD_CASE__c caseRec:cases){
                    caseRec.addError(lstCRUDPermissionException.get(0).getMessage());
                }
            }
        }
    }
    //Task Creation: T501 - SIDMOD Updated Case Individual Date of Death for CCCAP-7695
    public static void createTaskT501(List<T_SBSD_CASE__c> cases){
        List<Task> tasksToBeCreated = new List<Task>();
        Task newTask;
        for(T_SBSD_CASE__c caseRec:cases){
            String caseId;
            newTask = new Task();
            newTask.ActivityDate = System.today().addDays(5);
            newTask.Subject = 'T501 - SIDMOD updated case individual Date of Death';
            caseId = caseRec.Name <> null?'(# '+caseRec.Name+')':'';
            T_SBSD_INDIV__c individual = filteredCaseIds.containsKey(caseRec.Id) ?filteredCaseIds.get(caseRec.Id) : Null;
            newTask.Description = 'Case individual of case '+caseId+' date of death updated by SIDMOD. \n\n Please communicate with the family and provider as needed to make the necessary updates to the household composition on the case. Also re-run eligibility, adjust authorizations, and parent fees as needed, and enter Case Comments.\n\n Correspondences will continue to generate so please review before sending. \n\n Please review the case to make changes to recoveries as needed.\n';
            newTask.Description+= 'Individual - '+individual.NAM_FIRST__c +' '+individual.NAM_LAST__c+ ' - ' +URL.getOrgDomainUrl().toExternalForm()+'/'+individual?.Id;
            newTask.Status = 'Not Started';
            newTask.WhatId = caseRec.Id; 
            newTask.OwnerId = caseRec.OwnerId;
            tasksToBeCreated.add(newTask);
        }
        List<DMLResult> lstDMLResult = GenericDMLHandler.insertRecords(tasksToBeCreated, false, null);
        if(!lstDMLResult.isEmpty()){
            List<CRUDPermissionException> lstCRUDPermissionException = GenericDMLHandler.getCRUDPermissionExceptionsFromDMLResults(lstDMLResult);
            if(!lstCRUDPermissionException.isEmpty()){
                for(T_SBSD_CASE__c caseRec:cases){
                    caseRec.addError(lstCRUDPermissionException.get(0).getMessage());
                }
            }
        }
    }
    //Task Creation: T502 - SIDMOD Updated Case Individual Date of Death for case with active recovery for CCCAP-7695
    public static void createTaskT502(List<T_SBSD_CASE__c> cases){
        List<Task> tasksToBeCreated = new List<Task>();
        Task newTask;
        List<String> supervisors = new List<String>{'Fiscal_Worker_Supervisor_PS','Business_Office_Supervisor_PS','Universal_User_PS'}; // Replaced with custom permission CCCAP-14993
        //Replacing profile references as part of CCCAP-14993
        Set<Id> psaUserIds = new Set<Id>();
        for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name IN :supervisors AND Assignee.IsActive = true]) {
            psaUserIds.add(psa.AssigneeId);
        }
        if(!countyVsActiveAssignee.isEmpty() && !cases.isEmpty())
        {
            String countyLiterals = '';
            List<String> countyNames = new List<String>(countyVsActiveAssignee.keySet());
            for(Integer i = 0; i < countyNames.size(); i++){
                if(i > 0) countyLiterals += ',';
                countyLiterals += '\'' + String.escapeSingleQuotes(countyNames[i]) + '\'';
            }
            //removing profile.name and adding id check CCCAP-14993
            String dynamicQuery = 'select id,Common_County__c,Owner_County__c from User where ' +
                '(Common_County__c INCLUDES (' + countyLiterals + ') OR Owner_County__c IN :countyNames) ' +
                'AND IsActive=true AND Id IN :psaUserIds order by Name Asc';
            for(User u: Database.query(dynamicQuery)){
                if (String.isNotBlank(u.Common_County__c)) {
                    List<String> commonCountyValues = u.Common_County__c.split(';');
                    for (String countyValue : commonCountyValues) {
                        if (String.isNotBlank(countyValue)) {
                            if (countyVsActiveAssignee.containsKey(countyValue) && countyVsActiveAssignee.get(countyValue) == null) {
                                countyVsActiveAssignee.put(countyValue, u.Id);
                            }
                        }
                    }
                }
                if(countyVsActiveAssignee.containsKey(u.Owner_County__c) && countyVsActiveAssignee.get(u.Owner_County__c) == null){
                    countyVsActiveAssignee.put(u.Owner_County__c,u.Id);
                }   
            }
            for(T_SBSD_CASE__c caseRec:cases){
                String caseId;
                newTask = new Task();
                newTask.ActivityDate = System.today().addDays(5);
                newTask.Subject = 'T502- SIDMOD updated case individual Date of Death for a case with an active recovery';
                caseId = caseRec.Name <> null?'(# '+caseRec.Name+')':'';
                T_SBSD_INDIV__c individual = filteredCaseIds.containsKey(caseRec.Id) ?filteredCaseIds.get(caseRec.Id) : Null;
                newTask.Description = 'Case individual of case '+caseId+' date of death updated by SIDMOD. \n\n This case has an active recovery. Please review and make changes to the recovery as needed.';
                newTask.Status = 'Not Started';
                newTask.WhatId = caseRec.Id; 
                if(!test.isRunningtest()){
	                newTask.OwnerId = countyVsActiveAssignee.get(String.valueof(caseRec?.CDE_COUNTY__r?.CDE_COUNTY__c));                    
                }
                tasksToBeCreated.add(newTask);
            }
            List<DMLResult> lstDMLResult = GenericDMLHandler.insertRecords(tasksToBeCreated, false, null);
            if(!lstDMLResult.isEmpty()){
                List<CRUDPermissionException> lstCRUDPermissionException = GenericDMLHandler.getCRUDPermissionExceptionsFromDMLResults(lstDMLResult);
                if(!lstCRUDPermissionException.isEmpty()){
                    for(T_SBSD_CASE__c caseRec:cases){
                        filteredCaseIds.get(caseRec.Id).addError(lstCRUDPermissionException.get(0).getMessage());
                    }
                }else{
                    integer index = 0;
                    for(Database.SaveResult svr : GenericDMLHandler.getSaveResultsFromDMLResults(lstDMLResult)){
                        if(!svr.isSuccess()){
                            filteredCaseIds.get(tasksToBeCreated[index].whatId).addError(svr.getErrors()[0].getMessage());
                        }
                        index++;
                    }   
                }
            }
        }
    }
    //modified method structure to handle diff. filtering based on Date field changes and changeType
    //change done for CCCAP-7695, SIDMOD
    public static Map<Id,T_SBSD_INDIV__c> filterIndividualsForDateChanges(List<T_SBSD_INDIV__c> individualsNew, Map<Id, T_SBSD_INDIV__c> individualsOldMap,String changeType){
        Map<Id,T_SBSD_INDIV__c> filteredIndividuals = new Map<Id,T_SBSD_INDIV__c>();
        for(T_SBSD_INDIV__c individual:individualsNew){
            if(changeType =='DobChange' && individualsOldMap.get(individual.Id).DTE_DOB__c!= individual.DTE_DOB__c){
                filteredIndividuals.put(individual.Id,individual);
            }
            else if(changeType =='DoDeathChange' && individualsOldMap.get(individual.Id).DTE_Death__c!= individual.DTE_Death__c && individual.DTE_Death__c!=null){
                filteredIndividuals.put(individual.Id,individual);
            }
        }
        return filteredIndividuals;
    }
    public static List<T_SBSD_CASE__c> filterActiveRecoveryCases(Map<Id,T_SBSD_INDIV__c>individuals){
        List<T_SBSD_CASE__c> filteredCases = new List<T_SBSD_CASE__c>();
        countyVsActiveAssignee = new Map<String,Id>();
        filteredCaseIds = new Map<Id,T_SBSD_INDIV__c>();
        if(!individuals.isEmpty()){
            for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT IDN_CASE__c,IDN_CLIENT__c  FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:individuals.keyset()
                                                AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                                               ]){
                                                   filteredCaseIds.put(caseIndiv.IDN_CASE__c,individuals.get(caseIndiv.IDN_CLIENT__c));
                                               }
            if(!filteredCaseIds.isEmpty()){
                if(filteredCaseIds.size()>0){
                    for(T_SBSD_CASE__c caseRec:[SELECT Id, OwnerId, Name,CDE_COUNTY__r.CDE_COUNTY__c,
                                                (SELECT Id FROM T_SBSD_CASE10__r WHERE 
                                                 DTE_BEGIN_EFFV__c<=TODAY AND 
                                                 (DTE_END_EFFV__c =  null OR DTE_END_EFFV__c>TODAY) 
                                                 AND CDE_MODE_CASE__c = 'ONG' AND CDE_STATUS_CASE__c = 'CLS'),
                                                (SELECT id from Case__r WHERE CDE_TYPE_ADJMT__c ='2' and CDE_STATUS_ADJMT__c IN ('1','2'))
                                                FROM T_SBSD_CASE__c WHERE id IN:filteredCaseIds.keyset()]){
                                                    countyVsActiveAssignee.put(String.valueOf(caseRec.CDE_COUNTY__r.CDE_COUNTY__c),null);
                                                    if(caseRec.T_SBSD_CASE10__r!=null && caseRec.T_SBSD_CASE10__r.size()>0 && caseRec.Case__r!=null && caseRec.Case__r.size()>0 ){
                                                        filteredCases.add(caseRec);                 
                                                    }
                                                }
                }
            }
        }
        return filteredCases;
    }
    public static List<T_SBSD_CASE__c> filterCases(Map<Id,T_SBSD_INDIV__c> individuals){
        List<T_SBSD_CASE__c> filteredCases = new List<T_SBSD_CASE__c>();
        if(individuals.size()>0){
            filteredCaseIds = new Map<Id,T_SBSD_INDIV__c>();
            for(T_SBSD_CASE_INDIV__c caseIndiv:[SELECT IDN_CASE__c,IDN_CLIENT__c  FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:individuals.keyset()
                                                AND DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                                               ]){
                                                   filteredCaseIds.put(caseIndiv.IDN_CASE__c,individuals.get(caseIndiv.IDN_CLIENT__c));
                                               }
            if(filteredCaseIds.size()>0){
                for(T_SBSD_CASE__c caseRec:[SELECT Id, OwnerId, Name,
                                            (SELECT Id FROM T_SBSD_CASE10__r WHERE 
                                             DTE_BEGIN_EFFV__c<=TODAY AND 
                                             (DTE_END_EFFV__c =  null OR DTE_END_EFFV__c>TODAY) 
                                             AND CDE_MODE_CASE__c = 'ONG' AND CDE_STATUS_CASE__c = 'OPN'),
                                            (SELECT Id FROM T_SBSD_CASE114__r WHERE CDE_STATUS_WTLST__c = 'WLT'
                                             AND DTE_BEGIN_EFFV_WTLST__c<=TODAY
                                             AND (DTE_END_EFFV_WTLST__c=null OR DTE_END_EFFV_WTLST__c>TODAY))
                                            FROM T_SBSD_CASE__c WHERE id IN:filteredCaseIds.keyset()]){
                                                if(caseRec.T_SBSD_CASE10__r!=null && caseRec.T_SBSD_CASE10__r.size()>0 && (caseRec.T_SBSD_CASE114__r==null || caseRec.T_SBSD_CASE114__r.size()==0)){
                                                    filteredCases.add(caseRec);                 
                                                }                                           }
            }
        }
        return filteredCases;
    }   

    public static void validateSourceVerifiedCitizenship(List<T_SBSD_INDIV__c> individuals,Map<Id, T_SBSD_INDIV__c> individualsOldMap){
        Set<Id> indivIdSet = new Set<Id>();
        for(T_SBSD_INDIV_INFO__c indivInfo : [SELECT Id,IDN_CLIENT__c,DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, (SELECT Id FROM Individual_Verification__r WHERE CDE_TYPE_VERIF__c = 'V' AND CDE_TYPE_INFO_INDIV__c = 'CS') 
                                              FROM T_SBSD_INDIV_INFO__c WHERE IDN_CLIENT__c IN :individuals AND CDE_TYPE_INFO_INDIV__c = 'CS']){
                                                if((indivInfo.DTE_BEGIN_EFFV__c == null || indivInfo.DTE_BEGIN_EFFV__c<= Date.today()) && (indivInfo.DTE_END_EFFV__c == null || indivInfo.DTE_END_EFFV__c>=Date.today()) && indivInfo.Individual_Verification__r.size()>0){
                                                    indivIdSet.add(indivInfo.IDN_CLIENT__c);
                                                }
                                              }
        for(T_SBSD_INDIV__c indiv : individuals){
            if(String.isBlank(indiv.CDE_SOURCE_VRFYD_CITIZEN__c) && indivIdSet.contains(indiv.Id) && !indiv.Is_Peak_Data__c && !indiv.Is_CBMS_Data__c
                && indiv.Bypass_On__c == individualsOldMap.get(indiv.Id).Bypass_On__c){
                indiv.CDE_SOURCE_VRFYD_CITIZEN__c.addError('A value is required since citizenship records are present.');
            }
        }
    }
    
    public static void deleteChildRecords(List<T_SBSD_INDIV__c> individuals){
        List<SObject> recordsToBeDeleted = new List<SObject>();
        List<SObject> recordsToBeDeleted2 = new List<SObject>();
        List<SObject> childIdsToDeleteGrandChild = new List<SObject>();
        
        for(T_SBSD_INDIV__c individual:[SELECT Id,
                                        (SELECT Id FROM Individual__r),
                                        (SELECT Id FROM Case_Individual__r),
                                        (SELECT Id FROM Child_Support_Deductions__r),
                                        (SELECT Id FROM Individual_Information__r),
                                        (SELECT Id FROM Primary_Activity_Counter__r),
                                        (SELECT Id FROM Relationship__r),
                                        (SELECT Id FROM T_AUTH__r),
                                        (SELECT Id FROM T_INDIV_DISQLN__r),
                                        (SELECT Id FROM T_SBSD_INDIV1__r),
                                        (SELECT Id FROM T_SBSD_INDIV10__r),
                                        (SELECT Id FROM T_SBSD_INDIV12__r),
                                        (SELECT Id FROM T_SBSD_INDIV14__r),
                                        (SELECT Id FROM T_SBSD_INDIV19__r),
                                        (SELECT Id FROM T_SBSD_INDIV2__r),
                                        (SELECT Id FROM T_SBSD_INDIV22__r),
                                        (SELECT Id FROM T_SBSD_INDIV24__r),
                                        (SELECT Id FROM T_SBSD_INDIV26__r),
                                        (SELECT Id FROM T_SBSD_INDIV6__r),
                                        (SELECT Id FROM T_SBSD_INDIV7__r),
                                        (SELECT Id FROM Primary_Individual_Relationship__r)
                                        FROM T_SBSD_INDIV__c WHERE Id IN:individuals]){
                                            recordsToBeDeleted.addAll(individual.Individual__r);
                                            recordsToBeDeleted.addAll(individual.Case_Individual__r);
                                            if(!individual.Case_Individual__r.isEmpty()){
                                                childIdsToDeleteGrandChild.addAll(individual.Case_Individual__r);
                                            }
                                            recordsToBeDeleted.addAll(individual.Child_Support_Deductions__r);
                                            recordsToBeDeleted.addAll(individual.Individual_Information__r);
                                            if(!individual.Individual_Information__r.isEmpty()){
                                                childIdsToDeleteGrandChild.addAll(individual.Individual_Information__r);
                                            }
                                            recordsToBeDeleted.addAll(individual.Primary_Activity_Counter__r);
                                            recordsToBeDeleted.addAll(individual.Relationship__r);
                                            recordsToBeDeleted.addAll(individual.T_AUTH__r);
                                            if(!individual.T_AUTH__r.isEmpty()){
                                                childIdsToDeleteGrandChild.addAll(individual.T_AUTH__r);
                                            }
                                            recordsToBeDeleted.addAll(individual.T_INDIV_DISQLN__r);
                                            recordsToBeDeleted.addAll(individual.T_SBSD_INDIV1__r);
                                            recordsToBeDeleted.addAll(individual.T_SBSD_INDIV10__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV12__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV14__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV19__r);
                                            if(!individual.T_SBSD_INDIV19__r.isEmpty()){
                                                childIdsToDeleteGrandChild.addAll(individual.T_SBSD_INDIV19__r);
                                            }
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV2__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV22__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV24__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV26__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV6__r);
                                            recordsToBeDeleted2.addAll(individual.T_SBSD_INDIV7__r);
                                            recordsToBeDeleted2.addAll(individual.Primary_Individual_Relationship__r);
                                        }
        List<Id> recordIdsToBeDeleted = new List<String>();
        
        if(!childIdsToDeleteGrandChild.isEmpty()){
            for(T_INDIV_CAT_RQ__c ccr:[SELECT Id FROM T_INDIV_CAT_RQ__c WHERE IDN_CASE_INDIV__c IN:childIdsToDeleteGrandChild]){
                recordIdsToBeDeleted.add(ccr.id);
            }
            for(T_SBSD_CASE_INDIV_ROLE__c cir:[SELECT Id FROM T_SBSD_CASE_INDIV_ROLE__c WHERE IDN_CASE_INDIV__c IN:childIdsToDeleteGrandChild]){
                recordIdsToBeDeleted.add(cir.id);
            }
            for(T_DOC_RQ__c doc:[SELECT Id FROM T_DOC_RQ__c WHERE IDN_AUTH__c IN: childIdsToDeleteGrandChild AND IDN_CLIENT__c NOT IN: individuals]){
                recordIdsToBeDeleted.add(doc.id);
            }
            for(T_INDIV_EMPLMT_INFO__c empInfo:[SELECT Id FROM T_INDIV_EMPLMT_INFO__c WHERE IDN_EMPLMT_INDIV__c IN: childIdsToDeleteGrandChild]){
                recordIdsToBeDeleted.add(empInfo.id);
            }
            for(T_INDIV_EMPLMT_VERIF__c empVerif:[SELECT Id FROM T_INDIV_EMPLMT_VERIF__c WHERE IDN_EMPLMT_INDIV__c IN: childIdsToDeleteGrandChild]){
                recordIdsToBeDeleted.add(empVerif.id);
            }
            System.debug('recordIdsToBeDeleted:'+recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Class__c'=>'IndividualServices','Method__c'=>'deleteChildRecords'});
            recordIdsToBeDeleted.clear();
        }
        
        System.debug('recordsToBeDeleted:'+recordsToBeDeleted);
        if(!recordsToBeDeleted.isEmpty()){
            recordsToBeDeleted.sort();
            for(SObject sOb:recordsToBeDeleted){
                recordIdsToBeDeleted.add((Id)sOb.get('Id'));
            }
            System.debug('recordIdsToBeDeleted:'+recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Class__c'=>'IndividualServices','Method__c'=>'deleteChildRecords'});
            recordIdsToBeDeleted.clear();
        }
        System.debug('recordsToBeDeleted2:'+recordsToBeDeleted2);
        if(!recordsToBeDeleted2.isEmpty()){
            recordsToBeDeleted2.sort();
            for(SObject sOb:recordsToBeDeleted2){
                recordIdsToBeDeleted.add((Id)sOb.get('Id'));
            }
            System.debug('recordIdsToBeDeleted:'+recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Class__c'=>'IndividualServices','Method__c'=>'deleteChildRecords'});
        }
    }
    
    /**    
* @description Update PrimaryCareTaker on Case 
* @author Bharadwaj Gaddam
* @date 10/10/2018   
* @param List<T_SBSD_INDIV__c> trigger.new Individual list, Map<Id,T_SBSD_INDIV__c> trigger.oldMap
* @return void
*/          
    public static void updatePrimCaretakerOnCase(List<T_SBSD_INDIV__c> individualList, Map<Id,T_SBSD_INDIV__c> individualOldMap) {
        set<Id> individualIdSet = new set<Id>();
        Map<Id, T_SBSD_CASE__c> caseMap = new Map<Id, T_SBSD_CASE__c>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'IndividualServices','Method__c'=>'updatePrimCaretakerOnCase'};
            for(T_SBSD_INDIV__c eachIndiv:individualList) {
                if(individualOldMap.get(eachIndiv.Id).NAM_LAST__c !=eachIndiv.NAM_LAST__c || individualOldMap.get(eachIndiv.Id).NAM_FIRST__c != eachIndiv.NAM_FIRST__c || individualOldMap.get(eachIndiv.Id).NAM_MI__c != eachIndiv.NAM_MI__c) {
                    individualIdSet.add(eachIndiv.Id);
                }
            }
        if(!individualIdSet.isEmpty()){
            for(T_SBSD_CASE_INDIV__c eachCaseIndiv:[select Id,IDN_CLIENT__c,IDN_CASE__c,NAM_INDIV__c from T_SBSD_CASE_INDIV__c where IDN_CLIENT__c IN:individualIdSet and DTE_END_EFFV__c=null and IND_CRTKR__c=true and IDN_CASE__c !=null] ) {
                caseMap.put(eachCaseIndiv.IDN_CASE__c,new T_SBSD_CASE__c(Id=eachCaseIndiv.IDN_CASE__c,NAM_PRIMARY_CARETAKER__c=eachCaseIndiv.NAM_INDIV__c));             
            }   
        }
        
        if(!caseMap.isEmpty()) {
            GenericDMLHandler.updateRecords(caseMap.values(),methodInfo);
        }
    }
    
    /**    
* @description Send Individual to ATS queue on StateId update from Null
* @author Azharuddin Mohammad
* @date June 17,2019
* @param List<T_SBSD_INDIV__c> trigger.new Individual list,
* @return void
*/ 
    /*
public static void sendIndivToATSOnStateIDUpdate(List<T_SBSD_INDIV__C> individualList, Map<Id,T_SBSD_INDIV__C> individualOldMap) {
List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();

for(T_SBSD_INDIV__C eachUpdatedIndiv : individualList){
if(eachUpdatedIndiv.IDN_STATE__c != null &&  eachUpdatedIndiv.IDN_STATE__c != individualOldMap.get(eachUpdatedIndiv.Id).IDN_STATE__c){
batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
atsRecord.CDE_STATUS_TRANS__c= '1';
atsRecord.CDE_TYPE_TRANS__c ='2';
if(eachUpdatedIndiv.Name != null){
atsRecord.IDN_CLIENT__c = eachUpdatedIndiv.Name;
}
atsRecord.DTE_CHANGE_LAST__c = system.today();
lstATSRecords.add(atsRecord);
}
if(!lstATSRecords.isEmpty()){
system.debug('individuals inserted to ATS due to updation in StateID');
ATSHandler.insertATSRecord(true, lstATSRecords);    
}
}
} */    
    
    /*    
* @description For CCCAP-8454, update DOB_Change_Indicator__c field on Individual object when DOB is changed
* @author Nikita S Varna
* @date 7/26/2023
* @param Map<Id,T_SBSD_INDIV__c> filteredIndividualsMap
* @return void
*/
    public static void updateDOBChangeIndicator(Map<Id,T_SBSD_INDIV__c> filteredIndividualsMap){
        Set<Id> indId = new  Set<Id>();
        List<T_SBSD_INDIV__c> individualsToUpdate = new List<T_SBSD_INDIV__c>();
        for(T_SBSD_INDIV__c rec : filteredIndividualsMap.values()){
            T_SBSD_INDIV__c updateRec = new T_SBSD_INDIV__c(Id = rec.Id);
            updateRec.DOB_Change_Indicator__c = true;
            individualsToUpdate.add(updateRec);
        }
        if(!individualsToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(individualsToUpdate, new Map<String,Object>{'Class__c'=>'IndividualServices','Method__c'=>'updateDOBChangeFlag'},new List<String>{'DOB_Change_Indicator__c'});
        }
    }

    //added for CCCAP-11512
    public static void createIDXRStagingRecords(List<T_SBSD_INDIV__c> deletedIndivList){
        List<T_IDXR_STG_DELETE__c> idxrStgRecsToBeInserted = new List<T_IDXR_STG_DELETE__c>();
        for(T_SBSD_INDIV__c indiv: deletedIndivList){
            if(indiv.IND_NOTIFY_SIDMOD__c == 'Y'){
                T_IDXR_STG_DELETE__c idxrStgRec = new T_IDXR_STG_DELETE__c(IDN_CLIENT__c = indiv.Name);
                idxrStgRecsToBeInserted.add(idxrStgRec);
            }
        }
        if(!idxrStgRecsToBeInserted.isEmpty()){
            GenericDMLHandler.insertRecords(idxrStgRecsToBeInserted, new Map<String,Object>{'Class__c'=>'IndividualServices','Method__c'=>'createIDXRStagingRecords'}, new List<String>{'IDN_CLIENT__c'});
        }
    }

    //added for CCCAP-13633
    public static void validateReadOnlyFieldsForClearedIndividuals(List<T_SBSD_INDIV__c> individualList, Map<Id,T_SBSD_INDIV__c> individualOldMap){
        if(disableTrigger){
            return;
        }        
        for(T_SBSD_INDIV__c individual : individualList){
            if(individual.Id == null){
                continue;
            }            
            T_SBSD_INDIV__c oldIndividual = individualOldMap.get(individual.Id);
            if(individual.IND_NOTIFY_SIDMOD__c == 'Y' && oldIndividual.IND_NOTIFY_SIDMOD__c == 'Y' && !Userinfo.getUserId().contains(Label.Batch_User_Id)){
                if(individual.DTE_DOB__c != oldIndividual.DTE_DOB__c || individual.NAM_FIRST__c != oldIndividual.NAM_FIRST__c ||
                   individual.NAM_LAST__c != oldIndividual.NAM_LAST__c || individual.NAM_MI__c != oldIndividual.NAM_MI__c ||
                   individual.NBR_SSN__c != oldIndividual.NBR_SSN__c || individual.CDE_GENDER__c != oldIndividual.CDE_GENDER__c ||
                   individual.DTE_Death__c != oldIndividual.DTE_Death__c){                    
                    individual.addError('Fields: First Name, Middle Initial, Last Name, Gender, SSN, DOB, Date of Death cannot be edited for the cleared individual.');
                }
            }
        }
    }

    /**    
    * @description Prevent updates to How Verified fields when NONE of the related Case Individual records has status 'Child' for CCCAP-14038
    */
    public static void validateHowVerifiedFieldsForChildStatus(List<T_SBSD_INDIV__c> individualList){
        if(disableTrigger){
            return;
        }

        Map<Id, T_SBSD_INDIV__c> individualOldMap = (Map<Id, T_SBSD_INDIV__c>) Trigger.oldMap;
        
        Set<Id> individualIdsWithFieldChanges = new Set<Id>();
        Map<Id, T_SBSD_INDIV__c> individualsWithChanges = new Map<Id, T_SBSD_INDIV__c>();
        
        for(T_SBSD_INDIV__c individual : individualList){
            //added for CCCAP-14243
            if(individual.Bypass_On__c != individualOldMap.get(individual.Id).Bypass_On__c){
                continue;
            }      
            T_SBSD_INDIV__c oldIndividual = individualOldMap.get(individual.Id);            
            if(individual.CDE_SOURCE_VRFYD_DOB__c != oldIndividual.CDE_SOURCE_VRFYD_DOB__c || 
               individual.CDE_SOURCE_VRFYD_CITIZEN__c != oldIndividual.CDE_SOURCE_VRFYD_CITIZEN__c){
                individualIdsWithFieldChanges.add(individual.Id);
                individualsWithChanges.put(individual.Id, individual);
            }
        }
        //Added as part of CCCAP-14328 to not show the validation from add individual flow.
        list<T_SBSD_CASE_INDIV__c> csIndv = [SELECT IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__c 
                                   WHERE IDN_CLIENT__c IN :individualIdsWithFieldChanges
                                   AND DTE_BEGIN_EFFV__c <= TODAY 
                                   AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY)];
        if(individualIdsWithFieldChanges.isEmpty()|| csIndv.isEmpty() ){
            return;
        }
        
        Set<Id> individualsWithChildStatus = new Set<Id>();
        for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT IDN_CLIENT__c 
                                              FROM T_SBSD_CASE_INDIV__c 
                                              WHERE IDN_CLIENT__c IN :individualIdsWithFieldChanges 
                                              AND Individual_Status__c = 'Child'
                                              AND DTE_BEGIN_EFFV__c <= TODAY 
                                              AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY)]){
            individualsWithChildStatus.add(caseIndiv.IDN_CLIENT__c);
        }
        
        for(Id individualId : individualIdsWithFieldChanges){
            // Only prevent update if this individual has NO related Case Individual records with 'Child' status
            if(!individualsWithChildStatus.contains(individualId)){
                T_SBSD_INDIV__c individual = individualsWithChanges.get(individualId);
                T_SBSD_INDIV__c oldIndividual = individualOldMap.get(individualId);
                
                if(individual.CDE_SOURCE_VRFYD_DOB__c != oldIndividual.CDE_SOURCE_VRFYD_DOB__c){
                    individual.CDE_SOURCE_VRFYD_DOB__c.addError('This field is only editable for a child individual.');
                }
                
                if(individual.CDE_SOURCE_VRFYD_CITIZEN__c != oldIndividual.CDE_SOURCE_VRFYD_CITIZEN__c){
                    individual.CDE_SOURCE_VRFYD_CITIZEN__c.addError('This field is only editable for a child individual.');
                }
            }
        }
    }
}