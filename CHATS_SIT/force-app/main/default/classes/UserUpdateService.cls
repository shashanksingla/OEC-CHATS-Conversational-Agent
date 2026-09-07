/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           05/11/2018                                                          
*  @description    RAT FEES Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 11-May-2018                                                             
*  * Author: Shubham Khandelwal                                                  
*  * Description: Initial version                                                 
*  * CHATS-4622 : All Profiles are able to update their User info, including County access and Deactivation
*
*  * Version: 1.1                                                                             
*  * Date: 30-Oct-2019                                                             
*  * Author: ANUJ WALI                                                 
*  * Description: New method  handleOwnershipUpdate                                               
*  * CHATS-4622 : Automate Case and Fiscal Agreement ownership transfer when respective records have inactive users 
*********************************************************************************************/
public with sharing class UserUpdateService {
    /* Decommissioning CCCAP-14993
    public final static String STATE_PROGRAM_ADMIN = 'State Program Administrator';
    public final static String STATE_IT_USER = 'State IT User';
    public final static String CHATS_SYSTEM_ADMIN = 'CHATS System Administrator';*/
    //public final static String SYSTEM_ADMIN = 'System Administrator';
    public final static String SERVICE_ACCOUNT = 'Service Account';    
    public final static String CCCAP_PROGRAM_INTERNAL_TEAM = 'CCCAP Program Internal Team';    
    
    public static void validateUserBeforeUpdate (List<User> lstNewUser){
        
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Id, Name FROM Profile WHERE Id = :profileId WITH SYSTEM_MODE].Name;
        
        for(User user : lstNewUser){
            //Using Custom Permission CCCAP-14993
            if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team') && !profileName.equals(SERVICE_ACCOUNT)
              && !test.isRunningtest()) {
                   user.id.addError('You are not allowed to update user details');
            }
        }
    }
