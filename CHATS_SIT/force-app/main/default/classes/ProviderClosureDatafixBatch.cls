/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/24/2022                                                         
*  @description    Adjustment batch class for datafix                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 244-May-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class ProviderClosureDatafixBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Set<Id> providerId = new Set<Id>();
    public Set<String> providerCountySet = new Set<String>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        Date createdBeforeDateFilter = Date.newInstance(2022, 09, 25); // this is referred in below dynamic query
        String status ='2';
        String queryStr ='SELECT ID,Name, IND_ACTIVE__c,TXT_COMMENTS__c,CDE_COUNTY__c,CreatedById,createdDate,DTE_BEGIN_CLOSURE__c, IDN_PROVIDER__c FROM T_PROVR_CLOSURE__c Where CDE_COUNTY__c =null and IND_ACTIVE__c = true and DTE_BEGIN_CLOSURE__c >=:createdBeforeDateFilter and createdDate<=:createdBeforeDateFilter ';
        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_PROVR_CLOSURE__c> providerClosureList){
        try{
            List<T_PROVR_CLOSURE__c> providerClsLstToInsert=  new List<T_PROVR_CLOSURE__c>();
            List<T_PROVR_CLOSURE__c> providerClsLstToUpdate=  new List<T_PROVR_CLOSURE__c>();
            Map<id,List<T_PROVR_FISCAL_AGREMENT__c>> providerFiscalMap = new Map<id,List<T_PROVR_FISCAL_AGREMENT__c>>();
            for(T_PROVR_CLOSURE__c cls :providerClosureList){
                providerId.add(cls.IDN_PROVIDER__c);
            }
            for(T_PROVR_FISCAL_AGREMENT__c prodFis :[select id,DTE_BEGIN_AGRMT__c,CDE_COUNTY__c,ID_SERVICE__c,DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__c in:providerId and CDE_TYPE_STATUS__c ='OPN']){
                String key = prodFis.ID_SERVICE__c+'_'+prodFis.CDE_COUNTY__c;
                if(providerFiscalMap.containsKey(prodFis.ID_SERVICE__c)){
                    List<T_PROVR_FISCAL_AGREMENT__c> temp = providerFiscalMap.get(prodFis.ID_SERVICE__c);
                    temp.add(prodFis);
                    providerFiscalMap.put(prodFis.ID_SERVICE__c,temp);                    
                }else{
                    providerFiscalMap.put(prodFis.ID_SERVICE__c,new List<T_PROVR_FISCAL_AGREMENT__c>{prodFis});
                }
            }
            for(T_PROVR_CLOSURE__c cls :providerClosureList){
                if(providerFiscalMap.containskey(cls.IDN_PROVIDER__c)){
                    Integer i=0;
                    for(T_PROVR_FISCAL_AGREMENT__c fiscal :providerFiscalMap.get(cls.IDN_PROVIDER__c)){
                        if(fiscal.DTE_BEGIN_AGRMT__c <=cls.DTE_BEGIN_CLOSURE__c && fiscal.DTE_END_AGRMT__c >=cls.DTE_BEGIN_CLOSURE__c){
                            if(i==0){
                                cls.CDE_COUNTY__c=fiscal.CDE_COUNTY__c; 
                                providerClsLstToUpdate.add(cls);
                                i++;
                            }else{
                                T_PROVR_CLOSURE__c newCls = cls.clone(false, true, false, false); 
                                newCls.CDE_COUNTY__c =fiscal.CDE_COUNTY__c;
                                providerClsLstToInsert.add(newCls);
                                i++;
                            }
                        }
                        
                        
                    }
                }
            }
            system.debug('providerClsLstToInsert--'+providerClsLstToInsert);
            system.debug('providerClsLstToUpdate--'+providerClsLstToUpdate);
            
            if(providerClsLstToUpdate != null && providerClsLstToUpdate.size()>0){
                GenericDMLHandler.updateRecords(providerClsLstToUpdate,new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
            }
            if(providerClsLstToInsert != null && providerClsLstToInsert.size()>0){
                GenericDMLHandler.insertRecords(providerClsLstToInsert,new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
            }
          
            
        }
        catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'ProviderClosureDatafixBatch';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'ProviderClosureDatafixBatch  for adjustment'+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    }    
}