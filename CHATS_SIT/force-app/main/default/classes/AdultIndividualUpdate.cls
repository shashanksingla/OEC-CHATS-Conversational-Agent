//Commenting out as the batch is no longer in use
global with sharing class AdultIndividualUpdate{
    /*global List<Exception> batchErrors = new List<Exception>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM T_SBSD_INDIV__c where id not in (select idn_client__c from t_sbsd_case_indiv__c where Individual_Status__c ='Child' and (DTE_END_EFFV__c=null or DTE_END_EFFV__c >today)) and id in (select IDN_CLIENT__c from t_sbsd_case_indiv__c where (Individual_Status__c ='PC' or Individual_Status__c ='AC') and (DTE_END_EFFV__c=null or DTE_END_EFFV__c >today))]);
    }

    global void execute(Database.BatchableContext BC, List<T_SBSD_INDIV__c> scope){
		Set<Id> indAdult = new Set<Id>();
        List<T_INDIV_VERIF__c> indivVerifToDelete = new List<T_INDIV_VERIF__c>();
        List<T_SBSD_INDIV_INFO__c> indivInfoToUpdate = new List<T_SBSD_INDIV_INFO__c>();
        List<T_SBSD_INDIV__c> indivToUpdate = new List<T_SBSD_INDIV__c>();
        List<String> indivFieldsToUpdate = new List<String>{'CDE_GENDER__c','CDE_ATTENDING_SCHOOL1__c','IND_CHILD_IDEA__c','IND_CHILD_SCREEN__c','CDE_RACE__c','CDE_ETNCTY__c','IND_CDE_TYPE_VERIF_DOB__c','CDE_SOURCE_VRFYD_DOB__c','CDE_SOURCE_VRFYD_CITIZEN__c'};
        for(T_SBSD_INDIV__c indiv : scope){
            indAdult.add(indiv.Id);
        }
       	for(T_SBSD_INDIV_INFO__c indivInfo : [SELECT Id,IDN_CLIENT__c,CDE_VALUE_INFO_INDIV__c, (SELECT Id FROM Individual_Verification__r WHERE CDE_TYPE_INFO_INDIV__c = 'CS') 
                                                FROM T_SBSD_INDIV_INFO__c WHERE IDN_CLIENT__c IN :indAdult AND CDE_TYPE_INFO_INDIV__c = 'CS']){
            if(indivInfo.CDE_VALUE_INFO_INDIV__c != 'N/A-adult caretaker'){
                indivInfo.CDE_VALUE_INFO_INDIV__c = 'N/A-adult caretaker';
                indivInfoToUpdate.add(indivInfo);
            }
            if(indivInfo.Individual_Verification__r!=null && indivInfo.Individual_Verification__r.size()>0){
                indivVerifToDelete.addAll(indivInfo.Individual_Verification__r);
            }
        }
        
        List<T_SBSD_INDIV__c> indivList = [SELECT Id, CDE_GENDER__c,CDE_ATTENDING_SCHOOL1__c, IND_CHILD_IDEA__c, IND_CHILD_SCREEN__c, CDE_RACE__c, CDE_ETNCTY__c, IND_CDE_TYPE_VERIF_DOB__c, CDE_SOURCE_VRFYD_DOB__c, CDE_SOURCE_VRFYD_CITIZEN__c FROM T_SBSD_INDIV__c WHERE Id IN :indAdult];
        for(T_SBSD_INDIV__c indiv : indivList){
            indiv.CDE_GENDER__c = (indiv.CDE_GENDER__c != '3') ? '3' : indiv.CDE_GENDER__c;
            indiv.CDE_ATTENDING_SCHOOL1__c = (indiv.CDE_ATTENDING_SCHOOL1__c != 'Unknown') ? 'Unknown' : indiv.CDE_ATTENDING_SCHOOL1__c;
            indiv.IND_CHILD_IDEA__c = (indiv.IND_CHILD_IDEA__c != 'N') ? 'N' : indiv.IND_CHILD_IDEA__c;
            indiv.IND_CHILD_SCREEN__c = (indiv.IND_CHILD_SCREEN__c != 'N') ? 'N' : indiv.IND_CHILD_SCREEN__c;
            indiv.CDE_RACE__c = (indiv.CDE_RACE__c != '6') ? '6' : indiv.CDE_RACE__c; 
            indiv.CDE_ETNCTY__c = (indiv.CDE_ETNCTY__c != 'U') ? 'U' : indiv.CDE_ETNCTY__c;
            indiv.IND_CDE_TYPE_VERIF_DOB__c = (indiv.IND_CDE_TYPE_VERIF_DOB__c != 'N/A-adult caretaker') ? 'N/A-adult caretaker' : indiv.IND_CDE_TYPE_VERIF_DOB__c;
            indiv.CDE_SOURCE_VRFYD_DOB__c = (indiv.CDE_SOURCE_VRFYD_DOB__c != '' || indiv.CDE_SOURCE_VRFYD_DOB__c != null) ? '' : indiv.CDE_SOURCE_VRFYD_DOB__c;
            indiv.CDE_SOURCE_VRFYD_CITIZEN__c = (indiv.CDE_SOURCE_VRFYD_CITIZEN__c != '' || indiv.CDE_SOURCE_VRFYD_CITIZEN__c != null) ? '' : indiv.CDE_SOURCE_VRFYD_CITIZEN__c; 
            indiv.Bypass_On__c = System.now();
            indivToUpdate.add(indiv);
        }
        try {
            if(!indivVerifToDelete.isEmpty()){
                GenericDMLHandler.deleteRecords(indivVerifToDelete, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'AdultIndividualUpdate'});
            }
            if(!indivInfoToUpdate.isEmpty()){
                GenericDMLHandler.updateRecords(indivInfoToUpdate, false, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'AdultIndividualUpdate'});
            }
            if(!indivToUpdate.isEmpty()){
                IndividualServices.disableTrigger = true;
                GenericDMLHandler.updateRecords(indivToUpdate, false, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'AdultIndividualUpdate'});
                IndividualServices.disableTrigger = false;
            }
        } catch(DMLException ex) {
            IndividualServices.disableTrigger = false;
            batchErrors.add(ex);
        } catch(Exception e) {
            IndividualServices.disableTrigger = false;
            batchErrors.add(e);
        }
    }

    global void finish(Database.BatchableContext BC){
        if(!batchErrors.isEmpty()){
            Map<String,Object> methodInfo = new Map<String,Object>{'Method__c' => 'execute','Class__c' => 'AdultIndividualUpdate'};
            for(Exception e : batchErrors){
                ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
            }
        }
    }*/
}