//CCCAP-14971
    public static void validateCounty(List<User> newUserRecord, Map<Id, User> oldUserRecordMap) {
        
        for (User u : newUserRecord) {
            if ((Trigger.isInsert || 
                 (Trigger.isUpdate && ((u.Common_County__c != oldUserRecordMap.get(u.Id).Common_County__c) 
                                       || (u.Owner_County__c  != oldUserRecordMap.get(u.Id).Owner_County__c))))) 
            {
                u.Common_County_Text__c=u.Common_County__c;            
                if (String.isNotBlank(u.Common_County__c) && u.Owner_County__c != null) {
                    if (u.Common_County__c.split(';').contains(String.valueOf(u.Owner_County__c).trim())) {
                        u.addError('The selected County has already been selected. Please select a different Other County.');
                    }
                }else{
                    continue;
                }
            }
        }
    }
    
    public static void handleCaseOwnershipUpdate(List<T_SBSD_Case__c> caseList){
        List<String> caseCountyList = new List<String>();
        List<String> fiscalCountyList = new List<String>();
        List<String> allCountyCodes = new List<String>();
        
        List<User> defaultUser =  [SELECT Id, Name, IsActive, Owner_County__c 
                                   FROM User 
                                   WHERE Name = :Label.Case_FiscalAgreement_Default_Assignee
                                   AND IsActive = true  WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC];
        
        //Get all county codes:
        for(T_SBSD_Case__c cObj : caseList){
            caseCountyList.add(String.valueOf(Integer.valueOf(cObj.CDE_COUNTY__r.CDE_COUNTY__c)));
        }
        
        
        allCountyCodes.addAll(caseCountyList);
        
        // Permission Set names CCCAP-14993
        List<String> permissionSetNames = new List<String>{
            'Eligibility_Worker_PS', 'Eligibility_Worker_Supervisor_PS',
            'Universal_User_PS', 'Provider_Worker_PS', 'Provider_Worker_Supervisor_PS',
            'Fiscal_Worker_PS', 'Fiscal_Worker_Supervisor_PS', 'Business_Office_Worker_PS',
            'Business_Office_Supervisor_PS', 'Read_Only_User_PS', 'CCCAP_Program_Internal_Team'
        };
        
        // Combined query: Get permission set assignments with User data via relationship fields
        Map<Id, Set<String>> userIdToPermSetNames = new Map<Id, Set<String>>();
        Map<Id, User> userIdToUserMap = new Map<Id, User>();
        for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Name, Assignee.Id, Assignee.Name, Assignee.IsActive, Assignee.Owner_County__c
                                            FROM PermissionSetAssignment 
                                            WHERE PermissionSet.Name IN :permissionSetNames 
                                            AND Assignee.IsActive = true
                                            AND Assignee.Owner_County__c IN :allCountyCodes]) {
            if(!userIdToPermSetNames.containsKey(psa.AssigneeId)) {
                userIdToPermSetNames.put(psa.AssigneeId, new Set<String>());
                userIdToUserMap.put(psa.AssigneeId, psa.Assignee);
            }
            userIdToPermSetNames.get(psa.AssigneeId).add(psa.PermissionSet.Name);
        }
        
        List<User> allActiveUsers = userIdToUserMap.values();
        if(Test.isRunningTest()){
            allActiveUsers = new List<User>();
            for(User u : userIdToUserMap.values()){
                if(u.Name != null && (u.Name.startsWith('UserUpdateBatchTest') || u.Name.startsWith('UserUpdateBatchTest2'))){
                    allActiveUsers.add(u);
                }
            }
        }
        List<User> eliglibilityWorkerUsers = new List<User>();
        List<User> eliglibilityWorkerSupervisorUsers = new List<User>();
        List<User> universalUsers = new List<User>();
        List<User> providerWorkerUsers = new List<User>();
        List<User> providerSupervisorUsers = new List<User>();
        List<User> fiscalWorkerUsers = new List<User>();
        List<User> fiscalSupervisorUsers = new List<User>();
        List<User> boWorkerUsers = new List<User>();
        List<User> boSuperUsers = new List<User>();
        List<User> readOnlyUsers = new List<User>();
        List<User> CCCAPInternalTeamUsers = new List<User>();
        //CCCAP-14993 using permission set
        for(User activeUser : allActiveUsers ){
            Set<String> userPermSets = userIdToPermSetNames.get(activeUser.Id);
            if(userPermSets == null) continue;
            
            if(userPermSets.contains('Eligibility_Worker_PS')){
                eliglibilityWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Eligibility_Worker_Supervisor_PS')){
                eliglibilityWorkerSupervisorUsers.add(activeUser);
            }if(userPermSets.contains('Universal_User_PS')){
                universalUsers.add(activeUser);
            }if(userPermSets.contains('Provider_Worker_PS')){
                providerWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Provider_Worker_Supervisor_PS')){
                providerSupervisorUsers.add(activeUser);
            }if(userPermSets.contains('Fiscal_Worker_PS')){
                fiscalWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Fiscal_Worker_Supervisor_PS')){
                fiscalSupervisorUsers.add(activeUser);
            }if(userPermSets.contains('Business_Office_Worker_PS')){
                boWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Business_Office_Supervisor_PS')){
                boSuperUsers.add(activeUser);
            }if(userPermSets.contains('Read_Only_User_PS')){
                readOnlyUsers.add(activeUser);
            }if(userPermSets.contains('CCCAP_Program_Internal_Team')){
                CCCAPInternalTeamUsers.add(activeUser);
            }
        }
        
        // SEARCH FOR ALL USERS based on County;
        Map<String, List<User>> codeUserMap = new Map<String,List<User>>();
        
        List<User> activeLevel1Users = eliglibilityWorkerUsers;
        
        
        
        for(User userObj : activeLevel1Users){
            if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                List<User> newUlist = new List<User>();
                newUlist.add(userObj);
                codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
            }
            else{
                List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                existingUlist.add(userObj);
                codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
            }
        }
        
        List<String> remainingCodes = new List<String>();
        for(String ccode: allCountyCodes){
            if(codeUserMap.get(ccode) == null){
                remainingCodes.add(ccode);
            }
        }
        
        
        // DONE WITH LEVEL 1
        //START LEVEL 2
        if(remainingCodes.size() > 0){
            List<User> activeLevel2Users = new List<User>();
            for(User levelUser : eliglibilityWorkerSupervisorUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel2Users.add(levelUser);
                }
            }
            //List<User> activeLevel2Users = eliglibilityWorkerSupervisorUsers;
            
            for(User userObj : activeLevel2Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //DONE WITH LEVEL-2
        //START LEvel - 2
        if(remainingCodes.size() > 0){
            List<User> activeLevel3Users = new List<User>();
            for(User levelUser : universalUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel3Users.add(levelUser);
                }
            }
            //List<User> activeLevel3Users = universalUsers;
            
            for(User userObj : activeLevel3Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 4
        if(remainingCodes.size() > 0){
            List<User> activeLevel5Users = new List<User>();
            for(User levelUser : providerWorkerUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel5Users.add(levelUser);
                }
            }
            //List<User> activeLevel5Users = providerWorkerUsers;
            
            for(User userObj : activeLevel5Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 5
        if(remainingCodes.size() > 0){
            List<User> activeLevel6Users = new List<User>();
            for(User levelUser : providerSupervisorUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel6Users.add(levelUser);
                }
            }
            //List<User> activeLevel6Users = providerSupervisorUsers;
            
            for(User userObj : activeLevel6Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 6
        if(remainingCodes.size() > 0){
            List<User> activeLevel7Users = new List<User>();
            for(User levelUser : fiscalWorkerUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel7Users.add(levelUser);
                }
            }
            // List<User> activeLevel7Users = fiscalWorkerUsers;
            
            for(User userObj : activeLevel7Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 7
        if(remainingCodes.size() > 0){
            List<User> activeLevel8Users = new List<User>();
            for(User levelUser : fiscalSupervisorUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel8Users.add(levelUser);
                }
            }
            //List<User> activeLevel8Users = fiscalSupervisorUsers;
            
            for(User userObj : activeLevel8Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 8
        if(remainingCodes.size() > 0){
            List<User> activeLevel9Users = new List<User>();
            for(User levelUser : boWorkerUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel9Users.add(levelUser);
                }
            }
            // List<User> activeLevel9Users = boWorkerUsers;
            
            for(User userObj : activeLevel9Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL-9
        if(remainingCodes.size() > 0){
            List<User> activeLevel10Users = new List<User>();
            for(User levelUser : boSuperUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel10Users.add(levelUser);
                }
            }
            // List<User> activeLevel10Users = boSuperUsers;
            
            for(User userObj : activeLevel10Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL-10
        if(remainingCodes.size() > 0){
            List<User> activeLevel11Users = new List<User>();
            for(User levelUser : readOnlyUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel11Users.add(levelUser);
                }
            }
            // List<User> activeLevel11Users = readOnlyUsers;
            
            for(User userObj : activeLevel11Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }
                else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        
        if(remainingCodes.size() > 0){
            //GET DEFAULT USER
            List<User> defList = new List<User>();
            if(defaultUser.size()>0){
                defList.add(defaultUser[0]);
                for(String rcode: remainingCodes){
                    codeUserMap.put(rcode,defList);
                }
            }
            
        }
        
        
        for(T_SBSD_Case__c upCase : caseList){
            List<User> countyUserList = codeUserMap.get(String.valueOf(Integer.valueOf(upCase.CDE_COUNTY__r.CDE_COUNTY__c)));
            Integer randomIndex = Integer.valueOf(Math.random() * countyUserList.size());
            if(countyUserList.size() > 0){
                upCase.OwnerId = countyUserList[randomIndex].Id;
            }
        }
        
        //CCCAP-1881
        ByPass_Validation_Setting__c byPassValidation=[SELECT Is_Batch_Excluded__c FROM ByPass_Validation_Setting__c LIMIT 1];
        byPassValidation.Is_Batch_Excluded__c = TRUE;
        UPDATE byPassValidation;
        List<Id> updatedRecordIds = new List<Id>();
        List<DMLResult> dmlResult = new List<DMLResult>();
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        System.debug('caseList440: '+caseList);
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'UserUpdateService','Method__c'=>'handleCaseOwnershipUpdate'};
            if(!caseList.isEmpty()){
                dmlResult = GenericDMLHandler.updateRecords(caseList,false,methodInfo);
                lstSaveResult.addAll(GenericDMLHandler.getSaveResultsFromDMLResults(dmlResult));
                for(Integer i=0; i<lstSaveResult.size();i++){
                    if(lstSaveResult.get(i).isSuccess()){
                        updatedRecordIds.add(lstSaveResult.get(i).id);
                    }
                }
            }
        byPassValidation.Is_Batch_Excluded__c = false;
        UPDATE byPassValidation;
        List<T_SBSD_Case__c> caseListsucess = [SELECT Name, OwnerId FROM T_SBSD_Case__c WHERE id IN :updatedRecordIds WITH SECURITY_ENFORCED];
        
        //CREATE TASKS
        List<Task> caseTaskList = new List<Task>();
        for(T_SBSD_Case__c caseRecord: caseListsucess){
            Task newTaskRecord = new Task();
            newTaskRecord.OwnerId = caseRecord.OwnerId;
            newTaskRecord.Subject = 'T109 - Case has been transferred';
            newTaskRecord.Description = 'A Case '+  caseRecord.Name +'  has been transferred from an inactive user to you. Please review the case and take necessary action. ';
            newTaskRecord.WhatId = caseRecord.Id;
            caseTaskList.add(newTaskRecord);
        }
        if(!caseTaskList.isEmpty()){
            GenericDMLHandler.insertRecords(caseTaskList,null);
        }
        Set<Id> fislIds= new Set<Id>();
        Map<Id,T_SBSD_Case__c> mapOfFiscal=new Map<Id,T_SBSD_Case__c>();
        for(T_SBSD_Case__c fisclId : caseListsucess){
            fislIds.add(fisclId.Id);
            mapOfFiscal.put(fisclId.Id,fisclId);
        }
        List<Task> listOfTask = [SELECT Id, WhatId, OwnerId FROM Task WHERE WhatId IN :fislIds AND Status != 'Completed' WITH SECURITY_ENFORCED];
        for(Task task: listOfTask){
            task.OwnerId = mapOfFiscal.get(task.WhatId).OwnerId;
        }
        //end CCCAP-1881
        if(!listOfTask.isEmpty()){
            GenericDMLHandler.updateRecords(listOfTask,methodInfo);
        }
        
    }
    //CCCAP-15161
    /**
     * Enqueues a Queueable job to remove deactivated users from all Analytics
     * Report and Dashboard notification subscriptions they are recipients of.
     */
    public static void handleReportDashboardUnsubscribe(List<User> newUserRec, Map<Id, User> oldUserMap) {
        Set<Id> deactivatedUserIds = new Set<Id>();
        for(User u: newUserRec){
            if(!u.IsActive && oldUserMap.get(u.Id).isActive){
                deactivatedUserIds.add(u.Id);
            }
        }
        if (!deactivatedUserIds.isEmpty()) {
            System.enqueueJob(new UserReportSubscriptionQueueable(deactivatedUserIds));
}
    }

    public static void handleFiscalOwnershipUpdate(List<T_PROVR_FISCAL_AGREMENT__c> fiscList){
        List<String> caseCountyList = new List<String>();
        List<String> fiscalCountyList = new List<String>();
        List<String> allCountyCodes = new List<String>();
        
        List<User> defaultUser =  [SELECT Id, Name, IsActive, Owner_County__c 
                                   FROM User 
                                   WHERE Name = :Label.Case_FiscalAgreement_Default_Assignee
                                   AND IsActive = true WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC];
        
        for(T_PROVR_FISCAL_AGREMENT__c fObj : fiscList){
            fiscalCountyList.add(String.valueOf(Integer.valueOf(fObj.CDE_COUNTY__r.CDE_COUNTY__c)));
        }
        
        allCountyCodes.addAll(fiscalCountyList);
        
        // Permission Set names CCCAP-14993
        List<String> permissionSetNames = new List<String>{
            'Eligibility_Worker_PS', 'Eligibility_Worker_Supervisor_PS',
            'Universal_User_PS', 'Provider_Worker_PS', 'Provider_Worker_Supervisor_PS',
            'Fiscal_Worker_PS', 'Fiscal_Worker_Supervisor_PS', 'Business_Office_Worker_PS',
            'Business_Office_Supervisor_PS', 'Read_Only_User_PS'
        };
        
        // Combined query: Get permission set assignments with User data via relationship fields
        Map<Id, Set<String>> userIdToPermSetNames = new Map<Id, Set<String>>();
        Map<Id, User> userIdToUserMap = new Map<Id, User>();
        for(PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Name, Assignee.Id, Assignee.Name, Assignee.IsActive, Assignee.Owner_County__c
                                            FROM PermissionSetAssignment 
                                            WHERE PermissionSet.Name IN :permissionSetNames 
                                            AND Assignee.IsActive = true
                                            AND Assignee.Owner_County__c IN :allCountyCodes]) {
            if(!userIdToPermSetNames.containsKey(psa.AssigneeId)) {
                userIdToPermSetNames.put(psa.AssigneeId, new Set<String>());
                userIdToUserMap.put(psa.AssigneeId, psa.Assignee);
            }
            userIdToPermSetNames.get(psa.AssigneeId).add(psa.PermissionSet.Name);
        }
        
        List<User> allActiveUsers = userIdToUserMap.values();
        if(Test.isRunningTest()){
            allActiveUsers = new List<User>();
            for(User u : userIdToUserMap.values()){
                if(u.Name != null && (u.Name.startsWith('UserUpdateBatchTest') || u.Name.startsWith('UserUpdateBatchTest2'))){
                    allActiveUsers.add(u);
                }
            }
        }
        List<User> eliglibilityWorkerUsers = new List<User>();
        List<User> eliglibilityWorkerSupervisorUsers = new List<User>();
        List<User> universalUsers = new List<User>();
        List<User> providerWorkerUsers = new List<User>();
        List<User> providerSupervisorUsers = new List<User>();
        List<User> fiscalWorkerUsers = new List<User>();
        List<User> fiscalSupervisorUsers = new List<User>();
        List<User> boWorkerUsers = new List<User>();
        List<User> boSuperUsers = new List<User>();
        List<User> readOnlyUsers = new List<User>();
        //CCCAP-14993 Using permission sets
        for(User activeUser : allActiveUsers ){
            Set<String> userPermSets = userIdToPermSetNames.get(activeUser.Id);
            if(userPermSets == null) continue;
            
            if(userPermSets.contains('Eligibility_Worker_PS')){
                eliglibilityWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Eligibility_Worker_Supervisor_PS')){
                eliglibilityWorkerSupervisorUsers.add(activeUser);
            }if(userPermSets.contains('Universal_User_PS')){
                universalUsers.add(activeUser);
            }if(userPermSets.contains('Provider_Worker_PS')){
                providerWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Provider_Worker_Supervisor_PS')){
                providerSupervisorUsers.add(activeUser);
            }if(userPermSets.contains('Fiscal_Worker_PS')){
                fiscalWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Fiscal_Worker_Supervisor_PS')){
                fiscalSupervisorUsers.add(activeUser);
            }if(userPermSets.contains('Business_Office_Worker_PS')){
                boWorkerUsers.add(activeUser);
            }if(userPermSets.contains('Business_Office_Supervisor_PS')){
                boSuperUsers.add(activeUser);
            }if(userPermSets.contains('Read_Only_User_PS')){
                readOnlyUsers.add(activeUser);
            }
        }
        
        // SEARCH FOR ALL USERS based on County;
        Map<String, List<User>> codeUserMap = new Map<String,List<User>>();
        
        List<User> activeLevel1Users = providerWorkerUsers;
        for(User userObj : activeLevel1Users){
            if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                List<User> newUlist = new List<User>();
                newUlist.add(userObj);
                codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
            } else {
                List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                existingUlist.add(userObj);
                codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
            }
        }
        List<String> remainingCodes = new List<String>();
        for(String ccode: allCountyCodes){
            if(codeUserMap.get(ccode) == null){
                remainingCodes.add(ccode);
            }
        }
        // DONE WITH LEVEL 1
        
        // START LEVEL 2
        if(remainingCodes.size() > 0){
            List<User> activeLevel2Users = new List<User>();
            for(User levelUser : providerSupervisorUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel2Users.add(levelUser);
                }
            }
            //List<User> activeLevel2Users = eliglibilityWorkerSupervisorUsers;
            for(User userObj : activeLevel2Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //DONE WITH LEVEL-2
        //START LEvel - 2
        if(remainingCodes.size() > 0){
            List<User> activeLevel3Users = new List<User>();
            for(User levelUser : boWorkerUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel3Users.add(levelUser);
                }
            }
            //List<User> activeLevel3Users = universalUsers;
            for(User userObj : activeLevel3Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 4
        if(remainingCodes.size() > 0){
            List<User> activeLevel5Users = new List<User>();
            for(User levelUser : boSuperUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel5Users.add(levelUser);
                }
            }
            //List<User> activeLevel5Users = providerWorkerUsers;
            for(User userObj : activeLevel5Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 5
        if(remainingCodes.size() > 0){
            List<User> activeLevel6Users = new List<User>();
            for(User levelUser : universalUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel6Users.add(levelUser);
                }
            }
            //List<User> activeLevel6Users = providerSupervisorUsers;
            for(User userObj : activeLevel6Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 6
        if(remainingCodes.size() > 0){
            List<User> activeLevel7Users = new List<User>();
            for(User levelUser : fiscalWorkerUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel7Users.add(levelUser);
                }
            }
            // List<User> activeLevel7Users = fiscalWorkerUsers;
            for(User userObj : activeLevel7Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 7
        if(remainingCodes.size() > 0){
            List<User> activeLevel8Users = new List<User>();
            for(User levelUser : fiscalSupervisorUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel8Users.add(levelUser);
                }
            }
            //List<User> activeLevel8Users = fiscalSupervisorUsers;
            for(User userObj : activeLevel8Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL - 8
        if(remainingCodes.size() > 0){
            List<User> activeLevel9Users = new List<User>();
            for(User levelUser : eliglibilityWorkerUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel9Users.add(levelUser);
                }
            }
            // List<User> activeLevel9Users = boWorkerUsers;
            for(User userObj : activeLevel9Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL-9
        if(remainingCodes.size() > 0){
            List<User> activeLevel10Users = new List<User>();
            for(User levelUser : eliglibilityWorkerSupervisorUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel10Users.add(levelUser);
                }
            }
            // List<User> activeLevel10Users = boSuperUsers;
            for(User userObj : activeLevel10Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        //LEVEL-10
        if(remainingCodes.size() > 0){
            List<User> activeLevel11Users = new List<User>();
            for(User levelUser : readOnlyUsers){
                if(remainingCodes.contains(levelUser.Owner_County__c)){
                    activeLevel11Users.add(levelUser);
                }
            }
            // List<User> activeLevel11Users = readOnlyUsers;
            for(User userObj : activeLevel11Users){
                if(codeUserMap.get(String.valueOf(userObj.Owner_County__c)) == null ){
                    List<User> newUlist = new List<User>();
                    newUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),newUlist);
                }else{
                    List<User> existingUlist = codeUserMap.get(String.valueOf(userObj.Owner_County__c));
                    existingUlist.add(userObj);
                    codeUserMap.put(String.valueOf(userObj.Owner_County__c),existingUlist);
                }
            }
            remainingCodes = new List<String>();
            for(String ccode: allCountyCodes){
                if(codeUserMap.get(ccode) == null){
                    remainingCodes.add(ccode);
                }
            }
        }
        
        if(remainingCodes.size() > 0){
            //GET DEFAULT USER
            List<User> defList = new List<User>();
            if(defaultUser.size()>0){
                defList.add(defaultUser[0]);
                for(String rcode: remainingCodes){
                    codeUserMap.put(rcode,defList);
                }
            }
        }
        for(T_PROVR_FISCAL_AGREMENT__c upFiscal : fiscList){
            List<User> countyUserList = codeUserMap.get(String.valueOf(Integer.valueOf(upFiscal.CDE_COUNTY__r.CDE_COUNTY__c)));
            Integer randomIndex = Integer.valueOf(Math.random() * countyUserList.size());
            if(countyUserList.size() > 0){
                upFiscal.OwnerId = countyUserList[randomIndex].Id;
            }
        }
        //CCCAP-1881
        
        ByPass_Validation_Setting__c byPassValidation=[SELECT Id, Is_Batch_Excluded__c FROM ByPass_Validation_Setting__c LIMIT 1];
        byPassValidation.Is_Batch_Excluded__c = TRUE;
        UPDATE byPassValidation;
        List<Id> updatedRecordIds = new List<Id>();
        List<DMLResult> dmlResult = new List<DMLResult>();
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'UserUpdateService','Method__c'=>'handleFiscalOwnershipUpdate'};
            if(!fiscList.isEmpty()){
                dmlResult=GenericDMLHandler.updateRecords(fiscList,false,methodInfo);
                lstSaveResult.addAll(GenericDMLHandler.getSaveResultsFromDMLResults(dmlResult));
                for(Integer i=0; i<lstSaveResult.size();i++){
                    if(lstSaveResult.get(i).isSuccess()){
                        updatedRecordIds.add(lstSaveResult.get(i).id);
                    }
                }
            }
        byPassValidation.Is_Batch_Excluded__c = false;
        UPDATE byPassValidation;
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalListsucess = [SELECT Name, OwnerId FROM T_PROVR_FISCAL_AGREMENT__c WHERE id IN :updatedRecordIds WITH SECURITY_ENFORCED];
        List<Task> fiscalTaskList = new List<Task>();
        for(T_PROVR_FISCAL_AGREMENT__c fiscRecord: fiscalListsucess){
            Task newTaskRecord = new Task();
            newTaskRecord.OwnerId = fiscRecord.OwnerId;
            newTaskRecord.Subject = 'T207 - Fiscal Agreement has been transferred ';
            newTaskRecord.Description = 'A Fiscal Agreement '+ fiscRecord.Name +' has been transferred from an inactive user to you. Please review the Fiscal Agreement and take necessary action.';
            newTaskRecord.WhatId = fiscRecord.Id;
            fiscalTaskList.add(newTaskRecord);
        }
        if(!fiscalTaskList.isEmpty()){
            GenericDMLHandler.insertRecords(fiscalTaskList, null);
        }
        Set<Id> fislIds = new Set<Id>();
        Map<Id,T_PROVR_FISCAL_AGREMENT__c> mapOfFiscal = new Map<Id,T_PROVR_FISCAL_AGREMENT__c>();
        for(T_PROVR_FISCAL_AGREMENT__c fisclId : fiscalListsucess){
            fislIds.add(fisclId.Id);
            mapOfFiscal.put(fisclId.Id,fisclId);
        }
        List<Task> listOfTask = [SELECT Id, WhatId, OwnerId FROM Task WHERE WhatId IN :fislIds AND Status != 'Completed'];
        for(Task task: listOfTask){
            task.OwnerId=mapOfFiscal.get(task.WhatId).OwnerId;
        }
        if(!listOfTask.isEmpty()){
            GenericDMLHandler.updateRecords(listOfTask,methodInfo);
        } //CCCAP-1881
    }
}