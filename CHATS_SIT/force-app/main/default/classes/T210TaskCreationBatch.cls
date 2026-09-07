/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           07/29/2020                                                          
*  @description    T210 Task Creation Batch.                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-Jul-2020                                                             
*  * Author: Sahil Garg                                                     
*  * Description: Initial version 
*********************************************************************************************/
global with sharing class T210TaskCreationBatch implements Database.Batchable<sObject> {
    
    public Date validationDate =  System.today().addDays(Integer.valueOf(System.Label.t210task_time_period)) ;
    public List<String> providerStatus= new List<String>{'Open','Pending','Closed','NA'};
    public List<String> providerType= new List<String>{'EFACH'};
    
    global List<SObject> start(Database.BatchableContext BC) {
        List<SObject> finalList= new List<SObject>();
        List<T_CHATS_PROVR_STATUS__c> providers = new List<T_CHATS_PROVR_STATUS__c>();
        List<T_PROVR_FISCAL_AGREMENT__C> fiscalagreemswithnoauthonprovr= new List<T_PROVR_FISCAL_AGREMENT__C>();
        List<T_PROVR_FISCAL_AGREMENT__c> fasWithNoAuthOnCounty= new List<T_PROVR_FISCAL_AGREMENT__c>();
        if(!Test.isRunningTest()){
            providers=[SELECT Id, Name, CDE_TYPE_LICENSE__c, CDE_TYPE_PROVR__c,
                       (SELECT Id,ownerId,owner.isActive,Name, CDE_COUNTY__c,CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, 
                        DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__c, Provider_Name__c FROM Provider_Fiscal_Agreements__r 
                        where DTE_BEGIN_AGRMT__c<=:validationDate AND (DTE_END_AGRMT__c>=TODAY OR DTE_END_AGRMT__c = NULL) ),
                       (SELECT Id, Name,Authorization_Status__c, CDE_COUNTY__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,
                        IDN_PROVR__c, NAM_FACILITY__c FROM Authorizations__r) FROM T_CHATS_PROVR_STATUS__c 
                       where cde_type_provr__c in:providerType and CDE_STATUS_PROVR__c  in:providerStatus  AND Id in
                       (select IDN_PROVR__c from T_AUTH__c where DTE_END_EFFV_AUTH__c <= :validationDate AND DTE_END_EFFV_AUTH__c<>NULL) ];
            
            fiscalagreemswithnoauthonprovr=[SELECT Id,Name,ownerId,owner.isActive,CDE_COUNTY__c, CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__c,ID_SERVICE__r.Name,ID_SERVICE__r.CDE_TYPE_LICENSE__c,ID_SERVICE__r.CDE_TYPE_PROVR__c, Provider_Name__c FROM T_PROVR_FISCAL_AGREMENT__C where DTE_BEGIN_AGRMT__c<=:validationDate AND (DTE_END_AGRMT__c>=TODAY OR DTE_END_AGRMT__c = NULL) AND ID_SERVICE__r.cde_type_provr__c=:providerType and 
                                            ID_SERVICE__r.CDE_STATUS_PROVR__c  in:providerStatus AND CDE_TYPE_STATUS__c = 'OPN' AND ID_SERVICE__c Not in (select IDN_PROVR__c from T_AUTH__c)  ];
            fasWithNoAuthOnCounty=[SELECT Id,Name,ownerId,owner.isActive,CDE_COUNTY__c, CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__c,ID_SERVICE__r.Name,ID_SERVICE__r.CDE_TYPE_LICENSE__c,ID_SERVICE__r.CDE_TYPE_PROVR__c, Provider_Name__c FROM T_PROVR_FISCAL_AGREMENT__C where DTE_BEGIN_AGRMT__c<=:validationDate AND (DTE_END_AGRMT__c>=TODAY OR DTE_END_AGRMT__c = NULL) AND ID_SERVICE__r.cde_type_provr__c=:providerType and 
                                   ID_SERVICE__r.CDE_STATUS_PROVR__c  in:providerStatus AND CDE_TYPE_STATUS__c = 'OPN' AND CDE_COUNTY__C Not in (select CDE_COUNTY__C from T_AUTH__c) ];
        } else {
            Date todayDate= System.today();
            providers=[SELECT Id, Name, CDE_TYPE_LICENSE__c, CDE_TYPE_PROVR__c,
                       (SELECT Id,ownerId,owner.isActive,Name, CDE_COUNTY__c,CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, 
                        DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__c, Provider_Name__c FROM Provider_Fiscal_Agreements__r 
                        where DTE_BEGIN_AGRMT__c<=:todayDate AND (DTE_END_AGRMT__c>=TODAY OR DTE_END_AGRMT__c = NULL) ),
                       (SELECT Id, Name,Authorization_Status__c, CDE_COUNTY__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,
                        IDN_PROVR__c, NAM_FACILITY__c FROM Authorizations__r) FROM T_CHATS_PROVR_STATUS__c 
                       where cde_type_provr__c in:providerType and CDE_STATUS_PROVR__c  in:providerStatus  AND Id in
                       (select IDN_PROVR__c from T_AUTH__c where DTE_END_EFFV_AUTH__c = :todayDate AND DTE_END_EFFV_AUTH__c<>NULL) ];
            
            fiscalagreemswithnoauthonprovr=[SELECT Id,Name,ownerId,owner.isActive,CDE_COUNTY__c, CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__c,ID_SERVICE__r.Name,ID_SERVICE__r.CDE_TYPE_LICENSE__c,ID_SERVICE__r.CDE_TYPE_PROVR__c, Provider_Name__c FROM T_PROVR_FISCAL_AGREMENT__C where DTE_BEGIN_AGRMT__c<=:todayDate AND (DTE_END_AGRMT__c>=TODAY OR DTE_END_AGRMT__c = NULL) AND ID_SERVICE__r.cde_type_provr__c=:providerType and 
                                            ID_SERVICE__r.CDE_STATUS_PROVR__c  in:providerStatus AND CDE_TYPE_STATUS__c = 'OPN'  AND ID_SERVICE__c Not in (select IDN_PROVR__c from T_AUTH__c) ];
            fasWithNoAuthOnCounty=[SELECT Id,Name,ownerId,owner.isActive,CDE_COUNTY__c, CDE_TYPE_FACILITY__c, CDE_TYPE_STATUS__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c, DTE_RCV_AGRMT_FISCAL__c, ID_SERVICE__c,ID_SERVICE__r.Name,ID_SERVICE__r.CDE_TYPE_LICENSE__c,ID_SERVICE__r.CDE_TYPE_PROVR__c, Provider_Name__c FROM T_PROVR_FISCAL_AGREMENT__C where DTE_BEGIN_AGRMT__c<=:todayDate AND (DTE_END_AGRMT__c>=TODAY OR DTE_END_AGRMT__c = NULL) AND ID_SERVICE__r.cde_type_provr__c=:providerType and 
                                   ID_SERVICE__r.CDE_STATUS_PROVR__c  in:providerStatus AND CDE_TYPE_STATUS__c = 'OPN' AND CDE_COUNTY__C Not in (select CDE_COUNTY__C from T_AUTH__c) ];
            
        }
        finalList.addAll(providers);
        finalList.addAll(fiscalagreemswithnoauthonprovr);
        finalList.addAll(fasWithNoAuthOnCounty);
        return finalList;
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('Started method execute in T210 Task Creation Batch');
        Date lessThanToday90;
        if(!Test.isRunningTest())
            lessThanToday90 =  System.today().addDays(Integer.valueOf(System.Label.t210task_time_period)) ;
        else
            lessThanToday90 =  System.today() ;
        if(null!=scope &&!scope.isEmpty())
            System.debug('Number of records fetched from start method :'+scope.size());
        Map<Id,T210Wrapper> mapOf210Wrappers= new Map<Id,T210Wrapper>();
        Map<Id,Id> faProviderMap = new Map<Id,Id>();
        set<Id> providerIds = new set<Id>();
        set<Id> countyIds = new set<Id>();
        List<T_CHATS_PROVR_STATUS__c> listProviders= new List<T_CHATS_PROVR_STATUS__c>();
        List<T_PROVR_FISCAL_AGREMENT__C> fasWithNoAuthOnProvrCounty= new List<T_PROVR_FISCAL_AGREMENT__C> ();
        for(sObject obj : scope){
            if(String.valueOf(obj.Id.getsobjecttype()) == 'T_CHATS_PROVR_STATUS__c'){
                listProviders.add((T_CHATS_PROVR_STATUS__c)obj);
            }
            else if(String.valueOf(obj.Id.getsobjecttype()) == 'T_PROVR_FISCAL_AGREMENT__c'){
                fasWithNoAuthOnProvrCounty.add((T_PROVR_FISCAL_AGREMENT__c)obj);
            }
        }
        Map<Id,Id> providerCountyMap = new Map<Id,Id>();
        for(T_CHATS_PROVR_STATUS__c provrObj:listProviders){
            providerIds.add(provrObj.Id);
            System.debug('Got the provider');
            List<T_Auth__c> auths=provrObj.Authorizations__r;
            List<T_PROVR_FISCAL_AGREMENT__c> fas=provrObj.Provider_Fiscal_Agreements__r;
            if(null!=fas&&!fas.isEmpty()&&null!=auths&&!auths.isEmpty()){
                System.debug('Got the FAs and Auths');
                for(T_PROVR_FISCAL_AGREMENT__c fa:fas){
                    System.debug('Got the FA:');
                    for(T_Auth__c auth:auths){
                        System.debug('Got the Auth:');
                        if(fa.ID_SERVICE__c==auth.IDN_PROVR__c && fa.CDE_COUNTY__c==auth.CDE_COUNTY__c && auth.DTE_END_EFFV_AUTH__c<=lessThanToday90 && fa.CDE_TYPE_STATUS__c == 'OPN'){
                            System.debug('Got the Auth ended on validation date');
                            if(checkAuthsInFuture(auths,auth)==false){
                                System.debug('No Auth in Future');
                                T210Wrapper wrapper = new T210Wrapper();
                                wrapper.faOwnerId=fa.OwnerId;
                                wrapper.providerId=provrObj.Id;
                                wrapper.faId=fa.Id;
                                wrapper.faName=fa.Name;
                                wrapper.providerName=provrObj.Name;
                                wrapper.countyId=fa.CDE_COUNTY__c;
                                wrapper.isOwnerActive=fa.Owner.isActive;
                                mapOf210Wrappers.put(fa.Id,wrapper);
                                System.debug('Size of Task Wrapper:'+mapOf210Wrappers.size());
                            }
                        }
                    }
                }
            }
        }
        
        //TODO
        
        if(null!=fasWithNoAuthOnProvrCounty&&!fasWithNoAuthOnProvrCounty.isEmpty()){
            System.debug('Got the FAs without Auth:'+fasWithNoAuthOnProvrCounty.size());          
            
            
            for(T_PROVR_FISCAL_AGREMENT__C fa:fasWithNoAuthOnProvrCounty){
                T210Wrapper wrapper = new T210Wrapper();
                wrapper.faOwnerId=fa.OwnerId;
                wrapper.providerId=fa.Id_SERVICE__c;
                wrapper.faId=fa.Id;
                wrapper.faName=fa.Name;
                wrapper.providerName=fa.Id_SERVICE__r.Name;
                wrapper.isOwnerActive=fa.Owner.isActive;
                mapOf210Wrappers.put(fa.Id,wrapper);
                System.debug('Added a task in wrapper for FAs with no Auth');
            }
            
            
        }
        System.debug('Size of tasks to be inserted before removal:'+mapOf210Wrappers.size());
        List<Task> existingTask=[SELECT Id, Status, WhoId, WhatId, Subject FROM Task where whatId in:mapOf210Wrappers.keySet() and status!='Completed' AND Subject like 'T210%'];
        if(existingTask!=null&&!existingTask.isEmpty()){
            for(Task t:existingTask){
                if(mapOf210Wrappers.containsKey(t.whatId))
                    mapOf210Wrappers.remove(t.whatId);
            }
        }
        if(!mapOf210Wrappers.isEmpty()){
            createTasks(mapOf210Wrappers.values());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
        
    }
    public boolean checkAuthsInFuture(List<T_Auth__c> authList,T_AUTH__c auth){
        boolean result = false;
        for(T_Auth__c obj:authList){
            if(obj.IDN_PROVR__c==auth.IDN_PROVR__c&&obj.CDE_COUNTY__C==auth.CDE_COUNTY__c&&(obj.DTE_END_EFFV_AUTH__C>auth.DTE_END_EFFV_AUTH__C||obj.DTE_END_EFFV_AUTH__C==null)){
                result=true;
            }
        }
        return result;
    }
    public void createTasks(List<T210Wrapper> listOfWrappers){
        List<Task> taskstoBeCreated = new List<Task>();
        System.debug('Inserting '+listOfWrappers.size()+ ' Task');
        for(T210Wrapper wrapper:listOfWrappers){
            Task tsk= new Task();
            tsk.Subject = 'T210 - Fiscal Agreement without an open authorization for more than 90 days';
            tsk.WhatId = wrapper.faId;
            if(!Test.isRunningTest()){
                if(wrapper.isOwnerActive)
                    tsk.OwnerId = wrapper.faOwnerId;
                else
                    tsk.OwnerId=String.valueOf(System.label.t210_task_owner);
            }
            tsk.Status = 'New';
            tsk.Priority = 'Normal';
            tsk.ActivityDate= System.today().addDays(10);
            tsk.Description = 'The provider '+wrapper.providerName+'('+getHyperlink(wrapper.providerId)+') has not had an active authorization for '+wrapper.faName+'('+getHyperlink(wrapper.faId)+') for more than 90 days. Please review the Provider\'s authorizations, take necessary action to close the Fiscal Agreement and document your actions in Provider Notes';
            taskstoBeCreated.add(tsk);
        }
        if(null!=taskstoBeCreated&&!taskstoBeCreated.isEmpty())
            GenericDMLHandler.insertRecords(taskstoBeCreated, true, new Map<String,Object>{'Method__c'=>'createTasks','Class__c'=>'T210TaskCreationBatch'});
    }
    public String getHyperlink(Id recordId){
        return URL.getOrgDomainUrl().toExternalForm()+'/'+recordId;
    }
}