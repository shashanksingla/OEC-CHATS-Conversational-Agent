//Removed DML statements from FOR loop on 5/12/18 BG                                                                   
public with sharing class primaryActivityCounterServices {
    public static void createT105task(List<T_PRIM_ACTV_CNTR__c> newPrmryCntrList) {
        Map<Id, T_PRIM_ACTV_CNTR__c> prmryActvtyCntrMap = new Map<Id, T_PRIM_ACTV_CNTR__c>();
        set<Id> caseIdsFromCaseStatus = new set<Id>();
        set<Id> prmryCntrActvty = new set<Id>();
        Map<Id, T_COUNTY_PLAN__c> cntyPlanWeekDtlsMap = new Map<Id,T_COUNTY_PLAN__c>();
        List<Task> taskList = new List<Task>();
        Map<Id, T_SBSD_CASE_INDIV__c> caseToCaseIndivMap = new Map<Id, T_SBSD_CASE_INDIV__c>();    
        
        for(T_PRIM_ACTV_CNTR__c eachPrmryCntr : newPrmryCntrList) {
            if(eachPrmryCntr.IDN_PRIM_ACTV__c != Null) {
                prmryCntrActvty.add(eachPrmryCntr.IDN_PRIM_ACTV__c);
            }
        }
        system.debug('prmrycntractvty 13 '+ prmryCntrActvty);
        for(T_PRIM_ACTV_CNTR__c eachPrmryCntr : [select Id, IDN_PRIM_ACTV__c, IDN_PRIM_ACTV__r.IDN_CASE__c, IDN_PRIM_ACTV__r.DTE_END_ACTV_PRIM__c, IDN_PRIM_ACTV__r.Name, CDE_TYPE__c, CNT_WEEKS__c, IDN_CLIENT__c FROM T_PRIM_ACTV_CNTR__c 
                                                 WHERE IDN_PRIM_ACTV__c IN:prmryCntrActvty
                                                 //AND IDN_PRIM_ACTV__r.IDN_CASE__c IN (select IDN_CASE__c  FROM T_SBSD_CASE_STATUS_MODE__c WHERE CDE_MODE_CASE__c = 'ONG' AND CDE_STATUS_CASE__c = 'OPN')
                                                 ]) {
            prmryActvtyCntrMap.put(eachPrmryCntr.IDN_PRIM_ACTV__r.IDN_CASE__c, eachPrmryCntr);
        }
        system.debug('prmryactvtycntrmap 21 '+prmryActvtyCntrMap);

        //added by Nikita for CCCAP-12153
        for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Id, IDN_CASE__c, IDN_CLIENT__c, DTE_END_EFFV__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c IN: prmryActvtyCntrMap.keySet()]){
            if(prmryActvtyCntrMap.get(caseIndiv.IDN_CASE__c).IDN_CLIENT__c == caseIndiv.IDN_CLIENT__c){
              caseToCaseIndivMap.put(caseIndiv.IDN_CASE__c, caseIndiv);
            }
        }
        system.debug('casetocaseidivmap 28 '+caseToCaseIndivMap);
        
        for(T_SBSD_CASE_STATUS_MODE__c eachCaseStatusMode : [select Id, IDN_CASE__c, CDE_STATUS_CASE__c, CDE_MODE_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:prmryActvtyCntrMap.keySet() AND CDE_MODE_CASE__c = 'ONG' AND CDE_STATUS_CASE__c = 'OPN' AND (DTE_END_EFFV__c >=: system.today() OR DTE_END_EFFV__c = Null)]) {
            caseIdsFromCaseStatus.add(eachCaseStatusMode.IDN_CASE__c);
        }
        system.debug('caseidsfromcasestatus 34 '+caseIdsFromCaseStatus);
        
        //List of all active County Plans
        for(T_COUNTY_PLAN__c eachCountyPlan : [select Id, CDE_COUNTY__c, ELIGIBILITY_Q2_1__c, ELIGIBILITY_Q3_1__c, ELIGIBILITY_Q4__c FROM T_COUNTY_PLAN__c WHERE CDE_COUNTY__c IN (select Id FROM T_COUNTY__c) AND CDE_STATUS__c = 'APV' AND DTE_BEGIN_EFFEV__c <=: system.today() AND (DTE_END_EFFEV__c >=: system.today() OR DTE_END_EFFEV__c = Null) ]) {
            cntyPlanWeekDtlsMap.put(eachCountyPlan.CDE_COUNTY__c , eachCountyPlan);
        }
        system.debug('cntyplanweekdtlsmap 40 '+cntyPlanWeekDtlsMap);
        
        //Loop cases
        for(T_SBSD_CASE__c eachCase : [select Id, Name, CDE_COUNTY__c, OwnerId FROM T_SBSD_CASE__c WHERE Id IN:prmryActvtyCntrMap.keySet() ]) {
            if(caseIdsFromCaseStatus.contains(eachCase.Id)) {
                if((prmryActvtyCntrMap.containsKey(eachCase.Id)) && (cntyPlanWeekDtlsMap.ContainsKey(eachCase.CDE_COUNTY__c)) && (caseToCaseIndivMap.ContainsKey(eachCase.Id)) && (caseToCaseIndivMap.get(eachCase.Id).DTE_END_EFFV__c == null)){
                    if( ((prmryActvtyCntrMap.get(eachCase.Id).CDE_TYPE__c == 'GED/ESL/ABE') &&  ( prmryActvtyCntrMap.get(eachCase.Id).CNT_WEEKS__c == cntyPlanWeekDtlsMap.get(eachCase.CDE_COUNTY__c).ELIGIBILITY_Q3_1__c - 2 )) || ((prmryActvtyCntrMap.get(eachCase.Id).CDE_TYPE__c == 'Job Search') &&  ( prmryActvtyCntrMap.get(eachCase.Id).CNT_WEEKS__c == cntyPlanWeekDtlsMap.get(eachCase.CDE_COUNTY__c).ELIGIBILITY_Q4__c - 2 )) || ((prmryActvtyCntrMap.get(eachCase.Id).CDE_TYPE__c == 'Post-Secondary Education / Job Skills') && (prmryActvtyCntrMap.get(eachCase.Id).CNT_WEEKS__c == cntyPlanWeekDtlsMap.get(eachCase.CDE_COUNTY__c).ELIGIBILITY_Q2_1__c - 2 ))) {
                    
                        Task taskRecrd1 = new Task( OwnerId = eachCase.OwnerId, Subject = 'T105 - Time Limited Activity End Date Approaching', Priority = 'Normal', WhatId = eachCase.Id, ActivityDate = prmryActvtyCntrMap.get(eachCase.Id).IDN_PRIM_ACTV__r.DTE_END_ACTV_PRIM__c , Description = 'Case ' + eachCase.Name + ' has 2 weeks left for ( '+prmryActvtyCntrMap.get(eachCase.Id).IDN_PRIM_ACTV__r.Name+ ' , ' +prmryActvtyCntrMap.get(eachCase.Id).CDE_TYPE__c+ ' ). Please update the primary activity.');
                        taskList.add(taskRecrd1);
                    }
                }
            
            
            // SUD task generation at 50 weeks as part of CCCAP-13790
            if(prmryActvtyCntrMap.containsKey(eachCase.Id) && 
               prmryActvtyCntrMap.get(eachCase.Id).CDE_TYPE__c == 'Substance Use Disorder' && 
               prmryActvtyCntrMap.get(eachCase.Id).CNT_WEEKS__c == 50 && 
               caseToCaseIndivMap.get(eachCase.Id).DTE_END_EFFV__c == null){
                
                Task taskRecrd2 = new Task( 
                    OwnerId = eachCase.OwnerId, 
                    Subject = 'T105 - Time Limited Activity End Date Approaching', 
                    Priority = 'Normal', 
                    WhatId = eachCase.Id, 
                    ActivityDate = prmryActvtyCntrMap.get(eachCase.Id).IDN_PRIM_ACTV__r.DTE_END_ACTV_PRIM__c, 
                    Description = 'Case ' + eachCase.Name + ' has 2 weeks left for ( '+prmryActvtyCntrMap.get(eachCase.Id).IDN_PRIM_ACTV__r.Name+ ' , ' +prmryActvtyCntrMap.get(eachCase.Id).CDE_TYPE__c+ ' ). Please update the primary activity.'
                );
                taskList.add(taskRecrd2); 
               }}
        }
        //Start of code quality change BG 5/12/18
        if(!taskList.isEmpty()) {
            try{
            GenericDMLHandler.insertRecords(taskList,null);
            } catch(Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'primaryActivityCounterServices','Method__c'=>'createT105task'});
            }
        }
        //End of code quality change BG 5/12/18
    }
}