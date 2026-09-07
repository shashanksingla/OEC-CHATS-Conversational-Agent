/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           3/17/2022                                                         
*  @description    Individual batch class  for auto update individual record to sync age with postgres database                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 17-Mar-2022                                                           
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class UpdateIndivOnBirthDayBatchApxCtrl implements 
Database.Batchable<sObject>, Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer birthMonth = System.today().month();
        Integer birthDay = System.today().day();	
        Integer lastWeekMonth = system.today().addDays(-7).month();
        Integer lastWeekDay= system.today().addDays(-7).day();
        system.debug('birthMonth--'+birthMonth);
        system.debug('birthDay--'+birthDay);
        system.debug('lastWeekMonth--'+lastWeekMonth);
        system.debug('lastWeekDay--'+lastWeekDay);
        String queryString ='Select id,Age__c,DTE_DOB__c,LastModifiedDate,BirthDay__c,BirthMonth__c from T_SBSD_INDIV__c Where (BirthMonth__c =:birthMonth or BirthMonth__c =:lastWeekMonth) and (BirthDay__c <=: birthDay and ((BirthDay__c >=: lastWeekDay ) or (BirthDay__c <=: lastWeekDay and BirthMonth__c  !=: lastWeekMonth))) and LastModifiedDate != TODAY ';//and LastModifiedDate != TODAY';
        system.debug('queryString--'+queryString);
        return Database.getQueryLocator(queryString);
    }
    global void execute(Database.BatchableContext bc, List<T_SBSD_INDIV__c> indivList){
        system.debug('indivList--'+indivList);
        List<T_SBSD_INDIV__c> indivListToUpdate = new List<T_SBSD_INDIV__c>();
        ByPass_Validation_Setting__c byPassValidation=[SELECT Is_Batch_Excluded__c FROM ByPass_Validation_Setting__c LIMIT 1];
        byPassValidation.Is_Batch_Excluded__c = TRUE;
        Triggers_On_Off_Settings__c triggerService =[select id,Active__c from Triggers_On_Off_Settings__c where name ='IndividualTrigger' LIMIT 1];
            triggerService.Active__c = false;
        GenericDMLHandler.updateRecords(new List<SObject>{byPassValidation},new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
                        GenericDMLHandler.updateRecords(new List<SObject>{triggerService},new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});

        for(T_SBSD_INDIV__c indivObj:indivList){
            system.debug('indivObj--'+indivObj);
            if(indivObj.LastModifiedDate != system.today()){
                indivListToUpdate.add(indivObj);
            }
        }
        system.debug('indivListToUpdate--'+indivListToUpdate);
        if(indivListToUpdate.size()>0){
            GenericDMLHandler.updateRecords(indivListToUpdate,new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
            byPassValidation.Is_Batch_Excluded__c = false;
             triggerService.Active__c = true;
            GenericDMLHandler.updateRecords(new List<SObject>{byPassValidation},new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});
            GenericDMLHandler.updateRecords(new List<SObject>{triggerService},new Map<String,Object>{'Method__c'=>'syncIndivAgeWithPostgres','Class__c'=>'UpdateIndivOnBirthDayBatch'});


        }
        
    }
    global void finish(Database.BatchableContext bc){
        system.debug('individuals have been update to sync age to postgres');
    }
    
}