/*************************************************************
Class Name	    - ApplicationProcessQueueInvokable
Test Class	    - ApplicationProcessQueueInvokable_Test
Description     - Generic invocable class from 'Application Process Queue Flow' process builder to run different methods
Author          - Rishav Maji
**************************************************************/
public with sharing class ApplicationProcessQueueInvokable {
    
    public class ApplicationRequest {
        public ApplicationRequest() {}
        @InvocableVariable(label='Method Name' description='Determines which method will execute')
        public String methodName;
        
        @InvocableVariable(label='Record Id' description='Application process queue record id')
        public String recordId;
    }
    
    @InvocableMethod(
        label='Application Process Queue Invokable Method' 
        description='Bulkified invocable method called from Application_Process_Queue_Flow process builder'
    )
    public static void invokeApplicationProcessQueueApex(List<ApplicationRequest> requests) {
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'createT113Task','Method__c'=>'ApplicationProcessQueueInvokable'};
            List<String> appIdsForT113 = new List<String>(); // For which records T113 task will be created
        Try {
            for(ApplicationRequest req : requests) {
                if(req.methodName == 'createT113Task')
                    appIdsForT113.add(req.recordId);
            }
            if(appIdsForT113.size() > 0)
                createT113Task(appIdsForT113);
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
        }
        /* [ Template to be followed ]
        List<VARIABLE_TYPE> YOUR_FIRST_METHOD_PARAMETER = new List<VARIABLE_TYPE>();
        List<VARIABLE_TYPE> YOUR_SECOND_METHOD_PARAMETER = new List<VARIABLE_TYPE>();
        for(ApplicationRequest req : requests) {
            if(req.methodName == 'YOUR_FIRST_METHOD_NAME')
                YOUR_FIRST_METHOD_PARAMETER.add(req.recordId);
            if(req.methodName == 'YOUR_SECOND_METHOD_NAME')
                YOUR_SECOND_METHOD_PARAMETER.add(req.recordId);
        }
        if(YOUR_FIRST_METHOD_PARAMETER.size() > 0)
            YOUR_FIRST_METHOD(YOUR_FIRST_METHOD_PARAMETER);
        if(YOUR_SECOND_METHOD_PARAMETER.size() > 0)
            YOUR_SECOND_METHOD(YOUR_SECOND_METHOD_PARAMETER);
        */
    }
    
    public static void createT113Task(List<String> recordIdList) {
        // Task creation logic referred from T108_AppQueueCheckBatch for PEAK task creation.
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'createT113Task','Method__c'=>'ApplicationProcessQueueInvokable'};
        List<Task> taskstoBeCreated = new List<Task>();
        Set<String> allCounties = New Set<String>();
        Set<Id> queueIds = new Set<Id>();
        Map<String, String> countyOwnerMap = new Map<String, String>();
        Set<Id> activeUsersList = new Set<Id>();
        Map<String,String> eligibilitySupervisors = new Map<String, String>();
        Map<String,String> universalUsers = new Map<String, String>();
        Map<String,String> providerSupervisors = new Map<String, String>();
        Map<String,String> fiscalSupervisors = new Map<String, String>();
        Map<String,String> businessOfficeWorkers = new Map<String, String>();
        Map<String,String> readOnlyUsers = new Map<String, String>();
        Map<String,String> CCCAPInternalTeamUsers = new Map<String, String>();
        
        try{
            String dayOfWeek = System.now().format('u');
            
            List<T_APPLN_PRCS_QUEUE__c> recordList = [SELECT Id, Name, County_Name__c, COUNTY_NAME__r.CDE_COUNTY__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id IN :recordIdList];
            for(T_APPLN_PRCS_QUEUE__c appQueueRec : recordList) {
                queueIds.add(appQueueRec.Id);
                if(appQueueRec.COUNTY_NAME__r.CDE_COUNTY__c != null) {
                    allCounties.add(String.valueOf(appQueueRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                }
            }
			//Added the logic - validation of Permission set for users list instead of Profiles. CCCAP-14993
			Set<String> targetPermissionSetNames = new Set<String>{
				'Eligibility_Worker_Supervisor_PS', 
				'Universal_User_PS', 
				'Provider_Worker_Supervisor_PS',
				'Fiscal_Worker_Supervisor_PS', 
				'Business_Office_Worker_PS', 
				'Read_Only_User_PS',  
				'CCCAP_Program_Internal_Team_PS'
			};
			Map<Id, Set<String>> userToPermissionSetNamesMap = new Map<Id, Set<String>>();
			Map<Id, String> userIdToCountyMap = new Map<Id, String>();
			
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
					} else if(userPermSets.contains('Universal_User_PS')) {
						universalUsers.put(ownerCounty, userId); 
					} else if(userPermSets.contains('Provider_Worker_Supervisor_PS')) {
						providerSupervisors.put(ownerCounty, userId); 
					} else if(userPermSets.contains('Fiscal_Worker_Supervisor_PS')) {
						fiscalSupervisors.put(ownerCounty, userId); 
					} else if(userPermSets.contains('Business_Office_Worker_PS')) {
						businessOfficeWorkers.put(ownerCounty, userId); 
					} else if(userPermSets.contains('Read_Only_User_PS')) {
						readOnlyUsers.put(ownerCounty, userId); 
					} else if(userPermSets.contains('CCCAP_Program_Internal_Team_PS')){
						CCCAPInternalTeamUsers.put(ownerCounty, userId);
					}
				}
			}

            for(County_User__mdt countyOwner : [SELECT DeveloperName, MasterLabel, County_Code__c, County_Label__c, Primary_Owner__c, Secondary_Owner__c FROM County_User__mdt WHERE County_Code__c IN :allCounties]){
                if (countyOwner.Primary_Owner__c!=null && activeUsersList.contains(countyOwner.Primary_Owner__c)) {
                    countyOwnerMap.put(countyOwner.County_Code__c ,countyOwner.Primary_Owner__c); 
                } else if(countyOwner.Secondary_Owner__c!=null && activeUsersList.contains(countyOwner.Secondary_Owner__c)) {
                    countyOwnerMap.put(countyOwner.County_Code__c ,countyOwner.Secondary_Owner__c); 
                }
            }

            for(T_APPLN_PRCS_QUEUE__c app : recordList) {
                String ownerId;
                if(!String.isBlank(app.County_Name__c)) {
                    if(countyOwnerMap.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = countyOwnerMap.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (eligibilitySupervisors.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = eligibilitySupervisors.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (universalUsers.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = universalUsers.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (providerSupervisors.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = providerSupervisors.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (fiscalSupervisors.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = fiscalSupervisors.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (businessOfficeWorkers.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = businessOfficeWorkers.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (readOnlyUsers.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))) {
                        ownerId = readOnlyUsers.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                    } else if (CCCAPInternalTeamUsers.containsKey(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                        ownerId = CCCAPInternalTeamUsers.get(String.valueOf(app.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'));
                    }
                }
                
                if(!String.isBlank(ownerId)) {
                    Task tsk = new Task();
                    tsk.Subject = System.Label.Task_T113_Subject;
                    tsk.WhatId = app.Id;
                    tsk.OwnerId = ownerId;
                    tsk.Status = 'New';
                    tsk.Priority = 'Normal';
                    tsk.Description = CHATSUtility.mergeText(app, System.Label.Task_T113_Description);
                    if(dayOfWeek == '5') { // Friday
                        tsk.ActivityDate = System.today().addDays(3); // Monday
                    } else if(dayOfWeek == '6') { // Saturday
                        tsk.ActivityDate = System.today().addDays(2); // Monday
                    } else { // Sunday - Thrusday
                        tsk.ActivityDate = System.today().addDays(1); // Next day
                    }
                    taskstoBeCreated.add(tsk);
                }
            }
            GenericDMLHandler.insertRecords(taskstoBeCreated, methodInfo, new list<String>{'Subject','WhatId','OwnerId','Status','Priority','Description','ActivityDate'}); // Added Subject, WhatId, OwnerId, Status, Priority, Description, ActivityDate as part of CCCAP-8307
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, methodInfo);
        }
    }

}