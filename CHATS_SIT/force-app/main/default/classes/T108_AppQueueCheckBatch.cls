global with sharing class T108_AppQueueCheckBatch implements Database.Batchable<sObject> {
    
    List<String> STATUS = new List<String>{'PRC', 'REJ'};
    public static final String SOURCE ='PK';
    public static final Date TEN_DAY_PREVIOUS_DATE = system.today().addDays(-10);
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('Select Name, Id, CDE_COUNTY__c,COUNTY_NAME__c, COUNTY_NAME__r.CDE_COUNTY__c, DTE_RCVD_APPLN__c from T_APPLN_PRCS_QUEUE__c where CDE_SOURCE__c =:SOURCE AND CDE_STATUS_APPLN__c  not in :STATUS AND DTE_RCVD_APPLN__c!= NULL AND DTE_RCVD_APPLN__c=:TEN_DAY_PREVIOUS_DATE');
    }
    
    global void execute(Database.BatchableContext bc, List<T_APPLN_PRCS_QUEUE__c> scope) {
        List<Task> taskList = new List<Task>();
        Set<Id> queueIds = new Set<Id>();
        Map<Id,String> queueCountyName = new Map<Id,String>();
        Set<String> allCounties = New Set<String>();
        
        for(T_APPLN_PRCS_QUEUE__c appQueueRec : scope){
            queueIds.add(appQueueRec.Id);
            if(appQueueRec.COUNTY_NAME__r.CDE_COUNTY__c != null){
                allCounties.add(String.valueOf(appQueueRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
            }
        }
        system.debug('allCounties--> '+allCounties);
        Map<String, String> countyOwnerMap = new Map<String, String>();
        Set<Id> activeUsersList = new Set<Id>();
        Map<String,String> eligibilitySupervisors = new Map<String, String>();
        Map<String,String> universalUsers = new Map<String, String>();
        Map<String,String> providerSupervisors = new Map<String, String>();
        Map<String,String> fiscalSupervisors = new Map<String, String>();
        Map<String,String> businessOfficeWorkers = new Map<String, String>();
        Map<String,String> readOnlyUsers = new Map<String, String>();
        Map<String,String> CCCAPInternalTeamUsers = new Map<String, String>();

        // Permission Set names CCCAP-14993
        List<String> permissionSetNames = new List<String>{
            'Eligibility_Worker_Supervisor_PS', 'Universal_User_PS', 'Provider_Worker_Supervisor_PS',
            'Fiscal_Worker_Supervisor_PS', 'Business_Office_Worker_PS', 'Read_Only_User_PS',
            'CCCAP_Program_Internal_Team'
        };
        
        // Combined query: Get permission set assignments with User data via relationship fields
        Map<Id, Set<String>> userIdToPermSetNames = new Map<Id, Set<String>>();
        Map<Id, String> userIdToCountyMap = new Map<Id, String>();
        for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Name, Assignee.Owner_County__c 
                                            FROM PermissionSetAssignment 
                                            WHERE PermissionSet.Name IN :permissionSetNames 
                                            AND Assignee.IsActive = true
                                            AND Assignee.Owner_County__c IN :allCounties
                                            AND Assignee.PEAK_Overdue_Task_Assignee__c = true]) {
            activeUsersList.add(psa.AssigneeId);
            userIdToCountyMap.put(psa.AssigneeId, psa.Assignee.Owner_County__c);
            if(!userIdToPermSetNames.containsKey(psa.AssigneeId)) {
                userIdToPermSetNames.put(psa.AssigneeId, new Set<String>());
            }
            userIdToPermSetNames.get(psa.AssigneeId).add(psa.PermissionSet.Name);
        }

        for(Id userId : userIdToPermSetNames.keySet()) {
            Set<String> userPermSets = userIdToPermSetNames.get(userId);
            String ownerCounty = userIdToCountyMap.get(userId);
            if(userPermSets == null || ownerCounty == null) continue;
            
            if(userPermSets.contains('Eligibility_Worker_Supervisor_PS')){
                eligibilitySupervisors.put(ownerCounty, userId);
            } else if (userPermSets.contains('Universal_User_PS')){
                universalUsers.put(ownerCounty, userId);
            } else if (userPermSets.contains('Provider_Worker_Supervisor_PS')){
                providerSupervisors.put(ownerCounty, userId);
            } else if (userPermSets.contains('Fiscal_Worker_Supervisor_PS')){
                fiscalSupervisors.put(ownerCounty, userId);
            } else if (userPermSets.contains('Business_Office_Worker_PS')){
                businessOfficeWorkers.put(ownerCounty, userId);
            } else if (userPermSets.contains('Read_Only_User_PS')){
                readOnlyUsers.put(ownerCounty, userId);
            } else if (userPermSets.contains('CCCAP_Program_Internal_Team_PS')){
                CCCAPInternalTeamUsers.put(ownerCounty, userId);
            }
        }
        for(County_User__mdt countyOwner : [SELECT DeveloperName, MasterLabel, County_Code__c, County_Label__c, Primary_Owner__c, Secondary_Owner__c FROM County_User__mdt WHERE County_Code__c IN :allCounties]){
            if(countyOwner.Primary_Owner__c!=null && activeUsersList.contains(countyOwner.Primary_Owner__c)){
                countyOwnerMap.put(countyOwner.County_Code__c ,countyOwner.Primary_Owner__c); 
            } else if(countyOwner.Secondary_Owner__c!=null && activeUsersList.contains(countyOwner.Secondary_Owner__c)){
                countyOwnerMap.put(countyOwner.County_Code__c ,countyOwner.Secondary_Owner__c); 
            }
        }
        for(T_APPLN_PRCS_QUEUE__c eachAppPrcRec : scope){
            String ownerId ;
            if(eachAppPrcRec.CDE_COUNTY__c != null){
                if(countyOwnerMap.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = countyOwnerMap.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                } else if (eligibilitySupervisors.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = eligibilitySupervisors.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                } else if (universalUsers.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = universalUsers.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                } else if (providerSupervisors.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = providerSupervisors.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                }  else if (fiscalSupervisors.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = fiscalSupervisors.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                } else if (businessOfficeWorkers.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = businessOfficeWorkers.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                } else if (readOnlyUsers.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = readOnlyUsers.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.')) ;
                } else if (CCCAPInternalTeamUsers.containsKey(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'))){
                    ownerId = CCCAPInternalTeamUsers.get(String.valueOf(eachAppPrcRec.COUNTY_NAME__r.CDE_COUNTY__c).substringBefore('.'));
                }
            }
            system.debug('ownerId--> '+ownerId);
            if(ownerId != null){
                Task taskRcrd = new Task();
                taskRcrd.OwnerId = ownerId;
                taskRcrd.Subject = 'T108 - Peak Application received 10 days ago is due for processing';
                taskRcrd.Status = 'Not Started';
                taskRcrd.Priority = 'Normal';
                taskRcrd.WhatId = eachAppPrcRec.Id;
                taskRcrd.Description = 'PEAK Application ' + eachAppPrcRec.Name + ' is due for processing within 5 days. Please review the application and take necessary action.';
                taskRcrd.ActivityDate = system.today().addDays(+5);
                taskList.add(taskRcrd);
            } 
        }
        if(!taskList.isEmpty()){
            GenericDMLHandler.insertRecords(taskList,null);
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}