/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/09/2023                                                         
*  @description    Case batch class for tracking missing information letter and creating eligibility run data                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 9-May-2023                                                            
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class CaseEligibilityConfirmBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public List<T_SBSD_CASE__c> caseLstToBeUpdated = new List<T_SBSD_CASE__c>();
    public List<Task> taskT133ToBeInserted = new List<Task>();
    public List<String> caseIds = new List<String>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    public static final string OPEN='OPN';
    public static final string PENDING='PEN';
    public static final string INTAKE='INT';
    public static final string REDETERMINATION='RED';
    public static final string REOPEN ='REO';
    public static final String CONFIRMED = Label.CFM;
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    public  CaseEligibilityConfirmBatch(List<String> caseIds){
        this.caseIds = caseIds;
        system.debug('caseIds--'+caseIds);
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String letterStatus ='OPEN';
        String recordId='a1m8B000000tdAkQAI';//'a1m2M0000040sdHQAQ';
        system.debug('caseIds--'+caseIds);
        String queryStr ='SELECT ID,OwnerId,Name,IDN_EXTNL__c, IND_MissingInfo_Status__c,CDE_COUNTY__c,DTE_REDET_MODE_CASE__c,DTE_CHGD_LAST_DATA_ELIGTY__c,(SELECT ID,DTE_BEGIN_EFFEV__c FROM CBMS_Additional_Information__r ORDER BY DTE_BEGIN_EFFEV__c DESC NULLS FIRST LIMIT 1),';
        queryStr += 'DTE_REDET_LAST__c, DTE_REOPEN_LATEST__c,(SELECT ID,CDE_MODE_CASE__c,CDE_STATUS_CASE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c FROM T_SBSD_CASE10__r ORDER BY DTE_BEGIN_EFFV__c DESC NULLS FIRST LIMIT 1) FROM T_SBSD_CASE__c Where id IN:caseIds and IND_MissingInfo_Status__c=:letterStatus';
        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_SBSD_CASE__c> caseList){
        try{
            String programName='TF';
            Map<String, Object> objectData = new map<String, Object>();
            list<String> caseIds = new list<String>();
            List<T_SBSD_CASE__c> caseLstToUpdate=  new List<T_SBSD_CASE__c>();
            map<Id, T_SBSD_CASE__c> caseToIndividualMap = new map<Id, T_SBSD_CASE__c>();
            String caseId;
            List<String> params = new List<String>();
            String caseName;
            String eligRunSFID;
            String runId;
            system.debug('caseList--'+caseList);
            if(caseList != null && caseList.size()>0){
                 for(T_SBSD_CASE__c cs : caseList){
                    if((cs.T_SBSD_CASE10__r.size() > 0 && cs.T_SBSD_CASE10__r[0].CDE_MODE_CASE__c == INTAKE || cs.T_SBSD_CASE10__r[0].CDE_MODE_CASE__c == REDETERMINATION)){
                        caseId = cs.Id;
                        if((cs.CBMS_Additional_Information__r.size() > 0)){
                            programName='TF';
                        }else{
                            programName='LI';
                        }
                    }
                } 
                List<batchsit_t_eligty_run__x> eligrunList =  QueryExternalObjects.query([SELECT Id, dte_run_eligty__c, idn_case__c, idn_case__r.IND_CHGD_DATA_ELIGTY__c, idn_run_eligty__c, 
                                                                cde_eligty_cfmd__c, dte_redet_prpsd__c, dte_redet_ovrd__c, cde_date_redet_ovrd__c, txt_cmt_ovrd__c, createddate__c                                                                 
                                                                FROM batchsit_t_eligty_run__x WHERE idn_case__c =: caseList[0].IDN_EXTNL__c AND cde_eligty_cfmd__c = 'NCM' and dte_run_eligty__c=today ORDER BY dte_run_eligty__c DESC limit 1]);
                for(batchsit_t_eligty_run__x eligRun : eligrunList){
                    eligRunSFID =eligRun.Id;
                    if(Test.isRunningTest()){
                        eligRunSFID = '122334';
                    }
                    runId=String.valueOf(eligRun.idn_run_eligty__c);
                }
                system.debug('eligRunSFID--'+eligRunSFID);
                system.debug('programName--'+programName);
                system.debug('eligRunSFID--'+eligRunSFID);
                if(eligRunSFID !=null && runId!= null ){                    
                    LightningServerResponse validateConfirmResp = EligibilityFlowCmpApxCtrl.validateConfirmEligibility(eligRunSFID,programName);
                    if(validateConfirmResp != null && validateConfirmResp.isSuccessful){
                        system.debug('caseIds--'+caseIds);
                        List<String> confirmPageMessages = (List<String>) JSON.deserialize(JSON.serialize(validateConfirmResp.objectData.get('assessPageMessages')), List<String>.class);
                        LightningServerResponse confirmResp = HerokuService.doCallBREConfirmEligibility(caseList[0].Name,runId);
                        system.debug('confirmResp---'+confirmResp);
                        if(confirmResp != null && confirmResp.isSuccessful){
                            caseList[0].IND_MissingInfo_Status__c='PROCESSED';
                            caseList[0].IND_CHGD_DATA_ELIGTY__c = false;
                            caseLstToBeUpdated.add(caseList[0]);
                            //Task T133 creation logic
                            Task tsk = new Task();
                            tsk.Subject = System.Label.Task_T133_Subject;
                            tsk.WhatId = caseList[0].Id;
                            tsk.OwnerId = caseList[0].OwnerId;
                            tsk.Status = 'New';
                            tsk.Priority = 'Normal';
                            tsk.ActivityDate = system.today().addDays(2);
                            tsk.Description = 'Missing information has not been received for  '+caseList[0].Name + '('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SBSD_CASE__c/'+caseList[0].Id
                                +'/view ) '+' Please issue the CR115 Ineligibility Notice to notify the family that they are ineligible.';
                            taskT133ToBeInserted.add(tsk);
                            system.debug('tsk---'+tsk);
                            //End
                        }else{
                            system.debug('else--2-');
                            caseList[0].IND_MissingInfo_Status__c='FAILED';
                            caseLstToBeUpdated.add(caseList[0]);
                        }
                    }else{
                        system.debug('else---1');
                        caseList[0].IND_MissingInfo_Status__c='FAILED';
                        caseLstToBeUpdated.add(caseList[0]);
                    } 
                }
                
            }
            
            
            
        }
        catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'CaseMissingInfoTrackingBatch';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'CaseMissingInfoTrackingBatch  for case--'+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
    global void finish(Database.BatchableContext bc){
        if(caseLstToBeUpdated != null && caseLstToBeUpdated.size()>0){
            GenericDMLHandler.updateRecords(caseLstToBeUpdated, false, null);
        }
        system.debug('taskT133ToBeInserted--'+taskT133ToBeInserted);
        if(taskT133ToBeInserted != null && taskT133ToBeInserted.size()>0){
            GenericDMLHandler.insertRecords(taskT133ToBeInserted,false,null);
        }
    }    
}