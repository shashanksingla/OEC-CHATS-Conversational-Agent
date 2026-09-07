/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           
*  @description    CaseServices
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 
*  * Author: Shubham Jain
*  * Description: Initial version                                                 
*  * Deletes all the child CAT1 tables of Case.
*********************************************************************************************/
public with sharing class CaseServices {
    public static void deleteChildRecords(List<T_SBSD_CASE__c> cases){
        List<SObject> recordsToBeDeleted = new List<SObject>();
        List<SObject> recordsToBeDeleted2 = new List<SObject>();
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        List<SObject> childIdsToDeleteGrandChild = new List<SObject>();
        for(T_SBSD_CASE__c caseRec:[SELECT Id, Name,
                                    (SELECT Id FROM Application_Process_Queues__r),
                                    (SELECT Id FROM Case__r),
                                    (SELECT Id FROM CaseIndividuals__r),
                                    (SELECT Id FROM CBMS_Additional_Information__r),
                                    (SELECT Id FROM Correspondence_Request__r),
                                    (SELECT Id FROM CW_Additional_Information__r),
                                    (SELECT Id FROM Tasks),
                                    (SELECT Id FROM T_APPEAL__r),
                                    (SELECT Id FROM T_AUTH__r),
                                    (SELECT Id FROM T_COPAY_DELINQC__r),
                                    (SELECT Id FROM T_SBSD_CASE10__r),
                                    (SELECT Id FROM T_SBSD_CASE114__r),
                                    (SELECT Id FROM T_SBSD_CASE12__r),
                                    (SELECT Id FROM T_SBSD_CASE13__r),
                                    (SELECT Id FROM T_SBSD_CASE14__r),
                                    (SELECT Id FROM T_SBSD_CASE3__r),
                                    (SELECT Id FROM T_SBSD_CASE4__r),
                                    (SELECT Id FROM T_SBSD_CASE7__r)
                                    FROM T_SBSD_CASE__c WHERE Id IN:cases WITH SECURITY_ENFORCED]){
                                        recordsToBeDeleted.addAll(caseRec.Application_Process_Queues__r);
                                        recordsToBeDeleted.addAll(caseRec.Case__r);
                                        recordsToBeDeleted.addAll(caseRec.CaseIndividuals__r);
                                        if(!caseRec.CaseIndividuals__r.isEmpty()){
                                           childIdsToDeleteGrandChild.addAll(caseRec.CaseIndividuals__r);
                                        }
                                        recordsToBeDeleted.addAll(caseRec.CBMS_Additional_Information__r);
                                        recordsToBeDeleted.addAll(caseRec.Tasks);
                                        recordsToBeDeleted.addAll(caseRec.Correspondence_Request__r);
                                        recordsToBeDeleted.addAll(caseRec.CW_Additional_Information__r);
                                        recordsToBeDeleted.addAll(caseRec.T_APPEAL__r);
                                        if(!caseRec.T_APPEAL__r.isEmpty()){
                                           childIdsToDeleteGrandChild.addAll(caseRec.T_APPEAL__r);
                                        }
                                        recordsToBeDeleted.addAll(caseRec.T_AUTH__r);
                                        if(!caseRec.T_AUTH__r.isEmpty()){
                                           childIdsToDeleteGrandChild.addAll(caseRec.T_AUTH__r);
                                        }
                                        recordsToBeDeleted2.addAll(caseRec.T_COPAY_DELINQC__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE10__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE114__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE12__r);
                                        if(!caseRec.T_SBSD_CASE12__r.isEmpty()){
                                            childIdsToDeleteGrandChild.addAll(caseRec.T_SBSD_CASE12__r);
                                        }
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE13__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE14__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE3__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE4__r);
                                        recordsToBeDeleted2.addAll(caseRec.T_SBSD_CASE7__r);

                                        //added for CCCAP-12575
                                        batchsit_t_pos_trans_queue_ats__x atsRecord = new batchsit_t_pos_trans_queue_ats__x();
                                        atsRecord.CDE_TYPE_TRANS__c 	='11';
                                        atsRecord.CDE_STATUS_TRANS__c 	= '1';
                                        atsRecord.IDN_CASE__c 			= caseRec.Name;
                                        lstATSRecords.add(atsRecord);
                                    }
        
        List<Id> recordIdsToBeDeleted = new List<String>();

        if(!childIdsToDeleteGrandChild.isEmpty()){
            for(T_INDIV_CAT_RQ__c ccr:[SELECT Id FROM T_INDIV_CAT_RQ__c WHERE IDN_CASE_INDIV__c IN:childIdsToDeleteGrandChild WITH SECURITY_ENFORCED]){
                recordIdsToBeDeleted.add(ccr.id);
            }
            for(T_SBSD_CASE_INDIV_ROLE__c cir:[SELECT Id FROM T_SBSD_CASE_INDIV_ROLE__c WHERE IDN_CASE_INDIV__c IN:childIdsToDeleteGrandChild WITH SECURITY_ENFORCED]){
                recordIdsToBeDeleted.add(cir.id);
            }
            for(T_PRIM_ACTV_CNTR__c pac:[SELECT Id FROM T_PRIM_ACTV_CNTR__c WHERE IDN_PRIM_ACTV__c IN:childIdsToDeleteGrandChild WITH SECURITY_ENFORCED]){
                recordIdsToBeDeleted.add(pac.id);
            }
            for(T_INDIV_DISQLN__c indivDis:[SELECT Id FROM T_INDIV_DISQLN__c WHERE IDN_APPEAL__c IN:childIdsToDeleteGrandChild WITH SECURITY_ENFORCED]){
                recordIdsToBeDeleted.add(indivDis.id);
            }
            for(T_DOC_RQ__c doc:[SELECT Id FROM T_DOC_RQ__c WHERE IDN_AUTH__c IN: childIdsToDeleteGrandChild AND IDN_CASE__c NOT IN: cases WITH SECURITY_ENFORCED]){
                recordIdsToBeDeleted.add(doc.id);
            }
            System.debug('recordIdsToBeDeleted:'+recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Class__c'=>'CaseServices','Method__c'=>'deleteChildRecords'});
            recordIdsToBeDeleted.clear();
        }

        System.debug('recordsToBeDeleted:'+recordsToBeDeleted);
        if(!recordsToBeDeleted.isEmpty()){
            recordsToBeDeleted.sort();
            for(SObject sOb:recordsToBeDeleted){
                recordIdsToBeDeleted.add((Id)sOb.get('Id'));
            }
            System.debug('recordIdsToBeDeleted:'+recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Class__c'=>'CaseServices','Method__c'=>'deleteChildRecords'});
            recordIdsToBeDeleted.clear();
        }
        System.debug('recordsToBeDeleted2:'+recordsToBeDeleted2);
        if(!recordsToBeDeleted2.isEmpty()){
            recordsToBeDeleted2.sort();
            for(SObject sOb:recordsToBeDeleted2){
                recordIdsToBeDeleted.add((Id)sOb.get('Id'));
            }
            System.debug('recordIdsToBeDeleted:'+recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.setChildIdsToBeDeleted(recordIdsToBeDeleted);
            GenericWithoutSharingDMLOperations.deleteChildRecords(new Map<String,Object>{'Class__c'=>'CaseServices','Method__c'=>'deleteChildRecords'});
        }
        if(!lstATSRecords.isEmpty()){
            ATSHandler.insertATSRecord(true, lstATSRecords);        
        }        
    }
}