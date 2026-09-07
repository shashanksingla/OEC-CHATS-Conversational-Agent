public class ApplicationProcessQueueService {
    
    public final static String EMPTY_LOOKUP = null;

        /* added for UFE by Shashank 08/13/24
    check if Application is getting rejected of UFE Request Status =true Application, Publish the platform Event to Inform BridgeCare
    */
    public static void captureAppUpdates_UFE(List<T_APPLN_PRCS_QUEUE__c> applicationProcessQueues, Map<Id,T_APPLN_PRCS_QUEUE__c> oldMapApplicationProcessQueues){
        Set<Id> appIdsToCheck = new Set<Id>();
        List<UFEChangeInterface__e> ufeInfoUpdateEventList= new List<UFEChangeInterface__e>();
        for(T_APPLN_PRCS_QUEUE__c appQ : applicationProcessQueues){
            if((appQ.CDE_STATUS_APPLN__c!=oldMapApplicationProcessQueues.get(appQ.Id).CDE_STATUS_APPLN__c && appQ.CDE_STATUS_APPLN__c == 'REJ')
               || appQ.CDE_REJECT_APPLN__c!=oldMapApplicationProcessQueues.get(appQ.Id).CDE_REJECT_APPLN__c
               || appQ.CDE_REJECT_REFER__c!=oldMapApplicationProcessQueues.get(appQ.Id).CDE_REJECT_REFER__c)
            {
                appIdsToCheck.add(appQ.IDN_Appln__c);
            }
        }
        if(!appIdsToCheck.isEmpty()){
            for(T_APPLN_CASE__c appCase : [select id from T_APPLN_CASE__c where Id IN :appIdsToCheck and UFE_Request_Flag__c=true]){
                ufeInfoUpdateEventList.add(new UFEChangeInterface__e(IdNumber__c=appCase.Id,Type__c='application'));
            }
            Eventbus.publish(ufeInfoUpdateEventList);
        }
    }
    
    public static void populateCountyNameBasedOnCounty(List<T_APPLN_PRCS_QUEUE__c> applicationProcessQueues, Map<Id,T_APPLN_PRCS_QUEUE__c> oldMapApplicationProcessQueues){
        List<Decimal> countyCodes = new List<Decimal>();
        for(T_APPLN_PRCS_QUEUE__c applicationProcessQueue:applicationProcessQueues){
            if(String.isNotEmpty(applicationProcessQueue.CDE_COUNTY__c)){
                try{
                    countyCodes.add(Decimal.valueOf(applicationProcessQueue.CDE_COUNTY__c)); 
                }catch(Exception ex){
                    applicationProcessQueue.addError('County Code should be a number');
                    Map<String,Object> exceptionMap = new Map<String,Object>();
                    exceptionMap.put('Class__c','ApplicationProcessQueueService');    
                    exceptionMap.put('Method__c','populateCountyNameBasedOnCounty');            
                    ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
                }
            }
        }
        List<T_APPLN_PRCS_QUEUE__c> lstAppPrcsQueToBeUpdated = new List <T_APPLN_PRCS_QUEUE__c>();
        List<Id> countyIds = new List<Id>();
        for(T_APPLN_PRCS_QUEUE__c applicationProcessQueue:applicationProcessQueues){
            if(applicationProcessQueue.Id!= null && applicationProcessQueue.County_Name__c != oldMapApplicationProcessQueues.get(applicationProcessQueue.Id).County_Name__c){
                lstAppPrcsQueToBeUpdated.add(applicationProcessQueue);
                if(applicationProcessQueue.County_Name__c!= null){
                    countyIds.add(applicationProcessQueue.County_Name__c); 
                }
            }
        }
        Map<Decimal, String> countyCodeToCountyId = new Map<Decimal, String>();
        Map<String, Decimal> countyIdToCountyCode = new Map<String, Decimal>();
        for(T_COUNTY__c county:[SELECT id, CDE_COUNTY__c FROM T_COUNTY__c WHERE CDE_COUNTY__c IN :countyCodes OR Id IN:countyIds]){
            countyCodeToCountyId.put(county.CDE_COUNTY__c, county.Id);
            countyIdToCountyCode.put(county.Id,county.CDE_COUNTY__c );
        }
        for(T_APPLN_PRCS_QUEUE__c applicationProcessQueue:applicationProcessQueues){
            try{
                if(!String.isEmpty(applicationProcessQueue.CDE_COUNTY__c)){
                    if(applicationProcessQueue.Id==null 
                       || oldMapApplicationProcessQueues.get(applicationProcessQueue.id).CDE_COUNTY__c!=applicationProcessQueue.CDE_COUNTY__c){
                           Decimal countyCode = Decimal.valueOf(applicationProcessQueue.CDE_COUNTY__c);    
                           if(countyCodeToCountyId.containskey(countyCode)){
                               applicationProcessQueue.County_Name__c = countyCodeToCountyId.get(countyCode);
                           }else{
                               applicationProcessQueue.County_Name__c=EMPTY_LOOKUP;
                           }
                       }                
                }
            }catch(Exception ex){
                applicationProcessQueue.addError('County Code should be a number');
                Map<String,Object> exceptionMap = new Map<String,Object>();
                exceptionMap.put('Class__c','ApplicationProcessQueueService');    
                exceptionMap.put('Method__c','populateCountyNameBasedOnCounty');            
                ExceptionLoggingServices.captureExceptionLog(ex, exceptionMap);
            }         
        }
        
        for(T_APPLN_PRCS_QUEUE__c applicationProcessQueue:lstAppPrcsQueToBeUpdated){
            if(String.isEmpty(applicationProcessQueue.County_Name__c)){
                applicationProcessQueue.CDE_COUNTY__c=EMPTY_LOOKUP;
            }else{
                if(countyIdToCountyCode.containskey(applicationProcessQueue.County_Name__c)){
                    //added to make sure county code consistency remains in system for CCCAP-14154/CCCAP-13978
                    String countyCode = String.valueOf(countyIdToCountyCode.get(applicationProcessQueue.County_Name__c));
                    if(countyCode.length() == 1){
                        countyCode = '0'+countyCode;
                    }
                    applicationProcessQueue.CDE_COUNTY__c =countyCode;
                }
            } 
        } 
    } 
  	
    public static void populateApplicationProcessedDate(List<T_APPLN_PRCS_QUEUE__c> lstNewApplicationProcessQueues){
        for(T_APPLN_PRCS_QUEUE__c applicationProcessQueue : lstNewApplicationProcessQueues){
            if(applicationProcessQueue.CDE_STATUS_APPLN__c != null && (applicationProcessQueue.CDE_STATUS_APPLN__c =='PRC' || applicationProcessQueue.CDE_STATUS_APPLN__c == 'REJ')){
                applicationProcessQueue.DTE_PRCSD_APPLN__c = system.today(); //added for CCCAP-4748 
            }
            if(applicationProcessQueue.CDE_STATUS_APPLN__c=='REJ' && applicationProcessQueue.CDE_SOURCE__c == 'CB'){
                applicationProcessQueue.Reverse_Refer_Track__c = true; // added for CCCAP-10162 for CHATS Reverse mapping
            }
        }
    }
    
    public static void populateApplicationProcessedDateOnSearch(List<T_APPLN_PRCS_QUEUE__c> lstNewApplicationProcessQueues, Map<Id,T_APPLN_PRCS_QUEUE__c> oldMapApplicationProcessQueues){
        List<T_APPLN_PRCS_SEARCH__c> lstApplicationPrcsSearchToUpdate = new List<T_APPLN_PRCS_SEARCH__c>();
        List<Id> appCaseIds = new List<Id>();
        for(T_APPLN_PRCS_QUEUE__c applicationProcessQueue : lstNewApplicationProcessQueues){
            if(applicationProcessQueue.CDE_STATUS_APPLN__c!= null && applicationProcessQueue.CDE_STATUS_APPLN__c != oldMapApplicationProcessQueues.get(applicationProcessQueue.Id).CDE_STATUS_APPLN__c
               && (applicationProcessQueue.CDE_STATUS_APPLN__c =='PRC'||applicationProcessQueue.CDE_STATUS_APPLN__c=='REJ')){
                   appCaseIds.add(applicationProcessQueue.IDN_APPLN__c); 
                   applicationProcessQueue.DTE_PRCSD_APPLN__c = system.today(); //added for CCCAP-4748
                   // added for CCCAP-10162 for CHATS Reverse mapping
                   if(applicationProcessQueue.CDE_STATUS_APPLN__c=='REJ' && applicationProcessQueue.CDE_SOURCE__c == 'CB'){
                    applicationProcessQueue.Reverse_Refer_Track__c = true;
                } 
               }
        }
        // ADDED Empty list checks to save Query Count by Shashank
        if(!appCaseIds.isEmpty()){
            for(T_APPLN_PRCS_SEARCH__c appPrcsSearch :[Select Id,DTE_PRCSD_APPLN__c from T_APPLN_PRCS_SEARCH__c where IDN_APPLN__c in :appCaseIds]){
                appPrcsSearch.DTE_PRCSD_APPLN__c = system.today();
                lstApplicationPrcsSearchToUpdate.add(appPrcsSearch);
            }
            If(lstApplicationPrcsSearchToUpdate.size()>0){
                GenericDMLHandler.updateRecords(lstApplicationPrcsSearchToUpdate, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_PRCS_SEARCH__c'},'Class__c'=>'ApplicationProcessQueueService','Method__c'=>'populateApplicationProcessedDateOnSearch'}, new List<String>{'DTE_PRCSD_APPLN__c'}); // Added DTE_PRCSD_APPLN__c as part of CCCAP-8307\, added bypass since T_APPLN_PRCS_SEARCH__c is a read only object
            }    
        }
    }
    
    // Set 'Application Receive Date' on Application Process Queue to Today if peak application is submitted before 5pm else set it to next business working day.
    public static void setApplicationRecievedDate(List<T_APPLN_PRCS_QUEUE__c> appProcQueueLst){
        Integer daysToBeAdded = 0;
        set<Date> holidays = new set<Date>();
        for(T_YEAR_HOL__c holiday:[SELECT DTE_HOL__c FROM T_YEAR_HOL__c WHERE DTE_HOL__c>=:appProcQueueLst[0].CreatedDate.date() AND DTE_HOL__c<=:appProcQueueLst[0].CreatedDate.date().addMonths(1)]){
            holidays.add(holiday.DTE_HOL__c);
        }
        List<T_APPLN_PRCS_QUEUE__c> appProcessQueueToBeUpdated = [SELECT Id, CreatedDate FROM T_APPLN_PRCS_QUEUE__c WHERE id IN:appProcQueueLst AND CDE_SOURCE__c = 'PK'];
        for(T_APPLN_PRCS_QUEUE__c appProcessQueue: appProcessQueueToBeUpdated){
            if(appProcessQueue.CreatedDate.hour()>=17){
                daysToBeAdded = 1;
            }
            
            appProcessQueue.DTE_RCVD_APPLN__c = ConvertPeakDataToCHATS.getNextBusinessDay(appProcessQueue.CreatedDate.date().addDays(daysToBeAdded), holidays); 
        }
        update appProcessQueueToBeUpdated;
    }
    
    /*************************************************************
	Method Name	- UpdApplnRcvdDateAndCreateTask115()
	Called From     - applicationPrcsQueueTrigger
	Description     - when an application is updated/transferred to other county, Application received date is updated to system.today and sends the T115 task to county user
	Author          - Azharuddin Mohammad
	Created Date    - 23-July-2021
	JIRA Ticket     - CCCAP-3072
	**************************************************************/
    public static void UpdApplnRcvdDateAndCreateTask115(List<T_APPLN_PRCS_QUEUE__c> applicationProcessQueues, Map<Id,T_APPLN_PRCS_QUEUE__c> oldMapApplicationProcessQueues) {
        List<Task> taskList = new List<Task>();
        List<T_APPLN_PRCS_QUEUE__c> applicationProcessQueueListToBeUpdated = new List<T_APPLN_PRCS_QUEUE__c>();
        
        
        // Task creation logic referred from T108_AppQueueCheckBatch for PEAK task creation.
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'createT115Task','Method__c'=>'ApplicationProcessQueueService'};
        List<Task> taskstoBeCreated = new List<Task>();
        Set<String> allCounties = New Set<String>();
        Set<String> allCountiesSfids = New Set<String>();
        Map<String, String> mapCountySfidToCountyCode = new Map<String, String>();
        Set<Id> queueIds = new Set<Id>();
        Map<String, String> countyOwnerMap = new Map<String, String>();
        Set<Id> activeUsersList = new Set<Id>();
        List<String> recordIdList = new List<String>();
        MAp<String,String> eligibilityWorkers = new Map<String,String>();
        Map<String,String> eligibilitySupervisors = new Map<String, String>();
        Map<String,String> universalUsers = new Map<String, String>();
        Map<String,String> providerSupervisors = new Map<String, String>();
        Map<String,String> fiscalSupervisors = new Map<String, String>();
        Map<String,String> businessOfficeWorkers = new Map<String, String>();
        Map<String,String> readOnlyUsers = new Map<String, String>();
        Map<String,String> CCCAPInternalTeamUsers = new Map<String, String>();
        
        try{
            String dayOfWeek = System.now().format('u');
            
            for(T_APPLN_PRCS_QUEUE__c eachQueue: applicationProcessQueues) {
                if(eachQueue.County_Name__c!= null && eachQueue.County_Transfer_Notes__c !=null && eachQueue.CDE_SOURCE__c == 'PK' && eachQueue.County_Name__c != oldMapApplicationProcessQueues.get(eachQueue.Id).County_Name__c){
                    T_APPLN_PRCS_QUEUE__c applnProcessQueueRecord = new T_APPLN_PRCS_QUEUE__c();
                    
                    applnProcessQueueRecord.Id = eachQueue.Id;
                    applnProcessQueueRecord.DTE_RCVD_APPLN__c = system.today();
                    applicationProcessQueueListToBeUpdated.add(applnProcessQueueRecord);
                    
                    allCountiesSfids.add(eachQueue.County_Name__c);
                }
            }
            // ADDED Empty list checks to save Query Count by Shashank
            if(!allCountiesSfids.isEmpty()){
                for(T_COUNTY__c eachCounty : [select Id, CDE_COUNTY__c FROM T_COUNTY__c WHERE Id IN :allCountiesSfids]){
                    if(eachCounty.CDE_COUNTY__c != null){
                        allCounties.add(String.valueOf(eachCounty.CDE_COUNTY__c).substringBefore('.'));
                        mapCountySfidToCountyCode.put(eachCounty.Id, String.valueOf(eachCounty.CDE_COUNTY__c).substringBefore('.'));
                    }
                }
            }
            
            //Added the logic - validation of Permission set for users list instead of Profiles. CCCAP-14993
            Set<String> targetPermissionSetNames = new Set<String>{
                'Eligibility_Worker_Supervisor_PS', 
                'Eligibility_Worker_PS',
                'Universal_User_PS', 
                'CCCAP_Program_Internal_Team_PS'
            };
            Map<Id, Set<String>> userToPermissionSetNamesMap = new Map<Id, Set<String>>();
            Map<Id, String> userIdToCountyMap = new Map<Id, String>();
            
            // ADDED Empty list checks to save Query Count by Shashank
            if(!allCounties.isEmpty()){
                for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Name, Assignee.Owner_County__c 
                                                    FROM PermissionSetAssignment 
                                                    WHERE Assignee.Owner_County__c IN :allCounties 
                                                    AND Assignee.IsActive = true
                                                    AND PermissionSet.Name IN :targetPermissionSetNames]){
                    activeUsersList.add(psa.AssigneeId);
                    userIdToCountyMap.put(psa.AssigneeId, psa.Assignee.Owner_County__c);
                    if(!userToPermissionSetNamesMap.containsKey(psa.AssigneeId)){
                        userToPermissionSetNamesMap.put(psa.AssigneeId, new Set<String>());
                    }
                    userToPermissionSetNamesMap.get(psa.AssigneeId).add(psa.PermissionSet.Name);
                }
                
                for(Id userId : userToPermissionSetNamesMap.keySet()) {
                    Set<String> userPermSets = userToPermissionSetNamesMap.get(userId);
                    String ownerCounty = userIdToCountyMap.get(userId);
                    if(userPermSets != null && ownerCounty != null){
                        if(userPermSets.contains('Eligibility_Worker_Supervisor_PS')) {
                            eligibilitySupervisors.put(ownerCounty, userId); 
                        } else if(userPermSets.contains('Eligibility_Worker_PS')) {
                            eligibilityWorkers.put(ownerCounty, userId); 
                        } else if(userPermSets.contains('Universal_User_PS')) {
                            universalUsers.put(ownerCounty, userId); 
                        } else if(userPermSets.contains('CCCAP_Program_Internal_Team_PS')) {
                            CCCAPInternalTeamUsers.put(ownerCounty, userId);
                        }
                    }
                }
            }
            /*for(County_User__mdt countyOwner : [SELECT DeveloperName, MasterLabel, County_Code__c, County_Label__c, Primary_Owner__c, Secondary_Owner__c FROM County_User__mdt WHERE County_Code__c IN :allCounties]){
                if (countyOwner.Primary_Owner__c!=null && activeUsersList.contains(countyOwner.Primary_Owner__c)) {
                    countyOwnerMap.put(countyOwner.County_Code__c ,countyOwner.Primary_Owner__c); 
                } else if(countyOwner.Secondary_Owner__c!=null && activeUsersList.contains(countyOwner.Secondary_Owner__c)) {
                    countyOwnerMap.put(countyOwner.County_Code__c ,countyOwner.Secondary_Owner__c); 
                }
            }*/
            
            for(T_APPLN_PRCS_QUEUE__c app : applicationProcessQueues) {
                String ownerId;
                if(!String.isBlank(app.County_Name__c)) {
                    /*if(countyOwnerMap.containsKey(mapCountySfidToCountyCode.get(app.County_Name__c))){
                        ownerId =  countyOwnerMap.get(mapCountySfidToCountyCode.get(app.County_Name__c));
                    } else*/ 
                    if (eligibilityWorkers.containsKey(mapCountySfidToCountyCode.get(app.County_Name__c))){
                        ownerId =  eligibilityWorkers.get(mapCountySfidToCountyCode.get(app.County_Name__c));
                    } else if (eligibilitySupervisors.containsKey(mapCountySfidToCountyCode.get(app.County_Name__c))){
                        ownerId =  eligibilitySupervisors.get(mapCountySfidToCountyCode.get(app.County_Name__c));
                    } else if (universalUsers.containsKey(mapCountySfidToCountyCode.get(app.County_Name__c))){
                        ownerId =  universalUsers.get(mapCountySfidToCountyCode.get(app.County_Name__c));
                    } else if (CCCAPInternalTeamUsers.containsKey(mapCountySfidToCountyCode.get(app.County_Name__c))) {
                        ownerId = CCCAPInternalTeamUsers.get(mapCountySfidToCountyCode.get(app.County_Name__c));
                    }
                }
                
                if(!String.isBlank(ownerId)) {
                    Task tsk = new Task();
                    tsk.Subject = 'T115 - PEAK Application has been transferred to your county';
                    tsk.WhatId = app.Id;
                    tsk.OwnerId = ownerId;
                    tsk.Status = 'New';
                    tsk.Priority = 'Normal';
                    tsk.Description = 'Application Process Queue ' + app.Name + ' has been transferred to your county. Please review the case and take necessary action.';
                    /*if(dayOfWeek == '5') { // Friday
                        tsk.ActivityDate = System.today().addDays(3); // Monday
                    } else if(dayOfWeek == '6') { // Saturday
                        tsk.ActivityDate = System.today().addDays(2); // Monday
                    } else { // Sunday - Thrusday
                        tsk.ActivityDate = System.today().addDays(1); // Next day
                    }*/
                    taskstoBeCreated.add(tsk);
                }
            }
            
            if(!applicationProcessQueueListToBeUpdated.isEmpty()){
                GenericDMLHandler.updateRecords( applicationProcessQueueListToBeUpdated,new Map<String,Object>{'Class__c'=>'ApplicationProcessQueueService','Method__c'=>'UpdApplnRcvdDateAndCreateTask115'}, new List<String>{'DTE_RCVD_APPLN__c'});
            }
            GenericDMLHandler.insertRecords(taskstoBeCreated, methodInfo, new List<String>{'Subject','WhatId','OwnerId','Status','Priority','Description'}); // Added Subject, WhatId, OwnerId, Status, Priority, Description as part of CCCAP-8307
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
        }
    }
    //CCCAP-14530 To prevent user to make changes to records not belonging to their county
    public static void validateCountyWithUserCounties(Map<Id,T_APPLN_PRCS_QUEUE__c> newAPQs, Map<Id,T_APPLN_PRCS_QUEUE__c> oldAPQs){
        Map<Id,Id> appVsCountyIds = new Map<Id,Id>();
        Map<Id,Id> appVsOldCountyIds = new Map<Id,Id>();
        Set<Id> cbmsAPQIds = new Set<Id>();
        Map<String,Id> counties = new Map<String,Id>();
        
        for(T_APPLN_PRCS_QUEUE__c APQ : newAPQs.values()){
            if(APQ.CDE_SOURCE__c == 'CB'){
                cbmsAPQIds.add(APQ.Id);
            }
            if(Trigger.isInsert){
                if(APQ.County_Name__c != null){
                    appVsCountyIds.put(APQ.Id,APQ.County_Name__c); // check if <CURRENT County> belongs to User's assigned county 
                }
            }
            else if(Trigger.isUpdate){
                T_APPLN_PRCS_QUEUE__c oldRecord = oldAPQs.get(APQ.Id);
                if(APQ.County_Name__c != oldRecord.County_Name__c){
                    if(oldAPQs.get(APQ.Id).County_Name__c!=null){
                        appVsCountyIds.put(APQ.Id,oldAPQs.get(APQ.Id).County_Name__c); // check if <OLD County> belongs to User's assigned county
                    }
                }else if(APQ.County_Name__c!=null){
                    appVsCountyIds.put(APQ.Id,APQ.County_Name__c); // check if <CURRENT County> belongs to User's assigned county 
                }
            }
        }
        if(!cbmsAPQIds.isEmpty()){
            for(T_County__c county : [select id,cde_county__c from T_COUNTY__c]){
                counties.put(county.cde_county__c>10?''+county.cde_county__c:'0'+county.cde_county__c,county.Id);
            }
            for(T_APPLN_PRCS_QUEUE__c APQ : [select id,IDN_Appln__r.prior_county__c from T_APPLN_PRCS_QUEUE__c
                                             where Id in : cbmsAPQIds and IDN_Appln__r.prior_county__c!=null 
                                             and IDN_Appln__r.CBMS_REF_REASON__c in ('Inter County Transfer','CW Case Closure')])
            {
                appVsOldCountyIds.put(APQ.Id,counties.get(APQ.IDN_APPLN__r.prior_county__c)); // check if <PRIOR county> belongs to User's assigned county
            }
        }
        Set<Id> combinedCountyIds = new Set<Id>();
        combinedCountyIds.addAll(appVsCountyIds.values());
        combinedCountyIds.addAll(appVsOldCountyIds.values());
        if(!combinedCountyIds.isEmpty()){
            Map<Id,Boolean> countyMatchMap = CHATSUtility.checkCountyWithUserCountyBulk(new Set<Id>(combinedCountyIds));
            for(T_APPLN_PRCS_QUEUE__c APQ : newAPQs.values()){
                Id currentCountyId = appVsCountyIds.containskey(APQ.Id)?appVsCountyIds.get(APQ.Id):null;
                Id priorCountyId = appVsOldCountyIds.containskey(APQ.Id)?appVsOldCountyIds.get(APQ.Id):null;
                Boolean countyMatched = (currentCountyId!=null && countyMatchMap.containsKey(currentCountyId) && countyMatchMap.get(currentCountyId))
                    || (priorCountyId!=null && countyMatchMap.containsKey(priorCountyId) && countyMatchMap.get(priorCountyId));
                if(!countyMatched && !Test.isRunningTest()){
                    APQ.addError('The county of the Application Process Queue does not match your assigned county(ies).'); 
                }
            }
        }
    }
}