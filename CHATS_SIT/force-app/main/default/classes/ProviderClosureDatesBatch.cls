/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           4/18/2023                                                         
*  @description    Batch class for updating provider closure dates on FA.
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 4/18/2023
*  * Author: Shashank Singla                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class ProviderClosureDatesBatch implements 
Database.Batchable<sObject>, Database.Stateful,Schedulable {
    
    public Set<Id> providerId = new Set<Id>();
    public Set<String> providerCountySet = new Set<String>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    
    global void execute(SchedulableContext ctx) {
        database.executebatch(new ProviderClosureDatesBatch());
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String clsStatus ='CLS';
        String queryStr ='select id,(select id,DTE_PROVD_CLS__c,CDE_COUNTY__c from Provider_Fiscal_Agreements__r where CDE_TYPE_STATUS__c!=:clsStatus),(select id,DTE_BEGIN_CLOSURE__c,CDE_COUNTY__c from Provider_Closure__r where IND_ACTIVE__c=true) from T_CHATS_PROVR_STATUS__c where id in (select ID_SERVICE__c from T_PROVR_FISCAL_AGREMENT__c where CDE_TYPE_STATUS__c!=:clsStatus) and id in (select IDN_PROVIDER__c from T_PROVR_CLOSURE__c where IND_ACTIVE__c=true)';
        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_CHATS_PROVR_STATUS__c> providers){
        try{
            ByPass_Validation_Setting__c byPassValidation=[SELECT Is_Batch_Excluded__c FROM ByPass_Validation_Setting__c LIMIT 1];
            byPassValidation.Is_Batch_Excluded__c = TRUE;
            GenericDMLHandler.updateRecords(new List<SObject>{byPassValidation},new Map<String,Object>{'Method__c'=>'executeMethod','Class__c'=>'ProviderClosureDatesBatch'});
            Date pymtStartDate = Date.Today()-13 ;
            Date pymtEndDate = Date.Today()-7;
            system.debug('pymtStartDate'+pymtStartDate+'pymtEndDate'+pymtEndDate);
            List<T_PROVR_FISCAL_AGREMENT__c> agreementsToUpdate = new List<T_PROVR_FISCAL_AGREMENT__c>();
            for(T_CHATS_PROVR_STATUS__c prov : providers){
                Map<Id,String> countyVsDates = new Map<Id,String>();
                for(T_PROVR_CLOSURE__c provClos : prov.Provider_Closure__r){
                    String closeDates = '';
                    if(provClos.DTE_BEGIN_CLOSURE__c >=Date.valueOf(pymtStartDate) && provClos.DTE_BEGIN_CLOSURE__c<=Date.valueOf(pymtEndDate)){
                        if(countyVsDates.containsKey(provClos.CDE_COUNTY__c)){
                            closeDates = countyVsDates.get(provClos.CDE_COUNTY__c);
                        }
                        closeDates += provClos.DTE_BEGIN_CLOSURE__c.format()+';';
                        countyVsDates.put(provClos.CDE_COUNTY__c,closeDates);
                    }
                }
                if(countyVsDates.size()>0){
                    for(T_PROVR_FISCAL_AGREMENT__c agreement : prov.Provider_Fiscal_Agreements__r){
                        if(countyVsDates.containsKey(agreement.CDE_COUNTY__c)){
                            agreement.DTE_PROVD_CLS__c = countyVsDates.get(agreement.CDE_COUNTY__c);
                            agreementsToUpdate.add(agreement);
                            
                        }
                    }
                }
            }
            GenericDMLHandler.updateRecords(agreementsToUpdate,new Map<String,Object>{'Method__c'=>'executeMethod','Class__c'=>'ProviderClosureDatesBatch'});
            byPassValidation.Is_Batch_Excluded__c = false;
            GenericDMLHandler.updateRecords(new List<SObject>{byPassValidation},new Map<String,Object>{'Method__c'=>'executeMethod','Class__c'=>'ProviderClosureDatesBatch'});
        }
        catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'ProviderClosureDatesBatch';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'ProviderClosureDatesBatch :- '+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
    global void finish(Database.BatchableContext bc){
        if(errors.size()>0){
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'ProviderClosureDatesBatch'});
        }
    }    
}