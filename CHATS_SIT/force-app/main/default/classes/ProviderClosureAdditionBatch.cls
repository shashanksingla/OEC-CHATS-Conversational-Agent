/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/24/2022                                                         
*  @description    Child Enrollment batch class for datafix     currently 18868 open auths in PROD                         
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 22-Nov-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class ProviderClosureAdditionBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public List<T_PROVR_CLOSURE__c> providerClsToBeUpdated = new List<T_PROVR_CLOSURE__c>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime providerClsBeginDate = Datetime.newInstance(2022,09,25);
        Datetime providerClsEndDate = Datetime.newInstance(2022,10,28);
        if(Test.isRunningTest()){
            providerClsBeginDate = system.today();
            providerClsEndDate = system.today();
            return Database.getQueryLocator([SELECT  Id, Name, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,
                                         IDN_PROVR__c, CDE_COUNTY__c,createdDate 
                                         FROM T_AUTH__c ]);
        }else{
            return Database.getQueryLocator([SELECT  Id, Name, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,
                                         IDN_PROVR__c, IDN_PROVR__r.Name, CDE_COUNTY__c, CDE_COUNTY__r.Name,createdDate 
                                         FROM T_AUTH__c where createdDate >=:providerClsBeginDate and createdDate <=:providerClsEndDate                            
                                         order by Name ASC]);
        }
        
    }
    global void execute(Database.BatchableContext bc, List<T_AUTH__c> authList){
        try{
            String providerClsBegin = System.Label.ProviderClosure_Begin_Date;   
            Date providerClsBeginDate = Date.valueOf(providerClsBegin);
            if(Test.isRunningTest()){
                providerClsBeginDate = system.today();
            }
            Set<Id> providerSet = new Set<Id>();
            Set<Id> countySet = new Set<Id>();
            List<T_PROVR_CLOSURE__c> provrClosureList = new List<T_PROVR_CLOSURE__c>();
            Map<string,T_PROVR_CLOSURE__c> provrClosureMap= new Map<string,T_PROVR_CLOSURE__c>();
            Set<string> closureSet= new Set<string>();
            for(T_AUTH__c auth:authList){
                providerSet.add(auth.IDN_PROVR__c); 
                countySet.add(auth.CDE_COUNTY__c); 
            }
            for(T_PROVR_CLOSURE__c eachProvrRec : [select Id, Name, IDN_PROVIDER__c, IDN_PROVIDER__r.Name, CDE_COUNTY__c, CDE_COUNTY__r.Name, DTE_BEGIN_CLOSURE__c
                                                   FROM T_PROVR_CLOSURE__c
                                                   WHERE DTE_BEGIN_CLOSURE__c> 2022-11-06 and IDN_PROVIDER__c in:providerSet and CDE_COUNTY__c in:countySet
                                                   AND IND_ACTIVE__c = true]){
                                                       List<T_PROVR_CLOSURE__c> tempList = new List<T_PROVR_CLOSURE__c>();
                                                       closureSet.add(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c);
                                                       if(provrClosureMap.containsKey(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c+'_'+eachProvrRec.DTE_BEGIN_CLOSURE__c)){
                                                           provrClosureMap.put(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c+'_'+string.valueOf(eachProvrRec.DTE_BEGIN_CLOSURE__c),eachProvrRec);                                           
                                                       }else {
                                                           provrClosureMap.put(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c+'_'+string.valueOf(eachProvrRec.DTE_BEGIN_CLOSURE__c),eachProvrRec);
                                                       }
                                                       providerSet.add(eachProvrRec.IDN_PROVIDER__c);
                                                       countySet.add(eachProvrRec.CDE_COUNTY__c);
                                                       provrClosureList.add(eachProvrRec);
                                                       
                                                   } 
            List<batchsit_t_auth_encmbr__x> encmbrToBeUpdated = new List<batchsit_t_auth_encmbr__x>();
            List<T_AUTH_ENCUMBR__c> recToInsert = new List<T_AUTH_ENCUMBR__c>();
            
            for(T_AUTH__c eachAuth: authList){
                //for each AUTH record get the list of Provider Closures - for that Provider-county
                List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
                if(closureSet.contains(eachAuth.IDN_PROVR__c + '_' +eachAuth.CDE_COUNTY__c)){
                    if(!Test.isRunningTest()){
                        fetchedEncumberence = HerokuService.authEncumbrancefetch(eachAuth.Id);
                    }else{
                        fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =system.today(),idn_auth__c =eachAuth.Id,cde_status_encmbr__c='2',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId=eachAuth.Id,cnt_hour_attnd_actual__c=0));
                    }
                    
                    // system.debug('The fetched encumbrance Size' +fetchedEncumberence.size());
                    for(batchsit_t_auth_encmbr__x ew : fetchedEncumberence){
                        if(provrClosureMap.containsKey(eachAuth.IDN_PROVR__c + '_' +eachAuth.CDE_COUNTY__c+'_'+string.valueOf(ew.dte_Care__c))){
                            T_AUTH_ENCUMBR__c indiObj = new T_AUTH_ENCUMBR__c();
                            system.debug('ew--'+ew);
                            if(ew.cnt_hour_attnd_actual__c<=0 && ew.cde_Status_Encmbr__c !='5' ){
                                system.debug('meet condition--'+ew);
                                if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.cde_status_encmbr__c.isCreateable()){
                                    indiObj.cde_status_encmbr__c = ew.cde_Status_Encmbr__c;
                                }
                                if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.cnt_hour_care__c.isCreateable()){
                                    indiObj.cnt_hour_care__c = Integer.valueof(ew.cnt_Hour_Care__c);
                                }
                                if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.dte_care__c.isCreateable()){
                                    indiObj.dte_care__c = Date.valueof(ew.dte_Care__c);
                                }
                                if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.IDN_AUTH__c.isCreateable()){
                                    indiObj.IDN_AUTH__c = ew.idn_Auth__c;
                                }
                                recToInsert.add(indiObj);
                                ew.cde_Status_Encmbr__c = '5';
                                ew.cnt_Hour_Care__c = 0;
                                system.debug('The Encumbrance Update Value' + ew);
                                //add to the list of Encumbrance Update
                                encmbrToBeUpdated.add(ew);
                            }
                        }
                        
                    }
                }
            }
            if(!recToInsert.isEmpty()){
                system.debug('The Encmbr to be Updated 77 '+recToInsert.size());
                database.insert(recToInsert);
            }
            
            if(!encmbrToBeUpdated.isEmpty()){
                system.debug('The Encmbr to be Updated '+encmbrToBeUpdated.size());
                Database.updateAsync(encmbrToBeUpdated);
            }
            
        }
        catch(Exception e) {
            
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    }    
    
    
    
}