global without sharing class BulkTransferBatch implements Database.Batchable<sObject> {
    private List<id> itemIdList;
    private String newOwnerId;
    private String transferType;
    
    public BulkTransferBatch(List<Id> itemList, String newOwner, String transferTypeId){
        this.itemIdList = itemList;
        this.newOwnerId = newOwner;
        this.transferType = transferTypeId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<Id> allItemIdList = this.itemIdList;
        if(this.transferType == '1'){
          return Database.getQueryLocator(
            'SELECT Id, ownerId from T_SBSD_Case__c where Id in :allItemIdList '
        	);  
        }
        else if(this.transferType == '2'){
            return Database.getQueryLocator(
            'SELECT Id, ownerId from T_PROVR_FISCAL_AGREMENT__c where Id in :allItemIdList '
        	);
        }
        else if(this.transferType == '3'){
            return Database.getQueryLocator(
            'SELECT Id, ownerId from Task where Id in :allItemIdList '
        	);
        }
        else
            return null;
        
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        if(this.transferType == '1'){
           	List<T_SBSD_Case__c> updateList = new List<T_SBSD_Case__c>(); 
           	List<Task> updateTaskList = new List<Task>();
            for(sObject obj : scope){
                T_SBSD_Case__c rec = new T_SBSD_Case__c();
                rec.Id = obj.Id;
                rec.ownerId = this.newOwnerId;
                updateList.add(rec);
            }
            List<Id> itemsUpdated= new List<Id>();
            if(!updateList.isEmpty()){
                for( DMLResult result : GenericDMLHandler.updateRecords(updateList,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'BulkTransferBatch'})){
                    if(result.saveResult.isSuccess()){
                       itemsUpdated.add(result.saveResult.getId()); 
                    }
                } 
            }
            List<Id> lstItemIdsTask=getTaskId(itemsUpdated);
            if(lstItemIdsTask.size()>0){
                for(Id taskId:lstItemIdsTask){
                    Task rec = new Task();
                    rec.Id = taskId;
                	rec.ownerId = this.newOwnerId;
                	updateTaskList.add(rec);
                }
            }
            if(!updateTaskList.isEmpty()){
                //GenericDMLHandler.updateRecords(updateTaskList,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'BulkTransferBatch'}); 
                List<Database.SaveResult> lstSr= Database.update( updateTaskList, false);
            }
        }
        else if(this.transferType == '2'){
            
            List<T_PROVR_FISCAL_AGREMENT__c> updateList = new List<T_PROVR_FISCAL_AGREMENT__c>();
            List<Task> updateTaskList = new List<Task>();
            for(sObject obj : scope){
                T_PROVR_FISCAL_AGREMENT__c rec = new T_PROVR_FISCAL_AGREMENT__c();
                rec.Id = obj.Id;
                rec.ownerId = this.newOwnerId;
                updateList.add(rec);
            }
            List<Id> itemsUpdated= new List<Id>();
            if(!updateList.isEmpty()){
                for( DMLResult result : GenericDMLHandler.updateRecords(updateList,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'BulkTransferBatch'})){
                    if(result.saveResult.isSuccess()){
                       itemsUpdated.add(result.saveResult.getId()); 
                    }
                } 
            }
            List<Id> lstItemIdsTask=getTaskId(itemsUpdated);
            if(lstItemIdsTask.size()>0){
                for(Id taskId : lstItemIdsTask){
                    Task rec = new Task();
                    rec.Id = taskId;
                	rec.ownerId = this.newOwnerId;
                	updateTaskList.add(rec);
                }
            }
            if(!updateTaskList.isEmpty()){
                //GenericDMLHandler.updateRecords(updateTaskList,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'BulkTransferBatch'});
                List<Database.SaveResult> lstSr= Database.update( updateTaskList, false); 
            }
        }
        else if(this.transferType == '3'){
            List<Task> updateList = new List<Task>();
            for(sObject obj : scope){
                Task rec = new Task();
                rec.Id = obj.Id;
                rec.ownerId = this.newOwnerId;
                updateList.add(rec);
            }
            if(!updateList.isEmpty()){
                //Bypass Owner_Update_Restriction validation on T236/T237 complaint records
                Set<String> clientComplaintSubjects = new Set<String>{
                    System.Label.Task_T236_Subject,
                    System.Label.Task_T237_Subject
                };
                Set<Id> complaintWhatIds = new Set<Id>();
                for (Task t : [SELECT Id, Subject, WhatId FROM Task WHERE Id IN :updateList]) {
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

               // GenericDMLHandler.updateRecords(updateList,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'BulkTransferBatch'});
               List<Database.SaveResult> lstSr = Database.update(updateList, false); 

                //Re-disable bypass flag after task owner update
                if (!complaintsToBypass.isEmpty()) {
                    for (Client_Complaint__c cc : complaintsToBypass) {
                        cc.byPassValidation__c = false;
                    }
                    Database.update(complaintsToBypass, false);
                }
            }  
        }
    }
	
    public static List<Id> getTaskId(List<Id> lstItemIds){
        List<Id> lstItemTaskIds = new List<Id>();            
        for (Task task : [Select Id from task where WhatId in :lstItemIds and Status !='Completed']){
            lstItemTaskIds.add(task.Id); 
        }
        return lstItemTaskIds;
    }
	
    global void finish(Database.BatchableContext BC){
    }
}