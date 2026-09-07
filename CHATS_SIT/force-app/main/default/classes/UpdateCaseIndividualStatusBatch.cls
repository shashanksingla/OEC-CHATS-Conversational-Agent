/****************************************************************************
 * Class: UpdateCaseIndividualStatusBatch
 * Test Class : UpdateCaseIndividualStatusBatchTest
 * Description: One-time batch job to update INDIVIDUAL_STATUS__c on T_SBSD_CASE_INDIV__c records based on IND_CRTKR__C and relationship criteria
 ***************************************************************************/
global class UpdateCaseIndividualStatusBatch{
/*Commenting out as the batch is no longer in use
    private Integer recordsProcessed = 0;
    private Integer recordsUpdatedPC = 0;
    private Integer recordsUpdatedAC = 0;
    private Integer recordsUpdatedChild = 0;
    
    private final Set<String> AC_RELATIONSHIP_CODES = new Set<String>{'CLH', 'CLW', 'H', 'LIC', 'SO', 'W', 'X'};

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, INDIVIDUAL_STATUS__c, IND_CRTKR__c, IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__c where INDIVIDUAL_STATUS__c=null]);
    }

    global void execute(Database.BatchableContext BC, List<T_SBSD_CASE_INDIV__c> scope) {
        List<T_SBSD_CASE_INDIV__c> recordsToUpdate = new List<T_SBSD_CASE_INDIV__c>();
        List<T_SBSD_CASE_INDIV__c> updatedRecords = new List<T_SBSD_CASE_INDIV__c>();
        Map<Id, T_SBSD_CASE_INDIV__c> oldCaseIndividualsMap = new Map<Id, T_SBSD_CASE_INDIV__c>();
        Set<Id> nonCaretakerIndividualIds = new Set<Id>();
        
        for (T_SBSD_CASE_INDIV__c caseIndiv : scope) {
            oldCaseIndividualsMap.put(caseIndiv.Id, caseIndiv);
            if (caseIndiv.IND_CRTKR__c == true) {
                caseIndiv.INDIVIDUAL_STATUS__c = 'PC';
                recordsToUpdate.add(caseIndiv);
                recordsUpdatedPC++;
            } else if (caseIndiv.IDN_CLIENT__c != null) {
                nonCaretakerIndividualIds.add(caseIndiv.IDN_CLIENT__c);
            }
        }
        
        if (!nonCaretakerIndividualIds.isEmpty()) {
            Map<Id, Set<String>> individualToRelationshipTypes = new Map<Id, Set<String>>();
            
            for (T_INDIV_REL__c indivRel : [
                SELECT IDN_CLIENT_RELTD__c, CDE_TYPE_REL_INDIV__c
                FROM T_INDIV_REL__c
                WHERE IDN_CLIENT_RELTD__c IN :nonCaretakerIndividualIds
                AND CDE_TYPE_REL_INDIV__c != null
            ]) {
                if (!individualToRelationshipTypes.containsKey(indivRel.IDN_CLIENT_RELTD__c)) {
                    individualToRelationshipTypes.put(indivRel.IDN_CLIENT_RELTD__c, new Set<String>());
                }
                individualToRelationshipTypes.get(indivRel.IDN_CLIENT_RELTD__c).add(indivRel.CDE_TYPE_REL_INDIV__c);
            }
            
            for (T_SBSD_CASE_INDIV__c caseIndiv : scope) {
                if (caseIndiv.IND_CRTKR__c != true && caseIndiv.IDN_CLIENT__c != null) {
                    boolean isAC = false;
                    
                    if (individualToRelationshipTypes.containsKey(caseIndiv.IDN_CLIENT__c)) {
                        Set<String> relationshipTypes = individualToRelationshipTypes.get(caseIndiv.IDN_CLIENT__c);
                        
                        for (String relType : relationshipTypes) {
                            if (AC_RELATIONSHIP_CODES.contains(relType)) {
                                isAC = true;
                                break;
                            }
                        }
                    }
                    
                    if (isAC) {
                        caseIndiv.INDIVIDUAL_STATUS__c = 'AC';
                        recordsUpdatedAC++;
                    } else {
                        caseIndiv.INDIVIDUAL_STATUS__c = 'Child';
                        recordsUpdatedChild++;
                    }
                    
                    recordsToUpdate.add(caseIndiv);
                }
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            caseIndividualServices.disableTrigger = true;
            recordsProcessed += recordsToUpdate.size();
            
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            for(Integer index = 0; index < results.size(); index++) {
                if(results[index].isSuccess()) {
                    updatedRecords.add(recordsToUpdate[index]);
                } else {
                    for (Database.Error error : results[index].getErrors()) {
                        System.debug('Error updating record: ' + error.getMessage());
                    }
                }
            }
            caseIndividualServices.updateIndivDetailsForAdults(updatedRecords, oldCaseIndividualsMap);
        }
    }

    global void finish(Database.BatchableContext BC) {
		System.debug('Status has been updated');
        caseIndividualServices.disableTrigger = false;
    }*/
}