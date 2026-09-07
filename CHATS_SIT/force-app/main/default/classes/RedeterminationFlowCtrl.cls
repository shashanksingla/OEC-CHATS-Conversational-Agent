public with sharing class RedeterminationFlowCtrl {
    final static String INACTIVE = 'INA';
    
    @AuraEnabled
    public static LightningServerResponse updateCase(List<SObject> caseRecs){
        System.debug('caseRecs:'+caseRecs);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        List<APXFieldValidationError> lstAPXFieldValidationError; 
        Savepoint sp = Database.setSavepoint();
        List<SObject> lstRecordsToBeUpdated = new List<SObject>();
        List<SObject> lstEmplmtIncomeRecordsToBeUpdated = new List<SObject>();
        List<SObject> lstRecordsToBeInserted = new List<SObject>();
        List<Database.SaveResult> lstSaveResult = new List<Database.SaveResult>();
        Map<Id,Id> individualIds = new Map<Id,Id>();
        //Set<Id> individualIds = new Set<Id>();
        Set<Id> employmentIncomeIds = new Set<Id>();
        Map<Id,T_SBSD_CASE__c> mapIdToCaseRecords = new Map<Id,T_SBSD_CASE__c>();
        
        lstRecordsToBeUpdated.addAll(caseRecs);
        Set<Id> caseIds = new Set<Id>();
        for(SObject sOb:caseRecs){
            if(sOb.get('Id')!=null){
                caseIds.add((Id)sOb.get('Id'));
                mapIdToCaseRecords.put((Id)sOb.get('Id'),(T_SBSD_CASE__c)sOb);
            }
        }
        System.debug('caseIds:'+caseIds);
        for(T_SBSD_CASE__c cas:[Select Id,Name,DTE_RCVD_PACKET_REDET__c,(SELECT CDE_MODE_CASE__c,CDE_STATUS_CASE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,Id,
                                                                         IDN_CASE__c, CreatedDate FROM T_SBSD_CASE10__r WHERE (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY) ORDER BY DTE_BEGIN_EFFV__c DESC NULLS FIRST),
                                (SELECT IDN_CLIENT__c FROM CaseIndividuals__r WHERE DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c=null OR DTE_END_EFFV__c>TODAY))
                                 from T_SBSD_CASE__c where Id IN :caseIds]){
                                    
            System.debug('cas:'+cas);
            if(!cas.T_SBSD_CASE10__r.isEmpty()){
                System.debug('cas.T_SBSD_CASE10__r:'+cas.T_SBSD_CASE10__r);
                if(cas.DTE_RCVD_PACKET_REDET__c==mapIdToCaseRecords.get(cas.Id).DTE_RCVD_PACKET_REDET__c 
                   && cas.T_SBSD_CASE10__r.get(0).CDE_MODE_CASE__c=='RED' 
                   && date.newinstance(cas.T_SBSD_CASE10__r.get(0).CreatedDate.year(), cas.T_SBSD_CASE10__r.get(0).CreatedDate.month(), cas.T_SBSD_CASE10__r.get(0).CreatedDate.day())==System.today()){
                       isSuccessful = false;
                   }else{
                       T_SBSD_CASE_STATUS_MODE__c sbsdCaseStaMod =  new T_SBSD_CASE_STATUS_MODE__c();
                       sbsdCaseStaMod.CDE_MODE_CASE__c= 'RED';
                       sbsdCaseStaMod.DTE_BEGIN_EFFV__c= date.today();
                       sbsdCaseStaMod.CDE_STATUS_CASE__c = cas.T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c;
                       sbsdCaseStaMod.IDN_CASE__c = cas.id;
                       sbsdCaseStaMod.CDE_ELIGTY_CONTNUS__c = cas.T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c=='REO'?'Y':'';//CCCAP-13725 To enable eligibility to use SMI during reopen redetermination and income result to pass
                       lstRecordsToBeInserted.add(sbsdCaseStaMod);  
                       //SJ: CHATS-6763 - Added logic to populate end date for all effective case status mode]
                       for(T_SBSD_CASE_STATUS_MODE__c eachEffectiveCaseStatusMode:cas.T_SBSD_CASE10__r){
                           if(eachEffectiveCaseStatusMode.DTE_END_EFFV__c == null){
                               eachEffectiveCaseStatusMode.DTE_END_EFFV__c = date.today()-1; 
                           }
                           lstRecordsToBeUpdated.add(eachEffectiveCaseStatusMode);    
                       }
                   }
            }
            for(T_SBSD_CASE_INDIV__c caseIndiv:cas.CaseIndividuals__r){
                individualIds.put(caseIndiv.IDN_CLIENT__c,cas.Id);
            }
        }
        if(isSuccessful){
            Map<Id, T_EMPLMT_PAY_STUB__c> payStubMap = new Map<Id, T_EMPLMT_PAY_STUB__c>();
            for(T_SBSD_INDIV_EMPLMT__c employment:[SELECT Id, Name, IDN_CLIENT__c, DTE_END_EFFV__c, (SELECT Id, Name, CDE_STATUS__c FROM T_SBSD_INDIV_EMPLMT1__r) FROM T_SBSD_INDIV_EMPLMT__c WHERE IDN_CLIENT__c IN: individualIds.keyset() and IDN_CASE__c IN: caseIds
                                                  								AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY)]){
                for(T_EMPLMT_INCOME__c employmentIncome : employment.T_SBSD_INDIV_EMPLMT1__r){
                    employmentIncomeIds.add(employmentIncome.Id);
                    if(employmentIncome.CDE_STATUS__c != INACTIVE){
                        employmentIncome.CDE_STATUS__c = INACTIVE;
                        lstEmplmtIncomeRecordsToBeUpdated.add(employmentIncome);
                    }
                }
            }
            for(T_EMPLMT_PAY_STUB__c payStub : [SELECT Id, Name, CDE_STATUS__c, IDN_EMPLMT_INCOME__r.IDN_EMPLMT_INDIV__r.IDN_CLIENT__c, IDN_EMPLMT_INCOME__r.Name FROM T_EMPLMT_PAY_STUB__c WHERE IDN_EMPLMT_INCOME__c IN:employmentIncomeIds AND CDE_STATUS__c!=:INACTIVE]){
                payStub.CDE_STATUS__c = INACTIVE;
                payStub.bypassValidations__c = System.now(); // Setting timestamp to bypass validation rule CCCAP-15586
                lstEmplmtIncomeRecordsToBeUpdated.add(payStub);
                payStubMap.put(payStub.Id, payStub);
            }
            
            System.debug('lstRecordsToBeUpdated:'+lstRecordsToBeUpdated);
            System.debug('lstRecordsToBeInserted:'+lstRecordsToBeInserted);
            System.debug('lstEmplmtIncomeRecordsToBeUpdated:'+lstEmplmtIncomeRecordsToBeUpdated);
            
            List<Database.SaveResult> saveResults = Database.update(lstEmplmtIncomeRecordsToBeUpdated, false);
            List<String> dmlErrorMessages = new List<String>();
            for(Integer i = 0; i < saveResults.size(); i++){
                if(!saveResults[i].isSuccess()){
                    sObject obj = lstEmplmtIncomeRecordsToBeUpdated[i];
                    String objName = obj.getSObjectType().getDescribe().getName();                    
                    List<Database.Error> saveResultErrors = saveResults[i].getErrors();
                    for(Database.Error err : saveResultErrors){
                        String msg = err.getMessage();
                        if(objName == 'T_EMPLMT_INCOME__c'){
                            msg = 'Employment Income '+obj.get('Name')+ ': '+msg;
                        }
                        if(objName == 'T_EMPLMT_PAY_STUB__c'){
                            msg = 'Employment Income '+payStubMap.get(obj.Id).IDN_EMPLMT_INCOME__r.Name+ ', Pay Stub '+ obj.get('Name') +': '+msg;
                        }
                        dmlErrorMessages.add(msg);
                    }
                }
            }
            lstSaveResult.addAll(Database.update(lstRecordsToBeUpdated, false));
            lstSaveResult.addAll(Database.insert(lstRecordsToBeInserted, false));
            System.debug('lstSaveResult:'+lstSaveResult);
            
            lstRecordsToBeUpdated.addAll(lstRecordsToBeInserted);
            
            lstAPXFieldValidationError = CrudResponseApxCtrl.getCrudResponseFromSaveResults(lstRecordsToBeUpdated, lstSaveResult);
            if(lstAPXFieldValidationError.isEmpty() && dmlErrorMessages.isEmpty()){
                objectData.put('upsertedRecords',lstRecordsToBeUpdated);
                message = Label.Record_has_been_successfully_updated;
                isSuccessful = true;
            }else{
                objectData.put('upsertedRecords',lstRecordsToBeUpdated);
                objectData.put('dmlErrorMessages', dmlErrorMessages);
                message = Label.ERRORS_ON_THIS_PAGE;
                isSuccessful = false;
                // Rollback to the savepoint
                Database.rollback(sp);
                ExceptionLoggingServices.captureExceptionLog(lstSaveResult, lstRecordsToBeUpdated, new Map<String,Object>{'Class__c'=>'RedeterminationFlowCtrl','Method__c'=>'updateCase'});
            }
        }else{
            message = System.Label.CANNOT_ACCESS_REDETERMINATION_FLOW;
        }
        return new LightningServerResponse(isSuccessful,message,objectData,lstAPXFieldValidationError);
  }
}