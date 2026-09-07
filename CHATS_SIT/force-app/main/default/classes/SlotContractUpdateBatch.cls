global with sharing class SlotContractUpdateBatch implements Database.Batchable<sObject>, schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        string query = 'SELECT Id, Name, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IDN_AUTH__c,IDN_AUTH__r.IDN_SLOT_CONTRACT__c,IDN_AUTH__r.Id,IDN_AUTH__r.Name, IDN_AUTH__r.DTE_END_EFFV_AUTH__c,IDN_AUTH__r.DTE_BEGIN_SLOT__c, IDN_AUTH__r.IDN_CASE__c, IDN_AUTH__r.IDN_CASE__r.OwnerId, IDN_ADDENDUM__c, IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__c, IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId, IND_AVAILABLE__c, IND_FUTURE_VACANT__c, SLOT_CONTRACT_DESCRIPTION__c FROM T_SLOT_CONTRACT__c ORDER BY SLOT_CONTRACT_DESCRIPTION__c';  

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Date currDate = Date.today();
        Date next30Days = currDate.addDays(30);
        String day = System.now().format('EEEE');                   
        Integer daysToAdd = day == 'Saturday' ? 6 : (day == 'Sunday' ? 5 : 7);
                        
        system.debug(next30Days);
        list<T_SLOT_CONTRACT__c> recordsToUpdate = new list<T_SLOT_CONTRACT__c>();
        list<Task> taskToCreate = new list<Task>();
        list<Task> newtask = new list<Task>();
        Map<String, Set<String>> authIdDesrip = new Map<String, Set<String>>();
        set<string> descSet = new set<String>();
        set<id> authId=new set<id>();
        set<id>scIds = new set<id>();
        set<string> descOfSC = new set<String>();
        set<T_SLOT_CONTRACT__c> scRecs = new set<T_SLOT_CONTRACT__c>();
        
        for(T_SLOT_CONTRACT__c sc : (list<T_SLOT_CONTRACT__c>)scope){
            if(sc.DTE_END_SLOT__c < currDate){
                sc.IND_FUTURE_VACANT__c = false;
                sc.IND_AVAILABLE__c = false;
                recordsToUpdate.add(sc);
            } else if(sc.DTE_BEGIN_SLOT__c >= currDate && sc.IND_FUTURE_VACANT__c == true){
                sc.IND_FUTURE_VACANT__c = false;
                recordsToUpdate.add(sc);
            }

            descSet.add(sc.SLOT_CONTRACT_DESCRIPTION__c);
             authId.add(sc.IDN_AUTH__c);
        }

        if(!recordsToUpdate.isEmpty()){
            Database.update(recordsToUpdate, false);
        }

        /* START: Logic to merge consecutive slot contract records with same parameters */
        String key;
        Map<String, List<T_SLOT_CONTRACT__c>> slotContractMap = new Map<String, List<T_SLOT_CONTRACT__c>>();
        for(T_SLOT_CONTRACT__c sc : [SELECT Id, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c, IND_AVAILABLE__c, IDN_AUTH__c, IND_FUTURE_VACANT__c, SLOT_CONTRACT_DESCRIPTION__c,
                                     		CDE_CARE_LEVEL__c, CDE_CARE_UNIT__c, CDE_PRG_TYPE__c, CDE_RATE_TYPE__c, CNT_DAYS_OF_MONTH__c, CNT_DAYS_OF_WEEK__c
                                     FROM T_SLOT_CONTRACT__c WHERE SLOT_CONTRACT_DESCRIPTION__c IN :descSet ORDER BY DTE_BEGIN_SLOT__c ASC]){
            key = sc.SLOT_CONTRACT_DESCRIPTION__c +':'+ sc.CDE_CARE_LEVEL__c +':'+ sc.CDE_CARE_UNIT__c +':'+ sc.CDE_PRG_TYPE__c +':'+ sc.CDE_RATE_TYPE__c
                +':'+ sc.CNT_DAYS_OF_MONTH__c +':'+ sc.CNT_DAYS_OF_WEEK__c;
            if(!slotContractMap.containsKey(key)){
                slotContractMap.put(key, new List<T_SLOT_CONTRACT__c>());
            }
            slotContractMap.get(key).add(sc);
        }
        
        Date vlastEndDate;
        Date olastEndDate;
        T_SLOT_CONTRACT__c vacantMergedRec;
        T_SLOT_CONTRACT__c occupiedMergedRec;
        List<T_SLOT_CONTRACT__c> recordsToDelete = new List<T_SLOT_CONTRACT__c>();
        Map<Id, T_SLOT_CONTRACT__c> mergedRecords = new Map<Id, T_SLOT_CONTRACT__c>();
        for(String sdesc : slotContractMap.keySet()){
            vlastEndDate = null;
            vacantMergedRec = null;
            olastEndDate = null;
            occupiedMergedRec = null;
            for(T_SLOT_CONTRACT__c sc : slotContractMap.get(sdesc)){
                if(sc.IDN_AUTH__c == null){ //Vacant records
                    if(vlastEndDate != null && sc.DTE_BEGIN_SLOT__c.addDays(-1) == vlastEndDate){
                        vacantMergedRec.DTE_END_SLOT__c = sc.DTE_END_SLOT__c;
                        recordsToDelete.add(sc);
                        mergedRecords.put(vacantMergedRec.id, vacantMergedRec);
                    } else {
                        vacantMergedRec = sc;
                    }
                    vlastEndDate = sc.DTE_END_SLOT__c;
                } else { //Occupied records
                    if(occupiedMergedRec != null && sc.DTE_BEGIN_SLOT__c.addDays(-1) == olastEndDate && occupiedMergedRec.IDN_AUTH__c == sc.IDN_AUTH__c){
                    	occupiedMergedRec.DTE_END_SLOT__c = sc.DTE_END_SLOT__c;
                        recordsToDelete.add(sc);
                        mergedRecords.put(occupiedMergedRec.id, occupiedMergedRec);
                    } else {
                        occupiedMergedRec = sc;
                    }
                    olastEndDate = sc.DTE_END_SLOT__c;
                }
            }
        }
        if(!recordsToDelete.isEmpty()){
            SlotContractUtility.ALLOW_DELETE=true;
            //Database.delete(recordsToDelete, false);
            GenericDMLHandler.deleteRecords(recordsToDelete,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractUpdateBatch'});
        }
        if(!mergedRecords.isEmpty()){
            //Database.update(mergedRecords.values(), false);
            GenericDMLHandler.updateRecords(mergedRecords.values(),new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractUpdateBatch'});
        }
        /* END */
        
        /* START: Logic for T-214 Task creation */
        for(Task taskRec : [Select Id, Subject, WhatId, Description from Task where WhatId IN:authId AND Subject ='T214 – Slot Contract is ending and authorization will no longer have association']){
            if(!authIdDesrip.containsKey(taskRec.WhatId) ){ 
                authIdDesrip.put(taskRec.WhatId, new Set<String>());
            }
            authIdDesrip.get(taskRec.WhatId).add(taskRec.Description);            
        }
        
        for(T_SLOT_CONTRACT__c sc : (list<T_SLOT_CONTRACT__c>)scope){
            if(sc.IDN_AUTH__c != Null && sc.DTE_END_SLOT__c >= currDate && sc.DTE_END_SLOT__c < next30Days && sc.IDN_AUTH__r.DTE_END_EFFV_AUTH__c > sc.DTE_END_SLOT__c){
                
                Task tsktwo = new Task();
                tsktwo.Subject = 'T214 – Slot Contract is ending and authorization will no longer have association';
                tsktwo.Status = 'Open';
                tsktwo.Description = 'Slot Contract ID ' + sc.Name
                    +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SLOT_CONTRACT__c/'+sc.Id+'/view)'
                    +' that is currently associated with Authorization ID ' + sc.IDN_AUTH__r.Name
                    +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_AUTH__c/'+sc.IDN_AUTH__c+'/view)'
                    +' is ending in 30 days and authorization will no longer have a Slot Contract associated.';
                
                 if(authIdDesrip.get(sc.IDN_AUTH__c) == Null || !authIdDesrip.get(sc.IDN_AUTH__c).contains(tsktwo.Description)){
                    tsktwo.WhatId = sc.IDN_AUTH__c;
                    tsktwo.ActivityDate = currDate.addDays(daysToAdd);
                    tsktwo.OwnerId = sc.IDN_AUTH__r.IDN_CASE__r.OwnerId;
                    taskToCreate.add(tsktwo);

                    if(sc.IDN_AUTH__r.IDN_CASE__r.OwnerId != sc.IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId){
                    Task tskthree = tsktwo.clone();
                    tskthree.OwnerId = sc.IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId;
                    taskToCreate.add(tskthree);
                    }
                 }
            } 
        }  
        //Database.DMLOptions dm = new Database.DMLOptions();
        //dm.EmailHeader.triggerUserEmail = true;
        //dm.optAllOrNone = false;
        
        if(!taskToCreate.isEmpty()){
            //Database.insert(taskToCreate, dm);
            GenericDMLHandler.insertRecords(taskToCreate,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractUpdateBatch'});
        }
        /* END */
        
        /* START: Logic for T-213 Task creation */
        Map<String, List<T_SLOT_CONTRACT__c>> mapOccupiedSlots = new Map<String, List<T_SLOT_CONTRACT__c>>();
        for(T_SLOT_CONTRACT__c sc : (list<T_SLOT_CONTRACT__c>)scope){
            if(sc.IDN_AUTH__c != Null && sc.DTE_END_SLOT__c >= currDate && sc.DTE_END_SLOT__c < next30Days && sc.IDN_AUTH__r.DTE_END_EFFV_AUTH__c <= sc.DTE_END_SLOT__c){
                if(!mapOccupiedSlots.containsKey(sc.SLOT_CONTRACT_DESCRIPTION__c)){
                    mapOccupiedSlots.put(sc.SLOT_CONTRACT_DESCRIPTION__c, new List<T_SLOT_CONTRACT__c>());
                }
                mapOccupiedSlots.get(sc.SLOT_CONTRACT_DESCRIPTION__c).add(sc);
                descOfSC.add(sc.SLOT_CONTRACT_DESCRIPTION__c); 
            }
        }
        
        List <T_SLOT_CONTRACT__c> SCRecsone = [Select Id, Name, SLOT_CONTRACT_DESCRIPTION__c,DTE_BEGIN_SLOT__c, DTE_END_SLOT__c,IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId, IND_AVAILABLE__c FROM T_SLOT_CONTRACT__c WHERE SLOT_CONTRACT_DESCRIPTION__c IN :descOfSC AND IND_AVAILABLE__c = true];
        for(Task taskRec : [Select Id, Subject, WhatId from Task where WhatId IN :SCRecsone AND Subject ='T213 – Slot Contract is becoming vacant in 30 days']){
            scIds.add(taskRec.WhatId);
        }  
        
        for(T_SLOT_CONTRACT__c sc : SCRecsone) {//records having same desc and authId is null
            
            for(T_SLOT_CONTRACT__c scone : mapOccupiedSlots.get(sc.SLOT_CONTRACT_DESCRIPTION__c)) {//records having same desc and authId is available
                
                if(scone.DTE_END_SLOT__c == sc.DTE_BEGIN_SLOT__c.addDays(-1) && (scIds == Null || !(scIds.contains(sc.Id)) )){
                    Task tsk = new Task();
                    tsk.Subject = 'T213 – Slot Contract is becoming vacant in 30 days';
                    tsk.Status = 'Open';
                    tsk.Description = 'Slot Contract Description ' + scone.SLOT_CONTRACT_DESCRIPTION__c + ' that is currently associated with Authorization ID ' + scone.IDN_AUTH__r.Name 
                        +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_AUTH__c/'+scone.IDN_AUTH__c+'/view)'+' is becoming vacant in 30 days. Slot Contract ID is ' 
                        + sc.Name +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SLOT_CONTRACT__c/'+sc.Id+'/view)'+'.';	 
                    tsk.WhatId = sc.ID;
                    tsk.ActivityDate = currDate.addDays(daysToAdd);
                    tsk.OwnerId = scone.IDN_AUTH__r.IDN_CASE__r.OwnerId;
                    newtask.add(tsk);
                
                if(scone.IDN_AUTH__r.IDN_CASE__r.OwnerId != sc.IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId){
                    Task tskone = tsk.clone();
                    tskone.OwnerId = sc.IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId;
                    newtask.add(tskone);
                   }
                }
            }
        }
        if(!newtask.isEmpty()){
            //Database.insert(newtask, dm);
            GenericDMLHandler.insertRecords(newtask,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractUpdateBatch'});
        }
        /* END */   
        
        //update auth operations 
        Map<id,T_AUTH__c> authMap=new Map<id,T_AUTH__c>([select id,IDN_SLOT_CONTRACT__c,DTE_BEGIN_SLOT__c from T_AUTH__c where id in : authId]);
        for(T_SLOT_CONTRACT__c sc : (list<T_SLOT_CONTRACT__c>)scope){           
            if(string.isNotBlank(sc.IDN_AUTH__c) && string.isNotBlank(sc.IDN_AUTH__r.IDN_SLOT_CONTRACT__c)){
                if(sc.IDN_AUTH__c == sc.IDN_AUTH__r.IDN_SLOT_CONTRACT__c ){
                    if(sc.DTE_END_SLOT__c < system.today()){
                        authMap.get(sc.IDN_AUTH__c).IDN_SLOT_CONTRACT__c=null;
                        authMap.get(sc.IDN_AUTH__c).DTE_BEGIN_SLOT__c=null;
                    }
                }
            }
            if(string.isNotBlank(sc.IDN_AUTH__c)){
                if(system.today() >= sc.DTE_BEGIN_SLOT__c &&  system.today() <= sc.DTE_END_SLOT__c ){
                    authMap.get(sc.IDN_AUTH__c).IDN_SLOT_CONTRACT__c=sc.id;
                    authMap.get(sc.IDN_AUTH__c).DTE_BEGIN_SLOT__c=sc.DTE_BEGIN_SLOT__c;
                }
            }
        }
        Database.update(authMap.values(), false);
    }
    
    global void execute(SchedulableContext sc){
        database.executebatch(new SlotContractUpdateBatch(), 200);
    }
    
    global void finish(Database.BatchableContext BC){
    }
    
}