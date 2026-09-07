public without sharing class BulkTransferAPXCtrl {

    Public Static Boolean isSuccessful = true;
    Public Static String message = '';
    Public Static Integer successfulUpdates;
    Public Static Integer failedUpdates;

    @auraEnabled
    public Static LightningServerResponse transferItems(String countyId, String fromUserId, String toUserId, String transferType, String subject){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(countyId);
        if(countyMatched) {
            List<Id> lstItemIds = getItemIds(transferType, fromUserId, countyId, subject);
            //List<Id> lstItemIdsTask=getTaskId(lstItemIds,countyId,fromUserId);
            if(lstItemIds.size() > 1000) {
                BulkTransferBatch batchprocess = new BulkTransferBatch(lstItemIds, toUserId, transferType);
                Database.executeBatch(batchprocess);
                objectData.put('itemTransferred', lstItemIds.size());
                isSuccessful = true; 
            } else if(lstItemIds.size()>0) {
                updateOwner(transferType, toUserId, lstItemIds );
                objectData.put('itemTransferred', successfulUpdates);
                objectData.put('failedUpdates', failedUpdates);
            } else {
                isSuccessful = false;
                message = Label.No_Records_Found_for_transfer;
            }
        } else {
            String countyName = [SELECT Name FROM T_COUNTY__c WHERE Id =: countyId LIMIT 1][0].Name;
            String objType = transferType == '1' ? 'case' : (transferType=='2' ? 'Fiscal Agreement' : 'task');
            isSuccessful = false;
            message = 'The ' + objType + ' records that you are trying to access belong to ' + countyName + ' county. This does not match your assigned county(ies).';
        }   
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
       
    public static List<Id> getTaskId(List<Id> lstItemIds1, String countyId, String fromUserId){
        List<Id> lstItemTaskIds = new List<Id>();
        List<Id> lstRelatedCaseFAIds = new List<Id>();
        for(T_SBSD_Case__c caseRec : [SELECT Id FROM T_SBSD_Case__c WHERE CDE_COUNTY__c =: countyId WITH SECURITY_ENFORCED]){
            lstRelatedCaseFAIds.add(caseRec.Id);
        }
        for(T_PROVR_FISCAL_AGREMENT__c prvrFiscalRec : [SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE CDE_COUNTY__c =: countyId WITH SECURITY_ENFORCED]){
            lstRelatedCaseFAIds.add(prvrFiscalRec.Id); 
        }
        for(Task task : [SELECT Id FROM task WHERE WhatId IN: lstItemIds1 AND Status != 'Completed' WITH SECURITY_ENFORCED]){
            lstItemTaskIds.add(task.Id); 
        }
        return lstItemTaskIds;
    }

    public static List<Id> getItemIds(String transferType, String fromUserId, String countyId, String subject){
        List<Id> lstItemIds = new List<Id>();
        List<Profile> profileName = [Select Name from Profile where Id =: UserInfo.getProfileId()];
        String countyName = [SELECT Name FROM T_COUNTY__c WHERE Id =: countyId LIMIT 1][0].Name;
        Boolean skipCountyCheck = false;
        if(countyName.contains('All County')){
            skipCountyCheck = true;
        }        
        // Escape all string parameters to prevent SOQL injection
        transferType = String.escapeSingleQuotes(transferType);
        fromUserId = String.escapeSingleQuotes(fromUserId);
        countyId = String.escapeSingleQuotes(countyId);
        if(String.isNotBlank(subject)){
            subject = String.escapeSingleQuotes(subject);
        }        
        if(transferType == '1') {
            String caseQuery = 'SELECT Id FROM T_SBSD_Case__c WHERE ownerId = :fromUserId';
            if(!skipCountyCheck) {
                caseQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            caseQuery += ' WITH SECURITY_ENFORCED';
            
            for(T_SBSD_Case__c caseRec : Database.query(caseQuery)){
                lstItemIds.add(caseRec.Id); 
            }
        } else if(transferType == '2') {
            String fiscalQuery = 'SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE ownerId = :fromUserId';
            if(!skipCountyCheck) {
                fiscalQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            fiscalQuery += ' AND CDE_TYPE_STATUS__c != \'CLS\' WITH SECURITY_ENFORCED';
            
            for(T_PROVR_FISCAL_AGREMENT__c prvrFiscalRec : Database.query(fiscalQuery)){
                lstItemIds.add(prvrFiscalRec.Id); 
            }
        }
        else if (transferType=='3'){
            String query = 'SELECT Id, WhatId FROM Task Where OwnerId =:fromUserId and Status != \'Completed\'';
            if(String.isNotBlank(subject)){
                query += ' and Subject =:subject';
            }
            List<Task> taskList = Database.query(query);
            
            if(taskList.isEmpty()){
                return lstItemIds;
            }
            
            set<Id> whatIdSet = new set<Id>();            
            for(Task task : taskList){
                whatIdSet.add(task.WhatId);
            }
            
            set<Id> validWhatIds = new set<Id>();
            String caseQuery = 'SELECT Id FROM T_SBSD_Case__c WHERE Id IN :whatIdSet';
            if(!skipCountyCheck) {
                caseQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            caseQuery += ' WITH SECURITY_ENFORCED';
            for (T_SBSD_Case__c caseRec : Database.query(caseQuery)){
                validWhatIds.add(caseRec.Id);
            }
            String fiscalQuery = 'SELECT Id FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id IN :whatIdSet';
            if(!skipCountyCheck) {
                fiscalQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            fiscalQuery += ' WITH SECURITY_ENFORCED';
            for (T_PROVR_FISCAL_AGREMENT__c prvrFiscalRec : Database.query(fiscalQuery)){
                validWhatIds.add(prvrFiscalRec.Id); 
            }
            Date todayDate = System.today();
            String authQuery = 'SELECT Id FROM T_AUTH__c WHERE DTE_BEGIN_EFFV_AUTH__c <= :todayDate AND (DTE_END_EFFV_AUTH__c = null OR DTE_END_EFFV_AUTH__c >= :todayDate) AND Id IN :whatIdSet';
            if(!skipCountyCheck) {
                authQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            authQuery += ' WITH SECURITY_ENFORCED';
            for (T_AUTH__c authRec : Database.query(authQuery)){
                validWhatIds.add(authRec.Id); 
            }
            String slotQuery = 'SELECT Id FROM T_SLOT_CONTRACT__c WHERE Id IN :whatIdSet';
            if(!skipCountyCheck) {
                slotQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            slotQuery += ' WITH SECURITY_ENFORCED';
            for (T_SLOT_CONTRACT__c slotRec : Database.query(slotQuery)){
                validWhatIds.add(slotRec.Id); 
            }
            String slotAddQuery = 'SELECT Id FROM T_SLOT_CONTRACT_ADDENDUM__c WHERE Id IN :whatIdSet';
            if(!skipCountyCheck) {
                slotAddQuery += ' AND CDE_COUNTY__c = :countyId';
            }
            slotAddQuery += ' WITH SECURITY_ENFORCED';
            for (T_SLOT_CONTRACT_ADDENDUM__c slotAdd : Database.query(slotAddQuery)){
                validWhatIds.add(slotAdd.Id); 
            }
            // Added by Rishav for CCCAP-4373
            String provStatusQuery = 'SELECT Id FROM T_CHATS_PROVR_STATUS__c WHERE Id IN :whatIdSet';
            if(!skipCountyCheck) {
                provStatusQuery += ' AND CDE_COUNTY_OWNER__c = :countyId';
            }
            provStatusQuery += ' WITH SECURITY_ENFORCED';
            for(T_CHATS_PROVR_STATUS__c provRec : Database.query(provStatusQuery)){
                validWhatIds.add(provRec.Id); 
            }

            String clientComplaintQuery = 'SELECT Id FROM Client_Complaint__c WHERE Id IN :whatIdSet';
            if(!skipCountyCheck) {
                clientComplaintQuery += ' AND IDN_COUNTY__c = :countyId';
            }
            for(Client_Complaint__c complaintRec : Database.query(clientComplaintQuery)){
                validWhatIds.add(complaintRec.Id); 
            }
            
            // Added by Raina for CCCAP-7876
            //CCCAP-14993 Using Custom Permission
            if(FeatureManagement.checkPermission('Universal_User') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') || FeatureManagement.checkPermission('Business_Office_Supervisor') || FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')) {
                String adjCancelQuery = 'SELECT Id FROM T_ADJMT_CANCEL__c WHERE Id IN :whatIdSet';
                if(!skipCountyCheck) {
                    adjCancelQuery += ' AND IDN_ADJMT__r.CDE_COUNTY__c = :countyId';
                }
                adjCancelQuery += ' WITH SECURITY_ENFORCED';
                for(T_ADJMT_CANCEL__c adjCanRec : Database.query(adjCancelQuery)){
                    validWhatIds.add(adjCanRec.Id); 
                }
            }
            
            for(Task task : taskList){
                if(validWhatIds.contains(task.WhatId)){
                	lstItemIds.add(task.Id); 
                }
            }
        }  

        return lstItemIds;
    }
    
    public static void updateOwner(String transferType, String toUserId, List<Id> lstItemIds){
        List<Id> lstToBeUpdated = new List<Id>();
        if(lstItemIds.size() > 10000) {
            for(integer i=0; i<10000; i++){
                lstToBeUpdated.add(lstItemIds[i]);
            }
        } else {
            for(Id eachId : lstItemIds){
                lstToBeUpdated.add(eachId);
            }
        }        
        try {
            T_SBSD_Case__c caseRec;
            if(transferType == '1'){
                List<T_SBSD_Case__c> lstCaseRec = new List<T_SBSD_Case__c>();
                for(Id itemId : lstToBeUpdated){
                    caseRec = new T_SBSD_Case__c();
                    caseRec.Id = itemId;
                    caseRec.OwnerId = toUserId;
                    lstCaseRec.add(caseRec);
                }
                List<Database.SaveResult> lstSr = Database.update(lstCaseRec, false);
                ExceptionLoggingServices.captureExceptionLog(lstSr, lstCaseRec, new Map<String, Object>{'Class__c'=>'BulkTransferAPXCtrl', 'Method__c'=>'updateOwner'});
                isSuccessful = true;
                Integer success = 0;
                Integer failed = 0;
                List<Id> itemsUpdated = new List<Id>();
                for(Database.SaveResult sr : lstSr){
                    if(sr.isSuccess()) {
                        success++;
                        itemsUpdated.add(sr.getId());
                    } else {
                        failed++;
                    }
                }
                successfulUpdates = success;
                failedUpdates = failed;
                updateTaskOwners(itemsUpdated, toUserId);             
            }
            if(transferType == '2'){
                List<T_PROVR_FISCAL_AGREMENT__c> lstPFARec = new List<T_PROVR_FISCAL_AGREMENT__c>();
                T_PROVR_FISCAL_AGREMENT__c pFARec;
                for (Id itemId : lstToBeUpdated){
                    pFARec = new T_PROVR_FISCAL_AGREMENT__c();
                    pFARec.Id = itemId;
                    pFARec.OwnerId = toUserId;
                    lstPFARec.add(pFARec);
                }
                List<Database.SaveResult> lstSr = Database.update(lstPFARec, false);
                ExceptionLoggingServices.captureExceptionLog(lstSr, lstPFARec, new Map<String, Object>{'Class__c'=>'BulkTransferAPXCtrl', 'Method__c'=>'updateOwner'});
                isSuccessful = true;
                Integer success = 0;
                Integer failed = 0;
                List<Id> itemsUpdated = new List<Id>();
                for(Database.SaveResult sr: lstSr){
                    if(sr.isSuccess()) {
                        success++;
                        itemsUpdated.add(sr.getId());
                    } else {
                        failed++;
                    }
                }
                successfulUpdates = success;
                failedUpdates = failed;
                updateTaskOwners(itemsUpdated, toUserId);           
            }
            if(transferType == '3'){
                // Identify T236/T237 tasks and bypass validation on related complaints
                Set<Id> complaintWhatIds = new Set<Id>();
                Set<String> clientComplaintSubjects = new Set<String>{
                    System.Label.Task_T236_Subject,
                    System.Label.Task_T237_Subject
                };
                for (Task t : [SELECT Id, Subject, WhatId FROM Task WHERE Id IN :lstToBeUpdated]) {
                    if (t.WhatId != null && clientComplaintSubjects.contains(t.Subject)) {
                        complaintWhatIds.add(t.WhatId);
                    }
                }
                List<Client_Complaint__c> complaintsToBypass = new List<Client_Complaint__c>();
                if (!complaintWhatIds.isEmpty()) {
                    for (Client_Complaint__c cc : [SELECT Id FROM Client_Complaint__c WHERE Id IN :complaintWhatIds]) {
                        complaintsToBypass.add(new Client_Complaint__c(Id = cc.Id, byPassValidation__c = true));
                    }
                    Database.update(complaintsToBypass, false);
                }

                List<Task> lstTaskRec = new List<Task>();
                Task taskRec;
                for(Id itemId : lstToBeUpdated){
                    taskRec = new Task();
                    taskRec.Id = itemId;
                    taskRec.OwnerId = toUserId;
                    lstTaskRec.add(taskRec);
                }
                List<Database.SaveResult> lstSr = Database.update(lstTaskRec, false);
                ExceptionLoggingServices.captureExceptionLog(lstSr, lstTaskRec, new Map<String, Object>{'Class__c'=>'BulkTransferAPXCtrl', 'Method__c'=>'updateOwner'});
                isSuccessful = true;
                Integer success = 0;
                Integer failed = 0;
                for(Database.SaveResult sr : lstSr){
                    if(sr.isSuccess()) {
                        success++;
                    } else {
                        failed++;
                    }
                }
                successfulUpdates = success;
                failedUpdates = failed;

                //Re-disable bypass flag after task owner update
                if (!complaintsToBypass.isEmpty()) {
                    for (Client_Complaint__c cc : complaintsToBypass) {
                        cc.byPassValidation__c = false;
                    }
                    Database.update(complaintsToBypass, false);
                }
            }
        } catch(Exception e) {
            message = e.getMessage();
            isSuccessful = false;
            Map<String, Object> exceptionMap = new Map<String, Object>();
            exceptionMap.put('Class__c', 'BulkTransferAPXCtrl');    
            exceptionMap.put('Method__c', 'updateOwner');            
            ExceptionLoggingServices.captureExceptionLog(e, exceptionMap);
        }
    }

    public static void updateTaskOwners(List<Id> recordIds, Id toUserId){
        List<task> lstTaskToBeUpdated = new List<task>();
        for(Task task : [SELECT Id FROM task WHERE WhatId IN: recordIds AND Status != 'Completed']){
            task.OwnerId = String.escapeSingleQuotes(toUserId);
            lstTaskToBeUpdated.add(task);
        }
        if(!lstTaskToBeUpdated.isEmpty()){
            List<Database.SaveResult> lstSr = Database.update(lstTaskToBeUpdated, false);
        }
    }
}