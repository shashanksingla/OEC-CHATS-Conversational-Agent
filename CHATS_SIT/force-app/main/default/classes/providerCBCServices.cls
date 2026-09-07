public with sharing class providerCBCServices {
    
    public static void provrCBCResults(List<T_PROVR_CBC__c> newProvrCBCList) {
        List<T_PROVR_CBC__c> lstProvrCBC = new List<T_PROVR_CBC__c>();
        //Removed unused variable on 5/14/2018 BG  
        List<T_PROVR_FISCAL_AGREMENT__c> lstProvrFiscAgrmnt = new List<T_PROVR_FISCAL_AGREMENT__c>();
        List<Task> taskList = new List<Task>();
        Map<Id, T_PROVR_CBC__c> provrCBCMap = new Map<Id, T_PROVR_CBC__c>();
        set<Id> provrRcrdId = new set<Id>();
        set<Id> provrRcrdId1 = new set<Id>();
        //Removed unused variable on 5/14/2018 BG  
        for(T_PROVR_CBC__c eachProvrCBC : newProvrCBCList) {
            if(eachProvrCBC.CDE_CBC_STATUS__c == 'MST') {
                lstProvrCBC.add(eachProvrCBC);
                provrRcrdId.add(eachProvrCBC.IDN_PROVR__c);
                provrCBCMap.put(eachProvrCBC.IDN_PROVR__c , eachProvrCBC);
            }
        }
        for (T_CHATS_PROVR_STATUS__c eachProvr : [select Id, Name, CDE_STATUS_PROVR__c FROM T_CHATS_PROVR_STATUS__c where Id IN:provrCBCMap.keySet() AND CDE_STATUS_PROVR__c = 'Open']) {
            provrRcrdId1.add(eachProvr.Id);
        } 
        for (T_PROVR_FISCAL_AGREMENT__c eachProvrFiscAgrmnt : [select Id, CDE_TYPE_STATUS__c, ID_SERVICE__r.Name, OwnerId FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN:provrCBCMap.keySet() AND (CDE_TYPE_STATUS__c = 'FIN' OR CDE_TYPE_STATUS__c = 'OPN')]) {
            if(provrRcrdId1.contains(eachProvrFiscAgrmnt.ID_SERVICE__c)){
                Task taskRcrd = new Task();
                taskRcrd.OwnerId = eachProvrFiscAgrmnt.OwnerId;
                taskRcrd.Subject = 'T202 - Provider Requires Immediate Action Based on CBC Results';
                taskRcrd.Status = 'Not Started';
                taskRcrd.Priority = 'Normal';
                taskRcrd.WhatId = eachProvrFiscAgrmnt.Id;
                String provrId = eachProvrFiscAgrmnt.ID_SERVICE__r.Name;
                if(provrCBCMap.get(eachProvrFiscAgrmnt.ID_SERVICE__c) != Null){
                    taskRcrd.Description = 'Provider ' + provrId + ' has an individual ' + provrCBCMap.get(eachProvrFiscAgrmnt.ID_SERVICE__c).NAM_FIRST__c + ', ' + provrCBCMap.get(eachProvrFiscAgrmnt.ID_SERVICE__c).NAM_LAST__c + ' with a Must Revoke action.';
                }
                taskRcrd.ActivityDate = system.today().addDays(+5);
                taskList.add(taskRcrd);
            }
        }
        if(!taskList.isEmpty()) {
            GenericDMLHandler.insertRecords(taskList,null);
        }
    }
    
    // Added below method by Rishav for CCCAP-4768
    public static void updateProviderFields(List<T_PROVR_CBC__c> newProvCBCList) {
        List<T_CHATS_PROVR_STATUS__c> ProvrListToUpdate = new List<T_CHATS_PROVR_STATUS__c>();
        for(T_PROVR_CBC__c provrCBC : newProvCBCList){
            if(!String.isBlank(provrCBC.IDN_PROVR__c)){
                T_CHATS_PROVR_STATUS__c prov = new T_CHATS_PROVR_STATUS__c();
                prov.Id = provrCBC.IDN_PROVR__c;
                if(Schema.sObjectType.T_CHATS_PROVR_STATUS__c.fields.DTE_FA_ReimEff__c.isUpdateable()){
                    prov.DTE_FA_ReimEff__c = provrCBC.DTE_ProvFinFA_CareEff__c;
                }
                if(Schema.sObjectType.T_CHATS_PROVR_STATUS__c.fields.CDE_REQ_BGC_CHK_STATE__c.isUpdateable()){
                    prov.CDE_REQ_BGC_CHK_STATE__c = provrCBC.CDE_BGC_CHK_STATUS__c;
                }
                ProvrListToUpdate.add(prov);
            }
        }
        GenericDMLHandler.updateRecords(ProvrListToUpdate, new Map<String, Object>{'byPassObjects'=>new Set<String>{'T_CHATS_PROVR_STATUS__c'},'Method__c'=>'updateProviderFields','Class__c'=>'providerCBCServices'}); //Added bypass as part of CCCAP-15040 issue 3 to allow provider worker supervisor to create provider background check fields.
    }
    
    // Added below method by Rishav for CCCAP-4768
    public static void generateT218Task(List<T_PROVR_CBC__c> newProvCBCList, Map<Id, T_PROVR_CBC__c> oldProvCBCMap) {
        List<Task> taskToInsert = new List<Task>();
        Set<String> ProvrIdSet = new Set<String>();
        Set<String> QEIdSet = new Set<String>();
        Map<String, Set<String>> provrOwnerMap = new Map<String, Set<String>>();
        Map<String, String> provrNameMap = new Map<String, String>();
        for(T_PROVR_CBC__c newCBC : newProvCBCList){
            if(newCBC.CDE_BGC_CHK_STATUS__c == 'Cleared'){
                for(T_PROVR_CBC__c provrCBC : newProvCBCList){
                    ProvrIdSet.add(provrCBC.IDN_PROVR__c);
                }
            }
        }
        
        for(T_CHATS_PROVR_STATUS__C prv : [Select Id, CDE_TYPE_PROVR__c FROM T_CHATS_PROVR_STATUS__C where Id IN: ProvrIdSet and CDE_TYPE_PROVR__c = 'EFACH']){
            QEIdSet.add(prv.Id);
        }
        if(!QEIdSet.isEmpty()){
            for(T_PROVR_FISCAL_AGREMENT__c fa : [SELECT Id, ID_SERVICE__c, OwnerId, ID_SERVICE__r.Name FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN: QEIdSet AND CDE_TYPE_STATUS__c = 'DFT']){
                if(provrOwnerMap.containsKey(fa.ID_SERVICE__c)){
                    Set<String> ownerSet = provrOwnerMap.get(fa.ID_SERVICE__c);
                    if(!ownerSet.contains(fa.OwnerId)){
                        ownerSet.add(fa.OwnerId);
                    }
                    provrOwnerMap.put(fa.ID_SERVICE__c, ownerSet);
                } else {
                    provrOwnerMap.put(fa.ID_SERVICE__c, new Set<String>{fa.OwnerId});
                }
                provrNameMap.put(fa.ID_SERVICE__c, fa.ID_SERVICE__r.Name);
            }
            if(!provrOwnerMap.isEmpty()){
                for(T_PROVR_CBC__c provrCBC : newProvCBCList){
                    String Recordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+ provrCBC.IDN_PROVR__c;
                    if(oldProvCBCMap == null && provrCBC.DTE_ProvFinFA_CareEff__c != null){ // New CBC records
                        for(String ownerId : provrOwnerMap.get(provrCBC.IDN_PROVR__c)){
                            Task t = new Task();
                            t.Subject = Label.Task_T218_Subject;
                            t.Description = (Label.Task_T218_Description).replace('{!providerId}', Recordlink);
                            t.ActivityDate = System.today().addDays(5);
                            t.WhatId = provrCBC.IDN_PROVR__c;
                            t.OwnerId = ownerId;
                            taskToInsert.add(t);
                        }
                    }
                    if(oldProvCBCMap != null && provrCBC.DTE_ProvFinFA_CareEff__c != null){ // Existing CBC records
                        if(oldProvCBCMap.get(provrCBC.Id)?.DTE_ProvFinFA_CareEff__c == null){
                            for(String ownerId : provrOwnerMap.get(provrCBC.IDN_PROVR__c)){
                                Task t = new Task();
                                t.Subject = Label.Task_T218_Subject;
                                t.Description = (Label.Task_T218_Description).replace('{!providerId}', Recordlink);
                                t.ActivityDate = System.today().addDays(5);
                                t.WhatId = provrCBC.IDN_PROVR__c;
                                t.OwnerId = ownerId;
                                taskToInsert.add(t);
                            }
                        }
                    }
                }
            }
            GenericDMLHandler.insertRecords(taskToInsert, new Map<String, Object>{'Method__c'=>'generateT218Task','Class__c'=>'providerCBCServices'}); 
        }
    }
}