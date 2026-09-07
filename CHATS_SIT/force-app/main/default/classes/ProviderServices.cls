/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           14/12/2017                                                          
*  @description    Handler class for Provider Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 14-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version
*  *
*  * Version: 2.0
*  * Date: July 11, 2018
*  * Author: Gaurav Trivedi
*  * Description: CHATS-5640- OEC - Update OEC integration and trigger logic to populate "Level 1" for blank Quality rating values.
*  *              Method created  setDefaultValue
*  *
*  * Version: 3.0
*  * Date: July 23, 2018
*  * Author: Gaurav Trivedi
*  * Description: CHATS-5952- OEC - Update OEC integration and trigger logic to blank out Quality rating values for Exempt providers
*  *              Method modified  setDefaultValue with else if condition
*  *
*  * Version: 4.0
*  * Date: March 25, 2021
*  * Author: Rishav Maji
*  * Description: CCCAP-5929 - Resolved checkmarx issues by adding FLS Update & FLS Create checks
                             - FLS Read check is not added as it access issues for Connection User when data comes from ATS org
*********************************************************************************************/
public with sharing class ProviderServices {
    
    public static final String EXEMPT_PROVIDER = 'Exempt Providers';
    
    /*************************************************************
    Description     - updates CDE_TYPE_FACILITY__c on Fiscal Agreements
    Author          - Bharadwaj Gaddam
    Created Date    - 14/12/2017
    Param		    - List<T_CHATS_PROVR_STATUS__c> trigger.new Provider list, Map<Id,T_CHATS_PROVR_STATUS__c> old map of Provider list
    Return			- void
    **************************************************************/
    public static void updateFacilityTypeonFiscalAgreements(Map<Id, T_CHATS_PROVR_STATUS__c> ProviderNewMap, Map<Id, T_CHATS_PROVR_STATUS__c> providerOldMap) {
        Set<Id> providerIdSet = new Set<Id>();
        List<T_PROVR_FISCAL_AGREMENT__c> updateFiscalAgreements = new List<T_PROVR_FISCAL_AGREMENT__c>();
        Map<string,string> pickkeyValueMap = new Map<string,string>();
        for(T_CHATS_PROVR_STATUS__c providerEach:ProviderNewMap.values()) {
            if(providerEach.CDE_TYPE_PROVR__c != providerOldMap.get(providerEach.Id).CDE_TYPE_PROVR__c) {
                providerIdSet.add(providerEach.Id);
            }
        }
        try {
            if(providerIdSet.size() > 0) {
                for(R00781__mdt eachRec : [SELECT Id, Provider_Type_Key__c, MasterLabel FROM R00781__mdt WHERE Provider_Type_Key__c != null AND MasterLabel != null]) {
                    pickkeyValueMap.put(eachRec.Provider_Type_Key__c, eachRec.MasterLabel);
                    
                }
                updateFiscalAgreements = [SELECT Id, CDE_TYPE_FACILITY__c, ID_SERVICE__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN: providerIdSet AND CDE_TYPE_STATUS__c != 'CLS'];
                for(T_PROVR_FISCAL_AGREMENT__c FAEach : updateFiscalAgreements) {
                    if(ProviderNewMap.get(FAEach.ID_SERVICE__c).CDE_TYPE_PROVR__c != null) {
                        if(pickkeyValueMap.get(ProviderNewMap.get(FAEach.ID_SERVICE__c).CDE_TYPE_PROVR__c) != null) {
                            if(Schema.sObjectType.T_PROVR_FISCAL_AGREMENT__c.fields.CDE_TYPE_FACILITY__c.isUpdateable()){
                                FAEach.CDE_TYPE_FACILITY__c = pickkeyValueMap.get(ProviderNewMap.get(FAEach.ID_SERVICE__c).CDE_TYPE_PROVR__c);
                            }
                        }
                    } else {
                        FAEach.CDE_TYPE_FACILITY__c = '';
                    }
                }
            }
            if(updateFiscalAgreements.size() > 0) {
                GenericDMLHandler.updateRecords(updateFiscalAgreements,new Map<String,Object>{'Class__c'=>'ProviderServices','Method__c'=>'updateFacilityTypeonFiscalAgreements'});
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'ProviderServices','Method__c'=>'updateFacilityTypeonFiscalAgreements'});
        }
    }
    
    /*************************************************************
    Description     - 1. CHAT-554 Provider Closed in Trials, Task is created and assigned to Fiscal Agrmnt owner to close the fiscal Agreements
                      2. CHAT-558 if the Quality Rating is changed for Provider in OEC then owner of each fiscal agreement is notified of the update in Provider
    Author          - Azharuddin Mohammad
    Created Date    - 01-Feb-2018
    Param		    - List<T_CHATS_PROVR_STATUS__c> trigger.new Provider list, Map<Id,T_CHATS_PROVR_STATUS__c> old map of Provider list
    Return			- void
    **************************************************************/
    Public static final string CLOSED = 'Closed';
    Public static final string OPEN = 'Open';
    
    Public Static Void provrUpdtsFromTrialsAndOEC(Map<Id, T_CHATS_PROVR_STATUS__c> provrNewMap, Map<Id, T_CHATS_PROVR_STATUS__c> provrOldMap) {
        set<Id> provrIdClosedSet = new set<Id>();
        set<Id> provrIdQRISUpdtd = new set<Id>();
        set<Id> provrIdQRISUpdtd2 = new set<Id>();
        List<Task> taskList = new List<Task>();
        for(Id eachProvrId : provrNewMap.keySet()) {
            if(provrNewMap.get(eachProvrId).CDE_STATUS_PROVR__c == CLOSED && (provrNewMap.get(eachProvrId).CDE_STATUS_PROVR__c != provrOldMap.get(eachProvrId).CDE_STATUS_PROVR__c)) {
                provrIdClosedSet.add(eachProvrId);
            }
            else if((provrNewMap.get(eachProvrId).TXT_CHATS_RATING__c != provrOldMap.get(eachProvrId).TXT_CHATS_RATING__c) && (provrNewMap.get(eachProvrId).CDE_STATUS_PROVR__c == OPEN)) {
                if(provrOldMap.get(eachProvrId).TXT_CHATS_RATING__c != null && provrNewMap.get(eachProvrId).TXT_CHATS_RATING__c != null && (provrNewMap.get(eachProvrId).TXT_CHATS_RATING__c).contains('1')) {
                    provrIdQRISUpdtd2.add(eachProvrId);
                }
                provrIdQRISUpdtd.add(eachProvrId);
            }            
        }
        Task taskRcrd;
        String provrId;
        String task200OwnerName=System.label.T200_Owner; 
        if(test.isRunningTest()){
            task200OwnerName=UserInfo.getName();
        }               
        List <User> task200Owner = new List<User>([Select Id, Name FROM User WHERE Name =:task200OwnerName AND isActive=True LIMIT 1]);        
        for(T_PROVR_FISCAL_AGREMENT__c eachFiscalAgrmnt : [SELECT Id, CDE_TYPE_STATUS__c, ID_SERVICE__c, ID_SERVICE__r.Name, OwnerId FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN:provrIdClosedSet AND (CDE_TYPE_STATUS__c = 'FIN' OR CDE_TYPE_STATUS__c = 'OPN')]) {
            if(!task200Owner.isEmpty()){
                taskRcrd = new Task();
                taskRcrd.OwnerId = task200Owner[0]?.Id;      
                taskRcrd.Subject = 'T200 - Provider License is Closed'; 
                taskRcrd.Status = 'Not Started';
                taskRcrd.Priority = 'Normal';
                taskRcrd.WhatId = eachFiscalAgrmnt.Id;
                provrId = eachFiscalAgrmnt.ID_SERVICE__r.Name;
                taskRcrd.Description = 'Provider ' + provrId + ' license is closed. Please close Fiscal Agreements and applicable Slot Contract Addendum records, then a CHATS Task will notify the case worker so that all authorizations can be closed, if applicable.';
                taskRcrd.ActivityDate = system.today().addDays(+1);
                taskList.add(taskRcrd);
            }
            else{
                provrNewMap.get(eachFiscalAgrmnt.ID_SERVICE__c).addError('Owner for Task T200 not found!');
            }
        }
        Task taskRcrd1;
        String prvId;
        String ratingTierLevel;
        for(T_PROVR_FISCAL_AGREMENT__c eachFiscalAgrmnt : [SELECT Id, CDE_TYPE_STATUS__c, ID_SERVICE__c, ID_SERVICE__r.Name, ID_SERVICE__r.TXT_CHATS_RATING__c, OwnerId FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN:provrIdQRISUpdtd  AND (CDE_TYPE_STATUS__c = 'FIN' OR CDE_TYPE_STATUS__c = 'OPN')]) {
            taskRcrd1 = new Task();
            taskRcrd1.OwnerId = eachFiscalAgrmnt.OwnerId;
            ratingTierLevel = eachFiscalAgrmnt.ID_SERVICE__r.TXT_CHATS_RATING__c;
            taskRcrd1.Subject = 'T205 - Provider Rating Changed To Quality Rating Tier '+ ratingTierLevel +'';
            taskRcrd1.Status = 'Not Started';
            taskRcrd1.Priority = 'Normal';
            taskRcrd1.WhatId = eachFiscalAgrmnt.Id;
            prvId = eachFiscalAgrmnt.ID_SERVICE__r.Name;
            taskRcrd1.Description = 'Quality Rating has changed from Quality Rating Tier '+ provrOldMap.get(eachFiscalAgrmnt.ID_SERVICE__c).TXT_CHATS_RATING__c +' to Quality Rating Tier '+ ratingTierLevel +' for Provider ID '+ prvId +'. Please update the fiscal rate schedule.';
            if(provrIdQRISUpdtd2.contains(eachFiscalAgrmnt.ID_SERVICE__c)) {
                taskRcrd1.Description = 'Quality Rating has changed from Quality Rating Tier '+ provrOldMap.get(eachFiscalAgrmnt.ID_SERVICE__c).TXT_CHATS_RATING__c +' to Quality Rating Tier '+ ratingTierLevel +' for Provider ID '+ prvId +'. Please update the fiscal rate schedule and close the Slot Contract Addendum records, as necessary.';  
            }
            taskRcrd1.ActivityDate = system.today().addDays(+15);
            taskList.add(taskRcrd1);
        }
        if(!taskList.isEmpty()){
            GenericDMLHandler.insertRecords(taskList,null);
        }
    }
    
    public static void taskT116Creation(List<T_CHATS_PROVR_STATUS__c> newList, Map<Id,T_CHATS_PROVR_STATUS__c> oldMap){
        String t116Subject = 'T116 – Provider has made a suggestion for a Slot Contract record';
        Date currDate = Date.today();
        String day = System.now().format('EEEE');                   
        Integer daysToAdd = day == 'Saturday' ? 13 : (day == 'Sunday' ? 12 : 14);
        set<string> authIdSet = new set<string>();
        set<string> slotIdSet = new set<string>();
        set<id> provIdSet = new set<Id>();
        for(T_CHATS_PROVR_STATUS__c prov : newList){
            if(prov.Slot_Contract_Suggestion__c != null && prov.Slot_Contract_Suggestion__c != oldMap.get(prov.Id).Slot_Contract_Suggestion__c
              && prov.Slot_Contract_Suggestion__c.contains('~BREAK~')){
                list<string> tempArr = prov.Slot_Contract_Suggestion__c.split('~BREAK~');
                string authId = (tempArr[0].split(':'))[1];
                string scId = (tempArr[1].split(':'))[1];
                authIdSet.add(authId);
                slotIdSet.add(scId);
                provIdSet.add(prov.Id);
            }
        }
        if(provIdSet.isEmpty())
            return;
        set<Id> whatIdSet = new set<Id>();
        set<id> authIds = new set<id>();
        Map<String, T_AUTH__c> authMap = new Map<String, T_AUTH__c>();
        for(T_AUTH__c auth : [SELECT Id, Name, IDN_CASE__r.OwnerId, IDN_CLIENT__c, IDN_CLIENT__r.Name, Child_Name__c FROM T_AUTH__c Where Name IN:authIdSet]){
            authMap.put(auth.Name, auth);
            authIds.add(auth.Id);
            whatIdSet.add(auth.Id);
        }
        set<id> slotIds = new set<id>();
        Map<String, T_SLOT_CONTRACT__c> slotMap = new Map<String, T_SLOT_CONTRACT__c>();
        for(T_SLOT_CONTRACT__c sc : [SELECT Id, Name, IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId FROM T_SLOT_CONTRACT__c Where Name IN:slotIdSet]){
            slotMap.put(sc.Name, sc);
            slotIds.add(sc.Id);
            whatIdSet.add(sc.Id);
        }
        set<string> existingSCTaskDescs = new set<string>();
        set<string> existingAuthTaskDescs = new set<string>();
        for(Task t : [SELECT Id, Description, WhatID, Subject FROM Task Where WhatID IN :whatIdSet and Subject = :t116Subject and Status != 'Completed']){
            if(slotIds.contains(t.WhatID))
                existingSCTaskDescs.add(t.Description);
            if(authIds.contains(t.WhatID))
                existingAuthTaskDescs.add(t.Description);
        }
        list<Task> taskToCreate = new list<Task>();
        for(T_CHATS_PROVR_STATUS__c prov : newList){
            if(prov.Slot_Contract_Suggestion__c != null && prov.Slot_Contract_Suggestion__c != oldMap.get(prov.Id).Slot_Contract_Suggestion__c
               && prov.Slot_Contract_Suggestion__c.contains('~BREAK~')){
                list<string> tempArr = prov.Slot_Contract_Suggestion__c.split('~BREAK~');
                string authId = (tempArr[0].split(':'))[1];
                string scId = (tempArr[1].split(':'))[1];
                string comment = tempArr[2].replace('COMMENT:','');
                if(authMap.containsKey(authId) && slotMap.containsKey(scId)
                   && Schema.sObjectType.Task.fields.Subject.isCreateable()
                   && Schema.sObjectType.Task.fields.Status.isCreateable()
                   && Schema.sObjectType.Task.fields.Description.isCreateable()
                   && Schema.sObjectType.Task.fields.ActivityDate.isCreateable()
                   && Schema.sObjectType.Task.fields.WhatId.isCreateable()
                   && Schema.sObjectType.Task.fields.OwnerId.isCreateable()){
                       T_Auth__c auth = authMap.get(authId);
                       T_SLOT_CONTRACT__c sc = slotMap.get(scId);
                       Task tsk = new Task();
                       tsk.Subject = t116Subject;
                       tsk.Status = 'Open';
                       tsk.Description = 'Provider '+prov.Name
                           +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_CHATS_PROVR_STATUS__c/'+prov.Id+'/view)'
                           +' has made a suggestion that Child '+auth.Child_Name__c+' '+auth.IDN_CLIENT__r.Name
                           +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_INDIV__c/'+auth.IDN_CLIENT__c+'/view)'
                           + ' can be associated to the Slot Contract ID '+scId
                           +'('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SLOT_CONTRACT__c/'+sc.Id+'/view)'
                           +'. Please review the suggestion, communicate with the Provider, and make changes as needed. Provider Note: '+comment;
                       
                       tsk.ActivityDate = currDate.addDays(daysToAdd);
                       if(!existingAuthTaskDescs.contains(tsk.Description)){
                           tsk.WhatId = auth.Id;
                           tsk.OwnerId = auth.IDN_CASE__r.OwnerId;
                           taskToCreate.add(tsk);
                       }
                       if(!existingSCTaskDescs.contains(tsk.Description)){
                           Task tsk2 = tsk.clone();
                           tsk2.WhatId = sc.Id;
                           tsk2.OwnerId = sc.IDN_ADDENDUM__r.IDN_FISCAL_AGREEMENT__r.OwnerId;
                           taskToCreate.add(tsk2);
                       }
                   }
            }
        }
        Database.DMLOptions dm = new Database.DMLOptions();
        dm.EmailHeader.triggerUserEmail = true;
        dm.optAllOrNone = false;
        if(!taskToCreate.isEmpty()){
            Database.insert(taskToCreate, dm);
        }
        updateProviders(provIdSet);
    }
    
    @future
    private static void updateProviders(set<Id> providerIdSet){
        List<T_CHATS_PROVR_STATUS__c> provList = [SELECT Id, Slot_Contract_Suggestion__c FROM T_CHATS_PROVR_STATUS__c WHERE Id IN :providerIdSet];
        for(T_CHATS_PROVR_STATUS__c prov : provList){
            if(Schema.sObjectType.T_CHATS_PROVR_STATUS__c.fields.Slot_Contract_Suggestion__c.isUpdateable()){
                prov.Slot_Contract_Suggestion__c = null;
            }
        }
        update provList;
    }
    
    Public Static Void updQualityRatingObject(Map<Id, T_CHATS_PROVR_STATUS__c> provrNewMap, Map<Id, T_CHATS_PROVR_STATUS__c> provrOldMap) {
        List<T_ACF801_RECV_QLTY_INTFC__c> lstUpdQualityRating = new List<T_ACF801_RECV_QLTY_INTFC__c>(); 
        date dt = system.today();
        integer mnth = dt.month();
        integer yr = dt.year();
        string mnthStr;
        if(mnth < 10) mnthStr = '0' + mnth; else mnthStr = String.valueOf(mnth);
        String mnthReport = String.valueOf(yr) + mnthStr; //String.valueOf(mnth);
        for(Id eachProvrId : provrNewMap.keySet()) {
            if(provrOldMap != Null){
                if(provrOldMap.get(eachProvrId) != Null) {
                    if((provrNewMap.get(eachProvrId).TXT_CHATS_RATING__c != provrOldMap.get(eachProvrId).TXT_CHATS_RATING__c)) {
                        T_ACF801_RECV_QLTY_INTFC__c qltyRating = new T_ACF801_RECV_QLTY_INTFC__c();
                        if(provrNewMap.get(eachProvrId).Name.length() <= 10 && Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.IDN_PROVR__c.isCreateable()) {
                            qltyRating.IDN_PROVR__c = provrOldMap.get(eachProvrId).Name;
                        }
                        qltyRating.CDE_STATUS_PRCSD__c = Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.CDE_STATUS_PRCSD__c.isCreateable() ? 'P' : null;
                        if(provrOldMap.get(eachProvrId).TXT_CHATS_RATING__c != Null && Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.IDN_RATING__c.isCreateable()) {
                            qltyRating.IDN_RATING__c = provrOldMap.get(eachProvrId).TXT_CHATS_RATING__c.right(1);    
                        }
                        qltyRating.DTE_MONTH_REPORT__c = Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.DTE_MONTH_REPORT__c.isCreateable() ? mnthReport : null;
                        if(provrOldMap.get(eachProvrId).NAM_FACILITY__c != Null && Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.NAM_PROVR__c.isCreateable()) {
                            qltyRating.NAM_PROVR__c = provrOldMap.get(eachProvrId).NAM_FACILITY__c;    
                        }
                        lstUpdQualityRating.add(qltyRating);
                    }
                }
            } else {
                T_ACF801_RECV_QLTY_INTFC__c qltyRating1 = new T_ACF801_RECV_QLTY_INTFC__c();
                if(provrNewMap.get(eachProvrId).Name.length() <= 10 && Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.IDN_PROVR__c.isCreateable()) {
                    qltyRating1.IDN_PROVR__c = provrNewMap.get(eachProvrId).Name;
                }
                qltyRating1.CDE_STATUS_PRCSD__c = Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.CDE_STATUS_PRCSD__c.isCreateable() ? 'P' : null;
                if(provrNewMap.get(eachProvrId).TXT_CHATS_RATING__c != Null && Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.IDN_RATING__c.isCreateable()) {
                    qltyRating1.IDN_RATING__c = provrNewMap.get(eachProvrId).TXT_CHATS_RATING__c.right(1);    
                }
                qltyRating1.DTE_MONTH_REPORT__c = Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.DTE_MONTH_REPORT__c.isCreateable() ? mnthReport : null;
                if(provrNewMap.get(eachProvrId).NAM_FACILITY__c != Null && Schema.sObjectType.T_ACF801_RECV_QLTY_INTFC__c.fields.NAM_PROVR__c.isCreateable()) {
                    qltyRating1.NAM_PROVR__c = provrNewMap.get(eachProvrId).NAM_FACILITY__c;    
                }
                lstUpdQualityRating.add(qltyRating1);
            }
        }
        
        if(!lstUpdQualityRating.isEmpty()){
            GenericDMLHandler.insertRecords(lstUpdQualityRating,null);
        }
    }

    /*************************************************************
    Description     - Set default values before insert or update of records. This is requested under task CHATS-5640
    Param		    - {List<T_CHATS_PROVR_STATUS__c>} newProviderList
    Return			- void
    **************************************************************/
    public static void setDefaultValue(List<T_CHATS_PROVR_STATUS__c> newProviderList){
        for (T_CHATS_PROVR_STATUS__c provider : newProviderList) {
            if (provider.CDE_TYPE_PROVR__c <> null && !matchRequestedValue(provider.CDE_TYPE_PROVR__c, EXEMPT_PROVIDER) && String.isBlank(provider.TXT_CHATS_RATING__c))
                provider.TXT_CHATS_RATING__c = 'Level 1';
            else if(provider.CDE_TYPE_PROVR__c <> null && matchRequestedValue(provider.CDE_TYPE_PROVR__c, EXEMPT_PROVIDER))
                 provider.TXT_CHATS_RATING__c = '';
        }
    }

    /*************************************************************
    Description     - Give matched result from Global Static Metadata
    Param		    - {String} value,{String} category
    Return			- Boolean
    **************************************************************/
    public static Boolean matchRequestedValue(String value, String category){
        List<Global_Static_Value__mdt> exemptProviders = new List<Global_Static_Value__mdt>([SELECT MasterLabel, Value__c FROM Global_Static_Value__mdt WHERE isActive__c = true AND Category__c =: category AND Value__c =: value]);
        return !exemptProviders.isEmpty();
    }

    /*************************************************************
    Description     - returns assigned counties of logged in users
    Author          - Vineet Srivastava
    Created Date    - 10/06/2021
    Param		    - void
    Return			- LightningServerResponse
    **************************************************************/
    @auraEnabled
    public static LightningServerResponse getUserAssignedCounties(){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        Map<Decimal, Id> mapCountyCodeToId = new Map<Decimal, Id>();
        try {
            Id loggedInUser = UserInfo.getUserId();
            String profileName;
            Boolean isAdminProfile = false;
            if(string.isNotBlank(loggedInUser)){
                List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id =: userinfo.getProfileId() LIMIT 1];
                profileName = PROFILE[0].Name;
            }
            // Using Custompermission CCCAP-14993
            if(FeatureManagement.checkPermission('System_Administrator') || FeatureManagement.checkPermission('CCCAP_Program_Internal_Team') || (profileName=='System Admin')){
                isAdminProfile = true;
            }
            objectData.put('isAdminProfile', isAdminProfile);
            User UserRecord = [SELECT Id, Owner_County__c, Common_County__c FROM User where Id =: loggedInUser];
            Set<Decimal> setCounties = new Set<Decimal>();
            if (UserRecord.Owner_County__c != null){
                setCounties.add(Decimal.valueOf(UserRecord.Owner_County__c));
            }
            if (UserRecord.Common_County__c != null){
                List<String> countyValues = UserRecord.Common_County__c.split(';');
                for(String countyValue : countyValues){
                    if(String.isNotBlank(countyValue)){
                        setCounties.add(Decimal.valueOf(countyValue));
                    }
                }
            }
            if(setCounties.size() > 0){
                for(T_County__c county :[SELECT Id, CDE_COUNTY__c FROM T_COUNTY__c WHERE CDE_COUNTY__c IN: setCounties]){
                    mapCountyCodeToId.put(county.CDE_COUNTY__c, county.Id);
                }
            }
            if(String.isNotEmpty(UserRecord.Owner_County__c) && mapCountyCodeToId.containsKey(Decimal.valueOf(UserRecord.Owner_County__c))){
                objectData.put('Owner_County__c', mapCountyCodeToId.get(Decimal.valueOf(UserRecord.Owner_County__c)));
            }
            if(String.isNotEmpty(UserRecord.Common_County__c)){
                List<String> countyValues = UserRecord.Common_County__c.split(';');
                List<Id> commonCountyIds = new List<Id>();
                for(String countyValue : countyValues){
                    if(String.isNotBlank(countyValue) && mapCountyCodeToId.containsKey(Decimal.valueOf(countyValue))){
                        commonCountyIds.add(mapCountyCodeToId.get(Decimal.valueOf(countyValue)));
                    }
                }
                objectData.put('Common_County__c', commonCountyIds);
            }
            isSuccessful = true;
        } Catch(Exception e) {
            isSuccessful = false;
            message = e.getMessage();
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }

    /*************************************************************
    Method Name	    - QEProvrCloseActiveFA(Trigger.newMap, Trigger.oldMap)
    Called From     - ProviderTrigger
    Description     - Closes all open FAs of an QE Provider
    Author          - Rishav Maji
    JIRA Ticket     - CCCAP-4768
    **************************************************************/
    Public Static Void QEProvrCloseActiveFA(Map<Id, T_CHATS_PROVR_STATUS__c> provrNewMap, Map<Id, T_CHATS_PROVR_STATUS__c> provrOldMap){
        List<String> eligibleProvrIdList = new List<String>();
        for(T_CHATS_PROVR_STATUS__c provr : provrNewMap.values()) {
            if(provr.CDE_TYPE_PROVR__c == 'EFACH' && provr.CDE_REQ_BGC_CHK_STATE__c == 'Not Cleared'){
                eligibleProvrIdList.add(provr.Id);
            }
        }
        if(!eligibleProvrIdList.isEmpty()){
            List<T_PROVR_FISCAL_AGREMENT__c> FAListToClose = new List<T_PROVR_FISCAL_AGREMENT__c>();
            Id closedRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
            List<T_PROVR_FISCAL_AGREMENT__c> FARecList = [SELECT Id, RecordTypeId, DTE_END_AGRMT__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN: eligibleProvrIdList AND CDE_TYPE_STATUS__c = 'OPN'];
            for(T_PROVR_FISCAL_AGREMENT__c fa : FARecList) {
                fa.CDE_TYPE_STATUS__c = 'CLS';
                fa.RecordTypeId = closedRecordTypeId;
                fa.DTE_END_AGRMT__c = System.today();
                fa.CDE_REASON_END_AGRMT__c = 'MTA';
                FAListToClose.add(fa);
            }
            if(!FAListToClose.isEmpty()){
                GenericDMLHandler.updateRecords(FAListToClose, new Map<String, Object>{'Method__c'=>'QEProvrCloseActiveFA','Class__c'=>'providerServices'});
            }
        }
    }
	
}